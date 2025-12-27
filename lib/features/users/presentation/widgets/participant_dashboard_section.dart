import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ParticipantDashboardSection extends StatelessWidget {
  const ParticipantDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meu QR Code',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Gap(16),
        Center(
          child: Container(
            width: 200,
            height: 200,
            color: Colors.white,
            child: const Center(
              child: Icon(Icons.qr_code, size: 150),
            ),
          ),
        ),
        const Gap(24),
        Text(
          'Minhas Inscrições',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Gap(16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Você ainda não se inscreveu em nenhum evento.')),
          ),
        ),
        const Gap(24),
        Text(
          'Histórico de Compras',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Gap(16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Nenhuma compra registrada.')),
          ),
        ),
      ],
    );
  }
}
