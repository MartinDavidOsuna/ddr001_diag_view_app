# Etapa 1 — Notas del motor metrológico

## Alcance implementado

El paquete `app/` contiene exclusivamente el motor metrológico Dart puro y sus tests. No contiene widgets, adquisición, persistencia, backend ni integraciones. `VISUAL` representa LECTURA VISUAL productiva y comparte el cálculo desde lecturas confirmadas; no implementa `PulseSource` ni genera pulsos ficticios.

## Lecturas y vueltas de aguja

`MeterReading` conserva por separado el odómetro, su escala en litros, la posición fina y los litros por vuelta. Los endpoints por sí solos son ambiguos: por eso el cálculo exige exactamente uno de estos datos:

- número explícito de vueltas completas observado/confirmado; o
- `V_ref`, con el que selecciona el entero de vueltas que deja `V_ind` más cercano a la referencia, conforme a ADR-002.

Esto cubre cruces por cero, una o varias vueltas y avance simultáneo del odómetro. Si no existe ninguno de esos elementos de desambiguación, el motor rechaza el cálculo en vez de asumir silenciosamente una vuelta.

## Estrategia numérica

Las decisiones usan los valores `double` sin redondearlos. `NumericTolerance` centraliza una tolerancia absoluta y relativa de `1e-12`, destinada solo a absorber ruido de representación binaria en comparaciones `<=` y `>`. Una diferencia material mayor que esa tolerancia conserva su efecto metrológico.

## Interpretación conservadora del resumen por caudal

La SSOT no define un mínimo universal de muestras para cerrar cada caudal, pero sí indica que la repetibilidad solo se evalúa con `n >= 3`. Por ello:

- sin muestras, el caudal queda `PENDING`;
- con una o dos muestras todas `PASS`, el caudal puede resumirse como `PASS`, mientras repetibilidad queda `NOT_EVALUABLE`;
- cualquier muestra `FAIL` produce `FAIL`;
- sin `FAIL`, una muestra `INCONCLUSIVE` produce `INCONCLUSIVE`;
- con `n >= 3`, una repetibilidad fallida produce `FAIL`.

Una futura regla de selección/cierre que exija un número mínimo distinto debe definirse en SSOT/ADR antes de cambiar este comportamiento.

## Comparación con el legado

Funciones comparables inspeccionadas en `legacy/web-prototype/index.html`:

- `V_ref = (endCount - origin) * K`: compatible.
- error endpoint `(advance - vol) / vol * 100`: compatible.
- incertidumbre `uL * sqrt(2) / vol * 100`: compatible.
- reconstrucción diagnóstica de vueltas mediante el múltiplo de 100 L más cercano: compatible conceptualmente y endurecida para el endpoint.
- media, dispersión y desviación estándar muestral: compatibles.

Discrepancias donde prevalece SSOT v9:

- el resultado confirmado legado usa solo `abs(error) <= MPE`, ignorando `U` y sin `NO_CONCLUYENTE`; el motor aplica la banda de guarda oficial;
- al alcanzar `Vmax`, el legado fuerza aprobado/rechazado aunque la banda cruce el límite; el motor conserva `INCONCLUSIVE`;
- el resumen legado considera solo que cada muestra esté dentro del MPE y no aplica `s <= MPE/3`; el motor sí aplica repetibilidad desde `n >= 3`;
- el endpoint legado suma directamente odómetro y aguja y puede perder vueltas completas; el motor reconstruye una o varias vueltas;
- el simulador redondea la lectura mostrada; el motor nunca redondea para calcular ni decidir.

El escenario configurable del simulador con error `-1.2 %` y 200 L se conserva como prueba de regresión compatible. El caso JSON legado de 212 L patrón y 206 L indicados se prueba con los valores completos exigidos por SSOT.
