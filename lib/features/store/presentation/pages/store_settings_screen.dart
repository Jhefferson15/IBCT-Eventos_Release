import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../../../core/widgets/content_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/domain/models/event_model.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  final String eventId;

  const StoreSettingsScreen({super.key, required this.eventId});

  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  String? _selectedProductColumn;
  String? _selectedPriceColumn;
  bool _isLoading = false;
  bool _isInit = true;

  @override
  @override
  Widget build(BuildContext context) {
    // Using singleEventProvider to listen to real-time updates
    final eventAsync = ref.watch(singleEventProvider(widget.eventId));

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        title: const Text('Configurações da Loja'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ContentShell(
        maxWidth: 1200,
        child: eventAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erro: $err')),
          data: (event) {
            if (event == null) return const Center(child: Text('Evento não encontrado.'));

            // Initialize state
            if (_isInit) {
              final settings = event.storeSettings ?? {};
              _selectedProductColumn = settings['productColumn'];
              _selectedPriceColumn = settings['priceColumn'];
              
              if (_selectedProductColumn != null && !event.customColumns.contains(_selectedProductColumn)) {
                _selectedProductColumn = null;
              }
              if (_selectedPriceColumn != null && !event.customColumns.contains(_selectedPriceColumn)) {
                _selectedPriceColumn = null;
              }
              _isInit = false;
            }

            if (event.customColumns.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                      const Gap(16),
                      Text(
                        'Sem colunas personalizadas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Gap(8),
                      const Text(
                        'Este evento não possui colunas personalizadas. Adicione colunas na importação ou gerenciamento de colunas para configurar a loja.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;

                if (isDesktop) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Configuration
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mapeamento de Colunas',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Gap(8),
                              Text(
                                'Associe as colunas do seu evento aos campos da loja.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                              ),
                              const Gap(24),
                              _buildFormCard(context, event),
                              const Gap(32),
                              _buildSaveButton(event),
                            ],
                          ),
                        ),
                        const Gap(32),
                        // Right Column: Info/Help
                        Expanded(
                          flex: 2,
                          child: _buildInfoCard(context),
                        ),
                      ],
                    ),
                  );
                }

                // Mobile Layout
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(context),
                      const Gap(24),
                      Text(
                        'Mapeamento de Colunas',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Gap(8),
                      Text(
                        'Associe as colunas do seu evento aos campos da loja.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      const Gap(24),
                      _buildFormCard(context, event),
                      const Gap(32),
                      _buildSaveButton(event),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, Event event) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDropdown(
              context,
              label: 'Indicador de Produto',
              description: 'Coluna que contém o nome ou descrição do item.',
              value: _selectedProductColumn,
              items: event.customColumns,
              onChanged: (val) {
                setState(() {
                  _selectedProductColumn = val;
                });
              },
              hint: 'Selecione uma coluna',
              icon: Icons.shopping_bag_outlined,
            ),
            const Divider(height: 32),
            _buildDropdown(
              context,
              label: 'Indicador de Preço',
              description: 'Coluna que contém o valor monetário do item.',
              value: _selectedPriceColumn,
              items: event.customColumns,
              onChanged: (val) {
                setState(() {
                  _selectedPriceColumn = val;
                });
              },
              hint: 'Selecione uma coluna',
              icon: Icons.attach_money,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(Event event) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading 
          ? null 
          : () => _saveSettings(event),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Salvar Configurações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editor de Loja',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    fontSize: 16,
                  ),
                ),
                const Gap(4),
                Text(
                  'Configure como os dados dos participantes serão interpretados como itens de venda. Isso permitirá gerar relatórios de vendas e pedidos.',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String description,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const Gap(8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const Gap(4),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const Gap(12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_circle_outlined),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings(Event event) async {
    // Only block if both are empty? Or require at least one? The prompt said "informar o indicador de produto e o preço" so implying both.
    if (_selectedProductColumn == null || _selectedPriceColumn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione ambas as colunas para configurar a loja.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedSettings = {
        'productColumn': _selectedProductColumn!,
        'priceColumn': _selectedPriceColumn!,
      };

      final updatedEvent = event.copyWith(
        storeSettings: updatedSettings,
      );

      await ref.read(eventRepositoryProvider).updateItem(updatedEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações da loja salvas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Do not pop, let user stay or go back manually
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
