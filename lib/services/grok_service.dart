import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class GrokService {
  static bool get isConfigured => AppConfig.grokToken.isNotEmpty;

  static const String _systemPrompt =
      'Sen Türkçe konuşan bir kişisel finans danışmanısın. '
      'Kullanıcının harcama özetine bakarak somut öneriler üret. '
      'SADECE JSON dizisi döndür, başka hiçbir metin yazma. '
      'Her eleman şu alanlara sahip olmalı: '
      '"title" (kısa başlık, en fazla 60 karakter), '
      '"description" (1-2 cümle, somut ve uygulanabilir), '
      '"potential_saving" (TL cinsinden sayı, yoksa 0), '
      '"priority" ("high", "medium" veya "low"). '
      'En fazla 4 öneri ver.';

  static Future<List<Map<String, dynamic>>> getRecommendations(
      String spendingSummary) async {
    if (!isConfigured) {
      throw Exception('GROK_TOKEN tanımlı değil');
    }

    final response = await http
        .post(
          Uri.parse(AppConfig.grokBaseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.grokToken}',
          },
          body: jsonEncode({
            'model': AppConfig.grokModel,
            'temperature': 0.4,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': spendingSummary},
            ],
          }),
        )
        .timeout(const Duration(seconds: 40));

    if (response.statusCode != 200) {
      debugPrint('Grok API hatası: ${response.statusCode} ${response.body}');
      throw Exception('Grok API hatası: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final content = data['choices'][0]['message']['content'] as String;
    return _parseRecommendations(content);
  }

  static List<Map<String, dynamic>> _parseRecommendations(String content) {
    final start = content.indexOf('[');
    final end = content.lastIndexOf(']');
    if (start == -1 || end <= start) {
      throw const FormatException('Geçersiz AI yanıtı');
    }
    final list = jsonDecode(content.substring(start, end + 1)) as List;
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
