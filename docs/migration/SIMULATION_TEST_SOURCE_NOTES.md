# Modo SIMULACIÓN — notas de implementación y migración

## Alcance

La versión `1.3.0+10` agrega una fuente local de QA que recorre el pipeline real sin hardware ni red. No integra ni modifica `legacy/web-prototype/simulador_medidor.html`, backend o firmware.

## Persistencia

- Drift avanza de schema 11 a 12.
- `samples.simulation_scenario` es nullable y sólo admite `successful`, `failed` o `failThenPass` cuando `measurement_method = simulation`.
- Drift reconstruye controladamente la tabla para ampliar el CHECK existente, copiando las columnas y filas v11. La prueba automatizada conserva una Sample RUNNING durante la migración.
- Muestras reales conservan `simulation_scenario = null`, canonicalización histórica y export JSON v1.
- Muestras simuladas usan canonical checksum v6 y export JSON v2 con trazabilidad explícita.

## Flujo

`SimulationWorkflowService` crea START, alimenta `PulseProgressService`, captura INTERMEDIATE planificadas y FINAL, persiste lecturas y delega el cierre a `SampleClosureService`. El placeholder se copia al filesystem de Evidence y su SHA-256 se calcula sobre los bytes realmente escritos.

Los escenarios sólo eligen entradas deterministas:

- `successful`: error dentro de banda de guarda.
- `failed`: error fuera del MPE.
- `failThenPass`: conserva una primera Sample fallida y ejecuta una segunda aprobada.

El motor Stage 1 permanece como única autoridad del veredicto.

## Compatibilidad

No cambian UUIDs, payload, scan, keepalive, reconciliación BLE, MANUAL, LED, GPIO ni firmware. SIMULACIÓN no crea fuentes BLE ni exige backend, cámara o Internet. Recovery vuelve a leer contador, escenario y Evidence desde SQLite/filesystem.
