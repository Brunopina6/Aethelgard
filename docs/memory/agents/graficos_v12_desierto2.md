# Gráficos · V12 · Mar de Cristal, segunda pasada: perfil bajo y riqueza del paisaje

**Noche del 11 al 12/11/2026.** Rama LOCAL `claude/v12-desierto-arte2` (`D:\Aethelgard_v12_arte2`), desde
`claude/rebelum-v12` @ `373e7db`. Sin push ni merge. Todo lo de abajo está **comprobado ejecutando en el PC** (datos
aislados, `ejecutar_pruebas.ps1`) salvo lo marcado como **pendiente**. **Nada se ha visto en el Redmi** (sin teléfono esta
noche): las capturas del PC no sustituyen la prueba en Android.

## Commits

| Commit | Qué |
|---|---|
| `8b25b48` | herramientas: `medir_luz_perfiles.gd` (punto negro, saturación, tiempos de GPU/CPU, `pos=a,b/c,d`, `luz=` variantes, `luz_antes`, espera de 7 s) y `medir_capturas.gd` (nueva: mide capturas del Redmi con las mismas cuentas) |
| `500d20f` | perfil bajo de la región, sombras falsas del bajo, agua del oasis, palmeras, orilla y `paisaje.gd` |
| `874a4ed` | surcos del gusano, remolino (alto), palmeras solo al norte, agua hasta la orilla, sin la falda bajo la arena jugable, cintas de arena arrastrada con vetas finas y los `.uid` |
| (este) | este informe |

**Para integrar copiando** (`git checkout claude/v12-desierto-arte2 -- <rutas>`), todo bajo `aethelgard/`:
`zonas3d/mar_cristal_3d.gd`, `zonas3d/mar_cristal/{terreno,clima,materiales_arte,paisaje,sombras_bajo}.gd` (+ `.uid` de
los dos nuevos), `shaders/desierto/{arena,arena_arrastrada,agua_oasis,mancha_sombra,surco}.gdshader` (+ `.uid` de los
nuevos), `pruebas/herramientas/{medir_luz_perfiles,medir_capturas}.gd` (+ `.uid`), y
`docs/memory/agents/graficos_v12_desierto2.md`. No toca `vista3d.gd`, combate, Bramavidrio, `gusano.gd`, sonido, música
ni menús. `project.godot` sin cambios (se restauró tras la primera importación, que vació Dialogic, y se comprobó tras
las siguientes).

## 1. El perfil bajo lavado (prioridad)

**Diagnóstico (medido):**
- Las capturas del Redmi y las del PC dan **las mismas cuentas** en el bajo (v597, inicio): luminancia 0,710 / 0,713,
  punto negro 0,615 / 0,603, saturación 0,453 / 0,450 (`medir_capturas.gd`). El PC sirve para ajustar este problema.
- La «bruma» era sobre todo **la niebla** (densidad 0,006, color crema): con ella a un tercio, el punto negro de la
  escena baja mucho y los personajes y las rocas dejan de verse velados (variantes `luz=` medidas el 11/11, 22:23-22:25).
- El brillo final ×1,15 (vista3d) aclaraba sin quitar el velo, y la arena salía terracota-rosada.
- Había además dos manchas claras sin relación con la luz: **la falda de dunas lejanas asomaba** por los senos de la
  arena jugable (parches poligonales claros, en los tres perfiles) y **las cintas de arena arrastrada** se veían como
  losas claras rectangulares.

**Arreglo (solo esta región, el resto igual):** `mar_cristal_3d.gd` `LUZ_SIN_SOMBRAS` (se aplica cuando el perfil no tiene
sombras): niebla 0,002, sol ×1,8 en vez de brillo final (pasa por el mapeo de tonos), arena llevada al crema del medio
(`terreno.gd`, `ARENA_CREMA`, 50 %), saturación 0,94, ambiente 0,40; `clima.gd` parte de la niebla del perfil (la
tormenta sigue llegando a 0,075). Más **sombras falsas** (`sombras_bajo.gd`): las de las piezas grandes (rocas, paredes
del cañón, cobijo, tiendas, carro, columnas, costillar a rayas, copas de palmera, el arco al destaparse) horneadas en una
textura de 1 m que lee el sombreado de la arena (`SOMBRA_HORNEADA`, solo sin sombras; suelo y montones a la vez; 29 ms al
cargar en el PC) y una mancha suave bajo Kael, su grupo, Ismena y Oren. Volver a lo de antes: `LUZ_SIN_SOMBRAS =
LUZ_SIN_SOMBRAS_ANTES` (o Engine `mc_luz_antes`; las pruebas A/B con Engine `mc_luz_prueba`).

