# Rendimiento, V12 fase 2 · el Gran Bosque Verde 3D en el Redmi (bajo y medio a 30 FPS)

## 12/11/2026 · rama `claude/v12-fase2-bosque-rendimiento` (LOCAL, desde `claude/rebelum-v12` @ `8645218`), copia `D:\Aethelgard_v12_bosque_rend`

Encargo: el Gran Bosque Verde 3D iba en el Redmi (v646) a **27,3/25,9 FPS en bajo y 14,3/13,7 en medio** (objetivo 30),
mientras Pastos, la Garganta, Oakhaven y el Mar de Cristal van a 30. Llevarlo a 30 en bajo y medio **sin perder belleza**,
con el coste de GPU parecido o menor que Pastos en el mismo perfil. Sin push ni merge; sin ADB ni teléfono (mide el
coordinador). Todo con datos aislados (`APPDATA`/`LOCALAPPDATA`/`TEMP` en una carpeta temporal; la batería con
`ejecutar_pruebas.ps1`); la primera importación vació los directorios de Dialogic de `project.godot`: `git restore` y
reimportar (después, sin cambios). Solo se ha tocado el Gran Bosque (`zonas3d/gran_bosque/escenario.gd`) y una
herramienta nueva de medida; ni sistemas (cofres, armadura, encuentros, guardado, salida) ni nada compartido.

Leyenda: **[E]** medido/comprobado ejecutando (PC, aislado) · **[C]** visto en el código · **[?]** sin comprobar.

### 1. Cómo se ha medido (PC, para comparar; el Redmi lo mide el coordinador)

- Herramienta nueva: `aethelgard/pruebas/herramientas/medir_gpu_bosque.gd` (con ventana). En cada región, perfil y sitio
  (Kael quieto, la cámara de juego): mediana del **tiempo de GPU** de 40 fotogramas
  (`viewport_get_measured_render_time_gpu`), **llamadas de dibujo**, **primitivas** y **capas** (fragmentos rasterizados por
  píxel del 3D), con variantes que quitan una cosa cada vez (copas de hojas, copas macizas, troncos, sotobosque, hierba,
  haces, agua, sombras, partículas, suelo, personajes, el hueco) y pruebas de sombreado (`~cono_off`, `~cerca_off`...).
- **Como el Mali:** Godot no hace prepase de profundidad con Mali/Adreno/PowerVR/Apple
  (`rendering/driver/depth_prepass/disable_for_vendors`), y en el PC sí. Se ha medido con un `override.cfg` temporal
  (`[rendering] driver/depth_prepass/enable=false`), creado y borrado en cada pasada (no queda en el proyecto).
- **Ventana 1600×720** (la pantalla del Redmi; el 3D ocupa 1280×720 con las franjas, como en el teléfono) y el 3D al
  **doble de resolución** (`amplia=2`: misma geometría, ×4 píxeles) para que pese lo que cuesta por píxel; la RTX 3050 va
  sobrada a la resolución real.
- **Sobredibujado:** `Viewport.DEBUG_DRAW_OVERDRAW` **sí funciona en Compatibility** [E], pero cambia también el sombreado
  de vértices (no vería el hueco nuevo, que se hace en el vértice) y se satura a 7 capas. Por eso la herramienta dibuja
  cada pieza con una copia de su sombreado que conserva el vértice y en el píxel solo suma 0,1 (sin profundidad, luz,
  bruma ni mapeo de tonos), en un lienzo HDR (`use_hdr_2d`), calibrado con 1-40 capas conocidas (0,0888 por capa,
  lineal). «Capas» = fragmentos que la GPU rasteriza por píxel (las matas recortadas cuentan enteras: en el Mali se
  sombrean igual antes del descarte). Es una cota superior (sin prueba de profundidad).
- **La medida del PC predice bien el Redmi:** antes, medio en la entrada 2,93 ms ↔ 14,3 FPS en el Redmi (≈ 24 ms del
  Redmi por ms del PC); Pastos medio en el banco 1,40 ms ↔ 30,3 FPS (≈ 23,6). Bajo: 1,40 ms ↔ 27,3 FPS (≈ 26).
- Pastos se ha medido en los puntos del banco (`vista3d.gd`, `BANCO_RUTA`, donde se midió el medio a 30 FPS en el Redmi,
  v336), a 20 m y a 34 m, y en sus ruinas y su claro. Dos pasadas de Pastos separadas dieron las mismas cifras (±0,01 ms).

