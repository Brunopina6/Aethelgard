# Clímax musical de los grandes jefes: «REBELUM — Volverá a amanecer» (V12, 11/11/2026)

**Encargo del usuario (11/11):** que la canción suene solo en la fase final de los combates más importantes, cuando el
jefe autorizado baja al 20 % de su vida o menos. Se activa una vez por combate y entra desde su momento más emocionante.
Demostración con Bramavidrio. Debe ser una señal emocional de los grandes combates, nunca constante.

## La pista

| Dato | Valor |
|---|---|
| Archivo del usuario | `C:\Users\G513\Downloads\REBELUM — Volverá a amanecer.mp3` · 5:43,63 · MP3 48 kHz estéreo · «made with suno» · SHA-256 `6d0e945186f650bef3c937c1b7abc85448be71b0ceef0b60a1d1fd6d17481c8a` |
| Licencia | Suno Pro del autor (lo dijo el 11/11 al entregarla para el juego); registrada en `docs/recursos.md` |
| Maestras | `D:\REBELUM_musica\maestros\REBELUM - Volvera a amanecer [ORIGINAL].mp3` (idéntico) y `[MAESTRA 48k 24bit].wav` |
| Versión del juego | `aethelgard/audio/musica/jefes/volvera_a_amanecer_climax.ogg` · Vorbis q5, 48 kHz estéreo · **1:07,07** · 1,3 MB · `loop_offset` **13,62 s** |

## Análisis (LUFS momentáneos; banda de voz 500-3000 Hz)

| Tramo | Qué es |
|---|---|
| 0:00-0:12 | introducción |
| 0:12-0:52 | estrofa |
| 1:00-1:32 | subida |
| 1:32-2:32 | primer estribillo |
| 2:36-2:48 | puente |
| 3:12-4:00 | segundo estribillo, más fuerte |
| 4:00-4:08 | caída breve |
| 4:08-5:08 | estribillo final: el más alto y largo, hasta −12,8 |
| 5:08-5:22 | silencio dramático, −21 a −27 |
| **5:23,2** | el estallido: de −21 a −13,6 en 0,3 s |
| 5:24-5:40 | el clímax, −12,4: el pico de la canción |
| 5:43 | fin |

- **El grito «¡REBELUM! ¡QUE VUELVA A AMANECER!»** se ha localizado por su forma de onda: el gran estallido de voz
  justo después del silencio dramático, a los **5:23,2**. Sin reconocimiento de voz no se ha podido confirmar la letra
  exacta: **falta que el usuario lo escuche**.
- **El tempo** no se fijó con precisión. Los empalmes se eligieron por el patrón rítmico (correlación de los ataques en
  ventanas de 4 s) y en finales de frase, que son las bajadas de sonoridad.

## Cómo está montado el archivo del clímax

1. **0:00-1:20 (del original 5:22,0-5:23,2):** 1,2 s de subida, de −21 a −20.
2. **Hacia 1,2 s:** el estallido, y el clímax hasta 5:35,62 del original. **Una sola vez.**
3. **Empalme a 13,22-13,62 s:** fundido cruzado de 0,4 s de igual potencia (correlación rítmica 0,44) hacia el
   estribillo final.
4. **13,62-67,07 s (del original 4:13,23-5:06,68):** el estribillo final, que **se repite** mientras dure el combate.
   La vuelta va de 5:06,68 a 4:13,23 (53,45 s; correlación 0,50), con otro fundido de 0,4 s. Termina al final de
   frase, justo antes del silencio dramático.

**Medido en los empalmes** (cada 0,2 s), sin silencios ni saltos de más de 1,5 dB:
- del clímax al estribillo: −13,6 · −13,8 · −13,8 · −14,5 · −15,0;
- en la vuelta: −13,1 · −13,6 · −14,2 · −14,9.

Pico −4,75 dBFS, con un limitador por seguridad. Tono y velocidad sin cambiar. **Sin escuchar.**

**Para el juego:** al activarse, la música del jefe se apaga en unos 0,8-1 s y entra este archivo desde 0. El golpe
cae 1,2 s después.

## El sistema

Lo integra el especialista de combate. Se documentará aquí al integrarlo.
