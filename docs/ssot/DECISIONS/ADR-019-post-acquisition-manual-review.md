# ADR-019 — Captura manual posterior a adquisición

- **Estado:** aceptada
- **Fecha:** 2026-08-21

## Contexto

Después de congelar y fotografiar FINAL, el técnico puede tardar varios minutos capturando las lecturas manuales. La pantalla conservaba suscripciones de estado BLE y enlazaba lecturas mediante propuestas visuales transitorias. Un callback tardío podía sustituir el mensaje de la pantalla, exigir una captura ya terminada o perder el vínculo con START/FINAL.

## Decisión

- La fase `readings` comienza únicamente después de persistir FINAL y queda fuera de adquisición.
- Se cancelan todas las suscripciones de la Sample, incluida la de estado BLE; el transporte y su keepalive permanecen vivos e independientes.
- El cierre vuelve a leer Sample y evidencias desde persistencia y enlaza las lecturas mediante los IDs START y FINAL guardados.
- Un callback de cámara sin propósito cuando la app ya está en `readings` o `result` se trata como repetición idempotente y se ignora.

## Consecuencias

- El tiempo dedicado al formulario no cambia endpoint, integridad ni resultados.
- La pérdida o recuperación de conectividad posterior a FINAL no bloquea el cálculo.
- No cambia el modelo de datos ni se requiere migración.
