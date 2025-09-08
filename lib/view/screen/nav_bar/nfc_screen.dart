import 'package:touchhealth/core/utils/constant/api_url.dart';
import 'package:touchhealth/core/utils/helper/scaffold_snakbar.dart';
import 'package:touchhealth/core/utils/helper/download_dialog.dart';
import 'package:touchhealth/view/widget/button_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:touchhealth/core/service/nfc_service.dart';
import 'package:touchhealth/core/service/qr_service.dart';
import 'package:touchhealth/core/service/text_input_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

import '../../../controller/medical_record/medical_record_cubit.dart';
import '../../../core/utils/theme/color.dart';
import '../../../core/utils/helper/permission_manager.dart';
import '../../../core/utils/helper/custom_dialog.dart';
import '../../../core/utils/constant/image.dart';
import '../../widget/custom_tooltip.dart';

class NFCScreen extends StatefulWidget {
  final String? id;

  const NFCScreen({super.key, this.id});

  @override
  State<NFCScreen> createState() => _NFCScreenState();
}

class _NFCScreenState extends State<NFCScreen> {
  late WebViewController _controller;
  late final MedicalRecordCubit _cubit;
  bool _isLoading = true;
  final NfcService _nfcService = NfcService();
  final QrService _qrService = QrService();
  final TextInputService _textInputService = TextInputService();
  bool _isScanning = false;
  bool _isQrScanning = false;
  bool _isTextInputting = false;
  MobileScannerController? _qrController;
  final TextEditingController _textController = TextEditingController();
  String? _downloadedFilePath;
  bool _isFileDownloaded = false;

  @override
  void initState() {
    super.initState();
    _cubit = MedicalRecordCubit();

    if (widget.id != null) {
      _cubit.updateWebViewId(widget.id!);
    } else {
      _cubit.initWebView();
    }

    _setupWebViewController();
    _qrController = MobileScannerController();
  }

