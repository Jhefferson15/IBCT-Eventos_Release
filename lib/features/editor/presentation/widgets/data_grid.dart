import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/participant_model.dart';
import '../providers/participant_grid_provider.dart';
import '../providers/participant_history_provider.dart';
import '../providers/participant_providers.dart';
import '../../../users/presentation/providers/user_providers.dart';
// import 'data_grid/data_grid_header_cell.dart'; // Moved to DataGridHeader
import 'data_grid/data_grid_header.dart';
import 'data_grid/data_grid_row.dart';

// Intents for keyboard navigation
class GridMoveIntent extends Intent {
  final int dx;
  final int dy;
  const GridMoveIntent(this.dx, this.dy);
}

class GridEnterIntent extends Intent {
  const GridEnterIntent();
}

class UndoIntent extends Intent { const UndoIntent(); }
class RedoIntent extends Intent { const RedoIntent(); }

class DataGrid extends ConsumerStatefulWidget {
  final String eventId;
  const DataGrid({super.key, required this.eventId});

  @override
  ConsumerState<DataGrid> createState() => _DataGridState();
}

class _DataGridState extends ConsumerState<DataGrid> {
  // Controllers for syncing scrolling
  final ScrollController _headerController = ScrollController();
  final ScrollController _bodyController = ScrollController();
  
  // Controller for vertical scrolling
  final ScrollController _verticalController = ScrollController();

  // Focus Node for the Grid itself to capture keys
  final FocusNode _gridFocusNode = FocusNode();

  // Inline Editing State
  String? _editingId;
  String? _editingField;
  late TextEditingController _editController;
  final FocusNode _editFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(_syncScroll);
    _headerController.addListener(_syncHeaderScroll);
    _editController = TextEditingController();
    
