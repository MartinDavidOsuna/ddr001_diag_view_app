# ADR-026 — Sincronización productiva y cámara preparada

- Estado: aceptada
- Fecha: 2026-09-18
- Versión: 1.7.2+21

## Contexto

El APK 1.7.1+20 instalado carecía de URL API, por lo que ocultaba SYNC.
Los accesos maestros y las sesiones restauradas sólo poseían identidad local.
Además, confirmar regiones cerraba la cámara; START la reabría, reaplicaba
óptica y añadía 250 ms. El operador observó varios segundos de avance de aguja.
El operador reportó conteo aparentemente correcto tras configurar pulsos de
80 ms en el flujómetro; este cambio externo no certifica toda la cadena.

## Decisión

- Publicar configuración de build productivo sin secretos y mantener vacío el
  define como opción de desarrollo offline. La excepción de transporte HTTP
  se limita al hostname actual; no cambia el servidor.
- Autenticar explícitamente al sincronizar, incluidas sesiones maestras o
  restauradas. Reutilizar credenciales sólo con vínculo remoto coincidente.
  Una denegación de acceso no se convierte en un nuevo login para eludirla.
- Preparar sensor/zoom/enfoque antes de habilitar INICIAR, conservar la cámara
  entre preparación y adquisición y usar el disparo nativo sin esperas
  artificiales. Mantener resolución y enfoque automático; no introducir ZSL
  ni frames anteriores al botón como evidencia. Remover reenfoque cada 4 s.
- START excluye captura concurrente y FINAL hasta persistir su evidencia.
  Mantener el endpoint de conteo vigente: no añadir pulsos posteriores a FINAL
  para compensar la latencia de la foto. No reinterpretar muestras cerradas.
- Registro técnico distingue solicitud de disparo y archivo disponible;
  no representa timestamp exacto del sensor ni demuestra exposición inmediata.
- Una falla al persistir un pulso BLE se hace visible, bloquea FINAL y se marca
  comprometida cuando storage lo permite. El deduplicador sólo consume una
  secuencia tras guardarla; una falla no inutiliza la cola para futuras pruebas.

## Límites

Sin cambio de firmware, filtros ESP32, K, protocolo BLE, esquema Drift,
checksums ni fórmulas. Se requiere verificar físicamente nitidez y retardo en
Pixel, además del ACK productivo del expediente, después de instalar. Esta
entrega sólo copia el APK y no sustituye la app ni altera sus datos.
