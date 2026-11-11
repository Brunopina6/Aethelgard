# Gráficos · V12 · Arte del Mar de Cristal (primer sector)

**11/11/2026, 12:45.** Rama LOCAL `claude/v12-desierto-arte` (`D:\Aethelgard_v12_arte`), desde `claude/rebelum-v12` @
`e9eebf1`. Cierre ordenado a petición del coordinador (el usuario abrió otra sesión para la V12): lo que hay funciona y
está confirmado, pero el ajuste artístico no está terminado (ver «Pendiente»).

## Commits

| Commit | Qué |
|---|---|
| `b018290` | `fuente/crear_desierto.py` (guion de Blender, 80 KB de texto) y `modelos/desierto/*.glb` + `.import` (24 piezas, alto y ligero; 1,9 MB en total) |
| `8b57bb7` | `shaders/desierto/`: `arena`, `tela`, `planta` (con variante ESPEJISMO), `arena_arrastrada`, `calor`, `vidrio` |
| `96e1cf6` | `zonas3d/mar_cristal/materiales_arte.gd` |
| `a139894` | `pruebas/fotos_desierto_arte.gd` y su línea en `pruebas/lista_pruebas.txt` (modo «ventana») |

Sin push ni merge. Nada queda sin confirmar en la rama.

## Piezas entregadas y triángulos (alto · ligero)

Cada GLB: metros, origen en la base (y = 0 suelo; lo de debajo está enterrado), mirando al sur. Dentro: el objeto de
la pieza, a veces `<id>_arena` (montones de arena con el material del suelo), `<id>_tela` / `<id>_hojas` (lo que mueve
el viento), `caja_<i>_<ancho>_<fondo>_<alto>` (choques, cm) y `ancla_<nombre>`.

| id | alto | ligero | notas |
|---|---|---|---|
| ruinas_arco | 1088 | 713 | enterrado hasta −2,4 m (hundirlo antes de la tormenta); rombo de vidrio en la clave |
| ruinas_columna_a / b / c / d | 384 / 468 / 512 / 402 | 214 / 224 / 252 / 208 | entera · rota · caída · tocón con cristales |
| ruinas_muro | 654 | 482 | |
| trampilla | 434 | 296 | `trampilla_tapa` con origen en la bisagra (norte): abrir con `rotation.x = -deg_to_rad(105)`; debajo, hueco con escalones (`ancla_hueco`) |
| caravana_carro | 1448 | 970 | volcado; lona en `caravana_carro_tela` |
| caravana_cajas / caravana_barril / caravana_tela | 570 / 222 / 220 | 394 / 106 / 94 | |
| tienda_a / tienda_b | 718 / 232 | 529 / 162 | tela aparte (`_tela`); `ancla_entrada`, `ancla_farol` |
| fogata | 488 | 372 | `ancla_fuego` (el fuego lo pone la región) |
| palmera_a / palmera_b | 1005 / 981 | 419 / 423 | hojas aparte (`_hojas`); `ancla_copa` |
| juncos | 314 | 184 | |
| roca_canon_a / b / c / d | 828 / 1192 / 608 / 792 | 316 / 484 / 344 / 365 | peñón 9 m · paño de pared 12 m N-S · bloque caído · chimenea de hada |
| roca_cobijo | 1228 | 503 | el origen es el sitio del cobijo; masa al oeste; saliente en `roca_cobijo_techo` |
| huesos_costillas | 3701 | 2123 | 16 m O-E, cráneo al este (1296 de los 3701 son montones de arena) |
| esqueleto | 553 | (sin ligero) | espalda al norte (pared en z = −0,35); `ancla_nota` |

### Nombres frente a los que espera `terreno.gd` del coordinador

| terreno.gd espera | aquí |
|---|---|
| roca_canon_1..3 | `roca_canon_a`, `roca_canon_b`, `roca_canon_c` (y además `roca_canon_d`) |
| roca_cobijo | `roca_cobijo` (igual) |
| tienda | `tienda_a` (jaima grande) y `tienda_b` (cónica) |
| fogata | `fogata` (igual) |
| caravana_restos | `caravana_carro` + `caravana_cajas` + `caravana_barril` + `caravana_tela` |
| palmera_1 / palmera_2 | `palmera_a` / `palmera_b` |
| ruinas_arco | `ruinas_arco` (igual) |
| ruinas_columna | `ruinas_columna_a` … `_d` (y `ruinas_muro`) |
| ruinas_trampilla | `trampilla` |
| huesos_colosales | `huesos_costillas` |
| esqueleto | `esqueleto` (igual) |
| cartografa | **no hecho** (no estaba en mi encargo: es un PNJ) |

