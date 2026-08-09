# MIGRATION_PLAN — Plan aprobado

Cada etapa requiere tests verdes, SSOT/CHANGELOG actualizado y CI limpio.

## Etapa 0 — SSOT y decisiones ✅
- [x] Consolidar Flutter Android portrait + Node/Express + Prisma/PostgreSQL.
- [x] Login email+teléfono, alta automática y sesión persistente.
- [x] Jerarquía Medidor→Expediente→Caudal→Muestras ilimitadas.
- [x] Regla de decisión con incertidumbre y NO CONCLUYENTE.
- [x] Evidencia obligatoria e inmutabilidad.
- [x] OCR + aguja con confirmación humana.
- [x] **LECTURA VISUAL** conservada como funcionalidad productiva de campo; simulador web externo separado y solo para validación.
- [x] Storage inicial filesystem Windows Server 2018.
- [x] API preparada para panel futuro e integración read-only con hidrantes.

## Etapa 1 — Motor metrológico
- [x] Refactor/port puro en Dart sin widgets.
- [x] Q1-Q4, MPE, V_ref, V_ind, vueltas, E, U, banda de guarda, repetibilidad y veredicto global.
- [x] Tests de frontera, regresión compatible con el simulador y casos de referencia.

Notas y diferencias del legado: `STAGE_1_METROLOGY_NOTES.md`.

## Etapa 2 — Dominio + persistencia local
- [ ] Flutter create/configuración definitiva Android.
- [ ] Drift/SQLite y filesystem.
- [ ] Entidades User/Meter/Case/FlowPoint/Sample/Point/Evidence/SyncItem.
- [ ] Máquina de estados e inmutabilidad.

## Etapa 3 — UI Flutter
- [ ] Replicar capturas de `design/screenshots/`.
- [ ] Login, identificación, fuentes, cámara, prueba, registro, cálculo, muestras/expediente, ajustes.

## Etapa 4 — Cámara y visión
- [ ] Lectura aguja.
- [ ] OCR odómetro.
- [ ] Confirmación/corrección humana.
- [ ] Evidencias obligatorias e integridad.

## Etapa 5 — ESP32
- [ ] Interfaz común de pulsos para Manual/BLE/LED y abstracción de adquisición compatible con LECTURA VISUAL.
- [ ] **LECTURA VISUAL** sobre medidor real mediante cámara/visión.
- [ ] BLE ESP32.
- [ ] LED ESP32 por cámara.
- [ ] Validación de LECTURA VISUAL y motor contra simulador web externo sin modificarlo.

## Etapa 6 — Reporte
- [ ] HTML autocontenido fiel a referencia.
- [ ] Imágenes embebidas.
- [ ] Botón Descargar PDF + render PDF equivalente.
- [ ] Generación offline.

## Etapa 7 — Backend + sync
- [ ] Express/TS/Prisma/PostgreSQL.
- [ ] Auth persistente.
- [ ] Cases/flow-points/samples/evidence/report/sync.
- [ ] Filesystem storage abstraído.
- [ ] Endpoints de consulta para panel futuro.

## Etapa 8 — Integración API hidrantes
- [ ] Inspeccionar API existente.
- [ ] Consumir endpoint real de consulta de cuenta/levantamiento.
- [ ] Adaptador read-only; cero cambios al sistema de hidrantes.

## Etapa 9 — Endurecimiento Android
- [ ] Cierre inesperado/reanudación.
- [ ] Sin red y recuperación.
- [ ] ESP32 desconectado.
- [ ] GPS/cámara/OCR fallidos.
- [ ] Foto corrupta/almacenamiento lleno.
- [ ] Reintentos/duplicados de sync.
- [ ] APK/AAB y pruebas de campo.

## Fuera de alcance inmediato
- iOS.
- Landscape/tablet dedicado.
- Panel web UI.
- Modificaciones a API de hidrantes.
- Simulador web integrado en Flutter. **Esto no excluye LECTURA VISUAL**, que sí es funcionalidad productiva obligatoria.
