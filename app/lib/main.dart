import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'presentation/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final dependencies = await AppDependencies.createLocal();
  runApp(
    ProviderScope(
      overrides: [appDependenciesProvider.overrideWithValue(dependencies)],
      child: const Ddr001App(),
    ),
  );
}
