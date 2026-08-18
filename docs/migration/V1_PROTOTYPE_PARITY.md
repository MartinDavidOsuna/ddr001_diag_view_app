# V1 — Paridad con el prototipo

> Estado inicial auditado el 2026-08-15 sobre `feature/stage-5-esp32-pulse-sources` (`9611278`).
> `docs/ssot/` prevalece cuando una decisión vigente sustituye al prototipo.

| Prototipo | Flutter V1 | Estado | Evidencia |
|---|---|---|---|
| 1. Identificación | ID libre, operador desde sesión, Q1–Q4, LPS, MPE, GPS y consulta informativa | IMPLEMENTADO | GPS local con estados de permiso/error; consulta remota solo visible si está configurada; smoke GPS real pendiente |
| 2. Fuente de pulso | LECTURA VISUAL, MANUAL, LED y BLE | PARCIAL | Selector y pipeline real presentes; validación física LED/Píxel pendiente |
| 3. Carátula | Cámara, Evidence completa, selección táctil manual-first, totalizador, un dial, OCR/aguja y corrección | IMPLEMENTADO | OCR/aguja limitados a crops confirmados, geometría START recuperable y tests de layouts/artefactos; smoke Pixel pendiente |
| 4. Prueba | Sample real, métricas, pulso manual, evidencia planificada, punto diagnóstico y cierre | IMPLEMENTADO | `TestRunScreen`, `ExpectedEvidencePlan`, Points y tests de controlador |
| 5. Registro | Tabla START/INTERMEDIATE/FINAL con valores persistidos | IMPLEMENTADO | `TestRunScreen` y repositorio de puntos; requiere smoke final V1 |
| 6. Lecturas/cálculo | Fotos START/FINAL, propuesta, corrección y motor endpoint | IMPLEMENTADO | `ReadingsScreen`, Stage 1 y Stage 4; requiere smoke final V1 |
| 7. Muestras/reporte | Muestras ilimitadas, estadísticas, cambio de caudal y cierre | PARCIAL | Resumen existente; selección de muestras y reporte consolidado faltan |
| 8. Ajustes | K, paso, Vmín, Vmáx, incertidumbre y Manual de Uso | IMPLEMENTADO | Ajustes operativos, `SampleConfiguration` y manual Markdown canónico offline |
| 9. CSV | Exportación tabular real | IMPLEMENTADO | `CaseExportService.toCsv` y test estructural |
| 10. JSON/fila | Exportación estructurada conforme contratos actuales | IMPLEMENTADO | `CaseExportService.toJson`; no incluye fotografías Base64 |
| 11. HTML | Reporte autocontenido con evidencias | IMPLEMENTADO | HTML con data URI, tabla, resultado, imágenes ordenadas y sello; test offline |
| 12. PDF | PDF offline equivalente al reporte | IMPLEMENTADO | PDF local con tablas, resultado e imágenes; test de encabezado/tamaño |

## Hallazgos de Stage 5

- Firmware y `platformio.ini` usan el LED integrado GPIO2, activo HIGH; GPIO27 permanece como entrada.
- Flutter ya contiene reconciliación LED mediante contador BLE, métricas de frames, coordinación de cámara e integridad persistente.
- Las notas Stage 5.1 históricas describen el LED externo GPIO25; SSOT/CHANGELOG vigente ya registra GPIO2 integrado.
- El firmware compila, pero COM15 no estuvo disponible durante la auditoría inicial. La validación física no se presume.

Los estados cambian a `IMPLEMENTADO` o `VALIDADO` únicamente junto con evidencia automatizada o física reproducible.
