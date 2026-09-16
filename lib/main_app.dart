import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/resources/app_string.dart';
import 'package:the_builder_pros/app/constant/resources/app_theme.dart';
import 'package:the_builder_pros/app/constant/routing/app_pages.dart';
import 'package:the_builder_pros/app/constant/routing/app_route.dart';
import 'package:the_builder_pros/app/core/binding/initial_binding.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppString.appName,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
      theme: AppTheme.lightTheme,
      initialRoute: Routes.profileScreen,
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
    );
  }
}
