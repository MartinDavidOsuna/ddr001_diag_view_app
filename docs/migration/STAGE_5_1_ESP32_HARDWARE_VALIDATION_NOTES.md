# Stage 5.1 — Integración ESP32-WROOM-32

Fecha: 2026-08-11. Rama: `feature/stage-5-esp32-pulse-sources`.

## Hardware y firmware

COM15 fue confirmado como CH340 y `esptool 5.3.1` identificó `ESP32-D0WD-V3 revision 3.1`, 40 MHz, MAC Wi-Fi `1c:69:20:ea:ea:14`. PlatformIO 6.1.19 compiló y flasheó `firmware/esp32_pulse_bridge` exclusivamente en COM15.

Corrección V1 (2026-08-15): el firmware vigente y el hardware confirmado usan el LED integrado GPIO2, no un LED externo GPIO25. El firmware acepta flanco GPIO27 con pull-up y debounce 40 ms. Cada pulso incrementa un `uint32`, actualiza BLE y enciende GPIO2 durante 120 ms. El comando serie `p` es únicamente inyección explícita de desarrollo.

## BLE v1

- Nombre observado: `DDR001-PULSE-691C`.
- Service: `7b3a0001-6d5f-4f3c-9a21-4d4452303031`.
- Counter read/notify: `7b3a0002-6d5f-4f3c-9a21-4d4452303031`.
- Status read: `7b3a0003-6d5f-4f3c-9a21-4d4452303031`.
- Payload: 5 bytes; versión 1 seguida de contador uint32 little-endian.

Flutter filtra por servicio, permite buscar/seleccionar el dispositivo, lee contador al conectar, establece baseline si no existe y emite la diferencia con el último contador persistido. Un salto recupera pulsos perdidos; duplicado suma cero; rollback no compatible con wrap marca adquisición comprometida.

## Persistencia e integridad

Drift avanza 4→5 con migración aditiva. Persiste identidad/UUID/versión, baseline, último contador, configuración LED e `AcquisitionIntegrity`. Una adquisición `COMPROMISED` se conserva separada de `INVALID_EVIDENCE` y el cierre rechaza `CLOSED_VALID`.

Sample contract avanza v6→v7 y canonical checksum v4 se aplica solo cuando existe configuración de adquisición; muestras históricas conservan canonical previo.

## Cámara LED

`FlutterCameraAdapter` implementa `LedBrightnessPort` sobre ImageStream YUV420. Calcula luminancia únicamente en ROI normalizada y submuestreada. Para interrupciones de cámara, el contador BLE acumulativo es el canal de reconciliación; si la lectura BLE auxiliar falla, debe comprometerse la Sample.

START→INTERMEDIATE→FINAL y Stage 4 permanecen intactos. La instalación Pixel fue in-place y recuperó la Sample VISUAL previa; no se descartó para forzar una prueba BLE.
