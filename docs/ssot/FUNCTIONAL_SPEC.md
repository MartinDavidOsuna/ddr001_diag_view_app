# FUNCTIONAL_SPEC — Especificación funcional

## 0. Reglas generales
- Android portrait.
- UI fiel a `design/screenshots/`; no replicar controles del navegador.
- Offline-first.
- Muestras cerradas inmutables.
- El simulador web legado es únicamente una herramienta externa de validación y no se integra. **LECTURA VISUAL** es productiva y se utiliza con medidores reales; el modo **SIMULACIÓN** de QA es una fuente nueva, separada y siempre trazable.

## 1. Login persistente (`features/auth`)
- Campos, en orden: nombre, correo y teléfono. El nombre es obligatorio en la UI, admite Unicode y se persiste sin espacios exteriores.
- No hay contraseña ni pantalla de registro.
- La llave de identificación/autenticación sigue siendo `email + phone`; el nombre es únicamente perfil/identidad y no una tercera credencial.
- Primer login local: busca `email + phone`; si no existe, crea usuario automáticamente con `display_name`, sin conexión. Si un usuario local legado coincide y no tiene nombre, se completa sobre el mismo `user_id`; un nombre existente no se sobrescribe durante login.
- Guarda sesión y perfil local.
- Aperturas posteriores reutilizan sesión sin pedir login.
- Si está offline y existe sesión local válida, entra a la app normalmente.
- Única salida voluntaria: botón existente/definido **Cerrar sesión**.
- Las identidades documentadas de Martin Osuna (`martinosuna@agrienlace.com`), Rene (`renelopez@agrienlace.com`) y Omar (`omarpizano@aquafim.com`), todos con teléfono `9999999999`, conservan su normalización canónica. Todas las identidades válidas pueden crear una sesión local cuando el backend no está configurado.
- Login muestra la versión centrada al fondo con bajo contraste y no presenta leyendas sobre persistencia offline ni ausencia de contraseña.
- Login muestra la versión instalada. La identidad de producto se presenta como **VERIFICADOR FUNCIONAL** y el nombre Android es **AQ VF DDR001**.

## 2. Identificación (`features/identification`)
- ID/número de cuenta del medidor: texto libre, cualquier valor permitido.
- ID / banco de pruebas: obligatorio para identificar el banco físico utilizado y se congela en el expediente.
- Consulta opcional/automática de solo lectura al sistema de hidrantes cuando haya conectividad.
- Cuando la capability remota está configurada, estados visibles: consultando / localizado con datos previos / localizado sin levantamiento / no localizado-nuevo / error real. Sin configuración, la consulta se oculta y el ID continúa editable; no se presenta un pendiente ficticio al técnico.
- Si existe levantamiento previo, mostrar los datos disponibles sin obligar a que existan.
- Todo diagnóstico crea dos corridas obligatorias sin selector: `Q1 — Caudal operativo` y `Q2 — Caudal medio`, ambas con MPE ±2 %. Identificación no solicita ni persiste una estimación manual nueva; `lps_approx` queda nullable para compatibilidad histórica.
- GPS: latitud, longitud, precisión y timestamp. Si se pulsa CONTINUAR sin posición capturada, un modal exige confirmar `CONTINUAR SIN UBICACIÓN` o volver para capturarla. Aceptar avanza directamente y la ubicación permanece nullable.

