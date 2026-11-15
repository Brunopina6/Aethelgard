# Sunken City 3D (V12) — sector «Popa Rota → Cubierta Mayor»

15/11/2026 · agente de nueva ubicación 3D · rama `claude/v12-sunken3d` (desde `claude/rebelum-v12` @ `178c9cd`).
**Estado: EN PRUEBAS y APAGADO. Todo lo narrativo es PROPUESTA [P]**, sin aprobar (diseño:
`docs/diseno/ciudades_y_lugares.md` §2.2). Con la región apagada, Sunken City sigue siendo la zona 2D de siempre
(`zona.tscn` con el lugar 5) y nada de esto aparece (ni en el Diario).

## 1. Qué hay

Primer sector jugable de «la ciudad en las costillas»: un barco de guerra varado y medio hundido en una laguna salada,
a la hora fija de la **tarde dorada** (sol bajo del oeste-suroeste, sombras largas hacia el este, sombra fría del
reflejo de la laguna). El barco va del sur (popa, la entrada) al norte (proa, el hito).

| Tramo | Qué se ve y se hace |
|---|---|
| **Muelle de llegada** | Se llega del mapa por un muelle de tablas; al fondo, el **espejo de popa** curvo y partido por la mitad: el muelle entra por la brecha. «Examinar el espejo de popa»: el nombre del barco raspado, solo quedan los clavos de las letras. Al final del muelle, la **salida** («Mapa del mundo», disco que brilla). |
| **Cubierta de popa** | Redes, barriles y cajones. Junto a la brecha, por dentro, un **grabado** a navaja (la pista del secreto). |
| **Archivo del Águila** (desvío 1, al este, en alto por una rampa) | El antiguo camarote del capitán, abierto al cielo por delante y con una lona sobre los archivadores. La **contramaestre Ulla** tras su mesa; el **atril de los contratos** = el detalle de canon `sunken_contratos` (mismo id que la 2D; el brazalete brilla cerca mientras no se ha visto). |
| **La Quilla** | Pasarela de tablas sobre la quilla, bajo tres **costillas en arco** (z 44, 38 y 32), cada una con un farol de barco colgado… **menos la del medio** (cabo cortado). Casas de tablas pintadas colgadas a los lados, toldos remendados, ropa tendida de lado a lado. |
| **Cubierta Mayor** (la plaza, en alto por una rampa) | El **tocón del palo mayor** con la **bandera del Águila** (carmesí, el águila dorada siempre entera) que se mece; la **capitana Brea**; el **puesto del mercado** = la tienda del lugar 5 (con la Moneda del Águila de `equipo_extra.gd`); la **escotilla** al Casco, atrancada («Cerrado hasta la marea baja»: el Casco queda pendiente). Al norte, la **proa en obras** (cuerdas y letrero) y el **mascarón del águila dorada**, que se ve desde la barandilla de proa (cámara más baja en esa zona). |
| **Balcón de estribor** (desvío 2) | Mira al **dique**: una lona enorme sobre algo con forma de barco (la Astraea solo se VE; no se nombra ni se usa). |

**Misión «El sello de la capitana»** [P] (en el Diario, `datos/encargos_sunken.gd`; sin combate):
Ulla necesita el sello de Brea para el contrato de amarre → Brea, con una adivinanza: «lo dejé con la única de este
barco que nunca se arría» → el sello está atado a la driza de la bandera, al pie del palo mayor (sin la pista, el palo
solo enseña la bandera) → se le lleva a Ulla. El Diario enseña solo los pasos hechos y el actual, y las pistas oídas.

**Secreto «la costilla que no alumbra»** [P] (deducible): el grabado dice «Mi paga duerme bajo la costilla que no
alumbra»; de las tres costillas de la Quilla, la del medio no tiene farol; a su pie, una tabla suelta (el botón solo
sale pegado a ella, en el borde oeste de la pasarela) con la paga de un marinero: **80 monedas y 1 Éter, una vez**
(`cofres_abiertos["sunk_cofre_paga"]`).

