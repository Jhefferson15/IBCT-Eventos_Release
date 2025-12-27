import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/checkin_controller.dart';

// Local constants for strings. In production, use l10n.
class _CheckinStrings {
  static const alreadyCheckedIn = 'Já Havia Feito Check-in';
  static const checkinSuccess = 'Check-in Realizado!';
  static const invalidCode = 'Código Inválido';
  static const invalidToken = 'Inválido';
  static const userAlreadyEntered = 'Este usuário já entrou no evento.';
  static const next = 'Próximo';
  static const scanInstruction = 'Aponte a câmera para o QR Code';
  static const labelParticipant = 'Participante';
  static const labelTicket = 'Ingresso';
  static const labelTime = 'Horário';
}

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: false,
    );
    // Request permission after frame build to ensure context is ready if needed, 
    // though here we just call the plugin. 
    // Ideally, a PermissionService should handle checking/requesting before this screen is even shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _controller.start();
    } else {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Permissão de câmera necessária')),
         );
       }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true); 
        await ref.read(checkinControllerProvider.notifier).validateAndCheckIn(barcode.rawValue!);
        break; 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(checkinControllerProvider, (previous, next) {
      if (next is CheckinSuccess) {
        _showResult(
          context: context,
          isValid: true,
          name: next.participant.name,
          ticketType: next.participant.ticketType,
          alreadyCheckedIn: next.alreadyCheckedIn,
          token: next.participant.token
        );
      } else if (next is CheckinError) {
        _showResult(
          context: context,
          isValid: false,
          name: '',
          ticketType: '',
          alreadyCheckedIn: false,
          token: _CheckinStrings.invalidToken,
          errorMessage: next.message
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.white);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front, color: Colors.white);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear, color: Colors.white);
                  default:
                    return const Icon(Icons.camera, color: Colors.white);
                }
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Future<void> _showResult({
    required BuildContext context,
    required bool isValid,
    required String name,
    required String ticketType,
    required bool alreadyCheckedIn,
    required String token,
    String? errorMessage,
  }) async {
    Color color;
    IconData icon;
    String title;
    
    if (isValid) {
        if (alreadyCheckedIn) {
            color = Colors.orange;
            icon = Icons.warning_amber_rounded;
            title = _CheckinStrings.alreadyCheckedIn;
        } else {
            color = Colors.green;
            icon = Icons.check_circle;
            title = _CheckinStrings.checkinSuccess;
        }
    } else {
        color = Colors.red;
        icon = Icons.error;
        title = errorMessage ?? _CheckinStrings.invalidCode;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const Gap(16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const Gap(8),
            Text(
              token != _CheckinStrings.invalidToken ? 'Token: ${token.substring(0, token.length > 8 ? 8 : token.length)}...' : token,
              style: const TextStyle(color: Colors.grey),
            ),
            const Gap(24),
            if (isValid) ...[
              _buildInfoRow(_CheckinStrings.labelParticipant, name),
              const Divider(),
              _buildInfoRow(_CheckinStrings.labelTicket, ticketType),
              const Divider(),
              _buildInfoRow(_CheckinStrings.labelTime, TimeOfDay.now().format(context)),
              if (alreadyCheckedIn) ...[
                  const Gap(8),
                  const Text(_CheckinStrings.userAlreadyEntered, style: TextStyle(color: Colors.orange)),
              ]
            ],
            const Gap(32),
            CustomButton(
              text: _CheckinStrings.next,
              onPressed: () {
                Navigator.pop(context);
                ref.read(checkinControllerProvider.notifier).reset();
                setState(() => _isProcessing = false);
              }, 
              backgroundColor: isValid && !alreadyCheckedIn ? Colors.blue : Colors.grey,
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final scanAreaSize = constraints.maxWidth < 600 ? 250.0 : 400.0;
      return Stack(
        children: [
          // Dark Overlay with Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Instructions Text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Text(
                _CheckinStrings.scanInstruction,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    });
  }
}
