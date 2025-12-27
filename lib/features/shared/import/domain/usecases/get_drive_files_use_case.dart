import 'package:googleapis/drive/v3.dart' as drive;
import '../../../../auth/domain/repositories/auth_repository_interface.dart';
import '../../domain/repositories/import_repository_interface.dart';

class GetDriveFilesUseCase {
  final IAuthRepository _authRepository;
  final ImportRepository _importRepository;

  GetDriveFilesUseCase(this._authRepository, this._importRepository);

  Future<List<drive.File>> execute({required bool isSpreadsheet}) async {
    final client = await _authRepository.requestFormsAccess();
    if (client == null) {
      throw Exception('Autenticação cancelada ou falhou.');
    }

    if (isSpreadsheet) {
      return _importRepository.listSheets(client);
    } else {
      return _importRepository.listForms(client);
    }
  }
}