### 2. La causa, medida [E]

En medio, en la entrada (2,93 ms; Pastos 1,40): **las copas de hojas −1,79 ms** (61 %), y de eso, **el hueco tramado
−0,84 ms** (`~cono_off`; el corte cercano a la cámara, solo −0,15), las sombras −0,44, el suelo −0,23. Capas: **18,6 por
píxel** de media en la entrada (Pastos 2,0-3,5), 10,1 en las ruinas, 9,2 en el campamento.

- **El tramado del hueco era lo más caro:** en las copas, el hueco entre la cámara y Kael (un cono, ×2,4 de ancho junto a
  la cámara) y lo muy cercano a la cámara se descartaban **píxel a píxel** con un tramado (`discard`). Dentro de ese
  volumen se seguía rasterizando y sombreando cada mata de la copa (hasta el descarte) y todo lo de detrás; sin el
  descarte, la primera mata escribe profundidad y las de detrás se rechazan antes de sombrearse. Era lo que en la
  captura del Redmi se ve como grano a media pantalla. Además, con `discard` en todas las copas y troncos, el Mali no
  puede usar su eliminación de píxeles ocultos (FPK) ni en las copas macizas.
- **Copas de hojas cerca del camino:** en medio son de matas recortadas (doble cara) y, con la sombra del sol, en
  Compatibility se dibujan dos veces (pasada base y pasada aditiva de la luz con sombra).
- **En bajo** (1,40 ms en la entrada): las copas macizas −0,54 (triplanar: 3 lecturas del atlas por píxel, más el grano que
  se leía y se tiraba), las de hojas −0,20 (los árboles viejos), el hueco.
- Sotobosque, hierba, haces, agua y partículas: ≤ 0,03 ms cada uno en todos los sitios (no son el problema).

### 3. Qué se ha cambiado (`zonas3d/gran_bosque/escenario.gd`), por perfil

| Cambio | Bajo | Medio | Alto | Se ve |
|---|---|---|---|---|
| **Hueco de las copas en el VÉRTICE** (`HUECO_VERTICE`): cada mata (centro en `CUSTOM0`) o lóbulo se encoge hacia su centro según el hueco allí; lo de dentro no dibuja ni un píxel; copas sin `discard` del hueco | sí | sí | sí | Sin grano: el borde del hueco son hojas que se apartan; las copas cercanas se ven nítidas |
| Copas de hojas **sin las matas de dentro** («mata de sombra», `hondo` < 0,56) y con un **núcleo opaco** oscuro (lóbulos al 62 %, pintado como las macizas) — viejos y los de junto al camino | sí | sí | no | Igual (por los huecos se ve hojarasca oscura) |
| Copas macizas: mezcla triplanar **más corta** (`afilar` 3, `umbral` 0,06: ~1,4 lecturas por píxel en vez de 3) y el grano solo si no es copa pintada | sí | sí | grano sí, mezcla igual | Igual a la vista |
| **Suelo con UV** en vez de triplanar (grano y relieve: 1 lectura por textura en vez de 3); tangentes solo con relieve | sí | sí | no | Igual (suelo casi llano, grano suave) |
| Troncos: el tramado de siempre (poca superficie) | — | — | — | — |

No se ha quitado nada visible: ni árboles, ni copas de hojas (medio sigue con hojas a ≤ 4,5 casillas del camino; con 3 la
entrada se ve con bolas pintadas en primer plano: descartado), ni sombras, haces, agua, sotobosque o fauna. Los
interruptores `gb_*` (por `calidad_extra`) solo sirven para medir el antes y las alternativas (§5).

### 4. Cifras antes → después (PC, GPU ms con el 3D ×2, sin prepase; mismo sitio y cámara) [E]

Medidas: `D:\REBELUM_diagnostico\migracion\2026-11-12_gran_bosque_rendimiento\medidas\gpu_*_antes|despues.json/.txt`
(el antes, con el `escenario.gd` original de `8645218` puesto un momento y devuelto).