**Recompensa única ligada a un oficio**: Ulla da el **Bronce del Águila** (una plancha del forro del casco) →
investigación de la **forja de Kael** «El bronce del casco» (`kael_bronce_aguila`) → receta **«Guarda del Águila»**
(`kael_guarda_aguila`): **+2 de vitalidad para siempre (+16 PV), un solo uso**. `talleres.gd reservado()` lo guarda
(no se vende ni se gasta) hasta estudiarlo, como el Polvo de cantera.

**Vecinos** [P]: Ulla (figura chibi «alquimista» con atlas propio: túnica azul de marino, gafas, tintero) y Brea
(«viajero»: capa y capucha carmesí, casaca azul). 7 diálogos de 2-3 frases (≤ 110 letras) en `dialogos/sunken/`.

**Comentarios del grupo** [P] (solo si Lya o Garon están en el grupo activo; una vez por sesión): al cruzar la brecha
(Lya: «Cuelgan la ropa de las costillas…» / Garon: «Mientras aguante, es una casa»), ante la lona (Lya: «Tiene forma
de barco… pero no de los que se quedan en el agua» / Garon: «Lo que no se enseña, no se pregunta. Todavía») y tras el
secreto (Garon: «Paga de marinero. Alguien no volvió a por ella» / Lya: «O no pudo. Guárdala bien, Kael»). Con Kael
solo, los suyos.

**Sonido** (con lo que hay en `audio/`): ambiente «puerto» (el viento de la costa, `musica.gd`), el agua que lame el
casco (el bucle del río, bajo, a los dos costados), crujidos de madera a lo largo de la Quilla (`puente_cruje`), viento
en los obenques del palo (`viento_cuerdas`) y el murmullo del mercado en el puesto. Pasos de madera. **Pendiente:** no
hay olas, gaviotas, velas ni campana de barco en `audio/` (ver §7).

**Guardado** (solo claves que ya existían): `mazmorras["sunken"]` (sello_pedido, sello_pista, sello_hallado,
sello_fin, grabado_visto), `cofres_abiertos` (sunk_cofre_paga), `lore_visto` (sunken_contratos, por progreso.gd),
`investigaciones` e inventario. Se guarda al entrar, al acabar un diálogo que cambia algo, al examinar lo que cambia la
partida, al cerrar la tienda y al pausar (`guardar_posicion`). Una partida antigua carga limpia (todo por hacer).

## 2. Cómo se activa

- **Argumento**: `godot ... -- 3d sunken3d` (la exploración 3D y la región).
- **Ajustes** (solo en la APK de **Auditoría** o en el editor, `calidad_proto.pruebas_permitidas()`): bloque de
  regiones, fila «Sunken City: 2D (la de siempre) / 3D (en pruebas)» → `[regiones] sunken3d` en `user://ajustes.cfg`.
  Se nota la próxima vez que se entra desde el mapa.
- **Banco de pruebas**: no tiene entrada (no hacía falta para recorrerla; pendiente si el coordinador la quiere).
- Apagada: el mapa lleva a la 2D; una partida guardada en la 3D vuelve a la 2D por su entrada (los trazados no se
  corresponden: no hay `posicion_a_2d`); una partida de la 2D con la 3D encendida entra por el muelle.

## 3. Archivos

Nuevos:
- `aethelgard/zonas3d/sunken_3d.gd` / `.tscn` — la escena (extiende `prototipos/vista3d.gd`, como Oakhaven y Ciclópea).
- `aethelgard/zonas3d/sunken/trazado.gd` — por dónde se anda (tramos rectos), alturas, bloqueos, piezas y cámaras.
- `aethelgard/zonas3d/sunken/casco.gd` — monta el GLB (una malla por material, choques), el suelo, la laguna
  (`agua_sin_refraccion` en bajo/medio, `water.gdshader` con refracción en alto), faroles, mascarón, gaviotas
  (`fauna_simple.gd`) y aparta (medio transparentes) las costillas y la bandera que quedan entre la cámara y Kael.
