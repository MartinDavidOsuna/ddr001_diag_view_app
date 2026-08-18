# Manual de uso — DDR001 Verificador de Medidores

**Versión del manual:** 1.1  
**Última actualización del contenido:** 16 de agosto de 2026

La pantalla muestra por separado la versión instalada de la aplicación. Este manual es la fuente canónica del procedimiento visible para el técnico y funciona completamente sin internet.

## Índice

1. Propósito de la aplicación
2. Inicio de sesión
3. Pantalla de inicio
4. Identificación del medidor
5. GPS
6. Métodos de medición
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

El primer acceso requiere el backend DDR001 configurado. Después de guardar una sesión válida, la aplicación puede abrir y trabajar sin internet. La sesión permanece hasta pulsar **CERRAR SESIÓN** en Ajustes. Cerrar sesión no elimina expedientes, muestras ni fotografías locales.

## 3. Pantalla de inicio

- **NUEVA VERIFICACIÓN:** inicia la identificación de un medidor.
- **HISTORIAL LOCAL:** muestra expedientes guardados en el dispositivo.
- **Ajustes:** abre identidad, parámetros para nuevas muestras, Manual de uso y cierre de sesión.
- Si existe una Sample `RUNNING`, al abrir la app se ofrece **REANUDAR PRUEBA**. Ir al inicio no descarta esa prueba.

## 4. Identificación del medidor

Capture el **ID o número de cuenta**. Cualquier ID es válido para continuar. Cuando la consulta externa esté configurada, la aplicación puede informar si la cuenta está localizada con levantamiento, localizada sin levantamiento o no localizada/nueva. La consulta nunca bloquea la verificación y no escribe en el sistema de hidrantes.

Seleccione el caudal:

- **Q1:** caudal mínimo.
- **Q2:** caudal de transición.
- **Q3:** caudal permanente.
- **Q4:** caudal de sobrecarga.

Capture manualmente el **LPS aproximado**. El MPE mostrado se deriva del caudal seleccionado; no se introduce libremente.

## 5. GPS

Pulse el icono **Obtener ubicación GPS** en Identificación. La pantalla muestra latitud, longitud y precisión aproximada `±N m`. La captura usa la ubicación de alta precisión del teléfono y registra timestamp.

GPS no necesita internet ni servidor. Android puede solicitar permiso. Si el permiso se deniega, se deniega permanentemente, los servicios están apagados o ocurre timeout, aparece un mensaje claro y la prueba puede continuar sin coordenadas. Al pulsar **INICIAR PRUEBA**, la aplicación vuelve a intentar GPS si todavía no existe una posición.

Nunca se inventan coordenadas. Este procedimiento usa GPS del dispositivo; no agrega un diagnóstico GPRS o celular.

## 6. Métodos de medición

- **LECTURA VISUAL:** lectura productiva de un medidor real mediante fotografías y confirmación humana.
- **MANUAL:** cada pulsación del botón representa un pulso.
- **LED:** la cámara cuenta destellos del LED integrado del ESP32.
- **BLUETOOTH:** obtiene el contador acumulativo del ESP32 mediante BLE.

MANUAL, LED y BLUETOOTH convierten pulsos a volumen patrón con `Vref = pulsos × K`. LECTURA VISUAL registra su referencia explícita sin fabricar pulsos.

## 7. Método MANUAL

Configure **K en L/pulso**. Durante la prueba, cada acción sobre el botón de pulso representa exactamente un pulso real y aumenta el contador una unidad. El volumen patrón mostrado se obtiene multiplicando el contador por K.

No pulse varias veces por un único evento ni omita eventos físicos. Use **Capturar un punto ahora** solamente cuando necesite un punto diagnóstico adicional; no sustituye las evidencias obligatorias.

## 8. Método BLUETOOTH

El ESP32 DDR001 recibe el dummy/sensor en GPIO27 y publica un contador acumulativo BLE. En la preparación:

1. Pulse buscar.
2. Seleccione el dispositivo DDR001.
3. Espere el estado **READY**.
4. Inicie la prueba para congelar el contador inicial y K.

La aplicación concilia los incrementos del contador y conserva el último valor observado para recovery. Una reconexión válida incorpora el delta acumulado. Un rollback o intervalo que no puede conciliarse marca la adquisición `COMPROMISED`; esa muestra no puede cerrar como válida.

## 9. Método LED

