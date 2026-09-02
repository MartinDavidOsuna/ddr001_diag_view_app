# Manual de uso — AQ VF DDR001 · Verificador Funcional

**Versión del manual:** 1.2
**Última actualización del contenido:** 1 de septiembre de 2026

Inicio y Ajustes muestran por separado la versión instalada de la aplicación con el formato `Versión: #.#.#+##`. Este manual es la fuente canónica del procedimiento visible para el técnico y funciona completamente sin internet.

## Índice

1. Propósito de la aplicación
2. Inicio de sesión
3. Pantalla de inicio
4. Identificación del medidor
5. GPS
6. Métodos de medición
6.1 Modo SIMULACIÓN para QA
7. Método MANUAL
8. Método BLUETOOTH
9. Método LED
10. LECTURA VISUAL
11. Preparación de la prueba
12. Paso de evidencia
13. Captura START
14. Selección del totalizador
15. Formato del totalizador
16. Selección del dial
17. Aguja
18. Fotografías INTERMEDIATE
19. Captura FINAL
20. Registro
21. Resultado
22. Muestras
23. Expediente
24. Evidencia inválida
25. Adquisición comprometida
26. Reportes y exportes
27. Historial
28. Recuperación
29. Funcionamiento offline
30. Sincronización
31. Ajustes
32. Permisos Android
33. Resolución de problemas
34. Buenas prácticas en campo
35. Glosario

## 1. Propósito de la aplicación

DDR001 permite documentar la verificación de un medidor de agua desde la identificación hasta el resultado. Registra al operador, medidor, caudal, método, pulsos o volumen de referencia, lecturas, fotografías, puntos diagnósticos y resultado metrológico.

La aplicación conserva los datos localmente, admite varias muestras y caudales dentro de un expediente y genera CSV, JSON, evidencia HTML autocontenida y PDF. Las fórmulas se ejecutan en el motor metrológico de la aplicación; las cifras de una plantilla o reporte de ejemplo nunca sustituyen ese cálculo.

## 2. Inicio de sesión

El primer acceso solicita **Nombre**, **Correo** y **Teléfono**. Correo y teléfono forman la llave de identidad; no existe contraseña. El nombre identifica al operador y aparece en el expediente y reporte.

El primer acceso crea la identidad y la sesión en el dispositivo sin requerir backend ni conexión. La sesión permanece hasta pulsar **CERRAR SESIÓN** en Ajustes. Cerrar sesión no elimina expedientes, muestras ni fotografías locales.

Las identidades canónicas de **Martin Osuna** (`martinosuna@agrienlace.com`), **Rene** (`renelopez@agrienlace.com`) y **Omar** (`omarpizano@aquafim.com`), todas con teléfono **9999999999**, conservan su normalización documentada. No son requisito para el acceso local. La versión instalada se muestra discretamente al fondo.

## 3. Pantalla de inicio

- **NUEVA VERIFICACIÓN:** inicia la identificación de un medidor.
- **HISTORIAL LOCAL:** muestra expedientes guardados en el dispositivo.
- **Ajustes:** abre identidad, parámetros para nuevas muestras, Manual de uso y cierre de sesión.
- Si existe una Sample `RUNNING`, al abrir la app se ofrece **REANUDAR PRUEBA**. Ir al inicio no descarta esa prueba.

## 4. Identificación del medidor

Capture el **ID / número de cuenta del medidor** y el **ID / banco de pruebas** físico utilizado. El banco queda congelado en el expediente y aparece en el reporte.

Capture el **ID o número de cuenta**. Cualquier ID es válido para continuar. Cuando la consulta externa esté configurada, la aplicación puede informar si la cuenta está localizada con levantamiento, localizada sin levantamiento o no localizada/nueva. La consulta nunca bloquea la verificación y no escribe en el sistema de hidrantes.

Seleccione el caudal:

- **Q1 — Caudal operativo:** corrida obligatoria con MPE ±2 %.
- **Q2 — Caudal medio:** corrida obligatoria con MPE ±2 %.
- **Q3:** caudal permanente.
- **Q4:** caudal de sobrecarga.

Identificación ya no solicita un LPS aproximado. El caudal se calcula durante la prueba desde el primer pulso y se registra al tomar INICIO, cada fotografía INTERMEDIA y FINAL.

## 5. GPS

