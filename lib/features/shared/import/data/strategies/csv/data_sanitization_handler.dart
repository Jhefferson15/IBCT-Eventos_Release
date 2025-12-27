
import 'csv_handler.dart';

class DataSanitizationHandler implements CsvHandler<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> process(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final newRow = <String, dynamic>{};
      row.forEach((key, value) {
        newRow[key] = _sanitizeValue(key, value);
      });
      return newRow;
    }).toList();
  }

  dynamic _sanitizeValue(String key, dynamic value) {
     if (value == null) return '';
     final strVal = value.toString().trim();
     final lowerKey = key.toLowerCase();

     // Boolean normalization
     if (['sim', 'yes', 'true', '1'].contains(strVal.toLowerCase())) return 'true';
     if (['não', 'nao', 'no', 'false', '0'].contains(strVal.toLowerCase())) return 'false';
     
     // Date normalization (Simple heuristics for now)
     // Dealing with DD/MM/YYYY vs YYYY-MM-DD vs MM-DD-YYYY is complex without locale context.
     // For now we just trim. Ideally we'd parse and standardize to ISO8601 string.
     if (lowerKey.contains('data') || lowerKey.contains('date')) {
        // Replace / with - to help standard parsing later
        return strVal.replaceAll('/', '-'); 
     }

     return strVal;
  }
}
