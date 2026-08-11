# ADR-010 — Cámara, visión y trazabilidad de lectura

- Estado: Aceptado
- Fecha: 2026-08-10

## Contexto

LECTURA VISUAL necesita evidencia fotográfica productiva, OCR de odómetro y detección de aguja sin perder la relación auditable entre imagen, propuesta y lectura confirmada.

## Decisión

- Android usa `camera` con cámara trasera y resolución `high`; los archivos permanecen en el sandbox de la aplicación y solo se solicita permiso `CAMERA`.
- OCR se ejecuta on-device con ML Kit. La geometría de aguja se procesa localmente con `image` y un detector Dart desacoplado.
- La misma Evidence START/FINAL importada, hasheada y persistida alimenta el pipeline de visión. Una lectura confirmada conserva su `evidenceId`.
- El resultado automático siempre es una propuesta. El técnico confirma o corrige; una corrección se persiste como `MANUAL`, mientras una propuesta intacta se persiste como `AUTO_CONFIRMED`.
- Fallar OCR o aguja no inventa valores ni invalida una fotografía íntegra: se exige confirmación manual del componente faltante.
- La configuración geométrica (ROI, centro, cero angular, sentido y litros por revolución) está centralizada y es sustituible.
- Drift avanza de schemaVersion 1 a 2 mediante columnas nullable y migración aditiva; no se recrea la base.

## Consecuencias

El checksum de una muestra cerrada cubre las asociaciones de evidencia. Los parámetros por defecto requieren calibración futura por familia de medidor; la confirmación humana sigue siendo obligatoria y limita el riesgo mientras se recopilan fixtures reales.
