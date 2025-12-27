import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../features/dashboard/presentation/widgets/stat_card.dart';
import '../../../../features/events/presentation/providers/event_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEventsAsync = ref.watch(activeEventsProvider);
    final globalCountAsync = ref.watch(globalParticipantCountProvider);
    final activitiesAsync = ref.watch(recentActivitiesProvider);

    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas Rápidas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          activeEventsAsync.when(
            data: (events) => StatCard(
              title: 'Eventos Ativos',
              value: events.length.toString(),
              icon: Icons.event_available,
              color: Colors.green,
            ),
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('Erro ao carregar eventos'),
          ),
          const Gap(8),
          globalCountAsync.when(
            data: (count) => StatCard(
              title: 'Total de Participantes',
              value: count.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('Erro ao carregar saldo'),
          ),
          const Gap(32),
          Text(
            'Atividade Recente',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          Expanded(
            child: activitiesAsync.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return const Center(child: Text('Nenhuma atividade recente'));
                }
                return ListView.builder(
                  itemCount: activities.length > 5 ? 5 : activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityItem(
                      activity.actionType.name,
                      _formatTime(activity.timestamp),
                      _getIconForAction(activity.actionType.name),
                      _getColorForAction(activity.actionType.name),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Erro: $err'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'Há ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Há ${difference.inHours} horas';
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }

  IconData _getIconForAction(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('criado') || lower.contains('create')) return Icons.add_circle;
    if (lower.contains('excluído') || lower.contains('delete')) return Icons.delete;
    if (lower.contains('editado') || lower.contains('update')) return Icons.edit;
    if (lower.contains('import')) return Icons.upload_file;
    if (lower.contains('login')) return Icons.login;
    return Icons.notifications;
  }

  Color _getColorForAction(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('criado') || lower.contains('create')) return Colors.orange;
    if (lower.contains('excluído') || lower.contains('delete')) return Colors.red;
    if (lower.contains('editado') || lower.contains('update')) return Colors.blue;
    if (lower.contains('import')) return Colors.indigo;
    if (lower.contains('login')) return Colors.grey;
    return Colors.teal;
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 16,
            child: Icon(icon, color: color, size: 16),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
