import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_translate_localizer/flutter_translate_localizer.dart';
import 'package:flutter_translate_localizer/src/translator/translation_options.dart';

/// Entry point for the `flutter_translate` executable.
///
/// Run with:
/// ```
/// dart run flutter_translate_localizer          # uses translate_config.yaml
/// dart run flutter_translate_localizer -c path/to/config.yaml
/// ```
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'translate_config.yaml',
      help: 'Path to the YAML configuration file.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Print progress messages.',
    )
    ..addFlag(
      'escape-vars',
      negatable: false,
      help:
          'Detect and preserve interpolation placeholders ({var}, {{var}}, '
          r'%s, @var, ${var}) so they are not altered by the translation engine.',
    )
    ..addFlag(
      'handle-plurals',
      negatable: false,
      help:
          'Detect and translate plural key groups: both flat _plural-suffixed '
          'keys (Form A) and ICU MessageFormat blocks (Form B).',
    )
    ..addFlag(
      'cldr-expand',
      negatable: false,
      help:
          'When --handle-plurals is active, auto-expand ICU plural categories '
          'to match the full set required by the target language (CLDR rules).',
    )
    ..addFlag(
      'dry-run',
      negatable: false,
      help:
          'Print what would be translated without calling the translation API.',
    )
    ..addOption(
      'skip-keys',
      help:
          'Regular-expression pattern; any key whose fully-qualified dotted '
          'path matches this pattern is left untranslated.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message.',
    );

  late ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    stderr.writeln('Error: $e');
    _printUsage(parser);
    exit(1);
  }

  if (results['help'] as bool) {
    _printUsage(parser);
    return;
  }

  final configPath = results['config'] as String;
  final verbose = results['verbose'] as bool;

  // Build v2 options from CLI flags.
  RegExp? skipKeys;
  final skipKeysRaw = results['skip-keys'] as String?;
  if (skipKeysRaw != null && skipKeysRaw.isNotEmpty) {
    try {
      skipKeys = RegExp(skipKeysRaw);
    } catch (e) {
      stderr.writeln('Invalid --skip-keys regex: $e');
      exit(1);
    }
  }

  final options = TranslationOptions(
    escapeVars: results['escape-vars'] as bool,
    handlePlurals: results['handle-plurals'] as bool,
    cldrExpand: results['cldr-expand'] as bool,
    dryRun: results['dry-run'] as bool,
    skipKeys: skipKeys,
  );

  final localizer = Localizer(
    configPath: configPath,
    verbose: verbose,
    options: options,
  );

  try {
    await localizer.run();
    stdout.writeln('Translation complete!');
  } on FileSystemException catch (e) {
    stderr.writeln('File error: ${e.message} — ${e.path}');
    exit(1);
  } on FormatException catch (e) {
    stderr.writeln('Format error: ${e.message}');
    exit(1);
  } catch (e) {
    stderr.writeln('Unexpected error: $e');
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  stdout
    ..writeln('flutter_translate_localizer')
    ..writeln(
      'Translates JSON language files to multiple languages '
      'using a YAML config.',
    )
    ..writeln()
    ..writeln('Usage: dart run flutter_translate_localizer [options]')
    ..writeln()
    ..writeln(parser.usage);
}
