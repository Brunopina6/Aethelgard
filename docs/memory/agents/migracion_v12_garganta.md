# Migración 3D, V12 fase 2 · región 1: la Garganta del Diablo (lugar 2)

## 12/11/2026 · rama `claude/v12-fase2-garganta` (LOCAL, desde `claude/rebelum-v12` @ `c703625`), copia `D:\Aethelgard_v12_garganta`

Encargo: llevar la Garganta 3D a ser la de por defecto **sin perder ningún sistema de la 2D** («No acepto una región
visualmente bonita si al convertirla desaparecen sus sistemas originales»). Sin push ni merge. Todo con datos aislados
(`ejecutar_pruebas.ps1` o `APPDATA`/`LOCALAPPDATA` a una carpeta temporal); `partida.save` real sin cambios en todas
las pasadas. No se tocaron `combate*.gd`, `artes.gd`, `grupo.gd`, `enemigos/`, `personajes/`, `sonido.gd`, `musica.gd`
ni otras zonas.

Leyenda: **[C]** observado en el código · **[E]** comprobado ejecutando (aislado, PC) · **[?]** pendiente.

### 1. Revisión 2D frente a 3D (auditoría §1.3 y código)

| Sistema | 2D (`garganta.gd` + `zona.gd`) | 3D antes | 3D ahora |
|---|---|---|---|
| Acceso desde el mapa | lugar 2 → `garganta.tscn` | solo con `garganta3d` | **por defecto** con la exploración 3D; 2D elegible [C][E] |
| Estructura P1-P8, palanca, levadizo, puerta, ascensor | sí | igual, mismos ids [C] | igual [E `prueba_garganta3d`] |
| Encuentros por pasos (ritmo de puentes y cornisas) | sí | igual (`T.ritmo`) | igual |
| Combates fijos: nido (grupo 6), Gorthor (grupo 5) | sí | sí, vuelta antes del disparo | igual [E] |
| Coloso de la Falla (grupo 12) | — | solo 3D | igual [E `prueba_coloso_garganta`] |
| Cofre raro del nido `2_1984_3238` | sí | mismo id y premio | igual [E] |
| Otros cofres | ninguno (la Garganta 2D sobrescribe la generación: solo el del nido) [C] | — | — |
| Detalles `garganta_puentes` y `garganta_pilar` (Acto I) | sí | sí | igual |
| **Hallazgo «Báculo del Peregrino»** (`hall_baculo_peregrino`) | al examinar el pilar (`zona.gd:2325`) | **faltaba** | **hecho** (§2) [E] |
| **Brillo del brazalete** cerca de un detalle sin ver (`zona.gd`, `_brazalete`) | sí (sonido «brazalete» y destello en la muñeca) | **faltaba** (no lo citaba la auditoría) | **hecho** (§2) [E] |
| Notas `dialogos/notas/garganta.gd` | **no enganchadas** | no enganchadas | **hechas en 3D** (§3) [E]; en la 2D siguen sin estar (§6) |
| Encargo de Ferro (pista y veta del Hierro de la Falla) | **no existe** | sí | igual [E `prueba_veta_garganta`] |
| Comentarios de los héroes (llegar, cascada, cofre) | llegar y cofre | sí, y la cascada | igual |
| Texto del lugar tras Gorthor («La arena guarda silencio…») | al examinar el altar de la arena | aviso al entrar en la arena | igual |
| Guardado: al entrar, altares, palanca, cofre, al pausar | sí | sí | igual, y tras hallazgo o nota nueva |
| Partida guardada dentro de la 2D | — | `escena_equivalente` → 3D en el sitio equivalente | igual [E `prueba_restaurar_escenas`, nueva] |
| Partida guardada en la 3D con la 2D elegida | — | abría la 3D | **abre la 2D por su entrada** (nuevo) [E] |
| Música y ambiente | `mazmorra` | `mazmorra` (`musica.gd:118`) y sonido 3D | igual |
| NPC y Dialogic | ninguno | `gg_veta` | igual |

### 2. El Báculo del Peregrino y el brazalete

- **Módulo común nuevo `zonas3d/examinables_3d.gd`** (para las siguientes regiones 3D): `hallazgo_pendiente`,
  `hallazgo_al_examinar` (usa `hallazgos.gd` tal cual: mismo id, se apunta en `cofres_abiertos`, avisos en cola, sonido
  «tesoro» y guardado), `avisos`, `nota_cerca` y `leer_nota` (usa `progreso.ver_nota`: `lore_visto`, aviso del Diario y
  guardado). La región solo necesita `_mostrar_aviso(texto, s)`, `guardar_posicion()` y `scene_file_path`.
