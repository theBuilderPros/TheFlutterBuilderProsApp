import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_builder_pros/wallet_sdk/src/activation/activation_response_service.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/protocol/stellar_activation_protocol.dart';
import 'package:the_builder_pros/wallet_sdk/src/qr/activation_qr_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/distributor_status_client.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  test('builds, signs, encrypts, and binds an activation response', () async {
    const StrKeyCodec strKey = StrKeyCodec();
    final SimpleKeyPair deviceKey = await X25519().newKeyPair();
    final SimplePublicKey devicePublic = await deviceKey.extractPublicKey();
    final String distributorSecret = strKey.encodeEd25519SecretSeed(
      List<int>.filled(32, 0),
    );
    final String distributor = strKey.encodeEd25519PublicKey(
      (await (await Ed25519().newKeyPairFromSeed(
        List<int>.filled(32, 0),
      )).extractPublicKey()).bytes,
    );
    final String builder = strKey.encodeEd25519PublicKey(
      List<int>.filled(32, 2),
    );
    final String issuer = strKey.encodeEd25519PublicKey(
      List<int>.filled(32, 3),
    );
    final DateTime now = DateTime.utc(2026, 9, 19, 12);

    final ActivationResponseView result = await ActivationResponseService()
        .create(
          request: DecodedActivationRequest(
            requestId: 'ACT-TEST-01',
            challenge: 'ABCDEFGHIJKLMNOPQRSTUVWX',
            expiresAt: now.add(const Duration(minutes: 15)),
            deviceId: _encode(List<int>.filled(16, 4)),
            devicePublicKey: _encode(devicePublic.bytes),
            builder: const BuilderIdentity(
              displayName: 'Builder',
              phone: '+95912345678',
            ),
            activationAddress: builder,
          ),
          configuration: ProviderConfiguration(
            endpoint: Uri.parse('https://xlm.nownodes.io'),
            apiKey: 'protected-api-key',
            environment: ProviderEnvironment.test,
            version: 4,
          ),
          ledger: DistributorLedgerStatus(
            nativeBalance: 20,
            nativeSellingLiabilities: 0,
            subentryCount: 1,
            sequence: '99',
            nonNativeSpendableBalances: const <double>[25],
            feeP95Stroops: 200,
            nonNativeAssets: <DistributorAssetBalance>[
              DistributorAssetBalance(
                code: 'REWARD',
                issuer: issuer,
                spendable: 25,
              ),
            ],
          ),
          distributorAccount: distributor,
          distributorSecret: distributorSecret,
          now: now,
          responseId: 'RES-TEST-01',
        );

    final Map<String, dynamic> response =
        jsonDecode(result.qrValue) as Map<String, dynamic>;
    expect(response['type'], 'rewards_activation_response');
    expect(response['request_id'], 'ACT-TEST-01');
    expect(response['device_id'], _encode(List<int>.filled(16, 4)));
    expect(result.qrValue, isNot(contains('protected-api-key')));
    final StellarActivationEnvelope envelope = StellarActivationProtocol()
        .decodeEnvelopeBase64(response['envelope_xdr'] as String);
    expect(envelope.sequenceNumber, 100);
    expect(envelope.fee, 600);
    expect(
      envelope.operations.map((StellarActivationOperation value) => value.type),
      <StellarActivationOperationType>[
        StellarActivationOperationType.createAccount,
        StellarActivationOperationType.changeTrust,
        StellarActivationOperationType.payment,
      ],
    );
    expect(envelope.signatures, hasLength(1));
    expect(
      await StellarActivationProtocol().verifySignature(
        envelope,
        signature: envelope.signatures.single,
        publicAccount: distributor,
        networkPassphrase: StellarActivationProtocol.testNetworkPassphrase,
      ),
      isTrue,
    );
    final ActivationReview review = await ActivationResponseService().inspect(
      encoded: result.qrValue,
      request: DecodedActivationRequest(
        requestId: 'ACT-TEST-01',
        challenge: 'ABCDEFGHIJKLMNOPQRSTUVWX',
        expiresAt: now.add(const Duration(minutes: 15)),
        deviceId: _encode(List<int>.filled(16, 4)),
        devicePublicKey: _encode(devicePublic.bytes),
        builder: const BuilderIdentity(
          displayName: 'Builder',
          phone: '+95912345678',
        ),
        activationAddress: builder,
      ),
      deviceKeyPair: deviceKey,
      now: now,
    );
    expect(review.responseId, 'RES-TEST-01');
    expect(review.setupSteps, contains('Starting Rewards: 1'));

    final Map<String, dynamic> altered =
        jsonDecode(result.qrValue) as Map<String, dynamic>;
    altered['request_id'] = 'ACT-ALTERED';
    expect(
      () => ActivationResponseService().inspect(
        encoded: jsonEncode(altered),
        request: DecodedActivationRequest(
          requestId: 'ACT-TEST-01',
          challenge: 'ABCDEFGHIJKLMNOPQRSTUVWX',
          expiresAt: now.add(const Duration(minutes: 15)),
          deviceId: _encode(List<int>.filled(16, 4)),
          devicePublicKey: _encode(devicePublic.bytes),
          builder: const BuilderIdentity(
            displayName: 'Builder',
            phone: '+95912345678',
          ),
          activationAddress: builder,
        ),
        deviceKeyPair: deviceKey,
        now: now,
      ),
      throwsFormatException,
    );
  });

  test('fails closed without one configured spendable Rewards asset', () async {
    final SimplePublicKey devicePublic = await (await X25519().newKeyPair())
        .extractPublicKey();
    final String account = const StrKeyCodec().encodeEd25519PublicKey(
      List<int>.filled(32, 1),
    );
    expect(
      () => ActivationResponseService().create(
        request: DecodedActivationRequest(
          requestId: 'ACT-TEST-01',
          challenge: 'ABCDEFGHIJKLMNOPQRSTUVWX',
          expiresAt: DateTime.utc(2030),
          deviceId: _encode(List<int>.filled(16, 4)),
          devicePublicKey: _encode(devicePublic.bytes),
          builder: const BuilderIdentity(
            displayName: 'Builder',
            phone: '+95912345678',
          ),
          activationAddress: account,
        ),
        configuration: ProviderConfiguration(
          endpoint: Uri.parse('https://xlm.nownodes.io'),
          apiKey: 'key',
          environment: ProviderEnvironment.test,
          version: 1,
        ),
        ledger: const DistributorLedgerStatus(
          nativeBalance: 20,
          nativeSellingLiabilities: 0,
          subentryCount: 0,
          sequence: '1',
          nonNativeSpendableBalances: <double>[],
          feeP95Stroops: 100,
        ),
        distributorAccount: account,
        distributorSecret: const StrKeyCodec().encodeEd25519SecretSeed(
          List<int>.filled(32, 0),
        ),
        now: DateTime.utc(2026, 9, 19),
        responseId: 'RES-TEST-01',
      ),
      throwsA(
        isA<WalletSdkException>().having(
          (WalletSdkException value) => value.code,
          'code',
          WalletSdkFailureCode.activationPolicyUnavailable,
        ),
      ),
    );
  });
}

String _encode(List<int> value) => base64Url.encode(value).replaceAll('=', '');
