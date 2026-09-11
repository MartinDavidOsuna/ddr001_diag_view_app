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
