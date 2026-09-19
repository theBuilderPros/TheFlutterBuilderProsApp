import 'package:flutter/material.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_screen_components.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletHistoryScreen extends BaseView<WalletController> {
  const WalletHistoryScreen({super.key});
  @override
  Widget buildView(BuildContext context) => const WalletPage(
    title: 'Rewards History',
    subtitle: 'Mock activity on this device.',
    children: <Widget>[
      WalletCard(
        child: Column(
          children: <Widget>[
            WalletHistoryItem(
              icon: Icons.arrow_upward,
              title: 'Sent to Avery Chen',
              subtitle: 'Today • Confirmed',
              amount: '-25 pts',
            ),
            Divider(),
            WalletHistoryItem(
              icon: Icons.arrow_downward,
              title: 'Received from Morgan Lee',
              subtitle: 'Yesterday • Confirmed',
              amount: '+80 pts',
            ),
            Divider(),
            WalletHistoryItem(
              icon: Icons.schedule,
              title: 'Sent to Riley Park',
              subtitle: 'Sep 14 • Pending',
              amount: '-10 pts',
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      WalletPreviewNotice(),
    ],
  );
}
