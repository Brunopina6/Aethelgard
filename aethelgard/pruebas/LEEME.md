# Pruebas de Aethelgard

Scripts para comprobar el juego sin jugarlo a mano. No entran en el APK (`exclude_filter` de `export_presets.cfg`).

Uso general (desde `D:\Aethelgard`):

```
"<ruta>\Godot_v4.7.2-stable_win64_console.exe" --headless --path aethelgard --script res://pruebas/prueba_garon.gd --fixed-fps 30 -- grupo=1 auto embuir=Fuego esgrima=Giro
```

- Sin `--headless` y con `--write-movie <carpeta>\c.png` se guardan los fotogramas para verlos.
- Argumentos de combate (después de `--`): `grupo=N`, `auto`, `invocar`, `erebo=exito|fallo`, `embuir=Fuego`, `esgrima=Juicio|Giro`, `magia=Fuego:3`, `objeto=Éter`, `movil`.
- `herramientas/`: utilidades de arte (reducir modelos de Meshy, render de la isla, hojas de contactos con `hoja.ps1`).
