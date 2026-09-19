import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

final class DecodedActivationRequest {
  const DecodedActivationRequest({
    required this.requestId,
    required this.challenge,
    required this.expiresAt,
    required this.deviceId,
    required this.devicePublicKey,
    required this.builder,
    required this.activationAddress,
  });

  final String requestId;
  final String challenge;
  final DateTime expiresAt;
  final String deviceId;
  final String devicePublicKey;
  final BuilderIdentity builder;
  final String activationAddress;
}

final class ExpiredActivationRequestException extends FormatException {
  const ExpiredActivationRequestException()
    : super('Expired activation request.');
}

final class ActivationQrCodec {
  ActivationQrCodec({
    Sha256? sha256,
    StrKeyCodec strKeyCodec = const StrKeyCodec(),
  }) : _sha256 = sha256 ?? Sha256(),
       _strKeyCodec = strKeyCodec;

  static const int schemaVersion = 2;
  static const int maximumEncodedBytes = 4096;

  final Sha256 _sha256;
  final StrKeyCodec _strKeyCodec;

  Future<String> encodeRequest({
    required String requestId,
    required String challenge,
    required DateTime createdAt,
    required DateTime expiresAt,
    required BuilderIdentity builder,
    required String activationAddress,
    required String deviceId,
    required String devicePublicKey,
  }) async {
    final Map<String, Object> payload = <String, Object>{
      'type': 'rewards_activation_request',
      'version': schemaVersion,
      'request_id': requestId,
      'challenge': challenge,
      'created_at': createdAt.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'environment': 'test',
      'builder': <String, String>{
        'name': builder.displayName,
        'phone': builder.phone,
      },
      'activation_address': activationAddress,
      'device_id': deviceId,
      'device_configuration_public_key': devicePublicKey,
    };
    final String canonicalPayload = jsonEncode(payload);
    final String encoded = jsonEncode(<String, Object>{
      'payload': payload,
      'integrity': await _digest(canonicalPayload),
    });
    if (utf8.encode(encoded).length > maximumEncodedBytes) {
      throw const FormatException('Activation request is too large.');
    }
    return encoded;
  }

  Future<DecodedActivationRequest> decodeAndValidate(
    String encoded, {
    required DateTime now,
  }) async {
    if (encoded.isEmpty || utf8.encode(encoded).length > maximumEncodedBytes) {
      throw const FormatException('Invalid activation request size.');
    }
    final Object? decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic> ||
        !_hasExactKeys(decoded, const <String>{'payload', 'integrity'})) {
      throw const FormatException('Invalid activation request envelope.');
    }
    final Object? rawPayload = decoded['payload'];
    final Object? rawIntegrity = decoded['integrity'];
    if (rawPayload is! Map<String, dynamic> ||
        rawIntegrity is! String ||
        !_hasExactKeys(rawPayload, const <String>{
          'type',
          'version',
          'request_id',
          'challenge',
          'created_at',
          'expires_at',
          'environment',
          'builder',
          'activation_address',
          'device_id',
          'device_configuration_public_key',
        })) {
      throw const FormatException('Invalid activation request payload.');
    }
    final Object? rawBuilder = rawPayload['builder'];
    if (rawBuilder is! Map<String, dynamic> ||
        !_hasExactKeys(rawBuilder, const <String>{'name', 'phone'})) {
      throw const FormatException('Invalid Builder identity.');
    }
    if (rawPayload['type'] != 'rewards_activation_request' ||
        rawPayload['version'] != schemaVersion ||
        rawPayload['environment'] != 'test' ||
        await _digest(jsonEncode(rawPayload)) != rawIntegrity) {
      throw const FormatException('Unsupported or altered activation request.');
    }

    final String requestId = _requiredString(rawPayload, 'request_id');
    final String challenge = _requiredString(rawPayload, 'challenge');
    final String activationAddress = _requiredString(
      rawPayload,
      'activation_address',
    );
    final String deviceId = _requiredString(rawPayload, 'device_id');
    final String devicePublicKey = _requiredString(
      rawPayload,
      'device_configuration_public_key',
    );
    final String builderName = _requiredString(rawBuilder, 'name');
    final String phone = _requiredString(rawBuilder, 'phone');
    if (!requestId.startsWith('ACT-') ||
        challenge.length < 24 ||
        !_strKeyCodec.isValidEd25519PublicKey(activationAddress) ||
        !phone.startsWith('+') ||
        !_hasDecodedLength(deviceId, 16) ||
        !_hasDecodedLength(devicePublicKey, 32)) {
      throw const FormatException('Invalid activation request fields.');
    }
    final DateTime createdAt = _requiredDate(rawPayload, 'created_at');
    final DateTime expiresAt = _requiredDate(rawPayload, 'expires_at');
    if (!createdAt.isBefore(expiresAt) ||
        expiresAt.difference(createdAt) > const Duration(minutes: 15) ||
        !now.toUtc().isBefore(expiresAt)) {
      throw const ExpiredActivationRequestException();
    }
    return DecodedActivationRequest(
      requestId: requestId,
      challenge: challenge,
      expiresAt: expiresAt,
      deviceId: deviceId,
      devicePublicKey: devicePublicKey,
      builder: BuilderIdentity(displayName: builderName, phone: phone),
      activationAddress: activationAddress,
    );
  }

  bool _hasExactKeys(Map<String, dynamic> value, Set<String> expected) =>
      value.length == expected.length &&
      value.keys.toSet().containsAll(expected);

  String _requiredString(Map<String, dynamic> value, String key) {
    final Object? result = value[key];
    if (result is! String || result.isEmpty || result.length > 256) {
      throw const FormatException('Invalid activation request field.');
    }
    return result;
  }

  DateTime _requiredDate(Map<String, dynamic> value, String key) =>
      DateTime.parse(_requiredString(value, key)).toUtc();

  bool _hasDecodedLength(String value, int expectedLength) {
    try {
      return base64Url.decode(base64Url.normalize(value)).length ==
          expectedLength;
    } on FormatException {
      return false;
    }
  }

  Future<String> _digest(String value) async {
    final Hash hash = await _sha256.hash(utf8.encode(value));
    return base64Url.encode(hash.bytes).replaceAll('=', '');
  }
}
