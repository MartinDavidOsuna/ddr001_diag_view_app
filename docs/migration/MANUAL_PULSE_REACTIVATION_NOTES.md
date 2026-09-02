# Reactivación MANUAL — 2026-09-01

## Historia verificada

- `b5d24a5d3027dc4932cf9e92adfd33c44dd20da4` introdujo MANUAL en Stage 3 con selector, botón de pulso y persistencia por `PulseProgressService`.
- `6ffec407bb01a369f1b089bfb70a9fbdcb12e247` ocultó MANUAL al restringir el selector a BLE/VISUAL y exigir hardware READY para avanzar. No eliminó el dominio, controlador, botón, persistencia, recovery ni exportes.
- `e142f541d1eb3025db04bb22ffc5b2e3f7d920be` agregó SIMULACIÓN sobre la lista restringida sin reemplazar MANUAL.

## Decisión

Se restaura `MeasurementMethod.manual` en el selector y se permite continuar sin hardware. El contrato vigente tiene un solo `pulseCount` que alimenta `Vref`; por eso se conserva un único botón `+1 PULSO`. Cada tap genera `PulseEvent.manual` y converge con BLE en `PulseProgressService.acceptPulse()`.

No cambia Drift schema 12, metrología, BLE, firmware, backend, Simulación ni formatos de reporte.
