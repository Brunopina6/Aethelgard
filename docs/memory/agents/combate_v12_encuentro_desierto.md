# Combate, V12 · Encuentro nuevo del desierto: Vidracrán (demostración reversible)

## 12/11/2026, 12:00-13:30 · rama LOCAL `claude/v12-hito-encuentro-desierto` (`D:\Aethelgard_v12_encuentro`)

Desde `claude/rebelum-v12` @ `a23e131`. Sin push ni merge. Todo APAGADO: no sale en ningún encuentro de siempre; solo
en sus combates de prueba (`-- grupo=14|15|16`) o con el interruptor `encuentro_desierto_v12` en el Mar de Cristal.
Nombre de narrativa sin aprobar (NARRATIVA_DESIERTO.md §4).

### 1. Cuál y por qué (comparación técnica)

| | Vidracrán (elegido) | Tolvanera (intacta) |
|---|---|---|
| Legibilidad | silueta opaca de escorpión, bulbo verde que late: se lee contra la arena y a 20 m | polvo semitransparente color arena sobre arena: poco contraste (capturas del prototipo) |
| Coste | modelo y 10 clips listos (enterrarse, aviso, emerger, derrota…); faltaba solo `ruta_modelo`, el recorte bajo el suelo y la arena mate | 3 capas transparentes (sobredibujado sin medir en el Mali), derrota con un rastro que sobra, necesita un estado de clima en el combate |
| Reutiliza | la piel y la ventana del Coloso (×0,5 / ×1,5 y sus puntos débiles), el aviso + Defender de Zarzalín, la Guardia de Garon, `_anim_zarzalin` | «Agua lo asienta» lo tiene solo Lya (Kael o Kael + Garon no podrían contrarrestarla); «el viento le cura» no tiene contrapartida en las habilidades de hoy |
| Contrarrestable con cualquier grupo | sí: Defender, la Guardia, golpear en la ventana, magia contra el caparazón | no sin Lya |

Tolvanera no se ha tocado (`enemigos/tolvanera/**` igual que en `a23e131`).

### 2. La mecánica («caparazón y ventana»)

- **Caparazón de vidrio:** golpes físicos ×0,5, magia entera (como la piel de piedra del Coloso). «Caparazón» sobre su vida
  y en el panel de objetivos.
- **Ciclo fijo, sin azar:** Pinzas (a uno, ×1) → **se entierra** → **Aguijón** → Pinzas…
  - *Anticipación (enterrarse):* escarba (clip `enterrarse`), su montón de arena se desliza junto al héroe elegido (la
    curandera si ha curado; si no, el de menos vida: la regla de Zarzalín), el bulbo late dos veces (clip `aviso_aguijon`),
    «⚠ ¡Aguijón!» y un triángulo verde se quedan sobre ese héroe, y el registro lo dice («…brilla junto a Lya»).
    **Bajo la arena no se le puede apuntar** (única regla nueva; dura un turno suyo). Con dos, un aguijón a la vez.
  - *Ataque (aguijón, su turno siguiente):* emerge bajo el marcado (clip `emerger_aguijon`, impacto a 0,5 s), ×1,8.
    **Se contrarresta:** Defender lo deja a la mitad; la Guardia de Garon se lo lleva él (a la mitad).
  - *Ventana:* vuelve corriendo a su sitio **expuesto** hasta su turno siguiente: golpes físicos ×1,5 y los puntos débiles
    del Coloso brillan (`_marcar_puntos`). Al empezar su turno «cierra el caparazón».
- **Reacción y derrota:** `recibir_golpe` (no si está bajo la arena o atacando) y `derrota` (se apaga el vidrio), con su
  voz de vidrio y su derrumbe.
- **Sin estados nuevos que se guarden:** todo vive en el diccionario del luchador (`vc_*`) y acaba con el combate. No usa
  la magia negra ni cambia fórmulas: los multiplicadores son los del Coloso y de Zarzalín.
