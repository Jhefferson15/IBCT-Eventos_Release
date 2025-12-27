import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_theme.dart';
import '../import/presentation/import_controller.dart';
import '../import/presentation/import_state.dart';
import '../import/presentation/widgets/steps/mapping_step.dart';
import '../import/presentation/widgets/steps/preview_step.dart';
import '../import/presentation/widgets/steps/source_step.dart';

class ParticipantImportWidget extends ConsumerStatefulWidget {
  final String eventId;
  final VoidCallback? onFinish;
  final VoidCallback? onCancel;
  final ImportSource? initialSource;

  const ParticipantImportWidget({
    super.key, 
    required this.eventId,
    this.onFinish,
    this.onCancel,
    this.initialSource,
  });

  @override
  ConsumerState<ParticipantImportWidget> createState() => _ParticipantImportWidgetState();
}

class _ParticipantImportWidgetState extends ConsumerState<ParticipantImportWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.initialSource != null) {
      Future.microtask(() {
        ref.read(importControllerProvider(widget.eventId).notifier).setSource(widget.initialSource!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importControllerProvider(widget.eventId));
    final controller = ref.read(importControllerProvider(widget.eventId).notifier);
    
    // Listen for errors and show dialog
    ref.listen(importControllerProvider(widget.eventId).select((s) => s.errorMessage), (prev, next) {
      if (next != null && next.isNotEmpty) {
        _showError(next);
        // Optional: clear error after showing? or let user dismiss. 
        // Better to let user see it. Controller clears it on new actions usually.
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity, 
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                children: [
                   _buildHeader(isMobile, state),
                   const Divider(height: 32),
                   Expanded(
                     child: _buildStepContent(state),
                   ),
                   const Divider(height: 32),
                   _buildFooter(state, controller),
                ],
              ),
            ),
            if (state.isLoading)
              Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      }
    );
  }

  Widget _buildHeader(bool isMobile, ImportState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Importar Participantes',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 20 : 24,
                ),
              ),
              const Gap(4),
              Text(
                _getStepTitle(state.currentStep),
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        if (widget.onCancel != null)
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
          )
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Passo 1: Selecionar Fonte';
      case 1: return 'Passo 2: Mapear Colunas';
      case 2: return 'Passo 3: Revisão';
      default: return '';
    }
  }

  Widget _buildStepContent(ImportState state) {
    switch (state.currentStep) {
      case 0: return ImportSourceStepWidget(eventId: widget.eventId);
      case 1: return ImportMappingStepWidget(eventId: widget.eventId);
      case 2: return ImportPreviewStepWidget(eventId: widget.eventId);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildFooter(ImportState state, ImportController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (state.currentStep == 0)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: widget.onFinish,
              child: const Text('Pular / Concluir', style: TextStyle(color: Colors.grey)),
            ),
          ),
        if (state.currentStep > 0)
          TextButton(
            onPressed: controller.previousStep,
            child: const Text('Voltar'),
          ),
        const Gap(12),
        ElevatedButton(
          onPressed: () => _handleNextStep(state, controller),
          child: Text(state.currentStep == 2 ? 'Confirmar Importação' : 'Próximo'),
        ),
      ],
    );
  }

  void _handleNextStep(ImportState state, ImportController controller) {
    if (state.currentStep == 0) {
      if (state.selectedItems.isEmpty) {
        _showError('Selecione pelo menos um arquivo ou fonte de dados.');
        return;
      }
      controller.processSource(); 
    } else if (state.currentStep == 1) {
      controller.goToPreview();
    } else if (state.currentStep == 2) {
      controller.finalizeImport().then((success) {
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${state.previewParticipants.length} participantes importados com sucesso!'),
              backgroundColor: Colors.green,
            )
          );
          widget.onFinish?.call();
        }
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}

// Note: Google Forms connection logic is still in the step widget but needs access to providers
// We need to implement that properly in import_steps.dart
