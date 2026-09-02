# ADR-020 — Fuente de simulación trazable

- **Estado:** aceptada
- **Fecha:** 2026-09-01

## Contexto

La certificación de Registro, Historial, persistencia y exportes necesita ejecutar el workflow completo sin medidor, Bluetooth, ESP32, cámara, backend o Internet. Crear reportes falsos o fijar directamente un veredicto evitaría justamente los componentes que se deben verificar. LECTURA VISUAL continúa siendo un método productivo sobre un medidor real y el simulador web legado permanece externo.

## Decisión

- Incorporar `SIMULATION` como fuente de eventos separada de `SimulationScenario`.
- Persistir `SUCCESSFUL`, `FAILED` o `FAIL_THEN_PASS` en cada Sample simulada; una Sample real debe conservar el campo null.
- Generar Vref, Vind, caudal y pulsos deterministas según Q y MPE, pero delegar error, incertidumbre, banda de guarda y veredicto al motor metrológico real.
- Ejecutar el progreso mediante `PulseProgressService` y el cierre mediante `SampleClosureService`.
- Crear START, INTERMEDIATE y FINAL conforme al plan real. Cada Evidence copia un asset inequívoco al filesystem del expediente y persiste el SHA-256 calculado sobre ese archivo.
- Persistir el estado RUNNING para que recovery continúe desde el contador y reutilice Evidence existente.
- Marcar UI, Historial y exportes con una advertencia de prueba no física. El escenario mixto conserva la primera Sample fallida y agrega una segunda aprobada.
- Drift avanza de 11 a 12 con migración preservadora; Sample contract avanza de v8 a v9. La canonicalización v6 se aplica sólo a simulaciones.

## Consecuencias

- La simulación prueba el mismo pipeline local que una corrida, sin inicializar BLE ni llamar backend.
- Los datos de QA no pueden confundirse razonablemente con verificaciones físicas.
- Los reportes reales conservan su contrato y no reciben advertencias adicionales.
- Firmware, UUIDs, reconciliación ESP32, MANUAL y LED no cambian.
