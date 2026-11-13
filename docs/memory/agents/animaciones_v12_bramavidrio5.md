# Animaciones (arte y animación), V12: Bramavidrio versión 5, «la v4 resuelta»

## 12/11/2026, 19:30-21:30 · rama `claude/v12-bramavidrio5` (LOCAL, nace de `83d7774`) · copia `D:\Aethelgard_v12_bramavidrio5`

**Encargo:** la orden del usuario («Bramavidrio debe seguir teniendo prioridad artística hasta resolver
satisfactoriamente su cabeza, mandíbula y movimientos»): una v5 en `enemigos/bramavidrio/v5/` con su guion
`fuente/crear_bramavidrio5.py`, sin tocar la v1-v4, elegible en Ajustes como opción 5 y **sin ser la de por defecto**
(`VERSION_DEFECTO` sigue en 2). Sin push, sin merge, sin ADB.

**Referencia:** la lámina es una **referencia facilitada por el usuario** («Concepto del gusano de arena ancestral.png»;
el original ya no está en Descargas; uso la copia `D:\REBELUM_diagnostico\v12\referencias\bramavidrio_v4_referencia_usuario.png`,
SHA-256 `3A6044C0…A904C5D18`, comprobado hoy). Licencia sin registrar: no la invento. Solo se usa como referencia visual
en las hojas de comparación (fuera del proyecto); no se copia ni entra en el juego. Modelo, textura, normales, esqueleto
y clips: procedurales, de mi guion con Blender 5.2.3. Sin Hunyuan3D ni generadores.

### Commits (rama local, sin push)

| Commit | Qué |
|---|---|
| `5bdf545` | `fuente/crear_bramavidrio5.py`, el generador (primera versión) |
| `6c5a9de` | `enemigos/bramavidrio/v5/`: GLB alto/medio/bajo, pieles, normales y JSON (con sus `.import`) |
| `044a4dd` | `v5/bramavidrio5_3d.gd`, los 4 sombreadores (con `.uid`), `bramavidrio_version.gd` (opción 5) y `menus.gd` |
| `fb983e5` | `pruebas/prueba_bramavidrio5.gd` (nueva) y la v5 en `pruebas/prueba_bramavidrio_modelo.gd` |
| `1e4ea28` | la v5 ajustada (mandíbulas en cuña pegadas al collar, encuadre, látigo), GLB/JSON regenerados y `lista_pruebas.txt` |
| (este) | este informe |

**Para integrar copiando — NUEVOS:** `aethelgard/enemigos/bramavidrio/v5/*` (todo, con `.import` y `.uid`),
`aethelgard/fuente/crear_bramavidrio5.py`, `aethelgard/pruebas/prueba_bramavidrio5.gd` (+ `.uid`), este informe.
**COMPARTIDOS modificados:** `aethelgard/enemigos/bramavidrio/bramavidrio_version.gd` (la entrada 5 en `GUIONES` y
`MODELOS` y comentarios), `aethelgard/menus.gd` (solo el bloque «Bramavidrio»: la opción 5 y la fila pasa de
`HBoxContainer` a `HFlowContainer` porque con cinco botones no cabía en los 1080 px de Ajustes; ya con cuatro se pasaba:
1144 px), `aethelgard/pruebas/prueba_bramavidrio_modelo.gd` (la v5 en `DATOS_VERSION`, la lista por defecto `[1..5]`,
el interruptor con 5 y la holgura de sectores solo si el modelo los tiene), `aethelgard/pruebas/lista_pruebas.txt` (una
línea al final). **No cambian:** `combate.gd`, `combate_bramavidrio.gd`, `gusano.gd`, `recursos.gd`, sonidos, la v1-v4.

**Cómo se enciende:** Ajustes → «Bramavidrio» → «Prueba v5: la v4 resuelta» (`[bramavidrio] version = 5`), o
`bramavidrio_version=5` en la línea de órdenes, o `Engine.set_meta("bramavidrio_version", 5)`.

