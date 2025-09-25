import 'dart:developer';

import 'package:touchhealth/core/utils/theme/color.dart';
import 'package:touchhealth/core/router/routes.dart';
import 'package:touchhealth/core/utils/helper/extention.dart';
import 'package:touchhealth/core/utils/helper/scaffold_snakbar.dart';
import 'package:touchhealth/controller/auth/sign_in/sign_in_cubit.dart';
import 'package:touchhealth/view/screen/auth/forget_password.dart';
import 'package:touchhealth/view/widget/custom_button.dart';
import 'package:touchhealth/view/widget/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../controller/chat/chat_cubit.dart';
import '../../../controller/validation/formvalidation_cubit.dart';
import '../../widget/button_loading_indicator.dart';
import '../../widget/custom_sign_up_button.dart';
import '../../widget/custom_text_span.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;
  bool _isLoading = false;
  login() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      context
          .bloc<SignInCubit>()
          .userSignIn(email: _email!, password: _password!);
    }
    log("on pressed");
  }

  void _showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Email Verification Required'),
          content: Text(
            'Please check your email and click the verification link. After verifying, try logging in again.\n\nDidn\'t receive the email?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                  customSnackBar(context, 
                    'Verification email sent again! Check your inbox.', 
                    ColorManager.green, 5);
                } catch (e) {
                  customSnackBar(context, 
                    'Failed to send verification email. Try again later.', 
                    ColorManager.error, 5);
                }
              },
              child: Text('Resend Email'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Gap(context.height / 7),
                const CustomTextSpan(textOne: "Touch in.", textTwo: "Feel better."),
                Gap(8.h),
                Text(
                  "Please enter your email & password to access your account.",
                  textAlign: TextAlign.center,
                  style:
                      context.textTheme.bodySmall?.copyWith(fontSize: 16.spMin),
                ),
                Gap(12.h),
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
                        "🚀 Demo Login",
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ColorManager.green,
                        ),
                      ),
                      Gap(4.h),
                      Text(
                        "Email: demo@touchhealth.com\nPassword: demo123",
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: ColorManager.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(20.h),
                Gap(20.h),
                _buildEmailAndPasswordFields(),
                Gap(12.h),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: GestureDetector(
                    onTap: () => showForgetPasswordBottomSheet(context),
                    child: Text(
                      "Forgot Password?",
                      style: context.textTheme.displaySmall,
                    ),
                  ),
                ),
                Gap(32.h),
                BlocConsumer<SignInCubit, SignInState>(
                  listener: (context, state) async {
                    if (state is SignInLoading) {
                      _isLoading = true;
                    }
                    if (state is SignInSuccess) {
                      context.bloc<ChatCubit>().initHive();
                      FocusScope.of(context).unfocus();
                      Navigator.pushNamedAndRemoveUntil(
                          context, RouteManager.nav, (route) => false);
                      _isLoading = false;
                    }
                    if (state is EmailNotVerified) {
                      _isLoading = false;
                      FocusScope.of(context).unfocus();
                      customSnackBar(
                          context, state.message, ColorManager.green, 8);
                      // Show dialog with resend option
                      _showEmailVerificationDialog(context);
                    }
                    if (state is SignInFailure) {
                      FocusScope.of(context).unfocus();
                      customSnackBar(
                          context, state.message, ColorManager.error);
                      _isLoading = false;
                    }
                  },
                  builder: (context, state) {
                    return CustomButton(
                      title: "Login",
                      isDisabled: _isLoading,
                      widget: _isLoading == true
                          ? const ButtonLoadingIndicator()
                          : null,
                      onPressed: login,
                    );
                  },
                ),
                Gap(16.h),
                SignUpButton(
                  title: "Sign Up",
                  onTap: () => Navigator.pushNamed(context, RouteManager.email),
                ),
                Gap(24.h),
                // const CustomDivider(title: "Log in with"),
                // Gap(16.h),
                // const SocialLoginCard(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.medical_services, color: Colors.blue, size: 16.w),
                    Gap(8.w),
                    Text(
                      "Healthcare Professional?",
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Gap(8.h),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, RouteManager.practitionerLogin),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                  child: Text(
                    "Access Practitioner Portal",
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
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

  Widget _buildEmailAndPasswordFields() {
    final cubit = context.bloc<ValidationCubit>();
    return Column(children: [
      CustomTextFormField(
        keyboardType: TextInputType.emailAddress,
        onSaved: (data) {
          _email = data;
        },
        validator: cubit.validateEmail,
        hintText: "Enter your Email",
        title: "Email",
      ),
      CustomTextFormField(
        keyboardType: TextInputType.visiblePassword,
        onSaved: (data) {
          _password = data;
        },
        validator: cubit.validatePassword,
        hintText: "Enter Your Password",
        isVisible: true,
        title: "Password",
      )
    ]);
  }
}
