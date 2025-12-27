import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/participant_import_widget.dart';
import '../../../shared/import/presentation/import_state.dart' show ImportSource;

import '../../../shared/import/presentation/import_controller.dart';

class ParticipantImportModal extends ConsumerWidget {
  final String eventId;
  final ImportSource? initialSource;
  
  const ParticipantImportModal({
    super.key, 
    required this.eventId,
    this.initialSource,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch state to trigger animation on step change
    final state = ref.watch(importControllerProvider(eventId));
    final isExpandedStep = state.currentStep == 1; // Mapping step
    final screenSize = MediaQuery.sizeOf(context);

    // Calculate target sizes with safety margins
    final double targetWidth = isExpandedStep 
        ? (screenSize.width - 32).clamp(0, screenSize.width * 0.95)
        : 800;
    
    final double targetHeight = isExpandedStep
        ? (screenSize.height - 32).clamp(0, screenSize.height * 0.90)
        : 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
      clipBehavior: Clip.antiAlias, // Ensure content is clipped during transition
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubicEmphasized,
        width: targetWidth,
        height: targetHeight,
        constraints: BoxConstraints(
          maxWidth: screenSize.width,
          maxHeight: screenSize.height,
        ),
        child: ParticipantImportWidget(
          eventId: eventId,
          initialSource: initialSource,
          onFinish: () => Navigator.of(context).pop(),
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
