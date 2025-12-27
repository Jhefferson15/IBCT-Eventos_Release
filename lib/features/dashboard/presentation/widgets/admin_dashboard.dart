
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../event_creation/presentation/widgets/event_creation_modal.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/dashboard_controller.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/event_list.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(String eventId, String eventTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o evento "$eventTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(dashboardControllerProvider.notifier).deleteEvent(eventId, eventTitle);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento excluído com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir evento: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final isSearchExpanded = dashboardState.isSearchExpanded;
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: DashboardAppBar(tabController: _tabController),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const EventCreationModal(),
          );
        },
        label: const Text('Novo Evento'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      EventList(
                        eventsAsync: isSearchExpanded && searchQuery.length > 3
                            ? ref.watch(filteredEventsProvider)
                            : ref.watch(activeEventsProvider),
                        isSearchExpanded: isSearchExpanded,
                        onDelete: _confirmDelete,
                      ),
                      EventList(
                        eventsAsync: ref.watch(archivedEventsProvider),
                        isSearchExpanded: isSearchExpanded,
                        onDelete: _confirmDelete,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, color: Colors.grey.shade200),
                const Expanded(
                  flex: 1,
                  child: DashboardSidebar(),
                ),
              ],
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              EventList(
                eventsAsync: isSearchExpanded && searchQuery.length > 3
                    ? ref.watch(filteredEventsProvider)
                    : ref.watch(activeEventsProvider),
                isSearchExpanded: isSearchExpanded,
                onDelete: _confirmDelete,
              ),
              EventList(
                eventsAsync: ref.watch(archivedEventsProvider),
                isSearchExpanded: isSearchExpanded,
                onDelete: _confirmDelete,
              ),
            ],
          );
        },
      ),
    );
  }
}