Lo más sencillo: una tabla de alias en `terreno.gd` (o renombrar con `materiales_arte.PIEZAS`).

## Cómo usarlo desde la región

```gdscript
const Arte := preload("res://zonas3d/mar_cristal/materiales_arte.gd")
var perfil := Arte.perfil()
var arco := Arte.modelo("ruinas_arco", perfil)     # alto o ligero según el perfil; materiales ya puestos
add_child(arco); arco.position = Vector3(45, 0, 18)
add_child(Arte.choques(arco))                      # StaticBody3D con las cajas del GLB
suelo.material_override = Arte.mat_arena(perfil)   # mismo material que los montones de las piezas
var arrastre := Arte.arena_arrastrada(perfil); add_child(arrastre)   # moverlo con Kael (x, z)
Arte.intensidad_viento(self, 1.0)                  # tormenta; 0.25 calma
var esp := Arte.modelo("palmera_a", perfil, true)  # espejismo; Arte.mat_espejismo() «espejismo» 1 → 0
Arte.liberar()                                     # al salir
```

## Comprobado (11/11, con ventana, datos aislados en `D:\REBELUM_diagnostico\v12\arte\_aislado\…`)

- Blender 5.2 por script: las 24 piezas se generan sin errores (registro `D:\REBELUM_diagnostico\v12\arte\blender_ciclo.log`).
- Importación aislada en mi copia sin errores; `project.godot` restaurado tras cada importación.
- `fotos_desierto_arte.gd` con perfil alto y bajo: todas las piezas cargan («fallos 0»), los sombreadores compilan.
  Capturas en `D:\REBELUM_diagnostico\v12\arte\iter1` … `iter5` (la última, `iter5`, escena en alto y bajo; `iter4`,
  rocas y costillar nuevos). En PC, escena montada entera: 38-90 llamadas, 90-135 k primitivas (sobre todo el suelo de
  prueba y las sombras), 20-30 FPS con la ventana (medida sin hueco libre de carga: **no vale como medida**). Nada
  comprobado en Android.
- Hallazgo de luz (con `depurar_luz.gd` en el scratchpad, planos con StandardMaterial3D y con el sombreado de arena):
  **en Compatibility, con la sombra del sol activada, la luz ambiente y la bruma suman mucho más que sin sombras**
  (misma escena: ambiente 0,36 → píxel 0,60 sin sombras, 0,87 con sombras). El perfil bajo (sin sombras) se ve más
  oscuro que el alto y el medio. Afecta a todas las regiones, no solo al desierto; conviene que lo mire quien lleve la
  calidad (compensar ambiente/bruma según `sombras` o investigar el motor).

## Pendiente (no hecho o sin terminar)

1. **Ajuste artístico sin terminar.** Con la luz de prueba la arena al sol aún se quema en el perfil alto (píxel
   255,255,147 en `iter5/e01_campamento_alto`); en bajo se ve bien (237,188,121). Falta ajustar color y luz juntos con la
   luz real de la región.
2. Rocas: rehechas una vez (contorno con grietas, repisas solo en algunos estratos), aún algo cilíndricas; mejorar la
   silueta (más irregular, más alta en el paño de pared).
3. Costillar: costillas engrosadas y cráneo con hocico, cresta y dientes; sin revisar en captura tras el último cambio.
4. Sin capturas a la resolución del Redmi, sin medidas comparables y sin la cartógrafa.
5. Sin informe visual de la tormenta y el calor revisado (las capturas `e12`-`e15` existen en `iter1`/`iter5` pero no
   las revisé a fondo).
6. `aethelgard/fuente/` lleva solo `crear_desierto.py` (texto, 80 KB): se confirmó porque es lo que reproduce los GLB.

## Cambios que pido en archivos de otros

- `terreno.gd` (coordinador): alias de nombres de la tabla de arriba.
- Región: compensar ambiente y bruma con sombras (hallazgo de luz) y, para la arena, `SPECULAR = 0` ya está en el
  sombreado; si la región usa cielo con reflejos, no hace falta tocar nada más.
