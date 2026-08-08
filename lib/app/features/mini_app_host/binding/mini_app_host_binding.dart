import 'package:get/get.dart';
import 'package:the_builder_studio/app/features/mini_app_host/controller/mini_app_host_controller.dart';

class MiniAppHostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MiniAppHostController(), fenix: true);
  }
}
