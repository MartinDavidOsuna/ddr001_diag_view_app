# CHANGELOG funcional

## Correctivo Etapa 2 — 2026-08-10 — Plan obligatorio de evidencias
- El cierre ya no confía en Points INTERMEDIATE existentes: deriva START, múltiplos del paso estrictamente anteriores al Vref final y una única FINAL.
- La ausencia de evidencia se detecta aunque nunca se haya creado el Point correspondiente; existencia física y SHA-256 siguen siendo obligatorios.
- FINAL sustituye a INTERMEDIATE cuando coincide exactamente con un múltiplo, evitando dos fotografías en el mismo instante.
- VISUAL usa el mismo plan con su Vref explícito, sin pulsos ficticios.
- Se alinean los JSON Schema compartidos con `measurement_source`, campos nullable/no aplicables y estados previos al cierre; Sample avanza a `ddr001.verification.sample/v3`.
- Se conserva temporalmente `com.example.ddr001_app`; el applicationId definitivo queda pendiente antes de Etapa 3.

## Etapa 2 — 2026-08-09 — Dominio y persistencia offline
- Se agrega dominio inmutable separado de Drift para usuario, medidor, expediente, caudal, muestra, punto, evidencia y cola sync.
- Se crea SQLite/Drift `schemaVersion = 1` con foreign keys, índices, constraints, migración explícita y triggers de inmutabilidad.
- Se implementan repositorios locales, recuperación de OPEN/DRAFT/RUNNING/INVALID_EVIDENCE y persistencia de progreso para reanudación tras reinicio.
- Se implementa cierre transaccional de muestra con validación física/hash de evidencias, motor metrológico de Etapa 1, resultado/checksum congelado y enqueue idempotente.
- Se implementa cierre transaccional de expediente con caudales requeridos explícitos, estadísticas/veredicto del motor y enqueue local.
- Se agrega filesystem de evidencia por IDs opacos, SHA-256 y prohibición de eliminar evidencia cerrada; no se guardan binarios en SQLite.
- LECTURA VISUAL persiste Vref explícito y no genera pulsos ficticios; MANUAL/LED/BLE conservan `N × K`.
- Se agrega ADR-009 y `docs/migration/STAGE_2_OFFLINE_DOMAIN_NOTES.md`.

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
