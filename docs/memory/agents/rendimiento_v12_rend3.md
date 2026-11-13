# Rendimiento y fallos V12 · «rend3», pasada final (13/11/2026)

Copia `D:\Aethelgard_v12_rend2`, rama local `claude/v12-rend3` desde `cefed0a` (claude/rebelum-v12 de entonces). Sin
push ni merge. Todo Godot con datos aislados. Medidas, capturas y registros en `D:\REBELUM_diagnostico\v12\expansion\rend3\`.

**Todo lo medido es del PC**, no del Redmi. Esta vez el PC estaba aún más cargado y además **la ventana de medida iba
con un tope de 40 FPS** (todas las escenas a 25,0 ms exactos por fotograma, también en el vacío; probablemente el tope de
FPS para aplicaciones en segundo plano del sistema o del driver: no he tocado ajustes globales). Con `--fixed-fps 30`, ese
tope alarga también los tiempos de carga que dependen de fotogramas (fundidos, esperas). Por eso **comparo lo que no
depende de eso**: dibujos, primitivas, capas, vértices, memoria, y el tiempo de GPU medido en el mismo proceso
(intercalado). Los tiempos de GPU absolutos de hoy variaron hasta ×2,2 de un rato a otro con el mismo contenido.

Leyenda: **[E]** medido ejecutando · **[C]** visto en el código · **[?]** sin comprobar.

## 1. Fallos: antes y después

| Fallo | Origen | Antes | Después |
|---|---|---|---|
| `menus.gd`: la fila de talleres (HBoxContainer) quedaba **huérfana** cada vez que se pintaba la pestaña Objetos sin ningún taller disponible | **juego** | 1 nodo huérfano por repintado (memoria que crece al usar el menú); al salir, «ObjectDB instances leaked» y «RIDs of type CanvasItem were leaked» en `prueba_foco`, `prueba_accesorios_v12`, `prueba_efectos` | se libera; **0 huérfanos** tras abrir y repintar todas las pestañas de menús, Diario, tienda, alquimia y gremio (`fuga_ui`); sin avisos de CanvasItem en las tres pruebas [E] |
| `prueba_audio` falla a veces «por tiempo» | **la prueba** | medía la SUMA de los 6 fotogramas de espera de una pulsación (con el PC cargado, 118 ms el 09/11 sin ningún parón; con el PC libre, 51-97 ms) | mide el **peor fotograma** de la pulsación: 70 ms; el umbral de 100 ms sigue [E] |
| `SurfaceTool.generate_lod()` obsoleto (`zonas3d/oakhaven/ciudad.gd`) | juego (aviso) | un aviso de obsoleto al juntar los edificios (solo la primera vez: luego se leen de la caché `user://cache_oakhaven`) | **sin cambiar**: lo recomendado (`ImporterMesh.generate_lods`) **no da la misma imagen** (§1.1) |
| «N ObjectDB instances were leaked at exit» / «N resources still in use at exit» en 71 y 62 pruebas | **las pruebas** (salir con sonido) | — | clasificado (§1.2); no se cambia el juego |
| `prueba_bosque_pastos.gd:63` (lambda sobre un nodo liberado) | la prueba | 14 errores | **no tocado** (lo arregla el coordinador en claude/rebelum-v12) |

Otros avisos de los registros, todos **provocados a propósito por las pruebas** (partidas dañadas o sin permiso de
escritura en `prueba_partida`/`prueba_guardado_protegido`, fuentes 2D sin padre en `prueba_efectos`): correctos.

### 1.1 `generate_lod` → `ImporterMesh.generate_lods`: probado y descartado [E]

