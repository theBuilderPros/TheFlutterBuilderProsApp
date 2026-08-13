class LoyaltyBalanceResult {
  const LoyaltyBalanceResult({required this.balance, required this.assetCode});

  final String balance;
  final String assetCode;
}

class LoyaltySendResult {
  const LoyaltySendResult({
    required this.transactionHash,
    required this.updatedBalance,
  });

  final String transactionHash;
  final String updatedBalance;
}

class LoyaltyPointsFailure implements Exception {
  const LoyaltyPointsFailure({
    required this.code,
    required this.message,
    this.cause,
  });

  final String code;
  final String message;
  final Object? cause;

  static const configurationMissing = LoyaltyPointsFailure(
    code: 'configurationMissing',
    message: 'Wallet configuration is missing.',
  );

  static const notActivated = LoyaltyPointsFailure(
    code: 'notActivated',
    message: 'Activate your wallet before using this action.',
  );

  static const walletLocked = LoyaltyPointsFailure(
    code: 'walletLocked',
    message: 'Wallet is locked. Unlock it to send points.',
  );

  static const invalidAmount = LoyaltyPointsFailure(
    code: 'invalidAmount',
    message: 'Enter a valid amount greater than zero.',
  );

  static LoyaltyPointsFailure invalidRecipient(String message) {
    return LoyaltyPointsFailure(code: 'invalidRecipient', message: message);
  }

  static LoyaltyPointsFailure networkUnavailable(Object cause) {
    return LoyaltyPointsFailure(
      code: 'networkUnavailable',
      message: 'Network is unavailable. Please try again.',
      cause: cause,
    );
  }

  static LoyaltyPointsFailure transactionRejected(String message) {
    return LoyaltyPointsFailure(code: 'transactionRejected', message: message);
  }
}
