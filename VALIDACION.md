# Registro de validación

- Flutter 3.47.7, Dart 3.13.5.
- `flutter analyze`: sin incidencias.
- `flutter test`: 4 pruebas aprobadas (GET usuarios, filtro de posts, HTTP 500 y JSON inválido).
- `flutter build apk --debug`: compilación correcta.
- Instalación y ejecución real en emulador Android API 37, ARM64, 1080 x 2400.
- Lista y detalle: respuestas reales de JSONPlaceholder.
- Favoritos: Leanne Graham marcada y persistida; disponible después de `am force-stop` y reinicio con Wi-Fi y datos desactivados.
- Detalle sin conexión: datos del favorito visibles y aviso de que las publicaciones necesitan Internet.
- Carga capturada durante una petición con latencia de red configurada en el emulador; se restauró al finalizar.
- No se registraron excepciones Flutter/AndroidRuntime en la revisión final del log.
- Las capturas son pantallas reales del emulador, no diseños ilustrativos.

El emulador mostró un aviso de System UI durante su arranque inicial. Se cerró ese aviso del sistema antes de las pruebas; no era un cierre de la app del directorio.
