import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:the_builder_studio/app/constant/resources/app_string.dart';
import 'package:the_builder_studio/app/core/base/base_view.dart';
import 'package:the_builder_studio/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_studio/app/features/wallet/utility/wallet_ui_metrics.dart';
import 'package:the_builder_studio/app/widget/section_card.dart';

class WalletSendScanScreen extends BaseView<WalletController> {
  const WalletSendScanScreen({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppString.walletScanQrTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(WalletSpacing.lg),
          children: [_QrScannerPanel(controller: controller)],
        ),
      ),
    );
  }
}

class _QrScannerPanel extends StatefulWidget {
  const _QrScannerPanel({required this.controller});

  final WalletController controller;

  @override
  State<_QrScannerPanel> createState() => _QrScannerPanelState();
}

class _QrScannerPanelState extends State<_QrScannerPanel>
    with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 700,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  String _status = AppString.walletScannerOpening;
  bool _isRunning = false;
  bool _isProcessing = false;
  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startScanner());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_startScanner());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_stopScanner());
        break;
    }
  }

  Future<void> _startScanner() async {
    if (!mounted || _isRunning) {
      return;
    }

    _barcodeSubscription ??= _scannerController.barcodes.listen(
      _handleDetection,
    );

    try {
      await _scannerController.start();
      if (!mounted) {
        return;
      }
      setState(() {
        _isRunning = true;
        _status = AppString.walletScannerActive;
      });
    } on MobileScannerException catch (error) {
      await _barcodeSubscription?.cancel();
      _barcodeSubscription = null;
      if (!mounted) {
        return;
      }
      setState(() {
        _status = error.errorCode == MobileScannerErrorCode.permissionDenied
            ? AppString.walletScannerPermissionDenied
            : AppString.walletScannerUnavailable;
      });
    }
  }

  Future<void> _stopScanner() async {
    _isRunning = false;
    await _barcodeSubscription?.cancel();
    _barcodeSubscription = null;
    try {
      await _scannerController.stop();
    } catch (_) {
      // Camera shutdown can fail during lifecycle transitions.
    }
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    final normalizedValue = widget.controller.normalizeWalletPublicKey(
      rawValue,
    );

    if (normalizedValue == null) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() => _status = AppString.walletInvalidQr);
      }
      _isProcessing = false;
      return;
    }

    await _stopScanner();
    HapticFeedback.selectionClick();
    await widget.controller.applyScannedRecipient(normalizedValue);
    if (mounted) {
      setState(
        () => _status = widget.controller.recipientValidationMessage.value,
      );
    }
    _isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: AppString.walletScanQrTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(WalletRadius.md),
            child: AspectRatio(
              aspectRatio: 1,
              child: MobileScanner(
                controller: _scannerController,
                fit: BoxFit.cover,
                useAppLifecycleState: false,
                placeholderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, _) => const _ScannerFallback(),
              ),
            ),
          ),
          const SizedBox(height: WalletSpacing.sm),
          Row(
            children: [
              Expanded(child: Text(_status)),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _status = AppString.walletScannerOpening);
                  unawaited(_stopScanner().then((_) => _startScanner()));
                },
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: const Text(AppString.walletScanAgain),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_barcodeSubscription?.cancel());
    unawaited(_scannerController.dispose());
    super.dispose();
  }
}

class _ScannerFallback extends StatelessWidget {
  const _ScannerFallback();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.camera_alt_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 40,
        ),
      ),
    );
  }
}
