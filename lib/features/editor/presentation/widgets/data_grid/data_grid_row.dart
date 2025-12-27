import 'package:flutter/material.dart';
import '../../../domain/models/participant_model.dart';
import 'data_grid_cell.dart';

class DataGridRow extends StatelessWidget {
  final Participant participant;
  final bool isSelected;
  final bool isEven;
  final String? focusedColumnKey; // to check focus
  final String? focusedParticipantId;
  final String? editingId;
  final String? editingField;
  final TextEditingController editController;
  final FocusNode editFocusNode;
  final FocusNode gridFocusNode;
  final Function(String, String) onFocus; // participantId, columnKey
  final Function(String, String, String) onStartEditing; // participant, field, value
  final Function(Participant) onCommit;
  final Function(String, bool?) onToggleSelection;
  final Function(TapDownDetails, Participant, String) onShowContextMenu;
  final double Function(String) getColumnWidth;
  
  // Split rendering props
  final bool isFixed; // If true, renders Checkbox + Name. If false, renders other cols.
  final List<String> columns; // If isFixed, ignored (assumed Name). If false, renders these columns.

  const DataGridRow({
    super.key,
    required this.participant,
    required this.isSelected,
    required this.isEven,
    required this.focusedColumnKey,
    required this.focusedParticipantId,
    required this.editingId,
    required this.editingField,
    required this.editController,
    required this.editFocusNode,
    required this.gridFocusNode,
    required this.onFocus,
    required this.onStartEditing,
    required this.onCommit,
    required this.onToggleSelection,
    required this.onShowContextMenu,
    required this.getColumnWidth,
    required this.isFixed,
    this.columns = const [],
  });

  Border? _buildCellBorder(bool isFocused) {
     if (isFocused) {
        return Border.all(color: Colors.blue, width: 2);
     }
     return Border(bottom: BorderSide(color: Colors.grey.shade200));
  }

  String _getCellValue(String col) {
      final p = participant;
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

  @override
  Widget build(BuildContext context) {
    if (isFixed) {
      // Render Fixed Part (Checkbox + Name)
      final isFocused = focusedParticipantId == participant.id && focusedColumnKey == 'Nome';
      
      return Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : (isEven ? Colors.white : Colors.grey[50]),
          border: _buildCellBorder(isFocused),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Checkbox(
                value: isSelected,
                onChanged: (val) => onToggleSelection(participant.id, val),
              ),
            ),
             Expanded(
                child: DataGridCell(
                   participant: participant,
                   column: 'Nome',
                   isSelected: isSelected,
                   isFocused: isFocused,
                   isEditing: editingId == participant.id && editingField == 'Nome',
                   editController: editController,
                   editFocusNode: editFocusNode,
                   onTap: () {
                       onFocus(participant.id, 'Nome');
                       gridFocusNode.requestFocus();
                   },
                   onDoubleTap: () => onStartEditing(participant.id, 'Nome', participant.name),
                   onSecondaryTapDown: (details) {
                      onFocus(participant.id, 'Nome');
                      onShowContextMenu(details, participant, 'Nome');
                   },
                   onCommit: (val) {
                      editController.text = val;
                      onCommit(participant);
                   },
                ),
             ),
          ],
        ),
      );
    } else {
      // Render Scrollable Part
       return Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : (isEven ? Colors.white : Colors.grey[50]),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: columns.map((col) {
              final isFocused = focusedParticipantId == participant.id && focusedColumnKey == col;
              return Container(
                width: getColumnWidth(col),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                   border: _buildCellBorder(isFocused),
                ),
                child: DataGridCell(
                  participant: participant,
                  column: col,
                  isSelected: isSelected,
                  isFocused: isFocused,
                  isEditing: editingId == participant.id && editingField == col,
                  editController: editController,
                  editFocusNode: editFocusNode,
                  onTap: () {
                      onFocus(participant.id, col);
                      gridFocusNode.requestFocus();
                  },
                  onDoubleTap: () => onStartEditing(participant.id, col, _getCellValue(col)),
                  onSecondaryTapDown: (details) {
                     onFocus(participant.id, col);
                     onShowContextMenu(details, participant, col);
                  },
                  onCommit: (val) {
                     editController.text = val;
                     onCommit(participant);
                  },
                ),
              );
            }).toList(),
          ),
       );
    }
  }
}
