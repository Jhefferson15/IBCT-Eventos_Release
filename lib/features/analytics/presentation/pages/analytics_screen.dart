import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../export/presentation/dialogs/export_options_dialog.dart';
import '../../../editor/domain/models/participant_model.dart';
import '../../../shared/import/presentation/import_state.dart'; 
import '../../../editor/presentation/widgets/participant_import_modal.dart';
import '../controllers/analytics_dashboard_controller.dart';
import '../widgets/sync_status_card.dart';
import '../widgets/analytics_charts_widgets.dart';
import '../widgets/analytics_stat_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  final String eventId;
  const AnalyticsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsDashboardControllerProvider(eventId));
    final eventAsync = ref.watch(singleEventProvider(eventId));
    final eventName = eventAsync.value?.title ?? 'Evento';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Painel do Evento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/checkin'),
            tooltip: 'Check-in',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Erro: ${state.error}'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 800;
                      final participants = state.participants;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SyncStatusCard(eventId: eventId),
                          const Gap(16),
                          Text(
                            'Visão Geral',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Gap(16),
                          // Stats Cards
                          if (isMobile)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    AnalyticsStatCard(
                                      title: 'Inscritos',
                                      value: state.total.toString(),
                                      icon: Icons.people_alt,
                                      color: Colors.blue,
                                      onTap: () =>
                                          context.push('/participants/$eventId'),
                                    ),
                                    const Gap(12),
                                    AnalyticsStatCard(
                                      title: 'Confirmados',
                                      value: state.confirmed.toString(),
                                      icon: Icons.check_circle,
                                      color: Colors.green,
                                      onTap: () =>
                                          context.push('/participants/$eventId'),
                                    ),
                                  ],
                                ),
                                const Gap(12),
                                Row(
                                  children: [
                                    AnalyticsStatCard(
                                      title: 'Pendentes',
                                      value: state.pending.toString(),
                                      icon: Icons.pending,
                                      color: Colors.orange,
                                      onTap: () =>
                                          context.push('/participants/$eventId'),
                                    ),
                                    const Gap(12),
                                    AnalyticsStatCard(
                                      title: 'Check-in',
                                      value: state.checkedIn.toString(),
                                      icon: Icons.qr_code_scanner,
                                      color: AppTheme.primaryRed,
                                      onTap: () =>
                                          context.push('/participants/$eventId'),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                AnalyticsStatCard(
                                  title: 'Total de Inscritos',
                                  value: state.total.toString(),
                                  icon: Icons.people_alt,
                                  color: Colors.blue,
                                  onTap: () =>
                                      context.push('/participants/$eventId'),
                                ),
                                const Gap(16),
                                AnalyticsStatCard(
                                  title: 'Confirmados',
                                  value: state.confirmed.toString(),
                                  icon: Icons.check_circle,
                                  color: Colors.green,
                                  onTap: () =>
                                      context.push('/participants/$eventId'),
                                ),
                                const Gap(16),
                                AnalyticsStatCard(
                                  title: 'Pendentes',
                                  value: state.pending.toString(),
                                  icon: Icons.pending,
                                  color: Colors.orange,
                                  onTap: () =>
                                      context.push('/participants/$eventId'),
                                ),
                                const Gap(16),
                                AnalyticsStatCard(
                                  title: 'Check-in Realizado',
                                  value: state.checkedIn.toString(),
                                  icon: Icons.qr_code_scanner,
                                  color: AppTheme.primaryRed,
                                  onTap: () =>
                                      context.push('/participants/$eventId'),
                                ),
                              ],
                            ),
                          const Gap(24),

                          // Charts Grid
                          if (isMobile)
                            Column(
                              children: [
                                CheckInProgressBar(
                                    checkedIn: state.checkedIn,
                                    total: state.total),
                                const Gap(12),
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/participants/$eventId'),
                                  child: ParticipantsStatusChart(
                                      confirmed: state.confirmed,
                                      pending: state.pending,
                                      total: state.total),
                                ),
                                const Gap(12),
                                CheckInTimelineChart(participants: participants),
                                const Gap(12),
                                TicketTypeDistributionChart(
                                    participants: participants),
                                const Gap(12),
                                _buildActionsSection(
                                    context, participants, eventName, eventId),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      CheckInTimelineChart(
                                          participants: participants),
                                      const Gap(16),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: TicketTypeDistributionChart(
                                                participants: participants),
                                          ),
                                          const Gap(16),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => context
                                                  .push('/participants/$eventId'),
                                              child: ParticipantsStatusChart(
                                                  confirmed: state.confirmed,
                                                  pending: state.pending,
                                                  total: state.total),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      CheckInProgressBar(
                                          checkedIn: state.checkedIn,
                                          total: state.total),
                                      const Gap(16),
                                      _buildActionsSection(context, participants,
                                          eventName, eventId),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildActionsSection(BuildContext context,
      List<Participant> participants, String eventName, String eventId) {
    return Column(
      children: [
        Card(
          child: ListTile(
            dense: true,
            leading: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Icon(Icons.download, color: Colors.white, size: 20)),
            title: const Text('Exportar Relatório'),
            subtitle: const Text('PDF, Excel, CSV, QR Codes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ExportOptionsDialog(
                  participants: participants,
                  eventName: eventName,
                ),
              );
            },
          ),
        ),
        const Gap(12),
        Card(
          child: ListTile(
            dense: true,
            leading: const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryRed,
                child: Icon(Icons.edit, color: Colors.white, size: 20)),
            title: const Text('Editar Participantes'),
            subtitle: const Text('Ir para o Editor'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/editor/$eventId'),
          ),
        ),
        const Gap(12),
        Card(
          child: ListTile(
            dense: true,
            leading: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.purple,
                child: Icon(Icons.store, color: Colors.white, size: 20)),
            title: const Text('Loja'),
            subtitle: const Text('Vendas e Configurações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/store-dashboard/$eventId'),
          ),
        ),
        const Gap(12),
        Card(
          child: ListTile(
            dense: true,
            leading: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green,
                child: Icon(Icons.link, color: Colors.white, size: 20)),
            title: const Text('Vincular Google Forms'),
            subtitle: const Text('Importar novas respostas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ParticipantImportModal(
                  eventId: eventId,
                  initialSource: ImportSource.googleForms,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
