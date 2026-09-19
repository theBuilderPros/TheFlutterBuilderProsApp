import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_builder_pros/wallet_sdk/src/default_wallet_sdk.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/activation_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/credential_store.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('creates, restores, and cancels an activation request', () async {
    final DateTime now = DateTime.utc(2026, 9, 18, 10);
    final DefaultWalletSdk sdk = DefaultWalletSdk(
      now: () => now,
      random: Random(42),
    );

    final ActivationRequestView created = await sdk.startActivation(
      const BuilderIdentity(
        displayName: 'Jordan Rivers',
        phone: '+959123456789',
      ),
    );

    expect(created.requestId, startsWith('ACT-'));
    expect(created.expiresAt, now.add(const Duration(minutes: 15)));
    expect(created.builder.displayName, 'Jordan Rivers');

    final Map<String, dynamic> envelope =
        jsonDecode(created.qrValue) as Map<String, dynamic>;
    final Map<String, dynamic> qr = envelope['payload'] as Map<String, dynamic>;
    expect(qr['type'], 'rewards_activation_request');
    expect(qr['version'], 2);
    expect(qr['request_id'], created.requestId);
    expect(qr['device_id'], isNotEmpty);
    expect(qr['device_configuration_public_key'], isNotEmpty);
    expect(
      const StrKeyCodec().isValidEd25519PublicKey(
        qr['activation_address'] as String,
      ),
      isTrue,
    );
    expect(created.qrValue.toLowerCase(), isNot(contains('secret')));

    final ActivationRequestView? restored = await sdk
        .restoreActivationRequest();
    expect(restored?.requestId, created.requestId);
    expect(restored?.qrValue, created.qrValue);

    await sdk.cancelActivation();
    expect(await sdk.restoreActivationRequest(), isNull);
  });

  test('rejects invalid Builder details without creating a request', () async {
    final DefaultWalletSdk sdk = DefaultWalletSdk(random: Random(7));

    expect(
      () => sdk.startActivation(
        const BuilderIdentity(displayName: '', phone: '123'),
      ),
      throwsA(
        isA<WalletSdkException>().having(
          (WalletSdkException error) => error.code,
          'code',
          WalletSdkFailureCode.invalidBuilder,
        ),
      ),
    );
  });

  test('removes an expired request and its protected credential', () async {
    DateTime now = DateTime.utc(2026, 9, 18, 10);
    final _MemoryCredentialStore credentials = _MemoryCredentialStore();
    final DefaultWalletSdk sdk = DefaultWalletSdk(
      now: () => now,
      random: Random(8),
      credentialStore: credentials,
    );

    await sdk.startActivation(
      const BuilderIdentity(displayName: 'Maya Chen', phone: '+959111111111'),
    );
    expect(
      credentials.values.keys.where(
        (String key) => key.startsWith('rewards.activation.secret.'),
      ),
      hasLength(1),
    );

    now = now.add(const Duration(minutes: 16));

    expect(await sdk.restoreActivationRequest(), isNull);
    expect(
      credentials.values.keys.where(
        (String key) => key.startsWith('rewards.activation.secret.'),
      ),
      isEmpty,
    );
  });

  test('rolls back the protected credential when persistence fails', () async {
    final _MemoryCredentialStore credentials = _MemoryCredentialStore();
    final DefaultWalletSdk sdk = DefaultWalletSdk(
      random: Random(9),
      activationStore: _FailingActivationStore(),
      credentialStore: credentials,
    );

    await expectLater(
      sdk.startActivation(
        const BuilderIdentity(
          displayName: 'Noah Williams',
          phone: '+959222222222',
        ),
      ),
      throwsA(
        isA<WalletSdkException>().having(
          (WalletSdkException error) => error.code,
          'code',
          WalletSdkFailureCode.requestCreationFailed,
        ),
      ),
    );
    expect(
      credentials.values.keys.where(
        (String key) => key.startsWith('rewards.activation.secret.'),
      ),
      isEmpty,
    );
  });

  test('maps activation cleanup failure to a safe retryable error', () async {
    final _MemoryCredentialStore credentials = _MemoryCredentialStore();
    final DefaultWalletSdk sdk = DefaultWalletSdk(
      random: Random(10),
      credentialStore: credentials,
    );
    await sdk.startActivation(
      const BuilderIdentity(displayName: 'Ava Smith', phone: '+959333333333'),
    );
    credentials.failDelete = true;

    await expectLater(
      sdk.cancelActivation(),
      throwsA(
        isA<WalletSdkException>()
            .having(
              (WalletSdkException error) => error.code,
              'code',
              WalletSdkFailureCode.cancellationFailed,
            )
            .having(
              (WalletSdkException error) => error.canRetry,
              'canRetry',
              isTrue,
            ),
      ),
    );
    expect(await sdk.restoreActivationRequest(), isNotNull);
  });
}

final class _MemoryCredentialStore implements CredentialStore {
  final Map<String, String> values = <String, String>{};
  bool failDelete = false;

  @override
  Future<bool> contains(String key) async => values.containsKey(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> delete(String key) async {
    if (failDelete) {
      throw StateError('Simulated protected deletion failure.');
    }
    values.remove(key);
  }

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

final class _FailingActivationStore implements ActivationStore {
  @override
  Future<void> clear() async {}

  @override
  Future<PendingActivationRecord?> read() async => null;

  @override
  Future<void> write(PendingActivationRecord record) async {
    throw StateError('Simulated persistence failure.');
  }
}
