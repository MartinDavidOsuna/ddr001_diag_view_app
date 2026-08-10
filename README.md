# DDR001 Verificador de Medidores

Migración del verificador de medidores a **Flutter Android** con backend **Node.js + TypeScript + Express + Prisma + PostgreSQL**.

## Estado
- **Etapa 0 SSOT: cerrada** (v9, 2026-08-08).
- **Etapa 1 motor metrológico Dart: cerrada** (2026-08-09).
- **Etapa 2 dominio y persistencia offline: cerrada** (2026-08-09).
- `app/` contiene motor Dart, dominio, Drift/SQLite, filesystem local y cola sync; no contiene UI ni integraciones remotas.

## Motor metrológico
- API pública: `app/lib/core/metrology/metrology.dart`.
- Pruebas: `app/test/core/metrology/`.
- Validación desde `app/`: `dart format .`, `flutter analyze` y `flutter test`.

## Persistencia offline
- Schema Drift v1: `app/lib/data/local/database/app_database.dart`.
- Dominio: `app/lib/domain/`.
- Repositorios y cierres transaccionales: `app/lib/data/local/repositories/`.
- Notas: `docs/migration/STAGE_2_OFFLINE_DOMAIN_NOTES.md`.

## Principios
- Offline-first.
- UI fiel a capturas.
- Medidor → Expediente → Q1/Q2/Q3/Q4 → muestras ilimitadas.
- Muestras cerradas inmutables.
- Evidencia fotográfica obligatoria.
- Aguja + OCR con confirmación humana.
- **LECTURA VISUAL / Manual / LED ESP32 / BLE ESP32** como métodos productivos de medición.
- El simulador web legado permanece únicamente como herramienta externa para validar LECTURA VISUAL y el motor; no se integra.

Lee `AGENTS.md` y `docs/ssot/PROJECT_TRUTH.md` antes de codificar.
