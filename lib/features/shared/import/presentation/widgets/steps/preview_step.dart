
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../import_controller.dart';

// =============================================================================
// STEP 3: PREVIEW
// =============================================================================

class ImportPreviewStepWidget extends ConsumerWidget {
  final String eventId;

  const ImportPreviewStepWidget({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importControllerProvider(eventId));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total encontrado: ${state.previewParticipants.length} participantes'),
        const Gap(16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
            child: ListView.builder(
              itemCount: state.previewParticipants.length,
              itemBuilder: (ctx, index) {
                final p = state.previewParticipants[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(p.name.isNotEmpty ? p.name : 'Sem Nome'),
                  subtitle: Text('${p.email} • ${p.phone}'),
                  trailing: Chip(label: Text(p.ticketType)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
