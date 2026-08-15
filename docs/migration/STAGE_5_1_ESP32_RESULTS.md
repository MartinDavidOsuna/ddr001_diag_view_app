# Stage 5.1 — Resultados físicos ESP32

## BLE

| Prueba | Baseline | Final | Emitidos | Notificaciones | Reconciliados | Diferencia |
|---|---:|---:|---:|---:|---:|---:|
| A lenta | 0 | 20 | 20 | 20 | 20 | 0 |
| B 100 | 12 | 112 | 100 | 100 | 100 | 0 |

| Reconexión | Contador |
|---|---:|
| Baseline | 0 |
| 5 pulsos conectado | 5 |
| 7 pulsos desconectado | 12 |
| Relectura al reconectar | 12 |
| Delta reconciliado | 7 |
| Total | 12/12 |

Las pruebas usaron hardware y GATT reales mediante Bleak en Windows. Los pulsos se generaron con el comando serie de prueba y el contador firmware fue truth. No se observaron duplicados ni pérdidas.

## LED y Pixel

Pendiente de cableado/encuadre del LED externo GPIO25. No se reportan FPS, missed pulses ni duración mínima sin medición. `LED_ON_MS=120` permanece valor inicial, no validación final.

El APK schema 5 se instaló in-place en Pixel 7 Pro. La app abrió y recuperó una Sample VISUAL RUNNING previa con su sesión/datos; por conservación no se descartó para fabricar una corrida BLE/LED.

## Conclusión

BLE firmware/GATT y reconciliación acumulativa quedan físicamente demostrados. Stage 5 no debe cerrarse hasta ejecutar en Pixel una Sample BLE completa y validar LED 1/5/10/20 más coordinación de Evidence.
