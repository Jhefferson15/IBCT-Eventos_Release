
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../editor/domain/models/participant_model.dart';
import '../providers/export_providers.dart';

class ExportOptionsDialog extends ConsumerStatefulWidget {
  final List<Participant> participants;
  final String eventName;

  const ExportOptionsDialog({
    super.key,
    required this.participants,
    required this.eventName,
  });

  @override
  ConsumerState<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends ConsumerState<ExportOptionsDialog> {
  String _selectedFormat = 'CSV'; // CSV, Excel, QR_ZIP, QR_PDF
  final Map<String, bool> _selectedColumns = {
    'Nome': true,
    'Email': true,
    'Telefone': true,
    'Ingresso': true,
    'Status': true,
    'Check-in': true,
    'Empresa': false,
    'Cargo': false,
    'CPF': false,
  };
  bool _isExporting = false;

  void _toggleColumn(String column) {
    setState(() {
      _selectedColumns[column] = !(_selectedColumns[column] ?? false);
    });
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final service = ref.read(exportServiceProvider);
      final sanitizedEventName = widget.eventName.replaceAll(RegExp(r'[^\w\s]+'), '').trim().replaceAll(' ', '_');
      
      String? filePath;
      String mimeType = '';

      if (_selectedFormat == 'CSV') {
        final columns = _selectedColumns.entries.where((e) => e.value).map((e) => e.key).toList();
        final csvData = await service.generateCsv(widget.participants, columns);
        
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$sanitizedEventName.csv');
        await file.writeAsString(csvData);
        filePath = file.path;
        mimeType = 'text/csv';

      } else if (_selectedFormat == 'Excel') {
        final columns = _selectedColumns.entries.where((e) => e.value).map((e) => e.key).toList();
        final excelBytes = await service.generateExcel(widget.participants, columns);
        
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$sanitizedEventName.xlsx');
        await file.writeAsBytes(excelBytes);
        filePath = file.path;
         mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      } else if (_selectedFormat == 'QR_ZIP') {
        final zipBytes = await service.generateQrCodeZip(widget.participants);
        
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${sanitizedEventName}_qrcodes.zip');
        await file.writeAsBytes(zipBytes);
        filePath = file.path;
        mimeType = 'application/zip';

      } else if (_selectedFormat == 'QR_PDF') {
        final pdfBytes = await service.generateQrCodePdf(widget.participants);
        
        final tempDir = await getTemporaryDirectory();
         final file = File('${tempDir.path}/${sanitizedEventName}_qrcodes.pdf');
        await file.writeAsBytes(pdfBytes);
        filePath = file.path;
        mimeType = 'application/pdf';
      }

      if (filePath != null) {
        if (mounted) {
          // Close dialog first or stay? Maybe close.
          context.pop(); 
          // Use Share Plus to "export" (save/share)
          // ignore: deprecated_member_use
          await Share.shareXFiles([XFile(filePath, mimeType: mimeType)], text: 'Exportação do evento ${widget.eventName}');
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final double dialogWidth = isMobile ? constraints.maxWidth * 0.9 : 750;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: constraints.maxHeight * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.download, color: AppTheme.primaryRed),
                    const Gap(12),
                    Text(
                      'Exportar Dados',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Gap(24),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: isMobile 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormatSection(),
                              const Gap(24),
                              _buildOptionsSection(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildFormatSection(),
                              ),
                              const Gap(32),
                              Expanded(
                                flex: 3,
                                child: _buildOptionsSection(),
                              ),
                            ],
                          ),
                  ),
                ),

                const Gap(32),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isExporting ? null : () => context.pop(),
                      child: const Text('Cancelar'),
                    ),
                    const Gap(12),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _handleExport,
                      icon: _isExporting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download),
                      label: Text(_isExporting ? 'Exportando...' : 'Exportar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Formato de Exportação', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const Gap(12),
        Column(
          children: [
            _buildFormatOption('CSV', 'CSV (Planilha de texto)', Icons.description_outlined),
            const Gap(8),
            _buildFormatOption('Excel', 'Excel (.xlsx)', Icons.table_chart_outlined),
            const Gap(8),
            _buildFormatOption('QR_ZIP', 'QR Codes (Pacote ZIP)', Icons.qr_code_2),
            const Gap(8),
            _buildFormatOption('QR_PDF', 'QR Codes (Documento PDF)', Icons.picture_as_pdf_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatOption(String key, String label, IconData icon) {
    final isSelected = _selectedFormat == key;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppTheme.primaryRed : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryRed : Colors.grey[600], size: 20),
            const Gap(12),
            Expanded(child: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryRed, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFormat == 'CSV' || _selectedFormat == 'Excel') ...[
          Text('Personalizar Colunas', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Gap(12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _selectedColumns.keys.map((col) {
                return CheckboxListTile(
                  title: Text(col, style: const TextStyle(fontSize: 14)),
                  value: _selectedColumns[col],
                  onChanged: (val) => _toggleColumn(col),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
          const Gap(16),
          Text(
            'Selecione as informações que deseja incluir na planilha.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ] else if (_selectedFormat == 'QR_ZIP') ...[
           Text('Configurações de QR', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
           const Gap(12),
           _buildInfoCard(Icons.folder_zip, 'Um arquivo .zip será gerado contendo cada QR Code como uma imagem individual em alta resolução.'),
        ] else if (_selectedFormat == 'QR_PDF') ...[
           Text('Configurações de QR', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
           const Gap(12),
           _buildInfoCard(Icons.picture_as_pdf, 'Um documento PDF será estruturado com fichas individuais contendo o QR Code e nome do participante.'),
        ],
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const Gap(12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.blue.shade900, fontSize: 13))),
        ],
      ),
    );
  }
}
