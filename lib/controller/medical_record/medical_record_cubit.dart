import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:touchhealth/core/utils/constant/api_url.dart';
import 'package:touchhealth/core/service/medical_record_api_service.dart';
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
      // Fetch real medical record data from API
      final medicalRecord = await MedicalRecordApiService.getPatientRecord(patientId);
      
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
              <p><strong>Name:</strong> ${medicalRecord['name']}</p>
              <p><strong>DOB:</strong> ${medicalRecord['dateOfBirth']}</p>
              <p><strong>Phone:</strong> ${medicalRecord['phone']}</p>
              <p><strong>Email:</strong> ${medicalRecord['email']}</p>
              <p><strong>Address:</strong> ${medicalRecord['address']}</p>
              <p><strong>ID:</strong> ${patientId}</p>
              <p><strong>Record ID:</strong> MED-${patientId.toUpperCase()}</p>
              <p><strong>Last Updated:</strong> \${new Date().toLocaleDateString()}</p>
            </div>
            
            <div class="section">
              <h3>📊 Vital Signs</h3>
              <div class="vitals">
                <div class="vital-card">
                  <strong>Blood Pressure</strong><br>
                  ${medicalRecord['vitals']['bloodPressure']}
                </div>
                <div class="vital-card">
                  <strong>Heart Rate</strong><br>
                  ${medicalRecord['vitals']['heartRate']} bpm
                </div>
                <div class="vital-card">
                  <strong>Temperature</strong><br>
                  ${medicalRecord['vitals']['temperature']}°C
                </div>
                <div class="vital-card">
                  <strong>Oxygen Sat</strong><br>
                  ${medicalRecord['vitals']['oxygenSaturation']}%
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
              <p><strong>Cholesterol:</strong> ${medicalRecord['labResults']['cholesterol']} mg/dL (${medicalRecord['labResults']['cholesterolStatus']})</p>
              <p><strong>Glucose:</strong> ${medicalRecord['labResults']['glucose']} mg/dL (${medicalRecord['labResults']['glucoseStatus']})</p>
              <p><strong>Hemoglobin:</strong> ${medicalRecord['labResults']['hemoglobin']} g/dL (${medicalRecord['labResults']['hemoglobinStatus']})</p>
            </div>
            
            <div class="section">
              <h3>📅 Appointments</h3>
              <p><strong>Last Visit:</strong> ${medicalRecord['appointments']['lastVisit']['date']} - ${medicalRecord['appointments']['lastVisit']['doctor']} (${medicalRecord['appointments']['lastVisit']['type']})</p>
              <p><strong>Next Visit:</strong> ${medicalRecord['appointments']['nextVisit']['date']} - ${medicalRecord['appointments']['nextVisit']['doctor']} (${medicalRecord['appointments']['nextVisit']['type']})</p>
            </div>
            
            <div class="section">
              <h3>⚠️ Allergies</h3>
              <p>${medicalRecord['medicalHistory']['allergies'].join(', ')}</p>
            </div>
            
            <div class="section">
              <h3>🏥 Medical History</h3>
              <p><strong>Chronic Conditions:</strong> ${medicalRecord['medicalHistory']['chronicConditions'].join(', ')}</p>
              <p><strong>Previous Surgeries:</strong> ${medicalRecord['medicalHistory']['surgeries'].join(', ')}</p>
              <p><strong>Family History:</strong> ${medicalRecord['medicalHistory']['familyHistory'].join(', ')}</p>
            </div>
            
            <div class="section">
              <h3>💳 Insurance Information</h3>
              <p><strong>Provider:</strong> ${medicalRecord['insurance']['provider']}</p>
              <p><strong>Policy Number:</strong> ${medicalRecord['insurance']['policyNumber']}</p>
              <p><strong>Group Number:</strong> ${medicalRecord['insurance']['groupNumber']}</p>
            </div>
            
            <div class="section">
              <h3>📋 Notes</h3>
              <p>${medicalRecord['notes']}</p>
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
    final url = await _buildSafeUrl(defaultId);
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
