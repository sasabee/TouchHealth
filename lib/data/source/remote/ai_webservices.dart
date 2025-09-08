import 'dart:developer';

import 'package:touchhealth/core/utils/constant/api_url.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GenerativeAiWebService {
  static final _model = GenerativeModel(
    model: EnvManager.generativeModelVersion,
    apiKey: EnvManager.generativeModelApiKey,
  );

  static Future<String?> postData({required List<Content> content}) async {
    try {
      final response = await _model.generateContent(content);
      log("Data posted successfully!");

      final cleanResponse = response.text!.trim();
      log('response: $cleanResponse');
      return cleanResponse;
    } on Exception catch (err) {
      log(err.toString());
      return null;
    }
  }

  static Future<void> streamData({required String text}) async {
    final content = [Content.text(text)];
    final response = _model.generateContentStream(content);
    await for (final chunk in response) {
      log(chunk.text!);
    }
  }
}
