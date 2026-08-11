# Etapa 4.1 — Endurecimiento de lectura de carátula

## Procedimiento preservado

Se conserva `START → INTERMEDIATE` según `evidenceStepLiters` `→ FINAL`. Cada paso produce una sola fotografía completa. La misma Evidence origina totalizador, dial, OCR, aguja, propuesta y confirmación; ajustar regiones no agrega Evidence y solo REPETIR FOTO recaptura la evidencia mutable.

## Totalizador y dial

`TotalizerRegion` es un rectángulo relativo ajustable. Su crop derivado se orienta por EXIF, se amplía, convierte a grises y recibe contraste moderado antes de ML Kit. La foto original no se modifica. La corrección de perspectiva explícita queda pendiente: la normalización actual cubre rotación EXIF y el ajuste manual cubre inclinación moderada sin filtro destructivo.

`List<DialCandidate>` contiene círculos propuestos por contorno ligero. Mayor resolución significa menor volumen por vuelta, nunca mayor tamaño físico. Se soportan `×1`, `×0.1`, `×0.01` y `×0.001`; una escala ausente/empatada no se selecciona silenciosamente y se confirma visualmente. El círculo puede moverse, redimensionarse o reemplazarse por otro candidato.

## Freeze, recuperación e intermedias

START persiste geometría, escala, litros/vuelta, cero, sentido y origen en Sample. INTERMEDIATE intenta análisis diagnóstico con esa configuración sin exigir OCR; FINAL reutiliza la misma configuración y exige la confirmación endpoint usual. OCR/aguja fallidos no invalidan una foto íntegra.

Drift usa schema 3 con migración aditiva 2→3 y campos nullable. Sample contract es v5. Checksum canonical v2 incorpora configuración visual solo para muestras que la tienen; datos/checksums históricos conservan v1.

## Validación con simulador

Pixel 7 Pro `27301FDH3004R7`, Android 17/API 37, actualización in-place sin uninstall/Clear Data. Se completó una corrida con START, cuatro INTERMEDIATE (25/50/75/100 L) y FINAL; la app conservó sesión/Sample/Evidence tras dos actualizaciones y reanalizó la Evidence START existente al reanudar.

Capturas realmente realizadas: seis fotos del simulador con encuadre frontal similar. No se completó un corpus controlado de inclinación/distancia/iluminación, por lo que esas condiciones siguen pendientes.

- OCR endpoint: 0/2 automático (0 % observado); START y FINAL usaron fallback manual. En START el ROI inicial abarcó controles del simulador y, aun tras ajuste, produjo candidatos ambiguos sin selección silenciosa.
- Aguja START: `0.83 L` con ROI inicial; `61.39 L` tras el ajuste ensayado. La indicación visible conocida era aproximadamente `50 L`, por lo que los errores absolutos observados fueron aproximadamente `49.17 L` y `11.39 L` respectivamente.
- Aguja FINAL: propuesta `4.17 L`; no se registró una lectura real independiente confiable para calcular error.
- Resultado cerrado: `Vref=125.00 L`, `Vind=154.17 L`, `E=23.336 %`, `U=1.131371 %`, `RECHAZA`. Se conserva tal cual; no se ajustaron resultados para forzar concordancia.

Estas tasas describen únicamente los dos endpoints de esta corrida y no representan precisión general de campo.

## Limitaciones

- El detector circular ligero propone candidatos; confirmación humana sigue siendo obligatoria ante ambigüedad.
- OCR de multiplicador es auxiliar y una escala desconocida requiere selección manual.
- No se implementó corrección proyectiva de cuatro puntos ni OpenCV.
- No se reconocen manómetros externos, válvulas, gabinete, tubería ni medidor dentro de una escena amplia.
- Stage 5 permanece fuera de alcance.
