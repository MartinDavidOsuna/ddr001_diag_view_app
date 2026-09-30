# Corrección BLE desde Flutter — 2026-09-25

## Baseline conservado

- Repositorio: `/Users/martino/DEV/ddr001_diagnostico_funcional/ddr001_diag_view_app`.
- Remoto verificado: `https://github.com/MartinDavidOsuna/ddr001_diag_view_app.git`.
- Rama inicial: `feature/ble-connection-hardening`, sin upstream.
- HEAD: `b6a673bffa651cd4bd85cc0cc016de8b1b908156`.
- Versión local y teléfono inicial: **1.7.5+24**.
- 38 archivos tracked modificados; 23 entradas untracked en status (algunas directorios).
- Baseline efectivo: HEAD **más todo ese worktree**, incluidos hardening BLE,
  ADR-025/026, sync, cámara preparada y paridad Web anteriores. No se sustituyó.
- `git fetch origin --no-prune` exitoso, sin pull. `origin/main` y
  `origin/feature/simulation-test-source` siguen en
  `556a143eeb9d58b22fc9093d773f5bfa5c334572`, versión publicada **1.3.4+14**.
- Divergencia con main: **7 ahead / 0 behind**. No stashes.
- Commits locales no publicados: `de3afa5`, `3fd1f16`, `4d0d161`, `bc5cf79`,
  `4db119f`, `d1e1dd0`, `b6a673b`. Se mantienen todas las ramas previas.
- Reflog inspeccionado: cambio a hardening el 17/09 desde functional-api-sync;
  commits de septiembre y amend anteriores conservados, sin restaurar ninguno.
- Rama creada desde ese estado: **fix/ble-recovery-20260925**, sin upstream.
  HEAD no cambia. Sin commit, push, merge, rebase, reset, stash ni limpieza.

Respaldo fuera del repositorio:
`/Users/martino/DEV/ddr001_ble_recovery_artifacts/20260925/`.
Contiene patch binario del baseline, status, untracked y APK anterior. La copia
reconstruida de fuentes está en `/tmp/ddr001-ble-20260925/baseline-tree`.
El archivo `baseline-source.tgz` permite reproducir el baseline dirty; SHA-256:
`a6a162d934458c0d27ec4a4a6a21bfc7006b9d9cb3818d44e64849a6da1fe09e`.
El patch binario inicial tiene SHA-256
`e0db46a0c7514b47d8aaac34ec9291aec29f9c2499de5c63904db3be6d4c43bb`.
Los diffs contra HEAD incluyen trabajo previo: consultar el diff incremental
contra este baseline para atribuir esta corrección.

Se leyeron AGENTS, PROJECT_TRUTH, FUNCTIONAL_SPEC, METROLOGY_RULES, DATA_MODEL,
API_CONTRACT, SYNC_SPEC, VERSIONING y ADR-008/012/015/016/018/019/025/026.
Se inspeccionaron fuentes BLE, reconciliador, repositorios, dependencias,
controlador, captura/navegación/lifecycle, Android y firmware **en lectura**.

## Contraste de antecedentes

| Antecedente | Clasificación sobre el baseline local | Evidencia y acción |
|---|---|---|
| A: read fallido con enlace conectado deja recuperación atascada | YA CORREGIDO | La fuente ya redescubre GATT aun conectada; se conserva y prueba. |
| B: READY anterior a lectura / excepciones de preparación sin manejo | YA CORREGIDO | `_prepareGatt` espera READ válido; discovery/notify/read llegan al ciclo de recuperación. Se añade comprobación del booleano de NOTIFY. |
| C: `_tail` y `_pulseQueue` rechazadas permanentemente | YA CORREGIDO, con hueco CONFIRMADO | Las colas ya sobrevivían errores; clave se aceptaba después de escritura. Faltaba verificar resultado ambiguo tras commit y serializar/capturar errores del checkpoint del contador. |
| D: probes superpuestos y falta de generación | YA CORREGIDO, con huecos CONFIRMADOS | Ya había `_probeTask`, generaciones y stop. Se completan guardas de error/done, eventos de enlace atrasados y generación de asociación Sample; se evita aplicar READ atrasado dos veces. |
| E: reintentos se agotan | YA CORREGIDO | Backoff persistente 1/2/4/8/15/30 s existente. Se conserva. |
| E: scan usa `wasConnected` y puede desconectar transporte adquirido mientras valida | CONFIRMADO | Propiedad explícita antes de conectar; scan omite propietario, fuente espera limpieza de validación anterior. |
| F: estado visual y foreground | CONFIRMADO | `connected` se traducía como desconectado, scan podía declarar ready durante recuperación, y no había verificación BLE al reanudar. Ahora se consulta estado actual también al reasociar Sample. |
| Android apagado/permisos y plataformas anteriores a Android 12 | CONFIRMADO | Sin pausa específica de recuperación; Manifest sin permisos legacy y scan pedía sólo permisos Android 12+. Se corrige sin nuevas dependencias. |
| Background siempre desconecta / exige foreground service o autoConnect | NO APLICA como premisa; REQUIERE EVIDENCIA física | Navegación y cámara conservan fuente; no se añade arquitectura Android. |
| Estabilidad RF, Doze, ESP32 desplegado y reinicios no observables | REQUIERE EVIDENCIA | No hay ESP32 disponible. No se declara validación física. |

