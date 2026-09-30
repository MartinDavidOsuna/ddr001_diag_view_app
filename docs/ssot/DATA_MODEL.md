# DATA_MODEL — Modelo canónico

> **Actualización 1.8.0+26 (2026-09-30):** se permite corregir lecturas manuales
> INICIO/FINAL, configuración de cálculo y cuenta/banco de verificaciones finalizadas mediante revisiones
> locales auditadas. Esta excepción sustituye las prohibiciones generales de
> edición de datos manuales cerrados que aparecen más abajo; adquisición,
> pulsos y evidencias conservan su inmutabilidad. La configuración original queda en auditoría.
> Ambas constantes K se configuran en Preparación, con 10 L/pulso iniciales
> para pruebas nuevas; muestras previas conservan su K.
> Historial incorpora sincronización de todas las verificaciones finalizadas
> pendientes del usuario. Toda corrección queda **Pendiente (editada)** hasta que
> la API anuncie soporte explícito de revisiones en `/me/access`. Sin soporte se
> muestra el error de actualizar la API y continúan las demás verificaciones.
> El cliente implementa el contrato opcional documentado; el servidor no se modificó.
> Detalle normativo: [ADR-030](DECISIONS/ADR-030-local-manual-corrections.md).


## Jerarquía
`User → Meter → VerificationCase → FlowPoint → Sample → Point / Evidence`

Drift `schemaVersion = 14` es la implementación local real y la autoridad de
campo. Los JSON Schemas de `packages/shared-contracts/` son contratos
serializables actuales que el futuro serializer de sync deberá ampliar sin
perder compatibilidad. La representación remota oficial vive en SQL Server 2014
bajo `functional_diag`; Prisma/PostgreSQL deja de ser objetivo productivo.

La demo Flutter Web no abre ni replica Drift. Conserva únicamente una lista
JSON versionada de expedientes simulados completos en `localStorage` mediante
SharedPreferences Web. Ese historial es aislado, no sincronizable y puede
borrarse desde su propia UI; no modifica datos Android, API ni SQL.

La versión Web 1.7 amplía de forma aditiva cada muestra con `settings` y
`photos`: tipo, volumen, pulsos, caudal puntual, hora, asset empaquetado y
SHA-256. Los campos anteriores permanecen legibles; fotografías ausentes en
historial antiguo no se inventan. Configuración y fotografías de muestras
cerradas son snapshots inmutables. Las claves separadas
`ddr001_web_demo_draft_v1` y `ddr001_web_demo_settings_v1` conservan borrador y
preferencias; el historial continúa en `ddr001_web_demo_cases_v1`. El borrador
guarda fase, inicio/final, tiempo activo, remanente de pulsos y muestras previas.
El cierre guarda primero el expediente y después elimina el borrador; una
recuperación reconoce un expediente ya cerrado por su ID y no lo duplica.

## User
- `user_id` UUID local. Puede diferir del `rv.users.user_id` remoto; se conserva
  como `client_user_id` en el Case remoto para mantener checksums históricos.
- `email` único normalizado.
- `phone` normalizado.
- `display_name` requerido para nuevos accesos desde Stage 3; permanece nullable en almacenamiento para compatibilidad con usuarios locales legados, que se completan en el siguiente login sin cambiar `user_id`.
- `created_at`, `last_login_at`.
- `remote_user_id` nullable enlaza aditivamente la identidad local con
  `rv.users.user_id`; nunca sustituye ni reescribe el UUID local.
- Sin password.

## Meter
- `meter_id`: ID/número de cuenta capturado; siempre permitido.
- `external_status`: `FOUND_WITH_SURVEY | FOUND_NO_SURVEY | NOT_FOUND | UNKNOWN_OFFLINE`.
- `external_snapshot`: JSON nullable con datos obtenidos de hidrantes, solo copia de referencia.
- No se requiere alta previa en sistema externo.

