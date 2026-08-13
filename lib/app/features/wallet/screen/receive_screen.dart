import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_studio/app/constant/resources/app_string.dart';
import 'package:the_builder_studio/app/core/base/base_view.dart';
import 'package:the_builder_studio/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_studio/app/features/wallet/utility/wallet_ui_metrics.dart';
import 'package:the_builder_studio/app/widget/section_card.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletReceiveScreen extends BaseView<WalletController> {
  const WalletReceiveScreen({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppString.walletReceiveTitle)),
      body: SafeArea(
        child: Obx(() {
          final access = controller.walletAccess.value;

          return ListView(
            padding: const EdgeInsets.all(WalletSpacing.lg),
            children: [
              SectionCard(
                title: AppString.walletPublicKeyLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (access != null) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(WalletSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              WalletRadius.md,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: QrImageView(
                            data: access.publicKey,
                            version: QrVersions.auto,
                            size: 190,
                            backgroundColor: Colors.white,
                            gapless: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: WalletSpacing.sm),
                    ],
                    SelectableText(
                      access?.publicKey ?? AppString.walletActivateFirstMessage,
                    ),
                    const SizedBox(height: WalletSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: access == null
                          ? null
                          : controller.copyPublicKey,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text(AppString.walletCopyPublicKey),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
