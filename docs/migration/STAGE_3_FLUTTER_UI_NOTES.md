# Etapa 3 — Flutter UI, navegación y estado de presentación

## Arquitectura de presentación

La aplicación se compone en `app/lib/app/` y presenta módulos bajo `app/lib/presentation/`. Riverpod 2.6 administra un `AppController`/`AppViewState` único para el flujo de campo; los widgets no importan Drift, no ejecutan SQL y no calculan fórmulas metrológicas. El controlador consume exclusivamente repositorios y servicios de dominio de Etapa 2.

La navegación es un flujo de estado explícito con `AnimatedSwitcher`: carga, login, recuperación, inicio, identificación, método, configuración, prueba, lecturas, resultado, resumen, historial y ajustes. El botón Back durante una muestra RUNNING solicita confirmación y nunca invalida ni elimina la corrida.

## Sesión y bootstrap

`main.dart` fija portrait, crea Drift/filesystem/repositorios y monta `ProviderScope`. La sesión guarda únicamente `active_user_id` en `shared_preferences`; nombre, correo y teléfono viven en el `User` de SQLite y no se duplican en preferencias. No hay contraseña, token ficticio ni secreto. Login exige nombre, normaliza correo/teléfono, busca o crea el User local y permanece hasta logout. `email + phone` siguen siendo la llave; `displayName` es identidad, no credencial. Logout no elimina usuarios ni expedientes.

Los usuarios nuevos guardan `displayName` recortado. Si `email + phone` encuentran una identidad con nombre, se conserva ese nombre aunque el campo de login contenga otro valor. Si encuentran un usuario legado con `displayName` nulo/vacío, se completa el mismo registro y `user_id`, preservando sus expedientes. Home saluda `Hola, <displayName>` y Ajustes muestra nombre, correo y teléfono; el fallback legado sin nombre es simplemente `Hola`.

Al iniciar con sesión, el controlador consulta muestras incompletas. Una RUNNING abre primero “Prueba en curso”, con contexto de medidor, caudal, método, inicio y progreso, y solo permite reanudarla o conservarla.

## Pantallas y diseño

Se implementaron Login, Inicio, Recuperación, Identificación, selector VISUAL/MANUAL/LED/BLUETOOTH, configuración congelada, prueba, registro/evidencias, confirmación inicial/final, resultado, INVALID_EVIDENCE, muestras/estadísticas, resumen/cierre, historial local y ajustes mínimos.

Las capturas y el prototipo aportaron los tokens `#0F1826`, `#17263A`, `#0F1C2C`, `#1F3B5C`, `#1F5C99`, verde/rojo/ámbar, tarjetas de radio 12, campos oscuros, botones grandes, encabezado degradado y jerarquía numerada. No se copiaron barras de navegador ni funciones de exportación/reportes. La nomenclatura SSOT reemplaza etiquetas heredadas incorrectas: Q1/Q2/Q3/Q4 y LECTURA VISUAL.

## Operación real offline

- “Iniciar prueba” crea Sample DRAFT real, congela configuración, transiciona a RUNNING y persiste START.
- MANUAL incrementa pulsos, calcula el progreso con `N × K` mediante el modelo vigente y lo persiste tras cada toque.
- El cierre persiste lecturas confirmadas y delega evidencia, cálculo, checksum, inmutabilidad y sync queue a los servicios Stage 2.
- Resultados, estadísticas, repetibilidad y veredictos provienen del motor Stage 1 o del resultado congelado; los widgets solo formatean.
- Nueva muestra conserva todas las anteriores y no impone máximo.
- Historial lee expedientes locales y permite abrirlos en modo lectura cuando están cerrados.

## Adaptadores temporales

`DevelopmentEvidenceCaptureAdapter` implementa `EvidenceCapturePort`: genera un archivo placeholder claramente identificado, calcula SHA-256 con el filesystem real y persiste metadata real. No salta el plan de evidencia ni la validación de cierre. La UI permite desactivarlo para recorrer INVALID_EVIDENCE.

LECTURA VISUAL usa ingreso de desarrollo para lecturas y Vref confirmado, con `pulseCount = 0`. LED/BLE muestran estados no conectado/preparando/listo/error/desconectado sin solicitar permisos ni crear hardware. No hay cámara, OCR, visión ni BLE real.

## Android

- applicationId/namespace/package Kotlin: `com.aquafim.ddr001diagview`.
- nombre visible: `DDR001 VERIFICADOR VISUAL`.
- orientación: portrait en manifest y bootstrap Flutter.
- nombre de paquete Dart: `ddr001_diag_view_app`.

## Diferencias y pendientes

Las capturas disponibles documentan principalmente el flujo monolítico legado, no Login/Home/Recuperación/Historial; esas pantallas usan los mismos tokens y componentes sin agregar funciones administrativas. No se muestran cámara real, exportar CSV/HTML ni reporte porque pertenecen a etapas posteriores.

Stage 4 debe sustituir los puertos de desarrollo de lectura/evidencia por cámara, OCR y visión con confirmación humana. Stage 5 sustituirá estados LED/BLE por fuentes reales. No se implementaron reportes ni conectividad remota.

## Validación en dispositivo Android físico

El 2026-08-10 se instaló y recorrió la aplicación debug en un Google Pixel 7 Pro (`arm64-v8a`) con Android 17 / API 37. Se validaron login y sesión tras `force-stop`, expediente offline con medidor no consultado externamente, Q3, MANUAL, incremento exacto de pulsos y Vref, recuperación de una Sample RUNNING tras cerrar y abrir el proceso, advertencia del botón Back, plan START/INTERMEDIATE/FINAL, lecturas de desarrollo, resultado del motor, dos muestras, repetibilidad no evaluable para n=2, cierre read-only e historial local. La rotación forzada del dispositivo mantuvo `SCREEN_ORIENTATION_PORTRAIT`. No se observaron excepciones Flutter/Drift/filesystem, asserts ni overflows persistentes en logcat.

La validación detectó y corrigió tres defectos de Stage 3: la fuente de Material Icons no estaba declarada, el texto de botones primarios no tenía contraste suficiente y la pantalla RUNNING omitía visualmente el identificador del medidor aunque el estado lo conservaba. INVALID_EVIDENCE permanece validado por tests automatizados; no se fabricó una tercera corrida inválida durante este recorrido del expediente principal.

En el ancho lógico del Pixel, el selector de cuatro métodos distribuye BLUETOOTH en una segunda línea para conservar legibilidad y área táctil. Es una diferencia responsiva frente a la fila compacta del prototipo, sin pérdida funcional. Cámara/OCR/visión y hardware LED/BLE siguen expresamente pendientes de Stage 4/5.
