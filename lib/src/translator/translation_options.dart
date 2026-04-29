/// Options that control the v2 translation pipeline.
///
/// All features are opt-in and default to disabled so that v1 behaviour is
/// preserved when no flags are supplied.
class TranslationOptions {
  /// Escape interpolation placeholders before translation and restore them
  /// afterwards (Feature 1 — `--escape-vars`).
  final bool escapeVars;

  /// Detect and handle plural keys — both ICU MessageFormat (Form B) and
  /// flat `_plural`-suffixed keys (Form A) — before translating
  /// (`--handle-plurals`).
  final bool handlePlurals;

  /// When [handlePlurals] is enabled, automatically expand ICU plural arms to
  /// match the full set of CLDR plural categories required by the target
  /// language (`--cldr-expand`).
  final bool cldrExpand;

  /// Print what would be translated without calling the translation API
  /// (`--dry-run`).
  final bool dryRun;

  /// If non-null, any key whose fully-qualified dotted path matches this
  /// pattern is left untranslated (`--skip-keys`).
  final RegExp? skipKeys;

  const TranslationOptions({
    this.escapeVars = false,
    this.handlePlurals = true,
    this.cldrExpand = false,
    this.dryRun = true,
    this.skipKeys,
  });
}
