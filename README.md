# DDR001 Verificador de Medidores

Stage 5 incorporó el pipeline común de pulsos y los núcleos BLE/LED. Su cierre productivo permanece condicionado por integración UI/persistencia, contrato del firmware y validación física; consulta `docs/migration/STAGE_5_ESP32_PULSE_SOURCES_NOTES.md`.
Stage 5.1 agrega firmware ESP32 real, contador BLE reconciliable, persistencia schema 5 e ImageStream LED. BLE quedó validado físicamente; LED/flujo Pixel completo sigue pendiente de la conexión externa documentada en `STAGE_5_1_ESP32_RESULTS.md`.

La Etapa 4 ofrece una aplicación Flutter Android portrait funcional y offline en `app/`: flujo Stage 3 completo más cámara real, evidencia hasheada, OCR on-device, detección de aguja y confirmación humana trazable.

```powershell
cd app
flutter pub get
dart run build_runner build
flutter run
```

LECTURA VISUAL usa cámara/evidencia productiva. LED/BLE real, backend, sincronización remota y reportes todavía no están implementados.

Migración del verificador de medidores a **Flutter Android** con backend **Node.js + TypeScript + Express + Prisma + PostgreSQL**.

## Estado
- **Etapa 0 SSOT: cerrada** (v9, 2026-08-08).
- **Etapa 1 motor metrológico Dart: cerrada** (2026-08-09).
- **Etapa 2 dominio y persistencia offline: cerrada** (2026-08-09).
- **Etapa 3 UI Flutter offline: cerrada** (2026-08-10).
- **Etapa 4 cámara y lectura visual: cerrada** (2026-08-10).

## Motor metrológico
- API pública: `app/lib/core/metrology/metrology.dart`.
- Pruebas: `app/test/core/metrology/`.
- Validación desde `app/`: `dart format .`, `flutter analyze` y `flutter test`.

## Persistencia offline
- Schema Drift v2, con migración aditiva desde v1: `app/lib/data/local/database/app_database.dart`.
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
