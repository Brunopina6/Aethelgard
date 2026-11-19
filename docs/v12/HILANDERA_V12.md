# Hilandera del Eco en el combate (V12, 19/11/2026)

**Estado: implementada y APAGADA, pendiente de decisión del usuario y de verla en el Redmi.** No sale en el juego normal.
No es definitiva: las cifras de combate y el encuadre son propuestas **[P]**.

La primera de las tres bestias de T-097 que faltaban (PC-17; D-075 aprobada): «Élite de una gruta. Un artrópodo que
orienta las placas del lomo hacia los sonidos de la cueva». Ficha:
`D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\REBELUM_Bestiario\Fichas_e_integracion.txt`, líneas 37-41. Mismo
método que Velaria (`VELARIA_V12.md`) y el Cencerrante (`CENCERRANTE_V12.md`).

> **Licencia (PD-42).** El modelo es de Meshy, de la cuenta del usuario (tarea `01a1bd67-4bf7-74f7-a637-6356ad68912f`),
> y la licencia **no está confirmada**. Solo puede ir en APK de prueba privadas. Anotada en
> `docs/versiones/licencias_pendientes.txt` (`hilandera_completo`) y en `docs/recursos.md`.

## 1. Modelo y clips (Blender 5.2.3, por script)

- **Fuente, sin tocar:** `REBELUM_Bestiario\blender\hilandera_eco.blend` (SHA-1 `d5a10986…`) y
  `modelos\hilandera_eco.glb` (`cf3bb5e6…`). Se trabajó sobre una copia
  (`D:\REBELUM_diagnostico\hilandera_19_11\blender\hilandera_eco_copia.blend`).
- **Esqueleto:** el del usuario ya servía y no se ha cambiado: `root` (sin deformar), `body`, `abdomen` (las placas del
  lomo), `head` y seis patas de tres tramos (`leg{1,2,3}_{upper,middle,tip}.{L,R}`), 22 huesos. Mira a −Y en Blender
  (+Z en Godot). Inspección: `D:\REBELUM_diagnostico\hilandera_19_11\blender\inspeccion.txt`; signos de giro medidos:
  `signos.txt`.
- **Clips del usuario, sin tocar:** `reposo` (bucle, 1,07 s), `mordida_resonante` (impacto en el fotograma 23 =
  **0,733 s**), `trama_de_eco` (pulso en el 26 = **0,833 s**), `recibir_golpe`.
- **Clips nuevos** (`aethelgard/enemigos/hilandera/fuentes_blender/crear_clips.py`, con `.gdignore`):
  - `aviso_mordida` (1,23 s): el turno en que marca a su presa. La postura de aviso de la mordida (su fotograma 12),
    las placas orientadas, dos temblores y vuelta al reposo; el aviso a 0,40 s.
  - `derrota` (1,17 s): se encoge, las patas ceden hacia fuera y cae sobre el vientre; un estertor de las delanteras.
  - `entrada` (1,43 s): llega correteando desde 1,0 m por detrás (marcha de trípode) y se asienta.
  - `correr` (bucle, 0,4 s): corretea en el sitio (marcha de trípode), para acercarse a su presa y volver.
- **GLB:** `aethelgard/enemigos/hilandera/hilandera_completo.glb` (8,6 MB, SHA-1 `778466ac…`) y sus tres texturas 2K
  extraídas, comprimidas para la GPU (s3tc/etc2, como las del Cencerrante). Copia con los clips:
  `D:\REBELUM_diagnostico\hilandera_19_11\blender\hilandera_clips.blend` (fuera del historial).
- **Renders de las poses** (frente 3/4, cámara y luz fijas, una hoja por clip):
  `D:\REBELUM_diagnostico\hilandera_19_11\renders\hoja_{reposo,mordida_resonante,trama_de_eco,recibir_golpe,aviso_mordida,correr,entrada,derrota}.png`.
  Revisados: las patas apoyan, no hay piezas cruzadas a la vista. La primera derrota (patas recogidas bajo el cuerpo) se
  quedaba de pie con las patas rectas; se rehízo con las patas vencidas hacia fuera y el cuerpo en el suelo, y el ladeo
  se bajó de 9° a 3° porque levantaba las patas de un lado como palos.
