import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

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