Pulse el icono **Obtener ubicación GPS** en Identificación. La pantalla muestra latitud, longitud y precisión aproximada `±N m`. La captura usa la ubicación de alta precisión del teléfono y registra timestamp. Si pulsa **CONTINUAR** sin ubicación, confirme **CONTINUAR SIN UBICACIÓN** para avanzar o vuelva a capturarla.

GPS no necesita internet ni servidor. Android puede solicitar permiso. Si el permiso se deniega, se deniega permanentemente, los servicios están apagados o ocurre timeout, aparece un mensaje claro y la prueba puede continuar sin coordenadas. Al pulsar **INICIAR PRUEBA**, la aplicación vuelve a intentar GPS si todavía no existe una posición.

Nunca se inventan coordenadas. Este procedimiento usa GPS del dispositivo; no agrega un diagnóstico GPRS o celular.

## 6. Métodos de medición

- **LECTURA VISUAL:** lectura productiva de un medidor real mediante fotografías y confirmación humana.
- **MANUAL:** cada pulsación del botón representa un pulso.
- **LED:** la cámara cuenta destellos del LED integrado del ESP32.
- **BLUETOOTH:** obtiene el contador acumulativo del ESP32 mediante BLE.
- **SIMULACIÓN:** ejecuta una prueba local de QA sin medidor, cámara, Bluetooth, ESP32, backend ni Internet. Siempre queda marcada como no física.

MANUAL, LED y BLUETOOTH convierten pulsos a volumen patrón con `Vref = pulsos × K`. LECTURA VISUAL registra su referencia explícita sin fabricar pulsos.

### 6.1 Modo SIMULACIÓN para QA

Seleccione **SIMULACIÓN** en Método de prueba y elija uno de estos escenarios:

- **Prueba exitosa:** el motor metrológico real determina APRUEBA.
- **Prueba fallida:** el motor metrológico real determina RECHAZA.
- **Mixta: primera muestra falla / segunda aprueba:** conserva la primera muestra RECHAZA y crea una segunda muestra APRUEBA.

La pantalla muestra **MODO SIMULACIÓN** durante el flujo. La adquisición avanza de forma acelerada para poder observar Prueba en curso y genera START, fotografías INTERMEDIATE planificadas y FINAL. Las imágenes llevan la leyenda **EVIDENCIA DE SIMULACIÓN** y se almacenan como Evidence reales con checksum.

SIMULACIÓN no fuerza un resultado ni crea un reporte prefabricado: genera Vref/Vind coherentes con el Q seleccionado y utiliza las fórmulas, incertidumbre, MPE, banda de guarda, persistencia, Historial y exportadores vigentes. No use una simulación como constancia de una verificación física.

## 7. Método MANUAL

Seleccione **MANUAL** sin conectar Bluetooth o ESP32 y configure **K en L/pulso**. Durante la prueba, cada acción sobre el único botón **+1 PULSO** representa exactamente un pulso real y aumenta el contador una unidad. Espere a que el botón vuelva a habilitarse antes del siguiente tap. El volumen patrón mostrado se obtiene multiplicando el contador por K y cada incremento queda persistido para recovery.

No pulse varias veces por un único evento ni omita eventos físicos. Los puntos del registro se generan mediante las evidencias obligatorias de la corrida.

## 8. Método BLUETOOTH

El ESP32 DDR001 recibe el dummy/sensor en GPIO27 y publica un contador acumulativo BLE. En la preparación:

1. Pulse buscar.
2. Seleccione el dispositivo DDR001.
3. Espere el estado **READY**.
4. Inicie la prueba para congelar el contador inicial y K.

La aplicación concilia los incrementos del contador y conserva el último valor observado para recovery. Una reconexión válida incorpora el delta acumulado. Un rollback o intervalo que no puede conciliarse marca la adquisición `COMPROMISED`; esa muestra no puede cerrar como válida.

Durante la corrida, la app lee el contador cada 10 segundos como keepalive. Si el ESP32 no responde, realiza tres intentos de recuperación antes de mostrarlo desconectado. El control remoto Bluetooth también se verifica cada 10 segundos y solo se desarma después de tres verificaciones negativas.

