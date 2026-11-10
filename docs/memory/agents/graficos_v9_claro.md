# Gráficos · V9: el Claro del Guardián (sector 3D y arena de jefe)

## 2026-11-10 17:35 · Entrega (rama `claude/v9-sector`, copia `D:\Aethelgard_v9_sector`)

Encargo (directiva V9, hitos 6 y 10): convertir el claro del noreste de Pastos Verdes 3D, donde duerme el Guardián del
Bosque («El bosque que no recuerda»), en un sector con identidad que se lea como arena de jefe desde la cámara de juego,
con tres estados (dormido, purificado y derrotado), modelado con Blender por guion, presupuesto móvil y colisiones, sin
tocar `bosque_pastos.gd` ni `pastos_verdes_3d.gd`.

Nota: el encargo pedía leer `D:\Aethelgard_v9_sector\CLAUDE.md`, que no existe en esta copia; se siguieron las normas
de `D:\Aethelgard\CLAUDE.md` (las mismas que cargó la sesión).

### Qué hay (observado en el código y comprobado ejecutando, 10/11, commits `1aa56e7` a `b99148b`)

| Archivo | Qué es |
|---|---|
| `aethelgard/zonas3d/bosque/fuente/crear_claro.py` (+ `.gdignore`) | Genera el kit con Blender 5.2.3: `blender -b --factory-startup -P crear_claro.py -- <carpeta>`. Misma semilla, mismo GLB (SHA-256 igual en dos pasadas) |
| `aethelgard/zonas3d/bosque/claro_guardian.glb` (0,19 MB) y `claro_guardian_ligero.glb` (0,11 MB), con sus `.import` | El kit: 16 piezas en el origen (6930 / 3213 triángulos, una de cada). Importación sin LOD, tangentes ni mallas de sombra |
| `aethelgard/zonas3d/bosque/claro_guardian.gd` | `ClaroGuardian.crear(region, centro, estado, padre)`: coloca el kit en el terreno, lo junta y pone colisiones, suelo, motas y el latido de las runas |
| `aethelgard/pruebas/prueba_claro_guardian.gd` (auto, en `lista_pruebas.txt`) | La prueba sin ventana |
| `aethelgard/pruebas/fotos_claro_guardian.gd` | Capturas con ventana en la región (no es prueba; no está en la lista) |
| `docs/recursos.md` | Fila de procedencia: obra propia |

**El sector** (radio útil ~5 m alrededor del sitio del Guardián):
- **Corro de nueve menhires** (tres tipos: alto 3,1 m, ancho y de puerta) con runas pálidas talladas en la cara que
  mira al centro; musgo arriba y por detrás, liquen a manchas, churretes de lluvia y tierra al pie. Lo alto va al norte
  y al oeste (la cámara mira al norte, así no tapa a Kael); lo bajo, delante.
- **Abierto al este**: la entrada, entre las dos piedras de la puerta (a -45° y 75°), da al sendero; la salida del
  noreste queda fuera del anillo. Ninguna colisión a menos de su radio + 0,6 m del sendero.
- **Dos raíces enormes** que salen del suelo, se arquean (hasta 2 m) y abrazan el corro por fuera; de la grande cuelgan
  cinco **cintas de ofrenda**.
- **Tocón-trono** detrás del Guardián (más alto por detrás, como un respaldo, con el corte en astillas, costillas de
  corteza y contrafuertes) con un **ojo tallado** que brilla como las runas. A su lado, un **cuenco de ofrendas** con
  bellotas y un ramillete seco, y dos **mojones** de piedras apiladas: lo que cuenta que alguien vela ahí.
- **Lecho de raíces** bajas en corro, abierto hacia la entrada, con una cama de musgo donde se arrodilla el Guardián.
- Musgo, setas, raíces que reptan y un **suelo de musgo** en la misma rejilla del terreno (3 cm por encima, la misma
  diagonal: no se cruzan), que se funde con el color del terreno por fuera y junto al sendero.
- Las raíces son más oscuras y frías que la corteza del Guardián, para que él destaque sobre ellas.

**Los tres estados:**
- **dormido:** runas y ojo de luz fría que laten despacio, motas de luz pálida, musgo oscuro donde duerme y una hierba
  pálida alrededor (el olvido).
- **purificado:** runas cálidas (verde dorado), un árbol joven que brota del corte del tocón con una yema que brilla,
  un manantial nuevo entre las raíces (corro de piedras y agua), 13 ramilletes de flores (también donde dormía), motas
  doradas, musgo más vivo.
- **derrotado:** todo seco y gris (corteza, musgo y setas, por color de vértice), tres raíces partidas y astilladas,
  runas apagadas (oscuras), suelo de ceniza parda y sin motas: el claro en silencio.

**Presupuesto (comprobado ejecutando, prueba del 10/11):**

| Perfil | dormido | purificado | derrotado | Mallas (llamadas de dibujo) | Colisiones |
|---|---|---|---|---|---|
| alto (kit completo) | 11 135 | 13 917 | 11 366 | 4 (5 con el agua) + motas | 30 (33 derrotado) |
| medio y bajo (kit ligero) | 5 452 | 7 028 | 5 605 | 4 (5 con el agua) + motas | 22 (25) |

