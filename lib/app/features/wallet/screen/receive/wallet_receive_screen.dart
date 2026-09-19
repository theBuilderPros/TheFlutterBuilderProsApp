import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

const String _mockRewardId = 'BLD-JR-00142';

class WalletReceiveScreen extends BaseView<WalletController> {
  const WalletReceiveScreen({super.key});
  @override
  Widget buildView(BuildContext context) => WalletPage(
    title: 'Receive Rewards',
    subtitle: 'Share your public Reward ID.',
    children: <Widget>[
      WalletCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 196,
                height: 196,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 142,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Public Reward ID', textAlign: TextAlign.center),
            const SizedBox(height: 6),
            SelectableText(
              _mockRewardId,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: _mockRewardId));
                Get.snackbar('Copied', 'Mock public Reward ID copied.');
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy Reward ID'),
            ),
            FilledButton(onPressed: Get.back, child: const Text('Done')),
          ],
        ),
      ),
    ],
  );
}