- `aethelgard/zonas3d/sunken/fuente/crear_sunken.py` — **fuente editable de Blender 5.2** (reutiliza las ayudas de
  `oakhaven/fuente/crear_distrito.py`): `blender -b --factory-startup -P crear_sunken.py -- <carpeta>` →
  `modelos/sunken.glb` (alto, 19 988 triángulos) y `modelos/sunken_ligero.glb` (medio y bajo, 12 208).
- `aethelgard/ciudades/sunken.gd` — datos y lógica de la ciudad (vecinos, diálogos, señales, secreto, comentarios).
- `aethelgard/datos/encargos_sunken.gd` — la misión para el Diario.
- `aethelgard/dialogos/sunken/*.dtl` (7) y `aethelgard/dialogos/personajes/sunken/{ulla,brea}.dch`.
- `aethelgard/datos/materiales/bronce_aguila.tres`, `datos/investigaciones/kael_bronce_aguila.tres`,
  `datos/recetas/kael_guarda_aguila.tres`.
- `aethelgard/personajes/npc_v12/alquimista/ulla.png`, `viajero/brea.png` (atlas de persona; mismas UV del oficio).
- `aethelgard/pruebas/prueba_sunken3d.gd`, `prueba_sunken3d_apagada.gd`, `fotos_sunken3d.gd`.

