import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../lang_detector/lang_detector.dart';
import '../plural_handler/cldr_rules.dart';
import '../plural_handler/plural_handler.dart';
import '../variable_escaper/variable_escaper.dart';
import 'translation_options.dart';
import 'translation_summary.dart';

/// Translates JSON language files using the Google Translate public endpoint.
///
/// Traverses an arbitrarily nested JSON map and translates every string value
/// while preserving the original key structure.
///
/// v2 adds optional support for:
///   - Variable escaping (`options.escapeVars`)
///   - ICU and flat plural handling (`options.handlePlurals`)
///   - CLDR plural expansion (`options.cldrExpand`)
///   - Dry-run mode (`options.dryRun`)
///   - Key skipping via regex (`options.skipKeys`)
///   - Skipping values already written in the target language
class JsonTranslator {
  /// Google Translate endpoint (free, client=gtx).
  static const String _baseUrl =
      'https://translate.googleapis.com/translate_a/single';

  final http.Client _client;

  JsonTranslator({http.Client? client}) : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Translates all string values inside [json] from [sourceLanguage] to
  /// [targetLanguage] and returns a new map with the same structure.
  ///
  /// Non-string leaf values (numbers, booleans, null) are kept as-is.
  /// Nested maps and lists are traversed recursively.
  ///
  /// [options] controls the v2 features (all opt-in, default off).
  /// [summary] is updated in-place with translation statistics.
  Future<Map<String, dynamic>> translateJson(
    Map<String, dynamic> json,
    String sourceLanguage,
    String targetLanguage, {
    TranslationOptions options = const TranslationOptions(),
    TranslationSummary? summary,
    String keyPrefix = '',
  }) async {
    final result = <String, dynamic>{};

    // Detect Form-A plural groups at this level of the map.
    final pluralGroups = options.handlePlurals
        ? PluralHandler.detectPluralGroups(json)
        : <String, List<String>>{};

    // Track which keys belong to a plural group so we process them once.
    final pluralKeys = <String>{};
    for (final siblings in pluralGroups.values) {
      pluralKeys.addAll(siblings);
    }

    for (final entry in json.entries) {
      final key = entry.key;
      final qualifiedKey =
          keyPrefix.isEmpty ? key : '$keyPrefix.$key';

      // --- skip-keys filter ---
      if (options.skipKeys != null &&
          options.skipKeys!.hasMatch(qualifiedKey)) {
        result[key] = entry.value;
        continue;
      }

      // --- plural group (Form A): translate base + _plural together ---
      if (pluralKeys.contains(key) && pluralGroups.containsKey(key)) {
        for (final sibling in pluralGroups[key]!) {
          final sibValue = json[sibling];
          final sibQualifiedKey =
              keyPrefix.isEmpty ? sibling : '$keyPrefix.$sibling';
          if (sibValue is String) {
            result[sibling] = await _translateString(
              sibValue,
              sourceLanguage,
              targetLanguage,
              qualifiedKey: sibQualifiedKey,
              options: options,
              summary: summary,
            );
          } else {
            result[sibling] = sibValue;
          }
        }
        continue;
      }

      // --- skip keys already emitted as part of a plural group ---
      if (pluralKeys.contains(key)) {
        if (result.containsKey(key)) continue;
        result[key] = await _translateValue(
          entry.value,
          sourceLanguage,
          targetLanguage,
          qualifiedKey: qualifiedKey,
          options: options,
          summary: summary,
        );
        continue;
      }

      result[key] = await _translateValue(
        entry.value,
        sourceLanguage,
        targetLanguage,
        qualifiedKey: qualifiedKey,
        options: options,
        summary: summary,
      );
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Recursively translates a single JSON value.
  Future<dynamic> _translateValue(
    dynamic value,
    String sourceLanguage,
    String targetLanguage, {
    required String qualifiedKey,
    required TranslationOptions options,
    TranslationSummary? summary,
  }) async {
    if (value is String) {
      return _translateString(
        value,
        sourceLanguage,
        targetLanguage,
        qualifiedKey: qualifiedKey,
        options: options,
        summary: summary,
      );
    } else if (value is Map<String, dynamic>) {
      return translateJson(
        value,
        sourceLanguage,
        targetLanguage,
        options: options,
        summary: summary,
        keyPrefix: qualifiedKey,
      );
    } else if (value is List) {
      final translated = <dynamic>[];
      var idx = 0;
      for (final item in value) {
        translated.add(
          await _translateValue(
            item,
            sourceLanguage,
            targetLanguage,
            qualifiedKey: '$qualifiedKey[$idx]',
            options: options,
            summary: summary,
          ),
        );
        idx++;
      }
      return translated;
    }
    // Numbers, booleans, null — keep as-is.
    return value;
  }

  /// Translates a single string value, applying variable escaping and ICU
  /// plural handling when the relevant options are enabled.
  Future<String> _translateString(
    String value,
    String sourceLanguage,
    String targetLanguage, {
    required String qualifiedKey,
    required TranslationOptions options,
    TranslationSummary? summary,
  }) async {
    // Never translate empty strings.
    if (value.trim().isEmpty) return value;

    // Skip if the value is already written in the target language's script.
    if (LangDetector.isAlreadyInLanguage(value, languageCode: targetLanguage)) {
      return value;
    }

    // --- ICU plural (Form B) ---
    if (options.handlePlurals && PluralHandler.isIcuPlural(value)) {
      return _translateIcuPlural(
        value,
        sourceLanguage,
        targetLanguage,
        qualifiedKey: qualifiedKey,
        options: options,
        summary: summary,
      );
    }

    // --- dry-run ---
    if (options.dryRun) {
      stdout.writeln('[dry-run] $qualifiedKey: $value');
      return value;
    }

    // --- normal translation (with optional variable escaping) ---
    return _translateWithEscaping(
      value,
      sourceLanguage,
      targetLanguage,
      qualifiedKey: qualifiedKey,
      options: options,
      summary: summary,
    );
  }

  /// Translates an ICU plural block by translating each arm independently
  /// and then reconstructing the full block.
  Future<String> _translateIcuPlural(
    String value,
    String sourceLanguage,
    String targetLanguage, {
    required String qualifiedKey,
    required TranslationOptions options,
    TranslationSummary? summary,
  }) async {
    final block = PluralHandler.parse(value);
    if (block == null) {
      // Parsing failed — fall back to translating the whole string as plain text.
      return _translateWithEscaping(
        value,
        sourceLanguage,
        targetLanguage,
        qualifiedKey: qualifiedKey,
        options: options,
        summary: summary,
      );
    }

    if (options.dryRun) {
      for (final entry in block.entries) {
        stdout.writeln(
          '[dry-run] $qualifiedKey[${entry.category}]: ${entry.content}',
        );
      }
      return value;
    }

    // Translate each arm's content independently.
    final translatedArms = <String, String>{};
    for (final entry in block.entries) {
      translatedArms[entry.category] = await _translateWithEscaping(
        entry.content,
        sourceLanguage,
        targetLanguage,
        qualifiedKey: '$qualifiedKey[${entry.category}]',
        options: options,
        summary: summary,
        countInSummary: false, // counted once below at the ICU level
      );
    }

    final reconstructed = PluralHandler.reconstructIcu(
      block.variable,
      translatedArms,
      targetLanguage,
      cldrExpand: options.cldrExpand,
    );

    // Record expansion if the target language needs more categories than the
    // source provided.
    if (options.cldrExpand) {
      final sourceCategories = block.entries.map((e) => e.category).toSet();
      final targetCategories = getPluralCategories(targetLanguage).toSet();
      if (targetCategories.difference(sourceCategories).isNotEmpty) {
        summary?.pluralGroupsExpanded++;
      }
    }

    summary?.keysTranslated++;
    return reconstructed;
  }

  /// Translates [text] with optional variable escaping.
  ///
  /// When [options.escapeVars] is `true`, placeholders are tokenised before
  /// calling the API and restored afterwards.  If restoration fails, a warning
  /// is emitted and the original [text] is returned unchanged.
  Future<String> _translateWithEscaping(
    String text,
    String sourceLanguage,
    String targetLanguage, {
    required String qualifiedKey,
    required TranslationOptions options,
    TranslationSummary? summary,
    bool countInSummary = true,
  }) async {
    if (!options.escapeVars) {
      final translated =
          await _translateText(text, sourceLanguage, targetLanguage);
      if (countInSummary) summary?.keysTranslated++;
      return translated;
    }

    final escaped = VariableEscaper.escape(text);

    // No placeholders found — translate directly.
    if (escaped.variables.isEmpty) {
      final translated = await _translateText(
        escaped.tokenized,
        sourceLanguage,
        targetLanguage,
      );
      if (countInSummary) summary?.keysTranslated++;
      return translated;
    }

    final translatedTokenized = await _translateText(
      escaped.tokenized,
      sourceLanguage,
      targetLanguage,
    );

    final restored =
        VariableEscaper.restore(translatedTokenized, escaped.variables);
    if (restored == null) {
      stderr.writeln(
        '⚠ Variable mismatch in "$qualifiedKey"; keeping original.',
      );
      summary?.keysWithVarWarnings++;
      return text; // Fall back to original untranslated string.
    }

    if (countInSummary) summary?.keysTranslated++;
    return restored;
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
