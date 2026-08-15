import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'all shared JSON schemas parse and expose current measurement semantics',
    () {
      final directory = Directory('../packages/shared-contracts');
      final schemas = <String, Map<String, Object?>>{};
      for (final file in directory.listSync().whereType<File>()) {
        if (!file.path.endsWith('.schema.json')) continue;
        schemas[file.uri.pathSegments.last] =
            jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      }
      expect(schemas, hasLength(5));

      final pointProperties =
          schemas['point.schema.json']!['properties'] as Map<String, Object?>;
      expect((pointProperties['pulse_count'] as Map<String, Object?>)['type'], [
        'integer',
        'null',
      ]);
      expect((pointProperties['v_ref_l'] as Map<String, Object?>)['type'], [
        'number',
        'null',
      ]);

      final sample = schemas['test.schema.json']!;
      final required = (sample['required'] as List<Object?>).cast<String>();
      final properties = sample['properties'] as Map<String, Object?>;
      expect(required, contains('measurement_source'));
      expect(required, isNot(contains('pulse_source')));
      expect(
        (properties['measurement_source'] as Map<String, Object?>)['enum'],
        ['VISUAL', 'MANUAL', 'LED', 'BLE'],
      );
      expect(
        (properties['schema'] as Map<String, Object?>)['const'],
        'ddr001.verification.sample/v7',
      );
      final definitions = sample[r'$defs'] as Map<String, Object?>;
      final reading = definitions['reading'] as Map<String, Object?>;
      final readingProperties = reading['properties'] as Map<String, Object?>;
      expect(
        (readingProperties['evidence_id'] as Map<String, Object?>)['type'],
        ['string', 'null'],
      );
    },
  );
}
