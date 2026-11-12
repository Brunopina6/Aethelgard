# Rendimiento V12 · especialista «rend2» (12/11/2026)

Copia `D:\Aethelgard_v12_rend2`, rama local `claude/v12-rend2` (desde `d8a65d3`). Sin push, merge ni ADB. Todo Godot,
con datos aislados. Medidas, capturas y registros en `D:\REBELUM_diagnostico\v12\expansion\rend2\`.

**Todo lo medido es del PC** (Ryzen 7 4800H, RTX 3050 portátil, Godot 4.7.2 Compatibility). No son FPS del Redmi. Durante
la sesión había otros Godot y Blender de los demás especialistas trabajando en el mismo PC (se apuntan en cada
`procesos.txt` y en los resúmenes de las pruebas): por eso las comparaciones son **intercaladas** (antes, después,
antes, después) o **en el mismo proceso** cuando se puede, y los tiempos por fotograma del PC (limitados por la CPU) se
toman solo como orientación.

Leyenda: **[E]** medido ejecutando · **[C]** visto en el código · **[?]** sin comprobar.

## 0. Resumen

| Qué | Encendido | Se ve | Efecto medido (PC) |
|---|---|---|---|
| Gran Bosque: **orden de dibujo** de lo opaco (`render_priority`) | sí | igual (4-395 píxeles sueltos de 921 600, empates de profundidad) | GPU sin prepase, 3D ×2: mirador medio **1,77 → 1,40 ms (−21 %)**, bajo 1,20 → 0,99 (−18 %); puente −7 %; entrada −4 %; resto −1-3 %; alto −2-15 % |
| Gran Bosque: **matas recortadas** a un octógono | **no** (`gb_matas_casco`) | casi igual (10-35 mil píxeles cambian un poco: viento y normales) | fragmentos de hojas en la entrada −32 % (capas 3,16 → 2,14); GPU medio −1-3 %, alto −8-18 % |
| Primer combate: **precalentado 2D** | sí | igual (ventana que no se ve) | primer ataque 11,8-13,9 → 0,3-0,7 ms; primera lista de objetivos ~20 → 10-19 ms |
| **Guiones** que se compilaban en mitad del juego, precargados | sí | igual | abrir el menú del mapa la primera vez: −112 ms de compilación; tienda/alquimia −65, Diario −37…; arranque igual (dentro del ruido), +2 MB |
| **Arranque**: Humbaba (apagado) y Pastoral Pulse (sin elegir) ya no se precargan | sí | igual | memoria estática −9 MB, de vídeo −9-15 MB, −100 recursos |

Commits (locales): `d45299f` orden de dibujo + herramientas · `ca5fe48` precalentado del combate · `350ca0c` arranque ·
`64e5578` guiones residentes · `d8b11ce` matas recortadas (apagado) · y el de este informe.

## 1. Gran Bosque Verde: diagnóstico

### 1.1 Medida de partida (`medir_escenas.ps1 -Escenas granbosque -Perfiles bajo,medio,alto`, `d8a65d3`) [E]

`...\rend2\medidas\antes\`. Carga repetida bajo 735/728 ms, medio 1193/966, alto 873/897; dibujos 96 / 176 / 266;
primitivas 192 k / 300 k / 566 k; vídeo 70 / 71 / 96 MB. El fotograma activo del PC (3,6-7,6 ms) lo marca la CPU: no
dice nada del Mali. Por eso el resto se mide con `pruebas/herramientas/medir_gpu_bosque.gd` (tiempo de **GPU**, sin
prepase de profundidad como en el Mali, ventana 1600×720 y el 3D al doble para que pese el coste por píxel), igual que
el informe anterior (`rendimiento_v12_gran_bosque.md`).

### 1.2 Por qué el PC predijo 30 FPS en medio y el Redmi da 21-25

El informe anterior estimó el medio a partir del tiempo de GPU del PC (la entrada, 1,41 ms, igual que el banco de
Pastos, que en el Redmi va a 30) y el Redmi dio 21-25. Para ver qué tiene el Gran Bosque que el PC no castiga y el Mali
sí, la herramienta tiene ahora un **recuento** (`recuento`) por categoría y por tipo de material: capas (fragmentos que
se rasterizan por píxel), parte de la pantalla que cubren, vértices dentro de la cámara, materiales y sombreados
distintos, y llamadas y primitivas sin la sombra del sol. Medio, sitios de juego (`...\rend2\gpu\gpu_*_antes.json` y
`_orden.json`):

| Medio | GPU ms (PC) | Llamadas (sin sombra del sol) | Primitivas | Capas | **Recortado** (discard): capas / pantalla | Vértices opacos | Materiales a la vista |
|---|---|---|---|---|---|---|---|
| GB entrada | 1,41 | 183 (108) | 303 k | 5,3 | **3,76 / 53 %** | 576 k | 47 |
| GB puente | 1,11 | 86 (53) | 250 k | 2,2 | 0,64 / 70 % (el agua) | 473 k | 26 |
| GB ruinas | 1,20 | 175 (107) | 291 k | 3,1 | 1,38 / 42 % | 545 k | 45 |
| GB claro | 1,19 | 140 (79) | 290 k | 3,6 | 1,91 / 44 % | 561 k | 39 |
| GB mirador | 1,78 | 103 (89) | 287 k | 4,7 | 1,65 / 61 % | 752 k | 36 |
| Pastos banco A | 1,30 | 201 (144) | 459 k | 3,5 | 1,86 / 24 % | 822 k | 103 |
| Pastos banco B | 1,31 | 242 (145) | 453 k | 2,0 | **0,02 / 1 %** | 799 k | 98 |
| Pastos ruinas | 1,55 | 125 (77) | 356 k | 3,3 | 0,65 / 11 % | 598 k | 49 |

- **Lo que distingue al Gran Bosque no son llamadas, vértices ni materiales** (Pastos tiene más de las tres cosas y va a
  30 en medio), sino **lo recortado**: sombreados con `discard`/alfa recortado cubren el 42-70 % de la pantalla con
  hasta 3,8 capas (Pastos: 1-24 %, ≤ 1,9). En el Mali-G57 eso cuesta mucho más que en el PC: el Mali Offline Compiler
  marca esos sombreados con «ZS tardío» y «modifica la cobertura» (§1.3): no pueden tapar a nada con su eliminación de
  píxeles ocultos (FPK), escriben la profundidad tarde y obligan a sombrear cada capa hasta el descarte. Sin prepase
  (Godot no lo hace en Mali), cada capa recortada se rasteriza y se sombrea.
- **Qué es lo recortado, en la entrada de medio:** las copas de hojas, **3,17 capas** sobre el 40 % de la pantalla (en
  bajo, 0,99 sobre el 18 %: en bajo solo los árboles viejos llevan hojas); troncos y pinos con el tramado del hueco, 0,42
  sobre el 26 %; el agua (máscara con discard), 0,14 sobre el 10 % (en el puente, 0,62 sobre el 70 %).
- **La sombra del sol en medio:** +75 llamadas y +100 k primitivas en la entrada (mapa de sombras y la pasada aditiva:
  en Compatibility el sol con sombra se dibuja en una **segunda pasada** por objeto, `USE_ADDITIVE_LIGHTING` en la
  plantilla de escena). Igual que en Pastos.
- Kael, Lya y Garon: 180 k vértices que también dan sombra (60 k cada uno). Igual en todas las regiones.
- Sotobosque, hierba, haces, partículas: ≤ 0,2 capas, poco.

### 1.3 Coste estimado de los sombreadores en el Mali-G57 (Mali Offline Compiler) [E, estimación estática]

`pruebas/herramientas/malioc/`: `extraer_plantillas.py` saca del ejecutable de Godot las plantillas GLSL de escena de
Compatibility y `estimar_malioc.py` arma el GLSL ES 3.0 de cada material del Gran Bosque (traducción aproximada, la de
Godot no es idéntica letra a letra) para cada pasada que usa el juego y lo pasa por `malioc -c Mali-G57`. Ciclos por
fragmento del camino más largo (en bajo, la pasada base tiene un bucle de luces de longitud desconocida: ciclos totales).
Tabla completa: `...\rend2\malioc\malioc_tabla.txt`.

| Sombreador (fragmento) | bajo, base | medio, base | medio, sol con sombra | ZS tardío |
|---|---|---|---|---|
| Copas de hojas (hoy) | 12,75 | 7,78 | 6,22 | sí |
| … antes del 12/11 (hueco píxel a píxel) | 14,00 | 9,02 | 7,47 | sí |
| … sin brillo (`gb_hojas_sin_brillo`) | 11,88 | 7,78 | **5,40 (−13 %)** | sí |
| … ligeras (`gb_hojas_ligeras`) | 10,77 | 7,78 | **3,75 (−40 %)** | sí |
| Copas macizas | 14,00 | 9,90 | 7,31 | no |
| Troncos y pinos con tramado | 15,25 | 11,15 | 8,56 | sí |
| … sin tramado | 14,00 | 9,90 | 7,31 | no |

- En medio, cada fragmento visible de hoja paga las dos pasadas (7,8 + 6,2 ciclos); el sombreado de vértices de todo el
  follaje está limitado por carga/guardado (8 ciclos de posición y 13-15 de varyings por vértice: lecturas de los bloques
  de uniformes de Godot), igual en Pastos.
- Con 2 núcleos a ~950 MHz y 30 FPS el Mali tiene ~63 M ciclos por fotograma; a 1920×864 (escala 0,8), cada capa de un
  sombreado de ~8 ciclos sobre toda la pantalla son ~13 M. Es una cuenta gruesa, pero explica que 3-4 capas de hojas
  recortadas en media pantalla y dos pasadas no quepan [?].

## 2. Gran Bosque: lo cambiado

### 2.1 Orden de dibujo de lo opaco (encendido) — `escenario.gd`, `_materiales`, `_crear_terreno`, `_crear_agua`

Con `render_priority` (en lo opaco de Compatibility, **mayor = después**; medido: al revés salía un 15 % peor): primero
las copas macizas y los núcleos (−1), luego lo demás opaco (0), después lo recortado —copas de hojas, troncos y pinos
con tramado— (1) y al final el suelo y el agua (2). Lo que tapa escribe antes la profundidad y los fragmentos de detrás
se rechazan antes de sombrearse; el suelo, que queda detrás de casi todo, ya no se sombrea bajo las copas.

**Misma imagen** [E]: con el tiempo parado (`medir_gpu_bosque.gd igualdad`: personajes, partículas y viento quietos) se
capturan dos fotogramas seguidos con el orden (ruido: 0 píxeles salvo un parpadeo de 40 en la entrada) y uno sin él:
cambian **4-395 píxeles sueltos de 921 600** en los 24 sitios y perfiles, empates de profundidad entre piezas
coplanarias. Composiciones (antes | después | píxeles que cambian) en `...\rend2\capturas\orden\`.

GPU del PC (sin prepase, 3D ×2, mediana de 60 fotogramas, 2 pasadas intercaladas; `...\rend2\gpu_orden2\`, alto en
`...\rend2\gpu_casco\`):

| Sitio | bajo antes → después | medio antes → después | alto antes → después |
|---|---|---|---|
| entrada | 0,88 → 0,82 | 1,40 → 1,34 | 6,11 → 5,92 |
| puente | 0,77 → 0,72 | 1,09 → 1,02 | 6,55 → 6,13 |
| ruinas | 0,80 → 0,77 | 1,19 → 1,16 | 6,21 → 6,06 |
| campamento | 0,75 → 0,75 | 1,12 → 1,13 | 4,91 → 4,98 |
| claro | 0,79 → 0,78 | 1,18 → 1,15 | 5,62 → 5,44 |
| altar | 0,76 → 0,75 | 1,21 → 1,16 | 5,40 → 5,16 |
| bosque cerrado | 0,74 → 0,71 | 1,09 → 1,08 | 5,78 → 5,59 |
| **mirador** | **1,20 → 0,99** | **1,76 → 1,38** | **10,51 → 8,98** |

En el PC (que sí rechaza pronto lo tapado) la ganancia es modesta salvo donde se ve mucho suelo y bosque a la vez (el
mirador). En el Mali el orden pesa más (sin FPK para lo recortado) [?]: **hay que medirlo en el Redmi**.

Probado y quitado: ordenar las matas de cada copa de arriba abajo (sin efecto medible en el PC).

### 2.2 Matas recortadas a un octógono (APAGADO: `gb_matas_casco`)

Lo opaco de cada celda del atlas `modelos/hojas/matas.png` es solo el 26-42 % del cuadro de la mata; el resto se
rasteriza y se descarta. `_casco_matas` cambia cada cuadro por el octógono que contiene todo lo opaco de su celda
(alfa ≥ 100/255 y 3 % de margen; 61-68 % del cuadro; `pruebas/herramientas/casco_matas.py`), partido por la diagonal
del cuadro para interpolar cada atributo con los pesos de su triángulo original. 4 veces más vértices en las copas de
hojas (5,8 k → 23 k en la entrada: nada al lado de los 576 k opacos).

- **Fragmentos** [E] (recuento, medio, entrada): copas de hojas 3,16 → **2,14 capas (−32 %)**; total 5,26 → 4,22.
- **GPU del PC** [E] (2 pasadas intercaladas): medio −1-3 % (entrada 1,36 → 1,33, mirador 1,40 → 1,35); alto −8-18 %
  (ruinas 6,06 → 4,96, puente 6,13 → 5,43); bajo −2-30 % (con mucho ruido en esa pasada).
- **No es la misma imagen al píxel** [E]: con el tiempo parado cambian 10 000-35 000 píxeles en medio (hasta 60 000 en
  alto, 0-17 000 en bajo). El viento del sombreado mueve cada vértice según su sitio (no es lineal: los vértices nuevos
  no caen donde caía la interpolación del cuadro) y la normal se guarda normalizada. Se ve como hojas desplazadas un
  poco o con otra luz, sin que se note cuál es cuál (`...\rend2\capturas\matas_recortadas\`: cuadros enteros |
  recortadas | píxeles que cambian). Por la regla de «capturas iguales», **va apagado**; es la candidata más clara para
  el medio del Redmi.
- `prueba_casco_matas` (al final de la lista): todo lo opaco del atlas, con texel y medio de margen, cabe en su
  octógono; el recorte conserva posición, UV, color, centro y sentido de giro; apagado, la malla no cambia.

### 2.3 Lo que queda y no se ha tocado

- **Alternativas ya programadas y apagadas** para el medio (de antes): `gb_hojas_sin_brillo` (malioc: −13 % en la
  pasada del sol de las hojas), `gb_hondo: 0.68`, `gb_hojas_ligeras` (−40 %, se ven más planas).
- **El atlas de matas no tiene mipmaps** (`compress/mode=0`, `mipmaps/generate=false`) aunque el sombreado pide
  `filter_linear_mipmap`: a distancia se leen texels sueltos de una textura de 1024² (caché de texturas del Mali y
  centelleo). Con mipmaps cambia el aspecto (hojas más finas a lo lejos con alfa recortado): no aplicado; propuesta.
- **Troncos y pinos con tramado**: el `discard` del hueco está en todo su sombreado aunque solo actúa cerca de la línea
  cámara-Kael. Se podría poner el material sin tramado a los trozos lejos de esa línea (misma imagen, sin ZS tardío).
  No hecho (poca superficie: 0,4 capas).
- **El suelo** es una sola malla (111 k índices) que nunca se recorta: partirla en trozos ahorraría vértices fuera de
  cámara. No hecho (vértices, no fragmentos).

## 3. Primer combate: tirones [E]

Sonda nueva `pruebas/herramientas/sonda_tirones_combate.gd` (con ventana; turno de Kael; mide la llamada y los
fotogramas siguientes de la primera y la segunda lista de objetivos y del primer y segundo ataque de verdad).

- **El «52-67 ms» del informe anterior venía en parte de la herramienta**: `medir_escenas.gd` no hace la carga común
  de `carga.gd`, así que el primer golpe leía del disco cosas que en el juego ya están en memoria. Sin la carga común,
  el primer ataque tardaba 37-49 ms en la llamada; **con la carga común (`con_carga`, como el juego), 11,8-13,9 ms**, casi
  todo en `_lya_sabe()`, que hacía `load("res://investigacion.gd")` (compilar el guion y leer el catálogo de
  investigaciones) en mitad del primer ataque. El primer número de daño y su destello no daban tirón medible.
- **Arreglo** (`combate.gd`, `_precalentar_2d`, llamado junto a `_precalentar_efectos` en `_ready`; ~40 líneas, sin
  reorganizar nada): mira ya la ventaja de Lya y dibuja una vez, en una SubViewport que no se ve, los textos que salen
  la primera vez (números con contorno a 46, 58, 34 y 28; panel de objetivos con sus fuentes; nombre apuntado a 44) y un
  destello y unas chispas con el material aditivo.
- **Resultado** (con la carga común, 3 pasadas intercaladas, `...\rend2\combate\sonda_*_ab_*.json`):
  - primer ataque: llamada **11,8 / 13,9 / 13,9 → 0,7 / 0,3 / 0,7 ms**;
  - primera lista de objetivos (llamada + primer fotograma): **19,6 / 21,0 / 20,2 → 11,7 / 10,3 / 18,8 ms** (la segunda
    vez, 7-10 ms; la tercera pasada «después» tuvo el PC más cargado: fotograma normal 7,4 frente a 4,0);
  - el `_ready` del combate, dentro del aviso de carga: 260-300 → 294-362 ms (+~30 ms, con ruido).
- «sin_precalentar_2d» (argumento o meta) lo quita para medir el antes.

**Con `medir_escenas.ps1`** (sin la carga común; combate de tres de Pastos y de Bramavidrio, medio, 2 ciclos, 2 pasadas
intercaladas, `-Extra sin_precalentar_2d` para el antes; `...
end2\medidas\combate\`):

| | Tirones del combate 1 (> 50 ms), antes | Después |
|---|---|---|
| Combate de tres, pasada 1 | fotograma 106: 87 ms (lista de objetivos del ataque automático); 210: 126 ms (primer golpe) | 210: 67 ms |
| Combate de tres, pasada 2 | 106: 83 ms; 210: 93 ms | 210: 57 ms |
| Bramavidrio, pasada 1 | 106: 90 ms; 210: 92 ms | 210: 65 ms |
| Bramavidrio, pasada 2 | 106: 64 ms; 210: 92 ms | 210: 65 ms |

- El de la lista de objetivos desaparece; el del primer golpe baja un 30-45 % pero queda en esta herramienta, que lee del
  disco lo que el juego ya tiene en memoria (sonidos, texturas). Con la carga común (la sonda) el primer golpe no da
  ningún fotograma de más de 13 ms. **A confirmar en el Redmi** (§7).
- Queda, fuera de mi encargo, el tirón de 115-137 ms al volver del combate (`tras_volver`, fotograma ~70): crea el retrato
  de Dialogic (`RetratoVivo`) del comentario del grupo.
- Cargas del combate y vuelta: iguales dentro del ruido (el PC estaba muy ocupado: la vuelta a Pastos 1351-1596 →
  1497-1711 ms y a Bramavidrio 986-1387 → 1191-1246 ms, en las dos direcciones).

**Gran Bosque con `medir_escenas.ps1`** (`...
end2\medidasntes|despues\`): dibujos (96 / 176 / 266) y primitivas
(192 k / 300 k / 566 k) iguales en bajo/medio/alto, sin tirones en ninguna; los tiempos de carga y de fotograma de la
pasada «después» salieron peores en todo (carga repetida de medio 966-1193 → 1069-1177 ms; de bajo 728-735 → 1125-1210)
porque la hicieron con decenas de Godot y Blender de otros especialistas a la vez (`procesos.txt`): no se pueden
comparar. El orden de dibujo no cambia nada de la CPU (solo `render_priority`, que ya entraba en el orden de la lista).

## 4. Creación del grupo [E]

Sonda `pruebas/herramientas/sonda_grupo.gd`: crear Kael, Lya y Garon (como `grupo_3d.gd`), tres veces.

| | Kael | Lya | Garon |
|---|---|---|---|
| Sin la carga común (como medir_escenas) | 80 / 40 / 46 ms | 33 / 26 / 27 | 60 / 52 / 49 |
| **Con la carga común (como el juego)** | 40 (+47 de compilar su guion) / 2 / 2 | 2 (+1) / 1 / 1 | 5 (+32) / 3 / 3 |

Los **160-230 ms** del informe anterior eran sobre todo la carga de modelos que en el juego ya están en memoria. Con la
carga común, crear el grupo cuesta ~5-10 ms; lo que quedaba era **compilar los guiones** de los personajes la primera vez
(~80 ms, con la pantalla tapada al entrar en la primera región): ahora se precargan (§5.2).

## 5. Arranque

### 5.1 Lo que se precargaba sin usarse (encendido) [E]

`recursos.gd`, `APAGADOS`: Humbaba (`enemigos/humbaba/`, interruptor `humbaba_v12`, ~12 MB en disco: tres GLB y la
madera) y «Pastoral Pulse» (3 MB, solo si se elige en Ajustes) se cargan al encenderlos, con la pantalla tapada, como
lo demás de esa lista. Portada (`medir_escenas titulo`, medio, 3 pasadas intercaladas, `...\rend2\arranque\medidas\`):
memoria estática **200 → 191 MB**, de vídeo **278-284 → 269 MB**, recursos 6877 → 6777; carga hasta «TOCA PARA EMPEZAR»
13,7-15,7 → 12,7-14,1 s (con el PC muy ocupado por otros: no es concluyente).

Reparto de lo precargado (`...\rend2\arranque\precarga_resumen.txt`; hay además `pruebas/herramientas/listar_precarga.gd`
de antes): 879 archivos, 209 MB importados; PNG 110 MB, WebP 20, JPG 16, WAV 15, OGG 14, GLB 14. Lo más grande que se
usa siempre (música de combate MP3 de 6,9 MB, texturas de Kael/Garon/goblin, Zarzalín, la canción del título) se deja:
quitarlo crearía cargas o tirones después.

### 5.2 Guiones que se compilaban en mitad del juego (encendido) [E]

Sonda `pruebas/herramientas/sonda_guiones.gd`: tras la carga común quedaban 64 guiones sin cargar (1,46 s de compilar
en total en el PC). Los que se cargan con `load()` al abrir algo en pleno juego daban un tirón la primera vez: **el menú
del mapa 112 ms**, tienda 65, alquimia 65, Diario 37, gremio 36, parejas de la taberna 32, botica 26; y los de los
personajes y el grupo (Kael 22, Garon 33, Lya y gestos 13, grupo 25) al entrar en la primera región. En el Mali-G57 la CPU
es varias veces más lenta [?]. `recursos.gd`, `GUIONES_RESIDENTES`: `listar()` los añade y `carga.gd` los carga en segundo
plano con lo demás. Arranque (3 pasadas intercaladas): 11,8-12,2 → 11,3-12,7 s (igual dentro del ruido); +2 MB de
memoria estática. Tras el cambio quedan 50 guiones (1,14 s), casi todos de regiones (se compilan con su escena, con la
pantalla tapada) y prototipos apagados.

## 6. Pruebas

- **Batería final** sobre `d8b11ce` (`...end2\pruebas6-11-12_203017esumen.md`): **23 · 0 · 0 · 0**:
  `prueba_gran_bosque3d`, `prueba_casco_matas` (nueva), `prueba_precarga`, `prueba_cargas`, `prueba_precalentado`,
  `prueba_escenas`, `prueba_zona3d`, `prueba_grupo3d`, `prueba_grupos_combate`, `prueba_combate_huella`,
  `prueba_combate_seguro`, `prueba_huir`, `prueba_ia`, `prueba_equilibrio`, `prueba_hud_combate`,
  `prueba_humbaba_modelo`, `prueba_humbaba_combate`, `prueba_bramavidrio_combate`, `prueba_guardian_bosque`,
  `prueba_musica`, `prueba_oakhaven`, `prueba_guardado`, `prueba_partida`. Partida real, carpeta real de datos y proyecto
  sin cambios.
- Antes, sobre los commits intermedios: 14/14 y 13/13 más (`2026-11-12_195745`, `_200935`; en la segunda,
  `prueba_gran_bosque3d` falló porque corrió mientras `escenario.gd` tenía un error de análisis que corregí al momento;
  repetida en la final, superada).
- No se ha pasado la batería completa (más de 200 pruebas) ni las de «ventana».

## 7. Para validar en el Redmi (sin hacer: no hay teléfono)

1. **Gran Bosque en medio** (v649: 21,3 / 23,1 / 24,6 FPS en entrada / andando / lejos): FPS con el orden de dibujo, en
   la entrada, andando, el mirador y el claro. Lo esperado: mejora sobre todo donde se ve mucho bosque (mirador, lejos).
2. **Si no llega a 30**, uno a uno, en la entrada y el mirador (por `calidad_extra` o metiéndolos en el perfil medio):
   `gb_matas_casco` (misma escena, un tercio menos de fragmentos de hojas; mirar a ojo las copas cerca de la cámara),
   `gb_hojas_sin_brillo`, `gb_hondo: 0.68`, `gb_hojas_ligeras`. Apuntar FPS y mirar si se nota.
3. **Streamline** (cuando se pueda), Gran Bosque medio frente a Pastos medio en el banco: ciclos de fragmento, «ZS
   tardío/killed», FPK, primitivas del tiler y ciclos de vértice. La hipótesis de este informe es que el Gran Bosque
   pierde por los fragmentos recortados (hojas) en las dos pasadas del sol.
4. **Gran Bosque en bajo**: que siga a 30 (v649: 30,4) y nada cambiado a la vista.
5. **Primer combate** de la partida: sin parón al tocar «Atacar» (lista de objetivos) ni en el primer golpe; mirar con
   `--timestats` o gfxinfo que no haya fotogramas de > 50 ms.
6. **Primera vez que se abre el menú del mapa**, la tienda, la alquimia y el Diario: sin parón.
7. **Arranque**: tiempo hasta «TOCA PARA EMPEZAR» y PSS (v649: 19,2 s de carga, ~1,0 GB): no debe crecer por los
   guiones; debe bajar algo de memoria por Humbaba y Pastoral Pulse.
8. Con **Humbaba encendido** (`humbaba_v12`): entrar en el Gran Bosque y su combate; ahora sus modelos se cargan al entrar.

## 8. Herramientas nuevas o ampliadas

- `pruebas/herramientas/medir_gpu_bosque.gd`: «recuento» (por categoría y tipo de material) e «igualdad» (capturas con el
  tiempo parado: con orden, sin orden y con cuadros enteros).
- `pruebas/herramientas/malioc/` (`extraer_plantillas.py`, `estimar_malioc.py`): coste estimado en el Mali-G57.
- `pruebas/herramientas/sonda_tirones_combate.gd`, `sonda_grupo.gd`, `sonda_guiones.gd`, `casco_matas.py`.
- `pruebas/prueba_casco_matas.gd` (en la lista).

## 9. Archivos

NUEVOS: `aethelgard/pruebas/prueba_casco_matas.gd`, `aethelgard/pruebas/herramientas/sonda_tirones_combate.gd`,
`sonda_grupo.gd`, `sonda_guiones.gd`, `casco_matas.py`, `malioc/extraer_plantillas.py`, `malioc/estimar_malioc.py`, este
informe.

COMPARTIDOS modificados: `aethelgard/zonas3d/gran_bosque/escenario.gd`, `aethelgard/combate.gd` (solo
`_precalentar_2d` y su llamada), `aethelgard/recursos.gd` (`APAGADOS` + `_encendido`, `listar` + `GUIONES_RESIDENTES`),
`aethelgard/pruebas/herramientas/medir_gpu_bosque.gd`, `aethelgard/pruebas/lista_pruebas.txt` (una línea al final).

Sin tocar: `carga.gd` (usa `Recursos.listar()` tal cual), `grupo.gd`, `equipo_extra.gd`, `inventario.gd`, `menus.gd`,
Oakhaven 3D, los guiones de los personajes.