- **Presentación en Godot:** `enemigos/hilandera/hilandera_3d.gd` (y `hilandera_3d.tscn`), como `cencerrante_3d.gd`.
  Señales `aviso(ataque)` (la que faltaba, `docs/memory/agents/animaciones.md:890`: sale al empezar cada ataque y en el
  punto alto de la marca), `impacto(ataque)` (una vez, en el ancla), `ataque_terminado`, `clip_terminado`.
  `alcance()` mide en las pistas del clip cuánto adelanta las mandíbulas la mordida; `placas()` da de dónde sale el pulso.

## 2. Cómo se enciende

- Interruptor de sesión **`hilandera_v12`** (`Engine.set_meta("hilandera_v12", true)` o `-- hilandera_v12`). Apagado
  por defecto y fuera de la partida guardada.
- Banco de pruebas de Auditoría: caso nuevo **«Hilandera del Eco: mordida resonante y trama de eco (prueba)»**
  (`banco_pruebas.gd`, clave `hilandera`, GRUPOS[33], Kael, Lya y Garon, vida ×3 para verlo todo). Enciende el
  interruptor solo en ese caso; al salir se quita (`METAS_SESION`).
- Combate de prueba **GRUPOS[33]** (la Hilandera sola). No está en `AL_AZAR_POR_TAMANO` y queda por encima de
  `GRUPOS_AL_AZAR`: nunca sale al azar.
- Apagada, `preparar()` no cambia nada: si alguien pide a mano el grupo 33, es «agresivo» (los patrones de siempre) y sus
  golpes se ven con la mordida. No hay tiradas nuevas. Su carpeta queda fuera de la precarga (`recursos.gd`, APAGADOS).

## 3. Qué hace encendida (`aethelgard/combate_hilandera.gd`)

Mismo patrón que Velaria y el Cencerrante: IA en `turno()`, el daño en `combate.gd _animar_golpe` (su impacto, una vez,
con `_ligar(impacto)`, CIERRES_19_11) y la presentación en `hilandera_3d.gd`.

- **mordida_resonante, en dos turnos.**
  - **Marca:** alza el frente y orienta las placas hacia su presa (`avisar()`, clip `aviso_mordida`; la señal «aviso»
    pide `hilandera_aviso_mordida` una vez). Sobre su vida, «⚠ Cargando» y la señal de aviso; **sobre el héroe marcado,
    otra señal** (violeta, del color de sus placas). Son sprites, sin partículas: se leen en cualquier perfil gráfico,
    como pide la ficha. Ningún daño. El cartel dice a quién ha marcado con una frase neutra, que concuerda igual con
    Kael que con Lya, Naira o Nix: «Hilandera del Eco orienta las placas hacia Lya: ¡es su presa!» (revisión 19/11;
    antes decía «¡lo ha marcado!»).
  - **Mordida (el turno siguiente):** se acerca correteando hasta donde sus mandíbulas llegan al marcado en el impacto
    (su frente en reposo + `alcance()`, como el Cencerrante), alza el frente (`hilandera_aviso_mordida`) y muerde: el
    impacto (daño ×1,6 y `hilandera_mordida`) va UNA vez en el ancla del clip (0,733 s). Defender lo deja a la mitad,
    como cualquier golpe; Garon puede cubrir. La marca se quita y vuelve a su sitio. Si el marcado cayó, elige otro.
- **trama_de_eco:** desde su sitio alza las placas (`hilandera_aviso_trama`) y suelta un pulso a **todo el grupo** con
  **una sola resolución**: en el ancla del clip (0,833 s), un anillo violeta que se abre desde las placas (un sprite
  con su propia textura, `textura_anillo()`: hueco, filo claro por dentro y oscuro por fuera, mezcla normal; se ve con
  efectos reducidos), el daño de todos los héroes a la vez (×0,8 cada uno; menos la mitad de su defensa; Defender
  a la mitad; las reglas del golpe a todos de `_turno_patron`) y `hilandera_trama` una vez.
  **El turno siguiente se recupera** sin atacar («recoge las placas del lomo»): la presión es predecible.
