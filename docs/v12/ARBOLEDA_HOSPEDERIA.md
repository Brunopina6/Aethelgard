# Arboleda Mítica: «La escalera de la Hospedería» (V12, EXPERIMENTAL, solo desde el banco)

16/11/2026 · especialista de la Arboleda Mítica · rama `area-arboleda-hospederia` (desde `claude/rebelum-v12` @
`6ad4ad6`). Encargo: apartado 3 de `docs/v12/SUNKEN_ARBOLEDA_PLAN.md` (§3.9). Estudio de apoyo:
`D:\REBELUM_diagnostico\sunken_arboleda\estudio\arboleda.md`. Referencia de cuidado: la muestra de la calle de Oakhaven
(`docs/v12/MUESTRA_CALLE_OAKHAVEN.md`), con su método (medir antes, pasadas, antes y después en el mismo encuadre, luz
horneada, tres escalas de detalle) traducido a la técnica **2D pintada** de la isla, que no pasa a 3D.

**Estado: EXPERIMENTAL.** Solo en Auditoría o en el editor y solo desde el banco de pruebas: caso «Arboleda Mítica: la
escalera de la Hospedería (en pruebas)» y, para la actividad, antes el selector de sesión «Llevar una flor de abajo
(Arboleda)» → «Sí». Ninguna escena del juego la enlaza (ni el mapa, ni el mapamundi, ni `isla.tscn`), `isla.gd`,
`isla.tscn` y `res://isla/*` no cambian, no hay claves de partida nuevas y las APK 0, 1 y 2 no llevan la carpeta. Fuera
de Auditoría y del editor, la escena manda a `isla.tscn`. **Todo lo narrativo nuevo es PROPUESTA [P].**