## 3. Fuente / método de medición (`features/pulse_source`)
- El selector muestra BLUETOOTH, MANUAL, LECTURA VISUAL temporalmente deshabilitada y SIMULACIÓN. MANUAL es una fuente productiva de captura humana de pulsos, avanza sin hardware/BLE/backend y usa el mismo pipeline persistente que BLE; LED conserva su implementación interna pero no aparece en este selector. Elegir SIMULACIÓN evita scan/conexión BLE. Para BLUETOOTH, al entrar sin un módulo seleccionado se ejecuta un scan DDR001; exactamente un dispositivo compatible se selecciona automáticamente, mientras cero o varios conservan resolución manual. `BUSCAR ESP32` siempre ejecuta un scan nuevo y lista todos los candidatos válidos aunque ya exista conexión. Un candidato debe anunciar simultáneamente el prefijo y servicio DDR001 y validar por GATT la característica y payload del contador. `DESCONECTAR ESP32` es la única acción de usuario que destruye explícitamente el transporte BLE.
Modos productivos:
- **LECTURA VISUAL:** funcionalidad de campo para medidores reales. Utiliza cámara/visión sobre la carátula para obtener las lecturas visuales necesarias y determinar el avance del medidor durante la prueba. **No es un simulador.**
- **Manual:** botón de pulso; cada pulso suma `K` litros.
- MANUAL presenta un único botón `+1 PULSO` porque `pulseCount` es el único contador contractual que alimenta `Vref = N × K`. Cada tap aceptado se persiste inmediatamente mediante `PulseProgressService`; no hay decremento ni muestra, metrología, Evidence o reporte alternos.
- **LED ESP32:** cámara detecta el destello emitido por el ESP32 dentro de ROI configurable, con umbral/histéresis/anti-rebote; cada evento válido suma `K` litros.
- **BLE ESP32:** cada notificación/evento válido representa un pulso y suma `K` litros.
- **SIMULACIÓN:** fuente local de QA controlada por el operador. Produce un caudal fluctuante visible antes del inicio —Q1 entre 5 y 7 L/s, Q2 entre 2 y 3 L/s— y ningún cambio consecutivo supera 0.5 L/s. El operador inicia y finaliza; sólo dentro de esa frontera se acumulan tiempo, pulsos y Vref. Después captura lecturas manuales y usa el pipeline real de Sample, Evidence, cierre, metrología y reportes. Nunca fuerza el veredicto.
- El ESP32 DDR001 publica contador BLE v1 acumulativo. La app congela baseline, persiste el último contador y reconcilia saltos. Adquisición no verificable se marca `COMPROMISED` y no cierra válida.
- GPIO25/GPIO27 del firmware productivo usan el filtro de glitches PCNT y una segunda validación que exige LOW continuo mínimo 17 ms y rearme HIGH antes de incrementar o notificar. El nombre BLE contiene serie y versión bajo el prefijo contractual `DDR001-PULSE-`.
- La conexión BLE del ESP32 ejecuta keepalive leyendo el contador cada 10 s. Si no responde, intenta recuperar la conexión tres veces antes de declararlo no conectado; el contador acumulativo permite reconciliar el intervalo recuperado.
- El control remoto Bluetooth, expuesto por Android como dispositivo de entrada externo, se sondea cada 10 s. Tres verificaciones negativas consecutivas son necesarias para retirar su estado conectado y desarmarlo.
- Al crear una muestra BLE, la fuente se inicia antes de abrir Preparación de cámara. El transporte físico es independiente de la pantalla y de la Sample: navegar con Atrás, cambiar zoom, sugerir o fijar regiones y comenzar una verificación nueva no lo dispone ni lo vuelve a conectar. Las suscripciones de conteo sí se reasocian a la Sample activa.
- Un periférico ya conectado puede suspender advertising. El resultado de BUSCAR conserva y muestra el DDR001 activo validado por la fuente GATT, además de los nuevos anuncios encontrados. Lecturas keepalive con contadores sin cambio no emiten estado de aplicación; solo contadores nuevos actualizan persistencia/UI.

Manual, LED y BLE comparten una interfaz común de eventos de pulso. **LECTURA VISUAL** comparte el mismo dominio de muestra, evidencias y cálculo metrológico, pero su adquisición proviene de las lecturas visuales del medidor y no debe forzarse artificialmente a emitir pulsos.

El simulador web externo permanece sin cambios. El modo QA SIMULACIÓN no reutiliza ese HTML ni sustituye LECTURA VISUAL; se marca permanentemente `MODO SIMULACIÓN` y `PRUEBA SIMULADA — NO CORRESPONDE A UNA VERIFICACIÓN FÍSICA`.

### 3.1 Simulación controlada por operador
- El flujo inicia antes de la medición para representar la estabilización observable en campo. Esa previsualización no genera pulsos oficiales, no inicia el cronómetro y no modifica Vref.
- `INICIAR PRUEBA` fija el instante inicial y desde ese momento genera pulsos de acuerdo con el caudal mostrado. `FINALIZAR Y CONFIRMAR LECTURAS` fija el endpoint cuando lo decide el operador.
- Q1 fluctúa dentro de 5–7 L/s y Q2 dentro de 2–3 L/s. Entre dos actualizaciones consecutivas la variación absoluta es como máximo 0.5 L/s.
- START, INTERMEDIATE planificadas y FINAL usan un asset local almacenado como Evidence real y hasheado. Después de FINAL se presenta la misma captura manual de lecturas INICIO/FINAL; `Vind`, E, U, MPE y veredicto se calculan con el motor metrológico real.
- Una SIMULACIÓN DRAFT o RUNNING se recupera desde Drift sin duplicar Evidence ni fabricar pulsos durante el tiempo en que la app estuvo cerrada. Los escenarios históricos siguen siendo legibles.

