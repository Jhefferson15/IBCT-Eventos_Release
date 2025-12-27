
import 'dart:io';
import 'package:excel/excel.dart';
import 'import_strategy.dart';

class ExcelImportStrategy extends ImportStrategy {
  @override
  Future<List<Map<String, dynamic>>> parse(File file) async {
    var bytes = await file.readAsBytes();
    var excel = Excel.decodeBytes(bytes);
    
    // Assuming data is in the first sheet
    final table = excel.tables[excel.tables.keys.first];
    if (table == null) return [];
    
    // Convert rows to List<List<dynamic>>
    List<List<dynamic>> rows = [];
    for (var row in table.rows) {
      rows.add(row.map((e) => e?.value).toList());
    }
    return convertRowsToMap(rows);
  }
}
