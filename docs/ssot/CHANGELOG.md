# CHANGELOG funcional

## Versión 1.5.1+17 — corrección de escala en Vind BLE/SIMULACIÓN — 2026-09-10
- Corrige el defecto reproducido en Pixel donde 10.345→10.547 m³ se guardaba como 0.202 L: ahora la escala congelada convierte el avance a 202 L antes de ejecutar el motor metrológico.
- BLE y SIMULACIÓN calculan `Vind` desde `totalizador × litros/unidad + aguja` y eliminan del formulario el campo redundante **Total del medidor (L)**; la lectura de aguja continúa sin máximo fijo.
- Se agrega regresión metrológica exacta para 202 L. Muestras ya cerradas permanecen inmutables; la corrección aplica a nuevas corridas o repeticiones.

## Versión 1.5.0+16 — simulación controlada en campo — 2026-09-10
- SIMULACIÓN muestra caudal fluctuante antes del inicio: Q1 entre 5–7 L/s y Q2 entre 2–3 L/s, con variación consecutiva máxima de 0.5 L/s.
- El técnico decide cuándo iniciar y finalizar; tiempo, pulsos y Vref comienzan exactamente al pulsar INICIAR y no acumulan durante la previsualización.
- FINAL abre la captura manual de lecturas INICIO/FINAL y el resultado continúa calculándose con el motor metrológico, persistencia, Evidence y reportes reales.
- BLE y SIMULACIÓN aceptan una lectura de aguja no negativa sin máximo fijo de 100 L; la reconstrucción cíclica de otros métodos conserva su límite por vuelta.
- Drift avanza 13→14 preservando trabajo y agrega `OPERATOR_CONTROLLED`; Sample contract local avanza v9→v10. La Field API no cambia y recibe el escenario proyectado al veredicto real.

## Versión 1.4.0+15 — sync online/offline-first con DDR001 API — 2026-09-02
- Certificación Pixel corrige el MIME multipart a partir de la firma JPEG/PNG y
  alinea la canonicalización numérica de `payloadSha256` con JavaScript; los
  lotes rechazados por la huella anterior se reparan sin cambiar UUID, payload
  funcional ni checksums metrológicos.
- Auth adopta Field sessions reales con `client_app=ddr001_diag_view`, installation UUID estable, access/refresh seguro, un refresh ante 401 y aislamiento por app/instalación.
- Login guarda primero la identidad local y conserva operación completa ante timeout/5xx; el UUID local y `rv_user_id` quedan separados. Logout elimina secretos remotos y sesión local, nunca trabajo.
- Drift avanza 12→13 aditivamente con vínculo de usuario remoto, ACK/error de Evidence y `sync_batches` persistentes para recuperar respuestas perdidas tras restart.
- Evidence se verifica por archivo/SHA-256 y sube con concurrencia 1 antes del batch; archivo faltante, 409, acceso denegado o error de red conservan metadata, Case, checksum, cola y filesystem.
- `sync/push` serializa Meter, Case, FlowPoint, Sample, settings, Points y referencias Evidence con hashes canónicos; persiste receipt/ACK y consulta `sync/status` para estados ambiguos.
- La UI muestra Pendiente, Sincronizando, Sincronizado, Conflicto o Error sin sustituir el listado local por `/cases`; producción, API, Dashboard, `sync/pull` y motor metrológico no cambian.
- El estado confirmado `SYNC · Sincronizado` se muestra en verde para distinguir
  visualmente el ACK persistido; el botón queda inactivo para evitar una falsa
  acción de refresco. Historial lee el último ACK persistido y muestra también
  `Sincronizado` en verde; una nueva pulsación sobre un Case cerrado ya
  confirmado no envía otro batch ni crea otro receipt.
- El motor de sincronización aplica la misma guarda idempotente aunque sea
  invocado fuera de la pantalla: un Case con batch `synced` retorna su estado
  local sin hacer access, uploads ni `sync/push` adicionales.

## Macroetapa 1 — contrato online con DDR001 API — 2026-09-02
- Se congela `ddr001_api` + SQL Server 2014 como único backend productivo y se clasifica `backend/` Prisma/PostgreSQL como referencia histórica no desplegable.
- Se reserva el schema aislado `functional_diag`; la única FK compartida permitida es a `rv.users`, sin dependencias de negocio con RV, Construction u otras apps.
- Se adopta auth Field multi-app con `client_app=ddr001_diag_view`, installation UUID estable, access/refresh tokens y sesiones independientes por app/dispositivo.
- Se define Evidence independiente, subida previa, lote sync idempotente con receipts/ACK recuperable, conflicto UUID+checksum y filtro productivo que excluye simulación por defecto.
- Se documentan Field/Admin APIs, modelo SQL propuesto, seguridad, auditoría/reviews append-only y trazabilidad completa Drift -> payload -> SQL -> response -> dashboard.
- No se modifica runtime Flutter, backend histórico, API ejecutable, migraciones, UI ni producción.

