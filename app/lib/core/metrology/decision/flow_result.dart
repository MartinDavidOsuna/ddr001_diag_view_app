import '../models/flow_point.dart';
import '../models/sample_result.dart';
import '../statistics/sample_statistics.dart';
import 'decision_rule.dart';

enum FlowPointStatus { pending, pass, fail, inconclusive }

final class FlowPointResult {
  const FlowPointResult({
    required this.flowPoint,
    required this.status,
    required this.samples,
    this.statistics,
  });

  factory FlowPointResult.summarize({
    required FlowPoint flowPoint,
    required List<SampleResult> samples,
    required double mpePct,
  }) {
    final immutableSamples = List<SampleResult>.unmodifiable(samples);
    if (immutableSamples.isEmpty) {
      return FlowPointResult(
        flowPoint: flowPoint,
        status: FlowPointStatus.pending,
        samples: immutableSamples,
      );
    }
    final statistics = calculateSampleStatistics(
      immutableSamples,
      mpePct: mpePct,
    );
    final status =
        immutableSamples.any((sample) => sample.verdict == SampleVerdict.fail)
        ? FlowPointStatus.fail
        : immutableSamples.any(
            (sample) => sample.verdict == SampleVerdict.inconclusive,
          )
        ? FlowPointStatus.inconclusive
        : statistics.repeatabilityStatus == RepeatabilityStatus.fail
        ? FlowPointStatus.fail
        : FlowPointStatus.pass;
    return FlowPointResult(
      flowPoint: flowPoint,
      status: status,
      samples: immutableSamples,
      statistics: statistics,
    );
  }

  final FlowPoint flowPoint;
  final FlowPointStatus status;
  final List<SampleResult> samples;
  final SampleStatistics? statistics;
}
