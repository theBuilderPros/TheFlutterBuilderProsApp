import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_screen_components.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class WalletAuthenticationScreen extends BaseView<WalletController> {
  const WalletAuthenticationScreen({super.key});
  @override
  Widget buildView(BuildContext context) {
    final Object? arguments = Get.arguments;
    final String purpose = arguments is Map
        ? arguments['purpose'] as String? ?? 'Authorize protected action'
        : 'Authorize protected action';
    return WalletPage(
      title: 'Confirm Action',
      subtitle: purpose,
      children: <Widget>[
        const WalletStepIndicator(current: 2, total: 2, label: 'Authorization'),
        const SizedBox(height: 16),
        WalletCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(Icons.fingerprint, size: 66),
              const SizedBox(height: 14),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mock Rewards passcode',
                  hintText: 'Enter any value for this UI preview',
                  prefixIcon: Icon(Icons.password_outlined),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: controller.completeAuthentication,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Authorize preview'),
              ),
              TextButton(onPressed: Get.back, child: const Text('Cancel')),
            ],
          ),
        ),
      ],
    );
  }
}