LED utiliza el LED integrado GPIO2 del ESP32. La cámara observa una ROI, obtiene baseline de brillo y cuenta el flanco **DARK → BRIGHT** con histéresis y anti-rebote. Un destello válido equivale a un pulso y suma K litros.

El contador BLE acumulativo se usa como canal auxiliar de conciliación. Al tomar una fotografía de evidencia, la aplicación coordina la cámara y concilia lo ocurrido; no simula continuidad. Mantenga el LED dentro de la ROI y evite reflejos directos. Si el conteo óptico y el contador físico no pueden reconciliarse, la integridad queda comprometida y debe repetirse la muestra.

## 10. LECTURA VISUAL

LECTURA VISUAL **no es simulación**. Se aplica a medidores reales. Usa la foto completa de la carátula, un crop de totalizador y un crop del dial elegidos por el técnico. OCR y detección de aguja solamente proponen valores; el técnico siempre confirma o corrige START y FINAL.

El simulador web es una herramienta externa de validación y no forma parte de la app productiva.

## 11. Preparación de la prueba

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

1. Capture una foto completa y legible de la carátula.
2. En **CONFIGURAR LECTURA**, seleccione manualmente el totalizador.
3. Seleccione manualmente el dial que utilizará.
4. Confirme formato del totalizador y escala del dial.
5. Pulse **ANALIZAR LECTURA**.
6. Revise ambos crops y la propuesta.
7. Pulse **CORRECTA** o **CORREGIR**.

Al pulsar **FIJAR REGIONES**, la tarjeta de la fotografía se minimiza para dejar visibles los controles de formato, escala y **ANALIZAR LECTURA**.

Durante la preparación y la prueba, un panel permanece fijo debajo del título. Muestra la hora del primer pulso recibido, pulsos acumulados, volumen patrón y los caudales en L/s con dos decimales. Se refresca cada medio segundo: el caudal se calcula como volumen acumulado dividido entre el tiempo transcurrido desde el primer pulso. Por eso continúa cambiando aunque no llegue otro pulso y, si el flujo se detiene, disminuye progresivamente hasta mostrarse como 0.00 L/s. El botón **FINALIZAR Y CONFIRMAR LECTURAS** permanece dentro de ese panel aunque se desplace el registro.

El ESP32 recibe dos señales distintas. El **medidor de control** conectado a GPIO27 es el equipo con calibración probada: sus pulsos determinan Vref y el caudal patrón. El **medidor del hidrante** conectado a GPIO25 es el equipo que se está verificando y fotografiando. Sus pulsos son solamente diagnósticos; puede mostrar cero durante toda la prueba cuando ese medidor no disponga de salida de pulsos, sin invalidar la adquisición patrón.

El porcentaje de confianza del encabezado se calcula con los pulsos del **medidor de control**, nunca con los pulsos opcionales del hidrante. Expresa la resolución relativa del conteo patrón observado. Un pulso es la unidad mínima observable. Para `N` pulsos de control se calcula `Confianza = max(0, (1 − 1/N) × 100)`. Con un pulso la confianza es 0 %, con 10 pulsos es 90 % y aumenta hacia 100 % conforme crece el conteo. Se muestra blanco en 0 %, verde desde 97 % y rojo por debajo de 97 %. Es un indicador diagnóstico de resolución; no modifica Vref, el error metrológico, la incertidumbre, el MPE ni el veredicto.

Puede utilizarse un control Bluetooth de disparo fotográfico que Android presente como teclas de volumen. En **Prueba en curso**, cualquiera de sus botones ejecuta únicamente la acción principal disponible: inicia cuando el caudal de control cumple el intervalo configurado, o finaliza cuando la prueba ya inició y existe volumen patrón. El control no toma fotografías directamente, no captura puntos intermedios y no ejecuta otras funciones. Sin control asociado, utilice normalmente los botones de la pantalla.

Android puede mostrar el evento como **Volumen arriba** o **Volumen abajo**. Esto es normal: durante **Prueba en curso** la aplicación intercepta ese evento antes de que cambie el volumen y lo convierte en la acción habilitada. Fuera de esa pantalla, las teclas conservan su comportamiento normal.

En Preparación configure el caudal mínimo y máximo permitido para iniciar, además de cuántos litros representa cada pulso del **medidor del hidrante**. Tras confirmar la fotografía INICIO, la app observa continuamente los dos canales para mostrar sus caudales, pero los acumulados oficiales de pulsos, V patrón y volumen del hidrante permanecen en cero. El botón verde **INICIAR PRUEBA** permanece deshabilitado hasta que el caudal de control esté dentro del rango; el valor cambia a verde. Al pulsarlo se toman bases lógicas sin reiniciar el ESP32 ni interrumpir los caudales observados: desde ese instante comienzan en cero los acumulados oficiales y aparece **FINALIZAR Y CONFIRMAR LECTURAS**.

