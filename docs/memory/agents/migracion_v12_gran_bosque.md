# Migración 3D, V12 fase 2 · región 4: el Gran Bosque Verde (lugar 1)

## 12/11/2026 · rama `claude/v12-fase2-gran-bosque` (LOCAL, desde `claude/rebelum-v12` @ `cc3557d`), copia `D:\Aethelgard_v12_gran_bosque`

Encargo: el Gran Bosque Verde (hasta hoy solo la zona 2D generada, `zona.tscn` con el lugar 1, estilo «bosque») en 3D,
con el kit de Pastos Verdes pero con identidad propia, **sin perder ningún sistema de la 2D**, sin inventar ubicaciones ni
historia; por defecto solo si todo está y pasa, con la 2D elegible. Sin push ni merge. Todo con datos aislados
(`ejecutar_pruebas.ps1`, o `APPDATA`/`LOCALAPPDATA`/`TEMP` a una carpeta temporal para `--import` y los guiones sueltos);
`partida.save` real sin cambios en todas las pasadas. La primera importación de la copia vació los directorios de
Dialogic de `project.godot` (como avisaba RETOMAR): `git restore` y reimportar; después, `project.godot` sin cambios.
No se tocaron `combate*.gd`, `grupo.gd`, `artes.gd`, `magia_negra.gd`, `inventario.gd`, `grupo_3d.gd`, `enemigos/`,
`personajes/`, `sonido.gd`, `musica.gd` ni otras zonas.

Leyenda: **[C]** observado en el código · **[E]** comprobado ejecutando (aislado, PC) · **[?]** pendiente.

### 1. Inventario exacto de la 2D [C] y qué hay en la 3D

| Sistema de la 2D (`zona.gd` con el lugar 1) | 3D (`zonas3d/gran_bosque_3d.gd`) |
|---|---|
| **Acceso:** mapa, lugar 1 «Gran Bosque Verde» (`mapa.gd:42`) → `zona.tscn`; `Engine «lugar»` = {indice 1, zona «bosque», texto del mapa} | El mapa lleva a la 3D con la exploración 3D (`modo3d.escena_de(1)`); la escena pone el mismo «lugar» en Engine [E] |
| **Trazado** (semilla 1000 + 1·7919 = 8919; 80 × 56 casillas): camino del sur al altar del norte, tres ramas a las ruinas, el campamento y el claro; un río con dos puentes; 15 charcas; muros con linde de árboles; 1 113 objetos (652 árboles, helechos, setas, matas, flores, rocas, columnas…) | **El mismo**, leído de `zonas3d/gran_bosque/disposicion_2d.gd` (volcado de `zona.gd` con `pruebas/herramientas/volcar_bosque_2d.gd`) a 1,25 m por casilla: mismos caminos, rincones, río y charcas (su máscara), puentes y cada árbol en su casilla [E parte 0] |
| **Encuentros:** por pasos (20 px), 40 seguros, 0,012, zona «bosque» (nivel 4, `progreso.gd`), tabla genérica de `combate.gd` (`GRUPOS_AL_AZAR`), fondo «bosque», élites | Igual: paso de 0,3125 casillas × 1,25 m, mismas constantes, `Engine «zona» = "bosque"`, combate con vuelta al mismo sitio [E parte 8] |
| **Cofres generados** (3): ruinas `1_3004_2814`, campamento `1_1339_2335`, claro `1_1541_1723`; premio por `hash(id)` (40-120 monedas, 2 Pociones o 1 Éter), una vez | Los 3 con **sus ids** y **el mismo premio** (comprobado abriendo cada uno en la 2D y en la 3D desde la misma partida); abierto en una, abierto en la otra [E parte 4] |
| **Detalle** `bosque_armadura` (Acto I) en las ruinas: texto, página del Diario con el acto | El árbol que abraza la armadura (caballero sentado contra el tronco, el brazo izquierdo de oro hasta el suelo, la corteza que lo envuelve): texto, `ver_detalle`, página del acto [E parte 6] |
| **Hallazgo** «Hoja sin Nombre» (`hall_hoja_sin_nombre`, al examinar el detalle) | Con `zonas3d/examinables_3d.gd`: la hoja se ve entre las raíces mientras falta; una vez, guardada, desaparece; compatible en los dos sentidos [E parte 6] |
| **Hallazgo** «Diente de Grimfang» (`hall_diente_grimfang`, cofre junto al campamento) | Su cofre junto al campamento (algo apartado: en el sitio de la 2D caería sobre un tronco), una vez [E parte 5] |
| **Altar** del final del camino (orbe verde): al examinarlo, el texto del lugar y su hallazgo «altar» (ninguno en el lugar 1) | Altar de piedra con el orbe verde que flota y su luz; mismo texto y misma llamada a hallazgos [E parte 7] |
| **Brazalete** cerca del detalle sin ver (260 px) | A 5 m, se rearma al alejarse ×1,6; sonido y destello en la muñeca [E parte 6] |
| **Comentarios** del grupo: al llegar (clave «@lugar:1») y tras un cofre | Los mismos momentos y la misma clave |
| **Incienso de Ceniza** | Igual (`paso_incienso`) |
| **Música/ambiente:** contexto «bosque» (`musica.gd:133`) | El mismo ambiente; ver §6 (falta una línea en `musica.gd`) [E parte 3] |
| **Sonido:** pasos (hojas en el bosque, grava en el camino, madera en los puentes), el río | Lo mismo (`trazado.suelo`), el arroyo en los puentes y la hoguera del campamento (`fogata_bucle`) |
| **Clima:** hojas que caen, rayos de luz, luz ambiente verde | Hojas que caen alrededor de Kael, haces de luz en los claros, bruma verde y manchas de sol |
| **Guardado:** al entrar, tras un hallazgo, al pausar (`guardar_posicion`), tras cada combate | Al entrar, tras cofres, hallazgos y detalle nuevo, al pausar y tras cada combate [E partes 3-9] |
| **Salida:** el borde sur (o el botón «MAPA DEL MUNDO») | El pie del camino, señalado (disco, letrero «Mapa del mundo» y postes), como las otras regiones 3D [E parte 11] |
| NPC, misiones, Dialogic | No hay en la 2D; tampoco en la 3D |

