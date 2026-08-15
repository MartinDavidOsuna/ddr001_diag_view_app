# CHANGELOG funcional

## Etapa 5.1 — 2026-08-11 — ESP32-WROOM-32 e integridad persistente
- Firmware ESP32 en PlatformIO: GPIO27, LED GPIO25, BLE custom y contador acumulativo v1.
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