Mallas: «Altos» (menhires, arcos y tocón, grupo `ocluye`: si tapan a Kael se vuelven transparentes con el sistema de
`vista3d.gd`), «Bajos», «Runas» (sin sombreado), «Suelo» (material del terreno, sin sombra) y «Agua» (solo
purificado). Material base: `_mat_detalle` de la región (el mismo grano y relieve que rocas y terreno). Motas: 18
partículas por CPU (10 con el kit ligero). Sin texturas propias. Montarlo: 10-26 ms sin ventana y ~45 ms con ventana
en el PC (se hace en `_construir`, ya diferido).

### La línea de integración (para el coordinador; no he tocado `bosque_pastos.gd`)

En `aethelgard/zonas3d/bosque_pastos.gd`, `_crear_claro()`, justo después de `add_child(n)` (línea 599):

```gdscript
	load("res://zonas3d/bosque/claro_guardian.gd").crear(r, p, B.desenlace() if P().hito("bq_resuelto") else "dormido", self)
```

Recomendado además: en la rama `if P().hito("bq_resuelto"):` quitar las formas provisionales (el `brote` y
`_crear_manantial_claro()` en purificado, el `tocon` en derrotado, líneas 602-614), que el sector sustituye (se solapan
con el tocón y el manantial nuevos), y dejar `n.name` y `_punto("claro", n, "Examinar el claro")`. Opcional:
`_crear_manantial_claro()` quedaría sin uso. Las capturas «después» de purificado y derrotado esconden esas formas.

El centro (radio 1,6 m) queda sin colisiones: el Guardián, su `RADIO_CLARO` (3,2 m) y el punto «claro» (2,2 m) se
alcanzan andando por la entrada.

### Pruebas (comprobado ejecutando, 10/11, datos aislados)

- Importación aislada como `ci_local.ps1` (registro `D:\REBELUM_diagnostico\importaciones\v9_claro_2026-11-10_172301`);
  `project.godot` no cambió.
- `ejecutar_pruebas.ps1 -Solo prueba_claro_guardian,auditar_recursos,prueba_bosque_pastos`: **3 SUPERADAS**, código 0;
  partida real y carpeta real sin cambios, sin otros Godot. Resumen:
  `D:\REBELUM_diagnostico\pruebas\2026-11-10_172625\resumen.md`.
- La prueba encontró un fallo real antes de darla por buena: una raíz y una piedra del suroeste caían sobre el borde
  del barranco del río (pasada `2026-11-10_171928`, 18 FALLOS); se movieron hacia dentro y pasó.

### Evidencias (`D:\REBELUM_diagnostico\v9\sector_claro\`)

- `comparacion_antes_despues.png`: lámina antes / después de los tres estados (toma «dentro», recortada).
- `claro_<estado>_{camino,entrada,dentro,conjunto}.png`: perfil alto, 1280 × 720, cámara de juego (45°, 20 m; «conjunto»
  con el zum más abierto que permite el juego, 30 m).
- `claro_<estado>_antes_*.png`: el claro de antes (con `sin_sector`).
- `claro_<estado>_movil_*.png`: perfil bajo (kit ligero, sin sombras, 3D al 75 %).
- `fotos.ps1`, `importar.ps1` y `comparar.ps1`: cómo se hicieron (datos aislados en `_aislado\`).

### Límites

- **Sin medidas de rendimiento** (tiempos por fotograma, memoria): había otro Godot de pruebas en `D:\Aethelgard_v9`
  al empezar y no tengo la confirmación de un hueco sin carga. Los FPS que salen en las capturas (15-20) son de una
  ventana en el PC con otras cargas, no una medida. El presupuesto se comprobó contando triángulos y mallas.
- **Pantalla del Redmi:** `--resolution 1600x720` no cambió el tamaño de la captura (salió 1280 × 720); las capturas
  «movil» muestran el perfil bajo, no la proporción 20:9. Pendiente de verificar en el teléfono.
- **No integrado:** el sector solo aparece en la región cuando el coordinador ponga la línea de arriba; hasta entonces
  solo lo montan la prueba y el guion de capturas.
- **No comprobado:** que Lya y Garon (`grupo_3d.gd`) rodeen bien las piedras al seguir a Kael dentro del claro, y el
  combate desde el claro con el sector puesto (las colisiones no están en el pasillo de entrada, comprobado).
- Lo que no puedo cambiar sin tocar archivos de otros: el árbol grande de la región en (14, -14) tapa el cuadrante
  suroeste del corro, y dos arbustos de la región caen dentro del anillo.
- Archivos sin seguimiento que generó la importación y no son míos (no los confirmo): `dialogos/bosque/bq_orbe_a.dtl.uid`,
  `bq_orbe_b.dtl.uid` y `pruebas/prueba_oficios.gd.uid`.

### Siguiente paso propuesto

1. Coordinador: la línea de integración (y quitar las formas provisionales del claro resuelto).
2. Con eso puesto: `prueba_bosque_pastos` y una pasada andando con el grupo hasta el Guardián; capturas en el Redmi.
3. Opcional, si se toca la región: apartar el árbol de (14, -14) un par de metros al suroeste para que se vea el corro
   entero, y no poner arbustos dentro del claro (`sendero_puente.gd`, `_arbustos`).
4. Medir en el Redmi (banco de la región) en un hueco sin carga, antes y después, con el perfil bajo.
