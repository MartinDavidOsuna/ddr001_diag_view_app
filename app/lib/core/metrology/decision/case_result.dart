import '../models/flow_point.dart';
import 'flow_result.dart';

enum CaseVerdict { approved, rejected, inconclusive }

CaseVerdict calculateCaseVerdict({
  required Set<FlowPoint> requiredFlowPoints,
  required List<FlowPointResult> flowResults,
}) {
  if (requiredFlowPoints.isEmpty) {
    throw ArgumentError.value(
      requiredFlowPoints,
      'requiredFlowPoints',
      'At least one flow point must be explicitly required.',
    );
  }
  final byFlowPoint = <FlowPoint, FlowPointResult>{};
  for (final result in flowResults) {
    if (byFlowPoint.containsKey(result.flowPoint)) {
      throw ArgumentError('Duplicate result for ${result.flowPoint.name}.');
    }
    byFlowPoint[result.flowPoint] = result;
  }
  final requiredResults = requiredFlowPoints.map((point) => byFlowPoint[point]);
  if (requiredResults.any((result) => result?.status == FlowPointStatus.fail)) {
    return CaseVerdict.rejected;
  }
  if (requiredResults.any(
    (result) =>
        result == null ||
        result.status == FlowPointStatus.pending ||
        result.status == FlowPointStatus.inconclusive,
  )) {
    return CaseVerdict.inconclusive;
  }
  return CaseVerdict.approved;
}
