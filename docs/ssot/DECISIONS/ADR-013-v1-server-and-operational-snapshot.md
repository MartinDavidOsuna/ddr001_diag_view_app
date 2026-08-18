# ADR-013 — Servidor V1 y snapshot de ajustes operativos

- Estado: Aceptada
- Fecha: 2026-08-15

## Contexto

La V1 requiere exportes offline, sincronización PostgreSQL y congelar Vmín/Vmáx usados por cada muestra. Drift schema 5 ya existe en dispositivos y sus muestras cerradas/checksums no deben reescribirse. La evidencia se envía antes que la muestra según `SYNC_SPEC.md`.

## Decisión

1. Drift avanza a schema 6 con una tabla auxiliar aditiva `sample_operational_settings`, enlazada por `sample_id`, para Vmín/Vmáx. La ausencia de fila conserva semántica histórica y no cambia checksums previos.
2. El servidor usa el stack confirmado Node.js, TypeScript strict, Express, Prisma y PostgreSQL. Los binarios se guardan mediante storage de filesystem y PostgreSQL conserva metadata/hash/key.
3. Evidence puede quedar preparada con `pending_sample_id`; al ingerir idempotentemente la Sample, el servidor completa el enlace. Esto permite respetar el orden evidencia → metadata/muestra sin crear una muestra mutable provisional.
4. La base incluye únicamente metadata inicial de versiones. No se insertan usuarios, medidores ni expedientes de demostración.
5. El adaptador de hidrantes consume solo `GET /api/v1/hydrants/:accountNumber` del contrato real inspeccionado y normaliza su respuesta al API Contract DDR001.

## Consecuencias

- Las muestras históricas siguen legibles e inmutables.
- La instalación de PostgreSQL es reproducible mediante migraciones; `db push` no forma parte del despliegue.
- Un fallo de hidrantes se representa como indisponibilidad informativa y nunca impide el procedimiento local.
