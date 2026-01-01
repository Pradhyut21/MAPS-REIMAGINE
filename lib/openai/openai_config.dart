import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
const endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

class OpenAIClient {
  final String model;
  OpenAIClient({this.model = 'gpt-4o'});

  Future<String> chat(String prompt, {Map<String, dynamic>? extraSystem}) async {
    if (endpoint.isEmpty || apiKey.isEmpty) {
      throw Exception('OpenAI endpoint or API key is not configured');
    }
    final uri = Uri.parse(endpoint);
    final body = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a helpful travel assistant. Provide concise, accurate answers with actionable steps.'
        },
        if (extraSystem != null)
          {
            'role': 'system',
            'content': jsonEncode(extraSystem),
          },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.4,
    };
    try {
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (res.statusCode != 200) {
        debugPrint('OpenAI ${res.statusCode}: ${res.body}');
        throw Exception('OpenAI error ${res.statusCode}');
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) return '';
      final msg = choices.first['message'] as Map<String, dynamic>;
      final content = (msg['content'] as String?) ?? '';
      return content;
    } catch (e) {
      debugPrint('OpenAI chat failed: $e');
      rethrow;
    }
  }
}