- **Atacar sin nadie a tiro** (todos bajo la arena): no deja apuntar, vuelve al menú con «Está bajo la arena: no hay a
  quién apuntar. Defiéndete o cúrate.», sin gastar turno ni PM (también magia a todos, Esgrima, artes, magia negra,
  dúos, Érebo). Al empezar el turno de un héroe el registro avisa: «Vidracrán está bajo la arena: va a por Lya.
  ¡Defiéndete!».
- **Números:** 300 PV, ataque 18, velocidad 19, 55 de experiencia, 32 monedas (nivel del desierto 10; el escalado de
  siempre). Medido en la prueba A: tres héroes a nivel 10 con estrategia ganan en un ciclo y medio (11-12 turnos de héroe).

### 3. Sonido y procedencia

10 OGG mono 48 kHz (126 KB) en `aethelgard/enemigos/vidracran/sonido/`, claves nuevas `EFECTOS_VIDRACRAN` de
`sonido.gd` (y su voz, familia «vidracran»). Hechos con `preparar_vidracran.py` (Python estándar + el `ffmpeg.exe` 4.4.1
que ya estaba en el PC): recortar, cambiar el tono, sumar capas, filtro, normalizar por pico, Vorbis q4. Script y
procedencia en JSON: `D:\REBELUM_diagnostico\combate\2026-11-12_encuentro_desierto\herramientas\`. **Medido, no
escuchado.**

**Licencia:** paquetes GDC 2016 y 2017 de Sonniss (`D:\qtorrent\sound effect`, solo lectura), licencia «#GameAudioGDC»:
uso comercial ilimitado, sin atribución, editarlos dentro de la producción, no revenderlos tal cual (del historial:
leídas el 08/11 y comprobadas el 09/11, `docs/audio/inventario_sonidos.md`; los `Licensing.pdf` siguen en sus carpetas).
No se ha copiado ninguna biblioteca: solo los 10 derivados.

| Clave (archivo) | Cuándo | Capas (archivo · tramo s · tono · dB) | dur. s · pico/RMS dBFS |
|---|---|---|---|
| `vidracran_pinzas` (pinzas.ogg) | impacto de las pinzas | Window,Small,Crack,Medium Impact,Bright · 0-0,30 · ×0,85 + Wine Glass Hit Higher Pitch · 0,219-0,42 · ×0,7 · −10 | 0,35 · −1,1/−17,1 |
| `vidracran_enterrarse` | al empezar a enterrarse | Grit,course,hardsurface,dropping,scatter,alt1 · 1,0-2,4 · ×0,8 + Grit,medium,…,mortar,rolling,circles · 3,0-4,4 · ×0,85 · −6 | 1,75 · −4,7/−34,6 |
| `vidracran_aviso_emerger` (aviso.ogg) | primer latido del bulbo | Wine Glass Hit Higher Pitch · 0,219-0,46 · ×0,9, y otra vez a +0,267 s · ×0,95 · −1; eco | 0,59 · −2,7/−25,5 |
| `vidracran_brota` / `vidracran_entrada` (brota.ogg) | emerge / entra | Grit,course,hardsurface,throw,scatter · 0-0,67 · ×0,85 + SHARDS [LD Mono] 16 - Drop, Glass, Small Shards · 0,28-1,0 · −8 | 0,79 · −2,9/−29,4 |
| `vidracran_emerger` (emerger.ogg) | impacto del aguijón | SHARDS [LD Mono] 02 - Impact, Glass, Shatter, Small · 3,338-3,70 + Grit throw scatter · 0-0,4 · ×0,7 · −6 | 0,57 · −2,3/−32,4 |
| `vidracran_expuesto` | se abre la ventana | Window,Small,Crack,Medium Impact,Bright · 0-0,8 · ×0,75 | 1,07 · −3,0/−22,4 |
| `vidracran_herido` (herido_1/2.ogg) | voz de herido | Window,Small,Break,…Clinking Pieces · 0-0,28 · ×1,1 / SHARDS 02 · 9,168-9,40 · ×1,2 | 0,26 / 0,19 |
| `vidracran_caida` | voz de caída | Glass,Bottle,Break,Smash,Messy · 0-0,45 · ×0,8 | 0,56 · −1,3/−20,1 |
| `vidracran_derrumbe` | al morir (derrumbe de bestia) | Window,Small,Break,…Clinking Pieces · 0-1,39 · ×0,8 + SHARDS [LD Mono] 24 - Trickle, Glass, Metal, Debree · 0,53-2,0 · −10, a +0,4 s | 1,87 · −2,2/−23,5 |

SHA-256 de los derivados: aviso `d2c7277a27947ed190c8dd5daf9cd8e465ed49f5f4314a31e9f8a7278b276ea4`, brota
`b1bbd202a0f5f131d587ef2633bcd9e8b65176d7e7e4c49eca57d574ad759870`, caida `061342db9b9e7e203b85bc1d357bc5217fabf16fda9a622cfcb98978f81856c6`,
derrumbe `acb90546af68c918c5da1ab25a2ed5c08e9af7ecb5f7d03030f56d68c2a5a79c`, emerger
`305f3f9e773ddb918e34a0ff175232c07e6a542e08f7511a8580cfc1d4822cbf`, enterrarse
`337338ff810c3e8104a96599ab24e19a4999ce3fc4437c89e265b037d99f8627`, expuesto
`0388ec273069587f735cd33aba7f1505f45393776f401aba36300cccbb4b3299`, herido_1
`4180ede02c17cdf8b79e4b01c37fdff795feae52d3de892d8241e8dbc81799a7`, herido_2
`12c009934f1fe33657fcbf1f7371eb4eda1c592cd920fc2cf6957a45a070c066`, pinzas
`22384f6a7088ac30244211a07fc01243c63ba7edf78eafff79692d97b23fb960`.

SHA-256 de los originales (también en el JSON):
- GDC 2017 / Chris Skyes - Shards Broken Glass: `Window,Small,Crack,Medium Impact,Bright.wav`
  `f09b3af79b9321d8325e674a5fd09a7c098978c53f1abf5e3bf0f5a089708d47`; `Window,Small,Break,Medium Impact,Large Amount of
  Clinking Pieces.wav` `c2552ae7d0988bc1e8ac8cc9ce5d2081ec43a371cb1242f2788aadde95700909`; `Glass,Bottle,Break,Smash,Messy.wav`
  `d1852d362caf91b7ea6f70ce85a9905960c6e63ac5089b49d549edca89db3d12`.
- GDC 2017 / Double Trouble Audio - Shards: `SHARDS [LD Mono] 02 - Impact, Glass, Shatter, Small.wav`
  `b0602020399abd287c9f929cef99a09fdcc3783697f48ef246408435adddc3b2`; `… 16 - Drop, Glass, Small Shards.wav`
  `f77d39fb0f89726b383f0420ee1ad7df2861e46bdb8c5702705035cb40b8a4b7`; `… 24 - Trickle, Glass, Metal, Debree.wav`
  `84c6e7a3e5ff16ca78b5fb1c833afc0279c072a5f8d974fb410fbcab0bef46d9`.
- GDC 2016 / George Karagioules - The Source Collection SFX Pack: `Wine Glass Hit Higher Pitch.wav`
  `a3b9a8f4e0e0781943f54c78cec34443839b012b665d347e411552e1080261c0` (el mismo que `barrera_absorbe`, otros tramos y tono).
- GDC 2016 / Eiravaein Sound - Grit: `Grit,course,hardsurface,dropping,scatter,alt1.wav`
  `706cc6e3cd43152361f3094dee972171b05a6bff91b235a633be995d6f607854`; `Grit,medium,hardsurface,mortar,rolling,circles.wav`
  `203c00c31b6eeb8a1ecf549d875fd074dda1e9edb84e725f00189c660daa8a44`; `Grit,course,hardsurface,throw,scatter.wav`
  `75dc3bae91eb931b922db93c547f638af251659388ca412bc3740e54c17d2f29` (el mismo que `excavar_arena_2`).

Cuándo suena (una vez cada uno, comprobado en la prueba): las pinzas y el aguijón por la señal `impacto` del modelo en
el fotograma del impacto; el aviso por la señal `aviso` (primer latido); enterrarse, brota y expuesto desde
`combate_vidracran.gd`; voz por `Sonido.recibe` en los golpes físicos; derrumbe por `_restablecer_color` (bestias).

### 4. Recompensa

55 de experiencia y 32 monedas por cada uno (con el escalado de siempre) y una **Esquirla de vidracrán** (material
nuevo, `datos/materiales/esquirla_vidracran.tres`, se vende por 30) por cada uno vencido (no si huye). Se da desde
`combate_vidracran.gd botin_de` junto al botín de siempre, **sin** `de_enemigos` en el catálogo: así el botín de
`equipo_extra.gd` y `prueba_datos` no cambian.

### 5. Cómo se activa

- **Combate de prueba:** `-- grupo=14` (uno), `15` (dos), `16` (con Grimfang); o `Engine.set_meta("grupo_combate", 14)`.
- **Mar de Cristal:** `-- encuentro_desierto_v12` o `Engine.set_meta("encuentro_desierto_v12", true)`; la mitad de sus
  encuentros al azar pasan a ser de Vidracrán (1 héroe: grupo 14; 2: 14/15/16; 3: 15/16). **Apagado devuelve -1 sin tirar
  dados**: los encuentros y el azar quedan como estaban. Para siempre: `ACTIVO_POR_DEFECTO` de `combate_vidracran.gd`.
- **Quitarlo entero:** borrar `combate_vidracran.gd`, las líneas «V12, encuentro del desierto» de `combate.gd`,
  `sonido.gd` y `mar_cristal_3d.gd`, y `enemigos/vidracran/sonido/`.

### 6. Archivos y commits (para integrar copiando)

| Commit | Archivos (`aethelgard/…`) |
|---|---|
| `593b243` | `enemigos/vidracran/vidracran_3d.gd` (ruta_modelo, alcance, recortar_suelo), `vidracran_vidrio.gdshader` y `vidracran_brillo.gdshader` (recorte bajo el suelo; arena mate), `enemigos/vidracran/sonido/*.ogg` (10) y sus `.import` |
| `fffef98` | `combate_vidracran.gd` (+ `.uid`, nuevo), `combate.gd` (ganchos «V12, encuentro del desierto»), `combate_afinidades.gd` (una fila: `prueba_magia_negra` exige una por enemigo; solo escuelas nuevas), `datos/materiales/esquirla_vidracran.tres` (nuevo) |
| `0f1ae82` | `sonido.gd` (`EFECTOS_VIDRACRAN`, `definicion`, `_hay_voz`, familia «vidracran») |
| `bfb7c57` | `zonas3d/mar_cristal_3d.gd` (preload, `_paso` y `encuentro`: 6 líneas) |
| `108a25a` | `pruebas/prueba_encuentro_desierto.gd` (nuevo) |
| el último | este informe |

Fuera de la lista del encargo, y por eso los señalo: `combate_afinidades.gd` (una fila) y el `.tres` del material.
`combate_bramavidrio.gd`, `enemigos/bramavidrio/**`, `menus.gd`, `enemigos/tolvanera/**` y las partidas: sin tocar.
`project.godot`: la importación aislada vació los directorios de Dialogic; `git restore` y reimportado (sin cambios).

**Pido** (no lo he tocado) esta línea en `pruebas/lista_pruebas.txt`:

```
prueba_encuentro_desierto | auto |                   | 900 | user://     | V12 (12/11), encuentro del desierto (combate_vidracran.gd; interruptor encuentro_desierto_v12 APAGADO): sin interruptor nada cambia; Vidracrán con estrategia (pinzas, enterrarse sin daño ni objetivo, aguijón con un impacto y su sonido una vez, Defender a la mitad, Guardia, ventana), controlado, automáticos, Kael solo, derrota, huida, premio, limpieza
```
y, si se quiere el inventario común al día, las filas del apartado 3 en `docs/audio/efectos_procedencia.csv` y
`docs/recursos.md`.

### 7. Pruebas (comprobado ejecutando, aislado, 12/11)

- **`prueba_encuentro_desierto`** (nueva, auto, ~35 s): SUPERADA, `FALLOS: 0`.
  - U: interruptor apagado por defecto; apagado, `grupo_mar_cristal()` da -1 **sin tirar dados**; ningún grupo de siempre
    ni `grupo_al_azar` (1, 2 y 3 héroes, 300 semillas) trae a Vidracrán; encendido, solo -1 o 14/15/16. ×0,5 / ×1,5 /
    magia entera / 0 bajo la arena, y nada cambia en los demás. 10 claves cargan (OGG, sin bucle, 0,19-1,87 s, ni mudas ni
    saturadas), su voz es la suya. Material en el catálogo; el botín de siempre igual; el interruptor no se guarda.
  - A (Kael, Lya y Garon a nivel 10, estrategia de jugador, grupo 14): gana con pinzas → enterrarse → aguijón (→ pinzas
    con «cierra el caparazón»), 11-12 turnos de héroe; cada turno comprobado (un impacto, un alcanzado, sonido una vez
    en el fotograma del impacto; enterrarse sin daño, no apuntable, marca, aviso una vez; aguijón tras enterrarse y con
    un turno de héroe entre medias, quien defiende ≤ la mitad, Garon cubre, expuesto y su sonido una vez, de vuelta a
    su sitio). Atacar bajo la arena: vuelve al menú con su aviso sin gastar nada. Premio: +1 Esquirla, monedas y
    experiencia; derrumbe una vez; lo guardable sin claves `vc_*`.
  - B (parado): golpe de 40 → 20 (caparazón), 60 (ventana), Fuego 40 entero, 0 bajo la arena; aguijón 32 sin defender,
    16 defendiendo, 14 a Garon con la Guardia.
  - C: grupos 15 (dos; un aguijón a la vez) y 16 (con Grimfang) automáticos: terminan y ganan. D: Kael solo a nivel 10,
    automático: termina (pierde). E: derrota a nivel 1 sin premio; huida.
  - En todos: al acabar, sin marcas ni puntos, ningún sonido suyo sonando tras 2,5 s reales, sin nodos huérfanos nuevos.
- **De combate y desierto** (`D:\REBELUM_diagnostico\pruebas6-11-12_125146esumen.md`): 19 superadas
  (`prueba_grupos_combate`, `prueba_combate_huella` —la huella C0 igual—, `prueba_bramavidrio_combate`, `prueba_mar_cristal`,
  `prueba_huir`, `prueba_incorporacion`, `prueba_garon`, `prueba_equilibrio`, `prueba_ia`, `prueba_menu_magia`,
  `prueba_centinela`, `prueba_datos`, `prueba_audio_desierto`, `prueba_efectos`, `prueba_desierto_prototipos`,
  `prueba_combate_seguro`, `prueba_artes_combate`, `prueba_climax_jefe`, `prueba_coloso`) y `prueba_magia_negra` FALLIDA
  porque Vidracrán no tenía fila de afinidades: añadida y repetida, SUPERADA (`…6-11-12_125816esumen.md`).
- **Batería completa** con la prueba nueva (lista propia = `lista_pruebas.txt` + su línea), sobre `108a25a`:
  **SUPERADAS 133 · FALLIDAS 0 · MANUALES 60 · NO SEGURAS 0**; partida real, carpeta real y proyecto sin cambios.
  `D:\REBELUM_diagnostico\pruebas6-11-12_125849esumen.md`. Durante la pasada había Godot de otras copias (otros
  especialistas): el ejecutor los vigiló y la carpeta real no cambió.

### 8. Evidencias

Capturas con ventana (1280×720, PC, perfil por defecto) en `D:\REBELUM_diagnostico\combate\2026-11-12_encuentro_desierto\`:
`00_pinzas.png` (las pinzas, a Lya), `01_anticipacion.png` (bajo la arena junto a Lya: montón, cola, triángulo verde,
«⚠ ¡Aguijón!» y «Bajo la arena · ⚠ Aguijón: Lya»), `02_aguijon.png` (emerge bajo Garon, que cubre a Lya: 21),
`03_ventana.png` («¡Expuesto!» con los puntos débiles), `04_contraataque.png` (Kael golpea en la ventana) y
`05_derrota.png`. Herramientas de sonido: `herramientas\`.

### 9. Límites

- **No se ha oído nada** (sin escucha posible): niveles medidos, timbre sin juzgar.
- **No jugado a mano ni en el Redmi:** ni tacto real ni FPS del Mali. Coste añadido: un modelo de 2330 triángulos y dos
  materiales opacos; el recorte bajo el suelo usa `discard` en el sombreado de vidrio (sin medir en el Mali).
- Los combates de las pruebas los guía un guion (estrategia sencilla o ataques automáticos), no un jugador.
- Kael solo a nivel 10 contra uno pierde con ataques automáticos (en el juego no llega solo al desierto).
- Si el marcado cae antes del aguijón, pica a otro sin nuevo aviso (se lee en el registro).
- El montón de arena, con Vidracrán «Congelado» (Frostfang), sale teñido de hielo como todo su dibujo (es el tinte de
  siempre).
- Prototipo de animaciones sin aprobar: el modelo es el del 12/11, con tres retoques (ruta del modelo, recorte bajo el
  suelo, arena mate). Nombre sin aprobar.

## 12/11/2026, 13:50 · `prueba_encuentro_desierto` robusta (aviso del coordinador)

**Síntoma:** «FALLO: Vidracrán (aguijon): no queda expuesto» en la principal y en esta copia (registros
`2026-11-12_133605` y `_133738`). Solo aparecía en la parte D (Kael solo, automático).

**Causa (observada en los registros y en el código).** En esas pasadas, la parte D acababa con un aguijón que tumbaba a
Kael. Al caer el último héroe, `_comprobar_fin` llama a `Vidracran.al_acabar` y quita los puntos débiles, como debe.
La prueba miraba `puntos_nodo` después, al ver el cambio de `c.estado`, y ya no estaban. Que el último golpe sea el
aguijón o las pinzas varía de una pasada a otra, porque la carga va en un hilo con tiempo real y el PC estaba cargado.
Además, detectar los turnos por `c.estado` era frágil: dos turnos enemigos seguidos pueden encadenarse en un mismo
fotograma sin que se vea «esperando». **No es un fallo del juego:** la lógica no se ha tocado.

**Arreglo (solo la prueba):**
- Los turnos enemigos se siguen por `c.atacante_actual`. `_turno_enemigo` lo pone al empezar y `_fin_turno_enemigo` lo
  quita antes de su espera de 0,3 s y de `_comprobar_fin`. Si dos turnos van seguidos, el segundo parte del estado en
  que acabó el primero.
- La ventana se comprueba en el mismo fotograma en que se abre. `_vigilar_ventanas()` apunta, al subir el contador
  `expuesto` de `combate_vidracran.gd`, si está expuesto y si sus puntos débiles están en la escena. El aguijón exige
  una ventana abierta así. «Sigue expuesta al cerrar su turno» solo se pide si el combate no ha acabado.

**Comprobado (aislado), tres veces seguidas con `-Lista`:** SUPERADA las tres.
- Resúmenes en `D:\REBELUM_diagnostico\pruebas\`: `2026-11-12_134018`, `_134058` y `_134139`.
- En la 1.ª y la 3.ª, D acaba justo con el aguijón que lo tumba (el caso que fallaba); en la 2.ª, con las pinzas.
