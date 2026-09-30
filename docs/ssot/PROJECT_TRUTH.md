# PROJECT_TRUTH — DDR001 Verificador de Medidores

> **Actualización 1.8.0+26 (2026-09-30):** se permite corregir lecturas manuales
> INICIO/FINAL, configuración de cálculo y cuenta/banco de verificaciones finalizadas mediante revisiones
> locales auditadas. Esta excepción sustituye las prohibiciones generales de
> edición de datos manuales cerrados que aparecen más abajo; adquisición,
> pulsos y evidencias conservan su inmutabilidad. La configuración original queda en auditoría.
> Ambas constantes K se configuran en Preparación, con 10 L/pulso iniciales
> para pruebas nuevas; muestras previas conservan su K.
> Historial incorpora sincronización de todas las verificaciones finalizadas
> pendientes del usuario. Toda corrección queda **Pendiente (editada)** hasta que
> la API anuncie soporte explícito de revisiones en `/me/access`. Sin soporte se
> muestra el error de actualizar la API y continúan las demás verificaciones.
> El cliente implementa el contrato opcional documentado; el servidor no se modificó.
> Detalle normativo: [ADR-030](DECISIONS/ADR-030-local-manual-corrections.md).


- Versión de aplicación vigente: `1.8.0+26`. Login, Inicio y Ajustes muestran la versión instalada. La identidad funcional visible es **VERIFICADOR FUNCIONAL** y Android muestra **AQ VF DDR001**; el encabezado común y el splash Flutter conservan la identidad Aquafim.
- Política de incrementos y archivos coordinados: `VERSIONING.md`.

> **Estado:** SSOT consolidada — Etapa 0 cerrada el 2026-08-08.
> Este archivo es la referencia principal para ChatGPT/Codex. Ante discrepancias entre prototipo, capturas, código o documentos anteriores, prevalece `docs/ssot/`.

## 1. Misión
Migrar el verificador web legado a una aplicación **Flutter nativa para Android**, integrada de forma offline-first con el backend oficial **ddr001_api** (Node.js + TypeScript + Express + SQL Server 2014). La nueva app conserva el flujo y apariencia validados del prototipo, pero corrige y endurece metrología, persistencia, evidencia, visión, autenticación y sincronización.

## 2. Alcance inmediato
- Plataforma móvil productiva: **Android únicamente**, orientación **portrait**.
- Existe una entrada Flutter Web autónoma exclusivamente para presentaciones locales: sólo SIMULACIÓN Q1/Q2, sin login, API, SQL ni producción. Persiste su historial en almacenamiento del navegador y puede borrarlo explícitamente sin afectar Drift.
- La presentación Web reproduce el recorrido de SIMULACIÓN Android en formato portrait: Inicio, Identificación, Método, Preparación, Prueba con evidencias y registro, Lecturas, Resultado, repeticiones Q1/Q2, Resumen y exportes. Comparte tarjetas, avisos, tema, motor metrológico y renderizador CSV/JSON/HTML/PDF. Los indicadores de ESP32/control sólo aparecen en Prueba en curso.
- App: Flutter + Riverpod + Drift/SQLite.
- Backend oficial: repositorio `ddr001_api`, Node.js + TypeScript + Express + SQL Server 2014; `backend/` es referencia histórica Prisma/PostgreSQL no desplegable.
- Repositorios oficiales separados para app y API.
- Servidor inicial: **Windows Server 2018**.
- Panel web: no se construye en esta etapa, pero el backend debe exponer endpoints suficientes para un panel posterior.
- iOS y layout horizontal quedan fuera del alcance inmediato.

## 3. Referencias obligatorias
- `legacy/web-prototype/index.html`: referencia funcional histórica.
- `legacy/web-prototype/simulador_medidor.html`: simulador externo de validación; **no se integra a la app y no se modifica**.
- `design/screenshots/`: referencia visual contractual para Flutter. No replicar chrome/barra del navegador.
- Reporte HTML de evidencia proporcionado por el cliente: referencia de **estructura y apariencia**, no de valores ni reglas metrológicas.