## Cambios incrementales y evidencia

- `ble_connection_ownership.dart`: propiedad por dispositivo, espera de limpieza
  de validación en curso y liberación al terminar stop. No serializa de nuevo GATT.
- `ble_discovery.dart`: una búsqueda concurrente, `finally` para listeners,
  límite adicional de espera y parada del scan propio si queda activo; captura
  errores del stream; diagnósticos con operación, duración y número de candidatos.
- `ble_pulse_source.dart`: conserva conexión directa y mantiene una preparación,
  recuperación y probe propios. READ y NOTIFY se consumen por orden de stream;
  no se reinyecta el resultado viejo de read tras observar uno más nuevo.
  Durante preparación se retienen payloads hasta validar READ antes de READY.
  Tres preparaciones GATT fallidas con enlace activo permiten escalar a disconnect.
- `ble_permissions.dart` y Manifest: permisos según SDK; CONNECT denegado o
  adaptador apagado suspenden intentos. Foreground consulta estado y sondea;
  no reconstruye una sesión sana. Stop retira observador y suscripciones.
- `app_controller.dart`: checkpoint en la misma cola después de los pulsos;
  fallo visible y bloqueo de FINAL; guardas de asociación y de actualización
  de contexto después de awaits. La reconstrucción de fuente de una Sample BLE iniciada compromete su
  continuidad y bloquea FINAL; se relee configuración persistida. El estado
  físico `connected` es preparación,
  y scan/reasociación muestran el estado real de la fuente.
- `pulse_progress_service.dart`: tras excepción relee progreso. Si confirmó el
  incremento exacto acepta la clave una vez; si no hubo cambio deja reintentar;
  si no puede determinarlo bloquea esa Sample. La siguiente Sample sigue operable.
- Logs BLE: UTC, generación de fuente/GATT, estado, contador, preparación,
  fallo/duración de probe, recuperación, escalamiento, lifecycle y stop.
  Sin nombres de operador, credenciales, imágenes ni payloads crudos; keepalive
  sano duplicado no inunda el log ni actualiza UI/persistencia.
- SSOT, ADR-029, manual y CHANGELOG actualizados; versión **1.7.6+25** y fixtures
  visibles coordinados según VERSIONING. Sin modificaciones del runtime Web.

## Librería instalada y contrato

`flutter_blue_plus 1.36.8`, `flutter_blue_plus_android 7.0.4`, lock intacto.
Se inspeccionó el código instalado: `BluetoothCharacteristic.read` usa mutex
**global**, timeout, guardas de conexión/adaptador, y recibe el mismo evento
nativo que `onValueReceived`. Ese stream incluye READ y NOTIFY. Por ello no se
agrega mutex de operaciones propio ni se consume dos veces la lectura.
La conexión conserva timeout 12 s, MTU/defaults y estrategia directa sin scan.

Firmware `esp32_pulse_bridge`/README/contrato inspeccionados en lectura:
v1 de 5 bytes y v2 de 9 bytes, uint32 acumulativo, UUID y filtrado sin cambios.
Duplicados, saltos, wrap y rollback conservan la semántica existente.

## Validación automatizada

- Baseline antes de editar: `flutter analyze --no-pub` limpio; **94/94** en
  BLE hardening, fuentes/protocolo, progreso y AppController. Sin fallos previos
  en esas comprobaciones. No se afirma haber ejecutado toda la suite baseline.
- Suite completa tras corrección: `flutter test --no-pub --concurrency=1`,
  **359/359**. Incluye dominio, cámara, navegación, simulación y metrología
  existentes; no se modificaron sus algoritmos para pasar.
- Regresión de transporte tras ajustar escalamiento/fin de scan: **59/59**.
- Regresión intermedia de controlador/transporte tras las guardas visuales: **85/85**;
  después se añadieron dispose durante READ y reconstrucción con/sin FINAL
  persistido, y se repitió la suite completa.
