# DDR001 ESP32 pulse bridge

Target: ESP32-WROOM-32 / classic ESP32 (`esp32dev`). PlatformIO 6.1.19.

- Pulse input: GPIO 27, `INPUT_PULLUP`, falling edge, 40 ms debounce.
- Integrated board LED validated by Stage 5.2: GPIO 2, active HIGH. This
  assignment is explicit because the generic `esp32dev` board definition does
  not expose an LED pin.
- LED pulse: 120 ms initial validation value (`DDR001_LED_ON_MS`).
- Serial: 115200 baud. Lowercase `p` injects one explicit development pulse; production input remains GPIO 27.
- Advertised name: `DDR001-PULSE-XXXX`, stable suffix from eFuse MAC.

## BLE v1

- Service: `7b3a0001-6d5f-4f3c-9a21-4d4452303031`
- Counter read/notify characteristic: `7b3a0002-6d5f-4f3c-9a21-4d4452303031`
- Status read characteristic: `7b3a0003-6d5f-4f3c-9a21-4d4452303031`
- Counter payload: exactly 5 bytes: byte 0 protocol version `0x01`, bytes 1–4 unsigned 32-bit cumulative counter, little-endian.
- Status payload: UTF-8 `DDR001:PULSE:V1`.

The counter is monotonic from boot and wraps modulo 2^32. Flutter records the counter baseline at Sample start and reconciles forward deltas; no reset is required. Power cycling the ESP32 resets the counter and is detected as rollback during a RUNNING Sample.

## Commands

```powershell
cd firmware/esp32_pulse_bridge
python -m platformio run
python -m platformio run --target upload --upload-port COM15
python -m platformio device monitor --port COM15 --baud 115200
```

Only flash after `python -m esptool --port COM15 chip-id` confirms classic ESP32.
