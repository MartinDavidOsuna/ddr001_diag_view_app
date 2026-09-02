# API_CONTRACT — DDR001 Verificador Funcional online/offline-first

> Estado: contrato de diseño congelado en Macroetapa 1. El backend productivo es
> `ddr001_api` sobre SQL Server 2014. `backend/` en este repositorio es referencia
> histórica Prisma/PostgreSQL y no se despliega.

La persistencia primaria de campo continúa siendo Drift + filesystem local. El
API recibe únicamente trabajo ya persistido y validado localmente; no forma
parte del camino crítico de captura.

La especificación exhaustiva de tablas, payloads, respuestas, seguridad y
trazabilidad vive en
`ddr001_api/docs/functional-diagnostics-online-contract.md`. Este SSOT fija el
contrato que deberá consumir Flutter.

## 1. Auth compartido

No se implementa un segundo login. Se adopta el auth Field real de `ddr001_api`:

- `POST /api/v1/field-sessions/start`;
- `POST /api/v1/field-sessions/refresh`;
- `GET /api/v1/field-sessions/current`;
- `POST /api/v1/field-sessions/:id/end`.

La app enviará `client_app=ddr001_diag_view` y un `installation_id` UUID estable
de instalación. Este identificador cumple el contrato multi-app actual. El API
deberá admitir inicio de sesión sin cuadrilla para este `client_app`; no se usará
`rv.crews` como catálogo ni como dependencia del diagnóstico funcional.

Flutter deberá migrar `RemoteApiClient` desde `/api/v1/auth/login` y token único
a access/refresh tokens Field, almacenar credenciales con keys exclusivas de
esta app, refrescar sin destruir trabajo offline ante fallas de red y terminar
solamente su propia sesión al hacer logout explícito. El teléfono se normaliza
al contrato DDR001 de diez dígitos antes del login remoto.

El UUID de `User` local puede diferir de `rv.users.user_id`. El body conserva el
UUID local como `clientUserId`, pero el owner remoto siempre se deriva del JWT;
el cliente nunca elige el `userId` servidor.

Al iniciar una sesión para este cliente, el API provisiona idempotentemente la
capability `functional_diag.app_users`; `GET /me/access` sólo la consulta y no
produce efectos laterales.

## 2. Namespace Field

Todos requieren JWT Field, sesión abierta con
`client_app=ddr001_diag_view`, acceso en `functional_diag.app_users` y ownership:

- `GET /api/v1/functional-diagnostics/me/access`;
- `POST /api/v1/functional-diagnostics/evidence`;
- `POST /api/v1/functional-diagnostics/sync/push`;
- `GET /api/v1/functional-diagnostics/sync/status`;
- `GET /api/v1/functional-diagnostics/cases`;
- `GET /api/v1/functional-diagnostics/cases/:caseId`.

`GET /sync/pull` se pospone. V1 no necesita reconciliar edición servidor hacia
Drift: la app conserva autoridad local y usa las consultas como vistas remotas
read-only.

## 3. Evidencia

`POST /evidence` es multipart (`file` + metadata JSON) y acepta el UUID local,
Sample/Point reclamados, tipo, required, Vref, pulsos, captura, SHA-256 y tamaño.
El original se conserva byte a byte fuera de SQL bajo el namespace físico
`functional-diagnostics`; el servidor calcula un segundo SHA-256, detecta MIME
por contenido, genera la storage key y puede crear un thumbnail derivado.

Una Evidence puede cargarse antes de existir su Sample remota. Queda STORED con
`claimed_sample_id` y owner JWT. `sync/push` la enlaza sólo si UUID, hash, owner y
relaciones coinciden. Mismo UUID+hash+metadata es `exists`; UUID con hash o
metadata distinta es `409 EVIDENCE_CONFLICT`. Ni `local_path` ni un filename del
cliente llegan a ser rutas servidor.

## 4. Sync batch

