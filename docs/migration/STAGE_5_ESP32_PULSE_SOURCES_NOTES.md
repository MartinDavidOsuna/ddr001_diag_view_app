# Stage 5 — Fuentes de pulso ESP32

Fecha: 2026-08-11. Rama: `feature/stage-5-esp32-pulse-sources`.

## Arquitectura implementada

`PulseSource` expone lifecycle, estado y stream de `PulseEvent`. `PulseProgressService` es la única operación que acepta eventos MANUAL/LED/BLE, vuelve a leer la Sample RUNNING, valida la fuente congelada, incrementa el entero y persiste `N × K`. MANUAL fue movido a este servicio sin cambiar su UX.

BLE usa `flutter_blue_plus 1.36.8`, línea 1.x BSD elegida después de comprobar que `flutter_reactive_ble 5.5.0` no ensambla su módulo Android actual por declarar `compileSdk 33`. No existía UUID ni trama en SSOT/firmware del repositorio, por lo que `BlePulseConfiguration` recibe identidad y UUIDs reales sin MAC hardcodeada. `BlePulseProtocol` acepta exactamente byte `0x01` o UTF-8 `PULSE`; rechaza el resto. La fuente distingue connecting/connected/ready/reconnecting/error, mantiene una única suscripción y marca comprometida una pérdida de enlace. Sin sequence/counter firmware no puede reconciliar el periodo desconectado.

Android declara `BLUETOOTH_SCAN` (`neverForLocation`) y `BLUETOOTH_CONNECT`; para API <=30 conserva permisos de ubicación limitados por `maxSdkVersion=30`. CAMERA permanece intacto.

LED usa `LedRegion` relativa, baseline promedio breve, umbrales por delta (35 rising/20 falling por defecto), histéresis y `minPulseInterval=150 ms`. Solo DARK→BRIGHT emite. El procesamiento depende de `LedBrightnessPort`, de modo que tests sintéticos y cámara productiva pueden usar el mismo detector.

## Coordinación e integridad

`CameraResourceCoordinator` representa exclusión entre evidencia y detector. El adaptador Android actual no demuestra foto full-resolution y stream simultáneos. Sin contador acumulado ESP32, solicitar evidencia durante detección LED se rechaza como adquisición comprometida; no hay pausa silenciosa. Por eso la arquitectura/detector LED están implementados, pero LED no queda validado ni habilitado para cierre productivo en esta entrega.

La condición comprometida todavía no se persiste: no se cambió Drift schema 4, canonical v3 ni Sample contract v6. Esto es correctivo imprescindible antes de considerar LED cerrado.

## Validación y limitaciones

Las pruebas automáticas cubren payloads, señales LED, ruido, bright sostenido, histéresis, debounce, baseline, coordinación exclusiva, operación común, concurrencia, deduplicación y rechazo VISUAL. No se confirmó hardware ESP32 ni contrato de firmware durante esta ejecución.

- Falta UI productiva de descubrimiento/selección y persistencia de `BlePulseConfiguration`.
- Falta adaptador de frames de cámara para `LedBrightnessPort`, medición FPS/duración/frecuencia y corpus físico.
- Falta persistir adquisición comprometida y bloquear cierre en dominio.
- Stage 5 no puede cerrarse hasta resolver esos puntos y validar hardware real.
