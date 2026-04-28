import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_translate_localizer/flutter_translate_localizer.dart';

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

  final localizer = Localizer(configPath: configPath, verbose: verbose);

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
