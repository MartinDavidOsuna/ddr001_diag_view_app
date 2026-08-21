import 'package:ddr001_diag_view_app/infrastructure/vision/vision_models.dart';
import 'package:ddr001_diag_view_app/presentation/common/meter_face_region_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pinch resizes totalizer without labels or resize handles', (
    tester,
  ) async {
    var configuration = const DialVisionConfiguration();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: StatefulBuilder(
              builder: (context, setState) => MeterFaceRegionEditor.live(
                preview: const ColoredBox(color: Colors.black),
                aspectRatio: .75,
                configuration: configuration,
                target: MeterFaceEditTarget.totalizer,
                onChanged: (value) => setState(() => configuration = value),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('TOTALIZADOR'), findsNothing);
    expect(find.text('DIAL'), findsNothing);
    expect(find.byKey(const Key('resize-totalizer-region')), findsNothing);
    expect(find.byKey(const Key('resize-dial-region')), findsNothing);

    final initialWidth = configuration.totalizerRegion.geometry.width;
    final center = tester.getCenter(
      find.byKey(const Key('move-totalizer-region')),
    );
    final first = await tester.startGesture(
      center - const Offset(15, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(15, 0),
      pointer: 2,
    );
    await first.moveTo(center - const Offset(35, 0));
    await second.moveTo(center + const Offset(35, 0));
    await tester.pump();
    await first.up();
    await second.up();

    expect(
      configuration.totalizerRegion.geometry.width,
      greaterThan(initialWidth),
    );
  });

  testWidgets('pinch resizes selected dial across the full preview', (
    tester,
  ) async {
    var configuration = const DialVisionConfiguration();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: StatefulBuilder(
              builder: (context, setState) => MeterFaceRegionEditor.live(
                preview: const ColoredBox(color: Colors.black),
                aspectRatio: .75,
                configuration: configuration,
                target: MeterFaceEditTarget.dial,
                onChanged: (value) => setState(() => configuration = value),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    final initialRadius = configuration.selectedDial.radius;
    final center = tester.getCenter(find.byKey(const Key('move-dial-region')));
    final first = await tester.startGesture(
      center - const Offset(20, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 2,
    );
    await first.moveTo(center - const Offset(50, 0));
    await second.moveTo(center + const Offset(50, 0));
    await tester.pump();
    await first.up();
    await second.up();

    expect(configuration.selectedDial.radius, greaterThan(initialRadius));
  });
}
