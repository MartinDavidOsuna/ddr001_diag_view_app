import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/app_controller.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/home/home_screens.dart';
import '../presentation/results/result_screens.dart';
import '../presentation/workflow/readings_screen.dart';
import '../presentation/workflow/camera_screen.dart';
import '../presentation/workflow/run_screens.dart';
import '../presentation/workflow/setup_screens.dart';
import '../presentation/debug/visual_calibration_screen.dart';
import 'theme/app_theme.dart';

final class Ddr001App extends ConsumerStatefulWidget {
  const Ddr001App({super.key, this.initialize = true});

  final bool initialize;

  @override
  ConsumerState<Ddr001App> createState() => _Ddr001AppState();
}

final class _Ddr001AppState extends ConsumerState<Ddr001App> {
  @override
  void initState() {
    super.initState();
    if (widget.initialize) {
      Future.microtask(ref.read(appControllerProvider.notifier).initialize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    return MaterialApp(
      title: 'DDR001 VERIFICADOR VISUAL',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(
          key: ValueKey(state.page),
          child: switch (state.page) {
            AppPage.loading => const _LoadingScreen(),
            AppPage.login => const LoginScreen(),
            AppPage.recovery => const RecoveryScreen(),
            AppPage.home => const HomeScreen(),
            AppPage.identification => const IdentificationScreen(),
            AppPage.method => const MethodScreen(),
            AppPage.setup => const TestSetupScreen(),
            AppPage.run => const TestRunScreen(),
            AppPage.readings => const ReadingsScreen(),
            AppPage.result => const SampleResultScreen(),
            AppPage.caseSummary => const CaseSummaryScreen(),
            AppPage.history => const HistoryScreen(),
            AppPage.settings => const SettingsScreen(),
            AppPage.invalidEvidence => const InvalidEvidenceScreen(),
            AppPage.camera => const CameraCaptureScreen(),
            AppPage.debugCalibration => const VisualCalibrationScreen(),
          },
        ),
      ),
    );
  }
}

final class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop_rounded, size: 58, color: AppColors.heading),
          SizedBox(height: 18),
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Preparando almacenamiento offline…'),
        ],
      ),
    ),
  );
}
