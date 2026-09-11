# ADR-022 — Simulación variable controlada por operador

- **Estado:** aceptada
- **Fecha:** 2026-09-10

## Contexto

La simulación determinista anterior cerraba automáticamente y seleccionaba de
antemano una salida exitosa, fallida o mixta. Eso no representaba la espera de
estabilización ni el control manual de inicio y fin usado en campo, y omitía la
captura manual de lecturas que debe alimentar al motor metrológico real.

## Decisión

- Sustituir el escenario predeterminado de nuevas Samples por
  `OPERATOR_CONTROLLED`, conservando los valores históricos legibles.
- Mostrar flujo antes de INICIAR sin acumular tiempo, pulsos o Vref.
- Generar Q1 dentro de 5–7 L/s y Q2 dentro de 2–3 L/s; dos valores consecutivos
  no difieren en más de 0.5 L/s.
- Fijar el inicio oficial al pulsar INICIAR y el endpoint al pulsar FINALIZAR.
- Crear Evidence simulada START/INTERMEDIATE/FINAL y abrir después la captura
  manual de lecturas. El motor vigente calcula Vind, E, U, MPE y veredicto.
- Permitir en BLE y SIMULACIÓN una lectura de aguja finita no negativa sin
  máximo fijo. Cada lectura completa se deriva como
  `totalizador × litros/unidad + aguja`; Vind es la diferencia FINAL−INICIO y
  no se captura un total redundante.
- Avanzar Drift 13→14 y el contrato local de Sample v9→v10. Mantener sin cambios
  la API congelada, proyectando `OPERATOR_CONTROLLED` al resultado remoto real.

## Consecuencias

- La duración y el resultado dependen de acciones y lecturas explícitas del
  técnico, como en una prueba real.
- Recovery no simula el tiempo transcurrido con la app cerrada ni duplica
  evidencias.
- Las Samples históricas y los contratos remotos continúan siendo compatibles.
- No cambian fórmulas, MPE, incertidumbre, reportes, API, BLE ni firmware.
