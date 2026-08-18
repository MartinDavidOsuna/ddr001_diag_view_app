# Capabilities dependientes de servidor

Estado al 2026-08-16. La app es local-first y ninguna capability descrita aquí bloquea una prueba.

| Capability | Presentación sin configuración | Requisito para reactivar | Implementación preparada |
|---|---|---|---|
| Login/alta remota y sync DDR001 | Botones/estado remoto ocultos; sesión existente y cola local se conservan | Compilar con `--dart-define=DDR001_API_BASE_URL=https://servidor` y backend accesible | `RemoteApiClient`, `ServerBackedAuthService`, `SyncQueueRepository`, `AppController.syncCurrentCase` |
| Consulta de cuenta/hidrantes | No se muestra `Pendiente de consulta`; el ID sigue libre | Backend DDR001 configurado y, en servidor, `HYDRANTS_API_BASE_URL` + `HYDRANTS_API_TOKEN` reales | `RemoteApiClient.lookupMeter` y proxy read-only del backend |

El backend usa además `DATABASE_URL`, `JWT_SECRET`, `PORT` y `EVIDENCE_STORAGE_PATH`, documentados en `backend/.env.example`. No se incluyen secretos reales.

## Criterio de reactivación

La UI aparece solamente cuando `AppDependencies` expone la capability configurada. Deben validarse autenticación real, consulta localizada/sin levantamiento/no localizada/error, upload de Evidence, reintento idempotente y conflicto contra PostgreSQL productivo. Ocultar la UI no elimina adapters, contratos, tablas, cola, metadata ni pruebas automatizadas.
