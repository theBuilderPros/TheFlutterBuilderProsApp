import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/routing/app_route.dart';
import 'package:the_builder_pros/app/features/app_master/binding/app_master_binding.dart';
import 'package:the_builder_pros/app/features/app_master/screen/app_master_screens.dart';
import 'package:the_builder_pros/app/features/wallet/binding/wallet_binding.dart';
import 'package:the_builder_pros/app/features/wallet/screen/wallet_screens.dart';

class AppPages {
  AppPages._();

  static const String initial = Routes.wallet;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: Routes.wallet,
      page: WalletNotActivatedScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletActivation,
      page: WalletActivationRequestScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletActivationScan,
      page: WalletActivationScanScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletActivationReview,
      page: WalletActivationReviewScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletOverview,
      page: WalletOverviewScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletReceive,
      page: WalletReceiveScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletSendScan,
      page: WalletSendScanScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletSendAmount,
      page: WalletSendAmountScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletSendReview,
      page: WalletSendReviewScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletSendOutcome,
      page: WalletSendOutcomeScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletHistory,
      page: WalletHistoryScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletLocked,
      page: WalletLockedScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletAuthentication,
      page: WalletAuthenticationScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.walletRemove,
      page: WalletRemoveScreen.new,
      binding: WalletBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.appMaster,
      page: AppMasterDashboardScreen.new,
      binding: AppMasterBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.appMasterAdvanced,
      page: AppMasterAdvancedScreen.new,
      binding: AppMasterBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.appMasterActivationScan,
      page: AppMasterActivationScanScreen.new,
      binding: AppMasterBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.appMasterActivationReview,
      page: AppMasterActivationReviewScreen.new,
      binding: AppMasterBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.appMasterActivationQr,
      page: AppMasterActivationQrScreen.new,
      binding: AppMasterBinding(),
    ),
  ];
}
