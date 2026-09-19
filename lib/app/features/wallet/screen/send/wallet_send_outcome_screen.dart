import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletSendOutcomeScreen extends BaseView<WalletController> {
  const WalletSendOutcomeScreen({super.key});
  @override
  Widget buildView(BuildContext context) => WalletPage(
    title: 'Send Outcome',
    subtitle: 'Preview each possible send outcome.',
    children: <Widget>[
      Obx(() {
        final MockSendOutcome outcome = controller.sendOutcome.value;
        final (IconData, Color, String, String) presentation =
            switch (outcome) {
              MockSendOutcome.success => (
                Icons.check_circle_outline,
                AppColors.violet,
                'Rewards sent',
                'The mock transfer completed successfully.',
              ),
              MockSendOutcome.rejected => (
                Icons.error_outline,
                AppColors.primaryDark,
                'Send rejected',
                'The mock transfer was not submitted or accepted.',
              ),
              MockSendOutcome.pending => (
                Icons.schedule_outlined,
                AppColors.primary,
                'Outcome pending',
                'The result is unknown. Do not submit the transfer again.',
              ),
            };
        return WalletCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(presentation.$1, size: 58, color: presentation.$2),
              const SizedBox(height: 14),
              Text(
                presentation.$3,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(presentation.$4, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SegmentedButton<MockSendOutcome>(
                segments: const <ButtonSegment<MockSendOutcome>>[
                  ButtonSegment<MockSendOutcome>(
                    value: MockSendOutcome.success,
                    label: Text('Success'),
                  ),
                  ButtonSegment<MockSendOutcome>(
                    value: MockSendOutcome.rejected,
                    label: Text('Rejected'),
                  ),
                  ButtonSegment<MockSendOutcome>(
                    value: MockSendOutcome.pending,
                    label: Text('Pending'),
                  ),
                ],
                selected: <MockSendOutcome>{outcome},
                onSelectionChanged: (Set<MockSendOutcome> values) =>
                    controller.sendOutcome.value = values.first,
                showSelectedIcon: false,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: controller.openWalletOverview,
                child: const Text('Return to Rewards'),
              ),
            ],
          ),
        );
      }),
    ],
  );
}