**Cifras (PC, 1280×720, inicio 45,101; media · punto negro · saturación):**

| Perfil | Antes | Después |
|---|---|---|
| bajo | 0,713 · 0,603 · 0,450 | **0,747 · 0,627 · 0,432** (más claro, menos naranja; en las rocas y sombras el negro baja: cobijo 0,420 → 0,247) |
| medio | 0,794 · 0,681 · 0,413 | 0,792 · 0,680 · 0,414 (igual) |
| alto | 0,793 · 0,679 · 0,412 | 0,792 · 0,679 · 0,413 (igual) |

## 2. Riqueza del paisaje, por zona (`paisaje.gd` y `terreno.gd`)

- **Campamento:** columna de humo de la fogata (7/10/14 partículas por perfil) que se ve desde casi todo el sector y se
  tumba con la tormenta; matorrales secos en las afueras.
- **Caravana:** un barril más al norte (51,6, 54,6; con su choque, fuera del camino): el rastro hacia donde marca el sello.
- **Oasis:** agua nueva (`agua_oasis.gdshader`, opaca: hondo oscuro, orilla turquesa, ondas, cielo de lado y espuma en la
  orilla) hasta donde sube la arena del cuenco (sin borde de polígono); **palmeras solo en el arco norte** (al sur tapaban
  el agua y a Kael; `PALMERAS_AL_NORTE = false` vuelve al anillo); orilla mojada y cerco con verdín (colores de vértice);
  matorrales más verdes alrededor.
- **Cañón y cobijo:** matorrales al pie de las paredes; **hito de piedras con un trapo azul** junto al cobijo (se ve de
  lejos: dónde esperar la tormenta); las sombras horneadas del bajo dan profundidad al cañón.
- **Nicho del esqueleto:** cristales que lo alumbran; la roca que lo tapaba ahora **se aclara** (ver abajo).
- **Ruinas y trampilla:** un corro de cristales alrededor de la trampilla y junto al tocón vitrificado; cristales sueltos
  cada vez más frecuentes en el camino que sube a ellas (el corazón vitrificado está al norte).
- **Arena que tiembla y costillar:** tres surcos viejos del gusano (`surco.gdshader`, una malla) y cristales en el
  costillar; en el alto, un remolino de polvo que vaga por las dunas del este.
- **Espejismo:** corro de cristales (el vidrio que hace temblar el aire).
- **Rocas que tapan a Kael:** las rocas de gráficos, el costillar y el saliente del cobijo (con Kael debajo) pasan a una
  copia medio transparente de su material (antes la oclusión de `vista3d.gd` no las veía: usan materiales por superficie).
- **Arena arrastrada:** vetas más finas y recortadas (antes, losas claras); **falda lejana** recortada bajo la arena
  jugable (sin parches). Estos dos cambios se ven en los tres perfiles.
- Nada choca salvo el barril; nada pisa el camino, la cartógrafa, la fogata, la caravana, la trampilla, el esqueleto ni el
  cobijo (`paisaje.gd`, `_libre`). Todo con semilla fija.

## 3. Coste en el PC (llamadas · primitivas; RTX 3050, no vale para el Redmi)