La conexión se conserva al moverse con Atrás entre **FUENTE / MÉTODO**, **PREPARACIÓN** y **PREPARACIÓN DE CÁMARA**, al fijar regiones y al comenzar otra verificación. En **FUENTE / MÉTODO**, **DESCONECTAR ESP32** es la única acción que fuerza la desconexión. **BUSCAR ESP32** repite siempre la búsqueda y lista todos los equipos que validan el contrato DDR001 real; un nombre parecido sin servicio, característica y contador compatibles no aparece.

Un ESP32 conectado puede dejar de anunciarse temporalmente. Si la app continúa leyendo su contador por GATT, **BUSCAR ESP32** lo conserva en la lista como conectado y agrega los demás módulos cercanos encontrados; la ausencia de advertising no se interpreta por sí sola como desconexión.

## 9. Método LED

LED utiliza el LED integrado GPIO2 del ESP32. La cámara observa una ROI, obtiene baseline de brillo y cuenta el flanco **DARK → BRIGHT** con histéresis y anti-rebote. Un destello válido equivale a un pulso y suma K litros.

El contador BLE acumulativo se usa como canal auxiliar de conciliación. Al tomar una fotografía de evidencia, la aplicación coordina la cámara y concilia lo ocurrido; no simula continuidad. Mantenga el LED dentro de la ROI y evite reflejos directos. Si el conteo óptico y el contador físico no pueden reconciliarse, la integridad queda comprometida y debe repetirse la muestra.

## 10. LECTURA VISUAL

LECTURA VISUAL **no es simulación**. Se aplica a medidores reales. El técnico fija en la cámara las regiones del totalizador y del dial. La app no interpreta esas imágenes mediante OCR ni detección automática: al finalizar presenta ambos recortes como referencia y el técnico captura manualmente los valores.

El simulador web es una herramienta externa de validación y no forma parte de la app productiva.

## 11. Preparación de la prueba

La ficha **CONFIGURACIÓN** muestra Q1/Q2 como caudales calculados y los valores K para ambas corridas. K ya no se captura en esta pantalla. Aquí se configuran la escala del odómetro en L/unidad, la escala real de la aguja en L/vuelta (por ejemplo, 1000 L/vuelta), la cantidad de enteros y entre cero y tres decimales; estos valores quedan congelados en la corrida y Cámara debe conservarlos sin reducirlos. El selector productivo muestra BLUETOOTH, MANUAL, SIMULACIÓN y LECTURA VISUAL visible pero no seleccionable temporalmente. MANUAL permite **CONFIGURAR PRUEBA** sin hardware. Para BLUETOOTH, al entrar la app busca un ESP32 DDR001 y selecciona automáticamente solo cuando encuentra exactamente uno. El botón de búsqueda siempre ejecuta un scan nuevo y actualiza la lista aun cuando exista conexión; BLUETOOTH se habilita cuando el ESP32 llega a READY.

En **PREPARACIÓN DE CÁMARA**, las lupas de los extremos disminuyen o aumentan el zoom y el slider permite ajuste continuo. Después de cambiar zoom, pulse **NUEVA SUGERENCIA DE REGIONES** para volver a detectar y reposicionar totalizador y diales con el encuadre actual. Las sugerencias siguen siendo opcionales y ajustables manualmente.

Revise antes de iniciar:

- método y caudal;
- K para métodos de pulso;
- **Vmín** y **Vmáx** orientativos;
- incertidumbre de lectura;
- **Paso de evidencia**;
- ESP32 seleccionado y READY cuando aplique.

Estos valores quedan congelados en la Sample. Cambiar Ajustes después no altera una muestra iniciada ni una muestra cerrada.

## 12. Paso de evidencia

El Paso de evidencia indica cada cuántos litros se exige una foto intermedia. No es K, resolución, MPE ni intervalo de cálculo.

Ejemplo con paso de **25 L** y final de 100 L:

- START en 0 L;
- INTERMEDIATE en 25 L;
- INTERMEDIATE en 50 L;
- INTERMEDIATE en 75 L;
- FINAL en 100 L.

Si FINAL coincide con un múltiplo, existe una sola FINAL en ese volumen. Cada Evidence es una fotografía completa.

## 13. Captura START

Antes de START se abre **PREPARACIÓN DE CÁMARA**. Las guías se ajustan directamente sobre el preview en tiempo real: esta etapa no toma ni guarda una fotografía y no crea Evidence ni lectura inicial. El técnico coloca el rectángulo sobre el totalizador y el círculo sobre el dial que desea consultar. La app no intenta leer sus valores en esta etapa. La Evidence INICIO real se toma al pulsar **INICIAR PRUEBA**, usando el mismo zoom y geometría; INTERMEDIATE y FINAL restauran esos valores.