## 4. Carátula y cámara (`features/camera_dial`)
- Antes del inicio se abre `PREPARACIÓN DE CÁMARA`. Las regiones se ajustan directamente sobre el preview vivo; no se toma ni conserva fotografía y no se crea Evidence ni lectura INICIO. Una verificación nueva hereda la última geometría confirmada y no ejecuta sugerencia automática; si no hay geometría previa se permite un intento inicial no vinculante. `NUEVA SUGERENCIA DE REGIONES` avanza por candidatos detectados distintos antes de repetirlos. No produce lecturas y la selección humana permanece como autoridad. La Evidence INICIO oficial se captura al accionar INICIAR con la configuración congelada.
- Un dedo desplaza la región activa y un gesto pinch la reduce o amplía dentro de la imagen. Los marcos no incluyen texto ni handles que oculten la carátula; el dial conserva una cruz `+` en su centro geométrico para alinear el eje. La lectura en vivo aplica provisionalmente el formato visible del totalizador para habilitar la segmentación de tambores, incluso antes de congelar la configuración.
- El preview conserva la relación de aspecto real de `CameraController`. Pinch/slider usan `minZoomLevel`, `maxZoomLevel` y `setZoomLevel`; el zoom se persiste en la Sample y se restaura para START, INTERMEDIATE, FINAL y recovery.
- Totalizador y dial se confirman de forma manual. La sugerencia geométrica inicial es opcional, no se autoacepta y no genera una lectura.
- El técnico puede pulsar **NUEVA SUGERENCIA DE REGIONES** cuantas veces necesite; cada intento usa un frame transitorio con el zoom actual y reemplaza únicamente las sugerencias de totalizador/diales. Las lupas izquierda/derecha disminuyen/aumentan zoom como botones, respetando los límites reportados por Android.
- Un toque sobre el preview fija el punto normalizado de enfoque y exposición de la cámara Android y muestra transitoriamente el indicador de enfoque.
- Durante una corrida la cámara permanece preparada entre capturas cuando el hardware lo permite. Cada cuatro segundos y justo antes de fotografiar se restauran zoom congelado, enfoque automático, exposición y último punto de enfoque. La Evidence guardada siempre es el cuadro completo; las regiones de totalizador/dial solo producen recortes derivados para captura manual.
- Después de `FIJAR REGIONES`, la tarjeta de fotografía se contrae para priorizar formato, escala y `ANALIZAR LECTURA`.
- La configuración visual se usa exclusivamente para recortar y presentar las regiones de la Evidence FINAL.
- FINAL reutiliza el formato congelado. Una inconsistencia o carácter ambiguo exige confirmación/corrección humana y no invalida una fotografía íntegra.
- El procedimiento conserva una Evidence completa por START, cada INTERMEDIATE planificada y FINAL; no existen fotos separadas para totalizador y aguja.
- `TotalizerRegion` y el dial seleccionado usan geometría normalizada respecto de la imagen orientada. El técnico puede mover/redimensionar ambos durante Preparación.
- `litersPerRevolution` es la escala canónica positiva del dial. Cámara lee exactamente el valor configurado en Preparación, admite escalas reales como 1000 L/vuelta y no lo reduce ni sobrescribe al entrar o volver; `multiplier` se conserva sólo como representación histórica derivada respecto de 100 L/vuelta.
- En captura manual, **Total del medidor (L)** es el acumulado general y no tiene un máximo asociado a una vuelta. Para LECTURA VISUAL/MANUAL/LED, **Posición de aguja dentro de la vuelta (L)** cumple `0 <= posición < litersPerRevolution`. En BLE y SIMULACIÓN el campo representa una lectura libre no negativa y no tiene máximo de 100 L ni de una vuelta; el resultado oficial sigue usando los totales del medidor.
- Pueden existir uno o varios diales, pero el técnico selecciona exactamente uno. Las sugerencias automáticas, si existen, no se autoaceptan ni sobrescriben la geometría confirmada. Se conservan las escalas soportadas (`×1`, `×0.1`, `×0.01`, `×0.001`).
- Geometría y zoom se recuperan y reutilizan durante la Sample. INTERMEDIATE toma y persiste automáticamente una fotografía completa. INICIO no interrumpe la corrida para pedir valores. Tras capturar FINAL, **CAPTURAR LECTURAS** presenta primero los crops y valores manuales de INICIO y después los de FINAL. En cada endpoint se registran totalizador, aguja y total del medidor; `Vind = total FINAL − total INICIO`.
- Vista en vivo y estado de cámara.
- ROI/ajustes necesarios para lectura de carátula.
- Detección automática exclusivamente dentro del círculo. Requiere dominancia y cantidad roja suficientes, componente coherente con el eje, dirección radial, longitud y confianza mínimas; si falla: `Aguja no detectada`.
- No existe lectura automática productiva de las regiones.
- El técnico confirma el número real de tambores. Si un tambor mecánico muestra simultáneamente dos dígitos consecutivos durante una transición (por ejemplo 2→3), la propuesta conserva el dígito anterior/visible en la parte superior y exige confirmación humana.
- Toda lectura automática exitosa se presenta al técnico para confirmación: `Lectura detectada: ... ¿Es correcta?`.
- La captura de lectura FINAL siempre es manual.
- La confirmación/corrección es posible antes de cerrar la muestra.

