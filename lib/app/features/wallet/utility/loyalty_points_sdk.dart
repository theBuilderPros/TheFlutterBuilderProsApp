import 'package:the_builder_studio/app/features/wallet/utility/loyalty_points_result.dart';

abstract interface class LoyaltyPointsSdk {
  Future<LoyaltyBalanceResult> checkBalance();

  Future<LoyaltySendResult> send({
    required String recipient,
    required String amount,
  });
}
