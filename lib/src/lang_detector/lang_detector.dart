/// Very lightweight script-based language detector.
///
/// This is used to avoid re-translating strings that are already written in
/// the target language.  It works by counting characters that belong to the
/// primary Unicode block(s) of a language's writing system and comparing them
/// against a threshold.  It intentionally avoids any external dependencies.
class LangDetector {
  /// Returns `true` when [text] appears to already be written in [languageCode].
  ///
  /// For Latin-script languages the function returns `false` (i.e., we never
  /// skip Latin strings since they might simply be proper nouns or English
  /// loanwords in the source file).
  ///
  /// For non-Latin script languages (Arabic, CJK, Cyrillic, Hebrew, etc.)
  /// the function returns `true` when more than [threshold] fraction of the
  /// letters in [text] belong to that script.
  static bool isAlreadyInLanguage(
    String text, {
    required String languageCode,
    double threshold = 0.4,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final script = _scriptForLanguage(languageCode);
    if (script == null) return false; // Latin: never skip.

    final letters = trimmed.runes.where((r) => _isLetter(r)).toList();
    if (letters.isEmpty) return false;

    final matching = letters.where((r) => _inRange(r, script)).length;
    return matching / letters.length >= threshold;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static _ScriptRange? _scriptForLanguage(String lang) {
    final base = lang.split('-').first.toLowerCase();
    return _scriptMap[base];
  }

  static bool _isLetter(int rune) =>
      (rune >= 0x0041 && rune <= 0x005A) || // A-Z
      (rune >= 0x0061 && rune <= 0x007A) || // a-z
      rune > 0x00FF; // Any non-ASCII character is treated as a letter.

  static bool _inRange(int rune, _ScriptRange range) {
    for (var i = 0; i < range.ranges.length; i += 2) {
      if (rune >= range.ranges[i] && rune <= range.ranges[i + 1]) return true;
    }
    return false;
  }

  /// Map from BCP-47 base language code to the Unicode code-point ranges that
  /// cover the primary script of that language.
  static const Map<String, _ScriptRange> _scriptMap = {
    // Arabic
    'ar': _ScriptRange([0x0600, 0x06FF, 0x0750, 0x077F]),
    // Hebrew
    'he': _ScriptRange([0x0590, 0x05FF]),
    // Cyrillic (Russian, Ukrainian, Bulgarian, Serbian, …)
    'ru': _ScriptRange([0x0400, 0x04FF]),
    'uk': _ScriptRange([0x0400, 0x04FF]),
    'bg': _ScriptRange([0x0400, 0x04FF]),
    'be': _ScriptRange([0x0400, 0x04FF]),
    'sr': _ScriptRange([0x0400, 0x04FF]),
    'mk': _ScriptRange([0x0400, 0x04FF]),
    // Greek
    'el': _ScriptRange([0x0370, 0x03FF, 0x1F00, 0x1FFF]),
    // Devanagari (Hindi, Marathi, Nepali)
    'hi': _ScriptRange([0x0900, 0x097F]),
    'mr': _ScriptRange([0x0900, 0x097F]),
    'ne': _ScriptRange([0x0900, 0x097F]),
    // Bengali
    'bn': _ScriptRange([0x0980, 0x09FF]),
    // Tamil
    'ta': _ScriptRange([0x0B80, 0x0BFF]),
    // Telugu
    'te': _ScriptRange([0x0C00, 0x0C7F]),
    // Kannada
    'kn': _ScriptRange([0x0C80, 0x0CFF]),
    // Malayalam
    'ml': _ScriptRange([0x0D00, 0x0D7F]),
    // Sinhala
    'si': _ScriptRange([0x0D80, 0x0DFF]),
    // Thai
    'th': _ScriptRange([0x0E00, 0x0E7F]),
    // Lao
    'lo': _ScriptRange([0x0E80, 0x0EFF]),
    // Tibetan
    'bo': _ScriptRange([0x0F00, 0x0FFF]),
    // Myanmar
    'my': _ScriptRange([0x1000, 0x109F]),
    // Georgian
    'ka': _ScriptRange([0x10A0, 0x10FF]),
    // Ethiopic (Amharic)
    'am': _ScriptRange([0x1200, 0x137F]),
    // CJK (Chinese, Japanese, Korean share many code points)
    'zh': _ScriptRange([0x4E00, 0x9FFF, 0x3400, 0x4DBF]),
    'ja': _ScriptRange([
      0x3040, 0x309F, // Hiragana
      0x30A0, 0x30FF, // Katakana
      0x4E00, 0x9FFF, // Kanji
    ]),
    'ko': _ScriptRange([0xAC00, 0xD7AF]),
  };
}

/// Holds a flat list of [start, end, start, end, …] Unicode code-point pairs.
class _ScriptRange {
  final List<int> ranges;
  const _ScriptRange(this.ranges);
}