## Versión 1.3.4+14 — Evidence intermedia sin bloquear pulsos — 2026-09-01
- La captura y persistencia de Evidence INTERMEDIATE se ejecutan fuera de la cola de pulsos y ya no activan el `loading` global ni deshabilitan el ritmo de MANUAL o BLE/ESP32.
- Los pulsos conservan serialización y persistencia inmediata mientras la cámara procesa la fotografía; si se cruzan varios umbrales, la cola de Evidence los completa en orden y sin duplicarlos.
- FINAL congela nuevos pulsos y espera tanto los pulsos ya aceptados como la Evidence intermedia pendiente antes de cerrar la Sample.
- No cambian Drift 12, el plan START/INTERMEDIATE/FINAL, la metrología, Simulación, reportes, backend ni firmware.

## Versión 1.3.3+13 — frontera START obligatoria para MANUAL — 2026-09-01
- MANUAL habilita `INICIAR PRUEBA` sin exigir pulsos de caudal previos, captura primero Evidence START y sólo entonces habilita `+1 PULSO`.
- Un pulso MANUAL previo a START ya no puede incrementar la Sample ni hacer que recovery interprete la adquisición como iniciada.
- Recovery usa la Evidence START persistida como frontera durable y conserva las Samples inválidas o RUNNING ya existentes sin borrarlas.
- BLE/ESP32 conserva su compuerta de caudal; Simulación, metrología, Drift 12, Cámara y reportes no cambian.

## Versión 1.3.2+12 — reactivación productiva de captura MANUAL — 2026-09-01
- MANUAL vuelve al selector productivo tras haber sido ocultado por `6ffec407`; reutiliza la implementación existente desde Stage 3 y no crea un workflow paralelo.
- Un único botón `+1 PULSO` emite `PulseEvent.manual` hacia `PulseProgressService`, persiste cada incremento y Vref, y queda deshabilitado mientras se procesa el tap para evitar dobles eventos accidentales.
- MANUAL no exige BLE, ESP32, backend o Internet y conserva Cámara, Evidence, recovery RUNNING, cierre, metrología, Historial y los cuatro exportes comunes.
- Se preservan Simulación, BLE/ESP32, Drift schema 12, escala canónica de 1000 L/vuelta y aislamiento de Samples entre Cases.

## Versión 1.3.1+11 — escala de dial y selección aislada de reportes — 2026-09-01
- Preparación y Cámara comparten `litersPerRevolution` como escala canónica positiva; Cámara conserva 1000 L/vuelta y deriva el multiplicador histórico sin limitar el dominio a 100 L/vuelta.
- CAPTURAR LECTURAS distingue el total acumulado del medidor de la posición de aguja dentro de una vuelta. El total no queda limitado por L/vuelta; la aguja conserva su frontera metrológica.
- La selección de Samples para exportación se reconcilia al expediente abierto y nunca conserva IDs de otro Case; una selección vacía no genera reportes.
- PDF sustituye el marcador Unicode no disponible de repetibilidad por texto compatible, sin rediseñar la paginación.
- Drift permanece en schema 12; no hay migración ni cambio en fórmulas, Simulación, BLE, backend o firmware.

## Versión 1.3.0+10 — modo de simulación trazable — 2026-09-01
- Fuente SIMULACIÓN local con escenarios exitosa, fallida y mixta; el escenario genera entradas deterministas y el motor metrológico real decide APRUEBA/RECHAZA.
- La adquisición acelerada usa el progreso de pulsos, persistencia Drift, SampleClosureService, plan START/INTERMEDIATE/FINAL, archivos Evidence reales y SHA-256.
- El escenario mixto conserva la primera Sample RECHAZA y crea una segunda Sample APRUEBA dentro del mismo caudal.
- Drift avanza 11→12 mediante reconstrucción controlada de `samples`, preserva filas RUNNING y agrega `simulation_scenario`; Sample contract avanza v8→v9 y checksum simulado usa canonical v6.
- Historial, Registro, CSV, JSON v2, HTML y PDF muestran trazabilidad inequívoca de prueba no física. Los exportes de pruebas reales conservan JSON v1 y no reciben marcas de simulación.
- SIMULACIÓN no inicia BLE ni requiere cámara, ESP32, backend o Internet. Las fuentes reales, protocolo BLE y firmware permanecen sin cambios.

## Recuperación Git del baseline funcional — 2026-09-01
- Se restaura el primer acceso local passwordless para cualquier identidad válida cuando el backend no está configurado.
- Se elimina el bloqueo que mostraba `El primer acceso requiere conexión al backend DDR001 configurado`, sin alterar datos, esquema Drift, metrología, Evidence, pulsos ni contratos.
- El proveedor remoto permanece preparado y sólo se selecciona cuando existe `DDR001_API_BASE_URL` explícito.

## Versión 1.2.1+09 — cierre manual aislado de adquisición — 2026-08-21
- CAPTURAR LECTURAS queda aislada de pulsos, estado BLE y callbacks tardíos de cámara después de persistir FINAL.
- GUARDAR Y CALCULAR RESULTADO usa las evidencias START/FINAL persistidas, sin depender de una captura activa ni de recortes transitorios en memoria.
- Los callbacks duplicados de una fotografía ya finalizada son idempotentes y no muestran errores ni duplican evidencias.
- La validación de aguja fuera de su escala presenta una indicación específica en lugar del mensaje genérico de operación no permitida.
- El panel de prueba conserva contadores monotónicos durante capturas de evidencia y evita que una lectura asíncrona atrasada restaure un snapshot anterior.
- Los caudales visibles de patrón e hidrante usan todos los pulsos al arrancar y una ventana móvil de los últimos 10 después del décimo pulso.

