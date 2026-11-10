# Animaciones · Fase 3: modelo del Guardián del Bosque Olvidado

## 2026-11-10 15:55 · Entrega (rama `claude/f3-guardian-modelo`, copia `D:\Aethelgard_f3_modelo`)

Encargo: el modelo 3D del jefe de «El bosque que no recuerda», hecho con Blender 5.2.3 por guion, con geometría
procedural propia, listo para el combate ATB. Diseño: `docs/fase3_bosque/AVENTURA_JUGABLE.md`.

### Qué hay (observado en el código y comprobado ejecutando, 10/11, commits `bdec493`, `f79d02e` y `b97855c`)

| Archivo | Qué es |
|---|---|
| `aethelgard/enemigos/guardian_bosque/fuente/crear_guardian.py` | Genera malla, esqueleto, clips y GLB. Misma semilla, mismo GLB (SHA-256 igual en dos pasadas) |
| `aethelgard/enemigos/guardian_bosque/fuente/capturas_guardian.py` | Renderiza en Blender cada clip desde la vista del combate y compone las hojas |
| `aethelgard/enemigos/guardian_bosque/guardian_bosque.glb` (0,96 MB) y `.glb.import` | Modelo; el .import pone `corteza.tres` y `luz.tres` como materiales externos, sin LOD ni tangentes |
| `aethelgard/enemigos/guardian_bosque/corteza.tres`, `luz.tres` | Materiales de Godot (ver «Colores de vértice») |
| `aethelgard/enemigos/guardian_bosque/guardian_bosque_3d.gd` | Guion del modelo en combate (interfaz de `zarzalin_3d.gd` y lo nuevo) |
| `aethelgard/pruebas/prueba_guardian_modelo.gd` (auto) y `prueba_guardian_fotos.gd` (ventana) | Pruebas, registradas en `lista_pruebas.txt` |

**Aspecto:** criatura de madera de unos 3,75 m con la copa (cabeza a 3,15 m: algo más del doble que un héroe), tronco
con surcos y raíces que lo envuelven, brazos de rama con dedos de rama, piernas de raíz con pies de raíces abiertas,
musgo en hombros y espalda, copa de ramas como astas con hojas (verdes y algunas ámbar), barba de raíces, ojos y
corazón verde dorado emisivos con venas de luz y una jaula de raíces, y setas de repisa como acento cálido.

**Presupuesto:** 7 774 triángulos (máximo 12 000), 28 huesos (máximo 30), 1 malla, 2 materiales, ninguna textura.
Un halo (QuadMesh transparente) acompaña al corazón; lo crea el guion.

### Clips (30 fps; en el GLB empiezan en 0 s)

| Clip | Duración | Bucle | Anclas |
|---|---|---|---|
| `reposo` | 2,40 s | sí | respira (el corazón crece un 7 %) y se mece |
| `ataque` | 1,37 s | no | alza la rama a 0,33 s; **impacto 0,600 s**; acaba en el reposo |
| `carga` | 1,20 s | sí | encorvado; latidos a 0,13 y 0,40 s (el corazón hasta ×1,3) |
| `golpe_fuerte` | 1,97 s | no | empieza en la pose de la carga; se yergue a 0,37; **impacto 0,667 s**; raíces delante (1,7 m) hasta 0,77, se retiran hasta 1,4; acaba en el reposo |
| `herido` | 0,77 s | no | golpe a 0,10 s |
| `fase2` | 2,57 s | no | se recoge, late, se yergue a 1,03; coraza entera a 1,23 (señal a 0,933); acaba en el reposo con coraza |
| `derrota` | 2,37 s | no | cae de rodillas a 1,1 s, vencido a 1,63, manos en el suelo; la luz se apaga |
| `dormido` | 3,00 s | sí | de rodillas, inmóvil, cubierto de musgo (espalda, hombros, cabeza y suelo, con flores); el corazón late muy despacio |

**Piezas que se esconden con la escala de su hueso** (todas en la misma malla): la coraza (`coraza`, `coraza.L`,
`coraza.R`) está a escala 1 en los clips salvo en `dormido`, y en `fase2` crece de 0,01 a 1. **En la fase 1 la
esconde el guion.** El musgo del sueño (`musgo`, `musgo_cabeza`, `musgo_suelo`) solo se ve en `dormido`, y las raíces
del suelo (`raices_suelo`) solo en `golpe_fuerte`. Las del suelo crecen desde z = 0, sin asomar por debajo.

