# ADR-024 — Paridad de presentación de SIMULACIÓN Android y Web

- **Estado:** aceptada
- **Fecha:** 2026-09-10

## Contexto

La demo reducida omitía preparación, captura de evidencias, registro,
repeticiones y resumen; los indicadores de hardware aparecían fuera de la
prueba. Se requiere representar el procedimiento de campo, no otro simulador.

## Decisión

- Conservar la entrada Web autónoma de ADR-023 sin auth, API, SQL ni hardware.
- Replicar pantallas/orden de controles de SIMULACIÓN Android en portrait,
  incluyendo configuración, fotos, registro, lecturas, repeticiones, resumen,
  recuperación, ajustes, manual y exportes. No añadir una cámara física al
  modo que tampoco la usa en Android.
- Compartir tema, tarjetas y avisos, motor y generador de caudal. Extraer el
  renderizador de reportes del filesystem nativo e inyectar lectura de bytes:
  Android lee sus archivos; Web lee el asset simulado validado por SHA-256.
- Capturar snapshots de evidencia durante la adquisición; no sintetizar una
  lista de fotos al calcular. Congelar FINAL antes de captura manual, sin
  rellenar valores en función del volumen patrón.
- Guardar borrador, parámetros y fotos como JSON local aditivo. No abrir Drift.
- Mostrar indicadores verdes sólo en Prueba en curso, incluido el preflujo.

## Consecuencias

- Los exportes comparten implementación y pruebas con Android; el navegador
  los descarga y puede compartirlos cuando soporta Web Share.
- El historial antiguo se lee sin modificar sus resultados ni agregar evidencia
  inexistente. Los reportes antiguos pueden no tener fotos.
- Los únicos controles no operativos son los que exigirían hardware, GPS o
  sesión reales; no se presentan conexiones, usuarios o ubicaciones físicas
  ficticias. La presentación usa una identidad local explícitamente simulada.
- API, metrología, Drift y fuentes productivas Android no cambian.
