# ADR-001 — Stack y despliegue inicial
- **Estado:** aceptada
- **Fecha:** 2026-08-08
- **Decisión:** monorepo; Flutter Android portrait + Riverpod + Drift/SQLite; Node.js + TypeScript + Express; Prisma + PostgreSQL; backend inicial en Windows Server 2018. iOS fuera del alcance inmediato.
- **Consecuencia:** se prioriza Android y offline-first. La arquitectura evita dependencias que impidan iOS en el futuro, pero no se desarrolla/probará iOS ahora.
