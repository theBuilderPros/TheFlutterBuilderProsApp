import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_studio/app/constant/resources/app_colors.dart';
import 'package:the_builder_studio/app/core/base/base_view.dart';
import 'package:the_builder_studio/app/features/mini_app_host/controller/mini_app_host_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MiniAppHostScreen extends BaseView<MiniAppHostController> {
  const MiniAppHostScreen({super.key});

  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => controller.miniAppOpen.value
              ? Column(
                  children: [
                    _MiniAppTopBar(
                      status: controller.hostStatus.value,
                      onClose: controller.closeMiniApp,
                      onReload: controller.reloadMiniApp,
                    ),
                    Expanded(
                      child: WebViewWidget(
                        controller: controller.webViewController,
                      ),
                    ),
                  ],
                )
              : _MiniAppLanding(onOpen: controller.openMiniApp),
        ),
      ),
    );
  }
}

class _MiniAppLanding extends StatelessWidget {
  const _MiniAppLanding({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Mini App Host',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Open a bundled web mini app inside the BuilderStudio shell.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .32,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.accent,
                    AppColors.violet,
                  ],
                  stops: [0, .76, .76],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _HostCard(onOpen: onOpen),
        const SizedBox(height: 16),
        const _InfoCard(
          icon: Icons.security_rounded,
          title: 'Host controlled access',
          body:
              'The mini app asks Flutter before using profile, Rewards, or close actions.',
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          icon: Icons.offline_bolt_rounded,
          title: 'Bundled for demo',
          body:
              'The HTML, CSS, and JavaScript files are packaged as Flutter assets.',
        ),
      ],
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D231448),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.violetSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: AppColors.violet,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QuickPay Pass',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mini app bridge demo',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Mini App'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAppTopBar extends StatelessWidget {
  const _MiniAppTopBar({
    required this.status,
    required this.onClose,
    required this.onReload,
  });

  final String status;
  final VoidCallback onClose;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close mini app',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'QuickPay Pass',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(status, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Reload mini app',
            onPressed: onReload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
