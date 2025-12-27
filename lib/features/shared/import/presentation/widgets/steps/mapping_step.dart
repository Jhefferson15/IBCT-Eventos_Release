
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../import_controller.dart';
import '../../import_state.dart';

// =============================================================================
// STEP 2: MAPPING
// =============================================================================

class ImportMappingStepWidget extends ConsumerWidget {
  final String eventId;

  const ImportMappingStepWidget({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importControllerProvider(eventId));
    final controller = ref.read(importControllerProvider(eventId).notifier);

    return Column(
      children: [
        // Header with "Add Column"
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mapeamento de Colunas', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const Gap(4),
                    Text(
                      'Associe as colunas do arquivo ao sistema',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Gap(12),
              ElevatedButton.icon(
                onPressed: () => _showAddColumnDialog(context, controller),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nova Coluna'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed.withValues(alpha:0.1),
                  foregroundColor: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: state.mappingFields.length,
            onReorder: controller.reorderColumns,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final field = state.mappingFields[index];
              return Padding(
                 key: ValueKey(field.id),
                 padding: const EdgeInsets.only(bottom: 12),
                 child: _MappingItemCard(
                   field: field, 
                   headers: state.headers,
                   index: index,
                   onUpdateMapping: (val) => controller.updateMapping(field.id, val),
                   onRemove: () => controller.removeColumn(field.id),
                   onRename: () => _showRenameDialog(context, controller, field),
                 ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddColumnDialog(BuildContext context, ImportController controller) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Nova Coluna'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Nome do Campo',
            border: OutlineInputBorder(),
            hintText: 'Ex: Data de Nascimento'
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                controller.addCustomColumn(textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ImportController controller, MappingField field) {
    final textController = TextEditingController(text: field.label);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear Coluna'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Nome do Campo',
            border: OutlineInputBorder()
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                controller.renameColumn(field.id, textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _MappingItemCard extends StatelessWidget {
  final MappingField field;
  final List<String> headers;
  final int index;
  final ValueChanged<String?> onUpdateMapping;
  final VoidCallback onRemove;
  final VoidCallback onRename;

  const _MappingItemCard({
    required this.field,
    required this.headers,
    required this.index,
    required this.onUpdateMapping,
    required this.onRemove,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600; 
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
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Icon(Icons.drag_indicator, color: Colors.grey.shade300),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: isNarrow ? _buildStackedLayout() : _buildRowLayout(),
                ),
                if (!field.isRequired) ...[
                   const Gap(8),
                   IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 20),
                    tooltip: 'Remover mapeamento',
                    onPressed: onRemove,
                  ),
                ] else 
                   const Gap(48), 
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildRowLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildTargetField(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.arrow_right_alt, color: Colors.grey.shade400),
        ),
        Expanded(
          flex: 5,
          child: _buildSourceDropdown(),
        ),
      ],
    );
  }

  Widget _buildStackedLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTargetField(),
        const Gap(8),
        Center(
          child: Icon(Icons.arrow_downward, size: 16, color: Colors.grey.shade400),
        ),
        const Gap(8),
        _buildSourceDropdown(),
      ],
    );
  }

  Widget _buildTargetField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: field.isRequired ? Colors.red.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: field.isRequired ? Colors.red.withValues(alpha: 0.1) : Colors.transparent
        ),
      ),
      child: Row(
        children: [
          Icon(
            field.isCustom ? Icons.extension : Icons.label_outline,
            size: 16,
            color: field.isRequired ? Colors.red : Colors.grey[600],
          ),
          const Gap(8),
          Expanded(
            child: Tooltip(
              message: field.label,
              child: Text(
                field.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: field.isRequired ? AppTheme.primaryRed : Colors.grey[800],
                ),
              ),
            ),
          ),
          if (field.isCustom || !field.isRequired)
            InkWell(
              onTap: onRename,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.edit, size: 14, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: headers.contains(field.selectedHeader) ? field.selectedHeader : null,

        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.primaryRed),
          ),
          hintText: 'Selecione a coluna...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true,
          fillColor: Colors.white,
        ),
        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        items: [
          const DropdownMenuItem(
            value: null, 
            child: Text(
              '(Ignorar Coluna)', 
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
            )
          ),
          ...headers.map((h) => DropdownMenuItem(
            value: h, 
            child: Text(h, overflow: TextOverflow.ellipsis)
          )),
        ],
        onChanged: onUpdateMapping,
      ),
    );
  }
}