## Versión 1.2.0+08 — banco, procedencia y reporte cronológico — 2026-08-21
- Firmware ESP32 V1.0 incorpora filtro PCNT, estabilidad/rearme y debounce para GPIO25/GPIO27; el configurador exige `--nombre` con serie y versión y produce un nombre BLE compatible con DDR001.
- Identificación incorpora el campo obligatorio `ID / banco de pruebas`.
- Cada expediente congela ID de dispositivo, Android, marca y modelo disponibles; Ajustes los muestra y el reporte presentable los oculta.
- Login fija la versión discretamente al fondo, elimina las dos leyendas auxiliares y habilita accesos maestros para Rene y Omar.
- Reportes ordenan pruebas cronológicamente, presentan V.MEC desde GPIO25, agregan caudal mínimo/máximo/promedio y localizan etiquetas/horas al español.
- HTML/PDF dejan de mostrar el sello DDR001 y el número interno de expediente.
- El reporte incorpora configuración metrológica, ESP32, repetibilidad y mapa autocontenido del punto GPS con enlace opcional al detalle.
- El resumen local despliega integridad/adquisición, duración y endpoints, trazabilidad de fotografías y zoom/regiones congeladas.

## Versión 1.1.1+07 — endpoint FINAL atómico y cámara estable — 2026-08-21
- `FINALIZAR Y CONFIRMAR LECTURAS` congela inmediatamente el endpoint, desasocia todas las entradas de la muestra y evita que GPIO27/GPIO25 o reconciliación LED alteren pulsos, volumen o caudal durante el formulario.
- FINAL es la primera fotografía tomada después del botón; ya no se intentan reconstruir evidencias INTERMEDIAS faltantes durante el cierre.
- La cámara permanece inicializada entre INICIO, INTERMEDIAS y FINAL, restaura periódicamente enfoque automático, exposición, punto de enfoque y zoom, y vuelve a validarlos justo antes de cada fotografía.
- La Evidence conserva siempre el cuadro completo original; totalizador y dial se usan únicamente para generar recortes de presentación en el formulario manual.

## Versión 1.1.0+06 — caudal puntual, GPS y enfoque táctil — 2026-08-20
- Identificación elimina la captura manual de LPS Q1/Q2; ambos caudales se crean con `lps_approx` nullable y el cálculo comienza en el primer pulso, no al abrir la pantalla.
- INICIO, cada evidencia INTERMEDIA y FINAL registran `flow_lps`; Registro y exportes incorporan la lectura puntual y las estadísticas mínima, máxima y promedio.
- CONTINUAR sin GPS abre una confirmación explícita y, al aceptarla, avanza directamente sin fabricar coordenadas.
- Un toque en el preview de Preparación de cámara fija enfoque y exposición como la cámara estándar de Android.
- Al comenzar la prueba, control e hidrante reinician simultáneamente sus baselines visibles en cero.
- SQLite avanza aditivamente a schema 10 y la aplicación a `1.1.0+06`.

## Versión 1.0.5+05 — sesión BLE y verificaciones independientes — 2026-08-20
- La conexión GATT del ESP32 queda desacoplada de pantallas y muestras: Atrás, Método, Preparación, fijación de regiones y una verificación nueva conservan el mismo transporte y keepalive; únicamente `DESCONECTAR ESP32` lo destruye explícitamente.
- `FIJAR REGIONES` deja de reiniciar la fuente BLE y descarta mensajes vacíos durante transiciones, evitando la leyenda roja y las actualizaciones hacia widgets ya desmontados.
- Preparación de cámara reutiliza la última geometría confirmada. Solo sugiere automáticamente cuando no existe una anterior, y `NUEVA SUGERENCIA DE REGIONES` recorre candidatos distintos antes de repetirlos.
- Inicio crea siempre un expediente nuevo en `NUEVA VERIFICACIÓN` y limpia los datos operativos inconclusos; conserva únicamente periféricos conectados y la última geometría/zoom de totalizador y dial.
- Fuente/Método simplifica la acción a `BUSCAR ESP32`.

## Versión 1.0.4+04 — descubrimiento conectado y navegación BLE — 2026-08-20
- BUSCAR conserva en la lista el ESP32 cuya conexión GATT sigue activa aunque el firmware deje de anunciarse mientras está conectado; los anuncios de módulos adicionales se agregan normalmente.
- Keepalive deja de publicar contadores GPIO27/GPIO25 duplicados, evitando escrituras y reconstrucciones de UI sin cambio físico.
- La navegación deja de retener temporalmente la pantalla anterior con `AnimatedSwitcher`, eliminando listeners Riverpod salientes que podían recibir una actualización BLE después de destruirse y producir `_ElementLifecycle.defunct`.