En el extremo superior derecho, el icono Bluetooth y el texto **ESP32** son verdes cuando existe conexión y rojos cuando no existe. El icono del control remoto permanece gris hasta habilitarlo: la primera pulsación abre **Control conectado** y una segunda pulsación, o tocar **ACEPTAR**, lo habilita y cambia el icono a verde. Esta confirmación evita iniciar accidentalmente por pulsaciones repetidas durante la preparación. En el resumen, **V hidrante** es el acumulado oficial de pulsos GPIO25 multiplicado por el valor configurado de cada pulso del medidor del hidrante. El nombre del medidor y su renglón Q/caudal/K aparecen dentro del resumen, antes del estado de inicio.

La app no ejecuta el análisis definitivo antes de esas selecciones. La foto original se conserva intacta con su SHA-256; rectángulo y círculo producen solamente crops derivados.

## 14. Selección del totalizador

Pulse **EDITAR REGIONES** para entrar al modo de edición fijo. En este modo la pantalla no se desplaza: mueva el rectángulo ámbar hasta incluir **únicamente los dígitos del totalizador** y use el control de esquina para ampliar o reducir. Puede colocarlo arriba, abajo, al centro, a la izquierda o a la derecha según la marca del medidor. Pulse **FIJAR REGIONES** para volver al formulario de formato y análisis.

Use el selector **TOTALIZADOR / DIAL** para indicar qué guía está editando. Así, aunque ambas regiones se superpongan, solamente se moverá o redimensionará la elegida.

No incluya año, número de serie, Q3, R160, marca, modelo u otros números. OCR recibe exclusivamente el crop elegido; una cifra fuera del rectángulo no puede ser candidata.

## 15. Formato del totalizador

Confirme número total de dígitos, decimales, unidad y ceros iniciales cuando aplique. El decimal se aplica desde el formato confirmado aunque OCR no vea el punto.

Cuente todos los tambores visibles, incluidos los ceros iniciales. Si el último tambor está entre dos números (por ejemplo, se ve parte de `2` y parte de `3`), la aplicación propone el dígito anterior —`2` en ese ejemplo— y muestra una advertencia. Revise la propuesta antes de pulsar **CORRECTA**; use **CORREGIR** si no coincide con la lectura física.

Ejemplo: OCR `482`, formato `##.#`, propuesta `48.2 m³`. Si OCR falla, contiene caracteres ambiguos o no coincide con el formato, capture manualmente la lectura. Una foto íntegra sigue siendo Evidence válida aunque OCR falle.

## 16. Selección del dial

Un medidor puede tener uno, dos, tres, cuatro o más diales. Mueva el círculo verde sobre **un solo dial**: el que se utilizará para la lectura fina. Use el control del círculo para redimensionar y confirme su escala.

Seleccione el dial de **mayor resolución metrológica**, es decir, el que represente la menor cantidad de volumen por división o vuelta entre los diales disponibles para esa lectura. No significa el círculo físicamente más grande, la aguja más larga, el dial con más píxeles ni el más nítido. La app no decide automáticamente entre los diales.

## 17. Aguja

El detector busca exclusivamente una **aguja roja** dentro del círculo confirmado. Exige dominancia roja, suficientes píxeles, relación con el eje central, dirección radial, longitud y confianza mínimas.

Una línea negra, tornillo, reflejo, marca o sombra no debe producir lectura. Si no existe una aguja roja válida aparece **Aguja no detectada**. Puede introducir el valor manualmente, ajustar el círculo y reanalizar o repetir la foto. La Evidence no se invalida por una falla de visión.

## 18. Fotografías INTERMEDIATE

INTERMEDIATE aparece según el plan de evidencia. Al alcanzar cada umbral, la aplicación toma automáticamente una fotografía completa con la cámara y la guarda como Evidence: el técnico no pulsa un obturador ni abandona la pantalla de prueba. Mantenga la carátula encuadrada y visible mientras avanza el volumen. Es evidencia obligatoria y alimenta el registro diagnóstico, pero no sustituye el cálculo oficial START→FINAL. No exige OCR perfecto ni una confirmación exhaustiva en cada punto.