**Notas del inventario:**
- `bosque_armadura` **no es un combate ni un evento**: es el detalle de lore (`progreso.gd:29-30`). No hay combate fijo en el
  Gran Bosque.
- **El texto del mapa promete lo que no existe** («Santuario profanado donde Lya protege el Núcleo de la Naturaleza»,
  `mapa.gd:43`): no hay santuario, Lya no está aquí y no hay Núcleo. **No se ha inventado nada de eso.** La 2D enseña ese
  mismo texto al examinar el altar y la 3D lo mantiene igual (paridad). Decisión de narrativa pendiente: cambiar el
  texto o crear ese contenido.
- **Rarezas de la 2D que la 3D corrige sin cambiar nada guardado:** el agua de la orilla toca el camino junto a los dos
  puentes (en la 2D se pasa rozando, `_peso ≤ 0,55`) y la rama del claro cruza un brazo del río que su puente no cubre (en
  la 2D hay que rodear por el bosque). En la 3D los puentes son 1,5 casillas más largos por cada lado y hay una pasarela
  donde el camino aún pisaba agua (`trazado.puentes_3d`).
- El botón «MAPA DEL MUNDO» de la 2D no está (ninguna región 3D lo tiene: se sale andando por el sur).

### 2. La región 3D: identidad propia

- **Archivos:** `zonas3d/gran_bosque_3d.gd/.tscn` (la región: Kael, cámara, sistemas, interfaz), `zonas3d/gran_bosque/`
  `trazado.gd` (casillas ↔ metros, relieve, agua, lo que no se pisa, puentes, partidas), `escenario.gd` (todo lo que se
  ve) y `disposicion_2d.gd` (generado).
- **Más denso y antiguo que Pastos:** los 652 árboles de la 2D en su sitio, más altos lejos del camino, con raíces; nueve
  **árboles viejos** que enmarcan la entrada, el puente, el claro, el campamento y el altar; sotobosque de helechos, setas
  y matas (más que la 2D, junto a los caminos); una linde de bosque por fuera del borde para que nunca se vea el final.
- **Relieve:** lomas entre los caminos, el borde que sube, el cauce y las charcas hundidos, el camino algo gastado y la
  **loma del mirador** (2,6 m, con una rampa desde el camino, la ladera no se sube) al este, entre el puente y el altar.
- **Caminos naturales:** tierra pisada con el borde roto, piedras planas sueltas; los puentes de madera con barandilla
  sobre el agua.
- **Agua:** el arroyo y las charcas con la forma de la 2D (máscara suavizada; la orilla no sale en escalones), oscura,
  con brillos que se mueven y la orilla más clara.
- **Luz filtrada:** manchas de sol pintadas en el suelo bajo las copas (desplazadas según el sol; más suaves con
  sombras reales), haces de luz en los claros (3/5/7 por perfil), bruma verde, luz verdosa de rebote.