Capturas, láminas, vídeo, medidas y renders: `D:\REBELUM_diagnostico\arboleda_hospederia\` (fuera del repositorio).
Marcas: **[C]** canon, **[P]** propuesta, **[D]** decisión del usuario. **Ninguna medida es del Redmi** (estaba
desconectado): todo lo móvil está PENDIENTE (§8).

## 0. Qué se ve y cómo se juega

- **La conexión**: de la plaza este (Lumi y, nueva, la abuela Nívea [P]) a la escalera de piedra de la derecha del
  cristal; en lo alto, un **paso** (la máscara `tramo/paso_extra.png`, 400 celdas a 1/4) une la escalera de piedra con
  el **pie de la escalera de madera** de la casa de la cúpula verde, que sube a la **puerta de la terraza** y a la
  **cornisa** de detrás del árbol. Antes la terraza era una parcela andable que no se alcanzaba (comprobado: 118 713
  celdas alcanzables; ahora 121 321, sin ninguna parcela nueva suelta).
- **El atrezo de la terraza**: un **farol de peregrino** en su poste al pie de la escalera de madera (marca la entrada),
  **macetas** con plantas de la isla junto a la puerta, un **cántaro** y un cesto de pan de higo, y en la cornisa un
  **banco** que se asoma a las nubes y el **lino tendido** que **ondea** (el paño ondea en su propio sprite; los postes,
  quietos). Cada pieza se tapa con lo que la isla tenga delante (la tapa de la isla) y no se atraviesa.
- **La Hospedería del Peregrino** [P] (interior): una sala de dormitorio de peregrinos con tres camas bajo las ventanas
  (colchas de lino con franja lima, oro y cian) y una cuarta contra el muro, arcones a los pies, alfombra, la mesa larga
  con bancos (pan de higo, cántaro, tazas y una jarrita de flores), el **mostrador de Yedra** [P] con el **libro de
  huéspedes casi vacío** (una sola firma), la campanilla y el farol, el estante de tarros y el **llavero con las llaves
  colgadas**, el **arranque de la escalera** a las camas de arriba, cortinas de lino recogidas, faroles de peregrino en
  los pies derechos, mantas dobladas, macetas, el perchero con la capa y el bordón, el felpudo y las **campanillas** de
  la entrada. **Luz de mañana** que entra por las tres ventanas y dibuja manchas cálidas en el suelo, oclusión en los
  rincones y rebote cálido de la madera (horneados en Cycles). Por las ventanas se ve el cielo y **pasan nubes**.
- **Dentro**: Yedra habla; **dormir** cuesta 20 monedas [D], cura al grupo y cuenta la escena de descanso del diseño en
  avisos encadenados (Yedra, Kael, Lya y Garon: solo los que van en el grupo); sin dinero, el sonido de error y un
  aviso. Los pasos suenan a **madera** dentro y a piedra fuera. **Al salir** se vuelve a la terraza. Guardar dentro (o
  pausar o cerrar la app) deja `pos_isla` en la puerta de la terraza: al cargar, se aparece fuera.
- **«Una flor para Lumi»** [P v2 n.º 1]: Lumi dice sus tres frases [C] de siempre y, tras «Mi abuela dice que abajo todo
  es gris», la petición [P] «¿Me traes una flor de abajo? Una de verdad, de las que huelen.». Nívea da el contexto [P]:
  «Le dije a Lumi que abajo todo es gris. Hace tanto que no bajo que ya no sé si es verdad.». Con la flor (interruptor
  de sesión del banco), hablar con Lumi: «Kael le da a Lumi la flor de abajo…» y **«Entonces abajo no es gris.»**; el
  **dibujo de Lumi** aparece clavado en la pared de la Hospedería («Mirar el dibujo»: un sol, una flor morada, dos
  figuras y la nube gris tachada) y Yedra lo comenta. El hito `isla_flor_lumi` se guarda **solo en la partida aislada
  del banco**. No se da la Cinta de Lumi [D].
- **Sondas 2D y sombra**: la luz del suelo (sacada de la pasada de color, muy suavizada: `tramo/luz_tramo.png` e
  `interior/luz.png`) tiñe a Kael al andar y a los vecinos en su sitio: más frío y oscuro bajo los aleros y los árboles,
  un poco más cálido al sol. A la mancha de contacto de `isla.gd` se suma una **sombra larga** hacia abajo a la derecha
  (el sol de la isla viene de arriba a la izquierda). El **cristal de la plaza late** despacio con un brillo aditivo
  pequeño, como el del portal.

## 1. Comprobaciones previas (§3.9, pasos 1 y 2)

| Qué | Resultado (comprobado ejecutando, 16/11, `6ad4ad6`, datos aislados) |
|---|---|
| Línea base de `isla.tscn` | Medida **antes de tocar nada** con `pruebas/medir_isla.gd` (§4). No existía ninguna. |
| La escalera pintada (≈ 2030-2250, 2050-2160) | **Ya era alcanzable**: es la escalera de piedra. Lo que no se alcanzaba es la **escalera de madera** de la casa de la cúpula verde y la cornisa (una sola parcela, x 2288-2744 e y 1920-2180). Las separa el pie del pilar de la escalera de madera, cerrado en `isla_paso` por `preparar_isla.gd` aunque `isla_suelo` tiene valor allí (rejilla en `analisis/`). |
| `suelo > 0` en el paso | En las filas 529-531 sí; en las demás celdas del paso, 0. Por eso `paso_extra.png` lleva en verde la **profundidad interpolada** por filas, y `_poner_z` la usa donde `isla_suelo` vale 0. |
| La puerta naranja (≈ 2330,2050) | Ese punto **no se pisa** (es el muro). Lo andable más alto de la escalera de madera, frente a la puerta, es (2396, 2056): ahí está el botón «Entrar en la Hospedería». |
| Coordenadas del diseño | La Hospedería del diseño estaba en (2000, 2150) («una casa del lado este de la plaza»); el plan la pone en la casa de la cúpula verde, que es la que tiene terraza y puerta: se sigue el plan (anotado en §6). |
| `render_isla.gd` con `.glb` | **Lo acepta** (carga cualquier escena y toma la primera `MeshInstance3D`): los modelos van en GLB de una sola malla. |
| Modelo de Meshy | Sigue sin estar: el exterior no se vuelve a renderizar; todo lo nuevo va encima, con su máscara y su tapa. |

## 2. Lo que se hizo, en el orden de §3.9

1. **Medida de la línea base** (`pruebas/medir_isla.gd`, §4).
2. **Máscaras**: análisis de `isla_paso`, `isla_suelo` e `isla_tapa` con capturas superpuestas y rejillas
   (`analisis/tramo_*.png`, `zoom_*.png`).
3. **`paso_extra` y la prueba BFS** (`fuente/crear_paso_extra.gd`, determinista). Primera versión de 171 celdas (filas
   531-539); la prueba de andar con teclas en diagonal ↗ se topaba con la esquina, así que se amplió a 400 celdas
   (filas 524-539, x 2216-2316). La prueba BFS lo comprueba.
4. **El interior**: `fuente/crear_hospederia.py` (Blender 5.2.3) modela la sala en coordenadas que entiende
   `render_isla.gd` (el suelo a −0,127, entre `SUELO_MIN` y `SUELO_MAX`), a 84 px por metro para que Kael (100-118 px)
   quepa con muebles de tamaño normal. **Horneado en Cycles** (OptiX, 160 muestras): el color de cada material y la luz
   (directa e indirecta) con techo y muro del frente **solo para el horneado**, para que la luz entre por las ventanas;
   se componen en una sola textura (color × luz normalizada) y se exporta UNA malla con UN material. Después,
   `render_isla.gd` (color, máscara y profundidad, 1536 px, 38°) le pone **la misma luz que a la isla** (el mismo
   «revelado») y `preparar_isla.gd` saca paso, suelo y tapa. `fuente/preparar_tramo.gd interior` pone opaco y oscuro lo
   de fuera de la sala, deja transparentes las ventanas, suaviza un poco (para no ser más nítido que el fondo de Meshy)
   y saca la luz del suelo y las anclas en píxeles.
5. **El atrezo de la terraza**: `fuente/crear_terraza.py` (cinco GLB de una malla) → `render_isla.gd` (solo color, al
   doble) → `preparar_tramo.gd pieza` (recorte, reducción Lanczos, dos suavizados y el color calmado). **Primera versión
   más nítida y saturada que el fondo** (lámina `igualar_piezas_v2_nitidas_arriba_final_abajo.png`): se apagaron los
   colores de origen y se añadieron el segundo suavizado y la calma del color; se recolocaron el banco y el lino en la
   cornisa (en la primera, el banco quedaba encima de la barandilla).
6. **Sondas 2D y sombra**: `preparar_tramo.gd luz` (exterior, 768 × 837) e `interior/luz.png` (384 × 198); el tinte se
   suavizó a la mitad tras verlo en el interior (Kael se veía gris junto a la puerta).
7. **Lumi y Nívea**: `lumi_flor.gd`. Figuras nuevas de Yedra y Nívea (§5, riesgo de estilo).
8. **Integración y medida de antes y después** (§3 y §4), pruebas (§7).

## 3. Antes / después (mismo encuadre)

Láminas en `laminas/` (1280 × 720 por imagen, arriba el antes —`isla.tscn`— y abajo el después —el tramo—, con Kael en
el mismo punto y la misma cámara; las tomó `medir_isla.gd`):

| Lámina | Qué cambia |
|---|---|
| `comparar_portal_antes_arriba_despues_abajo.png` | Nada a la vista (la sombra larga de Kael). |
| `comparar_plaza_antes_arriba_despues_abajo.png` | La abuela Nívea junto a Lumi; el brillo del cristal; la sombra larga. |
| `comparar_escalera_antes_arriba_despues_abajo.png` | El farol de peregrino al pie de la escalera de madera; el tinte de Kael. |
| `comparar_terraza_antes_arriba_despues_abajo.png` | Farol, macetas, cántaro y, en la cornisa, el banco y el lino tendido; «Entrar en la Hospedería». |
| `igualar_piezas_v2_nitidas_arriba_final_abajo.png` | La primera versión del atrezo (más nítida y saturada que el fondo) frente a la igualada. |
| `interior_hospederia.png` e `interior_render_completo_1536x795.png` | El interior en el juego y el render entero. |

**Vídeo**: `video/tramo_hospederia.avi` (Movie Maker de Godot, MJPEG, 1280 × 720, 30 FPS, 776 fotogramas = 25,9 s): Kael lleva la flor a
Lumi, sube la escalera de piedra, cruza el paso, sube la escalera de madera, entra, mira el dibujo y duerme. (No hay
`ffmpeg` en el PC para pasarlo a MP4.)

## 4. Medidas en el PC (VERIFICADO; NO certifica el Redmi)

PC: RTX 3050 Laptop + Ryzen 7 4800H, Compatibility (OpenGL 3.3), ventana **1600 × 720** (la pantalla del Redmi; el juego
dibuja a 1280 × 720 con franjas). `pruebas/medir_isla.gd`; textos en `medidas/medida_{isla_antes,isla_antes2,tramo_despues}.txt`.
La 2D **no depende del perfil gráfico** (se anotó «bajo»). Medianas de 4 s, Kael quieto; «sin límite» = sin límite de
FPS ni sincronía vertical. Antes: dos pasadas (la primera, antes de tocar nada; la segunda, justo después del después,
en las mismas condiciones).

| Sitio | ANTES `isla.tscn` (1.ª / 2.ª) GPU · CPU · llamadas · ms sin límite | DESPUÉS tramo GPU · CPU · llamadas · ms sin límite |
|---|---|---|
| portal | 0,69 / 0,67 · 0,74 / 0,72 · 25 · 2,1 | 0,68 · 0,72 · 26 · 2,1 |
| plaza | 0,59 / 0,64 · 0,64 / 0,69 · 29 · 1,9-2,0 | 0,67 · 0,73 · 34 · 2,0 |
| escalera | 0,96 / 0,70 · 1,01 / 0,75 · 24 · 2,2-2,8 | 0,68 · 0,74 · 32 · 2,1 |
| terraza | 0,56 / 0,64 · 0,58 / 0,66 · 18 · 1,8-2,1 | **0,78** · 0,84 · 28 · 2,5 |
| interior | — | **0,60** · 0,63 · 22 · 1,9 |

| | ANTES | DESPUÉS |
|---|---|---|
| Con el límite normal (30 FPS) | mediana 33,3 · p95 33,4 ms en todos los sitios | igual (máx. suelto 35-39 ms en portal y terraza, uno por pasada) |
| Carga hasta el control (1.ª entrada del proceso) | 609 / 559 ms | **757 ms** (+150-200 ms: interior, piezas, figuras y máscaras) |
| Memoria tras entrar | vídeo 40,0 MB · texturas 29,8 MB · estática 99,6 MB | vídeo 45,8 · texturas **35,6** (+5,8 MB) · estática 105,4 |

- **Presupuesto §3.7**: la terraza, el sitio más cargado, sube **+0,14 ms de GPU** sobre la pasada «antes2» (límite:
  +1 ms) ✔. El interior cuesta **menos que cualquier sitio de fuera** (0,60 ms; la isla se oculta) ✔. Texturas nuevas
  medidas: **+5,8 MB** (≤ ≈ 8 MB) ✔; el fondo del interior va en VRAM comprimida con mipmaps y las máscaras sin pérdida.
  Ninguna capa transparente nueva a pantalla completa: el lino ondea en su sprite (189 × 130), el brillo del cristal
  es un sprite de 128 px escalado, las nubes de las ventanas son 6 partículas tras el fondo opaco ✔.
- Las llamadas suben 5-10 por sitio (cada pieza, figura y sombra es su propio dibujo con su material). En el Mali se
  mide en el Redmi (§8): si hiciera falta, las cinco piezas caben en un atlas con un solo material.
- `malioc`: no aplica (sombreados de lienzo nuevos muy pequeños: `SHADER_PIEZA`, con una lectura de tapa y un
  descarte, en sprites pequeños).

## 5. Figuras nuevas (riesgo de estilo)

Yedra y Nívea [P] salen de los chibis v12 (`campesina` y `anciana`, sin tocar sus GLB) con atlas nuevos: en
`fuente/crear_npc_chibi.py` solo se **añadieron** las personas «yedra» y «nivea» (sus atlas se generaron fuera del
proyecto, en `figuras/salida/`, y no se copia ningún atlas a `personajes/npc_v12/`). `fuente/render_figura.gd` las
renderiza a 38° con la luz de la isla y las reduce a 114 y 104 px. Nívea usa un fotograma del clip «hablar» (en el de
reposo, encorvada, la cámara alta le tapaba la cara con el pelo). **Riesgo**: al lado de los cuatro sprites antiguos
(dibujos de estilo anime a 240 px), las dos nuevas se ven 3D y de otra mano (lámina de la plaza). Es [D]: o se quedan
así, o se dibujan como los antiguos, o se renderizan todos los vecinos de la isla desde chibis.

## 6. Decisiones del usuario [D]

1. **Precio de la Hospedería: 20 monedas** (constante propia `hospederia.gd PRECIO`, sin tocar `zona.gd`). 
2. **Qué flor recibe Lumi**: el texto dice «una flor de abajo», sin nombrarla (la lavanda de los Pastos ya la lleva
   Rosa en `oak_lavanda`): ¿una segunda lavanda, la flor de Rosa u otra?
3. **La Cinta de Lumi**: no se da; `hallazgos.gd` la sigue teniendo en `FUERA` (lo comprueba la prueba).
4. **Yedra y Nívea** [P] (nombres, frases y aspecto: §5) y las frases nuevas [P] (Nívea «Le dije a Lumi…», Lumi «Le he
   hecho un dibujo a Yedra…», Yedra «Lumi me ha traído su dibujo…», «Kael le da a Lumi la flor de abajo…»).
5. **Los NPC pasan a Dialogic o no**: hoy hablan con el rótulo de aviso, como en la isla; la escena de descanso, en
   avisos encadenados. Pasarlos es un cambio aparte.
6. **El grupo del caso del banco**: el plan decía solo Kael (como la muestra de la calle); se puso **Kael, Lya y Garon**
   para que la escena de descanso del diseño salga entera (en la isla 2D solo se ve a Kael igualmente).
7. **Dónde está la Hospedería**: el diseño la ponía en (2000, 2150), «una casa del lado este de la plaza»; el plan y
   este tramo la ponen en la casa de la cúpula verde, la de la terraza.
8. **La nota del Diario** del dibujo (el diseño dice «un dibujo de Lumi (nota en el Diario)»): no se hizo, porque tocaría
   `progreso.gd` y el Diario, fuera de la lista de §3.6. Hoy el premio es el dibujo en la pared, que cambia de estado.

## 7. Pruebas

- **`pruebas/prueba_arboleda_tramo.gd`** (ventana, registrada en `lista_pruebas.txt`): **0 fallos** (16/11, 03:55,
  `ejecutar_pruebas.ps1 -Manual`, datos aislados). Comprueba: A, nadie más la enlaza (mapa, mapamundi, isla, zona,
  progreso, hallazgos; fuera de su carpeta solo `banco_pruebas.gd`, `recursos.gd` y `musica.gd`), APK 0, 1 y 2 sin ella,
  `isla_paso.png` intacta (MD5), sin precarga y música «viento»; B, la máscara combinada (puerta, cornisa y las cinco
  piezas alcanzables desde la llegada, 0 celdas sueltas); C, andar tocando hasta la puerta (llega en línea recta) y con
  ↗ (cruza el paso y sube hasta el muro de la casa sin atascarse); D, Kael tapado detrás de las cinco piezas y de un
  mueble del interior (píxeles: con y sin Kael, con y sin la pieza); E, Lumi sin flor (frase [C] y luego la petición),
  Nívea, y con la flor «Entonces abajo no es gris.», el hito en la partida del banco **y en su archivo** y el dibujo en la
  pared; la Cinta sigue fuera; F, entrar (la isla oculta, los límites de la cámara), Yedra, dormir (−20 y cura), sin
  dinero (aviso, no cobra), guardar dentro (`pos_isla` = la puerta de la terraza; al volver a cargar, fuera), salir,
  bajar por el portal, llegar al mapa (los recursos del tramo se sueltan) y salir del banco (su archivo se borra);
  G, 18 frases ≤ 110 sin vetos de D-033 ni D-073 y sin «niebla».
- **Siguen pasando** (misma pasada): `prueba_isla` y `prueba_tapa` (MANUAL, sin errores; en la captura de `prueba_tapa`, Kael queda tapado por un pilar, como
  debe; `isla.gd` no cambia),
  `prueba_musica`, `prueba_guardado`, `prueba_partida`, `prueba_guardado_protegido`, `prueba_hallazgos`,
  `prueba_ciudad_datos`, `prueba_banco_pruebas` (ahora cuenta 13 casos y 11 selectores) y `prueba_banco_pruebas_3d`:
  **8 SUPERADAS, 0 FALLIDAS, 3 MANUALES**; partida real, carpeta real de datos y proyecto sin cambios.
  Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-16_035434\resumen.md`.