1. Encuadre la carátula en **PREPARACIÓN DE CÁMARA**.
2. Seleccione manualmente la región del totalizador.
3. Seleccione manualmente el dial que utilizará.
4. Fije las regiones. La app conserva las últimas posiciones confirmadas para una verificación nueva. Solo propone posiciones automáticamente si todavía no existe una configuración anterior; use **NUEVA SUGERENCIA DE REGIONES** para recorrer objetos detectados distintos después de cambiar encuadre o zoom.
5. Inicie la prueba cuando se habilite la acción.
6. La app toma automáticamente la fotografía INICIO sin interrumpir la corrida. Sus valores se capturan después, junto con FINAL.

Al pulsar **FIJAR REGIONES**, la geometría queda preparada para los recortes que se presentarán al finalizar.

Durante la preparación y la prueba, un panel permanece fijo debajo del título. Muestra la hora del primer pulso recibido, pulsos acumulados, volumen patrón y los caudales en L/s con dos decimales. Se refresca cada medio segundo: al iniciar usa todos los pulsos disponibles de la muestra y, después de 10, calcula cada origen con sus últimos 10 pulsos. Por eso continúa cambiando aunque no llegue otro pulso y, si el flujo se detiene, disminuye progresivamente. Tomar una fotografía de evidencia no congela ni devuelve los pulsos visibles a un valor anterior. El botón **FINALIZAR Y CONFIRMAR LECTURAS** permanece dentro de ese panel aunque se desplace el registro.

El ESP32 recibe dos señales distintas. El **medidor de control** conectado a GPIO27 es el equipo con calibración probada: sus pulsos determinan Vref y el caudal patrón. El **medidor del hidrante** conectado a GPIO25 es el equipo que se está verificando y fotografiando. Sus pulsos son solamente diagnósticos; puede mostrar cero durante toda la prueba cuando ese medidor no disponga de salida de pulsos, sin invalidar la adquisición patrón.

El porcentaje de confianza del encabezado se calcula con los pulsos del **medidor de control**, nunca con los pulsos opcionales del hidrante. Expresa la resolución relativa del conteo patrón observado. Un pulso es la unidad mínima observable. Para `N` pulsos de control se calcula `Confianza = max(0, (1 − 1/N) × 100)`. Con un pulso la confianza es 0 %, con 10 pulsos es 90 % y aumenta hacia 100 % conforme crece el conteo. Se muestra blanco en 0 %, verde desde 97 % y rojo por debajo de 97 %. Es un indicador diagnóstico de resolución; no modifica Vref, el error metrológico, la incertidumbre, el MPE ni el veredicto.

Puede utilizarse un control Bluetooth de disparo fotográfico que Android presente como teclas de volumen. En **Prueba en curso**, cualquiera de sus botones ejecuta únicamente la acción principal disponible: inicia cuando el caudal de control cumple el intervalo configurado, o finaliza cuando la prueba ya inició y existe volumen patrón. El control no toma fotografías directamente, no captura puntos intermedios y no ejecuta otras funciones. Sin control asociado, utilice normalmente los botones de la pantalla.

Android puede mostrar el evento como **Volumen arriba** o **Volumen abajo**. Esto es normal: durante **Prueba en curso** la aplicación intercepta ese evento antes de que cambie el volumen y lo convierte en la acción habilitada. Fuera de esa pantalla, las teclas conservan su comportamiento normal.

En Preparación configure el caudal mínimo y máximo permitido para iniciar, además de cuántos litros representa cada pulso del **medidor del hidrante**. Antes de INICIAR, la app observa continuamente ambos canales y muestra también el caudal calculado del hidrante cuando recibe pulsos, mientras los acumulados oficiales permanecen en cero. El botón verde **INICIAR PRUEBA** se habilita únicamente cuando el caudal de control está dentro del rango. Al pulsarlo se toman bases lógicas sin reiniciar el ESP32: desde ese instante comienzan los acumulados oficiales y aparece **FINALIZAR Y CONFIRMAR LECTURAS**. El rango solo controla el inicio; después, una caída de caudal o ausencia temporal de pulsos no reinicia ni detiene la prueba. La corrida continúa midiendo tiempo hasta que el operador la finaliza expresamente.

