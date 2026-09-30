# ADR-027 — Errores de sincronización trazables

- Estado: aceptada
- Fecha: 2026-09-18
- Versión: 1.7.3+22

## Contexto

El Pixel muestra HTTP 500 sin operación ni detalle. Auth Field y el módulo
funcional usan formatos de error distintos; el cliente sólo leía el segundo.
La prueba integral contra DDR001_Hidrantes_TEST pasa con sesión, evidencias,
sync y ACK, pero no certifica el proceso desplegado en producción.

## Decisión

Aceptar los dos formatos existentes sin cambiar la API. Cada error HTTP
incluye operación conocida por el cliente, estado, mensaje y request ID UUID
validado. La etapa de refresh tiene prioridad sobre la solicitud original.
Las respuestas no JSON o JSON de tipo inesperado conservan el código HTTP y
la clasificación de reintento; no se muestra su cuerpo crudo. El detalle se
limita a 240 caracteres y se eliminan controles. No se añaden logs de tokens,
identidad, fotos ni cuerpos enviados. El motor conserva el diagnóstico en los
estados de error existentes; no hay migración ni cambio de datos cerrados.

## Límite

Una mejor descripción no repara una excepción del servidor. Hace falta
reintentar en el dispositivo y confirmar un ACK antes de declarar resuelto el
incidente. El código de captura de pulsos y cámara no cambia en esta versión.

## Ampliación 1.7.4+23

Mostrar hasta ocho rutas/códigos de validación de ambos contratos de errores.
Los campos se presentan en texto seleccionable debajo de SINCRONIZAR para
poder compartir el diagnóstico sin copiar datos rechazados ni todo el JSON.
Esta ampliación no cambia ni regenera un lote rechazado.
