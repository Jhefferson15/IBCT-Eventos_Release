import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/forms/v1.dart' as forms;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleFormsDataSource {
  final AuthClient _client;
  late final forms.FormsApi _formsApi;
  late final drive.DriveApi _driveApi;

  GoogleFormsDataSource(this._client) {
    _formsApi = forms.FormsApi(_client);
    _driveApi = drive.DriveApi(_client);
  }

  /// Lists Google Forms from the user's Drive.
  /// Uses a query to filter for strictly 'application/vnd.google-apps.form'.
  Future<List<drive.File>> listForms() async {
    try {
      debugPrint('GoogleFormsDataSource: Listing files with scope...');
      final fileList = await _driveApi.files.list(
        // Query slightly broadened to ensure we catch forms even if mimeType varies slightly or just to test connection
        // q: "mimeType = 'application/vnd.google-apps.form' and trashed = false",
        q: "trashed = false", 
        $fields: "files(id, name, mimeType, createdTime, modifiedTime)",
        pageSize: 50, 
        orderBy: "modifiedTime desc",
      );
      
      final allFiles = fileList.files ?? [];
      debugPrint('GoogleFormsDataSource: Fetched ${allFiles.length} files total.');
      
      // Filter in memory to see what we got
      final forms = allFiles.where((f) => f.mimeType == 'application/vnd.google-apps.form').toList();
      debugPrint('GoogleFormsDataSource: Filtered down to ${forms.length} forms.');
      debugPrint('GoogleFormsDataSource: Types found: ${allFiles.map((e) => e.mimeType).toSet().join(", ")}');

      return forms;
    } catch (e) {
      debugPrint('GoogleFormsDataSource: Error listing forms: $e');
      rethrow;
    }
  }

  /// Gets details of a specific form, including its schema (questions).
  Future<forms.Form> getFormDetails(String formId) async {
    return await _formsApi.forms.get(formId);
  }

  /// Fetches responses from a specific form.
  Future<List<forms.FormResponse>> getFormResponses(String formId) async {
    try {
      final response = await _formsApi.forms.responses.list(formId);
      return response.responses ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
