import 'package:get/get.dart';
import 'package:the_builder_pros/app/features/app_master/controller/app_master_controller.dart';
import 'package:the_builder_pros/app/features/app_master/service/qr_input_adapter.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

class AppMasterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AppMasterController>()) {
      Get.put<AppMasterController>(
        AppMasterController(
          Get.find<WalletSdk>(),
          qrInputAdapter: Get.isRegistered<QrInputAdapter>()
              ? Get.find<QrInputAdapter>()
              : null,
        ),
        permanent: true,
      );
    }
  }
}