- **En la Garganta 3D:** el báculo se ve apoyado en la cara oeste del pilar (madera clara, puño de cuero, el anillo
  partido en la punta, cinta roja y un destello) mientras no se ha encontrado (en la 2D o en la 3D). Al examinar el
  pilar: el texto del detalle, la página del Diario si toca, el aviso del báculo, «Has conseguido Báculo del Peregrino.»
  y el báculo desaparece. Los avisos ya no se pisan con la pista de Ferro (`_examinar` devuelve cuándo queda libre).
- **Brazalete:** `_brazalete()` en cada paso, como la 2D (radio 4 m ≈ 260 px; vuelve a armarse a 6,4 m; solo detalles
  sin ver y a la misma altura): sonido «brazalete» y destello en la muñeca de Kael.

### 3. Las notas

Encajan con la historia (no son canon nuevo: objetos de puenteros y peregrinos, ya revisados por narrativa) y van
como objetos examinables con su forma: **tabla** de los puenteros (poste, tabla con muescas y un rollo de cuerda),
**papel** clavado del ascensor, **escamas** de ámbar en la repisa del nido y **cintas** de colores atadas a una estaca
en una piedra junto al pilar. Destello mientras no se han leído; botón «Examinar» con su radio (2,2 m).
Dos sitios movidos en `dialogos/notas/garganta.gd` (y su `CASILLA_2D`): el aviso del ascensor caía dentro del tronco de
un pino de `escenario.gd` → (−14,0; 28,3), antes de llegar al ascensor; las escamas caían sobre un peldaño →
(6,3; 9,6) en la repisa. `prueba_notas_exploracion` sigue pasando.

### 4. 3D por defecto, 2D elegible

- `modo3d.gd`: la Garganta sale de `EN_PRUEBAS` y entra en `POR_DEFECTO_2D_ELEGIBLE = {GARGANTA: ["garganta3d",
  "garganta2d"]}`. Con la exploración 3D: sin nada en `user://ajustes.cfg` → 3D; `[regiones] garganta3d = false` (lo que
  guarda «2D (la de siempre)») → 2D; `true` → 3D. Es **la misma clave** de cuando estaba en pruebas: quien había elegido
  la 2D la conserva. Argumentos de prueba: `garganta2d` fuerza la 2D, `garganta3d` la 3D (manda). Sin la exploración 3D
  (APK estable), nada cambia. `eleccion()` nueva (true/false/null).
- `escena_equivalente`: además del sentido 2D → 3D, una partida guardada en la 3D con la 2D elegida abre la 2D por su
  entrada (solo para las regiones de `POR_DEFECTO_2D_ELEGIBLE`; Oakhaven y el Mar de Cristal, como estaban).
- `menus.gd` (mínimo y marcado «V12, migración de la Garganta»): el botón marcado es la versión en uso
  (`region_activa`), y las opciones pasan a «3D» y «2D (la de siempre)», en ese orden. Mismos ids de botón.

### 5. Rendimiento (PC, RTX 3050 portátil, 1280×720, `pruebas/medir_garganta3d.gd`, mismo recorrido)

