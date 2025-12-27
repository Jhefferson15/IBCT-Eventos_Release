import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../editor/presentation/pages/editor_screen.dart';
import '../../../editor/presentation/widgets/participant_detail_dialog.dart';
import '../providers/participant_list_controller.dart';
import '../widgets/participant_list_item.dart';

class ParticipantListScreen extends ConsumerWidget {
  final String eventId;

  const ParticipantListScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(paginatedParticipantsProvider(eventId));
    final listState = ref.watch(participantListStateProvider(eventId));
    final notifier = ref.read(participantListStateProvider(eventId).notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Participantes'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, size: 28), // Pen/Spreadsheet icon
            tooltip: 'Editor (Planilha)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditorScreen(eventId: eventId),
                ),
              ).then((_) {
                 // Refresh list when returning from editor
                 ref.invalidate(participantListStateProvider(eventId));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryRed, size: 28),
            tooltip: 'Adicionar Participante',
            onPressed: () {
               showDialog(
                context: context,
                builder: (context) => ParticipantDetailDialog(eventId: eventId),
              ).then((_) {
                 // Refresh list when returning from dialog
                 ref.invalidate(participantListStateProvider(eventId));
              });
            },
          ),
          const Gap(16),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar participantes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => notifier.setSearchQuery(value),
            ),
          ),

          // List
          Expanded(
            child: participantsAsync.when(
              data: (data) {
                if (data.items.isEmpty) {
                   if (data.totalItems == 0 && listState.searchQuery.isEmpty) {
                     return Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                           const Gap(16),
                           Text(
                             'Nenhum participante encontrado',
                             style: TextStyle(color: Colors.grey.shade600),
                           ),
                           const Gap(8),
                           ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => ParticipantDetailDialog(eventId: eventId),
                                ).then((_) => ref.invalidate(participantListStateProvider(eventId)));
                              },
                              child: const Text('Adicionar Participante'),
                           ),
                         ],
                       ),
                     );
                   }
                   return Center(
                     child: Text(
                       'Nenhum resultado para "${listState.searchQuery}"',
                       style: TextStyle(color: Colors.grey.shade600),
                     ),
                   );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (ResponsiveBreakpoints.isDesktop(constraints.maxWidth)) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 140, // Fixed height for cards
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: data.items.length,
                        itemBuilder: (context, index) {
                           final participant = data.items[index];
                           return Card(
                             clipBehavior: Clip.antiAlias,
                             child: InkWell(
                               onTap: () {
                                 showDialog(
                                   context: context,
                                   builder: (context) => ParticipantDetailDialog(
                                     participant: participant,
                                     eventId: eventId,
                                   ),
                                 ).then((_) => ref.invalidate(participantListStateProvider(eventId)));
                               },
                               child: Padding(
                                 padding: const EdgeInsets.all(16.0),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Row(
                                       children: [
                                         CircleAvatar(
                                           child: Text(participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?'),
                                         ),
                                         const Gap(12),
                                         Expanded(
                                           child: Text(
                                             participant.name,
                                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                             maxLines: 1,
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                       ],
                                     ),
                                     const Gap(12),
                                      if (participant.email.isNotEmpty)
                                       Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                            const Gap(8),
                                            Expanded(child: Text(participant.email, style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          ],
                                       ),
                                     // Add more details here if needed for Grid view
                                   ],
                                 ),
                               ),
                             ),
                           );
                        },
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: data.items.length,
                      itemBuilder: (context, index) {
                        final participant = data.items[index];
                        return ParticipantListItem(
                          participant: participant,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => ParticipantDetailDialog(
                                participant: participant,
                                eventId: eventId,
                              ),
                            ).then((_) => ref.invalidate(participantListStateProvider(eventId)));
                          },
                        );
                      },
                    );
                  }
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erro: $err')),
            ),
          ),

          // Pagination Controls
          participantsAsync.when(
            data: (data) {
              if (data.totalPages <= 1) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${data.totalItems} participantes',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: data.currentPage > 1
                              ? () => notifier.previousPage()
                              : null,
                        ),
                        Text(
                          '${data.currentPage} / ${data.totalPages}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: data.currentPage < data.totalPages
                              ? () => notifier.nextPage()
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
