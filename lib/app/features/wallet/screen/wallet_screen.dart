import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:the_builder_studio/app/constant/resources/app_colors.dart';
import 'package:the_builder_studio/app/constant/resources/app_string.dart';
import 'package:the_builder_studio/app/core/base/base_view.dart';
import 'package:the_builder_studio/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_studio/app/features/wallet/utility/wallet_ui_metrics.dart';

class WalletScreen extends BaseView<WalletController> {
  const WalletScreen({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _WalletHeader(controller: controller),
            const SizedBox(height: 24),
            _BalanceCard(controller: controller),
            const SizedBox(height: 18),
            _WalletModeSwitch(controller: controller),
            const SizedBox(height: 18),
            _WalletBody(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Rewards',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              onPressed: () => _showWalletMenu(context),
              icon: const Icon(Icons.more_horiz),
              tooltip: AppString.walletMenuTitle,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Send and receive Builder rewards.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .32,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.accent,
                    AppColors.violet,
                  ],
                  stops: [0, .76, .76],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showWalletMenu(BuildContext context) {
    Get.bottomSheet<void>(
      SafeArea(
        child: Material(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(WalletRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(WalletSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text(AppString.walletHistoryTitle),
                  onTap: () {
                    Get.back<void>();
                    controller.openHistory();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_2_outlined),
                  title: const Text(AppString.walletReceiveTitle),
                  onTap: () {
                    Get.back<void>();
                    controller.openReceive();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner_outlined),
                  title: const Text(AppString.walletSendTitle),
                  onTap: () {
                    Get.back<void>();
                    controller.openSendScan();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final formattedBalance =
          double.tryParse(
            controller.currentBalance.value,
          )?.toStringAsFixed(2) ??
          controller.currentBalance.value;

      return _RewardsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _Label('Your Balance'),
                const Spacer(),
                IconButton(
                  onPressed: controller.refreshWalletBalance,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: AppString.walletRefreshBalance,
                ),
              ],
            ),
            Text(
              '$formattedBalance pts',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      );
    });
  }
}

class _WalletModeSwitch extends StatelessWidget {
  const _WalletModeSwitch({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SegmentedButton<int>(
        segments: const [
          ButtonSegment(
            value: 0,
            label: Text(AppString.walletReceiveTitle),
            icon: Icon(Icons.qr_code_2),
          ),
          ButtonSegment(
            value: 1,
            label: Text(AppString.walletSendTitle),
            icon: Icon(Icons.send_outlined),
          ),
        ],
        selected: {controller.rewardsMode.value},
        onSelectionChanged: (value) =>
            controller.rewardsMode.value = value.first,
        showSelectedIcon: false,
      ),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.walletState.value) {
        case WalletState.loading:
          return const _StatusPanel(
            message: AppString.walletLoadingConfigMessage,
          );
        case WalletState.configMissing:
        case WalletState.error:
          return _StatusPanel(message: controller.message.value);
        case WalletState.ready:
          return _ActivationPanel(controller: controller);
        case WalletState.activated:
          return controller.rewardsMode.value == 0
              ? _ReceivePanel(controller: controller)
              : _SendPanel(controller: controller);
      }
    });
  }
}

class _ActivationPanel extends StatelessWidget {
  const _ActivationPanel({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return _RewardsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(AppString.walletStatusTitle),
          const SizedBox(height: 10),
          const Text(AppString.walletReadyToActivateMessage),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.activateWallet,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text(AppString.walletActivateButton),
          ),
        ],
      ),
    );
  }
}

class _ReceivePanel extends StatelessWidget {
  const _ReceivePanel({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final access = controller.walletAccess.value;
      final publicKey = access?.publicKey ?? '';

      return Column(
        children: [
          _RewardsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Receive via QR'),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 184,
                    height: 184,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFC49E)),
                    ),
                    child: publicKey.isEmpty
                        ? const Icon(
                            Icons.qr_code_2,
                            size: 110,
                            color: AppColors.accent,
                          )
                        : QrImageView(
                            data: publicKey,
                            version: QrVersions.auto,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.accent,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.accent,
                            ),
                            backgroundColor: AppColors.accentSoft,
                            gapless: false,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Show this to another Builder to receive points.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _RewardsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Your Reward ID'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _shortRewardId(publicKey),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        onPressed: publicKey.isEmpty
                            ? null
                            : controller.copyPublicKey,
                        icon: const Icon(Icons.copy, color: AppColors.violet),
                        tooltip: AppString.walletCopyPublicKey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  String _shortRewardId(String value) {
    if (value.isEmpty) {
      return 'Activate wallet first';
    }
    if (value.length <= 14) {
      return value;
    }
    return '${value.substring(0, 7)}-${value.substring(value.length - 6)}';
  }
}

class _SendPanel extends StatelessWidget {
  const _SendPanel({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RewardsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Send Rewards'),
              const SizedBox(height: 10),
              Text(
                'Scan another Builder reward QR to prepare a transfer.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.openSendScan,
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  label: const Text('Scan recipient QR'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RewardsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label(AppString.walletHistoryTitle),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: controller.openHistory,
                icon: const Icon(Icons.history_outlined),
                label: const Text('View reward history'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _RewardsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(AppString.walletStatusTitle),
          const SizedBox(height: 10),
          Text(message),
        ],
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }
}
