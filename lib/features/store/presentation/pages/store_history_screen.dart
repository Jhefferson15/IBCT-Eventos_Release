import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/content_shell.dart';
import '../providers/store_providers.dart';

class StoreHistoryScreen extends ConsumerWidget {
  final String eventId;

  const StoreHistoryScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(storeTransactionsProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Vendas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ContentShell(
        maxWidth: 1200,
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erro ao carregar histórico: $err')),
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_edu, size: 64, color: Colors.grey),
                    Gap(16),
                    Text('Nenhuma venda registrada.'),
                  ],
                ),
              );
            }

            final totalRevenue = transactions.fold<double>(0, (sum, t) => sum + t.price);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Arrecadado', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
                      Text(
                        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalRevenue),
                        style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                                columns: const [
                                  DataColumn(label: Text('Data/Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Produto', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Comprador', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Valor', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                ],
                                rows: transactions.map((transaction) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(transaction.timestamp))),
                                      DataCell(Text(transaction.productName)),
                                      DataCell(Text(transaction.participantName)),
                                      DataCell(Text(
                                        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(transaction.price),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                            ),
                            title: Text(transaction.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text('Comprador: ${transaction.participantName}'),
                                 Text(
                                   DateFormat('dd/MM/yyyy HH:mm').format(transaction.timestamp),
                                   style: const TextStyle(fontSize: 12),
                                 ),
                              ],
                            ),
                            trailing: Text(
                              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(transaction.price),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
