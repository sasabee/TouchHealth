import 'dart:developer';

import 'package:touchhealth/core/utils/theme/color.dart';
import 'package:touchhealth/core/router/routes.dart';
import 'package:touchhealth/core/utils/helper/extention.dart';
import 'package:touchhealth/core/utils/helper/scaffold_snakbar.dart';
import 'package:touchhealth/controller/auth/practitioner_auth/practitioner_auth_cubit.dart';
import 'package:touchhealth/view/widget/custom_button.dart';
import 'package:touchhealth/view/widget/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../controller/validation/formvalidation_cubit.dart';
import '../../widget/button_loading_indicator.dart';
import '../../widget/custom_text_span.dart';

class PractitionerLoginScreen extends StatefulWidget {
  const PractitionerLoginScreen({super.key});

  @override
  State<PractitionerLoginScreen> createState() => _PractitionerLoginScreenState();
}

class _PractitionerLoginScreenState extends State<PractitionerLoginScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  String? _hpcsaNumber;
  bool _isLoading = false;
  // Restrict to HPCSA login only
  final bool _useHpcsa = true;

  login() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      context.read<PractitionerAuthCubit>().signInWithHpcsa(
            hpcsaNumber: _hpcsaNumber!,
            password: _password!,
          );
    }
    log("Practitioner HPCSA login pressed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Practitioner Login',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.theme.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Gap(context.height / 10),
                Icon(
                  Icons.medical_services,
                  size: 80.w,
                  color: ColorManager.green,
                ),
                Gap(16.h),
                const CustomTextSpan(
                  textOne: "Healthcare", 
                  textTwo: "Professional Portal"
                ),
                Gap(8.h),
                Text(
                  "Access patient records and manage healthcare data securely.",
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(fontSize: 16.spMin),
                ),
                Gap(20.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: ColorManager.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: ColorManager.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "🩺 Demo Practitioner HPCSA Accounts",
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ColorManager.green,
                        ),
                      ),
                      Gap(8.h),
                      _buildHpcsaDemoRow("Doctor", "MP123456", "doctor123"),
                      Gap(4.h),
                      _buildHpcsaDemoRow("Cardiologist", "MP789012", "doctor123"),
                      Gap(4.h),
                      _buildHpcsaDemoRow("Nurse", "RN345678", "nurse123"),
                    ],
                  ),
                ),
                Gap(20.h),
                _buildHpcsaAndPasswordFields(),
                Gap(32.h),
                BlocConsumer<PractitionerAuthCubit, PractitionerAuthState>(
                  listener: (context, state) async {
                    if (state is PractitionerAuthLoading) {
                      _isLoading = true;
                    }
                    if (state is PractitionerAuthSuccess) {
                      FocusScope.of(context).unfocus();
                      Navigator.pushNamedAndRemoveUntil(
                          context, RouteManager.practitionerDashboard, (route) => false);
                      _isLoading = false;
                    }
                    if (state is PractitionerAuthFailure) {
                      FocusScope.of(context).unfocus();
                      customSnackBar(
                          context, state.message, ColorManager.error);
                      _isLoading = false;
                    }
                  },
                  builder: (context, state) {
                    return CustomButton(
                      title: "Login as Practitioner",
                      isDisabled: _isLoading,
                      widget: _isLoading == true
                          ? const ButtonLoadingIndicator()
                          : null,
                      onPressed: login,
                    );
                  },
                ),
                Gap(16.h),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, RouteManager.login),
                  child: Text(
                    "Switch to Patient Login",
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: ColorManager.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Gap(16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccount(String role, String email, String password) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        children: [
          Icon(
            role == "Nurse" ? Icons.local_hospital : Icons.medical_services,
            size: 16.w,
            color: ColorManager.green,
          ),
          Gap(8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorManager.green,
                    fontSize: 12.spMin,
                  ),
                ),
                Text(
                  "$email | $password",
                  style: context.textTheme.bodySmall?.copyWith(
                    color: ColorManager.green,
                    fontSize: 10.spMin,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHpcsaAndPasswordFields() {
    final cubit = context.read<ValidationCubit>();
    return Column(children: [
      CustomTextFormField(
        keyboardType: TextInputType.text,
        onSaved: (data) {
          _hpcsaNumber = data;
        },
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'HPCSA number is required';
          return null; // accept any non-empty for demo bypass
        },
        hintText: "Enter your HPCSA registration number (e.g., MP123456)",
        title: "HPCSA Number",
      ),
      CustomTextFormField(
        keyboardType: TextInputType.visiblePassword,
        onSaved: (data) {
          _password = data;
        },
        validator: cubit.validatePassword,
        hintText: "Enter your password",
        isVisible: true,
        title: "Password",
      )
    ]);
  }

  Widget _buildHpcsaDemoRow(String role, String hpcsa, String password) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        children: [
          Icon(
            role == "Nurse" ? Icons.local_hospital : Icons.medical_services,
            size: 16.w,
            color: ColorManager.green,
          ),
          Gap(8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorManager.green,
                    fontSize: 12.spMin,
                  ),
                ),
                Text(
                  "$hpcsa | $password",
                  style: context.textTheme.bodySmall?.copyWith(
                    color: ColorManager.green,
                    fontSize: 10.spMin,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
