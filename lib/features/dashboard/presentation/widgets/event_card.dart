import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../events/domain/models/event_model.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onEditEvent;
  final VoidCallback onEditParticipants;
  final VoidCallback onViewParticipants;
  final VoidCallback onStats;
  final VoidCallback onDelete;
  final VoidCallback? onLinkGoogleForms;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onEditEvent,
    required this.onEditParticipants,
    required this.onViewParticipants,
    required this.onStats,
    required this.onDelete,
    this.onLinkGoogleForms,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Simple breakpoint for card internal layout
        final isCompact = constraints.maxWidth < 350; 

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap ?? onViewParticipants,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header: Title & Menu ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (event.location.isNotEmpty) ...[
                              const Gap(4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, 
                                    size: 14, color: AppTheme.textLight),
                                  const Gap(4),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textLight,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildPopupMenu(context),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // --- Body Content ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description 
                        if (event.description.isNotEmpty) ...[
                           Text(
                            event.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                            ),
                            maxLines: isCompact ? 2 : 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(12),
                        ],

                        // Info Grid
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip(
                                  context,
                                  Icons.calendar_today,
                                  DateFormat('dd/MM/yyyy').format(event.date),
                                ),
                                if (event.responsiblePersons.isNotEmpty)
                                  _buildInfoChip(
                                    context,
                                    Icons.person_outline,
                                    event.responsiblePersons,
                                  ),
                                if (!isCompact && event.phoneWhatsApp.isNotEmpty)
                                  _buildInfoChip(
                                    context,
                                    Icons.phone,
                                    event.phoneWhatsApp,
                                  ),
                                if (!isCompact && event.eventEmail.isNotEmpty)
                                  _buildInfoChip(
                                    context,
                                    Icons.email_outlined,
                                    event.eventEmail,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Footer: Stats & Actions ---
                  const Gap(8),
                  Row(
                    children: [
                      InkWell(
                        onTap: onViewParticipants,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people, size: 14, color: AppTheme.primaryRed),
                              const Gap(4),
                              Text(
                                '${event.participantCount}',
                                style: const TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Shortct Action
                      InkWell(
                        onTap: onStats,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.analytics_outlined, 
                            color: AppTheme.textLight, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textLight),
        const Gap(4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textLight,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, color: AppTheme.textLight),
      itemBuilder: (context) => <PopupMenuEntry>[
        PopupMenuItem(
          onTap: onStats,
          child: const Row(
            children: [
              Icon(Icons.bar_chart, size: 20),
              SizedBox(width: 8),
              Text('Ver Painel'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onEditEvent,
          child: const Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Editar Evento'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onEditParticipants,
          child: const Row(
            children: [
              Icon(Icons.people, size: 20),
              SizedBox(width: 8),
              Text('Editar Participantes'),
            ],
          ),
        ),
        if (onLinkGoogleForms != null)
          PopupMenuItem(
            onTap: onLinkGoogleForms,
            child: const Row(
              children: [
                Icon(Icons.link, size: 20),
                SizedBox(width: 8),
                Text('Vincular Google Forms'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: onDelete,
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Excluir', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
