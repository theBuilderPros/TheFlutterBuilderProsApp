import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:the_builder_studio/app/core/config/loyalty_system_config.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class WalletSigningService {
  Future<WalletSubmissionResult> sendPayment({
    required LoyaltySystemConfig config,
    required String senderSecret,
    required String recipientPublicKey,
    required String amount,
  }) async {
    try {
      final senderKeyPair = KeyPair.fromSecretSeed(senderSecret);
      final senderAccount = await _loadAccount(
        config: config,
        publicKey: senderKeyPair.accountId,
      );
      final asset = Asset.createNonNativeAsset(
        config.assetCode,
        config.issuerPublicKey,
      );

      final transaction = TransactionBuilder(senderAccount)
          .addOperation(
            PaymentOperationBuilder(recipientPublicKey, asset, amount).build(),
          )
          .build();

      transaction.sign(senderKeyPair, _networkFor(config.networkName));
      final envelope = transaction.toEnvelopeXdrBase64();
      final response = await http.post(
        Uri.parse('${config.horizonUrl}/transactions'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          'api-key': config.nownodeApiKey,
        },
        body: {'tx': envelope},
      );

      if (response.statusCode != 200 && response.statusCode != 400) {
        throw WalletSigningFailure(
          'Horizon submission failed (${response.statusCode}).',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final submission = SubmitTransactionResponse.fromJson(body);
      if (!submission.success) {
        final codes = submission.extras?.resultCodes;
        final operationCode = codes?.operationsResultCodes?.join(', ');
        final message = operationCode?.isNotEmpty == true
            ? operationCode!
            : codes?.transactionResultCode ?? 'Transaction was rejected.';
        throw WalletSigningFailure(_friendlySubmissionMessage(message));
      }

      return WalletSubmissionResult(transactionHash: submission.hash ?? '');
    } on WalletSigningFailure {
      rethrow;
    } catch (_) {
      throw const WalletSigningFailure(
        'Could not submit the transaction. Check the network and try again.',
      );
    }
  }

  Future<AccountResponse> _loadAccount({
    required LoyaltySystemConfig config,
    required String publicKey,
  }) async {
    final response = await http.get(
      Uri.parse('${config.horizonUrl}/accounts/$publicKey'),
      headers: {'Accept': 'application/json', 'api-key': config.nownodeApiKey},
    );
    if (response.statusCode == 404) {
      throw const WalletSigningFailure('Sender wallet account was not found.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WalletSigningFailure(
        'Could not load sender account (${response.statusCode}).',
      );
    }
    return AccountResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Network _networkFor(String networkName) {
    final normalized = networkName.toLowerCase();
    if (normalized.contains('public')) {
      return Network.PUBLIC;
    }
    if (normalized.contains('future')) {
      return Network.FUTURENET;
    }
    if (normalized.contains('test')) {
      return Network.TESTNET;
    }
    return Network(networkName);
  }

  String _friendlySubmissionMessage(String code) {
    if (code.contains('op_underfunded') ||
        code.contains('tx_insufficient_balance')) {
      return 'Insufficient balance for this payment.';
    }
    if (code.contains('op_no_destination')) {
      return 'Recipient account was not found.';
    }
    if (code.contains('op_no_trust')) {
      return 'Recipient is missing the required trustline.';
    }
    return 'Transaction submission failed: $code';
  }
}

class WalletSubmissionResult {
  const WalletSubmissionResult({required this.transactionHash});

  final String transactionHash;
}

class WalletSigningFailure implements Exception {
  const WalletSigningFailure(this.message);

  final String message;
}
