/// Result of escaping placeholder variables in a string.
class EscapeResult {
  /// The original string with every placeholder replaced by a neutral token
  /// of the form `__VAR_0__`, `__VAR_1__`, etc.
  final String tokenized;

  /// The original placeholder strings in the order they were found, so that
  /// [VariableEscaper.restore] can put them back.
  final List<String> variables;

  const EscapeResult({required this.tokenized, required this.variables});
}

/// Extracts interpolation placeholders from translation strings before they
/// are sent to the translation API, and restores them afterwards.
///
/// Supported placeholder formats:
///   - `{variableName}`        — easy_localization / flutter_i18n
///   - `{{variableName}}`      — Mustache
///   - `%s` / `%d` / `%1$s`   — printf / sprintf
///   - `@variableName`         — Flutter ARB
///   - `${variableName}`       — Dart string interpolation
class VariableEscaper {
  // Single combined regex.  Order within the alternation matters:
  //   1. ${...}   must be tried before plain {...} (starts with $)
  //   2. {{...}}  must be tried before plain {...} (starts with {{)
  //   3. %N$X+    must be tried before %X        (longer form first)
  static final RegExp _pattern = RegExp(
    r'\$\{[^}]+\}'         // ${variableName}  — Dart interpolation
    r'|\{\{[^}]+\}\}'      // {{variableName}} — Mustache
    r'|\{[^{},\s]+\}'      // {variableName}   — easy_localization
                           //   (no commas/spaces → won't match ICU blocks)
    r'|%\d+\$[a-zA-Z]+'   // %1$s, %2$ld, %3$02d — positional printf
    r'|%[sd]'              // %s / %d              — simple printf
    r'|@[a-zA-Z_]\w*',    // @variableName        — ARB style
  );

  /// Replaces every placeholder in [text] with a token `__VAR_N__` and
  /// returns both the tokenized string and the list of original placeholders.
  static EscapeResult escape(String text) {
    final variables = <String>[];
    final tokenized = text.replaceAllMapped(_pattern, (match) {
      variables.add(match.group(0)!);
      return '__VAR_${variables.length - 1}__';
    });
    return EscapeResult(tokenized: tokenized, variables: variables);
  }

  /// Puts the original placeholders back into [translated].
  ///
  /// Returns the restored string on success, or `null` if any token is
  /// missing or appears more than once in [translated] (which would indicate
  /// the translation engine mangled the placeholder).
  static String? restore(String translated, List<String> variables) {
    if (variables.isEmpty) return translated;

    var result = translated;
    for (var i = 0; i < variables.length; i++) {
      final token = '__VAR_${i}__';
      final count = RegExp(RegExp.escape(token)).allMatches(result).length;
      if (count == 0 || count > 1) return null;
      result = result.replaceFirst(token, variables[i]);
    }

    // Guard: no stray tokens must remain in the output.
    if (RegExp(r'__VAR_\d+__').hasMatch(result)) return null;

    return result;
  }
}
