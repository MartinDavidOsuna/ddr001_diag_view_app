import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Class 2 MPE policy', () {
    const policy = Class2WaterMpePolicy();
    test('current Q1 inherits the former Q3 rule source', () {
      expect(FlowPoint.q1.metrologyRuleSource, FlowPoint.q3);
      expect(FlowPoint.q1.technicalName, FlowPoint.q3.technicalName);
    });
    for (final entry in {
      FlowPoint.q1: 2.0,
      FlowPoint.q2: 2.0,
      FlowPoint.q3: 2.0,
      FlowPoint.q4: 2.0,
    }.entries) {
      test('${entry.key.name} uses ${entry.value} percent', () {
        expect(policy.mpePctFor(entry.key), entry.value);
      });
    }
  });

  group('guard band', () {
    const rule = GuardBandDecisionRule();

    test('E=1.0 U=0.5 MPE=2 passes', () {
      expect(
        rule.evaluate(errorPct: 1, uncertaintyPct: 0.5, mpePct: 2).verdict,
        SampleVerdict.pass,
      );
    });
    test('E=1.7 U=0.5 MPE=2 is inconclusive', () {
      expect(
        rule.evaluate(errorPct: 1.7, uncertaintyPct: 0.5, mpePct: 2).verdict,
        SampleVerdict.inconclusive,
      );
    });
    test('E=2.8 U=0.5 MPE=2 fails', () {
      expect(
        rule.evaluate(errorPct: 2.8, uncertaintyPct: 0.5, mpePct: 2).verdict,
        SampleVerdict.fail,
      );
    });
    for (final mpe in [2.0, 5.0]) {
      for (final sign in [-1.0, 1.0]) {
        test('exact ${sign * mpe}% boundary with U=0 passes', () {
          expect(
            rule
                .evaluate(errorPct: sign * mpe, uncertaintyPct: 0, mpePct: mpe)
                .verdict,
            SampleVerdict.pass,
          );
        });
      }
    }
    test('exact acceptance boundary with uncertainty passes', () {
      expect(
        rule.evaluate(errorPct: 1.5, uncertaintyPct: 0.5, mpePct: 2).verdict,
        SampleVerdict.pass,
      );
    });
    test('exact rejection metric boundary is inconclusive', () {
      expect(
        rule.evaluate(errorPct: 2.5, uncertaintyPct: 0.5, mpePct: 2).verdict,
        SampleVerdict.inconclusive,
      );
    });
    test('binary noise within epsilon does not flip a pass', () {
      expect(
        rule
            .evaluate(errorPct: 2 + 5e-13, uncertaintyPct: 0, mpePct: 2)
            .verdict,
        SampleVerdict.pass,
      );
    });
    test('a material amount beyond epsilon fails', () {
      expect(
        rule.evaluate(errorPct: 2 + 1e-9, uncertaintyPct: 0, mpePct: 2).verdict,
        SampleVerdict.fail,
      );
    });
  });
}
