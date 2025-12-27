
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../providers/dashboard_controller.dart';

class DashboardAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final TabController tabController;

  const DashboardAppBar({super.key, required this.tabController});

  @override
  ConsumerState<DashboardAppBar> createState() => _DashboardAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
}

class _DashboardAppBarState extends ConsumerState<DashboardAppBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
     ref.read(dashboardControllerProvider.notifier).updateSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final isSearchExpanded = dashboardState.isSearchExpanded;

    return AppBar(
      backgroundColor: Colors.white,
      leading: isSearchExpanded
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                ref.read(dashboardControllerProvider.notifier).toggleSearch();
                _searchController.clear();
              },
            )
          : null,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isSearchExpanded
            ? TextField(
                key: const ValueKey('SearchField'),
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Digite e pressione Enter...',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: InputBorder.none,
                ),
              )
            : const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Painel Admin',
                  key: ValueKey('Title'),
                  style: TextStyle(color: Colors.black),
                ),
              ),
      ),
      actions: isSearchExpanded
          ? [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  _searchController.clear();
                  ref.read(dashboardControllerProvider.notifier).updateSearchQuery('');
                },
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => ref.read(dashboardControllerProvider.notifier).toggleSearch(),
                tooltip: 'Buscar Evento',
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.push('/profile'),
                tooltip: 'Minha Conta',
              ),
              const Gap(8),
            ],
      bottom: TabBar(
        controller: widget.tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.black54,
        tabs: const [
          Tab(text: 'Ativos'),
          Tab(text: 'Arquivados'),
        ],
      ),
    );
  }
}
