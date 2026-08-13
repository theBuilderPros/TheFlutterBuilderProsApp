import 'package:flutter/material.dart';
import 'package:the_builder_studio/app/constant/resources/app_string.dart';
import 'package:the_builder_studio/app/design/talkware_spacing.dart';
import 'package:the_builder_studio/app/design/widgets/talkware_logo.dart';

class TalkwareAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TalkwareAppBar({
    super.key,
    required this.onMenuPressed,
    this.menuTooltip = AppString.profileMenuTitle,
  });

  final VoidCallback onMenuPressed;
  final String menuTooltip;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: const Padding(
        padding: EdgeInsets.only(left: TalkwareSpacing.lg),
        child: TalkwareLogo(size: 32),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: TalkwareSpacing.sm),
          child: IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu_outlined),
            tooltip: menuTooltip,
          ),
        ),
      ],
    );
  }
}