La captura y persistencia se ejecutan transparentemente: no aparece un indicador de progreso que cubra la pantalla y las lecturas en vivo continúan visibles y actualizándose. Para no congelar el contador, INTERMEDIO no ejecuta OCR ni análisis de aguja en primer plano; por eso sus columnas de lectura diagnóstica pueden mostrar `—`.

En MANUAL, LED y BLUETOOTH la app abre automáticamente la captura al alcanzar cada umbral. FINAL permanece bloqueada si falta alguna fotografía INTERMEDIATE exigida.

## 19. Captura FINAL

Al pulsar **FINALIZAR Y CONFIRMAR LECTURAS**, la app congela inmediatamente el conteo y Vref: ningún pulso posterior cambia el endpoint de la prueba. El botón muestra **FINALIZANDO…** mientras, en segundo plano, se completa cualquier Evidence pendiente, se toma FINAL y se analiza. FINAL reutiliza el rectángulo, círculo, formato y escala congelados en START; después muestra directamente la propuesta para confirmar o corregir.

Si el encuadre cambió, pulse **AJUSTAR REGIONES** para abrir el modo fijo, mueva las guías y termine con **APLICAR Y REANALIZAR**. Ajustar regiones no toma otra foto, no crea otra Evidence y no altera la original.

## 20. Registro

- **Punto:** START, INTERMEDIATE, FINAL o punto manual diagnóstico.
- **Fecha / hora:** timestamp local de la Evidence correspondiente.
- **Pulsos:** contador cuando el método usa pulsos.
- **V patrón:** volumen de referencia del punto.
- **Lectura:** lectura observada del medidor.
- **V mecánico:** avance indicado/diagnóstico disponible.
- **Error diagnóstico:** comparación del punto; no es el error oficial.

`Lectura L` se completa al confirmar START y FINAL. En una INTERMEDIATE automática puede mostrarse `—` porque esa foto sirve como evidencia diagnóstica y no requiere una lectura confirmada; el guion no significa que falte la fotografía.

El resultado oficial siempre usa los endpoints START y FINAL.

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

Puede usar **INICIAR OTRA MUESTRA** sin límite artificial y **CAMBIAR CAUDAL** para trabajar Q1–Q4 dentro del mismo expediente. Las muestras anteriores se conservan.

Con tres o más muestras se muestran n, media, mínimo, máximo, dispersión, desviación estándar y repetibilidad. Con menos de tres, la repetibilidad es **No evaluable**.

## 23. Expediente

El expediente agrupa un medidor, sus caudales y muestras. **TERMINAR EXPEDIENTE** calcula el veredicto global conforme a los caudales realmente requeridos/evaluados. Un expediente cerrado queda de solo lectura. Una muestra `CLOSED_VALID` tampoco se edita; una corrección requiere una nueva muestra.

## 24. Evidencia inválida

Una foto obligatoria faltante, ilegible como archivo o con SHA-256 incorrecto produce `INVALID_EVIDENCE`. La prueba se conserva para trazabilidad pero debe repetirse. Una falla de OCR o aguja con foto válida no es evidencia inválida: use corrección manual.

## 25. Adquisición comprometida

`COMPROMISED` significa que el conteo de pulsos no pudo verificarse o reconciliarse. Es diferente de `INVALID_EVIDENCE`, que corresponde a fotografías. Una adquisición comprometida no puede cerrar `CLOSED_VALID`; repita la muestra y revise conexión BLE, ROI LED y contador ESP32.

## 26. Reportes y exportes

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

### OCR falla

Ajuste el rectángulo para contener solo dígitos, mejore encuadre/iluminación y reanalice. Si persiste, corrija manualmente.

### Aguja no detectada

Confirme que eligió el dial correcto, que el círculo contiene eje y aguja roja y que la escala es correcta. Ajuste, reanalice o capture manualmente la aguja.

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
- **START:** Evidence y lectura inicial.
- **INTERMEDIATE:** Evidence intermedia diagnóstica según el paso.
- **FINAL:** Evidence y lectura final.
- **Totalizador:** conjunto de dígitos acumulativos del medidor.
- **Dial:** círculo graduado con aguja para lectura fina.
- **Muestra/Sample:** una corrida individual cerrable.
- **Expediente/VerificationCase:** agrupación de caudales y muestras de un medidor.
- **Evidence:** fotografía completa original con hash y metadata.
- **Integridad:** posibilidad de verificar el conteo de adquisición.
