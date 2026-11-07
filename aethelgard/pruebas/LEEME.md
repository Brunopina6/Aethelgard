# Pruebas de Aethelgard

Scripts para comprobar el juego sin jugarlo a mano. No entran en el APK (`exclude_filter` de `export_presets.cfg`).

Uso general (desde `D:\Aethelgard`):

```
"<ruta>\Godot_v4.7.2-stable_win64_console.exe" --headless --path aethelgard --script res://pruebas/prueba_garon.gd --fixed-fps 30 -- grupo=1 auto embuir=Fuego esgrima=Giro
```

- Sin `--headless` y con `--write-movie <carpeta>\c.png` se guardan los fotogramas para verlos.
- Argumentos de combate (después de `--`): `grupo=N`, `auto`, `invocar`, `erebo=exito|fallo`, `embuir=Fuego`, `esgrima=Juicio|Giro`, `magia=Fuego:3`, `objeto=Éter`, `movil`.
- `herramientas/`: utilidades de arte (reducir modelos de Meshy, render de la isla, hojas de contactos con `hoja.ps1`).

## Ejecutar todas las pruebas (aisladas y con código de salida)

Desde `D:\Aethelgard`:

```
powershell -ExecutionPolicy Bypass -File .\aethelgard\pruebas\ejecutar_pruebas.ps1            # las automáticas
powershell -ExecutionPolicy Bypass -File .\aethelgard\pruebas\ejecutar_pruebas.ps1 -Manual     # también las de capturas, con ventana
powershell -ExecutionPolicy Bypass -File .\aethelgard\pruebas\ejecutar_pruebas.ps1 -Solo prueba_garon,prueba_huir
```

**Aislamiento: tus datos reales no se tocan.**
- Cada pasada lanza Godot con `APPDATA`, `LOCALAPPDATA`, `TEMP` y `TMP` apuntando a carpetas propias, así que `user://` queda dentro de la pasada.
- La sonda (`sonda_datos.gd`) lo comprueba antes de ejecutar nada. Si `user://` no está aislado, no se ejecuta ninguna prueba.
- El ejecutor toma la huella SHA-256 de toda la carpeta real de datos del juego (con `partida.save`) antes y después, y compara `git status`.

**Lista de pruebas:** `lista_pruebas.txt`. Cada línea indica el modo, los argumentos, el tiempo máximo, qué escribe y una nota. Los modos son:
- `auto`: sin ventana, en cada pasada.
- `ventana`: saca capturas.
- `manual`: necesita a una persona.
- `insegura`: no se ejecuta nunca.

**Resultados:**
- `SUPERADA`: terminó sin errores de script y sin declarar fallos.
- `FALLIDA`: error de script, código de salida distinto de 0, la prueba imprime `FALLO` o `FALLOS: n`, o se le acabó el tiempo.
- `MANUAL`: necesita intervención, sea revisar capturas, elegir argumentos o usar el móvil.
- `NO SEGURA`: no se puede ejecutar sin riesgo para los datos reales.

**Código de salida:**
- El número de pruebas FALLIDAS (0 si no hay ninguna).
- 254 si cambiaron los datos reales.
- 255 si no se pudo aislar.

**Registros, capturas y resumen (`resumen.md` y `resumen.csv`):** en `D:\REBELUM_diagnostico\pruebas\<fecha_hora>\`, fuera del proyecto.

**Qué comprueban:** casi todas son pruebas «de humo», que recorren el juego e imprimen datos. Cuando una fase toque una prueba, conviene que acabe con `quit(1)` si algo sale mal.
