
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'import_strategy.dart';
import 'csv/csv_processor.dart';

class CsvImportStrategy extends ImportStrategy {
  @override
  Future<List<Map<String, dynamic>>> parse(File file) async {
    // Run the processor in a background isolate
    return await compute(CsvProcessor.process, file);
  }

  // parseContent is removed/deprecated as logic is now centralized in CsvProcessor/Handlers.
  // If we need string parsing from URL, we should likely refactor ImportService to download 
  // to a temp file or update CsvProcessor to accept String input (but compute needs simple args).
  // For now, let's keep a simple parseContent that re-uses logic if possible or warns.
  // Actually, to support Google Sheets (which returns String body), we should add a processString method to CsvProcessor.
  
  Future<List<Map<String, dynamic>>> parseContent(String input) async {
     // For string content (e.g. from Google Sheets), we can compute as well
     return await compute(CsvProcessor.processString, input);
  }
}