- **Animales sencillos:** conejos (huyen de Kael), pájaros que planean, mariposas en el claro, luciérnagas en el altar y
  las ruinas (`prototipos/fauna_simple.gd`).
- **Lugares reconocibles, cada uno con su motivo:** la linde de la entrada (dos troncos caídos), las ruinas con el árbol
  de la armadura (el detalle y la Hoja), el campamento con su hoguera, troncos y dos cofres (el suyo y el Diente), el claro
  al sol (su cofre), los puentes, el altar del fondo (el texto del lugar) y el mirador (la cámara sube y se aleja: se ve
  el bosque desde arriba; sin texto nuevo).
- **No duplica «El bosque que no recuerda»** (Pastos): ni Guardián, ni manantial, ni orbe de los futuros, ni sus pistas.
- **Copas que no tapan a Kael:** un hueco en forma de cono entre la cámara y Kael, y lo que está muy cerca de la cámara,
  con disolución tramada (sombreado; vale para los MultiMesh, que no se pueden volver transparentes por pieza).

### 3. 3D por defecto, 2D elegible, partidas

- `modo3d.gd`: `GRAN_BOSQUE := 1` en `REGIONES` y en `POR_DEFECTO_2D_ELEGIBLE` (`["granbosque3d", "granbosque2d"]`).
  Sin nada en `user://ajustes.cfg` → 3D; `[regiones] granbosque3d = false` → 2D; argumento `granbosque2d` → 2D
  (`granbosque3d` manda). Sin la exploración 3D (APK estable), nada cambia [E parte 1].
- **Equivalencia de `zona.tscn` por lugar** (la 2D del bosque es la zona generada, compartida por varios lugares):
  `EQUIVALENTES_ZONA := [GRAN_BOSQUE]` y `escena_equivalente(escena, lugar)`; `progreso.gd` le pasa el índice del lugar
  de la partida (1 línea). Las de Oakhaven generada, Sunken City y el Mar de Arena 2D siguen igual [E parte 2,
  `prueba_restaurar_escenas`].
- **2D → 3D:** la misma casilla (`posicion_desde_2d`); si cae en agua o en la ladera del mirador, el camino más cercano.
- **3D → 2D elegida:** la misma casilla si en la 2D se puede estar (tierra del camino o de un rincón, sin agua, sin muro
  y fuera del choque de los objetos: `zona.gd` no lo comprueba al cargar); si no, la más cercana que sí. Si la partida no
  trae «lugar», se pone el del bosque. Comprobado con 398 posiciones [E parte 2].
- **Ajustes** (`menus.gd`, bloque marcado «V12, migración del Gran Bosque Verde»): «3D» / «2D (la de siempre)», como la
  Garganta y Oakhaven.
- **Por defecto: sí.** Todo lo de la 2D está (§1) y las pruebas pasan (§5).

### 4. Rendimiento en el PC (1280×720, RTX 3050 portátil; `pruebas/fotos_gran_bosque3d.gd`, 12/11)

Llamadas de dibujo · primitivas, media de 40 fotogramas en cada sitio (cámara de juego, 17 m):

| Sitio | Bajo | Medio | Alto |
|---|---|---|---|
| Entrada | 99 · 193 k | 176 · 292 k | 273 · 566 k |
| Puente | 48 · 153 k | 91 · 248 k | 224 · 552 k |
| Ruinas y armadura | 96 · 181 k | 172 · 282 k | 282 · 572 k |
| Campamento | 74 · 174 k | 129 · 274 k | 206 · 517 k |
| Claro | 77 · 179 k | 136 · 279 k | 227 · 540 k |
| Altar | 75 · 212 k | 121 · 311 k | 180 · 536 k |
| Mirador (cámara a 27 m) | 77 · 213 k | 100 · 280 k | 216 · 639 k |
| Bosque cerrado | 82 · 180 k | 113 · 262 k | 252 · 580 k |

- Comparación (de sus informes, mismo PC): la Garganta 3D, bajo 59-166 · 146-183 k y medio 91-213 · 312-362 k; Pastos
  medio 174 · 373 k. El bosque queda en el mismo margen (la Garganta y Pastos van a 30 FPS en el Redmi en bajo y medio).