Contrato: `functional-diagnostics.sync/v1`. Un request contiene `batchId`,
`installationId`, timestamp e ítems de tipo `METER`, `CASE`, `FLOW_POINT`,
`SAMPLE`, `OPERATIONAL_SETTINGS`, `POINT`, `EVIDENCE_REF` y `REPORT`. No contiene
binarios. El servidor ordena dependencias y procesa cada subgrafo de Case de
forma atómica.

Cada ítem tiene `itemId`, `entityId`, `parentId`, checksum metrológico cuando
aplica, SHA-256 del payload canónico y payload. La respuesta por ítem distingue:

`created | exists | accepted | conflict | rejected`

y códigos estables, al menos:

`CHECKSUM_CONFLICT | VALIDATION_FAILED | EVIDENCE_PENDING |
EVIDENCE_NOT_FOUND | EVIDENCE_HASH_MISMATCH | OWNER_MISMATCH |
PARENT_MISSING | CANONICAL_VERSION_UNSUPPORTED`.

`CASE` y `SAMPLE` cerrados usan UUID+checksum: igual es idempotente, distinto es
conflicto. Point/Flow/Report usan `payloadSha256` para identidad exacta de
transporte sin inventar un checksum metrológico. Un archivo pendiente impide
aceptar la Sample como cerrada, pero no altera su validez local.

`functional_diag.sync_receipts` persiste `batchId`, owner, instalación, hash del
request y ACK. Repetir batch+hash devuelve el ACK; batch con hash distinto da
409. `GET /sync/status?receiptId=` recupera ACK perdido.

## 5. Shapes y representación remota

El payload representa todos los campos persistidos relevantes de User/Meter,
Case, FlowPoint, Sample, configuración operacional/visual/adquisición, Point y
Evidence. Las únicas exclusiones deliberadas son:

- `Evidence.localPath`;
- estado, intentos, último error y backoff de `SyncItem`;
- timestamps puramente locales de sesión;
- rutas HTML/PDF actuales mientras Report no sea una entidad Drift.

La configuración y resultado congelados incluyen versiones de contrato,
canonicalización y algoritmo. Las Samples simuladas envían simultáneamente
`measurementSource=SIMULATION`, `isSimulation=true` y escenario; las reales
exigen `isSimulation=false` y escenario null.

## 6. Consultas Field

`GET /cases` sólo devuelve casos del JWT, con cursor keyset y filtros validados
por estado, veredicto, meter, fecha, fuente, simulación (false por defecto),
banco, integridad y Q. `GET /cases/:caseId` devuelve el grafo completo y 404
también para IDs ajenos, evitando IDOR. Ninguna ruta Field modifica una muestra
cerrada.

## 7. Namespace administrativo

El dashboard consumirá exclusivamente:

- `GET /api/v1/admin/dashboard/functional-diagnostics/summary`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/cases`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/cases/:caseId`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/cases/:caseId/evidence/:evidenceId/thumbnail`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/cases/:caseId/evidence/:evidenceId/content`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/metrics`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/trends`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/users`;
- `GET|PUT /api/v1/admin/dashboard/functional-diagnostics/users/:userId/access`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/users/:userId/access-history`;
- `GET|POST /api/v1/admin/dashboard/functional-diagnostics/cases/:caseId/reviews`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/reports`;
- `GET /api/v1/admin/dashboard/functional-diagnostics/cases/:caseId/report`.

Admin puede leer, cambiar acceso y revisar; supervisor puede leer/revisar;
viewer sólo lectura y thumbnails, no originales. Toda mutación administrativa
queda en `functional_diag.audit_events`. Una review es append-only y jamás
cambia cálculo, configuración, evidencia, checksum o veredicto de campo.

## 8. Errores y seguridad

Errores:

```json
{
  "error": {
    "code": "STABLE_CODE",
    "message": "Mensaje seguro",
    "details": {},
    "requestId": "uuid"
  }
}
```

Se exigen validación strict, ownership por JWT, límites de payload/items/archivo,
rate limits por ruta, MIME real, SHA-256, storage keys opacas, prevención de
traversal, queries parametrizadas, sort whitelist, paginación, sesiones
multi-app aisladas y filtro productivo `isSimulation=false` por defecto.
