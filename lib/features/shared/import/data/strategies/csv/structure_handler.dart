
import 'csv_handler.dart';

class StructureHandler implements CsvHandler<List<List<dynamic>>> {
  @override
  List<List<dynamic>> process(List<List<dynamic>> rows) {
    if (rows.isEmpty) return rows;

    final header = rows.first;
    final expectedColumns = header.length;
    final cleanedRows = <List<dynamic>>[];

    // Add header
    cleanedRows.add(header);

    for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        
        // 1. Ghost Headers: Skip if row looks exactly like header
        if (row.length == header.length && 
            row.toString() == header.toString()) {
            continue; 
        }

        // 2. Ragged Rows: Fix lengths
        if (row.length < expectedColumns) {
           // Pad with empty strings
           final padded = List<dynamic>.from(row);
           while (padded.length < expectedColumns) {
             padded.add('');
           }
           cleanedRows.add(padded);
        } else if (row.length > expectedColumns) {
           // Trim extra columns (or merge last ones if we were smarter, but trim is safer)
           cleanedRows.add(row.take(expectedColumns).toList());
        } else {
           cleanedRows.add(row);
        }
    }

    return cleanedRows;
  }
}
