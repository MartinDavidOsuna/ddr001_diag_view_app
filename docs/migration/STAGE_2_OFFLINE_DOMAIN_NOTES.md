# Etapa 2 — Dominio y persistencia offline

## Arquitectura

- `app/lib/domain/`: entidades inmutables, normalización, contratos de repositorio y checksum.
- `app/lib/data/local/database/`: schema Drift/SQLite v1 y código generado.
- `app/lib/data/local/repositories/`: mappers explícitos, repositorios y servicios transaccionales.
- `app/lib/data/local/filesystem/`: almacenamiento de evidencia desacoplado y verificable.
- `app/lib/core/metrology/`: motor de Etapa 1 reutilizado sin modificaciones.

El dominio no importa Drift. Las filas generadas no se exponen a consumidores de repositorios.

## SQLite v1

Tablas: `users`, `meters`, `verification_cases`, `flow_points`, `samples`, `test_points`, `evidence_items` y `sync_items`.

Foreign keys se habilitan en cada apertura. Existen índices para expedientes por medidor/estado, muestras por caudal/estado, evidencia por muestra y cola por estado/fecha. Restricciones relevantes:

- email normalizado único;
- un código Q1/Q2/Q3/Q4 por expediente;
- `sample_number` único por caudal, sin límite máximo;
- una versión de cola única por entidad, ID y checksum;
- checks para enums, valores positivos y contadores no negativos.

`schemaVersion = 1`. `onUpgrade` queda como punto explícito para migraciones futuras; no se usa recreación destructiva.

## Estados e inmutabilidad

Muestra: `DRAFT → RUNNING → CLOSED_VALID | INVALID_EVIDENCE`. Expediente: `OPEN → CLOSED`. No hay reapertura ni transición desde `INVALID_EVIDENCE`.

Repositorios validan estados antes de escribir. Triggers SQLite impiden UPDATE/DELETE de muestras cerradas, cambios en sus puntos/evidencias, alta de puntos/evidencias posteriores y UPDATE/DELETE de expedientes cerrados. Otros triggers impiden agregar caudales o muestras a un expediente cerrado.

## Configuración congelada y LECTURA VISUAL

La muestra tipa y congela método, K, paso de evidencia, `uL`, Q, MPE, LPS, escala de odómetro y litros por vuelta. MANUAL/LED/BLE derivan `V_ref = N × K`. VISUAL persiste `V_ref` observado explícitamente y mantiene `pulseCount = 0`; no crea pulsos ficticios.

## Cierre atómico

El cierre exige estado RUNNING y lecturas confirmadas. Un plan puro deriva las evidencias requeridas desde el origen relativo 0 L, `evidenceStepLiters` y el Vref final: START en 0, INTERMEDIATE en cada múltiplo positivo del paso estrictamente menor al final, y FINAL en el volumen final. Si el final coincide con un múltiplo no se exige otra INTERMEDIATE en el mismo instante. La validación compara tipo + `volume_ref_l` y verifica existencia y SHA-256; no depende de que exista Point. Evidencia ausente/corrupta cambia la muestra a `INVALID_EVIDENCE` sin resultado ni sync. VISUAL usa su Vref explícito para el mismo plan.

Si todo es válido, una transacción calcula mediante el motor de Etapa 1, persiste resultado completo, checksum y `CLOSED_VALID`, y encola la muestra y evidencias requeridas. El resultado no se recalcula al leer.

## Checksum

SHA-256 cubre IDs, configuración, progreso funcional, GPS, lecturas, timestamps esenciales, resultado completo y hashes de evidencia requerida. La canonicalización v1 usa una secuencia explícita de campos con nombre/valor de longitud prefijada, fechas UTC, doubles con 17 dígitos exponenciales y evidencias ordenadas por ID. No es firma de identidad; detecta alteración y versiona sync.

El expediente usa el mismo esquema canónico sobre identidad, fechas, caudales requeridos, estados y checksums de muestras ordenados.

## Filesystem

Ruta: `<documents>/evidence/<caseId>/<sampleId>/<evidenceId>.<ext>`. Los IDs y extensiones se validan. La implementación permite reservar ruta, importar archivo existente, calcular/verificar SHA-256 y eliminar solo temporales cuando la muestra no está cerrada. SQLite nunca almacena binarios ni Base64.

## Recuperación

Repositorios consultan expedientes OPEN y muestras DRAFT/RUNNING/INVALID_EVIDENCE. Todo progreso (contador o Vref visual, GPS y lecturas confirmadas) se escribe en SQLite. Una prueba abre una DB en archivo, persiste RUNNING, cierra la conexión, reabre y recupera exactamente el progreso.

## Cola local

Estados: `PENDING`, `IN_PROGRESS`, `FAILED`, `SYNCED`. Se registran entidad, ID, checksum, intentos, error y retry opcional. Enqueue es idempotente por versión. No hay HTTP ni contrato remoto nuevo.

## Contratos y pendientes

- `packages/shared-contracts` fue alineado: Point permite `pulse_count`/`v_ref_l` nullable u omitidos, Sample usa `measurement_source` con `VISUAL | MANUAL | LED | BLE`, K puede ser null cuando no aplica, y checksums/hashes admiten estado previo al cierre. El schema de Sample avanza a v3 por el rename contractual.
- La lista conceptual de estados sync de SSOT incluye `local/syncing/conflict/error`; evidencia conserva esos estados. `SyncItem` usa la máquina operativa solicitada para la cola (`pending/inProgress/failed/synced`). No se implementa resolución remota de conflictos.
- El `applicationId` Android continúa como `com.example.ddr001_app`. Debe definirse y cambiarse antes de iniciar Etapa 3; este correctivo no lo modifica.