**Al importar:** `--editor --quit` vació los directorios de Dialogic en `project.godot` (ya avisado); lo restauré con
`git restore` cada vez. `project.godot` no está en ningún commit.

## 1. La cabeza y la boca: diagnóstico de la v4 y lo que hace la v5

**Diagnóstico (renders con las mismas cámaras; hoja `comparar_v4_v5_referencia_cabeza.png`):** la boca de la v4 es un
disco plano: de frente los doce colmillos de los sectores se leen como radios de una rueda alrededor de un sol
amarillo (el fondo de la garganta), de perfil la cabeza es un cilindro romo **sin ninguna mandíbula**, y cerrada solo
cambia el frunce de los labios. La lámina, de perfil, enseña dos mandíbulas grandes con dientes; de frente, una boca
redonda con un marco de placas y colmillos y una garganta honda.

**La v5 (en `crear_bramavidrio5.py`, marcado «v5»):**
- **Cuatro MANDÍBULAS acorazadas** (arriba y abajo, 1,85 y 1,80 m; los lados, 1,55 m) con **bisagra recta** pegada al
  collar (la base no barre nada al girar) y un nudillo de carne y bronce que las une al collar. Son cuñas macizas
  (0,5 m de grueso en la bisagra, quilla en el lomo, coraza fuera y encía dentro, punta dentada). **Abiertas** (la pose
  de enlace) apuntan 22° hacia fuera y enmarcan la boca circular; **cerradas** (−58°) forman un hocico acorazado en punta
  roma delante del esfínter. De perfil se leen ya una mandíbula de arriba y una de abajo.
- **Colmillos que se despliegan** (un hueso por mandíbula, `colm_*`): plegados hacia la garganta con la boca cerrada
  (quedan detrás de las placas), desplegados hacia el eje y adelante al abrir, y **erizados** (1,08) al rugir. En el
  mordisco la boca se cierra con los colmillos fuera: se cruzan delante de la boca.
- El **esfínter de labios de la v4** sigue detrás (ahora avanza 0,55 m al cerrar, no 0,85: el frunce queda detrás de las
  mandíbulas). Los doce sectores de la v4 y sus colmillos-radio **desaparecen**.
- **Dientes:** cuatro filas en **espiral** en el embudo (cada fila girada y curvada hacia la garganta, más pequeñas
  cuanto más hondas) y dos colmillos fijos en cada hueco entre mandíbulas. Todos con cinco anillos de curva
  (`diente_curvo`; la v4 tenía tres y se leían rectos).
- **Garganta** más honda (hasta 1,8 m tras el embudo), con anillos en relieve y una **espiral de luz** de tres brazos
  que baja al fondo, en vez del disco encendido. El fondo es oscuro con un núcleo pequeño.
- **Corona:** los cuernos son más gruesos y curvos (cinco anillos a lo largo de la curva), y entre los dos grandes está
  la **cresta central** de la lámina sobre el núcleo. El marco de placas en punta queda en los cuatro huecos.
- **Esqueleto:** 57 huesos (los 61 de la v4, menos los doce `labio_*`, más `mand_arriba/izq/abajo/der` y
  `colm_arriba/izq/abajo/der`).

**Lo que sigue sin estar a la altura (honesto):** de frente y de tres cuartos, con la boca abierta, cada mandíbula se ve
como una placa separada (la del lado de allá parece despegada desde algunas cámaras de Blender, aunque está unida en la
bisagra: lo he comprobado numéricamente); la lámina tiene mucho más volumen y más dientes en los bordes. En la cámara del
combate se lee bien (fotos de abajo): boca abierta con mandíbula de arriba y de abajo con colmillos. Siguiente paso
propuesto: dientes también en el borde de cada mandíbula y la placa de arriba más ancha, como una «frente» que cubra la
boca (§8).

## 2. Interpenetraciones (comprobado ejecutando, Blender, malla deformada por el esqueleto)

