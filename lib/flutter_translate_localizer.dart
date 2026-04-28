/// Flutter Translate Localizer
///
/// A Dart CLI tool that reads a YAML config file and translates JSON language
/// files into multiple target languages using the Google Translate public API.
///
/// ## Quick start
///
/// 1. Add a `translate_config.yaml` in your project root.
/// 2. Run: `dart run flutter_translate_localizer`
library flutter_translate_localizer;

export 'src/config/translate_config.dart';
export 'src/file_handler/file_handler.dart';
export 'src/lang_detector/lang_detector.dart';
export 'src/localizer.dart';
export 'src/plural_handler/cldr_rules.dart';
export 'src/plural_handler/plural_handler.dart';
export 'src/translator/json_translator.dart';
export 'src/translator/translation_options.dart';
export 'src/translator/translation_summary.dart';
export 'src/variable_escaper/variable_escaper.dart';