Medidas en `D:\REBELUM_diagnostico\migracion\2026-11-12_garganta\medidas_antes\` (`c703625`) y `medidas_despues\`.
Llamadas de dibujo y primitivas al final de cada fase (antes → después):

| Fase | Medio: llamadas | Medio: primitivas | Bajo: llamadas | Bajo: primitivas |
|---|---|---|---|---|
| Entrada (andando) | 207 → 213 | 344 974 → 345 942 | 161 → 166 | 182 161 → 182 779 |
| Puentes | 136 → 136 | 351 244 → 351 816 | 100 → 100 | 165 313 → 165 611 |
| Asomarse al abismo | 184 → 189 | 361 012 → 361 986 | 127 → 131 | 172 353 → 172 977 |
| Cornisa baja | 125 → 127 | 343 681 → **336 821** | 82 → 83 | 159 321 → **155 891** |
| Palanca | 114 → 116 | 319 063 → **312 203** | 77 → 78 | 151 662 → **148 232** |
| Grieta (pilar, báculo, cintas) | 91 → 103 | 322 020 → 324 310 | 59 → 67 | 146 029 → 147 345 |

- **Lo caro demostrable que había:** el pomo de la palanca era una `SphereMesh` con los segmentos por defecto de Godot
  (64 × 32): **4 224 triángulos para una bola de 24 cm**, y con sombra. Ahora 12 × 6 (144); a la vista, igual. Es lo que
  baja la cornisa baja y la palanca (−3 400 en bajo, −6 900 en medio, que dibuja la sombra).
- **Lo nuevo cuesta poco:** las piezas fijas de las notas van en los lotes; las de color distinto, con el color en los
  vértices (`madera_color` y la nueva `tela_color`) para no abrir un lote por color (la primera versión sumaba ~10
  llamadas). El báculo es un nodo aparte (se quita al cogerlo): vara, puño y cinta en una malla, el anillo y el destello.
  Quedan +5 llamadas en la entrada (destellos de dos notas y sus lotes) y +8/+12 en la grieta mientras el báculo y las
  cintas están sin coger o sin leer; desaparecen los destellos al leer.
- **Revisado sin cambios:** inventario de mallas por triángulos, sombra y transparencia, y lo que cae en el campo de la
  cámara en 4 sitios (herramientas en el directorio temporal). El resto es contenido real: rocas en lotes por material
  (bordes de 50-117 m: entran enteros en la sombra), los tres héroes (~56 k triángulos), Gorthor, el gólem y el Coloso
  (se recortan por su caja), 2 capas de niebla de 27 × 73 m y 5 haces de luz de 52 m (transparentes: lo más probable en
  el p95 de 50 ms del medio en el Mali-G57, que es de fragmentos). No lo he tocado: es la belleza del abismo y no se
  puede medir sin el Redmi. Propuestas para medir en el teléfono (§6).
- El tiempo por fotograma del PC (5-8 ms de p95) no dice nada del Redmi.

### 6. Pendiente

- **Redmi (sin probar en el teléfono):** medir la Garganta 3D en bajo y medio con esta versión (antes: 30,4 · 30,2 FPS,
  medio p95 50 ms); ver el báculo y las notas en la pantalla pequeña. Si el medio sigue con tirones, probar, una cosa cada
  vez y con capturas antes/después: (a) sin sombra los lotes de roca que solo dan al abismo (muro norte y caras bajo las
  cornisas), (b) partir los lotes de roca por tramos de z para que la sombra los recorte, (c) una sola capa de niebla en
  el medio. Ninguna está hecha.
- **La 2D elegida sigue sin notas ni la veta de Ferro** (nunca las tuvo): con la 2D, el encargo del herrero no se puede
  terminar en la Garganta. Si se quiere paridad, `CASILLA_2D` de `dialogos/notas/garganta.gd` ya dice dónde irían.
- Las APK experimentales llevan ya la 3D por defecto: quien tenga la v6xx sin elegir nada pasará a la 3D al actualizar.
- Una partida guardada en la 3D con la 2D elegida entra por la entrada de la 2D (los trazados no se corresponden
  casilla a casilla); el progreso no se pierde.

### 7. Pruebas (aisladas, PC, 12/11)

- **Batería completa** tras el cambio por defecto, el báculo y las notas (`D:\REBELUM_diagnostico\pruebas\2026-11-12_002248`):
  **121 · 0 · 50 · 0**; `partida.save` real sin cambios.
- **Tras el brazalete** (`…\2026-11-12_003947`), 17 de 17: `prueba_garganta3d_examinables` (nueva, partes 0-4),
  `prueba_garganta3d`, `prueba_garganta3d_tramo`, `prueba_coloso_garganta`, `prueba_veta_garganta`, `prueba_hallazgos`,
  `prueba_notas_exploracion`, `prueba_restaurar_escenas`, `prueba_zona3d`, `prueba_integridad`, `prueba_efectos`,
  `prueba_musica`, `prueba_guardado`, `prueba_guardado_protegido`, `prueba_guardado_fallos`, `prueba_partida` y
  `prueba_calidad_auto`.
- `prueba_garganta3d` actualizada (paso 0: la 3D por defecto y `garganta2d`). Las demás pruebas de la Garganta siguen
  con `garganta3d` en la lista: ya no hace falta, pero no estorba.
- **Capturas** (`D:\REBELUM_diagnostico\migracion\2026-11-12_garganta\capturas\`, alto y bajo): el báculo junto al pilar,
  la tabla de los puenteros, el aviso del ascensor, las escamas del nido y las cintas.

### 8. Archivos para integrar (copiando, sin fusionar)

- Nuevos: `aethelgard/zonas3d/examinables_3d.gd` (+ `.uid`), `aethelgard/pruebas/prueba_garganta3d_examinables.gd`
  (+ `.uid`), este informe.
- Cambiados: `aethelgard/modo3d.gd`, `aethelgard/menus.gd` (solo el bloque «Garganta del Diablo», marcado),
  `aethelgard/zonas3d/garganta_3d.gd`, `aethelgard/zonas3d/garganta/piezas.gd`, `aethelgard/zonas3d/garganta/materiales.gd`,
  `aethelgard/dialogos/notas/garganta.gd` (dos posiciones y la cabecera), `aethelgard/hallazgos.gd` (solo comentario),
  `aethelgard/pruebas/prueba_garganta3d.gd`, `aethelgard/pruebas/lista_pruebas.txt` (una línea),
  `docs/diseno/garganta_3d.md` (§1 y §10).
- `menus.gd` lo pueden tocar otros: copiar solo el bloque marcado si hay conflicto. `project.godot` sin cambios.
