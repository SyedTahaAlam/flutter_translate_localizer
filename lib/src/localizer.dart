import 'package:flutter_translate_localizer/src/config/translate_config.dart';
import 'package:flutter_translate_localizer/src/file_handler/file_handler.dart';
import 'package:flutter_translate_localizer/src/translator/json_translator.dart';
import 'package:flutter_translate_localizer/src/translator/translation_options.dart';
import 'package:flutter_translate_localizer/src/translator/translation_summary.dart';

/// Orchestrates the full localisation workflow:
///
/// 1. Parse the YAML config file.
/// 2. Load the source JSON file.
/// 3. Translate to every target language.
/// 4. Write translated JSON files to the destination directory.
/// 5. Print the summary (keys translated, warnings, plural expansions).
class Localizer {
  final String configPath;
  final bool verbose;

  /// v2 feature flags — all default to off to preserve v1 behaviour.
  final TranslationOptions options;

  final FileHandler _fileHandler;
  final JsonTranslator _translator;

  Localizer({
    required this.configPath,
    this.verbose = false,
    this.options = const TranslationOptions(),
    FileHandler? fileHandler,
    JsonTranslator? translator,
  })  : _fileHandler = fileHandler ?? FileHandler(),
        _translator = translator ?? JsonTranslator();

  /// Runs the full translation pipeline.
  Future<void> run() async {
    _log('Reading config from $configPath …');
    final config = TranslateConfig.fromFile(configPath);
    _log('Config: $config');

    _log(
      'Reading source JSON '
      '(${config.sourceDestination}/${config.sourceLanguage}.json) …',
    );
    final sourceJson = _fileHandler.readJson(
      config.sourceDestination,
      config.sourceLanguage,
    );
    _log('Source contains ${sourceJson.length} top-level key(s).');

    final summary = TranslationSummary();

    for (final targetLang in config.outputLanguages) {
      _log('Translating ${config.sourceLanguage} → $targetLang …');

      final translatedJson = await _translator.translateJson(
        sourceJson,
        config.sourceLanguage,
        targetLang,
        options: options,
        summary: summary,
      );

      if (!options.dryRun) {
        final dest = config.translatedDestination;
        _fileHandler.writeJson(dest, targetLang, translatedJson);
        _log('  ✓ Written to $dest/$targetLang.json');
      }
    }

    _log('Done. Translated ${config.outputLanguages.length} language(s).');
    summary.printSummary();
    _translator.close();
  }

  void _log(String message) {
    if (verbose) print(message);
  }
}
