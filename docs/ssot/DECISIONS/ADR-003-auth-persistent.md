# ADR-003 — Login passwordless y sesión persistente
- **Estado:** aceptada
- **Fecha:** 2026-08-08
- **Contexto:** uso de campo; se quiere autenticar una sola vez sin passwords.
- **Decisión:** login con email + teléfono; alta automática en primer login; sesión persistente hasta logout explícito. Primer login requiere backend; uso posterior puede continuar offline.
- **Consecuencias:** no existe pantalla de registro ni recuperación de password. Los tokens/secretos se almacenan con mecanismos seguros del dispositivo y nunca se incluyen en reportes/exportes.
