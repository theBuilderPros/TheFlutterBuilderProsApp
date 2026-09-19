import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/default_wallet_sdk.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/configuration_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/configuration_metadata_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/horizon_health_client.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'health-checks and promotes a provider candidate to ready status',
    () async {
      final DefaultWalletSdk sdk = DefaultWalletSdk(
        horizonHealthClient: _SuccessfulHealthClient(),
      );

      final ProviderConfigurationOutcome outcome = await sdk
          .saveAppMasterProviderConfiguration(
            const ProviderConfigurationInput(
              endpoint: 'https://xlm.nownodes.io',
              apiKey: 'private-test-key',
              environment: ProviderEnvironment.test,
              version: 1,
            ),
          );

      expect(outcome.status.state, ProviderConfigurationState.ready);
      expect(outcome.status.environment, ProviderEnvironment.test);
      expect(outcome.status.version, 1);
      expect(outcome.status.endpointHost, 'xlm.nownodes.io');

      final ProviderConfigurationStatus restored = await DefaultWalletSdk(
        horizonHealthClient: _SuccessfulHealthClient(),
      ).getProviderConfigurationStatus();
      expect(restored.state, ProviderConfigurationState.ready);
      expect(restored.version, 1);

      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      expect(preferences.getKeys(), isNotEmpty);
      expect(
        preferences.getKeys().map(preferences.get).join(),
        isNot(contains('private-test-key')),
      );
      final Map<String, String> protected = await const FlutterSecureStorage()
          .readAll();
      expect(protected.values.join(), contains('private-test-key'));
    },
  );

  test('rejects invalid provider inputs without storing credentials', () async {
    final DefaultWalletSdk sdk = DefaultWalletSdk();
    const List<ProviderConfigurationInput> invalid =
        <ProviderConfigurationInput>[
          ProviderConfigurationInput(
            endpoint: 'http://xlm.nownodes.io',
            apiKey: 'key',
            environment: ProviderEnvironment.test,
            version: 1,
          ),
          ProviderConfigurationInput(
            endpoint: 'https://example.com',
            apiKey: 'key',
            environment: ProviderEnvironment.test,
            version: 1,
          ),
          ProviderConfigurationInput(
            endpoint: 'https://xlm.nownodes.io?key=leak',
            apiKey: 'key',
            environment: ProviderEnvironment.test,
            version: 1,
          ),
          ProviderConfigurationInput(
            endpoint: 'https://xlm.nownodes.io',
            apiKey: '',
            environment: ProviderEnvironment.test,
            version: 1,
          ),
          ProviderConfigurationInput(
            endpoint: 'https://xlm.nownodes.io',
            apiKey: 'key',
            environment: ProviderEnvironment.test,
            version: 0,
          ),
        ];

    for (final ProviderConfigurationInput input in invalid) {
      await expectLater(
        sdk.saveAppMasterProviderConfiguration(input),
        throwsA(
          isA<WalletSdkException>().having(
            (WalletSdkException error) => error.code,
            'code',
            WalletSdkFailureCode.invalidProviderConfiguration,
          ),
        ),
      );
    }

    expect(await const FlutterSecureStorage().readAll(), isEmpty);
    expect(
      (await sdk.getProviderConfigurationStatus()).state,
      ProviderConfigurationState.notConfigured,
    );
  });

  test('maps protected-store failure without exposing the API key', () async {
    final DefaultWalletSdk sdk = DefaultWalletSdk(
      configurationStore: _FailingConfigurationStore(),
      horizonHealthClient: _SuccessfulHealthClient(),
    );

    await expectLater(
      sdk.saveAppMasterProviderConfiguration(
        const ProviderConfigurationInput(
          endpoint: 'https://xlm.nownodes.io',
          apiKey: 'must-not-escape',
          environment: ProviderEnvironment.production,
          version: 2,
        ),
      ),
      throwsA(
        isA<WalletSdkException>()
            .having(
              (WalletSdkException error) => error.code,
              'code',
              WalletSdkFailureCode.providerConfigurationSaveFailed,
            )
            .having(
              (WalletSdkException error) => error.safeMessage,
              'safeMessage',
              isNot(contains('must-not-escape')),
            ),
      ),
    );
  });

  test(
    'rolls back protected candidate when metadata persistence fails',
    () async {
      final ProtectedConfigurationStore store = ProtectedConfigurationStore(
        metadataStore: _FailingMetadataStore(),
      );

      await expectLater(
        store.savePending(
          ProviderConfiguration(
            endpoint: Uri.parse('https://xlm.nownodes.io'),
            apiKey: 'rollback-key',
            environment: ProviderEnvironment.test,
            version: 1,
          ),
        ),
        throwsStateError,
      );

      expect(await const FlutterSecureStorage().readAll(), isEmpty);
      expect(
        (await store.readStatus()).state,
        ProviderConfigurationState.notConfigured,
      );
    },
  );

  test('clears pending protected configuration and safe metadata', () async {
    final ProtectedConfigurationStore store = ProtectedConfigurationStore();
    await store.savePending(
      ProviderConfiguration(
        endpoint: Uri.parse('https://xlm.nownodes.io'),
        apiKey: 'temporary-key',
        environment: ProviderEnvironment.test,
        version: 1,
      ),
    );

    await store.discardPending();

    expect(await const FlutterSecureStorage().readAll(), isEmpty);
    expect(
      (await store.readStatus()).state,
      ProviderConfigurationState.notConfigured,
    );
  });

  test('health failure preserves the previous active configuration', () async {
    final _ControllableHealthClient healthClient = _ControllableHealthClient();
    final DefaultWalletSdk sdk = DefaultWalletSdk(
      horizonHealthClient: healthClient,
    );
    await sdk.saveAppMasterProviderConfiguration(
      const ProviderConfigurationInput(
        endpoint: 'https://xlm.nownodes.io',
        apiKey: 'working-key',
        environment: ProviderEnvironment.test,
        version: 1,
      ),
    );
    healthClient.shouldFail = true;

    await expectLater(
      sdk.saveAppMasterProviderConfiguration(
        const ProviderConfigurationInput(
          endpoint: 'https://xlm.nownodes.io',
          apiKey: 'rejected-key',
          environment: ProviderEnvironment.test,
          version: 2,
        ),
      ),
      throwsA(
        isA<WalletSdkException>().having(
          (WalletSdkException error) => error.code,
          'code',
          WalletSdkFailureCode.providerUnauthorized,
        ),
      ),
    );

    final ProviderConfigurationStatus status = await sdk
        .getProviderConfigurationStatus();
    expect(status.state, ProviderConfigurationState.ready);
    expect(status.version, 1);
    final Map<String, String> protected = await const FlutterSecureStorage()
        .readAll();
    expect(protected.values.join(), contains('working-key'));
    expect(protected.values.join(), isNot(contains('rejected-key')));
  });
}

final class _FailingConfigurationStore implements ConfigurationStore {
  @override
  Future<void> discardPending() async {}

  @override
  Future<void> promotePending(DateTime checkedAt) async {}

  @override
  Future<ProviderConfiguration?> readActive() async => null;

  @override
  Future<ProviderConfiguration?> readPending() async => null;

  @override
  Future<ProviderConfigurationStatus> readStatus() async =>
      const ProviderConfigurationStatus.notConfigured();

  @override
  Future<void> savePending(ProviderConfiguration configuration) async {
    throw StateError('Simulated protected-store failure.');
  }
}

final class _SuccessfulHealthClient implements HorizonHealthClient {
  @override
  Future<void> check(ProviderConfiguration configuration) async {}
}

final class _ControllableHealthClient implements HorizonHealthClient {
  bool shouldFail = false;

  @override
  Future<void> check(ProviderConfiguration configuration) async {
    if (shouldFail) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.providerUnauthorized,
        safeMessage: 'The NOWNodes API key was not accepted.',
        canRetry: true,
      );
    }
  }
}

final class _FailingMetadataStore implements ConfigurationMetadataStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async {
    throw StateError('Simulated metadata failure.');
  }
}
