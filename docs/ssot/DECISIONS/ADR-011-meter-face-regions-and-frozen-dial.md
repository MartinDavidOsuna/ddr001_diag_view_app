# ADR-011 — Regiones de carátula y configuración de dial congelada

- Estado: Aceptado
- Fecha: 2026-08-10

## Contexto

Una fotografía de carátula contiene un totalizador rectangular y uno o varios diales circulares con semánticas y resoluciones diferentes. Stage 4 usaba ROI y mapeo únicos no persistidos.

## Decisión

- Una Evidence completa e inmutable alimenta derivados independientes de totalizador y dial; los crops nunca reemplazan el original.
- Toda geometría se normaliza respecto de la imagen orientada, no de la pantalla.
- El selector de dial usa litros por vuelta como resolución metrológica. Tamaño, píxeles y nitidez no deciden la selección. Sin escala inequívoca se requiere confirmación humana.
- La configuración confirmada en START (ROI, círculo, multiplicador, litros/vuelta, cero, sentido y origen) se persiste en Sample RUNNING y se reutiliza en INTERMEDIATE/FINAL.
- Drift 3 agrega columnas nullable mediante migración aditiva. La canonicalización v1 se conserva para muestras históricas; muestras con configuración visual usan v2.

## Consecuencias

Reanalizar ROI no crea evidencia ni altera el archivo original. La detección circular ligera solo propone candidatos y siempre conserva ajuste manual. No se incorpora OpenCV.
