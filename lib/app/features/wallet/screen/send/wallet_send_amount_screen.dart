import 'package:flutter/material.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

const String _mockRecipient = 'Avery Chen  •  BLD-AC-00831';

class WalletSendAmountScreen extends BaseView<WalletController> {
  const WalletSendAmountScreen({super.key});
  @override
  Widget buildView(BuildContext context) => WalletPage(
    title: 'Send Rewards',
    subtitle: 'Enter a mock amount for the validated recipient.',
    children: <Widget>[
      WalletCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text('Validated recipient'),
              subtitle: Text(_mockRecipient),
              trailing: Icon(Icons.verified, color: AppColors.violet),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Rewards amount',
                hintText: '25',
                suffixText: 'pts',
                prefixIcon: Icon(Icons.card_giftcard_outlined),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Available preview balance: 1,250 pts'),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: controller.reviewMockAmount,
              child: const Text('Continue to review'),
            ),
          ],
        ),
      ),
    ],
  );
}
