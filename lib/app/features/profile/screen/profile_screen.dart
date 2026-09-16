import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/constant/resources/app_images.dart';
import 'package:the_builder_pros/app/core/base/base_view.dart';
import 'package:the_builder_pros/app/features/profile/controller/profile_controller.dart';

class ProfileScreen extends BaseView<ProfileController> {
  const ProfileScreen({super.key});
  @override
  Widget buildView(BuildContext context) => Obx(() {
    final detail = controller.selectedSquad.value;
    return Scaffold(
      body: SafeArea(
        child: detail == null
            ? IndexedStack(
                index: controller.tabIndex.value,
                children: const [_Home(), _Rewards(), _Apps()],
              )
            : _SquadDetail(squad: detail),
      ),
      bottomNavigationBar: detail == null
          ? NavigationBar(
              selectedIndex: controller.tabIndex.value,
              onDestinationSelected: controller.selectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.card_giftcard_outlined),
                  selectedIcon: Icon(Icons.card_giftcard),
                  label: 'Rewards',
                ),
                NavigationDestination(
                  icon: Icon(Icons.apps_outlined),
                  selectedIcon: Icon(Icons.apps),
                  label: 'Apps',
                ),
              ],
            )
          : null,
    );
  });
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      const _Header(),
      const SizedBox(height: 24),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 5),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: .32,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accent, AppColors.violet],
                stops: [0, .76, .76],
              ),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      ...children,
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset(
        AppImages.theBuilderProsLogo,
        height: 58,
        width: 100,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
      const Spacer(),
      Stack(
        children: [
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const Positioned(
            right: 9,
            top: 8,
            child: CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
          ),
        ],
      ),
    ],
  );
}

class _Home extends GetView<ProfileController> {
  const _Home();
  @override
  Widget build(BuildContext context) => Obx(() {
    final followed = controller.squads
        .where((s) => controller.followedIds.contains(s.id))
        .toList();
    return _Page(
      title: 'Home',
      subtitle: 'Continue your current Builder Cycle.',
      children: [
        _Card(
          child: Row(
            children: [
              const _Avatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.builder.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      controller.builder.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    _Pill(label: controller.builder.level, violet: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _Label('Rewards Balance'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => controller.selectTab(1),
                    child: const Text('View Rewards →'),
                  ),
                ],
              ),
              Text(
                '${controller.balance} pts',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const _SectionTitle('Followed Apps'),
        const SizedBox(height: 12),
        ...followed.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SquadCard(squad: s),
          ),
        ),
      ],
    );
  });
}

class _Rewards extends GetView<ProfileController> {
  const _Rewards();
  @override
  Widget build(BuildContext context) => Obx(
    () => _Page(
      title: 'Rewards',
      subtitle: 'Send and receive Builder rewards.',
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _Label('Your Balance'),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                ],
              ),
              Text(
                '${controller.balance} pts',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Receive'),
              icon: Icon(Icons.qr_code_2),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Send'),
              icon: Icon(Icons.send_outlined),
            ),
          ],
          selected: {controller.rewardsMode.value},
          onSelectionChanged: (v) => controller.rewardsMode.value = v.first,
          showSelectedIcon: false,
        ),
        const SizedBox(height: 18),
        if (controller.rewardsMode.value == 0) ...[
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Receive via QR'),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFC49E)),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      size: 104,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Show this to another Builder to receive points.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Your Reward ID'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.rewardId,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      const Icon(Icons.copy, size: 18, color: AppColors.violet),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const _Card(
            child: Column(
              children: [
                _Field(label: 'Recipient ID', hint: 'Builder ID or email'),
                SizedBox(height: 16),
                _Field(label: 'Amount (pts)', hint: '0'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send_outlined),
              label: const Text('Send Rewards'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Apps extends GetView<ProfileController> {
  const _Apps();
  @override
  Widget build(BuildContext context) => Obx(() {
    final q = controller.search.value.toLowerCase();
    final items = controller.squads
        .where((s) => '${s.name} ${s.description}'.toLowerCase().contains(q))
        .toList();
    return _Page(
      title: 'Apps',
      subtitle: 'Follow App Squads and track what they are building.',
      children: [
        TextField(
          onChanged: (v) => controller.search.value = v,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search Apps…',
          ),
        ),
        const SizedBox(height: 18),
        ...items.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SquadCard(squad: s, showFollowing: true),
          ),
        ),
      ],
    );
  });
}

class _SquadDetail extends GetView<ProfileController> {
  const _SquadDetail({required this.squad});
  final Squad squad;
  @override
  Widget build(BuildContext context) => Obx(() {
    final items = controller.itemsFor(squad.id);
    final following = controller.followedIds.contains(squad.id);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.closeSquad,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
        const SizedBox(height: 12),
        Text(squad.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Text(
          'App overview and Squad work updates.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _Label('About this App'),
                  const Spacer(),
                  _Pill(label: squad.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(squad.description, style: const TextStyle(height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: following
              ? OutlinedButton.icon(
                  onPressed: () => controller.toggleFollow(squad.id),
                  icon: const Icon(Icons.check),
                  label: const Text('Following App Squad'),
                )
              : FilledButton(
                  onPressed: () => controller.toggleFollow(squad.id),
                  child: const Text('Follow App Squad'),
                ),
        ),
        const SizedBox(height: 26),
        ...['WIP', 'Committed', 'Done'].map(
          (state) => _WorkSection(
            title: state == 'Done'
                ? 'Work History'
                : state == 'Committed'
                ? 'Committed Work'
                : 'WIP',
            items: items.where((i) => i.state == state).toList(),
          ),
        ),
      ],
    );
  });
}

class _SquadCard extends GetView<ProfileController> {
  const _SquadCard({required this.squad, this.showFollowing = false});
  final Squad squad;
  final bool showFollowing;
  @override
  Widget build(BuildContext context) {
    final items = controller.itemsFor(squad.id);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  squad.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (showFollowing && controller.followedIds.contains(squad.id))
                const _Pill(label: 'Following', violet: true)
              else
                _Pill(label: squad.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            squad.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.timelapse, size: 15, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                '${items.where((i) => i.state == 'WIP').length} WIP',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.check_circle_outline,
                size: 15,
                color: Color(0xFF16865B),
              ),
              const SizedBox(width: 4),
              Text(
                '${items.where((i) => i.state == 'Done').length} completed',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => controller.openSquad(squad),
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkSection extends StatelessWidget {
  const _WorkSection({required this.title, required this.items});
  final String title;
  final List<WorkItem> items;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            _Pill(label: '${items.length}', violet: true),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text('No work items.', style: Theme.of(context).textTheme.bodyMedium)
        else
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Card(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      i.state == 'Done'
                          ? Icons.check_circle
                          : i.state == 'WIP'
                          ? Icons.schedule
                          : Icons.circle_outlined,
                      size: 18,
                      color: i.state == 'Done'
                          ? const Color(0xFF16865B)
                          : i.state == 'WIP'
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            i.outcome,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cycle ${i.cycle} · W${i.week} — ${i.weekLabel}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D231448),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [Padding(padding: const EdgeInsets.all(16), child: child)],
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar();
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.accent, AppColors.violet],
      ),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Text(
      'JR',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.violet = false});
  final String label;
  final bool violet;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: violet ? AppColors.violetSoft : AppColors.accentSoft,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: violet ? AppColors.violet : const Color(0xFFB84408),
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: .8,
      color: AppColors.textSecondary,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.hint});
  final String label, hint;
  @override
  Widget build(BuildContext context) => TextField(
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}
