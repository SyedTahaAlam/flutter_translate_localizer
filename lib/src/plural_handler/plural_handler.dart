import 'cldr_rules.dart';

/// A single category arm inside an ICU plural block, e.g. `one{# message}`.
class PluralEntry {
  /// The plural category (zero, one, two, few, many, other).
  final String category;

  /// The raw message content inside the braces, e.g. `# message`.
  final String content;

  const PluralEntry(this.category, this.content);
}

/// A parsed ICU MessageFormat plural block.
///
/// For example:
/// ```
/// {count, plural, one{# message} other{# messages}}
/// ```
/// produces:
/// - [variable] = `count`
/// - [entries]  = [`one` → `# message`, `other` → `# messages`]
class IcuPluralBlock {
  /// The selector variable name (e.g. `count`).
  final String variable;

  /// The plural arms in their original order.
  final List<PluralEntry> entries;

  const IcuPluralBlock(this.variable, this.entries);

  /// Reconstructs the ICU plural string from [entries].
  String reconstruct() {
    final arms =
        entries.map((e) => '${e.category}{${e.content}}').join(' ');
    return '{$variable, plural, $arms}';
  }
}

/// Utilities for detecting and parsing ICU MessageFormat plural strings
/// and for identifying Form-A flat plural key groups.
class PluralHandler {
  // Matches the whole ICU plural block: {variable, plural, <arms>}
  // The [\s\S] at the end handles the arms which may contain spaces/newlines.
  static final RegExp _icuPattern = RegExp(
    r'^\{([^,{}]+),\s*plural,\s*([\s\S]+)\}$',
    dotAll: true,
  );

  // Matches a single plural arm: category{content}
  // Content may contain one level of nested braces (e.g. {name}).
  static final RegExp _armPattern = RegExp(
    r'(zero|one|two|few|many|other)\{((?:[^{}]|\{[^{}]*\})*)\}',
  );

  /// Returns `true` if [text] looks like an ICU plural block.
  static bool isIcuPlural(String text) =>
      _icuPattern.hasMatch(text.trim());

  /// Parses an ICU plural block string into an [IcuPluralBlock].
  ///
  /// Returns `null` if the string is not a valid ICU plural block or contains
  /// no recognisable plural arms.
  static IcuPluralBlock? parse(String text) {
    final match = _icuPattern.firstMatch(text.trim());
    if (match == null) return null;

    final variable = match.group(1)!.trim();
    final armsStr = match.group(2)!;

    final entries = <PluralEntry>[];
    for (final arm in _armPattern.allMatches(armsStr)) {
      entries.add(PluralEntry(arm.group(1)!, arm.group(2)!));
    }

    if (entries.isEmpty) return null;
    return IcuPluralBlock(variable, entries);
  }

  /// Reconstructs an ICU plural block from translated arms, optionally
  /// expanding the category set to match [targetLanguage]'s CLDR rules.
  ///
  /// When [cldrExpand] is `true` and the target language requires categories
  /// not present in [translatedEntries], those extra categories are filled by
  /// picking the translated text of the closest source category according to
  /// the CLDR fallback rules.
  static String reconstructIcu(
    String variable,
    Map<String, String> translatedEntries,
    String targetLanguage, {
    bool cldrExpand = false,
  }) {
    final orderedCategories = [
      'zero',
      'one',
      'two',
      'few',
      'many',
      'other',
    ];

    late List<String> outputCategories;
    if (cldrExpand) {
      outputCategories = getPluralCategories(targetLanguage);
    } else {
      // Preserve the source order while keeping only categories present in
      // the translated map.
      outputCategories = orderedCategories
          .where(translatedEntries.containsKey)
          .toList();
    }

    final arms = <String>[];
    for (final cat in outputCategories) {
      if (translatedEntries.containsKey(cat)) {
        arms.add('$cat{${translatedEntries[cat]}}');
      } else {
        // CLDR expansion: fill missing category from the nearest source form.
        final fallback = cldrFallbackCategory(
          cat,
          translatedEntries.keys.toList(),
        );
        arms.add('$cat{${translatedEntries[fallback]}}');
      }
    }

    return '{$variable, plural, ${arms.join(' ')}}';
  }

  /// Scans [json] for Form-A flat plural groups.
  ///
  /// A plural group is a pair `{key: ..., key_plural: ...}` where both keys
  /// exist in the same map.  Returns a map from base-key to the list of
  /// sibling keys that form the group (always `[baseKey, baseKey_plural]`).
  static Map<String, List<String>> detectPluralGroups(
    Map<String, dynamic> json,
  ) {
    final groups = <String, List<String>>{};
    for (final key in json.keys) {
      if (key.endsWith('_plural')) {
        final base = key.substring(0, key.length - '_plural'.length);
        if (json.containsKey(base) && json[base] is String) {
          groups[base] = [base, key];
        }
      }
    }
    return groups;
  }
}
