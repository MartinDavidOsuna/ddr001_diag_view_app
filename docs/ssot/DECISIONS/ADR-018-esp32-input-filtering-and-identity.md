# ADR-018 — Filtrado de entradas e identidad versionada del ESP32

- **Estado:** aceptada
- **Fecha:** 2026-08-21

## Contexto

GPIO25 produjo pulsos sin medidor conectado y dos teléfonos reportaron pérdida GATT coincidente con actividad de esa entrada. El debounce temporal en ISR aceptaba cualquier flanco suficientemente separado y cada aceptación generaba una notificación BLE.

## Decisión

- GPIO25 y GPIO27 usan unidades PCNT independientes con el máximo filtro de glitches del ESP32 clásico (1023 ciclos APB).
- Un flanco filtrado solo se acepta si LOW permanece estable al menos 17 ms, respeta debounce de 40 ms y la entrada se rearma después de HIGH estable 2 ms.
- El configurador exige `--nombre ESP32-<SERIE>-V<VERSIÓN>` y genera el nombre anunciado `DDR001-PULSE-<SERIE>-V<VERSIÓN>` para conservar el contrato de descubrimiento Flutter.
- La característica de estado incluye protocolo y nombre BLE.

## Consecuencias

- Ruido breve, rebotes y entradas flotantes dejan de incrementar/notificar directamente.
- Pulsos físicos menores de 17 ms se rechazan deliberadamente; cualquier sensor que produzca pulsos más cortos requiere una nueva decisión documentada antes de reducir el umbral.
- El filtrado reduce una causa probable de ráfagas GATT, pero no demuestra por sí solo el origen de todas las desconexiones Android.
