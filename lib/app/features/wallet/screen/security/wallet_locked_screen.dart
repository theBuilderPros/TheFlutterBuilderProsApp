import 'package:flutter/material.dart';
import 'package:the_builder_pros/app/constant/routing/app_route.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletLockedScreen extends BaseView<WalletController> {
  const WalletLockedScreen({super.key});
  @override
  Widget buildView(BuildContext context) => WalletPage(
    title: 'Rewards Locked',
    subtitle: 'Protected actions need authorization.',
    children: <Widget>[
      WalletCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(Icons.lock_outline, size: 58),
            const SizedBox(height: 16),
            Text(
              'Protected actions are locked',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Rewards balance remains available, but protected actions require authorization.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => controller.requestAuthentication(
                purpose: 'Unlock protected Rewards actions',
                nextRoute: Routes.walletOverview,
              ),
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text('Unlock Rewards'),
            ),
          ],
        ),
      ),
    ],
  );
}