## 4. Principios innegociables
1. Leer `docs/ssot/` antes de codificar.
2. No inventar reglas metrológicas ni endpoints de sistemas externos.
3. UI fiel a las capturas, sin rediseño libre.
4. Operación completa sin conexión.
5. Una muestra cerrada es **inmutable**.
6. Fotografías obligatorias: si falla una evidencia obligatoria, la corrida es inválida y debe repetirse.
7. Toda decisión relevante se registra como ADR.
8. Cualquier cambio funcional requiere SSOT + CHANGELOG en el mismo PR.

## 5. Autenticación y sesión
- Login **passwordless** con `nombre + email + teléfono` en el primer acceso.
- `email + teléfono` son la llave de identificación/autenticación. El nombre es un atributo de identidad/perfil, no una tercera credencial ni un secreto; no existe password ni pantalla de alta.
- Primer login: si el usuario no existe localmente en DDR001 Verificador, se da de alta automáticamente en el dispositivo con el nombre capturado. No requiere backend. Un usuario local legado sin nombre conserva su mismo ID y recibe el nombre capturado al volver a acceder.
- Sesión persistente: no caduca para el usuario durante la operación normal. Solo termina cuando el usuario ejecuta explícitamente **Cerrar sesión**.
- La sesión local es la autoridad operativa vigente. El APK productivo configura explícitamente el backend mediante `app/config/production.json`; SINCRONIZAR obtiene credenciales remotas para sesiones locales previas, incluidos maestros, sin cambiar UUID ni requerir logout.
- Las identidades maestras documentadas para Martin Osuna, Rene y Omar conservan su normalización canónica; el acceso local no se limita a esas identidades.

## 6. Identificación del medidor y sistema de hidrantes
- Se permite capturar **cualquier ID/número de cuenta**.
- Se consulta de solo lectura la **API existente del proyecto de hidrantes** para saber si la cuenta existe y, si hay levantamiento previo, recuperar los datos disponibles.
- **No se modifica** la API de hidrantes para este proyecto.
- La UI solo comunica el estado de la consulta (ej. existente/con levantamiento, existente/sin levantamiento, nuevo/no localizado).
- Si no hay levantamiento previo, no se inventan datos del medidor.
- La ruta y payload exactos del sistema externo deben obtenerse inspeccionando su API real antes de implementar el adaptador; nunca se inventan en el SSOT.

## 7. Modelo operativo
Jerarquía principal:

`Usuario → Medidor → Expediente → Caudal → Muestras → Puntos/Evidencias`

- Un **expediente** agrupa toda la verificación de un mismo medidor.
- La V1 vigente crea obligatoriamente Q1 (Caudal operativo) y Q2 (Caudal medio), sin pedir LPS aproximado en Identificación; el modelo histórico continúa pudiendo leer Q1–Q4 y valores `lps_approx` legados.
- Cada caudal puede contener **muestras ilimitadas** hasta que el técnico finaliza la verificación.
- El caudal se calcula desde el primer pulso. INICIO, cada evidencia INTERMEDIA y FINAL persisten una lectura puntual LPS; mínimo, máximo y promedio se derivan exclusivamente de esos snapshots.
- Cada muestra se calcula y cierra individualmente.
- Al finalizar el expediente se genera un **veredicto global del medidor** según los caudales evaluados.

