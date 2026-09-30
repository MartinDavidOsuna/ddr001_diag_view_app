# ADR-030 — Correcciones manuales trazables e integración pendiente

- Estado: aceptada por solicitud explícita del usuario, 2026-09-30.
- Versión: 1.8.0+26; schema Drift 15.

## Decisión

Se permite corregir lecturas INICIO/FINAL, configuración de cálculo y cuenta/banco de una verificación
finalizada desde Historial local. Esta es una excepción explícita a la regla de
inmutabilidad de muestras cerradas de AGENTS, PROJECT_TRUTH y ADR anteriores.
Los repositorios ordinarios siguen rechazando actualizaciones de muestras
cerradas. No se reabre la adquisición ni se agregan muestras al expediente.

Cada corrección exige motivo y usuario propietario; compara el checksum de la
versión abierta por el formulario para rechazar ediciones obsoletas. Una sola
transacción registra snapshots completos antes/después de Case, Flow, Sample y
Point, actor, fecha, motivo y los totales manuales introducidos; recalcula usando
el mismo motor con la configuración corregida. Conserva pulsos, tiempos de adquisición,
GPS, imágenes y hashes, MPE y fórmulas. Permite corregir K patrón/hidrante, incertidumbre
base, escala del odómetro, escala de aguja y Vref manual para lectura visual. No convierte muestras inválidas
en válidas. La evidencia original debe continuar íntegra para recalcular una
muestra; cualquier error revierte la transacción completa.

Los triggers sólo permiten la escritura cerrada dentro del ámbito transaccional
`correction_write_scope`; se retira antes del commit. El historial
`case_corrections` no permite borrar ni alterar snapshots. Sólo se actualiza su
ACK. Se incrementa reportVersion, se recalculan checksum de muestra/expediente,
resúmenes de caudal, repetibilidad y veredicto global. La fecha de cierre físico
no cambia. Los exportes nuevos usan el resultado y revisión vigentes; los archivos
ya compartidos no se pueden retirar ni actualizar retrospectivamente.

Los métodos BLE/SIMULACIÓN recalculan Vind desde los endpoints compuestos
(totalizador × escala + aguja). Manual/LED/visual conservan la captura de totales
INICIO/FINAL y su diferencia, como el flujo de cierre vigente. Dado que versiones
anteriores sólo guardaban ese avance, el formulario propone un par de totales
que conserva exactamente el avance; no afirma recuperar dos totales originales
que no estaban persistidos.

## Configuración histórica

La respuesta posterior del usuario amplió explícitamente la corrección a
configuración, incluidos litros por pulso. K corregido recalcula Vref = N × K
con los mismos pulsos; Vref y caudal de los puntos se reexpresan proporcionalmente
al cambio de escala, sin estimar ni añadir pulsos. Incertidumbre y escalas manuales
alimentan el motor existente. Cada revisión conserva antes/después, incluyendo
`sample_operational_settings`. La evidencia se verifica contra el plan original
obtenido del primer snapshot, no contra un plan retroactivo de nuevas fotos.
Las fotos y metadata conservan el volumen de captura original, rotulado como tal
en el reporte; resultados/puntos usan los valores corregidos. Cambiar K no altera
la integridad del contador ni la validación de archivos originales.

El paso de captura, umbrales de inicio, geometría de cámara y formato de la
adquisición permanecen como hechos de la prueba realizada; el formulario corrige
la configuración de cálculo, no recrea esas operaciones físicas. En registros
legados sin settings, corregir K del hidrante materializa defaults operativos
100/300 L y rango 0..1e308, conservando el snapshot previo de ausencia.

## Litros por pulso

Preparación permite configurar K del medidor patrón en todos los métodos, además
de K del hidrante. Ambos inician en 10 L/pulso para nuevas configuraciones; quedan
congelados en cada Sample. No se migran los K de muestras previas ni se reinterpretan
sus pulsos. LECTURA VISUAL conserva su Vref explícito, sin fabricar pulsos.

## Sincronización y límite de API

El botón junto al título de Historial sincroniza secuencialmente verificaciones
finalizadas pendientes del usuario activo. Omite ACK ya confirmado, impide doble
activación y continúa con el siguiente expediente ante error individual. No envía
expedientes abiertos/incompletos como si fueran verificaciones finalizadas.

Cualquier corrección queda `Pendiente (editada)` de forma persistente. Por
instrucción posterior del usuario, esto incluye registros nunca enviados: toda
corrección requiere comprobar una capability explícita en `GET /me/access`.
Sin soporte se muestra «Hace falta actualizar la API…» y no se sube ni evidencia
ni grafo de esa verificación. La sincronización global continúa con las demás.

Cuando la API anuncie `manualCorrections.ready=true` y schema exacto
`functional-diagnostics.corrections/v1`, se envía un nuevo batch versionado al
endpoint existente `sync/push`. No se reusa el ACK anterior. Sólo un ACK completo
del grafo, de los correctionId y del checksum vigente confirma la corrección.
Se recuperan ACK perdidos antes de enviar revisiones posteriores. Los requests,
receipts y entradas de cola sustituidas se conservan para trazabilidad.

## Requisito para la API

El cliente ya implementa el contrato negociado propuesto; el servidor no se modificó.
Especificación exacta de capability, envelope, concurrencia e idempotencia:
[API_MANUAL_CORRECTIONS_V1](../../deployment/API_MANUAL_CORRECTIONS_V1.md).
La API debe implementarlo antes de anunciar readiness. No basta cambiar su versión.

## Validación

Tests de recálculo, persistencia transaccional, rollback ante fallo, propietarios,
checksum obsoleto, migración preservadora, protección fuera del servicio, historial,
primera publicación corregida, ACK anterior, formularios y regresión completa.
No hay pruebas de radio BLE ni cambios de firmware en esta intervención.
