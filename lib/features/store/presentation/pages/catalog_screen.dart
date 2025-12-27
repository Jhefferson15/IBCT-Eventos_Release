import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/widgets/content_shell.dart';
import '../../domain/models/product.dart';
import '../providers/product_providers.dart';
import 'product_editor_screen.dart';

class CatalogScreen extends ConsumerWidget {
  final String eventId;

  const CatalogScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Produtos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductEditorScreen(eventId: eventId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ContentShell(
        maxWidth: 1200,
        child: productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return const Center(child: Text('Nenhum produto cadastrado.'));
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  // Desktop / Tablet Grid
                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildPremiumProductCard(context, ref, product);
                    },
                  );
                }

                // Mobile List
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (context, index) => const Gap(12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildMobileProductCard(context, ref, product);
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erro: $error')),
        ),
      ),
    );
  }

  Widget _buildPremiumProductCard(BuildContext context, WidgetRef ref, Product product) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.03),
                  child: Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.isAvailable ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.isAvailable ? 'ATIVO' : 'INATIVO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: product.isAvailable ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Text(
                  product.category.toUpperCase(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'R\$ ${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).primaryColor,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        _buildSmallIconButton(
                          Icons.edit_outlined, 
                          Colors.blue, 
                          () => _navigateToEditor(context, product)
                        ),
                        const Gap(8),
                        _buildSmallIconButton(
                          Icons.delete_outline, 
                          Colors.red, 
                          () => _confirmDelete(context, ref, product)
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            dense: true,
            title: const Text('Disponibilidade', style: TextStyle(fontSize: 12)),
            value: product.isAvailable,
            activeTrackColor: Colors.green,
            onChanged: (value) {
              ref.read(productControllerProvider.notifier).updateProduct(
                    product.copyWith(isAvailable: value),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProductCard(BuildContext context, WidgetRef ref, Product product) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.shopping_bag_outlined, color: Theme.of(context).primaryColor, size: 24),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'R\$ ${product.price.toStringAsFixed(2)}',
            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: product.isAvailable,
              activeTrackColor: Colors.green,
              onChanged: (value) {
                ref.read(productControllerProvider.notifier).updateProduct(
                      product.copyWith(isAvailable: value),
                    );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.grey),
              onPressed: () => _navigateToEditor(context, product),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _navigateToEditor(BuildContext context, Product? product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductEditorScreen(
          eventId: eventId,
          product: product,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Tem certeza que deseja excluir "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(productControllerProvider.notifier).deleteProduct(product.id);
              Navigator.of(context).pop();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
