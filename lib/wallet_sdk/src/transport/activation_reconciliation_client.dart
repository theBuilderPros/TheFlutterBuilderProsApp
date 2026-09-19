import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';

enum ActivationReconciliationResult { pending, verified, failed }

abstract interface class ActivationReconciliationClient {
  Future<ActivationReconciliationResult> reconcile({
    required ProviderConfiguration configuration,
    required String transactionHash,
    required String builderAccount,
    required String assetCode,
    required String assetIssuer,
    required double minimumRewards,
  });
}

final class DirectActivationReconciliationClient
    implements ActivationReconciliationClient {
  DirectActivationReconciliationClient({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<ActivationReconciliationResult> reconcile({
    required ProviderConfiguration configuration,
    required String transactionHash,
    required String builderAccount,
    required String assetCode,
    required String assetIssuer,
    required double minimumRewards,
  }) async {
    try {
      final http.Response transaction = await _get(configuration, <String>[
        'transactions',
        transactionHash,
      ]);
      if (transaction.statusCode == 404) {
        return ActivationReconciliationResult.pending;
      }
      if (transaction.statusCode != 200 ||
          transaction.bodyBytes.length > 128 * 1024) {
        return ActivationReconciliationResult.pending;
      }
      final Map<String, dynamic> transactionJson =
          jsonDecode(utf8.decode(transaction.bodyBytes))
              as Map<String, dynamic>;
      if (transactionJson['successful'] != true) {
        return ActivationReconciliationResult.failed;
      }
      final http.Response account = await _get(configuration, <String>[
        'accounts',
        builderAccount,
      ]);
      if (account.statusCode == 404) {
        return ActivationReconciliationResult.pending;
      }
      if (account.statusCode != 200 || account.bodyBytes.length > 128 * 1024) {
        return ActivationReconciliationResult.pending;
      }
      final Map<String, dynamic> accountJson =
          jsonDecode(utf8.decode(account.bodyBytes)) as Map<String, dynamic>;
      if (accountJson['account_id'] != builderAccount) {
        return ActivationReconciliationResult.failed;
      }
      final List<dynamic> balances = accountJson['balances'] as List<dynamic>;
      final bool verified = balances.any((dynamic raw) {
        final Map<String, dynamic> balance = raw as Map<String, dynamic>;
        return balance['asset_code'] == assetCode &&
            balance['asset_issuer'] == assetIssuer &&
            double.parse(balance['balance'] as String) >= minimumRewards;
      });
      return verified
          ? ActivationReconciliationResult.verified
          : ActivationReconciliationResult.failed;
    } catch (_) {
      return ActivationReconciliationResult.pending;
    }
  }

  Future<http.Response> _get(
    ProviderConfiguration configuration,
    List<String> segments,
  ) => _client.get(
    configuration.endpoint.replace(
      pathSegments: <String>[
        ...configuration.endpoint.pathSegments.where(
          (String value) => value.isNotEmpty,
        ),
        ...segments,
      ],
      query: null,
      fragment: null,
    ),
    headers: <String, String>{
      'accept': 'application/json',
      'api-key': configuration.apiKey,
    },
  );
}
