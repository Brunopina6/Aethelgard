# Animaciones · V9: modelo del Coloso de la Falla

## 2026-11-10 18:45 · Entrega (rama `claude/v9-coloso-modelo`, copia `D:\Aethelgard_v9_coloso-modelo`)

Encargo (directiva V9, jefe 2): el modelo 3D del «Coloso de la Falla», gigantesco guardián de piedra con inscripciones
antiguas, jefe de la Garganta 3D. Hecho con Blender 5.2.3 por guion, geometría procedural propia, con la misma
interfaz de combate que el Guardián del Bosque.

### Qué hay (observado en el código y comprobado ejecutando, 10/11, commits `5eb3a8a`, `75d8521`, `51fabcb`, `cd85299`)

| Archivo | Qué es |
|---|---|
| `aethelgard/enemigos/coloso_falla/fuente/crear_coloso.py` | Genera malla, esqueleto, clips y GLB. Misma semilla, mismo GLB (SHA-256 igual en dos pasadas) |
| `aethelgard/enemigos/coloso_falla/fuente/capturas_coloso.py` | Renderiza en Blender cada clip desde la vista del combate, con la luz de las runas de cada fotograma, y compone las hojas |
| `aethelgard/enemigos/coloso_falla/coloso_falla.glb` (1,31 MB) y `.glb.import` | Modelo; el .import pone `piedra.tres` y `runas.tres` como materiales externos, sin LOD ni tangentes ni subrecursos de animación (como el del Guardián) |
| `aethelgard/enemigos/coloso_falla/piedra.tres`, `runas.tres` | Materiales: piedra con colores de vértice (`vertex_color_is_srgb = true`, como se corrigió en el Guardián) y runas emisivas de ámbar |
| `aethelgard/enemigos/coloso_falla/coloso_falla_3d.gd` | Guion del modelo en combate (interfaz de `guardian_bosque_3d.gd`) |
| `aethelgard/pruebas/prueba_coloso_modelo.gd` (auto) | Prueba, registrada en `lista_pruebas.txt` |
| `docs/recursos.md` | Fila nueva: obra propia (no hace falta línea en `licencias_pendientes.txt`) |

**Aspecto:** gólem de bloques de piedra redondeados de 4,16 m (lo alto de los monolitos de la espalda; la cabeza, a
3,7 m: más del doble que un héroe). Pecho y hombros enormes, la cabeza hundida entre ellos con ojos de luz, antebrazos
que se ensanchan hacia unos puños gigantes con nudillos, piernas cortas y gruesas, tres monolitos en la espalda.
Gris de la Garganta con vetas ocre y violeta, aristas gastadas más claras y algo de musgo en lo alto. Placas de
pizarra en hombros y antebrazos. **Runas:** 33 glifos angulosos de diseño propio (cinturón entre dos líneas, frente,
espalda, placas, muslos y, escondidas bajo las placas, hombros y antebrazos), en el material emisivo, con la luz
ámbar de la Falla. **Grietas vulnerables:** una oscura en el pecho y otra en la espalda, siempre visibles; dentro, una
línea de luz que solo se enciende cuando se señalan o en la fase 2.

**Por qué piedra en bloques:** cada bloque va pegado a un solo hueso, así que la piedra gira entera y no se estira en
ninguna pose (no hay pesos repartidos que deformen la roca).

**Presupuesto:** 9 042 triángulos (máximo 12 000), 29 huesos (máximo 30), 1 malla, 2 materiales, ninguna textura. Los
halos de las grietas (dos QuadMesh transparentes) los crea el guion.

### Clips (30 fps; en el GLB empiezan en 0 s)

| Clip | Duración | Bucle | Anclas |
|---|---|---|---|
| `reposo` | 2,80 s | sí | respira y se mece; las runas laten un 8 % |
| `ataque` | 1,50 s | no | echa el brazo derecho a 0,33 s; puñetazo hacia abajo, **impacto 0,600 s** (los nudillos 2,21 m por delante, a la altura de un héroe); acaba en el reposo |
| `carga` | 1,20 s | sí | gira el tronco y echa el brazo derecho atrás; las runas laten (primer latido 0,167 s, hasta ×1,9) |
| `golpe_fuerte` | 2,07 s | no | empieza en la pose de la carga; el brazo da la vuelta por detrás y por encima (0,37 s); **impacto 0,667 s**: el puño toca el suelo 1,72 m por delante, brotan lascas hasta 0,77 s y se hunden hasta 1,5; cinco rocas saltan en arco de 0,7 a 1,5 s; acaba en el reposo |
| `herido` | 0,77 s | no | golpe a 0,10 s |
| `fase2` | 2,57 s | no | se recoge, las runas arden (×2,8); se yergue y **las placas saltan a 1,033 s**, quedan fijas a 1,233; el brillo de las grietas crece de 0,9 a 1,033; acaba en el reposo con las placas abiertas |
| `derrota` | 2,50 s | no | se agrieta a 0,3 s (grietas de luz por el pecho, la espalda y los costados, las runas llamean), cede a 0,9, de rodillas a 1,3 con los puños en el suelo, vencido a 1,83; la placa del hombro izquierdo se suelta; las runas se apagan |
| `dormido` | 3,00 s | sí | de pie e inmóvil como una estatua, con musgo y lianas en hombros, cabeza y espalda; las runas apenas respiran (0,12 a 0,22) |