- Análisis final sin incidencias. Formato Dart y `git diff --check`.
- Flutter local **3.44.8**, Dart **3.12.2**: no se actualizó SDK ni dependencia.

Las pruebas nuevas cubren READ fallido con enlace activo; discovery/NOTIFY/read
inicial por separado; READY retenido aunque ya hay enlace; eventos repetidos o
atrasados; probe lento; backoff persistente; stop/dispose durante conexión,
discovery, lectura y espera; desconexión explícita; propietario en recuperación
frente a scan; limpieza previa de scan; foreground conectado y enlace perdido
sin callback; permisos/adaptador bloqueados; READ→NOTIFY→resultado READ atrasado;
checkpoint después de todo el delta; error antes de commit, después de commit y
resultado ilegible. Una prueba usa AppController y SQLite reales con trigger de
fallo de checkpoint: conserva pulsos escritos, impide FINAL y permite otra
Sample sin desconectar el transporte. También reconstruye después la fuente,
comprueba continuidad comprometida y bloqueo de FINAL sin cambiar los pulsos
guardados. Si FINAL ya está persistido, comprueba retorno a lecturas sin
reconectar ni marcar comprometido el endpoint por reconstrucción. Ninguna
representa radio Bluetooth real.

Las pruebas widget usan reloj virtual; la E/S de Drift y cancelación de streams
se ejecuta en runAsync. Los bloqueos iniciales del harness al cruzar ambos
relojes se corrigieron en las pruebas, sin relajar sus expectativas.

## Android y APK

Pixel 7 Pro conectado por ADB, Android 17. Package inicial
`com.aquafim.ddr001diagview`, versionName 1.7.5, versionCode 24, minSdk 24,
targetSdk 36. Bluetooth ON, SCAN/CONNECT y ubicación concedidos. No había
entradas flutter/AndroidRuntime en el buffer consultado antes de la prueba.
Se extrajo su base.apk antes de actualizar. No se borraron datos ni emparejamientos.

Compilación productiva: `flutter build apk --release --no-pub
--dart-define-from-file=config/production.json`. La advertencia KGP de plugins
existentes no se trató como motivo para actualizar dependencias.

### Resultado de instalación y comprobación local

- `adb install -r` completó **Success**. Package y certificado coinciden con el
  anterior; appId **10430** y firstInstallTime **2026-08-31 12:29:09** conservados.
  No desinstalación, `pm clear`, cambios de emparejamiento ni sincronización.
- APK entregado/instalado: **1.7.6+25**, minSdk 24/targetSdk 36.
  SHA-256 tanto en Mac como en `/data/app/.../base.apk`:
  `5d77fc44ed0e0f5ca6bb0500bcfe5adcac5ac9e103dfe1a49121f6cc0db81f75`.
- APK anterior extraído, SHA-256:
  `2f9eeaab2bb95db75849b2399ace9ab1901a915a4532af4037cbd1308045b0ef`.
- Arranque y arranque en frío del APK final sin crash. Inicio muestra 1.7.6+25,
  sesión restaurada y REANUDAR PRUEBA GUARDADA. Cinco expedientes visibles antes
  de actualizar coinciden textualmente después; no se afirma una comparación
  byte a byte de la base privada Android.
- Tres scans sin periférico: operaciones 1/2/3 completadas con **0 candidatos**
  en **6031 / 6012 / 6006 ms**. Dos taps seguidos compartieron operación 2.
  Scan durante background terminó; al volver seguía «No conectado» y
  CONFIGURAR PRUEBA estaba deshabilitado. No se forzó READY ni una conexión.
- Navegación por Inicio, Historial, Identificación, Método, Ajustes y Manual;
  regreso mediante Volver, background/foreground y respuesta de UI comprobados.
- Esas búsquedas se hicieron sobre el primer APK 1.7.6+25. Las modificaciones
  productivas posteriores fueron guardas `mounted` y bloqueo conservador de
  continuidad al reconstruir una fuente BLE de una Sample ya iniciada, con
  retorno directo a lecturas cuando FINAL ya está guardado.
  Se recompiló/reinstaló el APK final y se repitieron arranque frío,
  background/foreground, historial e identificación de versión/hash; no se
  presenta ese recorrido como una prueba RF.
- Logcat de ambos procesos inspeccionados: **0** `E/flutter`, `Unhandled Exception`
  o `FATAL EXCEPTION` en el intervalo observado. Sin ESP32 no hubo operaciones
  GATT físicas; su recuperación se valida sólo con los dobles de prueba.
