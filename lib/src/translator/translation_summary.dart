/// Accumulates statistics for the translation run and prints a human-readable
/// summary at the end.
class TranslationSummary {
  /// Total number of leaf string values successfully translated.
  int keysTranslated = 0;

  /// Number of keys where a placeholder token was missing or duplicated in the
  /// translated output (fell back to original string).
  int keysWithVarWarnings = 0;

  /// Number of ICU plural blocks whose category set was expanded to match the
  /// target language's CLDR plural rules.
  int pluralGroupsExpanded = 0;

  /// Prints the three-line summary to stdout.
  void printSummary() {
    print('✔ Keys translated: $keysTranslated');
    print('⚠ Keys with variable warnings: $keysWithVarWarnings');
    print('✎ Plural groups expanded: $pluralGroupsExpanded');
  }
}
