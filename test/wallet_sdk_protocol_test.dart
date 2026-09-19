import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/protocol/stellar_activation_protocol.dart';
import 'package:the_builder_pros/wallet_sdk/src/protocol/xdr/xdr_codec.dart';

void main() {
  const StrKeyCodec strKey = StrKeyCodec();
  final StellarActivationProtocol protocol = StellarActivationProtocol();
  // RFC 8032 Ed25519 public key derived from the all-zero 32-byte seed.
  final String distributor = strKey.encodeEd25519PublicKey(
    _fromHex(
      '3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29',
    ),
  );
  final String builder = strKey.encodeEd25519PublicKey(
    List<int>.generate(32, (int index) => 31 - index),
  );
  final String issuer = strKey.encodeEd25519PublicKey(List<int>.filled(32, 7));

  group('RFC 4506 codec', () {
    test('encodes signed values and variable opaque padding byte-for-byte', () {
      final Uint8List bytes =
          (XdrWriter()
                ..writeInt32(-1)
                ..writeUint32(0xffffffff)
                ..writeInt64(-2)
                ..writeVariableOpaque(<int>[1, 2, 3], 3))
              .takeBytes();

      expect(_hex(bytes), 'fffffffffffffffffffffffffffffffe0000000301020300');
    });

    test('round trips bounded primitives', () {
      final Uint8List encoded =
          (XdrWriter()
                ..writeBool(true)
                ..writeUint64(42)
                ..writeFixedOpaque(<int>[1, 2, 3, 4, 5], 5))
              .takeBytes();
      final XdrReader reader = XdrReader(encoded);

      expect(reader.readBool(), isTrue);
      expect(reader.readUint64(), 42);
      expect(reader.readFixedOpaque(5), <int>[1, 2, 3, 4, 5]);
      reader.ensureFinished();
    });

    test('rejects truncation, non-zero padding, invalid bools, and bounds', () {
      expect(() => XdrReader(<int>[0]).readInt32(), throwsFormatException);
      expect(
        () => XdrReader(<int>[0, 0, 0, 1, 7, 1, 0, 0])..readVariableOpaque(1),
        throwsFormatException,
      );
      expect(
        () => XdrReader(<int>[0, 0, 0, 2]).readBool(),
        throwsFormatException,
      );
      expect(
        () => XdrReader(<int>[0, 0, 0, 2]).readArrayLength(1),
        throwsFormatException,
      );
    });
  });

  group('limited Stellar activation protocol', () {
    test(
      'passes the RFC 8032 Ed25519 empty-message signature vector',
      () async {
        final SimpleKeyPair keyPair = await Ed25519().newKeyPairFromSeed(
          _fromHex(
            '9d61b19deffd5a60ba844af492ec2cc4'
            '4449c5697b326919703bac031cae7f60',
          ),
        );

        final Signature signature = await Ed25519().sign(
          const <int>[],
          keyPair: keyPair,
        );

        expect(
          _hex(signature.bytes),
          'e5564300c360ac729086e2cc806e828a'
          '84877f1eb8e5d974d873e06522490155'
          '5fb8821590a33bacc61e39701cf9b46b'
          'd25bf5f0595bbe24655141438e7a100b',
        );
      },
    );

    test('round trips all three allowed operations and time bounds', () {
      final StellarActivationEnvelope original = _activationEnvelope(
        distributor: distributor,
        builder: builder,
        issuer: issuer,
      );

      final Uint8List encoded = protocol.encodeEnvelope(original);
      final StellarActivationEnvelope decoded = protocol.decodeEnvelope(
        encoded,
      );

      expect(decoded.sourceAccount, distributor);
      expect(decoded.fee, 300);
      expect(decoded.sequenceNumber, 123456789);
      expect(decoded.minTime, 1700000000);
      expect(decoded.maxTime, 1700000900);
      expect(
        decoded.operations.map((StellarActivationOperation op) => op.type),
        <StellarActivationOperationType>[
          StellarActivationOperationType.createAccount,
          StellarActivationOperationType.changeTrust,
          StellarActivationOperationType.payment,
        ],
      );
      final StellarChangeTrustOperation trust =
          decoded.operations[1] as StellarChangeTrustOperation;
      expect(trust.sourceAccount, builder);
      expect(trust.asset, StellarAsset.credit(code: 'REWARD', issuer: issuer));
      expect(protocol.encodeEnvelope(decoded), encoded);
      expect(
        protocol.decodeEnvelopeBase64(base64Encode(encoded)).operations.length,
        3,
      );
    });

    test(
      'preserves existing signatures while adding and verifying another',
      () async {
        final StellarActivationEnvelope original =
            _activationEnvelope(
              distributor: distributor,
              builder: builder,
              issuer: issuer,
            ).withSignatures(<StellarDecoratedSignature>[
              StellarDecoratedSignature(
                hint: <int>[9, 9, 9, 9],
                signature: List<int>.filled(64, 4),
              ),
            ]);
        final String seed = strKey.encodeEd25519SecretSeed(
          List<int>.filled(32, 0),
        );

        final StellarActivationEnvelope signed = await protocol.sign(
          original,
          secretSeed: seed,
          networkPassphrase: StellarActivationProtocol.testNetworkPassphrase,
        );

        expect(signed.signatures.length, 2);
        expect(signed.signatures.first.hint, <int>[9, 9, 9, 9]);
        expect(
          await protocol.verifySignature(
            signed,
            signature: signed.signatures.last,
            publicAccount: distributor,
            networkPassphrase: StellarActivationProtocol.testNetworkPassphrase,
          ),
          isTrue,
        );
        expect(
          await protocol.verifySignature(
            signed,
            signature: signed.signatures.last,
            publicAccount: distributor,
            networkPassphrase:
                StellarActivationProtocol.publicNetworkPassphrase,
          ),
          isFalse,
        );
      },
    );

    test(
      'transaction hash is stable and excludes envelope signatures',
      () async {
        final StellarActivationEnvelope original = _activationEnvelope(
          distributor: distributor,
          builder: builder,
          issuer: issuer,
        );
        final StellarActivationEnvelope decorated = original.withSignatures(
          <StellarDecoratedSignature>[
            StellarDecoratedSignature(
              hint: <int>[1, 2, 3, 4],
              signature: List<int>.filled(64, 8),
            ),
          ],
        );

        expect(
          await protocol.transactionHash(
            decorated,
            StellarActivationProtocol.testNetworkPassphrase,
          ),
          await protocol.transactionHash(
            original,
            StellarActivationProtocol.testNetworkPassphrase,
          ),
        );
      },
    );

    test('rejects unsupported envelope and operation discriminants', () {
      final Uint8List encoded = protocol.encodeEnvelope(
        _activationEnvelope(
          distributor: distributor,
          builder: builder,
          issuer: issuer,
        ),
      );
      final Uint8List wrongEnvelope = Uint8List.fromList(encoded)
        ..setRange(0, 4, <int>[0, 0, 0, 5]);
      final Uint8List wrongOperation = Uint8List.fromList(encoded);
      // V1 tag(4), source(36), fee(4), seq(8), time cond+bounds(20),
      // memo(4), array count(4), optional source bool(4): op tag starts at 84.
      wrongOperation.setRange(84, 88, <int>[0, 0, 0, 5]);

      expect(
        () => protocol.decodeEnvelope(wrongEnvelope),
        throwsFormatException,
      );
      expect(
        () => protocol.decodeEnvelope(wrongOperation),
        throwsFormatException,
      );
    });

    test('rejects trailing, truncated, and mutated signature data', () {
      final Uint8List encoded = protocol.encodeEnvelope(
        _activationEnvelope(
          distributor: distributor,
          builder: builder,
          issuer: issuer,
        ),
      );
      expect(
        () => protocol.decodeEnvelope(<int>[...encoded, 0]),
        throwsFormatException,
      );
      expect(
        () => protocol.decodeEnvelope(encoded.sublist(0, encoded.length - 1)),
        throwsFormatException,
      );
    });
  });
}

StellarActivationEnvelope _activationEnvelope({
  required String distributor,
  required String builder,
  required String issuer,
}) => StellarActivationEnvelope(
  sourceAccount: distributor,
  fee: 300,
  sequenceNumber: 123456789,
  minTime: 1700000000,
  maxTime: 1700000900,
  operations: <StellarActivationOperation>[
    StellarCreateAccountOperation(
      destination: builder,
      startingBalance: 21000000,
    ),
    StellarChangeTrustOperation(
      sourceAccount: builder,
      asset: StellarAsset.credit(code: 'REWARD', issuer: issuer),
      limit: 9223372036854775807,
    ),
    StellarPaymentOperation(
      destination: builder,
      asset: StellarAsset.credit(code: 'REWARD', issuer: issuer),
      amount: 10000000,
    ),
  ],
);

String _hex(List<int> bytes) =>
    bytes.map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join();

List<int> _fromHex(String value) => List<int>.generate(
  value.length ~/ 2,
  (int index) =>
      int.parse(value.substring(index * 2, index * 2 + 2), radix: 16),
);
