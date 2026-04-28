import 'dart:io';

import 'package:flutter_translate_localizer/src/file_handler/file_handler.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late FileHandler handler;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_handler_test_');
    handler = FileHandler();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('FileHandler.readJson', () {
    test('reads a valid JSON file', () {
      final file = File('${tempDir.path}/en.json');
      file.writeAsStringSync('{"hello": "Hello", "world": "World"}');

      final result = handler.readJson(tempDir.path, 'en');
      expect(result, {'hello': 'Hello', 'world': 'World'});
    });

    test('reads nested JSON', () {
      final file = File('${tempDir.path}/en.json');
      file.writeAsStringSync(
        '{"greetings": {"hello": "Hello", "bye": "Goodbye"}}',
      );

      final result = handler.readJson(tempDir.path, 'en');
      expect(result['greetings'], {'hello': 'Hello', 'bye': 'Goodbye'});
    });

    test('throws FileSystemException for missing file', () {
      expect(
        () => handler.readJson(tempDir.path, 'missing'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('throws FormatException for invalid JSON', () {
      final file = File('${tempDir.path}/bad.json');
      file.writeAsStringSync('not json at all');

      expect(
        () => handler.readJson(tempDir.path, 'bad'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when JSON root is not an object', () {
      final file = File('${tempDir.path}/list.json');
      file.writeAsStringSync('["a", "b"]');

      expect(
        () => handler.readJson(tempDir.path, 'list'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('FileHandler.writeJson', () {
    test('writes JSON to file with pretty-printing', () {
      handler.writeJson(tempDir.path, 'es', {'hola': 'Hola'});

      final file = File('${tempDir.path}/es.json');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('"hola"'));
      expect(content, contains('"Hola"'));
    });

    test('creates intermediate directories', () {
      final nested = '${tempDir.path}/sub/dir';
      handler.writeJson(nested, 'fr', {'bonjour': 'Bonjour'});

      final file = File('$nested/fr.json');
      expect(file.existsSync(), isTrue);
    });

    test('overwrites an existing file', () {
      handler.writeJson(tempDir.path, 'de', {'alt': 'old value'});
      handler.writeJson(tempDir.path, 'de', {'neu': 'new value'});

      final file = File('${tempDir.path}/de.json');
      final content = file.readAsStringSync();
      expect(content, contains('"neu"'));
      expect(content, isNot(contains('"alt"')));
    });

    test('round-trips nested JSON', () {
      final original = {
        'greetings': {'hello': 'Hola', 'bye': 'Adiós'},
        'count': 42,
      };
      handler.writeJson(tempDir.path, 'es', original);

      final result = handler.readJson(tempDir.path, 'es');
      expect(result['greetings'], {'hello': 'Hola', 'bye': 'Adiós'});
      expect(result['count'], 42);
    });
  });
}
