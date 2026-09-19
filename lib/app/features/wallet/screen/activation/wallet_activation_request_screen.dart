import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/profile/widget/builder_identity_card.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_screen_components.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletActivationRequestScreen extends BaseView<WalletController> {
  const WalletActivationRequestScreen({super.key});

  @override
  Widget buildView(BuildContext context) => WalletPage(
    title: 'Activation Request',
    subtitle: 'Let an App Master scan your activation request.',
    children: <Widget>[
      const WalletStepIndicator(current: 1, total: 3, label: 'Request'),
      const SizedBox(height: 16),
      BuilderIdentityCard.summary(
        name: controller.builderName,
        phone: controller.phoneNumber,
        status: 'Waiting for activation',
      ),
      const SizedBox(height: 16),
      Obx(() {
        final request = controller.activationRequest.value;
        if (request == null) {
          return const WalletCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return WalletCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                label: 'Activation request QR',
                image: true,
                child: Center(
                  child: QrImageView(
                    data: request.qrValue,
                    size: 190,
                    semanticsLabel: 'Activation request QR',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your activation request',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SelectableText(request.requestId, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Expires at ${_formatTime(request.expiresAt)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: request.qrValue));
                  Get.snackbar('Copied', 'Activation request copied.');
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy activation request'),
              ),
              FilledButton.icon(
                onPressed: controller.openActivationScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan activation QR'),
              ),
              TextButton.icon(
                onPressed: controller.importActivationResponse,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Import QR image'),
              ),
              Obx(() {
                final String error = controller.activationResponseError.value;
                return error.isEmpty
                    ? const SizedBox.shrink()
                    : Text(error, textAlign: TextAlign.center);
              }),
              const SizedBox(height: 8),
              Obx(
                () => OutlinedButton.icon(
                  onPressed: controller.isCancellingActivation.value
                      ? null
                      : () => _confirmCancellation(context),
                  icon: controller.isCancellingActivation.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close),
                  label: Text(
                    controller.isCancellingActivation.value
                        ? 'Cancelling…'
                        : 'Cancel activation',
                  ),
                ),
              ),
              Obx(() {
                final String error =
                    controller.activationCancellationError.value;
                if (error.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
      const SizedBox(height: 16),
      const WalletBoundaryNotice(
        icon: Icons.security_outlined,
        text: 'Your private activation details stay protected on this device.',
      ),
      const SizedBox(height: 8),
      const WalletBoundaryNotice(
        icon: Icons.science_outlined,
        text:
            'QR scanning and image import are previews and do not activate Rewards yet.',
      ),
    ],
  );

  Future<void> _confirmCancellation(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Cancel activation?'),
        content: const Text(
          'This request will stop working. You can start again with a new request.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep request'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel activation'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.cancelActivation();
    }
  }

  static String _formatTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