- **`pruebas/medir_isla.gd`** (manual): la medida de §4.
- **Con controles normales, a mano**: PENDIENTE (teclado, mando, ratón y toque en el PC; cruceta en el Redmi). Las
  pruebas simulan el toque (destino) y las teclas (`Input.action_press`), no las sustituyen.

## 8. Redmi (PENDIENTE: estaba desconectado)

Nada de lo móvil está medido. Guion para cuando esté (la APK de **Auditoría** se copia por USB a Download, D-065, y la
instala el usuario):

1. Abrir el banco de pruebas → selector «Llevar una flor de abajo (Arboleda)» en «No» → caso «Arboleda Mítica: la
   escalera de la Hospedería (en pruebas)». Mirar el contador de FPS de arriba: **≥ 30 sostenidos** en la llegada.
2. Con la cruceta: a la plaza (hablar con Lumi y con Nívea), subir la escalera de piedra **en diagonal** (que resbale y
   no se atasque), cruzar el paso, subir la escalera de madera y seguir a la cornisa. Anotar FPS en plaza, escalera y
   terraza, y si algo tira (las llamadas suben 5-10 por sitio).
3. Ver que Kael pasa **por detrás** del farol, las macetas, el cántaro, el banco y el lino, y que el lino ondea.
4. «Entrar en la Hospedería»: FPS dentro (debe ser **igual o mejor** que fuera), hablar con Yedra, «Mirar el dibujo» (no
   debe estar), dormir (−20 y la escena), salir.
