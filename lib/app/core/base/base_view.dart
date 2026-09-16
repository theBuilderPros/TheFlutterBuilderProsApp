import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/core/base/base_controller.dart';

abstract class BaseView<T extends BaseController> extends GetView<T> {
  const BaseView({super.key});

  Widget buildView(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          buildView(context),
          if (controller.isLoading.value)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