## 5. Ejecución de muestra (`features/test_run`)
Estados mínimos: `draft → ready → running → awaiting_reading_confirmation → closed_valid | invalid_evidence`.

### Iniciar
- Preparación congela caudal mínimo/máximo del medidor de control para habilitar el inicio y K L/pulso independiente del medidor del hidrante.
- Después de confirmar Evidence INICIO, GPIO27 se observa solamente para estabilización: no incrementa Sample/Vref. `INICIAR PRUEBA` permanece verde pero deshabilitado hasta que el caudal calculado esté dentro del rango; dentro del rango el caudal se muestra verde y el botón se habilita.
- Al pulsar `INICIAR PRUEBA` se fijan baselines de ambos canales, comienza el registro, se oculta ese botón y aparece `FINALIZAR Y CONFIRMAR LECTURAS`.
- En SIMULACIÓN, el caudal ya fluctúa antes de INICIAR, pero la frontera oficial de tiempo, pulsos y Vref se fija exactamente con esa acción.
- Captura GPS si es posible.
- Congela configuración de la muestra.
- Fija contador origen.
- Captura evidencia inicial obligatoria.
- Si la fotografía inicial falla, no inicia una muestra válida; informa y permite reintentar.

### Durante
- ESP32 mantiene dos canales: flujómetro 1 calibrado en GPIO27 es el patrón y única fuente de Vref; flujómetro 2 bajo prueba en GPIO25 es opcional/diagnóstico y puede permanecer en cero sin comprometer la muestra. Fotografías y lecturas visuales corresponden al flujómetro 2.
- En UI se denominan `medidor de control` y `medidor del hidrante`; el resumen no expone la etiqueta técnica `flujómetro 1 · GPIO27`.
- Debajo del título permanece fijo un panel con timestamp del primer pulso observado, acumulados oficiales, caudales calculados, V patrón y V hidrante. Un reloj de UI actualiza ambos caudales cada 500 ms. Desde INICIAR y hasta 10 pulsos usa todos los pulsos de la muestra; a partir del pulso 11 usa una ventana móvil de los últimos 10 pulsos de cada origen. Si el flujo se detiene, el denominador continúa creciendo y el valor decae. Capturar una evidencia nunca congela ni revierte los acumulados del panel. La observación es continua al cruzar INICIAR; los acumulados oficiales parten lógicamente de cero sin reiniciar el ESP32. El encabezado muestra conexión ESP32, presencia del control remoto y confianza diagnóstica `max(0, (1 − 1/N) × 100)`, calculada exclusivamente con `N` pulsos observados del medidor de control; no participa en metrología ni veredicto. El panel mantiene siempre visible `FINALIZAR Y CONFIRMAR LECTURAS` una vez iniciada la medición.
- El rango de caudal habilita exclusivamente INICIAR. Una vez iniciada, la corrida no vuelve al estado previo ni se detiene por caída de caudal o ausencia de pulsos; continúa acumulando tiempo hasta la finalización explícita del operador. El caudal previo del hidrante se muestra desde que GPIO25 tiene pulsos observados.
- Q2 y las repeticiones crean directamente la siguiente Sample RUNNING y abren Prueba en curso con su FlowPoint. Reutilizan la geometría y zoom definidos en la primera preparación de cámara; no vuelven a solicitarla.
- La pantalla Prueba en curso no ofrece captura manual de puntos diagnósticos.
- Controles Bluetooth de disparo que Android exponga como volumen arriba/abajo activan exclusivamente INICIAR o FINALIZAR según el estado. INICIAR conserva la compuerta de caudal; FINALIZAR exige medición iniciada y Vref positivo. No disparan fotografías ni otras acciones directamente.
- Al pulsar FINALIZAR se congelan timestamp, contadores y Vref antes de cualquier operación de cámara. Se desasocian las entradas GPIO27/GPIO25/LED de la Sample manteniendo vivo el transporte BLE, y FINAL se captura como primera acción sin completar intermedias omitidas. Pulsos posteriores no modifican el endpoint ni el formulario.
- Tras persistir FINAL, `CAPTURAR LECTURAS` es una fase post-adquisición: puede permanecer abierta indefinidamente y solo usa Sample, START y FINAL persistidos. Keepalive, cambios de estado BLE, pulsos y callbacks tardíos de cámara no modifican ni invalidan el formulario; `GUARDAR Y CALCULAR RESULTADO` enlaza las lecturas a las evidencias persistidas y no a estado transitorio de cámara.
- Indicadores: pulsos, V patrón, tiempo, incertidumbre estimada.
- Captura intermedia automática según paso (25 L default).
- INTERMEDIATE se limita a captura/persistencia de Evidence. FINAL tampoco muestra overlay: congela el endpoint, toma la fotografía y abre la captura manual usando los crops configurados.
- Para BLE/LED, el enlace físico del contador se inicia antes de Preparación de cámara y se conserva al fijar regiones; INICIO no requiere confirmación de lectura.
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
La vista portrait usa cuatro columnas: PUNTO con `HH:mm:ss`; PULSOS/PATRÓN; LECTURA L/V.MEC L; ERROR %. La fecha aparece una vez junto al título. En esta tabla únicamente, `V.MEC L` significa el snapshot real de pulsos GPIO25 del medidor del hidrante. Sin pulsos del hidrante, Lectura L, V.MEC L y Error % quedan vacíos; no se fabrica un cero ni se altera ninguna fórmula metrológica.

