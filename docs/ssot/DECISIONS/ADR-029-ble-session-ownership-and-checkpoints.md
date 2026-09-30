# ADR-029 — Propiedad BLE, orden de lecturas y checkpoints

- Estado: aceptada
- Fecha: 2026-09-25
- Versión: 1.7.6+25
- Complementa ADR-025/026; conserva firmware y protocolo v1/v2.

## Decisión

La fuente reclama el dispositivo antes de conectar y conserva su propiedad
hasta finalizar stop. BUSCAR omite la validación GATT de un dispositivo
reclamado. Si ya había una validación en curso, la fuente espera su limpieza
antes de usar el enlace. No es un segundo mutex GATT: flutter_blue_plus 1.36.8
ya serializa operaciones con su mutex global. Las búsquedas simultáneas
comparten una operación y su listener se cancela en finally.

`onValueReceived` incluye READ y NOTIFY. Es la secuencia canónica; el resultado
asíncrono de read no se aplica de nuevo si ya llegaron valores por ese stream.
Durante preparación se retienen los valores hasta validar la lectura inicial;
READY exige NOTIFY exitoso, lectura válida y reconciliación sin rollback.
Los eventos de pulso se entregan sincrónicamente para encolar todo el delta
antes del checkpoint. AppController serializa también la persistencia del
contador y captura sus errores; una generación de asociación impide que una
Sample anterior sustituya el contexto visual actual.

Un error aislado conserva el enlace físico y recupera GATT. Tres preparaciones
GATT fallidas durante recuperación, aún con enlace conectado, justifican un
disconnect antes del siguiente intento directo. El backoff anterior permanece.
Permiso denegado o adaptador apagado suspenden los intentos; activar Bluetooth
o volver a foreground verifica el estado real. Un enlace READY se sondea sin
reconstruirlo. Una desconexión explícita retira observadores y no se reanuda.
Android anterior a 12 conserva los permisos legacy y ubicación para scan;
Android 12+ usa SCAN/CONNECT. No hay servicio Android nuevo.

Ante error de updateProgress, PulseProgressService relee el resultado: progreso
exactamente confirmado consume la clave una vez; progreso intacto permite
reintentar; resultado distinto o ilegible bloquea esa Sample en memoria.
AppController informa y marca integridad comprometida cuando storage permite,
sin bloquear futuras Samples. Un error posterior al guardado de un pulso no
justifica reproducir ese pulso. No cambia el esquema de persistencia.

## Límites

No se introduce atomicidad nueva entre pulsos y checkpoint ante muerte del
proceso. Si se reconstruye la fuente de una Sample BLE que ya había iniciado,
se marca continuidad no verificable y se bloquea FINAL: el técnico debe repetir
con otra Sample. Se relee su configuración persistida para recuperar el
dispositivo conocido. Esto no aplica a background con la misma fuente viva. Las pruebas deterministas cubren fallos en un proceso vivo; no
certifican radio, Doze ni ejecución permanente. El protocolo sin bootId no
permite detectar todo reinicio ESP32: si el contador reiniciado alcanza el
anterior, la continuidad no puede probarse. El rollback observable sigue
comprometiendo la adquisición, sin inventar ni estimar pulsos.

La preparación de cámara, capturas intermedias y FINAL mantienen sus fronteras.
No se alteran firmware, UUID, payload, fórmulas, MPE, API ni backend.

Si FINAL ya está persistido, reanudar BLE abre la captura de lecturas sin
reconstruir adquisición ni comprometer el endpoint terminado por esa causa.
Las validaciones de evidencia y cierre permanecen vigentes.
