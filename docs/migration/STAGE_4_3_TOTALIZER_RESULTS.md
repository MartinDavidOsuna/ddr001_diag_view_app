# Stage 4.3 — Resultados de formato del totalizador

Fecha: 2026-08-11. Pixel 7 Pro, simulador visible `48.2 m³`, configuración evaluada: tres dígitos significativos, un decimal, unidad m³ y ceros iniciales permitidos.

Se reutilizan las diez fotografías independientes del corpus físico AFTER de Stage 4.2. No se movió la aguja ni se creó una calibración productiva. Todas invocaron el pipeline productivo; Stage 4.3 vuelve a interpretar sus salidas raw con la configuración explícita nueva.

| # | Truth | Raw OCR | Digits/candidato | Decimal places | Proposal | Correcta | Fallback |
|---:|---:|---|---|---:|---:|:---:|:---:|
| 1 | 48.2 | `482` | `482` | 1 | 48.2 | sí | no |
| 2 | 48.2 | `482` | `482` | 1 | 48.2 | sí | no |
| 3 | 48.2 | `o482` | `0482`, ambiguo | 1 | 48.2 | sí | confirmación |
| 4 | 48.2 | `482` | `482` | 1 | 48.2 | sí | no |
| 5 | 48.2 | `o48.2` | `0482`, ambiguo | 1 | 48.2 | sí | confirmación |
| 6 | 48.2 | `o482` | `0482`, ambiguo | 1 | 48.2 | sí | confirmación |
| 7 | 48.2 | `482` | `482` | 1 | 48.2 | sí | no |
| 8 | 48.2 | `e482` | `482` | 1 | 48.2 | sí | no |
| 9 | 48.2 | `o482` | `0482`, ambiguo | 1 | 48.2 | sí | confirmación |
| 10 | 48.2 | `482` | `482` | 1 | 48.2 | sí | no |

## Métricas

- Reconocimiento útil de la secuencia de dígitos: 10/10 = 100%.
- Propuesta final exacta OCR + configuración: 10/10 = 100%.
- Propuestas que requirieron confirmación conservadora por caracteres ambiguos: 4/10 = 40%.
- Autoaceptación silenciosa de candidatos ambiguos: 0.
- Objetivo preliminar de propuesta exacta ≥70%: alcanzado en este corpus controlado.

Esto no afirma precisión general de campo. En la corrida productiva normal adicional, START (`olel48:` → `148`) y FINAL (`alalals` → sin candidato) necesitaron fallback manual; ambas Evidence permanecieron válidas. La diferencia confirma que ML Kit puede fallar antes del parser, mientras que la pérdida aislada del separador queda resuelta por configuración.
