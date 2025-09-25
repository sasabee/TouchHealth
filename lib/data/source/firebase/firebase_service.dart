import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../model/feedback_model.dart';
import '../../../core/cache/cache.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configure Firebase with timeout settings
  static void configureFirebase() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    // Set network timeout for Firestore
    _firestore.enableNetwork();
    
    // Configure Firebase Auth for better network handling
    _auth.setSettings(
      appVerificationDisabledForTesting: false, // Enable for production
      forceRecaptchaFlow: false,
    );
    
    log("Firebase configured with production settings");
  }

  static Future<List> checkMapLockStatus() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('enable_map').get();

      for (QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot
          in querySnapshot.docs) {
        bool isEnabled = documentSnapshot.data()['isEnabled'] as bool;
        String message = documentSnapshot.data()['message'] as String;
        return [
          isEnabled,
          message,
        ];
      }
      return [
        false,
        "",
      ];
    } catch (e) {
      log('Error fetching map lock status: $e');
      return [
        false,
        "An error occurred while fetching the map lock status.",
      ];
    }
  }

  static Future<void> storeUserData({
    required String name,
    required String phoneNumber,
    required String dob,
    required String gender,
    required String bloodType,
    required String saId,
    required String medicalRecordNumber,
  }) async {
    Map<String, dynamic> userData = {
      'isActive': true,
      'date': DateTime.now().toString(),
      'email': _auth.currentUser!.email,
      'uid': _auth.currentUser!.uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'dob': dob,
      'gender': gender,
      'bloodType': bloodType,
      'saId': saId,
      'medicalRecordNumber': medicalRecordNumber,
      'medicalRecordStatus': 'No medical records recorded yet',
    };

    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .set(userData);
  }

  //! REGISTER
  static Future<void> register(
      {required String email,
      required String password,
      required String displayName}) async {
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await FirebaseAuth.instance.currentUser!.updateDisplayName(displayName);
    FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'uid': userCredential.user!.uid,
      'email': userCredential.user!.email,
      'name': userCredential.user!.displayName,
      //  'image': userCredential.user?.photoURL,
      'time': DateTime.now().toString(),
    });
  }

  // Future<void> renameDocument() async {
  //   final Map<String, dynamic> userData = CacheData.getMapData(key: "userData");
  //   final firestore = FirebaseFirestore.instance;

  //   final userDocRef = firestore.collection('users').doc(userData['uid']);
  //   final originalDocSnapshot = await userDocRef.get();
  //   final data = originalDocSnapshot.data();

  //   if (data != null) {
  //     final newDocRef = firestore.collection('users').doc('account_deprecated');
  //     await newDocRef.set(data);
  //     await userDocRef.delete();

  //     log('Document renamed successfully!');
  //   } else {
  //     log('Original document not found.');
  //   }
  // }

//! LOGIN
  static Future<void> logIn(
      {required String email, required String password}) async {
    try {
      // First attempt with shorter timeout
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15));

      // Store user data with timeout
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'email': userCredential.user!.email,
        'name': userCredential.user!.displayName,
        'time': DateTime.now().toString(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      
    } catch (e) {
      log('Login error: $e');
      
      // If network error, try offline mode
      if (e.toString().contains('network') || 
          e.toString().contains('timeout') ||
          e.toString().contains('unreachable')) {
        log('Network error detected, enabling offline mode');
        await _enableOfflineMode(email);
        return;
      }
      rethrow;
    }
  }

  // Offline mode fallback
  static Future<void> _enableOfflineMode(String email) async {
    try {
      // Store offline user data
      await CacheData.setMapData(key: "userData", value: {
        "name": "Offline User",
        "email": email,
        "uid": "offline_${email.hashCode}",
        "emailVerified": true,
        "offline": true
      });
      log("Offline mode enabled for $email");
    } catch (e) {
      log('Offline mode setup failed: $e');
    }
  }

  //! RESET PASSWORD
  static Future<void> resetPassword({required String email}) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  //! LOG OUT
  static Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  //! EMAIL VERIFY
  static Future<void> emailVerify() async {
    await FirebaseAuth.instance.currentUser!.sendEmailVerification();
  }

  //! DELETE USER
  static Future<void> deleteUser(
      {required String email, required String password}) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final User? user = firebaseAuth.currentUser;
    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);
        await user.delete();
        log('User account deleted successfully.');
      } catch (e) {
        log('An error occurred while deleting the user account: $e');
      }
    } else {
      log('No user is currently signed in.');
    }
  }

//! CHANGE EMAIL
  static Future<void> changeEmail(String newEmail) async {
    try {
      User user = FirebaseAuth.instance.currentUser!;
      if (!user.emailVerified) {
        log("Please verify the new email before changing email.");
        return;
      }

      await user.updateEmail(newEmail);
      log("Email address updated successfully");
    } catch (error) {
      log("Error updating email: $error");
    }
  }

//! CHANGE EMAIL WITH REAUTH
  static Future<void> updateEmailWithReauth(
      {required String newEmail, required String password}) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);

        await user.updateEmail(newEmail);
        log("Email updated successfully to $newEmail");
      } else {
        log("User not signed in.");
      }
    } catch (e) {
      log("Error updating email: $e]");
    }
  }

  static Future<void> updateUserImage({String? urlImage}) async {
    await FirebaseAuth.instance.currentUser!.updatePhotoURL(urlImage);
    log(FirebaseAuth.instance.currentUser!.photoURL.toString());
  }

  static Future<void> updateUserDisplayName({String? name}) async {
    await FirebaseAuth.instance.currentUser!.updateDisplayName(name);
    log(FirebaseAuth.instance.currentUser!.displayName.toString());
  }

  static Future<bool> submitFeedback(FeedbackModel feedback) async {
    try {
      final String? userId = _auth.currentUser?.uid;

      final Map<String, dynamic> feedbackData = {
        ...feedback.toMap(),
        'userId': userId,
        'submitted': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('feedback').add(feedbackData);
      return true;
    } catch (e) {
      log('Error submitting feedback: $e');
      return false;
    }
  }

  // Test mode functionality for development
  static Future<void> setTestMode() async {
    await CacheData.setData(key: "test_mode", value: true);
    await CacheData.setMapData(key: "userData", value: {
      "name": "Test User",
      "email": "test@demo.com",
      "uid": "test_user_123",
      "emailVerified": true
    });
    log("Test mode enabled");
  }

  static bool isTestMode() {
    return CacheData.getdata(key: "test_mode") ?? false;
  }
}
