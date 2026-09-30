# ADR-028 — Identidad de puntos en transporte

- Estado: aceptada
- Fecha: 2026-09-18
- Versión: 1.7.5+24

El Pixel rechaza items[6..13].payload.pointId y doce ítems más con invalid_string.
Captura usa IDs locales point-<evidenceUUID>; la API exige UUID. No se cambia
el esquema compartido ni se reescriben puntos de muestras cerradas.

UUID locales válidos se envían intactos. Los demás IDs se convierten a UUID v5
con namespace URL 6ba7b811-9dad-11d1-80b4-00c04fd430c8 y nombre JSON compacto
["ddr001.functional.point/v1", sampleId.toLowerCase(), localPointId]. Esta regla
es estable e idempotente. POINT.entityId, POINT.payload.pointId, referencias y
metadata de upload aplican la misma función; evidencia y muestra conservan UUID.

Sólo un lote failed, sin receipt, rechazado explícitamente con VALIDATION_FAILED
puede reparar estos campos. Conserva batchId/itemId, datos, timestamps y
checksums congelados; recalcula payloadSha256/requestSha256. Un 422 de schema
ocurre antes de crear receipt en la API. No se regeneran lotes ambiguos,
sincronizados, con receipt o en conflicto. La reparación previa de huellas
PAYLOAD_HASH_MISMATCH se conserva separada.

Pruebas incluyen MANUAL/BLE, consistencia con evidencia, lote legado persistido,
inmutabilidad local, estabilidad del UUID y bloqueo de reparación ambigua/conflicto.
La aceptación productiva sólo se afirma después del ACK del expediente real.
