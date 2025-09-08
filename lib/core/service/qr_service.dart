import 'dart:developer';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrService {
  Future<bool> isCameraAvailable() async {
    try {
      // Check if camera permission is available
      return true; // mobile_scanner handles permission internally
    } catch (e) {
      log('Error checking camera availability: $e');
      return false;
    }
  }

  Future<void> scanQrCode({
    required Function(Map<String, dynamic> data) onQrCodeScanned,
    required Function(String error) onError,
    required Function() onTimeout,
  }) async {
    try {
      log('=== QR Code Scanning Started ===');
      
      // The actual scanning will be handled by the MobileScanner widget
      // This service provides the callback structure similar to NFC service
      
      log('QR Code scanner initialized successfully');
      
    } catch (e) {
      log('=== QR Code Scanning Error ===');
      log('Error: $e');
      onError('Error initializing QR code scanner: $e');
    }
  }

  void processQrData(String qrData, Function(Map<String, dynamic> data) onQrCodeScanned) {
    try {
      log('=== QR Code Data Processing ===');
      log('QR Data: $qrData');

      // Extract medical record ID from QR code
      String medicalId = _extractMedicalId(qrData);
      
      if (medicalId.isNotEmpty) {
        log('Medical ID extracted: $medicalId');
        
        onQrCodeScanned({
          'message': 'QR code scanned successfully.',
          'tagId': medicalId, // Use same key as NFC for compatibility
          'qrData': qrData,
          'rawData': qrData,
        });
      } else {
        onQrCodeScanned({
          'message': 'Could not extract medical ID from QR code.',
          'tagId': qrData, // Use raw data as fallback
          'qrData': qrData,
          'rawData': qrData,
        });
      }
      
      log('=== QR Code Processing Completed ===');
    } catch (e) {
      log('Error processing QR data: $e');
      // Still return the raw data even if processing fails
      onQrCodeScanned({
        'message': 'Error processing QR data: $e',
        'tagId': qrData,
        'qrData': qrData,
        'rawData': qrData,
      });
    }
  }

  String _extractMedicalId(String qrData) {
    // Handle different QR code formats
    
    // Format 1: Plain medical ID (just numbers/letters)
    if (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(qrData)) {
      return qrData;
    }
    
    // Format 2: URL with medical ID
    // Example: https://touchhealth.com/medical-record/12345
    final urlPattern = RegExp(r'medical[-_]?record[/:]([a-zA-Z0-9]+)', caseSensitive: false);
    final urlMatch = urlPattern.firstMatch(qrData);
    if (urlMatch != null) {
      return urlMatch.group(1) ?? '';
    }
    
    // Format 3: JSON format
    // Example: {"medicalId": "12345", "patientName": "John Doe"}
    if (qrData.startsWith('{') && qrData.endsWith('}')) {
      try {
        // Simple JSON parsing for medical ID
        final idPattern = RegExp(r'"(?:medicalId|id|recordId)":\s*"([^"]+)"', caseSensitive: false);
        final jsonMatch = idPattern.firstMatch(qrData);
        if (jsonMatch != null) {
          return jsonMatch.group(1) ?? '';
        }
      } catch (e) {
        log('Error parsing JSON QR data: $e');
      }
    }
    
    // Format 4: Key-value pairs
    // Example: medicalId=12345&patientName=John
    final kvPattern = RegExp(r'(?:medicalId|id|recordId)=([a-zA-Z0-9]+)', caseSensitive: false);
    final kvMatch = kvPattern.firstMatch(qrData);
    if (kvMatch != null) {
      return kvMatch.group(1) ?? '';
    }
    
    // Format 5: Colon separated
    // Example: medicalId:12345
    final colonPattern = RegExp(r'(?:medicalId|id|recordId):([a-zA-Z0-9]+)', caseSensitive: false);
    final colonMatch = colonPattern.firstMatch(qrData);
    if (colonMatch != null) {
      return colonMatch.group(1) ?? '';
    }
    
    // If no pattern matches, return the raw data
    log('No medical ID pattern matched, using raw QR data');
    return qrData;
  }
}
