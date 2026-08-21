import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('point flow statistics use only persisted evidence snapshots', () {
    final capturedAt = DateTime.utc(2026, 8, 20, 12);
    final points = [
      TestPoint(
        id: 'start',
        sampleId: 'sample',
        type: PointType.start,
        capturedAt: capturedAt,
        flowLps: 1.2,
      ),
      TestPoint(
        id: 'intermediate',
        sampleId: 'sample',
        type: PointType.intermediate,
        capturedAt: capturedAt.add(const Duration(seconds: 10)),
        flowLps: 1.8,
      ),
      TestPoint(
        id: 'final',
        sampleId: 'sample',
        type: PointType.finalPoint,
        capturedAt: capturedAt.add(const Duration(seconds: 20)),
        flowLps: 1.5,
      ),
    ];

    final result = PointFlowStatistics.fromPoints(points)!;

    expect(result.minimumLps, 1.2);
    expect(result.maximumLps, 1.8);
    expect(result.averageLps, 1.5);
    expect(result.count, 3);
  });

  test('point flow statistics ignore legacy points without flow', () {
    final result = PointFlowStatistics.fromPoints([
      TestPoint(
        id: 'legacy',
        sampleId: 'sample',
        type: PointType.start,
        capturedAt: DateTime.utc(2026, 8, 20),
      ),
    ]);

    expect(result, isNull);
  });
}
