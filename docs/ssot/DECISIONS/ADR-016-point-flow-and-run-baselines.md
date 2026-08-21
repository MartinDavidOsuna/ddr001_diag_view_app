# ADR-016 — Caudal puntual y baselines de corrida

- **Estado:** aceptada
- **Fecha:** 2026-08-20

## Contexto

El LPS aproximado manual no representa el comportamiento observado durante la prueba. Además, iniciar los contadores de control e hidrante en momentos distintos produce una comparación visual incoherente.

## Decisión

- Las verificaciones nuevas no solicitan LPS en Identificación; `FlowPoint.lps_approx` permanece nullable para compatibilidad histórica.
- El caudal continuo se calcula con volumen acumulado dividido entre el tiempo desde el primer pulso, nunca desde la apertura de una pantalla.
- INICIO, cada INTERMEDIA y FINAL congelan `Point.flow_lps` con el timestamp de su Evidence. Mínimo, máximo y promedio consideran únicamente esos puntos persistidos.
- Al pulsar INICIAR se congelan simultáneamente los baselines GPIO27/GPIO25 y ambos contadores visibles comienzan en cero.
- Al pulsar FINALIZAR se desasocian atómicamente GPIO27, GPIO25 y reconciliación LED de la Sample antes de capturar FINAL. El transporte GATT permanece conectado, pero ningún evento posterior altera el endpoint.

## Consecuencias

- Los registros históricos sin `flow_lps` siguen siendo válidos y se excluyen de las estadísticas.
- Las estadísticas de caudal son descriptivas y no alteran el error metrológico endpoint ni el veredicto.
- SQLite incorpora `test_points.flow_lps` mediante una migración aditiva a schema 10.
