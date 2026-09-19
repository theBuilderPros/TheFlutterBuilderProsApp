import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_screen_components.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletOverviewScreen extends BaseView<WalletController> {
  const WalletOverviewScreen({super.key});
  @override
  Widget buildView(BuildContext context) => WalletPage(
    title: 'Rewards',
    subtitle: 'Your Builder Rewards preview.',
    trailing: IconButton.filledTonal(
      onPressed: controller.openLocked,
      tooltip: 'Preview protected Rewards',
      icon: const Icon(Icons.lock_outline),
    ),
    children: <Widget>[
      WalletCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text('Available balance'),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.snackbar(
                    'Mock balance',
                    'Balance refresh is presentation-only.',
                  ),
                  tooltip: 'Refresh mock balance',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            Text(
              '1,250 pts',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const WalletStatusBadge(label: 'Preview balance'),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: <Widget>[
          Expanded(
            child: WalletActionCard(
              icon: Icons.qr_code_2,
              label: 'Receive',
              onTap: controller.openReceive,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: WalletActionCard(
              icon: Icons.send_outlined,
              label: 'Send',
              onTap: controller.openSend,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      WalletCard(
        child: Column(
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: const Text('Rewards history'),
              subtitle: const Text('Review mock Rewards activity'),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.openHistory,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phonelink_erase_outlined),
              title: const Text('Remove Rewards access'),
              subtitle: const Text('Preview removal from this device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.openRemoveWallet,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: controller.openAppMaster,
        icon: const Icon(Icons.hub_outlined),
        label: const Text('Open App Master'),
      ),
      const SizedBox(height: 12),
      const WalletPreviewNotice(),
    ],
  );
}
