import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:the_builder_studio/app/constant/resources/app_string.dart';
import 'package:the_builder_studio/app/core/base/base_view.dart';
import 'package:the_builder_studio/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_studio/app/features/wallet/utility/wallet_ui_metrics.dart';
import 'package:the_builder_studio/app/widget/section_card.dart';

class WalletSendScreen extends BaseView<WalletController> {
  const WalletSendScreen({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppString.walletSendTitle)),
      body: SafeArea(
        child: Obx(() {
          final isActivated = controller.walletAccess.value != null;
          if (!isActivated) {
            return const _MessagePanel(
              message: AppString.walletActivateFirstMessage,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(WalletSpacing.lg),
            children: [
              SectionCard(
                title: AppString.walletSendTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller.recipientController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: AppString.walletRecipientLabel,
                        hintText: AppString.walletRecipientReadonlyHint,
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                    ),
                    const SizedBox(height: WalletSpacing.sm),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: AppString.walletAssetReadonlyLabel,
                        prefixIcon: Icon(Icons.loyalty_outlined),
                      ),
                      child: Text(controller.assetCode),
                    ),
                    const SizedBox(height: WalletSpacing.sm),
                    TextField(
                      controller: controller.amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: AppString.walletAmountLabel,
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: WalletSpacing.sm),
                    _ValidationStatus(controller: controller),
                    const SizedBox(height: WalletSpacing.sm),
                    _ReviewButton(controller: controller),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ValidationStatus extends StatelessWidget {
  const _ValidationStatus({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = controller.recipientValidationMessage.value;
      if (message.isEmpty) {
        return const SizedBox.shrink();
      }
      return Row(
        children: [
          if (controller.isRecipientValidating.value)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              controller.isRecipientValid.value
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
            ),
          const SizedBox(width: WalletSpacing.sm),
          Expanded(child: Text(message)),
        ],
      );
    });
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.amountController,
      builder: (_, value, _) {
        final amount = double.tryParse(value.text.trim());
        final hasValidAmount = amount != null && amount > 0;
        return Obx(
          () => FilledButton.icon(
            onPressed: controller.isRecipientValid.value && hasValidAmount
                ? controller.continueToReview
                : null,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text(AppString.walletReviewTitle),
          ),
        );
      },
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(WalletSpacing.lg),
      children: [
        SectionCard(title: AppString.walletSendTitle, child: Text(message)),
      ],
    );
  }
}
