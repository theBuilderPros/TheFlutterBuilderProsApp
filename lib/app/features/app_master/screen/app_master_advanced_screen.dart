import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/app_master/controller/app_master_controller.dart';
import 'package:the_builder_pros/app/features/app_master/widget/app_master_page.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_screen_components.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

class AppMasterAdvancedScreen extends BaseView<AppMasterController> {
  const AppMasterAdvancedScreen({super.key});

  @override
  Widget buildView(BuildContext context) {
    final AppMasterController viewController = controller;
    return AppMasterPage(
      title: 'Advanced',
      subtitle: 'App Master service configuration and support details.',
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
          selected: const <String>{'advanced'},
          onSelectionChanged: (Set<String> selection) {
            if (selection.contains('overview')) {
              viewController.finishActivation();
            } else if (selection.contains('rewards')) {
              viewController.openBuilderWallet();
            }
          },
        ),
        const SizedBox(height: 16),
        WalletCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'NOWNodes configuration',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'App Master only. The Wallet SDK protects this configuration '
                'and provisions it to a Builder during activation.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: viewController.nowNodesEndpoint,
                onChanged: (String value) =>
                    viewController.nowNodesEndpoint = value,
                decoration: const InputDecoration(
                  labelText: 'NOWNodes endpoint',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProviderEnvironment>(
                initialValue: viewController.providerEnvironment.value,
                decoration: const InputDecoration(labelText: 'Environment'),
                items: const <DropdownMenuItem<ProviderEnvironment>>[
                  DropdownMenuItem<ProviderEnvironment>(
                    value: ProviderEnvironment.production,
                    child: Text('Production'),
                  ),
                  DropdownMenuItem<ProviderEnvironment>(
                    value: ProviderEnvironment.test,
                    child: Text('Test'),
                  ),
                ],
                onChanged: viewController.isSavingProviderConfiguration.value
                    ? null
                    : (ProviderEnvironment? value) {
                        if (value != null) {
                          viewController.providerEnvironment.value = value;
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey<int>(
                  viewController.providerKeyFieldRevision.value,
                ),
                onChanged: (String value) =>
                    viewController.nowNodesApiKey = value,
                decoration: const InputDecoration(
                  labelText: 'NOWNodes API key',
                ),
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
              ),
              const SizedBox(height: 14),
              Obx(
                () => WalletStatusBadge(
                  label: _statusLabel(
                    viewController.providerConfigurationStatus.value,
                  ),
                ),
              ),
              Obx(() {
                final String error =
                    viewController.providerConfigurationError.value;
                if (error.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: viewController.isSavingProviderConfiguration.value
                      ? null
                      : viewController.saveProviderConfiguration,
                  icon: viewController.isSavingProviderConfiguration.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.health_and_safety_outlined),
                  label: Text(
                    viewController.isSavingProviderConfiguration.value
                        ? 'Checking settings…'
                        : 'Save and verify settings',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'The API key is checked directly with NOWNodes and retained only '
                'in protected storage after verification.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WalletCard(
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                WalletStatusBadge(
                  label: _statusLabel(
                    viewController.providerConfigurationStatus.value,
                  ),
                ),
                const SizedBox(height: 18),
                WalletReviewRow(
                  label: 'Environment',
                  value: _environmentLabel(
                    viewController
                            .providerConfigurationStatus
                            .value
                            .environment ??
                        viewController.providerEnvironment.value,
                  ),
                ),
                WalletReviewRow(
                  label: 'Configuration version',
                  value:
                      'v${viewController.providerConfigurationStatus.value.version ?? 0}',
                ),
                WalletReviewRow(
                  label: 'Activation capacity',
                  value: viewController.appMasterOverview.value == null
                      ? 'Not refreshed'
                      : '${viewController.appMasterOverview.value!.activationCapacity} Builders',
                ),
                WalletReviewRow(
                  label: 'Rewards available',
                  value: viewController.appMasterOverview.value == null
                      ? 'Not refreshed'
                      : '${viewController.appMasterOverview.value!.rewardsAvailable} Rewards',
                ),
                WalletReviewRow(
                  label: 'Last service check',
                  value: _formatLastChecked(
                    viewController
                        .providerConfigurationStatus
                        .value
                        .lastCheckedAt,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Obx(
          () => WalletCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Distributor account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'App Master only. Import the existing account secret once. '
                  'It will be verified and kept in protected device storage.',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: ValueKey<int>(
                    viewController.distributorSecretFieldRevision.value,
                  ),
                  onChanged: (String value) =>
                      viewController.distributorSecret = value,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Distributor secret key',
                    helperText: 'Entered once and never displayed again',
                  ),
                ),
                const SizedBox(height: 12),
                WalletStatusBadge(
                  label:
                      viewController.distributorAuthorityStatus.value.state ==
                          DistributorAuthorityState.ready
                      ? 'Distributor verified'
                      : 'Distributor not configured',
                ),
                if (viewController
                        .distributorAuthorityStatus
                        .value
                        .maskedAccountId !=
                    null) ...<Widget>[
                  const SizedBox(height: 12),
                  WalletReviewRow(
                    label: 'Account',
                    value: viewController
                        .distributorAuthorityStatus
                        .value
                        .maskedAccountId!,
                  ),
                ],
                if (viewController.distributorAuthorityError.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      viewController.distributorAuthorityError.value,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: viewController.isSavingDistributorAuthority.value
                        ? null
                        : () => _confirmImport(context, viewController),
                    icon: viewController.isSavingDistributorAuthority.value
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.key_outlined),
                    label: Text(
                      viewController.isSavingDistributorAuthority.value
                          ? 'Verifying account…'
                          : 'Import and verify account',
                    ),
                  ),
                ),
                if (viewController.distributorAuthorityStatus.value.state ==
                    DistributorAuthorityState.ready)
                  TextButton.icon(
                    onPressed: () => _confirmRemoval(context, viewController),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove distributor account'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Builder diagnostics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ...AppMasterController.builders.map(
          (MockBuilderRewards builder) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WalletCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    builder.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  WalletReviewRow(
                    label: 'Access status',
                    value: builder.status,
                  ),
                  WalletReviewRow(
                    label: 'Rewards balance',
                    value: builder.rewardsBalance,
                  ),
                  WalletReviewRow(
                    label: 'Last checked',
                    value: builder.lastChecked,
                  ),
                ],
              ),
            ),
          ),
        ),
        const WalletBoundaryNotice(
          icon: Icons.admin_panel_settings_outlined,
          text:
              'The API key is masked here. The Wallet SDK validates it, '
              'stores it securely, and will include it only in an encrypted, '
              'device-bound activation payload.',
        ),
      ],
    );
  }

  static String _statusLabel(ProviderConfigurationStatus status) =>
      switch (status.state) {
        ProviderConfigurationState.notConfigured => 'Not configured',
        ProviderConfigurationState.pendingVerification =>
          'Verification pending',
        ProviderConfigurationState.ready =>
          'Configuration v${status.version} ready',
      };

  static String _environmentLabel(ProviderEnvironment environment) =>
      switch (environment) {
        ProviderEnvironment.test => 'Test',
        ProviderEnvironment.production => 'Production',
      };

  static String _formatLastChecked(DateTime? value) {
    if (value == null) {
      return 'Not checked';
    }
    final DateTime local = value.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  static Future<void> _confirmImport(
    BuildContext context,
    AppMasterController controller,
  ) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Import distributor account?'),
            content: const Text(
              'Anyone with this secret controls the distributor account. '
              'Continue only on the App Master device.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import securely'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await controller.importDistributorAuthority();
    }
  }

  static Future<void> _confirmRemoval(
    BuildContext context,
    AppMasterController controller,
  ) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Remove distributor account?'),
            content: const Text(
              'New Builder activations will stop until an account is imported again.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep account'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove account'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await controller.removeDistributorAuthority();
    }
  }
}
