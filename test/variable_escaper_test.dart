import 'package:flutter_translate_localizer/src/variable_escaper/variable_escaper.dart';
import 'package:test/test.dart';

void main() {
  group('VariableEscaper.escape', () {
    test('escapes {variableName} easy_localization style', () {
      final result = VariableEscaper.escape('Hello {name}');
      expect(result.tokenized, 'Hello __VAR_0__');
      expect(result.variables, ['{name}']);
    });

    test('escapes {{variableName}} mustache style', () {
      final result = VariableEscaper.escape('Hello {{name}}');
      expect(result.tokenized, 'Hello __VAR_0__');
      expect(result.variables, ['{{name}}']);
    });

    test(r'escapes ${variableName} Dart interpolation style', () {
      final result = VariableEscaper.escape(r'Hello ${name}');
      expect(result.tokenized, 'Hello __VAR_0__');
      expect(result.variables, [r'${name}']);
    });

    test('escapes %s printf style', () {
      final result = VariableEscaper.escape('Hello %s');
      expect(result.tokenized, 'Hello __VAR_0__');
      expect(result.variables, ['%s']);
    });

    test('escapes %d printf style', () {
      final result = VariableEscaper.escape('Count: %d');
      expect(result.tokenized, 'Count: __VAR_0__');
      expect(result.variables, ['%d']);
    });

    test('escapes %1\$s positional printf style', () {
      final result = VariableEscaper.escape('Hello %1\$s');
      expect(result.tokenized, 'Hello __VAR_0__');
      expect(result.variables, ['%1\$s']);
    });

    test('escapes multi-character positional printf like %1\$ld', () {
      final result = VariableEscaper.escape('Value is %1\$ld');
      expect(result.tokenized, 'Value is __VAR_0__');
      expect(result.variables, ['%1\$ld']);
    });

    test('escapes multi-character positional printf like %2\$02d', () {
      final result = VariableEscaper.escape('Index %2\$02d');
      expect(result.tokenized, 'Index __VAR_0__');
      expect(result.variables, ['%2\$02d']);
    });

    test('escapes @variableName ARB style', () {
      final result = VariableEscaper.escape('Hello @name');
      expect(result.tokenized, 'Hello __VAR_0__');
      expect(result.variables, ['@name']);
    });

    test('escapes multiple variables and assigns sequential tokens', () {
      final result =
          VariableEscaper.escape('Welcome {firstName}, you have {count} messages');
      expect(result.tokenized,
          'Welcome __VAR_0__, you have __VAR_1__ messages');
      expect(result.variables, ['{firstName}', '{count}']);
    });

    test('returns empty variables list when no placeholders present', () {
      final result = VariableEscaper.escape('No placeholders here');
      expect(result.tokenized, 'No placeholders here');
      expect(result.variables, isEmpty);
    });

    test('does not escape ICU plural blocks (contains comma+space)', () {
      const icu = '{count, plural, one{# item} other{# items}}';
      final result = VariableEscaper.escape(icu);
      // The outer ICU braces contain a comma so they must NOT be escaped.
      expect(result.variables, isEmpty);
    });

    test('prefers {{...}} over {...} for mustache', () {
      final result = VariableEscaper.escape('Hello {{world}}');
      // Should match the double-brace form, not split into two single-brace tokens.
      expect(result.variables, ['{{world}}']);
    });
  });

  group('VariableEscaper.restore', () {
    test('restores single placeholder', () {
      final result = VariableEscaper.restore('Hola __VAR_0__', ['{name}']);
      expect(result, 'Hola {name}');
    });

    test('restores multiple placeholders', () {
      final result = VariableEscaper.restore(
        'مرحباً __VAR_0__، لديك __VAR_1__ رسالة',
        ['{firstName}', '{count}'],
      );
      expect(result, 'مرحباً {firstName}، لديك {count} رسالة');
    });

    test('returns original string unchanged when no variables', () {
      final result = VariableEscaper.restore('Hola', []);
      expect(result, 'Hola');
    });

    test('returns null when a token is missing in translated string', () {
      // __VAR_0__ was dropped by the translation engine.
      final result = VariableEscaper.restore('Hola mundo', ['{name}']);
      expect(result, isNull);
    });

    test('returns null when a token appears more than once', () {
      final result = VariableEscaper.restore(
        '__VAR_0__ and __VAR_0__',
        ['{name}'],
      );
      expect(result, isNull);
    });

    test('returns null when stray tokens remain after restoration', () {
      // Two variables but only one token in translated output.
      final result = VariableEscaper.restore(
        '__VAR_0__',
        ['{a}', '{b}'],
      );
      expect(result, isNull);
    });

    test('round-trip: escape then restore recovers original string', () {
      const original = r'Welcome ${user}, you have {count} messages at %s';
      final escaped = VariableEscaper.escape(original);
      final restored = VariableEscaper.restore(escaped.tokenized, escaped.variables);
      expect(restored, original);
    });
  });
}
