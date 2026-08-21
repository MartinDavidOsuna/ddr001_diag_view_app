# DDR001 ESP32 pulse bridge

Target: ESP32-WROOM-32 / classic ESP32 (`esp32dev`). PlatformIO 6.1.19.

- Control flowmeter (calibrated pattern): GPIO 27, `INPUT_PULLUP`, falling edge, filtro PCNT de hardware, nivel LOW estable mínimo 17 ms, rearme HIGH estable 2 ms y debounce 40 ms. Este contador es el único usado para Vref e integridad.
- Meter under test: GPIO 25 con el mismo filtrado PCNT + estabilidad + rearme. Es opcional y diagnóstico; una entrada sin medidor debe permanecer en cero.
- Integrated board LED validated by Stage 5.2: GPIO 2, active HIGH. This
  assignment is explicit because the generic `esp32dev` board definition does
  not expose an LED pin.
- LED pulse: 120 ms initial validation value (`DDR001_LED_ON_MS`).
- Serial: 115200 baud. Lowercase `p` injects one explicit development pulse; production input remains GPIO 27.
- Nombre anunciado: `DDR001-PULSE-<SERIE>-V<VERSIÓN>`, configurado obligatoriamente antes de flashear. Ejemplo de comando: `--nombre ESP32-NS1001-V1.0` anuncia `DDR001-PULSE-NS1001-V1.0`, conservando compatibilidad con el filtro de la app.

## BLE v1

- Service: `7b3a0001-6d5f-4f3c-9a21-4d4452303031`
- Counter read/notify characteristic: `7b3a0002-6d5f-4f3c-9a21-4d4452303031`
- Status read characteristic: `7b3a0003-6d5f-4f3c-9a21-4d4452303031`
- Protocol v2 payload: exactly 9 bytes: version `0x02`, bytes 1–4 GPIO27 control counter and bytes 5–8 GPIO25 tested-meter counter, both uint32 little-endian. Flutter remains able to read the legacy v1 five-byte control-only payload.
- Status payload: UTF-8 `DDR001:DUAL:V2:<NOMBRE_BLE>`.

The counter is monotonic from boot and wraps modulo 2^32. Flutter records the counter baseline at Sample start and reconciles forward deltas; no reset is required. Power cycling the ESP32 resets the counter and is detected as rollback during a RUNNING Sample.

## Commands

```powershell
cd firmware/esp32_pulse_bridge
python configure.py --nombre ESP32-NS1001-V1.0 --solo-compilar
python configure.py --nombre ESP32-NS1001-V1.0 --puerto COM15
python -m platformio device monitor --port COM15 --baud 115200
```

El configurador rechaza nombres sin número de serie/versión y evita exceder el tamaño BLE. El nombre solicitado se normaliza al prefijo productivo `DDR001-PULSE-` que la app valida.

## Filtrado de entradas

PCNT elimina glitches de hasta 1023 ciclos APB (aprox. 12.8 µs a 80 MHz). Después, el software exige LOW continuo durante al menos 17 ms, acepta como máximo un pulso cada 40 ms y no rearma hasta observar HIGH continuo durante 2 ms. Así una transición espuria, un pulso demasiado corto o un rebote no se convierte directamente en contador/notificación BLE.

Only flash after `python -m esptool --port COM15 chip-id` confirms classic ESP32.
