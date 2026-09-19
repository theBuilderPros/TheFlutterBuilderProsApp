import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/credential_store.dart';

final class DeviceConfigurationIdentity {
  const DeviceConfigurationIdentity({
    required this.deviceId,
    required this.publicKey,
  });

  final String deviceId;
  final String publicKey;
}

final class DeviceConfigurationIdentityService {
  DeviceConfigurationIdentityService({
    required CredentialStore credentialStore,
    Random? random,
    X25519? algorithm,
  }) : _credentialStore = credentialStore,
       _random = random ?? Random.secure(),
       _algorithm = algorithm ?? X25519();

  static const String _privateKey = 'rewards.device.configuration.private.v1';
  static const String _publicKey = 'rewards.device.configuration.public.v1';
  static const String _deviceIdKey = 'rewards.device.configuration.id.v1';

  final CredentialStore _credentialStore;
  final Random _random;
  final X25519 _algorithm;

  Future<DeviceConfigurationIdentity> getOrCreate() async {
    final String? storedPrivate = await _credentialStore.read(_privateKey);
    final String? storedPublic = await _credentialStore.read(_publicKey);
    final String? storedDeviceId = await _credentialStore.read(_deviceIdKey);
    if (storedPrivate != null &&
        storedPublic != null &&
        storedDeviceId != null &&
        _isEncodedLength(storedPrivate, 32) &&
        _isEncodedLength(storedPublic, 32) &&
        _isEncodedLength(storedDeviceId, 16)) {
      return DeviceConfigurationIdentity(
        deviceId: storedDeviceId,
        publicKey: storedPublic,
      );
    }

    await clear();
    final Uint8List privateBytes = _randomBytes(32);
    final SimpleKeyPair keyPair = await _algorithm.newKeyPairFromSeed(
      privateBytes,
    );
    final SimplePublicKey publicKey = await keyPair.extractPublicKey();
    final String encodedPrivate = _encode(privateBytes);
    final String encodedPublic = _encode(publicKey.bytes);
    final String deviceId = _encode(_randomBytes(16));
    try {
      await _credentialStore.write(key: _privateKey, value: encodedPrivate);
      await _credentialStore.write(key: _publicKey, value: encodedPublic);
      await _credentialStore.write(key: _deviceIdKey, value: deviceId);
    } catch (_) {
      await clear();
      rethrow;
    }
    return DeviceConfigurationIdentity(
      deviceId: deviceId,
      publicKey: encodedPublic,
    );
  }

  Future<void> clear() async {
    await _credentialStore.delete(_privateKey);
    await _credentialStore.delete(_publicKey);
    await _credentialStore.delete(_deviceIdKey);
  }

  Future<SimpleKeyPair> readPrivateKeyPair() async {
    final String? encoded = await _credentialStore.read(_privateKey);
    if (encoded == null || !_isEncodedLength(encoded, 32)) {
      throw StateError('Device configuration identity is unavailable.');
    }
    return _algorithm.newKeyPairFromSeed(
      base64Url.decode(base64Url.normalize(encoded)),
    );
  }

  Uint8List _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256), growable: false),
  );

  String _encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  bool _isEncodedLength(String value, int length) {
    try {
      return base64Url.decode(base64Url.normalize(value)).length == length;
    } on FormatException {
      return false;
    }
  }
}
