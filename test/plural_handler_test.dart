import 'package:flutter_translate_localizer/src/plural_handler/cldr_rules.dart';
import 'package:flutter_translate_localizer/src/plural_handler/plural_handler.dart';
import 'package:test/test.dart';

void main() {
  // -------------------------------------------------------------------------
  // PluralHandler.isIcuPlural
  // -------------------------------------------------------------------------
  group('PluralHandler.isIcuPlural', () {
    test('returns true for a valid ICU plural block', () {
      expect(
        PluralHandler.isIcuPlural(
          '{count, plural, one{# message} other{# messages}}',
        ),
        isTrue,
      );
    });

    test('returns false for a plain string', () {
      expect(PluralHandler.isIcuPlural('Hello world'), isFalse);
    });

    test('returns false for a simple {variable} placeholder', () {
      expect(PluralHandler.isIcuPlural('{name}'), isFalse);
    });

    test('returns false for partial ICU (missing closing brace)', () {
      expect(
        PluralHandler.isIcuPlural('{count, plural, one{# item} other{# items}'),
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // PluralHandler.parse
  // -------------------------------------------------------------------------
  group('PluralHandler.parse', () {
    test('parses a two-form ICU plural block', () {
      final block = PluralHandler.parse(
        '{count, plural, one{# message} other{# messages}}',
      );
      expect(block, isNotNull);
      expect(block!.variable, 'count');
      expect(block.entries.length, 2);
      expect(block.entries[0].category, 'one');
      expect(block.entries[0].content, '# message');
      expect(block.entries[1].category, 'other');
      expect(block.entries[1].content, '# messages');
    });

    test('parses all six Arabic plural categories', () {
      const input =
          '{count, plural, zero{# رسائل} one{# رسالة} two{# رسالتان} '
          'few{# رسائل} many{# رسالة} other{# رسائل}}';
      final block = PluralHandler.parse(input);
      expect(block, isNotNull);
      expect(block!.entries.map((e) => e.category),
          ['zero', 'one', 'two', 'few', 'many', 'other']);
    });

    test('returns null for a non-ICU string', () {
      expect(PluralHandler.parse('Hello world'), isNull);
    });

    test('parses content with nested {variable} placeholders', () {
      final block = PluralHandler.parse(
        '{n, plural, one{{name} has one item} other{{name} has {n} items}}',
      );
      expect(block, isNotNull);
      expect(block!.entries[0].content, '{name} has one item');
      expect(block.entries[1].content, '{name} has {n} items');
    });
  });

  // -------------------------------------------------------------------------
  // IcuPluralBlock.reconstruct
  // -------------------------------------------------------------------------
  group('IcuPluralBlock.reconstruct', () {
    test('reconstructs an ICU block from parsed entries', () {
      final block = PluralHandler.parse(
        '{count, plural, one{# item} other{# items}}',
      )!;
      expect(
        block.reconstruct(),
        '{count, plural, one{# item} other{# items}}',
      );
    });
  });

  // -------------------------------------------------------------------------
  // PluralHandler.reconstructIcu (with / without cldrExpand)
  // -------------------------------------------------------------------------
  group('PluralHandler.reconstructIcu', () {
    test('preserves source categories when cldrExpand is false', () {
      final result = PluralHandler.reconstructIcu(
        'count',
        {'one': '# Nachricht', 'other': '# Nachrichten'},
        'de',
      );
      expect(result, '{count, plural, one{# Nachricht} other{# Nachrichten}}');
    });

    test('expands to full Arabic categories when cldrExpand is true', () {
      final result = PluralHandler.reconstructIcu(
        'count',
        {'one': '# رسالة', 'other': '# رسائل'},
        'ar',
        cldrExpand: true,
      );
      // Arabic needs: zero, one, two, few, many, other
      expect(result, contains('zero{'));
      expect(result, contains('one{'));
      expect(result, contains('two{'));
      expect(result, contains('few{'));
      expect(result, contains('many{'));
      expect(result, contains('other{'));
      // The reconstructed string must be syntactically valid ICU.
      expect(result, startsWith('{count, plural,'));
      expect(result, endsWith('}'));
    });

    test('fills missing categories using CLDR fallback content', () {
      // Source only has 'other'; target (ar) also needs 'one', etc.
      final result = PluralHandler.reconstructIcu(
        'n',
        {'other': '# items'},
        'ar',
        cldrExpand: true,
      );
      // All six Arabic categories must appear.
      for (final cat in ['zero', 'one', 'two', 'few', 'many', 'other']) {
        expect(result, contains('$cat{'), reason: 'Missing category: $cat');
      }
    });
  });

  // -------------------------------------------------------------------------
  // PluralHandler.detectPluralGroups (Form A)
  // -------------------------------------------------------------------------
  group('PluralHandler.detectPluralGroups', () {
    test('detects a simple base + _plural pair', () {
      final json = {
        'apple': 'apple',
        'apple_plural': 'apples',
        'orange': 'orange',
      };
      final groups = PluralHandler.detectPluralGroups(json);
      expect(groups.keys, contains('apple'));
      expect(groups['apple'], ['apple', 'apple_plural']);
      expect(groups.keys, isNot(contains('orange')));
    });

    test('ignores _plural keys without a matching base key', () {
      final json = {'apple_plural': 'apples'};
      final groups = PluralHandler.detectPluralGroups(json);
      expect(groups, isEmpty);
    });

    test('ignores base keys whose value is not a string', () {
      final json = {'item': 42, 'item_plural': 'items'};
      final groups = PluralHandler.detectPluralGroups(json);
      expect(groups, isEmpty);
    });

    test('detects multiple plural groups in the same map', () {
      final json = {
        'cat': 'cat',
        'cat_plural': 'cats',
        'dog': 'dog',
        'dog_plural': 'dogs',
      };
      final groups = PluralHandler.detectPluralGroups(json);
      expect(groups.keys, containsAll(['cat', 'dog']));
    });
  });

  // -------------------------------------------------------------------------
  // CLDR rules
  // -------------------------------------------------------------------------
  group('getPluralCategories', () {
    test('returns correct categories for Arabic', () {
      expect(
        getPluralCategories('ar'),
        ['zero', 'one', 'two', 'few', 'many', 'other'],
      );
    });

    test('returns correct categories for English', () {
      expect(getPluralCategories('en'), ['one', 'other']);
    });

    test('returns correct categories for Russian', () {
      expect(getPluralCategories('ru'), ['one', 'few', 'many', 'other']);
    });

    test('defaults to [one, other] for unknown language', () {
      expect(getPluralCategories('xx'), ['one', 'other']);
    });

    test('handles BCP-47 variant codes like pt-BR', () {
      // pt maps to ['one', 'many', 'other']
      expect(getPluralCategories('pt-BR'), ['one', 'many', 'other']);
    });
  });

  // -------------------------------------------------------------------------
  // cldrFallbackCategory
  // -------------------------------------------------------------------------
  group('cldrFallbackCategory', () {
    test('maps zero to other when available', () {
      expect(
        cldrFallbackCategory('zero', ['one', 'other']),
        'other',
      );
    });

    test('maps two to one when available', () {
      expect(
        cldrFallbackCategory('two', ['one', 'other']),
        'one',
      );
    });

    test('maps few to other when many is not available', () {
      expect(
        cldrFallbackCategory('few', ['one', 'other']),
        'other',
      );
    });
  });
}
