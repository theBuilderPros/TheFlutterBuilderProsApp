import 'package:the_builder_studio/app/core/config/loyalty_system_config.dart';
import 'package:the_builder_studio/app/features/wallet/service/recipient_validation_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_activation_storage_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_balance_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_signing_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_unlock_service.dart';
import 'package:the_builder_studio/app/features/wallet/utility/loyalty_points_result.dart';
import 'package:the_builder_studio/app/features/wallet/utility/loyalty_points_sdk.dart';

class DefaultLoyaltyPointsSdk implements LoyaltyPointsSdk {
  const DefaultLoyaltyPointsSdk({
    required WalletActivationStorageService storageService,
    required WalletBalanceService balanceService,
    required WalletUnlockService unlockService,
    required RecipientValidationService recipientValidationService,
    required WalletSigningService signingService,
  }) : _storageService = storageService,
       _balanceService = balanceService,
       _unlockService = unlockService,
       _recipientValidationService = recipientValidationService,
       _signingService = signingService;

  final WalletActivationStorageService _storageService;
  final WalletBalanceService _balanceService;
  final WalletUnlockService _unlockService;
  final RecipientValidationService _recipientValidationService;
  final WalletSigningService _signingService;

  @override
  Future<LoyaltyBalanceResult> checkBalance() async {
    final config = await _loadConfig();
    final walletAccess = await _storageService.restoreWalletAccess();
    if (walletAccess == null) {
      throw LoyaltyPointsFailure.notActivated;
    }

    try {
      final balance = await _balanceService.fetchBalance(
        config: config,
        walletAccess: walletAccess,
      );
      return LoyaltyBalanceResult(
        balance: balance,
        assetCode: walletAccess.assetCode.isNotEmpty
            ? walletAccess.assetCode
            : config.assetCode,
      );
    } on WalletBalanceFailure catch (error) {
      throw LoyaltyPointsFailure.networkUnavailable(error);
    }
  }

  @override
  Future<LoyaltySendResult> send({
    required String recipient,
    required String amount,
  }) async {
    final config = await _loadConfig();
    final walletAccess = await _storageService.restoreWalletAccess();
    if (walletAccess == null) {
      throw LoyaltyPointsFailure.notActivated;
    }

    final normalizedAmount = amount.trim();
    final parsedAmount = double.tryParse(normalizedAmount);
    if (parsedAmount == null || parsedAmount <= 0) {
      throw LoyaltyPointsFailure.invalidAmount;
    }

    final normalizedRecipient = recipient.trim();
    final recipientResult = await _recipientValidationService.validate(
      config: config,
      recipientPublicKey: normalizedRecipient,
    );
    if (!recipientResult.isValid) {
      throw LoyaltyPointsFailure.invalidRecipient(recipientResult.message);
    }

    final secret = _unlockService.unlockedSecret;
    if (secret == null || secret.isEmpty) {
      throw LoyaltyPointsFailure.walletLocked;
    }

    try {
      final submission = await _signingService.sendPayment(
        config: config,
        senderSecret: secret,
        recipientPublicKey: normalizedRecipient,
        amount: normalizedAmount,
      );
      final updatedBalance = await _balanceService.fetchBalance(
        config: config,
        walletAccess: walletAccess,
      );
      return LoyaltySendResult(
        transactionHash: submission.transactionHash,
        updatedBalance: updatedBalance,
      );
    } on WalletSigningFailure catch (error) {
      throw LoyaltyPointsFailure.transactionRejected(error.message);
    } on WalletBalanceFailure catch (error) {
      throw LoyaltyPointsFailure.networkUnavailable(error);
    }
  }

  Future<LoyaltySystemConfig> _loadConfig() async {
    try {
      return await LoyaltySystemConfig.loadLocal();
    } on LoyaltySystemConfigMissing {
      throw LoyaltyPointsFailure.configurationMissing;
    } on LoyaltySystemConfigFailure catch (error) {
      throw LoyaltyPointsFailure(
        code: 'configurationInvalid',
        message: error.message,
        cause: error,
      );
    }
  }
}