## 8. Fuentes de adquisición y simulación trazable
- **Manual/tap**.
- **LED emitido por ESP32**, detectado por cámara. Un pulso detectado equivale al volumen configurado `K`.
- **Bluetooth desde ESP32**. READ/NOTIFY entregan el contador acumulativo uint32; cada incremento reconciliado equivale a `K` litros. Una notificación puede recuperar varios pulsos; un contador duplicado no agrega ninguno.
- **LECTURA VISUAL** se utiliza con medidores reales en campo y no es simulación. El archivo web legado sigue siendo únicamente una herramienta externa de validación y no se integra ni se modifica.
- **SIMULACIÓN** es una fuente local exclusiva de QA, explícitamente rotulada como no física. Antes de INICIAR presenta un caudal fluctuante de campo; Q1 permanece entre 5 y 7 L/s y Q2 entre 2 y 3 L/s, con cambios consecutivos máximos de 0.5 L/s. El operador decide cuándo iniciar y finalizar. Sólo desde INICIAR se acumulan tiempo, pulsos y Vref. Al terminar captura manualmente las lecturas INICIO/FINAL y el motor real decide con Vref, Vind, U y MPE; no existe un resultado prefabricado.
- Una Sample simulada persiste su escenario, participa en recovery y permanece marcada en Historial, CSV, JSON, HTML y PDF. No inicia BLE ni exige backend, Internet, cámara o ESP32.
- En SIMULACIÓN Android y en la demo Web, los indicadores verdes de Bluetooth y control remoto son deliberadamente demostrativos; no afirman una conexión física. La captura manual muestra recortes ilustrativos del totalizador y dial generados desde una carátula demo y permite abrir la carátula completa. La imagen no interviene en los cálculos.
- Las fuentes de pulsos, incluida SIMULACIÓN, implementan la abstracción común `PulseSource`; LECTURA VISUAL comparte Sample/Evidence sin fabricar pulsos.
- En ESP32 v2, GPIO27 recibe el flujómetro 1 de control calibrado y gobierna Vref/integridad; GPIO25 recibe pulsos opcionales del flujómetro 2 bajo prueba. La ausencia de pulsos GPIO25 no es una falla y el medidor 2 continúa documentándose mediante fotografías y lecturas.
- Firmware ESP32 V1.0 filtra GPIO25/GPIO27 con PCNT integrado, exige un pulso LOW de al menos 17 ms, rearme HIGH y debounce. Cada unidad se configura con serie/versión; `--nombre ESP32-NS1001-V1.0` anuncia `DDR001-PULSE-NS1001-V1.0` para conservar el contrato de descubrimiento.
- ESP32 y control remoto mantienen presencia mediante keepalive cada 10 s. BLE recupera transporte/GATT y contador con reintentos persistentes de 1, 2, 4, 8, 15 y hasta 30 s, sin cambiar la conexión directa ni firmware. El control remoto conserva sus tres comprobaciones negativas. Un rollback del contador no se recupera como continuidad válida (ADR-025).
- La conexión BLE física persiste entre Método, Preparación y Preparación de cámara, incluso al navegar con Atrás o comenzar una verificación nueva. Cambiar o fijar regiones no recrea ni desconecta la fuente; solamente `DESCONECTAR ESP32` destruye el transporte durante la vida de la app. En Fuente/Método, BUSCAR siempre renueva la lista con dispositivos que acrediten nombre, servicio, característica y payload DDR001.
- Un ESP32 con GATT activo puede dejar de anunciarse y aun así permanece conectado: BUSCAR combina anuncios válidos con la conexión DDR001 activa y nunca elimina el módulo confirmado por lecturas exitosas. Keepalive duplicado no publica cambios de UI ni persistencia.

## 9. Cámara y lectura manual
- Cada captura obligatoria sigue siendo una sola fotografía completa de la carátula. La Evidence original permanece intacta y produce derivados TOTALIZADOR/DIAL únicamente para presentación.
- Preparación de cámara ocurre sobre preview vivo y fija zoom y regiones. Reutiliza la última geometría confirmada sin sugerir otra automáticamente; si no existe geometría previa realiza una sugerencia inicial. Cada pulsación de `NUEVA SUGERENCIA DE REGIONES` prueba un candidato distinto antes de repetir el ciclo. No toma Evidence ni obtiene una lectura.
- La app productiva no ejecuta OCR, detección de aguja ni otro método automático.
- INICIO se captura al iniciar sin pedir valores. INTERMEDIATE permanece automática. FINAL se captura al terminar y presenta ambos crops.
- El técnico captura manualmente en FINAL el totalizador, la aguja y el total del medidor (`Vind`). No se fabrica lectura INICIO.
- En BLE y SIMULACIÓN la captura de aguja es una lectura libre no negativa, sin máximo de 100 L ni límite por vuelta. `Vind` se deriva de la diferencia entre las lecturas compuestas `totalizador × litros/unidad + aguja`; por ejemplo, 10.345→10.547 m³ equivale a 202 L, no 0.202 L. No se solicita un total duplicado. Los métodos que reconstruyen una posición cíclica dentro de una vuelta conservan su validación contra `litersPerRevolution`.
- Geometría y zoom se congelan por Sample y se recuperan durante RUNNING.
- Preparación permite solicitar nuevamente las sugerencias geométricas después de modificar zoom. Las lupas de ambos extremos son botones de zoom además del slider.

