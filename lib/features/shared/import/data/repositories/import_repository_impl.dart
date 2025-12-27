import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import '../../domain/repositories/import_repository_interface.dart';
import '../datasources/google_forms_data_source.dart';
import '../datasources/google_sheets_data_source.dart';
import '../strategies/csv_import_strategy.dart';
import '../strategies/excel_import_strategy.dart';
import '../strategies/import_strategy.dart';

class ImportRepositoryImpl implements ImportRepository {
  @override
  Future<List<Map<String, dynamic>>> parseFile(PlatformFile file) async {
    ImportStrategy strategy;

    if (file.extension == 'csv') {
      strategy = CsvImportStrategy();
    } else if (file.extension == 'xlsx' || file.extension == 'xls') {
      strategy = ExcelImportStrategy();
    } else {
      throw Exception('Unsupported file format');
    }

    return await strategy.parse(File(file.path!));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFromGoogleSheetsUrl(String url) async {
    // Convert 'edit?USP=sharing' logic to 'export?format=csv' if needed
    // Simple heuristic: if it contains /edit, replace with /export?format=csv
    String csvUrl = url;
    if (url.contains('/edit')) {
       csvUrl = '${url.split('/edit').first}/export?format=csv';
    }

    try {
      final response = await http.get(Uri.parse(csvUrl));
      if (response.statusCode == 200) {
         return await CsvImportStrategy().parseContent(response.body);
      } else {
        throw Exception('Failed to fetch Google Sheets: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching sheets: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFromGoogleSheetsApi(AuthClient authClient, String spreadsheetId) async {
    final sheetsDataSource = GoogleSheetsDataSource(authClient);
    
    // 1. Get Values
    // Try to get first sheet name
    final spreadsheet = await sheetsDataSource.getSpreadsheetDetails(spreadsheetId);
    final firstSheetTitle = spreadsheet.sheets?.firstOrNull?.properties?.title;
    
    if (firstSheetTitle == null) {
      throw Exception('Nenhuma aba encontrada na planilha.');
    }

    final rows = await sheetsDataSource.getSheetValues(spreadsheetId, firstSheetTitle);
    
    if (rows.isEmpty) return [];

    // 2. Parse Headers (first row)
    final headers = rows.first.map((e) => e.toString()).toList();
    final dataRows = rows.skip(1).toList();

    // 3. Parse Data
    return dataRows.map((row) {
      final map = <String, dynamic>{};
      for (int i = 0; i < headers.length; i++) {
        if (i < row.length) {
          map[headers[i]] = row[i]?.toString() ?? '';
        } else {
          map[headers[i]] = '';
        }
      }
      return map;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFromGoogleForms(AuthClient authClient, String formId) async {
    final formsDataSource = GoogleFormsDataSource(authClient);
    
    // 1. Get Form Details to map Question IDs to Titles
    final formDetails = await formsDataSource.getFormDetails(formId);
    final questionMap = <String, String>{}; // questionId -> title logic

    if (formDetails.items != null) {
      for (var item in formDetails.items!) {
        final qItem = item.questionItem;
        if (qItem != null && qItem.question != null && qItem.question!.questionId != null) {
          questionMap[qItem.question!.questionId!] = item.title ?? 'Untitled Question';
        }
      }
    }

    // 2. Get Responses
    final responses = await formsDataSource.getFormResponses(formId);

    // 3. Convert to Map<String, dynamic> using Titles as keys
    return responses.map((r) {
      final map = <String, dynamic>{
        'responseId': r.responseId,
        'createTime': r.createTime,
        'email': r.respondentEmail ?? '', // Collected email if available
      };

      if (r.answers != null) {
        r.answers!.forEach((questionId, answer) {
          final title = questionMap[questionId] ?? questionId;
          // Join multiple values if checkbox, otherwise just take first
          final value = answer.textAnswers?.answers?.map((a) => a.value).join(', ') ?? '';
          map[title] = value;
        });
      }
      return map;
    }).toList();
  }
  @override
  Future<List<drive.File>> listForms(AuthClient authClient) async {
    final formsDataSource = GoogleFormsDataSource(authClient);
    return await formsDataSource.listForms();
  }

  @override
  Future<List<drive.File>> listSheets(AuthClient authClient) async {
    final sheetsDataSource = GoogleSheetsDataSource(authClient);
    return await sheetsDataSource.listSheets();
  }
}
