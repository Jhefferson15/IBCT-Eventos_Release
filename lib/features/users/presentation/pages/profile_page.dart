import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/content_shell.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feedback/presentation/widgets/feedback_dialog.dart';
import '../../domain/models/app_user.dart';
import '../providers/user_providers.dart';
import '../widgets/admin_dashboard_section.dart';
import '../widgets/helper_dashboard_section.dart';
import '../widgets/participant_dashboard_section.dart';
import '../../domain/models/activity_log.dart';
import '../providers/activity_log_provider.dart';
import '../../../../core/services/update_service.dart';
import 'package:ota_update/ota_update.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Conta'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }
          return ContentShell(
            maxWidth: 1100,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: isMobile 
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildUserInfo(user, context),
                            const Gap(32),
                            _buildActionButtons(context, ref),
                            const Gap(32),
                            const Divider(),
                            const Gap(24),
                            _buildDashboardByRole(user),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildUserInfo(user, context, isMobile: false),
                                  const Gap(32),
                                  _buildActionButtons(context, ref, isMobile: false),
                                ],
                              ),
                            ),
                            const Gap(48),
                            const VerticalDivider(width: 1),
                            const Gap(48),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Acessos e Dashboards',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Gap(24),
                                  _buildDashboardByRole(user),
                                ],
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, {bool isMobile = true}) {
    return Column(
      children: [
        _buildActionButton(
          context,
          label: 'Enviar Feedback / Reportar Erro',
          icon: Icons.feedback_outlined,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const FeedbackDialog(),
            );
          },
        ),
        const Gap(16),
        _buildActionButton(
          context,
          label: 'Alterar Minha Senha',
          icon: Icons.lock_reset,
          onPressed: () => context.push('/change-password'),
        ),
        const Gap(16),
        _buildActionButton(
          context,
          label: 'Buscar Atualização',
          icon: Icons.system_update,
          onPressed: () => _checkForUpdate(context, ref),
        ),
        const Gap(16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Sair da Conta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              padding: const EdgeInsets.all(16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = ref.read(currentUserProvider).value;
      
      if (user != null) {
          try {
            await ref.read(logActivityUseCaseProvider).call(
              userId: user.id,
              actionType: ActivityActionType.logout,
              targetId: user.id,
              targetType: 'user',
              details: {},
            );
          } catch (_) {}
      }

      await authRepo.signOut();
      
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
        if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: $e')),
        );
      }
    }
  }

  Widget _buildUserInfo(AppUser user, BuildContext context, {bool isMobile = true}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 3),
          ),
          child: CircleAvatar(
            radius: isMobile ? 40 : 60,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: isMobile ? 32 : 48,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Gap(24),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const Gap(16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getRoleLabel(user.role).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildDashboardByRole(AppUser user) {
    switch (user.role) {
      case UserRole.admin:
        return const AdminDashboardSection();
      case UserRole.helper:
        return const HelperDashboardSection();
      case UserRole.participant:
        return const ParticipantDashboardSection();
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

  Future<void> _checkForUpdate(BuildContext context, WidgetRef ref) async {
    final updateService = ref.read(updateServiceProvider);
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verificando atualizações...')),
    );

    try {
      final updateInfo = await updateService.checkForUpdate();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (updateInfo != null) {
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent closing while downloading if we reused this
          builder: (ctx) => AlertDialog(
            title: const Text('Nova Atualização Disponível'),
            content: Text(
              'Versão ${updateInfo.latestVersion} está disponível.\nDeseja baixar e instalar agora? (Download em background)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _startBackgroundDownload(context, ref, updateInfo.downloadUrl);
                },
                child: const Text('Atualizar Agora'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O aplicativo já está atualizado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao verificar: $e')),
        );
      }
    }
  }

  void _startBackgroundDownload(BuildContext context, WidgetRef ref, String url) {
    final updateService = ref.read(updateServiceProvider);

    // Show a non-dismissible dialog to track progress (optional) OR 
    // just a toast saying "Downloading in background..."
    // Since user requested "background download", we can just notify.
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Iniciando download em segundo plano... A instalação abrirá automaticamente.'),
        duration: Duration(seconds: 4),
      ),
    );

    updateService.downloadAndInstall(url).listen(
      (OtaEvent event) {
        // Can be used to show a progress notification or update UI if we had a persistent state
        if (event.status == OtaStatus.DOWNLOADING) {
           // Debug: print('Downloading ${event.value}%');
        } else if (event.status == OtaStatus.INSTALLING) {
           // Debug: print('Installing...');
        }
      },
      onError: (e) {
        // ignore: avoid_print
        print('Download error: $e');
        // In a real app we might want to show a notification of failure
      },
    );
  }
}
