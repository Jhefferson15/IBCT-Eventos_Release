import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'package:ibct_eventos/features/events/domain/models/event_model.dart';
import '../../../../core/utils/validators.dart';
import 'package:ibct_eventos/core/widgets/formatters/brazil_phone_formatter.dart';
import '../providers/event_mutation_controller.dart';

class EventEditModal extends ConsumerStatefulWidget {
  final Event event;
  
  const EventEditModal({super.key, required this.event});

  @override
  ConsumerState<EventEditModal> createState() => _EventEditModalState();
}

class _EventEditModalState extends ConsumerState<EventEditModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dateController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  late final TextEditingController _responsibleController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emergencyPhoneController;
  late final TextEditingController _emailController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing event data
    _nameController = TextEditingController(text: widget.event.title);
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.event.date),
    );
    _descController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _responsibleController = TextEditingController(text: widget.event.responsiblePersons);
    _phoneController = TextEditingController(text: widget.event.phoneWhatsApp);
    _emergencyPhoneController = TextEditingController(text: widget.event.emergencyPhone);
    _emailController = TextEditingController(text: widget.event.eventEmail);
  }

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



  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final date = DateFormat('dd/MM/yyyy').parse(_dateController.text);
    
    final updatedEvent = widget.event.copyWith(
      title: _nameController.text,
      date: date,
      description: _descController.text,
      location: _locationController.text,
      responsiblePersons: _responsibleController.text,
      phoneWhatsApp: _phoneController.text,
      emergencyPhone: _emergencyPhoneController.text,
      eventEmail: _emailController.text,
    );

    await ref.read(eventMutationControllerProvider.notifier).updateEvent(updatedEvent);
    final state = ref.read(eventMutationControllerProvider);

    if (state.status == MutationStatus.success) {
      if (mounted) {
        context.pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento atualizado com sucesso!')),
        );
      }
    } else if (state.status == MutationStatus.error) {
       if (mounted) {
         setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar evento: ${state.errorMessage}')),
        );
      }
    } else {
       if (mounted) setState(() => _isSaving = false);
    }
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.event.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final double width = isMobile ? constraints.maxWidth * 0.95 : 750;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
          child: Container(
            width: width,
            constraints: BoxConstraints(maxWidth: width, maxHeight: constraints.maxHeight * 0.9),
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Editar Evento',
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

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
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
                    ),
                  ),
                ),

                const Gap(16),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancelar'),
                    ),
                    const Gap(16),
                    CustomButton(
                      text: 'Salvar Alterações',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? () {} : _saveEvent,
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
}
