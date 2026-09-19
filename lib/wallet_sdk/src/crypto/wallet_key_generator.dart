import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';

final class WalletKeyPair {
  const WalletKeyPair({required this.accountId, required this.secretSeed});

  final String accountId;
  final String secretSeed;
}

final class WalletKeyGenerator {
  WalletKeyGenerator({
    Random? random,
    Ed25519? algorithm,
    StrKeyCodec strKeyCodec = const StrKeyCodec(),
  }) : _random = random ?? Random.secure(),
       _algorithm = algorithm ?? Ed25519(),
       _strKeyCodec = strKeyCodec;

  final Random _random;
  final Ed25519 _algorithm;
  final StrKeyCodec _strKeyCodec;

  Future<WalletKeyPair> generate() async {
    final Uint8List seed = Uint8List.fromList(
      List<int>.generate(32, (_) => _random.nextInt(256), growable: false),
    );
    final SimpleKeyPair keyPair = await _algorithm.newKeyPairFromSeed(seed);
    final SimplePublicKey publicKey = await keyPair.extractPublicKey();
    return WalletKeyPair(
      accountId: _strKeyCodec.encodeEd25519PublicKey(publicKey.bytes),
      secretSeed: _strKeyCodec.encodeEd25519SecretSeed(seed),
    );
  }
}
