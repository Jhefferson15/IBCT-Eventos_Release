
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/participant_grid_provider.dart';


class DataGridHeaderCell extends ConsumerWidget {
  final String label;
  final double width;
  final String eventId;
  final bool isFixed; // If true (e.g. Name), disable reordering/hiding if needed

  const DataGridHeaderCell({
    super.key,
    required this.label,
    required this.width,
    required this.eventId,
    this.isFixed = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access State
    final gridState = ref.watch(participantGridStateProvider(eventId));
    final gridNotifier = ref.read(participantGridStateProvider(eventId).notifier);

    final columnKey = label;
    final isSortColumn = gridState.sortColumnKey == columnKey;
    final isFiltered = gridState.columnFilters.containsKey(columnKey);

    // Content Display
    final content = Container(
      width: width,
      height: 50,
      decoration: BoxDecoration(
         color: Colors.grey[100], 
         border: Border(
            right: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300, width: 2),
         ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            right: 15,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => gridNotifier.setSort(columnKey, !gridState.sortAscending),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              label, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                              overflow: TextOverflow.ellipsis
                            )
                          ),
                          if (isSortColumn)
                            Icon(
                              gridState.sortAscending ? Icons.arrow_upward : Icons.arrow_downward, 
                              size: 14, 
                              color: Colors.blue
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                   onTap: () => _showFilterDialog(context, columnKey, gridState.columnFilters[columnKey], gridNotifier),
                   child: Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Icon(
                        Icons.filter_alt, 
                        size: 16, 
                        color: isFiltered ? Colors.blue : Colors.grey.shade400
                     ),
                   ),
                ),
              ],
            ),
          ),
          
          // Resize Handle
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                   final newWidth = width + details.delta.dx;
                   if (newWidth > 50) {
                       gridNotifier.setColumnWidth(columnKey, newWidth);
                   }
                },
                child: Container(
                  width: 15,
                  color: Colors.transparent, 
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 2,
                    height: 25,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isFixed) return content;

    // Draggable for reordering
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != columnKey && details.data != 'Nome',
      onAcceptWithDetails: (details) {
         final fromKey = details.data;
         
         // Reorder Logic relying on current filtered list to get full column list visibility
         final data = ref.read(filteredParticipantsProvider(eventId)).value;
         if (data != null) {
            final visible = List<String>.from(data.visibleColumns);
            final oldIndex = visible.indexOf(fromKey);
            final newIndex = visible.indexOf(columnKey);
            
            if (oldIndex != -1 && newIndex != -1) {
               visible.removeAt(oldIndex);
               visible.insert(newIndex, fromKey);
               gridNotifier.setColumnOrder(visible);
            }
         }
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<String>(
          data: columnKey,
          feedback: Material(
            elevation: 4,
            child: SizedBox(
               width: width, 
               height: 50, 
               child: content
            ),
          ),
          child: candidateData.isNotEmpty 
             ? Container(
                 width: width,
                 height: 50,
                 decoration: BoxDecoration(
                   border: Border(left: BorderSide(color: Colors.blue, width: 2)),
                 ),
                 child: content,
               ) 
             : content,
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context, String column, String? currentValue, ParticipantGridNotifier notifier) {
     final controller = TextEditingController(text: currentValue);
     showDialog(
       context: context,
       builder: (context) {
          return AlertDialog(
             title: Text('Filtrar $column'),
             content: TextField(
               controller: controller,
               autofocus: true,
               decoration: const InputDecoration(hintText: 'Digite para filtrar...'),
               onSubmitted: (val) {
                  notifier.setFilter(column, val);
                  Navigator.of(context).pop();
               },
             ),
             actions: [
                TextButton(
                  onPressed: () {
                     notifier.setFilter(column, '');
                     Navigator.of(context).pop();
                  },
                  child: const Text('Limpar'),
                ),
                ElevatedButton(
                  onPressed: () {
                     notifier.setFilter(column, controller.text);
                     Navigator.of(context).pop();
                  },
                  child: const Text('Aplicar'),
                ),
             ],
          );
       }
     );
  }
}
