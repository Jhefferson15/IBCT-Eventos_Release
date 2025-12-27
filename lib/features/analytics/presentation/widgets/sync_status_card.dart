import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:ibct_eventos/features/events/presentation/providers/event_providers.dart';
import '../controllers/sync_controller.dart';

class SyncStatusCard extends ConsumerWidget {
  final String eventId;
  const SyncStatusCard({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(singleEventProvider(eventId));
    final isSyncing = ref.watch(syncControllerProvider);

    return eventAsync.when(
      data: (event) {
        if (event == null) return const SizedBox.shrink();
        final hasLink = event.googleSheetsUrl != null &&
            event.googleSheetsUrl!.isNotEmpty;
        if (!hasLink) return const SizedBox.shrink();

        final lastSync = event.lastSyncTime != null
            ? DateFormat('dd/MM HH:mm').format(event.lastSyncTime!)
            : 'Nunca';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
          ),
          color: Colors.green.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.googleDrive,
                    color: Colors.green, size: 32),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Integração Google Forms Ativa',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                      Text(
                        'Última sincronização: $lastSync',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isSyncing)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  TextButton.icon(
                    onPressed: () async {
                      final result = await ref
                          .read(syncControllerProvider.notifier)
                          .syncParticipants(eventId);

                      if (context.mounted) {
                        if (result['success']) {
                          final count = result['newCount'];
                          if (count > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '$count novos participantes sincronizados!'),
                                  backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Tudo atualizado! Nenhum participante novo encontrado.')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Erro na sincronização: ${result['error']}'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Sincronizar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  )
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
