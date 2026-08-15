# ADR-012 — Integridad local de fuentes de pulso

Estado: aceptada y ampliada por Stage 5.1 (2026-08-11).

## Contexto

MANUAL, LED y BLE producen pulsos, pero únicamente el dominio puede convertirlos en `pulseCount` y `Vref = pulseCount × K`. BLE puede desconectarse y la cámara Android no puede asumirse compartible entre detección LED continua y fotografía de evidencia.

## Decisión

- Las tres fuentes emiten `PulseEvent` hacia `PulseProgressService`, que serializa, deduplica cuando existe una clave local/sequence real, incrementa y persiste inmediatamente.
- El protocolo BLE Stage 5 es mínimo y configurable: UUID de servicio/característica suministrados por el firmware; payload válido `0x01` o texto `PULSE`. No se inventa contador.
- Una desconexión BLE compromete el intervalo no observado cuando el firmware no reporta contador acumulado.
- La detección LED usa ROI relativa, baseline, histéresis y flanco ascendente. La captura de evidencia mientras LED ocupa la cámara se rechaza si no existe reconciliación; nunca se pausa silenciosamente.
- `INVALID_EVIDENCE` y adquisición comprometida siguen siendo conceptos distintos. Hasta persistir el segundo en el modelo y cierre, LED no se aprueba para cierre productivo.

## Consecuencias

BLE y LED comparten metrología sin duplicar fórmulas. La semántica es exactly-once local dentro de la vida del pipeline cuando hay `sequence`; sin contador firmware no puede garantizarse recuperación durante desconexión o proceso detenido. LED requiere una solución física validada antes de cerrarse como productivo.

## Ampliación Stage 5.1

El firmware publica contador BLE v1 (`uint32` little-endian) legible/notificable. La Sample congela baseline y último contador; reconexión incorpora el delta. Rollback o imposibilidad de leer persisten `COMPROMISED` y bloquean `CLOSED_VALID`. En LED, BLE puede ser canal auxiliar sin cambiar `measurementMethod=LED`.
