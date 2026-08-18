# API_CONTRACT — REST `/api/v1`

Auth mediante bearer token/sesión persistente. Bodies validados en el borde. La API debe soportar tanto sincronización móvil como consultas de un panel futuro.

## 1. Auth passwordless
### `POST /auth/login`
Body:
```json
{ "email": "usuario@dominio.mx", "phone": "+52..." }
```
Comportamiento:
- normaliza email/teléfono;
- busca usuario;
- si no existe, lo crea automáticamente;
- devuelve perfil y sesión/token persistente.

Response 200/201:
```json
{ "token": "...", "user": { "user_id": "...", "email": "...", "phone": "...", "display_name": null } }
```

### `POST /auth/logout`
Revoca la sesión actual explícitamente.

### `GET /auth/me`
Devuelve perfil de la sesión.

## 2. Consulta de padrón externo
### `GET /external/hydrants/accounts/:meterId`
Endpoint **de nuestro backend/adaptador**, no del sistema legado. Internamente consume la ruta real existente de la API de hidrantes en modo solo lectura.

Response normalizada:
```json
{ "status": "FOUND_WITH_SURVEY|FOUND_NO_SURVEY|NOT_FOUND", "data": {} }
```

La implementación debe inspeccionar la API de hidrantes y mapear su endpoint/payload real; no se permite modificarla ni inventar contratos externos.

Contrato externo inspeccionado el 2026-08-15 en `ddr001_api_rv`: `GET /api/v1/hydrants/:accountNumber`, con Bearer de campo; `404` significa no localizado. `officialInspectionId` o `latestInspectionId` indican levantamiento disponible. El adaptador se configura mediante base URL y token separados, solo ejecuta GET y no reexpone la credencial.

## 3. Expedientes
- `POST /cases` crea/ingesta expediente idempotente.
- `GET /cases/:id` devuelve expediente completo o vista expandible.
- `GET /cases?meter_id=&user_id=&status=&verdict=&from=&to=&limit=&cursor=` lista para app/panel.
- `POST /cases/:id/close` registra cierre y veredicto calculado; nunca recalcula con reglas distintas sin versionar.

## 4. Caudales
- `POST /cases/:caseId/flow-points` agrega Q1/Q2/Q3/Q4.
- `GET /cases/:caseId/flow-points`.
- `GET /flow-points/:id` incluye estadísticas y muestras.

## 5. Muestras
- `POST /samples` ingesta idempotente de muestra cerrada.
- `GET /samples/:id`.
- `GET /samples?case_id=&flow_point=&meter_id=&from=&to=&limit=&cursor=`.

Idempotencia: mismo `sample_id + checksum` → `exists`; mismo ID con checksum distinto → `409 CONFLICT`. Una muestra cerrada existente **no se sobrescribe**.

## 6. Evidencias
- `POST /evidence` multipart + metadata + SHA-256. Idempotente por hash/storage key.
- `GET /evidence/:id` o endpoint firmado/controlado para binario.
- El backend inicial almacena binarios en filesystem administrado, no en PostgreSQL.

## 7. Reportes
- `POST /cases/:id/reports` registra metadata de un reporte generado/subido si aplica.
- `GET /cases/:id/report` entrega/ubica la última versión disponible.
- La generación local HTML/PDF no depende de este endpoint.

## 8. Sync
### `POST /sync/push`
Acepta lote de entidades serializadas y responde estado por ítem. Debe ser seguro ante reintentos.

### `GET /sync/pull?since=`
Cambios disponibles para conciliación/consulta futura.

## 9. Consultas para panel futuro
La API deberá permitir al menos:
- usuarios;
- medidores/cuentas;
- expedientes por fecha/estado/veredicto;
- detalle de Q1-Q4;
- muestras y estadísticas;
- evidencias;
- estado de sincronización/auditoría.

No se construye UI web del panel en el alcance inmediato.

## 10. Errores
```json
{ "error": { "code": "VALIDATION|AUTH|CONFLICT|NOT_FOUND|EXTERNAL_API|STORAGE|SERVER", "message": "...", "details": {} } }
```