`comprobar_intersecciones` con árboles BVH sobre la malla ya deformada, en **todos los clips cada 0,1 s más los
instantes del contrato (311 instantes)**: mandíbulas entre sí y con la cabeza (cráneo, collar y nudillos, marco,
cuernos), con los labios y con los dientes fijos; colmillos entre sí, con su mandíbula y las demás, con la cabeza, los
labios y los dientes; dientes fijos con labios. Resultado (alto, `bramavidrio5_clips.json`, «intersecciones_total»):
**0 pares en los 10 clips**. No cuentan las bases de dientes y mandíbulas (metidas en la carne o en el nudillo a
propósito). Por el camino corregí, demostrándolo con los pares que se cruzaban: colmillos plegados que se metían en el
gancho de su propia mandíbula (ahora se pliegan hacia la garganta, con el eje del pliegue 10 cm sobre la encía) y las
mandíbulas abiertas de más contra el nudillo (el nudillo cubre ±45° alrededor de atrás). Además, el esfínter se frunce
sin pliegues (paso radial mínimo 1,3 mm) y cada mandíbula se queda en su cuadrante abierta o cerrada.

## 3. Movimientos orgánicos (en el generador: `retardar`, `hornear`, `buscar`, `resorte`)

- **Seguimiento y superposición:** la columna se evalúa con un adelanto distinto en cada tramo (0 en la nuca, máximo
  junto al agujero). Con adelanto > 0 la base va por delante y la cabeza llega después (emerger, rugido, embestida,
  caída de la Fractura, derrota); con < 0 el movimiento nace en la cabeza y baja hacia la cola (la herida y los rebotes
  tras un impacto). La cabeza siempre va a su hora: los instantes del contrato no se mueven. Las crestas van 0,07 s más
  tarde que su tramo. El adelanto nunca baja más deprisa que el tiempo (no hay marcha atrás).
- **Látigo de la embestida:** la base llega a su sitio y **espera** (`tope=1.0`) mientras la cabeza acelera; el cuerpo
  sale del agujero a la hora de la cabeza; en los últimos fotogramas la cabeza va clavada en la dirección del mordisco.
  Medido en Godot: el giro del cuello junto al agujero llega al 99 % a 0,93 s; la cabeza, a 1,0 s.
- **Anticipación** antes de cada ataque (se recoge en S, toma aire, se echa atrás antes de caer), **peso al caer**
  (aceleración cúbica, dos rebotes cada vez menores, el golpe sube por el cuerpo) y **derrota con peso** (se retuerce,
  cede la base, rueda solo al final de la caída, rebota dos veces y las mandíbulas quedan flojas por la gravedad: la de
  abajo cuelga más).
- **Respiración:** el reposo dura ahora 6 s (dos respiraciones de 3 s que bajan por el cuello con retraso, vaivén
  lateral con onda que viaja al agujero, las mandíbulas se separan ≤ 2° al inspirar, el núcleo y la garganta laten).
- **La cabeza busca a su objetivo:** en el reposo vigila al grupo y pasa de un héroe a otro (cada ~2 s) con un muelle
  (llega, se pasa un poco y se asienta); en la embestida, mientras fija (0,55-0,8 s), **el cuello tiembla pero la boca
  se queda clavada** (gira 2,1° como mucho; el cuello se mueve 4 cm).
- **Herida:** la cabeza salta atrás y el golpe baja por el cuello (la cabeza a 0,10 s, el cuello a 0,17 s), las
  mandíbulas castañetean y los colmillos asoman.
- **Contrato:** mismos 10 clips, instantes y señales que la v1-v4 (impacto de la embestida 1,0, Fractura 2,5333,
  descarga 1,85, caída de la derrota 1,6, emersión 0,2333/0,8667…), comprobados por `prueba_bramavidrio_modelo`
  (version=5) y el sonido por `prueba_audio_bramavidrio` con la v5 elegida. La única constante del guion que cambia es
  la **espera de la Fractura**: `[1.3, 1.7667]` (dos vueltas justas de su sacudida: al repetirse no salta); el
  combate no la lee.

