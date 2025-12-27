
import 'package:flutter/material.dart';
import '../../../domain/models/participant_model.dart';

class DataGridCell extends StatelessWidget {
  final Participant participant;
  final String column;
  final bool isSelected;
  final bool isFocused;
  final bool isEditing;
  final TextEditingController? editController;
  final FocusNode? editFocusNode;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Function(TapDownDetails)? onSecondaryTapDown;
  final Function(String)? onCommit;

  const DataGridCell({
    super.key,
    required this.participant,
    required this.column,
    required this.isSelected,
    this.isFocused = false,
    this.isEditing = false,
    this.editController,
    this.editFocusNode,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTapDown,
    this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing && editController != null && editFocusNode != null) {
      return _buildEditor();
    }

    return _buildDisplay();
  }

  Widget _buildDisplay() {
    final value = _getCellValue(participant, column);

    // Common container style can be applied by parent/wrapper, but inner visual styles (like badges) go here.
    Widget content;

    if (column == 'Status') {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value == 'Confirmado'
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(value,
            style: TextStyle(
                fontSize: 12,
                color: value == 'Confirmado' ? Colors.green : Colors.orange)),
      );
    } else {
      content = Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      );
    }

    return InkWell(
      onDoubleTap: onDoubleTap,
      onTap: onTap,
      onSecondaryTapDown: onSecondaryTapDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
           // Center vertically
          child: Align(
            alignment: Alignment.centerLeft,
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    if (column == 'Status') {
       final initial = ['Confirmado', 'Pendente', 'Cancelado', 'Credenciado'].contains(participant.status) ? participant.status : 'Pendente';
       return DropdownButtonFormField<String>(
         initialValue: initial,
         items: ['Confirmado', 'Pendente', 'Cancelado', 'Credenciado'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
         onChanged: (val) {
           if (val != null) {
              onCommit?.call(val);
           }
         },
         decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
         focusNode: editFocusNode,
       );
    }
    
    if (column == 'Ingresso') {
       final initial = ['Standard', 'VIP', 'Staff', 'Palestrante', 'Estudante'].contains(participant.ticketType) ? participant.ticketType : 'Standard';
       return DropdownButtonFormField<String>(
         initialValue: initial,
         items: ['Standard', 'VIP', 'Staff', 'Palestrante', 'Estudante'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
         onChanged: (val) {
           if (val != null) {
              onCommit?.call(val);
           }
         },
         decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
         focusNode: editFocusNode,
       );
    }

    return TextField(
      controller: editController,
      focusNode: editFocusNode,
      decoration: const InputDecoration(
         isDense: true,
         border: InputBorder.none,
         contentPadding: EdgeInsets.all(8),
      ),
      style: const TextStyle(fontSize: 13),
      onSubmitted: (val) => onCommit?.call(val),
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
}