`pruebas/herramientas/fotos_oakhaven_lod.gd` hace capturas deterministas (semilla fija, `--fixed-fps`, sin caché de
edificios, tiempo parado): dos pasadas con el mismo código dan **0 píxeles distintos** (fuera del contador de FPS). Con el
cambio a `ImporterMesh.generate_lods` (tomando el nivel con el número de triángulos más parecido al pedido) cambian
**24 000-79 000 píxeles por captura** en bajo y medio, y se ve peor: desaparecen las almenas de la puerta, el emblema
del cartel, los marcos de las ventanas y el entramado de las fachadas
(`...\rend3\capturas\oakhaven_medio_llegada_generate_lod_antiguo_vs_importermesh.png`: izquierda el de ahora, derecha el
recomendado). Los niveles que da `generate_lods` no tienen el tope de error (0,02) que usa `generate_lod`. **Se queda
como estaba**: el aviso solo sale la primera vez que se juntan los edificios en cada aparato y versión de la caché.
Si una versión futura de Godot quita el método, `ciudad.gd` ya cae a la malla sin simplificar.

### 1.2 Avisos de memoria al salir: de dónde vienen [E]

- **Sonido sonando al salir** (casi todos): `--verbose` en `prueba_cofre3d` y `prueba_turnos_v12` da solo
  `AudioStreamPlaybackWAV/MP3` y sus `AudioStreamWAV/MP3` (río, cascada, pradera, viento, golpes, música de combate).
  Reproducido sin ninguna prueba (`fuga_audio2`): con el ambiente de Pastos o una fuente 3D sonando y `quit()`, aparecen;
  **si el ambiente se calla antes de salir, no aparece ninguno**. Es la forma de salir de las pruebas (con `quit()` en
  mitad del sonido el servidor de audio no llega a soltar la reproducción), no una fuga durante la partida: en las
  medidas de 3 ciclos la memoria no crece de entrada en entrada. En Android la aplicación no sale así. Probé a callar las
  capas en `Musica._exit_tree()`: no basta (al salir ya no se procesa el audio), y lo quité.
- **Nodos de menús** (`prueba_foco`, `prueba_accesorios_v12`, `prueba_efectos`): era el fallo de `menus.gd` de §1.
- La memoria entre ciclos de combate: en el combate de tres crece 6 y 2 MB en el 2.º y 3.er ciclo (el 12/11, 3 y 2 MB)
  con +14 y +6 recursos: el combate al azar trae enemigos distintos en cada ciclo (se cargan sus sonidos y texturas). En
  Bramavidrio (siempre el mismo) no crece (159,4 → 159,7 → 159,8 MB).

## 2. Rendimiento de lo ENCENDIDO: las 8 escenas frente al 12/11 [E]

