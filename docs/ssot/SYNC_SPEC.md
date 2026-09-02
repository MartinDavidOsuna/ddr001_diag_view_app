# SYNC_SPEC — Offline-first

## Principio
La app completa funciona sin señal una vez que existe sesión local. SQLite/Drift + filesystem local son la primera persistencia; PostgreSQL es la copia servidor sincronizada.

## Flujo
1. Crear/actualizar borrador local de expediente, congelando banco de pruebas y metadata disponible del teléfono.
2. Ejecutar muestra y guardar puntos/evidencias localmente, incluido `flow_lps` puntual cuando corresponda.
3. Validar que toda evidencia obligatoria exista y sea íntegra.
4. Cerrar muestra, congelar datos y checksum.
5. Encolar evidencias y entidades.
6. Al recuperar red: subir cada evidencia/binario con metadata de enlace pendiente; luego muestra, caudal y expediente. El servidor enlaza atómicamente evidencias previamente preparadas cuando recibe la muestra.
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
La falta de red no bloquea el uso ni el primer login/alta automática local. Nombre, correo y teléfono crean o recuperan la identidad local passwordless; la sincronización remota sólo se habilita cuando el backend está configurado explícitamente.

## Simulación
Las Samples simuladas se conservan y encolan con `is_simulation` y `simulation_scenario` en el payload preparado. Ejecutar la simulación nunca inicia ni requiere sincronización, autenticación remota, Internet o backend. Un consumidor remoto futuro debe conservar la marca no física y no presentarla como verificación de campo.

## API externa de hidrantes
Si no hay red, la identificación puede continuar con cualquier ID y queda `UNKNOWN_OFFLINE`; la consulta se realiza cuando exista conectividad. Nunca bloquea la verificación por no encontrar la cuenta.