## Versión 1.0.3+03 — continuidad BLE y preparación de cámara — 2026-08-20
- La conexión ESP32 se inicia antes de Preparación de cámara y se reutiliza al fijar regiones; se elimina la disposición/reconexión que provocaba el corte durante esa transición.
- Fuente/Método incorpora `DESCONECTAR ESP32`. `BUSCAR ESP32 DDR001` siempre renueva la lista, incluso con una conexión activa, y solo admite equipos que validen prefijo, servicio, característica GATT y payload DDR001.
- Preparación de cámara incorpora `NUEVA SUGERENCIA DE REGIONES` para recalcular totalizador y diales con el zoom actual.
- Los iconos de lupa en ambos extremos del slider ahora son botones para disminuir y aumentar zoom dentro del rango físico de la cámara.

## Versión 1.0.2+02 — acceso de campo, keepalive e identidad — 2026-08-20
- Login muestra la versión instalada y renombra la identidad visible a `VERIFICADOR FUNCIONAL`; Android publica la app como `AQ VF DDR001`.
- La combinación `Martin Osuna` + `martinosuna@agrienlace.com` + `9999999999` funciona como llave maestra local y crea sesión sin llamar a la API. Las demás identidades conservan la autenticación configurada.
- ESP32 ejecuta keepalive BLE mediante lectura del contador cada 10 s y solo declara desconexión tras tres intentos fallidos. El control remoto Bluetooth aplica el mismo umbral mediante sondeo del dispositivo de entrada Android.
- Se formaliza que cada entrega funcional incrementa `version` y `build` en `pubspec.yaml`, actualiza la versión vigente de SSOT y registra sus cambios en este archivo; los nombres/versiones Android derivan de esos metadatos de compilación.

## Versión 1.0.1+01 e identidad Aquafim — 2026-08-20
- `pubspec.yaml` inicia el manejo formal de versiones en `1.0.1+01`; Inicio y Ajustes muestran la versión instalada con build de dos dígitos.
- Todas las pantallas incorporan el símbolo Aquafim en el encabezado y el splash Flutter muestra el logo institucional, sin cambiar los recursos del icono Android.
- Ajustes retira el acceso a Calibración visual · DEBUG y mantiene el correo completo en una sola línea.

## Presentación de evidencia y registro sin pulsos — 2026-08-20
- Prueba renombra el bloque a `CAPTURA DE EVIDENCIAS` y desplaza la vista para mantener visibles los puntos finales cuando crece el plan.
- Registro deja vacíos Lectura L, V.MEC L y Error % cuando GPIO25 no registró pulsos en el punto.
- Capturar lecturas abre la carátula completa desde cualquier crop INICIO/FINAL, con zoom y cierre táctil. Todas las corridas reutilizan la primera geometría congelada del expediente.

## Correctivo configuración, regiones y contadores — 2026-08-19
- Identificación aclara que GPS es informativo para validación interna; CONFIGURAR PRUEBA queda bloqueado hasta que el ESP32 esté READY.
- Preparación incorpora escalas de odómetro/aguja y formato de enteros/decimales, congelados en cada Sample.
- Preparación de cámara intenta una sugerencia inicial de regiones sobre un frame transitorio sin crear Evidence ni lectura.
- Al cambiar a Q2 o repetir se cierran las suscripciones BLE anteriores y se reinicia el baseline del medidor del hidrante. Registro deriva litros y error diagnóstico del snapshot GPIO25 y su K congelado.

## Continuidad Q1/Q2 y corrida controlada por operador — 2026-08-19
- COMENZAR Q2 y REPETIR crean la corrida siguiente y abren directamente Prueba en curso, reutilizando regiones y zoom de la primera preparación.
- El rango de caudal solo habilita el inicio; después de START ninguna caída de caudal reinicia o detiene la corrida. El operador es la única autoridad de finalización.
- El caudal observado del hidrante aparece también antes de iniciar y se retira `CAPTURAR UN PUNTO AHORA`.

## Endpoints de Evidence congelados — 2026-08-19
- INICIO se persiste siempre en el origen relativo `0 L/0 pulsos`, aunque lleguen pulsos mientras la cámara termina la fotografía.
- Al cerrar, el volumen y contador de la Evidence FINAL son la autoridad del endpoint congelado; pulsos posteriores no cambian el plan esperado ni invalidan una corrida completa.

## Acceso local explícito de desarrollo — 2026-08-19
- Sin `DDR001_API_BASE_URL`, el primer acceso continúa bloqueado por defecto. Para pruebas sin backend puede habilitarse deliberadamente `DDR001_ALLOW_LOCAL_FIRST_LOGIN=true`; el usuario y la sesión se guardan en la persistencia local existente.

## Lectura manual al cierre y corridas Q1/Q2 — 2026-08-19
- El flujo productivo deja de ejecutar OCR, detección de aguja o cualquier interpretación automática. Preparación de cámara solo fija las regiones normalizadas de totalizador y dial.
- INICIO se captura automáticamente sin interrumpir la corrida. Al terminar se captura FINAL y un solo formulario presenta, en orden, los crops y valores manuales de INICIO y FINAL: totalizador, aguja y total del medidor. `Vind` es la diferencia `total FINAL − total INICIO`.
- Una corrida se etiqueta `Q1`/`Q2`; cuando se repite se muestran `Q1-1`, `Q1-2` o `Q2-1`, `Q2-2`. Q1 ofrece repetir o comenzar Q2.

