import 'package:get/get.dart';
import 'package:the_builder_studio/app/constant/routing/app_route.dart';
import 'package:the_builder_studio/app/features/profile/binding/profile_binding.dart';
import 'package:the_builder_studio/app/features/profile/screen/profile_screen.dart';
import 'package:the_builder_studio/app/features/wallet/binding/wallet_binding.dart';
import 'package:the_builder_studio/app/features/wallet/screen/receive_screen.dart';
import 'package:the_builder_studio/app/features/wallet/screen/send_review_screen.dart';
import 'package:the_builder_studio/app/features/wallet/screen/send_scan_screen.dart';
import 'package:the_builder_studio/app/features/wallet/screen/send_screen.dart';
import 'package:the_builder_studio/app/features/wallet/screen/transaction_history_screen.dart';
import 'package:the_builder_studio/app/features/wallet/screen/wallet_screen.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.profileScreen;

  static final routes = [
    GetPage(
      name: Routes.profileScreen,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.wallet,
      page: () => const WalletScreen(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: Routes.walletReceive,
      page: () => const WalletReceiveScreen(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: Routes.walletSend,
      page: () => const WalletSendScreen(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: Routes.walletSendScan,
      page: () => const WalletSendScanScreen(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: Routes.walletSendReview,
      page: () => const WalletSendReviewScreen(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: Routes.walletHistory,
      page: () => const WalletTransactionHistoryScreen(),
      binding: WalletBinding(),
    ),
  ];
}
