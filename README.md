# DDR001 Verificador Funcional

App Flutter Android offline-first con Drift/SQLite. El backend productivo es
`ddr001_api` (Node.js/TypeScript + SQL Server). `backend/` es referencia
histórica Prisma/PostgreSQL y no se despliega.

```sh
cd app
flutter pub get
flutter build apk --release --dart-define-from-file=config/production.json
```

La configuración productiva habilita **SINCRONIZAR** en el resumen del
expediente. Sin `DDR001_API_BASE_URL`, el build conserva operación sólo local
y oculta el botón. No se requiere servidor para capturar ni consultar trabajo.
Consulte [la guía de entrega Android](docs/deployment/ANDROID_PRODUCTION.md).

## Estado
- **Etapa 0 SSOT: cerrada** (v9, 2026-08-08).
- **Etapa 1 motor metrológico Dart: cerrada** (2026-08-09).
- **Etapa 2 dominio y persistencia offline: cerrada** (2026-08-09).
- **Etapa 3 UI Flutter offline: cerrada** (2026-08-10).
- **Etapa 4 cámara y lectura visual: cerrada** (2026-08-10).
- **Stage 5 implementación: completa; validación física final bloqueada por hardware no disponible**.
- **Reporte/exportes/backend V1: implementados y cubiertos por pruebas automatizadas** (2026-08-15).

## Motor metrológico
- API pública: `app/lib/core/metrology/metrology.dart`.
- Pruebas: `app/test/core/metrology/`.
- Validación desde `app/`: `dart format .`, `flutter analyze` y `flutter test`.

## Persistencia offline
- Schema Drift v6, con migraciones aditivas y compatibilidad histórica: `app/lib/data/local/database/app_database.dart`.
- Dominio: `app/lib/domain/`.
- Repositorios y cierres transaccionales: `app/lib/data/local/repositories/`.
- Notas: `docs/migration/STAGE_2_OFFLINE_DOMAIN_NOTES.md`.

## Principios
- Offline-first.
- UI fiel a capturas.
- Medidor → Expediente → Q1/Q2/Q3/Q4 → muestras ilimitadas.
- Muestras cerradas inmutables.
- Evidencia fotográfica obligatoria.
- Selección táctil manual-first de totalizador y un dial; OCR/aguja se ejecutan solo en crops confirmados.
- GPS local offline con estados de permiso/error y Manual de Uso empaquetado en Ajustes.
- **LECTURA VISUAL / Manual / LED ESP32 / BLE ESP32** como métodos productivos de medición.
- El simulador web legado permanece únicamente como herramienta externa para validar LECTURA VISUAL y el motor; no se integra.

Lee `AGENTS.md` y `docs/ssot/PROJECT_TRUTH.md` antes de codificar.
