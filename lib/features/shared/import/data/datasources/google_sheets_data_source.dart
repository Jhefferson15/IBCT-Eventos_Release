import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleSheetsDataSource {
  final AuthClient _client;
  late final sheets.SheetsApi _sheetsApi;
  late final drive.DriveApi _driveApi;

  GoogleSheetsDataSource(this._client) {
    _sheetsApi = sheets.SheetsApi(_client);
    _driveApi = drive.DriveApi(_client);
  }

  /// Lists Google Sheets from the user's Drive.
  Future<List<drive.File>> listSheets() async {
    try {
      debugPrint('GoogleSheetsDataSource: Listing files with scope...');
      final fileList = await _driveApi.files.list(
        q: "mimeType = 'application/vnd.google-apps.spreadsheet' and trashed = false",
        $fields: "files(id, name, mimeType, createdTime, modifiedTime)",
        pageSize: 50,
        orderBy: "modifiedTime desc",
      );
      
      final allFiles = fileList.files ?? [];
      debugPrint('GoogleSheetsDataSource: Fetched ${allFiles.length} sheets.');
      return allFiles;
    } catch (e) {
      debugPrint('GoogleSheetsDataSource: Error listing sheets: $e');
      rethrow;
    }
  }

  /// Gets details of a specific spreadsheet.
  Future<sheets.Spreadsheet> getSpreadsheetDetails(String spreadsheetId) async {
    return await _sheetsApi.spreadsheets.get(spreadsheetId);
  }

  /// Fetches values from a specific sheet range.
  /// If range is null, it typically fetches the first sheet entire content or requires a range.
  /// For now, we will assume we want to read the first sheet or allow passing a range.
  Future<List<List<Object?>>> getSheetValues(String spreadsheetId, String range) async {
    try {
      final response = await _sheetsApi.spreadsheets.values.get(spreadsheetId, range);
      return response.values ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
