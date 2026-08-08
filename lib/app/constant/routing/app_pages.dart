import 'package:get/get.dart';
import 'package:the_builder_studio/app/constant/routing/app_route.dart';
import 'package:the_builder_studio/app/features/mini_app_host/binding/mini_app_host_binding.dart';
import 'package:the_builder_studio/app/features/mini_app_host/screen/mini_app_host_screen.dart';
import 'package:the_builder_studio/app/features/profile/binding/profile_binding.dart';
import 'package:the_builder_studio/app/features/profile/screen/profile_screen.dart';

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
      name: Routes.miniAppHostScreen,
      page: () => const MiniAppHostScreen(),
      binding: MiniAppHostBinding(),
    ),
  ];
}
