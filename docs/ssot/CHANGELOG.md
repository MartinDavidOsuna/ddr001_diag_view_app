# CHANGELOG funcional

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
