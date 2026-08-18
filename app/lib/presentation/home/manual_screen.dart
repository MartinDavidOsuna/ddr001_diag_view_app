import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme/app_theme.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';

final class ManualScreen extends ConsumerWidget {
  const ManualScreen({super.key, this.packageInfoLoader});

  static const assetPath = 'assets/manual/manual_de_uso.md';
  final Future<PackageInfo> Function()? packageInfoLoader;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    title: 'Manual de uso',
    onBack: ref.read(appControllerProvider.notifier).showSettings,
    child: FutureBuilder<String>(
      future: rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SectionCard(
            title: 'Manual de uso',
            child: Text('No fue posible abrir el manual incluido en la app.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final manual = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<PackageInfo>(
              future: _packageInfo(),
              builder: (context, info) => Text(
                info.hasData
                    ? 'App ${info.data!.version} (${info.data!.buildNumber}) · disponible offline'
                    : 'Manual incluido · disponible offline',
                key: const Key('manual-app-version'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            MarkdownBody(
              key: const Key('manual-content'),
              data: manual,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(
                  color: AppColors.heading,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                h2: const TextStyle(
                  color: AppColors.heading,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
                p: const TextStyle(height: 1.45),
                listBullet: const TextStyle(color: AppColors.heading),
              ),
            ),
          ],
        );
      },
    ),
  );

  Future<PackageInfo> _packageInfo() async {
    try {
      if (packageInfoLoader != null) return await packageInfoLoader!();
      return await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {
      return PackageInfo(
        appName: 'DDR001',
        packageName: 'mx.aquafim.ddr001',
        version: 'desconocida',
        buildNumber: 'local',
      );
    }
  }
}