  void _setupWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            log('WebView error: ${error.description}');
          },
        ),
      );

    // Load initial URL after cubit initialization
    _loadInitialUrl();
  }

  Future<void> _loadInitialUrl() async {
    try {
      String initialUrl;
      if (widget.id != null) {
        // Wait for the cubit to process the ID and generate URL
        await Future.delayed(const Duration(milliseconds: 100));
        await _cubit.loadMedicalRecord(widget.id!);
        initialUrl = _cubit.state.url;
      } else {
        await _cubit.initWebView();
        initialUrl = _cubit.state.url;
      }
      
      if (initialUrl.isNotEmpty) {
        await _controller.loadRequest(Uri.parse(initialUrl));
      }
    } catch (e) {
      log('Error loading initial URL: $e');
    }
  }

  @override
  void dispose() {
    _qrController?.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _scanNFC() async {
    setState(() {
      _isScanning = true;
    });

    bool isAvailable = await _nfcService.isNfcAvailable();

    if (!isAvailable) {
      customSnackBar(context, 'NFC is not available on this device');
      setState(() {
        _isScanning = false;
      });
      return;
    }

    await _nfcService.readNfcData(
      onTagDiscovered: (data) {
        setState(() {
          _isScanning = false;
        });

        String? nfcId = data['tagId'];
        log('NFC Tag ID from service: $nfcId');

        if (nfcId != null && nfcId.isNotEmpty) {
          // Use the async loadMedicalRecord method instead of direct URL loading
          _cubit.loadMedicalRecord(nfcId).then((_) {
            // After loading, update the WebView with the generated URL
            _controller.loadRequest(Uri.parse(_cubit.state.url));
            setState(() {});
            customSnackBar(context, 'NFC tag read successfully: ID $nfcId');
          }).catchError((error) {
            log('Error loading medical record: $error');
            customSnackBar(context, 'Error loading medical record: $error', ColorManager.error);
          });
          _cubit.nfcID = nfcId; // Store the ID for PDF download
        } else {
          customSnackBar(context, 'Could not find ID in NFC tag');
        }
      },
      onError: (error) {
        setState(() {
          _isScanning = false;
        });
        customSnackBar(context, 'Error: $error', ColorManager.error);
      },
      onTimeout: () {
        setState(() {
          _isScanning = false;
        });
        customSnackBar(context, 'NFC scan timed out');
      },
    );
  }

  Future<void> _scanQRCode() async {
    setState(() {
      _isQrScanning = true;
    });

    bool isAvailable = await _qrService.isCameraAvailable();

    if (!isAvailable) {
      customSnackBar(context, 'Camera is not available on this device');
      setState(() {
        _isQrScanning = false;
      });
      return;
    }

    await _qrService.scanQrCode(
      onQrCodeScanned: (data) {
        setState(() {
          _isQrScanning = false;
        });

        String? qrId = data['tagId'];
        log('QR Code ID from service: $qrId');

        if (qrId != null && qrId.isNotEmpty) {
          // Use the async loadMedicalRecord method instead of direct URL loading
          _cubit.loadMedicalRecord(qrId).then((_) {
            // After loading, update the WebView with the generated URL
            _controller.loadRequest(Uri.parse(_cubit.state.url));
            setState(() {});
            customSnackBar(context, 'QR code scanned successfully: ID $qrId');
          }).catchError((error) {
            log('Error loading medical record: $error');
            customSnackBar(context, 'Error loading medical record: $error', ColorManager.error);
          });
          _cubit.nfcID = qrId; // Use same variable for compatibility
        } else {
          customSnackBar(context, 'Could not find ID in QR code');
        }
      },
      onError: (error) {
        setState(() {
          _isQrScanning = false;
        });
        customSnackBar(context, 'Error: $error', ColorManager.error);
      },
      onTimeout: () {
        setState(() {
          _isQrScanning = false;
        });
        customSnackBar(context, 'QR code scan timed out');
      },
    );
  }

  void _showQRScanner() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorManager.green,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scan QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _isQrScanning = false;
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: MobileScanner(
                    controller: _qrController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          Navigator.of(context).pop();
                          _qrService.processQrData(
                            barcode.rawValue!,
                            (data) {
                              setState(() {
                                _isQrScanning = false;
                              });

                              String? qrId = data['tagId'];
                              log('QR Code ID from scanner: $qrId');

                              if (qrId != null && qrId.isNotEmpty) {
                                _cubit.updateWebViewId(qrId);
                                final url = '${_cubit.baseUrl}$qrId';
                                log('Loading WebView URL: $url');
                                _controller.loadRequest(Uri.parse(url));
                                _cubit.nfcID = qrId;
                                setState(() {});
                                customSnackBar(context, 'QR code scanned successfully: ID $qrId');
                              } else {
                                customSnackBar(context, 'Could not find ID in QR code');
                              }
                            },
                          );
                          break;
                        }
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorManager.green.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Position the QR code within the frame to scan',
                    style: TextStyle(
                      color: ColorManager.green,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scanTextInput() async {
    setState(() {
      _isTextInputting = true;
    });

    bool isAvailable = await _textInputService.isTextInputAvailable();

    if (!isAvailable) {
      customSnackBar(context, 'Text input is not available');
      setState(() {
        _isTextInputting = false;
      });
      return;
    }

    await _textInputService.processTextInput(
      onTextInputProcessed: (data) {
        setState(() {
          _isTextInputting = false;
        });

        String? textId = data['tagId'];
        log('Text Input ID from service: $textId');

        if (textId != null && textId.isNotEmpty) {
          // Use the async loadMedicalRecord method instead of direct URL loading
          _cubit.loadMedicalRecord(textId).then((_) {
            // After loading, update the WebView with the generated URL
            _controller.loadRequest(Uri.parse(_cubit.state.url));
            setState(() {});
            customSnackBar(context, 'Medical ID entered successfully: ID $textId');
          }).catchError((error) {
            log('Error loading medical record: $error');
            customSnackBar(context, 'Error loading medical record: $error', ColorManager.error);
          });
          _cubit.nfcID = textId; // Use same variable for compatibility
        } else {
          customSnackBar(context, 'Could not process medical ID');
        }
      },
      onError: (error) {
        setState(() {
          _isTextInputting = false;
        });
        customSnackBar(context, 'Error: $error', ColorManager.error);
      },
      onTimeout: () {
        setState(() {
          _isTextInputting = false;
        });
        customSnackBar(context, 'Text input timed out');
      },
    );
  }

  void _showTextInputDialog() {
    _textController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorManager.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enter Medical Record ID',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.green,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _isTextInputting = false;
                        });
                      },
                      icon: Icon(
                        Icons.close,
                        color: ColorManager.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Please enter the medical record ID manually:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: ColorManager.grey,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter medical record ID...',
                    hintStyle: TextStyle(
                      color: ColorManager.grey.withOpacity(0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: ColorManager.green.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: ColorManager.green,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: ColorManager.green.withOpacity(0.3),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.medical_information,
                      color: ColorManager.green,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: ColorManager.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Examples: 12345, MED-001, REC123456',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorManager.grey.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _isTextInputting = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.grey.withOpacity(0.2),
                          foregroundColor: ColorManager.grey,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          final inputText = _textController.text.trim();
                          if (inputText.isNotEmpty) {
                            Navigator.of(context).pop();
                            _textInputService.processTextData(
                              inputText,
                              (data) {
                                setState(() {
                                  _isTextInputting = false;
                                });

                                String? textId = data['tagId'];
                                log('Text Input ID from dialog: $textId');

                                if (textId != null && textId.isNotEmpty) {
                                  _cubit.updateWebViewId(textId);
                                  final url = '${_cubit.baseUrl}$textId';
                                  log('Loading WebView URL: $url');
                                  _controller.loadRequest(Uri.parse(url));
                                  _cubit.nfcID = textId;
                                  setState(() {});
                                  customSnackBar(context, 'Medical ID entered successfully: ID $textId');
                                } else {
                                  customSnackBar(context, 'Invalid medical ID format');
                                }
                              },
                            );
                          } else {
                            customSnackBar(context, 'Please enter a medical record ID');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Load Record',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadPDF(String url) async {
    setState(() {
      _isLoading = true;
    });

    bool isCancelled = false;
    CancelToken cancelToken = CancelToken();

    Function? updateDialog;

    try {
      showDownloadProgressDialog(
        context: context,
        initialMessage: 'Preparing to download PDF...',
        onControllerReady: (updateFn) {
          updateDialog = updateFn;
        },
        onCancel: () {
          isCancelled = true;
          cancelToken.cancel('Download cancelled by user');
          Navigator.of(context, rootNavigator: true).pop();
          _showMessageDialog(
              context, 'Download Cancelled', 'Download operation was cancelled',
              isError: true);
        },
        onOpen: () {
          Navigator.of(context, rootNavigator: true).pop();
          _openDownloadedFile();
        },
      );

      await Future.delayed(Duration(milliseconds: 200));

      final permissionManager = PermissionManager();
      bool permissionGranted = await permissionManager.requestPermission();

      if (permissionGranted) {
        Directory? directory;
        if (Platform.isAndroid) {
          try {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } catch (e) {
            log('Error accessing Download directory: $e');
            directory = await getExternalStorageDirectory();
            if (directory == null) {
              throw Exception('Could not access external storage');
            }
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        String fileName =
            'medical_record_${DateTime.now().millisecondsSinceEpoch}.pdf';
        String filePath = '${directory.path}/$fileName';

        log('Downloading PDF to: $filePath');
        updateDialog?.call(0.05, 'Establishing connection...', false);

        final dio = Dio();

        try {
          final response = await dio.get(
            url,
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
              headers: {
                'Accept': '*/*',
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
              },
            ),
            cancelToken: cancelToken,
            onReceiveProgress: (received, total) {
              if (total != -1 && !isCancelled) {
                final progress = received / total;
                updateDialog?.call(
                    progress,
                    'Downloading PDF... ${(progress * 100).toStringAsFixed(0)}%',
                    false);
              }
            },
          );

          if (response.statusCode == 200) {
            final file = File(filePath);
            updateDialog?.call(0.95, 'Saving file...', false);
            await file.writeAsBytes(response.data);

            if (await file.exists() && await file.length() > 0) {
              log('File downloaded successfully to: ${file.path} with size: ${await file.length()} bytes');

              _downloadedFilePath = file.path;
              _isFileDownloaded = true;

              updateDialog?.call(
                  1.0, 'PDF downloaded successfully to Downloads folder', true);

              setState(() {});
            } else {
              throw Exception('File was created but is empty or invalid');
            }
          } else {
            throw Exception('Failed to download file: ${response.statusCode}');
          }
        } catch (dioError) {
          if (isCancelled) {
            return;
          }

          log('Initial download method failed: $dioError');
          log('Trying alternative download method...');

          updateDialog?.call(
              0.1, 'Trying alternative download method...', false);

          try {
            await dio.download(
              url,
              filePath,
              options: Options(
                followRedirects: true,
                validateStatus: (status) => status != null && status < 500,
              ),
              cancelToken: cancelToken,
              onReceiveProgress: (received, total) {
                if (total != -1 && !isCancelled) {
                  final progress = received / total;
                  updateDialog?.call(
                      progress,
                      'Downloading PDF... ${(progress * 100).toStringAsFixed(0)}%',
                      false);
                }
              },
            );

            final file = File(filePath);
            if (await file.exists() && await file.length() > 0) {
              log('File downloaded successfully with alternative method. Size: ${await file.length()} bytes');

              _downloadedFilePath = file.path;
              _isFileDownloaded = true;

              updateDialog?.call(
                  1.0, 'PDF downloaded successfully to Downloads folder', true);

              setState(() {});
            } else {
              throw Exception(
                  'Alternative download failed: File is empty or invalid');
            }
          } catch (alternativeError) {
            if (isCancelled) {
              return;
            }
            throw Exception('All download attempts failed: $alternativeError');
          }
        }
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        _showMessageDialog(context, 'Permission Error',
            'Storage permission denied. Please enable in settings.',
            isError: true);
        openAppSettings();
      }
    } catch (e) {
      if (!isCancelled) {
        log('Error downloading PDF: $e');
        Navigator.of(context, rootNavigator: true).pop();
        _showMessageDialog(
            context, 'Download Error', 'Error downloading PDF: ${e.toString()}',
            isError: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openDownloadedFile() async {
    if (_downloadedFilePath != null) {
      try {
        final file = File(_downloadedFilePath!);
        if (await file.exists()) {
          try {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  backgroundColor: ColorManager.white,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 24.h, horizontal: 16),
                    decoration: BoxDecoration(
                      color: ColorManager.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "PDF File",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: ColorManager.green,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Your medical record PDF has been downloaded to:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14.sp, color: ColorManager.grey),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: ColorManager.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ColorManager.green,
                              width: 1,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          child: Text(
                            file.path,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: ColorManager.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await Share.shareXFiles(
                                  [XFile(file.path)],
                                  text: 'Medical Record',
                                  subject: 'Medical Record PDF',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.share, size: 16.w),
                                  SizedBox(width: 8.w),
                                  Text("Share"),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                _openFileWithOptions(file);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_with, size: 16.w),
                                  SizedBox(width: 8.w),
                                  Text("Open With"),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.error,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cancel, size: 16.w),
                                  SizedBox(width: 8.w),
                                  Text("Cancel"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } catch (e) {
            log('Error opening file with share dialog: $e');
            _showMessageDialog(
                context, 'Error', 'Error opening file: ${e.toString()}',
                isError: true);
          }
        } else {
          _showMessageDialog(context, 'Error', 'File does not exist anymore',
              isError: true);
        }
      } catch (e) {
        log('Error opening file: $e');
        _showMessageDialog(
            context, 'Error', 'Error opening file: ${e.toString()}',
            isError: true);
      }
    }
  }

  void _openFileWithOptions(File file) async {
    try {
      await OpenFilex.open(
        file.path,
        type: 'application/pdf',
      );
    } catch (e) {
      log('Error opening file with options: $e');
      _showMessageDialog(
          context, 'Error', 'Error opening file: ${e.toString()}',
          isError: true);
    }
  }

  void _showMessageDialog(BuildContext context, String title, String message,
      {bool isError = false}) {
    customDialog(
      context,
      title: title,
      errorMessage: message,
      subtitle: '',
      buttonTitle: 'Cancel',
      onPressed: () => Navigator.of(context).pop(),
      image: isError ? ImageManager.errorIcon : ImageManager.trueIcon,
      dismiss: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: WebViewWidget(controller: _controller)),
          // if (_isLoading)
          //   const Center(
          //     child: CircularProgressIndicator(
          //       color: ColorManager.green,
          //     ),
          //   ),
          if (_isScanning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  ButtonLoadingIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Scanning NFC...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isQrScanning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  ButtonLoadingIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Preparing QR Scanner...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isTextInputting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  ButtonLoadingIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Processing Text Input...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 40.h,
            right: 8,
            child: CustomToolTip(
              bottomMargin: 20,
              message: 'Reload',
              child: FloatingActionButton.small(
                heroTag: 'refreshButton',
                shape: CircleBorder(),
                backgroundColor: ColorManager.green,
                onPressed: () => _controller.reload(),
                child: const Icon(Icons.refresh, color: ColorManager.white),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomToolTip(
            bottomMargin: 20,
            message: 'Share PDF',
            child: FloatingActionButton.small(
              heroTag: 'openFileButton',
              backgroundColor:
                  _isFileDownloaded ? ColorManager.green : ColorManager.grey,
              onPressed: _isFileDownloaded ? _openDownloadedFile : null,
              child: const Icon(Icons.open_in_new, color: ColorManager.white),
            ),
          ),
          Gap(10.h),
          CustomToolTip(
            bottomMargin: 20,
            message: 'Download PDF',
            child: FloatingActionButton.small(
              heroTag: 'saveButton',
              backgroundColor:
                  (_cubit.nfcID != null || _cubit.nfcID?.isNotEmpty == true)
                      ? ColorManager.green
                      : ColorManager.grey,
              onPressed: _cubit.nfcID != null
                  ? () {
                      String pdfUrl =
                          '${EnvManager.medicalRecordPdfBackend}${_cubit.nfcID}/generate-pdf/';
                      _downloadPDF(pdfUrl);
                    }
                  : null,
              child: const Icon(Icons.save, color: ColorManager.white),
            ),
          ),
          Gap(10.h),
          CustomToolTip(
            bottomMargin: 20,
            message: 'Enter Text ID',
            child: FloatingActionButton(
              heroTag: 'textButton',
              backgroundColor: ColorManager.green,
              onPressed: (_isScanning || _isQrScanning || _isTextInputting) ? null : () {
                setState(() {
                  _isTextInputting = true;
                });
                _showTextInputDialog();
              },
              child: const Icon(Icons.keyboard, color: ColorManager.white),
            ),
          ),
          Gap(10.h),
          CustomToolTip(
            bottomMargin: 20,
            message: 'Scan QR Code',
            child: FloatingActionButton(
              heroTag: 'qrButton',
              backgroundColor: ColorManager.green,
              onPressed: (_isScanning || _isQrScanning || _isTextInputting) ? null : () {
                setState(() {
                  _isQrScanning = true;
                });
                _showQRScanner();
              },
              child: const Icon(Icons.qr_code_scanner, color: ColorManager.white),
            ),
          ),
          Gap(10.h),
          CustomToolTip(
            bottomMargin: 20,
            message: 'Scan NFC',
            child: FloatingActionButton(
              heroTag: 'nfcButton',
              backgroundColor: ColorManager.green,
              onPressed: (_isScanning || _isQrScanning || _isTextInputting) ? null : _scanNFC,
              child: const Icon(Icons.nfc, color: ColorManager.white),
            ),
          ),
        ],
      ),
    );
  }
}
