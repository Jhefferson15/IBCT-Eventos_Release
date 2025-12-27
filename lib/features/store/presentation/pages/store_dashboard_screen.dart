import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../../../core/widgets/content_shell.dart';
import '../../../users/domain/models/app_user.dart';
import '../../../users/presentation/providers/user_providers.dart'; 
import '../providers/store_providers.dart';

class StoreDashboardScreen extends ConsumerWidget {
  final String eventId;

  const StoreDashboardScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(currentUserRoleProvider);
    final isAdmin = userRole == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel da Loja'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ContentShell(
        maxWidth: 1200,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            final isTablet = constraints.maxWidth >= 700 && constraints.maxWidth < 1000;
            final int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo à Gestão da Loja',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Gap(8),
                  Text(
                    'Gerencie vendas, produtos e configurações de forma integrada.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const Gap(32),
                  
                  // Dashboard Stats Header (Dynamic metrics)
                  if (!isMobile) ...[
                     Row(
                        children: [
                          _buildQuickStat(context, 'Status do PDV', 'Ativo', Icons.check_circle_outline, Colors.green),
                          const Gap(16),
                          ref.watch(storeStatsProvider(eventId)).when(
                            data: (stats) => _buildQuickStat(context, 'Vendas Hoje', stats.todaySalesCount.toString(), Icons.shopping_basket_outlined, Colors.blue),
                            loading: () => _buildQuickStat(context, 'Vendas Hoje', '...', Icons.shopping_basket_outlined, Colors.blue),
                            error: (_, __) => _buildQuickStat(context, 'Vendas Hoje', 'Err', Icons.shopping_basket_outlined, Colors.blue),
                          ),
                          if (!isTablet) ...[
                            const Gap(16),
                            ref.watch(storeStatsProvider(eventId)).when(
                              data: (stats) => _buildQuickStat(context, 'Produtos', stats.productsCount.toString(), Icons.inventory_2_outlined, Colors.purple),
                              loading: () => _buildQuickStat(context, 'Produtos', '...', Icons.inventory_2_outlined, Colors.purple),
                              error: (_, __) => _buildQuickStat(context, 'Produtos', 'Err', Icons.inventory_2_outlined, Colors.purple),
                            ),
                          ],
                        ],
                     ),
                     const Gap(32),
                  ],

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isMobile ? 2.5 : 1.3,
                    children: [
                      _buildMenuCard(
                        context,
                        title: 'Nova Venda (POS)',
                        subtitle: 'Ponto de Venda com leitura de QR Code',
                        icon: Icons.qr_code_scanner,
                        color: Colors.blue,
                        onTap: () => context.push('/store-pos/$eventId'),
                        isMobile: isMobile,
                      ),
                      _buildMenuCard(
                        context,
                        title: 'Histórico de Vendas',
                        subtitle: 'Relatório detalhado de transações',
                        icon: Icons.history,
                        color: Colors.orange,
                        onTap: () => context.push('/store-history/$eventId'),
                        isMobile: isMobile,
                      ),
                      if (isAdmin) ...[
                        _buildMenuCard(
                          context,
                          title: 'Catálogo',
                          subtitle: 'Gerenciar estoque e preços',
                          icon: Icons.inventory_2,
                          color: Colors.purple,
                          onTap: () => context.push('/store-catalog/$eventId'),
                          isMobile: isMobile,
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Configurações',
                          subtitle: 'Mapeamento de colunas e permissões',
                          icon: Icons.settings,
                          color: Colors.teal,
                          onTap: () => context.push('/store-settings/$eventId'),
                          isMobile: isMobile,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const Gap(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isMobile 
            ? Row(
                children: [
                  _buildIconBox(color, icon),
                  const Gap(16),
                  Expanded(child: _buildTextContent(context, title, subtitle)),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIconBox(color, icon),
                  const Gap(20),
                  _buildTextContent(context, title, subtitle, textAlign: TextAlign.center),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildIconBox(Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  Widget _buildTextContent(BuildContext context, String title, String subtitle, {TextAlign textAlign = TextAlign.start}) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.start ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(4),
        Text(
          subtitle,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
