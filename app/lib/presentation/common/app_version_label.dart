import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

final class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key, this.style, this.loader});

  final TextStyle? style;
  final Future<PackageInfo> Function()? loader;

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

final class _AppVersionLabelState extends State<AppVersionLabel> {
  late final Future<PackageInfo> _packageInfo =
      widget.loader?.call() ?? PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: _packageInfo,
    builder: (context, snapshot) {
      final info = snapshot.data;
      final build = info?.buildNumber.padLeft(2, '0');
      return Text(
        info == null ? 'Versión: …' : 'Versión: ${info.version}+$build',
        key: const Key('app-version-label'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    },
  );
}