| Sitio | bajo antes → después | medio | alto |
|---|---|---|---|
| inicio 45,101 | 39 · 87,3 k → 45 · 88,4 k | 64 · 167,6 k → 67 · 170,8 k | 100 · 184,1 k → 107 · 188,8 k |
| campamento 36,95 | 36 · 85,8 k → 42 · 86,8 k | 59 · 165,2 k → 62 · 168,4 k | 99 · 191,2 k → 106 · 195,9 k |
| caravana 50,65 | 31 · 77,4 k → 38 · 79,5 k | 52 · 157,2 k → 59 · 163,9 k | 99 · 177,5 k → 109 · 185,8 k |
| cobijo 17,49 | 39 · 79,9 k → 45 · 81,9 k | 67 · 162,0 k → 73 · 168,6 k | 83 · 180,3 k → 91 · 189,4 k |
| ruinas 45,30 | 35 · 77,8 k → 40 · 79,8 k | 61 · 158,2 k → 65 · 164,8 k | 67 · 162,4 k → 73 · 171,5 k |
| huesos 56,40 | 28 · 78,8 k → 34 · 80,9 k | 41 · 159,2 k → 46 · 165,8 k | 64 · 168,3 k → 71 · 177,5 k |

Bajo: +5-7 llamadas (4 manchas, cristales, matorrales, humo, surcos) y +1-2 k primitivas; medio y alto: +3-10 llamadas y
+4-9 k primitivas (en ellos los cristales y matorrales también dan sombra). Tiempo de GPU en el PC: 0,6-0,9 ms (bajo),
0,7-1,2 ms (medio), 0,9-1,5 ms (alto); FPS limitados por la pantalla (144). Sin errores ni fugas al cerrar (una fuga por
referencia circular terreno ↔ paisaje se encontró y se arregló en `terreno.liberar()`).

## 4. Capturas (`D:\REBELUM_diagnostico\graficos\2026-11-12_desierto\`)

- `comparar\`: por sitio y perfil, `<n>_<sitio>_<perfil>_antes.png` / `_despues.png` (1 inicio, 2 campamento,
  3 caravana, 4 oasis oeste, 4b oasis desde el sur, 5 cobijo, 6 ruinas, 7 huesos, 8 nicho) y las del Redmi como
  referencia (`0_redmi_v597_inicio_*`, `0_redmi_v581_inicio_bajo_brillo1.3`). (El oasis oeste no es comparable: las
  palmeras cambiaron de sitio.)
- `antes\…\luz_perfiles.csv` y `despues\…\luz_perfiles.csv`: todas las cifras. `experimentos\`: las variantes de luz.
- `pruebas\2026-11-11_225705\fotos_desierto_arte\`: las 77 de la prueba de gráficos (fallos 0; su escena usa su propia
  luz de prueba, no la de la región).

## 5. Pruebas (11/11, 22:57, `874a4ed` sin el informe; datos aislados; partida real sin cambios)

`prueba_mar_cristal`, `prueba_zona3d`, `prueba_integridad`, `prueba_buscador`: **SUPERADAS** (4 de 4).
`fotos_desierto_arte`: MANUAL, 77 capturas, fallos 0, revisadas por muestreo. Resumen:
`D:\REBELUM_diagnostico\graficos\2026-11-12_desierto\pruebas\2026-11-11_225705\resumen.md`. **No se pasó la batería
entera.**

## 6. Pendiente

1. **Android (lo primero):** compilar una APK de Auditoría con esto y mirar en el Redmi el bajo del desierto (inicio,
   cobijo, oasis): ¿sigue lavado o con bruma?, ¿la mancha bajo los personajes y las sombras horneadas se ven bien?, y medir
   FPS en bajo, medio y alto frente a la v615 (30,4 / 30,4 / 23,6). Si el medio pierde el tope de 30: quitar la sombra de
   matorrales y cristales en el medio (`paisaje.gd`, `cast_shadow`).
2. La tormenta con la luz nueva del bajo: la lógica la cubre `prueba_mar_cristal`; **no la he mirado en captura**.
3. Kael y el grupo pueden pisar el agua en el borde oeste (lo prohibido acaba a 4,6 m; ya pasaba antes).
4. Propuesta, no hecha: el medio y el alto también llevan bastante niebla en las caras de roca (`17,49`); se dejó igual
   porque en el teléfono el usuario no se quejó de ellos y el alto no se rebaja.
5. La batería entera de pruebas.