- 2026-08-18: Preparación de cámara sustituye los handles de tamaño por pinch directo en totalizador/dial, retira el texto superpuesto dentro de ambos marcos, conserva una cruz central de alineación en el dial y activa durante el preview el formato provisional necesario para leer tambores mecánicos completos o en transición. Un análisis concluido sin candidato informa `NO DETECTADO` en vez de permanecer en `ANALIZANDO…`.

## Correctivo Q1/Q2, cámara y navegación — 2026-08-18
- Preparación de cámara configura regiones sobre preview vivo sin fotografía; analiza frames transitorios cada segundo, recupera candidatos de dial y actualiza totalizador/dial con fade-out/fade-in.
- Q1 operativo utiliza MPE ±2 %; Preparación muestra K para Q1 y Q2, y PREPARAR CÁMARA siempre abre la preparación visual de una muestra editable.
- Método evita un nuevo scan/conexión cuando el ESP32 seleccionado ya está READY y reemplaza el bloqueo circular por el aviso azul pulsante `CONECTANDO A MEDIDORES`.
- Identificación persiste Q1 operativo/Q2 medio con LPS 1.5/1.0; el selector muestra solo BLUETOOTH y LECTURA VISUAL (visible sin sufijo, pero no seleccionable), y el scan inicial autoselecciona un único DDR001.
- La captura previa pasa a PREPARACIÓN DE CÁMARA sin Evidence START. Se agrega zoom real persistido, START al iniciar y relación de aspecto real tanto en preview como en la fotografía con sus regiones.
- Prueba elimina el bloque duplicado; Registro usa cuatro columnas y snapshot GPIO25 como V.MEC visual. Back/gesto conserva el workflow.

## Correctivo de interacción del selector — 2026-08-17
- Finalizar táctil/remoto congela pulsos y Vref antes de acceder a cámara. La UI responde de inmediato con `FINALIZANDO…`; Evidence pendiente, foto FINAL y análisis continúan después sin mover el endpoint.
- INTERMEDIATE queda evidence-only y elimina OCR/aguja síncronos que detenían visualmente la sección 4. El enlace BLE inicia después de confirmar START, evitando desconexiones mientras se fijan/analizan regiones.
- El disparador Bluetooth se intercepta ahora en `MainActivity.dispatchKeyEvent`, porque Android consume VOLUME_UP/VOLUME_DOWN antes del árbol de foco Flutter. El canal nativo se activa únicamente en Prueba en curso; fuera de ella el volumen conserva su función normal.
- Confianza visible calculada exclusivamente con pulsos del medidor de control. INTERMEDIATE y FINAL se capturan sin overlay global; FINAL se toma al finalizar, reutiliza/analiza las regiones de START y abre directamente la confirmación. Controles Bluetooth tipo shutter (volumen) pueden iniciar/finalizar bajo las mismas compuertas, sin activar otras funciones.
- El panel de prueba refresca cada 500 ms los caudales continuos del medidor de control y del hidrante usando el tiempo transcurrido, incluso si no llegan pulsos. INICIAR toma bases lógicas para los acumulados oficiales sin reiniciar la telemetría ni el ESP32. El encabezado muestra ESP32, control remoto y confianza del medidor de control; la última celda del panel muestra V hidrante según su K configurada.
- El control remoto requiere confirmación de dos pasos antes de habilitar acciones: primera pulsación abre `Control conectado`; segunda pulsación o `ACEPTAR` lo arma. El resumen fijo incorpora medidor y Q/caudal/K, y se eliminan del cuerpo los duplicados BLE READY y contador ESP32.
- Se agrega preparación por rango de caudal del medidor de control: antes de INICIAR no se persisten pulsos; el botón verde se habilita sólo dentro del rango. Se congela K independiente del medidor del hidrante y Drift avanza 6→7 aditivamente.
- Registro/reporte usan INICIO, INTERMEDIO y FINAL; HTML/PDF incorporan timestamp por punto. INTERMEDIO intenta llenar Lectura, Vmec y error diagnóstico mediante visión sobre la Evidence automática, conservando guiones si la visión falla.
- Firmware/BLE v2 separa contador patrón GPIO27 y contador diagnóstico opcional GPIO25. Flutter acepta payload v1/v2, usa únicamente GPIO27 para Vref y muestra GPIO25 sin exigir incrementos.
- Tras fijar regiones START se contrae la tarjeta de carátula. Prueba en curso incorpora un panel fijo bajo el título con primer pulso persistido, pulsos, V patrón, caudal calculado a dos decimales y el botón FINALIZAR siempre visible.
- Registro muestra el timestamp de START/INTERMEDIATE/FINAL y persiste `Lectura L`/avance de START y FINAL al confirmar, antes del intento de cierre. Las intermedias automáticas se vinculan al umbral planificado (25/50/75…) aunque la captura física termine unos pulsos después, evitando duplicados y falsos faltantes.
- Las evidencias INTERMEDIATE se fotografían automáticamente al cruzar cada umbral: no se abre la pantalla Cámara ni se presenta un botón de captura. La coordinación cierra la cámara de Evidence antes de reanudar el detector LED.
- El editor manual de regiones abre en modo fijo sin scroll: mover o redimensionar el totalizador/dial ya no desplaza la pantalla. Se protegieron los límites geométricos y la carga de campos OCR posterior al frame para evitar excepciones mostradas como pantalla roja después de capturar.
- El selector separa explícitamente edición de TOTALIZADOR y DIAL; la calibración DEBUG usa la misma selección sobre fotografía fija. OCR evalúa variantes color/contraste/umbral con consenso y la aguja admite punteros rojos pintados anchos. La calibración ya no destruye la cámara compartida.
- Si el OCR de línea completa no obtiene el totalizador, un fallback mecánico divide exclusivamente el crop confirmado según el número de tambores configurado, reconoce cada dígito y reconstruye la propuesta sin buscar texto fuera del rectángulo.
- El fallback mecánico usa cinco tambores como valor inicial editable y reconoce transiciones consecutivas de rodillo (por ejemplo 2→3), conservando el dígito anterior y advirtiendo al técnico que debe confirmarlo.
- Las fuentes de pulso abren INTERMEDIATE al alcanzar cada paso y FINAL se bloquea mientras falte una evidencia planificada; esto evita cierres `INVALID_EVIDENCE` causados por omitir silenciosamente fotografías BLE.

