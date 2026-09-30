import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/pulse/pulse_progress_service.dart';
import 'package:ddr001_diag_view_app/domain/pulse/esp32_counter_protocol.dart';
import 'package:ddr001_diag_view_app/domain/pulse/pulse_source.dart';
import 'package:ddr001_diag_view_app/infrastructure/pulse/ble_pulse_source.dart';
import 'package:ddr001_diag_view_app/infrastructure/pulse/ble_connection_ownership.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../support/offline_fixture.dart';
import '../support/presentation_fixture.dart';
import 'package:ddr001_diag_view_app/presentation/app_controller.dart';
import 'package:ddr001_diag_view_app/infrastructure/pulse/ble_discovery.dart';
import 'package:uuid/uuid.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/infrastructure/camera/camera_port.dart';

void main() {
  late _Device device;
  late BlePulseSource source;
  late List<PulseEvent> events;
  late List<PulseSourceState> states;
  late WidgetTester activeTester;
  var permission = true;
  var adapter = BluetoothAdapterState.on;

  void setupSource() {
    permission = true;
    adapter = BluetoothAdapterState.on;
    device = _Device();
    source = BlePulseSource.withDevice(
      const BlePulseConfiguration(
        deviceId: 'AA:BB:CC:DD:EE:FF',
        serviceUuid: Ddr001BleContract.serviceUuid,
        characteristicUuid: Ddr001BleContract.counterCharacteristicUuid,
      ),
      device,
      hasPermission: () async => permission,
      adapterState: () async => adapter,
    );
    events = [];
    states = [];
    source.events.listen(events.add);
    source.states.listen(states.add);
  }

  void bleTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      activeTester = tester;
      setupSource();
      await body(tester);
    });
  }

  Future<void> tick(
    WidgetTester tester, [
    Duration duration = Duration.zero,
  ]) async {
    await tester.pump(duration);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  Future<void> finish() async {
    await activeTester.runAsync(source.dispose);
    expect(device.counter.activeListeners, 0);
    expect(device.counter.maximumListeners, lessThanOrEqualTo(1));
    expect(device.maximumConnections, lessThanOrEqualTo(1));
    await device.changes.close();
    await device.counter.values.close();
  }

  for (final initial in [true, false]) {
    bleTest('READ stream then newer NOTIFY before result, initial=$initial', (
      tester,
    ) async {
      if (!initial) await source.start();
      device.counter.gate = Completer<List<int>>();
      Future<void>? starting;
      if (initial) {
        starting = source.start();
        await tick(tester);
      } else {
        await tick(tester, const Duration(seconds: 10));
      }
      device.counter.values.add(_payload(initial ? 100 : 101));
      device.counter.values.add(_payload(102));
      await tick(tester);
      device.counter.gate!.complete(_payload(initial ? 100 : 101));
      await starting;
      await tick(tester);
      expect(source.lastObservedCounter, 102);
      expect(source.currentState.compromised, isFalse);
      expect(events.map((event) => event.sequence), [101, 102]);
      await finish();
    });
  }

  bleTest('late duplicate disconnected event cannot invalidate current link', (
    tester,
  ) async {
    await source.start();
    device.changes.add(BluetoothConnectionState.connected);
    device.changes.add(BluetoothConnectionState.disconnected);
    device.changes.add(BluetoothConnectionState.connected);
    await tick(tester, const Duration(seconds: 2));
    expect(source.currentState.status, PulseSourceStatus.ready);
    expect(device.discoveries, 1);
    await finish();
  });

  for (final denied in [true, false]) {
    bleTest('blocked environment pauses retries, permissionDenied=$denied', (
      tester,
    ) async {
      permission = !denied;
      adapter = denied ? BluetoothAdapterState.on : BluetoothAdapterState.off;
      await source.start();
      expect(source.currentState.status, PulseSourceStatus.error);
      expect(source.currentState.compromised, isFalse);
      await tick(tester, const Duration(minutes: 5));
      expect(device.connects, 0);
      permission = true;
      adapter = BluetoothAdapterState.on;
      source.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tick(tester);
      await tick(tester, const Duration(seconds: 1));
      expect(source.currentState.status, PulseSourceStatus.ready);
      expect(device.connects, 1);
      await finish();
    });
  }

  bleTest('foreground probes actual link without rebuilding valid GATT', (
    tester,
  ) async {
    await source.start();
    device.counter.count = 103;
    await source.verifyConnection();
    await tick(tester);
    expect(events, hasLength(3));
    expect(device.discoveries, 1);
    expect(device.counter.reads, 2);
    device.connected = false; // A lost callback during suspension.
    source.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tick(tester);
    await tick(tester, const Duration(seconds: 1));
    expect(source.currentState.status, PulseSourceStatus.ready);
    expect(device.connects, 2);
    await finish();
  });

  for (final disposing in [false, true]) {
    bleTest('stop/dispose during discovery, disposing=$disposing', (
      tester,
    ) async {
      device.discoveryGate = Completer<void>();
      final starting = source.start();
      await tick(tester);
      final stopping = tester.runAsync(
        disposing ? source.dispose : source.stop,
      );
      await tester.pump();
      device.discoveryGate!.complete();
      await starting;
      await stopping;
      expect(device.counter.notifies, 0);
      expect(source.currentState.status, PulseSourceStatus.stopped);
      await tick(tester, const Duration(minutes: 2));
      expect(device.connects, 1);
      await finish();
    });
  }

  bleTest('BUSCAR cannot validate or disconnect a recovering transport', (
    tester,
  ) async {
    await source.start();
    device.loseLink();
    await tick(tester);
    var validations = 0;
    expect(
      await BleConnectionOwnership.shared.validate(source.deviceId, () async {
        validations++;
        await device.disconnect();
        return true;
      }),
      isFalse,
    );
    expect(validations, 0);
    await tick(tester, const Duration(seconds: 1));
    expect(source.currentState.status, PulseSourceStatus.ready);
    await finish();
  });

  bleTest('source waits for scan cleanup before taking the link', (
    tester,
  ) async {
    final gate = Completer<void>();
    final validating = BleConnectionOwnership.shared.validate(
      source.deviceId,
      () async {
        await gate.future;
        await device.disconnect();
        return true;
      },
    );
    final starting = source.start();
    await tick(tester);
    expect(device.connects, 0);
    gate.complete();
    await validating;
    await starting;
    expect(source.currentState.status, PulseSourceStatus.ready);
    expect(device.connects, 1);
    await finish();
  });

  bleTest('failed scan releases ownership gate for direct connection', (
    tester,
  ) async {
    await expectLater(
      BleConnectionOwnership.shared.validate(source.deviceId, () async {
        throw StateError('scan failure');
      }),
      throwsStateError,
    );
    await source.start();
    expect(source.currentState.status, PulseSourceStatus.ready);
    await finish();
  });

  bleTest('counter checkpoint is queued after every pulse in the delta', (
    tester,
  ) async {
    final order = <String>[];
    final pulses = source.events.listen(
      (event) => order.add('p${event.sequence}'),
    );
    final counters = source.counters.listen(
      (counter) => order.add('c$counter'),
    );
    await source.start();
    await tick(tester);
    order.clear();
    device.counter.count = 104;
    device.counter.emit();
    await tick(tester);
    expect(order, ['p101', 'p102', 'p103', 'p104', 'c104']);
    await tester.runAsync(() async {
      await pulses.cancel();
      await counters.cancel();
    });
    await finish();
  });

  bleTest('repeated GATT failure escalates only after three full attempts', (
    tester,
  ) async {
    await source.start();
    device.counter.failure = 'read';
    await tick(tester, const Duration(seconds: 10));
    for (final seconds in [1, 2, 4]) {
      device.failure = 'discover';
      await tick(tester, Duration(seconds: seconds));
    }
    expect(device.connects, 1);
    expect(device.isConnected, isFalse);
    await tick(tester, const Duration(seconds: 8));
    expect(device.connects, 2);
    expect(source.currentState.status, PulseSourceStatus.ready);
    await finish();
  });

  bleTest('physical connection is insufficient while initial READ is pending', (
    tester,
  ) async {
    device.counter.gate = Completer<List<int>>();
    final starting = source.start();
    await tick(tester);
    expect(device.isConnected, isTrue);
    expect(source.currentState.status, PulseSourceStatus.connected);
    device.counter.gate!.complete(_payload(100));
    await starting;
    expect(source.currentState.status, PulseSourceStatus.ready);
    await finish();
  });

  bleTest('explicit stop while scan owns link never starts deferred connect', (
    tester,
  ) async {
    final gate = Completer<void>();
    final scan = BleConnectionOwnership.shared.validate(
      source.deviceId,
      () async {
        await gate.future;
        return true;
      },
    );
    final starting = source.start();
    await tick(tester);
    final stopping = source.stop();
    gate.complete();
    await scan;
    await starting;
    await stopping;
    expect(device.connects, 0);
    expect(BleConnectionOwnership.shared.isOwned(source.deviceId), isFalse);
    await finish();
  });

  for (final hasFinal in [false, true]) {
    testWidgets(
      'controller checkpoint failure, next Sample and reconstruction hasFinal=$hasFinal',
      (tester) async {
        final fixture = (await tester.runAsync(PresentationFixture.create))!;
        final device = _Device();
        final controller = (await tester.runAsync(
          () async => AppController(
            fixture.dependencies.copyWith(camera: _UnusedCamera()),
            const Uuid(),
            null,
            (configuration) => BlePulseSource.withDevice(configuration, device),
          ),
        ))!;
        Future<void> recordTestStart() async {
          final sample = controller.state.sample!;
          await fixture.dependencies.evidenceCapture.capture(
            caseId: controller.state.activeCase!.id,
            sample: sample,
            type: EvidenceType.start,
            volumeRefLiters: 0,
            pulseCount: 0,
          );
          await controller.initialize();
        }

        try {
          await tester.runAsync(() async {
            await fixture.seedSession();
            await controller.initialize();
            await controller.identifyMeter(meterId: 'BLE-TEST', lpsApprox: 20);
            controller.selectMethod(MeasurementMethod.ble);
            controller.selectBleDevice(
              const BleDeviceCandidate(
                id: 'AA:BB:CC:DD:EE:FF',
                name: 'DDR001-PULSE-TEST',
                rssi: -40,
              ),
            );
            await controller.startSample();
            await recordTestStart();
          });
          tester.binding.scheduleFrame();
          await tester.pump();
          await tester.runAsync(controller.resumeSample);
          tester.binding.scheduleFrame();
          await tester.pump();
          final firstId = controller.state.sample!.id;

          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            expect(
              (await fixture.dependencies.samples.getById(
                firstId,
              ))!.pulseAcquisitionConfiguration!.lastObservedEsp32Counter,
              100,
            );
            await fixture.database.customStatement("""
          CREATE TEMP TRIGGER reject_checkpoint BEFORE UPDATE OF last_observed_esp32_counter ON samples
          BEGIN SELECT RAISE(ABORT, 'checkpoint failure'); END
        """);
            device.counter.count = 102;
            device.counter.emit();
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          tester.binding.scheduleFrame();
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.runAsync(() async {
            final saved = await fixture.dependencies.samples.getById(firstId);
            expect(saved!.pulseCount, 2);
            expect(
              saved.pulseAcquisitionConfiguration!.lastObservedEsp32Counter,
              100,
            );
          });
          expect(
            controller.state.errorMessage,
            contains('guardar todos los pulsos'),
          );
          await tester.runAsync(controller.requestFinalEvidence);
          expect(controller.state.finalizingMeasurement, isFalse);
          await tester.runAsync(() async {
            await fixture.database.customStatement(
              'DROP TRIGGER reject_checkpoint',
            );
            await controller.repeatSample();
            await controller.startSample();
            await recordTestStart();
          });
          tester.binding.scheduleFrame();
          await tester.pump();
          await tester.runAsync(controller.resumeSample);
          tester.binding.scheduleFrame();
          await tester.pump();
          final nextId = controller.state.sample!.id;
          expect(nextId, isNot(firstId));
          expect(controller.state.hardwareState, HardwareState.ready);
          await tester.runAsync(() async {
            device.counter.count = 103;
            device.counter.emit();
            await Future<void>.delayed(const Duration(milliseconds: 100));
            final saved = (await fixture.dependencies.samples.getById(nextId))!;
            expect(saved.pulseCount, 1);
            expect(saved.acquisitionIntegrity.isCompromised, isFalse);
            expect(
              saved.pulseAcquisitionConfiguration!.lastObservedEsp32Counter,
              103,
            );
          });
          expect(device.connects, 1);
          await tester.runAsync(() async {
            if (hasFinal) {
              await fixture.dependencies.evidenceCapture.capture(
                caseId: controller.state.activeCase!.id,
                sample: controller.state.sample!,
                type: EvidenceType.finalEvidence,
                volumeRefLiters: 1,
                pulseCount: 1,
              );
            }
            await controller.initialize();
            await controller.disconnectBleDevice();
            await controller.resumeSample();
            if (hasFinal) {
              expect(controller.state.page, AppPage.readings);
              expect(device.connects, 1);
            } else {
              expect(
                controller.state.errorMessage,
                contains('no se puede verificar'),
              );
              await controller.requestFinalEvidence();
              expect(controller.state.finalizingMeasurement, isFalse);
            }
            final restored = (await fixture.dependencies.samples.getById(
              nextId,
            ))!;
            expect(restored.acquisitionIntegrity.isCompromised, !hasFinal);
            expect(restored.pulseCount, 1);
          });
        } finally {
          await tester.runAsync(() async {
            await controller.disconnectBleDevice();
            controller.dispose();
            await fixture.dispose();
            await device.changes.close();
            await device.counter.values.close();
          });
        }
      },
    );
  }

  bleTest('direct connection preserves defaults and READ plus NOTIFY', (
    tester,
  ) async {
    await source.start();
    await tick(tester);
    expect(source.currentState.status, PulseSourceStatus.ready);
    expect(device.connects, 1);
    expect(device.lastTimeout, const Duration(seconds: 12));
    expect(device.counter.notifies, 1);
    expect(device.counter.reads, 1);
    expect(events, isEmpty);
    await source.start();
    expect(device.connects, 1);
    await tick(tester, const Duration(seconds: 10));
    expect(device.counter.reads, 2);
    expect(events, isEmpty);
    expect(
      states.where((state) => state.status == PulseSourceStatus.ready),
      hasLength(1),
    );
    await finish();
  });

  bleTest(
    'persistent direct retries use capped backoff beyond three failures',
    (tester) async {
      device.failConnects = 8;
      await source.start();
      expect(source.currentState.status, PulseSourceStatus.reconnecting);
      for (final seconds in [1, 2, 4, 8, 15, 30, 30, 30]) {
        final before = device.connects;
        await tick(tester, Duration(milliseconds: seconds * 1000 - 1));
        expect(device.connects, before);
        await tick(tester, const Duration(milliseconds: 1));
        expect(device.connects, before + 1);
      }
      expect(source.currentState.status, PulseSourceStatus.ready);
      expect(device.connects, 9);
      expect(states.any((state) => state.compromised), isFalse);
      await finish();
    },
  );

  for (final operation in [
    'discover',
    'notify',
    'read',
    'service',
    'characteristic',
    'payload',
  ]) {
    bleTest('temporary $operation failure recovers GATT before READY', (
      tester,
    ) async {
      device.failure = operation;
      device.counter.failure = operation;
      await source.start();
      expect(source.currentState.status, PulseSourceStatus.reconnecting);
      expect(
        states.any((state) => state.status == PulseSourceStatus.ready),
        isFalse,
      );
      await tick(tester, const Duration(seconds: 1));
      expect(source.currentState.status, PulseSourceStatus.ready);
      expect(device.connects, 1);
      expect(device.discoveries, 2);
      expect(states.any((state) => state.compromised), isFalse);
      await finish();
    });
  }

  bleTest('lost notifications reconcile by keepalive without duplicates', (
    tester,
  ) async {
    await source.start();
    device.counter.count = 104;
    await tick(tester, const Duration(seconds: 10));
    expect(events.map((event) => event.sequence), [101, 102, 103, 104]);
    device.counter.emit();
    await tick(tester, const Duration(seconds: 10));
    expect(events, hasLength(4));
    await finish();
  });

  bleTest('disconnect and simultaneous errors share one recovery loop', (
    tester,
  ) async {
    await source.start();
    device.loseLink();
    device.counter.values.addError(StateError('notify unavailable'));
    device.changes.addError(StateError('link unavailable'));
    await tick(tester);
    expect(source.currentState.status, PulseSourceStatus.reconnecting);
    device.counter.count = 105;
    await tick(tester, const Duration(seconds: 1));
    expect(device.connects, 2);
    expect(source.currentState.status, PulseSourceStatus.ready);
    expect(events.map((event) => event.sequence), [101, 102, 103, 104, 105]);
    expect(states.any((state) => state.compromised), isFalse);
    await tick(tester, const Duration(seconds: 10));
    expect(device.counter.reads, 3);
    expect(events, hasLength(5));
    await finish();
  });

  bleTest(
    'notification error alone resubscribes and reads same connected device',
    (tester) async {
      await source.start();
      device.counter.values.addError(StateError('notification interruption'));
      await tick(tester);
      device.counter.count = 104;
      await tick(tester, const Duration(seconds: 1));
      expect(device.connects, 1);
      expect(device.counter.notifies, 2);
      expect(events, hasLength(4));
      expect(source.currentState.compromised, isFalse);
      await finish();
    },
  );

  bleTest('failed keepalive reads recover without integrity failure', (
    tester,
  ) async {
    await source.start();
    device.counter.failure = 'read';
    await tick(tester, const Duration(seconds: 10));
    expect(source.currentState.status, PulseSourceStatus.reconnecting);
    device.counter.count = 103;
    await tick(tester, const Duration(seconds: 1));
    expect(source.currentState.status, PulseSourceStatus.ready);
    expect(events, hasLength(3));
    expect(states.any((state) => state.compromised), isFalse);
    await finish();
  });

  bleTest('one keepalive read at a time and late read after stop is ignored', (
    tester,
  ) async {
    await source.start();
    device.counter.gate = Completer<List<int>>();
    await tick(tester, const Duration(seconds: 10));
    final reads = device.counter.reads;
    await tick(tester, const Duration(seconds: 30));
    expect(device.counter.reads, reads);
    final stopping = tester.runAsync(source.stop);
    await tester.pump();
    device.counter.gate!.complete(_payload(105));
    await stopping;
    expect(events, isEmpty);
    expect(source.currentState.status, PulseSourceStatus.stopped);
    await tick(tester, const Duration(minutes: 2));
    expect(device.connects, 1);
    await finish();
  });

  for (final dispose in [false, true]) {
    bleTest(
      '${dispose ? 'dispose' : 'explicit stop'} cancels waiting recovery',
      (tester) async {
        device.failConnects = 100;
        await source.start();
        if (dispose) {
          await tester.runAsync(source.dispose);
        } else {
          await tester.runAsync(source.stop);
        }
        await tick(tester, const Duration(minutes: 3));
        expect(device.connects, 1);
        expect(source.currentState.status, PulseSourceStatus.stopped);
        await finish();
      },
    );
  }

  bleTest('stop during connect prevents late GATT and disconnects late link', (
    tester,
  ) async {
    device.gate = Completer<void>();
    final starting = source.start();
    await tick(tester);
    final stopping = tester.runAsync(source.stop);
    await tester.pump();
    device.gate!.complete();
    await starting;
    await stopping;
    expect(device.discoveries, 0);
    expect(device.isConnected, isFalse);
    await tick(tester, const Duration(minutes: 1));
    expect(device.connects, 1);
    await finish();
  });

  bleTest(
    'rollback remains compromised across reconnect and restart attempts',
    (tester) async {
      device.counter.count = 845;
      await source.start();
      device.loseLink();
      await tick(tester);
      device.counter.count = 0;
      await tick(tester, const Duration(seconds: 1));
      expect(source.currentState.compromised, isTrue);
      expect(source.currentState.status, PulseSourceStatus.error);
      device.counter.count = 850;
      device.counter.emit();
      await source.start();
      await tick(tester, const Duration(minutes: 1));
      expect(events, isEmpty);
      expect(source.currentState.compromised, isTrue);
      await finish();
    },
  );

  bleTest('simultaneous starts share one connection and subscription', (
    tester,
  ) async {
    await Future.wait([source.start(), source.start(), source.start()]);
    expect(device.connects, 1);
    expect(device.counter.notifies, 1);
    await finish();
  });

  bleTest('stop immediately after start prevents deferred connection', (
    tester,
  ) async {
    final starting = source.start();
    final stopping = tester.runAsync(source.stop);
    await starting;
    await stopping;
    await tick(tester, const Duration(minutes: 1));
    expect(device.connects, 0);
    expect(source.currentState.status, PulseSourceStatus.stopped);
    await finish();
  });

  bleTest('initial disconnected snapshot does not start competing recovery', (
    tester,
  ) async {
    device.initialDisconnected = true;
    await source.start();
    await tick(tester, const Duration(seconds: 2));
    expect(device.connects, 1);
    expect(device.discoveries, 1);
    expect(source.currentState.status, PulseSourceStatus.ready);
    await finish();
  });

  bleTest('dispose during connect rejects late READY and future starts', (
    tester,
  ) async {
    device.gate = Completer<void>();
    final starting = source.start();
    await tick(tester);
    final disposal = tester.runAsync(source.dispose);
    await tester.pump();
    device.gate!.complete();
    await starting;
    await disposal;
    expect(device.isConnected, isFalse);
    expect(device.discoveries, 0);
    await expectLater(source.start(), throwsStateError);
    await finish();
  });

  for (final disposing in [false, true]) {
    bleTest(
      'stop/dispose during initial read ignores late endpoint disposing=$disposing',
      (tester) async {
        device.counter.gate = Completer<List<int>>();
        final starting = source.start();
        await tick(tester);
        final stopping = tester.runAsync(
          disposing ? source.dispose : source.stop,
        );
        await tester.pump();
        device.counter.gate!.complete(_payload(105));
        await starting;
        await stopping;
        expect(
          states.any((state) => state.status == PulseSourceStatus.ready),
          isFalse,
        );
        expect(source.lastObservedCounter, isNull);
        expect(events, isEmpty);
        await finish();
      },
    );
  }

  bleTest('link lost during discovery never publishes stale READY', (
    tester,
  ) async {
    device.discoveryGate = Completer<void>();
    final starting = source.start();
    await tick(tester);
    device.loseLink();
    await tick(tester);
    device.discoveryGate!.complete();
    await starting;
    expect(source.currentState.status, PulseSourceStatus.reconnecting);
    expect(
      states.any((state) => state.status == PulseSourceStatus.ready),
      isFalse,
    );
    device.discoveryGate = null;
    await tick(tester, const Duration(seconds: 1));
    expect(source.currentState.status, PulseSourceStatus.ready);
    await finish();
  });

  bleTest('in-process background and foreground do not rebuild transport', (
    tester,
  ) async {
    await source.start();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    device.counter.count = 104;
    await tick(tester, const Duration(seconds: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tick(tester);
    expect(device.connects, 1);
    expect(events, hasLength(4));
    await finish();
  });

  test(
    'same transport rebinds Sample A to B to A without duplicate persistence',
    () async {
      setupSource();
      final directory = await Directory.systemTemp.createTemp(
        'ble-sample-binding-',
      );
      final fixture = OfflineFixture(memoryDatabase(), directory);
      await fixture.seed();
      await fixture.running(id: 'sample-a', method: MeasurementMethod.ble);
      await fixture.running(
        id: 'sample-b',
        number: 2,
        method: MeasurementMethod.ble,
      );
      final progress = PulseProgressService(fixture.samples);
      StreamSubscription<PulseEvent>? subscription;
      Future<void> pending = Future.value();
      try {
        await source.start();
        for (final binding in [
          ('sample-a', 101),
          ('sample-b', 102),
          ('sample-a', 103),
        ]) {
          await subscription?.cancel();
          subscription = source.events.listen((event) {
            pending = pending.then((_) async {
              await progress.acceptPulse(binding.$1, event);
            });
          });
          device.counter.count = binding.$2;
          device.counter.emit();
          device.counter.emit();
          await Future<void>.delayed(Duration.zero);
          await pending;
        }
        expect((await fixture.samples.getById('sample-a'))!.pulseCount, 2);
        expect((await fixture.samples.getById('sample-b'))!.pulseCount, 1);
        expect(device.connects, 1);
        expect(device.counter.notifies, 1);
      } finally {
        await subscription?.cancel();
        await source.dispose();
        await fixture.database.close();
        await directory.delete(recursive: true);
        await device.changes.close();
        await device.counter.values.close();
      }
    },
  );

  bleTest('uint32 wrap still emits exact sequences once', (tester) async {
    device.counter.count = 0xfffffffe;
    await source.start();
    device.counter.count = 1;
    device.counter.emit();
    device.counter.emit();
    await tick(tester);
    expect(events.map((event) => event.sequence), [0xffffffff, 0, 1]);
    expect(source.currentState.compromised, isFalse);
    await finish();
  });
}

List<int> _payload(int counter) {
  final bytes = ByteData(5)
    ..setUint8(0, 1)
    ..setUint32(1, counter, Endian.little);
  return bytes.buffer.asUint8List();
}

final class _Device extends BluetoothDevice {
  _Device() : super.fromId('AA:BB:CC:DD:EE:FF');
  final changes = StreamController<BluetoothConnectionState>.broadcast();
  final counter = _Counter();
  bool connected = false;
  int connects = 0;
  int failConnects = 0;
  int discoveries = 0;
  int pendingConnections = 0;
  int maximumConnections = 0;
  Duration? lastTimeout;
  String? failure;
  Completer<void>? gate;
  Completer<void>? discoveryGate;
  bool initialDisconnected = false;

  @override
  bool get isConnected => connected;
  @override
  Stream<BluetoothConnectionState> get connectionState => changes.stream;

  @override
  Future<void> connect({
    Duration timeout = const Duration(seconds: 35),
    int? mtu = 512,
    bool autoConnect = false,
  }) async {
    expectSync(autoConnect, isFalse);
    expectSync(mtu, 512);
    connects++;
    if (initialDisconnected) changes.add(BluetoothConnectionState.disconnected);
    lastTimeout = timeout;
    pendingConnections++;
    if (pendingConnections > maximumConnections) {
      maximumConnections = pendingConnections;
    }
    try {
      await gate?.future;
      if (connects <= failConnects) {
        throw StateError('Transient connection failure');
      }
      connected = true;
      changes.add(BluetoothConnectionState.connected);
    } finally {
      pendingConnections--;
    }
  }

  void loseLink() {
    connected = false;
    changes.add(BluetoothConnectionState.disconnected);
  }

  @override
  Future<void> disconnect({
    int timeout = 35,
    bool queue = true,
    int androidDelay = 2000,
  }) {
    loseLink();
    return Future<void>.value();
  }

  @override
  Future<List<BluetoothService>> discoverServices({
    bool subscribeToServicesChanged = true,
    int timeout = 15,
  }) async {
    discoveries++;
    await discoveryGate?.future;
    final problem = failure;
    failure = null;
    if (problem == 'discover') throw StateError('Transient GATT failure');
    if (problem == 'service') return [];
    return [
      _Service(problem == 'characteristic' ? [] : [counter]),
    ];
  }
}

final class _Service extends Fake implements BluetoothService {
  _Service(this.characteristics);
  @override
  final List<BluetoothCharacteristic> characteristics;
  @override
  Guid get uuid => Guid(Ddr001BleContract.serviceUuid);
}

final class _Counter extends BluetoothCharacteristic {
  _Counter()
    : super(
        remoteId: const DeviceIdentifier('AA:BB:CC:DD:EE:FF'),
        serviceUuid: Guid(Ddr001BleContract.serviceUuid),
        characteristicUuid: Guid(Ddr001BleContract.counterCharacteristicUuid),
      );
  final values = StreamController<List<int>>.broadcast();
  int count = 100;
  int reads = 0;
  int notifies = 0;
  int activeListeners = 0;
  int maximumListeners = 0;
  String? failure;
  Completer<List<int>>? gate;

  void emit() => values.add(_payload(count));

  @override
  Stream<List<int>> get onValueReceived => Stream.multi((listener) {
    activeListeners++;
    if (activeListeners > maximumListeners) {
      maximumListeners = activeListeners;
    }
    final subscription = values.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = () {
      activeListeners--;
      return subscription.cancel();
    };
  });

  @override
  Future<bool> setNotifyValue(
    bool notify, {
    int timeout = 15,
    bool forceIndications = false,
  }) async {
    expectSync(notify, isTrue);
    notifies++;
    if (failure == 'notify') {
      failure = null;
      throw StateError('Transient subscribe failure');
    }
    return true;
  }

  @override
  Future<List<int>> read({int timeout = 15}) async {
    reads++;
    if (failure == 'read') {
      failure = null;
      throw StateError('Transient read failure');
    }
    if (failure == 'payload') {
      failure = null;
      return [];
    }
    if (gate != null) return gate!.future;
    final payload = _payload(count);
    values.add(payload);
    return payload;
  }
}

final class _UnusedCamera extends Fake implements CameraPort {}