5. **Pausar la app dentro** de la Hospedería (botón de inicio) y volver: debe seguir dentro y, si se cierra y se vuelve a
   abrir desde el banco, aparecer en la terraza.
6. Volver al banco → «Llevar una flor de abajo» en «Sí» → entrar → dar la flor a Lumi → entrar en la Hospedería: el
   dibujo está en la pared.
7. Bajar por el portal al mapa y «Volver al banco». Para la memoria: `adb shell dumpsys meminfo` del paquete (PSS) en
   la terraza y dentro (lo hace el usuario o se autoriza; referencia de la región: ≤ 880 MB).
8. Mirar en la pantalla de verdad si las piezas y las figuras nuevas **se distinguen del fondo de Meshy** (más nítidas,
   más saturadas o de otro estilo) y las bandas del ETC2 en el fondo del interior.

## 9. Provisional (no es final)

- **El atrezo** (lino, banco, farol, macetas, cántaro): modelos sencillos de colores planos; vistos desde 38° el banco
  se lee poco. Igualado al fondo (suavizado y color), pero sigue siendo más limpio que el render de Meshy.
- **El interior** es más limpio y menos saturado que la isla (otra «mano», aunque con la misma luz). Es una sala aparte,
  así que choca menos que una pieza sobre el fondo; la sombra del muro izquierdo cae en diagonal sobre la escalera.
