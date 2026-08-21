# ADR-015 — Acceso maestro local y keepalive de periféricos

- **Estado:** aceptada
- **Fecha:** 2026-08-20

## Contexto

La operación de campo necesita un acceso de contingencia explícito sin disponibilidad del backend. El ESP32 GATT y el obturador Bluetooth tampoco deben aparecer desconectados por inactividad mientras continúen presentes.

## Decisión

- Cada combinación exacta normalizada de nombre, correo y teléfono documentada en SSOT para Martin Osuna, Rene y Omar crea una identidad y sesión locales sin invocar la API. No se genera token remoto y cualquier otra combinación conserva el proveedor normal de autenticación.
- El ESP32 se mantiene activo leyendo periódicamente su contador GATT. Un fallo inicia hasta tres recuperaciones; solo después se publica `disconnected`. Al recuperar, el contador acumulativo reconcilia el delta.
- El control remoto Bluetooth HID se verifica mediante `InputManager`, porque Android administra su enlace y lo expone como dispositivo de entrada. Se requieren tres sondeos negativos antes de retirar su presencia.
- El intervalo inicial de keepalive es 10 s; los reintentos usan espera corta de 1–2 s.
- El transporte BLE vive por encima de pantallas y Samples. Las suscripciones metrológicas se desasocian y reasocian cuando cambia la Sample, pero la conexión GATT persiste al navegar, fijar regiones y comenzar otra verificación. El scan manual verifica anuncios y contrato GATT sin forzar la desconexión del módulo activo. `DESCONECTAR ESP32` es la única acción explícita que destruye el transporte durante la vida de la app.
- Como advertising puede detenerse durante una conexión, el listado combina el scan con el módulo que la fuente activa ya validó por GATT. Un keepalive con el mismo contador confirma presencia, pero no vuelve a emitir progreso ni estado Flutter.

## Consecuencias

- La llave maestra es una excepción local auditable, no una credencial de servidor.
- Una desconexión transitoria no cambia inmediatamente la UI ni desarma el control.
- Un intervalo BLE recuperado sigue sujeto a reconciliación e integridad del contador acumulativo.
