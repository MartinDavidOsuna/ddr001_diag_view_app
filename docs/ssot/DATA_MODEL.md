# DATA_MODEL — Modelo canónico

## Jerarquía
`User → Meter → VerificationCase → FlowPoint → Sample → Point / Evidence`

Los JSON Schemas de `packages/shared-contracts/` son contratos serializables. Prisma y Drift deben representar el mismo dominio.

## User
- `user_id` UUID.
- `email` único normalizado.
- `phone` normalizado.
- `display_name` requerido para nuevos accesos desde Stage 3; permanece nullable en almacenamiento para compatibilidad con usuarios locales legados, que se completan en el siguiente login sin cambiar `user_id`.
- `created_at`, `last_login_at`.
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
- `mpe_pct` congelado (5 para Q1; 2 para Q2/Q3/Q4 salvo regla normativa futura documentada).
- `status`: `OPEN | PASS | FAIL | INCONCLUSIVE`.
- estadísticas nullable: n, mean_error, dispersion, sample_stddev, repeatability_pass.

## Sample (Muestra/corrida)
- `sample_id` PK.
- `flow_point_id`.
- `sample_number` secuencial dentro del caudal.
- `status`: `DRAFT | RUNNING | INVALID_EVIDENCE | CLOSED_VALID`.
- `measurement_source`: `VISUAL | MANUAL | LED | BLE | SIMULATION`. `VISUAL` corresponde a **LECTURA VISUAL** productiva sobre un medidor real; `SIMULATION` es una fuente local de QA inequívocamente no física.
- `simulation_scenario`: nullable `SUCCESSFUL | FAILED | FAIL_THEN_PASS`. Es obligatorio únicamente cuando `measurement_source = SIMULATION` y debe ser null para muestras reales.
- timestamps inicio/fin. En métodos de pulsos, el inicio se reemplaza una sola vez con `PulseEvent.receivedAt` del primer pulso aceptado; en LECTURA VISUAL conserva el momento de inicio de la Sample.
- GPS nullable.
- configuración congelada: K, paso, volumen mínimo/máximo operativo, volumen objetivo/orientativo, incertidumbre y parámetros relevantes.
- configuración de arranque congelada: caudal mínimo/máximo del medidor de control y K L/pulso independiente del medidor del hidrante. Se persiste en `sample_operational_settings`; schemaVersion 7 agrega columnas de forma aditiva.
- configuración de adquisición nullable: identidad/UUID/versión BLE, baseline/último contador, ROI/umbrales LED y BLE auxiliar.
- integridad `OK | COMPROMISED`, razón, timestamp y fuente; `COMPROMISED` bloquea `CLOSED_VALID` sin reutilizar `INVALID_EVIDENCE`.
- configuración visual nullable para compatibilidad histórica: región relativa seleccionada manualmente para el totalizador y su formato (`digitCount`, `decimalPlaces`, unidad, ceros iniciales y origen); centro/radio relativo del único dial elegido por el técnico; multiplicador, litros por vuelta, cero, sentido y origen `AUTO_CONFIRMED | MANUAL`. Se confirma antes de analizar START, se recupera durante RUNNING y forma parte de la canonicalización v3 de muestras nuevas; muestras sin formato conservan v1/v2. El correctivo manual-first reutiliza estos campos y no requiere migración.
- Para muestras nuevas de lectura manual al cierre, `initialReading` y `finalReading` conservan totalizador y aguja asociados a sus Evidence. El formulario también captura el total del medidor en ambos endpoints y persiste en `indicated_liters` su diferencia `FINAL − INICIO`, que es el `Vind` evaluado. Muestras históricas mantienen su cálculo anterior.
- `camera_zoom_level` nullable/default 1.0, agregado aditivamente en schema 8 y congelado para todas las capturas de la Sample.
- lecturas inicial/final con origen (`AUTO_CONFIRMED | MANUAL`) y `evidence_id` nullable; en captura visual productiva enlaza la imagen exacta que originó la propuesta confirmada.
- resultado: V_ref, V_ind, E, U, MPE, decision_metric(s), verdict.
- `checksum` al cierre.
- La canonicalización v6 incorpora `simulation_scenario` únicamente para muestras simuladas; checksums históricos conservan su versión previa.
- Una `CLOSED_VALID` es inmutable.

Drift `schemaVersion = 12` reconstruye controladamente `samples` desde v11 para ampliar el CHECK de fuente y agregar `simulation_scenario`, copiando todas las columnas existentes. No elimina expedientes, Samples RUNNING, Evidence ni archivos.

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

## AuthSession (local/server)
Representa la política de sesión persistente; no usar password. El secreto/token nunca forma parte de exportes ni reportes.
La sesión creada por la identidad maestra es local y no fabrica un bearer token de servidor; sus entidades continúan sujetas a la misma persistencia y sincronización que cualquier trabajo offline.

## SyncItem
- entity type/id, checksum, state, attempts, last_error, timestamps.

## Report
- `report_id`, `case_id`, versión, html_path/local, pdf_path nullable, checksum, created_at.

## Metadata de despliegue servidor
PostgreSQL conserva registros iniciales no operativos con versiones de esquema, API y sync. No se crean usuarios ni expedientes ficticios; el primer login crea la identidad real.

## Inmutabilidad
- `Sample(CLOSED_VALID)` no admite UPDATE funcional de lecturas, pulsos, evidencia ni resultado.
- Las correcciones se modelan como una nueva Sample.
- Un expediente cerrado tampoco se reabre silenciosamente; cualquier política de revisión futura requiere ADR.

## Integración externa hidrantes
Los datos externos se tratan como snapshot informativo. DDR001 Verificador no escribe sobre la API de hidrantes.

## Almacenamiento de imágenes
PostgreSQL guarda metadata/hash/storage key. Los binarios se guardan inicialmente en filesystem del Windows Server mediante una interfaz de storage desacoplada.