- No tiene golpe suelto: cada turno marca, muerde, teje la trama o se recupera. Sin presa marcada, trama con 0,4 y si no
  marca.
- Si cae ella o su presa, la marca se quita (`repasar`, en `_actualizar`); al acabar el combate, también (`al_acabar`).

**Cifras PROPUESTAS [P], sin equilibrar (decisión del usuario):** PV 160, ataque 13, velocidad 13, exp 48, oro 30
(élite: más vida que el Velador, 115, y el Custodio, 130; el ataque de ambos); `MULT_MORDIDA` 1,6, `MULT_TRAMA` 0,8 a
cada héroe, `PROB_TRAMA` 0,4. Afinidades: fila **neutra** (la ficha no trae). Botín de la ficha («Placa de eco»): no
añadido, el objeto no existe. Encuadre (ventana 900 × 600, 2,0 m de alto de vista mirando a 0,8 m; `caida` 1,4 s)
**sin ver en el Redmi**.

## 4. Cambios en archivos

- Nuevos: `aethelgard/combate_hilandera.gd` (y `.uid`); `aethelgard/enemigos/hilandera/` (`hilandera_3d.gd` y `.uid`,
  `hilandera_3d.tscn`, el GLB y sus tres texturas con sus `.import`, `fuentes_blender/crear_clips.py` con `.gdignore`);
  `aethelgard/pruebas/prueba_hilandera_combate.gd` y `prueba_hilandera_modelo.gd` (y sus `.uid`).
- `aethelgard/combate.gd`: precarga del módulo; `MODELOS["hilandera"]`, `ENEMIGOS["hilandera"]`, GRUPOS[33],
  `ANIM["hilandera"]`; ganchos «V12, Hilandera» en `_elegir_enemigos` (preparar), `_turno_enemigo` (su IA),
  `_animar_golpe` (su rama con `_ligar(impacto)`), `_actualizar` (repasar la marca) y `_comprobar_fin` (al_acabar).
  Los sonidos salen por el `_sonidos_bestia` de siempre (la clave «hilandera» y la primera palabra del ataque dan
  `hilandera_aviso_mordida`, `hilandera_aviso_trama`, `hilandera_mordida` y `hilandera_trama`, ya en `sonido.gd`):
  no hizo falta tocarlo. Sin el interruptor, nada de esto cambia un combate de siempre.
- `aethelgard/combate_afinidades.gd`: fila neutra. `aethelgard/recursos.gd`: su carpeta, con `hilandera_v12`.
- `aethelgard/banco_pruebas.gd`: caso `hilandera` y su interruptor en `METAS_SESION`.
- Pruebas: `lista_pruebas.txt` (la nueva; la nota de `prueba_salir_a_mitad`); `prueba_salir_a_mitad.gd` (once ramas
  ligadas con la Hilandera); `herramientas/diag_salir_hibrida.gd` (dice qué estática le toca a la Hilandera);
  `prueba_banco_pruebas.gd` (20 casos, el de la Hilandera en B y su interruptor en E); `prueba_meshy_e01.gd` (GRUPOS
  tiene 34 entradas).
- `docs/recursos.md` y `docs/versiones/licencias_pendientes.txt`: su procedencia y su licencia pendiente.

## 5. Pruebas (19/11/2026, `ejecutar_pruebas.ps1 -Solo`, datos aislados; `git status` igual antes y después)

`2026-11-19_192205` (la nueva, a la primera):

```
prueba_hilandera_combate SUPERADA     8,2 s
OK: U: apagada; A (semilla 20261119); B: apagada, 2 turnos con la mordida { "entrada": true, "marca": 4, "mordida": 4, "defendida": 4, "trama": 2, "recupera": 1, "vuelta": 4 }
FALLOS: 0
```

`2026-11-19_192245`:

```
prueba_integridad    SUPERADA    10,7 s
prueba_salir_a_mitad SUPERADA    32,2 s     (ligados en combate.gd: 11 de 11 [... "Velaria", "Cencerrante", "Hilandera"])
prueba_meshy_e01     SUPERADA    15,9 s
SUPERADAS 3 · FALLIDAS 0 · MANUALES 0 · NO SEGURAS 0
partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin cambios · otros Godot: 0
```

`2026-11-19_192408`:

```
prueba_magia_negra   SUPERADA     9,6 s
prueba_banco_pruebas SUPERADA    24,5 s     (OK: A: archivo propio, grupo de partida, 7 selectores y 20 casos)
prueba_vida_enemigos_solape SUPERADA     8,7 s
SUPERADAS 3 · FALLIDAS 0 · MANUALES 0 · NO SEGURAS 0
partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin cambios · otros Godot: 0
```

(Los AVISO de `prueba_vida_enemigos_solape` son los de siempre, con la magia negra de desarrollo en GRUPOS 0, 24 y 27;
ninguno de la Hilandera.)

`2026-11-19_192513`:

```
prueba_velaria_combate SUPERADA     4,7 s
prueba_cencerrante_combate SUPERADA     7,5 s
prueba_hilandera_combate SUPERADA     9,1 s
prueba_cargas        SUPERADA    11,3 s
prueba_escalado      SUPERADA     7,3 s
prueba_enemigos_v12  SUPERADA    11,1 s
SUPERADAS 6 · FALLIDAS 0 · MANUALES 0 · NO SEGURAS 0
partida.save real: sin cambios · carpeta real de datos: sin cambios · proyecto: sin cambios · otros Godot: 0
```

`2026-11-19_193336` (prueba de modelo nueva, `prueba_hilandera_modelo`, en la lista; repetida con `prueba_integridad` y
`prueba_hilandera_combate` en `2026-11-19_193418`: SUPERADAS 3 · FALLIDAS 0, `git status` igual):

```
prueba_hilandera_modelo SUPERADA     2,3 s
  ok    la mordida adelanta las mandíbulas 0.765 m en el impacto
  ok    en reposo, las mandíbulas 0.730 m por delante de su sitio
  ok    mordida_resonante: impacto a 0.733 s de la orden (esperado 0.733 ± 0.05)
  ok    trama_de_eco: impacto a 0.833 s de la orden (esperado 0.833 ± 0.05)
  ok    aviso de la marca a 0.400 s (0,40)
  ok    cae al suelo: la raíz baja de 0.001 a -0.478 m
FALLOS: 0
```

(Comprueba los 8 clips, que cada uno gira los 22 huesos, que los ataques, la marca, el golpe y la entrada acaban en la
pose del reposo, los bucles, las texturas 2K comprimidas, que el GLB no trae cámaras, aviso e impacto una vez y en su
ancla también con pausa y con un golpe a medias, la derrota en el suelo sin atacar ni avisar, revivir, la entrada desde
1,0 m por detrás, el alcance, ALTURA y `.new()`.)

Qué comprueba `prueba_hilandera_combate`: **U** (apagada: interruptor, `preparar()`, solo su grupo, nada al azar,
precarga, afinidades, modelo y sus 7 sonidos en el catálogo; desde la revisión, el anillo del pulso: textura propia,
hueca, violeta y sin mezcla aditiva); **A** (encendida con Kael, Lya y Garon; se defienden hasta
verlo todo y luego atacan): la entrada con su clip; cada marca con una señal «aviso», sin impacto ni daño, «⚠ Cargando» y
la señal visible sobre el marcado y la frase neutra «¡es su presa!» con su nombre; cada mordida el turno siguiente con un impacto, solo al marcado, la marca fuera y de
vuelta a su sitio (defendida, la mitad o menos); cada trama con un impacto y UNA resolución (todos los héroes vivos
pierden PV una vez, en el mismo fotograma, con su pulso y un solo anillo) y luego siempre recuperación sin golpe; nunca dos tramas
seguidas; ganan los héroes, cae con su derrota y no quedan marcas; cada señal pide su sonido una vez y en su fotograma;
la entrada suena una vez; **B** (apagada en su grupo: nunca marca, carga ni se recupera; sus golpes son la mordida).

