import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/profile/widget/builder_identity_card.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_screen_components.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletNotActivatedScreen extends BaseView<WalletController> {
  const WalletNotActivatedScreen({super.key});

  @override
  Widget buildView(BuildContext context) => WalletPage(
    title: 'Rewards',
    subtitle: 'Activate Builder Rewards on this device.',
    trailing: IconButton.filledTonal(
      onPressed: controller.openAppMaster,
      tooltip: 'Open App Master',
      icon: const Icon(Icons.hub_outlined),
    ),
    children: <Widget>[
      Obx(
        () => BuilderIdentityCard.editable(
          nameController: controller.builderNameController,
          phoneController: controller.phoneController,
          errorText: controller.activationError.value,
          enabled: !controller.isPreparingActivation.value,
        ),
      ),
      const SizedBox(height: 16),
      WalletCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 54,
              color: AppColors.violet,
            ),
            const SizedBox(height: 16),
            Text(
              'Rewards is not activated',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Activate Rewards on this device to view your balance, receive Rewards, and send Rewards.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Obx(
              () => FilledButton.icon(
                onPressed: controller.isPreparingActivation.value
                    ? null
                    : controller.startActivation,
                icon: controller.isPreparingActivation.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(
                  controller.isPreparingActivation.value
                      ? 'Preparing your activation request…'
                      : 'Start activation',
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const WalletPreviewNotice(),
    ],
  );
}
