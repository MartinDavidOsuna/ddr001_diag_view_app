# SYNC_SPEC — Offline-first

## Principio
La app completa funciona sin señal una vez que existe sesión local. SQLite/Drift + filesystem local son la primera persistencia; PostgreSQL es la copia servidor sincronizada.

## Flujo
1. Crear/actualizar borrador local de expediente.
2. Ejecutar muestra y guardar puntos/evidencias localmente.
3. Validar que toda evidencia obligatoria exista y sea íntegra.
4. Cerrar muestra, congelar datos y checksum.
5. Encolar evidencias y entidades.
6. Al recuperar red: subir binarios primero; luego metadata/muestra/caudal/expediente.
7. Confirmación idempotente → `synced`.

## Estados
`local | pending | syncing | synced | conflict | error`.

## Idempotencia
- Muestras/expedientes: ID + checksum.
- Evidencias: SHA-256.
- Reintentos no duplican registros.

## Conflictos e inmutabilidad
Una muestra cerrada con mismo ID y checksum distinto nunca se sobrescribe. Se marca conflicto para diagnóstico. La app no ofrece edición posterior como mecanismo de resolución.

## Conservación local
No existe purga automática en el alcance actual. Borradores, expedientes y fotografías sincronizadas permanecen en el dispositivo hasta que una política futura, documentada por ADR, indique otra cosa.

## Auth offline
Si ya existe sesión local persistente, la falta de red no bloquea el uso. El primer login/alta automática sí requiere conectividad con nuestro backend.

## API externa de hidrantes
Si no hay red, la identificación puede continuar con cualquier ID y queda `UNKNOWN_OFFLINE`; la consulta se realiza cuando exista conectividad. Nunca bloquea la verificación por no encontrar la cuenta.
