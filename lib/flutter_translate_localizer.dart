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
export 'src/localizer.dart';
export 'src/translator/json_translator.dart';