**Apoyos:** la altura de la raíz de cada pose se calcula para que lo más bajo de las piernas toque el suelo. En las
poses de rodillas, el giro del brazo se busca para que las manos queden a 2-5 cm del suelo.

### El guion (`guardian_bosque_3d.gd`)

**Misma interfaz que `zarzalin_3d.gd`:** `reposo`, `andar`/`correr` (no corre: se queda en reposo), `cansada`,
`herida`/`recibir_golpe`, `morir`/`derrota`, `victoria`, `revivir`, `entrada`, `mirar`, `mirar_frente`,
`lanzar_magia`/`punto_magia`/`fin_magia` (las esporas nacen en el corazón), `preparar_golpe`/`golpear`/`fin_golpe`,
`atacar(ataque, al_impactar)`, `alcance`, `tiempo_impacto`, `duracion`, `play`, `ALTURA` y `FRENTE_ENEMIGO`.

**Nuevas** (la interfaz no las tenía):
- `ataque(al_impactar)`
- `cargar(ataque)`: el bucle `carga`
- `golpe_fuerte(al_impactar)`: sigue desde la carga sin repetirla
- `fase2()`: con su señal `coraza_desplegada`
- `poner_fase(n)`, `en_fase2()`
- `dormir()`, `despertar()`
- `corazon()` y `punta_rama()`: posiciones en el mundo

**Alias de `atacar`:** `latigazo`, `raices`, `juicio`, `juicio_del_bosque`, `colmillo_lateral` y `embestida_espinosa`.

**Señales:** `aviso`, `impacto`, `coraza_desplegada`, `ataque_terminado` y `clip_terminado`.

**A propósito no tiene `avisar()`:** si lo tuviera, `combate.gd` lo mandaría por `_anim_zarzalin`, que galopa hasta el
héroe y vuelve de espaldas. El Guardián ataca desde su sitio: la rama llega 2,27 m por delante en el impacto.

**`entrada()`** = despertar: de `dormido` al reposo en 1,4 s; el musgo se retira con la mezcla.

**La luz** (corazón, ojos y venas) brilla según la escala del hueso `corazon`: 1,0 en reposo, hasta 1,66 en la carga,
2,3 en la transformación y 0,2 al ser derrotado.

### Colores de vértice: causa y arreglo (comprobado ejecutando, 10/11)

- **Primera captura en combate:** el Guardián salía oscuro y rojizo.
- **Causa:** glTF guarda los colores de vértice en lineal, y Godot los importó así (la luz llegó como 0,61, no como
  0,8). El renderizador Compatibility no convierte los colores de vértice: `vertex_color_is_srgb` no actúa en él.
  Además, la importación no activó `vertex_color_use_as_albedo`.
- **Arreglo:** los colores se guardan en sRGB en el GLB. `corteza.tres` tiene `vertex_color_use_as_albedo = true` y
  `vertex_color_is_srgb = true`, que es correcto también en Forward+ y Mobile.
- **En Blender,** un nodo Gamma 2,2 los muestra bien.
- **Resultado:** después del cambio, el color del combate coincide con el de los renders.
- **La prueba lo vigila:** el material debe leer los colores en el espacio en que llegan.
- **Ambos materiales** tienen una sola cara: las hojas tienen sus dos caras en la malla.

### Pruebas (comprobado ejecutando, aislado, 10/11)

