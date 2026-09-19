import 'package:flutter/material.dart';
import 'package:the_builder_pros/app/constant/resources/app_colors.dart';
import 'package:the_builder_pros/app/constant/resources/app_dimens.dart';
import 'package:the_builder_pros/app/constant/resources/app_images.dart';

class FeatureHeader extends StatelessWidget {
  const FeatureHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Image.asset(
              AppImages.theBuilderProsLogo,
              height: 58,
              width: 100,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
            const Spacer(),
            trailing ??
                IconButton.filledTonal(
                  onPressed: () {},
                  tooltip: 'Notifications preview',
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
          ],
        ),
        const SizedBox(height: 20),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        FractionallySizedBox(
          widthFactor: .32,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[
                  AppColors.accent,
                  AppColors.accent,
                  AppColors.violet,
                ],
                stops: <double>[0, .76, .76],
              ),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    );
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.screenPadding,
            18,
            AppDimens.screenPadding,
            32,
          ),
          children: <Widget>[
            FeatureHeader(title: title, subtitle: subtitle, trailing: trailing),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class WalletCard extends StatelessWidget {
  const WalletCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class WalletStatusBadge extends StatelessWidget {
  const WalletStatusBadge({
    super.key,
    required this.label,
    this.pending = false,
  });

  final String label;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pending ? AppColors.primarySoft : AppColors.violetSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: pending ? AppColors.primaryDark : AppColors.violet,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
