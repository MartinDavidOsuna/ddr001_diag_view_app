enum FlowPoint { q1, q2, q3, q4 }

extension FlowPointDescription on FlowPoint {
  /// Product rule mapping: current Q1 is the former permanent-flow Q3 stage.
  FlowPoint get metrologyRuleSource => switch (this) {
    FlowPoint.q1 => FlowPoint.q3,
    _ => this,
  };

  String get technicalName => switch (this) {
    FlowPoint.q1 => 'permanent',
    FlowPoint.q2 => 'transitional',
    FlowPoint.q3 => 'permanent',
    FlowPoint.q4 => 'overload',
  };
}
