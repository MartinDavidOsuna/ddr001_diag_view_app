# Validación V1 — 2026-08-15

## Automatizada ejecutada

- `dart run build_runner build`: aprobado (147 outputs evaluados/generados).
- `dart format .`: aprobado.
- Flutter analyze: limpio.
- Flutter test: 186 pruebas aprobadas.
- Backend Prisma generate, TypeScript strict, ESLint, Vitest y build: aprobados.
- PostgreSQL 17 temporal real: migración aplicada, 10 tablas y tres registros `deployment_metadata` verificados. El clúster temporal fue detenido y eliminado.
- Firmware PlatformIO: compilación aprobada durante esta sesión; GPIO27/GPIO2 confirmados en fuente.
- APK debug: generado sin instalar ni borrar datos de dispositivo.

## Recorridos teóricos/fakes

Los tests cubren motor endpoint y banda de guarda; evidencia requerida y corrupta; inmutabilidad; recovery RUNNING; MANUAL; parser/reconciliación BLE; frames LED con baseline, histéresis y debounce; OCR/aguja y fallback; exportes CSV/JSON/HTML/PDF. La matriz de paridad registra por separado implementación y validación física.

## Matriz de hardening

| Escenario | Cobertura automatizada | Ejecución física pendiente |
|---|---|---|
| force-stop/relaunch y RUNNING | Reapertura de SQLite + recuperación de muestra/configuración/evidencia | Smoke Android |
| sesión offline | Restauración local sin backend; primer login exige backend | Alternar red Android |
| cámara/permiso/OCR fallido | Estados de error, Evidence válida con lectura manual, fakes de visión | Permiso real/cámara real |
| GPS fallido | Excepción no bloqueante y estado sin GPS | Servicio/permiso real |
| BLE desconectado/reconexión | Estados, rollback/contador y `COMPROMISED` | ESP32 real |
| LED ruido/destellos | Frames fake, ROI, histéresis, debounce y conciliación | LED GPIO2 real |
| evidencia corrupta | SHA-256 y `INVALID_EVIDENCE` | Archivo real en dispositivo |
| offline/sync retry/conflict | Cola local, servidor idempotente y reglas de conflicto | Cambio de red + servidor |
| expediente cerrado | Triggers/repositorios read-only | Smoke UI |
| almacenamiento lleno | Propagación de error filesystem sin cierre válido | Simulación Android |

## Bloqueo físico objetivo

Por instrucción del usuario no hay acceso ADB al Pixel en esta fase. COM15 tampoco estuvo disponible. No se ejecutaron `adb uninstall`, `pm clear`, borrado de app ni flasheo. La corrida física LOGIN→reporte/sync y la validación cuantitativa LED/BLE final deben ejecutarse cuando vuelvan esos recursos; no se presentan como pruebas aprobadas.
