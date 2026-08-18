# ADR-014 — Carátula manual-first y visibilidad por capability

- Estado: Aceptado
- Fecha: 2026-08-16

## Contexto

No hay layout universal entre marcas. El análisis de fotografía completa produjo falsos positivos y una UI remota sin configuración parecía una tarea incompleta del técnico.

## Decisión

El técnico confirma `TotalizerRegion`, un `DialGeometry` y formato/escala en START antes de analizar. OCR y aguja reciben exclusivamente esos crops; una aguja válida requiere rojo y geometría radial. La configuración existente se persiste, congela y recupera; no se crea un modelo paralelo. UI de hidrantes/sync se muestra solo con capability configurada. El manual canónico offline forma parte de la app.

## Consecuencias

Se evitan decisiones automáticas de layout y números externos al crop. El técnico puede ajustar FINAL sin crear Evidence. Código de sugerencias puede permanecer como utilidad no autoritativa. No cambian metrología, cantidad de fotos, backend ni contratos.
