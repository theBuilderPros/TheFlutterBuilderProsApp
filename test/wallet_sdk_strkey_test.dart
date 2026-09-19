import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/wallet_key_generator.dart';

void main() {
  const StrKeyCodec codec = StrKeyCodec();

  group('StrKeyCodec', () {
    test('encodes official zero-value public key and seed vectors', () {
      final List<int> zeros = List<int>.filled(32, 0);

      expect(
        codec.encodeEd25519PublicKey(zeros),
        'GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF',
      );
      expect(
        codec.encodeEd25519SecretSeed(zeros),
        'SAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABSU2',
      );
    });

    test('round trips public keys and secret seeds', () {
      final List<int> bytes = List<int>.generate(32, (int index) => index);

      final String publicKey = codec.encodeEd25519PublicKey(bytes);
      final String secretSeed = codec.encodeEd25519SecretSeed(bytes);

      expect(codec.decodeEd25519PublicKey(publicKey), bytes);
      expect(codec.decodeEd25519SecretSeed(secretSeed), bytes);
    });

    test('rejects invalid official SEP-23 examples', () {
      const List<String> invalid = <String>[
        'GAAAAAAAACGC6',
        'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZA',
        'G47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVP2I',
      ];

      for (final String value in invalid) {
        expect(codec.isValidEd25519PublicKey(value), isFalse);
      }
    });

    test('rejects checksum changes and wrong key types', () {
      final String publicKey = codec.encodeEd25519PublicKey(
        List<int>.filled(32, 7),
      );
      final String changed = '${publicKey.substring(0, 55)}A';
      final String secretSeed = codec.encodeEd25519SecretSeed(
        List<int>.filled(32, 7),
      );

      expect(codec.isValidEd25519PublicKey(changed), isFalse);
      expect(codec.isValidEd25519PublicKey(secretSeed), isFalse);
      expect(codec.isValidEd25519SecretSeed(publicKey), isFalse);
    });
  });

  test(
    'WalletKeyGenerator derives an Ed25519 public key from its seed',
    () async {
      final WalletKeyPair generated = await WalletKeyGenerator(
        random: _ZeroRandom(),
      ).generate();

      expect(generated.secretSeed, startsWith('S'));
      expect(generated.accountId, startsWith('G'));
      expect(
        codec.decodeEd25519SecretSeed(generated.secretSeed),
        List<int>.filled(32, 0),
      );
      expect(
        _hex(codec.decodeEd25519PublicKey(generated.accountId)),
        '3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29',
      );
    },
  );
}

String _hex(List<int> bytes) =>
    bytes.map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join();

final class _ZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
