# METROLOGY_RULES — Reglas metrológicas

> **Estado:** consolidado en Etapa 0. No cambiar sin ADR.

## 1. Referencia normativa
La implementación toma como referencia técnica la familia ISO 4064 / OIML R49 para medidores de agua. Para medidores Clase 2 y agua fría, el MPE usado por el sistema es:

| Zona | Intervalo | MPE |
|---|---|---:|
| Corrida Q1 — caudal operativo | Configuración operativa DDR001 | ±2 % |
| Superior | Q2 ≤ Q ≤ Q4 | ±2 % |

La V1 usa una nomenclatura operativa de dos corridas:
- **Q1 — Caudal operativo:** sustituye a la antigua etapa Q3 y hereda todas sus reglas de caudal permanente, incluido MPE ±2 %.
- **Q2 — Caudal medio:** conserva las reglas que ya correspondían a Q2, incluido MPE ±2 %.

Q3 y Q4 permanecen únicamente para compatibilidad con expedientes históricos; no son corridas nuevas del flujo V1.

No se captura `LPS aprox.` para verificaciones nuevas. El caudal mostrado durante la corrida usa volumen acumulado/tiempo transcurrido desde el primer pulso aceptado, nunca desde la apertura de la pantalla. Cada Evidence INICIO/INTERMEDIA/FINAL congela su LPS puntual; el mínimo, máximo y promedio son estadísticas descriptivas de esos snapshots y no sustituyen el error endpoint.

## 2. Constantes configurables
Valores iniciales:
- `K = 1 L/pulso`.
- Paso de evidencia = `25 L`.
- Volumen mínimo orientativo = `100 L`.
- Volumen máximo orientativo = `300 L`.
- Incertidumbre de lectura base `u_L = 1 L` mientras no exista un presupuesto más completo.

Los valores realmente usados se congelan dentro de cada muestra cerrada.

## 3. Volumen patrón
`V_ref = N × K`

- `N`: pulsos válidos desde el origen de la muestra.
- `K`: litros por pulso configurados para esa muestra.
- Manual, LED y BLE alimentan exactamente el mismo contador de pulsos.
- **LECTURA VISUAL** es también un método productivo de campo, pero obtiene el avance mediante lectura visual de la carátula/odómetro del medidor real; no debe modelarse como pulsos ficticios. El simulador web externo se usa únicamente para contrastar y validar esta lógica.

## 4. Volumen indicado
`V_ind = lectura_final − lectura_inicial`, expresado en litros y corregido por continuidad de la aguja/odómetro.

### Reconstrucción de vueltas
Cuando la lectura fina de aguja cubre 100 L por vuelta:

```text
fineAdv = agujaFinal - agujaInicial
odoAdv  = (odoFinal - odoInicial) * 1000
adv0    = odoAdv + fineAdv
kTurns  = round((V_ref - adv0) / 100)
V_ind   = adv0 + 100 * kTurns
```

La implementación Flutter puede adoptar una representación de lectura completa más robusta, pero debe conservar la capacidad de resolver una o más vueltas y producir el mismo avance físico correcto.

## 5. Error reportable — endpoint
El único error reportable por muestra es:

`E(%) = ((V_ind - V_ref) / V_ref) × 100`

Los puntos de 25 L son diagnósticos/evidencia. **No se promedian** para producir el error oficial de la muestra.

## 6. Incertidumbre
Modelo inicial de lectura:

`U_read(%) = (u_L × √2 / V_ref) × 100`

Cuando exista incertidumbre certificada del patrón u otras componentes, deben combinarse por RSS en unidades compatibles y documentarse antes de sustituir este modelo.

En reportes, `U` representa la incertidumbre expandida declarada por la implementación vigente. La configuración y componentes utilizados quedan congelados en la muestra.

## 7. Regla de decisión con banda de guarda
Para reducir falsos APROBADO, la conformidad se decide considerando `U`:

- **APRUEBA:** `|E| + U ≤ MPE`.
- **RECHAZA:** `|E| - U > MPE`.
- **NO CONCLUYENTE:** en cualquier otro caso, es decir, cuando el intervalo asociado a la incertidumbre cruza el límite de aceptación.

Un resultado **NO CONCLUYENTE** obliga a repetir la muestra; no se transforma automáticamente en aprobado ni rechazado.

El reporte debe mostrar como mínimo: `E`, `U`, `MPE`, resultado de la regla de decisión y veredicto.

## 8. Repetibilidad
La app admite muestras ilimitadas. A partir de `n ≥ 3` muestras válidas e independientes de un mismo caudal calcula:
- error medio;
- dispersión `max(E) - min(E)`;
- desviación estándar muestral `s`.

Como control de repetibilidad para el mismo caudal:

`s ≤ MPE / 3`

El resultado de repetibilidad es adicional al veredicto individual de cada muestra y debe quedar visible en el resumen del caudal.

## 9. Resultado por caudal
Un caudal puede estar:
- `PENDING`: sin muestras válidas suficientes/seleccionadas para cierre.
- `PASS`: las muestras consideradas válidas cumplen la regla y, cuando aplica, repetibilidad.
- `FAIL`: existe incumplimiento que determina rechazo del caudal.
- `INCONCLUSIVE`: no puede cerrarse por resultados no concluyentes hasta repetir.

El flujo exacto de selección/cierre debe conservar todas las muestras y nunca borrar historial.

## 10. Veredicto global del expediente
Al finalizar el expediente se calcula un veredicto global sobre **los caudales efectivamente requeridos/evaluados en ese expediente**:
- `APROBADO`: todos los caudales cerrados requeridos están `PASS`.
- `RECHAZADO`: al menos uno está `FAIL`.
- `NO CONCLUYENTE`: no existe `FAIL`, pero algún caudal requerido sigue `INCONCLUSIVE`/sin cierre.

El sistema nunca inventa caudales faltantes como aprobados.

## 11. Casos de test obligatorios
1. `V_ref=212 L`, `V_ind=206 L` → `E=-2.830188...%`, `U≈0.667%`, MPE 2 → **RECHAZA**.
2. `E=+1.00%`, `U=0.50%`, MPE 2 → `1.50≤2` → **APRUEBA**.
3. `E=+1.70%`, `U=0.50%`, MPE 2 → intervalo cruza límite → **NO CONCLUYENTE**.
4. `E=+2.80%`, `U=0.50%`, MPE 2 → `2.30>2` → **RECHAZA**.
5. Caso de 200 L con vueltas de aguja debe reconstruir correctamente `V_ind` sin perder múltiplos de 100 L.
6. Fronteras exactas de ±2 % y ±5 % con U=0 y con U>0.
7. Repetibilidad `s=MPE/3` debe cumplir; apenas por encima debe fallar.
