# ADR-017 — Procedencia del dispositivo y presentación del reporte

- **Estado:** aceptada
- **Fecha:** 2026-08-21

## Contexto

Cada diagnóstico debe identificar el banco físico y el teléfono que originó sus datos. La procedencia del teléfono sirve para auditoría interna, pero no debe exponer identificadores técnicos en el reporte entregable.

## Decisión

- El expediente congela `test_bench_id` obligatorio y metadata nullable del dispositivo: ID, versión de Android, marca y modelo.
- La metadata del teléfono se conserva en SQLite, sincronización y exporte estructurado; Ajustes permite inspeccionarla. HTML/PDF no la presentan.
- HTML/PDF muestran el banco, ordenan muestras por `createdAt`, localizan las etiquetas, muestran fecha por prueba y únicamente hora local por punto.
- `V.MEC L` usa `meter_under_test_pulse_count × hydrant_liters_per_pulse`.
- Mínimo, máximo y promedio se derivan solo de los `Point.flow_lps` persistidos en las evidencias de la prueba.
- El reporte incluye configuración metrológica, identidad ESP32, repetibilidad y un SVG autocontenido que ubica el GPS; un enlace externo opcional abre cartografía detallada.
- Integridad/adquisición, endpoints, evidencias y configuración de cámara se presentan exclusivamente en el resumen local expandible de cada prueba finalizada.

## Consecuencias

- Drift avanza aditivamente a schema 11; expedientes históricos conservan banco vacío y metadata nullable.
- El checksum de expedientes nuevos usa canonicalización v2 e incluye banco y procedencia; expedientes históricos sin esos datos conservan v1.
- Los identificadores técnicos no aparecen en el reporte presentable.
- La presentación no recalcula caudales desde eventos no persistidos ni altera el resultado metrológico.