**Piezas que se esconden con la escala de su hueso** (todas en la misma malla):
- `grietas` (brillo de las grietas vulnerables): escala 1 en los clips salvo `dormido`, y en `fase2` crece de 0,01 a 1.
  **En la fase 1 lo esconde el guion** salvo que el combate lo señale.
- `grietas_derrota`: solo en `derrota`. `musgo`: solo en `dormido`. `rocas` y `proyectiles`: solo en `golpe_fuerte`
  (huesos sin padre, en el suelo: no bajan con la raíz).

**Placas** (`placa_hombro.L/.R`, `placa_antebrazo.L/.R`): cerradas en todos los clips salvo `fase2`, que las separa
(los hombros, 0,37 m hacia arriba y fuera y ladeadas 18°; los antebrazos, 0,26 m hacia fuera) y deja a la vista las
runas de debajo. En la fase 2 del combate el guion las mantiene en la pose final de `fase2` y flotando 2,5 cm.

**Apoyos:** la altura de la raíz de cada pose se calcula para que lo más bajo de las piernas toque el suelo. En el
golpe fuerte se busca el ángulo del brazo para que el puño toque el suelo (queda a 7 mm); de rodillas, el de cada brazo
para apoyar los puños.

**Corrección durante el trabajo (comprobado en los renders):** en la primera pasada el cinturón de runas se leía como
letras latinas («FOXANY»); se cambiaron los glifos por formas que no lo parecen. También el golpe fuerte salía con el
cuerpo doblado 80° y el puño junto al pie: la búsqueda era por la inclinación del tronco; ahora busca el ángulo del
brazo con las piernas muy dobladas.

### El guion (`coloso_falla_3d.gd`)

**Misma interfaz que `guardian_bosque_3d.gd`:** `reposo`, `andar`/`correr` (no corre), `cansada`,
`herida`/`recibir_golpe`, `morir`/`derrota`, `victoria`, `revivir`, `entrada`, `mirar`, `mirar_frente`,
`lanzar_magia`/`punto_magia`/`fin_magia`, `preparar_golpe`/`golpear`/`fin_golpe`, `atacar(ataque, al_impactar)`,
`ataque(al_impactar)`, `golpe_fuerte(al_impactar)`, `cargar(ataque)`, `fase2()`, `poner_fase(n)`, `en_fase2()`,
`dormir()`, `despertar()`, `dormido_al_empezar`, `alcance`, `tiempo_impacto`, `duracion`, `play`, `corazon()`,
`punta_rama()`, `ALTURA` (4,16), `CENTRO` y `FRENTE_ENEMIGO`.

**Nuevas:** `senalar_grietas(si)` y `grietas_visibles()` (los puntos vulnerables: brillo y halo que late, delante y
detrás; el de la espalda no se ve a través del pecho), `punto_vulnerable(espalda)`, `nucleo()` (= `corazon()`),
`puno()` (= `punta_rama()`) y `energia_runas()`.

**Señales:** `aviso`, `impacto`, `placas_abiertas` **y** `coraza_desplegada` (el nombre del Guardián, en el mismo
instante, por compatibilidad), `ataque_terminado` y `clip_terminado`.

**Alias de `atacar`:** `punetazo`, `puñetazo`, `golpe`, `puno`, `golpe_de_piedra`, `latigazo` → `ataque`;
`puno_al_suelo`, `derrumbe`, `terremoto`, `sismo`, `lluvia_de_rocas`, `rocas`, `juicio` → `golpe_fuerte`.

**A propósito no tiene `avisar()` y sí `despertar()`:** `combate.gd` (`_animar_golpe`) ya lo manda por
`_anim_guardian`, que ataca desde su sitio, llama al impacto una vez y hace temblar la pantalla en `golpe_fuerte`.

