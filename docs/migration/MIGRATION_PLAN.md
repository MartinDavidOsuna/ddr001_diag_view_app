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
- [x] Flutter create/configuración mínima Android, sin UI.
- [x] Drift/SQLite y filesystem.
- [x] Entidades User/Meter/Case/FlowPoint/Sample/Point/Evidence/SyncItem.
- [x] Máquina de estados, recuperación, cola sync local e inmutabilidad persistida.

Notas: `STAGE_2_OFFLINE_DOMAIN_NOTES.md`.

## Etapa 3 — UI Flutter
- [x] Replicar identidad y flujo de las capturas sin elementos del navegador ni funciones futuras.
- [x] Login/sesión local, recuperación, identificación, métodos, prueba, registro, cálculo, muestras/expediente, historial y ajustes mínimos.
- [x] Integración UI → repositorios Drift → motor; MANUAL funcional y adaptadores de desarrollo reemplazables para lectura/evidencia.

Notas: `STAGE_3_FLUTTER_UI_NOTES.md`.

## Etapa 4 — Cámara y visión
- [x] Lectura aguja.
- [x] OCR odómetro.
- [x] Confirmación/corrección humana.
- [x] Evidencias obligatorias e integridad.

Notas: `STAGE_4_VISUAL_READING_CAMERA_NOTES.md`.

## Etapa 5 — ESP32
- [x] Interfaz común de pulsos para Manual/BLE/LED y abstracción de adquisición compatible con LECTURA VISUAL.
- [ ] Validación ampliada y calibración por familia de medidor de **LECTURA VISUAL**.
- [x] BLE ESP32 (implementación y fake CI; validación física previa documentada).
- [x] LED ESP32 por cámara (implementación y fake CI; validación física final pendiente).
- [ ] Validación de LECTURA VISUAL y motor contra simulador web externo sin modificarlo.

## Etapa 6 — Reporte
- [x] HTML autocontenido fiel a referencia.
- [x] Imágenes embebidas.
- [x] Botón Descargar PDF + render PDF equivalente.
- [x] Generación offline.

## Etapa 7 — Backend + sync
- [x] Express/TS/Prisma/PostgreSQL.
- [x] Auth persistente.
- [x] Cases/flow-points/samples/evidence/report/sync.
- [x] Filesystem storage abstraído.
- [x] Endpoints de consulta para panel futuro.

## Etapa 8 — Integración API hidrantes
- [x] Inspeccionar API existente.
- [x] Consumir endpoint real de consulta de cuenta/levantamiento.
- [x] Adaptador read-only; cero cambios al sistema de hidrantes.

## Etapa 9 — Endurecimiento Android
- [ ] Cierre inesperado/reanudación.
- [ ] Sin red y recuperación.
- [ ] ESP32 desconectado.
- [ ] GPS/cámara/OCR fallidos.
- [ ] Foto corrupta/almacenamiento lleno.
- [ ] Reintentos/duplicados de sync.
- [ ] APK/AAB y pruebas de campo.

## Correctivo V1 — carátula manual-first, GPS y ayuda offline
- [x] START exige selección táctil de totalizador y un dial antes de analizar.
- [x] OCR/aguja quedan limitados a crops confirmados; aguja no roja se rechaza.
- [x] Geometría/formato/escala START se persisten y recuperan con la misma Evidence.
- [x] GPS Android local maneja permiso, servicio apagado, timeout y error sin depender de red.
- [x] Capabilities remotas no configuradas se ocultan sin borrar cola/adapters.
- [x] Manual canónico offline agregado a Ajustes; todo cambio operativo debe revisarlo.
- [ ] Smoke físico GPS/cámara y recorrido manual-first en Pixel cuando exista dispositivo ADB.

## Etapa 4.2 — Calibración cuantitativa
- [x] Corpus físico de aguja BEFORE/AFTER (21 + 21 imágenes) y métricas reales.
- [x] Corrección demostrada de centro/crop y validación de wrap.
- [x] Corpus OCR controlado y política conservadora sin inventar decimal.
- [ ] OCR automático exacto ≥70%; requiere Stage 4.3 antes de Stage 5.

Resultados: `STAGE_4_2_VISUAL_CALIBRATION_RESULTS.md`.

## Etapa 4.3 — Formato del totalizador
- [x] Separación entre OCR raw, candidatos y formato explícito.
- [x] Freeze/recovery de `TotalizerConfiguration` y cobertura de checksum/contract.
- [x] Propuesta exacta 10/10 sobre corpus controlado con decimal configurado.
- [x] Corrida VISUAL normal y recuperación por force-stop en Pixel.

Resultados: `STAGE_4_3_TOTALIZER_RESULTS.md`.

## Fuera de alcance inmediato

## Etapa 5 — Fuentes ESP32 de pulso
- [x] Pipeline común MANUAL/LED/BLE con persistencia inmediata de N × K.
- [x] Parser/fuente BLE configurable y detector LED con ROI, baseline, histéresis y debounce.
- [x] Política conservadora de coordinación de cámara sin pérdida silenciosa.
- [x] UI/persistencia BLE, adaptador real de frames LED e integridad comprometida persistida.
- [ ] Validación física cuantitativa con hardware ESP32 y coordinación de evidencia.

Estado: correctivo imprescindible antes de cerrar Stage 5; ver `STAGE_5_ESP32_PULSE_SOURCES_NOTES.md`.

### Stage 5.1
- [x] Firmware ESP32 y BLE counter v1 flasheados/validados.
- [x] Descubrimiento UI, baseline/reconciliación, schema 5, integrity y cámara LED real.
- [ ] Validación LED física y corrida completa BLE/LED en Pixel sin descartar la Sample previa.

- iOS.
- Landscape/tablet dedicado.
- Panel web UI.
- Modificaciones a API de hidrantes.
- Simulador web integrado en Flutter. **Esto no excluye LECTURA VISUAL**, que sí es funcionalidad productiva obligatoria.

## Correctivo V1 — dos corridas y preparación de cámara

- [x] Identificación conserva Q1 caudal operativo y Q2 caudal medio con sus LPS.
- [x] BLUETOOTH es el método inicial y LECTURA VISUAL permanece visible, desactivada temporalmente.
- [x] La fotografía de preparación configura regiones y zoom, pero no crea Evidence START.
- [x] Evidence START se captura al iniciar efectivamente la corrida.
- [x] La preparación de cámara solo fija regiones; no ejecuta OCR ni lectura automática.
- [x] START no interrumpe la corrida; al cierre se presentan crops INICIO/FINAL y se capturan manualmente ambos endpoints. Vind es total FINAL menos total INICIO.
- [x] Q1/Q2 admiten repeticiones conservadas como Q1-1, Q1-2, Q2-1, Q2-2 cuando hay más de una corrida.
- [x] Zoom óptico persistente y navegación Atrás dentro del workflow editable.
- [x] Registro portrait compacto en cuatro columnas; V.mec presenta pulsos del medidor del hidrante.
