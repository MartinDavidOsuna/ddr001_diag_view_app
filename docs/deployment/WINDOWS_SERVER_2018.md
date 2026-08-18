# DDR001 V1 en Windows Server 2018

## Requisitos

- Node.js LTS compatible con las versiones fijadas en `backend/package-lock.json`.
- PostgreSQL 17 (o una versión soportada por Prisma 6) como servicio de Windows.
- Una cuenta de servicio sin inicio de sesión interactivo.
- Carpetas NTFS separadas para aplicación, evidencia y logs.

## Base de datos

Desde `backend/`, instalar exactamente las dependencias bloqueadas:

```powershell
npm ci
npm run prisma:generate
```

Un administrador PostgreSQL puede crear el rol, la base y aplicar las migraciones reproducibles con:

```powershell
.\scripts\initialize-database.ps1 `
  -AdminDatabaseUrl 'postgresql://postgres@localhost:5432/postgres' `
  -DatabaseName 'ddr001' `
  -ApplicationRole 'ddr001_app' `
  -ApplicationPassword '<secreto>'
```

El script no escribe la contraseña en archivos. Después debe guardarse `DATABASE_URL` en el administrador de secretos/variables del servicio. Para despliegues posteriores use exclusivamente:

```powershell
npm run prisma:migrate:deploy
```

No usar `prisma db push` en producción. La migración inicial crea tablas, índices, relaciones y los registros de versión contractual en `deployment_metadata`.

## Variables

Copiar los nombres de `backend/.env.example` al entorno del servicio y proporcionar valores reales. `JWT_SECRET` debe ser aleatorio, tener al menos 32 caracteres y no registrarse. `HYDRANTS_API_BASE_URL` apunta al host de `ddr001_api_rv`; `HYDRANTS_API_TOKEN` es un Bearer de campo emitido por esa API. Si faltan, la consulta devuelve indisponible y nunca bloquea una prueba local.

## Evidencias y permisos

Crear `EVIDENCE_STORAGE_PATH` fuera del árbol de código. Conceder a la cuenta de servicio lectura, creación, escritura y renombrado únicamente sobre esa carpeta. PostgreSQL conserva metadata, SHA-256 y `storageKey`; las imágenes permanecen en filesystem.

## Compilación y servicio

```powershell
npm run lint
npm run typecheck
npm test
npm run build
npm run prisma:migrate:deploy
node dist/src/server.js
```

Registrar el último comando mediante NSSM, WinSW o el administrador de servicios institucional, con inicio automático y reinicio ante fallo. Redirigir stdout/stderr al colector de logs autorizado y aplicar rotación. No registrar tokens, secretos ni contenido binario.

## Verificación

1. Consultar `GET /api/v1/health/live`.
2. Probar alta/login y logout con una identidad de prueba.
3. Sincronizar un expediente con evidencia y repetir el envío para comprobar idempotencia.
4. Verificar permisos de lectura del archivo y que PostgreSQL no contenga el binario.
5. Simular caída/reinicio del servicio y confirmar que migraciones y archivos permanecen.

