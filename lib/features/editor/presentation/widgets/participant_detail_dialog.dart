import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/models/participant_model.dart';
import '../providers/participant_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../users/presentation/providers/user_providers.dart';
import 'participant_info_tab.dart';
import 'participant_qr_card.dart';

class ParticipantDetailDialog extends ConsumerStatefulWidget {
  final Participant? participant;
  final String? eventId;

  const ParticipantDetailDialog({
    super.key, 
    this.participant,
    this.eventId,
  });

  @override
  ConsumerState<ParticipantDetailDialog> createState() => _ParticipantDetailDialogState();
}

class _ParticipantDetailDialogState extends ConsumerState<ParticipantDetailDialog> {
  late bool _isEditing;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _idController;
  // New standard fields
  late TextEditingController _companyController;
  late TextEditingController _roleController;
  late TextEditingController _cpfController;

  String? _token;
  bool _isLoading = false;

  // Custom Fields State
  final Map<String, TextEditingController> _customFieldControllers = {};

  @override
  void initState() {
    super.initState();
    // If no participant provided, we are creating a new one, so start in edit mode
    _isEditing = widget.participant == null;
    
    _nameController = TextEditingController(text: widget.participant?.name ?? '');
    _emailController = TextEditingController(text: widget.participant?.email ?? '');
    _phoneController = TextEditingController(text: widget.participant?.phone ?? '');
    _idController = TextEditingController(text: widget.participant?.id ?? '');
    
    _companyController = TextEditingController(text: widget.participant?.company ?? '');
    _roleController = TextEditingController(text: widget.participant?.role ?? '');
    _cpfController = TextEditingController(text: widget.participant?.cpf ?? '');
    
    // Initialize custom field controllers from existing participant data
    widget.participant?.customFields.forEach((key, value) {
      _customFieldControllers[key] = TextEditingController(text: value.toString());
    });
    
    // Use existing token or generate a new one if creating
    _token = widget.participant?.token;
    if (_token == null || _token!.isEmpty) {
      _token = const Uuid().v4();
    }

    // Load available columns from the Event to ensure we show all fields
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEventColumns());
  }

  Future<void> _loadEventColumns() async {
    final eventId = widget.participant?.eventId ?? widget.eventId;
    if (eventId == null) return;

    try {
      final Event? event = await ref.read(singleEventProvider(eventId).future);
      if (event != null) {
        setState(() {
          for (final column in event.customColumns) {
            if (!_customFieldControllers.containsKey(column)) {
              _customFieldControllers[column] = TextEditingController();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading event columns: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _companyController.dispose();
    _roleController.dispose();
    _cpfController.dispose();
    // Dispose custom field controllers
    _customFieldControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
  
  void _addCustomField() {
    // Show dialog to enter field name
    final fieldNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Coluna'),
        content: TextField(
          controller: fieldNameController,
          decoration: const InputDecoration(labelText: 'Nome da Coluna'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final key = fieldNameController.text.trim();
              if (key.isNotEmpty) {
                 setState(() {
                   _customFieldControllers[key] = TextEditingController();
                 });
                 Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _removeCustomField(String key) {
    setState(() {
      _customFieldControllers[key]?.dispose();
      _customFieldControllers.remove(key);
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveParticipant() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e Email são obrigatórios')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(participantsControllerProvider(widget.participant?.eventId ?? widget.eventId ?? '').notifier);
      final currentUser = ref.read(currentUserProvider).value;
      
      // Collect custom fields
      final Map<String, dynamic> customFields = {};
      _customFieldControllers.forEach((key, controller) {
        customFields[key] = controller.text;
      });
      
      final participant = Participant(
        id: widget.participant?.id ?? '', 
        eventId: widget.participant?.eventId ?? widget.eventId ?? '',
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        ticketType: widget.participant?.ticketType ?? 'Standard',
        status: widget.participant?.status ?? 'Pendente',
        token: _token!,
        isCheckedIn: widget.participant?.isCheckedIn ?? false,
        checkInTime: widget.participant?.checkInTime,
        customFields: customFields,
        company: _companyController.text,
        role: _roleController.text,
        cpf: _cpfController.text,
      );

      if (widget.participant == null) {
        // Create
        if (currentUser != null) {
           await controller.addParticipant(participant, currentUser.id);
        } else {
           throw Exception("Usuário não logado");
        }

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Participante criado com sucesso!'), backgroundColor: Colors.green),
          );
        }
      } else {
        // Update
        if (currentUser != null) {
           await controller.updateParticipant(participant, currentUser.id);
        }

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Participante atualizado com sucesso!'), backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // QR Data
    final qrData = _token ?? '';
    final userStatus = widget.participant?.status ?? 'Pendente';
    final checkInText = widget.participant?.checkInTime != null 
        ? widget.participant!.checkInTime.toString() 
        : 'Pendente';

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        // Breakpoints
        final bool isMobile = screenWidth < 700;
        final bool isTablet = screenWidth >= 700 && screenWidth < 1100;
        // final bool isDesktop = screenWidth >= 1100; // Unused

        // Dialog Dimensions
        double dialogWidth;
        if (isMobile) {
          dialogWidth = screenWidth * 0.95;
        } else if (isTablet) {
          dialogWidth = screenWidth * 0.9;
        } else {
          dialogWidth = 1200.0; // Max width for desktop
        }

        final contentPadding = isMobile ? const EdgeInsets.all(16) : const EdgeInsets.all(32);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40, vertical: 24),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(maxHeight: isMobile ? constraints.maxHeight * 0.95 : 900),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.participant == null 
                              ? 'Novo Participante' 
                              : (_isEditing ? 'Editar Participante' : 'Detalhes'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 20 : 24,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: contentPadding,
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Mobile: Stacked (QR First)
                              if (widget.participant != null)
                                ParticipantQrCard(
                                  qrData: qrData,
                                  participantName: _nameController.text,
                                  token: _token!,
                                  isMobile: true,
                                ),
                              const Gap(24),
                              ParticipantInfoTab(
                                isEditing: _isEditing,
                                nameController: _nameController,
                                emailController: _emailController,
                                phoneController: _phoneController,
                                cpfController: _cpfController,
                                companyController: _companyController,
                                roleController: _roleController,
                                customFieldControllers: _customFieldControllers,
                                onAddCustomField: _addCustomField,
                                onRemoveCustomField: _removeCustomField,
                              ),
                              const Gap(32),
                              _buildActionButtons(context),
                              if (widget.participant != null) ...[
                                const Gap(24),
                                _buildQuickInfoCard(context, checkInText, userStatus),
                              ],
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tablet/Desktop: Side-by-side
                              Expanded(
                                flex: isTablet ? 3 : 4, // Form gets more space on Desktop
                                child: ParticipantInfoTab(
                                  isEditing: _isEditing,
                                  nameController: _nameController,
                                  emailController: _emailController,
                                  phoneController: _phoneController,
                                  cpfController: _cpfController,
                                  companyController: _companyController,
                                  roleController: _roleController,
                                  customFieldControllers: _customFieldControllers,
                                  onAddCustomField: _addCustomField,
                                  onRemoveCustomField: _removeCustomField,
                                ),
                              ),
                              const Gap(40),
                              const VerticalDivider(width: 1),
                              const Gap(40),
                              Expanded(
                                flex: 2, // QR Side stays relatively compact
                                child: Column(
                                  children: [
                                    if (widget.participant != null) ...[
                                      ParticipantQrCard(
                                        qrData: qrData,
                                        participantName: _nameController.text,
                                        token: _token!,
                                        isMobile: false,
                                      ),
                                      const Gap(32),
                                    ],
                                    _buildActionButtons(context),
                                    const Gap(24),
                                    if (widget.participant != null)
                                      _buildQuickInfoCard(context, checkInText, userStatus),
                                  ],
                                ),
                              )
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickInfoCard(BuildContext context, String checkInTime, String status) {
     final bool isConfirmed = status == 'Confirmado' || widget.participant?.isCheckedIn == true;
     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: isConfirmed ? Colors.green[50] : Colors.orange[50],
         borderRadius: BorderRadius.circular(16),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               Icon(isConfirmed ? Icons.check_circle : Icons.pending, 
                    color: isConfirmed ? Colors.green[700] : Colors.orange[700], size: 20),
               const Gap(12),
               Text(
                 isConfirmed ? 'CHECK-IN REALIZADO' : 'AGUARDANDO CHECK-IN',
                 style: TextStyle(
                   fontWeight: FontWeight.bold,
                   fontSize: 12,
                   color: isConfirmed ? Colors.green[800] : Colors.orange[800],
                 ),
               ),
             ],
           ),
           if (isConfirmed) ...[
              const Gap(8),
              Text(
                 'Realizado em: $checkInTime',
                 style: TextStyle(fontSize: 11, color: Colors.green[900]),
              ),
           ],
         ],
       ),
     );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isEditing && widget.participant != null) {
      return CustomButton(
        text: 'Editar Dados',
        icon: Icons.edit,
        onPressed: _toggleEdit,
        backgroundColor: Colors.blue,
        isFullWidth: true,
      );
    } else {
      return Row(
        children: [
          if (widget.participant != null)
          Expanded(
            child: OutlinedButton(
              onPressed: _toggleEdit,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          if (widget.participant != null) const Gap(16),
          Expanded(
            child: CustomButton(
              text: 'Salvar',
              icon: Icons.save,
              onPressed: _saveParticipant,
              isFullWidth: true,
            ),
          ),
        ],
      );
    }
  }
}
