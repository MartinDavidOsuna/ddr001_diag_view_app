# SYNC_SPEC — Offline-first con DDR001 API compartido

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


## Principio

Drift/SQLite y filesystem local son la persistencia primaria. La captura y el
cierre no dependen de Internet, auth remoto, SQL Server ni confirmación HTTP.

```text
captura -> persistencia local -> validación -> cierre inmutable
        -> cola persistente -> sync -> ACK servidor
```

Nunca se guarda local después del éxito API. Una falla remota conserva visible
y válida toda la información local y sólo cambia el estado de la cola.

La demo Flutter Web autónoma no participa en esta cola ni simula ACKs: no tiene
sync, tokens, API ni SQL. Sus expedientes de presentación son sólo locales al
navegador y se identifican permanentemente como simulados.

## Identidad remota

Se reutiliza Field auth de `ddr001_api` con
`client_app=ddr001_diag_view` e `installation_id` UUID estable. Access/refresh,
work session y rv user ID se guardan de forma segura y separada de otras apps.
Timeout/5xx no limpia sesión local ni datos; 401/403 sólo exige autenticar para
reanudar operaciones remotas.

El user UUID local se conserva como `clientUserId`; ownership servidor se toma
del JWT. Nunca se reescribe una muestra/caso histórico para cambiar su user ID.

## Activación productiva y sesiones locales previas

El APK productivo se compila con `--dart-define-from-file=config/production.json`
desde `app/`; el archivo contiene sólo la URL pública del backend. No contiene
credenciales. Android permite HTTP únicamente para `cifra.aquafim.com`, mientras
el despliegue actual publica el servicio en ese transporte.

La acción **SINCRONIZAR** del resumen autentica la identidad local vigente si
carece de credenciales remotas, incluidas las identidades maestras. Relee su
vínculo remoto persistido antes de reutilizar tokens. Ante 401 agotado el refresh
puede iniciar otra sesión con la misma identidad local; 403 y errores de red
permanecen visibles. Restaurar la app sigue siendo enteramente local. Logout
revoca la sesión Field también para maestros. UUID y datos históricos no cambian.

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

## Diagnóstico de errores remotos (1.7.3+22)

Los errores HTTP conservan la operación ejecutada, estado, mensaje de los dos
contratos (Field problem+json o functional `error`) y request ID UUID válido.
La UI de sincronización muestra esos datos y el motor los conserva en los
estados de error que ya persiste. Un fallo de renovación identifica esa
operación, no la petición que originó el refresh. HTML y cuerpos inesperados
no se muestran crudos; un 5xx conserva su categoría transitoria. No se registran
tokens, cuerpos enviados ni imágenes para esta instrumentación.

Los errores de validación (1.7.4+23) muestran hasta ocho rutas de campos y
códigos recibidos en `error.details.issues` o `errors`. Se omiten valores
rechazados y cuerpos crudos. El lote rechazado se conserva sin reinterpretar
muestras cerradas ni eludir validaciones del servidor.

## Identidad remota de puntos (ADR-028)

IDs de Point locales no UUID se adaptan a UUID v5 deterministas únicamente en
transporte (sampleId + pointId, namespace/nombre definidos en ADR-028). Se
conservan IDs locales y checksums de muestras/casos. Metadata y referencias de
Evidence usan la misma identidad remota. Lotes failed por VALIDATION_FAILED,
sin receipt y con IDs legados, reparan esos campos y hashes de transporte con
el mismo batchId/itemId. No se cambian lotes ambiguos, confirmados o en conflicto.
