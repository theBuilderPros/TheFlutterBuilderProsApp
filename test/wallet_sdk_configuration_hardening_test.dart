import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/configuration_handshake_service.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/configuration_handshake_store.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 9, 19, 12);
  final ConfigurationHandshakeService service = ConfigurationHandshakeService();
  late SimpleKeyPair deviceKey;
  late DecodedConfigurationRequest request;
  late String update;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    deviceKey = await X25519().newKeyPair();
    final SimplePublicKey devicePublicKey = await deviceKey.extractPublicKey();
    final String requestQr = await service.createRequest(
      requestId: 'CFG-TEST-01',
      deviceId: _b64(List<int>.generate(16, (int i) => i)),
      devicePublicKey: _b64(devicePublicKey.bytes),
      currentVersion: 1,
      environment: ProviderEnvironment.test,
      challenge: _b64(List<int>.filled(24, 7)),
      now: now,
    );
    request = await service.inspectRequest(requestQr, now);
    const StrKeyCodec codec = StrKeyCodec();
    final List<int> seed = List<int>.filled(32, 4);
    final SimpleKeyPair signer = await Ed25519().newKeyPairFromSeed(seed);
    final SimplePublicKey signerPublic = await signer.extractPublicKey();
    update = await service.createUpdate(
      updateId: 'UPD-TEST-01',
      request: request,
      configuration: ProviderConfiguration(
        endpoint: Uri.parse('https://xlm.nownodes.io'),
        apiKey: 'private-test-key',
        environment: ProviderEnvironment.test,
        version: 2,
      ),
      signingSecret: codec.encodeEd25519SecretSeed(seed),
      signerAccount: codec.encodeEd25519PublicKey(signerPublic.bytes),
      now: now,
    );
  });

  test('accepts only a signed update bound to the intended device', () async {
    final InspectedConfigurationUpdate inspected = await service.inspectUpdate(
      encoded: update,
      request: request,
      deviceKeyPair: deviceKey,
      installedVersion: 1,
      now: now,
    );
    expect(inspected.review.version, 2);
    expect(inspected.configuration.apiKey, 'private-test-key');
    expect(update, isNot(contains('private-test-key')));

    await expectLater(
      service.inspectUpdate(
        encoded: update,
        request: request,
        deviceKeyPair: await X25519().newKeyPair(),
        installedVersion: 1,
        now: now,
      ),
      throwsA(anything),
    );
  });

  test('rejects tamper, expiry, downgrade, and replay', () async {
    final Map<String, dynamic> altered =
        jsonDecode(update) as Map<String, dynamic>;
    altered['update_id'] = 'UPD-TAMPERED';
    await expectLater(
      service.inspectUpdate(
        encoded: jsonEncode(altered),
        request: request,
        deviceKeyPair: deviceKey,
        installedVersion: 1,
        now: now,
      ),
      throwsFormatException,
    );
    await expectLater(
      service.inspectUpdate(
        encoded: update,
        request: request,
        deviceKeyPair: deviceKey,
        installedVersion: 1,
        now: now.add(const Duration(minutes: 11)),
      ),
      throwsA(isA<ExpiredConfigurationUpdateException>()),
    );
    await expectLater(
      service.inspectUpdate(
        encoded: update,
        request: request,
        deviceKeyPair: deviceKey,
        installedVersion: 2,
        now: now,
      ),
      throwsFormatException,
    );
    final ConfigurationHandshakeStore store = ConfigurationHandshakeStore();
    await store.markConsumed('UPD-TEST-01');
    expect(await store.isConsumed('UPD-TEST-01'), isTrue);
  });
}

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
