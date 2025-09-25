import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:touchhealth/core/utils/helper/extention.dart';
import 'package:touchhealth/core/utils/theme/color.dart';
import 'package:touchhealth/core/service/patient_lookup_service.dart';
import 'package:touchhealth/controller/auth/practitioner_auth/practitioner_auth_cubit.dart';

class EditPatientScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  const EditPatientScreen({super.key, required this.patient});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _genderCtrl;
  late final TextEditingController _bloodTypeCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nameCtrl = TextEditingController(text: p['name']?.toString() ?? '');
    _emailCtrl = TextEditingController(text: p['email']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: p['phone']?.toString() ?? '');
    _genderCtrl = TextEditingController(text: p['gender']?.toString() ?? '');
    _bloodTypeCtrl = TextEditingController(text: p['bloodType']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _genderCtrl.dispose();
    _bloodTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final prac = context.read<PractitionerAuthCubit>().currentPractitioner;
      final patientId = widget.patient['medicalNumber']?.toString() ?? '';
      final updated = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'gender': _genderCtrl.text.trim(),
        'bloodType': _bloodTypeCtrl.text.trim(),
      };
      // Remove empty fields to avoid overwriting with blanks
      updated.removeWhere((key, value) => (value is String) ? value.trim().isEmpty : value == null);

      await PatientLookupService.updatePatientDemographics(
        patientId,
        updated,
        practitionerUid: prac?.uid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient profile updated')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.green,
        title: const Text('Edit Patient', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Basic Information'),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20.h),
              _SectionHeader(title: 'Clinical'),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _genderCtrl,
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _bloodTypeCtrl,
                decoration: const InputDecoration(labelText: 'Blood Type (e.g., O+, A-)'),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.edit, color: ColorManager.green, size: 20.w),
        SizedBox(width: 8.w),
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorManager.green,
          ),
        ),
      ],
    );
  }
}
