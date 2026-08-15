import 'dart:io';

import 'package:ddr001_diag_view_app/core/metrology/models/measurement_method.dart';
import 'package:ddr001_diag_view_app/domain/pulse/pulse_progress_service.dart';
import 'package:ddr001_diag_view_app/domain/pulse/pulse_source.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/domain/pulse/esp32_counter_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/offline_fixture.dart';

void main() {
  late Directory directory;
  late OfflineFixture fixture;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('pulse-progress-');
    fixture = OfflineFixture(memoryDatabase(), directory);
    await fixture.seed();
  });

  tearDown(() async {
    await fixture.database.close();
    await directory.delete(recursive: true);
  });

  PulseEvent event(String id, PulseSourceType source, {int? sequence}) {
    return PulseEvent(
      id: id,
      source: source,
      occurredAt: fixedTime,
      receivedAt: fixedTime,
      sequence: sequence,
    );
  }

  test('one common event increments and persists N and Vref', () async {
    await fixture.running(method: MeasurementMethod.manual);
    final service = PulseProgressService(fixture.samples);

    expect(
      await service.acceptPulse(
        'sample-1',
        event('one', PulseSourceType.manual),
      ),
      1,
    );
    final saved = await fixture.samples.getById('sample-1');
    expect(saved!.pulseCount, 1);
    expect(saved.referenceLitersProgress, 1);
  });

  test('sequential events cannot lose an increment', () async {
    await fixture.running(method: MeasurementMethod.ble);
    final service = PulseProgressService(fixture.samples);
    await Future.wait([
      service.acceptPulse('sample-1', event('one', PulseSourceType.ble)),
      service.acceptPulse('sample-1', event('two', PulseSourceType.ble)),
      service.acceptPulse('sample-1', event('three', PulseSourceType.ble)),
    ]);
    expect((await fixture.samples.getById('sample-1'))!.pulseCount, 3);
  });

  test('same source sequence is accepted once locally', () async {
    await fixture.running(method: MeasurementMethod.ble);
    final service = PulseProgressService(fixture.samples);
    await service.acceptPulse(
      'sample-1',
      event('a', PulseSourceType.ble, sequence: 7),
    );
    await service.acceptPulse(
      'sample-1',
      event('b', PulseSourceType.ble, sequence: 7),
    );
    expect((await fixture.samples.getById('sample-1'))!.pulseCount, 1);
  });

  test('VISUAL rejects pulse events', () async {
    await fixture.running(method: MeasurementMethod.visual);
    final service = PulseProgressService(fixture.samples);
    expect(
      () =>
          service.acceptPulse('sample-1', event('one', PulseSourceType.manual)),
      throwsStateError,
    );
  });

  test('BLE configuration and integrity survive repository recovery', () async {
    await fixture.running(method: MeasurementMethod.ble);
    await fixture.samples.updatePulseAcquisition(
      id: 'sample-1',
      configuration: const PulseAcquisitionConfiguration(
        bleDeviceId: 'device-1',
        bleDeviceName: 'DDR001-PULSE-691C',
        bleServiceUuid: Ddr001BleContract.serviceUuid,
        bleCounterCharacteristicUuid:
            Ddr001BleContract.counterCharacteristicUuid,
        bleProtocolVersion: 1,
        esp32CounterAtStart: 100,
        lastObservedEsp32Counter: 107,
      ),
      integrity: AcquisitionIntegrity(
        status: AcquisitionIntegrityStatus.compromised,
        reason: 'rollback',
        occurredAt: fixedTime,
        source: MeasurementMethod.ble,
      ),
    );
    final recovered = await fixture.samples.getById('sample-1');
    expect(recovered!.pulseAcquisitionConfiguration!.esp32CounterAtStart, 100);
    expect(
      recovered.pulseAcquisitionConfiguration!.lastObservedEsp32Counter,
      107,
    );
    expect(recovered.acquisitionIntegrity.isCompromised, isTrue);
  });

  test(
    'compromised acquisition blocks CLOSED_VALID independently of evidence',
    () async {
      await fixture.running(method: MeasurementMethod.ble);
      await fixture.samples.updatePulseAcquisition(
        id: 'sample-1',
        configuration: const PulseAcquisitionConfiguration(
          bleDeviceId: 'device-1',
        ),
        integrity: AcquisitionIntegrity(
          status: AcquisitionIntegrityStatus.compromised,
          reason: 'counter rollback',
          occurredAt: fixedTime,
          source: MeasurementMethod.ble,
        ),
      );
      expect(
        () => fixture.sampleClosure.closeValid('sample-1', at: fixedTime),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Conteo de pulsos no verificable'),
          ),
        ),
      );
    },
  );
}