En el extremo superior derecho, el icono Bluetooth y el texto **ESP32** son verdes cuando existe conexión y rojos cuando no existe. El icono del control remoto permanece gris hasta habilitarlo: la primera pulsación abre **Control conectado** y una segunda pulsación, o tocar **ACEPTAR**, lo habilita y cambia el icono a verde. Esta confirmación evita iniciar accidentalmente por pulsaciones repetidas durante la preparación. En el resumen, **V hidrante** es el acumulado oficial de pulsos GPIO25 multiplicado por el valor configurado de cada pulso del medidor del hidrante. El nombre del medidor y su renglón Q/caudal/K aparecen dentro del resumen, antes del estado de inicio.

La foto original se conserva intacta con su SHA-256; rectángulo y círculo producen solamente recortes derivados para consulta visual.

## 14. Selección del totalizador

Pulse **EDITAR REGIONES** para entrar al modo de edición fijo. En este modo la pantalla no se desplaza: mueva el rectángulo ámbar con un dedo hasta incluir **únicamente los dígitos del totalizador**. Junte dos dedos sobre el rectángulo para reducirlo y sepárelos para ampliarlo. Puede colocarlo arriba, abajo, al centro, a la izquierda o a la derecha según la marca del medidor. Pulse **FIJAR REGIONES** para guardar la geometría.

Use el selector **TOTALIZADOR / DIAL** para indicar qué guía está editando. Así, aunque ambas regiones se superpongan, solamente se moverá o redimensionará la elegida.

No incluya año, número de serie, Q3, R160, marca, modelo u otros números. Al finalizar, solo esta región se presenta ampliada para que el técnico capture el valor.

## 15. Formato del totalizador

Al finalizar, observe el recorte y capture manualmente el valor del totalizador. Cuente todos los tambores visibles, incluidos los ceros iniciales, y aplique los decimales de la carátula. Si un tambor está en transición, interprete la lectura física siguiendo el procedimiento de campo aplicable; la app no propone ni corrige el dígito.

## 16. Selección del dial

Un medidor puede tener uno, dos, tres, cuatro o más diales. Mueva el círculo verde con un dedo sobre **un solo dial**: el que se utilizará para la lectura fina. Junte dos dedos para reducir el círculo o sepárelos para ampliarlo y confirme su escala.

Seleccione el dial de **mayor resolución metrológica**, es decir, el que represente la menor cantidad de volumen por división o vuelta entre los diales disponibles para esa lectura. No significa el círculo físicamente más grande, la aguja más larga, el dial con más píxeles ni el más nítido. La app no decide automáticamente entre los diales.

## 17. Aguja

Al finalizar, la app presenta el recorte del dial seleccionado. Observe directamente la posición de la aguja y capture manualmente su valor dentro de una sola vuelta, en litros; debe ser menor que la escala L/vuelta. **Total del medidor (L)** es un dato distinto: representa el acumulado general y puede superar libremente una vuelta. La app no busca color, calcula ángulos ni propone una lectura automática.

## 18. Fotografías INTERMEDIATE

INTERMEDIATE aparece según el plan de evidencia. Al alcanzar cada umbral, la aplicación toma automáticamente una fotografía completa con la cámara y la guarda como Evidence: el técnico no pulsa un obturador ni abandona la pantalla de prueba. Mantenga la carátula encuadrada y visible mientras avanza el volumen. Es evidencia obligatoria y alimenta el registro diagnóstico, pero no sustituye el cálculo oficial START→FINAL. No exige OCR perfecto ni una confirmación exhaustiva en cada punto.

La captura y persistencia se ejecutan transparentemente: no aparece un indicador de progreso que cubra la pantalla y las lecturas en vivo continúan visibles y actualizándose. Para no congelar el contador, INTERMEDIO no ejecuta OCR ni análisis de aguja en primer plano; por eso sus columnas de lectura diagnóstica pueden mostrar `—`.

En MANUAL, LED y BLUETOOTH la app abre automáticamente la captura al alcanzar cada umbral. FINAL permanece bloqueada si falta alguna fotografía INTERMEDIATE exigida.

## 19. Captura FINAL

