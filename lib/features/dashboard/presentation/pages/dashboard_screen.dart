import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../users/presentation/providers/user_providers.dart';
import '../../../users/domain/models/app_user.dart';
import '../widgets/admin_dashboard.dart';
import '../widgets/helper_dashboard.dart';
import '../widgets/participant_dashboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch User
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('Usuário não autenticado')));

        switch (user.role) {
          case UserRole.admin:
            return const AdminDashboard();
          case UserRole.helper:
            return const HelperDashboard();
          case UserRole.participant:
            return const ParticipantDashboard();
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro: $err'))),
    );
  }
}

