
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/file_export_data_source.dart';

final exportServiceProvider = Provider<FileExportDataSource>((ref) {
  return FileExportDataSource();
});
