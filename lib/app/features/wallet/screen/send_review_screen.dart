import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_studio/app/constant/resources/app_string.dart';
import 'package:the_builder_studio/app/core/base/base_view.dart';
import 'package:the_builder_studio/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_studio/app/features/wallet/utility/wallet_ui_metrics.dart';
import 'package:the_builder_studio/app/widget/section_card.dart';

class WalletSendReviewScreen extends BaseView<WalletController> {
  const WalletSendReviewScreen({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppString.walletReviewTitle)),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.all(WalletSpacing.lg),
            children: [
              SectionCard(
                title: AppString.walletReviewTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReviewRow(
                      label: AppString.walletRecipientLabel,
                      value: controller.recipientController.text,
                    ),
                    _ReviewRow(
                      label: AppString.walletAmountLabel,
                      value: controller.amountController.text,
                    ),
                    _ReviewRow(
                      label: AppString.walletAssetCodeLabel,
                      value: controller.assetCode,
                    ),
                    _ReviewRow(
                      label: AppString.walletNetworkLabel,
                      value: controller.networkName,
                    ),
                    const SizedBox(height: WalletSpacing.sm),
                    if (!controller.isWalletUnlocked)
                      OutlinedButton.icon(
                        onPressed: controller.unlockWalletForSend,
                        icon: const Icon(Icons.lock_open_outlined),
                        label: const Text(AppString.walletUnlockButton),
                      ),
                    const SizedBox(height: WalletSpacing.sm),
                    FilledButton.icon(
                      onPressed: controller.isSubmittingSend.value
                          ? null
                          : controller.confirmSend,
                      icon: controller.isSubmittingSend.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text(AppString.walletConfirmSend),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WalletSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: WalletSpacing.xs),
          SelectableText(
            value.isEmpty ? AppString.walletUnavailableValue : value,
          ),
        ],
      ),
    );
  }
}
