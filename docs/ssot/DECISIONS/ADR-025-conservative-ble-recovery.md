# ADR-025 — Recuperación BLE conservadora desde Flutter

- Estado: aceptada
- Fecha: 2026-09-17
- Amplía exclusivamente recuperación BLE de ADR-012/ADR-015; HID no cambia.

## Decisión

Se conserva BlePulseSource, flutter_blue_plus 1.36.8, conexión directa con
timeout de 12 s y sus valores predeterminados, descubrimiento, UUID y READ +
NOTIFY v1/v2. No se introduce autoConnect, dependencia del scan para recuperar,
servicio Android, cambio de payload ni modificación de firmware. La ruta
directa que funcionaba sigue siendo la única ruta: no hay estrategia nueva
que pueda impedir su fallback.

Un único ciclo recupera el enlace y vuelve a descubrir GATT, suscribir y leer,
incluido si Android aún considera conectado el equipo. Backoff: 1, 2, 4, 8,
15, 30, 30… segundos. Sólo después de una lectura válida reconciliada se
publica READY. Keepalive conserva 10 s y una sola lectura en vuelo.

Las generaciones de transporte/GATT invalidan callbacks tardíos. Stop y dispose
cancelan el temporizador de reintento, retiran listeners y esperan operaciones
en vuelo antes de dar por detenido el transporte. No hay desconexión física
adicional por cambiar pantallas o Sample.

Errores transitorios de transporte se separan de pérdida de integridad. El
reconciliador y el delta uint32 no cambian. Un rollback deja error comprometido
y no se borra automáticamente. Mientras el transporte BLE no está READY no se
admite iniciar ni fijar FINAL: esperar recuperación o repetir, nunca validar
un intervalo todavía no reconciliado. Métodos MANUAL, LED, VISUAL y SIMULACIÓN
no cambian su operación de captura.

## Inicio solicitado

Android abre Inicio con sesión válida, incluso si existe prueba incompleta.
La carga del contexto persistido no se elimina y Inicio ofrece reanudarla
explícitamente. No modifica autenticación, datos ni resultados.

## Límites y validación

- Reinicio ESP32: sin bootId/sessionId/uptime no puede demostrarse toda
  continuidad. Un retroceso fuera de la ventana wrap existente se rechaza;
  tampoco puede detectarse un reboot que alcance/supere el contador previo.
  Es una **LIMITACIÓN RESIDUAL DEL PROTOCOLO/FIRMWARE ACTUAL**.
- Background, pantalla apagada y terminación de proceso dependen de Android.
  No se promete ejecución permanente ni se introduce foreground service.
  Navegación/cámara no destruyen GATT; la cámara conserva su propio lifecycle.
- Dobles de las APIs de la versión instalada prueban errores y carreras.
  No sustituyen validación RF con los ESP32 reales, distintas versiones de
  Android, pantalla apagada, cámara y regreso a foreground.
- El APK se entrega por ADB en Download, sin instalarlo. Por ello no se afirma
  una certificación física del binario nuevo en el Pixel.
