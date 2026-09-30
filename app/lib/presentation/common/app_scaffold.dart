import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../app_controller.dart';
import 'app_brand_logo.dart';
export 'section_card.dart';

final class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    super.key,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.scrollable = true,
    this.pinnedHeader,
    this.scrollController,
    this.logoLeadingPadding = AppSpacing.md,
    this.logoExtraMarginFraction = .03,
    this.bottomOverlay,
  });

  final String title;
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool scrollable;
  final Widget? pinnedHeader;
  final ScrollController? scrollController;
  final double logoLeadingPadding;
  final double logoExtraMarginFraction;
  final Widget? bottomOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final back =
        onBack ?? () => ref.read(appControllerProvider.notifier).goBack();
    final logoMargin =
        logoLeadingPadding +
        MediaQuery.sizeOf(context).width * logoExtraMarginFraction;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && showBack) back();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 70,
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy, Color(0xFF274D78)],
              ),
            ),
          ),
          leadingWidth: (showBack ? 48 : 0) + logoMargin + 38,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBack)
                IconButton(
                  tooltip: 'Volver',
                  onPressed: back,
                  icon: const Icon(Icons.arrow_back),
                ),
              Padding(
                padding: EdgeInsets.only(left: logoMargin),
                child: const AppBrandLogo(
                  variant: AppBrandLogoVariant.symbol,
                  width: 30,
                  height: 30,
                ),
              ),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'DDR001 · Modo offline',
                style: TextStyle(fontSize: 11, color: Color(0xFFBCD0E8)),
              ),
            ],
          ),
          actions: actions,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              if (scrollable)
                Column(
                  children: [
                    if (pinnedHeader != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          0,
                        ),
                        child: pinnedHeader!,
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.sizeOf(context).height - 120,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: child,
                  ),
                ),
              if (bottomOverlay != null)
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.lg,
                  child: Center(child: bottomOverlay!),
                ),
              if (state.busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x660F1826),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