## 4. Encuadre (comprobado ejecutando en el combate real, `prueba_bramavidrio5`, parte E)

Combate fijo del grupo 13, cámara de `_crear_rig_3d`, lienzo 1280 × 720. **20:9 y 16:9 dan el mismo encuadre
vertical:** el proyecto usa `stretch canvas_items` con el aspecto por defecto (`keep`), así que en 20:9 (2400 × 1080) el
lienzo de 1280 × 720 se ve entero con bandas a los lados. La prueba mide con el dibujo del gusano quieto: en el combate
cada dibujo «respira» (`combate.gd`, `_process`: escala ±1,2 % y giro ±0,8° sobre los pies), lo que mueve lo alto de la
cabeza unos ±17 px; por eso pide **20 px de margen**.

Lo más alto de la cabeza (puntas de los cuernos, la cresta y las mandíbulas), px desde el borde de arriba (negativo =
fuera); la v4, con las mismas puntas de corona (la medida la favorece: sus cuernos son algo más altos):

| | reposo | **aviso Fractura** | caída Fractura | Aliento | **descarga** | rugido | embestida | herida | derrota |
|---|---|---|---|---|---|---|---|---|---|
| v4 | 11 | **−29** | −5 | −25 | 27 | −44 | −22 | −16 | −30 |
| v5 | 36 | **25** | 54 | 16 | **60** | 25 | −14 | 5 | −12 |

En el aviso de la Fractura de la v4, además, la cabeza se iba 113 px por la izquierda; en la v5 queda a 19-24 px del
borde. Quedan un poco fuera en la v5 (y más en la v4) la anticipación de la embestida (0,4 s) y el principio de la
derrota: no se pedían, pero los apunto. Fotos del combate real: `combate_v5_alto_2400x1080\v5_alto_fractura_1_aviso.png`
y `…_aliento_2_descarga.png` (la cabeza y los cuernos enteros dentro). Ojo: la ventana pedida a 2400 × 1080 la recortó
el monitor a 16:9 (la foto sale 1875 × 1055); la equivalencia 20:9 = 16:9 en vertical es por la configuración, no por
una foto en 20:9.

## 5. Materiales

- **Normales horneadas** de las alturas que pinta la textura (canto biselado y arista de las placas, picaduras, runas
  grabadas, zarpazos hondos, anillos del vientre, estrías y arrugas de la carne, más el paso alto de la luminancia para
  las grietas): `bramavidrio5_normal.webp` 1024 (alto) y `_normal_medio.webp` 512 (medio), importadas como mapa de
  normales comprimido (S3TC/ETC2, con mipmaps). **El bajo no las lleva.** La piel las usa con `#define NORMALES`, más
  marcadas en el mineral (basalto) que en la carne.
- Textura de color 2048/1024/512 (la misma paleta y pintor que la v4), comprimida para la GPU.
- **Triángulos:** alto 16 173 (≤ 18 000), medio 7 970 (≤ 8 000), bajo 3 463 (≤ 3 500).
- No he comparado el coste del sombreador con el Mali Offline Compiler (habría que sacar el GLSL que genera Godot).

## 6. Medida en el PC (`medir_escenas.ps1 -Escenas combate_brama -Perfiles medio -Ciclos 3 -Extra bramavidrio_version=4|5`)

