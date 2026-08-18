# FUNCTIONAL_SPEC — Especificación funcional

## 0. Reglas generales
- Android portrait.
- UI fiel a `design/screenshots/`; no replicar controles del navegador.
- Offline-first.
- Muestras cerradas inmutables.
- El simulador web legado es únicamente una herramienta externa de validación y no se integra. La **funcionalidad de lectura visual** que representa sí es productiva y se utilizará con medidores reales en campo.

## 1. Login persistente (`features/auth`)
- Campos, en orden: nombre, correo y teléfono. El nombre es obligatorio en la UI, admite Unicode y se persiste sin espacios exteriores.
- No hay contraseña ni pantalla de registro.
- La llave de identificación/autenticación sigue siendo `email + phone`; el nombre es únicamente perfil/identidad y no una tercera credencial.
- Primer login online: backend busca `email + phone`; si no existe, crea usuario automáticamente con `display_name`. Si un usuario local legado coincide y no tiene nombre, se completa sobre el mismo `user_id`; un nombre existente no se sobrescribe durante login.
- Guarda sesión y perfil local.
- Aperturas posteriores reutilizan sesión sin pedir login.
- Si está offline y existe sesión local válida, entra a la app normalmente.
- Única salida voluntaria: botón existente/definido **Cerrar sesión**.

## 2. Identificación (`features/identification`)
- ID/número de cuenta del medidor: texto libre, cualquier valor permitido.
- Consulta opcional/automática de solo lectura al sistema de hidrantes cuando haya conectividad.
- Cuando la capability remota está configurada, estados visibles: consultando / localizado con datos previos / localizado sin levantamiento / no localizado-nuevo / error real. Sin configuración, la consulta se oculta y el ID continúa editable; no se presenta un pendiente ficticio al técnico.
- Si existe levantamiento previo, mostrar los datos disponibles sin obligar a que existan.
- Caudal: Q1, Q2, Q3 o Q4 con descripción técnica correcta y MPE derivado por zona.
- `LPS aprox.` manual.
- GPS: latitud, longitud, precisión y timestamp. También se intenta capturar al iniciar muestra.

## 3. Fuente / método de medición (`features/pulse_source`)
Modos productivos:
- **LECTURA VISUAL:** funcionalidad de campo para medidores reales. Utiliza cámara/visión sobre la carátula para obtener las lecturas visuales necesarias y determinar el avance del medidor durante la prueba. **No es un simulador.**
- **Manual:** botón de pulso; cada pulso suma `K` litros.
- **LED ESP32:** cámara detecta el destello emitido por el ESP32 dentro de ROI configurable, con umbral/histéresis/anti-rebote; cada evento válido suma `K` litros.
- **BLE ESP32:** cada notificación/evento válido representa un pulso y suma `K` litros.
- El ESP32 DDR001 publica contador BLE v1 acumulativo. La app congela baseline, persiste el último contador y reconcilia saltos. Adquisición no verificable se marca `COMPROMISED` y no cierra válida.

Manual, LED y BLE comparten una interfaz común de eventos de pulso. **LECTURA VISUAL** comparte el mismo dominio de muestra, evidencias y cálculo metrológico, pero su adquisición proviene de las lecturas visuales del medidor y no debe forzarse artificialmente a emitir pulsos.

El modo que en el prototipo web se denominaba **Simulación** debe migrarse a Flutter como **LECTURA VISUAL**, eliminando cualquier semántica de simulación en la app productiva. El simulador web externo permanece sin cambios y se usa para validar esta implementación.