**`entrada()`** = despertar: de estatua al reposo en 1,6 s; el musgo se retira y las runas se encienden con la mezcla.

**Luz:** las runas brillan según la escala del hueso `nucleo`: 1,0 en reposo, hasta 1,9 en la carga, 2,8 en la
transformación, 1,35 en el reposo de la fase 2 (×1,3 con las placas abiertas), 0 al ser derrotado y 0,12-0,22 dormido.

### Pruebas (comprobado ejecutando, aislado, 10/11)

- **Importación aislada** (como `ci_local.ps1`, paso 1, con su restauración de `project.godot`):
  `D:\REBELUM_diagnostico\importaciones\v9_coloso_modelo_2026-11-10_183433`. Las primeras importaciones
  cambiaron `project.godot` y se restauró con `git restore`; al final, `project.godot` sin cambios.
- **`ejecutar_pruebas.ps1 -Solo prueba_coloso_modelo`** (desde PowerShell): **SUPERADA**, 182 comprobaciones y 0
  fallos; partida real, carpeta real de datos y proyecto sin cambios. Resumen:
  `D:\REBELUM_diagnostico\pruebas\2026-11-10_183444\resumen.md` (copia del registro en
  `D:\REBELUM_diagnostico\v9\coloso_modelo\prueba_coloso_modelo.log`).
- Había otros dos Godot abiertos, sobre `D:\Aethelgard_v9_coloso-combate` (`fotos_coloso.gd`): no eran de mi copia.
- **Qué comprueba:** los 8 clips (y solo esos), cada uno escribe los 29 huesos; presupuesto, materiales, caras y
  espacio de color; bucles sin salto; acciones que acaban en el reposo (fase2, salvo las placas); golpe fuerte desde la
  carga; piezas escondidas en cada clip; el guion con `.new()`: reposo y mirada, métodos, grietas apagadas en la fase 1
  y señaladas, placas cerradas; impactos una vez y en su ancla (0,600 y 0,667 s); aviso de la carga; golpe recibido en
  carga; golpe a mitad del puñetazo; fase 2 (señales una vez a 1,033 s, placas abiertas y que siguen tras atacar,
  grietas encendidas, runas); magia en el núcleo; derrota de rodillas, agrietado y apagado, sin atacar; revivir;
  estatua de pie con musgo; entrada; el GLB solo con `dormido`; alcance y el encuadre en todos los clips.
- **Encuadre:** cada clip cada 0,1 s, con el Coloso girado hacia los héroes y la cámara de `_crear_rig_3d`: nudillos,
  placas, cabeza, monolitos, pies, lascas y rocas (con margen) caen dentro de la ventana 3D propuesta. Para que
  cupieran se recogieron el brazo de la carga, el izquierdo del golpe fuerte y los de la fase 2.

### Evidencias

- **Renders de Blender de cada clip** (hojas por clip y vistas de frente, perfil, espalda, grietas señaladas, fase 2 y
  estatua): `D:\REBELUM_diagnostico\v9\coloso_modelo\blender_capturas\` (`hoja_<clip>.png`, `hoja_vistas.png`).
- **`.blend` regenerable** (fuera del historial) y registros: `D:\REBELUM_diagnostico\v9\coloso_modelo\blender\`.

### Entrada propuesta para `MODELOS` de `combate.gd` (no la he tocado)

```gdscript
	# Coloso de la Falla (V9, jefe de la Garganta 3D): modelo 3D propio (animaciones, Blender; enemigos/coloso_falla/),
	# con el 2D de respaldo. ~140 px/m en la escena (4,16 m → ~585 px); ventana 3D con sitio para el brazo por encima de
	# la cabeza, los brazos abiertos de la fase 2, los puños en el suelo y las rocas.
	"coloso_falla": {
		"tipo": "3d", "esc": 0.64, "script": "res://enemigos/coloso_falla/coloso_falla_3d.gd",
		"gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/coloso_falla/coloso_falla.glb"],
		"vp": Vector2i(1260, 1360), "alto_vista": 6.2, "centro_y": 2.3, "barra_y": 150.0, "centro_3d": 2.7,
		"respaldo": "guardian"},
