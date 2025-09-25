import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:http/http.dart' as http;

class MedicalRecordApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com/users';
  static const Duration timeoutDuration = Duration(seconds: 10);

  /// Get patient medical record by ID
  static Future<Map<String, dynamic>> getPatientRecord(String patientId) async {
    try {
      dev.log('Fetching medical record for patient ID: $patientId');
      
      // Check if this is our demo patient "Mosa Lefu"
      if (patientId.toLowerCase().contains('mosa') || patientId.toLowerCase().contains('lefu') || patientId == 'DEMO001') {
        return _generateMosaLefuRecord(patientId);
      }
      
      // Convert patientId to valid user ID (1-10 for JSONPlaceholder)
      int userId = _convertToValidUserId(patientId);
      
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        
        // Generate comprehensive medical record
        final medicalRecord = _generateMedicalRecord(patientId, userData);
        
        dev.log('Successfully generated medical record for patient: ${medicalRecord['patient']['name']}');
        return medicalRecord;
      } else {
        throw Exception('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      dev.log('Error fetching medical record: $e');
      
      // Return fallback medical record
      return _generateFallbackRecord(patientId);
    }
  }

  /// Convert any patient ID to valid user ID (1-10)
  static int _convertToValidUserId(String patientId) {
    // Extract numbers from patient ID
    final numbers = patientId.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbers.isEmpty) {
      return 1; // Default to user 1
    }
    
    // Use modulo to ensure ID is between 1-10
    int id = int.parse(numbers) % 10;
    return id == 0 ? 10 : id;
  }

  /// Generate comprehensive medical record
  static Map<String, dynamic> _generateMedicalRecord(String patientId, Map<String, dynamic> userData) {
    final random = Random(patientId.hashCode); // Consistent data per ID
    
    return {
      'patientId': patientId,
      'recordId': 'MED-${patientId.toUpperCase()}',
      'timestamp': DateTime.now().toIso8601String(),
      
      // Patient Information
      'patient': {
        'name': userData['name'] ?? 'Unknown Patient',
        'email': userData['email'] ?? 'patient@example.com',
        'phone': userData['phone'] ?? '+1-555-0123',
        'username': userData['username'] ?? 'patient${patientId}',
        'website': userData['website'] ?? 'www.patient-portal.com',
        'address': {
          'street': userData['address']?['street'] ?? '123 Medical St',
          'suite': userData['address']?['suite'] ?? 'Apt. 1',
          'city': userData['address']?['city'] ?? 'Healthcare City',
          'zipcode': userData['address']?['zipcode'] ?? '12345-6789',
          'geo': {
            'lat': userData['address']?['geo']?['lat'] ?? '40.7128',
            'lng': userData['address']?['geo']?['lng'] ?? '-74.0060'
          }
        },
        'company': {
          'name': userData['company']?['name'] ?? 'Healthcare Corp',
          'catchPhrase': userData['company']?['catchPhrase'] ?? 'Your health is our priority',
          'bs': userData['company']?['bs'] ?? 'comprehensive healthcare solutions'
        }
      },
      
      // Medical Information
      'medical': {
        'age': 25 + (random.nextInt(50)), // Age 25-75
        'gender': random.nextBool() ? 'Male' : 'Female',
        'bloodType': _getRandomBloodType(random),
        'height': '${160 + random.nextInt(40)} cm', // 160-200 cm
        'weight': '${50 + random.nextInt(50)} kg', // 50-100 kg
        'emergencyContact': {
          'name': _getRandomName(random),
          'phone': '+1-555-${random.nextInt(9000) + 1000}',
          'relationship': _getRandomRelationship(random)
        }
      },
      
      // Vital Signs
      'vitals': {
        'bloodPressure': {
          'systolic': 110 + random.nextInt(40), // 110-150
          'diastolic': 70 + random.nextInt(20), // 70-90
          'unit': 'mmHg'
        },
        'heartRate': {
          'value': 60 + random.nextInt(40), // 60-100 bpm
          'unit': 'bpm'
        },
        'temperature': {
          'value': 36.0 + (random.nextDouble() * 2), // 36-38°C
          'unit': '°C'
        },
        'oxygenSaturation': {
          'value': 95 + random.nextInt(6), // 95-100%
          'unit': '%'
        },
        'respiratoryRate': {
          'value': 12 + random.nextInt(8), // 12-20 breaths/min
          'unit': 'breaths/min'
        }
      },
      
      // Medical History
      'medicalHistory': {
        'allergies': _generateAllergies(random),
        'chronicConditions': _generateChronicConditions(random),
        'surgeries': _generateSurgeries(random),
        'familyHistory': _generateFamilyHistory(random)
      },
      
      // Current Medications
      'medications': _generateMedications(random),
      
      // Recent Lab Results
      'labResults': _generateLabResults(random),
      
      // Appointments
      'appointments': {
        'last': {
          'date': DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
          'doctor': 'Dr. ${_getRandomName(random)}',
          'department': _getRandomDepartment(random),
          'notes': 'Regular checkup completed successfully'
        },
        'next': {
          'date': DateTime.now().add(Duration(days: random.nextInt(60) + 7)).toIso8601String(),
          'doctor': 'Dr. ${_getRandomName(random)}',
          'department': _getRandomDepartment(random),
          'notes': 'Follow-up appointment scheduled'
        }
      },
      
      // Insurance Information
      'insurance': {
        'provider': _getRandomInsurance(random),
        'policyNumber': 'POL-${random.nextInt(900000) + 100000}',
        'groupNumber': 'GRP-${random.nextInt(9000) + 1000}',
        'effectiveDate': DateTime.now().subtract(Duration(days: random.nextInt(365))).toIso8601String()
      },
      
      // Status
      'status': {
        'active': true,
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': '1.0'
      }
    };
  }

  /// Generate demo record for Mosa Lefu
  static Map<String, dynamic> _generateMosaLefuRecord(String patientId) {
    return {
      'patientId': patientId,
      'recordId': 'MED-DEMO001',
      'timestamp': DateTime.now().toIso8601String(),
      
      // Patient Information
      'patient': {
        'name': 'Mosa Lefu',
        'email': 'mosa.lefu@touchhealth.com',
        'phone': '+27-82-123-4567',
        'username': 'mosalefu',
        'website': 'www.touchhealth.com',
        'address': {
          'street': '123 Health Avenue',
          'suite': 'Suite 101',
          'city': 'Cape Town',
          'zipcode': '8001',
          'geo': {
            'lat': '-33.9249',
            'lng': '18.4241'
          }
        },
        'company': {
          'name': 'TouchHealth Technologies',
          'catchPhrase': 'Revolutionizing healthcare with technology',
          'bs': 'digital health solutions'
        }
      },
      
      // Medical Information
      'medical': {
        'age': 28,
        'gender': 'Male',
        'bloodType': 'O+',
        'height': '178 cm',
        'weight': '75 kg',
        'emergencyContact': {
          'name': 'Sarah Lefu',
          'phone': '+27-82-987-6543',
          'relationship': 'Spouse'
        }
      },
      
      // Vital Signs
      'vitals': {
        'bloodPressure': {
          'systolic': 120,
          'diastolic': 80,
          'unit': 'mmHg'
        },
        'heartRate': {
          'value': 72,
          'unit': 'bpm'
        },
        'temperature': {
          'value': 36.8,
          'unit': '°C'
        },
        'oxygenSaturation': {
          'value': 98,
          'unit': '%'
        },
        'respiratoryRate': {
          'value': 16,
          'unit': 'breaths/min'
        }
      },
      
      // Medical History
      'medicalHistory': {
        'allergies': ['Peanuts'],
        'chronicConditions': [],
        'surgeries': [],
        'familyHistory': ['Hypertension (Father)', 'Diabetes Type 2 (Mother)']
      },
      
      // Current Medications
      'medications': [
        {
          'name': 'Multivitamin',
          'dosage': '1 tablet',
          'frequency': 'Once daily',
          'prescribedBy': 'Dr. Smith',
          'startDate': '2024-01-15'
        }
      ],
      
      // Recent Lab Results
      'labResults': {
        'date': DateTime.now().subtract(Duration(days: 14)).toIso8601String(),
        'results': {
          'cholesterol': {
            'total': 180,
            'hdl': 55,
            'ldl': 110,
            'unit': 'mg/dL',
            'status': 'Normal'
          },
          'glucose': {
            'value': 90,
            'unit': 'mg/dL',
            'status': 'Normal'
          },
          'hemoglobin': {
            'value': 14.5,
            'unit': 'g/dL',
            'status': 'Normal'
          }
        }
      },
      
      // Appointments
      'appointments': {
        'last': {
          'date': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          'doctor': 'Dr. John Smith',
          'department': 'General Practice',
          'notes': 'Annual health checkup - all results normal'
        },
        'next': {
          'date': DateTime.now().add(Duration(days: 180)).toIso8601String(),
          'doctor': 'Dr. John Smith',
          'department': 'General Practice',
          'notes': 'Follow-up appointment for annual checkup'
        }
      },
      
      // Insurance Information
      'insurance': {
        'provider': 'Discovery Health',
        'policyNumber': 'POL-789456123',
        'groupNumber': 'GRP-4567',
        'effectiveDate': DateTime.now().subtract(Duration(days: 365)).toIso8601String()
      },
      
      // Status
      'status': {
        'active': true,
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': '1.0',
        'notes': 'Demo patient record for TouchHealth application testing'
      }
    };
  }

  /// Generate fallback record when API fails
  static Map<String, dynamic> _generateFallbackRecord(String patientId) {
    final random = Random(patientId.hashCode);
    
    return {
      'patientId': patientId,
      'recordId': 'MED-${patientId.toUpperCase()}',
      'timestamp': DateTime.now().toIso8601String(),
      'patient': {
        'name': 'Patient ${patientId}',
        'email': 'patient${patientId}@touchhealth.com',
        'phone': '+1-555-${random.nextInt(9000) + 1000}',
      },
      'medical': {
        'age': 25 + random.nextInt(50),
        'gender': random.nextBool() ? 'Male' : 'Female',
        'bloodType': _getRandomBloodType(random),
      },
      'vitals': {
        'bloodPressure': {'systolic': 120, 'diastolic': 80, 'unit': 'mmHg'},
        'heartRate': {'value': 72, 'unit': 'bpm'},
        'temperature': {'value': 36.5, 'unit': '°C'},
      },
      'status': {
        'active': true,
        'lastUpdated': DateTime.now().toIso8601String(),
        'note': 'Offline record generated'
      }
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

  static String _getRandomRelationship(Random random) {
    final relationships = ['Spouse', 'Parent', 'Sibling', 'Child', 'Friend', 'Partner'];
    return relationships[random.nextInt(relationships.length)];
  }

  static String _getRandomDepartment(Random random) {
    final departments = ['Cardiology', 'Neurology', 'Orthopedics', 'Dermatology', 'Internal Medicine', 'Pediatrics'];
    return departments[random.nextInt(departments.length)];
  }

  static String _getRandomInsurance(Random random) {
    final insurers = ['Blue Cross Blue Shield', 'Aetna', 'Cigna', 'UnitedHealth', 'Humana', 'Kaiser Permanente'];
    return insurers[random.nextInt(insurers.length)];
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

  static Map<String, dynamic> _generateLabResults(Random random) {
    return {
      'date': DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
      'results': {
        'cholesterol': {
          'total': 150 + random.nextInt(100),
          'hdl': 40 + random.nextInt(30),
          'ldl': 70 + random.nextInt(60),
          'unit': 'mg/dL'
        },
        'glucose': {
          'value': 80 + random.nextInt(40),
          'unit': 'mg/dL'
        },
        'hemoglobin': {
          'value': 12.0 + (random.nextDouble() * 4),
          'unit': 'g/dL'
        }
      }
    };
  }
}
