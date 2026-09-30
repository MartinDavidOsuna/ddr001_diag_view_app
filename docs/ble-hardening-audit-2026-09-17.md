# Auditoría y entrega BLE — 2026-09-17

## Baseline previo a cualquier edición

```text
BASELINE_BRANCH=feature/functional-api-sync
BASELINE_LOCAL_SHA=b6a673bffa651cd4bd85cc0cc016de8b1b908156
REMOTE_SHA=N/A (no existe upstream ni rama remota homónima)
COMPARISON_REMOTE=origin/main
COMPARISON_REMOTE_SHA=556a143eeb9d58b22fc9093d773f5bfa5c334572
LOCAL_AHEAD=7 (comparación con origin/main)
LOCAL_BEHIND=0 (comparación con origin/main)
WORKTREE=dirty
BLE_BASELINE_IDENTIFIED=YES
SOURCE_BRANCH=feature/functional-api-sync
SOURCE_SHA=b6a673bffa651cd4bd85cc0cc016de8b1b908156
WORK_BRANCH=feature/ble-connection-hardening
WORKTREE_STATUS=dirty, preservado
```

Se ejecutaron pwd, status, remote -v, branch -vv, log --all, reflog, stash y
tags antes de modificar. Fetch --all --prune exitoso, seguido de segunda
auditoría; sin pull, merge, rebase, reset, stash, commit ni push. No había
stashes, tags ni rama de hardening previa. Las otras ramas locales apuntaban
a ancestros del HEAD elegido, no a trabajo más avanzado.

Commits locales no publicados, preservados:

- b6a673b: demo Web autónoma.
- d1e1dd0: escala BLE/simulación.
- 4db119f: simulación controlada por operador.
- bc5cf79: fiabilidad sync.
- 4d0d161: correcciones E2E.
- 3fd1f16: integración funcional API.
- de3afa5: documentación API compartida.

No hay commits remotos ausentes respecto a origin/main. Reflog confirma la
secuencia local desde docs/functional-verifier-shared-api y dos amend anteriores
a 4d0d161; no se restablecieron ni eliminaron esas referencias. No se adoptó
el SHA histórico como baseline. BlePulseSource/protocolo no tenían commits
posteriores al remoto; AppController sí tiene trabajo posterior legítimo
(integración, simulación y escala), conservado.

## Worktree previo preservado

Tracked sin commit:

- app/assets/manual/manual_de_uso.md
- app/lib/infrastructure/export/case_export_service.dart
- app/lib/presentation/common/app_scaffold.dart
- app/lib/web_demo/web_demo_app.dart
- app/lib/web_demo/web_demo_domain.dart
- app/pubspec.yaml
- app/test/web_demo/web_demo_domain_test.dart
- docs/ssot/CHANGELOG.md
- docs/ssot/DATA_MODEL.md
- docs/ssot/FUNCTIONAL_SPEC.md
- docs/ssot/PROJECT_TRUTH.md
- docs/ssot/VERSIONING.md
- docs/web-demo-local.md

Untracked previos:

- app/lib/infrastructure/export/case_report_renderer.dart
- app/lib/presentation/common/section_card.dart
- app/lib/web_demo/web_demo_export.dart
- app/lib/web_demo/web_demo_records.dart
- app/lib/web_demo/web_demo_results.dart
- app/lib/web_demo/web_demo_workflow.dart
- app/test/web_demo/demo_meter_face.png (enlace al asset existente)
- app/test/web_demo/web_demo_app_test.dart
- app/test/web_demo/web_demo_parity_test.dart
- docs/ssot/DECISIONS/ADR-024-web-simulation-android-parity.md

Origen identificado: paridad Web/Android y corrección de reportes de las
sesiones anteriores. No se descartan ni se incorporan como trabajo BLE nuevo.
Respaldo fuera del repo: /tmp/ddr001-ble-baseline.patch y
/tmp/ddr001-ble-preexisting-work.tar.gz. Se compararon byte a byte los
renderizadores/exportadores, runtime Web, tarjetas compartidas y documentos de
datos/demo con el respaldo: intactos. Sólo se amplían manual/SSOT y se eleva
versión/fixture visible donde ya había trabajo previo.

## Auditoría técnica y baseline de pruebas

Revisados BlePulseSource, discovery, Esp32CounterProtocol/Reconciler,
PulseSource, PulseProgressService, AppDependencies, AppController, pubspec y
lock, Manifest, pruebas de fuentes/dominio/controlador y ADR-008/012/015/016/
018/019/022. Búsqueda transversal BLE registrada en
/tmp/ddr001-ble-search.txt. Plugin instalado: flutter_blue_plus **1.36.8**;
APIs y valores predeterminados verificados en su código local, sin actualizarlo.

