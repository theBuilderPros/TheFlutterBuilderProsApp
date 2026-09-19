import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/configuration_policy.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

final class DecodedConfigurationRequest {
  const DecodedConfigurationRequest({
    required this.requestId,
    required this.deviceId,
    required this.devicePublicKey,
    required this.currentVersion,
    required this.environment,
    required this.challenge,
    required this.expiresAt,
  });

  final String requestId;
  final String deviceId;
  final String devicePublicKey;
  final int currentVersion;
  final ProviderEnvironment environment;
  final String challenge;
  final DateTime expiresAt;
}

final class InspectedConfigurationUpdate {
  const InspectedConfigurationUpdate({
    required this.review,
    required this.configuration,
  });

  final ConfigurationReview review;
  final ProviderConfiguration configuration;
}

final class ConfigurationHandshakeService {
  ConfigurationHandshakeService({Random? random})
    : _random = random ?? Random.secure();

  static const int maximumBytes = 4096;
  static const Duration lifetime = Duration(minutes: 10);
  final Random _random;
  final Sha256 _sha256 = Sha256();
  final X25519 _x25519 = X25519();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final Xchacha20 _cipher = Xchacha20.poly1305Aead();
  final Ed25519 _ed25519 = Ed25519();

  Future<String> createRequest({
    required String requestId,
    required String deviceId,
    required String devicePublicKey,
    required int currentVersion,
    required ProviderEnvironment environment,
    required String challenge,
    required DateTime now,
  }) async {
    final Map<String, Object> payload = <String, Object>{
      'type': 'wallet_configuration_request',
      'version': 1,
      'request_id': requestId,
      'device_id': deviceId,
      'device_configuration_public_key': devicePublicKey,
      'current_configuration_version': currentVersion,
      'environment': environment.name,
      'challenge': challenge,
      'created_at': now.toUtc().toIso8601String(),
      'expires_at': now.add(lifetime).toUtc().toIso8601String(),
    };
    return jsonEncode(<String, Object>{
      'payload': payload,
      'integrity': _encode(
        (await _sha256.hash(utf8.encode(jsonEncode(payload)))).bytes,
      ),
    });
  }

