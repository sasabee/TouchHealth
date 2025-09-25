import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:touchhealth/data/source/firebase/firebase_service.dart';
import 'package:touchhealth/core/utils/helper/sa_id_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit() : super(SignUpInitial());
  int _ctn = 0;
  final _firestore = FirebaseFirestore.instance;
  Future<void> verifyEmail() async {
    emit(SignUpLoading());
    try {
      await FirebaseService.emailVerify();
      emit(VerifyEmailSuccess());
    } on FirebaseException catch (err) {
      emit(VerifyEmailFailure(errorMessage: err.message ?? err.code));
    }
  }

  Future<void> createEmailAndPassword(
      {required String email, required String password}) async {
    emit(SignUpLoading());
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(CreatePasswordSuccess());
    } on FirebaseAuthException catch (err) {
      emit(CreateProfileFailure(errorMessage: err.message ?? err.code));
    }
  }

  Future<void> createProfile(
      {required String name,
      required String phoneNumber,
      required String dob,
      required String gender,
      required String bloodType,
      required String saId}) async {
    emit(SignUpLoading());
    try {
      // Extract info from SA ID
      final saIdInfo = SAIdValidator.extractInfoFromSAId(saId);
      final medicalRecordNumber = SAIdValidator.generateMedicalRecordNumber(saId);
      
      await FirebaseService.storeUserData(
          name: name,
          phoneNumber: phoneNumber,
          dob: saIdInfo?['dateOfBirth'] ?? dob,
          gender: saIdInfo?['gender'] ?? gender,
          bloodType: bloodType,
          saId: saId,
          medicalRecordNumber: medicalRecordNumber);
      emit(CreateProfileSuccess());
    } on FirebaseException catch (err) {
      emit(CreateProfileFailure(errorMessage: err.message ?? err.code));
    }
  }

  Future<void> checkIfEmailInUse(String emailAddress) async {
    emit(EmailCheckLoading());
    try {
      if (_ctn < 5) {
        final querySnapshot = await _firestore
            .collection('users')
            .where('isActive', isEqualTo: true)
            .get()
            .timeout(const Duration(seconds: 5));
        final isEmailInUse = querySnapshot.docs
            .any((doc) => doc.data()['email'] == emailAddress);
        if (isEmailInUse) {
          _ctn++;
          emit(EmailNotValid());
          log("Email already in use");
        } else {
          emit(EmailValid());
          _ctn = 0;
          log("Email not in use");
        }
      } else {
        Future.delayed(const Duration(seconds: 10), () {
          _ctn = 0;
        });
        emit(EmailNotValid(message: "Too many requests, try again later"));
      }
    } on FirebaseAuthException catch (err) {
      log(err.message.toString());
      emit(EmailNotValid());
    }
  }
}
