import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/widgets/content_shell.dart';
import '../controllers/survey_controller.dart';

class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _answers = {};
  
  // Example questions - these could be dynamic in a real app
  final _nameController = TextEditingController();
  final _opinionController = TextEditingController();
  String? _usageFrequency;

  @override
  void dispose() {
    _nameController.dispose();
    _opinionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _answers['name'] = _nameController.text;
      _answers['opinion'] = _opinionController.text;
      _answers['usageFrequency'] = _usageFrequency;

      ref.read(surveyControllerProvider.notifier).submitSurvey(_answers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(surveyControllerProvider);

    ref.listen(surveyControllerProvider, (previous, next) {
      if (next.hasValue && !next.isLoading && !next.hasError) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Obrigado por responder nossa pesquisa!')),
           );
           Navigator.of(context).pop();
        }
      }
      if (next.hasError) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro ao enviar pesquisa: ${next.error}')),
           );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coleta de Informações'),
      ),
      body: SingleChildScrollView(
        child: ContentShell(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajude-nos a melhorar!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Gap(16),
                const Text('Como devemos te chamar?'),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Seu nome',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório' : null,
                ),
                const Gap(16),
                const Text('Qual sua frequência de uso do app?'),
                DropdownButtonFormField<String>(
                  initialValue: _usageFrequency,
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Diariamente')),
                    DropdownMenuItem(value: 'weekly', child: Text('Semanalmente')),
                    DropdownMenuItem(value: 'monthly', child: Text('Mensalmente')),
                    DropdownMenuItem(value: 'rarely', child: Text('Raramente')),
                  ],
                  onChanged: (value) => _usageFrequency = value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null ? 'Selecione uma opção' : null,
                ),
                const Gap(16),
                const Text('O que você acha do app? (Opcional)'),
                TextFormField(
                  controller: _opinionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Sua opinião...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Gap(24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: state.isLoading ? null : _submit,
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Enviar Respostas'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
