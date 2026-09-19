import 'package:flutter/material.dart';
import 'package:the_builder_pros/app/constant/resources/app_dimens.dart';
import 'package:the_builder_pros/app/features/wallet/widget/wallet_ui.dart';

class AppMasterPage extends StatelessWidget {
  const AppMasterPage({
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
  Widget build(BuildContext context) => Scaffold(
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
