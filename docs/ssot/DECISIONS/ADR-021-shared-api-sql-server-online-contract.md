# ADR-021 — Backend compartido y contrato online aislado

- **Estado:** aceptada
- **Fecha:** 2026-09-02

## Contexto

El monorepo conserva un backend histórico Express/Prisma/PostgreSQL que sirvió
para explorar contratos de sincronización. La plataforma DDR001 ya dispone de
un API oficial con SQL Server 2014, auth Field/Admin y sesiones multi-app. Crear
o desplegar otro backend duplicaría identidad, seguridad y operación.

La app debe sincronizar sin degradar su operación offline-first ni acoplar el
diagnóstico funcional a RV, Construction u otras aplicaciones.

## Decisión

- El único backend productivo será el repositorio `ddr001_api`; el directorio
  local `backend/` queda como referencia histórica no desplegable y no se borra.
- La base productiva será SQL Server 2014. El dominio vivirá en el schema
  `functional_diag` y su única FK compartida será a `rv.users(user_id)`.
- No habrá FK, joins de negocio ni catálogos provenientes de `rv.hydrants`,
  inspecciones, fotos, reportes, auditoría, crews, Construction u otros dominios.
- Se reutilizarán auth, device/work session, refresh, middleware, storage y
  seguridad transversales del API con `client_app=ddr001_diag_view` e
  `installation_id` estable. La sesión de este cliente no requiere cuadrilla.
- Drift/SQLite y filesystem local permanecen como autoridad de captura. El sync
  ocurre sólo después del cierre/checksum y usa uploads de Evidence separados de
  lotes JSON idempotentes.
- El servidor conserva cálculos y versiones congelados; no recalcula ni permite
  editar silenciosamente una Sample cerrada. Reviews administrativas son
  append-only y separadas.
- La especificación exhaustiva queda en
  `ddr001_api/docs/functional-diagnostics-online-contract.md` y los SSOT
  `API_CONTRACT.md`, `SYNC_SPEC.md` y `DATA_MODEL.md`.

Esta ADR sustituye únicamente las decisiones de backend productivo y base de
datos de ADR-001, ADR-007 y ADR-013. Sus decisiones locales, metrológicas y de
filesystem desacoplado continúan vigentes.

## Consecuencias

- Las siguientes etapas deben crear migraciones/rutas dentro de `ddr001_api`, no
  dentro del backend Prisma histórico.
- Flutter deberá adoptar tokens Field access/refresh y un serializer batch, sin
  mover lógica metrológica fuera de la app.
- Las simulaciones se almacenan, pero se excluyen por defecto de consultas y
  estadísticas productivas.
- `sync/pull` y subida remota de HTML/PDF quedan pospuestos sin bloquear V1.