- **`ejecutar_pruebas.ps1 -Manual -Solo prueba_guardian_modelo,prueba_guardian_fotos`** (desde PowerShell):
  - `prueba_guardian_modelo`: **SUPERADA**, 147 comprobaciones y 0 fallos;
  - `prueba_guardian_fotos`: **MANUAL**, 16 capturas sin errores;
  - partida real y carpeta real de datos sin cambios;
  - resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-10_155339\resumen.md`.
- **Antes de las pruebas,** importación aislada como `ci_local.ps1` (última:
  `D:\REBELUM_diagnostico\importaciones\f3_guardian_2026-11-10_155328`). `project.godot` no cambió; si hubiera
  cambiado, el guion de importación lo restauraba.
- **Qué comprueba `prueba_guardian_modelo`:**
  - los 8 clips, y que cada uno escribe los 28 huesos;
  - el presupuesto, los materiales y las caras;
  - los bucles sin salto, y que las acciones acaban en el reposo;
  - las piezas escondidas;
  - el impacto una vez y en su ancla (latigazo 0,600 s; golpe fuerte desde la carga 0,667 s);
  - el aviso de la carga una vez, y el golpe recibido en carga que vuelve a la carga;
  - el golpe a mitad del latigazo, que no lo corta;
  - la fase 2: la coraza escondida al empezar, la señal a 0,933 s, la coraza puesta y la que sigue tras atacar;
  - la luz, la derrota de rodillas sin atacar, revivir, dormir y entrada;
  - el GLB solo con `dormido` (sin coraza y con el musgo);
  - `ALTURA`, `alcance` y el encuadre.
- **Bucles:** como en `zarzalin_3d.gd`, los pone el guion. Poner `loop_mode` en los subrecursos del `.import` hacía
  que Godot lo reescribiera con 256 «slices» (209 KB), así que el `.import` lleva solo los materiales.

### Evidencias

- **Renders de Blender de cada clip** (hojas por clip y vistas de frente, perfil, espalda, fase 2 y dormido):
  `D:\REBELUM_diagnostico\fase3\guardian_modelo\blender_capturas\` (`hoja_<clip>.png`, `hoja_vistas.png`).
- **Capturas de Godot en un combate de verdad:** grupo 9, en la ventana 3D de Grimfang con el encuadre propuesto y
  junto a Kael, Lya y Garon. Están en `D:\REBELUM_diagnostico\fase3\guardian_modelo\godot_combate\`; la hoja, en
  `...\guardian_modelo\hoja_godot_combate.png`.
- **El registro de la prueba,** en `...\guardian_modelo\prueba_guardian_modelo.log`; el resumen, en
  `resumen_pruebas.md`.
- **`.blend` regenerable** (fuera del historial): `D:\REBELUM_diagnostico\fase3\guardian_modelo\blender\guardian_bosque.blend`.

### Entrada propuesta para `MODELOS` de `combate.gd` (no la he tocado: es del coordinador)

```gdscript
	# Guardián del Bosque Olvidado (fase 3; modelo propio de Blender, enemigos/guardian_bosque/). ~146 px/m en la
	# escena (3,75 m con la copa → ~550 px); ventana 3D con sitio para los brazos en alto (4,15 m) y las raíces.
	"guardian_bosque": {
		"tipo": "3d", "esc": 0.6, "script": "res://enemigos/guardian_bosque/guardian_bosque_3d.gd",
		"gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/guardian_bosque/guardian_bosque.glb"],
		"vp": Vector2i(1000, 1120), "alto_vista": 4.6, "centro_y": 1.95, "barra_y": 50.0, "centro_3d": 1.9,
		"respaldo": "guardian"},
```

**Medidas del encuadre** (de la prueba):
- en la ventana 3D, los pies caen en y = 1 024, el corazón en 534, la copa en 131 y los brazos en alto en 36;
- en la escena, los pies quedan a 615 px del origen del rig y la copa a 79 (de ahí `barra_y` 50).

**Con `esc` 0,6, el doble de Érebo** no crece (`clamp(esc / 0,6, 1, 1,6)` = 1). `ALTURA` es 3,75, y
`ALTURA · 0,55` ≈ 2,06 m, la altura del corazón.

**Sitio en el grupo:** para que los pies queden donde los de Grimfang en el grupo 9 (x 300, y 130), el Guardián va en
**`Vector2(150, -120)`**: los pies salen a 615 px del rig. Ejemplo:
`[["guardian_bosque", Vector2(150, -120)]]`.

**Cómo atacar desde su sitio:** propuesta para `_animar_golpe`, antes de la rama de `has_method("atacar_hacha")`:
```gdscript
	elif _p3d(origen) != null and _p3d(origen).has_method("golpe_fuerte"):     # Guardián del Bosque (fase 3)
		await _anim_guardian(origen, impacto, str(origen.get("ataque_3d", "ataque")))
...
# El Guardián ataca desde su sitio: la rama llega 2,27 m por delante y las raíces brotan a 1,7 m.
func _anim_guardian(o: Dictionary, impacto: Callable, ataque: String) -> void:
	var p = _p3d(o)
	o["animando"] = true
	var golpes := [0]
	var al_golpear := func():
		golpes[0] += 1
		if golpes[0] == 1:
			impacto.call()
			if ataque == "golpe_fuerte":
				_temblor(9.0)
	await p.atacar(ataque, al_golpear)
	if golpes[0] == 0:
		al_golpear.call()
	o["animando"] = false