`medir_escenas.ps1` (medio, 3 ciclos), `...\rend3\medidas\escenas\` y `escenas2\`, frente a `21dd706`
(`D:\REBELUM_diagnostico\rendimiento\2026-11-12_despues\`):

| Escena (medio) | Dibujos 12/11 → hoy | Primitivas | Vídeo (MB) | Notas |
|---|---|---|---|---|
| Portada | 85 → 85 | — | 269 → 301 | hoy arranca la pantalla de inicio alternativa (`portada/inicio_alternativo.tscn`), no `carga.tscn` |
| Pastos Verdes | 116 → 115-116 | 328 k → 328-329 k | 85,6 → 85,6 | igual |
| Garganta | 191 → 191-209 | 363 k → 340-363 k | 86,1 → 86,1 | sin cambios de código; la diferencia es del recorrido |
| Oakhaven (sin NPC) | 87 → 87-90 | 257 k → 257-258 k | 97,2 → 97,2 | igual |
| Gran Bosque | 176 → 172-176 | 300 k → 300-302 k | 70,6 → 70,6 | igual |
| Mar de Cristal | 58 → 58-67 | 168 k → 168-171 k | 64,1 → 64,0-64,1 | igual |
| Combate de Bramavidrio | 88 → 88 | 67 k → 67 k | 110 → 120-122 | +10-12 MB |
| Combate de tres (Pastos) | 104 → 107-110 | 78 k → 63 k | 114 → 114-131 | la capa de Garon: +3 dibujos (§2.1) |

- **Sin regresiones de contenido**: con el recuento por sitio de `medir_gpu_bosque.gd` (mismas cámaras que el 12/11), Gran
  Bosque, Pastos, Garganta, Mar de Cristal y Oakhaven dan **las mismas llamadas, primitivas y capas** (±4 piezas por los
  pájaros o la fauna que entran o no en cámara).
- **Los tiempos de hoy no son comparables**: con el tope de 40 FPS de la ventana todas las escenas salen a 25,0 ms por
  fotograma, y las cargas que avanzan por fotogramas se alargan (la vuelta del combate de tres, 1,04 → 2,7-3,3 s; la de
  Bramavidrio, 0,75-0,82 → 2,5 s). No es el juego: el contenido es el mismo y la creación del grupo cuesta lo mismo que
  el 12/11 (Kael 1,6-9 ms, Lya 1,4 ms, Garon 3,5-8,6 ms con la carga común; `sonda_grupo.gd`). **Hay que repetir esta tabla
  con la ventana en primer plano y el PC libre**, o mirarla en el Redmi.
- **Tirones**: los mismos que el 12/11 en esta herramienta (que no hace la carga común): el primer diálogo al volver del
  combate (71-73 ms aquí; con la carga común, 11-16 ms desde rend2) y el reposo de Pastos (106 ms, fotograma 16: el
  primer diálogo de la misión). Ninguno nuevo.

### 2.1 La capa de Garon (encendida) [E]

En Pastos medio, los personajes pasan de 13 a 16 dibujos (la capa en la pasada base, en la del sol con sombra y en el mapa
de sombras) y ~850 vértices; crear a Garon con la carga común, 3,5 ms (el 12/11, 3,0-4,9 ms). Coste pequeño.

## 3. Lo APAGADO más costoso, para cuando se encienda [E]

`pruebas/herramientas/sonda_combate_coste.gd` (combate con un grupo fijo y los interruptores pedidos, 240 fotogramas
quietos, 2 pasadas) y `medir_gpu_bosque.gd` con `meta=` (`...\rend3\combate_coste\`, `...\rend3\apagados\`):

| Qué | Dibujos | Primitivas | SubViewport | GPU del PC (ventana + SubViewport) | Vídeo |
|---|---|---|---|---|---|
| Combate de tres contra 3 Slimes (2D) | 93 | 85 k | 3 (héroes) | 0,93-1,02 + 0,62-0,69 ms | 78-90 MB |
| … con la **línea de turnos** (`turnos_v12`) | **108 (+15)** | 86 k | 3 | 1,08-1,13 + 0,61-0,68 | 80 MB |
| … con **Nix** en vez de Garon (`nix_v12`) | 80-81 | 67 k | 3 | 0,76-0,80 + 0,47-0,52 | 68 MB |
| Contra 1 Grimfang (3D) | 83 | 101 k | 4 | 0,82-0,91 + 0,83 | 93 MB |
| Contra **2 Grimfang** | 91 (+8) | 116 k (+15 k) | **5 (+1 de 465×480)** | 0,84-0,85 + **0,97 (+0,14)** | 94-96 MB |
| Centinela + Slime (`enemigos_v12`) | 83-89 | 73-91 k | 4 (una de **960×975**) | 0,91-0,96 + 0,75-0,83 | 90-96 MB |
| Gólem + Slime (`enemigos_v12`) | 87-90 | 79-89 k | 4 (una de 750×682) | 0,93-0,94 + 0,78 | 89-91 MB |
| Oakhaven medio **con NPC** (`mundo_vivo_v12`) | +1-9 | **+33-54 k** | — | +0,03-0,22 ms | — |
| Ciclópea 3D medio (`ciclopea3d`) | 68-84 | 178-185 k | — | 1,78-1,92 ms (Pastos medio en la misma pasada: 2,82-3,45) | — |

- **Enemigos 3D iguales**: cada uno su SubViewport; el segundo Grimfang añade una ventana entera (+8 dibujos, +15 k
  primitivas, +0,14 ms de GPU en el PC, unos 0,22 Mpx más que limpiar y componer). El Centinela usa una ventana de casi
  1 Mpx (960×975). **Propuesta** (para el especialista del bestiario, que ya lo estudia; no he tocado peon_linde,
  velador_corteza ni sus módulos): compartir la ventana entre enemigos del mismo tipo o recortar la del Centinela a lo que
  ocupa en pantalla; en el Mali cada ventana es una pasada más con su limpieza y su lectura.
- **Línea de turnos**: +15 dibujos, +0,1 ms de la ventana principal en el PC. Su autor ya la dibuja por capas y solo la
  repinta cuando cambia el orden; los retratos leen la textura viva de cada personaje (texturas distintas: no se juntan).
  Poco que ganar sin cambiar cómo se ve.
- **Nix** es más barata que Garon (menos dibujos, primitivas y memoria).
- **NPC de Oakhaven**: cada NPC a la vista son ~22 000 vértices (+51 000 a +113 000 con 2-5 a la vista); dibujos casi
  igual (comparten material). En el Mali los vértices pesan (ver rend1, §1.3: 8 + 13-15 ciclos por vértice). **Propuesta**
  para su especialista: un nivel de detalle más ligero para los NPC a más de ~10 m, o menos subdivisión del modelo chibi.
- **Ciclópea 3D**: ligera (sin recortados ni transparencias, 1,2-1,5 capas); la sombra del sol en medio dobla los dibujos
  (84 → 38 sin ella) y cuesta 0,3-0,4 ms en el PC, como en las demás regiones.
- El bestiario v2 (Peón y Velador) no estaba en `cefed0a`: sin medir aquí.

## 4. Pruebas

- **Batería completa al empezar** (`cefed0a`, `...\rend3\pruebas\2026-11-13_033924`): **152 · 0 · 70 · 0**.
- **Batería completa al acabar**: `d8388a2` (`...end3\pruebas6-11-13_070519`): **152 · 0 · 70 · 0**, partida real y
  carpeta real de datos sin cambios («proyecto cambiado» = este informe, sin commit durante la pasada). Avisos: **ya
  ningún «RID of type CanvasItem was leaked»** (antes 3 pruebas); siguen los de sonido al salir (82 pruebas «ObjectDB
  leaked», 74 «resources still in use»: varía de una pasada a otra según qué suene al salir, §1.2), los 14 de la lambda de
  `prueba_bosque_pastos` (del coordinador), los 2 de `generate_lod` (§1.1) y los provocados por las pruebas de guardado.
- Sueltas tras el arreglo de `menus.gd` y `prueba_audio`: `prueba_audio`, `prueba_foco`, `prueba_accesorios_v12`,
  `prueba_efectos`: 4 · 0 · 0 · 0, ya sin avisos de CanvasItem.

## 5. Para el Redmi

1. Repetir la tabla de §2 con el teléfono: FPS de las 8 escenas en bajo y medio frente a la v665/v649 (no se puede fiar del
   PC de hoy por el tope de 40 FPS).
2. Oakhaven con `mundo_vivo_v12`: FPS en medio con 3-5 NPC a la vista.
3. Combate con 2-3 enemigos 3D iguales (Grimfang) y con el Centinela: FPS y memoria; comparar con uno solo.
4. La línea de turnos (`turnos_v12`) en un combate de tres: FPS.
5. Abrir el menú del mapa muchas veces seguidas (pestaña Objetos): que la memoria ya no suba.

## 6. Commits y archivos

- `93e2818`: fallos (`menus.gd`, `pruebas/prueba_audio.gd`).
- `d8388a2`: herramientas (`pruebas/herramientas/sonda_combate_coste.gd` y `fotos_oakhaven_lod.gd`, nuevas;
  `medir_gpu_bosque.gd` con `meta=` y Ciclópea).
- El de este informe.

NUEVOS: `aethelgard/pruebas/herramientas/sonda_combate_coste.gd`, `aethelgard/pruebas/herramientas/fotos_oakhaven_lod.gd`,
`docs/memory/agents/rendimiento_v12_rend3.md`.
COMPARTIDOS modificados: `aethelgard/menus.gd` (2 líneas), `aethelgard/pruebas/prueba_audio.gd`,
`aethelgard/pruebas/herramientas/medir_gpu_bosque.gd`.
**`recursos.gd` NO se ha tocado en esta pasada** (no choca con los APAGADOS del bestiario que añadió el coordinador).
Sin tocar: `zonas3d/oakhaven/ciudad.gd` (el cambio se probó y se deshizo), enemigos/peon_linde, velador_corteza.
