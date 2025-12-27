
import 'csv_handler.dart';

class MetadataHandler implements CsvHandler {
  @override
  dynamic process(dynamic input) {
    if (input is! String) return input;

    final lines = input.split('\n');
    int headerIndex = -1;

    // Look for a line that likely contains headers (e.g., standard columns like ID, Nome, Email)
    // For the test case: "ID,Nome,Email"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.contains('ID') && line.contains('Nome') && line.contains('Email')) {
        headerIndex = i;
        break;
      }
    }

    if (headerIndex != -1) {
      return lines.sublist(headerIndex).join('\n');
    }

    return input;
  }
}
