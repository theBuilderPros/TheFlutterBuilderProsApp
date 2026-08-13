import 'package:get/get.dart';
import 'package:the_builder_studio/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_studio/app/features/wallet/service/customer_access_import_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/recipient_validation_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_activation_storage_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_balance_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_signing_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_transaction_history_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_unlock_service.dart';
import 'package:the_builder_studio/app/features/wallet/utility/default_loyalty_points_sdk.dart';
import 'package:the_builder_studio/app/features/wallet/utility/loyalty_points_sdk.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CustomerAccessImportService>()) {
      Get.lazyPut(() => CustomerAccessImportService(), fenix: true);
    }
    if (!Get.isRegistered<WalletBalanceService>()) {
      Get.lazyPut(() => WalletBalanceService(), fenix: true);
    }
    if (!Get.isRegistered<WalletActivationStorageService>()) {
      Get.lazyPut(() => WalletActivationStorageService(), fenix: true);
    }
    if (!Get.isRegistered<WalletUnlockService>()) {
      Get.put(WalletUnlockService()..startLifecycleObserver(), permanent: true);
    }
    if (!Get.isRegistered<RecipientValidationService>()) {
      Get.lazyPut(() => RecipientValidationService(), fenix: true);
    }
    if (!Get.isRegistered<WalletSigningService>()) {
      Get.lazyPut(() => WalletSigningService(), fenix: true);
    }
    if (!Get.isRegistered<WalletTransactionHistoryService>()) {
      Get.lazyPut(() => WalletTransactionHistoryService(), fenix: true);
    }
    if (!Get.isRegistered<LoyaltyPointsSdk>()) {
      Get.lazyPut<LoyaltyPointsSdk>(
        () => DefaultLoyaltyPointsSdk(
          storageService: Get.find<WalletActivationStorageService>(),
          balanceService: Get.find<WalletBalanceService>(),
          unlockService: Get.find<WalletUnlockService>(),
          recipientValidationService: Get.find<RecipientValidationService>(),
          signingService: Get.find<WalletSigningService>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<WalletController>()) {
      Get.lazyPut(() => WalletController(), fenix: true);
    }
  }
}
