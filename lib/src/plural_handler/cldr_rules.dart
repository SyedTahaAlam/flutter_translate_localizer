/// CLDR plural category data.
///
/// Each entry maps an ISO-639-1 language code to the ordered list of plural
/// categories that language requires, as specified by the Unicode CLDR
/// (https://cldr.unicode.org/index/cldr-spec/plural-rules).
///
/// Only the categories relevant to *cardinal* plurals are listed.
/// Languages not present in this map default to `['one', 'other']`.
const Map<String, List<String>> cldrPluralCategories = {
  'af': ['one', 'other'],
  'ar': ['zero', 'one', 'two', 'few', 'many', 'other'],
  'az': ['one', 'other'],
  'be': ['one', 'few', 'many', 'other'],
  'bg': ['one', 'other'],
  'bn': ['one', 'other'],
  'ca': ['one', 'other'],
  'cs': ['one', 'few', 'many', 'other'],
  'cy': ['zero', 'one', 'two', 'few', 'many', 'other'],
  'da': ['one', 'other'],
  'de': ['one', 'other'],
  'el': ['one', 'other'],
  'en': ['one', 'other'],
  'es': ['one', 'other'],
  'et': ['one', 'other'],
  'eu': ['one', 'other'],
  'fa': ['one', 'other'],
  'fi': ['one', 'other'],
  'fil': ['one', 'other'],
  'fr': ['one', 'many', 'other'],
  'ga': ['one', 'two', 'few', 'many', 'other'],
  'gl': ['one', 'other'],
  'gu': ['one', 'other'],
  'he': ['one', 'two', 'many', 'other'],
  'hi': ['one', 'other'],
  'hr': ['one', 'few', 'other'],
  'hu': ['one', 'other'],
  'hy': ['one', 'other'],
  'id': ['other'],
  'is': ['one', 'other'],
  'it': ['one', 'many', 'other'],
  'ja': ['other'],
  'ka': ['one', 'other'],
  'kk': ['one', 'other'],
  'km': ['other'],
  'kn': ['one', 'other'],
  'ko': ['other'],
  'lt': ['one', 'few', 'many', 'other'],
  'lv': ['zero', 'one', 'other'],
  'mk': ['one', 'other'],
  'ml': ['one', 'other'],
  'mn': ['one', 'other'],
  'mr': ['one', 'other'],
  'ms': ['other'],
  'my': ['other'],
  'nb': ['one', 'other'],
  'ne': ['one', 'other'],
  'nl': ['one', 'other'],
  'or': ['one', 'other'],
  'pa': ['one', 'other'],
  'pl': ['one', 'few', 'many', 'other'],
  'pt': ['one', 'many', 'other'],
  'ro': ['one', 'few', 'other'],
  'ru': ['one', 'few', 'many', 'other'],
  'si': ['one', 'other'],
  'sk': ['one', 'few', 'many', 'other'],
  'sl': ['one', 'two', 'few', 'other'],
  'sq': ['one', 'other'],
  'sr': ['one', 'few', 'other'],
  'sv': ['one', 'other'],
  'sw': ['one', 'other'],
  'ta': ['one', 'other'],
  'te': ['one', 'other'],
  'th': ['other'],
  'tr': ['one', 'other'],
  'uk': ['one', 'few', 'many', 'other'],
  'ur': ['one', 'other'],
  'uz': ['one', 'other'],
  'vi': ['other'],
  'zh': ['other'],
  'zu': ['one', 'other'],
};

/// Default plural categories used when the language is not in [cldrPluralCategories].
const List<String> defaultPluralCategories = ['one', 'other'];

/// Returns the CLDR plural categories required by [languageCode].
///
/// Handles BCP-47 variants (e.g. `zh-TW`, `pt-BR`) by falling back to the
/// base language code.
List<String> getPluralCategories(String languageCode) {
  final base = languageCode.split('-').first.toLowerCase();
  return cldrPluralCategories[base] ?? defaultPluralCategories;
}

/// For a given [targetCategory] that does not exist in the source plural arms,
/// returns the best source category to use as a translation seed.
///
/// Precedence:
///   zero  → other (then many if available, else first available)
///   one   → one   (then other)
///   two   → one   (then other)
///   few   → other (then many)
///   many  → other
///   other → other (always present)
String cldrFallbackCategory(
  String targetCategory,
  List<String> availableSourceCategories,
) {
  final preferences = <String, List<String>>{
    'zero': ['other', 'many', 'few'],
    'one': ['one', 'other'],
    'two': ['one', 'other'],
    'few': ['other', 'many', 'few'],
    'many': ['other', 'many'],
    'other': ['other'],
  };
  final prefs = preferences[targetCategory] ?? ['other'];
  for (final pref in prefs) {
    if (availableSourceCategories.contains(pref)) return pref;
  }
  return availableSourceCategories.first;
}
