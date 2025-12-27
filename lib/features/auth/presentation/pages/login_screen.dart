import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_theme.dart';
// import '../../../../core/widgets/custom_button.dart';
import '../providers/login_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // bool _isLoading = false; // Moved to Controller State

  @override
  Widget build(BuildContext context) {
    // Listen to Controller State for Side Effects (Navigation, Errors)
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.status == LoginUIStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro: ${next.errorMessage}')),
        );
      } else if (next.status == LoginUIStatus.success) {
         context.go('/dashboard');
      } else if (next.status == LoginUIStatus.firstLogin) {
         context.go('/change-password');
      }
    });

    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.status == LoginUIStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.secondaryRed,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          if (isDesktop) {
            return Row(
              children: [
                // Left Side: Branding
                Expanded(
                  child: Container(
                    color: AppTheme.secondaryRed,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.church_rounded,
                            size: 120,
                            color: AppTheme.primaryRed,
                          ).animate().scale(delay: 200.ms),
                          const Gap(24),
                          Text(
                            'IBCT Eventos',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.bold,
                                ),
                          ).animate().fadeIn().moveY(begin: 10, end: 0),
                          const Gap(16),
                          Text(
                            'Gestão de Eventos',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.textLight,
                                ),
                          ).animate().fadeIn(delay: 100.ms),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right Side: Form
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 450),
                              child: _buildLoginForm(context, isLoading),
                            ),
                            const Gap(48),
                            Text(
                              '© 2025 Igreja Batista Central de Taguatinga',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile Layout
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const Icon(
                    Icons.church_rounded,
                    size: 80,
                    color: AppTheme.primaryRed,
                  ).animate().scale(delay: 200.ms),
                  const Gap(16),
                  Text(
                    'IBCT Eventos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn().moveY(begin: 10, end: 0),
                  const Gap(8),
                  Text(
                    'Gestão de Eventos',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ).animate().fadeIn(delay: 100.ms),

                  const Gap(48),

                  // Login Options Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildLoginForm(context, isLoading),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),

                  const Gap(48),
                  Text(
                    '© 2025 Igreja Batista Central de Taguatinga',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bem-vindo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Gap(32),

            // Google Login Button
            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      ref.read(loginControllerProvider.notifier).signInWithGoogle();
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const FaIcon(FontAwesomeIcons.google, size: 20),
              label: Text(isLoading ? 'Buscando conta...' : 'Entrar com Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const Gap(24),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OU',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const Gap(24),

            // Email Login Button
            OutlinedButton.icon(
              onPressed: isLoading ? null : () => _showEmailLoginDialog(context),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Entrar com E-mail'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailLoginDialog(BuildContext dialogContext) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isObscured = true;

    showDialog(
      context: dialogContext,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbContext, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.email_outlined, color: AppTheme.primaryRed),
                      ),
                      const Gap(16),
                      Text(
                        'Entrar com E-mail',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Gap(32),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'exemplo@ibct.org.br',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Informe seu e-mail' : null,
                  ),
                  const Gap(20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: isObscured,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => isObscured = !isObscured),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Informe sua senha' : null,
                  ),
                  const Gap(32),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.pop(dialogCtx);
                        ref.read(loginControllerProvider.notifier).signInWithEmail(
                              emailController.text.trim(),
                              passwordController.text,
                            );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ENTRAR NA CONTA',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                  ),
                  const Gap(16),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(
                      'CANCELAR',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

