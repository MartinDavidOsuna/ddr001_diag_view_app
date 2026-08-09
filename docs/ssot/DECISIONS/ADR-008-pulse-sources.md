# ADR-008 — Métodos productivos de medición
- **Estado:** aceptada
- **Fecha:** 2026-08-08
- **Decisión:** la app productiva soporta **LECTURA VISUAL**, Manual, LED desde ESP32 y BLE desde ESP32.
- **LECTURA VISUAL:** es una funcionalidad real de campo aplicada sobre medidores reales mediante cámara/visión de la carátula. Es la evolución productiva de la funcionalidad que el prototipo web presenta como simulación; en Flutter debe llamarse **LECTURA VISUAL** y nunca presentarse al técnico como simulador.
- **Manual / LED / BLE:** cada pulso válido equivale a `K` litros y las tres fuentes comparten una interfaz común de eventos de pulso.
- **Simulador web legado:** permanece externo, no se integra y no se modifica. Se utiliza como banco de validación del comportamiento de LECTURA VISUAL y del motor metrológico durante el desarrollo.
- **Consecuencias:** el dominio de una muestra debe aceptar `VISUAL | MANUAL | LED | BLE`. No se debe eliminar la lógica visual por confundirla con el simulador externo, ni generar pulsos ficticios para forzar LECTURA VISUAL dentro de la interfaz de pulsos.
