import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'qr_export_dialog.dart';

class ParticipantQrCard extends StatelessWidget {
  final String qrData;
  final String participantName;
  final String token;
  final bool isMobile;

  const ParticipantQrCard({
    super.key,
    required this.qrData,
    required this.participantName,
    required this.token,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
               color: AppTheme.primaryRed,
               borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: isMobile ? 160.0 : 200.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.white,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.white,
              ),
            ),
          ),
          const Gap(20),
          Text(
             participantName.toUpperCase(),
             textAlign: TextAlign.center,
             style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
          ),
          const Gap(4),
          Text(
            token,
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const Gap(16),
          OutlinedButton.icon(
             onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => QrExportDialog(
                    data: qrData,
                    participantName: participantName,
                  ),
                );
             },
             icon: const Icon(Icons.qr_code_2, size: 18),
             label: const Text('EXPORTAR QR'),
             style: OutlinedButton.styleFrom(
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
          ),
        ],
      ),
    );
  }
}
