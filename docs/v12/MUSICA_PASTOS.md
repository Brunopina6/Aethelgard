# La música de Pastos Verdes: «Pastoral Pulse» (V12, 11/11/2026)

Elegida por el usuario para la región 3D de Pastos Verdes: el comienzo de la aventura, la naturaleza, la esperanza, la
amistad y los primeros misterios. Instrumental, hecha con Suno Pro para REBELUM.

## La pista

| Dato | Valor |
|---|---|
| Archivo usado | `C:\Users\G513\Downloads\Pastoral Pulse (1).mp3`, el adjuntado. El texto decía «(1)(1)», que no existe; en Descargas hay además `Pastoral Pulse.mp3`, otra toma de 3:10, que **no** se ha usado |
| Original | 2:58,03 · MP3 48 kHz estéreo, 190 kb/s · «made with suno» · SHA-256 `4f220f44ff8bb5fc…` (completo en las maestras) |
| Maestras (fuera de Git) | `D:\REBELUM_musica\maestros\Pastoral Pulse (1) [ORIGINAL].mp3` (idéntico al original) y `[MAESTRA 48k 24bit].wav` (decodificado sin pérdida) |
| Versión del juego (en Git desde el 11/11) | `aethelgard/audio/musica/pastos/pastoral_pulse.ogg`: Vorbis q5, 48 kHz estéreo, 2:44,28, 3,1 MB |
| Licencia | Suno Pro del autor: el 11/11 confirmó la suscripción y autorizó incluirla en el proyecto (Git y APK); registrada en `docs/recursos.md` |

## Estructura y bucle

- **Forma** (LUFS momentáneos):
  - la introducción, suave: −22 → −20 hasta los 4 s;
  - el tema entra a los 5 s y el cuerpo va de −13 a −17;
  - tramos tranquilos en 1:36-1:50 y 2:18-2:25;
  - el final se apaga desde unos 2:49 hasta el silencio (2:58).
- **Puntos del bucle**, elegidos por el patrón rítmico (correlación de los ataques en ventanas de 4 s a los dos lados,
  búsqueda a 10 ms; mejor pareja con correlación 0,60). El tempo no se pudo fijar con precisión: unos 97 pulsos por
  minuto.
  - **Inicio del bucle: 0:11,17.** Lo anterior (la introducción y la entrada del tema) suena **una sola vez**.
  - **Final del bucle: 2:44,28**, justo antes del final que se apaga, que no se usa en el bucle.
  - **Cuerpo que se repite:** 153,11 s.
- **Empalme:** fundido cruzado de **0,4 s** de igual potencia, ya hecho dentro del archivo:
  - los últimos 0,4 s del archivo son el final del cuerpo apagándose sobre los 0,4 s anteriores a 0:11,17;
  - Godot vuelve a 0:11,17 (`loop_offset`, que pone `musica.gd` al sonar).
  
  En la forma de onda no hay coincidencia de fase (0,03, lo normal en una mezcla orquestal), así que el fundido es
  necesario. Más un fundido de 0,03 s al empezar.
- **Medido en el empalme** (los 4 s de antes y los 4 de después, cada 0,1 s): −15,1 · −15,3 · −15,3 · −14,9 LUFS, sin
  silencio ni saltos de más de medio decibelio.
- **Tono y velocidad sin cambiar.**
- **Sin escuchar:** el empalme se ha comprobado con números, no de oído. Si suena mal, los puntos se cambian en
  `docs/v12/MUSICA_PASTOS.md` y `musica.gd` («bucle_desde») y se rehace el OGG con el mismo filtro.

## En el juego

- **Elegible:** Ajustes → «Música de Pastos Verdes» → «Pastoral Pulse» o «Solo ambiente».
  - Por defecto, «Solo ambiente», que es lo de siempre: Pastos Verdes no tenía música, solo el ambiente de la pradera,
    que no se ha tocado.
  - Se guarda en `user://ajustes.cfg`, `[musica] pastos`.
- **`musica.gd`, contexto «pradera_musica»:**
  - la música por el bus Música (−9 dB) y el ambiente de la pradera algo más bajo (−9 dB, antes −6);
  - una sola reproducción;
  - el combate la calla con un fundido y al volver sigue donde iba;
  - el mapa la calla y al volver a Pastos sigue donde iba;
  - al venir de la pantalla de inicio, la canción del título se funde (1,2 s) y entra esta (2 s);
  - la pausa de Android lo para todo y lo reanuda.
- **No cambia:** el resto de regiones, la canción del título ni nada de la banda sonora.

## Pruebas (11/11, en el PC, datos aislados)

**`prueba_musica_pastos`** (nueva) comprueba:
- que suena una sola vez por el bus Música y con el ambiente;
- el bucle (cerca del final vuelve a la sección central sin pararse);
- que el combate la calla y se reanuda donde iba, sin duplicarse;
- que el mapa la calla;
- que con «Solo ambiente» no suena.

Junto con `prueba_musica_titulo`, `prueba_musica`, `prueba_zona3d` y `prueba_foco`: 5 de 5.

Pendiente:
- en el Redmi, la memoria y los FPS;
- escucharla durante un rato largo.
