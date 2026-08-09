import '../models/flow_point.dart';

abstract interface class MpePolicy {
  double mpePctFor(FlowPoint flowPoint);
}

final class Class2WaterMpePolicy implements MpePolicy {
  const Class2WaterMpePolicy();

  static const double lowerZoneMpePct = 5;
  static const double upperZoneMpePct = 2;

  @override
  double mpePctFor(FlowPoint flowPoint) => switch (flowPoint) {
    FlowPoint.q1 => lowerZoneMpePct,
    FlowPoint.q2 || FlowPoint.q3 || FlowPoint.q4 => upperZoneMpePct,
  };
}
