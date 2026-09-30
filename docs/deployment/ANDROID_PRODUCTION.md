# APK Android productivo

Backend oficial: `ddr001_api`, SQL Server `DDR001_Hidrantes_Prod`.
El directorio `backend/` de este repositorio es histórico y no se despliega.

Desde `app/`:

```sh
flutter build apk --release --dart-define-from-file=config/production.json
```

`config/production.json` contiene únicamente `DDR001_API_BASE_URL` pública.
No omitir ese archivo: sin define, la app es offline y oculta SINCRONIZAR.
Android autoriza el transporte HTTP del despliegue actual sólo para
`cifra.aquafim.com`. Si cambia a HTTPS, actualizar configuración y retirar
esa excepción; no deshabilitar verificaciones TLS.

Copiar `build/app/outputs/flutter-apk/app-release.apk` con nombre versionado a
`/sdcard/Download/`. Confirmar SHA-256 origen/destino y versionName/versionCode.
Instalar encima de la versión anterior, nunca desinstalar ni borrar datos.
En esta entrega el agente sólo copia; la instalación queda al operador.

Tras instalar, abrir Historial → expediente → SINCRONIZAR y esperar el ACK
Sincronizado. Una falla conserva el expediente y sus fotografías. La demo Web
no participa. Las simulaciones Android se marcan y no aparecen por defecto en
consultas productivas.

Para medir cámara con una prueba real: registrar `DDR001 START_BUTTON_ACCEPTED`,
`CAMERA_SHUTTER_REQUEST` y `CAMERA_FILE_READY` en logcat y comparar con un reloj
visible o video externo. El intervalo de archivo incluye procesamiento JPEG;
no equivale al instante de exposición. Verificar nitidez de totalizador/dial.