## 10. Evidencia obligatoria
- Evidencia fotográfica obligatoria: inicio, capturas intermedias según paso configurado (por defecto 25 L) y final.
- Si una foto obligatoria falla o queda inválida/corrupta, la corrida no puede producir una muestra válida: se avisa el error y se ofrece **Reintentar prueba**.
- Cada archivo se guarda con hash y metadata de captura.

## 11. Metrología
- Nomenclatura V1: Q1 operativo hereda todas las reglas de la antigua Q3 permanente; Q2 conserva sus reglas. Q3/Q4 permanecen para compatibilidad histórica.
- MPE por zona y fórmula endpoint: `METROLOGY_RULES.md`.
- La regla de decisión considera la incertidumbre mediante banda de guarda y contempla resultado **NO CONCLUYENTE**.
- El conteo/reconstrucción de vueltas de la aguja se conserva como protección contra ambigüedad de 100 L/vuelta y puede adaptarse técnicamente en Flutter siempre que entregue el mismo `V_ind` correcto.
- No se utiliza el promedio de puntos intermedios como error reportable.

## 12. Offline-first e inmutabilidad
Sin conexión el técnico puede:
- iniciar sesión si ya existe una sesión local válida;
- capturar una verificación completa;
- usar sensores/cámara;
- calcular resultados;
- consultar expedientes locales;
- generar HTML de evidencia y PDF;
- dejar todo en cola de sincronización.

Las muestras cerradas no se editan. Una corrección requiere una nueva muestra. Los borradores y expedientes sincronizados se conservan localmente por ahora; no hay purga automática.

## 13. Reporte
- HTML autocontenido con fotografías embebidas (Base64 o equivalente data URI).
- Debe reproducir la **estructura y apariencia** del HTML de referencia.
- Debe usar cálculos y veredictos del nuevo motor, aunque difieran del ejemplo legado.
- Incluye botón **Descargar PDF** y el PDF conserva el contenido/orden visual.
- Incluye error, incertidumbre, MPE, regla aplicada y veredicto para trazabilidad.
- Presenta muestras en orden cronológico, vocabulario español, fecha en el encabezado y hora local en cada punto. Incluye V.MEC real y caudal puntual mínimo, máximo y promedio.
- Cada expediente congela el ID del banco de pruebas y, como metadata interna no visible en el reporte, ID del teléfono, Android, marca y modelo cuando Android los proporciona.
- El reporte incluye configuración metrológica, ESP32, repetibilidad y mapa del GPS. Integridad/adquisición, endpoints, trazabilidad de evidencias y geometría de cámara permanecen consultables en el resumen local de pruebas finalizadas.

## 14. Backend y almacenamiento
- SQL Server 2014 bajo el schema aislado `functional_diag`; única FK compartida a `rv.users`.
- `ddr001_api`: Node.js + TypeScript + Express. `backend/` Prisma/PostgreSQL permanece sólo como referencia histórica.
- Evidencias físicas en filesystem administrado por el API bajo `functional-diagnostics`; SQL Server guarda metadata, hashes y storage keys opacas.
- La capa de storage debe estar abstraída para migrar posteriormente a S3-compatible sin cambiar el dominio.
- Endpoints de lectura/listado deben servir también a un panel administrativo posterior.

## 15. Orden de implementación
0. SSOT y ADRs (esta etapa).
1. Motor metrológico y tests.
2. Dominio + persistencia local offline.
3. UI Flutter fiel a capturas.
4. Cámara, detección de aguja y OCR.
5. ESP32 LED/BLE.
6. Reporte HTML/PDF.
7. Backend + sincronización + endpoints de consulta.
8. Adaptador de solo lectura a API existente de hidrantes.
9. Endurecimiento Android y pruebas de campo.

## 16. Definition of Done
Una tarea solo está terminada si: código correcto + tests verdes + lint/analyze + SSOT actualizado cuando aplica + CHANGELOG + ADR cuando aplica. Nunca se considera terminado un cambio metrológico sin tests de frontera.
