import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/domain/models/event_model.dart';
import 'package:gap/gap.dart';
import '../../../users/domain/models/activity_log.dart';
import '../../../users/presentation/providers/activity_log_provider.dart';
import '../../../users/presentation/providers/user_providers.dart';

class ColumnManagerDialog extends ConsumerStatefulWidget {
  final Event event;
  final List<String> knownCustomColumns;

  const ColumnManagerDialog({super.key, required this.event, this.knownCustomColumns = const []});

  @override
  ConsumerState<ColumnManagerDialog> createState() => _ColumnManagerDialogState();
}

class _ColumnManagerDialogState extends ConsumerState<ColumnManagerDialog> {
  late List<String> _currentColumns;
  final TextEditingController _newColumnController = TextEditingController();
  bool _isLoading = false;

  // List of standard columns that are available by default but can be hidden
  static const List<String> _standardAvailableColumns = [
    'ID', 'Nome', 'Email', 'Telefone', 'Ingresso', 'Status', 'Empresa', 'Cargo', 'CPF/CNPJ'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event.visibleColumns.isNotEmpty) {
      _currentColumns = List.from(widget.event.visibleColumns);
      
      // Ensure all standard columns are present
      for (final col in _standardAvailableColumns) {
        if (!_currentColumns.contains(col)) {
          _currentColumns.add(col);
        }
      }
      
      // Ensure all custom columns are present (from event)
      for (final col in widget.event.customColumns) {
         if (!_currentColumns.contains(col)) {
          _currentColumns.add(col);
        }
      }
      
      // Ensure all known custom columns from data are present
      for (final col in widget.knownCustomColumns) {
        if (!_currentColumns.contains(col)) {
          _currentColumns.add(col);
        }
      }

    } else {
      // Default initial state: ALL Standard basics + existing custom + known from data
      _currentColumns = List.from(_standardAvailableColumns);
      _currentColumns.addAll(widget.event.customColumns);
      
      for (final col in widget.knownCustomColumns) {
        if (!_currentColumns.contains(col)) {
          _currentColumns.add(col);
        }
      }
    }
  }

  @override
  void dispose() {
    _newColumnController.dispose();
    super.dispose();
  }

  void _addColumn() {
    final name = _newColumnController.text.trim();
    if (name.isNotEmpty && !_currentColumns.contains(name)) {
      setState(() {
        _currentColumns.add(name);
        _newColumnController.clear();
      });
    }
  }

  void _addStandardColumn(String name) {
     if (!_currentColumns.contains(name)) {
      setState(() {
        _currentColumns.add(name);
      });
    }
  }

  void _removeColumn(String name) {
    setState(() {
      _currentColumns.remove(name);
    });
  }

  void _moveColumn(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final String item = _currentColumns.removeAt(oldIndex);
      _currentColumns.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(eventRepositoryProvider);
      
      // Calculate which of the current columns are actually "custom"
      // (i.e., not in the fixed known standard set)
      // This ensures we keep tracking new schema fields properly
      final List<String> newCustomColumns = _currentColumns
          .where((col) => !_standardAvailableColumns.contains(col))
          .toList();

      debugPrint('DEBUG: Saving visible columns: $_currentColumns');
      debugPrint('DEBUG: Derived custom columns: $newCustomColumns');

      final updatedEvent = widget.event.copyWith(
        visibleColumns: _currentColumns,
        customColumns: newCustomColumns,
      );
      
      await repository.updateItem(updatedEvent);
      debugPrint('DEBUG: Saved event columns successfully');

      // Force refresh of events to ensure DataGrid updates immediately
      ref.invalidate(eventsProvider); 
      if (widget.event.id != null) {
        ref.invalidate(singleEventProvider(widget.event.id!));
      } 

      // Log Activity
      try {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser != null) {
          await ref.read(logActivityUseCaseProvider).call(
            userId: currentUser.id,
            actionType: ActivityActionType.updateEvent,
            targetId: widget.event.id ?? 'unknown',
            targetType: 'event',
            details: {'action': 'manage_columns', 'columnCount': _currentColumns.length},
          );
        }
      } catch (e) {
        // ignore
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Colunas atualizadas com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Note: I will replace the build method and initState primarily. 
  // Let's use the tool to replace the whole class state or specific parts if easier.
  // Given I need to wrap everything in LayoutBuilder, replacing the build method is key.
  
  @override
  Widget build(BuildContext context) {
    final availableToAdd = _standardAvailableColumns
        .where((c) => !_currentColumns.contains(c))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final double width = isMobile ? constraints.maxWidth * 0.95 : 600;
        final double padding = isMobile ? 16 : 24;

        return Dialog(
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
           insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
           child: Container(
             width: width,
             padding: EdgeInsets.all(padding),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 Text(
                   'Gerenciar Colunas da Tabela',
                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                     fontWeight: FontWeight.bold,
                     fontSize: isMobile ? 20 : 24,
                   ),
                 ),
                 const Gap(8),
                 Text(
                   'Adicione, remova ou reordene as colunas visíveis.',
                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                 ),
                 const Gap(24),
                 
                 // Add New / Standard Column Section
                 if (isMobile) ...[
                   // Mobile: Stacked Layout
                   CustomTextField(
                     label: 'Nova Coluna',
                     controller: _newColumnController,
                     prefixIcon: Icons.add,
                   ),
                   const Gap(12),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        if (availableToAdd.isNotEmpty)
                         Expanded(
                           child: PopupMenuButton<String>(
                              onSelected: _addStandardColumn,
                              tooltip: 'Adicionar Coluna Padrão',
                              itemBuilder: (context) {
                                return availableToAdd.map((col) {
                                  return PopupMenuItem<String>(
                                    value: col,
                                    child: Text(col),
                                  );
                                }).toList();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Padrão"),
                                    Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                           ),
                         )
                        else
                          const Spacer(),
                           
                       const Gap(16),
                       ElevatedButton.icon(
                         onPressed: _addColumn,
                         icon: const Icon(Icons.add),
                         label: const Text('Adicionar'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.green,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                         ),
                       ),
                     ],
                   ),
                 ] else ...[
                   // Desktop: Row Layout
                   Row(
                     children: [
                       Expanded(
                         flex: 2,
                         child: CustomTextField(
                           label: 'Nova Coluna Personalizada',
                           controller: _newColumnController,
                           prefixIcon: Icons.add,
                         ),
                       ),
                       const Gap(8),
                       IconButton(
                         onPressed: _addColumn,
                         icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                         tooltip: 'Criar nova coluna',
                       ),
                       if (availableToAdd.isNotEmpty) ...[
                         const Gap(16),
                         Expanded(
                           flex: 1,
                           child: PopupMenuButton<String>(
                              onSelected: _addStandardColumn,
                              tooltip: 'Adicionar Coluna Padrão',
                              itemBuilder: (context) {
                                return availableToAdd.map((col) {
                                  return PopupMenuItem<String>(
                                    value: col,
                                    child: Text(col),
                                  );
                                }).toList();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.list),
                                    Gap(8),
                                    Text("Padrão"),
                                    Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                           ),
                         ),
                       ]
                     ],
                   ),
                 ],
                 const Gap(16),
                 
                 // List Reorderable
                 Flexible(
                   child: Container(
                     constraints: BoxConstraints(maxHeight: isMobile ? constraints.maxHeight * 0.5 : 400),
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.grey.shade200),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: _currentColumns.isEmpty
                         ? const Padding(
                             padding: EdgeInsets.all(16.0),
                             child: Center(child: Text('Nenhuma coluna visível.')),
                           )
                         : ReorderableListView.builder(
                             shrinkWrap: true,
                             buildDefaultDragHandles: false,
                             onReorder: _moveColumn,
                             itemCount: _currentColumns.length,
                             itemBuilder: (context, index) {
                               final col = _currentColumns[index];
                               final isStandard = _standardAvailableColumns.contains(col);
                               return Container(
                                 key: ValueKey(col),
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
                                  ),
                                 child: ListTile(
                                   dense: isMobile,
                                   contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
                                   
                                   title: Text(col, style: TextStyle(
                                     fontWeight: isStandard ? FontWeight.normal : FontWeight.bold,
                                     fontSize: isMobile ? 14 : 16,
                                   )),
                                   leading: ReorderableDragStartListener(
                                     index: index,
                                     child: const Icon(Icons.drag_handle),
                                   ),
                                   trailing: IconButton(
                                     icon: const Icon(Icons.delete, color: Colors.red),
                                     onPressed: () => _removeColumn(col),
                                   ),
                                 ),
                               );
                             },
                           ),
                   ),
                 ),
                 const Gap(24),
                 _isLoading
                     ? const Center(child: CircularProgressIndicator())
                     : CustomButton(
                         text: 'Salvar Alterações',
                         onPressed: _save,
                         backgroundColor: AppTheme.primaryRed,
                         isFullWidth: true,
                       ),
               ],
             ),
           ),
        );
      }
    );
  }
}
