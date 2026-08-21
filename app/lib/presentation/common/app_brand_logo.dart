import 'package:flutter/material.dart';

import '../../app/app_assets.dart';

enum AppBrandLogoVariant { symbol, splash }

final class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    required this.variant,
    this.width,
    this.height,
    super.key,
  });

  final AppBrandLogoVariant variant;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Aquafim',
    child: Image.asset(
      switch (variant) {
        AppBrandLogoVariant.symbol => AppAssets.logoSymbol,
        AppBrandLogoVariant.splash => AppAssets.splashLogo,
      },
      key: Key('aquafim-logo-${variant.name}'),
      width: width,
      height: height,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}