Tocados (lo mínimo): `modo3d.gd` (SUNKEN en REGIONES, EN_PRUEBAS y EQUIVALENTES_ZONA), `menus.gd` (una línea: la fila
de Ajustes), `musica.gd` (contexto «puerto»), `encargos.gd` (FUENTES), `talleres.gd` (reservado del bronce),
`project.godot` (los 7 diálogos y 2 personajes de Dialogic), `pruebas/lista_pruebas.txt`, `fuente/crear_npc_chibi.py`
(las personas «ulla» y «brea») y los `.json` de los oficios alquimista y viajero (lista de personas).
No tocados: combate*, progreso.gd, investigacion.gd, datos/catalogo.gd, ciudades/oakhaven*, zonas3d/oakhaven/*, Érebo,
Nix, Garon.

## 4. Pruebas y resultados

**Batería** (`ejecutar_pruebas.ps1`, datos aislados; carpeta `D:\REBELUM_diagnostico\pruebas\2026-11-15_023036\`):
**SUPERADAS 20 · FALLIDAS 0** — prueba_sunken3d, prueba_sunken3d_apagada, prueba_restaurar_escenas,
prueba_gran_bosque3d, prueba_oakhaven3d, prueba_ciudad_datos, prueba_diario_misiones, prueba_encargos, prueba_datos,
prueba_investigacion, prueba_oficios, prueba_oakhaven_propuestas, prueba_oakhaven_v10, prueba_ciclopea3d,
prueba_ciclopea3d_apagada, prueba_musica, prueba_formato_regiones, prueba_mundo_vivo, prueba_calidad_pruebas,
prueba_portada_alternativa. `partida.save` real y carpeta real de datos: sin cambios. («Proyecto cambiado»: solo `.uid`
sin seguimiento que Godot genera para archivos ajenos a este encargo; no se añaden.)

`prueba_sunken3d` comprueba (16 apartados): interruptor y entrada por el muelle (lugar 5, zona «ciudad», ambiente
«puerto»); suelo a su altura en todo lo andable y la laguna, la proa, la escotilla y las casas sin pisar; las 11 piezas
y vecinos alcanzables con el controlador real (destino → vista3d, tramos rectos desde el muelle) con su botón; la
costilla sin farol; guardar y cargar ANTES, A MITAD y DESPUÉS con `Progreso.cargar`; la misión con Dialogic de verdad;
el secreto y la forja una sola vez; el detalle `sunken_contratos`; la tienda del lugar 5; partida antigua; salida al
mapa y vuelta; referencias, frases ≤ 110 sin términos vetados, catálogo válido y comentarios del grupo.

**Recorrido jugado con ventana** (`fotos_sunken3d.gd`, clics en el suelo e Intro, sin poner estados a mano):
**0 fallos** en alto. Capturas y `recorrido_alto.txt` en `D:\REBELUM_diagnostico\sunken\recorrido_15_11b\` (26 momentos:
llegada, nombre raspado, brecha con el comentario de Lya y Garon, grabado, Ulla, Diario, contratos, Quilla, Cubierta
Mayor, palo sin y con la pista, Brea, tienda, proa con el mascarón, lona con comentario, fin de la misión, Diario
final, la tabla y su comentario, forja de Kael; y 14 vistas fijas medidas). Vistas en medio y bajo:
`D:\REBELUM_diagnostico\sunken\vistas_15_11\`. Pasadas anteriores de arte: `iter1`…`iter3` en la misma carpeta.

**Medidas en el PC** (no certifican Android; con Lya y Garon en pantalla, que son la mayor parte de las primitivas):
| Perfil | Casco | Llamadas de dibujo | Primitivas | ms/fotograma (tope de FPS del perfil) |
|---|---|---|---|---|
| alto | sunken.glb, 19 988 tri, 87 mallas | 81–143 | 147–164 k | 18–19,6 |
| medio | sunken_ligero.glb, 12 208 tri, 79 mallas | 54–106 | 130–144 k | 18,4–19,2 |
| bajo | sunken_ligero.glb | 40–75 | 68–75 k | 18,5–19,2 |
Montar el casco: 45–60 ms. Había otros Godot de otros agentes abiertos durante las medidas: son orientativas.

**Hallazgos técnicos para el coordinador** (fuera de este encargo, no tocados):
1. `vista3d.gd _vigilar_atasco`: si se pone un destino nuevo antes de llegar al anterior (un toque o un arrastre
   mientras Kael anda), compara con la distancia que quedaba al anterior y puede pararlo «por atasco» al segundo.
   Afecta a todas las regiones; la prueba de aquí espera a que Kael se pare antes del siguiente tramo.
2. En las pruebas sin ventana con `--fixed-fps 30`, entrar desde el mapa (`mapa._entrar` → `Recursos.cambiar_escena`,
   carga en segundo plano) falla al cargar el guion de la región (igual con Ciclópea 3D). Sin `--fixed-fps` entra bien.
   La prueba de aquí reproduce lo que hace `_entrar` y cambia de escena directamente.
3. Al importar, Dialogic reordena dos líneas de `project.godot` (`oak_ferro_v` / `oak_ferro_sin_hierro`); se dejó en
   su orden original.

## 5. Estado artístico

- **Revisado a ojo con capturas** (tres pasadas): costillas, espejo de popa, casas colgadas, Archivo, palo y bandera,
  mascarón, dique y lona, luz de la tarde, agua. Es **primera versión** de arte procedural (bloques y tubos con colores de
  vértice y el grano de `materiales.gd`), pensada para la cámara del juego; **no es arte final**.
- **Provisional (identificado como tal):** casas colgadas (cajas de tablas), lona de la Astraea (malla de joroba), la
  orilla de arena y la costa lejana (cajas), el puesto del mercado (el del distrito de Oakhaven), el timón caído, las
  redes (cajas). El mascarón se lee como «ave dorada» desde la proa, sin detalle de cerca. Ulla y Brea son la familia
  chibi V12 con atlas nuevo (no tienen retrato en Dialogic, como Ferro o Hilda).

## 6. Propuestas de canon (todas sin aprobar)

Ulla y Brea con sus frases; «El sello de la capitana» (el contrato de amarre, el sello de la capitana, la adivinanza de
la bandera); el grabado y la paga del marinero; el Bronce del Águila y la Guarda del Águila; los textos del espejo de
popa y de la bandera (de las notas `nota_sunk_popa` y `nota_sunk_bandera` del diseño, aquí solo como avisos: no se
guardan como notas porque `progreso.gd` no conoce Sunken en CIUDADES); «Cerrado hasta la marea baja» en la escotilla
(gancho a la misión «La marea baja» del diseño); «Proa en obras. Orden de la capitana»; los comentarios del grupo.
Respetado: nada de Érebo, corazones ni recuerdos; la Astraea solo se ve bajo la lona (Brea: «lo que hay debajo vuela»,
del diseño); nada de que Garon sirviera en la Compañía; nada con forma de brazalete; el Casco, cerrado.

## 7. Pendientes

- **Redmi**: medir bajo y medio (llamadas de dibujo, ms) con el grupo completo; revisar legibilidad de los botones en el
  Archivo y la Quilla; el agua opaca en bajo.
- **Sonido**: olas contra el casco, gaviotas, velas/cabos y campana de barco no existen en `audio/`.
- **Arte**: casas y lona con piezas de Blender más detalladas; Doña Coral, Inés y el resto de vecinos del diseño; el
  Casco del buque, el Muelle de la Laguna, el Ancla Seca y el resto de Babor/Estribor; las notas en el Diario (necesitan
  `progreso.gd` CIUDADES[5]).
- Entrada en el banco de pruebas, si se quiere.

## Mediciones de PC (15/11, sin otros Godot; NO certifican Android)

`pruebas/medir_sunken3d.gd`, `D:\REBELUM_diagnostico\sunken\medida_15_11\medida_<perfil>_<frio|cache>.txt`.
- **Configuración:** NVIDIA RTX 3050 Laptop (OpenGL 3.3, controlador 621.01), AMD Ryzen 7 4800H (14 hilos), ventana
  1280×720, renderizador gl_compatibility. «Frío»: carpeta de datos nueva (sombreadores sin caché); «caché»: la misma
  carpeta otra vez. Tres entradas por proceso desde el mapa (Recursos.cambiar_escena, como mapa._entrar).
- **Cargas hasta el control:**

| Perfil | 1.ª entrada, frío | 1.ª entrada, con caché | Posteriores |
|---|---|---|---|
| Bajo | 1487 ms | 1275 ms | 903-923 ms |
| Medio | 1421 ms | 1306 ms | 898-939 ms |
| Alto | 1447 ms | 1314 ms | 893-908 ms |

- **Tirones tras entrar** (peor fotograma de los 2 s siguientes): ninguno; 33,4-33,6 ms en bajo y medio (límite de
  30 FPS) y 16,9-17,0 ms en alto (límite de 60 FPS), también la primera vez en frío.
- **Fotogramas quietos 4 s** (mediana · p95 · máximo, con el límite del perfil): bajo y medio 33,3 · 33,4 · ≤33,9 ms;
  alto 16,7 · 16,7 · ≤17,2 ms. Dibujo medido por el motor (sin límite):

| Perfil | Muelle | Quilla | Cubierta |
|---|---|---|---|
| Bajo | CPU 0,76-1,33 / GPU 0,38-0,61 ms · 34 llamadas · 24,5 mil prim. | CPU 0,87-0,91 / GPU 0,41-0,49 · 72 · 25,7 mil | CPU 0,83-1,08 / GPU 0,46-0,56 · 64 · 31,5 mil |
| Medio | CPU 0,71-0,77 / GPU 0,48-0,57 · 41 · 43,2 mil | CPU 0,96-0,98 / GPU 0,51-0,52 · 90-94 · 44,3-44,6 mil | CPU 0,88-0,98 / GPU 0,60-0,66 · 82-86 · 56,5-56,7 mil |
| Alto | CPU 0,95-1,01 / GPU 1,13-1,14 · 81 · 61,8 mil | CPU 1,14-1,60 / GPU 1,16-1,18 · 134 · 71,0 mil | CPU 1,27-1,32 / GPU 1,32 · 110-114 · 74,2-74,5 mil |

- **Memoria** (estática · vídeo · texturas): en el mapa 101 · 36,7 · 28,4 MB. En Sunken: bajo 117,9-118,7 · 48,0-48,7 ·
  34,7-35,4; medio 118,3-119,1 · 48,9-49,6 · 35,6-36,3; alto 119,0-119,9 · 70,6-71,4 · 56,8-57,6 MB. De vuelta al
  mapa vuelve a lo mismo en cada entrada (sin crecimiento entre la 2.ª y la 3.ª).
- **Android:** pendiente de medir en el Redmi (FPS, perdidos, PSS, temperatura).
