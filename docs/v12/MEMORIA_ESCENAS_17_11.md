# Memoria del banco entre escenas (17/11, medida en el PC)

Pendiente (2) del RELEVO del 16/11, 14:40: en el Redmi, el PSS del **banco** subía de un caso al siguiente
(888 → 913 → 916 → 935 → 951 MB tras ciudad ×4, barrio, muestra, Arboleda y Sunken con la Quilla), mientras que
repetir la misma escena no crecía (900-902 MB). Aquí se reproduce ese orden en el PC y se busca qué se queda.

**Resultado en una línea:** NO hay fuga. Es memoria que se llena **una sola vez** por escena distinta y después se queda
plana: en el 2.º y el 3.er ciclo completo el banco no sube nada (0,1 MB de ruido). Lo que se queda es, sobre todo, del
motor (búferes 3D de la ventana, sombreadores y scripts ya compilados) y la caché del barrio, que existe a propósito para
que volver a entrar no dé tirón. **No se ha cambiado el juego.** El Redmi está **SIN MEDIR** con esta herramienta.

## Cómo se ha medido
- Herramienta: `aethelgard/pruebas/medir_memoria_escenas.gd` (medida, no prueba; no va en `lista_pruebas.txt`).
- PC con ventana (1600×720; dibujo 1280×720 con franjas), Compatibility (OpenGL 3.3, RTX 3050 Laptop), perfil **bajo FIJO**
  (`calidad_proto`, el regulador no cambia nada a mitad). APPDATA aislado: ni la partida ni los ajustes reales.
- Como una persona: pantalla de carga (portada alternativa, con su precalentado de muestra y barrio), botón «Banco de
  pruebas», **clic** en cada caso de EXPLORAR, 5 s dentro, **clic** en «Volver al banco», 2 s y medida.
  Sunken con «Quilla horneada = Sí» (la meta `sunken_quilla_v12`, como el selector del banco).
- Tras cada vuelta: `Performance` MEMORY_STATIC, RENDER_VIDEO_MEM_USED, RENDER_TEXTURE_MEM_USED, RENDER_BUFFER_MEM_USED,
  OBJECT_COUNT, OBJECT_RESOURCE_COUNT, OBJECT_NODE_COUNT, OBJECT_ORPHAN_NODE_COUNT; los archivos de `res://` que siguen en
  la caché de ResourceLoader (`has_cached` sobre los 2 952 archivos) y lo que entra o sale; los grupos de `Recursos`; el
  tamaño de las cachés estáticas (muestra_calle, barrio, interiores, utensilios, npc_chibi, kit_ciudad, blockout, ciudad,
  plano...) y las texturas a las que llegan.