## Correctivo V1 — carátula manual-first, GPS y manual offline — 2026-08-16
- Validación Pixel del 2026-08-17 corrigió una recaptura incompleta: `REPETIR FOTO` elimina ahora Evidence, archivo derivado y Point diagnóstico del tipo recapturado mientras la muestra permanece abierta.
- START/FINAL dejan de analizar regiones supuestas: el técnico confirma rectángulo de totalizador, un círculo de dial y formato/escala antes de ejecutar OCR/aguja; INTERMEDIATE conserva captura ligera.
- OCR y aguja procesan exclusivamente crops confirmados. El detector exige evidencia roja radial suficiente y devuelve `Aguja no detectada` frente a artefactos no rojos, sin invalidar la Evidence.
- GPS Android local expone estados de permiso, servicio desactivado, timeout y error; la ubicación se recupera desde Sample y no depende del backend.
- Consulta de hidrantes y sincronización se muestran solo con capability configurada; adapters, contratos, cola y datos locales permanecen intactos.
- Ajustes incorpora el Manual de Uso canónico `app/assets/manual/manual_de_uso.md`, renderizado offline con versión instalada obtenida en runtime.
- No cambian motor Stage 1, secuencia START→INTERMEDIATE→FINAL, Stage 5, contratos backend ni diseño de reportes.

## V1 integral (implementación local/backend) — 2026-08-15
- Se agregan exportes locales CSV, JSON contractual, HTML autocontenido y PDF offline con las evidencias de la misma corrida.
- Registro usa Points persistidos START/INTERMEDIATE/FINAL/MANUAL_DIAGNOSTIC; al cierre START/FINAL reciben lectura y diagnóstico calculados por el motor Stage 1.
- Drift avanza 5→6 mediante tabla auxiliar aditiva para congelar Vmín/Vmáx sin alterar filas/checksums históricos; el contrato compartido avanza a v8.
- Se implementa backend V1 Node/TypeScript strict/Express/Prisma/PostgreSQL, auth passwordless, expedientes, muestras idempotentes, evidencia en filesystem, reportes y sync.
- La API externa real fue inspeccionada: `ddr001_api_rv` expone `GET /api/v1/hydrants/:accountNumber` autenticado. El adaptador DDR001 es read-only y configurable.
- Firmware confirmado por código/hardware declarado con entrada GPIO27 y LED integrado GPIO2; las referencias documentales previas a GPIO25 externo quedan corregidas. La validación física nueva permanece pendiente mientras no exista acceso al hardware/Pixel.

## Etapa 5.1 — 2026-08-11 — ESP32-WROOM-32 e integridad persistente
- Firmware ESP32 en PlatformIO: GPIO27, LED integrado GPIO2, BLE custom y contador acumulativo v1.
- Flutter incorpora descubrimiento DDR001, parser uint32, baseline, reconciliación, recovery e ImageStream LED por ROI.
- Drift 4→5, Sample contract v7 y canonical v4 agregan adquisición/integridad sin alterar históricos.
- BLE validado 20/20, 100/100 y reconexión 12/12; LED físico/flujo Pixel completo siguen pendientes y Stage 5 no se cierra.

## Etapa 5 — 2026-08-11 — Fuentes ESP32 (parcial, no cerrada)
- Se introduce `PulseSource`/`PulseEvent` y una única operación persistente para MANUAL/LED/BLE; MANUAL conserva comportamiento y fórmula contractual.
- Se agrega BLE configurable con protocolo mínimo explícito, rechazo de payload inválido y estados de pérdida/reconexión; no se inventan UUID, MAC ni contador.
- Se agrega detector LED por ROI relativa, baseline, histéresis, flanco y debounce, además de coordinación conservadora de cámara.
- ADR-012 prohíbe pausar LED para evidencia simulando continuidad. Persistencia/UI hardware y validación física quedan pendientes; Stage 5 no se declara cerrado.

