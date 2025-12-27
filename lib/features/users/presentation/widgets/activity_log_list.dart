
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/activity_log.dart';
import '../providers/activity_log_provider.dart';
import '../providers/user_providers.dart';

class ActivityLogList extends ConsumerWidget {
  final bool shrinkWrap;
  const ActivityLogList({super.key, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final logsAsync = ref.watch(activityLogsProvider(currentUser?.id));

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('Nenhuma atividade registrada.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          itemCount: logs.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildLogTile(context, log);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro ao carregar logs: $err')),
    );
  }

  Widget _buildLogTile(BuildContext context, ActivityLog log) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getColorForAction(log.actionType).withValues(alpha: 0.1),
        child: Icon(_getIconForAction(log.actionType), color: _getColorForAction(log.actionType), size: 20),
      ),
      title: Text(
        _getTitleForAction(log),
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.details.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _getDetailsText(log),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp),
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _getTitleForAction(ActivityLog log) {
    switch (log.actionType) {
      case ActivityActionType.login:
        return 'Login Realizado';
      case ActivityActionType.logout:
        return 'Logout Realizado';
      case ActivityActionType.sale:
        return 'Venda Realizada';
      case ActivityActionType.surveyAnswer:
        return 'Pesquisa Respondida';
      case ActivityActionType.productCreate:
        return 'Produto Criado';
      case ActivityActionType.productUpdate:
        return 'Produto Atualizado';
      case ActivityActionType.productDelete:
        return 'Produto Removido';
      case ActivityActionType.surveyCreate:
        return 'Pesquisa Criada';
      case ActivityActionType.profileUpdate:
        return 'Perfil Atualizado';
      case ActivityActionType.createEvent:
        return 'Evento Criado';
      case ActivityActionType.updateEvent:
        return 'Evento Atualizado';
      case ActivityActionType.deleteEvent:
        return 'Evento Excluído';
      case ActivityActionType.addParticipant:
        return 'Participante Adicionado';
      case ActivityActionType.updateParticipant:
        return 'Participante Atualizado';
      case ActivityActionType.importParticipants:
        return 'Importação Realizada';
      case ActivityActionType.deleteParticipant:
        return 'Participante Removido';
      case ActivityActionType.checkInParticipant:
        return 'Check-in Realizado';
      case ActivityActionType.addHelper:
        return 'Funcionário Adicionado';
      case ActivityActionType.removeHelper:
        return 'Funcionário Removido';
      case ActivityActionType.unknown:
        return 'Atividade Desconhecida';
    }
  }

  String _getDetailsText(ActivityLog log) {
    switch (log.actionType) {
      case ActivityActionType.login:
      case ActivityActionType.logout:
        return 'Via ${log.details['method'] ?? 'app'}';
      case ActivityActionType.sale:
        return log.details.containsKey('itemCount') 
            ? '${log.details['itemCount']} itens - R\$ ${(log.details['totalValue'] as num?)?.toStringAsFixed(2)}'
            : '${log.details['productName']} - R\$ ${(log.details['value'] as num?)?.toStringAsFixed(2)}';
      case ActivityActionType.surveyAnswer:
        return 'Respondido por ${log.details['email']}';
      case ActivityActionType.createEvent:
      case ActivityActionType.updateEvent:
        return '${log.details['title'] ?? 'Sem título'}';
      case ActivityActionType.addParticipant:
      case ActivityActionType.updateParticipant:
      case ActivityActionType.checkInParticipant:
        return '${log.details['name'] ?? 'Sem nome'}';
      case ActivityActionType.importParticipants:
        return '${log.details['count']} participantes importados';
      case ActivityActionType.addHelper:
      case ActivityActionType.removeHelper:
        return '${log.details['name'] ?? 'Sem nome'} (${log.details['email'] ?? 'Sem email'})';
      default:
        return log.details.isNotEmpty ? log.details.toString() : '';
    }
  }

  IconData _getIconForAction(ActivityActionType type) {
    switch (type) {
      case ActivityActionType.login:
        return Icons.login;
      case ActivityActionType.logout:
        return Icons.logout;
      case ActivityActionType.sale:
        return Icons.point_of_sale;
      case ActivityActionType.surveyAnswer:
        return Icons.assignment_turned_in;
      case ActivityActionType.productCreate:
      case ActivityActionType.productUpdate:
        return Icons.shopping_bag;
      case ActivityActionType.productDelete:
        return Icons.remove_shopping_cart;
      case ActivityActionType.surveyCreate:
        return Icons.poll;
      case ActivityActionType.profileUpdate:
        return Icons.person_outline;
      case ActivityActionType.createEvent:
        return Icons.event;
      case ActivityActionType.addParticipant:
      case ActivityActionType.updateParticipant:
        return Icons.person_add;
      case ActivityActionType.importParticipants:
        return Icons.upload_file;
      case ActivityActionType.addHelper:
      case ActivityActionType.removeHelper:
        return Icons.badge;
      case ActivityActionType.updateEvent:
        return Icons.edit;
      case ActivityActionType.deleteEvent:
        return Icons.delete;
      case ActivityActionType.deleteParticipant:
        return Icons.person_remove;
      case ActivityActionType.checkInParticipant:
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _getColorForAction(ActivityActionType type) {
    switch (type) {
      case ActivityActionType.login:
      case ActivityActionType.logout:
        return Colors.blueGrey;
      case ActivityActionType.sale:
        return Colors.green.shade700;
      case ActivityActionType.surveyAnswer:
        return Colors.indigo;
      case ActivityActionType.createEvent:
        return Colors.blue;
      case ActivityActionType.addParticipant:
        return Colors.green;
      case ActivityActionType.importParticipants:
        return Colors.orange;
      case ActivityActionType.addHelper:
        return Colors.purple;
      case ActivityActionType.deleteEvent:
      case ActivityActionType.deleteParticipant:
        return Colors.red;
       case ActivityActionType.checkInParticipant:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
