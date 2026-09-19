import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/app_master/controller/app_master_controller.dart';
import 'package:the_builder_pros/app/features/app_master/widget/app_master_page.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_screen_components.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

class AppMasterActivationQrScreen extends BaseView<AppMasterController> {
  const AppMasterActivationQrScreen({super.key});

  @override
  Widget buildView(BuildContext context) => Obx(() {
    final ActivationResponseView? response =
        controller.activationResponse.value;
    return AppMasterPage(
      title: 'Activation QR',
      subtitle: 'Let the Builder scan or import this activation.',
      children: <Widget>[
        WalletCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: response == null
                        ? const Icon(Icons.qr_code_2, size: 190)
                        : QrImageView(
                            data: response.qrValue,
                            size: 190,
                            errorCorrectionLevel: QrErrorCorrectLevel.L,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Builder activation package',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                response == null
                    ? 'Activation package unavailable'
                    : '${response.responseId} • valid until ${_expiry(response.expiresAt)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: response == null
                    ? null
                    : () => Get.snackbar(
                        'Activation QR',
                        'Use your device screenshot action to save this QR.',
                      ),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Save QR image'),
              ),
              FilledButton(
                onPressed: controller.finishActivation,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const WalletBoundaryNotice(
          icon: Icons.info_outline,
          text:
              'The Builder must review and approve this package on their device.',
        ),
      ],
    );
  });

  String _expiry(DateTime value) {
    final DateTime local = value.toLocal();
    return '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }
}
