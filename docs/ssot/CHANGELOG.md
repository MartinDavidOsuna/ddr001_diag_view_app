# CHANGELOG funcional

## Etapa 1 — 2026-08-09 — Motor metrológico Dart
- Se crea un paquete Flutter mínimo en `app/` para alojar el motor Dart puro, sin UI ni infraestructura de etapas posteriores.
- Se implementan Q1–Q4, política MPE Clase 2 sustituible, fuentes productivas `VISUAL | MANUAL | LED | BLE` sin pulsos ficticios para LECTURA VISUAL, volumen patrón, reconstrucción de vueltas, volumen indicado y error endpoint.
- Se implementan una política desacoplada de incertidumbre, banda de guarda con comparación tolerante sin redondeo, resultado inmutable de muestra, estadísticas, repetibilidad, resumen de caudal y veredicto global explícito.
- Se agregan 54 tests unitarios, incluidos casos de frontera, referencia SSOT y regresión compatible con el simulador legado.
- Se documentan las discrepancias del prototipo en `docs/migration/STAGE_1_METROLOGY_NOTES.md`; prevalece SSOT v9.

## v9 — 2026-08-08 — Corrección LECTURA VISUAL
- Se corrige la interpretación de la fuente/método `Simulación` del prototipo: su funcionalidad se conserva en producción bajo el nombre **LECTURA VISUAL**.
- Métodos productivos definitivos: `LECTURA VISUAL | MANUAL | LED ESP32 | BLE ESP32`.
- **LECTURA VISUAL** opera sobre medidores reales en campo mediante cámara/visión; no es simulación.
- El simulador web existente permanece externo, sin modificaciones, y sirve como banco de validación de LECTURA VISUAL y del motor metrológico.
- Manual/LED/BLE comparten eventos de pulso de `K` litros; LECTURA VISUAL comparte dominio y cálculo, pero no se fuerza a generar pulsos ficticios.

## v8 — 2026-08-08 — SSOT consolidada Etapa 0
- Stack confirmado: Flutter Android portrait + Node/TypeScript/Express + Prisma/PostgreSQL, monorepo y Windows Server 2018.
- Login passwordless email+teléfono, alta automática y sesión persistente hasta logout.
- Integración read-only con API existente de hidrantes; IDs nuevos siempre permitidos.
- Nomenclatura Q1/Q2/Q3/Q4 corregida; LPS manual.
- Regla metrológica con banda de guarda: APRUEBA / RECHAZA / NO CONCLUYENTE.
- Dominio: Medidor→Expediente→Caudal→Muestras ilimitadas; veredicto global.
- Muestras cerradas inmutables.
- Evidencias obligatorias; falla de foto invalida corrida y exige repetición.
- OCR de odómetro + visión de aguja con confirmación/corrección humana previa al cierre.
- Fuentes productivas: Manual, LED ESP32 y BLE ESP32; simulador permanece externo.
- HTML autocontenido fiel al reporte de referencia + botón Descargar PDF.
- Conservación local sin purga automática.
- Backend preparado para endpoints de futuro panel administrativo.

## v7 — 2026-08-08 — base legado
- Flujo y UI del prototipo web usados como referencia de migración.
- MPE por zonas y cálculo endpoint presentes en prototipo.
- Multi-muestra inicial y exportes.