`D:\REBELUM_diagnostico\v12\expansion\bramavidrio5\medidas\v4|v5\`. **Había 10-35 Godot de otros especialistas
abiertos** (`procesos.txt`): los tiempos NO son fiables; los conteos y la memoria sí sirven.

| Combate (medio) | v4 | v5 |
|---|---|---|
| dibujos | 88 | 88 |
| primitivas | 68 514 | 69 336 |
| memoria de vídeo | 106,0 MB | 110,3 MB (+4,3: las normales) |
| texturas | 84,5 MB | 84,7 MB |
| fotograma mediana / p95 (contaminado) | 6,7-7,2 / 8,8-10,3 ms | 5,4-5,8 / 7,8-10,2 ms |

Son medidas del PC, no FPS del Redmi.

## 7. Pruebas (aisladas; partida, carpeta real de datos y proyecto sin cambios en todas)

- **Con la v2 por defecto** (`D:\REBELUM_diagnostico\pruebas\2026-11-12_210209\resumen.md`): `prueba_cargas`,
  `prueba_mar_cristal`, `prueba_bramavidrio_modelo` (las CINCO versiones), `prueba_bramavidrio_combate`,
  `prueba_climax_jefe`, `prueba_audio_bramavidrio`, `prueba_encuentro_desierto` y `prueba_bramavidrio5`: **8 SUPERADAS**.
- **Con la v5 elegida** (`bramavidrio_version=5`; `…\2026-11-12_210555\resumen.md`): mar_cristal, modelo, combate,
  clímax, audio y encuentro del desierto **SUPERADAS (6)**; **`prueba_cargas` FALLIDA**: con la v5 la precarga mete
  también su mapa de normales del perfil (modelo, piel **y normales**) y la prueba pide exactamente dos archivos. Es lo
  que debe hacer (si no, la primera vez del combate se cargaría a medias); el cambio que pido está en §8.
- `prueba_bramavidrio5` (nueva, al final de `lista_pruebas.txt`, con «comparar»): **SUPERADA** (`…\2026-11-12_204414` y
  la de las 8). Partes A-E de su cabecera.
- `fotos_bramavidrio_pulido version=5 perfil=alto` con ventana: `FALLOS: 0`.
- No he pasado la batería completa (más de 200 pruebas) por tiempo: solo las de Bramavidrio y las que lo cargan.

## 8. Evidencias (`D:\REBELUM_diagnostico\v12\expansion\bramavidrio5\`)

- `comparar_v4_v5_referencia_cabeza.png`: arriba la lámina (frente, perfil, tres cuartos), en medio la v4 y abajo la
  v5 **con las mismas cámaras** (frente abierta/media/cerrada, perfil abierta/media/cerrada, tres cuartos abierta y
  cerrada). La v4 se volvió a renderizar con su propio guion (copia en la carpeta temporal con la cámara de perfil en los
  tres estados): `v4_mismas_camaras\`.
- `blender\`: las etapas 1-5 de la v5 (silueta, cabeza y boca, materiales, rig y deformaciones, clips con los muñecos
  de los héroes) y sus hojas, y los vídeos de Blender por clip.
- **`v5_clips.mp4`** (ffmpeg): los 8 clips del combate con su nombre y la boca de cerca en el rugido y la embestida.
- `combate_v5_alto_2400x1080\`: unas 35 fotos del combate real que corre (avisos, impactos, descarga, derrota,
  héroes golpeando) y su registro.
- `medidas\`: las dos pasadas de medida.
- `.blend` fuente: en la carpeta temporal de la sesión (`scratchpad\bramavidrio5\bramavidrio5.blend`); se rehace con
  `blender -b --factory-startup -P fuente/crear_bramavidrio5.py -- aethelgard/enemigos/bramavidrio/v5 alto,medio,bajo [<.blend>] [<fotos>] [1,2,3,4,5,video]`
  (unos 80 s sin fotos; variables `BRAMA_PASO_ROCES` y `BRAMA_DEPURAR`).

## 9. Límites (lo que no he podido comprobar)

- **Redmi:** nada (sin ADB). Lo nuevo de la GPU: el mapa de normales (una lectura más en la piel, alto y medio) y 4 MB de
  VRAM; mismos dibujos.
- **Rendimiento:** medido con otros Godot abiertos: los tiempos no valen; pido repetirlo sin carga.
- **20:9 en foto:** no pude abrir una ventana de 2400 de ancho en este monitor (ver §4).
- **Fotos en medio y bajo con `movil`** del combate real: no las he sacado (solo alto).
- **Sonido:** medido (`prueba_audio_bramavidrio`), no escuchado.
- **El aspecto de las mandíbulas** desde cerca (§1): mejor que la v4 y legible en el combate, pero no tan macizo ni tan
  dentado como la lámina. **No es definitiva:** decide el usuario.

## 10. Siguiente paso y peticiones

1. **Usuario:** ver `comparar_v4_v5_referencia_cabeza.png`, `v5_clips.mp4` y las fotos del combate, y decir si la boca con
   mandíbulas va por buen camino. Si sí, la siguiente vuelta (solo en el generador): dientes en el borde de cada
   mandíbula, la de arriba más ancha como una frente sobre la boca, y la anticipación de la embestida algo más baja.
2. **`pruebas/prueba_cargas.gd` (no es mío),** línea 114-116, para que con la v5 acepte su mapa de normales del perfil:
   cambiar `_ok(brama.size() == 2, …)` por
   `_ok(brama.filter(func(x): return not x.get_basename().contains("_normal")).size() == 2 and brama.size() <= 3, …)`
   (la comprobación de carpeta y perfil de cada archivo, justo debajo, sigue valiendo para las normales).
3. **`docs/recursos.md` (no es mío):** la fila
   `| Bramavidrio v5 «la v4 resuelta»: enemigos/bramavidrio/v5/* | Modelo, textura, normales, esqueleto y clips generados con Blender 5.2.3 por fuente/crear_bramavidrio5.py; referencia visual: lámina facilitada por el usuario («Concepto del gusano de arena ancestral.png», SHA-256 3a6044c0…a904c5d18; licencia sin registrar, no entra en el juego) | Propia | Combate fijo «mc_bramavidrio» y Mar de Cristal (si se elige la versión 5) | Sí |`
4. **Coordinador:** medir en el Redmi (y en el PC sin carga) el combate con la v5 en medio y bajo.

## 12/11/2026, 21:35-22:20 · segunda vuelta de la boca (encargo del coordinador)

**Lo que pidió:** en la hoja, columna 7 (tres cuartos, boca abierta), una mandíbula se veía separada de la cabeza;
que ninguna pieza se despegue en ningún clip ni cámara (medido como los roces); mandíbulas con anatomía (piel o encía
continua que las una a la boca, grosor, curvatura, dientes en el borde; la de arriba más ancha, como una frente);
acercarse al cráneo esculpido de la lámina (frente, cejas óseas, cuernos que nacen de ellas, anillos de dientes en el
borde de la boca); repetir hoja, vídeo, fotos del combate (también medio y bajo con «movil») y pruebas.

**Causa de la mandíbula «flotante» (demostrada):** no estaba separada: su base estaba en la bisagra (medido: 0 m). Lo
que se veía era el HUECO alrededor del eje de la bisagra: por detrás lo tapaba el nudillo (±45°) y por delante la
placa, pero a los lados del eje no había nada, y desde tres cuartos se veía el fondo entre el collar y la mandíbula del
lado de allá. Además, al añadir la piel, la primera prueba era de una sola cara: desde dentro de la boca el descarte de
caras traseras la dejaba invisible (lo comprobé con un render sin descarte, que sí la enseñaba).

**Lo hecho (solo `fuente/crear_bramavidrio5.py` y los archivos v5):**
- **Piel continua de la boca, por las dos caras:** cada mandíbula lleva un **belfo** por fuera (de la cáscara, detrás
  del collar, envolviendo el canto, a la coraza de la mandíbula) y una **encía** por dentro (del rodete de la boca a la
  encía de la mandíbula), con los pesos repartidos entre la cabeza y la mandíbula; entre cada par de mandíbulas vecinas,
  una **mejilla** de carne (cosida a las dos y, en medio, sujeta también a la cabeza) y, detrás, una tira que la cose al
  collar. Abiertas, la carne se estira entre las mandíbulas como en la lámina; cerradas, se recoge.
- **Dientes en el borde de cada mandíbula** (una fila en la punta y otra más pequeña cerca de la bisagra, que van con la
  mandíbula): con las cuatro filas en espiral del embudo hacen los anillos de dientes de la boca. Se quitan los dientes
  fijos de los huecos (ahora hay mejillas ahí).
- **Mandíbula de arriba más ancha** (1,38 m de semiancho en la bisagra; las otras, 1,22 y 1,0), como una frente sobre la
  boca.
- **Cejas óseas:** dos arcos de hueso gruesos sobre la boca que suben hasta la base de los cuernos (los cuernos nacen
  de ellas); la testera y el marco de placas acaban ahora antes de la boca (si no, rozaban el belfo de arriba).
- **Medida nueva en el generador** (`bramavidrio5_clips.json`): `separacion_bisagra_m` (en los 10 clips, cada 0,1 s,
  los vértices de la bisagra de cada mandíbula frente a donde los lleva la cabeza) y `piel_boca_estiramiento` (cuánto se
  estira y se recoge cada tramo de la piel). Y la piel entra en la comprobación de roces (con colmillos, dientes, labios,
  cráneo y las mandíbulas a las que no va cosida).

**Medido (alto, todos los clips cada 0,1 s más los instantes del contrato):**
- **0 pares que se atraviesan** en los 10 clips (mandíbulas, colmillos, dientes, labios, cabeza y piel de la boca).
- **Separación de la bisagra: 0,0000 m** en las cuatro mandíbulas y los 10 clips. Es la comprobación de que el rig
  no las suelta; la ilusión de hueco era de la malla, y la cierra la piel.
- **Piel de la boca:** se estira como mucho ×1,95 y se recoge hasta ×0,29 (cerrada); no se rompe ni se da la vuelta.
- **Triángulos:** 17 789 / 7 967 / 3 443 (≤ 18 000 / 8 000 / 3 500). Para caber, el medio lleva 2 filas de dientes en el
  embudo y menos dientes de borde; el bajo, una fila de dientes de borde, sin filas en el embudo, sin cejas ni marco (de
  lejos no se distinguen).
- El encuadre y los movimientos no cambian (la parte E de `prueba_bramavidrio5`: aviso de la Fractura a 25 px del
  borde, descarga a 60 px).

**Pruebas (aisladas; partida, datos reales y proyecto sin cambios):**
- Con la v2 por defecto: **8 SUPERADAS** (`D:\REBELUM_diagnostico\pruebas\2026-11-12_215948\resumen.md`).
- Con la v5 elegida: 6 SUPERADAS y `prueba_cargas` FALLIDA por el mismo motivo de antes (la precarga incluye las
  normales del perfil; el coordinador lo arregla al integrar) (`…\2026-11-12_220211\resumen.md`).
- `prueba_bramavidrio5` con las dos medidas nuevas (bisagra y piel): SUPERADA (`…\2026-11-12_215228`).

**Evidencias (`D:\REBELUM_diagnostico\v12\expansion\bramavidrio5\vuelta2\`):**
- `comparar_v4_v5_referencia_cabeza.png`: la lámina, la v4, la v5 de la primera vuelta y la de ahora, **con las mismas
  cámaras** (frente, perfil y tres cuartos; abierta, media y cerrada).
- `blender\`: las etapas 1-5 y los vídeos de Blender; `v5_clips.mp4` (ffmpeg): la boca de cerca en el rugido y la
  embestida y los 8 clips en la vista del combate.
- `combate_v5_alto\`, `combate_v5_medio_movil\` y `combate_v5_bajo_movil\`: 33 fotos cada una del combate real que
  corre, `FALLOS: 0` en las tres (orden de dibujo y limpieza).

**Límites:** de cerca la carne de las mejillas es aún plana (bandas con las estrías de la textura de la carne), y la
lámina tiene más volumen y más dientes; en el combate se lee como boca unida con mandíbula de arriba bajo las cejas y
la de abajo con su fila de dientes. Nada en el Redmi; el rendimiento no lo he vuelto a medir (+~300 triángulos en el
alto; mismos materiales y dibujos que en la primera vuelta). **No es definitiva: decide el usuario.**