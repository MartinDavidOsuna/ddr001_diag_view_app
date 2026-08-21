# GLOSSARY — Glosario

- **Q1 operativo** — corrida V1 que sustituye a la antigua Q3 y hereda sus reglas de gasto permanente (nominal).
- **Q2 medio** — corrida V1 que conserva las reglas de la anterior Q2.
- **Q3 histórico (Qp/Qn)** — identificador anterior de gasto permanente, conservado para leer expedientes existentes.
- **Q4 (Qmáx/Qs)** — gasto de sobrecarga (≈2·Q3).
- **K** — constante del banco: volumen por pulso. Proyecto: 1 L/pulso.
- **MPE** — error máximo permisible (±2% zona superior, ±5% inferior).
- **Endpoint** — error relativo de indicación calculado sobre el volumen total colectado (métrica reportable).
- **V.patrón / V_ref** — volumen de referencia = N·K.
- **V.mec / V_ind** — volumen indicado por el medidor = lectura_final − lectura_inicial.
- **Odómetro** — parte gruesa de la carátula (m³).
- **Aguja ×0.01 m³** — parte fina; una vuelta = 100 L; marca mínima 2 L.
- **Punto diagnóstico** — corte intermedio cada 25 L; NO se promedia para el resultado.
- **Repetibilidad (s)** — desv. est. muestral de errores entre corridas independientes (n≥3).
- **Dispersión** — (máx − mín) de errores entre muestras.
- **TUR** — test uncertainty ratio; se exige ≥ 4:1 (patrón vs MPE).
- **Checksum** — FNV-1a del registro; integridad + idempotencia de sync.
- **SSOT** — single source of truth (`docs/ssot/`).