```

- **Medidas** (de la prueba): en la ventana 3D, los pies caen en y = 1 173 y lo alto (4,16 m) en 281; en la escena,
  los pies quedan a 751 px del origen del rig y lo alto a 180 (de ahí `barra_y` 150). `centro_3d` 2,7 = el núcleo.
- **La ventana 3D es mayor que la del Guardián** (1 260 × 1 360 frente a 1 000 × 1 120: ×1,53 píxeles; con
  `res_personajes` 0,7 en el móvil, 882 × 952). Es un solo enemigo en pantalla; su coste en el Redmi está **pendiente
  de medir**.
- **Respaldo:** `"guardian"` (el guardián de piedra 2D). Si se quiere más grande o teñido, una entrada nueva como
  `guardian_bosque2d` (por ejemplo `"tam": 1.5`, tinte gris violeta).
- **Con `esc` 0,64, el doble de Érebo** crece un poco (`clamp(esc / 0,6, 1, 1,6)` ≈ 1,07). `ALTURA` es 4,16, y
  `ALTURA · 0,55` ≈ 2,29 m (cintura alta; el núcleo está a 2,7 m).

**Sitio en el grupo:** para que los pies queden donde los del Guardián del Bosque en el grupo 11 (sus pies, a
(450, 494) desde el origen del grupo), el Coloso va en **`Vector2(47, -256)`** (sus pies, a (403, 751) del rig).
Ejemplo de grupo fijo: `[["coloso_falla", Vector2(47, -256)]]`. **No lo he comprobado en un combate de verdad.**

**Cómo atacar:** ya funciona con lo que hay en `combate.gd` (rama de `has_method("despertar")` → `_anim_guardian`),
poniendo `f["ataque_3d"]` a `"ataque"` o `"golpe_fuerte"`. Lo que falta es la ficha del turno (un `_turno_coloso`, como
`_turno_guardian`): el aviso con `await p.cargar("golpe_fuerte")`; al 50 %, `await p.fase2()` conectando antes
`p.placas_abiertas` al destello y al texto; y, si el diseño lo pide, `p.senalar_grietas(true)` cuando el Coloso quede
expuesto (por ejemplo, el turno después del golpe fuerte), con `p.punto_vulnerable()` para los efectos del crítico.

### Cómo poner el Coloso dormido en la Garganta 3D (la región)

```gdscript
var c: Node3D = load("res://enemigos/coloso_falla/coloso_falla_3d.gd").new()
c.dormido_al_empezar = true
add_child(c)                         # 1 unidad = 1 m; de pie mide 4,16 m
c.global_position = punto_de_la_arena
c.mirar(Vector3(0, 0, 1), 0.0)       # que mire a +Z del nodo
# … al acercarse el grupo o en la cinemática: c.despertar()  (señal clip_terminado("despertar"))
```
Solo el GLB: `ap.play("dormido")` (con `loop_mode` en bucle, o quieto en su última pose, que también vale); ya trae el
musgo y las grietas apagadas, pero sin el guion las runas brillan al máximo del material (no se atenúan).

### Límites (lo que no he comprobado)

- **Sin capturas de Godot en un combate de verdad ni vídeo:** solo renders de Blender por clip. La prueba comprueba el
  encuadre por cálculo (proyección de los huesos), no por imagen. Pendiente: una prueba con ventana como
  `prueba_guardian_fotos` (no la he hecho para no lanzar Godot con ventana mientras otro especialista hacía capturas
  del Coloso en `D:\Aethelgard_v9_coloso-combate`).
- **Rendimiento en el Redmi:** no medido (no se mide con otros especialistas trabajando). 9 042 triángulos, 29 huesos,
  2 materiales y sin texturas, pero ventana 3D mayor que la del Guardián.
- **Sin enganchar a `combate.gd` ni a la región:** archivos de otros. Ni `ENEMIGOS`, ni grupo, ni turno, ni sonido.
- **Sombra en la región y escala relativa a Kael 3D:** no comprobadas (1 unidad = 1 m, como el Guardián).
- **Halos de las grietas:** con prueba de profundidad, se cortan si tocan la piedra; están 0,22 m por fuera. No vistos
  en Godot con ventana.
- **Estilo:** los bloques redondeados se leen bien desde la cámara del combate en los renders; la paleta (gris violáceo,
  ocre y ámbar) se eligió con la de `zonas3d/garganta/materiales.gd`, pero no la he visto sobre el escenario real.

### Cambios que pido en archivos de otros

1. **`combate.gd`:** la entrada de `MODELOS`, `ENEMIGOS`, el grupo y el turno (arriba).
2. **La Garganta 3D:** el Coloso dormido en su arena y `despertar()` al empezar el combate.
3. **`docs/recursos.md`:** hecho en esta rama (`cd85299`). De paso: la fila del Guardián del Bosque tiene la ruta del
   `.blend` estropeada (le faltan las barras invertidas: `D:\REBELUM_diagnosticoase3\…`); no la he tocado porque no
   era parte del encargo.
