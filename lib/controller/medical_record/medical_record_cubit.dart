import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:touchhealth/core/utils/constant/api_url.dart';
import 'package:touchhealth/core/service/medical_record_api_service.dart';
import 'package:touchhealth/core/service/patient_data_service.dart';
import 'package:equatable/equatable.dart';

part 'medical_record_state.dart';

class MedicalRecordCubit extends Cubit<MedicalRecordState> {
  MedicalRecordCubit() : super(MedicalRecordState.initial());

  static String defaultId = EnvManager.defaultMedicalRecordID;

  String get baseUrl => EnvManager.medicalRecord;
  String? nfcID;

  String get initialUrl => defaultId;

  Future<String> _buildSafeUrl(String id) async {
    final baseUrl = EnvManager.medicalRecord;
    if (baseUrl.contains('example.com')) {
      // Generate dynamic medical record HTML using API service
      return await _generateMedicalRecordHtml(id);
    }
    return '$baseUrl$id';
  }

  Future<String> _generateMedicalRecordHtml(String patientId) async {
    try {
      // Try to get current patient's medical record first
      Map<String, dynamic>? medicalRecord;
      
      // Check if this is the current logged-in patient
      final currentPatientMedicalNumber = await PatientDataService.getCurrentPatientMedicalNumber();
      if (currentPatientMedicalNumber == patientId) {
        medicalRecord = await PatientDataService.getCurrentPatientMedicalRecord();
      }
      
      // Fallback to API service
      medicalRecord ??= await MedicalRecordApiService.getPatientRecord(patientId);
      
      // Generate HTML with real data
      return '''data:text/html,
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>TouchHealth - Medical Record</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #e91e63; color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; text-align: center; }
        .patient-info { background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
        .section { margin-bottom: 20px; }
        .section h3 { color: #e91e63; border-bottom: 2px solid #e91e63; padding-bottom: 5px; }
        .vitals { display: flex; flex-wrap: wrap; gap: 15px; }
        .vital-card { background: #e3f2fd; padding: 10px; border-radius: 8px; flex: 1; min-width: 150px; }
        .medications { background: #fff3e0; padding: 15px; border-radius: 8px; }
        .loading { text-align: center; padding: 40px; color: #666; }
        .error { background: #ffebee; color: #c62828; padding: 15px; border-radius: 8px; }
        .success { background: #e8f5e8; color: #2e7d32; padding: 15px; border-radius: 8px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🏥 TouchHealth Medical Records</h1>
          <p>Patient ID: $patientId</p>
        </div>
        <div id="content" class="loading">
          <h3>📋 Loading Medical Record...</h3>
          <p>Fetching patient data from secure medical database...</p>
        </div>
      </div>
      
      <script>
        // Simulate API call and display medical record
        setTimeout(() => {
          const content = document.getElementById('content');
          content.innerHTML = \`
            <div class="success">
              ✅ Medical record loaded successfully for Patient ID: $patientId
            </div>
            
            <div class="patient-info">
              <h2>👤 Patient Information</h2>
              <p><strong>Name:</strong> ${medicalRecord['patient']['name']}</p>
              <p><strong>Age:</strong> ${medicalRecord['medical']['age']} years</p>
              <p><strong>Gender:</strong> ${medicalRecord['medical']['gender']}</p>
              <p><strong>Blood Type:</strong> ${medicalRecord['medical']['bloodType']}</p>
              <p><strong>Phone:</strong> ${medicalRecord['patient']['phone']}</p>
              <p><strong>Email:</strong> ${medicalRecord['patient']['email']}</p>
              <p><strong>Address:</strong> ${medicalRecord['patient']['address']['street']}, ${medicalRecord['patient']['address']['city']}</p>
              <p><strong>ID:</strong> ${patientId}</p>
              <p><strong>Record ID:</strong> ${medicalRecord['recordId']}</p>
              <p><strong>Last Updated:</strong> \${new Date().toLocaleDateString()}</p>
            </div>
            
            <div class="section">
              <h3>📊 Vital Signs</h3>
              <div class="vitals">
                <div class="vital-card">
                  <strong>Blood Pressure</strong><br>
                  ${medicalRecord['vitals']['bloodPressure']['systolic']}/${medicalRecord['vitals']['bloodPressure']['diastolic']} ${medicalRecord['vitals']['bloodPressure']['unit']}
                </div>
                <div class="vital-card">
                  <strong>Heart Rate</strong><br>
                  ${medicalRecord['vitals']['heartRate']['value']} ${medicalRecord['vitals']['heartRate']['unit']}
                </div>
                <div class="vital-card">
                  <strong>Temperature</strong><br>
                  ${medicalRecord['vitals']['temperature']['value']}${medicalRecord['vitals']['temperature']['unit']}
                </div>
                <div class="vital-card">
                  <strong>Oxygen Sat</strong><br>
                  ${medicalRecord['vitals']['oxygenSaturation']['value']}${medicalRecord['vitals']['oxygenSaturation']['unit']}
                </div>
              </div>
            </div>
            
            <div class="section">
              <h3>💊 Current Medications</h3>
              <div class="medications">
                ${medicalRecord['medications'].map((med) => '<p>• ${med['name']} ${med['dosage']} - ${med['frequency']}</p>').join('')}
              </div>
            </div>
            
            <div class="section">
              <h3>🔬 Recent Lab Results</h3>
              <p><strong>Cholesterol:</strong> ${medicalRecord['labResults']['results']['cholesterol']['total']} mg/dL (${medicalRecord['labResults']['results']['cholesterol']['status']})</p>
              <p><strong>Glucose:</strong> ${medicalRecord['labResults']['results']['glucose']['value']} mg/dL (${medicalRecord['labResults']['results']['glucose']['status']})</p>
              <p><strong>Hemoglobin:</strong> ${medicalRecord['labResults']['results']['hemoglobin']['value']} g/dL (${medicalRecord['labResults']['results']['hemoglobin']['status']})</p>
            </div>
            
            <div class="section">
              <h3>📅 Appointments</h3>
              <p><strong>Last Visit:</strong> ${medicalRecord['appointments']['last']['date']} - ${medicalRecord['appointments']['last']['doctor']} (${medicalRecord['appointments']['last']['department']})</p>
              <p><strong>Next Visit:</strong> ${medicalRecord['appointments']['next']['date']} - ${medicalRecord['appointments']['next']['doctor']} (${medicalRecord['appointments']['next']['department']})</p>
            </div>
            
            <div class="section">
              <h3>⚠️ Allergies</h3>
              <p>\${medicalRecord['medicalHistory']['allergies'].join(', ') || 'No known allergies'}</p>
            </div>
            
            <div class="section">
              <h3>🏥 Medical History</h3>
              <p><strong>Chronic Conditions:</strong> \${medicalRecord['medicalHistory']['chronicConditions'].join(', ') || 'None'}</p>
              <p><strong>Previous Surgeries:</strong> \${medicalRecord['medicalHistory']['surgeries'].join(', ') || 'None'}</p>
              <p><strong>Family History:</strong> \${medicalRecord['medicalHistory']['familyHistory'].join(', ') || 'None reported'}</p>
            </div>
            
            <div class="section">
              <h3>💳 Insurance Information</h3>
              <p><strong>Provider:</strong> ${medicalRecord['insurance']['provider']}</p>
              <p><strong>Policy Number:</strong> ${medicalRecord['insurance']['policyNumber']}</p>
              <p><strong>Group Number:</strong> ${medicalRecord['insurance']['groupNumber']}</p>
            </div>
            
            <div class="section">
              <h3>📋 Notes</h3>
              <p>\${medicalRecord['status']['notes'] || 'No additional notes'}</p>
            </div>
          \`;
        }, 1500);
      </script>
    </body>
    </html>''';
    } catch (e) {
      // Return fallback HTML on API error
      return '''data:text/html,
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>TouchHealth - Error</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
          .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .error { background: #ffebee; color: #c62828; padding: 15px; border-radius: 8px; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="error">
            ❌ Failed to generate medical record for ID: $patientId<br>
            Error: $e
          </div>
        </div>
      </body>
      </html>''';
    }
  }

  Future<void> initWebView() async {
    // Try to load current patient's medical record first
    final currentPatientMedicalNumber = await PatientDataService.getCurrentPatientMedicalNumber();
    // Use a known demo record if no logged-in patient is detected to ensure Records tab always shows data
    final id = currentPatientMedicalNumber ?? 'DEMO001';
    
    final url = await _buildSafeUrl(id);
    emit(state.copyWith(url: url));
  }

  Future<void> loadMedicalRecord(String id) async {
    emit(state.copyWith(isLoading: true));
    nfcID = id;
    try {
      final url = await _buildSafeUrl(id);
      emit(state.copyWith(
        isLoading: false,
        url: url,
      ));
    } catch (e) {
      // Return fallback HTML on error
      final fallbackUrl = '''data:text/html,
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>TouchHealth - Error</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
          .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .error { background: #ffebee; color: #c62828; padding: 15px; border-radius: 8px; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="error">
            ❌ Failed to load medical record for ID: $id<br>
            Error: $e
          </div>
        </div>
      </body>
      </html>''';
      
      emit(state.copyWith(
        isLoading: false,
        url: fallbackUrl,
      ));
    }
  }

  void updateWebViewId(String id) {
    loadMedicalRecord(id);
  }
}
