import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:touchhealth/core/service/patient_lookup_service.dart';

/// Service to link Firebase authenticated users with their medical records
class PatientDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current logged-in patient's medical record number
  static Future<String?> getCurrentPatientMedicalNumber() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        
        // Return medical record number if it exists
        if (userData.containsKey('medicalRecordNumber') && 
            userData['medicalRecordNumber'] != null &&
            userData['medicalRecordNumber'].toString().isNotEmpty) {
          return userData['medicalRecordNumber'];
        }
        
        // Fallback: try to match by email with demo patients
        final email = currentUser.email;
        if (email != null) {
          final medicalNumber = _getPatientMedicalNumberByEmail(email);
          if (medicalNumber != null) {
            // Update user document with medical record number
            await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .update({'medicalRecordNumber': medicalNumber});
            return medicalNumber;
          }
        }
      }

      return null;
    } catch (e) {
      dev.log('Error getting current patient medical number: $e');
      return null;
    }
  }

  /// Match email with demo patient medical numbers
  static String? _getPatientMedicalNumberByEmail(String email) {
    final demoPatients = {
      'mosa@touchhealth.com': 'MED000001',
      'sarah@touchhealth.com': 'MED000002', 
      'david@touchhealth.com': 'MED000003',
    };
    
    return demoPatients[email.toLowerCase()];
  }

  /// Get current patient's full medical record
  static Future<Map<String, dynamic>?> getCurrentPatientMedicalRecord() async {
    try {
      final medicalNumber = await getCurrentPatientMedicalNumber();
      if (medicalNumber == null) return null;

      return await PatientLookupService.getPatientMedicalRecord(medicalNumber);
    } catch (e) {
      dev.log('Error getting current patient medical record: $e');
      return null;
    }
  }

  /// Check if current user is a demo patient
  static Future<bool> isCurrentUserDemoPatient() async {
    final currentUser = _auth.currentUser;
    if (currentUser?.email == null) return false;
    
    final demoEmails = [
      'mosa@touchhealth.com',
      'sarah@touchhealth.com', 
      'david@touchhealth.com'
    ];
    
    return demoEmails.contains(currentUser!.email!.toLowerCase());
  }

  /// Get patient info for practitioner lookup
  static Future<Map<String, dynamic>?> getPatientInfoForPractitioner(String email) async {
    try {
      // First check if it's a demo patient
      final medicalNumber = _getPatientMedicalNumberByEmail(email);
      if (medicalNumber != null) {
        return await PatientLookupService.findPatientByMedicalNumber(medicalNumber);
      }

      // Search in Firebase users collection
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        
        // Convert Firebase user data to patient format
        return {
          'medicalNumber': userData['medicalRecordNumber'] ?? 'Unknown',
          'name': userData['name'] ?? 'Unknown Patient',
          'email': userData['email'] ?? email,
          'phone': userData['phoneNumber'] ?? '',
          'age': _calculateAge(userData['dob']),
          'gender': userData['gender'] ?? 'Unknown',
          'bloodType': userData['bloodType'] ?? 'Unknown',
          'lastVisit': userData['date'] ?? DateTime.now().toIso8601String(),
          'status': userData['isActive'] == true ? 'Active' : 'Inactive',
        };
      }

      return null;
    } catch (e) {
      dev.log('Error getting patient info for practitioner: $e');
      return null;
    }
  }

  /// Calculate age from date of birth string
  static int _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 0;
    
    try {
      DateTime birthDate = DateTime.parse(dob);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      
      if (today.month < birthDate.month || 
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      
      return age;
    } catch (e) {
      return 0;
    }
  }
}
