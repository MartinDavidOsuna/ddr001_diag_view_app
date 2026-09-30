# Demo Web local

La demo es autónoma: no usa login, API, SQL ni producción. Desde `app/`:

```bash
flutter run -d chrome -t lib/main_web_demo.dart \
  --web-hostname 127.0.0.1 --web-port 8080
```

Abrir `http://127.0.0.1:8080` en Chrome. Para servir un build estático en
Firefox o Edge:

```bash
flutter build web -t lib/main_web_demo.dart
```

Servir el contenido de `app/build/web/` bajo `localhost`; no abrir
`index.html` directamente con `file://`. Cada navegador conserva su propio
historial local. **BORRAR HISTORIAL** sólo elimina los expedientes demo de ese
navegador.

## Recorrido de presentación

La versión 1.7.0+19 conserva el orden de pantallas de SIMULACIÓN Android en
portrait: Inicio → Identificación → Método → Preparación → Prueba → Lecturas
→ Resultado → Q2/repetición → Resumen → cierre y reportes. Los indicadores
ESP32/control sólo se muestran en Prueba en curso (también en el preflujo).

Las fotografías simuladas se registran durante la prueba y pueden ampliarse;
el formulario de lecturas no propone automáticamente un resultado. Los
exportes CSV/JSON/HTML/PDF comparten el renderizador de Android. La recuperación
del borrador es local al navegador, sin avanzar pulsos durante la pausa.

## Validación automatizada

Desde `app/`:

```bash
flutter analyze
flutter test
flutter test --platform chrome test/web_demo/web_demo_app_test.dart
flutter build web -t lib/main_web_demo.dart
```

Las pruebas de widgets de Chrome suministran una imagen PNG de prueba y el
manifiesto de assets mediante el messenger de Flutter Test, que no sirve ese
canal como el runtime normal. Las pruebas de dominio/exportación en VM validan
la carátula real empaquetada, su hash y las imágenes embebidas en reportes.