| Sitio | GPU ms | Llamadas | Primitivas | Capas |
|---|---|---|---|---|
| **bajo** | | | | |
| entrada | 1,40 → **0,90** | 106 → 109 | 193 → 195 k | 6,8 → **3,1** |
| puente | 0,83 → **0,77** | 51 → 53 | 153 → 154 k | 2,7 → **2,0** |
| ruinas | 1,28 → **0,80** | 99 → 101 | 182 → 183 k | 9,0 → **2,6** |
| campamento | 1,14 → **0,75** | 77 → 78 | 174 → 175 k | 6,7 → **2,1** |
| claro | 1,09 → **0,78** | 70 → 72 | 178 → 179 k | 4,7 → **2,7** |
| altar | 0,95 → **0,76** | 68 → 65 | 211 → 212 k | 2,8 → **1,9** |
| bosque cerrado | 0,81 → **0,72** | 52 → 52 | 168 → 167 k | 1,7 → **1,6** |
| mirador (cámara a 27 m) | 1,60 → **1,21** | 67 → 70 | 212 → 214 k | 4,2 → **4,0** |
| **medio** | | | | |
| entrada | 2,93 → **1,41** | 176 → 183 | 292 → 303 k | 18,6 → **5,3** |
| puente | 1,25 → **1,10** | 87 → 90 | 248 → 251 k | 2,9 → **2,2** |
| ruinas | 1,98 → **1,19** | 168 → 175 | 282 → 291 k | 10,1 → **3,0** |
| campamento | 1,92 → **1,13** | 125 → 130 | 274 → 280 k | 9,2 → **2,7** |
| claro | 1,70 → **1,21** | 124 → 137 | 278 → 290 k | 6,5 → **3,6** |
| altar | 1,80 → **1,21** | 121 → 120 | 311 → 316 k | 6,3 → **3,2** |
| bosque cerrado | 1,37 → **1,10** | 96 → 99 | 253 → 258 k | 3,5 → **2,8** |
| mirador (27 m) | 2,45 → **1,79** | 96 → 103 | 280 → 287 k | 5,1 → **4,7** |
| **alto** (no es para el Redmi) | | | | |
| entrada | 9,34 → **5,96** | 272 → 272 | 566 k | 21,8 → **7,9** |
| ruinas | 8,96 → **6,13** | 274 → 270 | 572 k | 13,7 → **4,3** |
| campamento · claro · altar | 6,8-7,1 → **5,1-5,8** | ≈ | ≈ | 7,4-10,8 → **3,3-5,1** |
| puente · bosque cerrado · mirador | 6,2-11,0 → **5,8-10,3** | ≈ | ≈ | ≈ |

**Pastos Verdes, mismo PC y método:** bajo **0,93-1,14 ms** (banco 0,93-0,99; a 34 m 1,10-1,11), capas 2,0-3,5; medio
**1,40-1,67 ms** (banco 1,40-1,42; a 34 m 1,51-1,52), llamadas 134-254, primitivas 356-459 k, capas 2,0-3,5; alto 3,45-3,98.

- **Bajo:** el Gran Bosque queda **por debajo de Pastos en todos los sitios** (0,72-0,90 frente a 0,93-1,14), salvo el
  mirador (1,21: como Pastos a 34 m, +9 %).
- **Medio:** **igual o por debajo de Pastos** en todos los sitios (1,10-1,41 frente a 1,40-1,67); la entrada (1,41) queda
  como el banco de Pastos, que en el Redmi da 30,3 FPS. El mirador (1,79) queda +18 % sobre Pastos a 34 m (que en el
  Redmi daba 27,7 FPS en medio).
- **Estimación para el Redmi** (×24-26 ms por ms del PC, §1) [?]: bajo 19-24 ms (30 FPS con el tope), mirador ~31 ms;
  medio 26-34 ms (la entrada, ~30 FPS justos, como Pastos), mirador ~43 ms (~23 FPS).
- Llamadas y primitivas suben un poco (+3-13 llamadas: el núcleo de las copas; +2-12 k primitivas): no es lo que limita.
- **Carga** (PC, `fotos_gran_bosque3d.gd`): construir el escenario +10 ms en bajo y +50 ms en medio (las tangentes del
  relieve del suelo); la carga total, dentro del ruido (0,9-2,0 s).

### 5. Lo que queda y alternativas medidas (sin aplicar)

