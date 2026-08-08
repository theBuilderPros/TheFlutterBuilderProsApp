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
          const _PromoSearchBar(),
          const SizedBox(height: 14),
          _HeroBanner(onOpen: onOpen),
          const SizedBox(height: 18),
          _RecentPanel(onOpen: onOpen),
          const SizedBox(height: 20),
          const _CategoryRail(),
          const SizedBox(height: 22),
          _MiniAppGrid(onOpen: onOpen),
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
          icon: const Icon(Icons.trip_origin_rounded),
        ),
      ],
    );
  }
}

class _PromoSearchBar extends StatelessWidget {
  const _PromoSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D231448),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'New',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search Builder services',
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.violet, Color(0xFF241A66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24231448),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'BuilderStudio Mini App',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'QuickPay Pass',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Open a fast local mini app for rewards and service actions.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .88),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onOpen,
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text('Open'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 92,
            height: 116,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.accent,
                    size: 34,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 14,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.violetSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppColors.violet,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPanel extends StatelessWidget {
  const _RecentPanel({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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
                child: _SegmentLabel(
                  active: true,
                  icon: Icons.history_rounded,
                  label: 'Recently Used',
                ),
              ),
              Expanded(
                child: _SegmentLabel(
                  active: false,
                  icon: Icons.favorite_border_rounded,
                  label: 'My Favorites',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniAppShortcut(
                  color: AppColors.accent,
                  icon: Icons.bolt_rounded,
                  label: 'QuickPay',
                  onTap: onOpen,
                ),
              ),
              const Expanded(
                child: _MiniAppShortcut(
                  color: AppColors.violet,
                  icon: Icons.workspace_premium_rounded,
                  label: 'Reward ID',
                ),
              ),
              const Expanded(
                child: _MiniAppShortcut(
                  color: Color(0xFF1F8F8A),
                  icon: Icons.notifications_active_rounded,
                  label: 'Updates',
                ),
              ),
              const Expanded(
                child: _MiniAppShortcut(
                  color: Color(0xFF3F6FD8),
                  icon: Icons.fact_check_rounded,
                  label: 'Evidence',
                ),
              ),
              const Expanded(
                child: _MiniAppShortcut(
                  color: Color(0xFF20242A),
                  icon: Icons.grid_view_rounded,
                  label: 'More',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.active,
    required this.icon,
    required this.label,
  });

  final bool active;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 56,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }
}

class _MiniAppShortcut extends StatelessWidget {
  const _MiniAppShortcut({
    required this.color,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail();

  @override
  Widget build(BuildContext context) {
    const categories = [
      _CategoryData(Icons.auto_awesome_rounded, 'For You', AppColors.accent),
      _CategoryData(Icons.school_rounded, 'Learning', Color(0xFF3F6FD8)),
      _CategoryData(Icons.card_giftcard_rounded, 'Rewards', AppColors.violet),
      _CategoryData(Icons.travel_explore_rounded, 'Events', Color(0xFF1F8F8A)),
      _CategoryData(Icons.workspaces_rounded, 'Services', Color(0xFF20242A)),
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryItem(category: category, active: index == 0);
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.category, required this.active});

  final _CategoryData category;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: active ? .14 : .08),
              borderRadius: BorderRadius.circular(16),
              border: active
                  ? Border.all(color: category.color.withValues(alpha: .36))
                  : null,
            ),
            child: Icon(category.icon, color: category.color),
          ),
          const SizedBox(height: 8),
          Text(
            category.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? category.color : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAppGrid extends StatelessWidget {
  const _MiniAppGrid({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MiniAppData(
        icon: Icons.bolt_rounded,
        title: 'QuickPay Pass',
        subtitle: 'Rewards action',
        color: AppColors.accent,
        onTap: onOpen,
      ),
      const _MiniAppData(
        icon: Icons.fact_check_rounded,
        title: 'Evidence Studio',
        subtitle: 'Task proof',
        color: Color(0xFF3F6FD8),
      ),
      const _MiniAppData(
        icon: Icons.school_rounded,
        title: 'Classroom Sync',
        subtitle: 'Learning hub',
        color: Color(0xFF1F8F8A),
      ),
      const _MiniAppData(
        icon: Icons.emoji_events_rounded,
        title: 'Demo Day',
        subtitle: 'Showcase',
        color: AppColors.violet,
      ),
      const _MiniAppData(
        icon: Icons.card_giftcard_rounded,
        title: 'Reward Loop',
        subtitle: 'Points center',
        color: Color(0xFFCA7A00),
      ),
      const _MiniAppData(
        icon: Icons.apps_rounded,
        title: 'Builder Apps',
        subtitle: 'More tools',
        color: Color(0xFF20242A),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's New", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.16,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) => _MiniAppTile(data: items[index]),
          ),
        ],
      ),
    );
  }
}

class _MiniAppTile extends StatelessWidget {
  const _MiniAppTile({required this.data});

  final _MiniAppData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(data.icon, color: data.color, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;
}

class _MiniAppData {
  const _MiniAppData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
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
