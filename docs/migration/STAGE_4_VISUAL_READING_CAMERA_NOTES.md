# Etapa 4 — Cámara y lectura visual

## Arquitectura

La infraestructura se divide en puertos de cámara, OCR, detección de aguja y pipeline visual bajo `app/lib/infrastructure/`. Presentación nunca consume directamente los plugins. `CameraEvidenceCaptureAdapter` impide placeholders en producción; los adaptadores Development/Fake permanecen solo para tests host.

## Cámara y permisos

- `camera 0.12.0+2`, cámara trasera principal, `ResolutionPreset.high`, JPEG, audio desactivado, autoenfoque y autoexposición cuando están disponibles.
- Único permiso Android: `CAMERA`. No se solicitan permisos amplios de almacenamiento.
- Estados explícitos: concedido, denegado, denegado permanentemente y no disponible. El estado permanente ofrece abrir Ajustes.
- La pantalla pausa/libera la cámara durante análisis, background y navegación, y la restaura al volver o recapturar.

## Pipeline y ROI

La captura se importa primero a `EvidenceFileStore`, se calcula SHA-256 y se persiste. Ese mismo archivo se decodifica, normaliza mediante orientación EXIF, recorta con ROI proporcionales y alimenta OCR y aguja. La ROI de carátula por defecto es `(0.08, 0.16, 0.84, 0.68)` y la sub-ROI de odómetro `(0.18, 0.08, 0.64, 0.25)` respecto de la carátula. No hay coordenadas ligadas al Pixel.

ML Kit reconoce texto latino on-device. El parser separa candidatos numéricos, informa ambigüedades y no inventa confianza si la API no la entrega. La aguja roja se obtiene por dominancia cromática, anillo radial, bins angulares ponderados y rechazo por confianza. El mapeo está separado: cero `-90°`, sentido horario y `100 L/vuelta` por defecto.

## Confirmación y trazabilidad

`VisualReadingProposal` contiene Evidence ID/path, texto OCR, candidatos, ángulo/litros, advertencias y timestamp. La confirmación sin cambios produce `AUTO_CONFIRMED`; cualquier corrección produce `MANUAL`. START alimenta lectura inicial y FINAL la final. INTERMEDIATE usa captura asistida y el plan obligatorio de Stage 2, sin forzar una lectura endpoint. Recapturar elimina únicamente la evidencia/archivo aún mutable.

`ConfirmedReading.evidenceId` enlaza la lectura con Evidence. Drift schemaVersion 2 agrega `initial_reading_evidence_id` y `final_reading_evidence_id` nullable mediante migración aditiva 1→2 y el checksum las incluye. El contrato Sample avanza a `ddr001.verification.sample/v4`.

## LECTURA VISUAL y otros métodos

LECTURA VISUAL usa START/FINAL reales y Vref operativo explícito, sin pulsos ficticios. MANUAL conserva `N × K`; cámara/evidencia también se usa cuando el plan lo exige. LED/BLE reales siguen fuera de alcance.

## Validación Pixel 7 Pro

Se instaló como actualización, sin desinstalar ni borrar datos, en Pixel 7 Pro `27301FDH3004R7`, Android 17/API 37 arm64. Sobrevivieron sesión e historial Stage 3. Se verificaron permiso, preview, ROI, captura START/FINAL, recaptura, background/foreground, persistencia/reanudación y fallback manual.

En la prueba preliminar con medidor, OCR no produjo candidato y se usó la corrección humana prevista. La aguja sí produjo propuestas (31.39 L y 96.39 L en capturas distintas), pero esos valores no constituyen medición de precisión porque cambiaron encuadre/iluminación y aún no existe un corpus calibrado por modelo. La app rechazó controladamente imágenes sin componentes detectables.

## Limitaciones

- ROI/centro/calibración por defecto deben validarse con un corpus representativo antes de afirmar precisión de campo.
- ML Kit emite una advertencia de compatibilidad futura del Kotlin Gradle Plugin al compilar con la cadena actual; no impide build ni ejecución.
- No se implementaron BLE, LED/ESP32, backend, sincronización ni reportes.
