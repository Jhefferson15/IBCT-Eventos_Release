import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../features/editor/presentation/providers/participant_providers.dart';

import '../providers/store_providers.dart';
import '../providers/pos_providers.dart';
import '../providers/store_controller.dart';

class StoreScannerScreen extends ConsumerStatefulWidget {
  final String eventId;

  const StoreScannerScreen({super.key, required this.eventId});

  @override
  ConsumerState<StoreScannerScreen> createState() => _StoreScannerScreenState();
}

class _StoreScannerScreenState extends ConsumerState<StoreScannerScreen> {
  late MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: false,
    );
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    await Permission.camera.request();
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        await _processBarcode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processBarcode(String token) async {
    // 1. Fetch Participant
    try {
      final participants = await ref.read(participantsControllerProvider(widget.eventId).future);
      final participant = participants.firstWhere(
        (p) => p.token == token,
        orElse: () => throw Exception('Participante não encontrado'),
      );

      // 2. Get Cart Items
      final cart = ref.read(posCartProvider);
      if (cart.items.isEmpty) {
        throw Exception('Carrinho vazio.');
      }

      if (!mounted) return;

      // 3. Show Confirmation
      _showConfirmationDialog(
        participant.id, 
        participant.name,
        cart,
      );

    } catch (e) {
      if (mounted) {
        _showResult(
          isValid: false,
          title: 'Erro de Leitura',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _showConfirmationDialog(String participantId, String participantName, CartState cart) {
    showModalBottomSheet(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.shopping_cart, size: 64, color: Colors.blue),
            const Gap(16),
            Text(
              'Confirmar Venda',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(24),
            _buildInfoRow('Participante', participantName),
            const Divider(),
            ...cart.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.quantity}x ${item.product.name}'),
                  Text('R\$ ${item.totalPrice.toStringAsFixed(2)}'),
                ],
              ),
            )),
            const Divider(),
            _buildInfoRow('Total', 'R\$ ${cart.total.toStringAsFixed(2)}'),
            const Gap(32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isProcessing = false);
                    },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Cancelar'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close confirmation
                      await _confirmSale(participantId, participantName, cart);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CONFIRMAR'),
                  ),
                ),
              ],
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSale(String participantId, String participantName, CartState cart) async {
      try {
        await ref.read(storeControllerProvider.notifier).processCartSale(
          eventId: widget.eventId,
          participantId: participantId,
          participantName: participantName,
          items: cart.items,
        );
        
        // Clear cart after successful sale
        ref.read(posCartProvider.notifier).clear();

        if (mounted) {
           _showResult(isValid: true, title: 'Venda Realizada!', message: 'Transação salva com sucesso.');
        }
      } catch (e) {
        if (mounted) {
          _showResult(isValid: false, title: 'Erro na Venda', message: e.toString());
        }
      }
  }

  Future<void> _showResult({
    required bool isValid,
    required String title,
    required String message,
  }) async {
    final color = isValid ? Colors.green : Colors.red;
    final icon = isValid ? Icons.check_circle : Icons.error;

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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const Gap(32),
            CustomButton(
              text: 'Novo Pagamento',
              onPressed: () {
                Navigator.pop(context); // Close Result
                Navigator.pop(context); // Close Scanner to return to POS
              },
              backgroundColor: color,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Text(
                'Leia o QR Code do Participante para Vender',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
}