```text
BASELINE_ANALYZE=OK
BASELINE_BLE_TESTS=17/17
BASELINE_DOMAIN_TESTS=6/6
BASELINE_CONTROLLER_TESTS=42/42
```

Defectos: tres reintentos máximos, recuperación dada por conexión física sin
esperar GATT/read, callbacks GATT async sin captura de fallos, errores de
notificación tratados inmediatamente como pérdida irreversible y ausencia de
invalidación de operaciones tardías tras stop. Se conserva descubrimiento y
conexión directa existentes, con recuperación/serialización alrededor de ellos.

26 regresiones nuevas de transporte incluyen conexión normal, backoff acotado
con ocho fallos, fallos de discovery/servicio/característica/NOTIFY/read/payload,
notifications perdidas, keepalive, una lectura en vuelo, errores simultáneos,
stop/dispose en recuperación y conexión, respuesta tardía, inicio concurrente,
contador duplicado, delta exacto, wrap, rollback, lifecycle en proceso y
reasociación de suscripciones Sample A→B→A con persistencia real de dominio.

Las expectativas antiguas de pantalla Recovery al bootstrap se ajustan por la
petición explícita de abrir Inicio, no para aceptar una regresión BLE. Los
tests de protocolo, reconciliador y dominio existentes quedan intactos.

## Alcance y limitaciones

Firmware, UUID, nombres, payload, GATT esperado, lock de dependencias,
Manifest, API, backend, autenticación, Drift y metrología no se modifican.
Sin servicios Android nuevos, autoConnect ni scan obligatorio para recuperar.
El lifecycle de cámara permanece intacto. Los logs no registran credenciales,
fotos ni identidad del operador.

Reboot sin identificador de sesión, suspensión o muerte de proceso Android y
validación RF con equipos reales son limitaciones residuales (ADR-025).
Las pruebas de lifecycle sólo simulan notificaciones dentro de un proceso vivo;
no certifican Doze, pantalla apagada ni ejecución en segundo plano.

## APK

Versión solicitada: **1.7.1+20**. Comando: `flutter build apk --release --no-pub`.
Usa configuración local predeterminada, sin inventar una URL API; se conserva
la firma debug de release que ya define Gradle, sin cambiar applicationId.
Destino: `/sdcard/Download/DDR001-Verificador-1.7.1+20.apk` en Pixel 7 Pro.
No se ejecuta install ni se abre/sustituye la aplicación instalada. Antes de
la entrega el Pixel tiene com.aquafim.ddr001diagview 1.5.1, versionCode 17.

## Resultado de entrega

- Análisis estático sin incidencias.
- 313 tests pasan con `flutter test --no-pub --concurrency=1`.
- Revalidación final BLE/dominio: 49/49, con seguimiento de cada listener de
  notificaciones y máximo de una conexión/lectura en vuelo.
- Regresión adicional Chrome: 5/6 pasan, incluidos los cuatro exportes. El
  test `leaving and resuming preserves active evidence and hides indicators`
  falla por un pulso adicional (43→44; repetición aislada 47→48). El runtime
  Web está idéntico al respaldo; sólo cambió el fixture de versión visible.
  Se registra como incidencia pendiente fuera del alcance BLE; no se alteró
  la simulación ni su expectativa para forzar verde. Logs en
  /tmp/ddr001-ble-web-regression.log y /tmp/ddr001-ble-web-retry.log.
- Una ejecución paralela con Gradle simultáneo falló en la expectativa de
  veredicto del test temporizado de simulación; no se alteró ese escenario,
  cálculo ni expectativa para ocultarlo. La repetición serial pasó íntegra.
- APK release generado: 108284725 bytes, package `com.aquafim.ddr001diagview`,
  versionName `1.7.1`, versionCode `20`, minSdk 24/targetSdk 36 sin cambios.
- Transferencia ADB completada a `/sdcard/Download/DDR001-Verificador-1.7.1+20.apk`.
- SHA-256 idéntico en Mac y Pixel:
  `0ab4fca654f6f8fd9fcd272a7cb37f1083524bfd2a82209123d41e346ee9311d`.
- Tras copiar, la app instalada conserva 1.5.1+17 y lastUpdateTime
  `2026-09-10 17:40:24`: no se instaló el APK.
- Firmware, Android/Manifest/Gradle, pubspec.lock, dominio de pulsos y motor
  metrológico sin diff. Rama local sin publicar y HEAD del baseline intacto.
- Gradle advierte de migración futura KGP en plugins existentes; no se
  actualizaron dependencias ni herramientas para esta entrega.
