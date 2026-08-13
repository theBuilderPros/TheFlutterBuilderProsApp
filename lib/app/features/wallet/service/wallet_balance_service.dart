import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:the_builder_studio/app/core/config/loyalty_system_config.dart';
import 'package:the_builder_studio/app/features/wallet/model/customer_wallet_access.dart';

class WalletBalanceService {
  Future<String> fetchBalance({
    required LoyaltySystemConfig config,
    required CustomerWalletAccess walletAccess,
  }) async {
    final accountUri = Uri.parse(
      '${config.horizonUrl}/accounts/${walletAccess.publicKey}',
    );
    final response = await http.get(
      accountUri,
      headers: {'Accept': 'application/json', 'api-key': config.nownodeApiKey},
    );

    if (response.statusCode == 404) {
      return '0';
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WalletBalanceFailure(
        'Could not load wallet balance from Horizon (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final balances = body['balances'];
    if (balances is! List) {
      return '0';
    }

    final selectedAssetCode = walletAccess.assetCode.isNotEmpty
        ? walletAccess.assetCode
        : config.assetCode;

    for (final item in balances) {
      final balance = Map<String, dynamic>.from(item as Map);
      final isMatchingAsset =
          balance['asset_type'] != 'native' &&
          balance['asset_code'] == selectedAssetCode &&
          (config.issuerPublicKey.isEmpty ||
              balance['asset_issuer'] == config.issuerPublicKey);
      if (isMatchingAsset) {
        return (balance['balance'] ?? '0').toString();
      }
    }

    return '0';
  }
}

class WalletBalanceFailure implements Exception {
  const WalletBalanceFailure(this.message);

  final String message;
}
