# DDR001 Verificador de Medidores

La V1 integra el pipeline común MANUAL/BLE/LED, LECTURA VISUAL, evidencia, registro, reportes offline y backend PostgreSQL. Stage 5 usa GPIO27 para pulsos y LED integrado GPIO2; BLE tuvo validación física previa y la corrida final LED/Pixel permanece pendiente de acceso al hardware.

La Etapa 4 ofrece una aplicación Flutter Android portrait funcional y offline en `app/`: flujo Stage 3 completo más cámara real, evidencia hasheada, OCR on-device, detección de aguja y confirmación humana trazable.

```powershell
cd app
flutter pub get
dart run build_runner build
flutter run
```

El primer acceso crea y conserva la identidad localmente, sin requerir backend. Si se configura el backend experimental, la aplicación utiliza el proveedor remoto:

```powershell
flutter build apk --debug --dart-define=DDR001_API_BASE_URL=http://servidor:3000
```

El backend está en `backend/`. Consulte su README y `docs/deployment/WINDOWS_SERVER_2018.md` para crear PostgreSQL, aplicar migraciones y configurar filesystem de evidencia.

Migración del verificador de medidores a **Flutter Android** con backend **Node.js + TypeScript + Express + Prisma + PostgreSQL**.

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
