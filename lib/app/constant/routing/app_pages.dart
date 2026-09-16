import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/routing/app_route.dart';
import 'package:the_builder_pros/app/features/profile/binding/profile_binding.dart';
import 'package:the_builder_pros/app/features/profile/screen/profile_screen.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.profileScreen;

  static final routes = [
    GetPage(
      name: Routes.profileScreen,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
  ];
}
