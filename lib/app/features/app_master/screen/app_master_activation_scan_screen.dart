import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:the_builder_pros/app/features/app_master/controller/app_master_controller.dart';
import 'package:the_builder_pros/app/features/app_master/service/qr_input_adapter.dart';

class AppMasterActivationScanScreen extends StatefulWidget {
  const AppMasterActivationScanScreen({super.key});

  @override
  State<AppMasterActivationScanScreen> createState() =>
      _AppMasterActivationScanScreenState();
}

class _AppMasterActivationScanScreenState
    extends State<AppMasterActivationScanScreen> {
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
    if (_handled) {
      return;
    }
    final AppMasterController controller = Get.find<AppMasterController>();
    final QrInputResult result = controller.qrInputAdapter.fromCapture(capture);
    if (!result.isSuccess) {
      controller.handleQrFailure(result.failure!);
      return;
    }
    _handled = true;
    await _scanner.stop();
    await controller.acceptActivationRequest(result.value!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan activation request')),
    body: MobileScanner(
      controller: _scanner,
      onDetect: _onDetect,
      errorBuilder: (BuildContext context, MobileScannerException error) {
        final bool denied =
            error.errorCode == MobileScannerErrorCode.permissionDenied;
        return _ScannerMessage(
          icon: denied ? Icons.no_photography_outlined : Icons.qr_code_2,
          message: denied
              ? 'Camera access was denied. You can import a QR image instead.'
              : 'The camera scanner is unavailable on this device.',
        );
      },
      overlayBuilder: (_, BoxConstraints constraints) => Center(
        child: Container(
          width: constraints.maxWidth * 0.72,
          height: constraints.maxWidth * 0.72,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ),
  );
}

class _ScannerMessage extends StatelessWidget {
  const _ScannerMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
