
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_theme.dart';

class QrExportDialog extends StatefulWidget {
  final String data;
  final String participantName;

  const QrExportDialog({
    super.key,
    required this.data,
    required this.participantName,
  });

  @override
  State<QrExportDialog> createState() => _QrExportDialogState();
}

class _QrExportDialogState extends State<QrExportDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareQrCode() async {
    setState(() => _isSharing = true);
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = await _screenshotController.captureAndSave(
        directory.path,
        fileName: 'qr_${widget.participantName.replaceAll(' ', '_')}.png',
      );

      if (imagePath != null) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(imagePath)], text: 'QR Code para ${widget.participantName}');
      }
    } catch (e) {
      debugPrint('Error sharing: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final dialogWidth = isMobile ? constraints.maxWidth * 0.9 : 450.0;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: constraints.maxHeight * 0.9,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QR Code do Participante',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(widget.participantName, textAlign: TextAlign.center),
                  const Gap(24),
                  Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: widget.data,
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppTheme.primaryRed,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            widget.data,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(24),
                  isMobile 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isSharing ? null : _shareQrCode,
                            icon: _isSharing 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.share),
                            label: const Text('Exportar / Compartilhar'),
                          ),
                          const Gap(16),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fechar'),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fechar'),
                          ),
                          const Gap(16),
                          ElevatedButton.icon(
                            onPressed: _isSharing ? null : _shareQrCode,
                            icon: _isSharing 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.share),
                            label: const Text('Exportar / Compartilhar'),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
