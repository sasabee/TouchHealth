import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:touchhealth/core/service/consent_service.dart';
import 'package:touchhealth/core/service/blockchain_ledger_service.dart';

class PatientLookupService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com/users';
  static const Duration timeoutDuration = Duration(seconds: 10);
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search for patient by medical number
  static Future<Map<String, dynamic>?> findPatientByMedicalNumber(String medicalNumber) async {
    try {
      dev.log('Searching for patient with medical number: $medicalNumber');
      
      // Check for demo patients first
      if (_isDemoMedicalNumber(medicalNumber)) {
        return _getDemoPatient(medicalNumber);
      }

      // Convert medical number to valid user ID for API call
      int userId = _convertMedicalNumberToUserId(medicalNumber);
      
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return _generatePatientFromUserData(medicalNumber, userData);
      } else {
        throw Exception('Patient not found: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('Error finding patient: $e');
      return null;
    }
  }

  /// Get comprehensive patient medical record by medical number
  static Future<Map<String, dynamic>?> getPatientMedicalRecord(String medicalNumber) async {
    try {
      dev.log('Fetching medical record for medical number: $medicalNumber');
      
      // Check for demo patients - build base record then merge Firestore entries and overrides
      if (_isDemoMedicalNumber(medicalNumber)) {
        final baseRecord = _getDemoPatientRecord(medicalNumber);
        // Merge Firestore entries and patient overrides on top of demo record
        final merged = await _mergeWithFirestoreEntries(baseRecord, medicalNumber);
        return merged;
      }
      
      // For real patients, use the medical record API service
      final patient = await findPatientByMedicalNumber(medicalNumber);
      if (patient == null) return null;

      // Generate comprehensive medical record with new entries
      final random = Random();
      
      // Get existing medications and merge with new entries
      final baseMedications = _generateMedications(random);
      final newMedicationsMemory = _getPatientEntries(medicalNumber, 'medication');
      final newMedicationsFs = await _fetchFirestoreEntries(medicalNumber, 'medications');
      final allMedications = [...baseMedications, ...newMedicationsMemory, ...newMedicationsFs];

      // Get new entries for other types
      final newVitalsMemory = _getPatientEntries(medicalNumber, 'vital');
      final newHistoryMemory = _getPatientEntries(medicalNumber, 'history');
      final newAppointmentsMemory = _getPatientEntries(medicalNumber, 'appointment');

      final newVitalsFs = await _fetchFirestoreEntries(medicalNumber, 'vitals');
      final newHistoryFs = await _fetchFirestoreEntries(medicalNumber, 'history');
      final newAppointmentsFs = await _fetchFirestoreEntries(medicalNumber, 'appointments');

      // Base vitals with new entries appended
      final baseVitals = {
        'bloodPressure': {
          'systolic': 120 + random.nextInt(40),
          'diastolic': 70 + random.nextInt(20),
          'unit': 'mmHg',
          'timestamp': DateTime.now().subtract(Duration(hours: random.nextInt(24))).toIso8601String(),
        },
        'heartRate': {
          'value': 60 + random.nextInt(40),
          'unit': 'bpm',
          'timestamp': DateTime.now().subtract(Duration(hours: random.nextInt(24))).toIso8601String(),
        },
        'temperature': {
          'value': 36.0 + random.nextDouble() * 2,
          'unit': '°C',
          'timestamp': DateTime.now().subtract(Duration(hours: random.nextInt(24))).toIso8601String(),
        },
      };

      // Add new vitals to base vitals
      for (var vital in [...newVitalsMemory, ...newVitalsFs]) {
        baseVitals[vital['type']?.toLowerCase().replaceAll(' ', '') ?? 'custom'] = {
          'value': vital['value'],
          'unit': vital['unit'],
          'timestamp': vital['timestamp'],
          'notes': vital['notes'],
          'addedBy': vital['addedBy'],
        };
      }
      
      return {
        'patient': patient,
        'vitals': baseVitals,
        'medicalHistory': {
          'allergies': _generateAllergies(random),
          'chronicConditions': _generateChronicConditions(random),
          'familyHistory': _generateFamilyHistory(random),
          'newEntries': [...newHistoryMemory, ...newHistoryFs], // Add new history entries
        },
        'medications': allMedications,
        'appointments': {
          'last': {
            'date': DateTime.now().subtract(Duration(days: random.nextInt(30) + 1)).toIso8601String(),
            'doctor': 'Dr. ${['Smith', 'Johnson', 'Williams', 'Brown'][random.nextInt(4)]}',
            'type': 'Regular Checkup',
          },
          'next': {
            'date': DateTime.now().add(Duration(days: random.nextInt(30) + 1)).toIso8601String(),
            'doctor': 'Dr. ${['Smith', 'Johnson', 'Williams', 'Brown'][random.nextInt(4)]}',
            'type': 'Follow-up',
          },
          'newAppointments': [...newAppointmentsMemory, ...newAppointmentsFs], // Add new appointment entries
        },
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      dev.log('Error fetching medical record: $e');
      return null;
    }
  }

  /// Search patients by name (for practitioners)
  static Future<List<Map<String, dynamic>>> searchPatientsByName(String searchQuery) async {
    try {
      dev.log('Searching patients by name: $searchQuery');
      
      List<Map<String, dynamic>> results = [];
      
      // Add demo patients if they match
      final demoPatients = _getAllDemoPatients();
      for (var patient in demoPatients) {
        if (patient['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())) {
          results.add(patient);
        }
      }
      
      // Generate additional patients from API
      for (int i = 1; i <= 5; i++) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/$i'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(timeoutDuration);

          if (response.statusCode == 200) {
            final userData = json.decode(response.body);
            final medicalNumber = 'MED${i.toString().padLeft(6, '0')}';
            
            if (userData['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())) {
              results.add(_generatePatientFromUserData(medicalNumber, userData));
            }
          }
        } catch (e) {
          dev.log('Error fetching patient $i: $e');
        }
      }
      
      return results;
    } catch (e) {
      dev.log('Error searching patients: $e');
      return [];
    }
  }

  // Helper methods
  static bool _isDemoMedicalNumber(String medicalNumber) {
    final demoNumbers = ['MED000001', 'DEMO001', 'MED000002', 'MED000003'];
    return demoNumbers.contains(medicalNumber.toUpperCase());
  }

  static int _convertMedicalNumberToUserId(String medicalNumber) {
    // Extract numbers from medical number
    final numbers = medicalNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbers.isEmpty) {
      return 1;
    }
    
    // Use modulo to ensure ID is between 1-10
    int id = int.parse(numbers) % 10;
    return id == 0 ? 10 : id;
  }

  static Map<String, dynamic> _getDemoPatient(String medicalNumber) {
    switch (medicalNumber.toUpperCase()) {
      case 'MED000001':
      case 'DEMO001':
        return {
          'medicalNumber': 'MED000001',
          'name': 'Mosa Lefu',
          'email': 'mosa.lefu@touchhealth.com',
          'phone': '+27-82-123-4567',
          'age': 28,
          'gender': 'Male',
          'bloodType': 'O+',
          'lastVisit': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          'status': 'Active',
          'loginEmail': 'mosa@touchhealth.com',
          'loginPassword': 'patient123',
        };
      case 'MED000002':
        return {
          'medicalNumber': 'MED000002',
          'name': 'Sarah Johnson',
          'email': 'sarah.johnson@email.com',
          'phone': '+27-82-987-6543',
          'age': 35,
          'gender': 'Female',
          'bloodType': 'A+',
          'lastVisit': DateTime.now().subtract(Duration(days: 15)).toIso8601String(),
          'status': 'Active',
          'loginEmail': 'sarah@touchhealth.com',
          'loginPassword': 'patient123',
        };
      case 'MED000003':
        return {
          'medicalNumber': 'MED000003',
          'name': 'David Williams',
          'email': 'david.williams@email.com',
          'phone': '+27-82-456-7890',
          'age': 42,
          'gender': 'Male',
          'bloodType': 'B+',
          'lastVisit': DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
          'status': 'Active',
          'loginEmail': 'david@touchhealth.com',
          'loginPassword': 'patient123',
        };
      default:
        return _generateFallbackPatient(medicalNumber);
    }
  }

  static List<Map<String, dynamic>> _getAllDemoPatients() {
    return [
      _getDemoPatient('MED000001'),
      _getDemoPatient('MED000002'),
      _getDemoPatient('MED000003'),
    ];
  }

  static Map<String, dynamic> _getDemoPatientRecord(String medicalNumber) {
    final patient = _getDemoPatient(medicalNumber);
    final random = Random(medicalNumber.hashCode);
    
    return {
      'patient': patient,
      'medicalHistory': {
        'allergies': medicalNumber == 'MED000001' ? ['Peanuts'] : _generateAllergies(random),
        'chronicConditions': _generateChronicConditions(random),
        'surgeries': _generateSurgeries(random),
        'familyHistory': _generateFamilyHistory(random),
      },
      'vitals': {
        'bloodPressure': {
          'systolic': 110 + random.nextInt(40),
          'diastolic': 70 + random.nextInt(20),
          'unit': 'mmHg'
        },
        'heartRate': {
          'value': 60 + random.nextInt(40),
          'unit': 'bpm'
        },
        'temperature': {
          'value': 36.0 + (random.nextDouble() * 2),
          'unit': '°C'
        },
      },
      'medications': _generateMedications(random),
      'labs': _generateLabs(random),
      'scans': _generateScans(random),
      'appointments': {
        'last': {
          'date': DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
          'doctor': 'Dr. ${_getRandomName(random)}',
          'department': _getRandomDepartment(random),
        },
        'next': {
          'date': DateTime.now().add(Duration(days: random.nextInt(60) + 7)).toIso8601String(),
          'doctor': 'Dr. ${_getRandomName(random)}',
          'department': _getRandomDepartment(random),
        }
      },
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _generatePatientFromUserData(String medicalNumber, Map<String, dynamic> userData) {
    final random = Random(medicalNumber.hashCode);
    
    return {
      'medicalNumber': medicalNumber,
      'name': userData['name'] ?? 'Unknown Patient',
      'email': userData['email'] ?? 'patient@example.com',
      'phone': userData['phone'] ?? '+1-555-0123',
      'age': 25 + random.nextInt(50),
      'gender': random.nextBool() ? 'Male' : 'Female',
      'bloodType': _getRandomBloodType(random),
      'lastVisit': DateTime.now().subtract(Duration(days: random.nextInt(90))).toIso8601String(),
      'status': 'Active',
    };
  }


  static Map<String, dynamic> _generateComprehensiveMedicalRecord(String medicalNumber, Map<String, dynamic> userData) {
    final patient = _generatePatientFromUserData(medicalNumber, userData);
    final random = Random(medicalNumber.hashCode);
    
    return {
      'patient': patient,
      'medicalHistory': {
        'allergies': _generateAllergies(random),
        'chronicConditions': _generateChronicConditions(random),
        'surgeries': _generateSurgeries(random),
        'familyHistory': _generateFamilyHistory(random),
      },
      'vitals': {
        'bloodPressure': {
          'systolic': 110 + random.nextInt(40),
          'diastolic': 70 + random.nextInt(20),
          'unit': 'mmHg'
        },
        'heartRate': {
          'value': 60 + random.nextInt(40),
          'unit': 'bpm'
        },
        'temperature': {
          'value': 36.0 + (random.nextDouble() * 2),
          'unit': '°C'
        },
      },
      'medications': _generateMedications(random),
      'appointments': {
        'last': {
          'date': DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
          'doctor': 'Dr. ${_getRandomName(random)}',
          'department': _getRandomDepartment(random),
        },
        'next': {
          'date': DateTime.now().add(Duration(days: random.nextInt(60) + 7)).toIso8601String(),
          'doctor': 'Dr. ${_getRandomName(random)}',
          'department': _getRandomDepartment(random),
        }
      },
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _generateFallbackPatient(String medicalNumber) {
    final random = Random(medicalNumber.hashCode);
    
    return {
      'medicalNumber': medicalNumber,
      'name': 'Patient ${medicalNumber}',
      'email': 'patient${medicalNumber}@touchhealth.com',
      'phone': '+27-82-${random.nextInt(900) + 100}-${random.nextInt(9000) + 1000}',
      'age': 25 + random.nextInt(50),
      'gender': random.nextBool() ? 'Male' : 'Female',
      'bloodType': _getRandomBloodType(random),
      'lastVisit': DateTime.now().subtract(Duration(days: random.nextInt(90))).toIso8601String(),
      'status': 'Active',
    };
  }

  // Helper methods for generating realistic medical data
  static String _getRandomBloodType(Random random) {
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    return bloodTypes[random.nextInt(bloodTypes.length)];
  }

  static String _getRandomName(Random random) {
    final firstNames = ['John', 'Jane', 'Michael', 'Sarah', 'David', 'Emily', 'Robert', 'Lisa'];
    final lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis'];
    return '${firstNames[random.nextInt(firstNames.length)]} ${lastNames[random.nextInt(lastNames.length)]}';
  }

  static String _getRandomDepartment(Random random) {
    final departments = ['Cardiology', 'Neurology', 'Orthopedics', 'Dermatology', 'Internal Medicine', 'Pediatrics'];
    return departments[random.nextInt(departments.length)];
  }

  static List<String> _generateAllergies(Random random) {
    final allergies = ['Penicillin', 'Peanuts', 'Shellfish', 'Latex', 'Pollen', 'Dust mites'];
    final count = random.nextInt(3);
    return List.generate(count, (index) => allergies[random.nextInt(allergies.length)]);
  }

  static List<String> _generateChronicConditions(Random random) {
    final conditions = ['Hypertension', 'Diabetes Type 2', 'Asthma', 'Arthritis', 'High Cholesterol'];
    final count = random.nextInt(2);
    return List.generate(count, (index) => conditions[random.nextInt(conditions.length)]);
  }

  static List<Map<String, dynamic>> _generateSurgeries(Random random) {
    final surgeries = ['Appendectomy', 'Gallbladder Removal', 'Knee Replacement', 'Cataract Surgery'];
    final count = random.nextInt(2);
    return List.generate(count, (index) => {
      'procedure': surgeries[random.nextInt(surgeries.length)],
      'date': DateTime.now().subtract(Duration(days: random.nextInt(3650))).toIso8601String(),
      'hospital': 'General Hospital'
    });
  }

  static List<String> _generateFamilyHistory(Random random) {
    final conditions = ['Heart Disease', 'Cancer', 'Diabetes', 'Stroke', 'Alzheimer\'s'];
    final count = random.nextInt(3);
    return List.generate(count, (index) => conditions[random.nextInt(conditions.length)]);
  }

  static List<Map<String, dynamic>> _generateMedications(Random random) {
    final medications = [
      {'name': 'Lisinopril', 'dosage': '10mg', 'frequency': 'Once daily'},
      {'name': 'Metformin', 'dosage': '500mg', 'frequency': 'Twice daily'},
      {'name': 'Atorvastatin', 'dosage': '20mg', 'frequency': 'Once daily'},
      {'name': 'Omeprazole', 'dosage': '20mg', 'frequency': 'Once daily'},
    ];
    final count = random.nextInt(3);
    return List.generate(count, (index) => medications[random.nextInt(medications.length)]);
  }

  static List<Map<String, dynamic>> _generateLabs(Random random) {
    final tests = [
      {'testName': 'Complete Blood Count', 'unit': '', 'referenceRange': 'N/A'},
      {'testName': 'Blood Glucose', 'unit': 'mmol/L', 'referenceRange': '4.0 - 7.0'},
      {'testName': 'Cholesterol (LDL)', 'unit': 'mmol/L', 'referenceRange': '< 3.0'},
    ];
    final count = 1 + random.nextInt(3);
    return List.generate(count, (i) {
      final t = tests[random.nextInt(tests.length)];
      return {
        'testName': t['testName'],
        'resultValue': (4 + random.nextInt(10)).toString(),
        'unit': t['unit'],
        'referenceRange': t['referenceRange'],
        'collectedAt': DateTime.now().subtract(Duration(days: random.nextInt(90))).toIso8601String(),
        'notes': random.nextBool() ? 'No abnormalities detected.' : null,
      };
    });
  }

  static List<Map<String, dynamic>> _generateScans(Random random) {
    final types = ['X-Ray', 'MRI', 'CT Scan', 'Ultrasound'];
    final findings = ['Normal', 'Minor anomaly', 'Requires follow-up', 'Inflammation observed'];
    final count = random.nextInt(2);
    return List.generate(count, (i) => {
      'type': types[random.nextInt(types.length)],
      'findings': findings[random.nextInt(findings.length)],
      'radiologist': 'Dr. ${_getRandomName(random)}',
      'date': DateTime.now().subtract(Duration(days: random.nextInt(180))).toIso8601String(),
      'notes': random.nextBool() ? 'Recommend clinical correlation.' : null,
    });
  }

  // In-memory storage for new medical entries
  static final Map<String, Map<String, List<Map<String, dynamic>>>> _patientEntries = {};

  static Future<void> addMedicalEntry(
    String patientId,
    String entryType,
    Map<String, String> entryData,
  ) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));

    // Initialize patient entries if not exists
    if (!_patientEntries.containsKey(patientId)) {
      _patientEntries[patientId] = {
        'vitals': [],
        'medications': [],
        'appointments': [],
        'history': [],
        'labs': [],
        'scans': [],
      };
    }

    // Convert entry data to proper format based on type
    Map<String, dynamic> formattedEntry;
    
    switch (entryType) {
      case 'vital':
        formattedEntry = {
          'type': entryData['type'],
          'value': entryData['value'],
          'unit': entryData['unit'],
          'notes': entryData['notes'],
          'timestamp': entryData['timestamp'],
          'addedBy': entryData['addedBy'],
        };
        break;
      case 'medication':
        formattedEntry = {
          'name': entryData['name'],
          'dosage': entryData['dosage'],
          'frequency': entryData['frequency'],
          'prescribedBy': entryData['prescribedBy'],
          'notes': entryData['notes'],
          'timestamp': entryData['timestamp'],
          'addedBy': entryData['addedBy'],
        };
        break;
      case 'appointment':
        formattedEntry = {
          'type': entryData['type'],
          'doctor': entryData['doctor'],
          'date': entryData['date'],
          'time': entryData['time'],
          'notes': entryData['notes'],
          'timestamp': entryData['timestamp'],
          'addedBy': entryData['addedBy'],
        };
        break;
      case 'history':
        formattedEntry = {
          'condition': entryData['condition'],
          'diagnosis': entryData['diagnosis'],
          'treatment': entryData['treatment'],
          'notes': entryData['notes'],
          'timestamp': entryData['timestamp'],
          'addedBy': entryData['addedBy'],
        };
        break;
      case 'lab':
        formattedEntry = {
          'testName': entryData['testName'],
          'resultValue': entryData['resultValue'],
          'unit': entryData['unit'],
          'referenceRange': entryData['referenceRange'],
          'collectedAt': entryData['collectedAt'] ?? entryData['timestamp'],
          'notes': entryData['notes'],
          'timestamp': entryData['timestamp'],
          'addedBy': entryData['addedBy'],
        };
        break;
      case 'scan':
        formattedEntry = {
          'type': entryData['type'],
          'findings': entryData['findings'],
          'radiologist': entryData['radiologist'],
          'date': entryData['date'] ?? entryData['timestamp'],
          'notes': entryData['notes'],
          'timestamp': entryData['timestamp'],
          'addedBy': entryData['addedBy'],
        };
        break;
      default:
        throw Exception('Unknown entry type: $entryType');
    }

    // Add to patient entries
    _patientEntries[patientId]![entryType + 's']!.add(formattedEntry);

    // Persist to Firestore under medical_records/{patientId}/{collection}
    final collection = _mapEntryTypeToCollection(entryType);
    final dataToSave = {
      ...formattedEntry,
      'createdAt': DateTime.now().toIso8601String(),
      'entryType': entryType,
    };

    // Enforce consent for practitioner-originated writes
    final practitionerUid = entryData['addedByUid'];
    if (practitionerUid != null && practitionerUid.isNotEmpty) {
      final hasConsent = await ConsentService.hasConsent(
        medicalNumber: patientId,
        practitionerUid: practitionerUid,
      );
      if (!hasConsent) {
        throw Exception('Access denied: Patient consent required to add records.');
      }
    }

    final docRef = await _firestore
        .collection('medical_records')
        .doc(patientId)
        .collection(collection)
        .add(dataToSave);

    // Update parent doc with simple metadata for quick lookups
    await _firestore.collection('medical_records').doc(patientId).set({
      'medicalNumber': patientId,
      'lastUpdated': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // Append tamper-evident ledger entry
    try {
      await BlockchainLedgerService.appendEntry(
        patientId: patientId,
        practitionerId: practitionerUid ?? 'unknown',
        action: 'create',
        entryType: entryType,
        documentId: docRef.id,
        payload: dataToSave,
      );
    } catch (e) {
      dev.log('Ledger append failed: $e');
    }
  }

  static List<Map<String, dynamic>> _getPatientEntries(String patientId, String entryType) {
    if (!_patientEntries.containsKey(patientId)) {
      return [];
    }
    return _patientEntries[patientId]![entryType + 's'] ?? [];
  }

  // Update an existing medical entry (e.g., medication) by document ID
  static Future<void> updateMedicalEntry(
    String patientId,
    String entryType, // 'medication', 'vital', 'appointment', 'history'
    String documentId,
    Map<String, dynamic> updatedFields,
    {
      String? practitionerUid,
    }
  ) async {
    final collection = _mapEntryTypeToCollection(entryType);

    // Enforce consent if practitioner context is provided
    if (practitionerUid != null && practitionerUid.isNotEmpty) {
      final hasConsent = await ConsentService.hasConsent(
        medicalNumber: patientId,
        practitionerUid: practitionerUid,
      );
      if (!hasConsent) {
        throw Exception('Access denied: Patient consent required to update records.');
      }
    }

    // Update Firestore document
    await _firestore
        .collection('medical_records')
        .doc(patientId)
        .collection(collection)
        .doc(documentId)
        .set({...updatedFields, 'updatedAt': DateTime.now().toIso8601String()}, SetOptions(merge: true));

    await _firestore.collection('medical_records').doc(patientId).set({
      'medicalNumber': patientId,
      'lastUpdated': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // Append ledger entry for update
    try {
      await BlockchainLedgerService.appendEntry(
        patientId: patientId,
        practitionerId: practitionerUid ?? 'unknown',
        action: 'update',
        entryType: entryType,
        documentId: documentId,
        payload: updatedFields,
      );
    } catch (e) {
      dev.log('Ledger append failed (update): $e');
    }
  }

  // Map entry type to Firestore subcollection name
  static String _mapEntryTypeToCollection(String entryType) {
    switch (entryType) {
      case 'vital':
        return 'vitals';
      case 'medication':
        return 'medications';
      case 'appointment':
        return 'appointments';
      case 'history':
        return 'history';
      case 'lab':
        return 'labs';
      case 'scan':
        return 'scans';
      default:
        return 'entries';
    }
  }

  // Fetch entries from Firestore for a given patient and collection
  static Future<List<Map<String, dynamic>>> _fetchFirestoreEntries(
    String patientId,
    String collection,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('medical_records')
          .doc(patientId)
          .collection(collection)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((d) => {
        'id': d.id,
        ...d.data(),
      }).toList();
    } catch (e) {
      dev.log('Error fetching Firestore entries for $patientId/$collection: $e');
      return [];
    }
  }

  // Merge Firestore entries into a base record (used for demo patients as well)
  static Future<Map<String, dynamic>> _mergeWithFirestoreEntries(
    Map<String, dynamic> baseRecord,
    String medicalNumber,
  ) async {
    try {
      // Fetch patient overrides from parent document
      final parentDoc = await _firestore.collection('medical_records').doc(medicalNumber).get();
      Map<String, dynamic> overrides = {};
      if (parentDoc.exists) {
        final data = parentDoc.data();
        if (data != null && data['patientOverrides'] is Map<String, dynamic>) {
          overrides = Map<String, dynamic>.from(data['patientOverrides'] as Map);
        }
      }

      final vitalsFs = await _fetchFirestoreEntries(medicalNumber, 'vitals');
      final medsFs = await _fetchFirestoreEntries(medicalNumber, 'medications');
      final apptsFs = await _fetchFirestoreEntries(medicalNumber, 'appointments');
      final historyFs = await _fetchFirestoreEntries(medicalNumber, 'history');
      final labsFs = await _fetchFirestoreEntries(medicalNumber, 'labs');
      final scansFs = await _fetchFirestoreEntries(medicalNumber, 'scans');

      // Merge vitals: add/override with custom vitals
      final vitals = (baseRecord['vitals'] as Map<String, dynamic>? ?? {});
      for (var vital in vitalsFs) {
        final key = (vital['type']?.toString() ?? 'custom').toLowerCase().replaceAll(' ', '');
        vitals[key] = {
          'id': vital['id'],
          'value': vital['value'],
          'unit': vital['unit'],
          'timestamp': vital['timestamp'],
          'notes': vital['notes'],
          'addedBy': vital['addedBy'],
        };
      }

      // Merge medications: append
      final medications = List<Map<String, dynamic>>.from(baseRecord['medications'] ?? []);
      medications.addAll(medsFs);

      final labs = List<Map<String, dynamic>>.from(baseRecord['labs'] ?? []);
      labs.addAll(labsFs);

      // Merge appointments: append under newAppointments
      final appointments = Map<String, dynamic>.from(baseRecord['appointments'] ?? {});
      final newAppts = List<Map<String, dynamic>>.from(appointments['newAppointments'] ?? []);
      newAppts.addAll(apptsFs);
      appointments['newAppointments'] = newAppts;

      // Merge history: append under newEntries
      final medicalHistory = Map<String, dynamic>.from(baseRecord['medicalHistory'] ?? {});
      final newHist = List<Map<String, dynamic>>.from(medicalHistory['newEntries'] ?? []);
      newHist.addAll(historyFs);
      medicalHistory['newEntries'] = newHist;

      final scans = List<Map<String, dynamic>>.from(baseRecord['scans'] ?? []);
      scans.addAll(scansFs);

      // Merge patient overrides on top of patient object if present
      final patient = Map<String, dynamic>.from(baseRecord['patient'] ?? {});
      if (overrides.isNotEmpty) {
        patient.addAll(overrides);
      }

      return {
        ...baseRecord,
        'patient': patient,
        'vitals': vitals,
        'medications': medications,
        'labs': labs,
        'scans': scans,
        'appointments': appointments,
        'medicalHistory': medicalHistory,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      dev.log('Error merging Firestore entries: $e');
      return baseRecord;
    }
  }

  /// Update patient demographic fields. Stores overrides in parent doc and appends ledger entry.
  static Future<void> updatePatientDemographics(
    String patientId,
    Map<String, dynamic> updatedFields, {
    String? practitionerUid,
  }) async {
    // Enforce consent when practitioner context provided
    if (practitionerUid != null && practitionerUid.isNotEmpty) {
      final hasConsent = await ConsentService.hasConsent(
        medicalNumber: patientId,
        practitionerUid: practitionerUid,
      );
      if (!hasConsent) {
        throw Exception('Access denied: Patient consent required to update demographics.');
      }
    }

    // Persist overrides on parent document
    await _firestore.collection('medical_records').doc(patientId).set({
      'patientOverrides': updatedFields,
      'medicalNumber': patientId,
      'lastUpdated': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // Append ledger entry
    try {
      await BlockchainLedgerService.appendEntry(
        patientId: patientId,
        practitionerId: practitionerUid ?? 'unknown',
        action: 'update',
        entryType: 'patient',
        documentId: 'patient_overrides',
        payload: updatedFields,
      );
    } catch (e) {
      dev.log('Ledger append failed (update demographics): $e');
    }
  }
}
