# SYNC_SPEC — Offline-first con DDR001 API compartido

## Principio

Drift/SQLite y filesystem local son la persistencia primaria. La captura y el
cierre no dependen de Internet, auth remoto, SQL Server ni confirmación HTTP.

```text
captura -> persistencia local -> validación -> cierre inmutable
        -> cola persistente -> sync -> ACK servidor
```

Nunca se guarda local después del éxito API. Una falla remota conserva visible
y válida toda la información local y sólo cambia el estado de la cola.

## Identidad remota

Se reutiliza Field auth de `ddr001_api` con
`client_app=ddr001_diag_view` e `installation_id` UUID estable. Access/refresh,
work session y rv user ID se guardan de forma segura y separada de otras apps.
Timeout/5xx no limpia sesión local ni datos; 401/403 sólo exige autenticar para
reanudar operaciones remotas.

El user UUID local se conserva como `clientUserId`; ownership servidor se toma
del JWT. Nunca se reescribe una muestra/caso histórico para cambiar su user ID.

## Flujo V1

1. Crear y modificar borradores sólo en Drift.
2. Capturar Evidence al filesystem local y persistir metadata/hash.
3. Validar conjunto obligatorio, adquisición, lecturas y metrología.
4. Cerrar Sample/Case de forma transaccional, congelar checksum/versiones y
   encolar.
5. Con conectividad y sesión remota válida, subir cada archivo por
   `POST /api/v1/functional-diagnostics/evidence`.
6. Guardar localmente ACK, storage key opaca y confirmación. Un ACK
   perdido se recupera reintentando el mismo UUID/hash.
7. Enviar un lote JSON sin binarios a
   `POST /api/v1/functional-diagnostics/sync/push`, incluyendo Meter, Case,
   FlowPoints, Samples, settings, Points, referencias de Evidence y Report
   cuando exista entidad local.
8. El servidor valida owner, parents, hashes y evidencia; enlaza los uploads en
   la transacción del subgrafo Case.
9. Aplicar cada resultado a su SyncItem. Sólo `created`, `exists` o `accepted`
   confirman el ítem. Conflict/rejected permanecen visibles y no cambian el
   dominio cerrado.
10. Recuperar ACK incierto con `GET .../sync/status?receiptId=<batchId>`.

## Idempotencia y receipts

- Evidence: `evidenceId + SHA-256 + metadata`.
- Case/Sample cerrados: UUID + checksum metrológico.
- FlowPoint/Point/Settings/Report: UUID + SHA-256 del payload canónico.
- Batch: `batchId + requestSha256`.

Mismo identificador y misma huella devuelve `exists`/ACK previo. Mismo UUID de
entidad inmutable con otra huella devuelve `conflict`; mismo batch con otro body
devuelve HTTP 409. La cola no marca synced por un HTTP 200 global: inspecciona
el estado individual.

Un rechazo `PAYLOAD_HASH_MISMATCH` ocurre antes de crear receipt. Al actualizar
desde una versión con canonicalización de transporte incompatible, la app puede
recalcular únicamente los `payloadSha256` y la huella del request persistido,
conservando el mismo `batchId`, payload funcional, UUID y checksums metrológicos.
Esta reparación no se aplica a lotes ambiguos, con receipt o en conflicto.

Estados de respuesta por ítem:

`created | exists | accepted | conflict | rejected`

Los rechazos informan `code`, `retryable` y detalles seguros. Se distinguen
evidencia pendiente/no encontrada/hash distinto, parent faltante, owner
incorrecto, validación y versión canónica desconocida.

## Estados locales

`SyncItem`: `pending | inProgress | failed | synced`. Evidence conserva
`local | pending | syncing | synced | conflict | error`. Attempts, lastError y
nextRetryAt son sólo locales. `SyncBatch` persiste el JSON exacto y
`pending | sending | ambiguous | synced | conflict | failed`, además de
`receiptId`, intentos, error y backoff. Un timeout posterior al envío queda
`ambiguous`: el siguiente intento consulta `/sync/status` antes de reenviar.
Ningún estado altera entidades funcionales.

El motor procesa Evidence con concurrencia 1 y Cases secuencialmente. Un Case
con error o conflicto produce su resultado y no detiene los siguientes. Los
reintentos transitorios no hacen polling permanente y conservan el mismo lote.

## Atomicidad y orden

El archivo se recibe antes que la referencia cerrada. El orden de ítems JSON no
es contractual: el servidor ordena Meter -> Case -> FlowPoint -> Sample/Settings
-> Point/Evidence link -> Report. Cada subgrafo Case es atómico; fallar un caso
no revierte otro caso independiente del batch.

Una Sample CLOSED_VALID sólo se acepta si sus Evidence required referenciadas
están VERIFIED y coinciden. Una ausencia remota no cambia CLOSED_VALID local.
INVALID_EVIDENCE puede sincronizarse opcionalmente para diagnóstico mediante su
huella de payload, sin resultado/checksum y sin convertirse después en válida;
la repetición correcta usa otra Sample. DRAFT y RUNNING permanecen sólo locales.

## Conservación e inmutabilidad

No hay purga local automática. Mismo Sample UUID con checksum distinto jamás se
sobrescribe. La corrección crea otra Sample. El servidor no recalcula resultados
ni reabre Cases; reviews administrativas son metadata separada append-only.

## Simulación

SIMULATION sí se sincroniza y conserva escenario, fuente y flag. Lotes,
consultas Field y dashboard pueden filtrarla; las consultas/estadísticas
productivas aplican `isSimulation=false` por defecto. Nunca se disfraza como
medición física. El escenario local `OPERATOR_CONTROLLED` se serializa al
vocabulario remoto existente `PASS|FAIL|INCONCLUSIVE` según el veredicto real,
sin cambiar UUID, checksum metrológico ni contrato de la API.

## Pull

`GET /sync/pull` queda pospuesto. Las consultas `/cases` son vistas remotas
read-only y no fusionan datos dentro de Drift. Un pull futuro requiere ADR para
merge, tombstones, ownership e inmutabilidad.
