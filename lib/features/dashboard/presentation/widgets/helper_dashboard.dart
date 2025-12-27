
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../users/presentation/widgets/helper_dashboard_section.dart';

class HelperDashboard extends StatelessWidget {
  const HelperDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Funcionário'),
        actions: [
           IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: HelperDashboardSection(),
      ),
    );
  }
}
