import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/configuration_policy.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/protocol/stellar_activation_protocol.dart';
import 'package:the_builder_pros/wallet_sdk/src/qr/activation_qr_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/distributor_status_client.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

final class ExpiredActivationResponseException extends FormatException {
  const ExpiredActivationResponseException()
    : super('Expired activation response.');
}

final class InspectedActivationResponse {
  const InspectedActivationResponse({
    required this.review,
    required this.configuration,
    required this.envelope,
  });

  final ActivationReview review;
  final ProviderConfiguration configuration;
  final StellarActivationEnvelope envelope;
}

final class ActivationResponseService {
  ActivationResponseService({Random? random})
    : _random = random ?? Random.secure();

  static const int maximumEncodedBytes = 4096;
  static const int _startingNativeAmount = 21000000;
  static const int _startingRewardsAmount = 10000000;
  static const int _maximumFeePerOperation = 100000;
  static const Duration _responseLifetime = Duration(minutes: 5);

  final Random _random;
  final StellarActivationProtocol _protocol = StellarActivationProtocol();
  final X25519 _x25519 = X25519();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final Xchacha20 _cipher = Xchacha20.poly1305Aead();
  final Ed25519 _ed25519 = Ed25519();
  final Sha256 _sha256 = Sha256();

  Future<ActivationResponseView> create({
    required DecodedActivationRequest request,
    required ProviderConfiguration configuration,
    required DistributorLedgerStatus ledger,
    required String distributorAccount,
    required String distributorSecret,
    required DateTime now,
    required String responseId,
  }) async {
    if (ledger.nonNativeAssets.length != 1 ||
        ledger.nonNativeAssets.single.spendable < 1) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.activationPolicyUnavailable,
        safeMessage: 'Rewards activation settings need review.',
        canRetry: false,
      );
    }
    final DistributorAssetBalance configuredAsset =
        ledger.nonNativeAssets.single;
    final int feePerOperation = max(100, ledger.feeP95Stroops);
    if (feePerOperation > _maximumFeePerOperation) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.activationPolicyUnavailable,
        safeMessage: 'Activation costs are temporarily too high.',
        canRetry: true,
      );
    }
    final DateTime expiresAt = _earlier(
      request.expiresAt,
      now.add(_responseLifetime),
    );
    final StellarAsset rewards = StellarAsset.credit(
      code: configuredAsset.code,
      issuer: configuredAsset.issuer,
    );
    final StellarActivationEnvelope unsigned = StellarActivationEnvelope(
      sourceAccount: distributorAccount,
      fee: feePerOperation * 3,
      sequenceNumber: int.parse(ledger.sequence) + 1,
      minTime: now.millisecondsSinceEpoch ~/ 1000,
      maxTime: expiresAt.millisecondsSinceEpoch ~/ 1000,
      operations: <StellarActivationOperation>[
        StellarCreateAccountOperation(
          destination: request.activationAddress,
          startingBalance: _startingNativeAmount,
        ),
        StellarChangeTrustOperation(
          sourceAccount: request.activationAddress,
          asset: rewards,
          limit: 0x7fffffffffffffff,
        ),
        StellarPaymentOperation(
          destination: request.activationAddress,
          asset: rewards,
          amount: _startingRewardsAmount,
        ),
      ],
    );
    final String passphrase =
        configuration.environment == ProviderEnvironment.test
        ? StellarActivationProtocol.testNetworkPassphrase
        : StellarActivationProtocol.publicNetworkPassphrase;
    final StellarActivationEnvelope signed = await _protocol.sign(
      unsigned,
      secretSeed: distributorSecret,
      networkPassphrase: passphrase,
    );
    final Map<String, Object> binding = <String, Object>{
      'response_id': responseId,
      'request_id': request.requestId,
      'challenge': request.challenge,
      'device_id': request.deviceId,
      'environment': configuration.environment.name,
      'configuration_version': configuration.version,
      'issued_at': now.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
    final Map<String, Object> encrypted = await _encryptConfiguration(
      configuration,
      request.devicePublicKey,
      utf8.encode(jsonEncode(binding)),
    );
    final Map<String, Object> payload = <String, Object>{
      'type': 'rewards_activation_response',
      'version': 1,
      ...binding,
      'activation_address': request.activationAddress,
      'envelope_xdr': _protocol.encodeEnvelopeBase64(signed),
      'encrypted_provider_configuration': encrypted,
      'app_master_key_id': distributorAccount,
    };
    final List<int> digest = (await _sha256.hash(
      utf8.encode(jsonEncode(payload)),
    )).bytes;
    final SimpleKeyPair signingKey = await _ed25519.newKeyPairFromSeed(
      _decode(distributorSecret, secret: true),
    );
    final Signature authorization = await _ed25519.sign(
      digest,
      keyPair: signingKey,
    );
    final String encoded = jsonEncode(<String, Object>{
      ...payload,
      'integrity_signature': _encode(authorization.bytes),
    });
    if (utf8.encode(encoded).length > maximumEncodedBytes) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.activationApprovalFailed,
        safeMessage: 'The activation package is too large.',
        canRetry: false,
      );
    }
    return ActivationResponseView(
      responseId: responseId,
      requestId: request.requestId,
      qrValue: encoded,
      expiresAt: expiresAt,
    );
  }

  Future<ActivationReview> inspect({
    required String encoded,
    required DecodedActivationRequest request,
    required SimpleKeyPair deviceKeyPair,
    required DateTime now,
  }) async => (await inspectDetails(
    encoded: encoded,
    request: request,
    deviceKeyPair: deviceKeyPair,
    now: now,
  )).review;

  Future<InspectedActivationResponse> inspectDetails({
    required String encoded,
    required DecodedActivationRequest request,
    required SimpleKeyPair deviceKeyPair,
    required DateTime now,
    bool allowExpired = false,
  }) async {
    if (encoded.isEmpty || utf8.encode(encoded).length > maximumEncodedBytes) {
      throw const FormatException('Invalid activation response size.');
    }
    final Object? raw = jsonDecode(encoded);
    if (raw is! Map<String, dynamic> ||
        !_hasExactKeys(raw, const <String>{
          'type',
          'version',
          'response_id',
          'request_id',
          'challenge',
          'device_id',
          'environment',
          'configuration_version',
          'issued_at',
          'expires_at',
          'activation_address',
          'envelope_xdr',
          'encrypted_provider_configuration',
          'app_master_key_id',
          'integrity_signature',
        })) {
      throw const FormatException('Invalid activation response envelope.');
    }
    if (raw['type'] != 'rewards_activation_response' || raw['version'] != 1) {
      throw const FormatException('Unsupported activation response.');
    }
    final String responseId = _string(raw, 'response_id');
    final String requestId = _string(raw, 'request_id');
    final String challenge = _string(raw, 'challenge');
    final String deviceId = _string(raw, 'device_id');
    final String environment = _string(raw, 'environment');
    final int configurationVersion = raw['configuration_version'] as int;
    final DateTime issuedAt = DateTime.parse(_string(raw, 'issued_at')).toUtc();
    final DateTime expiresAt = DateTime.parse(
      _string(raw, 'expires_at'),
    ).toUtc();
    final String activationAddress = _string(raw, 'activation_address');
    final String appMaster = _string(raw, 'app_master_key_id');
    if (!responseId.startsWith('RES-') ||
        requestId != request.requestId ||
        challenge != request.challenge ||
        deviceId != request.deviceId ||
        activationAddress != request.activationAddress ||
        configurationVersion < 1 ||
        issuedAt.isAfter(now) ||
        expiresAt.isAfter(request.expiresAt) ||
        expiresAt.difference(issuedAt) > _responseLifetime) {
      throw const FormatException('Activation response binding failed.');
    }
    if (!allowExpired && !now.isBefore(expiresAt)) {
      throw const ExpiredActivationResponseException();
    }
    final Map<String, dynamic> signedPayload = Map<String, dynamic>.from(raw)
      ..remove('integrity_signature');
    final List<int> digest = (await _sha256.hash(
      utf8.encode(jsonEncode(signedPayload)),
    )).bytes;
    final bool authorized = await _ed25519.verify(
      digest,
      signature: Signature(
        _decode(_string(raw, 'integrity_signature')),
        publicKey: SimplePublicKey(
          const StrKeyCodec().decodeEd25519PublicKey(appMaster),
          type: KeyPairType.ed25519,
        ),
      ),
    );
    if (!authorized) {
      throw const FormatException('Activation response authorization failed.');
    }
    final Map<String, Object> binding = <String, Object>{
      'response_id': responseId,
      'request_id': requestId,
      'challenge': challenge,
      'device_id': deviceId,
      'environment': environment,
      'configuration_version': configurationVersion,
      'issued_at': issuedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
    final ProviderConfiguration configuration = await _decryptConfiguration(
      raw['encrypted_provider_configuration'],
      deviceKeyPair,
      utf8.encode(jsonEncode(binding)),
    );
    if (configuration.environment.name != environment ||
        configuration.version != configurationVersion) {
      throw const FormatException('Provider configuration binding failed.');
    }
    try {
      ConfigurationPolicy().validate(
        ProviderConfigurationInput(
          endpoint: configuration.endpoint.toString(),
          apiKey: configuration.apiKey,
          environment: configuration.environment,
          version: configuration.version,
        ),
      );
    } on WalletSdkException {
      throw const FormatException('Invalid provider configuration.');
    }
    final StellarActivationEnvelope envelope = _protocol.decodeEnvelopeBase64(
      _string(raw, 'envelope_xdr'),
    );
    await _validateEnvelope(
      envelope,
      appMaster: appMaster,
      builder: activationAddress,
      environment: configuration.environment,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
    return InspectedActivationResponse(
      configuration: configuration,
      envelope: envelope,
      review: ActivationReview(
        responseId: responseId,
        requestId: requestId,
        expiresAt: expiresAt,
        preparedBy: 'Verified App Master',
        setupSteps: const <String>[
          'Activation costs covered',
          'Rewards access ready',
          'Starting Rewards: 1',
        ],
      ),
    );
  }

  Future<ProviderConfiguration> _decryptConfiguration(
    Object? raw,
    SimpleKeyPair deviceKeyPair,
    List<int> binding,
  ) async {
    if (raw is! Map<String, dynamic> ||
        !_hasExactKeys(raw, const <String>{
          'algorithm',
          'ephemeral_public_key',
          'nonce',
          'ciphertext',
        }) ||
        raw['algorithm'] != 'X25519-HKDF-SHA256-XCHACHA20POLY1305') {
      throw const FormatException('Invalid encrypted configuration.');
    }
    final List<int> packed = _decode(_string(raw, 'ciphertext'));
    if (packed.length < 17) {
      throw const FormatException('Invalid encrypted configuration.');
    }
    final SecretKey shared = await _x25519.sharedSecretKey(
      keyPair: deviceKeyPair,
      remotePublicKey: SimplePublicKey(
        _decode(_string(raw, 'ephemeral_public_key')),
        type: KeyPairType.x25519,
      ),
    );
    final SecretKey key = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: (await _sha256.hash(binding)).bytes,
      info: utf8.encode('theBuilderPros/rewards/provider/v1'),
    );
    final List<int> clear = await _cipher.decrypt(
      SecretBox(
        packed.sublist(0, packed.length - 16),
        nonce: _decode(_string(raw, 'nonce')),
        mac: Mac(packed.sublist(packed.length - 16)),
      ),
      secretKey: key,
      aad: binding,
    );
    return ProviderConfiguration.decodeProtected(utf8.decode(clear));
  }

  Future<void> _validateEnvelope(
    StellarActivationEnvelope envelope, {
    required String appMaster,
    required String builder,
    required ProviderEnvironment environment,
    required DateTime issuedAt,
    required DateTime expiresAt,
  }) async {
    if (envelope.sourceAccount != appMaster ||
        envelope.operations.length != 3 ||
        envelope.signatures.length != 1 ||
        envelope.fee < 300 ||
        envelope.fee > _maximumFeePerOperation * 3 ||
        envelope.sequenceNumber < 1 ||
        envelope.minTime != issuedAt.millisecondsSinceEpoch ~/ 1000 ||
        envelope.maxTime != expiresAt.millisecondsSinceEpoch ~/ 1000) {
      throw const FormatException('Activation transaction policy failed.');
    }
    final StellarActivationOperation first = envelope.operations[0];
    final StellarActivationOperation second = envelope.operations[1];
    final StellarActivationOperation third = envelope.operations[2];
    if (first is! StellarCreateAccountOperation ||
        first.sourceAccount != null ||
        first.destination != builder ||
        first.startingBalance != _startingNativeAmount ||
        second is! StellarChangeTrustOperation ||
        second.sourceAccount != builder ||
        second.limit != 0x7fffffffffffffff ||
        second.asset.isNative ||
        third is! StellarPaymentOperation ||
        third.sourceAccount != null ||
        third.destination != builder ||
        third.amount != _startingRewardsAmount ||
        third.asset != second.asset) {
      throw const FormatException('Activation operation policy failed.');
    }
    final String passphrase = environment == ProviderEnvironment.test
        ? StellarActivationProtocol.testNetworkPassphrase
        : StellarActivationProtocol.publicNetworkPassphrase;
    if (!await _protocol.verifySignature(
      envelope,
      signature: envelope.signatures.single,
      publicAccount: appMaster,
      networkPassphrase: passphrase,
    )) {
      throw const FormatException('Activation transaction signature failed.');
    }
  }

  Future<Map<String, Object>> _encryptConfiguration(
    ProviderConfiguration configuration,
    String encodedDeviceKey,
    List<int> binding,
  ) async {
    final SimpleKeyPair ephemeral = await _x25519.newKeyPair();
    final SimplePublicKey publicKey = await ephemeral.extractPublicKey();
    final SecretKey shared = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        base64Url.decode(base64Url.normalize(encodedDeviceKey)),
        type: KeyPairType.x25519,
      ),
    );
    final SecretKey encryptionKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: (await _sha256.hash(binding)).bytes,
      info: utf8.encode('theBuilderPros/rewards/provider/v1'),
    );
    final Uint8List nonce = _randomBytes(24);
    final SecretBox box = await _cipher.encrypt(
      utf8.encode(configuration.encodeProtected()),
      secretKey: encryptionKey,
      nonce: nonce,
      aad: binding,
    );
    return <String, Object>{
      'algorithm': 'X25519-HKDF-SHA256-XCHACHA20POLY1305',
      'ephemeral_public_key': _encode(publicKey.bytes),
      'nonce': _encode(nonce),
      'ciphertext': _encode(<int>[...box.cipherText, ...box.mac.bytes]),
    };
  }

  Uint8List _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256), growable: false),
  );

  String _encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  List<int> _decode(String value, {bool secret = false}) {
    if (secret) {
      return const StrKeyCodec().decodeEd25519SecretSeed(value);
    }
    return base64Url.decode(base64Url.normalize(value));
  }

  bool _hasExactKeys(Map<String, dynamic> value, Set<String> expected) =>
      value.length == expected.length &&
      value.keys.toSet().containsAll(expected);

  String _string(Map<String, dynamic> value, String key) {
    final Object? result = value[key];
    if (result is! String ||
        result.isEmpty ||
        result.length > maximumEncodedBytes) {
      throw const FormatException('Invalid activation response field.');
    }
    return result;
  }

  DateTime _earlier(DateTime left, DateTime right) =>
      left.isBefore(right) ? left : right;
}
