import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/participant_grid_provider.dart';
import 'data_grid_header_cell.dart';

class DataGridHeader extends ConsumerWidget {
  final String eventId;
  final ScrollController headerController;
  final ParticipantGridData gridData;

  const DataGridHeader({
    super.key,
    required this.eventId,
    required this.headerController,
    required this.gridData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridState = ref.watch(participantGridStateProvider(eventId));
    final gridNotifier = ref.read(participantGridStateProvider(eventId).notifier);

    final participants = gridData.participants;
    final otherCols = gridData.visibleColumns.where((c) => c != 'Nome').toList();
    
    // Default Widths helper
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

    return Row(
      children: [
        // Fixed Left Header (Selection + Name)
        SizedBox(
          width: 300, // Fixed width for Checkbox(50) + Name(250)
          child: Container(
            height: 50,
            color: Colors.grey[100],
            child: Row(
              children: [
                // Select All Checkbox
                SizedBox(
                  width: 50,
                  child: Checkbox(
                    value: participants.isNotEmpty && gridState.selectedIds.length == participants.length,
                    onChanged: (val) {
                      if (val == true) {
                         for(var p in participants) {
                           gridNotifier.toggleSelection(p.id, true);
                         }
                      } else {
                         gridNotifier.clearSelection();
                      }
                    },
                  ),
                ),
                // Name Header (Fixed)
                Expanded(
                  child: DataGridHeaderCell(
                    label: 'Nome',
                    width: 250,
                    eventId: eventId,
                    isFixed: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Vertical Divider
        const VerticalDivider(width: 1, thickness: 1),
        
        // Scrollable Right Header
        Expanded(
          child: SingleChildScrollView(
            controller: headerController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: otherCols.map((col) {
                return DataGridHeaderCell(
                   label: col,
                   width: getColumnWidth(col),
                   eventId: eventId,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
