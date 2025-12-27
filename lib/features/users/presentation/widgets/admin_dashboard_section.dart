import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../features/events/presentation/providers/event_providers.dart';
import '../../domain/models/app_user.dart';
import '../providers/user_providers.dart';
import '../providers/activity_log_provider.dart';
import '../../domain/models/activity_log.dart';
import 'activity_log_list.dart';

import 'edit_helper_dialog.dart';
import '../providers/user_di.dart';

class AdminDashboardSection extends ConsumerWidget {
  const AdminDashboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    
    final eventsAsync = ref.watch(eventsProvider);
    final myEvents = eventsAsync.whenData((events) {
      return events.where((e) => e.creatorId == currentUser?.id).toList();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gerenciamento',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Gap(16),
        _buildSectionHeader(context, 'Meus Eventos', Icons.event),
        const Gap(8),
        myEvents.when(
            data: (events) {
              if (events.isEmpty) {
                return _buildEmptyState('Nenhum evento criado.');
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_note),
                      title: Text(event.title),
                      subtitle: Text('${event.date.day}/${event.date.month}/${event.date.year}'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erro: $err')),
          ),
        const Gap(24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context, 'Minha Equipe', Icons.people),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Novo Funcionário'),
              onPressed: () => _showAddHelperDialog(context, ref),
            ),
          ],
        ),
        const Gap(8),
        _buildHelperList(ref),
        const Gap(24),
        _buildSectionHeader(context, 'Registro de Atividades', Icons.history),
        const Gap(8),
        const ActivityLogList(shrinkWrap: true),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const Gap(8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildHelperList(WidgetRef ref) {
    final teamAsync = ref.watch(teamMembersProvider);

    return teamAsync.when(
        data: (helpers) {
          if (helpers.isEmpty) {
            return _buildEmptyState('Nenhum funcionário cadastrado.');
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: helpers.length,
            itemBuilder: (context, index) {
              final helper = helpers[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Text(helper.name[0].toUpperCase()),
                  ),
                  title: Text(helper.name),
                  subtitle: Text(helper.email),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => EditHelperDialog(user: helper),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro ao carregar equipe: $err')),
      );
  }

  void _showAddHelperDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _AddHelperDialog(),
    );
  }
}

class _AddHelperDialog extends ConsumerStatefulWidget {
  const _AddHelperDialog();

  @override
  ConsumerState<_AddHelperDialog> createState() => _AddHelperDialogState();
}

class _AddHelperDialogState extends ConsumerState<_AddHelperDialog> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _generatedPassword;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final double width = isMobile ? constraints.maxWidth * 0.95 : 650;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: width,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _generatedPassword == null ? 'Novo Funcionário' : 'Cadastro Concluído',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const Gap(24),
                
                if (_generatedPassword == null) ...[
                  if (!isMobile) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Nome Completo',
                            controller: _nameController,
                            prefixIcon: Icons.person,
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: CustomTextField(
                            label: 'Email',
                            controller: _emailController,
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    CustomTextField(
                      label: 'Nome Completo',
                      controller: _nameController,
                      prefixIcon: Icons.person,
                    ),
                    const Gap(16),
                    CustomTextField(
                      label: 'Email',
                      controller: _emailController,
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const Gap(16),
                        const Expanded(
                          child: Text(
                            'Uma senha temporária será gerada automaticamente e exibida na próxima tela.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 64),
                        const Gap(16),
                        const Text(
                          'Funcionário cadastrado com sucesso!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const Gap(24),
                        const Text('SENHA TEMPORÁRIA:'),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: SelectableText(
                            _generatedPassword!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              letterSpacing: 2,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const Gap(16),
                        const Icon(Icons.copy, size: 16, color: Colors.grey),
                        const Gap(16),
                        const Text(
                          'Copie e envie esta senha para o funcionário. Por segurança, ela não será exibida novamente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const Gap(32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_generatedPassword == null) ...[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const Gap(16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createHelper,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Confirmar Cadastro'),
                      ),
                    ] else
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Entendido'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _createHelper() async {
    setState(() => _isLoading = true);
    
    // Generate random password
    final tempPassword = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    
    try {
       // 1. Create Auth User
       final uid = await ref.read(authRepositoryProvider).createSecondaryUser(_emailController.text, tempPassword);

       // 2. Create Firestore User
       final currentUser = ref.read(currentUserProvider).value;
        if (currentUser != null) {
            final newUser = AppUser(
                id: uid, 
                email: _emailController.text, 
                name: _nameController.text, 
                role: UserRole.helper,
                createdBy: currentUser.id,
                isFirstLogin: true,
                createdAt: DateTime.now(),
            );
            await ref.read(userRepositoryProvider).createUser(newUser);
            
            // Refresh the team list
            ref.invalidate(teamMembersProvider);
    
            // Log Activity
            try {
              final admin = ref.read(currentUserProvider).value;
              if (admin != null) {
                await ref.read(logActivityUseCaseProvider).call(
                  userId: admin.id,
                  actionType: ActivityActionType.addHelper,
                  targetId: newUser.id,
                  targetType: 'user',
                  details: {'email': newUser.email, 'name': newUser.name},
                );
              }
            } catch (e) {
              debugPrint('Error logging helper creation: $e');
            }
        }
    
        if (mounted) {
          setState(() {
            _generatedPassword = tempPassword;
          });
        }

    } catch (e) {
      if (mounted) {
        final message = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar funcionário: $message'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
