import 'package:flutter/material.dart';
import 'package:the_builder_studio/app/design/talkware_assets.dart';

class TalkwareLogo extends StatelessWidget {
  const TalkwareLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      TalkwareAssets.logo,
      width: size,
      height: size,
      semanticLabel: 'Talkware logo',
      fit: BoxFit.contain,
    );
  }
}

