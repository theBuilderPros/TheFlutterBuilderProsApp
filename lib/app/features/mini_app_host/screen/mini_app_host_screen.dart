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
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          const _StoreHeader(),
          const SizedBox(height: 14),
          _SearchPill(onOpen: onOpen),
          const SizedBox(height: 14),
          _PromoSlider(onOpen: onOpen),
          const SizedBox(height: 18),
          _MiniAppAccessPanel(onOpen: onOpen),
        ],
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back',
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Mini Apps',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'More',
          onPressed: () {},
          icon: const Icon(Icons.more_horiz_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Mini app center',
          onPressed: () {},
          icon: const Icon(Icons.radio_button_checked_rounded),
        ),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'New',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search mini apps',
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class _PromoSlider extends StatefulWidget {
  const _PromoSlider({required this.onOpen});

  final VoidCallback onOpen;

  @override
  State<_PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<_PromoSlider> {
  final PageController _pageController = PageController();
  int _activePage = 0;

  static const List<_MiniAppListing> _miniApps = [
    _MiniAppListing(
      title: 'Skino Mini',
      tag: 'Featured',
      description: 'Your blue mini app, opened inside BuilderStudio.',
      icon: Icons.bolt_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _miniApps.length,
            onPageChanged: (index) => setState(() => _activePage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == _miniApps.length - 1 ? 0 : 10,
                ),
                child: _PromoSlide(
                  miniApp: _miniApps[index],
                  onOpen: widget.onOpen,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _miniApps.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _activePage == index ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _activePage == index
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({required this.miniApp, required this.onOpen});

  final _MiniAppListing miniApp;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    miniApp.tag,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    miniApp.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    miniApp.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: FilledButton(
                      onPressed: onOpen,
                      child: const Text('Open Mini App'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniAppIcon(icon: miniApp.icon, size: 78, radius: 22),
                const SizedBox(height: 10),
                Container(
                  width: 54,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAppAccessPanel extends StatelessWidget {
  const _MiniAppAccessPanel({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recently Used',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      width: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'My Favorites',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onOpen,
              child: SizedBox(
                width: 94,
                child: Column(
                  children: [
                    const _MiniAppIcon(
                      icon: Icons.bolt_rounded,
                      size: 58,
                      radius: 17,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Skino Mini',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAppIcon extends StatelessWidget {
  const _MiniAppIcon({
    required this.icon,
    required this.size,
    required this.radius,
  });

  final IconData icon;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0F71D9),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: Colors.white, size: size * .48),
    );
  }
}

class _MiniAppListing {
  const _MiniAppListing({
    required this.title,
    required this.tag,
    required this.description,
    required this.icon,
  });

  final String title;
  final String tag;
  final String description;
  final IconData icon;
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
                  'Skino Mini',
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
