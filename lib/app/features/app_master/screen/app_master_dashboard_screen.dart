import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/app_master/controller/app_master_controller.dart';
import 'package:the_builder_pros/app/features/app_master/widget/app_master_page.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class AppMasterDashboardScreen extends BaseView<AppMasterController> {
  const AppMasterDashboardScreen({super.key});

  @override
  Widget buildView(BuildContext context) => AppMasterPage(
    title: 'App Master',
    subtitle: 'Activate Builders and manage Rewards access.',
    trailing: IconButton.filledTonal(
      onPressed: controller.openBuilderWallet,
      tooltip: 'Open User Rewards',
      icon: const Icon(Icons.card_giftcard_outlined),
    ),
    children: <Widget>[
      SegmentedButton<String>(
        segments: const <ButtonSegment<String>>[
          ButtonSegment<String>(
            value: 'overview',
            label: Text('Overview'),
            icon: Icon(Icons.hub_outlined),
          ),
          ButtonSegment<String>(
            value: 'advanced',
            label: Text('Advanced'),
            icon: Icon(Icons.tune),
          ),
          ButtonSegment<String>(
            value: 'rewards',
            label: Text('My Rewards'),
            icon: Icon(Icons.card_giftcard_outlined),
          ),
        ],
        selected: const <String>{'overview'},
        onSelectionChanged: (Set<String> selection) {
          if (selection.contains('advanced')) {
            controller.openAdvanced();
          } else if (selection.contains('rewards')) {
            controller.openBuilderWallet();
          }
        },
      ),
      const SizedBox(height: 16),
      Obx(
        () => Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: controller.isRefreshingOverview.value
                ? null
                : controller.refreshOverview,
            icon: controller.isRefreshingOverview.value
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Refresh status'),
          ),
        ),
      ),
      Obx(
        () => WalletCard(
          child: Row(
            children: <Widget>[
              const CircleAvatar(
                backgroundColor: AppColors.violetSoft,
                child: Icon(Icons.group_add_outlined, color: AppColors.violet),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Activation capacity'),
                    const SizedBox(height: 4),
                    Text(
                      controller.appMasterOverview.value == null
                          ? '—'
                          : '${controller.appMasterOverview.value!.activationCapacity} Builders',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.appMasterOverview.value?.serviceStatus ??
                          'Complete setup in Advanced',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Obx(
        () => WalletCard(
          child: Row(
            children: <Widget>[
              const CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Icon(
                  Icons.loyalty_outlined,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Rewards available'),
                    const SizedBox(height: 4),
                    Text(
                      controller.appMasterOverview.value == null
                          ? '—'
                          : '${controller.appMasterOverview.value!.rewardsAvailable} Rewards',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      Obx(
        () => controller.overviewError.value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.overviewError.value,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
      ),
      const SizedBox(height: 18),
      Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (controller.activationRequestReview.value != null) ...<Widget>[
              OutlinedButton.icon(
                onPressed: controller.openActivationReview,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Resume Builder review'),
              ),
              const SizedBox(height: 4),
            ],
            FilledButton.icon(
              onPressed: controller.openActivationScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan activation request'),
            ),
            OutlinedButton.icon(
              onPressed: controller.isImportingActivationRequest.value
                  ? null
                  : controller.importActivationRequest,
              icon: controller.isImportingActivationRequest.value
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              label: Text(
                controller.isImportingActivationRequest.value
                    ? 'Reading QR image…'
                    : 'Import QR image',
              ),
            ),
            if (controller.qrInputError.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.qrInputError.value,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Row(
        children: <Widget>[
          Text('Builder access', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          const WalletStatusBadge(label: '3 Builders'),
        ],
      ),
      const SizedBox(height: 10),
      ...AppMasterController.builders.map(
        (MockBuilderRewards builder) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: WalletCard(
            child: Row(
              children: <Widget>[
                CircleAvatar(child: Text(builder.name.characters.first)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        builder.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        builder.rewardsBalance.replaceAll('BUILDER', 'Rewards'),
                      ),
                    ],
                  ),
                ),
                WalletStatusBadge(
                  label: builder.status,
                  pending: builder.status.startsWith('Pending'),
                ),
              ],
            ),
          ),
        ),
      ),
      const WalletCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.science_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Builder access, balances, and activation results are UI previews. QR scanning and image import are active.',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
