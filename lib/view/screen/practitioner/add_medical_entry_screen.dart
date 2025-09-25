import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:touchhealth/controller/practitioner/patient_search_cubit.dart';
import 'package:touchhealth/controller/auth/practitioner_auth/practitioner_auth_cubit.dart';
import 'package:touchhealth/core/utils/theme/color.dart';
import 'package:touchhealth/view/widget/custom_text_field.dart';

class AddMedicalEntryScreen extends StatefulWidget {
  final String patientId;
  final String entryType; // 'vital', 'medication', 'appointment', 'history'

  const AddMedicalEntryScreen({
    super.key,
    required this.patientId,
    required this.entryType,
  });

  @override
  State<AddMedicalEntryScreen> createState() => _AddMedicalEntryScreenState();
}

class _AddMedicalEntryScreenState extends State<AddMedicalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    switch (widget.entryType) {
      case 'vital':
        _controllers['type'] = TextEditingController();
        _controllers['value'] = TextEditingController();
        _controllers['unit'] = TextEditingController();
        _controllers['notes'] = TextEditingController();
        break;
      case 'medication':
        _controllers['name'] = TextEditingController();
        _controllers['dosage'] = TextEditingController();
        _controllers['frequency'] = TextEditingController();
        _controllers['prescribedBy'] = TextEditingController();
        _controllers['notes'] = TextEditingController();
        break;
      case 'appointment':
        _controllers['type'] = TextEditingController();
        _controllers['doctor'] = TextEditingController();
        _controllers['date'] = TextEditingController();
        _controllers['time'] = TextEditingController();
        _controllers['notes'] = TextEditingController();
        break;
      case 'history':
        _controllers['condition'] = TextEditingController();
        _controllers['diagnosis'] = TextEditingController();
        _controllers['treatment'] = TextEditingController();
        _controllers['notes'] = TextEditingController();
        break;
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  String get _screenTitle {
    switch (widget.entryType) {
      case 'vital':
        return 'Add Vital Signs';
      case 'medication':
        return 'Add Medication';
      case 'appointment':
        return 'Add Appointment';
      case 'history':
        return 'Add Medical History';
      case 'lab':
        return 'Add Lab Result';
      case 'scan':
        return 'Add Scan';
      default:
        return 'Add Entry';
    }
  }

  Widget _buildVitalForm() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _controllers['type']!,
          hintText: 'Vital Type (e.g., Blood Pressure, Heart Rate)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['value']!,
          hintText: 'Value (e.g., 120/80, 72)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['unit']!,
          hintText: 'Unit (e.g., mmHg, bpm)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['notes']!,
          hintText: 'Notes (optional)',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildMedicationForm() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _controllers['name']!,
          hintText: 'Medication Name',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['dosage']!,
          hintText: 'Dosage (e.g., 10mg, 2 tablets)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['frequency']!,
          hintText: 'Frequency (e.g., Twice daily, As needed)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['prescribedBy']!,
          hintText: 'Prescribed By',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['notes']!,
          hintText: 'Notes (optional)',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildAppointmentForm() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _controllers['type']!,
          hintText: 'Appointment Type (e.g., Follow-up, Consultation)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['doctor']!,
          hintText: 'Doctor/Practitioner',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['date']!,
          hintText: 'Date (DD/MM/YYYY)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['time']!,
          hintText: 'Time (HH:MM)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['notes']!,
          hintText: 'Notes (optional)',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildHistoryForm() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _controllers['condition']!,
          hintText: 'Medical Condition',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['diagnosis']!,
          hintText: 'Diagnosis',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['treatment']!,
          hintText: 'Treatment/Intervention',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _controllers['notes']!,
          hintText: 'Additional Notes (optional)',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildForm() {
    switch (widget.entryType) {
      case 'vital':
        return _buildVitalForm();
      case 'medication':
        return _buildMedicationForm();
      case 'appointment':
        return _buildAppointmentForm();
      case 'history':
        return _buildHistoryForm();
      case 'lab':
        return _buildLabForm();
      case 'scan':
        return _buildScanForm();
      default:
        return Container();
    }
  }

  Widget _buildLabForm() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _ensure('testName'),
          hintText: 'Test Name (e.g., Blood Glucose, CBC)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _ensure('resultValue'),
          hintText: 'Result Value (e.g., 5.5)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _ensure('unit'),
          hintText: 'Unit (e.g., mmol/L)',
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _ensure('referenceRange'),
          hintText: 'Reference Range (e.g., 4.0 - 7.0)',
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _ensure('collectedAt'),
          hintText: 'Collected At (ISO8601, optional)',
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _ensure('notes'),
          hintText: 'Notes (optional)',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildScanForm() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _ensure('type'),
          hintText: 'Scan Type (e.g., X-Ray, MRI)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _ensure('findings'),
          hintText: 'Findings (e.g., Normal, Minor anomaly)',
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _ensure('radiologist'),
          hintText: 'Radiologist (optional)',
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _ensure('date'),
          hintText: 'Date (ISO8601, optional)',
        ),
        SizedBox(height: 16.h),
        CustomTextFormField(
          controller: _ensure('notes'),
          hintText: 'Notes (optional)',
          maxLines: 3,
        ),
      ],
    );
  }

  TextEditingController _ensure(String key) {
    return _controllers.putIfAbsent(key, () => TextEditingController());
  }

  void _saveEntry() {
    if (_formKey.currentState?.validate() == true) {
      final entryData = <String, String>{};
      _controllers.forEach((key, controller) {
        entryData[key] = controller.text.trim();
      });

      // Add timestamp
      entryData['timestamp'] = DateTime.now().toIso8601String();
      final authCubit = context.read<PractitionerAuthCubit>();
      final practitioner = authCubit.currentPractitioner;
      entryData['addedBy'] = practitioner?.name ?? practitioner?.email ?? 'Unknown Practitioner';
      if (practitioner != null) {
        entryData['addedByUid'] = practitioner.uid;
        entryData['addedByEmail'] = practitioner.email;
      }

      context.read<PatientSearchCubit>().addMedicalEntry(
        widget.patientId,
        widget.entryType,
        entryData,
      );

      Navigator.pop(context, true); // Return true to indicate entry was added
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: ColorManager.green,
        title: Text(
          _screenTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<PatientSearchCubit, PatientSearchState>(
        listener: (context, state) {
          if (state is PatientSearchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding entry: ${state.message}'),
                backgroundColor: ColorManager.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: ColorManager.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: ColorManager.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ColorManager.green,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Adding new ${widget.entryType} entry for patient ${widget.patientId}',
                          style: TextStyle(
                            color: ColorManager.green,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                _buildForm(),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.black,
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: BlocBuilder<PatientSearchCubit, PatientSearchState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed: state is PatientSearchLoading ? null : _saveEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(state is PatientSearchLoading ? 'Saving...' : 'Save Entry'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