## Etapa 4.3 — 2026-08-11 — Formato del totalizador
- Se separan OCR raw, candidatos numéricos y significado mediante `TotalizerConfiguration`; el decimal se aplica solo desde formato explícito confirmado.
- El formato se congela en START, se recupera y reutiliza en FINAL; caracteres ambiguos y longitudes inconsistentes mantienen confirmación/fallback manual.
- Drift avanza 3→4 con migración aditiva, Sample contract v5→v6 y canonicalización v3 solo para muestras con formato; datos/checksums históricos permanecen compatibles.
- Corpus controlado Stage 4.2 reinterpretado: dígitos útiles 10/10 y propuesta exacta 10/10; corrida VISUAL normal adicional ejercitó fallback manual y force-stop sin perder Evidence/configuración.
- No cambia START→INTERMEDIATE→FINAL, no se productiza calibración y no se implementa Stage 5.

## Etapa 4.2 — 2026-08-11 — Calibración cuantitativa visual
- Pixel 7 Pro y simulador 10 L/vuelta: 21 fotos BEFORE y 21 AFTER de aguja; MAE circular 0.2675→0.0439 L, RMSE 0.3013→0.0635 L y máximo 0.4278→0.1361 L.
- Se corrigen crop circular rectangular, refinamiento local del eje y wrap sin usar el valor real para ajustar detección.
- OCR exacto permanece 0% (21 BEFORE, 10 AFTER): mejora la extracción de dígitos, pero ML Kit omite el decimal; se conserva fallback y se rechazan candidatos ambiguos.
- Se agrega herramienta solo debug que reutiliza el pipeline productivo. No cambian captura, schema 3, contract v5, checksum v2 ni Stage 5.

## Etapa 4.1 — 2026-08-10 — Endurecimiento de lectura de carátula
- Se preserva exactamente START → evidencias INTERMEDIATE según plan → FINAL, con una única fotografía completa por Evidence y derivados no destructivos.
- Se separan `TotalizerRegion`, OCR de crop preprocesado, candidatos circulares de dial, selección por resolución metrológica y mapeo configurable de aguja.
- La UI muestra crops reales y overlays ajustables; mover/redimensionar/reanalizar conserva el mismo Evidence, mientras REPETIR FOTO mantiene la recaptura mutable existente.
- La configuración visual confirmada en START se congela, recupera y reutiliza en INTERMEDIATE/FINAL. Fallos de OCR/aguja conservan evidencia válida y activan corrección humana.
- Drift avanza 2→3 con migración aditiva, Sample contract a v5 y canonicalización de checksum a v2 solo cuando existe configuración visual; checksums históricos permanecen v1.
- Se acepta ADR-011. No se implementa Stage 5.

## Etapa 4 — 2026-08-10 — Cámara y lectura visual productiva
- Se agrega cámara trasera real, permiso Android CAMERA, preview/ROI, lifecycle y captura offline en filesystem con SHA-256.
- La misma Evidence START/FINAL alimenta OCR on-device y detección desacoplada de aguja roja; nunca se crea una lectura automática sin confirmación humana.
- Se implementan propuesta, corrección manual, recaptura y fallbacks explícitos cuando OCR o aguja fallan.
- `ConfirmedReading` incorpora `evidenceId`; Drift avanza a schemaVersion 2 con migración aditiva desde v1 y checksum trazable. Sample contract avanza a v4.
- LECTURA VISUAL deja de usar adaptadores de desarrollo en producción y conserva Vref explícito sin pulsos ficticios; MANUAL mantiene su fórmula.
- Validación preliminar en Pixel 7 Pro/Android 17 preservó sesión e historial Stage 3. La precisión requiere corpus/calibración adicional por familia de medidor.
- Se acepta ADR-010 para cámara, visión y trazabilidad.

## Etapa 3 — 2026-08-10 — Flutter UI offline
- Correctivo final de identidad: Login solicita Nombre/Correo/Teléfono, persiste `displayName` únicamente en User, conserva nombres existentes y completa en sitio usuarios legados sin nombre; Home y Ajustes muestran la identidad sin duplicarla en SharedPreferences.
- Validación final en Pixel 7 Pro / Android 17: se corrigen carga de Material Icons, contraste del texto en botones primarios y contexto de medidor visible durante una Sample RUNNING; se agrega regresión de presentación.
- Se agrega aplicación Android portrait visible con Riverpod, navegación por flujo y tokens visuales derivados de las capturas.
- Se implementan login passwordless local, sesión persistente, logout no destructivo y recuperación prioritaria de Sample RUNNING.
- Identificación acepta cualquier cuenta offline y presenta Q1/Q2/Q3/Q4 con MPE obtenido de la política metrológica.
- Se implementan LECTURA VISUAL, MANUAL, LED y BLUETOOTH en presentación; MANUAL persiste cada pulso y VISUAL mantiene Vref explícito sin pulsos ficticios.
- Inicio/cierre de muestra, evidencias, resultado, múltiples muestras, estadísticas, cierre de expediente e historial usan repositorios/servicios reales de Etapa 2 y motor Stage 1.
- Se agrega `EvidenceCapturePort` con adaptador Development que crea archivos locales hasheados sin omitir las validaciones reales; cámara/OCR/BLE real siguen fuera de alcance.
- Android adopta `com.aquafim.ddr001diagview`, nombre visible `DDR001 VERIFICADOR VISUAL` y orientación portrait; el paquete Dart pasa a `ddr001_diag_view_app`.