Al pulsar **FINALIZAR Y CONFIRMAR LECTURAS**, la app congela inmediatamente el conteo y Vref y desasocia los canales de la muestra: ningún pulso posterior cambia el endpoint. FINAL es la primera fotografía posterior al botón; no se toman evidencias intermedias atrasadas durante el cierre. Después abre **CAPTURAR LECTURAS**: primero muestra totalizador y dial de INICIO y solicita totalizador, aguja y total del medidor; enseguida muestra los mismos elementos y campos de FINAL.

Puede permanecer en **CAPTURAR LECTURAS** el tiempo necesario. La prueba ya terminó: la app calcula con las evidencias INICIO/FINAL guardadas e ignora pulsos, cambios de Bluetooth y respuestas tardías de la cámara. **GUARDAR Y CALCULAR RESULTADO** no requiere una captura activa.

En Preparación de cámara, toque el punto de la imagen que desea enfocar; el indicador amarillo marca temporalmente el punto de enfoque y exposición. Durante la corrida la app conserva la cámara preparada, restaura periódicamente el enfoque y vuelve a validar enfoque y zoom antes de cada foto. La fotografía guardada siempre contiene la carátula completa: los recuadros únicamente recortan totalizador y dial para mostrarlos ampliados en el formulario. Toque cualquiera de esos recortes para abrir la fotografía completa. Puede ampliarla con dos dedos. Cierre con la cruz, tocando fuera de la imagen o deslizando hacia la izquierda. INICIO y FINAL utilizan exactamente las regiones y el zoom congelados en la primera preparación de cámara; Q2 y las repeticiones no vuelven a buscar ni desplazan esas regiones.

Los valores de INICIO se solicitan al cierre, no durante el arranque. `Vind` es la diferencia entre el total manual FINAL y el total manual INICIO. Las fotografías originales no se alteran.

## 20. Registro

La fecha aparece una vez junto a **5 · REGISTRO**. La tabla portrait usa cuatro columnas: punto/hora, pulsos/patrón, lectura/V.mec y Error %. En esta tabla, **V.mec L** representa el snapshot de pulsos GPIO25 del medidor del hidrante. Si el punto no tiene pulsos del hidrante, Lectura L, V.mec L y Error % permanecen vacíos. Esta etiqueta visual no modifica Vind ni el cálculo endpoint.

- **Punto:** START, INTERMEDIATE, FINAL o punto manual diagnóstico.
- **Fecha / hora:** timestamp local de la Evidence correspondiente.
- **Pulsos:** contador cuando el método usa pulsos.
- **V patrón:** volumen de referencia del punto.
- **Lectura:** lectura observada del medidor.
- **V mecánico:** avance indicado/diagnóstico disponible.
- **Error diagnóstico:** comparación del punto; no es el error oficial.

`Lectura L` se completa en FINAL con el valor capturado manualmente. START e INTERMEDIATE pueden mostrar `—` porque no requieren lectura; el guion no significa que falte la fotografía.

El resultado oficial compara Vref con `Vind = total FINAL − total INICIO`. El botón Atrás, el gesto desde el borde y la flecha regresan al paso anterior conservando el diagnóstico editable o RUNNING; salir a Inicio continúa siendo una acción explícita. Una muestra cerrada permanece inmutable.

## 21. Resultado

- **Vref:** volumen patrón.
- **Vind:** avance indicado por el medidor.
- **Error E:** diferencia porcentual respecto de Vref.
- **U:** incertidumbre porcentual.
- **MPE:** error máximo permisible del caudal.

La regla vigente es:

- **APRUEBA:** `|E| + U ≤ MPE`.
- **RECHAZA:** `|E| − U > MPE`.
- **NO CONCLUYENTE:** el intervalo cruza el límite; realice otra muestra.

Los valores se calculan completos; el redondeo mostrado no interviene en la decisión.

## 22. Muestras

Después de Q1 puede **REPETIR PRUEBA Q1** o **COMENZAR Q2**. Ambas acciones crean la siguiente corrida y abren directamente **Prueba en curso** con la configuración Q correspondiente. Las regiones y el zoom de cámara se definen una sola vez y se reutilizan en Q2 y en todas las repeticiones. Después de Q2 puede repetir Q2. Las muestras anteriores se conservan. Si solo existe una corrida del caudal se identifica como `Q1` o `Q2`; al repetir se muestran `Q1-1`, `Q1-2`, … o `Q2-1`, `Q2-2`, ….

