import 'package:flutter/material.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletSendScanScreen extends BaseView<WalletController> {
  const WalletSendScanScreen({super.key});
  @override
  Widget buildView(BuildContext context) => WalletPage(
    title: 'Scan Recipient',
    subtitle: 'Identify who will receive Builder Rewards.',
    children: <Widget>[
      WalletCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.violetSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.violet),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.qr_code_scanner, size: 94),
                  SizedBox(height: 12),
                  Text('Mock camera preview'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: controller.useMockRecipient,
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Scan sample recipient'),
            ),
            OutlinedButton.icon(
              onPressed: controller.useMockRecipient,
              icon: const Icon(Icons.keyboard_outlined),
              label: const Text('Enter Reward ID instead'),
            ),
          ],
        ),
      ),
    ],
  );
}
