enum FlowPoint { q1, q2, q3, q4 }

extension FlowPointDescription on FlowPoint {
  String get technicalName => switch (this) {
    FlowPoint.q1 => 'minimum',
    FlowPoint.q2 => 'transitional',
    FlowPoint.q3 => 'permanent',
    FlowPoint.q4 => 'overload',
  };
}
