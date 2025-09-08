import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvManager {
  EnvManager._();

  static String pyDrAi = dotenv.env['PY_DR_AI'] ?? 'https://api.example.com';
  static String get medicalTips => dotenv.env['DAILY_TIPS_BASE_URL'] ?? 'https://tips.example.com';
  static String googleMapApiKey = dotenv.env['MAP_API_KEY'] ?? '';
  static String placeSuggetion = dotenv.env['PLACE_SUGGESTION_BASE_URL'] ?? 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static String placeLocation = dotenv.env['PLACE_LOCATION_BASE_URL'] ?? 'https://maps.googleapis.com/maps/api/place/details/json';
  static String directions = dotenv.env['PLACE_DIRECTIONS_BASE_URL'] ?? 'https://maps.googleapis.com/maps/api/directions/json';
  static String nearestHospital = dotenv.env['NEAREST_HOSPITAL_BASE_URL'] ?? 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static String generativeModelApiKey = dotenv.env['GENERATIVE_MODEL_API_KEY'] ?? 'AIzaSyAowcJEG-_2d3i696QzMsQUvAmK0XYeEg0';
  static String generativeModelVersion = dotenv.env['GENERATIVE_MODEL_VERSION'] ?? 'gemini-pro';
  static String get medicalRecord => dotenv.env['MEDICAL_RECORD_URL'] ?? 'https://example.com/medical-record/';
  static String medicalRecordPdfBackend = dotenv.env['MEDICAL_RECORD_PDF_BACKEND'] ?? 'https://pdf.example.com';
  static String defaultMedicalRecordID = dotenv.env['DEFAULT_MEDICAL_RECORD_ID'] ?? 'demo_record_123';
}
