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
- checksum del expediente cerrado.

## FlowPoint (Caudal evaluado)
- `flow_point_id`.
- `case_id`.
- `code`: `Q1 | Q2 | Q3 | Q4`.
- `lps_approx` manual nullable.
- `mpe_pct` congelado (5 para Q1; 2 para Q2/Q3/Q4 salvo regla normativa futura documentada).
- `status`: `OPEN | PASS | FAIL | INCONCLUSIVE`.
- estadísticas nullable: n, mean_error, dispersion, sample_stddev, repeatability_pass.

## Sample (Muestra/corrida)
- `sample_id` PK.
- `flow_point_id`.
- `sample_number` secuencial dentro del caudal.
- `status`: `DRAFT | RUNNING | INVALID_EVIDENCE | CLOSED_VALID`.
- `measurement_source`: `VISUAL | MANUAL | LED | BLE`. `VISUAL` corresponde a **LECTURA VISUAL** productiva sobre un medidor real; no significa simulación.
- timestamps inicio/fin.
- GPS nullable.
- configuración congelada: K, paso, volumen objetivo/orientativo, incertidumbre y parámetros relevantes.
- configuración visual nullable para compatibilidad histórica: ROI relativo y formato del totalizador (`digitCount`, `decimalPlaces`, unidad, ceros iniciales y origen); centro/radio relativo del dial; multiplicador, litros por vuelta, cero, sentido y origen `AUTO_CONFIRMED | MANUAL`. Se confirma en START, se recupera durante RUNNING y forma parte de la canonicalización v3 de muestras nuevas; muestras sin formato conservan v1/v2.
- lecturas inicial/final con origen (`AUTO_CONFIRMED | MANUAL`) y `evidence_id` nullable; en captura visual productiva enlaza la imagen exacta que originó la propuesta confirmada.
- resultado: V_ref, V_ind, E, U, MPE, decision_metric(s), verdict.
- `checksum` al cierre.
- Una `CLOSED_VALID` es inmutable.

## Point
- `point_id`.
- `sample_id`.
- `type`: `START | INTERMEDIATE | FINAL | MANUAL_DIAGNOSTIC`.
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

## SyncItem
- entity type/id, checksum, state, attempts, last_error, timestamps.

## Report
- `report_id`, `case_id`, versión, html_path/local, pdf_path nullable, checksum, created_at.

## Inmutabilidad
- `Sample(CLOSED_VALID)` no admite UPDATE funcional de lecturas, pulsos, evidencia ni resultado.
- Las correcciones se modelan como una nueva Sample.
- Un expediente cerrado tampoco se reabre silenciosamente; cualquier política de revisión futura requiere ADR.

## Integración externa hidrantes
Los datos externos se tratan como snapshot informativo. DDR001 Verificador no escribe sobre la API de hidrantes.

## Almacenamiento de imágenes
PostgreSQL guarda metadata/hash/storage key. Los binarios se guardan inicialmente en filesystem del Windows Server mediante una interfaz de storage desacoplada.