Con tres o más muestras se muestran n, media, mínimo, máximo, dispersión, desviación estándar y repetibilidad. Con menos de tres, la repetibilidad es **No evaluable**.

## 23. Expediente

El expediente agrupa un medidor, sus caudales y muestras. **TERMINAR EXPEDIENTE** calcula el veredicto global conforme a los caudales realmente requeridos/evaluados. Un expediente cerrado queda de solo lectura. Una muestra `CLOSED_VALID` tampoco se edita; una corrección requiere una nueva muestra.

## 24. Evidencia inválida

Una foto obligatoria faltante, ilegible como archivo o con SHA-256 incorrecto produce `INVALID_EVIDENCE`. La prueba se conserva para trazabilidad pero debe repetirse. La captura manual de valores no modifica la validez física del archivo.

## 25. Adquisición comprometida

`COMPROMISED` significa que el conteo de pulsos no pudo verificarse o reconciliarse. Es diferente de `INVALID_EVIDENCE`, que corresponde a fotografías. Una adquisición comprometida no puede cerrar `CLOSED_VALID`; repita la muestra y revise conexión BLE, ROI LED y contador ESP32.

## 26. Reportes y exportes

Cuando la selección contiene una simulación, CSV y JSON incluyen la marca y el escenario; HTML y PDF muestran **PRUEBA SIMULADA — NO CORRESPONDE A UNA VERIFICACIÓN FÍSICA**. En el escenario mixto aparecen ambas muestras y no se oculta la primera fallida.

Las pruebas aparecen en orden cronológico. Cada prueba muestra su fecha; la tabla usa **Tiempo** y presenta únicamente la hora local. `V.MEC L` corresponde al volumen del medidor del hidrante calculado con los pulsos GPIO25 y su K configurada. También se muestran los caudales puntuales mínimo, máximo y promedio obtenidos en las fotografías de evidencia.

El ID técnico del teléfono, versión de Android, marca y modelo se guardan para trazabilidad interna cuando Android los proporciona. Puede consultarlos en **Ajustes > Usuario actual**, antes de la versión, pero no aparecen en el HTML/PDF entregable.

El reporte muestra además la configuración metrológica usada, la identidad del ESP32, la repetibilidad por caudal y un mapa autocontenido del punto GPS. El enlace **Abrir mapa detallado** requiere conexión; el punto, coordenadas y precisión permanecen visibles sin internet.

En el **Resumen del expediente**, expanda **INFORMACIÓN TÉCNICA LOCAL** debajo de una prueba finalizada para consultar integridad de adquisición, incidencia registrada, contadores ESP32, primer/último punto, duración, pulsos, fotografías y su integridad, zoom y coordenadas normalizadas de las regiones de cámara.

En el resumen seleccione una o varias muestras. Puede generar:

- **CSV:** tabla de prueba.
- **JSON:** datos estructurados y checksums, sin fotos Base64 para BD.
- **HTML:** evidencia autocontenida con fotografías.
- **PDF:** mismo contenido esencial y orden, disponible offline.

Los archivos pueden abrirse o compartirse desde Android. La generación no depende del servidor.

## 27. Historial

Historial local muestra expedientes abiertos y cerrados. Los cerrados son read-only. Abrir un expediente no borra información ni crea una muestra automáticamente.

## 28. Recuperación

Si Android detiene la app durante una Sample `RUNNING`, al relanzar se recuperan Evidence, progreso, método, contador, configuración visual, rectángulo, círculo, formato y escala persistidos. Pulse **REANUDAR PRUEBA**.

En BLE/LED, la aplicación intenta recuperar el contador acumulativo. Si el intervalo no puede conciliarse, marca integridad comprometida; nunca fabrica pulsos para aparentar continuidad.

Una SIMULACIÓN `RUNNING` también conserva escenario, progreso y Evidence. Al reanudar continúa desde el contador persistido y no duplica evidencias ya guardadas.

## 29. Funcionamiento offline

Con una sesión local válida funcionan sin servidor: identificación libre, GPS, selección de método, prueba, cámara, evidencia, lecturas, cálculo, registro, muestras, historial y exportes HTML/PDF/CSV/JSON. Los datos permanecen en SQLite y filesystem del dispositivo.

## 30. Sincronización

