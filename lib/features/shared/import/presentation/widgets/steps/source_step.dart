import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../import_controller.dart';
import '../../import_state.dart';

// =============================================================================
// STEP 1: SOURCE SELECTION
// =============================================================================

class ImportSourceStepWidget extends ConsumerWidget {
  final String eventId;

  const ImportSourceStepWidget({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importControllerProvider(eventId));
    final controller = ref.read(importControllerProvider(eventId).notifier);
    
    // Check orientation/size for layout
    final isMobile = MediaQuery.of(context).size.width < 600;

    final actionButtons = [
      Expanded(
        flex: isMobile ? 0 : 1,
        child: _buildAddButton(
          icon: FontAwesomeIcons.fileCsv,
          title: 'Adicionar Arquivo',
          color: Colors.blue,
          onTap: controller.pickFile,
        ),
      ),
      Gap(isMobile ? 16 : 16),
      Expanded(
        flex: isMobile ? 0 : 1,
        child: _buildAddButton(
          icon: FontAwesomeIcons.googleDrive,
          title: 'Adicionar Google Forms',
          color: const Color(0xFF673AB7), // Purple for Forms
          onTap: () => _connectAndSelectForm(context, ref, controller),
        ),
      ),
      Gap(isMobile ? 16 : 16),
      Expanded(
        flex: isMobile ? 0 : 1,
        child: _buildAddButton(
          icon: FontAwesomeIcons.fileExcel,
          title: 'Adicionar Google Sheets',
          color: Colors.green,
          onTap: () => _connectAndSelectSheet(context, ref, controller),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selecione as fontes de dados para importação. Você pode adicionar múltiplos arquivos ou planilhas.',
          style: TextStyle(color: Colors.grey),
        ),
        const Gap(16),
        isMobile 
          ? Column(children: actionButtons)
          : Row(children: actionButtons),
        const Gap(24),
        const Text(
          'Fontes Selecionadas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        Expanded(
          child: state.selectedItems.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                itemCount: state.selectedItems.length,
                separatorBuilder: (c, i) => const Gap(8),
                itemBuilder: (context, index) {
                  final item = state.selectedItems[index];
                  return _buildItemCard(context, item, controller);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
          const Gap(16),
          Text(
            'Nenhuma fonte selecionada',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ImportSourceItem item, ImportController controller) {
    IconData icon;
    Color color;
    String typeLabel;

    switch (item.type) {
      case ImportSource.file:
        icon = FontAwesomeIcons.fileCsv;
        color = Colors.blue;
        typeLabel = 'Arquivo Local';
        break;
      case ImportSource.googleForms:
        icon = FontAwesomeIcons.googleDrive;
        color = const Color(0xFF673AB7);
        typeLabel = 'Google Forms';
        break;
      case ImportSource.googleSheets:
        icon = FontAwesomeIcons.fileExcel;
        color = Colors.green;
        typeLabel = 'Google Sheets';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(typeLabel, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => controller.removeSourceItem(item.id),
          tooltip: 'Remover',
        ),
      ),
    );
  }

  Widget _buildAddButton({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const Gap(8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Google Forms Selection Logic
  Future<void> _connectAndSelectForm(BuildContext context, WidgetRef ref, ImportController controller) async {
    final success = await controller.connectAndLoadForms();
    
    if (!context.mounted) return;

    if (success) {
      final state = ref.read(importControllerProvider(eventId));
      _showFormSelectionDialog(context, state.availableDriveFiles, controller);
    }
  }

  void _showFormSelectionDialog(BuildContext context, List<drive.File> forms, ImportController controller) {
    if (forms.isEmpty) {
      _showError(context, 'Nenhum formulário encontrado na conta Google conectada.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Selecione um Formulário', style: Theme.of(context).textTheme.titleLarge),
              const Gap(16),
               Expanded(
                 child: ListView.builder(
                   itemCount: forms.length,
                   itemBuilder: (ctx, i) {
                     final form = forms[i];
                     return ListTile(
                       leading: const Icon(FontAwesomeIcons.googleDrive, color: Color(0xFF673AB7)),
                       title: Text(form.name ?? 'Sem Nome'),
                       subtitle: Text('Modificado: ${form.modifiedTime?.toLocal()}'),
                       onTap: () {
                         controller.addDriveFile(form, ImportSource.googleForms);
                         Navigator.pop(context);
                       },
                     );
                   },
                 ),
               ),
               TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))
            ],
          ),
        ),
      ),
    );
  }

  // Google Sheets Selection Logic
  Future<void> _connectAndSelectSheet(BuildContext context, WidgetRef ref, ImportController controller) async {
    final success = await controller.connectAndLoadSheets();
    
    if (!context.mounted) return;

    if (success) {
      final state = ref.read(importControllerProvider(eventId));
      _showSheetSelectionDialog(context, state.availableDriveFiles, controller);
    }
  }

  void _showSheetSelectionDialog(BuildContext context, List<drive.File> sheets, ImportController controller) {
    if (sheets.isEmpty) {
      _showError(context, 'Nenhuma planilha encontrada na conta Google conectada.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Selecione uma Planilha', style: Theme.of(context).textTheme.titleLarge),
              const Gap(16),
               Expanded(
                 child: ListView.builder(
                   itemCount: sheets.length,
                   itemBuilder: (ctx, i) {
                     final sheet = sheets[i];
                     return ListTile(
                       leading: const Icon(Icons.table_chart, color: Colors.green),
                       title: Text(sheet.name ?? 'Sem Nome'),
                       subtitle: Text('Modificado: ${sheet.modifiedTime?.toLocal()}'),
                       onTap: () {
                         controller.addDriveFile(sheet, ImportSource.googleSheets);
                         Navigator.pop(context);
                       },
                     );
                   },
                 ),
               ),
               TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}
