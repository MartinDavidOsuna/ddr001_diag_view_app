param(
  [Parameter(Mandatory = $true)][string]$AdminDatabaseUrl,
  [string]$DatabaseName = 'ddr001',
  [string]$ApplicationRole = 'ddr001_app',
  [Parameter(Mandatory = $true)][string]$ApplicationPassword
)

$ErrorActionPreference = 'Stop'
if ($DatabaseName -notmatch '^[a-zA-Z][a-zA-Z0-9_]*$') { throw 'DatabaseName inválido.' }
if ($ApplicationRole -notmatch '^[a-zA-Z][a-zA-Z0-9_]*$') { throw 'ApplicationRole inválido.' }

$psql = (Get-Command psql -ErrorAction Stop).Source
$escapedPassword = $ApplicationPassword.Replace("'", "''")
$bootstrap = @"
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', '$ApplicationRole', '$escapedPassword')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$ApplicationRole')\gexec
SELECT format('CREATE DATABASE %I OWNER %I', '$DatabaseName', '$ApplicationRole')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '$DatabaseName')\gexec
"@
$bootstrap | & $psql $AdminDatabaseUrl --set ON_ERROR_STOP=1
if ($LASTEXITCODE -ne 0) { throw 'No fue posible crear rol/base DDR001.' }

$uri = [Uri]$AdminDatabaseUrl
$port = if ($uri.Port -gt 0) { $uri.Port } else { 5432 }
$databaseUrl = "postgresql://${ApplicationRole}:$([Uri]::EscapeDataString($ApplicationPassword))@$($uri.Host):$port/${DatabaseName}?schema=public"
$env:DATABASE_URL = $databaseUrl
Push-Location (Join-Path $PSScriptRoot '..')
try {
  & npm run prisma:migrate:deploy
  if ($LASTEXITCODE -ne 0) { throw 'Prisma migrate deploy falló.' }
} finally {
  Pop-Location
  Remove-Item Env:DATABASE_URL -ErrorAction SilentlyContinue
}
Write-Host 'Base DDR001 creada y migrada. Guarde DATABASE_URL en el administrador de secretos del servidor.'