## 6. Capturas del combate en el banco (con ventana)

`D:\REBELUM_diagnostico\hilandera_19_11\capturas\` (1280 × 720; `capturas.txt` dice qué es cada una; guion fuera del
repositorio: `..\fotos_banco.gd`, con datos aislados): `01_entrada`, `02_reposo`, `02_marca_sobre_el_heroe` (la señal
violeta sobre Lya y «⚠ Cargando» sobre ella), `03-05` aviso e impacto de la mordida (junto a Lya), `06-07` aviso y pulso
de la trama, `07_recupera`, `10_impacto_mordida_resonante_2`, `14-15` la segunda trama, `90_derrota_cayendo` y
`91_derrota_en_el_suelo`. Una primera tanda está en `capturas_1\`.

Vistas: la marca y los carteles se leen; la mordida llega a la presa; la trama alcanza a los tres con un número cada uno.
Para revisar en el teléfono: es grande (sus patas casi tocan su barra de vida); en la mordida pasa por delante de Kael y
Garon; tendida en el suelo, sus patas derechas llegan bajo Garon.

## 7. Lo que queda

- **Decisión del usuario:** las cifras [P] (PV, ataque, multiplicadores, probabilidad de la trama); sus afinidades
  (neutras); el botín («Placa de eco», sin objeto); la regla de la marca (dos turnos para morder es una propuesta: la
  ficha dice «castiga al objetivo marcado»); si algún día sale en encuentros normales (en qué gruta y con quién).
- **Licencia de Meshy (PD-42):** confirmarla antes de cualquier publicación. Hasta entonces, solo APK de prueba
  privadas.
- **Redmi:** ver el caso del banco: encuadre 900 × 600, legibilidad de la marca y del anillo con el perfil bajo,
  rendimiento (GLB de 8,6 MB y tres texturas 2K). Sin probar en el móvil.
- **Sin capturas de estudio** del modelo (como `prueba_cencerrante_fotos`, con la textura sin comprimir frente a
  comprimida): las texturas van comprimidas como las del Cencerrante, sin esa comparación propia.

## 8. Revisión 19/11 (HILANDERA_19_11_REVISION)

- **docs/recursos.md:** la fila de la Hilandera llevaba dos caracteres de control en las rutas de procedencia (U+0082 en
  `entradas\2026-11-09_bestiario` y un retroceso en `hilandera_19_11\blender`). Reescritas con barras invertidas
  literales; de paso, las mismas roturas en la fila del Zarzalín (`bestiario\2026-11-09\zarzalin\blender\…`) y en la
  del Bramavidrio v3 (`animaciones\2026-11-12\bramavidrio3`), comprobadas contra las carpetas reales. Queda una: la
  fila de Naira PROVISIONAL (l.26) nació cortada en 4f9e93b (un `\a` y un `\n` tomados como escapes: la ruta y el resto
  de la fila se perdieron); no se reconstruye lo que no se sabe.
- **La frase de la marca:** «¡lo ha marcado!» no concordaba con Lya, Naira o Nix; ahora «¡es su presa!». La prueba lo
  mira en cada marca.
- **El pulso de la trama:** era el brillo radial aditivo de combate.gd, que salía como un resplandor blanquecino que
  teñía el cuerpo de azul. Ahora es un anillo de verdad (`textura_anillo()` / `sprite_anillo()`): hueco, filo claro
  por dentro y violeta oscuro por fuera, con mezcla normal. Capturas con ventana:
  `D:\REBELUM_diagnostico\hilandera_19_11_revision\capturas\10_impacto_trama_de_eco_1.png` (recién abierto) y
  `11_pulso_abierto_trama_de_eco_1.png` (a 5 fotogramas): se lee como un aro violeta alrededor de ella, sin taparla.
  La prueba mira la textura (hueca, banda violeta con alfa ≥ 0,8, sin material aditivo) y un anillo por pulso.
  Sigue pendiente verlo en el Redmi con el perfil bajo.
- **lista_pruebas.txt:** la descripción de `prueba_salir_a_mitad` decía «diez ramas» al final; ahora «once».
