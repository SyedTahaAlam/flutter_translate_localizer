import 'dart:io';

import 'package:flutter_translate_localizer/src/config/translate_config.dart';
import 'package:test/test.dart';

void main() {
  group('TranslateConfig.fromYamlString', () {
    test('parses scalar source and list output', () {
      const yaml = '''
source: en
output:
  - es
  - ar
''';
      final config = TranslateConfig.fromYamlString(yaml);
      expect(config.sourceLanguage, 'en');
      expect(config.outputLanguages, ['es', 'ar']);
      expect(config.sourceDestination, 'lib/lang');
      expect(config.translatedDestination, 'lib/lang');
    });

    test('parses list source and list output', () {
      const yaml = '''
source:
  - en
output:
  - fr
''';
      final config = TranslateConfig.fromYamlString(yaml);
      expect(config.sourceLanguage, 'en');
      expect(config.outputLanguages, ['fr']);
    });

    test('parses optional source_destination and translated_destination', () {
      const yaml = '''
source: en
output:
  - es
source_destination:
  - assets/lang
translated_destination:
  - lib/translated
''';
      final config = TranslateConfig.fromYamlString(yaml);
      expect(config.sourceDestination, 'assets/lang');
      expect(config.translatedDestination, 'lib/translated');
    });

    test('parses scalar source_destination and translated_destination', () {
      const yaml = '''
source: en
output:
  - de
source_destination: assets/i18n
translated_destination: lib/i18n
''';
      final config = TranslateConfig.fromYamlString(yaml);
      expect(config.sourceDestination, 'assets/i18n');
      expect(config.translatedDestination, 'lib/i18n');
    });

    test('defaults to lib/lang when destinations are omitted', () {
      const yaml = '''
source: en
output:
  - ja
''';
      final config = TranslateConfig.fromYamlString(yaml);
      expect(config.sourceDestination, 'lib/lang');
      expect(config.translatedDestination, 'lib/lang');
    });

    test('throws FormatException when source is missing', () {
      const yaml = '''
output:
  - es
''';
      expect(
        () => TranslateConfig.fromYamlString(yaml),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when output is missing', () {
      const yaml = '''
source: en
''';
      expect(
        () => TranslateConfig.fromYamlString(yaml),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when output is empty list', () {
      const yaml = '''
source: en
output: []
''';
      expect(
        () => TranslateConfig.fromYamlString(yaml),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when root is not a map', () {
      const yaml = '- en';
      expect(
        () => TranslateConfig.fromYamlString(yaml),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('TranslateConfig.fromFile', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('translate_config_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('loads config from an existing YAML file', () {
      final file = File('${tempDir.path}/config.yaml');
      file.writeAsStringSync('''
source: en
output:
  - es
  - ar
source_destination:
  - assets/lang
translated_destination:
  - lib/translated
''');

      final config = TranslateConfig.fromFile(file.path);
      expect(config.sourceLanguage, 'en');
      expect(config.outputLanguages, ['es', 'ar']);
      expect(config.sourceDestination, 'assets/lang');
      expect(config.translatedDestination, 'lib/translated');
    });

    test('throws FileSystemException for missing file', () {
      expect(
        () => TranslateConfig.fromFile('/nonexistent/path/config.yaml'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('TranslateConfig.toString', () {
    test('returns human-readable representation', () {
      const config = TranslateConfig(
        sourceLanguage: 'en',
        outputLanguages: ['es'],
        sourceDestination: 'lib/lang',
        translatedDestination: 'lib/lang',
      );
      expect(config.toString(), contains('en'));
      expect(config.toString(), contains('es'));
    });
  });
}