## VerificationCase (Expediente)
- `case_id` UUID/ULID, PK.
- `meter_id`.
- `user_id`.
- `status`: `OPEN | CLOSED`.
- `overall_verdict`: `APROBADO | RECHAZADO | NO_CONCLUYENTE | null`.
- timestamps de creación/cierre.
- `report_version`.
- `test_bench_id`: identificador obligatorio del banco de pruebas usado.
- metadata nullable de procedencia: `device_id`, `android_version`, `device_brand`, `device_model`; se congela al crear el expediente y no se presenta en HTML/PDF.
- checksum del expediente cerrado.

## FlowPoint (Caudal evaluado)
- `flow_point_id`.
- `case_id`.
- `code`: `Q1 | Q2 | Q3 | Q4`.
- `lps_approx` nullable y legado; verificaciones nuevas no lo solicitan.
- `mpe_pct` congelado (2 para las corridas V1 Q1/Q2 y también para Q3/Q4
  históricos bajo la política vigente; cualquier regla futura requiere ADR).
- `status`: `OPEN | PASS | FAIL | INCONCLUSIVE`.
- estadísticas nullable: n, mean_error, dispersion, sample_stddev, repeatability_pass.

## Sample (Muestra/corrida)
- `sample_id` PK.
- La configuración congelada usa `needle_liters_per_revolution` como escala canónica positiva. `dial_multiplier` es compatibilidad histórica derivada (`litersPerRevolution / 100`), no un catálogo que limite las escalas reales.
- `flow_point_id`.
- `sample_number` secuencial dentro del caudal.
- `status`: `DRAFT | RUNNING | INVALID_EVIDENCE | CLOSED_VALID`.
- `measurement_source`: `VISUAL | MANUAL | LED | BLE | SIMULATION`. `VISUAL` corresponde a **LECTURA VISUAL** productiva sobre un medidor real; `SIMULATION` es una fuente local de QA inequívocamente no física.
- `simulation_scenario`: nullable `SUCCESSFUL | FAILED | FAIL_THEN_PASS | OPERATOR_CONTROLLED`. `OPERATOR_CONTROLLED` es el valor de nuevas simulaciones; los tres valores previos permanecen para leer historial. Es obligatorio únicamente cuando `measurement_source = SIMULATION` y debe ser null para muestras reales.
- timestamps inicio/fin. En métodos de pulsos, el inicio se reemplaza una sola vez con `PulseEvent.receivedAt` del primer pulso aceptado; en LECTURA VISUAL conserva el momento de inicio de la Sample.
- GPS nullable.
- configuración congelada: K, paso, volumen mínimo/máximo operativo, volumen objetivo/orientativo, incertidumbre y parámetros relevantes.
- configuración de arranque congelada: caudal mínimo/máximo del medidor de control y K L/pulso independiente del medidor del hidrante. Se persiste en `sample_operational_settings`; schemaVersion 7 agrega columnas de forma aditiva.
- configuración de adquisición nullable: identidad/UUID/versión BLE, baseline/último contador, ROI/umbrales LED y BLE auxiliar.
- integridad `OK | COMPROMISED`, razón, timestamp y fuente; `COMPROMISED` bloquea `CLOSED_VALID` sin reutilizar `INVALID_EVIDENCE`.
- configuración visual nullable para compatibilidad histórica: región relativa seleccionada manualmente para el totalizador y su formato (`digitCount`, `decimalPlaces`, unidad, ceros iniciales y origen); centro/radio relativo del único dial elegido por el técnico; multiplicador, litros por vuelta, cero, sentido y origen `AUTO_CONFIRMED | MANUAL`. Se confirma antes de analizar START, se recupera durante RUNNING y forma parte de la canonicalización v3 de muestras nuevas; muestras sin formato conservan v1/v2. El correctivo manual-first reutiliza estos campos y no requiere migración.
- Para muestras nuevas de lectura manual al cierre, `initialReading` y `finalReading` conservan totalizador y aguja asociados a sus Evidence. LECTURA VISUAL/MANUAL/LED capturan además el total explícito. BLE/SIMULACIÓN derivan cada endpoint como `odometerUnits × litersPerOdometerUnit + needleLiters` y persisten su diferencia en `indicated_liters`; no dividen nuevamente un valor ya expresado en m³ ni solicitan un total duplicado. Muestras históricas mantienen su cálculo anterior.
- `needleLiters` conserva cualquier valor finito no negativo. BLE y SIMULACIÓN no imponen máximo; la reconstrucción cíclica valida por separado que la posición esté dentro de `litersPerRevolution` cuando ese cálculo aplica.
- `camera_zoom_level` nullable/default 1.0, agregado aditivamente en schema 8 y congelado para todas las capturas de la Sample.
- lecturas inicial/final con origen (`AUTO_CONFIRMED | MANUAL`) y `evidence_id` nullable; en captura visual productiva enlaza la imagen exacta que originó la propuesta confirmada.
- resultado: V_ref, V_ind, E, U, MPE, decision_metric(s), verdict.
- `checksum` al cierre.
- La canonicalización v6 incorpora `simulation_scenario` únicamente para muestras simuladas; checksums históricos conservan su versión previa.
- Una `CLOSED_VALID` es inmutable.

