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

Integrado por el especialista de combate el 11/11 en `claude/v12-climax` (commits `d00ef60` y `74cadc0`). Probado en el
PC (aislado). **Sin escuchar y sin probar en el Redmi.**

**Dónde está:**
- `aethelgard/combate_climax.gd`: la configuración y las cuentas (qué jefes, qué canción, el umbral);
- `aethelgard/combate.gd`: cuándo y cómo suena (ganchos «V12, clímax»: `_quitar_pv`, `_process`, `_climax_empezar`,
  `_musica_fase2`).

**Cuándo se activa:**
1. Un golpe deja al jefe autorizado **entre 1 PV y el 20 % de su vida máxima**, y antes estaba por encima. Si el golpe lo
   mata, no hay clímax. Nunca con la vida sin poner (`hp_max` 0) ni si el jefe ya empezaba por debajo.
2. Queda pendiente hasta que acaba ese golpe: empieza cuando el combate vuelve a esperar o a pedir órdenes (nunca a
   mitad de una animación). Si el jefe cae antes, no empieza.
3. **Una sola vez por combate:** ni más golpes, ni que se cure por encima del 20 %, ni otro jefe autorizado lo repiten.

**Qué pasa:**
1. La música del combate baja a −40 dB en 0,9 s y se quita.
2. Suena el golpe de energía de la segunda fase (`fase2` de `sonido.gd`, ya licenciado), una vez.
3. «¡Momento decisivo!» en dorado unos 2 s y un velo dorado muy suave: nada se pausa ni se oscurece.
4. A los 0,9 s entra la canción **desde 0**, por el bus **Musica** (respeta el volumen del jugador), a −7 dB, en bucle
   desde 13,62 s (`loop_offset` puesto al sonar).
5. Cuando la canción llega a su estallido (1,2 s, mirando su posición real), un destello dorado sobre el jefe.
6. La canción pasa a ser la música del combate: la victoria, la derrota y la huida la cierran con el fundido de siempre
   (1,8 s) y suenan su victoria o su derrota de siempre. Al salir del combate no queda ningún reproductor.

**Mezcla:** en combate, el bus Musica ya se aparta solo cuando suenan efectos (`sonido.gd`, `APARTAR_MUSICA_EN_COMBATE`,
compresor que escucha a Efectos). La canción va por ese bus, así que avisos, golpes, interrupciones y menús quedan por
encima sin tocar nada más. Falta escucharlo.

**No toca:** el estado del combate, el ATB, las interrupciones, las invocaciones ni las técnicas combinadas. Si a la vez
llega la segunda fase de un jefe con fases, la fase no cambia la canción.

**Configuración por jefe** (`combate_climax.gd`):
- `CATEGORIAS`: «normal», «elite» y «minijefe» no pueden tenerlo. «jefe» se puede elegir, «gran_jefe» es candidato y
  «final» llevará su propia banda.
- `JEFES`: clave de `ENEMIGOS`, su categoría, su pista y «activo». Hoy solo está activo `bramavidrio`. Están apuntados,
  sin activar, el Coloso de la Falla, el Guardián del Bosque, Gorthor, el Guardián de piedra y el Gólem de ámbar.
- `PISTAS`: la ruta, el `loop_offset`, el instante del estallido y el volumen de cada canción.
- Un enemigo de élite nunca lo tiene.

**Cómo desactivarlo:**
- todo el sistema: `ACTIVO = false` en `combate_climax.gd`;
- un jefe: su «activo»: false en `JEFES`.

**Pruebas:** `pruebas/prueba_climax_jefe.gd` (en `lista_pruebas.txt`), superada. Capturas en
`D:\REBELUM_diagnostico\combate\2026-11-11_climax\`.

## Volumen del clímax frente a la música del combate (12/11, noche)

Medido con `ebur128`, sonoridad integrada:

| Pista | LUFS | Volumen en el juego | Efectivo |
|---|---|---|---|
| `musica_combate_normal.mp3` (la de todos los combates; la de los jefes también) | −12,2 (pico +0,1 dBFS) | −6 dB | −18,2 |
| `volvera_a_amanecer_climax.ogg` | −13,9 | antes −7 dB, **ahora −4,5 dB** | antes −20,9, **ahora −18,4** |

- **Por qué:** a −7 dB el clímax sonaba casi 3 dB por debajo de la música que sustituye, y el gran momento se oía como una
  bajada. Ahora queda casi igual.
- **Los efectos no quedan tapados:** el clímax va por el bus Musica y en combate se aparta solo cuando suenan efectos
  (`sonido.gd`, `APARTAR_MUSICA_EN_COMBATE`).
- **Cómo cambiarlo:** `PISTAS["volvera_a_amanecer"]["db"]` en `combate_climax.gd`.
- **Sin escuchar:** el equilibrio está medido, no oído.

**No hay música propia de jefe:** `musica_jefe.mp3/.ogg` y `musica_jefe_fase2.mp3` no existen en el proyecto. Por eso los
jefes usan la música normal y en su segunda fase la aceleran (`PITCH_FASE2`). No es un fallo: `combate.gd` ya lo
contempla.
