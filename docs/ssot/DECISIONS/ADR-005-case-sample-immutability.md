# ADR-005 — Expediente, muestras ilimitadas e inmutabilidad
- **Estado:** aceptada
- **Fecha:** 2026-08-08
- **Decisión:** jerarquía Medidor→Expediente→Caudal→Muestras. Cada caudal admite muestras ilimitadas. Una muestra cerrada válida no puede editarse; una corrección es una nueva muestra. El expediente produce veredicto global.
- **Consecuencias:** trazabilidad completa y modelo preparado para panel/auditoría.
