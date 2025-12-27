
import 'dart:io';

abstract class ImportStrategy {
  Future<List<Map<String, dynamic>>> parse(File file);

  /// Helper to convert raw rows to a list of maps using the first row as headers.
  List<Map<String, dynamic>> convertRowsToMap(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];
    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final data = rows.skip(1).toList();

    return data.map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        if (i < row.length) {
          map[headers[i]] = row[i];
        }
      }
      return map;
    }).toList();
  }
}
