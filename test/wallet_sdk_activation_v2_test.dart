import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_builder_pros/wallet_sdk/src/default_wallet_sdk.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/qr/activation_qr_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/activation_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/credential_store.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 9, 19, 10);

  test('v2 canonical encoding is deterministic and validates', () async {
    final ActivationQrCodec codec = ActivationQrCodec();
    Future<String> encode() => codec.encodeRequest(
      requestId: 'ACT-ABCD-EF',
      challenge: '123456789012345678901234',
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
      builder: const BuilderIdentity(
        displayName: 'Jordan Rivers',
        phone: '+959123456789',
      ),
      activationAddress: _activationAddress(),
      deviceId: _encodedBytes(16, 1),
      devicePublicKey: _encodedBytes(32, 2),
    );

    final String first = await encode();
    final String second = await encode();
    expect(second, first);

    final DecodedActivationRequest decoded = await codec.decodeAndValidate(
      first,
      now: now,
    );
    expect(decoded.requestId, 'ACT-ABCD-EF');
    expect(decoded.deviceId, _encodedBytes(16, 1));
    expect(decoded.devicePublicKey, _encodedBytes(32, 2));
  });

  test(
    'v2 decoder rejects malformed, oversized, unsupported, expired, and altered requests',
    () async {
      final ActivationQrCodec codec = ActivationQrCodec();
      final String valid = await codec.encodeRequest(
        requestId: 'ACT-ABCD-EF',
        challenge: '123456789012345678901234',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        builder: const BuilderIdentity(
          displayName: 'Jordan Rivers',
          phone: '+959123456789',
        ),
        activationAddress: _activationAddress(),
        deviceId: _encodedBytes(16, 1),
        devicePublicKey: _encodedBytes(32, 2),
      );
      final Map<String, dynamic> unsupported =
          jsonDecode(valid) as Map<String, dynamic>;
      (unsupported['payload'] as Map<String, dynamic>)['version'] = 1;
      final Map<String, dynamic> altered =
          jsonDecode(valid) as Map<String, dynamic>;
      ((altered['payload'] as Map<String, dynamic>)['builder']
              as Map<String, dynamic>)['name'] =
          'Altered';

      for (final ({String value, DateTime at}) item
          in <({String value, DateTime at})>[
            (value: '{bad', at: now),
            (value: List<String>.filled(5000, 'x').join(), at: now),
            (value: jsonEncode(unsupported), at: now),
            (value: valid, at: now.add(const Duration(minutes: 16))),
            (value: jsonEncode(altered), at: now),
          ]) {
        await expectLater(
          codec.decodeAndValidate(item.value, now: item.at),
          throwsFormatException,
        );
      }
    },
  );

  test('restored and replacement requests retain one device binding', () async {
    final _MemoryCredentialStore credentials = _MemoryCredentialStore();
    final _MemoryActivationStore records = _MemoryActivationStore();
    final DefaultWalletSdk sdk = DefaultWalletSdk(
      now: () => now,
      random: Random(33),
      credentialStore: credentials,
      activationStore: records,
    );
    const BuilderIdentity builder = BuilderIdentity(
      displayName: 'Jordan Rivers',
      phone: '+959123456789',
    );

    final ActivationRequestView first = await sdk.startActivation(builder);
    final Map<String, dynamic> firstPayload = _payload(first.qrValue);
    final String privateValue = credentials.values.entries
        .singleWhere((entry) => entry.key.contains('configuration.private'))
        .value;
    expect(first.qrValue, isNot(contains(privateValue)));

    final ActivationRequestView? restored = await sdk
        .restoreActivationRequest();
    expect(restored?.qrValue, first.qrValue);

    await sdk.cancelActivation();
    final ActivationRequestView replacement = await sdk.startActivation(
      builder,
    );
    final Map<String, dynamic> replacementPayload = _payload(
      replacement.qrValue,
    );
    expect(replacementPayload['device_id'], firstPayload['device_id']);
    expect(
      replacementPayload['device_configuration_public_key'],
      firstPayload['device_configuration_public_key'],
    );
  });

  test('legacy v1 pending request is safely invalidated', () async {
    final _MemoryCredentialStore credentials = _MemoryCredentialStore()
      ..values['legacy-secret'] = 'protected';
    final _MemoryActivationStore records = _MemoryActivationStore()
      ..record = PendingActivationRecord(
        requestId: 'ACT-OLD-01',
        qrValue: jsonEncode(<String, Object>{
          'type': 'rewards_activation_request',
          'version': 1,
        }),
        expiresAt: now.add(const Duration(minutes: 10)),
        credentialKey: 'legacy-secret',
        builderName: 'Legacy Builder',
        builderPhone: '+959123456789',
      );
    final DefaultWalletSdk sdk = DefaultWalletSdk(
      now: () => now,
      random: Random(44),
      credentialStore: credentials,
      activationStore: records,
    );

    expect(await sdk.restoreActivationRequest(), isNull);
    expect(records.record, isNull);
    expect(credentials.values.containsKey('legacy-secret'), isFalse);
  });
}

Map<String, dynamic> _payload(String qrValue) {
  final Map<String, dynamic> envelope =
      jsonDecode(qrValue) as Map<String, dynamic>;
  return envelope['payload'] as Map<String, dynamic>;
}

String _encodedBytes(int length, int value) =>
    base64Url.encode(List<int>.filled(length, value)).replaceAll('=', '');

String _activationAddress() =>
    const StrKeyCodec().encodeEd25519PublicKey(List<int>.filled(32, 3));

final class _MemoryCredentialStore implements CredentialStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<bool> contains(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

final class _MemoryActivationStore implements ActivationStore {
  PendingActivationRecord? record;

  @override
  Future<void> clear() async => record = null;

  @override
  Future<PendingActivationRecord?> read() async => record;

  @override
  Future<void> write(PendingActivationRecord value) async => record = value;
}
