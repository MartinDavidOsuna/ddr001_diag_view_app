import '../models/flow_point.dart';

abstract interface class MpePolicy {
  double mpePctFor(FlowPoint flowPoint);
}

final class Class2WaterMpePolicy implements MpePolicy {
  const Class2WaterMpePolicy();

  static const double upperZoneMpePct = 2;

  @override
  double mpePctFor(FlowPoint flowPoint) =>
      switch (flowPoint.metrologyRuleSource) {
        FlowPoint.q2 || FlowPoint.q3 || FlowPoint.q4 => upperZoneMpePct,
        FlowPoint.q1 => throw StateError('Q1 must resolve to former Q3 rules.'),
      };
}
