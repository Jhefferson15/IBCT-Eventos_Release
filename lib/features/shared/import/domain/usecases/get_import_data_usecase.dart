import 'package:file_picker/file_picker.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import '../repositories/import_repository_interface.dart';

class GetImportDataUseCase {
  final ImportRepository _repository;

  GetImportDataUseCase(this._repository);

  Future<List<Map<String, dynamic>>> execute({
    PlatformFile? file,
    String? googleSheetsUrl,
    String? spreadsheetId,
    String? formId,
    AuthClient? authClient,
  }) {
    if (file != null) {
      return _repository.parseFile(file);
    } else if (googleSheetsUrl != null) {
      return _repository.fetchFromGoogleSheetsUrl(googleSheetsUrl);
    } else if (spreadsheetId != null && authClient != null) {
      return _repository.fetchFromGoogleSheetsApi(authClient, spreadsheetId);
    } else if (formId != null && authClient != null) {
      return _repository.fetchFromGoogleForms(authClient, formId);
    } else {
      throw Exception('Invalid arguments for GetImportDataUseCase');
    }
  }
}
