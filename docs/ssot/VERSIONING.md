# VERSIONING — Aplicación DDR001

## Fuente de versión

`app/pubspec.yaml` es la fuente ejecutable de la versión Flutter con formato `MAJOR.MINOR.PATCH+BUILD`. Android recibe `versionName` y `versionCode` desde Flutter; no se duplican números fijos en Gradle ni Manifest.

## Incrementos

- `PATCH`: corrección o cambio compatible dentro del flujo vigente.
- `MINOR`: capacidad funcional nueva compatible.
- `MAJOR`: cambio incompatible de datos, API o procedimiento que requiera migración coordinada.
- `BUILD`: entero Android estrictamente creciente en cada APK distribuido.

## Archivos obligatorios por entrega

Todo incremento actualiza en el mismo cambio:

1. `app/pubspec.yaml`.
2. La versión vigente en `PROJECT_TRUTH.md`.
3. Una entrada fechada en `CHANGELOG.md`.
4. Tests o fixtures que validen la versión visible.
5. `app/assets/manual/manual_de_uso.md` cuando cambie un procedimiento visible para el técnico.
6. SSOT funcional y ADR cuando cambien comportamiento, modelo, API o una decisión relevante.

La versión vigente es `1.5.1+17`.
