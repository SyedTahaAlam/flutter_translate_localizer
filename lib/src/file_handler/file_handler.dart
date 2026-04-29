import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Handles reading source JSON files and writing translated JSON files.
class FileHandler {
  /// Reads a JSON file at [directory]/[languageCode].json and returns the
  /// decoded map.
  ///
  /// Throws [FileSystemException] if the file does not exist.
  /// Throws [FormatException] if the file content is not valid JSON.
  Map<String, dynamic> readJson(
      String directory, String languageCode, String fileExtension,
      {String fileName = ""}) {
    final filePath = p.join(directory, '$fileName$languageCode.$fileExtension');
    final file = File(filePath);

    if (!file.existsSync()) {
      throw FileSystemException(
        'Source JSON file not found.',
        filePath,
      );
    }

    final content = file.readAsStringSync(encoding: utf8);
    final dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw FormatException('Invalid JSON in source file: $filePath');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Source JSON file must contain a JSON object at the top level.',
      );
    }
    return decoded;
  }

  /// Writes [content] as pretty-printed JSON to [directory]/[languageCode].json.
  ///
  /// Creates intermediate directories if they do not exist.
  void writeJson(String directory, String languageCode,
      Map<String, dynamic> content, String fileExtension,
      {String fileName = ""}) {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final filePath = p.join(directory, '$fileName$languageCode.$fileExtension');
    final file = File(filePath);
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(content), encoding: utf8);
  }
}