- **Yedra y Nívea** (§5).
- **El paso** cruza el pie del pilar de la escalera de madera: Kael lo pisa (se ve como si rodeara el pilar).
- **Sonido**: no hay efecto de campanillas en `sonido.gd`; las de la entrada están solo en la imagen. El viento es la
  música de la isla.
- **El brillo del cristal** es sutil a propósito; no reacciona a nada.
- **Las anclas del interior** (puerta, mostrador, cama, dibujo) son puntos fijos del modelo: si se rehace, se rehacen
  con `preparar_tramo.gd interior`.

## 10. Archivos

**Nuevos** en `aethelgard/zonas3d/arboleda_tramo/`: `arboleda_tramo.tscn`, `arboleda_tramo.gd`, `hospederia.gd`,
`lumi_flor.gd`; `fuente/crear_paso_extra.gd`, `fuente/crear_hospederia.py`, `fuente/crear_terraza.py`,
`fuente/preparar_tramo.gd`, `fuente/render_figura.gd`; `fuente/modelos/` (`hospederia.glb` con su textura horneada,
`terraza_*.glb`, `hospederia_anclas.json`, `terraza_piezas.json`); `tramo/paso_extra.png`, `tramo/luz_tramo.png`;
`interior/{color,paso,suelo,tapa,luz}.png` y `interior/anclas.json`; `piezas/{lino,banco,farol,macetas,cantaro,yedra,
nivea,dibujo_lumi}.png`. Pruebas: `pruebas/prueba_arboleda_tramo.gd`, `pruebas/medir_isla.gd`. Este documento.

