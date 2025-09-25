import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:touchhealth/core/utils/theme/color.dart';
import 'package:touchhealth/core/utils/helper/extention.dart';
import 'package:touchhealth/controller/practitioner/patient_search_cubit.dart';
import 'package:touchhealth/controller/auth/practitioner_auth/practitioner_auth_cubit.dart';
import 'package:touchhealth/core/service/consent_service.dart';
import 'package:touchhealth/core/service/blockchain_ledger_service.dart';
import 'package:touchhealth/core/service/pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:touchhealth/core/service/patient_lookup_service.dart';
import 'package:touchhealth/core/router/routes.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  Map<String, dynamic>? _currentRecord;
  bool? _hasConsent; // null = unknown/loading, true/false once checked
  String? _practitionerUid;
  String? _practitionerName;
  String? _practitionerEmail;
  List<Map<String, dynamic>> _ledgerEntries = [];

  @override
  void initState() {
    super.initState();
    // Load full medical record when screen opens
    context.read<PatientSearchCubit>().getPatientMedicalRecord(
      widget.patient['medicalNumber'] ?? '',
    );
    _initConsent();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final patientId = widget.patient['medicalNumber']?.toString() ?? '';
    if (patientId.isEmpty) return;
    try {
      final entries = await BlockchainLedgerService.fetchEntries(patientId: patientId, limit: 15);
      if (mounted) setState(() => _ledgerEntries = entries);
    } catch (_) {
      // Silent fail: ledger is optional UI
    }
  }

  Widget _buildLedgerSection(String patientId) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: Colors.indigo, size: 24.w),
              Gap(8.w),
              Expanded(
                child: Text(
                  'Blockchain Ledger',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh ledger',
                icon: Icon(Icons.refresh, color: Colors.indigo),
                onPressed: _loadLedger,
              ),
            ],
          ),
          Gap(12.h),
          if (_ledgerEntries.isEmpty)
            Text(
              'No ledger entries yet.',
              style: context.textTheme.bodyMedium,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ledgerEntries.length,
              separatorBuilder: (_, __) => Divider(height: 12.h),
              itemBuilder: (ctx, i) {
                final e = _ledgerEntries[i];
                final idx = e['chainIndex'] ?? i;
                final action = (e['action'] ?? '').toString();
                final type = (e['entryType'] ?? '').toString();
                final ts = (e['timestamp'] ?? '').toString();
                final hash = (e['hash'] ?? '').toString();
                final prev = (e['prevHash'] ?? '').toString();
                final docId = (e['documentId'] ?? '').toString();
                final practitionerId = (e['practitionerId'] ?? '').toString();
                final payload = (e['payload'] is Map<String, dynamic>)
                    ? Map<String, dynamic>.from(e['payload'])
                    : <String, dynamic>{};
                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#$idx  ${action.toUpperCase()}  ${type.toUpperCase()}',
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          Text(
                            ts,
                            style: context.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      Gap(6.h),
                      if (docId.isNotEmpty)
                        Text('Doc: $docId', style: context.textTheme.bodySmall),
                      if (practitionerId.isNotEmpty)
                        Text('By: $practitionerId', style: context.textTheme.bodySmall),
                      Gap(6.h),
                      if (payload.isNotEmpty) ...[
                        Text('Payload:', style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                        Gap(4.h),
                        ...payload.entries.map((kv) => Padding(
                              padding: EdgeInsets.only(left: 8.w, bottom: 2.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: context.textTheme.bodySmall),
                                  Expanded(
                                    child: Text(
                                      '${kv.key}: ${kv.value}',
                                      style: context.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      Gap(6.h),
                      Text('Hash: ${hash.isNotEmpty ? hash.substring(0, 12) : ''}...', style: context.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                      if (prev.isNotEmpty)
                        Text('Prev: ${prev.substring(0, 12)}...', style: context.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _editVital(String key, Map<String, dynamic> vital) async {
    final typeCtrl = TextEditingController(text: vital['type']?.toString() ?? key);
    final valueCtrl = TextEditingController(text: vital['value']?.toString() ?? '');
    final unitCtrl = TextEditingController(text: vital['unit']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: vital['notes']?.toString() ?? '');
    final timestampCtrl = TextEditingController(text: vital['timestamp']?.toString() ?? DateTime.now().toIso8601String());

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Vital'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(labelText: 'Type (e.g., O2 Saturation)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: valueCtrl,
                  decoration: const InputDecoration(labelText: 'Value'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: unitCtrl,
                  decoration: const InputDecoration(labelText: 'Unit (e.g., bpm, mmHg, %)'),
                ),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
                TextFormField(
                  controller: timestampCtrl,
                  decoration: const InputDecoration(labelText: 'Timestamp (ISO8601)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final prac = context.read<PractitionerAuthCubit>().currentPractitioner;
                final updated = {
                  'type': typeCtrl.text.trim(),
                  'value': valueCtrl.text.trim(),
                  'unit': unitCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                  'timestamp': timestampCtrl.text.trim(),
                };
                final docId = vital['id'] as String?;
                if (docId == null) {
                  throw Exception('Cannot edit: missing entry id');
                }
                await PatientLookupService.updateMedicalEntry(
                  widget.patient['medicalNumber'] ?? '',
                  'vital',
                  docId,
                  updated,
                  practitionerUid: prac?.uid,
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                context.read<PatientSearchCubit>().getPatientMedicalRecord(
                  widget.patient['medicalNumber'] ?? '',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vital updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildLabs(List<dynamic>? labs, {bool enableAdd = true}) {
    if (labs == null) return SizedBox.shrink();

    return _buildSection(
      title: 'Lab Results',
      icon: Icons.science,
      entryType: enableAdd ? 'lab' : null,
      child: Column(
        children: labs.map((lab) => _buildLabItem(Map<String, dynamic>.from(lab))).toList(),
      ),
    );
  }

  Widget _buildLabItem(Map<String, dynamic> lab) {
    final collectedAt = DateTime.tryParse(lab['collectedAt'] ?? '');
    final dateStr = collectedAt != null ? '${collectedAt.day}/${collectedAt.month}/${collectedAt.year}' : (lab['collectedAt']?.toString() ?? '');
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.biotech, color: Colors.purple, size: 20.w),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lab['testName']?.toString() ?? 'Lab Test', style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('${lab['resultValue'] ?? ''} ${lab['unit'] ?? ''}', style: context.textTheme.bodySmall),
                if (lab['referenceRange'] != null)
                  Text('Ref: ${lab['referenceRange']}', style: context.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                if (dateStr.isNotEmpty)
                  Text('Collected: $dateStr', style: context.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                if (lab['notes'] != null)
                  Text('Notes: ${lab['notes']}', style: context.textTheme.bodySmall),
              ],
            ),
          ),
          if (_hasConsent == true)
            IconButton(
              tooltip: 'Edit lab result',
              icon: Icon(Icons.edit, color: ColorManager.green, size: 20.w),
              onPressed: () => _editLab(lab),
            ),
        ],
      ),
    );
  }

  Widget _buildScans(List<dynamic>? scans, {bool enableAdd = true}) {
    if (scans == null) return SizedBox.shrink();

    return _buildSection(
      title: 'Scans',
      icon: Icons.image_search,
      entryType: enableAdd ? 'scan' : null,
      child: Column(
        children: scans.map((s) => _buildScanItem(Map<String, dynamic>.from(s))).toList(),
      ),
    );
  }

  Widget _buildScanItem(Map<String, dynamic> scan) {
    final date = DateTime.tryParse(scan['date'] ?? '');
    final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : (scan['date']?.toString() ?? '');
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_information, color: Colors.teal, size: 20.w),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan['type']?.toString() ?? 'Scan', style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(scan['findings']?.toString() ?? '', style: context.textTheme.bodySmall),
                if (scan['radiologist'] != null)
                  Text('By: ${scan['radiologist']}', style: context.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                if (dateStr.isNotEmpty)
                  Text('Date: $dateStr', style: context.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                if (scan['notes'] != null)
                  Text('Notes: ${scan['notes']}', style: context.textTheme.bodySmall),
              ],
            ),
          ),
          if (_hasConsent == true)
            IconButton(
              tooltip: 'Edit scan',
              icon: Icon(Icons.edit, color: ColorManager.green, size: 20.w),
              onPressed: () => _editScan(scan),
            ),
        ],
      ),
    );
  }

  Future<void> _editLab(Map<String, dynamic> lab) async {
    final testNameCtrl = TextEditingController(text: lab['testName']?.toString() ?? '');
    final valueCtrl = TextEditingController(text: lab['resultValue']?.toString() ?? '');
    final unitCtrl = TextEditingController(text: lab['unit']?.toString() ?? '');
    final refCtrl = TextEditingController(text: lab['referenceRange']?.toString() ?? '');
    final collectedCtrl = TextEditingController(text: lab['collectedAt']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: lab['notes']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Lab Result'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: testNameCtrl, decoration: const InputDecoration(labelText: 'Test Name')),
                TextFormField(controller: valueCtrl, decoration: const InputDecoration(labelText: 'Result Value')),
                TextFormField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit')),
                TextFormField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Reference Range')),
                TextFormField(controller: collectedCtrl, decoration: const InputDecoration(labelText: 'Collected At (ISO8601)')),
                TextFormField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final prac = context.read<PractitionerAuthCubit>().currentPractitioner;
                final updated = {
                  'testName': testNameCtrl.text.trim(),
                  'resultValue': valueCtrl.text.trim(),
                  'unit': unitCtrl.text.trim(),
                  'referenceRange': refCtrl.text.trim(),
                  'collectedAt': collectedCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                };
                final docId = lab['id'] as String?;
                if (docId != null) {
                  await PatientLookupService.updateMedicalEntry(
                    widget.patient['medicalNumber'] ?? '',
                    'lab',
                    docId,
                    updated,
                    practitionerUid: prac?.uid,
                  );
                } else {
                  // No existing Firestore doc; create a new entry
                  final entryData = <String, String>{
                    'testName': updated['testName'] ?? '',
                    'resultValue': updated['resultValue'] ?? '',
                    'unit': updated['unit'] ?? '',
                    'referenceRange': updated['referenceRange'] ?? '',
                    'collectedAt': updated['collectedAt'] ?? '',
                    'notes': updated['notes'] ?? '',
                    'timestamp': DateTime.now().toIso8601String(),
                    'addedBy': prac?.name ?? prac?.email ?? 'Unknown Practitioner',
                    if (prac?.uid != null) 'addedByUid': prac!.uid,
                  };
                  await PatientLookupService.addMedicalEntry(
                    widget.patient['medicalNumber'] ?? '',
                    'lab',
                    entryData,
                  );
                }
                if (!mounted) return;
                Navigator.pop(ctx);
                context.read<PatientSearchCubit>().getPatientMedicalRecord(
                  widget.patient['medicalNumber'] ?? '',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lab updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editScan(Map<String, dynamic> scan) async {
    final typeCtrl = TextEditingController(text: scan['type']?.toString() ?? '');
    final findingsCtrl = TextEditingController(text: scan['findings']?.toString() ?? '');
    final radiologistCtrl = TextEditingController(text: scan['radiologist']?.toString() ?? '');
    final dateCtrl = TextEditingController(text: scan['date']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: scan['notes']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Scan'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type')),
                TextFormField(controller: findingsCtrl, decoration: const InputDecoration(labelText: 'Findings')),
                TextFormField(controller: radiologistCtrl, decoration: const InputDecoration(labelText: 'Radiologist')),
                TextFormField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (ISO8601)')),
                TextFormField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final prac = context.read<PractitionerAuthCubit>().currentPractitioner;
                final updated = {
                  'type': typeCtrl.text.trim(),
                  'findings': findingsCtrl.text.trim(),
                  'radiologist': radiologistCtrl.text.trim(),
                  'date': dateCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                };
                final docId = scan['id'] as String?;
                if (docId != null) {
                  await PatientLookupService.updateMedicalEntry(
                    widget.patient['medicalNumber'] ?? '',
                    'scan',
                    docId,
                    updated,
                    practitionerUid: prac?.uid,
                  );
                } else {
                  final entryData = <String, String>{
                    'type': updated['type'] ?? '',
                    'findings': updated['findings'] ?? '',
                    'radiologist': updated['radiologist'] ?? '',
                    'date': updated['date'] ?? '',
                    'notes': updated['notes'] ?? '',
                    'timestamp': DateTime.now().toIso8601String(),
                    'addedBy': prac?.name ?? prac?.email ?? 'Unknown Practitioner',
                    if (prac?.uid != null) 'addedByUid': prac!.uid,
                  };
                  await PatientLookupService.addMedicalEntry(
                    widget.patient['medicalNumber'] ?? '',
                    'scan',
                    entryData,
                  );
                }
                if (!mounted) return;
                Navigator.pop(ctx);
                context.read<PatientSearchCubit>().getPatientMedicalRecord(
                  widget.patient['medicalNumber'] ?? '',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scan updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _initConsent() async {
    final prac = context.read<PractitionerAuthCubit>().currentPractitioner;
    _practitionerUid = prac?.uid;
    _practitionerName = prac?.name;
    _practitionerEmail = prac?.email;
    final medicalNumber = widget.patient['medicalNumber'] ?? '';
    if (_practitionerUid == null || medicalNumber.isEmpty) {
      setState(() => _hasConsent = false);
      return;
    }
    try {
      final allowed = await ConsentService.hasConsent(
        medicalNumber: medicalNumber,
        practitionerUid: _practitionerUid!,
      );
      if (mounted) setState(() => _hasConsent = allowed);

      // Append blockchain access event (view/select) best-effort
      try {
        await BlockchainLedgerService.appendEntry(
          patientId: medicalNumber,
          practitionerId: _practitionerUid!,
          action: 'access',
          entryType: 'access',
          documentId: 'patient_select',
          payload: {
            'practitionerName': _practitionerName,
            'practitionerEmail': _practitionerEmail,
            'consent': allowed ? 'active' : 'missing',
            'screen': 'PatientDetailsScreen',
          },
        );
        // Refresh ledger view after writing an access entry
        await _loadLedger();
      } catch (_) {
        // ignore
      }
    } catch (_) {
      if (mounted) setState(() => _hasConsent = false);
    }
  }

  Future<void> _exportToPdf() async {
    if (_currentRecord == null) return;
    try {
      final bytes = await PdfService.buildMedicalRecordPdf(_currentRecord!);
      await Printing.sharePdf(bytes: bytes, filename: 'TouchHealth_Medical_Record.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorManager.green,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Details',
          style: context.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_hasConsent == true)
            IconButton(
              tooltip: 'Edit patient profile',
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                final args = Map<String, dynamic>.from(
                  _currentRecord != null ? (_currentRecord!['patient'] ?? widget.patient) : widget.patient,
                );
                final result = await Navigator.pushNamed(
                  context,
                  RouteManager.editPatientDemographics,
                  arguments: args,
                );
                if (result == true) {
                  if (!mounted) return;
                  context.read<PatientSearchCubit>().getPatientMedicalRecord(
                        widget.patient['medicalNumber'] ?? '',
                      );
                }
              },
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<PatientSearchCubit>().getPatientMedicalRecord(
                widget.patient['medicalNumber'] ?? '',
              );
            },
          ),
          IconButton(
            tooltip: 'Export to PDF',
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _currentRecord == null ? null : () => _exportToPdf(),
          ),
        ],
      ),
      body: BlocBuilder<PatientSearchCubit, PatientSearchState>(
        builder: (context, state) {
          if (state is PatientDetailsLoading) {
            return Center(
              child: CircularProgressIndicator(color: ColorManager.green),
            );
          }

          if (state is PatientDetailsSuccess) {
            _currentRecord = state.patientRecord;
            return _buildPatientDetails(state.patientRecord);
          }

          if (state is PatientSearchError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.w, color: ColorManager.error),
                  Gap(16.h),
                  Text(
                    'Error Loading Patient Details',
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: ColorManager.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      state.message,
                      style: context.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Gap(24.h),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PatientSearchCubit>().getPatientMedicalRecord(
                        widget.patient['medicalNumber'] ?? '',
                      );
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Fallback to basic patient info
          return _buildBasicPatientInfo();
        },
      ),
    );
  }

  Widget _buildPatientDetails(Map<String, dynamic> record) {
    final patient = record['patient'] ?? widget.patient;
    final hasConsent = _hasConsent == true;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientHeader(patient),
          if (_hasConsent == false) ...[
            Gap(12.h),
            _buildConsentWarning(),
          ],
          Gap(20.h),
          _buildVitalSigns(record['vitals'], enableAdd: hasConsent),
          Gap(20.h),
          _buildMedicalHistory(record['medicalHistory'], enableAdd: hasConsent),
          Gap(20.h),
          _buildCurrentMedications(record['medications'], enableAdd: hasConsent),
          Gap(20.h),
          _buildLabs(record['labs'], enableAdd: hasConsent),
          Gap(20.h),
          _buildScans(record['scans'], enableAdd: hasConsent),
          Gap(20.h),
          _buildAppointments(record['appointments'], enableAdd: hasConsent),
          Gap(20.h),
          _buildLastUpdated(record['lastUpdated']),
          Gap(20.h),
          _buildLedgerSection(widget.patient['medicalNumber'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildBasicPatientInfo() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientHeader(widget.patient),
          Gap(20.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 32.w),
                Gap(8.h),
                Text(
                  'Limited Information Available',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Gap(4.h),
                Text(
                  'Full medical record could not be loaded. Showing basic patient information only.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(Map<String, dynamic> patient) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorManager.green, ColorManager.green.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: Colors.white,
            child: Icon(
              patient['gender'] == 'Male' ? Icons.man : Icons.woman,
              color: ColorManager.green,
              size: 50.w,
            ),
          ),
          Gap(12.h),
          Text(
            patient['name'] ?? 'Unknown Patient',
            style: context.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Medical #: ${patient['medicalNumber']}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Gap(12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoChip('Age', '${patient['age']} years'),
              _buildInfoChip('Gender', patient['gender'] ?? 'Unknown'),
              _buildInfoChip('Blood Type', patient['bloodType'] ?? 'Unknown'),
            ],
          ),
          if (patient['phone'] != null) ...[
            Gap(8.h),
            Text(
              patient['phone'],
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontSize: 10.spMin,
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSigns(Map<String, dynamic>? vitals, {bool enableAdd = true}) {
    if (vitals == null) return SizedBox.shrink();

    return _buildSection(
      title: 'Vital Signs',
      icon: Icons.favorite,
      entryType: enableAdd ? 'vital' : null,
      child: Column(
        children: [
          if (vitals['bloodPressure'] != null)
            _buildVitalRow(
              'Blood Pressure',
              '${vitals['bloodPressure']['systolic']}/${vitals['bloodPressure']['diastolic']} ${vitals['bloodPressure']['unit']}',
              Icons.monitor_heart,
            ),
          if (vitals['heartRate'] != null)
            _buildVitalRow(
              'Heart Rate',
              '${vitals['heartRate']['value']} ${vitals['heartRate']['unit']}',
              Icons.favorite,
            ),
          if (vitals['temperature'] != null)
            _buildVitalRow(
              'Temperature',
              '${vitals['temperature']['value'].toStringAsFixed(1)} ${vitals['temperature']['unit']}',
              Icons.thermostat,
            ),
          // Render additional practitioner-added vitals (merged from Firestore)
          ...vitals.entries
              .where((e) =>
                  e.key != 'bloodPressure' &&
                  e.key != 'heartRate' &&
                  e.key != 'temperature')
              .map((e) {
            final v = Map<String, dynamic>.from(e.value ?? {});
            final label = (e.key as String)
                .replaceAll(RegExp(r'(?<!^)([A-Z])'), ' \\1')
                .replaceAll('_', ' ')
                .trim();
            final valueStr = [
              if (v['value'] != null) v['value'].toString(),
              if (v['unit'] != null) v['unit'].toString(),
            ].join(' ').trim();
            return Container(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                children: [
                  Icon(Icons.health_and_safety, color: ColorManager.green, size: 20.w),
                  Gap(12.w),
                  Expanded(
                    child: Text(
                      label.isEmpty ? 'Vital' : label,
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    valueStr,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorManager.green,
                    ),
                  ),
                  if ((_hasConsent == true) && (v['id'] != null))
                    IconButton(
                      tooltip: 'Edit vital',
                      icon: Icon(Icons.edit, color: ColorManager.green, size: 20.w),
                      onPressed: () => _editVital(e.key, v),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVitalRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, color: ColorManager.green, size: 20.w),
          Gap(12.w),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorManager.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistory(Map<String, dynamic>? history, {bool enableAdd = true}) {
    if (history == null) return SizedBox.shrink();

    return _buildSection(
      title: 'Medical History',
      icon: Icons.history,
      entryType: enableAdd ? 'history' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history['allergies'] != null && (history['allergies'] as List).isNotEmpty)
            _buildHistoryItem('Allergies', history['allergies']),
          if (history['chronicConditions'] != null && (history['chronicConditions'] as List).isNotEmpty)
            _buildHistoryItem('Chronic Conditions', history['chronicConditions']),
          if (history['familyHistory'] != null && (history['familyHistory'] as List).isNotEmpty)
            _buildHistoryItem('Family History', history['familyHistory']),
          if (history['newEntries'] != null && (history['newEntries'] as List).isNotEmpty) ...[
            Gap(12.h),
            Text(
              'New History Entries',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ColorManager.green,
              ),
            ),
            Gap(8.h),
            ...List<Map<String, dynamic>>.from(history['newEntries']).map((e) => _buildHistoryEditableItem(e)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, List<dynamic> items) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorManager.green,
            ),
          ),
          Gap(4.h),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(left: 16.w, bottom: 2.h),
            child: Row(
              children: [
                Icon(Icons.circle, size: 4.w, color: Colors.grey),
                Gap(8.w),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCurrentMedications(List<dynamic>? medications, {bool enableAdd = true}) {
    if (medications == null || medications.isEmpty) return SizedBox.shrink();

    return _buildSection(
      title: 'Current Medications',
      icon: Icons.medication,
      entryType: enableAdd ? 'medication' : null,
      child: Column(
        children: medications.map((med) => _buildMedicationItem(med)).toList(),
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> medication) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.medication, color: Colors.blue, size: 20.w),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication['name'] ?? 'Unknown Medication',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${medication['dosage']} - ${medication['frequency']}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (_hasConsent == true)
            IconButton(
              tooltip: 'Edit medication',
              icon: Icon(Icons.edit, color: ColorManager.green, size: 20.w),
              onPressed: () => _editMedication(medication),
            ),
        ],
      ),
    );
  }

  Future<void> _editMedication(Map<String, dynamic> medication) async {
    final nameCtrl = TextEditingController(text: medication['name']?.toString() ?? '');
    final dosageCtrl = TextEditingController(text: medication['dosage']?.toString() ?? '');
    final freqCtrl = TextEditingController(text: medication['frequency']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: medication['notes']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Medication'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(labelText: 'Dosage'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: freqCtrl,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final prac = context.read<PractitionerAuthCubit>().currentPractitioner;
                final updated = {
                  'name': nameCtrl.text.trim(),
                  'dosage': dosageCtrl.text.trim(),
                  'frequency': freqCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                };
                final docId = medication['id'] as String?;
                if (docId != null) {
                  await PatientLookupService.updateMedicalEntry(
                    widget.patient['medicalNumber'] ?? '',
                    'medication',
                    docId,
                    updated,
                    practitionerUid: prac?.uid,
                  );
                } else {
                  // Create new medication entry
                  final entryData = <String, String>{
                    'name': updated['name'] ?? '',
                    'dosage': updated['dosage'] ?? '',
                    'frequency': updated['frequency'] ?? '',
                    'prescribedBy': prac?.name ?? 'Practitioner',
                    'notes': updated['notes'] ?? '',
                    'timestamp': DateTime.now().toIso8601String(),
                    'addedBy': prac?.name ?? prac?.email ?? 'Unknown Practitioner',
                    if (prac?.uid != null) 'addedByUid': prac!.uid,
                  };
                  await PatientLookupService.addMedicalEntry(
                    widget.patient['medicalNumber'] ?? '',
                    'medication',
                    entryData,
                  );
                }
                if (!mounted) return;
                Navigator.pop(ctx);
                // Refresh record
                context.read<PatientSearchCubit>().getPatientMedicalRecord(
                  widget.patient['medicalNumber'] ?? '',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medication updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Widget _buildAppointments(Map<String, dynamic>? appointments, {bool enableAdd = true}) {
    if (appointments == null) return SizedBox.shrink();

    return _buildSection(
      title: 'Appointments',
      icon: Icons.calendar_today,
      entryType: enableAdd ? 'appointment' : null,
      child: Column(
        children: [
          if (appointments['last'] != null)
            _buildAppointmentItem('Last Visit', appointments['last'], Icons.history),
          if (appointments['next'] != null)
            _buildAppointmentItem('Next Appointment', appointments['next'], Icons.schedule),
          if (appointments['newAppointments'] != null && (appointments['newAppointments'] as List).isNotEmpty) ...[
            Gap(8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'New Appointments',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorManager.green,
                ),
              ),
            ),
            Gap(6.h),
            ...List<Map<String, dynamic>>.from(appointments['newAppointments']).map((a) => _buildAppointmentEditableItem(a)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryEditableItem(Map<String, dynamic> entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.brown.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note_alt, color: Colors.brown, size: 20.w),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry['condition'] != null)
                  Text('Condition: ${entry['condition']}', style: context.textTheme.bodySmall),
                if (entry['diagnosis'] != null)
                  Text('Diagnosis: ${entry['diagnosis']}', style: context.textTheme.bodySmall),
                if (entry['treatment'] != null)
                  Text('Treatment: ${entry['treatment']}', style: context.textTheme.bodySmall),
                if (entry['notes'] != null)
                  Text('Notes: ${entry['notes']}', style: context.textTheme.bodySmall),
              ],
            ),
          ),
          if ((_hasConsent == true) && (entry['id'] != null))
            IconButton(
              tooltip: 'Edit history entry',
              icon: Icon(Icons.edit, color: ColorManager.green, size: 20.w),
              onPressed: () => _editHistory(entry),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentEditableItem(Map<String, dynamic> appt) {
    final date = DateTime.tryParse(appt['date'] ?? '');
    final formattedDate = date != null 
        ? '${date.day}/${date.month}/${date.year}'
        : (appt['date']?.toString() ?? 'Date not available');
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ColorManager.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_note, color: ColorManager.green, size: 20.w),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt['type']?.toString() ?? 'Appointment',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorManager.green,
                  ),
                ),
                Text(
                  formattedDate,
                  style: context.textTheme.bodySmall,
                ),
                if (appt['doctor'] != null)
                  Text(appt['doctor'], style: context.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
          ),
          if ((_hasConsent == true) && (appt['id'] != null))
            IconButton(
              tooltip: 'Edit appointment',
              icon: Icon(Icons.edit, color: ColorManager.green, size: 20.w),
              onPressed: () => _editAppointment(appt),
            ),
        ],
      ),
    );
  }

  Future<void> _editHistory(Map<String, dynamic> entry) async {
    final conditionCtrl = TextEditingController(text: entry['condition']?.toString() ?? '');
    final diagnosisCtrl = TextEditingController(text: entry['diagnosis']?.toString() ?? '');
    final treatmentCtrl = TextEditingController(text: entry['treatment']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: entry['notes']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit History Entry'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: conditionCtrl,
                  decoration: const InputDecoration(labelText: 'Condition'),
                ),
                TextFormField(
                  controller: diagnosisCtrl,
                  decoration: const InputDecoration(labelText: 'Diagnosis'),
                ),
                TextFormField(
                  controller: treatmentCtrl,
                  decoration: const InputDecoration(labelText: 'Treatment'),
                ),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final prac = context.read<PractitionerAuthCubit>().currentPractitioner;
                final updated = {
                  'condition': conditionCtrl.text.trim(),
                  'diagnosis': diagnosisCtrl.text.trim(),
                  'treatment': treatmentCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                };
                await PatientLookupService.updateMedicalEntry(
                  widget.patient['medicalNumber'] ?? '',
                  'history',
                  entry['id'] as String,
                  updated,
                  practitionerUid: prac?.uid,
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                context.read<PatientSearchCubit>().getPatientMedicalRecord(
                  widget.patient['medicalNumber'] ?? '',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _editAppointment(Map<String, dynamic> appt) async {
    final typeCtrl = TextEditingController(text: appt['type']?.toString() ?? '');
    final doctorCtrl = TextEditingController(text: appt['doctor']?.toString() ?? '');
    final dateCtrl = TextEditingController(text: appt['date']?.toString() ?? '');
    final timeCtrl = TextEditingController(text: appt['time']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: appt['notes']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Appointment'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextFormField(
                  controller: doctorCtrl,
                  decoration: const InputDecoration(labelText: 'Doctor'),
                ),
                TextFormField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Date (ISO8601)'),
                ),
                TextFormField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final prac = context.read<PractitionerAuthCubit>().currentPractitioner;
                final updated = {
                  'type': typeCtrl.text.trim(),
                  'doctor': doctorCtrl.text.trim(),
                  'date': dateCtrl.text.trim(),
                  'time': timeCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                };
                await PatientLookupService.updateMedicalEntry(
                  widget.patient['medicalNumber'] ?? '',
                  'appointment',
                  appt['id'] as String,
                  updated,
                  practitionerUid: prac?.uid,
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                context.read<PatientSearchCubit>().getPatientMedicalRecord(
                  widget.patient['medicalNumber'] ?? '',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Widget _buildConsentWarning() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange),
              Gap(8.w),
              Expanded(
                child: Text(
                  'Patient consent required to add or edit records.',
                  style: context.textTheme.bodyMedium?.copyWith(color: Colors.orange[900]),
                ),
              ),
            ],
          ),
          Gap(8.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _requestAccess,
              icon: Icon(Icons.vpn_key),
              label: Text('Request Access'),
              style: ElevatedButton.styleFrom(backgroundColor: ColorManager.green, foregroundColor: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _requestAccess() async {
    if (_practitionerUid == null || (_practitionerName == null && _practitionerEmail == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in as a practitioner to request access.')),
      );
      return;
    }
    final medicalNumber = widget.patient['medicalNumber'] ?? '';
    try {
      await ConsentService.requestAccess(
        medicalNumber: medicalNumber,
        practitionerUid: _practitionerUid!,
        practitionerName: _practitionerName ?? 'Unknown',
        practitionerEmail: _practitionerEmail ?? 'unknown@unknown',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access request sent to patient.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request access: $e')),
      );
    }
  }

  Widget _buildAppointmentItem(String title, Map<String, dynamic> appointment, IconData icon) {
    final date = DateTime.tryParse(appointment['date'] ?? '');
    final formattedDate = date != null 
        ? '${date.day}/${date.month}/${date.year}'
        : 'Date not available';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ColorManager.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: ColorManager.green, size: 20.w),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorManager.green,
                  ),
                ),
                Text(
                  formattedDate,
                  style: context.textTheme.bodySmall,
                ),
                if (appointment['doctor'] != null)
                  Text(
                    appointment['doctor'],
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(String? lastUpdated) {
    if (lastUpdated == null) return SizedBox.shrink();

    final date = DateTime.tryParse(lastUpdated);
    final formattedDate = date != null 
        ? '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
        : 'Unknown';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: Colors.grey, size: 16.w),
          Gap(8.w),
          Text(
            'Last updated: $formattedDate',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    String? entryType,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorManager.green, size: 24.w),
              Gap(8.w),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorManager.green,
                  ),
                ),
              ),
              if (entryType != null)
                IconButton(
                  onPressed: () => _navigateToAddEntry(entryType),
                  icon: Icon(
                    Icons.add_circle,
                    color: ColorManager.green,
                    size: 28.w,
                  ),
                  tooltip: 'Add new $entryType',
                ),
            ],
          ),
          Gap(12.h),
          child,
        ],
      ),
    );
  }

  void _navigateToAddEntry(String entryType) async {
    final result = await Navigator.pushNamed(
      context,
      '/add-medical-entry',
      arguments: {
        'patientId': widget.patient['medicalNumber'],
        'entryType': entryType,
      },
    );

    // Refresh patient data if entry was added
    if (result == true) {
      context.read<PatientSearchCubit>().getPatientMedicalRecord(
        widget.patient['medicalNumber'] ?? '',
      );
    }
  }
}
