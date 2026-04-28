import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Translates JSON language files using the Google Translate public endpoint.
///
/// Traverses an arbitrarily nested JSON map and translates every string value
/// while preserving the original key structure.
class JsonTranslator {
  /// Google Translate endpoint (free, client=gtx).
  static const String _baseUrl =
      'https://translate.googleapis.com/translate_a/single';

  final http.Client _client;

  JsonTranslator({http.Client? client}) : _client = client ?? http.Client();

  /// Translates all string values inside [json] from [sourceLanguage] to
  /// [targetLanguage] and returns a new map with the same structure.
  ///
  /// Non-string leaf values (numbers, booleans, null) are kept as-is.
  /// Nested maps and lists are traversed recursively.
  Future<Map<String, dynamic>> translateJson(
    Map<String, dynamic> json,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final result = <String, dynamic>{};
    for (final entry in json.entries) {
      result[entry.key] = await _translateValue(
        entry.value,
        sourceLanguage,
        targetLanguage,
      );
    }
    return result;
  }

  /// Recursively translates a single JSON value.
  Future<dynamic> _translateValue(
    dynamic value,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    if (value is String) {
      if (value.trim().isEmpty) return value;
      return _translateText(value, sourceLanguage, targetLanguage);
    } else if (value is Map<String, dynamic>) {
      return translateJson(value, sourceLanguage, targetLanguage);
    } else if (value is List) {
      final translated = <dynamic>[];
      for (final item in value) {
        translated.add(
          await _translateValue(item, sourceLanguage, targetLanguage),
        );
      }
      return translated;
    }
    // Numbers, booleans, null – keep as-is.
    return value;
  }

  /// Calls the Google Translate public endpoint and returns the translated text.
  ///
  /// Throws [HttpException] when the server returns a non-200 status code.
  Future<String> _translateText(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'client': 'gtx',
        'sl': sourceLanguage,
        'tl': targetLanguage,
        'dt': 't',
        'q': text,
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw HttpException(
        'Google Translate returned status ${response.statusCode} '
        'for text: "$text".',
      );
    }

    return _parseTranslation(response.body);
  }

  /// Parses the raw response body returned by Google Translate.
  ///
  /// The response is a nested JSON array; the translated fragments are in the
  /// first element of the outermost array, at index 0 of each fragment.
  String _parseTranslation(String responseBody) {
    final dynamic data = jsonDecode(responseBody);
    if (data is! List || data.isEmpty || data[0] is! List) {
      throw FormatException(
        'Unexpected Google Translate response format: $responseBody',
      );
    }

    final buffer = StringBuffer();
    for (final fragment in data[0] as List) {
      if (fragment is List && fragment.isNotEmpty) {
        buffer.write(fragment[0].toString());
      }
    }
    return buffer.toString();
  }

  /// Closes the underlying HTTP client.
  ///
  /// Should be called when the translator is no longer needed to free
  /// underlying socket resources.
  void close() => _client.close();
}
