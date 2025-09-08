import 'dart:developer';

class TextInputService {
  Future<bool> isTextInputAvailable() async {
    try {
      // Text input is always available
      return true;
    } catch (e) {
      log('Error checking text input availability: $e');
      return false;
    }
  }

  Future<void> processTextInput({
    required Function(Map<String, dynamic> data) onTextInputProcessed,
    required Function(String error) onError,
    required Function() onTimeout,
  }) async {
    try {
      log('=== Text Input Processing Started ===');
      
      // The actual text input will be handled by the dialog
      // This service provides the callback structure similar to NFC/QR services
      
      log('Text input service initialized successfully');
      
    } catch (e) {
      log('=== Text Input Processing Error ===');
      log('Error: $e');
      onError('Error initializing text input: $e');
    }
  }

  void processTextData(String textData, Function(Map<String, dynamic> data) onTextInputProcessed) {
    try {
      log('=== Text Input Data Processing ===');
      log('Text Data: $textData');

      // Extract medical record ID from text input
      String medicalId = _extractMedicalId(textData);
      
      if (medicalId.isNotEmpty) {
        log('Medical ID extracted: $medicalId');
        
        onTextInputProcessed({
          'message': 'Medical ID entered successfully.',
          'tagId': medicalId, // Use same key as NFC/QR for compatibility
          'textData': textData,
          'rawData': textData,
        });
      } else {
        onTextInputProcessed({
          'message': 'Invalid medical ID format.',
          'tagId': textData, // Use raw data as fallback
          'textData': textData,
          'rawData': textData,
        });
      }
      
      log('=== Text Input Processing Completed ===');
    } catch (e) {
      log('Error processing text data: $e');
      // Still return the raw data even if processing fails
      onTextInputProcessed({
        'message': 'Error processing text data: $e',
        'tagId': textData,
        'textData': textData,
        'rawData': textData,
      });
    }
  }

  String _extractMedicalId(String textData) {
    // Clean the input text
    String cleanedText = textData.trim();
    
    // Handle different text input formats
    
    // Format 1: Plain medical ID (just numbers/letters)
    if (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(cleanedText)) {
      return cleanedText;
    }
    
    // Format 2: URL with medical ID
    // Example: https://touchhealth.com/medical-record/12345
    final urlPattern = RegExp(r'medical[-_]?record[/:]([a-zA-Z0-9]+)', caseSensitive: false);
    final urlMatch = urlPattern.firstMatch(cleanedText);
    if (urlMatch != null) {
      return urlMatch.group(1) ?? '';
    }
    
    // Format 3: ID with prefix
    // Example: ID:12345, MedicalID:12345, RecordID:12345
    final prefixPattern = RegExp(r'(?:id|medicalid|recordid|medical[-_]?id|record[-_]?id)[:=]\s*([a-zA-Z0-9]+)', caseSensitive: false);
    final prefixMatch = prefixPattern.firstMatch(cleanedText);
    if (prefixMatch != null) {
      return prefixMatch.group(1) ?? '';
    }
    
    // Format 4: Extract numbers from mixed text
    // Example: "Patient record 12345 for John Doe"
    final numberPattern = RegExp(r'\b([a-zA-Z0-9]{3,})\b');
    final numberMatches = numberPattern.allMatches(cleanedText);
    for (final match in numberMatches) {
      final potential = match.group(1) ?? '';
      // Prefer alphanumeric IDs that are at least 3 characters
      if (potential.length >= 3 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(potential)) {
        return potential;
      }
    }
    
    // Format 5: Remove common separators and spaces
    // Example: "12-34-56" -> "123456"
    final cleanedId = cleanedText.replaceAll(RegExp(r'[-\s_.]'), '');
    if (cleanedId.isNotEmpty && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(cleanedId)) {
      return cleanedId;
    }
    
    // If no pattern matches, return the cleaned text if it's reasonable
    if (cleanedText.length >= 2 && cleanedText.length <= 50) {
      log('Using cleaned text as medical ID');
      return cleanedText;
    }
    
    // Return empty if text is too short or too long
    log('Text input does not match any medical ID pattern');
    return '';
  }

  bool isValidMedicalId(String id) {
    // Basic validation for medical ID
    if (id.isEmpty || id.length < 2 || id.length > 50) {
      return false;
    }
    
    // Allow alphanumeric characters and common separators
    return RegExp(r'^[a-zA-Z0-9\-_\.]+$').hasMatch(id);
  }
}
