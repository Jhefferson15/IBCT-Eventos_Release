import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/feedback_controller.dart';
import 'package:gap/gap.dart';

class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({super.key});

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  final _messageController = TextEditingController();
  String _selectedType = 'general';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(feedbackControllerProvider.notifier).submitFeedback(
            message: _messageController.text,
            type: _selectedType,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedbackControllerProvider);

    ref.listen(feedbackControllerProvider, (previous, next) {
      if (next.hasValue && !next.isLoading && !next.hasError) {
         if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feedback enviado com sucesso!'), backgroundColor: Colors.green),
            );
         }
      }
      if (next.hasError) {
         if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao enviar feedback: ${next.error}'), backgroundColor: Colors.red),
            );
         }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final double dialogWidth = isMobile ? constraints.maxWidth * 0.95 : 750;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Feedback e Sugestões',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Gap(8),
                Text(
                  'Sua opinião nos ajuda a melhorar a experiência de todos.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const Gap(24),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('O que você quer nos dizer?', style: TextStyle(fontWeight: FontWeight.bold)),
                                const Gap(12),
                                DropdownButtonFormField<String>(
                                  // ignore: deprecated_member_use
                                  value: _selectedType,
                                  items: const [
                                    DropdownMenuItem(value: 'general', child: Text('Elogio ou Comentário Geral')),
                                    DropdownMenuItem(value: 'bug', child: Text('Encontrei um Erro / Falha')),
                                    DropdownMenuItem(value: 'suggestion', child: Text('Tenho uma Sugestão')),
                                  ],
                                  onChanged: (value) => setState(() => _selectedType = value!),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                const Gap(20),
                                const Text('Mensagem detalhada', style: TextStyle(fontWeight: FontWeight.bold)),
                                const Gap(12),
                                TextFormField(
                                  controller: _messageController,
                                  maxLines: 6,
                                  decoration: InputDecoration(
                                    hintText: 'Descreva sua experiência ou relate o problema com detalhes...',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Por favor, digite uma mensagem.' : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isMobile) ...[
                          const Gap(24),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.orange.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lightbulb_outline, color: Colors.orange.shade800, size: 32),
                                  const Gap(16),
                                  Text(
                                    'Dicas para um bom feedback:',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                  ),
                                  const Gap(12),
                                  _buildTip('Seja específico sobre qual tela ou botão apresentou problema.'),
                                  _buildTip('Se for um erro, descreva o que você estava tentando fazer.'),
                                  _buildTip('Sugestões de novas funcionalidades são sempre bem-vindas!'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const Gap(24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const Gap(16),
                    FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Enviar Feedback'),
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

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.orange.shade900))),
        ],
      ),
    );
  }
}