- Registros y CSV (fuera del repositorio): `D:\REBELUM_diagnostico\pendientes_17_11\memoria_escenas\`
  (`antes\` orden del Redmi ×3, `orden_inverso\` ×2, `atribucion*\` con el experimento, `comprobacion_final\` solo la
  muestra + experimento).
- Orden de uso: `Godot --path aethelgard --resolution 1600x720 --script res://pruebas/medir_memoria_escenas.gd --
  salida=<carpeta> ciclos=3 salir_banco` (y `experimento` para la atribución); ver la cabecera del script.
- `Performance` no es el PSS de Android: en el teléfono el PSS lleva además la memoria del controlador (programas de
  sombreado compilados, texturas en formato del Mali). Las cifras sirven para ver la FORMA, no para predecir MB del Redmi.

## Cifras: el banco tras cada vuelta (orden del Redmi, 3 ciclos)
MB; «vídeo» = RENDER_VIDEO_MEM_USED (texturas + búferes). Huérfanos: 0 en todas las medidas. Nodos del banco: 245-246.

| Ciclo | Banco tras | Estática | Vídeo | Texturas | Objetos | Recursos | Caché res:// |
|---|---|---|---|---|---|---|---|
| 0 | (inicio) | 219,9 | 322,1 | 275,4 | 9 801 | 7 433 | 1 330 |
| 1 | ciudad | 225,9 | 327,6 | 280,9 | 9 838 | 7 449 | 1 346 |
| 1 | barrio | 226,5 | 331,7 | 284,9 | 9 908 | 7 468 | 1 355 |
| 1 | muestra | 226,5 | 331,7 | 284,9 | 9 925 | 7 468 | 1 355 |
| 1 | Arboleda | 229,1 | 334,0 | 287,2 | 9 947 | 7 472 | 1 359 |
| 1 | Sunken + Quilla | 233,1 | 337,9 | 291,1 | 9 968 | 7 475 | 1 362 |
| 2 | ciudad … Sunken (los 5) | 233,1-233,2 | 337,9 | 291,1 | 9 968 | 7 475 | 1 362 |
| 3 | ciudad … Sunken (los 5) | 233,2 | 337,9 | 291,1 | 9 968 | 7 475 | 1 362 |
| 3 | tras «Salir del banco» (portada) | 232,0 | 339,6 | 292,6 | 9 844 | 7 478 | 1 356 |

- **Ciclo 1: sube** con cada escena distinta (+15,7 MB de texturas, +13,2 MB de estática, +167 objetos, +42 recursos), con
  la misma forma que el Redmi: la muestra no suma nada (en el Redmi +3), barrio, Arboleda y Sunken sí.
- **Ciclos 2 y 3: plano.** Ni un objeto ni un recurso más; ningún archivo nuevo en la caché. Es una caché que se llena una
  vez, no una fuga por ciclo (igual que la ciudad repetida en el Redmi: 900-902).
- Dentro de cada escena (ciclo 1 → ciclo 2, vídeo): ciudad 329,6 → 339,8; barrio 343,9 → 350,1; muestra 331,7 → 337,9;
  Arboleda 357,4 → 361,2; Sunken 346,2 → 346,2 (en el ciclo 1 ya era la última). Lo que el banco gana se nota también
  dentro: el pico de cada escena es el del ciclo 2 (con todo ya visitado). En el Redmi, Sunken con la Quilla al final dio
  979 MB: ese es el «peor caso» real, el de haber visitado todo antes.

## El orden no cambia el total (orden inverso, 2 ciclos)
Sunken → Arboleda → muestra → barrio → ciudad: el banco sube +7,8 MB de texturas tras Sunken (la primera escena 3D, con
lo que el motor prepara una vez), +2,3 Arboleda, +0,4 muestra, +4,0 barrio, +1,2 ciudad, y acaba en **lo mismo**:
291,1 texturas · 337,9 vídeo · 233,0 estática · 9 966 objetos · 7 475 recursos. El ciclo 2, plano otra vez.
La primera escena 3D que se visita carga con ≈ 4-5 MB que no son suyos (la ciudad en el orden del Redmi, Sunken aquí).

## Qué se queda y quién lo suelta (experimento en el banco, tras el ciclo)
Partiendo del banco «lleno» (291,1 texturas · 337,9 vídeo · 233,0 estática · 9 967 objetos · 7 475 recursos) se suelta
cada cosa por separado (solo en la herramienta; el juego no lo hace):

| Se suelta | Texturas | Vídeo | Estática | Objetos | Recursos |
|---|---|---|---|---|---|
| Cachés del barrio (`barrio.gd`, `interiores.gd`, `barrio_vivo.gd` → utensilios y los NPC del barrio en npc_chibi) | **−10,1** | −10,7 | −1,4 | −139 | −79 |
| Caché de la muestra (`muestra_calle.soltar_caches`) | 0 | 0 | −0,3 | −17 | 0 |
| El resto de npc_chibi (los oficios de la cuadrilla de la Quilla, Ulla y Brea) | 0 | 0 | 0 | −2 | 0 |
| Cachés de la ciudad (kit_ciudad, blockout, `_puertas`, `_zonas`) | 0 | 0 | 0 | 0 | 0 |
| Búferes 3D de la ventana (escala 3D ±0,01: se rehacen) | **−3,9** | −4,0 | 0 | 0 | 0 |
| `root.disable_3d = true`; cambiar 8 px el tamaño de la ventana | 0 | 0 | 0 | 0 | 0 |
| **Queda** respecto al banco de inicio | +1,7 | +1,1 | **+11,5** | — | — |

- **Barrio** (≈ 4 MB de texturas propias en el PC: los 6 mapas de luz de 1024 de los tramos, las sondas y el atlas de los
  utensilios, + materiales). Es la caché «entre entradas» de propósito (como la de la muestra): se suelta en
  `banco_pruebas.salir()` y NO al volver al banco, para que volver a entrar no repita el coste de los materiales.
  **≈ 6 MB de los −10,1 no son de la visita**: los deja el **precalentado de la carga** (solo Auditoría/editor) antes de
  entrar en el banco. Comprobado entrando SOLO en la muestra y soltando después las cachés del barrio: −6,0 MB de
  texturas, −60 recursos y 9 archivos menos en la caché (los modelos y atlas de los vecinos del barrio en npc_chibi).
  Están en el banco desde el principio (no forman parte de la subida 888 → 951) y son los que mantienen vivo lo que el
  precalentado compila.
- **Sin dueño visible (≈ 7 MB de texturas)**: tras soltarlo todo, el banco sigue ≈ 7 MB por encima de lo que había menos
  lo del precalentado. Llega con la ciudad (si no es la primera escena), la Arboleda y Sunken, no está en la caché de
  ResourceLoader ni en ninguna caché estática, y no baja ni rehaciendo los búferes de la ventana. Es del motor (o del
  controlador), sin identificar: desde GDScript no se pueden listar las texturas vivas de la GPU
  (`RenderingServer.texture_debug_usage` no está expuesto). Tampoco crece en el 2.º ciclo.
- **Muestra**: sus materiales retienen texturas que ya están en el grupo «comun» de `Recursos` (precargadas al abrir):
  soltarla no baja nada en la GPU.
- **Ciudad (maqueta)**: deja 16 scripts y 2 sombreadores del blockout en la caché y `_puertas`/`_zonas` (datos); 0 MB de GPU.
  `kit_ciudad` ni se carga en esta versión.
- **Quilla**: la cuadrilla suelta sus personas al irse (`obreros.gd`, `_exit_tree`); quedan 3 oficios en `npc_chibi._escenas`
  cuyos GLB están en «comun» (0 MB).
- **Búferes 3D de la ventana** (≈ 4 MB): son de la VENTANA, no de la escena; los deja la primera escena 3D que los pide y
  los usa la siguiente. No se sueltan al pasar al banco (2D). Cualquier escena 3D los vuelve a crear al entrar.
- **Estática que queda (+11,5 MB)**: no la suelta nada del juego. Son los scripts de cada región ya compilados (ciudad 16,
  Arboleda 4, Quilla 3...) y lo que el motor guarda de cada variante de sombreador compilada y de cada escena (por eso
  no vuelve a subir en el ciclo 2). Ni objetos huérfanos ni nodos de más (huérfanos 0; nodos del banco 245-246).
- La salida del banco tampoco vuelve a las cifras de la carga (339,6 MB de vídeo frente a 320,2): la portada vuelve a
  precalentar la muestra y el barrio, y lo del motor sigue.

## Causa
1. Llenado único por escena distinta: los sombreadores y scripts que cada región compila la primera vez (en el Mali, los
   programas compilados viven en la memoria del controlador: es lo más probable para los +16-25 MB por escena del Redmi,
   **sin comprobar**), la caché del barrio (≈ 4 MB en el PC), los búferes 3D de la ventana (≈ 4 MB) y ≈ 7 MB de texturas
   del motor sin dueño visible.
2. No hay crecimiento por ciclo: ni objetos, ni recursos, ni archivos en caché, ni texturas.
3. `banco_pruebas.salir()` suelta lo que debe soltar del juego (muestra, barrio, interiores, utensilios y los NPC del
   barrio); al volver al banco se sueltan, como está pensado, el grupo «zona» de `Recursos` (la isla y el tramo de la
   Arboleda: 22 recursos) y todo lo que solo usaba la escena. Nada del juego se queda sin dueño.

## Arreglo: ninguno aplicado (y por qué)
No hay fuga ni una caché que se quede «sin querer» con memoria apreciable. Lo único de la app que se queda (la caché del
barrio) está ahí para no repetir el tirón de entrada; quitarla iría contra la regla del encargo. Propuestas, por si se
quiere bajar el banco o el pico:

- **P1 (decisión del usuario; no aplicada):** soltar las cachés del barrio al entrar en OTRO caso del banco. En el PC,
  ≈ −4 MB de GPU y −1,4 MB de estática en las demás escenas; a cambio, la siguiente entrada al barrio vuelve a pagar sus
  materiales (el tirón que la caché evita). Repetir el barrio seguido no cambiaría.
- **P2 (no aplicada):** rehacer los búferes 3D de la ventana al volver al banco (tocar la escala 3D un fotograma):
  −3,9 MB en el banco del PC, pero vuelven al entrar en cualquier escena 3D: no baja el pico dentro de Sunken, que es el
  que pasa de 950. Y la escala 3D es del regulador de calidad: no conviene tocarla por un efecto secundario.
- **P3 (higiene, sin efecto hoy):** `banco_pruebas.salir()` no llama a `kit_ciudad.soltar_caches()` (materiales con texturas;
  la maqueta aún no usa el kit). Si un día la ciudad lo usa, añadirlo ahí, como los del barrio.
- **P4 (presupuesto):** el tope de 950 MB del plan conviene juzgarlo con todo visitado (2.º ciclo), no con la escena sola:
  Sunken con la Quilla al final dio 979 MB en el Redmi.

## Para el Redmi (SIN MEDIR con esta herramienta ni después de nada)
No ha cambiado el juego, así que no hay «después» que medir. Lo que confirmaría la explicación en el teléfono:
1. Dos ciclos seguidos del mismo orden (ciudad, barrio, muestra, Arboleda, Sunken con la Quilla, volviendo al banco):
   si es como en el PC, el 2.º ciclo deja el banco en ≈ 951 MB sin subir.
2. `dumpsys meminfo` completo (no solo TOTAL PSS) en el banco tras el 1.er y el 2.º ciclo: «Graphics / GL mtrack» frente a
   «Native Heap» separa lo del controlador (sombreadores, texturas, búferes) de lo de Godot.
3. Sunken con la Quilla DENTRO en el 2.º ciclo: es el pico real (979 MB el 16/11).