## 4. Carátula y cámara (`features/camera_dial`)
- En START, antes de cualquier análisis definitivo, se abre `CONFIGURAR LECTURA`: el técnico mueve/redimensiona el rectángulo de totalizador, mueve/redimensiona el círculo del dial elegido y confirma formato/escala. Solo `ANALIZAR LECTURA` ejecuta OCR y detección de aguja.
- Después de `FIJAR REGIONES`, la tarjeta de fotografía se contrae para priorizar formato, escala y `ANALIZAR LECTURA`.
- El OCR conserva texto raw y candidatos separados del formato. La posición decimal solo se aplica desde `TotalizerConfiguration` confirmada en START (`digitCount`, `decimalPlaces`, unidad y política de ceros iniciales); nunca se infiere silenciosamente.
- FINAL reutiliza el formato congelado. Una inconsistencia o carácter ambiguo exige confirmación/corrección humana y no invalida una fotografía íntegra.
- El procedimiento conserva una Evidence completa por START, cada INTERMEDIATE planificada y FINAL; no existen fotos separadas para totalizador y aguja.
- `TotalizerRegion` y el dial seleccionado usan geometría normalizada respecto de la imagen orientada. El técnico puede mover/redimensionar ambos y reanalizar la misma Evidence.
- Pueden existir uno o varios diales, pero el técnico selecciona exactamente uno. Las sugerencias automáticas, si existen, no se autoaceptan ni sobrescriben la geometría confirmada. Se conservan las escalas soportadas (`×1`, `×0.1`, `×0.01`, `×0.001`).
- Geometría, escala, cero, sentido y litros/vuelta confirmados en START se recuperan y reutilizan durante la Sample. Al alcanzar cada umbral planificado, INTERMEDIATE toma y persiste automáticamente una fotografía completa sin navegación ni obturador manual; no exige OCR perfecto. START conserva captura/configuración manual-first. FINAL se captura automáticamente al finalizar y solicita al técnico únicamente confirmar/corregir el análisis basado en la configuración START.
- Vista en vivo y estado de cámara.
- ROI/ajustes necesarios para lectura de carátula.
- Detección automática exclusivamente dentro del círculo. Requiere dominancia y cantidad roja suficientes, componente coherente con el eje, dirección radial, longitud y confianza mínimas; si falla: `Aguja no detectada`.
- OCR automático exclusivamente sobre el rectángulo elegido; números externos nunca son candidatos.
- El técnico confirma el número real de tambores. Si un tambor mecánico muestra simultáneamente dos dígitos consecutivos durante una transición (por ejemplo 2→3), la propuesta conserva el dígito anterior/visible en la parte superior y exige confirmación humana.
- Toda lectura automática exitosa se presenta al técnico para confirmación: `Lectura detectada: ... ¿Es correcta?`.
- Si OCR/aguja falla, se habilita captura manual de la lectura correspondiente.
- La confirmación/corrección es posible antes de cerrar la muestra.

## 5. Ejecución de muestra (`features/test_run`)
Estados mínimos: `draft → ready → running → awaiting_reading_confirmation → closed_valid | invalid_evidence`.

### Iniciar
- Preparación congela caudal mínimo/máximo del medidor de control para habilitar el inicio y K L/pulso independiente del medidor del hidrante.
- Después de confirmar Evidence INICIO, GPIO27 se observa solamente para estabilización: no incrementa Sample/Vref. `INICIAR PRUEBA` permanece verde pero deshabilitado hasta que el caudal calculado esté dentro del rango; dentro del rango el caudal se muestra verde y el botón se habilita.
- Al pulsar `INICIAR PRUEBA` se fijan baselines de ambos canales, comienza el registro, se oculta ese botón y aparece `FINALIZAR Y CONFIRMAR LECTURAS`.
- Captura GPS si es posible.
- Congela configuración de la muestra.
- Fija contador origen.
- Captura evidencia inicial obligatoria.
- Si la fotografía inicial falla, no inicia una muestra válida; informa y permite reintentar.

### Durante
- ESP32 mantiene dos canales: flujómetro 1 calibrado en GPIO27 es el patrón y única fuente de Vref; flujómetro 2 bajo prueba en GPIO25 es opcional/diagnóstico y puede permanecer en cero sin comprometer la muestra. Fotografías y lecturas visuales corresponden al flujómetro 2.
- En UI se denominan `medidor de control` y `medidor del hidrante`; el resumen no expone la etiqueta técnica `flujómetro 1 · GPIO27`.
- Debajo del título permanece fijo un panel con timestamp del primer pulso observado, acumulados oficiales, caudales calculados, V patrón y V hidrante. Un reloj de UI actualiza ambos caudales cada 500 ms como `pulsos observados × K / tiempo desde el primer pulso`, incluso sin pulsos nuevos, por lo que decaen hasta mostrarse como cero cuando se detiene el flujo. La observación es continua al cruzar INICIAR; los acumulados oficiales parten lógicamente de cero sin reiniciar el ESP32 ni el caudal mostrado. El encabezado muestra conexión ESP32, presencia del control remoto y confianza diagnóstica `max(0, (1 − 1/N) × 100)`, calculada exclusivamente con `N` pulsos observados del medidor de control; no participa en metrología ni veredicto. El panel mantiene siempre visible `FINALIZAR Y CONFIRMAR LECTURAS` una vez iniciada la medición.
- Controles Bluetooth de disparo que Android exponga como volumen arriba/abajo activan exclusivamente INICIAR o FINALIZAR según el estado. INICIAR conserva la compuerta de caudal; FINALIZAR exige medición iniciada y Vref positivo. No disparan fotografías ni otras acciones directamente.
- Indicadores: pulsos, V patrón, tiempo, incertidumbre estimada.
- Captura intermedia automática según paso (25 L default).
- INTERMEDIATE se limita a captura/persistencia de Evidence y no ejecuta OCR/aguja en el isolate de UI, evitando detener pulsos, volumen y método de la sección 4. La toma de FINAL tampoco muestra overlay; FINAL reutiliza y analiza automáticamente la configuración visual congelada en START y abre después su confirmación/corrección.
- Para BLE/LED, el enlace de contador se inicia después de confirmar la lectura START, no durante la selección/análisis de regiones, evitando que el trabajo visual compita con el establecimiento del enlace.
- Puede existir captura diagnóstica manual adicional.
- Si una evidencia intermedia obligatoria falla, la muestra queda `invalid_evidence`; el técnico debe repetir la prueba.

