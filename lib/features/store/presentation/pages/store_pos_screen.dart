import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/breakpoints.dart';
import '../providers/product_providers.dart';
import '../providers/pos_providers.dart';

class StorePosScreen extends ConsumerWidget {
  final String eventId;

  const StorePosScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Venda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () => ref.read(posCartProvider.notifier).clear(),
            tooltip: 'Limpar Carrinho',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (ResponsiveBreakpoints.isDesktop(constraints.maxWidth)) {
            return _buildDesktopLayout(context, ref);
          }
          return _buildMobileLayout(context, ref);
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posCartProvider);
    return Column(
      children: [
        Expanded(child: _buildProductList(ref)),
        if (cart.items.isNotEmpty) _buildCartSummary(context, cart, eventId),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posCartProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  'Catálogo de Produtos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(child: _buildProductList(ref, isGrid: true)),
            ],
          ),
        ),
        Container(
          width: 450,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(left: BorderSide(color: Colors.grey.shade200, width: 2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, color: Colors.blue),
                    ),
                    const Gap(16),
                    Text(
                      'Carrinho de Venda',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (cart.items.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => ref.read(posCartProvider.notifier).clear(),
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: const Text('Limpar'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: cart.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[300]),
                            const Gap(16),
                            Text('Seu carrinho está vazio', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const Gap(12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.inventory_2_outlined, color: Colors.blue, size: 20),
                              ),
                              title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${item.quantity} x R\$ ${item.product.price.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildQuantityButton(Icons.remove, () => ref.read(posCartProvider.notifier).removeItem(item.product)),
                                  const Gap(12),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const Gap(12),
                                  _buildQuantityButton(Icons.add, () => ref.read(posCartProvider.notifier).addItem(item.product)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              _buildCartSummary(context, cart, eventId, isEmbedded: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildProductList(WidgetRef ref, {bool isGrid = false}) {
    final productsAsync = ref.watch(productsProvider(eventId));
    final cart = ref.watch(posCartProvider);

    return productsAsync.when(
      data: (products) {
        final availableProducts = products.where((p) => p.isAvailable).toList();
        if (availableProducts.isEmpty) {
          return const Center(child: Text('Nenhum produto disponível.'));
        }

        if (isGrid) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: availableProducts.length,
            itemBuilder: (context, index) {
              final product = availableProducts[index];
              final cartItem = cart.items
                  .where((i) => i.product.id == product.id)
                  .firstOrNull;
              final quantity = cartItem?.quantity ?? 0;

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      ref.read(posCartProvider.notifier).addItem(product),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          child: Center(
                            child: Text(
                              product.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'R\$ ${product.price.toStringAsFixed(2)}'),
                                if (quantity > 0)
                                  Badge(
                                    label: Text('$quantity'),
                                    child: const Icon(Icons.shopping_cart),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: availableProducts.length,
          separatorBuilder: (context, index) => const Gap(8),
          itemBuilder: (context, index) {
            final product = availableProducts[index];
            final cartItem = cart.items
                .where((i) => i.product.id == product.id)
                .firstOrNull;
            final quantity = cartItem?.quantity ?? 0;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('R\$ ${product.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (quantity > 0)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          ref
                              .read(posCartProvider.notifier)
                              .removeItem(product);
                        },
                      ),
                    if (quantity > 0)
                      Text(
                        '$quantity',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.blue),
                      onPressed: () {
                        ref.read(posCartProvider.notifier).addItem(product);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erro: $error')),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartState cart, String eventId,
      {bool isEmbedded = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: isEmbedded
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
        borderRadius:
            isEmbedded ? null : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cart.itemCount} itens',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Total: R\$ ${cart.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                ),
              ],
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: cart.items.isEmpty
                  ? null
                  : () {
                      context.push('/store-pay/$eventId');
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('FINALIZAR VENDA'),
            ),
          ],
        ),
      ),
    );
  }
}

