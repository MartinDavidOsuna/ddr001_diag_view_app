# Stage 4.2 — Resultados de calibración visual

Fecha: 2026-08-11. Dispositivo: Pixel 7 Pro `27301FDH3004R7`. Banco: simulador DDR001 mostrado físicamente frente a la cámara. Estas métricas describen únicamente este corpus controlado; no son precisión general de campo.

## Configuración y método

- Dial: 10 L/vuelta, cero a las 12, sentido horario.
- Posiciones: 0, 1, 2.5, 5, 7.5, 9 y 9.9 L.
- Tres fotografías independientes por posición y fase: 21 BEFORE + 21 AFTER.
- Mismos `CameraPort` y `VisualReadingPipeline` productivos. El valor real no modifica la detección.
- En wrap se usa la diferencia circular mínima dentro de 10 L; 9.6389 frente a 0 equivale a -0.3611 L.

## Aguja BEFORE

| Real | Detectado 1 | Detectado 2 | Detectado 3 | Errores circulares (L) |
|---:|---:|---:|---:|---|
| 0.0 | 9.6389 | 9.6389 | 9.6389 | -0.3611, -0.3611, -0.3611 |
| 1.0 | 0.5833 | 0.6944 | 0.6944 | -0.4167, -0.3056, -0.3056 |
| 2.5 | 2.4722 | 2.4722 | 2.4722 | -0.0278, -0.0278, -0.0278 |
| 5.0 | 5.3611 | 5.3611 | 5.3611 | +0.3611, +0.3611, +0.3611 |
| 7.5 | 7.4167 | 7.4167 | 7.4167 | -0.0833, -0.0833, -0.0833 |
| 9.0 | 8.6944 | 8.6944 | 8.6944 | -0.3056, -0.3056, -0.3056 |
| 9.9 | 9.5278 | 9.4722 | 9.5278 | -0.3722, -0.4278, -0.3722 |

Métricas: n=21; detecciones=21; failure rate=0%; mean signed error=-0.1643 L; MAE=0.2675 L; RMSE=0.3013 L; máximo absoluto=0.4278 L; desviación estándar poblacional=0.2525 L.

## Diagnóstico y corrección

El error casi nulo en 2.5/7.5 L, positivo en 5 L y negativo alrededor de 0/1/9/9.9 L descartó un `zeroAngle` constante o una escala proporcional. El centro del crop no coincidía con el eje físico y el círculo relativo generaba un crop portrait rectangular que incluía parte del totalizador. Un intento PCA empeoró 9.9 L a aproximadamente 9.2 L y fue rechazado.

La corrección final genera un crop cuadrado en píxeles, refina el eje con el conjunto rojo próximo al centro configurado y después aplica el histograma angular. El mapping ángulo→litros permanece separado. El snap de cero es ±2°, menor que los 3.6° que separan 9.9 L de cero.

## Aguja AFTER

| Real | Detectado 1 | Detectado 2 | Detectado 3 | Errores (L) |
|---:|---:|---:|---:|---|
| 0.0 | 0.0000 | 0.0000 | 0.0000 | 0, 0, 0 |
| 1.0 | 0.9306 | 0.9583 | 0.9583 | -0.0694, -0.0417, -0.0417 |
| 2.5 | 2.4861 | 2.4861 | 2.4861 | -0.0139, -0.0139, -0.0139 |
| 5.0 | 4.9861 | 4.9861 | 4.9861 | -0.0139, -0.0139, -0.0139 |
| 7.5 | 7.4861 | 7.4861 | 7.4861 | -0.0139, -0.0139, -0.0139 |
| 9.0 | 8.9306 | 8.9028 | 8.9306 | -0.0694, -0.0972, -0.0694 |
| 9.9 | 9.7639 | 9.7639 | 9.7639 | -0.1361, -0.1361, -0.1361 |

Métricas: n=21; detecciones=21; failure rate=0%; mean signed error=-0.0439 L; MAE=0.0439 L; RMSE=0.0635 L; máximo absoluto=0.1361 L; desviación estándar poblacional=0.0459 L. Se alcanzó el objetivo proporcional de 0.2 L para 10 L/vuelta.

Una captura adicional de 0 L durante el corpus OCR produjo 9.9306 L. No pertenece al corpus dedicado AFTER y se conserva como limitación de wrap ante variación de captura.

## OCR

BEFORE: 21 fotos, exact automatic success=0/21 (0%). ML Kit produjo `47 2`, `o472`, `47 3` o vacío.

AFTER: ROI más ceñido, color preservado y rechazo de candidato ambiguo. Se usaron diez registros completos frontales independientes con valor 48.2; una captura sin registro completo se excluyó.

| # | ML Kit raw | Resultado | Clasificación |
|---:|---|---|---|
| 1 | `482` | 482 | incorrecta |
| 2 | `482` | 482 | incorrecta |
| 3 | `o482` | ambiguo/no seleccionado | fallback |
| 4 | `482` | 482 | incorrecta |
| 5 | `o48.2` | 48.2 ambiguo/no seleccionado | fallback |
| 6 | `o482` | ambiguo/no seleccionado | fallback |
| 8 | `e482` | 482 | incorrecta |
| 9 | `482` | 482 | incorrecta |
| 10 | `o482` | ambiguo/no seleccionado | fallback |
| 11 | `482` | 482 | incorrecta |

Métricas AFTER: total=10; exact automatic success=0; wrong automatic=6; no candidate=0; ambiguous=4; manual fallback=4; exact success rate=0%. ML Kit obtuvo dígitos útiles en 10/10, pero solo una salida contenía el decimal correcto y además era ambigua. No se insertó el decimal por heurística porque la configuración no declara posiciones decimales.

## Recuperación, límites y conclusión

`am force-stop` + relanzamiento conservó sesión y datos. No había Sample VISUAL RUNNING activa, así que no se observó físicamente la reanudación de geometría; permanece cubierta por tests de persistencia de Stage 4.1. No cambian schema 3, contract v5 ni checksum v2.

La aguja queda validada cuantitativamente para este simulador frontal. OCR no alcanza 70% y conserva fallback manual. Se recomienda Stage 4.3 antes de Stage 5 para declarar el formato decimal o segmentar tambores sin inferir dígitos, ampliar corpus y repetir recovery físico con Sample RUNNING.
