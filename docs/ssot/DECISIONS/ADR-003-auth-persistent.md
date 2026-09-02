# ADR-003 — Login passwordless y sesión persistente
- **Estado:** aceptada
- **Fecha:** 2026-08-08
- **Contexto:** uso de campo; se quiere autenticar una sola vez sin passwords.
- **Decisión:** login con email + teléfono; alta local automática en primer login; sesión persistente hasta logout explícito. El backend no es requisito operativo del primer acceso.
- **Consecuencias:** no existe pantalla de registro ni recuperación de password. Una integración remota futura puede almacenar tokens/secretos con mecanismos seguros del dispositivo, pero nunca debe incluirlos en reportes/exportes ni bloquear la operación local.