La sincronización solo aparece cuando el backend está configurado. Cuando no lo está, no hay un botón remoto inútil: el trabajo se conserva localmente. Al configurar servidor, la app puede subir evidencias y metadata de forma idempotente y mostrar estados reales de sincronización o conflicto.

## 31. Ajustes

- **K (L/pulso):** volumen representado por cada pulso.
- **Paso captura/evidencia:** intervalo de litros entre fotos INTERMEDIATE.
- **Vmín/Vmáx:** límites operativos orientativos para nuevas muestras.
- **Incertidumbre de lectura:** componente usado por el motor vigente.
- **Manual de uso:** abre este documento offline.
- **Cerrar sesión:** termina la sesión sin borrar datos.

El MPE se deriva de Q1–Q4. Los cambios se aplican únicamente a nuevas Samples.

## 32. Permisos Android

- **Cámara:** necesaria para Evidence; sin ella una muestra no puede cerrarse válidamente.
- **Ubicación:** permite GPS; denegarla no bloquea la prueba.
- **Bluetooth cercano:** necesario para buscar y conectar ESP32 en BLE/LED.

Si un permiso fue denegado permanentemente, habilítelo desde Ajustes de Android.

## 33. Resolución de problemas

### La cámara no abre

Revise permiso de Cámara, cierre otras aplicaciones que la ocupen y vuelva a intentar. No finalice sin las fotos obligatorias.

### GPS denegado o no disponible

Conceda Ubicación precisa, active servicios de ubicación y vuelva a pulsar el icono. Puede continuar sin GPS; nunca introduzca coordenadas ficticias.

### El recorte del totalizador no permite leerlo

Repita la corrida si la fotografía FINAL no permite identificar con certeza los dígitos. En la siguiente preparación ajuste el rectángulo y el encuadre; no estime un valor que no pueda verificarse.

### El recorte del dial no permite leer la aguja

Repita la corrida si la fotografía FINAL no permite identificar con certeza la aguja. En la siguiente preparación centre y dimensione nuevamente el círculo.

### BLE no encuentra ESP32

Revise alimentación, permisos Bluetooth, proximidad y que el dispositivo anuncie DDR001. Repita búsqueda sin modificar el dummy.

### LED no detecta destellos

Coloque el LED GPIO2 dentro de la ROI, evite reflejos y espere baseline. Verifique también la conexión BLE auxiliar.

### Conteo comprometido

No cierre la muestra. Revise ESP32/conexión y repita; no intente compensar pulsos manualmente dentro de LED/BLE.

### Evidencia faltante o corrupta

La muestra será inválida y debe repetirse. OCR fallido por sí solo no significa corrupción.

### La app recupera una prueba

Pulse REANUDAR. No borre datos ni desinstale la app; el estado `RUNNING` se conserva deliberadamente.

### No hay servidor

Continúe offline. Las funciones remotas se ocultan y los datos quedan locales hasta configurar backend/API.

## 34. Buenas prácticas en campo

- Capture la carátula completa, enfocada y con totalizador legible.
- Seleccione únicamente los dígitos del totalizador.
- Elija conscientemente el dial de mayor resolución metrológica que usará.
- Confirme escala, formato y lectura antes de continuar.
- Mantenga un encuadre parecido entre START y FINAL, ajustando guías cuando sea necesario.
- No cierre una prueba con conteo no verificable ni omita Evidence obligatoria.

## 35. Glosario

- **Vref:** volumen de referencia o patrón.
- **Vind:** volumen indicado/avance del medidor.
- **K:** litros representados por un pulso.
- **MPE:** error máximo permisible.
- **U:** incertidumbre usada en la decisión.
- **START:** Evidence inicial automática; sus valores manuales se capturan al cierre.
- **INTERMEDIATE:** Evidence intermedia diagnóstica según el paso.
- **FINAL:** Evidence final; abre la captura manual de los endpoints INICIO y FINAL.
- **Totalizador:** conjunto de dígitos acumulativos del medidor.
- **Dial:** círculo graduado con aguja para lectura fina.
- **Muestra/Sample:** una corrida individual cerrable.
- **Expediente/VerificationCase:** agrupación de caudales y muestras de un medidor.
- **Evidence:** fotografía completa original con hash y metadata.
- **Integridad:** posibilidad de verificar el conteo de adquisición.