## 6.1 Navegación del workflow
Android Back, gesto desde borde y flecha de la app regresan al paso inmediatamente anterior y conservan el expediente/Sample RUNNING. Home requiere una acción explícita. Los borradores editables conservan identificación y configuración; una Sample `CLOSED_VALID` permanece inmutable.

El error de puntos es solo diagnóstico. El resultado oficial siempre es endpoint.

## 7. Cálculo y cierre (`features/readings_calc`)
- Presenta los recortes inicial/final y permite abrir la carátula completa en un modal con zoom, cierre por cruz, toque exterior o deslizamiento a la izquierda.
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
- Las pruebas se ordenan por fecha/hora de creación, no por IDs internos. Cada encabezado de prueba presenta su fecha y las filas presentan únicamente la hora local bajo `Tiempo`.
- Toda etiqueta visible usa español. No se presentan el número interno de expediente ni un sello DDR001.
- `V.MEC L` se deriva del snapshot GPIO25 multiplicado por su K congelada. Cada prueba incluye caudal puntual mínimo, máximo y promedio calculado únicamente con INICIO, evidencias INTERMEDIAS y FINAL que tengan `flow_lps`.
- El ID del banco es visible. La identidad técnica del teléfono queda dentro de los datos del expediente/exporte estructurado, pero no se presenta en HTML/PDF; Ajustes la muestra antes de la versión para inspección local.
- El reporte presenta configuración metrológica congelada, identidad/protocolo ESP32 y repetibilidad por caudal. Cuando hay GPS incluye un mapa autocontenido con el punto y un enlace opcional a un mapa detallado; sin GPS declara que la ubicación no fue registrada.
- El resumen local de cada prueba finalizada permite desplegar integridad de adquisición, endpoints y duración, contadores, trazabilidad de cada evidencia con su integridad y configuración exacta de zoom/regiones. Esta información técnica local no recarga el reporte entregable.
- Debe generarse offline.
- Toda selección que contenga una Sample simulada identifica `is_simulation` y `simulation_scenario` en CSV/JSON y muestra una advertencia no física en HTML/PDF. Las muestras reales conservan sus contratos y presentación sin esa marca.

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