- Se conserva un expediente vacío **QA-SIN-ESP32-20260925**, banco **QA-BLE-APP**,
  creado para entrar al selector. Sin Sample, pulsos, resultados ni sync; no se
  borró. El teléfono queda en Inicio con la prueba previa disponible.
- Permisos SCAN/CONNECT permanecen concedidos, adaptador ON. Denegación de
  permisos/apagado se probaron con dobles; no se alteró el Bluetooth del teléfono.

## Límites y pruebas físicas pendientes

- Sin ESP32 no se valida recepción física, alcance, latencia GATT real,
  preparación/capturas con adquisición real, pantalla bloqueada ni Doze.
- El proceso vivo conserva sesiones y reconciliación. No se introduce atomicidad
  nueva entre progreso y checkpoint frente a muerte de proceso/storage. Al
  reconstruir la fuente de una Sample BLE iniciada se persiste integridad
  comprometida y se bloquea FINAL; exige otra Sample. Background con fuente
  viva conserva recuperación normal. FINAL ya guardado permite volver a
  lecturas sin reconstruir adquisición. No se aceptan esos intervalos inciertos.
- Sin bootId/uptime el protocolo no detecta un reboot que haya alcanzado/superado
  el contador anterior. El rollback observable sí compromete la adquisición.
- No se declara «BLE estable», ausencia de pérdidas ni validación end-to-end.

| Con ESP32 real | Comprobar |
|---|---|
| Operación normal + capturas intermedias | READY sólo tras READ; mismos pulsos antes/después de cámara, sin reconectar al navegar. |
| Corte breve de alcance | Una recuperación; delta exacto al volver; ningún pulso duplicado. |
| Interrupción prolongada | Backoff hasta 30 s, sin agotarse; recuperación directa sin BUSCAR. |
| Pantalla bloqueada/background | Registrar tiempos/estado Android, volver a foreground y reconciliar; no asumir ejecución en Doze. |
| BUSCAR conectado y recuperando | No desconecta ni redescubre GATT del propietario; termina listado aun sin advertising. |
| Varias Samples A→B→A | Sin callbacks viejos, baseline correcto, ninguna muestra cerrada se modifica. |
| Reinicio ESP32 | Si retrocede: integridad comprometida, FINAL válido bloqueado. Registrar limitación si iguala/supera contador anterior. |
| Trazabilidad de pulsos | Comparar pulsos físicos, contador ESP32 y progreso persistido por Sample; incluir saltos/read+notify y v1/v2 desplegados. |

## Volver a la versión anterior conservando datos

El APK original se conserva en el directorio de artefactos indicado. Su firma
SHA-256 es `294d1c1cf25490509b7e0c9643cd82d42c48faed4b449e4d1497b59a6e0ac731`.
Es release no-debuggable, aunque se firma con la clave debug ya usada por el
proyecto. Android puede rechazar volver del versionCode 25 al 24; `-d` no ofrece
una garantía de downgrade para este APK. No resolverlo desinstalando ni con
`pm clear`.

Ruta preservadora: extraer el baseline respaldado en **otro directorio**, usar
mismas herramientas/lock/configuración productiva y clave original, compilar
ese código 1.7.5 con `--build-name=1.7.5 --build-number=26` (o mayor que el código
instalado), verificar package/firma e instalar con `adb install -r`. Eso recupera
el baseline local auditado, no los bytes idénticos del APK code 24. No se puede
probar que todo el worktree local coincidiera con las fuentes exactas del APK
anterior instalado; para reproducir exactamente ese comportamiento se requieren
sus fuentes de build o un downgrade que Android permita. Esta
corrección no cambia esquema/migraciones, por lo que no requiere conversión de
datos. Conservar primero el APK y copias de fuentes; no hacer reset del árbol
actual. La reversión no se ejecutó ni se declara probada en el teléfono.


Ejemplo de compilación de reversión en una extracción separada del respaldo:

```sh
# Desde app/ de la copia del baseline; nunca desde la rama corregida.
flutter pub get --offline
# Comprobar que pubspec.lock sigue idéntico al respaldo antes de compilar.
flutter build apk --release --no-pub --dart-define-from-file=config/production.json \
  --build-name=1.7.5 --build-number=26
# Verificar package y certificado contra los valores anteriores, luego:
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Si el teléfono ya tiene code 26 o mayor, elegir otro estrictamente mayor.
Si cambia firma o package, detener la instalación; no desinstalar para resolverlo.
El archivo `correction.patch` en artefactos contiene sólo los cambios de esta
sesión sobre el worktree inicial, facilitando revisión sin mezclar trabajo previo.
