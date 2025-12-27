import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../features/events/presentation/providers/event_providers.dart';
import '../providers/user_providers.dart';
import 'activity_log_list.dart';

class HelperDashboardSection extends ConsumerWidget {
  const HelperDashboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    // Filter events where currentUser is authorized
    final eventsAsync = ref.watch(eventsProvider);
    final authorizedEvents = eventsAsync.whenData((events) {
      return events.where((e) => e.authorizedUsers.contains(currentUser?.id)).toList();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Painel do Funcionário',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Gap(16),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to Check-in Sceen
            },
            icon: const Icon(Icons.qr_code_scanner, size: 28),
            label: const Text('Ler QR Code / Check-in'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const Gap(24),
        const Text('Eventos Designados'),
        const Gap(8),
         authorizedEvents.when(
            data: (events) {
              if (events.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Você não possui eventos vinculados.')),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(event.title),
                      subtitle: Text('Data: ${event.date.day}/${event.date.month}'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erro: $err')),
         ),
        const Gap(24),
        Text(
          'Minhas Atividades',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Gap(8),
        const ActivityLogList(shrinkWrap: true),
      ],
    );
  }
}
