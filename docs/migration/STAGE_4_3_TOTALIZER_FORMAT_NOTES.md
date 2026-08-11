# Stage 4.3 — Formato del totalizador

Fecha: 2026-08-11.

## Problema observado

Stage 4.2 obtuvo dígitos útiles en 10/10 fotografías del corpus AFTER, pero ML Kit omitió con frecuencia el separador decimal (`482` para una lectura visible `48.2`). Insertar el punto por heurística habría mezclado reconocimiento con significado metrológico.

## Solución

Se separaron `RawOcrResult`, candidatos de `OdometerParser` y la aplicación explícita de `TotalizerConfiguration`. La configuración contiene `digitCount`, `decimalPlaces`, unidad (`m3`), política de ceros iniciales, ROI relativo y origen. El parser conserva el texto raw, extrae candidatos y marca `O/o/I/l` como ambiguos; no autoacepta correcciones de caracteres.

La posición decimal se aplica exclusivamente desde la configuración confirmada. Por ejemplo, `482` con tres dígitos y un decimal produce `48.2 m³`; con dos decimales produce `4.82 m³`. Un cero inicial adicional solo se elimina cuando `leadingZerosAllowed=true`, y la propuesta exige confirmación.

## Flujo productivo

No se agregó calibración. START sigue usando una fotografía completa, permite confirmar una vez el formato y guarda configuración, lectura y Evidence. FINAL reutiliza la configuración congelada. INTERMEDIATE conserva su función diagnóstica y no exige OCR exacto. La herramienta de calibración continúa enlazada únicamente bajo `kDebugMode`.

Una corrección humana marca la lectura como `MANUAL`; aceptar una propuesta intacta conserva `AUTO_CONFIRMED`. Las muestras cerradas siguen inmutables.

## Persistencia, integridad y contrato

- Drift avanza de schema 3 a 4 mediante columnas aditivas nullable; no se borró la base del Pixel.
- Canonicalización v3 se usa solo cuando existe formato de totalizador; muestras históricas conservan v1/v2.
- Sample contract avanza de v5 a v6 e incorpora `totalizer_format` tipado.
- Force-stop real recuperó formato `digitCount=5`, `decimalPlaces=1`, unidad `cubicMeters`, ceros iniciales permitidos, ROI, lectura START manual `48.2`, aguja `0.0` y el mismo Evidence `a81a6b6b-908e-40cb-b1db-cc306d28eabb` con SHA-256 sin cambio.

## Validación productiva

Se completó en Pixel 7 Pro una corrida VISUAL normal `STAGE43y`, fuera de la pantalla debug. START y FINAL usaron una fotografía cada uno; no hubo INTERMEDIATE porque Vref fue 10 L y el paso configurado 25 L. FINAL mostró directamente `####.# · m³`, demostrando reutilización. Al permanecer estático el simulador, el resultado metrológico fue el rechazo esperado; esto no se usó para ajustar visión.

## Limitaciones

La ROI depende del encuadre y puede requerir ajuste visual. En las dos fotografías de la corrida normal el crop aún produjo caracteres ambiguos o ningún candidato, por lo que se ejercitó el fallback manual. El corpus controlado de Stage 4.2 demuestra el caso dominante de dígitos útiles sin punto y se reevalúa en el archivo de resultados.