Drift `schemaVersion = 13` agrega de forma aditiva identidad remota, metadata de
ACK de Evidence y lotes persistentes. La migración 12→13 no reconstruye tablas,
no reescribe checksums y no elimina expedientes, Samples RUNNING, Evidence,
usuarios, cola ni archivos.

Drift `schemaVersion = 14` amplía de forma preservadora el CHECK de
`simulation_scenario` para `OPERATOR_CONTROLLED`. No elimina ni reescribe
Samples, Evidence, checksums, queue, usuarios o archivos. El contrato local de
Sample avanza a v10; el payload remoto conserva el contrato implementado por la
API y proyecta el escenario controlado al veredicto real de la Sample.

## Point
- `point_id`.
- `sample_id`.
- `type`: `START | INTERMEDIATE | FINAL | MANUAL_DIAGNOSTIC`.
- `meter_under_test_pulse_count` nullable/default visual 0: snapshot GPIO25 usado exclusivamente como `V.MEC L` en Registro; agregado aditivamente en schema 9.
- `flow_lps` nullable: lectura puntual calculada desde el primer pulso del patrón al capturar INICIO, cada INTERMEDIA y FINAL. Schema 10 la agrega aditivamente; mínimo, máximo y promedio se derivan de los puntos no-null de la muestra.
- pulse_count, V_ref, lectura nullable, V_ind diagnostic nullable, error diagnostic nullable, timestamp.

## Evidence
- `evidence_id`.
- `sample_id`.
- `point_id` nullable.
- `type`: `START | INTERMEDIATE | FINAL | EXTRA`.
- `required` boolean.
- `volume_ref_l`, `pulse_count`, timestamp.
- `sha256`.
- `local_path`.
- `server_storage_key` nullable.
- `sync_status`.
- `server_confirmed_at` y `last_sync_error`, metadata remota mutable que no
  altera la imagen, su hash ni la inmutabilidad metrológica.

## AuthSession (local/server)
Representa la política de sesión persistente; no usar password. El secreto/token nunca forma parte de exportes ni reportes.
La sesión creada por la identidad maestra es local y no fabrica un bearer token de servidor; sus entidades continúan sujetas a la misma persistencia y sincronización que cualquier trabajo offline.

La sesión remota reutiliza `ddr001_api` Field auth con
`client_app=ddr001_diag_view`, `installation_id` UUID estable, access/refresh
tokens, device y work session multi-app. Las credenciales se almacenan con keys
exclusivas de esta app. El owner remoto se deriva del JWT y nunca de un user ID
aceptado desde el body.

