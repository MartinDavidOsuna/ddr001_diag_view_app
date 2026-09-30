# Contrato requerido para subir correcciones manuales — app 1.8.0+26

**Propuesta implementada en el cliente, pendiente en la API.** No se modificó
el repositorio `ddr001_api`. Se inspeccionaron en lectura su ruta `me/access`,
schema `functional-diagnostics.sync/v1` y contrato local: no anuncian revisiones.
No se usó producción para enviar datos durante esta validación.

## 1. Negociación antes de cada intento

Extender `GET /api/v1/functional-diagnostics/me/access`, conservando sus campos:

```json
{
  "data": {
    "userId": "<UUID del usuario>",
    "accessEnabled": true,
    "policyVersion": 1,
    "capabilities": {
      "manualCorrections": {
        "ready": true,
        "schema": "functional-diagnostics.corrections/v1"
      }
    }
  }
}
```

Anunciar `ready: true` únicamente cuando estén desplegados validación,
persistencia, revisiones/ACK e idempotencia descritos aquí. `policyVersion`,
versionName o un HTTP 200 por sí solos no habilitan el envío. Capability ausente,
false, mal tipada o con schema distinto deja **todas** las verificaciones editadas
locales (incluso las nunca enviadas), sin subir ni evidencias ni payloads. La app
muestra «Hace falta actualizar la API para sincronizar verificaciones modificadas».
Se comprueba nuevamente en cada solicitud, sin cachear una autorización permanente.
Un fallo de red/auth se comunica como tal; no se presenta como API incompatible.

## 2. Envío, sobre el endpoint existente

Extender `POST /api/v1/functional-diagnostics/sync/push` para aceptar
`schema: functional-diagnostics.corrections/v1`. Conservar el contrato v1 normal
para expedientes no editados. El nuevo envelope usa:

- `batchId`, `installationId`, `clientGeneratedAt`: como sync/v1, con nuevo batchId.
- `items`: grafo vigente completo, con los tipos, IDs, payloadSha256 y
  entityChecksum que ya produce el serializer v1. Pulsos y evidencias originales
  no cambian; Points/resultado/configuración de cálculo pueden estar corregidos.
- `baseBatchId`: último batch local conocido, nullable.
- `baseCaseChecksum` y `baseCasePayloadSha256`: huellas del ítem CASE de ese batch,
  nullable cuando no existe. La huella de payload cubre también un CASE abierto.
- `allowCreate`: true si no había un batch confirmado; permite primera publicación
  de una verificación ya editada, pero no sobrescribir un Case ajeno/diferente.
- `corrections`: revisiones locales pendientes, en orden cronológico. Cada una:

```json
{
  "correctionId": "<UUID>",
  "caseId": "<UUID>",
  "sampleId": "<UUID o null si es identificación>",
  "baseCaseChecksum": "<checksum local anterior>",
  "resultCaseChecksum": "<checksum local después>",
  "reportVersion": 2,
  "correctedAt": "<UTC ISO 8601>",
  "reason": "Corrección de un error de captura",
  "manualValues": {
    "meterId": "<cuenta>",
    "testBenchId": "<banco>",
    "initialOdometerUnits": 1,
    "initialNeedleLiters": 0,
    "finalOdometerUnits": 1.2,
    "finalNeedleLiters": 0,
    "litersPerPulse": 10,
    "hydrantLitersPerPulse": 10,
    "readingUncertaintyLiters": 1,
    "litersPerOdometerUnit": 1000,
    "needleLitersPerRevolution": 100,
    "initialTotalLiters": 1000,
    "finalTotalLiters": 1200
  }
}
```

Las claves de lectura/configuración sólo se incluyen si sampleId no es null;
`visualReferenceLiters` sólo para método visual. Los totales pueden ser null
cuando no se capturaron como entradas de la corrección; BLE/SIMULACIÓN usan
endpoints compuestos, no esos totales. No se envían snapshots SQL completos,
rutas de archivos, tokens ni un actor elegido por el cliente: el servidor deriva
actor/owner del JWT.

El servidor debe validar esquema/whitelist, ownership, base remota, cadena de
revisiones, coherencia con el grafo final y los cálculos. Comparar ambas huellas
base contra la revisión vigente; rechazar concurrencia con 409, nunca aplicar
last-write-wins. Si la base anterior nunca se publicó, conservar también la
cadena local como trazabilidad; sus checksums locales intermedios no se confunden
con revisiones que ya existieran en servidor. Aplicar grafo, auditoría y receipt
atómicamente, manteniendo imágenes, pulsos, adquisición y snapshots anteriores.

K corregido cambia Vref con N original; las fotos conservan su volumen de captura
original. El servidor debe distinguir metadata de adquisición de la configuración
corregida: no exigir fotos retroactivas ni reinterpretar evidencia como capturada
con el K corregido. Fórmulas y MPE siguen siendo las vigentes.

## 3. ACK obligatorio e idempotencia

La respuesta `data` y `GET /sync/status?receiptId=` deben conservar los campos e
ítems del ACK actual y agregar:

```json
{
  "appliedCorrectionIds": ["<correctionId aplicado>"],
  "caseChecksum": "<checksum CASE del grafo enviado>"
}
```

La app exige ACK aceptado (`created`, `exists` o `accepted`) por cada itemId,
entityId y entityType enviado, más todos los correctionId del batch y el checksum
final del Case. Un ACK parcial o v1 sin confirmación de revisiones deja el envío
ambiguo/pendiente. Sólo se confirman las revisiones incluidas en ese request;
correcciones posteriores permanecen pendientes.

Repetir batchId+hash idénticos retorna el mismo receipt. Hash diferente para el
mismo batchId o corrección incompatible da conflicto. Tras pérdida de ACK la app
consulta status antes de subir una revisión posterior. Un envío legacy ambiguo
sin ACK se mantiene pendiente para no adivinar qué versión está en el servidor.
No se reciclan requests ni receipts anteriores para confirmar una corrección.

Actualizar vistas, reportes y dashboard para devolver la revisión vigente y
permitir consultar historial. No basta agregar `ready: true` a la respuesta.

## 4. Sincronización global

La app procesa verificaciones finalizadas del usuario de forma secuencial. Un
error de compatibilidad de una editada se muestra en su fila y no impide subir
las no editadas. No se reenvían las ya confirmadas sin cambios. El botón no realiza
solicitudes duplicadas si se pulsa dos veces mientras sigue ocupado.

## 5. Validación pendiente

Se probaron API antigua, capability incompatible, API preparada, ACK incompleto,
pérdida de ACK, revisión posterior y cola mixta con mocks HTTP y SQLite reales.
Falta implementar este contrato en API y validar el intercambio real; no se afirma
que producción admita ni haya recibido correcciones.
