import 'package:file_picker/file_picker.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;

abstract class ImportRepository {
  /// Parses a local file (CSV or Excel) and returns a list of rows `Map<String, dynamic>`.
  Future<List<Map<String, dynamic>>> parseFile(PlatformFile file);

  /// Fetches CSV data from a published Google Sheets URL
  Future<List<Map<String, dynamic>>> fetchFromGoogleSheetsUrl(String url);

  /// Fetches data from Google Sheets API using an authenticated client.
  Future<List<Map<String, dynamic>>> fetchFromGoogleSheetsApi(AuthClient authClient, String spreadsheetId);

  /// Fetches responses from a Google Form API.
  Future<List<Map<String, dynamic>>> fetchFromGoogleForms(AuthClient authClient, String formId);

  /// Lists available Google Forms for the user.
  Future<List<drive.File>> listForms(AuthClient authClient);

  /// Lists available Google Sheets (spreadsheets) for the user.
  Future<List<drive.File>> listSheets(AuthClient authClient);
}
