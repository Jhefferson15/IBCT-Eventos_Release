import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../editor/domain/models/participant_model.dart';

class FileExportDataSource {
  Future<String> generateCsv(List<Participant> participants, List<String> columns) async {
    return compute(_generateCsvIsolate, _ExportData(participants, columns));
  }

  Future<List<int>> generateExcel(List<Participant> participants, List<String> columns) async {
    return compute(_generateExcelIsolate, _ExportData(participants, columns));
  }

  Future<List<int>> generateQrCodeZip(List<Participant> participants) async {
    // QR generation might require platform channel if using some libs, but QrPainter is pure Dart.
    // However, toImage() might need UI binding. 
    // QrPainter.toImageData() uses ui.Image which might be tricky in compute isolate without setup.
    // Let's try running it in main isolate for now if it's not too heavy, or handle carefully.
    // Actually, QrPainter.toImageData returns ByteData.
    
    final archive = Archive();

    for (var p in participants) {
      if (p.token.isEmpty) continue;
      
      final painter = QrPainter(
        data: p.token,
        version: QrVersions.auto,
        gapless: false,
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
      );

      final picData = await painter.toImageData(2048); // High res
      if (picData != null) {
        final pngBytes = picData.buffer.asUint8List();
        final filename = 'qrcode_${p.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim().replaceAll(' ', '_')}_${p.id.substring(0, 4)}.png';
        archive.addFile(ArchiveFile(filename, pngBytes.length, pngBytes));
      }
    }

    final encoder = ZipEncoder();
    return encoder.encode(archive) ?? [];
  }

  Future<List<int>> generateQrCodePdf(List<Participant> participants) async {
    final pdf = pw.Document();

    // Generate QR images first
    final qrImages = <String, Uint8List>{};
    for (var p in participants) {
       if (p.token.isEmpty) continue;
       final painter = QrPainter(
        data: p.token,
        version: QrVersions.auto,
        gapless: false,
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
      );
      final picData = await painter.toImageData(2048);
      if (picData != null) {
        qrImages[p.id] = picData.buffer.asUint8List();
      }
    }

    // Add pages
    // Assuming 1 QR per page for "square pages" as requested "páginas quadrada"? 
    // Or maybe printable format? "um arquivo de pdf completo com páginas quadrada" usually means square page size?
    // Let's assume standard A4 with grid or Square Participants cards.
    // "com páginas quadrada" -> Square pages.
    
    for (var p in participants) {
      if (!qrImages.containsKey(p.id)) continue;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(500, 500), // Square page
          build: (pw.Context context) {
            return pw.Center(
               child: pw.Column(
                 mainAxisAlignment: pw.MainAxisAlignment.center,
                 children: [
                   pw.Text(p.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                   pw.SizedBox(height: 20),
                   pw.Image(pw.MemoryImage(qrImages[p.id]!), width: 300, height: 300),
                   pw.SizedBox(height: 10),
                   pw.Text(p.token, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                 ]
               )
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}

// Helpers for compute
class _ExportData {
  final List<Participant> participants;
  final List<String> columns;

  _ExportData(this.participants, this.columns);
}

Future<String> _generateCsvIsolate(_ExportData data) async {
  final rows = <List<dynamic>>[];
  rows.add(data.columns);

  for (var p in data.participants) {
    final row = <dynamic>[];
    for (var col in data.columns) {
      row.add(_getValueForColumn(p, col));
    }
    rows.add(row);
  }

  return const ListToCsvConverter().convert(rows);
}

Future<List<int>> _generateExcelIsolate(_ExportData data) async {
  final excel = Excel.createExcel();
  final sheet = excel['Participantes'];
  
  // Header
  for (var i = 0; i < data.columns.length; i++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
    cell.value = TextCellValue(data.columns[i]);
  }

  // Data
  for (var i = 0; i < data.participants.length; i++) {
    final p = data.participants[i];
    for (var j = 0; j < data.columns.length; j++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
      final val = _getValueForColumn(p, data.columns[j]);
      cell.value = TextCellValue(val.toString());
    }
  }

  return excel.encode() ?? [];
}

dynamic _getValueForColumn(Participant p, String column) {
  // Map friendly names to fields
  switch (column) {
    case 'Nome': return p.name;
    case 'Email': return p.email;
    case 'Telefone': return p.phone;
    case 'Ingresso': return p.ticketType;
    case 'Status': return p.status;
    case 'Check-in': return p.isCheckedIn ? 'Sim' : 'Não';
    case 'Empresa': return p.company ?? '';
    case 'Cargo': return p.role ?? '';
    case 'CPF': return p.cpf ?? '';
    default: return p.customFields[column] ?? '';
  }
}
