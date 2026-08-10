import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../app_controller.dart';

final class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    super.key,
    this.showBack = true,
    this.actions,
  });

  final String title;
  final Widget child;
  final bool showBack;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Scaffold(
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
        leading: showBack
            ? IconButton(
                tooltip: 'Volver',
                onPressed: () =>
                    ref.read(appControllerProvider.notifier).showHome(),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height - 120,
                ),
                child: child,
              ),
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
    );
  }
}

final class SectionCard extends StatelessWidget {
  const SectionCard({required this.title, required this.child, super.key});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.heading,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    ),
  );
}

final class StatusBanner extends StatelessWidget {
  const StatusBanner({
    required this.text,
    required this.color,
    super.key,
    this.icon,
  });
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .18),
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: color),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
