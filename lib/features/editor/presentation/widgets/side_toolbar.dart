import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/data_generator.dart';
import 'participant_detail_dialog.dart';
import 'participant_import_modal.dart';
import 'qr_export_dialog.dart';
import 'column_manager_dialog.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/participant_providers.dart';
import '../../../users/presentation/providers/user_providers.dart';
import '../providers/participant_grid_provider.dart';

class SideToolbar extends ConsumerWidget {
  final String eventId;
  
  const SideToolbar({
    super.key,
    required this.eventId,
  });

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
  
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _generateQr(BuildContext context, WidgetRef ref) {
    // Contextual QR: If participants exist, use the first one or a "Template" message
    final participantsAsync = ref.read(participantsControllerProvider(eventId));
    
    participantsAsync.when(
      data: (participants) {
        if (participants.isEmpty) {
          _showError(context, 'Nenhum participante para gerar QR.');
          return;
        }
        
        // Use first participant as example for the "Export Example" button
        final example = participants.first;
        
        showDialog(
          context: context,
          builder: (context) => QrExportDialog(
            data: DataGenerator.generateQrData(eventId, example.id),
            participantName: example.name,
          ),
        );
      },
      loading: () => null,
      error: (_, __) => _showError(context, 'Erro ao carregar participantes.'),
    );
  }

  Future<void> _generateTokens(BuildContext context, WidgetRef ref) async {
    try {
      final controller = ref.read(participantsControllerProvider(eventId).notifier);
      await controller.generateTokens();
      if (context.mounted) _showSuccess(context, 'Tokens gerados com sucesso.');
    } catch (e) {
      if (context.mounted) _showError(context, 'Erro ao gerar tokens: $e');
    }
  }
  
  Future<void> _generatePasswords(BuildContext context, WidgetRef ref) async {
    try {
      final controller = ref.read(participantsControllerProvider(eventId).notifier);
      await controller.generatePasswords();
      if (context.mounted) _showSuccess(context, 'Senhas geradas com sucesso.');
    } catch (e) {
      if (context.mounted) _showError(context, 'Erro ao gerar senhas: $e');
    }
  }

  Future<void> _assignIds(BuildContext context, WidgetRef ref) async {
    try {
      final controller = ref.read(participantsControllerProvider(eventId).notifier);
      await controller.assignSequentialIds();
      if (context.mounted) _showSuccess(context, 'IDs sequenciais atribuídos.');
    } catch (e) {
      if (context.mounted) _showError(context, 'Erro ao atribuir IDs: $e');
    }
  }

  Future<void> _openColumnManager(BuildContext context, WidgetRef ref) async {
    // Determine event - we might need to fetch it since we only have ID here
    // Using simple fetch via provider reading
    try {
      final event = await ref.read(singleEventProvider(eventId).future);
      
      if (context.mounted) {
        if (event != null) {
          final participantsAsync = ref.read(participantsControllerProvider(eventId));
          List<String> knownCustomColumns = [];
          
          participantsAsync.whenData((participants) {
             final Set<String> keys = {};
             for (var p in participants) {
               keys.addAll(p.customFields.keys);
             }
             knownCustomColumns = keys.toList();
          });

          showDialog(
            context: context,
            builder: (context) => ColumnManagerDialog(
              event: event,
              knownCustomColumns: knownCustomColumns,
            ),
          );
        } else {
          _showError(context, 'Evento não encontrado.');
        }
      }
    } catch (e) {
      if (context.mounted) {
         _showError(context, 'Erro ao carregar evento: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Gerenciamento',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ActionButton(
                  icon: Icons.add,
                  label: 'Novo Participante',
                  color: AppTheme.primaryRed,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => ParticipantDetailDialog(eventId: eventId),
                    );
                  },
                ),
                const Gap(8),
                _ActionButton(
                  icon: Icons.view_column,
                  label: 'Gerenciar Colunas',
                  onTap: () => _openColumnManager(context, ref),
                ),
                const Gap(8),
                _ActionButton(
                  icon: Icons.upload_file,
                  label: 'Importar CSV',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => ParticipantImportModal(eventId: eventId),
                    );
                  },
                ),
                const Gap(8),
                _ActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'Visualizar Painel',
                  color: Colors.blue,
                  onTap: () {
                    context.push('/analytics/$eventId');
                  },
                ),
                const Gap(24),
                Text(
                  'Ações em Lote',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),
                const Gap(16),
                _ActionButton(
                  icon: Icons.vpn_key_outlined,
                  label: 'Gerar Tokens',
                  onTap: () => _generateTokens(context, ref),
                ),
                const Gap(8),
                _ActionButton(
                  icon: Icons.password,
                  label: 'Gerar Senhas',
                  onTap: () => _generatePasswords(context, ref),
                ),
                const Gap(8),
                _ActionButton(
                  icon: Icons.perm_identity,
                  label: 'Atribuir IDs',
                  onTap: () => _assignIds(context, ref),
                ),
                const Gap(24),
                // Dynamic Selection Actions
                Consumer(
                  builder: (context, ref, child) {
                    final gridState = ref.watch(participantGridStateProvider(eventId));
                    final selectedCount = gridState.selectedIds.length;
                    
                    if (selectedCount == 0) return const SizedBox.shrink();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seleção ($selectedCount)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                        ),
                        const Gap(16),
                        _ActionButton(
                          icon: Icons.delete,
                          label: 'Excluir Selecionados',
                          color: Colors.red,
                          onTap: () async {
                              final controller = ref.read(participantsControllerProvider(eventId).notifier);
                              final currentUser = ref.read(currentUserProvider).value;
                              
                              if (currentUser == null) return;

                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmar Exclusão'),
                                  content: Text('Deseja excluir $selectedCount participantes?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                  await controller.deleteParticipants(gridState.selectedIds.toList(), currentUser.id);
                                  ref.read(participantGridStateProvider(eventId).notifier).clearSelection();
                              }
                          },
                        ),
                        const Gap(8),
                        _ActionButton(
                          icon: Icons.check_circle,
                          label: 'Confirmar Presença',
                           onTap: () async {
                              final currentUser = ref.read(currentUserProvider).value;
                              if (currentUser == null) return;
                              
                              final controller = ref.read(participantsControllerProvider(eventId).notifier);
                              await controller.bulkUpdateStatus(gridState.selectedIds.toList(), 'Presente', currentUser.id);
                              
                              if (context.mounted) {
                                _showSuccess(context, 'Status atualizado para Confirmado');
                                ref.read(participantGridStateProvider(eventId).notifier).clearSelection();
                              }
                          },
                        ),
                        const Gap(24),
                      ],
                    );
                  },
                ),
                Text(

                  'Ferramentas',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),
                const Gap(16),
                 _ActionButton(
                  icon: Icons.qr_code,
                  label: 'Exportar QR Exemplo',
                  onTap: () => _generateQr(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey.shade100).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color?.withValues(alpha: 0.3) ?? Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppTheme.textDark),
            const Gap(12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color ?? AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
