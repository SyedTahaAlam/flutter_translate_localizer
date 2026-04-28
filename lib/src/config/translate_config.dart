import 'dart:io';

import 'package:yaml/yaml.dart';

/// Holds the parsed configuration from the YAML config file.
class TranslateConfig {
  /// The source language code (e.g. 'en').
  final String sourceLanguage;

  /// The list of target language codes to translate into (e.g. ['es', 'ar']).
  final List<String> outputLanguages;

  /// Directory that contains the source JSON file.
  /// Defaults to 'lib/lang'.
  final String sourceDestination;

  /// Directory where translated JSON files will be written.
  /// Defaults to 'lib/lang'.
  final String translatedDestination;

  const TranslateConfig({
    required this.sourceLanguage,
    required this.outputLanguages,
    required this.sourceDestination,
    required this.translatedDestination,
  });

  /// Loads and parses a [TranslateConfig] from a YAML file at [configPath].
  ///
  /// Throws a [FileSystemException] if the file does not exist.
  /// Throws a [FormatException] if the YAML structure is invalid.
  static TranslateConfig fromFile(String configPath) {
    final file = File(configPath);
    if (!file.existsSync()) {
      throw FileSystemException(
        'Config file not found. Please create a translate_config.yaml file.',
        configPath,
      );
    }

    final content = file.readAsStringSync();
    return TranslateConfig.fromYamlString(content);
  }

  /// Parses a [TranslateConfig] from a YAML [content] string.
  ///
  /// Both scalar and list forms are accepted for each field:
  /// ```yaml
  /// source: en
  /// # or
  /// source:
  ///   - en
  /// ```
  static TranslateConfig fromYamlString(String content) {
    final dynamic doc = loadYaml(content);

    if (doc is! Map) {
      throw const FormatException(
        'Invalid config file: root element must be a YAML mapping.',
      );
    }

    final sourceRaw = doc['source'];
    if (sourceRaw == null) {
      throw const FormatException(
        'Missing required key "source" in config file.',
      );
    }
    final sourceLanguage = _extractSingleValue(sourceRaw, 'source');

    final outputRaw = doc['output'];
    if (outputRaw == null) {
      throw const FormatException(
        'Missing required key "output" in config file.',
      );
    }
    final outputLanguages = _extractList(outputRaw, 'output');
    if (outputLanguages.isEmpty) {
      throw const FormatException(
        'The "output" key must contain at least one language code.',
      );
    }

    final srcDestRaw = doc['source_destination'];
    final sourceDestination = srcDestRaw != null
        ? _extractSingleValue(srcDestRaw, 'source_destination')
        : 'lib/lang';

    final transDestRaw = doc['translated_destination'];
    final translatedDestination = transDestRaw != null
        ? _extractSingleValue(transDestRaw, 'translated_destination')
        : 'lib/lang';

    return TranslateConfig(
      sourceLanguage: sourceLanguage,
      outputLanguages: outputLanguages,
      sourceDestination: sourceDestination,
      translatedDestination: translatedDestination,
    );
  }

  /// Extracts a single string value from a scalar or single-element list node.
  static String _extractSingleValue(dynamic node, String key) {
    if (node is String) return node.trim();
    if (node is YamlList) {
      if (node.isEmpty) {
        throw FormatException(
          'The "$key" key must not be an empty list.',
        );
      }
      return node.first.toString().trim();
    }
    return node.toString().trim();
  }

  /// Extracts a list of string values from a scalar or list node.
  static List<String> _extractList(dynamic node, String key) {
    if (node is String) return [node.trim()];
    if (node is YamlList) {
      return node.map((e) => e.toString().trim()).toList();
    }
    throw FormatException(
      'The "$key" key must be a string or a list of strings.',
    );
  }

  @override
  String toString() => 'TranslateConfig('
      'source: $sourceLanguage, '
      'output: $outputLanguages, '
      'sourceDestination: $sourceDestination, '
      'translatedDestination: $translatedDestination)';
}