**Cambios fuera de la carpeta** (todos los de §3.6 y ninguno más; mínimos, en líneas propias):
1. `banco_pruebas.gd`: `EXPLORAR["arboleda"]`, el selector «Llevar una flor de abajo (Arboleda)» y `"arboleda_flor"`
   en `METAS_SESION`.
2. `recursos.gd`: `"res://zonas3d/arboleda_tramo/"` en `EXCLUIR` (como `res://isla/`).
3. `musica.gd`: la escena del tramo junto a `isla.tscn` en «viento».
4. `export_presets.cfg`: `zonas3d/arboleda_tramo/*` en los presets 1 y 2.
5. `pruebas/lista_pruebas.txt`: `prueba_arboleda_tramo` y `medir_isla`; corregida la descripción de `prueba_tapa`.
6. `fuente/crear_npc_chibi.py`: solo se añaden las personas «yedra» (campesina) y «nivea» (anciana).
7. `pruebas/prueba_banco_pruebas.gd` (compartido): los recuentos (13 casos, 11 selectores). **Ojo al integrar**: el
   barrio de Oakhaven u otro área pueden añadir casos o selectores a la vez; los números se suman.

**Procedencia**: todo lo nuevo es obra propia hecha aquí (Blender 5.2.3 y Godot 4.7.2 por guion; texturas y dibujo
pintados por código; los chibis v12 son del proyecto). Nada descargado, de pago ni en la nube; sin Meshy, sin Hunyuan3D,
sin complementos ni GDExtension. El fondo de la isla sigue siendo el render de Meshy (sin licencia para una APK
entregable, `inventario_licencias.md:64`): el tramo, como la isla, solo va en Auditoría.

**Cómo regenerarlo** (en este orden; los de Blender, con el turno de `D:\REBELUM_coordinacion\horneado.lock`):
`crear_paso_extra.gd` → `preparar_tramo.gd luz` → `crear_hospederia.py -- fuente/modelos` → `render_isla.gd` (color,
mascara, profundidad; 1536, 1 × 1, 38) → `preparar_isla.gd` → `preparar_tramo.gd interior <render> <prep> <anclas>`;
`crear_terraza.py -- fuente/modelos` → `render_isla.gd` (color, al doble del `ancho_px` de `terraza_piezas.json`) →
`preparar_tramo.gd pieza <render> res://…/piezas/<pieza>.png 0.5`; `crear_npc_chibi.py -- <raíz> <láminas>
campesina,anciana <carpeta fuera>` → `render_figura.gd campesina <yedra.png> …/yedra.png 114` y `anciana <nivea.png>
…/nivea.png 104 hablar 1.0`; `preparar_tramo.gd dibujo`.
