import 'dart:developer';

import 'package:touchhealth/core/utils/constant/api_url.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GenerativeAiWebService {
  static final _model = GenerativeModel(
    model: EnvManager.generativeModelVersion,
    apiKey: EnvManager.generativeModelApiKey,
    safetySettings: [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
    ],
  );

  static Future<String?> postData({required List<Content> content}) async {
    try {
      final response = await _model.generateContent(content);
      log("TouchHealth AI response generated successfully!");

      if (response.text == null || response.text!.isEmpty) {
        return "I'm sorry, I couldn't generate a response at the moment. Please try asking your question again.";
      }

      final cleanResponse = response.text!.trim();
      log('TouchHealth AI response: $cleanResponse');
      return cleanResponse;
    } on GenerativeAIException catch (e) {
      log('Generative AI Error: ${e.message}');
      return "I'm experiencing some technical difficulties. Please try again in a moment.";
    } on Exception catch (err) {
      log('General error: ${err.toString()}');
      return "I'm sorry, I encountered an error while processing your request. Please try again.";
    }
  }

  static Future<String?> getHealthAdvice({required String userMessage, String? medicalContext}) async {
    try {
      List<Content> healthContent = [
        Content.text("You are TouchHealth AI, a knowledgeable health assistant."),
        Content.text("Provide helpful, accurate health information while being empathetic."),
        Content.text("Always remind users to consult healthcare professionals for serious concerns."),
        if (medicalContext != null) Content.text("User's medical context: $medicalContext"),
        Content.text("User question: $userMessage"),
      ];

      final response = await _model.generateContent(healthContent);
      return response.text?.trim();
    } catch (e) {
      log('Health advice error: $e');
      return "I'm sorry, I couldn't provide health advice at the moment. Please consult with a healthcare professional.";
    }
  }

  static Future<void> streamData({required String text}) async {
    try {
      final content = [Content.text(text)];
      final response = _model.generateContentStream(content);
      await for (final chunk in response) {
        if (chunk.text != null) {
          log(chunk.text!);
        }
      }
    } catch (e) {
      log('Streaming error: $e');
    }
  }
}
