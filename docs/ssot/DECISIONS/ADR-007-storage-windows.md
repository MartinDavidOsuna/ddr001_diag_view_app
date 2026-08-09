# ADR-007 — Almacenamiento inicial de evidencia
- **Estado:** aceptada
- **Fecha:** 2026-08-08
- **Contexto:** despliegue inicial en Windows Server 2018.
- **Decisión:** PostgreSQL almacena metadata; binarios de evidencia/reporte se guardan en filesystem administrado por backend. Acceso mediante interfaz de storage abstraída.
- **Consecuencias:** despliegue inicial simple; una futura migración a S3-compatible no debe alterar entidades ni contratos de dominio.
