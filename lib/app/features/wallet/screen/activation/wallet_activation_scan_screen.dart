import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:the_builder_pros/app/features/app_master/service/qr_input_adapter.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';

class WalletActivationScanScreen extends StatefulWidget {
  const WalletActivationScanScreen({super.key});

  @override
  State<WalletActivationScanScreen> createState() =>
      _WalletActivationScanScreenState();
}

class _WalletActivationScanScreenState
    extends State<WalletActivationScanScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final WalletController controller = Get.find<WalletController>();
    final QrInputResult result = controller.qrInputAdapter.fromCapture(capture);
    if (!result.isSuccess) return;
    _handled = true;
    await _scanner.stop();
    await controller.inspectActivationResponse(result.value!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan activation QR')),
    body: MobileScanner(
      controller: _scanner,
      onDetect: _onDetect,
      errorBuilder: (_, MobileScannerException error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            error.errorCode == MobileScannerErrorCode.permissionDenied
                ? 'Camera access was denied. Import a QR image instead.'
                : 'The camera scanner is unavailable.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