- **Qué se hizo para que quepa:** MultiMesh por trozos de 25 m con distancia de dibujo por perfil; copas macizas
  «pintadas» con las matas de Pastos (opacas, sin recorte) lejos del camino y en todo el bajo (las de hojas, solo en los
  nueve árboles viejos); en medio, copas de hojas a ≤ 4,5 casillas del camino, troncos sencillos y la sombra de cada copa
  con una bola de 36 triángulos; el suelo no da sombra (salvo en alto); sin luces reales en bajo y medio (halo pintado);
  menos helechos y haces en bajo. Medido durante el trabajo: de 340-458 k a 248-311 k en medio.
- **Montar la escena:** ~0,7 s en el PC (rejilla de alturas 0,19 s una vez por proceso; suelo 0,23 s). En el Redmi
  será más (**sin medir**).
- El tiempo por fotograma del PC (3-6 ms) no dice nada del Redmi (limitado por la GPU).

### 5. Pruebas (aisladas, PC, 12/11)

- **`prueba_gran_bosque3d`** (nueva, partes 0-11): superada [E].
- **Zona, guardado y vecinas:** `prueba_zona3d`, `prueba_integridad`, `prueba_guardado`, `prueba_guardado_protegido`,
  `prueba_guardado_fallos`, `prueba_partida`, `prueba_restaurar_escenas`, `prueba_hallazgos`, `prueba_musica`,
  `prueba_comentarios`, `prueba_efectos`, `prueba_garganta3d_examinables` y `prueba_oakhaven3d_completo`: 14 de 14
  superadas (`D:\REBELUM_diagnostico\pruebas\2026-11-12_034424`).
- **Batería completa:** 126 · 0 · 57 · 0 (§7).
- **Capturas:** `D:\REBELUM_diagnostico\migracion\2026-11-12_gran_bosque\capturas\` (bajo, medio y alto en 10 sitios, con
  `medidas_*.json`), el plano de la 2D (`bosque_2d_plano.png`) y las iteraciones `iter1`…`iter8` (el antes y el después
  de cada cambio de aspecto y de coste).

### 6. Pendiente

- **Redmi (sin probar):** medir bajo y medio en la entrada, las ruinas, el altar y el mirador; mirar la disolución tramada
  de las copas cerca de la cámara (en el PC se ve como grano en los bordes de la pantalla), el brillo del bajo
  (`brillo_sin_sombras` = 1,18, sin medir con `medir_luz_perfiles.gd`) y el tiempo de carga.
- **`musica.gd`** (no es mío): añadir `"res://zonas3d/gran_bosque_3d.tscn"` al contexto «bosque» de `contexto_de`. Mientras
  tanto la escena pide el ambiente ella misma (`_musica`, solo si el contexto es «silencio»).
- **Narrativa:** el texto del mapa del lugar 1 (Lya, el Núcleo, el santuario profanado) no corresponde a nada jugable.
- **Fauna:** conejos y pájaros de primitivas (`fauna_simple.gd`), como en Pastos.
- La armadura es de primitivas (cápsulas): con la metodología de Blender, un modelo propio sería mejor.

### 7. Batería completa

- Sobre `139ffa6` (`D:\REBELUM_diagnostico\pruebas\2026-11-12_034759`): **126 · 0 · 57 · 0** (antes de esta rama, la
  última conocida era 124 · 0 · 55 · 0: +2 por las dos líneas nuevas de `lista_pruebas.txt`). `partida.save` real y carpeta
  real de datos sin cambios. El «proyecto cambiado» es este informe, escrito durante la pasada. Había Godot de otras
  copias abiertos (otros especialistas): no estorban, solo se vigilan.

### 8. Archivos para integrar (copiando, sin fusionar)

- Nuevos: `aethelgard/zonas3d/gran_bosque_3d.gd` (+ `.uid`), `gran_bosque_3d.tscn`, `aethelgard/zonas3d/gran_bosque/`
  (`disposicion_2d.gd`, `trazado.gd`, `escenario.gd`, + `.uid`), `aethelgard/pruebas/prueba_gran_bosque3d.gd`,
  `fotos_gran_bosque3d.gd`, `pruebas/herramientas/volcar_bosque_2d.gd` (+ `.uid`), este informe.
- Cambiados: `aethelgard/modo3d.gd` (GRAN_BOSQUE, EQUIVALENTES_ZONA, `escena_equivalente(escena, lugar)` y `_lugar_zona`),
  `aethelgard/progreso.gd` (1 línea en `restaurar`), `aethelgard/menus.gd` (solo el bloque marcado «Gran Bosque Verde»),
  `aethelgard/pruebas/lista_pruebas.txt` (dos líneas).
- `modo3d.gd` y `menus.gd` los tocan otros: copiar solo lo marcado si hay conflicto. `project.godot` sin cambios.
