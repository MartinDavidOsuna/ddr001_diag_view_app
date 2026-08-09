# FUNCTIONAL_SPEC — Especificación funcional

## 0. Reglas generales
- Android portrait.
- UI fiel a `design/screenshots/`; no replicar controles del navegador.
- Offline-first.
- Muestras cerradas inmutables.
- El simulador web legado es únicamente una herramienta externa de validación y no se integra. La **funcionalidad de lectura visual** que representa sí es productiva y se utilizará con medidores reales en campo.

## 1. Login persistente (`features/auth`)
- Campos: correo y teléfono.
- No hay contraseña ni pantalla de registro.
- Primer login online: backend busca `email + phone`; si no existe, crea usuario automáticamente.
- Guarda sesión y perfil local.
- Aperturas posteriores reutilizan sesión sin pedir login.
- Si está offline y existe sesión local válida, entra a la app normalmente.
- Única salida voluntaria: botón existente/definido **Cerrar sesión**.

## 2. Identificación (`features/identification`)
- ID/número de cuenta del medidor: texto libre, cualquier valor permitido.
- Consulta opcional/automática de solo lectura al sistema de hidrantes cuando haya conectividad.
- Estados visibles: localizado con datos previos / localizado sin levantamiento / no localizado-nuevo / consulta pendiente por falta de red.
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

Manual, LED y BLE comparten una interfaz común de eventos de pulso. **LECTURA VISUAL** comparte el mismo dominio de muestra, evidencias y cálculo metrológico, pero su adquisición proviene de las lecturas visuales del medidor y no debe forzarse artificialmente a emitir pulsos.

El modo que en el prototipo web se denominaba **Simulación** debe migrarse a Flutter como **LECTURA VISUAL**, eliminando cualquier semántica de simulación en la app productiva. El simulador web externo permanece sin cambios y se usa para validar esta implementación.

## 4. Carátula y cámara (`features/camera_dial`)
- Vista en vivo y estado de cámara.
- ROI/ajustes necesarios para lectura de carátula.
- Detección automática de aguja roja; si falla: mensaje explícito `Aguja no detectada`.
- OCR automático del odómetro.
- Toda lectura automática exitosa se presenta al técnico para confirmación: `Lectura detectada: ... ¿Es correcta?`.
- Si OCR/aguja falla, se habilita captura manual de la lectura correspondiente.
- La confirmación/corrección es posible antes de cerrar la muestra.

## 5. Ejecución de muestra (`features/test_run`)
Estados mínimos: `draft → ready → running → awaiting_reading_confirmation → closed_valid | invalid_evidence`.

### Iniciar
- Captura GPS si es posible.
- Congela configuración de la muestra.
- Fija contador origen.
- Captura evidencia inicial obligatoria.
- Si la fotografía inicial falla, no inicia una muestra válida; informa y permite reintentar.

### Durante
- Indicadores: pulsos, V patrón, tiempo, incertidumbre estimada.
- Captura intermedia automática según paso (25 L default).
- Puede existir captura diagnóstica manual adicional.
- Si una evidencia intermedia obligatoria falla, la muestra queda `invalid_evidence`; el técnico debe repetir la prueba.

### Finalizar
- Captura final obligatoria.
- Si falla, marca `invalid_evidence` y ofrece repetir.
- Abre captura/confirmación de lecturas.
- Calcula solo cuando lecturas inicial/final estén confirmadas.

## 6. Registro (`features/registry`)
Tabla de puntos: tipo, pulsos, V patrón, lectura, V mecánico, error diagnóstico y referencia a evidencia.

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