```

**El resto de la ficha:**
- **El aviso de «Raíces que aprisionan»** y del «Juicio del bosque»: `await p.cargar("golpe_fuerte")`. Al turno
  siguiente, `f["ataque_3d"] = "golpe_fuerte"`.
- **Al 50 %:** `await p.fase2()`, conectando antes `p.coraza_desplegada` al destello, al tinte, a las hojas y al texto
  «¡El corazón del bosque despierta!».
- **Las esporas** van por `_anim_magia_3d`, que ya llama a `lanzar_magia`, `punto_magia` y `fin_magia`.

**Comprobado en las capturas:** con el sitio de Grimfang, la punta de la rama llega a Kael en el impacto.

### Cómo poner el Guardián dormido en una escena 3D (la región)

Recomendado, con el guion (despierta con el musgo retirándose):
```gdscript
var g: Node3D = load("res://enemigos/guardian_bosque/guardian_bosque_3d.gd").new()
g.dormido_al_empezar = true
add_child(g)                         # 1 unidad = 1 m; mide 3,75 m de pie (dormido, ~2 m)
g.global_position = punto_del_claro
g.mirar(Vector3(0, 0, 1), 0.0)       # que mire a +Z del nodo; luego se gira el nodo (o se pasa la dirección)
# … al empezar el combate o en la cinemática: g.despertar()  (señal clip_terminado("despertar"))
```

Solo el GLB:
```gdscript
var m: Node3D = load("res://enemigos/guardian_bosque/guardian_bosque.glb").instantiate()
add_child(m)
var ap: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
ap.get_animation("dormido").loop_mode = Animation.LOOP_LINEAR
ap.play("dormido")
```
- **El clip ya esconde la coraza y saca el musgo.** Si no se pone en bucle, se queda quieto en su última pose, que
  también vale.
- **Sin el guion,** la luz del corazón no se atenúa.

### Límites (lo que no he comprobado)

- **Rendimiento en el Redmi:** no medido. No se mide rendimiento con otros especialistas trabajando; lo programa el
  coordinador. Por el presupuesto (7 774 triángulos, 28 huesos, 2 materiales, sin texturas) debería costar menos que
  Zarzalín (2K y 3 texturas), pero está **pendiente de verificar**.
- **Sin enganchar a `combate.gd` ni a la región:** son archivos del coordinador. Las capturas sustituyen a Grimfang
  dentro de un combate de verdad, sin tocar `combate.gd`: es **simulado**.
- **Integración que falta:** el grupo, `ENEMIGOS` y las fases de `combate.gd`.
- **Sombra en la región:** no comprobada. `create_shadow_meshes` está activo.
- **Escala relativa al Kael 3D de la región:** no comprobada. Se supuso 1 unidad = 1 m, como Zarzalín.
- **Halo del corazón:** en el combate se nota poco, porque sobre el fondo transparente de la ventana 3D solo se ve
  encima del cuerpo. No lo he ajustado más.
- **Vídeo en movimiento:** no hay. Las capturas son poses fijas en sus momentos clave, más el despertar en marcha.
  Para un vídeo: Godot con `--write-movie`.
- **El `.uid` de `prueba_teclas_sistema.gd`:** lo crea la importación y queda sin seguimiento. No es mío y no lo he
  confirmado.

### Cambios que pido en archivos de otros

1. **`combate.gd`:** la entrada de `MODELOS`, el grupo, `_anim_guardian` y la rama de `_animar_golpe` (arriba).
2. **`docs/recursos.md`:** una fila nueva. **Obra propia: no hace falta línea en `licencias_pendientes.txt`.**

   > | Guardián del Bosque Olvidado (`aethelgard/enemigos/guardian_bosque/guardian_bosque.glb`, 0,96 MB, y los materiales `corteza.tres` y `luz.tres`) | Obra propia del proyecto: geometría procedural, esqueleto de 28 huesos y 8 clips generados con Blender 5.2.3 por `aethelgard/enemigos/guardian_bosque/fuente/crear_guardian.py` (2026-11-10, fase 3), sin recursos descargados | Propia, sin restricciones | Jefe de «El bosque que no recuerda» (combate y región) | El `.blend` se regenera con el guion; copia en `D:\REBELUM_diagnostico\fase3\guardian_modelo\blender\` |
