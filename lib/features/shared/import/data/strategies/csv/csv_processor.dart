
import 'dart:io';
import 'package:csv/csv.dart';
import 'encoding_handler.dart';

import 'structure_handler.dart';
import 'data_sanitization_handler.dart';
import 'csv_sniffer.dart';

class CsvProcessor {
  /// Entry point for compute isolate with File
  static Future<List<Map<String, dynamic>>> process(File file) async {
    // 1. Encoding (File -> String)
    String content = EncodingHandler().process(file);
    return _processContent(content);
  }

  /// Entry point for compute isolate with String
  static Future<List<Map<String, dynamic>>> processString(String content) async {
    return _processContent(content);
  }

  static List<Map<String, dynamic>> _processContent(String content) {
    if (content.trim().isEmpty) {
      throw Exception('O arquivo está vazio ou não pôde ser lido (Conteúdo vazio).');
    }

    // 2. Formatting Sniffing
    // STRATEGY: Try standard Parse first (Comma, Auto-EOL).
    // If the file is nice, this is fast and safe.
    List<List<dynamic>> rows = const CsvToListConverter(
      fieldDelimiter: ',',
      shouldParseNumbers: false,
      allowInvalid: true,
    ).convert(content); // CsvToListConverter defaults to auto-eol detection if not specified? Verify. 
    // Actually defaultValue for eol is null, which handles \r\n and \n.

    bool standardParseIsGood = false;
    if (rows.isNotEmpty) {
      final firstRowLen = rows.first.length;
      if (firstRowLen > 1 && rows.every((r) => r.length == firstRowLen)) {
         // Perfect table.
         standardParseIsGood = true;
      }
    }

    if (!standardParseIsGood) {
       // Only sniff if standard failed (1 col, or ragged)
       final sniffer = CsvSniffer();
       final config = sniffer.sniff(content);
       
       rows = CsvToListConverter(
          fieldDelimiter: config.fieldDelimiter,
          eol: config.eol,
          shouldParseNumbers: false, 
          allowInvalid: true,
        ).convert(content);
    }
    
    if (rows.isEmpty) {
      throw Exception('A conversão do CSV falhou (0 linhas detectadas). Verifique o formato do arquivo.');
    }

    // SANITY CHECK: Check for "Column Explosion"
    // If we have > 100 columns, it's very likely the EOL detection failed or the file is binary garbage.
    if (rows.first.length > 100) {
       throw Exception('Falha Crítica de Formato: Detectadas ${rows.first.length} colunas em uma linha. O arquivo provavelmente não é um CSV válido ou usa uma quebra de linha desconhecida.');
    }

    // 4. Structure Fixes (Ragged Rows / Ghost Headers)
    rows = StructureHandler().process(rows);
    
    // RECOVERY: If we only have 1 row left, it might be a headerless file or a single entry.
    // Instead of failing, let's auto-generate headers so the user can map it.
    if (rows.length == 1) {
       final singleRow = rows.first;
       // Generate headers: Coluna 1, Coluna 2...
       final generatedHeader = List.generate(singleRow.length, (i) => 'Coluna ${i + 1}');
       rows = [generatedHeader, singleRow];
    }
    
    if (rows.isEmpty) {
      throw Exception('Todas as linhas foram removidas durante a correção de estrutura. O arquivo pode estar mal formatado.');
    }

    // 5. Convert to Map
    List<Map<String, dynamic>> mapRows = _convertRowsToMap(rows);
    
    if (mapRows.isEmpty) {
       // Should not happen with the recovery above, but just in case
       throw Exception('Falha ao mapear colunas. O processador detectou linhas mas não conseguiu converter.');
    }

    // 6. Data Sanitization
    mapRows = DataSanitizationHandler().process(mapRows);
    
    if (mapRows.isEmpty) {
      throw Exception('Todos os dados foram removidos na sanitização.');
    }

    return mapRows;
  }

  static List<Map<String, dynamic>> _convertRowsToMap(List<List<dynamic>> rows) {
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
