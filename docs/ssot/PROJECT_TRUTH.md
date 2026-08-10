# PROJECT_TRUTH — DDR001 Verificador de Medidores

> **Estado:** SSOT consolidada — Etapa 0 cerrada el 2026-08-08.
> Este archivo es la referencia principal para ChatGPT/Codex. Ante discrepancias entre prototipo, capturas, código o documentos anteriores, prevalece `docs/ssot/`.

## 1. Misión
Migrar el verificador web legado a una aplicación **Flutter nativa para Android** con backend **Node.js + TypeScript + Express**, persistencia **PostgreSQL + Prisma** y operación **offline-first**. La nueva app conserva el flujo y apariencia validados del prototipo, pero corrige y endurece metrología, persistencia, evidencia, visión, autenticación y sincronización.

## 2. Alcance inmediato
- Plataforma móvil: **Android únicamente**, orientación **portrait**.
- App: Flutter + Riverpod + Drift/SQLite.
- Backend: Node.js + TypeScript + Express + Prisma + PostgreSQL.
- Repositorio: **monorepo** por ahora.
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
- Primer login: si el usuario no existe en DDR001 Verificador, se da de alta automáticamente con el nombre capturado y se cargan sus datos. Un usuario local legado sin nombre conserva su mismo ID y recibe el nombre capturado al volver a acceder.
- Sesión persistente: no caduca para el usuario durante la operación normal. Solo termina cuando el usuario ejecuta explícitamente **Cerrar sesión**.
- El backend emite credenciales/token persistentes apropiados para esta política; la app almacena la sesión de forma segura.

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
- Un expediente puede contener pruebas en Q1, Q2, Q3 y Q4.
- Cada caudal puede contener **muestras ilimitadas** hasta que el técnico finaliza la verificación.
- `LPS aprox.` es un dato manual.
- Cada muestra se calcula y cierra individualmente.
- Al finalizar el expediente se genera un **veredicto global del medidor** según los caudales evaluados.

## 8. Fuentes de pulso productivas
- **Manual/tap**.
- **LED emitido por ESP32**, detectado por cámara. Un pulso detectado equivale al volumen configurado `K`.
- **Bluetooth desde ESP32**. Cada evento/notificación válida equivale igualmente a `K` litros.
- La funcionalidad que el prototipo/simulador identifica como simulación se conserva en producción bajo el nombre **LECTURA VISUAL**: se utilizará con medidores reales en campo, usando la cámara/visión para obtener la lectura del medidor y derivar el avance observado. El archivo web legado sigue siendo únicamente una herramienta externa de validación y no se integra ni se modifica.
- Todas las fuentes implementan una abstracción común `PulseSource`.

## 9. Cámara, visión y OCR
- La app intenta reconocer automáticamente la **aguja** y los **dígitos del odómetro**.
- Si no detecta la aguja, informa explícitamente al técnico y permite continuar hacia captura/confirmación manual cuando proceda.
- Si OCR falla, solicita lectura manual.
- Tras una lectura automática exitosa siempre muestra la lectura detectada y pide confirmación: **¿Es correcta?**
- Antes del cierre de la muestra el técnico puede corregir la propuesta automática; después del cierre, la lectura queda inmutable.

## 10. Evidencia obligatoria
- Evidencia fotográfica obligatoria: inicio, capturas intermedias según paso configurado (por defecto 25 L) y final.
- Si una foto obligatoria falla o queda inválida/corrupta, la corrida no puede producir una muestra válida: se avisa el error y se ofrece **Reintentar prueba**.
- Cada archivo se guarda con hash y metadata de captura.

## 11. Metrología
- Nomenclatura correcta: Q1 mínimo, Q2 transición, Q3 permanente, Q4 sobrecarga.
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

## 14. Backend y almacenamiento
- PostgreSQL + Prisma.
- Node.js + TypeScript + Express.
- Evidencias físicas inicialmente en filesystem administrado por el backend en Windows Server 2018; PostgreSQL guarda metadata, hashes y rutas lógicas.
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