### Finalizar
- La acción táctil o remota congela inmediatamente el endpoint de pulsos/Vref antes de cualquier operación de cámara. Eventos posteriores se ignoran; callbacks ya serializados terminan antes de fijar el snapshot.
- La UI cambia inmediatamente a `FINALIZANDO…`. Evidencias intermedias faltantes, captura FINAL y análisis se completan después sin overlay global; al existir propuesta se abre confirmación/corrección.
- Captura final obligatoria.
- Si falla, marca `invalid_evidence` y ofrece repetir.
- Abre captura/confirmación de lecturas.
- Calcula solo cuando lecturas inicial/final estén confirmadas.

## 6. Registro (`features/registry`)
Tabla de puntos: tipo, timestamp local de captura, pulsos, V patrón, lectura, V mecánico, error diagnóstico y referencia a evidencia. START y FINAL muestran su lectura confirmada inmediatamente; INTERMEDIATE conserva guion porque su captura automática es Evidence transparente y no ejecuta lectura visual en primer plano.

El error de puntos es solo diagnóstico. El resultado oficial siempre es endpoint.

## 7. Cálculo y cierre (`features/readings_calc`)
- Presenta foto inicial/final.
- Propone odómetro vía OCR y aguja vía visión.
- Técnico confirma o corrige antes del cierre.
- Calcula V_ind, V_ref, error, U, MPE y regla de decisión según `METROLOGY_RULES.md`.
- Veredictos de muestra: `APRUEBA`, `RECHAZA`, `NO CONCLUYENTE`.
- Al cerrar, la muestra queda inmutable y se genera checksum.
- `NO CONCLUYENTE` solicita nueva muestra.

## 8. Expediente, caudales y muestras (`features/samples_report`)
- Un mismo medidor mantiene un expediente activo hasta `Terminar expediente`.
- Dentro del expediente se pueden agregar Q1/Q2/Q3/Q4.
- Cada caudal admite **muestras ilimitadas**.
- Acción principal tras cerrar una muestra: `Iniciar otra muestra` o `Cambiar caudal` o `Terminar expediente`.
- Para n≥3 en un caudal, muestra media, dispersión, s y criterio de repetibilidad.
- Al terminar expediente, calcula veredicto global.
- No se borran ni reescriben muestras cerradas.

## 9. Reporte de evidencia (`features/report`)
- HTML autocontenido, fiel en estructura/apariencia al reporte de referencia.
- Imágenes embebidas.
- Datos reales del expediente/muestras.
- Muestra regla metrológica, E, U, MPE y veredicto.
- Botón `Descargar PDF` dentro del reporte.
- Debe generarse offline.

## 10. Sincronización (`features/sync`)
- Todo se guarda primero en Drift/archivos locales.
- Al recuperar señal se suben usuarios necesarios, expediente, caudales, muestras, puntos y evidencias de manera idempotente.
- UI muestra estados: local/pending/syncing/synced/conflict/error.
- No se purgan automáticamente expedientes ni fotografías sincronizadas.

## 11. Ajustes
Configuración operativa con valores por defecto y validaciones:
- K L/pulso.
- Paso de evidencia.
- Volumen mínimo/máximo orientativo.
- Parámetros de cámara/LED.
- Incertidumbre base de lectura.

El MPE se deriva de la zona Q1-Q4; cualquier override excepcional debe quedar explícito y auditado, no oculto.