- **El mirador** sigue siendo lo más caro (bajo 1,21, medio 1,79): la cámara a 27 m ve medio bosque (suelo −0,38, copas
  macizas −0,39, de hojas −0,21, sombras −0,27). Probado: cámara del mirador a 24 m −3 %, a 22 m −9 % (no aplicado:
  cambia el encuadre). En el Redmi con calidad automática actuaría el ajuste dinámico (resolución).
- **Si la entrada en medio no llega a 30 en el Redmi** (interruptores ya en el código, apagados; se encienden con
  `calidad_extra` o añadiéndolos al perfil; capturas en `...\2026-11-12_gran_bosque_rendimiento\alternativas\`), en la
  entrada en medio (base 1,36 en esa pasada):
  - `gb_hojas_sin_brillo` (hojas sin especular, que con 0,12 y rugosidad 0,85 apenas se ve): **1,29 (−5 %)**, sin
    diferencia visible apreciable; la primera opción;
  - `gb_hondo: 0.68` (más matas de dentro fuera; el núcleo las sustituye): **1,26 (−7 %)**, capas 5,3 → 3,8 (como
    Pastos), pero la copa se ve algo más oscura (`hondo_056_vs_068_*.png`);
  - `gb_hojas_ligeras` (sin especular, Lambert y sin la pasada de la sombra): **1,23 (−10 %)**, pero las copas se ven
    más claras y planas (`hojas_ligeras_entrada.png`). No aplicado.
- Medio con copas de hojas solo a ≤ 3 casillas: −0,07 ms en la entrada, pero se ven bolas pintadas en primer plano.
  Descartado.
- Probado y sin efecto (≤ 0,07 ms): relieve del suelo, sombra de los troncos, Lambert en las macizas, el corte cercano más
  ancho, haces, partículas, agua, hierba y sotobosque.
- Los troncos siguen con el tramado del hueco (−0,15 ms en total los troncos en medio).

### 6. Capturas (antes | después)

`D:\REBELUM_diagnostico\migracion\2026-11-12_gran_bosque_rendimiento\`:
- `antes_despues\<perfil>_<sitio>.png`: 24 composiciones (bajo, medio y alto en los 8 sitios), el antes a la izquierda.
- `capturas\granbosque_<perfil>_<sitio>_antes|despues.png` (resolución real del perfil) y `..._capas.png` (capas por
  píxel, gris = 0,0888 por capa, blanco ≥ 11).
- `medidas\`: las cifras de §4 (JSON y texto).

### 7. Pruebas [E]

- **Batería completa** (`D:\REBELUM_diagnostico\pruebas\2026-11-12_101601`): **130 · 0 · 58 · 0** (igual que la base,
  `b719ea0`); `partida.save` real y carpeta real de datos sin cambios. El «proyecto CAMBIADO» de esa pasada es este
  informe y dos interruptores apagados añadidos durante la pasada.
- **Con el código final** (`2026-11-12_103143`): `prueba_gran_bosque3d`, `prueba_zona3d`, `prueba_integridad`,
  `prueba_guardado`, `prueba_guardado_protegido`, `prueba_restaurar_escenas`: **6 de 6**; datos reales sin cambios.
- En las pasadas con ventana de la herramienta (decenas, tres perfiles), ningún error de sombreado ni de script.

### 8. Archivos para integrar (copiando, sin fusionar)

- Cambiado: `aethelgard/zonas3d/gran_bosque/escenario.gd` (solo el Gran Bosque).
- Nuevo: `aethelgard/pruebas/herramientas/medir_gpu_bosque.gd` (+ `.uid`), este informe.
- Uso de la herramienta (datos aislados; quien la lance crea y borra el `override.cfg` sin prepase):
  `Godot --path aethelgard --resolution 1600x720 --script res://pruebas/herramientas/medir_gpu_bosque.gd -- salida=<carpeta>
  regiones=granbosque,pastos perfiles=bajo,medio variantes=base,-copas_hojas,... amplia=2 n=40 [fotos] [etiqueta=x]
  [extra=gb_hondo:0.68]`.
- **Pendiente [?]:** medir en el Redmi bajo y medio en la entrada, las ruinas, el claro y el mirador; mirar andando el
  borde del hueco (hojas que se apartan).
- Sin cambios: `gran_bosque_3d.gd`, `trazado.gd`, `disposicion_2d.gd`, `prototipos/*`, `calidad_proto.gd`, `project.godot`,
  pruebas y lista de pruebas.
