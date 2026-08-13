import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:the_builder_studio/app/core/config/loyalty_system_config.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class RecipientValidationService {
  Future<RecipientValidationResult> validate({
    required LoyaltySystemConfig config,
    required String recipientPublicKey,
  }) async {
    if (!_isValidPublicKey(recipientPublicKey)) {
      return const RecipientValidationResult.invalid(
        'That QR does not contain a valid Stellar public key.',
      );
    }

    final accountUri = Uri.parse(
      '${config.horizonUrl}/accounts/$recipientPublicKey',
    );
    final response = await http.get(
      accountUri,
      headers: {'Accept': 'application/json', 'api-key': config.nownodeApiKey},
    );

    if (response.statusCode == 404) {
      return const RecipientValidationResult.invalid(
        'Recipient account was not found on the Stellar network.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return RecipientValidationResult.invalid(
        'Could not validate recipient right now (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final balances = body['balances'];
    if (balances is! List) {
      return const RecipientValidationResult.invalid(
        'Recipient account could not be checked for a trustline.',
      );
    }

    final hasTrustline = balances.any((item) {
      final balance = Map<String, dynamic>.from(item as Map);
      return balance['asset_type'] != 'native' &&
          balance['asset_code'] == config.assetCode &&
          balance['asset_issuer'] == config.issuerPublicKey;
    });

    if (!hasTrustline) {
      return RecipientValidationResult.invalid(
        'Recipient is missing a ${config.assetCode} trustline.',
      );
    }

    return const RecipientValidationResult.valid();
  }

  bool _isValidPublicKey(String publicKey) {
    if (!RegExp(r'^G[A-Z2-7]{55}$').hasMatch(publicKey)) {
      return false;
    }
    try {
      KeyPair.fromAccountId(publicKey);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class RecipientValidationResult {
  const RecipientValidationResult._({
    required this.isValid,
    required this.message,
  });

  const RecipientValidationResult.valid()
    : this._(isValid: true, message: 'Recipient is ready to receive points.');

  const RecipientValidationResult.invalid(String message)
    : this._(isValid: false, message: message);

  final bool isValid;
  final String message;
}