  Future<DecodedConfigurationRequest> inspectRequest(
    String encoded,
    DateTime now,
  ) async {
    _size(encoded);
    final Object? raw = jsonDecode(encoded);
    if (raw is! Map<String, dynamic> ||
        !_keys(raw, const <String>{'payload', 'integrity'}) ||
        raw['payload'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid configuration request.');
    }
    final Map<String, dynamic> payload = raw['payload'] as Map<String, dynamic>;
    if (!_keys(payload, const <String>{
          'type',
          'version',
          'request_id',
          'device_id',
          'device_configuration_public_key',
          'current_configuration_version',
          'environment',
          'challenge',
          'created_at',
          'expires_at',
        }) ||
        payload['type'] != 'wallet_configuration_request' ||
        payload['version'] != 1 ||
        raw['integrity'] !=
            _encode(
              (await _sha256.hash(utf8.encode(jsonEncode(payload)))).bytes,
            )) {
      throw const FormatException('Invalid configuration request.');
    }
    final DateTime created = DateTime.parse(
      _string(payload, 'created_at'),
    ).toUtc();
    final DateTime expires = DateTime.parse(
      _string(payload, 'expires_at'),
    ).toUtc();
    final String deviceId = _string(payload, 'device_id');
    final String deviceKey = _string(
      payload,
      'device_configuration_public_key',
    );
    final Object? currentVersion = payload['current_configuration_version'];
    if (!created.isBefore(expires) ||
        expires.difference(created) > lifetime ||
        !now.isBefore(expires) ||
        currentVersion is! int ||
        currentVersion < 1 ||
        _decode(deviceId).length != 16 ||
        _decode(deviceKey).length != 32) {
      throw const FormatException('Invalid configuration request binding.');
    }
    return DecodedConfigurationRequest(
      requestId: _string(payload, 'request_id'),
      deviceId: deviceId,
      devicePublicKey: deviceKey,
      currentVersion: currentVersion,
      environment: ProviderEnvironment.values.byName(
        _string(payload, 'environment'),
      ),
      challenge: _string(payload, 'challenge'),
      expiresAt: expires,
    );
  }

  Future<String> createUpdate({
    required String updateId,
    required DecodedConfigurationRequest request,
    required ProviderConfiguration configuration,
    required String signingSecret,
    required String signerAccount,
    required DateTime now,
  }) async {
    if (configuration.version <= request.currentVersion ||
        configuration.environment != request.environment) {
      throw const FormatException('Configuration version did not advance.');
    }
    final DateTime expires = now.add(lifetime).isBefore(request.expiresAt)
        ? now.add(lifetime)
        : request.expiresAt;
    final Map<String, Object> binding = <String, Object>{
      'update_id': updateId,
      'request_id': request.requestId,
      'device_id': request.deviceId,
      'environment': configuration.environment.name,
      'configuration_version': configuration.version,
      'challenge': request.challenge,
      'issued_at': now.toUtc().toIso8601String(),
      'expires_at': expires.toUtc().toIso8601String(),
    };
    final Map<String, Object> payload = <String, Object>{
      'type': 'wallet_configuration_update',
      'version': 1,
      ...binding,
      'encrypted_configuration': await _encrypt(
        configuration,
        request.devicePublicKey,
        utf8.encode(jsonEncode(binding)),
      ),
      'app_master_key_id': signerAccount,
    };
    final List<int> digest = (await _sha256.hash(
      utf8.encode(jsonEncode(payload)),
    )).bytes;
    final SimpleKeyPair key = await _ed25519.newKeyPairFromSeed(
      const StrKeyCodec().decodeEd25519SecretSeed(signingSecret),
    );
    final Signature signature = await _ed25519.sign(digest, keyPair: key);
    return jsonEncode(<String, Object>{
      ...payload,
      'integrity_signature': _encode(signature.bytes),
    });
  }

  Future<InspectedConfigurationUpdate> inspectUpdate({
    required String encoded,
    required DecodedConfigurationRequest request,
    required SimpleKeyPair deviceKeyPair,
    required int installedVersion,
    required DateTime now,
  }) async {
    _size(encoded);
    final Map<String, dynamic> raw =
        jsonDecode(encoded) as Map<String, dynamic>;
    if (!_keys(raw, const <String>{
          'type',
          'version',
          'update_id',
          'request_id',
          'device_id',
          'environment',
          'configuration_version',
          'challenge',
          'issued_at',
          'expires_at',
          'encrypted_configuration',
          'app_master_key_id',
          'integrity_signature',
        }) ||
        raw['type'] != 'wallet_configuration_update' ||
        raw['version'] != 1) {
      throw const FormatException('Invalid configuration update.');
    }
    final String updateId = _string(raw, 'update_id');
    final int version = raw['configuration_version'] as int;
    final DateTime issued = DateTime.parse(_string(raw, 'issued_at')).toUtc();
    final DateTime expires = DateTime.parse(_string(raw, 'expires_at')).toUtc();
    if (_string(raw, 'request_id') != request.requestId ||
        _string(raw, 'device_id') != request.deviceId ||
        _string(raw, 'challenge') != request.challenge ||
        _string(raw, 'environment') != request.environment.name ||
        version <= installedVersion ||
        issued.isAfter(now) ||
        expires.isAfter(request.expiresAt)) {
      throw const FormatException('Configuration update binding failed.');
    }
    if (!now.isBefore(expires)) {
      throw const ExpiredConfigurationUpdateException();
    }
    final Map<String, dynamic> payload = Map<String, dynamic>.from(raw)
      ..remove('integrity_signature');
    final String signer = _string(raw, 'app_master_key_id');
    final bool valid = await _ed25519.verify(
      (await _sha256.hash(utf8.encode(jsonEncode(payload)))).bytes,
      signature: Signature(
        _decode(_string(raw, 'integrity_signature')),
        publicKey: SimplePublicKey(
          const StrKeyCodec().decodeEd25519PublicKey(signer),
          type: KeyPairType.ed25519,
        ),
      ),
    );
    if (!valid) throw const FormatException('Invalid update authorization.');
    final Map<String, Object> binding = <String, Object>{
      'update_id': updateId,
      'request_id': request.requestId,
      'device_id': request.deviceId,
      'environment': request.environment.name,
      'configuration_version': version,
      'challenge': request.challenge,
      'issued_at': issued.toIso8601String(),
      'expires_at': expires.toIso8601String(),
    };
    final ProviderConfiguration configuration = await _decrypt(
      raw['encrypted_configuration'],
      deviceKeyPair,
      utf8.encode(jsonEncode(binding)),
    );
    if (configuration.version != version ||
        configuration.environment != request.environment) {
      throw const FormatException('Configuration update mismatch.');
    }
    ConfigurationPolicy().validate(
      ProviderConfigurationInput(
        endpoint: configuration.endpoint.toString(),
        apiKey: configuration.apiKey,
        environment: configuration.environment,
        version: configuration.version,
      ),
    );
    return InspectedConfigurationUpdate(
      configuration: configuration,
      review: ConfigurationReview(
        updateId: updateId,
        version: version,
        environment: configuration.environment,
        endpointHost: configuration.endpoint.host,
        expiresAt: expires,
      ),
    );
  }

  Future<Map<String, Object>> _encrypt(
    ProviderConfiguration configuration,
    String devicePublicKey,
    List<int> aad,
  ) async {
    final SimpleKeyPair ephemeral = await _x25519.newKeyPair();
    final SimplePublicKey publicKey = await ephemeral.extractPublicKey();
    final SecretKey shared = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        _decode(devicePublicKey),
        type: KeyPairType.x25519,
      ),
    );
    final SecretKey key = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: (await _sha256.hash(aad)).bytes,
      info: utf8.encode('theBuilderPros/rewards/configuration-update/v1'),
    );
    final Uint8List nonce = Uint8List.fromList(
      List<int>.generate(24, (_) => _random.nextInt(256), growable: false),
    );
    final SecretBox box = await _cipher.encrypt(
      utf8.encode(configuration.encodeProtected()),
      secretKey: key,
      nonce: nonce,
      aad: aad,
    );
    return <String, Object>{
      'algorithm': 'X25519-HKDF-SHA256-XCHACHA20POLY1305',
      'ephemeral_public_key': _encode(publicKey.bytes),
      'nonce': _encode(nonce),
      'ciphertext': _encode(<int>[...box.cipherText, ...box.mac.bytes]),
    };
  }

  Future<ProviderConfiguration> _decrypt(
    Object? raw,
    SimpleKeyPair deviceKeyPair,
    List<int> aad,
  ) async {
    final Map<String, dynamic> value = raw as Map<String, dynamic>;
    if (!_keys(value, const <String>{
          'algorithm',
          'ephemeral_public_key',
          'nonce',
          'ciphertext',
        }) ||
        value['algorithm'] != 'X25519-HKDF-SHA256-XCHACHA20POLY1305') {
      throw const FormatException('Invalid encrypted configuration.');
    }
    final List<int> packed = _decode(_string(value, 'ciphertext'));
    if (packed.length < 17) {
      throw const FormatException('Invalid encrypted configuration.');
    }
    final SecretKey shared = await _x25519.sharedSecretKey(
      keyPair: deviceKeyPair,
      remotePublicKey: SimplePublicKey(
        _decode(_string(value, 'ephemeral_public_key')),
        type: KeyPairType.x25519,
      ),
    );
    final SecretKey key = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: (await _sha256.hash(aad)).bytes,
      info: utf8.encode('theBuilderPros/rewards/configuration-update/v1'),
    );
    final List<int> clear = await _cipher.decrypt(
      SecretBox(
        packed.sublist(0, packed.length - 16),
        nonce: _decode(_string(value, 'nonce')),
        mac: Mac(packed.sublist(packed.length - 16)),
      ),
      secretKey: key,
      aad: aad,
    );
    return ProviderConfiguration.decodeProtected(utf8.decode(clear));
  }

  void _size(String value) {
    if (value.isEmpty || utf8.encode(value).length > maximumBytes) {
      throw const FormatException('Invalid configuration QR size.');
    }
  }

  bool _keys(Map<String, dynamic> value, Set<String> expected) =>
      value.length == expected.length &&
      value.keys.toSet().containsAll(expected);
  String _string(Map<String, dynamic> value, String key) {
    final Object? result = value[key];
    if (result is! String || result.isEmpty || result.length > maximumBytes) {
      throw const FormatException('Invalid configuration field.');
    }
    return result;
  }

  String _encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
  List<int> _decode(String value) =>
      base64Url.decode(base64Url.normalize(value));
}

final class ExpiredConfigurationUpdateException extends FormatException {
  const ExpiredConfigurationUpdateException()
    : super('Configuration update expired.');
}