## SyncItem
- entity type/id, checksum, state, attempts, last_error, timestamps.

## SyncBatch
- `batch_id` UUID, `case_id`, JSON exacto y SHA-256 canónico del request.
- estado `PENDING | SENDING | AMBIGUOUS | SYNCED | CONFLICT | FAILED`.
- receipt remoto, intentos, último error, timestamps y próximo reintento.
- persiste antes del HTTP para que app restart/reboot conserve la identidad del
  lote y pueda consultar un ACK perdido sin generar duplicados.

## Report
- `report_id`, `case_id`, versión, html_path/local, pdf_path nullable, checksum, created_at.

La app actual genera HTML/PDF en filesystem pero todavía no persiste una tabla
Report en Drift. La representación SQL queda reservada y su sync es opcional
hasta agregar una migración local explícita en otra macroetapa.

## Representación remota oficial

El único backend productivo es `ddr001_api`. SQL Server 2014 agrega el schema
aislado `functional_diag` con:

- `app_users`, única capability funcional ligada por FK a `rv.users`;
- `meters`, `cases`, `flow_points`, `samples`,
  `sample_operational_settings`, `points` y `evidence`;
- `reports` y `sync_receipts`;
- `case_status_history`, `admin_reviews` y `audit_events` append-only.

La única FK desde este dominio hacia otro es a `rv.users(user_id)`. No existen
FK ni joins funcionales con hidrantes, inspecciones, fotos, reportes, auditoría,
cuadrillas o Construction. Los IDs UUID generados en móvil son PK remotas salvo
`Meter.id`, que es el identificador libre capturado.

Case conserva ambos `user_id` remoto (JWT/FK) y `client_user_id` local
(checksum). Sample conserva configuración, lecturas, pulsos, resultado,
integridad, simulación, checksum, canonicalización, algoritmo y contrato sin
recalcularlos. Point/Flow/Settings tienen además una huella canónica de payload
para idempotencia de transporte.

Evidence es propia de `functional_diag`, puede quedar pendiente por
`claimed_sample_id`, y sólo se enlaza después de validar owner, UUID y hashes.
Guarda hashes cliente/servidor, MIME, tamaño, storage key opaca e integridad;
no usa `rv.photos`.

El detalle de columnas SQL, constraints, índices y la matriz campo Drift -> API
-> SQL -> dashboard está congelado en
`ddr001_api/docs/functional-diagnostics-online-contract.md`.

## Inmutabilidad
- `Sample(CLOSED_VALID)` no admite UPDATE funcional de lecturas, pulsos, evidencia ni resultado.
- Las correcciones se modelan como una nueva Sample.
- Un expediente cerrado tampoco se reabre silenciosamente; cualquier política de revisión futura requiere ADR.

## Integración externa hidrantes
Los datos externos existentes se tratan como snapshot informativo local. El
nuevo dominio no consulta ni referencia `rv.hydrants`; una integración futura
read-only requerirá contrato explícito y persistirá sólo snapshot.

## Almacenamiento de imágenes
SQL Server guarda metadata/hash/storage key. Los originales se conservan fuera
de SQL, byte a byte, bajo un namespace físico
`STORAGE_ROOT/functional-diagnostics/`; thumbnails son derivados. El cliente no
elige rutas ni storage keys.

## Identidad remota de puntos (ADR-028)

IDs de Point locales no UUID se adaptan a UUID v5 deterministas únicamente en
transporte (sampleId + pointId, namespace/nombre definidos en ADR-028). Se
conservan IDs locales y checksums de muestras/casos. Metadata y referencias de
Evidence usan la misma identidad remota. Lotes failed por VALIDATION_FAILED,
sin receipt y con IDs legados, reparan esos campos y hashes de transporte con
el mismo batchId/itemId. No se cambian lotes ambiguos, confirmados o en conflicto.
