# Muestra gráfica: una calle de Oakhaven (V12, EN PRUEBAS)

15/11/2026 · especialista gráfico · rama `area-grafico/muestra-calle` (desde `claude/rebelum-v12` @ `bbdeff8`).
**Estado: EXPERIMENTAL, EN PRUEBAS y APAGADA.** Solo se entra desde el banco de pruebas de Auditoría
(«Muestra gráfica: una calle de Oakhaven (en pruebas)»). Ninguna escena del juego la enlaza, Oakhaven 3D no cambia y
las APK sin banco no la llevan. Es una pieza para juzgar el salto de calidad **antes** de renovar nada más.

Capturas, vídeo y medidas: `D:\REBELUM_diagnostico\muestra_calle_15_11\` (fuera del repositorio).

## 0. Qué hay y cómo se entra

- **Escena:** `aethelgard/zonas3d/muestra_calle/muestra_calle.tscn` (`muestra_calle.gd`, extiende `prototipos/vista3d.gd`:
  el mismo control de Kael —tocar/clic, teclas, mando—, CAL y RND).
- **Entrada:** `banco_pruebas.gd`, `EXPLORAR["muestra_calle"]` (solo Kael). «Volver al banco», arriba a la izquierda, como
  en las demás exploraciones del banco.
- **Qué se ve:** una calle a la última luz de la tarde con dos fachadas de entramado con vuelos (la casa de la puerta,
  larga, con alero a la calle, buhardilla y chimenea; la casa de la esquina, con el hastial a la calle, dos vuelos,
  balconcillo, viga de polea y chimenea), **la puerta** (arco de dovelas, hoja verde de tablas con herrajes y aldaba,
  tres escalones gastados, farol, macetas, banco, escoba y el letrero colgado de la botica con su mortero de latón) y
  **la esquina** (torreón en voladizo sobre ménsula y jabalcones, con entramado, ventanitas y tejado cónico de pizarra
  con veleta; guardacantón, hornacina con velas y figurilla, farol en diagonal). Entre las dos, un **callejón** con
  escalones, macetas, hiedra, ropa tendida de ventana a ventana y un patio al sol al fondo, tras un arco. En los extremos,
  el muro del huerto con su portillo y un árbol (oeste) y una calleja con cobertizo, leña y farol de pie (este). Al sur,
  la orilla de la calle con matorrales agrupados, el farol de pie y la carretilla que enmarcan, y un huerto con cerca,
  bancales, pozo y almiar (lo que ve la cámara alta).
- **Suelo:** losas irregulares (celdas de Voronoi con junta y canto biselado, algo inclinadas y de alturas distintas) que
  se deshacen hacia los bordes en tierra pisada, con huecos de losa que faltan y hierba en las juntas.

## 1. Paso 0 — análisis (antes de modelar)

(El análisis se hizo antes de modelar —lectura del código de Oakhaven, de Kael y de los perfiles, y la decisión de
hornear la luz—, pero este documento se escribió al final, con lo medido. Los números del presupuesto «previsto» son los
de entonces.)

### 1.a La referencia, sin la imagen: qué cualidades se traducen y cómo

No se recibió la imagen de Final Fantasy IX (Moguri mod). No se copia ningún edificio, encuadre ni elemento: se extraen
las cualidades que se describieron y se traducen a esta calle y a lo que puede un Mali-G57.

| Cualidad | En esta calle |
|---|---|
| **Densidad de detalle en capas** | Tres escalas: masa (casas, tejados), elementos (vigas, postigos, jardineras, ménsulas, cabezas de viguetas, cumbreras, chimeneas) y menudo (clavos, aldaba, pinzas, velas, manzanas). Primer plano / medio / fondo: farol de pie, barriles, carretilla y matorrales abajo; Kael y las fachadas en medio; el patio al sol tras el arco del callejón, el árbol y la calleja al fondo. |
| **Siluetas irregulares** | Vuelos escalonados, aleros hondos, buhardilla, dos chimeneas, hastial con viga de polea, torreón cónico con veleta, letrero colgado en brazo de hierro, ropa tendida. Las piezas llevan una pizca de deformación (vigas y escalones no perfectamente rectos, tejas con hundimiento). |
| **Paleta cálida con acentos** | Revoques crema y ocre, madera oscura rojiza, teja anaranjada calmada, piedra gris cálida; acentos: postigos azules (casa A) y rojos (casa B), puerta verde, pizarra azulada del torreón, flores rojas/amarillas/lilas, latón del letrero, cristales encendidos. |
| **Luz con dirección y ambiente** | Sol bajo del oeste-suroeste (24° de altura): sombras largas y rasantes sobre las fachadas (vuelos, ménsulas y postigos dibujan bandas), cielo frío en la sombra, rebotes cálidos del suelo, oclusión en rincones y bajo los aleros. Todo horneado (Cycles), así que es igual en el perfil bajo. Bruma cálida suave. |
| **Suelo con historia** | Losas gastadas e inclinadas, con musgo en algunas, losas que faltan, juntas con hierba, el empedrado deshecho en tierra en la orilla, escalones gastados. |
| **Rincones que cuentan algo** | La hornacina con velas en la esquina, el cesto de manzanas en el cajón, la escoba y el cubo junto a la puerta, la ropa tendida entre vecinos, la leña bajo el cobertizo, el pozo del huerto. |

### 1.b Los recursos actuales de Oakhaven 3D

Mirado: `zonas3d/oakhaven_3d.gd`, `zonas3d/oakhaven/` (ciudad.gd, distrito.gd, barrios.gd, modelos/*.glb,
fuente/*.py), `zonas3d/garganta/materiales.gd`, `ciudades/oakhaven_arte/`, el Kael de la exploración (vista3d.gd →
heroes_v2 → `kael_3d.gd`/`maga_3d.gd`) y `prototipos/calidad_proto.gd`.

| | Recurso | Por qué |
|---|---|---|
| **APROVECHABLE** | Trazado de la ciudad (`ciudades/oakhaven.gd`, LUGARES; una casilla = un metro) | La muestra no lo toca; una renovación encajaría sus calles sobre él. |
| | `prototipos/vista3d.gd` (cámara sin giro, recorrido seguro, CAL/RND, regulador) | La muestra lo hereda tal cual (solo cambia la cámara y la luz de Kael). |
| | Kael (`kael_3d.gd` sobre `maga_3d.gd`: `marcha()` sin patinar, esperas) | Se usa sin tocar su escala ni sus proporciones (1,7 m). |
| | `prototipos/calidad_proto.gd` (perfiles bajo/medio/alto) | La muestra lee de él la escala 3D, MSAA y FPS; añade solo qué mapa de luz y qué extras. |
| | Método de los guiones de Blender (`crear_distrito.py`, `crear_barrios.py`: coordenadas de Godot, cajas de choque, anclas, misma semilla) | Es el mismo método; la muestra lo amplía con texturas, horneado y recorte. |
| | Sonido de pasos y oyente 3D (`Sonido.pasos_3d`) | Usado tal cual («paso_piedra»). |
| **MEJORABLE** | `modelos/casa_*.glb`, `distrito.glb`, `barrios.glb`, `taberna.glb`… | Geometría correcta y con entramado, pero **color plano por vértice**, sin texturas, sin oclusión ni sombra propia horneada; ventanas encendidas planas. Con el horneado de la muestra ganarían mucho sin rehacer la forma. |
| | `materiales.gd` (`sillar()`, `detalle()`: grano de ruido) | Correctos para color plano; para la calidad pedida faltan texturas con dibujo (juntas, vetas, tejas). |
| | Adoquines de `ciudad.gd` (MultiMesh de piedras redondas iguales sobre una rejilla) | Leen como «guijarros sueltos» sobre el suelo; la muestra los sustituye por losas que encajan con juntas. |
| | Vegetación de `ciudad.gd` (`_mata`, flores al azar en jardines) | Repartida al azar; la muestra la agrupa en bordes, grietas y rincones. |
| | Faroles y halos falsos | Buen recurso barato; en la muestra los faroles alumbran de verdad (en el horneado). |
| **A SUSTITUIR** | Suelo de rejilla de 1 m con color por vértice (`ciudad._suelo`) | Se ve a cuadros; sin relieve ni transición. |
| | Iluminación uniforme de la hora azul sin sombras en el bajo | En el bajo (sin sombras) todo queda plano; el horneado da sombra y rebote en todos los perfiles. |
| | `ciudades/oakhaven_arte/*.webp` | Arte 2D de la ciudad 2D: no aplica al 3D (vale como referencia de paleta). |

### 1.c Plan de pasadas y presupuesto (perfil bajo)

Pasadas en el orden pedido, con capturas de cada una: composición → arquitectura → materiales → iluminación →
vegetación/decoración → integración del personaje → optimización.

Decisión técnica central: **luz horneada en Blender** (Cycles) y **materiales sin cálculo de luz** en Godot
(`unshaded`: textura × tinte × luz). Es lo más barato que hay en un Mali y da sombras, rebotes y oclusión que en el bajo
(sin sombras en tiempo real) hoy no existen. Kael se ilumina en tiempo real con **el mismo sol y el mismo cielo** que
el horneado, medidos en Blender con dos placas de calibración.

| Presupuesto (bajo) | Previsto | Medido (PC) |
|---|---|---|
| Triángulos en pantalla | ≤ 120 000 (calle ≤ 90 000 + Kael) | **77 134** (calle 10 943 + piezas 19 389 + vegetación 28 584 + Kael ≈ 18 000) |
| Llamadas de dibujo | ≤ 40 | **31** |
| Texturas de la muestra | 8 × 512² + mapa de luz 1024², comprimidas (≈ 2 MB) | 8 × 512² VRAM + 1024² (bajo) / 2048² (medio y alto) |
| Luces | 1 direccional SIN sombra (solo afecta a Kael); 0 omni | igual |
| Sombreados | 4, sin luz | `calle_estatico`, `calle_vertice`, `calle_hoja`, `calle_brillo` |
| Transparencias | 0 en bajo y medio | 0 (humo y motas solo en el alto) |

## 2. Las pasadas (lo que se hizo y lo que salió)

Capturas `pN_*`: las de las pasadas 1-5 salieron a 1280×720 (lo que dibuja el juego; el nombre lo dice); desde la 6, a
1600×720 con las franjas negras que tendrá el Redmi (el proyecto conserva 16:9, `stretch keep`).

1. **Composición (blockout)** — `p1_blockout_*`. Cajas y faldones. Se fijó la cámara: con la de Oakhaven (52°) las
   fachadas se ven por arriba y los tejados se salen del cuadro; para la muestra, **10,8 m sobre Kael, 14,2 m al sur,
   25° hacia abajo, 38° de campo**, sin girar, siguiendo a Kael en x entre −3,5 y 3,5 (y algo en z en el callejón).
   Kael queda en el tercio inferior y caben las fachadas enteras con aleros y chimeneas.
2. **Arquitectura** — `p2_arquitectura_*` (luz en tiempo real, sin texturas). Entramados, vuelos, ménsulas, cabezas de
   viguetas, postigos abiertos, jardineras, puerta, letrero, torreón, callejón, extremos. Arreglos: la puerta no cabía
   bajo el vuelo (planta baja a 3,1 m, sin tejadillo), ventanas fuera de los pies derechos, hornacina en la fachada (la
   pared este nunca se ve), letrero paralelo a la fachada (de canto no se leía).
3. **Materiales** — `p3_materiales_*`. Texturas de 512² pintadas con numpy (revoque con chorretones, madera con veta,
   tejas abombadas, sillería con llagas, piedra moteada con liquen, tierra con guijarros, tela, hoja); el color lo pone el
   tinte de cada pieza. Se calmó la paleta de las losas y de las tejas.
4. **Iluminación** — `p4_iluminacion_*`. Horneado Cycles (OptiX, 256 muestras, ≈ 20 s): difusa directa + indirecta. Tres
   ajustes hasta que se leyó la luz: sol más fuerte y cielo más bajo (relación sol/sombra ≈ 3:1), y el sol más rasante
   desde el oeste-suroeste (rumbo 252°, 24°) para que vuelos y postigos dibujen sombras largas. Lección: las miles de losas
   y piezas en el mapa de luz se comían el sitio de las fachadas → **las piezas sueltas y la vegetación llevan la luz en
   los vértices** (también horneada) y el mapa se queda para lo grande. Se apagaron en la importación los LOD automáticos,
   las tangentes y las mallas de sombra (no se usan).
5. **Vegetación y decoración** — `p5_vegetacion_decoracion_*`. Matas al pie de los muros (más en esquinas y escalones),
   hierba en juntas de losas hacia la orilla, matorrales en grupos con calvas entre ellos, flores en jardineras y macetas,
   hiedra en la esquina oeste y en el fondo del callejón, rosal en la casa B, arbustos y árbol; barriles, cajones, cesto,
   macetas, escoba, cubo, banco, carretilla con sacos, leña, faroles de pie, ropa tendida; después, el huerto del sur.
   Viento en la vegetación (vértices).
6. **Integración de Kael** — `p6_integracion_*` (y `vista_libre` de cerca). Escala de siempre; suelo de choque a la altura
   de las losas; luz con el sol y el cielo medidos en el horneado; **sondas** (rejilla de 0,25 m a 1 m del suelo con
   cuánto sol y cuánto cielo llega): al pisar la sombra del callejón se apaga su sol y baja su ambiente. **Sombra**: mancha
   de contacto y sombra larga hacia donde la echa el sol, dentro de los propios sombreados del suelo, las piezas y la
   vegetación (no como capa transparente: ver §7, «Riesgos»).
7. **Optimización** — `p7_final_*`. Recorte en Blender de lo que ninguna cámara posible ve (19 470 triángulos, el 40 % de
   lo fijo: caras del norte, bajos, interiores; siguen en el horneado para tapar y rebotar luz); mapa de luz de 1024 en el
   bajo; texturas VRAM con mipmaps; una superficie por material (31 llamadas); cero luces dinámicas sobre la calle; humo
   y motas solo en el alto.

## 3. Antes / después (mismo encuadre)

- **Antes:** Oakhaven 3D, **Calle del Cuervo**, Kael en (21,5; 0; 26,0), ante la Taberna del Cuervo Oxidado y la casa de
  6×4 (con Lya y Garon detrás, como en el juego).
- **Después:** la muestra, Kael en (−1,0; 0,06; 0,9).
- **Cámara «muestra»:** Kael + (0; 10,8; 14,2), rotación (−25°, 0, 0), campo 38°. En Oakhaven: posición (21,5; 10,8; 40,2).
- **Cámara «juego»:** la de juego de Oakhaven en esa calle: ojo a 0,9 m sobre Kael, 52°, 18 m, campo 38°. En Oakhaven:
  posición (21,5; 15,08; 37,08), rotación (−52°, 0, 0).
- Archivos (1600×720): `antes_camara_{muestra,juego}_{bajo,medio}`, `despues_camara_{muestra,juego}_{bajo,medio,alto}` y
  las comparaciones `comparar_camara_{muestra,juego}_{bajo,medio}_antes_arriba_despues_abajo.png`.
- **Ojo:** el antes es la **hora azul** canónica de Oakhaven y el después la **tarde dorada**: la comparación mezcla
  calidad y hora. Hornear una variante a la hora azul con el mismo guion es directo (otro sol, otro cielo, faroles más
  fuertes) y no se ha hecho.
- Coste del antes (mismas capturas, medianas de 30 fotogramas): Calle del Cuervo con la cámara de la muestra, **82
  llamadas · 208 305 primitivas** (bajo) y 93 · 312 551 (medio); con la de juego, 67 · 190 665 (bajo).

**Vídeo:** `kael_calle_bajo.mp4` (28 s, 1280×720, 30 FPS, perfil bajo; Movie Maker de Godot + ffmpeg): Kael anda (clip
de andar, 1,4 m/s) del oeste a la puerta, a la boca del callejón, sube los escalones (entra en la sombra), baja y sigue
hasta la esquina del torreón. Grabado con `pruebas/grabar_muestra_calle.gd`. (Se ve el contador de FPS de la esquina
superior: es de la interfaz general.)

## 4. Medidas en el PC (VERIFICADO; NO certifica el Redmi)

PC: RTX 3050 Laptop + Ryzen 7 4800H, Compatibility (OpenGL 3.3), ventana 1600×720. `pruebas/medir_muestra_calle.gd`;
textos en `medidas/medida_muestra_{bajo,medio,alto}.txt`. Cuatro sitios (inicio, puerta, esquina, callejón): los números
apenas cambian entre ellos.

| Perfil | Carga (hasta el control) | Con su límite (ms reales) | Sin límite (ms reales) | CPU dibujo | GPU dibujo | Llamadas | Primitivas | Vídeo / texturas |
|---|---|---|---|---|---|---|---|---|
| bajo | 769 ms | 33,3 / p95 33,4 / máx 33,8 (30 FPS) | 6,9 / p95 7,5 / máx 8,5 | 0,85 ms | 0,41 ms | 31 | 77 134 | 39,7 / 24,9 MB |
| medio | 746 ms | 33,3 / 33,4 / 33,7 (30 FPS) | 6,9 / 7,5 / 8,5 | 0,86 ms | 0,41 ms | 31 | 77 144 | 42,2 / 27,4 MB |
| alto | 723 ms | 16,7 / 16,7 / 17,2 (60 FPS) | 7,0 / 7,4 / 9,2 | 0,96 ms | 0,78 ms | 32 | 77 182 | 60,0 / 45,2 MB |

- «Sin límite» se queda en ≈ 7 ms porque lo marca otra cosa del PC (probablemente la sincronía con la pantalla), no la
  escena: la GPU dibuja en 0,4 ms.
- La memoria de texturas sube 17,5 MB al entrar en el bajo, pero las texturas de la muestra son ≈ 2 MB (8 × 512² y el mapa
  de 1024², comprimidos): el resto es Kael (sus texturas del FBX). Las primitivas que cuenta el motor son las del dibujo
  opaco.
- **Mali Offline Compiler (Mali-G57, estimación estática)**, `pruebas/herramientas/malioc/estimar_malioc_muestra.py`,
  tabla en `malioc/malioc_muestra.txt`: fragmento **4,8 ciclos** (estático, con mapa de luz), 4,5 (piezas y vegetación),
  4,0 (brillo); vértice 13-15 ciclos (variaciones); sin ZS tardío ni cambio de cobertura (sin descartes). Es poco: a
  0,75 × 1600×720 son ≈ 650 000 píxeles por capa.
- **Redmi (30 FPS sostenidos con el perfil bajo): PENDIENTE.** No se ha medido en el teléfono.

## 5. Pruebas

- `pruebas/prueba_muestra_calle.gd` (registrada en `lista_pruebas.txt`, modo auto): entrada del banco y escena; nadie más
  nombra la muestra; las APK sin banco no la llevan; carga, materiales, mapa de luz del perfil, choques, sondas y Kael;
  Kael anda 4 m con su clip, sobre el suelo, con la cámara siguiéndole sin girar; no entra en las casas ni sale por el
  sur; el callejón tiene menos sol y cielo que la calle; perfil bajo con el mapa de 1024.
- `ejecutar_pruebas.ps1 -Solo prueba_muestra_calle,prueba_banco_pruebas,prueba_banco_pruebas_3d`: **3 SUPERADAS, 0
  FALLIDAS** (partida real y carpeta de datos sin cambios). `prueba_banco_pruebas` cuenta ahora 11 casos.

## 6. Procedencia de cada recurso

| Recurso | Procedencia |
|---|---|
| Geometría de la calle (casas, puerta, esquina, callejón, losas, atrezo, vegetación, huerto) | Hecha aquí, procedural, en `fuente/crear_calle.py` (Blender 5.2.3, script propio). |
| Texturas `texturas/*.png` | Pintadas por código (numpy, dentro del mismo guion). |
| Mapas de luz `modelos/calle_luz_*.png`, luz de vértices, `calle_luz.json` (calibración y sondas) | Horneados con Cycles por el mismo guion. |
| Sombreados `calle_*.gdshader`, escena y guiones de prueba/herramientas | Escritos aquí. |
| Kael, `vista3d.gd`, perfiles, sonido de pasos («paso_piedra»), banco | Del proyecto, sin cambios. |
| Herramientas | Blender 5.2.3, Godot 4.7.2, ffmpeg y el Mali Offline Compiler instalados en el PC. |

Nada descargado, de pago ni en la nube; **sin Hunyuan3D**; sin complementos, addons ni GDExtension.

## 7. Valoración honesta

**Conseguido (VERIFICADO en el PC):** una calle terminada con capas reales (primer plano, medio y fondo), siluetas ricas
(vuelos, aleros, buhardilla, chimeneas, polea, torreón, letrero), luz con dirección y ambiente igual en los tres perfiles
—incluido el bajo, que hoy no tiene sombras—, suelo de losas con juntas que se deshace en tierra, vegetación en grupos y
rincones con historia; Kael con la misma luz que la calle, que se apaga en la sombra, y con sombra de contacto. Barata:
31 llamadas, 77 000 primitivas, 0,4 ms de GPU en el PC (la Calle del Cuervo de hoy: 82 llamadas y 208 000 primitivas en
el bajo) y ≈ 5 ciclos por fragmento estimados en el Mali-G57.

**Lo que aún no llega a la calidad pedida (FFIX Moguri):**
- Las texturas son de código: tienen grano y dibujo, pero no la pincelada, la suciedad pintada ni el detalle a mano de
  un fondo de FFIX. No hay mapas de normales (ni falta hacen sin luz dinámica, pero el relieve fino no existe).
- De cerca las losas se ven facetadas (sombreado plano con brillo en el bisel) y las matas, espigadas; la hiedra y el
  rosal son rombos. A la distancia de juego se sostiene; en las vistas de cerca, no del todo.
- El torreón y la calleja del este quedan algo desnudos; las ventanas encendidas son planas; el rellano del callejón,
  en sombra, se lee algo ruidoso.
- La sombra de Kael es sutil en el plano general; no se proyecta sobre paredes ni muebles.
- Una sola hora (tarde dorada), distinta de la hora azul canónica de Oakhaven. El cielo no se ve con esta cámara.
- No hay vecinos, ni sonido ambiente, ni interacción: es una muestra visual.

**Riesgos de rendimiento en el Redmi (PENDIENTE de medir):**
- Por GPU, poco riesgo: sombreados de ≈ 5 ciclos sin luz ni descartes, 31 llamadas y sin transparencias en el bajo.
- Memoria: lo de la muestra es pequeño; lo que pesa es Kael (texturas del FBX). El GLB pesa 5 MB y el PNG del mapa
  grande 4,4 MB (en el APK, comprimidos a ETC2).
- Calidad en el teléfono: el ETC2 puede dar bandas en los degradados del mapa de luz; la luz de vértices se guarda en 8
  bits (posibles escalones en sombras muy oscuras). Sin probar en pantalla real.
- **Transparencias:** en bajo y medio, en esta escena, una capa transparente oscura (material estándar, textura, color
  de vértice o sombreado propio, mezcla o multiplicación) **no oscurecía nada** en Compatibility; en el alto sí se
  dibujaba (mal). No se averiguó la causa (¿relación con la escala 3D < 1?). Se rodeó metiendo la sombra en los
  sombreados opacos y dejando humo y motas solo en el alto. Conviene investigarlo antes de usar transparencias en el
  móvil.
- Carga: 0,75 s en el PC; en el teléfono será más (PENDIENTE).

**Qué haría falta para extenderlo (sin hacerlo):**
1. Convertir el generador en un **kit**: fachadas, vuelos, tejados, puertas, ventanas y esquinas parametrizados, y
   montar con él las calles del trazado de Oakhaven (`ciudades/oakhaven.gd`).
2. **Hornear por barrios** (un mapa de luz por trozo de ~30 m, con su malla) para que el recorte por cámara y el
   descarte por trozos funcionen en una ciudad entera; decidir qué edificios se vuelven transparentes al tapar a Kael
   (necesita mallas separadas por edificio).
3. **Hora azul** horneada (la de Oakhaven) y, si se quiere, mañana: un mapa por franja, cambiando de mapa al dormir.
4. Una pasada de **textura pintada a mano** (o pintada sobre el horneado) para acercarse a la referencia.
5. Vecinos y objetos móviles con las sondas (misma luz que Kael) y sombras de contacto en el sombreado del suelo.
6. Medir en el Redmi antes de nada, con el perfil bajo, y decidir si el medio usa el mapa grande.

## 8. PENDIENTE

- **Medida en el Redmi** (30 FPS sostenidos, perfil bajo, 1600×720) y revisión en su pantalla: no hecha.
- Visto bueno del usuario a la dirección (la tarde dorada, la cámara más baja que la de Oakhaven, el estilo).
- La imagen de referencia no se recibió: lo de §1.a sale de la descripción.
- La rareza de las transparencias en bajo/medio (§7).
- Sonido ambiente de la calle: solo hay pasos.

## 9. Cómo regenerarla

1. `blender -b --factory-startup -P aethelgard/zonas3d/muestra_calle/fuente/crear_calle.py -- <ruta>/aethelgard/zonas3d/muestra_calle`
   (≈ 25 s con OptiX; `--fase blockout|arquitectura`, `--sin-horneado`, `--sin-recorte`, `--muestras N`, `--res N`).
2. Reimportar en Godot (con datos aislados): `godot --headless --path aethelgard --import`.
3. Capturas: `pruebas/fotos_muestra_calle.gd` (cabecera); medida: `pruebas/medir_muestra_calle.gd`; vídeo:
   `pruebas/grabar_muestra_calle.gd` con `--write-movie`; malioc: `pruebas/herramientas/malioc/estimar_malioc_muestra.py`.
   Las VISTAS fijas y la cámara están repetidas en `crear_calle.py` (para el recorte) y en `muestra_calle.gd`: si se
   cambian en uno, hay que cambiarlas en el otro.
