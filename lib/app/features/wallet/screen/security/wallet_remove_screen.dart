import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/constant/routing/app_route.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletRemoveScreen extends BaseView<WalletController> {
  const WalletRemoveScreen({super.key});
  @override
  Widget buildView(BuildContext context) => WalletPage(
    title: 'Remove Rewards Access',
    subtitle: 'Preview removal from this device.',
    children: <Widget>[
      WalletCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(
              Icons.warning_amber_rounded,
              size: 58,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Remove Rewards access from this device?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'This preview returns Rewards to the not-activated screen. No real account or balance is changed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => controller.requestAuthentication(
                purpose: 'Authorize Rewards access removal',
                nextRoute: Routes.wallet,
              ),
              icon: const Icon(Icons.phonelink_erase_outlined),
              label: const Text('Continue removal'),
            ),
            OutlinedButton(
              onPressed: Get.back,
              child: const Text('Keep Rewards access'),
            ),
          ],
        ),
      ),
    ],
  );
}