    // Request focus for the grid on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _gridFocusNode.requestFocus();
    });
  }

  void _syncScroll() {
    if (_headerController.hasClients && _bodyController.hasClients) {
      if (_headerController.offset != _bodyController.offset) {
        _headerController.jumpTo(_bodyController.offset);
      }
    }
  }

  void _syncHeaderScroll() {
    if (_headerController.hasClients && _bodyController.hasClients) {
      if (_bodyController.offset != _headerController.offset) {
        _bodyController.jumpTo(_headerController.offset);
      }
    }
  }

  @override
  void dispose() {
    _headerController.removeListener(_syncHeaderScroll);
    _bodyController.removeListener(_syncScroll);
    _headerController.dispose();
    _bodyController.dispose();
    _verticalController.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    _gridFocusNode.dispose();
    super.dispose();
  }

  void _startEditing(Participant participant, String field, String initialValue) {
    setState(() {
      _editingId = participant.id;
      _editingField = field;
      _editController.text = initialValue;
    });
    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingId = null;
      _editingField = null;
    });
    _gridFocusNode.requestFocus(); // Return focus to grid
  }

  Future<void> _commitEdit(Participant participant) async {
    if (_editingField == null) return;
    
    final newValue = _editController.text;
    _cancelEditing(); // Close editor immediately for responsiveness

    // Clone and update
    Participant updated = participant;
    
    switch (_editingField) {
      case 'Nome': updated = participant.copyWith(name: newValue); break;
      case 'Email': updated = participant.copyWith(email: newValue); break;
      case 'Telefone': updated = participant.copyWith(phone: newValue); break;
      case 'Empresa': updated = participant.copyWith(company: newValue); break;
      case 'Cargo': updated = participant.copyWith(role: newValue); break;
      case 'CPF/CNPJ': updated = participant.copyWith(cpf: newValue); break;
      case 'Status': updated = participant.copyWith(status: newValue); break;
      case 'Ingresso': updated = participant.copyWith(ticketType: newValue); break;
      default:
        // Custom Field
        final newCustom = Map<String, dynamic>.from(participant.customFields);
        newCustom[_editingField!] = newValue;
        updated = participant.copyWith(customFields: newCustom);
    }
    
    // Save via History (Undo/Redo)
    final controller = ref.read(participantsControllerProvider(widget.eventId).notifier);
    final history = ref.read(historyProvider.notifier);
    final currentUser = ref.read(currentUserProvider).value;
    
    if (currentUser != null) {
      // Use Command
      await history.execute(UpdateParticipantCommand(controller, currentUser.id, participant, updated));
    }
  }

  void _handleNavigate(int dx, int dy, List<Participant> participants, List<String> columns) {
     final state = ref.read(participantGridStateProvider(widget.eventId));
     final notifier = ref.read(participantGridStateProvider(widget.eventId).notifier);

     // Current Focus
     final currentId = state.focusedParticipantId;
     final currentKey = state.focusedColumnKey;

     int currentRow = -1;
     int currentCol = -1;

     if (currentId != null) {
       currentRow = participants.indexWhere((p) => p.id == currentId);
     }
     if (currentKey != null) {
       currentCol = columns.indexOf(currentKey);
     }

     // Use first cell if nothing focused
     if (currentRow == -1) currentRow = 0;
     if (currentCol == -1) currentCol = 0;

     // Calculate Target
     var targetRow = currentRow + dy;
     var targetCol = currentCol + dx;

     // Clamp
     if (targetRow < 0) targetRow = 0;
     if (targetRow >= participants.length) targetRow = participants.length - 1;
     
     if (targetCol < 0) targetCol = 0;
     if (targetCol >= columns.length) targetCol = columns.length - 1;

     if (participants.isEmpty || columns.isEmpty) return;

     final targetId = participants[targetRow].id;
     final targetKey = columns[targetCol];

     notifier.setFocus(targetId, targetKey);
     _ensureVisible(targetRow, targetCol, columns);
  }
  
  void _ensureVisible(int rowIndex, int colIndex, List<String> columns) {
     // Vertical Scroll
     final itemHeight = 50.0;
     final viewportHeight = _verticalController.position.viewportDimension;
     final currentOffset = _verticalController.offset;
     
     final targetTop = rowIndex * itemHeight;
     final targetBottom = targetTop + itemHeight;

     if (targetTop < currentOffset) {
       _verticalController.jumpTo(targetTop);
     } else if (targetBottom > currentOffset + viewportHeight) {
       _verticalController.jumpTo(targetBottom - viewportHeight);
     }

     // Horizontal Scroll (Only if in scrollable area)
     if (columns[colIndex] == 'Nome') return; 

     // Calculate Horizontal Offset
     double offsetForCol = 0.0;
     double colWidth = _getColumnWidth(columns[colIndex]);
     
     int scrollableIndex = -1;
     // Find index in the scrollable list
     final otherCols = columns.where((c) => c != 'Nome').toList();
     scrollableIndex = otherCols.indexOf(columns[colIndex]);
     
     if (scrollableIndex == -1) return; // Should likely be Nome

     for (int i = 0; i < scrollableIndex; i++) {
        offsetForCol += _getColumnWidth(otherCols[i]);
     }
     
     final horizontalViewport = _bodyController.position.viewportDimension;
     final currentHOffset = _bodyController.offset;
     
     if (offsetForCol < currentHOffset) {
        _bodyController.jumpTo(offsetForCol);
     } else if (offsetForCol + colWidth > currentHOffset + horizontalViewport) {
        _bodyController.jumpTo(offsetForCol + colWidth - horizontalViewport);
     }
  }
  
  void _handleEnter(List<Participant> participants) {
     final state = ref.read(participantGridStateProvider(widget.eventId));
     if (state.focusedParticipantId != null && state.focusedColumnKey != null) {
        final p = participants.firstWhere((element) => element.id == state.focusedParticipantId, orElse: () => participants.first);
        final val = _getCellValue(p, state.focusedColumnKey!);
        _startEditing(p, state.focusedColumnKey!, val);
     }
  }


  @override
  Widget build(BuildContext context) {
    final filteredDataAsync = ref.watch(filteredParticipantsProvider(widget.eventId));
    final gridNotifier = ref.read(participantGridStateProvider(widget.eventId).notifier);
    final gridState = ref.watch(participantGridStateProvider(widget.eventId));
    final history = ref.read(historyProvider.notifier);

    // Default Widths helper - repeated for usage in ensureVisible, etc.
    // Ideally this should be in the Provider.
    double getColumnWidth(String column) {
      if (gridState.columnWidths.containsKey(column)) {
         return gridState.columnWidths[column]!;
      }
      switch (column) {
        case 'Nome': return 250; 
        case 'Email': return 220;
        case 'Telefone': return 130;
        case 'Ingresso': return 100;
        case 'Status': return 120;
        case 'Empresa': return 160;
        case 'Cargo': return 160;
        case 'CPF/CNPJ': return 150;
        default: return 150;
      }
    }

    return FocusableActionDetector(
      focusNode: _gridFocusNode,
      shortcuts: {
         const SingleActivator(LogicalKeyboardKey.arrowUp): const GridMoveIntent(0, -1),
         const SingleActivator(LogicalKeyboardKey.arrowDown): const GridMoveIntent(0, 1),
         const SingleActivator(LogicalKeyboardKey.arrowLeft): const GridMoveIntent(-1, 0),
         const SingleActivator(LogicalKeyboardKey.arrowRight): const GridMoveIntent(1, 0),
         const SingleActivator(LogicalKeyboardKey.enter): const GridEnterIntent(),
         const SingleActivator(LogicalKeyboardKey.keyZ, control: true): const UndoIntent(),
         const SingleActivator(LogicalKeyboardKey.keyY, control: true): const RedoIntent(),
      },
      actions: {
        GridMoveIntent: CallbackAction<GridMoveIntent>(
          onInvoke: (intent) => filteredDataAsync.whenData((data) {
             _handleNavigate(intent.dx, intent.dy, data.participants, data.visibleColumns);
          }),
        ),
        GridEnterIntent: CallbackAction<GridEnterIntent>(
          onInvoke: (intent) => filteredDataAsync.whenData((data) {
             _handleEnter(data.participants);
          }),
        ),
        UndoIntent: CallbackAction<UndoIntent>(
          onInvoke: (_) => history.undo(),
        ),
        RedoIntent: CallbackAction<RedoIntent>(
          onInvoke: (_) => history.redo(),
        ),
      },
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // 1. Search Bar & Tools
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                   Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar (Nome, Email, ID)...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        gridNotifier.setSearchQuery(value);
                      },
                    ),
                  ),
                  if (gridState.selectedIds.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Text('${gridState.selectedIds.length} selecionados', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: gridNotifier.clearSelection,
                      tooltip: 'Limpar Seleção',
                    ),
                  ]
                ],
              ),
            ),
  
            const Divider(height: 1),
  
            // 2. Data Grid
            Expanded(
              child: filteredDataAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro: $err')),
                data: (gridData) {
                   
                   final participants = gridData.participants;
                   final otherCols = gridData.visibleColumns.where((c) => c != 'Nome').toList(); 
                   final fixedWidth = 300.0;
                   
                   return GestureDetector(
                     onTap: () {
                        _gridFocusNode.requestFocus();
                     },
                     child: Column(
                       children: [
                          // Header Row (Fixed + Scrollable)
                          DataGridHeader(
                            eventId: widget.eventId,
                            headerController: _headerController,
                            gridData: gridData,
                          ),
                          
                          const Divider(height: 1),

                          // Body Row (Fixed + Scrollable)
                          Expanded(
                            child: Row(
                              children: [
                                // Fixed Column List
                                SizedBox(
                                  width: fixedWidth,
                                  child: ListView.builder(
                                    controller: _verticalController, 
                                    itemCount: participants.length,
                                    itemExtent: 50,
                                    itemBuilder: (context, index) {
                                      final p = participants[index];
                                      return DataGridRow(
                                        participant: p,
                                        isSelected: gridState.selectedIds.contains(p.id),
                                        isEven: index.isEven,
                                        focusedColumnKey: gridState.focusedColumnKey,
                                        focusedParticipantId: gridState.focusedParticipantId,
                                        editingId: _editingId,
                                        editingField: _editingField,
                                        editController: _editController,
                                        editFocusNode: _editFocusNode,
                                        gridFocusNode: _gridFocusNode,
                                        onFocus: gridNotifier.setFocus,
                                        onStartEditing: (id, field, val) {
                                           // Find participant and call internal
                                           final part = participants.firstWhere((e) => e.id == id);
                                           _startEditing(part, field, val);
                                        },
                                        onCommit: _commitEdit,
                                        onToggleSelection: gridNotifier.toggleSelection,
                                        onShowContextMenu: (details, p, col) => _showContextMenu(context, details, p, col),
                                        getColumnWidth: getColumnWidth,
                                        isFixed: true,
                                      );
                                    },
                                  ),
                                ),
                                
                                // Vertical Divider
                                const VerticalDivider(width: 1, thickness: 1),
                                
                                // Scrollable Area List
                                Expanded(
                                   child: SingleChildScrollView(
                                     controller: _bodyController, // Horizontal Body
                                     scrollDirection: Axis.horizontal,
                                     child: SizedBox(
                                       width: otherCols.fold<double>(0.0, (sum, col) => sum + getColumnWidth(col)),
                                       child: ListView.builder(
                                         // NOTE: Using _verticalController here again.
                                         // This relies on the behavior that they scroll together if physics/extent allow.
                                         // ideally we should use linked_scroll_controller or one listener driving the other.
                                         // Since I am not changing behavior, I stick to the original code's pattern.
                                         // Original Code: used _verticalController for BOTH ListViews.
                                         // Wait, original code:
                                         // Line 386: controller: _verticalController
                                         // Line 473: controller: _verticalController
                                         // So yes, it was using the same controller. 
                                         // If it worked before, I will keep it.
                                         controller: _verticalController, 
                                         itemCount: participants.length,
                                         itemExtent: 50,
                                         itemBuilder: (context, index) {
                                            final p = participants[index];
                                            return DataGridRow(
                                              participant: p,
                                              isSelected: gridState.selectedIds.contains(p.id),
                                              isEven: index.isEven,
                                              focusedColumnKey: gridState.focusedColumnKey,
                                              focusedParticipantId: gridState.focusedParticipantId,
                                              editingId: _editingId,
                                              editingField: _editingField,
                                              editController: _editController,
                                              editFocusNode: _editFocusNode,
                                              gridFocusNode: _gridFocusNode,
                                              onFocus: gridNotifier.setFocus,
                                              onStartEditing: (id, field, val) {
                                                 final part = participants.firstWhere((e) => e.id == id);
                                                 _startEditing(part, field, val);
                                              },
                                              onCommit: _commitEdit,
                                              onToggleSelection: gridNotifier.toggleSelection,
                                        onShowContextMenu: (details, p, col) => _showContextMenu(context, details, p, col),
                                              getColumnWidth: getColumnWidth,
                                              isFixed: false,
                                              columns: otherCols,
                                            );
                                         },
                                       ),
                                     ),
                                   ),
                                ),
                              ],
                            ),
                          ),
                       ],
                     ),
                   );
                },
              ),
            ),
            
             // Footer
            Container(
               color: Colors.grey[100],
               padding: const EdgeInsets.all(8),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                    Text('Total: ${filteredDataAsync.asData?.value.participants.length ?? 0}'),
                 ],
               ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCellValue(Participant p, String col) {
      switch (col) {
      case 'Nome': return p.name;
      case 'Email': return p.email;
      case 'Telefone': return p.phone;
      case 'Empresa': return p.company ?? '';
      case 'Cargo': return p.role ?? '';
      case 'CPF/CNPJ': return p.cpf ?? '';
      case 'Status': return p.status;
      case 'Ingresso': return p.ticketType;
      default: return p.customFields[col]?.toString() ?? '';
    }
  }

  void _showContextMenu(BuildContext context, TapDownDetails details, Participant participant, String column) {
      final value = _getCellValue(participant, column);
      
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        ),
        items: <PopupMenuEntry<dynamic>>[
           PopupMenuItem(
             child: const Row(children: [Icon(Icons.copy, size: 16), SizedBox(width: 8), Text('Copiar')]),
             onTap: () async {
                 await Clipboard.setData(ClipboardData(text: value));
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado!'), duration: Duration(milliseconds: 500)));
                 }
             },
           ),
           if (column == 'Email')
             PopupMenuItem(
               child: const Row(children: [Icon(Icons.email, size: 16), SizedBox(width: 8), Text('Copiar Email')]),
               onTap: () async {
                   await Clipboard.setData(ClipboardData(text: participant.email));
               },
             ),
           const PopupMenuDivider(),
           PopupMenuItem(
             child: const Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Editar Linha')]),
             onTap: () {
                 _startEditing(participant, column, value);
             },
           ),
           PopupMenuItem(
             child: const Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: Colors.red))]),
             onTap: () async {
                  final controller = ref.read(participantsControllerProvider(widget.eventId).notifier);
                  final currentUser = ref.read(currentUserProvider).value;
                  if (currentUser != null) {
                    await controller.deleteParticipants([participant.id], currentUser.id);
                  }
             },
           ),
        ],
      );
  }

  double _getColumnWidth(String column) {
    final state = ref.read(participantGridStateProvider(widget.eventId));
    // Check state first
    if (state.columnWidths.containsKey(column)) {
       return state.columnWidths[column]!;
    }
    
    // Defaults
    switch (column) {
      case 'Nome': return 250; 
      case 'Email': return 220;
      case 'Telefone': return 130;
      case 'Ingresso': return 100;
      case 'Status': return 120;
      case 'Empresa': return 160;
      case 'Cargo': return 160;
      case 'CPF/CNPJ': return 150;
      default: return 150;
    }
  }
}
