import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'package:ibct_eventos/features/events/domain/models/event_model.dart';
import 'package:ibct_eventos/features/users/presentation/providers/user_providers.dart';
import 'package:ibct_eventos/features/shared/widgets/participant_import_widget.dart';
import '../../../../core/utils/validators.dart';
import 'package:ibct_eventos/core/widgets/formatters/brazil_phone_formatter.dart';
import '../providers/event_mutation_controller.dart';

class EventCreationModal extends ConsumerStatefulWidget {
  const EventCreationModal({super.key});

  @override
  ConsumerState<EventCreationModal> createState() => _EventCreationModalState();
}

class _EventCreationModalState extends ConsumerState<EventCreationModal> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Mock file state for Step 2 (if relevant for MVP)
  // New state for created event ID
  String? _createdEventId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _responsibleController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        _createEventAndAdvance();
      }
    } else {
      // Step 2 finish is handled by the widget or manual close
      context.pop();
    }
  }



  Future<void> _createEventAndAdvance() async {
    setState(() => _isSaving = true);
    
    final date = DateFormat('dd/MM/yyyy').parse(_dateController.text);
    final currentUser = ref.read(currentUserProvider).value;
    
    final newEvent = Event(
      title: _nameController.text,
      date: date,
      description: _descController.text,
      participantCount: 0, 
      location: _locationController.text,
      responsiblePersons: _responsibleController.text,
      phoneWhatsApp: _phoneController.text,
      emergencyPhone: _emergencyPhoneController.text,
      eventEmail: _emailController.text,
      creatorId: currentUser?.id,
    );

    await ref.read(eventMutationControllerProvider.notifier).createEvent(newEvent);
    
    final state = ref.read(eventMutationControllerProvider);
    
    if (state.status == MutationStatus.success) {
      if (mounted) {
        setState(() {
          _createdEventId = state.resultId;
          _currentStep = 1;
          _isSaving = false;
        });
      }
    } else if (state.status == MutationStatus.error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar evento: ${state.errorMessage}')),
        );
      }
    } else {
        setState(() => _isSaving = false);
    }
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // File picking logic removed as it's now in the shared widget

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
          child: Container(
            width: 800, // Increased width for import step
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (only show if step 0, as ImportWidget has its own header)
                if (_currentStep == 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Novo Evento',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Gap(16),
                ],

                // Content
                Expanded(
                  child: _currentStep == 0 ? SingleChildScrollView(child: _buildStep1(isMobile)) : _buildStep2(),
                ),

                const Gap(16),
                
                // Actions (Only for Step 1, Step 2 handles its own actions)
                if (_currentStep == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomButton(
                        text: 'Próximo',
                        isLoading: _isSaving,
                        onPressed: _isSaving ? () {} : _nextStep,
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

  Widget _buildStep1(bool isMobile) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          if (!isMobile) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'Nome do Evento',
                    controller: _nameController,
                    prefixIcon: Icons.event,
                    validator: (v) => Validators.validateName(v),
                  ),
                ),
                const Gap(16),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: IgnorePointer(
                      child: CustomTextField(
                        label: 'Data',
                        controller: _dateController,
                        prefixIcon: Icons.calendar_month,
                        validator: (v) => Validators.validateRequired(v, fieldName: 'Data'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Local',
                    controller: _locationController,
                    prefixIcon: Icons.location_on,
                    validator: (v) => Validators.validateRequired(v, fieldName: 'Local'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: CustomTextField(
                    label: 'Responsáveis',
                    controller: _responsibleController,
                    prefixIcon: Icons.person,
                    validator: (v) => Validators.validateRequired(v, fieldName: 'Responsáveis'),
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Telefone/WhatsApp',
                    controller: _phoneController,
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      BrazilPhoneFormatter(),
                    ],
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: CustomTextField(
                    label: 'Telefone de Emergência (Opcional)',
                    controller: _emergencyPhoneController,
                    prefixIcon: Icons.emergency,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v != null && v.isNotEmpty ? Validators.validatePhone(v) : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      BrazilPhoneFormatter(),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Email do Evento (Opcional)',
                    controller: _emailController,
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                ),
                const Gap(16),
                const Spacer(),
              ],
            ),
          ] else ...[
            CustomTextField(
              label: 'Nome do Evento',
              controller: _nameController,
              prefixIcon: Icons.event,
              validator: (v) => Validators.validateName(v),
            ),
            const Gap(16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: IgnorePointer(
                child: CustomTextField(
                  label: 'Data',
                  controller: _dateController,
                  prefixIcon: Icons.calendar_month,
                  validator: (v) => Validators.validateRequired(v, fieldName: 'Data'),
                ),
              ),
            ),
            const Gap(16),
            CustomTextField(
              label: 'Local',
              controller: _locationController,
              prefixIcon: Icons.location_on,
              validator: (v) => Validators.validateRequired(v, fieldName: 'Local'),
            ),
            const Gap(16),
            CustomTextField(
              label: 'Responsáveis',
              controller: _responsibleController,
              prefixIcon: Icons.person,
              validator: (v) => Validators.validateRequired(v, fieldName: 'Responsáveis'),
            ),
            const Gap(16),
            CustomTextField(
              label: 'Telefone/WhatsApp',
              controller: _phoneController,
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone, 
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                BrazilPhoneFormatter(),
              ],
            ),
            const Gap(16),
            CustomTextField(
              label: 'Telefone de Emergência (Opcional)',
              controller: _emergencyPhoneController,
              prefixIcon: Icons.emergency,
              keyboardType: TextInputType.phone,
              validator: (v) => v != null && v.isNotEmpty ? Validators.validatePhone(v) : null,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                BrazilPhoneFormatter(),
              ],
            ),
            const Gap(16),
            CustomTextField(
              label: 'Email do Evento (Opcional)',
              controller: _emailController,
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
          ],
          const Gap(16),
          CustomTextField(
            label: 'Descrição (Opcional)',
            controller: _descController,
            prefixIcon: Icons.text_fields,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    if (_createdEventId == null) return const Center(child: Text('Erro: Evento não criado.'));
    
    return ParticipantImportWidget(
      eventId: _createdEventId!,
      onFinish: () => context.pop(),
      onCancel: () => context.pop(),
    );
  }
}

