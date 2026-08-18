# Backend DDR001 V1

API Node.js + TypeScript strict + Express + Prisma + PostgreSQL. La aplicación es local-first; este servicio recibe sincronización idempotente, conserva metadata y guarda evidencia en filesystem.

```powershell
Copy-Item .env.example .env
npm ci
npm run prisma:generate
npm run prisma:migrate:deploy
npm run dev
```

No se incluyen secretos ni usuarios ficticios. Los registros iniciales son únicamente versiones de esquema/contrato. El primer login válido crea el usuario por correo + teléfono.

Consulte `docs/ssot/API_CONTRACT.md`, `docs/ssot/SYNC_SPEC.md` y `docs/deployment/WINDOWS_SERVER_2018.md`.
