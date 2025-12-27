
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:go_router/go_router.dart';

import '../../../events/domain/models/event_model.dart';
import '../widgets/event_card.dart';
import '../../../event_creation/presentation/widgets/event_edit_modal.dart';
import '../../../editor/presentation/widgets/participant_import_modal.dart'; // Import Import Modal
import '../../../shared/import/presentation/import_state.dart'; // Fixed path for ImportSource

class EventList extends ConsumerStatefulWidget {
  final AsyncValue<List<Event>> eventsAsync;
  final bool isSearchExpanded;
  final Function(String, String) onDelete;

  const EventList({
    super.key,
    required this.eventsAsync,
    required this.isSearchExpanded,
    required this.onDelete,
  });

  @override
  ConsumerState<EventList> createState() => _EventListState();
}

class _EventListState extends ConsumerState<EventList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return widget.eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                     const Gap(16),
                     Text(
                       'Nenhum evento encontrado',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                     ),
                     if (!widget.isSearchExpanded) ...[
                       const Gap(8),
                       const Text('Crie seu primeiro evento clicando no botão abaixo.'),
                     ]
                   ],
                 ),
               );
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(isMobile ? 12 : 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: isMobile ? 12 : 24,
                      crossAxisSpacing: isMobile ? 12 : 24,
                      childAspectRatio: isMobile ? 1.85 : 1.55,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = events[index];
                          return EventCard(
                            event: event,
                            onTap: () {
                              context.push('/analytics/${event.id}');
                            },
                            onEditEvent: () {
                              showDialog(
                                context: context,
                                builder: (context) => EventEditModal(event: event),
                              );
                            },
                          onEditParticipants: () {
                            context.push('/editor/${event.id}');
                          },
                          onViewParticipants: () {
                            context.push('/participants/${event.id}');
                          },
                          onLinkGoogleForms: () {
                            showDialog(
                              context: context,
                              builder: (context) => ParticipantImportModal(
                                eventId: event.id!,
                                initialSource: ImportSource.googleForms,
                              ),
                            );
                          },
                          onStats: () {
                            context.push('/analytics/${event.id}');
                          },
                          onDelete: () {
                            widget.onDelete(event.id!, event.title);
                          },
                        ).animate().scale(
                              delay: (index * 50).ms,
                              duration: 300.ms,
                              curve: Curves.easeOutBack,
                            );
                      },
                      childCount: events.length,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Erro ao carregar eventos: $err'),
          ),
        );
      },
    );
  }
}
