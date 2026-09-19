import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_builder_pros/wallet_sdk/src/authority/distributor_authority_service.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/wallet_key_generator.dart';
import 'package:the_builder_pros/wallet_sdk/src/default_wallet_sdk.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/configuration_store.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  test(
    'imports, verifies, masks, restores, and removes distributor secret',
    () async {
      final WalletKeyPair keyPair = await WalletKeyGenerator(
        random: Random(91),
      ).generate();
      final _MemoryAuthorityStore authorityStore = _MemoryAuthorityStore();
      final _Verifier verifier = _Verifier();
      final DistributorAuthorityService authorityService =
          DistributorAuthorityService(
            store: authorityStore,
            verifier: verifier,
          );
      final DefaultWalletSdk sdk = DefaultWalletSdk(
        now: () => DateTime.utc(2026, 9, 19, 15),
        configurationStore: _ActiveConfigurationStore(_configuration),
        distributorAuthorityService: authorityService,
      );

      final DistributorAuthorityStatus imported = await sdk
          .importDistributorSecret(keyPair.secretSeed);

      expect(verifier.accountId, keyPair.accountId);
      expect(authorityStore.secret, keyPair.secretSeed);
      expect(imported.state, DistributorAuthorityState.ready);
      expect(
        imported.maskedAccountId,
        startsWith(keyPair.accountId.substring(0, 6)),
      );
      expect(
        imported.maskedAccountId,
        endsWith(keyPair.accountId.substring(50)),
      );
      expect(imported.maskedAccountId, isNot(contains(keyPair.secretSeed)));
      expect(
        (await sdk.getDistributorAuthorityStatus()).maskedAccountId,
        imported.maskedAccountId,
      );

      await sdk.removeDistributorAuthority();
      expect(authorityStore.secret, isNull);
      expect(
        (await sdk.getDistributorAuthorityStatus()).state,
        DistributorAuthorityState.notConfigured,
      );
    },
  );

  test('rejects invalid secrets and requires provider configuration', () async {
    final DefaultWalletSdk withoutProvider = DefaultWalletSdk(
      configurationStore: _ActiveConfigurationStore(null),
      distributorAuthorityService: DistributorAuthorityService(
        store: _MemoryAuthorityStore(),
        verifier: _Verifier(),
      ),
    );
    await expectLater(
      withoutProvider.importDistributorSecret('not-a-secret'),
      throwsA(
        isA<WalletSdkException>().having(
          (WalletSdkException error) => error.code,
          'code',
          WalletSdkFailureCode.providerConfigurationRequired,
        ),
      ),
    );

    final DefaultWalletSdk invalidSecret = DefaultWalletSdk(
      configurationStore: _ActiveConfigurationStore(_configuration),
      distributorAuthorityService: DistributorAuthorityService(
        store: _MemoryAuthorityStore(),
        verifier: _Verifier(),
      ),
    );
    await expectLater(
      invalidSecret.importDistributorSecret('not-a-secret'),
      throwsA(
        isA<WalletSdkException>().having(
          (WalletSdkException error) => error.code,
          'code',
          WalletSdkFailureCode.invalidDistributorSecret,
        ),
      ),
    );
  });

  test(
    'does not replace the protected secret when verification fails',
    () async {
      final WalletKeyPair keyPair = await WalletKeyGenerator(
        random: Random(92),
      ).generate();
      final _MemoryAuthorityStore store = _MemoryAuthorityStore()
        ..secret = 'previous-protected-secret';
      final DefaultWalletSdk sdk = DefaultWalletSdk(
        configurationStore: _ActiveConfigurationStore(_configuration),
        distributorAuthorityService: DistributorAuthorityService(
          store: store,
          verifier: _Verifier(fail: true),
        ),
      );

      await expectLater(
        sdk.importDistributorSecret(keyPair.secretSeed),
        throwsA(isA<WalletSdkException>()),
      );
      expect(store.secret, 'previous-protected-secret');
    },
  );
}

final ProviderConfiguration _configuration = ProviderConfiguration(
  endpoint: Uri.parse('https://xlm.nownodes.io'),
  apiKey: 'protected-test-key',
  environment: ProviderEnvironment.test,
  version: 1,
);
final class _MemoryAuthorityStore implements DistributorAuthorityStore {
  String? secret;

  @override
  Future<void> clear() async => secret = null;

  @override
  Future<String?> readSecret() async => secret;

  @override
  Future<void> writeSecret(String value) async => secret = value;
}

final class _Verifier implements DistributorAccountVerifier {
  _Verifier({this.fail = false});

  final bool fail;
  String? accountId;

  @override
  Future<void> verify({
    required ProviderConfiguration configuration,
    required String accountId,
  }) async {
    this.accountId = accountId;
    if (fail) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.distributorAccountUnavailable,
        safeMessage: 'The distributor account could not be verified.',
        canRetry: true,
      );
    }
  }
}

final class _ActiveConfigurationStore implements ConfigurationStore {
  _ActiveConfigurationStore(this.active);

  final ProviderConfiguration? active;

  @override
  Future<void> discardPending() async {}

  @override
  Future<void> promotePending(DateTime checkedAt) async {}

  @override
  Future<ProviderConfiguration?> readActive() async => active;

  @override
  Future<ProviderConfiguration?> readPending() async => null;

  @override
  Future<ProviderConfigurationStatus> readStatus() async =>
      const ProviderConfigurationStatus.notConfigured();

  @override
  Future<void> savePending(ProviderConfiguration configuration) async {}
}
