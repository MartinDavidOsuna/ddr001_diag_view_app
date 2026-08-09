/// Central comparison tolerance used only to absorb binary floating-point noise.
/// Values are never rounded before a decision. The relative component scales
/// with the compared magnitudes; the floor covers values around zero.
final class NumericTolerance {
  const NumericTolerance({
    this.absoluteEpsilon = 1e-12,
    this.relativeEpsilon = 1e-12,
  });

  final double absoluteEpsilon;
  final double relativeEpsilon;

  double toleranceFor(double left, double right) {
    final scale = left.abs() > right.abs() ? left.abs() : right.abs();
    final relative = scale * relativeEpsilon;
    return relative > absoluteEpsilon ? relative : absoluteEpsilon;
  }

  bool lessThanOrEqual(double left, double right) =>
      left <= right + toleranceFor(left, right);

  bool greaterThan(double left, double right) =>
      left > right + toleranceFor(left, right);
}
