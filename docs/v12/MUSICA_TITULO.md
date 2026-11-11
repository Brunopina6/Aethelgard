# La canción del título: «REBELUM — When the World Forgets» (V12, 11/11/2026)

## Decisión del usuario (11/11)

- Es **la canción de la pantalla de inicio** de REBELUM: lo primero que escucha el jugador.
- **Queda RESERVADA para el desenlace del juego.** El jugador la escuchará al empezar y volverá a encontrarla al
  terminar la aventura. El final todavía no está escrito ni decidido:
  - no se inventa ni se implementa nada del final;
  - no se cambia la historia;
  - cuando llegue el momento se decidirá si suena la canción entera, otra interpretación o una introducción
    instrumental, sin perder su melodía.
- No se sustituye por ninguna otra pista ni se compone otra.

## La pista

| Dato | Valor |
|---|---|
| Archivo del usuario | `C:\Users\G513\Downloads\REBELUM — When the World Forgets (2).mp3` |
| Origen | Suno Pro (canción original para REBELUM; metadatos «made with suno», creada el 2026-11-11), voces en inglés, J-rock sinfónico con orquesta |
| Duración y formato | 5:01,99 · MP3 48 kHz estéreo, 183 kb/s · SHA-256 `1d7deac78827bd8a8becbc81367e9da4252dacd4006ef9cc1dfee2fee0c5529d` |
| Maestras (fuera de Git) | `D:\REBELUM_musica\maestros\`: el MP3 **idéntico** al original (mismo SHA-256) y `[MAESTRA 48k 24bit].wav` (decodificado sin pérdida) |
| Versión del juego (fuera de Git) | `aethelgard/audio/musica/titulo/when_the_world_forgets.ogg`: Vorbis q5, 48 kHz estéreo, 5:01,96, 5,5 MB |

**Licencia.** Norma vigente (CLAUDE.md, desde el 08/11): la música de Suno, solo en pruebas privadas locales, fuera de
los commits y de cualquier APK que se distribuya.
- `aethelgard/audio/musica/` está en `.gitignore`.
- La APK de Auditoría la lleva, porque es una prueba privada en el Redmi; su comprobación de licencias la marca como
  «NO DISTRIBUIR» (`audio/musica/`).
- El usuario dice que es de Suno Pro. Si quiere cambiar la norma, debe decirlo y se registra en `docs/recursos.md`.

## Análisis (medido en la forma de onda; `D:\REBELUM_diagnostico\v12\musica\`)

- **Sonoridad** (LUFS momentáneos):
  - la introducción, suave: −26 → −17 en 10 s;
  - el cuerpo, entre −20 y −15;
  - pausas hacia 0:40-1:00, en 3:50-4:00 (puente, −27,7) y en 4:30-4:44;
  - el final, fuerte (−15 en el último segundo).
- **El grupo entra a los 7,0 s:** los graves (bajo y batería) pasan de −54 a −28. La gran subida, a los **53 s**.
- **El final no es un corte:** es un golpe que se apaga en unos 0,8 s, hasta −36 en el último instante.

## Cómo se repite

Se repite **entera**: acaba con su golpe, que se apaga, y vuelve su introducción suave. Así no se corta ninguna voz ni
se trocea la estructura, y el enlace es el de «la canción acaba y empieza otra vez». El bucle instrumental se descartó:
habría que cortar la canción por dentro, y no se ha encontrado un tramo sin voces que se pueda medir sin escucharlo.

El OGG lleva solo dos fundidos para que no haya chasquidos en la vuelta:
- 0,03 s al empezar;
- 0,42 s en el último resto del golpe, desde 5:01,55, con curva suave.

Tono, velocidad y melodía no cambian. Godot la repite sin huecos: `loop` se pone al sonar (`musica.gd`, «bucle»).

**Sin escuchar todavía:** el enlace se ha comprobado en los números, no de oído.

## En el juego

- **`musica.gd`, contexto «titulo»** (`portada/inicio_alternativo.tscn`):
  - una sola reproducción, por el bus Música, que respeta el volumen y el silencio de Ajustes;
  - empieza desde el principio al entrar («desde_cero»);
  - sigue sin cortes de la carga a «TOCA PARA EMPEZAR», al menú y a Opciones, porque es la misma escena;
  - al empezar o continuar la partida se funde (1,2 s) hacia el audio del lugar;
  - al volver al título empieza de nuevo;
  - sin el archivo (es privado), silencio.
- **`portada/inicio_alternativo.gd` y `fondo_portada.gd`, las luces con la canción** (nunca sobre las opciones):
  - el logo respira con la introducción;
  - a los 7,0 s, un destello del cristal y la escena se aviva;
  - a los 53 s, un poco más;
  - en cada vuelta, otra vez en calma;
  - el viento de fondo baja para no ensuciarla.
- **La pantalla original** (`carga.tscn`) no cambia y sigue sin música. Se elige en Ajustes → «Pantalla de inicio» →
  «Original».

## Pruebas

**`prueba_musica_titulo`** (nueva) comprueba:
- que suena al entrar, desde el principio y una sola vez, por el bus Música y en bucle;
- que sigue al abrir el menú y Opciones;
- que se calla al ir al juego;
- que vuelve a empezar al volver al título;
- que respeta el silencio del bus.

Con `prueba_musica`, `prueba_portada_alternativa` y `prueba_portada_estable`: 4 de 4 (11/11).

Pendiente:
- el Redmi: memoria, FPS, carga y toques;
- escucharla, el enlace del bucle incluido.
