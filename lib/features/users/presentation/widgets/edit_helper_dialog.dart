import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/models/app_user.dart';
import '../providers/user_providers.dart';
import '../providers/user_di.dart';

class EditHelperDialog extends ConsumerStatefulWidget {
  final AppUser user;

  const EditHelperDialog({super.key, required this.user});

  @override
  ConsumerState<EditHelperDialog> createState() => _EditHelperDialogState();
}

class _EditHelperDialogState extends ConsumerState<EditHelperDialog> {
  late TextEditingController _nameController;
  late UserRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final double width = isMobile ? constraints.maxWidth * 0.95 : 600;

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
                      'Editar Funcionário',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const Gap(24),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMobile) ...[
                          Row(
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
                                  controller: TextEditingController(text: widget.user.email),
                                  prefixIcon: Icons.email,
                                  enabled: false,
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
                            controller: TextEditingController(text: widget.user.email),
                            prefixIcon: Icons.email,
                            enabled: false,
                          ),
                        ],
                        const Gap(24),
                        const Text('Permissões e Nível de Acesso', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Gap(12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<UserRole>(
                              // ignore: deprecated_member_use
                              value: _selectedRole,
                              decoration: const InputDecoration(border: InputBorder.none),
                              items: UserRole.values.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Row(
                                    children: [
                                      Icon(_getRoleIcon(role), size: 18, color: Colors.grey[700]),
                                      const Gap(12),
                                      Text(_getRoleLabel(role)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedRole = value);
                                }
                              },
                            ),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          _getRoleDescription(_selectedRole),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Gap(32),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _isLoading ? null : _confirmDelete,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Excluir'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const Gap(12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Salvar Alterações'),
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

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin: return Icons.admin_panel_settings;
      case UserRole.helper: return Icons.badge;
      case UserRole.participant: return Icons.person;
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Acesso total a todos os eventos e gerenciamento de equipe.';
      case UserRole.helper: return 'Acesso limitado aos eventos designados para check-in e vendas.';
      case UserRole.participant: return 'Acesso apenas aos próprios ingressos e informações.';
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.helper:
        return 'Funcionário';
      case UserRole.participant:
        return 'Participante';
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final updatedUser = widget.user.copyWith(
        name: _nameController.text,
        role: _selectedRole,
      );

      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
         await ref.read(manageHelperUseCaseProvider).updateUser(updatedUser, currentUser.id);
      }
      
      // Refresh the team list
      ref.invalidate(teamMembersProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Funcionário'),
        content: const Text('Tem certeza que deseja excluir este funcionário? Ele perderá o acesso imediatamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteHelper();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHelper() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
          await ref.read(manageHelperUseCaseProvider).deleteUser(widget.user, currentUser.id);
      }
      
      ref.invalidate(teamMembersProvider);

      if (mounted) {
        Navigator.of(context).pop(); // Close edit dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário excluído com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
