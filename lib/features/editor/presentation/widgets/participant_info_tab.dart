import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';

class ParticipantInfoTab extends StatefulWidget {
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController cpfController;
  final TextEditingController companyController;
  final TextEditingController roleController;
  final Map<String, TextEditingController> customFieldControllers;
  final VoidCallback onAddCustomField;
  final ValueChanged<String> onRemoveCustomField;

  const ParticipantInfoTab({
    super.key,
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.cpfController,
    required this.companyController,
    required this.roleController,
    required this.customFieldControllers,
    required this.onAddCustomField,
    required this.onRemoveCustomField,
  });

  @override
  State<ParticipantInfoTab> createState() => _ParticipantInfoTabState();
}

class _ParticipantInfoTabState extends State<ParticipantInfoTab> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine number of columns based on width
        // < 500: 1 column
        // 500 - 800: 2 columns
        // > 800: 3 columns (if needed) or just spacious 2
        int crossAxisCount = 1;
        if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 500) {
          crossAxisCount = 2;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, Icons.person_outline, 'Identificação'),
            const Gap(16),
            
            // Grid for Identification
            _buildResponsiveGrid(
              crossAxisCount: crossAxisCount,
              children: [
                 CustomTextField(
                  label: 'Nome Completo',
                  controller: widget.nameController,
                  enabled: widget.isEditing,
                  prefixIcon: Icons.badge_outlined,
                ),
                CustomTextField(
                  label: 'E-mail',
                  controller: widget.emailController,
                  enabled: widget.isEditing,
                  prefixIcon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                ),
                CustomTextField(
                  label: 'Telefone',
                  controller: widget.phoneController,
                  enabled: widget.isEditing,
                  prefixIcon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
                CustomTextField(
                  label: 'CPF/CNPJ',
                  controller: widget.cpfController,
                  enabled: widget.isEditing,
                  prefixIcon: Icons.fingerprint,
                ),
              ],
            ),
            
            const Gap(32),
            _buildSectionHeader(context, Icons.business_center_outlined, 'Profissional'),
            const Gap(16),
            
             // Grid for Professional
            _buildResponsiveGrid(
              crossAxisCount: crossAxisCount,
              children: [
                CustomTextField(
                  label: 'Empresa',
                  controller: widget.companyController,
                  enabled: widget.isEditing,
                  prefixIcon: Icons.business,
                ),
                CustomTextField(
                  label: 'Cargo/Função',
                  controller: widget.roleController,
                  enabled: widget.isEditing,
                  prefixIcon: Icons.work_outline,
                ),
              ],
            ),

            const Gap(32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 _buildSectionHeader(context, Icons.tune_outlined, 'Campos Personalizados'),
                 if (widget.isEditing)
                   TextButton.icon(
                     onPressed: widget.onAddCustomField,
                     icon: const Icon(Icons.add_circle_outline, size: 20),
                     label: const Text('Novo Campo'),
                   ),
              ],
            ),
            const Gap(8),
            if (widget.customFieldControllers.isEmpty)
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 12),
                 child: Text("Sem dados adicionais vinculados.", style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
               ),
            
             // Grid for Custom Fields
            _buildResponsiveGrid(
              crossAxisCount: crossAxisCount,
              children: widget.customFieldControllers.entries.map((entry) {
                return Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: entry.key,
                        controller: entry.value,
                        enabled: widget.isEditing,
                        prefixIcon: Icons.label_important_outline, 
                      ),
                    ),
                    if (widget.isEditing)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                        onPressed: () => widget.onRemoveCustomField(entry.key),
                        tooltip: 'Remover',
                      ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveGrid({
    required int crossAxisCount,
    required List<Widget> children,
    double spacing = 16.0,
  }) {
    if (crossAxisCount <= 1) {
      return Column(
        children: children.map((c) => Padding(padding: EdgeInsets.only(bottom: spacing), child: c)).toList(),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += crossAxisCount) {
      final chunk = children.sublist(i, (i + crossAxisCount) > children.length ? children.length : i + crossAxisCount);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: chunk.map((c) => Expanded(child: c)).expand((widget) => [widget, SizedBox(width: spacing)]).toList()..removeLast(),
        ),
      );
      rows.add(SizedBox(height: spacing));
    }
    // Remove last spacing if exists
    if (rows.isNotEmpty && rows.last is SizedBox) {
       rows.removeLast();
    }
    return Column(children: rows);
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryRed),
        const Gap(12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }
}