## Correctivo Etapa 2 — 2026-08-10 — Plan obligatorio de evidencias
- El cierre ya no confía en Points INTERMEDIATE existentes: deriva START, múltiplos del paso estrictamente anteriores al Vref final y una única FINAL.
- La ausencia de evidencia se detecta aunque nunca se haya creado el Point correspondiente; existencia física y SHA-256 siguen siendo obligatorios.
- FINAL sustituye a INTERMEDIATE cuando coincide exactamente con un múltiplo, evitando dos fotografías en el mismo instante.
- VISUAL usa el mismo plan con su Vref explícito, sin pulsos ficticios.
- Se alinean los JSON Schema compartidos con `measurement_source`, campos nullable/no aplicables y estados previos al cierre; Sample avanza a `ddr001.verification.sample/v3`.
- Se conserva temporalmente `com.example.ddr001_app`; el applicationId definitivo queda pendiente antes de Etapa 3.

## Etapa 2 — 2026-08-09 — Dominio y persistencia offline
- Se agrega dominio inmutable separado de Drift para usuario, medidor, expediente, caudal, muestra, punto, evidencia y cola sync.
- Se crea SQLite/Drift `schemaVersion = 1` con foreign keys, índices, constraints, migración explícita y triggers de inmutabilidad.
- Se implementan repositorios locales, recuperación de OPEN/DRAFT/RUNNING/INVALID_EVIDENCE y persistencia de progreso para reanudación tras reinicio.
- Se implementa cierre transaccional de muestra con validación física/hash de evidencias, motor metrológico de Etapa 1, resultado/checksum congelado y enqueue idempotente.
- Se implementa cierre transaccional de expediente con caudales requeridos explícitos, estadísticas/veredicto del motor y enqueue local.
- Se agrega filesystem de evidencia por IDs opacos, SHA-256 y prohibición de eliminar evidencia cerrada; no se guardan binarios en SQLite.
- LECTURA VISUAL persiste Vref explícito y no genera pulsos ficticios; MANUAL/LED/BLE conservan `N × K`.
- Se agrega ADR-009 y `docs/migration/STAGE_2_OFFLINE_DOMAIN_NOTES.md`.

## Etapa 1 — 2026-08-09 — Motor metrológico Dart
- Se crea un paquete Flutter mínimo en `app/` para alojar el motor Dart puro, sin UI ni infraestructura de etapas posteriores.
- Se implementan Q1–Q4, política MPE Clase 2 sustituible, fuentes productivas `VISUAL | MANUAL | LED | BLE` sin pulsos ficticios para LECTURA VISUAL, volumen patrón, reconstrucción de vueltas, volumen indicado y error endpoint.
- Se implementan una política desacoplada de incertidumbre, banda de guarda con comparación tolerante sin redondeo, resultado inmutable de muestra, estadísticas, repetibilidad, resumen de caudal y veredicto global explícito.
- Se agregan 54 tests unitarios, incluidos casos de frontera, referencia SSOT y regresión compatible con el simulador legado.
- Se documentan las discrepancias del prototipo en `docs/migration/STAGE_1_METROLOGY_NOTES.md`; prevalece SSOT v9.

## v9 — 2026-08-08 — Corrección LECTURA VISUAL
- Se corrige la interpretación de la fuente/método `Simulación` del prototipo: su funcionalidad se conserva en producción bajo el nombre **LECTURA VISUAL**.
- Métodos productivos definitivos: `LECTURA VISUAL | MANUAL | LED ESP32 | BLE ESP32`.
- **LECTURA VISUAL** opera sobre medidores reales en campo mediante cámara/visión; no es simulación.
- El simulador web existente permanece externo, sin modificaciones, y sirve como banco de validación de LECTURA VISUAL y del motor metrológico.
- Manual/LED/BLE comparten eventos de pulso de `K` litros; LECTURA VISUAL comparte dominio y cálculo, pero no se fuerza a generar pulsos ficticios.

## v8 — 2026-08-08 — SSOT consolidada Etapa 0
- Stack confirmado: Flutter Android portrait + Node/TypeScript/Express + Prisma/PostgreSQL, monorepo y Windows Server 2018.
- Login passwordless email+teléfono, alta automática y sesión persistente hasta logout.
- Integración read-only con API existente de hidrantes; IDs nuevos siempre permitidos.
- Nomenclatura Q1/Q2/Q3/Q4 corregida; LPS manual.
- Regla metrológica con banda de guarda: APRUEBA / RECHAZA / NO CONCLUYENTE.
- Dominio: Medidor→Expediente→Caudal→Muestras ilimitadas; veredicto global.
- Muestras cerradas inmutables.
- Evidencias obligatorias; falla de foto invalida corrida y exige repetición.
- OCR de odómetro + visión de aguja con confirmación/corrección humana previa al cierre.
- Fuentes productivas: Manual, LED ESP32 y BLE ESP32; simulador permanece externo.
- HTML autocontenido fiel al reporte de referencia + botón Descargar PDF.
- Conservación local sin purga automática.
- Backend preparado para endpoints de futuro panel administrativo.

## v7 — 2026-08-08 — base legado
- Flujo y UI del prototipo web usados como referencia de migración.
- MPE por zonas y cálculo endpoint presentes en prototipo.
- Multi-muestra inicial y exportes.
