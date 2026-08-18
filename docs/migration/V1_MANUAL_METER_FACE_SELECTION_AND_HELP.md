# Correctivo V1 — selección manual de carátula, GPS y ayuda

## Correctivo de interacción 2026-08-17

La selección de regiones entra en un modo de edición de pantalla fija. El scroll del flujo se deshabilita mientras el técnico mueve o redimensiona el rectángulo del totalizador y el círculo del dial. `FIJAR REGIONES` regresa a formato/análisis; al ajustar una lectura analizada, `APLICAR Y REANALIZAR` procesa los nuevos crops. Los límites de ambos selectores se protegen y los controladores OCR se hidratan después del frame para impedir excepciones de render tras capturar.

El modo fijo incluye selección explícita `TOTALIZADOR / DIAL`, por lo que las regiones superpuestas no compiten por el mismo gesto. La herramienta DEBUG captura primero, permite seleccionar ambas regiones sobre la fotografía y después calibra/analiza. El pipeline prueba tres derivados locales del mismo crop (color, contraste y umbral) y solo propone totalizador configurado cuando existe consenso; el detector calcula el eje central de agujas rojas anchas. La pantalla DEBUG pausa, pero nunca dispone, la cámara compartida.

En adquisición por pulsos, al alcanzar `evidenceStepLiters` se abre la captura INTERMEDIATE. No se permite solicitar FINAL con intermedias faltantes. La muestra BLE física de 322 pulsos inspeccionada durante este correctivo tenía START/FINAL pero carecía de 25…300 L y por eso permanece correctamente inmutable como `INVALID_EVIDENCE`; el correctivo aplica a muestras nuevas.

## Motivo

El análisis automatic-first podía tomar números ajenos al totalizador o artefactos de la carátula como aguja. Las distintas marcas colocan totalizador y uno o varios diales sin una geometría universal. V1 adopta selección humana manual-first sin cambiar metrología ni evidencias.

## Comportamiento

- START conserva una fotografía completa hasheada y abre `CONFIGURAR LECTURA` sin OCR/aguja previo.
- El técnico mueve y redimensiona el rectángulo para incluir solo dígitos; después selecciona con un círculo exactamente el dial de mayor resolución metrológica que usará.
- Confirma dígitos, decimales y una escala ya soportada. `ANALIZAR LECTURA` persiste la configuración y procesa únicamente ambos crops.
- START congela la configuración; FINAL la presenta como guía y permite `AJUSTAR REGIONES` sobre la misma Evidence. INTERMEDIATE conserva evidencia/registro ligero sin exigir OCR perfecto.
- La aguja requiere componente rojo coherente con eje y dirección radial. Un fallo muestra `Aguja no detectada` y permite corregir, ajustar o repetir foto sin convertir la Evidence íntegra en inválida.
- La reanudación recupera Evidence, rectángulo, círculo, escala y formato persistidos.

## GPS

`GeolocatorLocationAdapter` captura latitud, longitud, precisión y timestamp con alta precisión y timeout. Se distinguen permiso denegado, denegación permanente, servicios apagados, timeout y error. La acción está en Identificación y se reintenta al iniciar; nunca depende de internet ni bloquea indefinidamente.

## Capabilities remotas

Consulta de hidrantes y sync no configurados se ocultan en UI. Los estados operativos reales (Evidence, Sample, Flow y cola sync) no se alteraron. Variables y criterio de reactivación: `SERVER_DEPENDENT_PENDING.md`.

## Manual de Uso

La fuente única es `app/assets/manual/manual_de_uso.md`, incluida por `pubspec.yaml` y renderizada como Markdown seleccionable desde `Ajustes > Manual de uso`, sin WebView ni red. La pantalla obtiene versión/build instalada mediante `package_info_plus`. `AGENTS.md` obliga a revisar esta fuente en todo cambio visible para el técnico.

## Pruebas y validación

- Layouts arriba/abajo/izquierda/derecha/borde y selección exclusiva de una de cuatro zonas.
- OCR y aguja reciben solamente crops confirmados.
- Aguja roja válida se conserva; línea negra, reflejo, tornillo, marca y sombra se rechazan.
- GPS: éxito, denegado, permanente, servicio apagado, timeout/error y recuperación persistida.
- Sin API no aparece `Pendiente de consulta`; Manual abre desde el asset offline y contiene los temas contractuales.
- Validación física Pixel queda objetivamente pendiente si `adb devices` no presenta un dispositivo autorizado.

El 2026-08-17 el Pixel 7 Pro confirmó upgrade sin borrar datos, recovery de la muestra RUNNING, GPS offline con precisión reportada, Manual empaquetado y entrada manual-first después de FINAL. La prueba detectó y corrigió que `REPETIR FOTO` dejaba un Point diagnóstico huérfano; la recaptura elimina ahora Evidence, archivo y Point correspondiente.

No se modificaron motor Stage 1, START→INTERMEDIATE→FINAL, reglas de Evidence, ESP32/BLE/LED, backend, contratos o reportes.
