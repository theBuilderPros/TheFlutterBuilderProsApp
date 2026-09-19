import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

abstract interface class DistributorAuthorityStore {
  Future<String?> readSecret();

  Future<void> writeSecret(String secret);

  Future<void> clear();
}

final class ProtectedDistributorAuthorityStore
    implements DistributorAuthorityStore {
  ProtectedDistributorAuthorityStore({FlutterSecureStorage? secureStorage})
    : _storage = secureStorage ?? const FlutterSecureStorage();

  static const String _key = 'rewards.app_master.distributor.secret.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readSecret() => _storage.read(key: _key);

  @override
  Future<void> writeSecret(String secret) =>
      _storage.write(key: _key, value: secret);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

abstract interface class DistributorAccountVerifier {
  Future<void> verify({
    required ProviderConfiguration configuration,
    required String accountId,
  });
}

final class HorizonDistributorAccountVerifier
    implements DistributorAccountVerifier {
  HorizonDistributorAccountVerifier({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<void> verify({
    required ProviderConfiguration configuration,
    required String accountId,
  }) async {
    final Uri endpoint = configuration.endpoint.replace(
      pathSegments: <String>[
        ...configuration.endpoint.pathSegments.where(
          (String segment) => segment.isNotEmpty,
        ),
        'accounts',
        accountId,
      ],
      query: null,
      fragment: null,
    );
    final http.Response response = await _client
        .get(
          endpoint,
          headers: <String, String>{
            'accept': 'application/json',
            'api-key': configuration.apiKey,
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 || response.bodyBytes.length > 64 * 1024) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.distributorAccountUnavailable,
        safeMessage: 'The distributor account could not be verified.',
        canRetry: true,
      );
    }
    final Object? decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['account_id'] != accountId) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.distributorAccountUnavailable,
        safeMessage: 'The distributor account could not be verified.',
        canRetry: true,
      );
    }
  }
}

final class DistributorAuthorityService {
  DistributorAuthorityService({
    required DistributorAuthorityStore store,
    required DistributorAccountVerifier verifier,
    StrKeyCodec strKeyCodec = const StrKeyCodec(),
    Ed25519? algorithm,
  }) : _store = store,
       _verifier = verifier,
       _strKeyCodec = strKeyCodec,
       _algorithm = algorithm ?? Ed25519();

  final DistributorAuthorityStore _store;
  final DistributorAccountVerifier _verifier;
  final StrKeyCodec _strKeyCodec;
  final Ed25519 _algorithm;

  Future<String> deriveAccountId(String secret) async {
    final List<int> seed = _strKeyCodec.decodeEd25519SecretSeed(secret);
    final SimpleKeyPair keyPair = await _algorithm.newKeyPairFromSeed(seed);
    final SimplePublicKey publicKey = await keyPair.extractPublicKey();
    return _strKeyCodec.encodeEd25519PublicKey(publicKey.bytes);
  }

  Future<void> verifyAndStore({
    required String secret,
    required ProviderConfiguration configuration,
  }) async {
    final String accountId = await deriveAccountId(secret);
    await _verifier.verify(configuration: configuration, accountId: accountId);
    await _store.writeSecret(secret);
  }

  Future<String?> readAccountId() async {
    final String? secret = await _store.readSecret();
    return secret == null ? null : deriveAccountId(secret);
  }

  Future<String?> readSecret() => _store.readSecret();

  Future<void> clear() => _store.clear();
}
