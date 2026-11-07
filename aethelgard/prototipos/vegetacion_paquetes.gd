extends "res://prototipos/sendero_puente.gd"
# PRUEBA AISLADA de vegetación con los paquetes descargados (REBELUM, Fase 2) — iteración 2 «composición y color».
#   - césped: EmacEArt Stylized Grass v1.3.0 (mata de 32 triángulos y su sombreado de viento con ráfagas);
#   - árboles, arbustos, helechos y flores: Quaternius Stylized Nature MegaKit (CC0).
# Mismo terreno, sendero, río, luz y perfiles que Pastos Verdes, pero con su vegetación sustituida SOLO en esta escena:
# así se compara de verdad y se puede medir en el Redmi. No cambia Pastos Verdes ni el juego.
# Solo usa la copia reducida de vegetacion_prueba/ (los ZIP originales siguen en Descargas).
# Abrir: prototipos/vegetacion_paquetes.tscn (F6).
#
# Dirección de arte de esta iteración:
#   - una sola paleta para todo (verdes salvia/esmeralda, sin lima fosforito); la saturación se controla aquí;
#   - dos variantes de árbol (las de copa más llena), mejor sombreadas de cerca;
#   - composición: bosquetes que enmarcan el camino, arbustos y helechos al pie de los árboles, flores en
#     manchas de una sola especie en los claros y en los bordes del camino; el camino y el puente quedan limpios.

const Q := "res://vegetacion_prueba/quaternius/"
const E := "res://vegetacion_prueba/emace/"
const FOLLAJE := "res://vegetacion_prueba/follaje.gdshader"

# --- paleta común (todo el follaje sale de aquí)
const PALETA := {
	"copa": [Color(0.5, 0.68, 0.3), Color(0.42, 0.63, 0.33)],   # las dos variantes de árbol: cálida y fresca
	"arbusto": Color(0.42, 0.62, 0.3),
	"arbusto_flor": Color(0.47, 0.66, 0.3),
	"planta": Color(0.9, 0.98, 0.82),          # helechos y tallos (su textura ya es verde: solo se templa)
	"bajo": Color(0.55, 0.68, 0.7),            # sombra fresca, algo azulada (biblia de arte: relleno azul)
	"alto": Color(1.25, 1.17, 0.88),           # luz cálida arriba
	"variacion": Color(1.1, 1.05, 0.74),       # algunos grupos de hojas más dorados
	"saturacion": 0.92,
}
const VARIANTES := ["CommonTree_1", "CommonTree_2"]

# Bosquetes: los sitios de árbol de Pastos Verdes (ya enmarcan el camino) más los dos sitios especiales.
const SITIOS := [Vector3(-13, 0, 6), Vector3(-6, 0, 12), Vector3(-19, 0, 12), Vector3(-1, 0, 10), Vector3(-8, 0, -4),
	Vector3(-14, 0, -6), Vector3(-2, 0, -9), Vector3(16, 0, 2), Vector3(22, 0, -4), Vector3(14, 0, -14),
	Vector3(-20, 0, -14), Vector3(4, 0, -16), Vector3(24, 0, 8), Vector3(-24, 0, 2), Vector3(26, 0, -18),
	Vector3(-12, 0, 18), Vector3(6, 0, 14), Vector3(-17, 0, -20), Vector3(17, 0, -9), Vector3(-4, 0, -14)]

var _ruido := FastNoiseLite.new()        # manchas grandes: praderas de flores y hierba más alta o más baja


# --- banco A/B (botón «VEG»): qué cuesta cada parte, en el mismo recorrido, cámara y perfil.
# «veg» en los cambios del perfil elige qué vegetación se construye:
#   original: la de Pastos Verdes · cesped_simple: césped nuevo con material sencillo (sin viento ni tinte)
#   cesped: césped nuevo con su sombreado de viento · arboles: solo árboles nuevos
#   plantas: solo arbustos, flores y helechos · todo: todo junto
# Ronda 1 (Redmi, 2026-11-06): el césped de EmacE bajaba a 9 FPS incluso sin viento -> ver docs/vegetacion_rendimiento.md
# Ronda 2 (Redmi): el césped opaco cuesta +4..6,6 ms; árboles y plantas de Quaternius, +20 ms cada grupo.
# Ronda 3 (Redmi): lo caro de árboles y arbustos es el recorte de transparencia (hojas opacas: 8 veces menos).
# Ronda 4 (candidata): hojas convertidas en geometría opaca (pruebas/herramientas/hojas_a_geometria.gd), césped
# opaco, plantas en sectores. Perfiles medio y bajo, a 20 y 34 m, con y sin tope de 30 FPS.
# Ronda 5 (experimento de sombras, botón VEG): misma vegetación candidata; A dinámica, B solo móviles (diagnóstico),
# C horneada, C+ horneada con la sombra dinámica de los móviles ajustada (1 tramo, 1024 px, 40 m). Bajo: hoy sin
# sombras; con C gana las sombras horneadas, y con C+ también la de Kael.
const _CMAS := {"sombra_modo": "horneada", "sombra_tramos": 1, "sombra_res": 1024, "dist_sombras": 40.0}
# Ronda 6 (experimento LOD, botón VEG): A vegetación y sombras actuales; B con LOD y sombras actuales; C con LOD y
# sombras C+. Además: impostor con recorte en vez de racimos, fundido de Godot entre niveles, tope de 30 FPS y bajo.
const _LOD_CMAS := {"veg_lod": true, "sombra_modo": "horneada", "sombra_tramos": 1, "sombra_res": 1024, "dist_sombras": 40.0}
# Ronda 7 (mallas indexadas, botón VEG): C (LOD + sombras C+) frente a C con «veg_indexada», en orden alterno
# (C, Ci, Ci, C) para que la temperatura o el orden no favorezcan a ninguna.
const _LOD_CMAS_IDX := {"veg_lod": true, "veg_indexada": true, "sombra_modo": "horneada", "sombra_tramos": 1,
	"sombra_res": 1024, "dist_sombras": 40.0}
const _BAJO_CMAS_IDX := {"veg_lod": true, "veg_indexada": true, "sombra_modo": "horneada", "sombras": true,
	"sombra_tramos": 1, "sombra_res": 1024, "dist_sombras": 40.0}
const _BAJO_CMAS := {"veg_lod": true, "sombra_modo": "horneada", "sombras": true, "sombra_tramos": 1, "sombra_res": 1024,
	"dist_sombras": 40.0}
# Ronda 8 (ajustes de sombreado, botón VEG; Mali Offline Compiler 2026-11-07): sobre C indexada, V1 sin reflejo del
# cielo, V2 = V1 + sombra de 1 lectura, V3 = V2 + terreno sin especular y Lambert. Orden alterno C, V1, V2, V3, V3, V2,
# V1, C (la temperatura o el orden no favorecen a ninguna); 20 y 34 m, y el perfil bajo.
const _V1 := {"veg_lod": true, "veg_indexada": true, "sombra_modo": "horneada", "sombra_tramos": 1, "sombra_res": 1024,
	"dist_sombras": 40.0, "veg_sin_reflejo": true}
const _V2 := {"veg_lod": true, "veg_indexada": true, "sombra_modo": "horneada", "sombra_tramos": 1, "sombra_res": 1024,
	"dist_sombras": 40.0, "veg_sin_reflejo": true, "veg_sombra_dura": true}
const _V3 := {"veg_lod": true, "veg_indexada": true, "sombra_modo": "horneada", "sombra_tramos": 1, "sombra_res": 1024,
	"dist_sombras": 40.0, "veg_sin_reflejo": true, "veg_sombra_dura": true, "veg_terreno_simple": true}
const _BAJO_V3 := {"veg_lod": true, "veg_indexada": true, "sombra_modo": "horneada", "sombras": true, "sombra_tramos": 1,
	"sombra_res": 1024, "dist_sombras": 40.0, "veg_sin_reflejo": true, "veg_sombra_dura": true, "veg_terreno_simple": true}
const BANCO_VEG := [["medio", 20.0, false, _LOD_CMAS_IDX, "C idx"], ["medio", 20.0, false, _V1, "V1 sin reflejo"],
	["medio", 20.0, false, _V2, "V2 +sombra"], ["medio", 20.0, false, _V3, "V3 +terreno"],
	["medio", 20.0, false, _V3, "V3 +terreno"], ["medio", 20.0, false, _V2, "V2 +sombra"],
	["medio", 20.0, false, _V1, "V1 sin reflejo"], ["medio", 20.0, false, _LOD_CMAS_IDX, "C idx"],
	["medio", 34.0, false, _LOD_CMAS_IDX, "C idx"], ["medio", 34.0, false, _V1, "V1 sin reflejo"],
	["medio", 34.0, false, _V2, "V2 +sombra"], ["medio", 34.0, false, _V3, "V3 +terreno"],
	["medio", 34.0, false, _V3, "V3 +terreno"], ["medio", 34.0, false, _V2, "V2 +sombra"],
	["medio", 34.0, false, _V1, "V1 sin reflejo"], ["medio", 34.0, false, _LOD_CMAS_IDX, "C idx"],
	["bajo", 20.0, false, _BAJO_CMAS_IDX, "bajo C idx"], ["bajo", 20.0, false, _BAJO_V3, "bajo V3"]]
const BANCO_VEG_RONDA7 := [["medio", 20.0, false, _LOD_CMAS, "C"], ["medio", 20.0, false, _LOD_CMAS_IDX, "C indexada"],
	["medio", 20.0, false, _LOD_CMAS_IDX, "C indexada"], ["medio", 20.0, false, _LOD_CMAS, "C"],
	["medio", 34.0, false, _LOD_CMAS, "C"], ["medio", 34.0, false, _LOD_CMAS_IDX, "C indexada"],
	["medio", 34.0, false, _LOD_CMAS_IDX, "C indexada"], ["medio", 34.0, false, _LOD_CMAS, "C"],
	["bajo", 20.0, false, _BAJO_CMAS, "bajo C"], ["bajo", 20.0, false, _BAJO_CMAS_IDX, "bajo C idx"],
	["medio", 20.0, false, _LOD_CMAS_IDX, "C indexada", true], ["medio", 34.0, false, _LOD_CMAS_IDX, "C indexada", true]]
const BANCO_VEG_RONDA6 := [["medio", 20.0, false, {}, "A actual"],
	["medio", 20.0, false, {"veg_lod": true}, "B LOD"],
	["medio", 20.0, false, _LOD_CMAS, "C LOD+C+"],
	["medio", 34.0, false, {}, "A actual"],
	["medio", 34.0, false, {"veg_lod": true}, "B LOD"],
	["medio", 34.0, false, _LOD_CMAS, "C LOD+C+"],
	["medio", 34.0, false, {"veg_lod": true, "veg_lod2": "impostor"}, "B LOD impost."],
	["medio", 34.0, false, {"veg_lod": true, "veg_lod_fundido": true, "sombra_modo": "horneada", "sombra_tramos": 1,
		"sombra_res": 1024, "dist_sombras": 40.0}, "C fundido"],
	["bajo", 20.0, false, {"veg_lod": true, "sombra_modo": "horneada", "sombras": true, "sombra_tramos": 1,
		"sombra_res": 1024, "dist_sombras": 40.0}, "bajo LOD+C+"],
	["bajo", 34.0, false, {"veg_lod": true, "sombra_modo": "horneada", "sombras": true, "sombra_tramos": 1,
		"sombra_res": 1024, "dist_sombras": 40.0}, "bajo LOD+C+"],
	["medio", 20.0, false, _LOD_CMAS, "C LOD+C+", true],
	["medio", 34.0, false, _LOD_CMAS, "C LOD+C+", true]]
const BANCO_VEG_RONDA5 :=[["medio", 20.0, false, {}, "A dinamica"],
	["medio", 20.0, false, {"sombra_modo": "moviles"}, "B moviles"],
	["medio", 20.0, false, {"sombra_modo": "horneada"}, "C horneada"],
	["medio", 20.0, false, _CMAS, "C+ ajustada"],
	["medio", 34.0, false, {}, "A dinamica"],
	["medio", 34.0, false, {"sombra_modo": "moviles"}, "B moviles"],
	["medio", 34.0, false, {"sombra_modo": "horneada"}, "C horneada"],
	["medio", 34.0, false, _CMAS, "C+ ajustada"],
	["bajo", 20.0, false, {}, "bajo actual"],
	["bajo", 20.0, false, {"sombra_modo": "horneada"}, "bajo C"],
	["bajo", 20.0, false, {"sombra_modo": "horneada", "sombras": true, "sombra_tramos": 1, "sombra_res": 1024,
		"dist_sombras": 40.0}, "bajo C+"],
	["medio", 20.0, false, _CMAS, "C+ ajustada", true],
	["medio", 34.0, false, _CMAS, "C+ ajustada", true]]
const BANCO_VEG_RONDA4 :=[["medio", 20.0, false, {"veg": "nada"}, "sin vegetacion"],
	["medio", 20.0, false, {"veg": "original"}, "original"],
	["medio", 34.0, false, {"veg": "original"}, "original"],
	["medio", 20.0, false, {"veg": "arboles"}, "arboles geom."],
	["medio", 20.0, false, {"veg": "plantas"}, "plantas geom."],
	["medio", 20.0, false, {"veg": "todo", "veg_hojas_geom": false}, "candid. alfa"],
	["medio", 20.0, false, {"veg": "todo"}, "candidata"],
	["medio", 34.0, false, {"veg": "todo"}, "candidata"],
	["medio", 20.0, false, {"veg": "todo"}, "candidata", true],
	["medio", 34.0, false, {"veg": "todo"}, "candidata", true],
	["bajo", 20.0, false, {"veg": "todo"}, "candidata bajo"],
	["bajo", 34.0, false, {"veg": "todo"}, "candidata bajo"],
	["bajo", 20.0, false, {"veg": "todo"}, "candid. bajo", true],
	["bajo", 34.0, false, {"veg": "todo"}, "candid. bajo", true]]


func _veg() -> String:
	return perfil.get("veg", "todo")


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super._crear_panel_rnd(capa)
	var bv := Button.new()
	bv.text = "VEG"
	bv.position = Vector2(1160, 332)
	bv.custom_minimum_size = Vector2(108, 56)
	bv.focus_mode = Control.FOCUS_NONE
	bv.pressed.connect(func(): _empezar_banco(BANCO_VEG))
	capa.add_child(bv)


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	_ruido.seed = 31
	_ruido.frequency = 0.045
	super._ready()
	_experimento_sombras()
	_ajustes_sombreado()
	print("CARGA escena (%s): %d ms" % [perfil.get("veg_lod", false), Time.get_ticks_msec() - t0])


func _crear_ambiente() -> void:
	super._crear_ambiente()
	if _veg() == "original":
		return
	for n in get_children():
		if n is WorldEnvironment:
			n.environment.adjustment_saturation = 1.2    # Pastos Verdes usa 1,3: con este follaje se iba a lo fosforito
			n.environment.adjustment_contrast = 1.08


# El suelo bajo la hierba, del mismo verde que la base del césped: los huecos entre matas no se leen como manchas.
func _color_terreno(x: float, z: float, y: float, pendiente: float) -> Color:
	var c := super._color_terreno(x, z, y, pendiente)
	if _veg() != "original" and y > -0.5 and pendiente < 0.5:
		var junto := smoothstep(1.7, 2.4, _dist_sendero_xz(x, z))
		c = c.lerp(Color(0.3, 0.44, 0.2), 0.8 * junto)
	return c


func _crear_escenario() -> void:
	arboles_mapa = _veg() == "original"
	super._crear_escenario()
	seed(777)
	if _veg() != "original":
		_bosquetes()


# --- césped (sustituye a la hierba y a las flores de Pastos Verdes, solo en esta escena)
func _hierba_y_flores() -> void:
	if _veg() == "original":
		super._hierba_y_flores()
		return
	if not _veg() in ["cesped", "cesped_simple", "todo"]:
		return
	var mata: Mesh = load(E + "EA_Grass_Clump.mesh")
	var mat := ShaderMaterial.new()
	mat.shader = load(E + "EA_GrassWind.gdshader")
	# parten del material «EA_Grass_Green» del paquete; color llevado a la paleta y manchas más suaves (menos ruido)
	var valores := {"albedo_texture": load(E + "GRASS_DIFF.tga"), "normal_texture": load(E + "GRASS_NMAP.tga"),
		"base_color": Color(0.9, 1.04, 0.46), "alpha_cutoff": 0.594, "normal_strength": 0.57, "smoothness": 0.0,
		"wind_strength": 0.28, "wind_speed": 0.9, "wind_frequency": 0.8, "wind_direction_x": 1.0, "wind_direction_z": 0.35,
		"anchor_height": 0.87, "gust_strength": 0.55, "gust_scale": 0.05, "gust_speed": 0.35,
		"tint_color_small": Color(1.0, 0.9, 0.55), "stripes_mode_small": false, "tint_intensity_small_blob": 0.5,
		"tint_color_large": Color(0.62, 0.8, 0.62), "stripes_mode_large": false, "tint_intensity_large_blob": 0.3,
		"tint_scale_large_blob": 0.12, "tint_width_large_blob": 0.6, "tint_speed_large_blob": 0.15,
		"ambient_lift": 0.4, "ambient_tint": Color(0.74, 0.82, 0.8), "normal_up_bias": 0.75, "tint_quality": 1}
	for k in valores:
		mat.set_shader_parameter(k, valores[k])
	var material: Material = mat
	if _veg() == "cesped_simple":                        # A/B: la misma mata con un material sencillo, sin viento
		var sm := StandardMaterial3D.new()
		sm.albedo_texture = valores["albedo_texture"]
		sm.albedo_color = Color(0.7, 0.85, 0.4)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		sm.alpha_scissor_threshold = 0.594
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		sm.roughness = 1.0
		material = sm
	var opt := _opt()
	if opt and not _alto():
		mat.set_shader_parameter("tint_quality", 0)    # manchas de color calculadas por vértice, no por píxel
	var n := int(perfil["hierba"] * 0.9)
	if _cesped() == "hojas":
		# móvil: matas de hojas OPACAS (sin recorte de transparencia). Medido en el Redmi: las tarjetas recortadas
		# de EmacE se pintan muchas veces por píxel (la Mali no puede descartar lo tapado) y bajan a 9 FPS
		mata = _mata_hojas()
		material = mata.surface_get_material(0)
		n = int(perfil["hierba"] * float(perfil.get("veg_hojas_factor", 1.6)))
	var lista: Array = []
	if opt:
		# rejilla con desorden (no azar puro): el azar amontona matas en unos sitios (dibujar dos veces el mismo
		# píxel) y deja calvas en otros; la rejilla cubre igual con las mismas matas
		var lado := sqrt(58.0 * 54.0 / float(n) * 0.82)     # ~82 % del área es andable (sin camino ni barranco)
		var x := -26.0
		while x < 32.0:
			var z := -28.0
			while z < 26.0:
				var p := Vector3(x + randf_range(-0.45, 0.45) * lado, 0, z + randf_range(-0.45, 0.45) * lado)
				if _libre(p, 1.3):
					lista.append(p)
				z += lado
			x += lado
	else:
		var intentos := 0
		while lista.size() < n and intentos < n * 4:
			intentos += 1
			var p := Vector3(randf_range(-26, 32), 0, randf_range(-28, 26))
			if _libre(p, 1.3):
				lista.append(p)
	# detalle según la distancia: cerca, todas las matas; lejos, una de cada dos (el suelo ya es del color del
	# césped, así que lejos no se ven calvas). Las distancias van con la de la cámara (20-34 m).
	var cerca: float = perfil["dist_hierba"] if not opt else maxf(perfil["dist_hierba"], 44.0)
	var lejos: float = cerca if not opt else cerca + 22.0
	var trozos := {}
	for p in lista:
		var clave := Vector2i(floori(p.x / TROZO_HIERBA), floori(p.z / TROZO_HIERBA))
		if not trozos.has(clave):
			trozos[clave] = []
		trozos[clave].append(p)
	for clave in trozos:
		var centro := Vector3((clave.x + 0.5) * TROZO_HIERBA, 0, (clave.y + 0.5) * TROZO_HIERBA)
		centro.y = altura(centro.x, centro.z)
		var todos: Array = trozos[clave]
		for capa in 2:                         # capa 0: una de cada dos matas, llega lejos; capa 1: el resto, solo cerca
			var puntos: Array = []
			for k in todos.size():
				if k % 2 == capa:
					puntos.append(todos[k])
			if puntos.is_empty():
				continue
			_trozo_cesped(puntos, centro, mata, material, lejos if capa == 0 else cerca)


func _opt() -> bool:
	return perfil.get("veg_opt", true)


func _alto() -> bool:
	return load("res://prototipos/calidad_proto.gd").actual() == "alto"


func _trozo_cesped(puntos: Array, centro: Vector3, mata: Mesh, material: Material, hasta: float) -> void:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mata
		mm.instance_count = puntos.size()
		for k in puntos.size():
			var p: Vector3 = puntos[k]
			# altura: ondas suaves de pradera (ruido grande) y más baja junto al camino (borde limpio y legible)
			var onda := 0.5 + 0.5 * _ruido.get_noise_2d(p.x * 0.7, p.z * 0.7)
			var borde := lerpf(0.55, 1.0, smoothstep(1.3, 3.4, _dist_sendero(p)))
			var e := lerpf(0.58, 1.0, onda) * borde * randf_range(0.9, 1.1)
			var b := Basis(Vector3.UP, randf() * TAU)
			b = Basis(Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized(), deg_to_rad(randf_range(-4, 4))) * b
			mm.set_instance_transform(k, Transform3D(b.scaled(Vector3(e, e * randf_range(0.9, 1.15), e)),
				Vector3(p.x, altura(p.x, p.z) - 0.03, p.z) - centro))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = material
		mmi.position = centro
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = hasta
		add_child(mmi)
		if _lod() and _cesped() == "hojas":
			_lod_cesped(mmi, hasta)


func _arbustos() -> void:
	if _veg() == "original":
		super._arbustos()                         # los arbustos de esta prueba salen de _bosquetes()


# --- modelos del paquete Quaternius

func _malla_q(nombre: String) -> Mesh:
	var sc: Node = load(Q + nombre + ".gltf").instantiate()
	var mi: MeshInstance3D = sc.find_children("*", "MeshInstance3D", true, false)[0]
	var m: Mesh = mi.mesh
	sc.free()
	return m


func _es_follaje(m: Material) -> bool:
	return m != null and (m.resource_name.begins_with("Leaves") or m.resource_name == "Flowers")


# Caja de los vértices de una superficie (para el centro y el radio de la copa).
func _caja_superficie(malla: Mesh, s: int) -> AABB:
	var vs: PackedVector3Array = malla.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
	var caja := AABB(vs[0], Vector3.ZERO)
	for v in vs:
		caja = caja.expand(v)
	return caja


# Material de follaje con la paleta común. «verde»: tiñe la hoja blanca del paquete (las «_C» vienen coloreadas,
# algunas rojas de otoño). «flor»: pétalos, solo se templa la saturación.
var _shader_opaco: Shader


# «veg_follaje» (solo para el banco A/B): "opaco" = el mismo sombreado sin recorte de transparencia (mide lo que cuesta
# el recorte en la Mali); "estandar" = material estándar de Godot con recorte (mide lo que cuesta nuestro sombreado).
func _follaje(original: Material, malla: Mesh, s: int, ajustes: Dictionary) -> Material:
	var sm := ShaderMaterial.new()
	sm.shader = load(FOLLAJE)
	if perfil.get("veg_follaje", "") == "opaco" or _hojas_geom(malla):
		if _shader_opaco == null:
			_shader_opaco = Shader.new()
			_shader_opaco.code = sm.shader.code.replace("ALPHA = t.a;", "").replace("ALPHA_SCISSOR_THRESHOLD = corte;", "")
		sm.shader = _shader_opaco
	var tex: Texture2D = original.albedo_texture
	if perfil.get("veg_follaje", "") == "estandar":
		var st := StandardMaterial3D.new()
		st.albedo_texture = tex if not tex.resource_path.ends_with("_C.png") else load(tex.resource_path.replace("_C.png", ".png"))
		st.albedo_color = ajustes.get("verde", Color(0.9, 0.95, 0.85))
		st.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		st.cull_mode = BaseMaterial3D.CULL_DISABLED
		return st
	if ajustes.has("verde") and tex.resource_path.ends_with("_C.png"):
		tex = load(tex.resource_path.replace("_C.png", ".png"))
		ajustes["tinte"] = ajustes["verde"]
	ajustes.erase("verde")
	sm.set_shader_parameter("albedo_tex", tex)
	var caja := malla.get_aabb()
	var hojas := _caja_superficie(malla, s)
	var comunes := {"base_y": caja.position.y, "alto": caja.size.y, "centro": hojas.get_center(),
		"radio": hojas.size[hojas.get_longest_axis_index()] * 0.5, "color_bajo": PALETA["bajo"], "color_alto": PALETA["alto"],
		"color_variacion": PALETA["variacion"], "saturacion": PALETA["saturacion"]}
	comunes.merge(ajustes, true)
	for k in comunes:
		sm.set_shader_parameter(k, comunes[k])
	return sm


var _mallas := {}                  # nombre de árbol -> malla con los materiales de la paleta (compartida)


func _malla_arbol(nombre: String, v: int) -> Mesh:
	if _mallas.has(nombre):
		return _mallas[nombre]
	var malla: Mesh = _malla_hojas(nombre)
	if float(perfil.get("veg_copa_ligera", 0.0)) > 0.0:
		malla = _aligerar(malla, float(perfil["veg_copa_ligera"]))
	for s in malla.get_surface_count():
		var m := malla.surface_get_material(s)
		if _es_follaje(m):
			# con la sombra sencilla (medio/bajo) la copa no se sombrea a sí misma y sale más clara: se compensa el tono
			var verde: Color = PALETA["copa"][v] * (0.92 if perfil.get("arbol_sombra_simple", false) and _opt() else 1.0) * (0.95 if nombre.ends_with("_lod2") else 1.0)   # LOD2: igualado midiendo el color de la misma copa en LOD0
			malla.surface_set_material(s, _follaje(m, malla, s, {"verde": verde, "normal_esfera": 0.8,
				"oclusion": 0.45, "variacion": 0.7, "viento": 0.1, "viento_vel": 1.0,
				"contraluz": Color(0.24, 0.28, 0.1), "relleno": 0.1}))
		elif m is StandardMaterial3D:
			var c: StandardMaterial3D = m.duplicate()
			c.roughness = 0.95
			c.normal_scale = 0.9
			c.albedo_color = Color(0.74, 0.68, 0.66)       # corteza menos anaranjada, hacia el marrón de la paleta
			malla.surface_set_material(s, c)
		if _es_follaje(m):
			malla.set_meta("copa", _caja_superficie(malla, s))
	_mallas[nombre] = malla
	return malla


func _arbol_q(v: int, sitio: Vector3, escala: float, giro: float) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = Vector3(sitio.x, altura(sitio.x, sitio.z) - 0.1, sitio.z)
	cuerpo.rotation.y = giro
	cuerpo.scale = Vector3.ONE * escala
	add_child(cuerpo)
	var mi := MeshInstance3D.new()
	mi.mesh = _malla_arbol(VARIANTES[v], v)
	cuerpo.add_child(mi)
	_anotar_arbol(cuerpo, mi.mesh)
	if float(perfil.get("veg_copa_ligera", 0.0)) > 0.0 and mi.mesh.has_meta("copa"):
		_nucleo_copa(cuerpo, mi.mesh.get_meta("copa"), v)
	# perfiles medio/bajo: la sombra la da una forma sencilla (bola + tronco), no hoja a hoja (lo caro en el Redmi)
	if perfil.get("arbol_sombra_simple", false) and _opt() and mi.mesh.has_meta("copa"):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var copa: AABB = mi.mesh.get_meta("copa")
		# un disco horizontal en la parte baja de la copa: en el suelo da casi la misma sombra que la copa entera,
		# y como la luz viene de arriba no oscurece la propia copa (una bola sí lo hacía)
		var disco := CylinderMesh.new()
		disco.top_radius = minf(copa.size.x, copa.size.z) * 0.42
		disco.bottom_radius = disco.top_radius * 0.9
		disco.height = 0.25
		disco.radial_segments = 12
		var sb := MeshInstance3D.new()
		sb.mesh = disco
		sb.position = copa.get_center() - Vector3(0, copa.size.y * 0.18, 0)
		sb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		cuerpo.add_child(sb)
		var tronco := CylinderMesh.new()
		tronco.top_radius = 0.18
		tronco.bottom_radius = 0.3
		tronco.height = copa.position.y + 0.5
		tronco.radial_segments = 6
		var st := MeshInstance3D.new()
		st.mesh = tronco
		st.position.y = tronco.height * 0.5
		st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		cuerpo.add_child(st)
	_lod_arbol(cuerpo, mi, v)
	var col := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.4
	cil.height = 3.0
	col.shape = cil
	col.position.y = 1.5
	cuerpo.add_child(col)


# Una MultiMesh por modelo de planta, con los materiales de la paleta.
func _multimesh_planta(nombre: String, sitios: Array, esc: Vector2, viento: float, verde, sombra := false) -> void:
	var solo: String = perfil.get("veg_plantas_solo", "")
	if solo != "" and not nombre.begins_with({"flores": "Flower", "arbustos": "Bush", "helechos": "Fern"}[solo]):
		return
	print("VEG planta %s: %d" % [nombre, sitios.size()])
	if sitios.is_empty():
		return
	var malla: Mesh = _malla_hojas(nombre)
	var arbusto := nombre.begins_with("Bush")
	if arbusto and float(perfil.get("veg_arbusto_ligero", 0.0)) > 0.0:
		malla = _aligerar(malla, float(perfil["veg_arbusto_ligero"]))
	# experimento LOD: los arbustos tienen un segundo nivel (LOD1) para lejos
	var malla1: Mesh = _malla_hojas(nombre + "_lod1") if arbusto and _lod() else null
	for mx in ([malla] if malla1 == null else [malla, malla1]):
		_preparar_planta(mx, viento, verde, arbusto)
	# en sectores (como el césped): lo que queda fuera de la cámara no se dibuja. En un solo bloque para todo el
	# mapa se dibujaban siempre todas (medido: cientos de grupos de flores de 750-1700 triángulos cada uno)
	var sectores := {}
	var trozo: float = TROZO_HIERBA if perfil.get("veg_plantas_sectores", true) else 1000.0
	for p in sitios:
		var clave := Vector2i(floori(p.x / trozo), floori(p.z / trozo))
		if not sectores.has(clave):
			sectores[clave] = []
		sectores[clave].append(p)
	for clave in sectores:
		var lista: Array = sectores[clave]
		var centro := Vector3((clave.x + 0.5) * trozo, 0, (clave.y + 0.5) * trozo)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = malla
		mm.instance_count = lista.size()
		for k in lista.size():
			var p: Vector3 = lista[k]
			var e := randf_range(esc.x, esc.y)
			if arbusto:
				_oclusores.append(["contacto", Vector3(p.x, altura(p.x, p.z), p.z), 0.75 * e])
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(Vector3.ONE * e),
				Vector3(p.x, altura(p.x, p.z) - 0.05, p.z) - centro))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = centro
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra and perfil.get("veg_sombra_plantas", _alto()) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		if malla1 != null:
			_lod_planta(mmi, malla1)


func _lejos_de(p: Vector3, lista: Array, d: float) -> bool:
	for q in lista:
		if Vector2(p.x - q.x, p.z - q.z).length() < d:
			return false
	return true


# Composición: árboles en los sitios de los bosquetes; al pie, arbustos y helechos (como crecen de verdad: a la
# sombra y en el borde del bosque); flores en manchas de una sola especie en los claros y junto al camino.
func _bosquetes() -> void:
	var arboles: Array = []
	for k in SITIOS.size():
		var p: Vector3 = SITIOS[k]
		var v := k % 2 if k % 5 != 3 else 0                 # más del árbol redondo; el fresco salpicado
		var esc := randf_range(0.82, 1.05)
		var giro := randf() * TAU
		if _veg() in ["arboles", "todo"]:
			_arbol_q(v, p, esc, giro)
		arboles.append(p)
	var arbustos: Array = []
	var arbustos_flor: Array = []
	var helechos: Array = []
	for p in arboles:
		for j in randi_range(1, 2):
			var a := randf() * TAU
			var q: Vector3 = p + Vector3(cos(a), 0, sin(a)) * randf_range(2.2, 3.2)
			if _libre(q, 2.0) and _lejos_de(q, arbustos + arbustos_flor, 2.0):
				(arbustos_flor if randf() < 0.45 else arbustos).append(q)
		for j in randi_range(2, 3):
			var a := randf() * TAU
			var q: Vector3 = p + Vector3(cos(a), 0, sin(a)) * randf_range(1.0, 2.4)
			if _libre(q, 1.8):
				helechos.append(q)
	# flores: manchas en los claros (lejos de los árboles) y algunas acompañando el borde del camino
	var factor := float(perfil["flores"]) / 450.0 * float(perfil.get("veg_flores_factor", 1.0))
	var amarillas: Array = []
	var rosas: Array = []
	var manchas := 0
	var intentos := 0
	while manchas < int(36 * factor) and intentos < 4000:
		intentos += 1
		var c := Vector3(randf_range(-24, 30), 0, randf_range(-26, 24))
		var ds := _dist_sendero(c)
		var claro := _ruido.get_noise_2d(c.x, c.z) > 0.05
		var borde := ds > 2.2 and ds < 3.2
		if not (claro or borde) or not _libre(c, 2.2) or not _lejos_de(c, arboles, 3.0):
			continue
		manchas += 1
		var lista: Array = amarillas if manchas % 3 == 0 else rosas     # más rosa (cálido) que amarillo
		for j in randi_range(7, 12):
			var q := c + Vector3(randfn(0.0, 0.75), 0, randfn(0.0, 0.75))
			if _libre(q, 1.9):
				lista.append(q)
	if not _veg() in ["plantas", "todo"]:
		return
	_multimesh_planta("Bush_Common", arbustos, Vector2(0.9, 1.2), 0.05, PALETA["arbusto"], true)
	_multimesh_planta("Bush_Common_Flowers", arbustos_flor, Vector2(0.85, 1.1), 0.05, PALETA["arbusto_flor"], true)
	_multimesh_planta("Fern_1", helechos, Vector2(0.42, 0.6), 0.06, null)
	_multimesh_planta("Flower_3_Group", rosas, Vector2(0.3, 0.42), 0.08, null)
	_multimesh_planta("Flower_4_Group", amarillas, Vector2(0.28, 0.38), 0.08, null)


# --- césped para móvil (perfiles medio y bajo): matas de hojas opacas
# «veg_cesped» en el perfil: "emace" (tarjetas del paquete, la referencia del alto) u "hojas" (opacas, móvil).
func _cesped() -> String:
	return perfil.get("veg_cesped", "emace" if _alto() else "hojas")


const SHADER_HOJAS := """
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
// Hojas de hierba opacas: sin textura ni transparencia (en la Mali, lo opaco se descarta antes de pintarse
// si queda tapado). Color por vértice (base oscura, punta clara) y viento: ondas que cruzan la pradera
// en la dirección del viento + un balanceo propio de cada hoja. La normal apunta hacia arriba (luz de pradera).
uniform vec4 tinte : source_color = vec4(1.0);
uniform vec3 color_punta : source_color = vec3(0.98, 0.94, 0.6);
uniform float viento = 0.22;
uniform float viento_vel = 1.1;
uniform vec2 viento_dir = vec2(0.94, 0.33);
uniform sampler2D sombra_mapa : source_color, hint_default_white, filter_linear_mipmap, repeat_disable;
uniform vec3 sombra_rect = vec3(0.0, 0.0, 1.0);
varying vec2 v_suelo;
varying float v_alto;
void vertex() {
	float h = clamp(VERTEX.y / 0.6, 0.0, 1.0);
	v_alto = h;
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_suelo = (w.xz - sombra_rect.xy) * sombra_rect.z;
	float ola = sin(dot(w.xz, viento_dir) * 0.35 - TIME * viento_vel * 1.6) * 0.6
		+ sin(dot(w.xz, viento_dir.yx) * 0.9 - TIME * viento_vel * 2.3) * 0.25;
	float propio = sin(TIME * viento_vel * 3.1 + VERTEX.x * 9.0 + VERTEX.z * 7.0 + w.x) * 0.2;
	vec3 empuje = vec3(viento_dir.x, 0.0, viento_dir.y) * (ola + propio + 0.35) * viento * h * h;
	mat3 m = mat3(MODEL_MATRIX);
	VERTEX += (empuje * m) / max(dot(m[0], m[0]), 1e-4);
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.8));
}
void fragment() {
	vec3 c = COLOR.rgb * tinte.rgb;
	c = mix(c, c * color_punta * 1.25, smoothstep(0.55, 1.0, v_alto));
	ALBEDO = c * texture(sombra_mapa, v_suelo).rgb;
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.18, 0.22, 0.08) * v_alto;
}
"""


# Una mata: hojas finas en abanico, curvadas, de alturas distintas; tres triángulos por hoja.
func _mata_hojas(hojas := 11, ancho_f := 1.0) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 99
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for k in hojas:
		var a := TAU * k / hojas + r.randf_range(-0.3, 0.3)
		var dir := Vector3(cos(a), 0, sin(a))
		var lado := Vector3(-dir.z, 0, dir.x)
		var base := dir * r.randf_range(0.0, 0.16)
		var alto := r.randf_range(0.32, 0.6)
		var ancho := r.randf_range(0.035, 0.055) * ancho_f
		var curva := dir * r.randf_range(0.08, 0.2)
		# color: base sombreada y cuerpo con algo de variación (unas hojas más frescas, otras más doradas)
		var cuerpo := Color(0.36, 0.56, 0.2).lerp(Color(0.46, 0.6, 0.2), r.randf())
		var pie := Color(0.17, 0.3, 0.13)
		var p0 := base - lado * ancho
		var p1 := base + lado * ancho
		var m := base + curva * 0.45 + Vector3(0, alto * 0.55, 0)
		var p2 := m - lado * ancho * 0.75
		var p3 := m + lado * ancho * 0.75
		var punta := base + curva + Vector3(0, alto, 0)
		var n := (dir + Vector3(0, 0.6, 0)).normalized()
		for t in [[p0, pie], [p1, pie], [p3, cuerpo], [p0, pie], [p3, cuerpo], [p2, cuerpo],
				[p2, cuerpo], [p3, cuerpo], [punta, cuerpo.lightened(0.15)]]:
			st.set_color(t[1])
			st.set_normal(n)
			st.add_vertex(t[0])
	if perfil.get("veg_indexada", false):
		st.index()            # experimento: vértices idénticos compartidos (misma imagen, menos vértices)
	var malla := st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER_HOJAS
	malla.surface_set_material(0, mat)
	return malla


# --- copas más ligeras para la Mali (perfiles medio/bajo)
# Medido en el Redmi: lo caro de árboles y arbustos es el recorte de transparencia de las hojas (con hojas opacas
# cuestan 8 veces menos), porque la copa apila muchas capas de tarjetas y cada capa se pinta. Se quitan las tarjetas
# del interior (casi no se ven) y se pone dentro un volumen opaco del verde en sombra que tapa los huecos y deja a la
# GPU descartar lo que queda detrás. «umbral»: distancia al centro (1 = borde de la copa) por debajo de la cual se quitan.
func _aligerar(malla: Mesh, umbral: float) -> Mesh:
	var nueva := ArrayMesh.new()
	for s in malla.get_surface_count():
		var arr := malla.surface_get_arrays(s)
		var m := malla.surface_get_material(s)
		if _es_follaje(m) and arr[Mesh.ARRAY_INDEX] != null:
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var caja := _caja_superficie(malla, s)
			var c := caja.get_center()
			var mitad := caja.size * 0.5
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var quedan := PackedInt32Array()
			for t in range(0, idx.size(), 3):
				var g := (vs[idx[t]] + vs[idx[t + 1]] + vs[idx[t + 2]]) / 3.0
				if ((g - c) / mitad).length() >= umbral:
					quedan.append_array([idx[t], idx[t + 1], idx[t + 2]])
			print("VEG aligerar: %d -> %d triángulos" % [idx.size() / 3, quedan.size() / 3])
			arr[Mesh.ARRAY_INDEX] = quedan
		nueva.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		nueva.surface_set_material(s, m)
	return nueva


# Volumen opaco dentro de la copa (solo con la copa aligerada).
func _nucleo_copa(cuerpo: Node3D, copa: AABB, v: int) -> void:
	var bola := SphereMesh.new()
	bola.radius = 1.0
	bola.height = 2.0
	bola.radial_segments = 12
	bola.rings = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(PALETA["copa"][v]) * 0.62
	mat.roughness = 1.0
	bola.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = bola
	mi.position = copa.get_center()
	mi.scale = copa.size * 0.5 * float(perfil.get("veg_nucleo", 0.45))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cuerpo.add_child(mi)


# --- hojas como geometría opaca (pruebas/herramientas/hojas_a_geometria.gd)
# «veg_hojas_geom»: usar las mallas en las que cada tarjeta recortada es ya un polígono con la forma de las hojas.
# Misma silueta, sin recorte de transparencia: la Mali puede descartar lo tapado.
const RECORTADAS := "res://vegetacion_prueba/quaternius/recortadas/"


func _usar_hojas_geom() -> bool:
	return perfil.get("veg_hojas_geom", not _alto())


func _malla_hojas(nombre: String) -> Mesh:
	if (_usar_hojas_geom() or "_lod" in nombre) and ResourceLoader.exists(RECORTADAS + nombre + ".res"):
		# experimento «veg_indexada»: la copia indexada de la misma malla (mismos triángulos y datos por vértice)
		var idx := RECORTADAS + nombre + "_idx.res"
		var ruta := idx if perfil.get("veg_indexada", false) and ResourceLoader.exists(idx) else RECORTADAS + nombre + ".res"
		var m: Mesh = load(ruta).duplicate()
		m.set_meta("hojas_geom", true)
		return m
	return _malla_q(nombre).duplicate()


func _hojas_geom(malla: Mesh) -> bool:
	return malla.has_meta("hojas_geom")


# ================================================================ EXPERIMENTO DE SOMBRAS (Fase 2)
# «sombra_modo» en el perfil (solo esta prueba; sin él todo queda exactamente como antes):
#   "dinamica"  A: como siempre (el sol vuelve a pintar en su mapa de sombras todo lo que da sombra, cada fotograma).
#   "moviles"   B: DIAGNÓSTICO, no es un aspecto final. Solo Kael y la fauna dan sombra dinámica.
#   "horneada"  C: como B + sombra precalculada al cargar (árboles, rocas, puente, postes, estatua y contacto de los
#               arbustos) en un mapa en planta (textura) que leen el terreno, las losas, el césped y las plantas bajas.
#               Kael, al pasar bajo un árbol, se oscurece leyendo ese mismo mapa.
#   "horneada_vertices": C, pero en el terreno la sombra va en los colores de vértice (cada 0,6 m) y no en la textura.
# Medido antes (Streamline, Redmi): el mapa de sombras es ~65 % de los píxeles escritos y ~7 ms por fotograma.
const SOMBRA_COLOR := Color(0.3, 0.36, 0.5)   # multiplica el color: fresca y algo azulada (medido: ~0,5 del suelo al sol)
var _oclusores := []
var _terreno_mi: MeshInstance3D
var _alturas := PackedFloat32Array()            # alturas del terreno en su rejilla (dónde cae la sombra)
var _alt_n := 0
var _sombra_img: Image
var _sombra_tex: ImageTexture
var _sombra_res := 1024
var _kael_capa: ShaderMaterial
var _kael_luz := Color.WHITE
var _ruido_hojas := FastNoiseLite.new()


func _modo_sombra() -> String:
	return perfil.get("sombra_modo", "dinamica")


func _horneada() -> bool:
	return _modo_sombra().begins_with("horneada")


# --- registro de lo que da sombra (mientras se construye la escena; no cambia nada de lo construido)
func _roca(p: Vector3, r: float, mat: Material) -> void:
	_oclusores.append(["elipsoide", p, Vector3(r * 1.1, r * 0.75, r * 1.1), 1.0, false])
	super._roca(p, r, mat)


func _bloque(pos: Vector3, tam: Vector3, mat: Material, giro := Vector3.ZERO, choca := true) -> void:
	_oclusores.append(["caja", Transform3D(Basis.from_euler(giro), pos), tam * 0.5])
	super._bloque(pos, tam, mat, giro, choca)


func _poste(pos: Vector3, alto: float, farol := false) -> void:
	_oclusores.append(["capsula", pos, pos + Vector3(0, alto, 0), 0.1])
	super._poste(pos, alto, farol)


func _estatua_guardian(p: Vector3, giro_grados: float) -> void:
	var y := altura(p.x, p.z)
	_oclusores.append(["elipsoide", Vector3(p.x, y + 1.5, p.z), Vector3(0.8, 1.5, 0.8), 1.0, false])
	super._estatua_guardian(p, giro_grados)


func _anotar_arbol(cuerpo: Node3D, malla: Mesh) -> void:
	if not malla.has_meta("copa"):
		return
	var copa: AABB = malla.get_meta("copa")
	var e := cuerpo.scale.x
	var c: Vector3 = cuerpo.transform * copa.get_center()
	var rxz := (copa.size.x + copa.size.z) * 0.25 * e * 0.95
	_oclusores.append(["elipsoide", c, Vector3(rxz, copa.size.y * 0.5 * e * 0.9, rxz), 0.94, true])
	_oclusores.append(["capsula", cuerpo.position, c - Vector3(0, copa.size.y * 0.25 * e, 0), 0.22 * e])


func _crear_terreno() -> void:
	super._crear_terreno()
	_terreno_mi = get_child(get_child_count() - 1).get_child(0) as MeshInstance3D
	var vs: PackedVector3Array = _terreno_mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_alt_n = int(TAM / PASO)
	_alturas.resize(vs.size())
	for k in vs.size():
		_alturas[k] = vs[k].y


func _altura_rejilla(x: float, z: float) -> float:
	var fx := clampf((x - (-TAM * 0.5 + 3.0)) / PASO, 0.0, _alt_n - 0.001)
	var fz := clampf((z - (-TAM * 0.5)) / PASO, 0.0, _alt_n - 0.001)
	var j := int(fx)
	var i := int(fz)
	var tx := fx - j
	var tz := fz - i
	var a := i * (_alt_n + 1) + j
	var b := a + _alt_n + 1
	return lerpf(lerpf(_alturas[a], _alturas[a + 1], tx), lerpf(_alturas[b], _alturas[b + 1], tx), tz)


# --- montaje del experimento (al final de _ready)
func _experimento_sombras() -> void:
	var modo := _modo_sombra()
	if modo == "dinamica":
		return
	var t0 := Time.get_ticks_usec()
	var quitadas := _solo_moviles_dan_sombra()
	var t1 := Time.get_ticks_usec()
	if _horneada():
		_hornear_sombras()
		var t2 := Time.get_ticks_usec()
		_aplicar_sombras(modo == "horneada_vertices")
		var t3 := Time.get_ticks_usec()
		print("SOMBRA %s: hornear %d ms, aplicar %d ms, %d oclusores, mapa %d px (%.1f cm/px)" % [modo, (t2 - t1) / 1000,
			(t3 - t2) / 1000, _oclusores.size(), _sombra_res, TAM / _sombra_res * 100.0])
	print("SOMBRA %s: %d objetos dejan de dar sombra dinámica (%d ms)" % [modo, quitadas, (t1 - t0) / 1000])


func _solo_moviles_dan_sombra() -> int:
	var moviles: Array = [kael]
	for c in get_children():
		if c.get_script() != null and c.get_script().resource_path.ends_with("fauna_simple.gd"):
			moviles.append(c)
	var n := 0
	for g in find_children("*", "GeometryInstance3D", true, false):
		var es_movil := false
		for m in moviles:
			if m.is_ancestor_of(g):
				es_movil = true
				break
		if es_movil:
			continue
		if g.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			g.visible = false
			n += 1
		elif g.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n += 1
	return n


func _hornear_sombras() -> void:
	var sol: DirectionalLight3D = null
	for n in get_children():
		if n is DirectionalLight3D:
			sol = n
	var hacia_sol: Vector3 = sol.global_transform.basis.z.normalized()
	_sombra_res = int(perfil.get("sombra_mapa_res", 1024))
	var x0 := -TAM * 0.5 + 3.0
	var z0 := -TAM * 0.5
	var paso := TAM / _sombra_res
	var luz := PackedFloat32Array()
	luz.resize(_sombra_res * _sombra_res)
	luz.fill(1.0)
	_ruido_hojas.seed = 5
	_ruido_hojas.frequency = 1.3
	for o in _oclusores:
		var c: Vector3
		var r: float
		match o[0]:
			"elipsoide":
				c = o[1]
				r = maxf(o[2].x, o[2].y)
			"capsula":
				c = (o[1] + o[2]) * 0.5
				r = (o[2] - o[1]).length() * 0.5 + o[3]
			"caja":
				c = o[1].origin
				r = o[2].length()
			"contacto":
				c = o[1]
				r = o[2]
		var suelo := _altura_rejilla(c.x, c.z)
		var pie := c - hacia_sol * maxf(0.0, (c.y - suelo) / hacia_sol.y)
		var ext := r / hacia_sol.y + 0.6
		var ia := clampi(int((pie.x - ext - x0) / paso), 0, _sombra_res - 1)
		var ib := clampi(int((pie.x + ext - x0) / paso), 0, _sombra_res - 1)
		var ka := clampi(int((pie.z - ext - z0) / paso), 0, _sombra_res - 1)
		var kb := clampi(int((pie.z + ext - z0) / paso), 0, _sombra_res - 1)
		for k in range(ka, kb + 1):
			var z := z0 + (k + 0.5) * paso
			for i in range(ia, ib + 1):
				var x := x0 + (i + 0.5) * paso
				var g := Vector3(x, _altura_rejilla(x, z), z)
				var a := _cubre(o, g, hacia_sol)
				if a > 0.0:
					luz[k * _sombra_res + i] *= 1.0 - a
	var datos := PackedByteArray()
	datos.resize(_sombra_res * _sombra_res * 3)
	datos.fill(255)
	for k in luz.size():
		if luz[k] < 0.999:
			var col := SOMBRA_COLOR.lerp(Color.WHITE, luz[k])
			datos[k * 3] = int(col.r * 255.0)
			datos[k * 3 + 1] = int(col.g * 255.0)
			datos[k * 3 + 2] = int(col.b * 255.0)
	_sombra_img = Image.create_from_data(_sombra_res, _sombra_res, false, Image.FORMAT_RGB8, datos)


# Cuánto tapa el oclusor la luz del sol que llega al punto del suelo g (0 = nada, 1 = todo).
func _cubre(o: Array, g: Vector3, d: Vector3) -> float:
	match o[0]:
		"elipsoide":
			var rad: Vector3 = o[2]
			var oo: Vector3 = (g - o[1]) / rad
			var dd := d / rad
			var tc := -oo.dot(dd) / dd.length_squared()
			if tc <= 0.0:
				return 0.0
			var cerca := oo + dd * tc
			var dist := cerca.length()
			if dist >= 1.0:
				return 0.0
			var a := smoothstep(1.0, 0.7, dist) * float(o[3])
			if o[4]:                                     # copa: claros de luz entre las hojas, más en el borde
				var p := g + d * tc
				var n := _ruido_hojas.get_noise_3d(p.x, p.y, p.z)
				a *= 1.0 - 0.75 * smoothstep(0.15, 0.5, n) * smoothstep(0.3, 0.9, dist)
			return a
		"capsula":
			var p0: Vector3 = o[1]
			var v: Vector3 = o[2] - p0
			var w := g - p0
			var b := d.dot(v)
			var cc := v.dot(v)
			var dd := d.dot(w)
			var e := v.dot(w)
			var den := cc - b * b
			var t := clampf((e - b * dd) / den, 0.0, 1.0) if absf(den) > 1e-6 else 0.0
			var s := maxf(0.0, b * t - dd)
			var dist := ((g + d * s) - (p0 + v * t)).length()
			return smoothstep(o[3] * 1.3, o[3] * 0.7, dist)
		"caja":
			var xf: Transform3D = o[1]
			var h: Vector3 = o[2]
			var lo: Vector3 = xf.affine_inverse() * g
			var ld: Vector3 = xf.basis.transposed() * d
			var tmin := 0.0
			var tmax := 1e9
			for ax in 3:
				if absf(ld[ax]) < 1e-6:
					if absf(lo[ax]) > h[ax]:
						return 0.0
				else:
					var t1 := (-h[ax] - lo[ax]) / ld[ax]
					var t2 := (h[ax] - lo[ax]) / ld[ax]
					tmin = maxf(tmin, minf(t1, t2))
					tmax = minf(tmax, maxf(t1, t2))
			return 1.0 if tmax >= tmin else 0.0
		"contacto":                                       # sombra de contacto suave bajo los arbustos
			var desplaza := Vector3(-d.x, 0, -d.z) * 0.25
			var q: Vector3 = o[1] + desplaza
			var dist := Vector2(g.x - q.x, g.z - q.z).length()
			return 0.55 * smoothstep(o[2], o[2] * 0.3, dist)
	return 0.0


func _sombra_en(x: float, z: float) -> Color:
	var fx := clampf((x - (-TAM * 0.5 + 3.0)) / TAM * _sombra_res - 0.5, 0.0, _sombra_res - 1.001)
	var fz := clampf((z - (-TAM * 0.5)) / TAM * _sombra_res - 0.5, 0.0, _sombra_res - 1.001)
	var i := int(fx)
	var k := int(fz)
	var a := _sombra_img.get_pixel(i, k).lerp(_sombra_img.get_pixel(i + 1, k), fx - i)
	var b := _sombra_img.get_pixel(i, k + 1).lerp(_sombra_img.get_pixel(i + 1, k + 1), fx - i)
	return a.lerp(b, fz - k)


func _aplicar_sombras(en_vertices: bool) -> void:
	var img := _sombra_img.duplicate()
	img.generate_mipmaps()
	_sombra_tex = ImageTexture.create_from_image(img)
	var x0 := -TAM * 0.5 + 3.0
	var z0 := -TAM * 0.5
	var rect := Vector3(x0, z0, 1.0 / TAM)
	# terreno: o colores de vértice (en_vertices) o la textura en el canal de detalle (multiplica), por UV2 en planta
	var arr := _terreno_mi.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var mat: StandardMaterial3D = _terreno_mi.material_override
	if en_vertices:
		var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		for k in vs.size():
			cols[k] = cols[k] * _sombra_en(vs[k].x, vs[k].z)
		arr[Mesh.ARRAY_COLOR] = cols
	else:
		var uv2 := PackedVector2Array()
		uv2.resize(vs.size())
		for k in vs.size():
			uv2[k] = Vector2((vs[k].x - x0) / TAM, (vs[k].z - z0) / TAM)
		arr[Mesh.ARRAY_TEX_UV2] = uv2
		mat.detail_enabled = true
		mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
		mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		mat.detail_albedo = _sombra_tex
	var nueva := ArrayMesh.new()
	nueva.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_terreno_mi.mesh = nueva
	# losas (material estándar): misma textura proyectada en planta (triplanar en coordenadas del mundo);
	# césped y plantas bajas (sombreados propios): leen el mapa
	for mmi in find_children("*", "MultiMeshInstance3D", true, false):
		var malla: Mesh = mmi.multimesh.mesh
		var mats: Array = [mmi.material_override]
		for s in malla.get_surface_count():
			mats.append(malla.surface_get_material(s))
		if malla is PrimitiveMesh:
			mats.append(malla.material)
		for m in mats:
			if m is ShaderMaterial:
				m.set_shader_parameter("sombra_mapa", _sombra_tex)
				m.set_shader_parameter("sombra_rect", rect)
			elif m is StandardMaterial3D and malla is PrimitiveMesh:
				m.detail_enabled = true
				m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
				m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
				m.detail_albedo = _sombra_tex
				m.uv2_triplanar = true
				m.uv2_world_triplanar = true
				m.uv2_triplanar_sharpness = 8.0
				m.uv2_scale = Vector3.ONE / TAM
				m.uv2_offset = Vector3(-x0 / TAM, 0.0, -z0 / TAM)
	# Kael: una capa que multiplica su color por la sombra del suelo donde pisa (bajo los árboles se oscurece)
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded, blend_mul, depth_draw_never, fog_disabled;\nuniform vec4 luz : source_color = vec4(1.0);\nvoid fragment() { ALBEDO = luz.rgb; }\n"
	_kael_capa = ShaderMaterial.new()
	_kael_capa.shader = sh
	for mi in kael.find_children("*", "MeshInstance3D", true, false):
		mi.material_overlay = _kael_capa


func _process(delta: float) -> void:
	super._process(delta)
	if _kael_capa != null:
		var objetivo := _sombra_en(kael.global_position.x, kael.global_position.z)
		_kael_luz = _kael_luz.lerp(objetivo, clampf(delta * 8.0, 0.0, 1.0))
		_kael_capa.set_shader_parameter("luz", _kael_luz)


# ================================================================ EXPERIMENTO LOD (Fase 2)
# «veg_lod» (solo esta prueba; sin él todo queda como antes): árboles con 3 niveles y arbustos con 2 (mallas generadas
# por pruebas/herramientas/hojas_a_geometria.gd; el LOD0 es la malla de siempre) y césped lejano con matas de menos hojas.
#   «veg_lod_dist»: [fin LOD0, fin LOD1] de los árboles (m de la cámara al árbol).
#   «veg_lod_arbusto», «veg_lod_cesped»: distancia a la que pasan a su nivel ligero.
#   «veg_lod_forzar»: 0/1/2 = todos los árboles en ese nivel (para comparar las vistas).
#   «veg_lod2»: "racimos" (copa de esferas bajas opacas) o "impostor" (tarjeta con la imagen del árbol, con recorte).
#   «veg_lod_fundido»: fundido de Godot entre niveles (visibility_range_fade_mode) en vez de cambio directo.
const IMPOSTORES := "res://vegetacion_prueba/quaternius/impostores/"
var _mata_lejos: Mesh


func _lod() -> bool:
	return perfil.get("veg_lod", false)


func _lod_rango(n: GeometryInstance3D, desde: float, hasta: float) -> void:
	n.visibility_range_begin = desde
	n.visibility_range_end = hasta
	var margen := 2.0
	n.visibility_range_begin_margin = margen if desde > 0.0 else 0.0
	n.visibility_range_end_margin = margen if hasta > 0.0 else 0.0
	if perfil.get("veg_lod_fundido", false):
		n.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


func _lod_arbol(cuerpo: Node3D, mi: MeshInstance3D, v: int) -> void:
	if not _lod():
		return
	var dist: Array = perfil.get("veg_lod_dist", [28.0, 50.0])
	var forzar := int(perfil.get("veg_lod_forzar", -1))
	var niveles: Array = [mi]
	var m1 := MeshInstance3D.new()
	m1.mesh = _malla_arbol(VARIANTES[v] + "_lod1", v)
	niveles.append(m1)
	var m2: GeometryInstance3D
	if perfil.get("veg_lod2", "racimos") == "impostor" and ResourceLoader.exists(IMPOSTORES + VARIANTES[v] + ".png"):
		m2 = _impostor(v, cuerpo)
	else:
		m2 = MeshInstance3D.new()
		m2.mesh = _malla_arbol(VARIANTES[v] + "_lod2", v)
	niveles.append(m2)
	for k in [1, 2]:
		niveles[k].cast_shadow = mi.cast_shadow
		cuerpo.add_child(niveles[k])
	for k in 3:
		var n: GeometryInstance3D = niveles[k]
		if forzar >= 0:
			n.visible = k == forzar
		else:
			_lod_rango(n, 0.0 if k == 0 else float(dist[k - 1]), float(dist[k]) if k < 2 else 0.0)


# Impostor: una tarjeta que mira siempre a la cámara con la imagen del árbol (pintada antes con
# pruebas/herramientas/impostores.gd desde la inclinación de la cámara del juego). Sin luz propia: la imagen ya la lleva.
func _impostor(v: int, cuerpo: Node3D) -> MeshInstance3D:
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(IMPOSTORES + VARIANTES[v] + ".json"))
	var q := QuadMesh.new()
	q.size = Vector2(datos["ancho"], datos["alto"])
	q.center_offset = Vector3(0, datos["centro_y"], 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(IMPOSTORES + VARIANTES[v] + ".png")
	var k := 1.0 / float(datos.get("exposicion", 1.0))
	mat.albedo_color = Color(k, k, k)          # la escena vuelve a aplicar su exposición: se deshace la de la pintura
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	q.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = q
	return mi


func _lod_planta(mmi: MultiMeshInstance3D, malla1: Mesh) -> void:
	var d := float(perfil.get("veg_lod_arbusto", 24.0))
	_lod_rango(mmi, 0.0, d)
	var mm: MultiMesh = mmi.multimesh
	var mm1 := MultiMesh.new()
	mm1.transform_format = MultiMesh.TRANSFORM_3D
	mm1.mesh = malla1
	mm1.instance_count = mm.instance_count
	for k in mm.instance_count:
		mm1.set_instance_transform(k, mm.get_instance_transform(k))
	var m1 := MultiMeshInstance3D.new()
	m1.multimesh = mm1
	m1.position = mmi.position
	m1.cast_shadow = mmi.cast_shadow
	_lod_rango(m1, d, 0.0)
	add_child(m1)


# Césped: más allá de «veg_lod_cesped» las mismas matas (mismos sitios, giros y tamaños) con 6 hojas algo más anchas
# en vez de 11: cubren casi lo mismo con la mitad de triángulos.
func _lod_cesped(mmi: MultiMeshInstance3D, hasta: float) -> void:
	var d := float(perfil.get("veg_lod_cesped", 24.0))
	if hasta <= d:
		return
	if _mata_lejos == null:
		_mata_lejos = _mata_hojas(6, 1.6)
	_lod_rango(mmi, 0.0, d)
	var mm: MultiMesh = mmi.multimesh
	var mm1 := MultiMesh.new()
	mm1.transform_format = MultiMesh.TRANSFORM_3D
	mm1.mesh = _mata_lejos
	mm1.instance_count = mm.instance_count
	for k in mm.instance_count:
		mm1.set_instance_transform(k, mm.get_instance_transform(k))
	var m1 := MultiMeshInstance3D.new()
	m1.multimesh = mm1
	m1.material_override = mmi.material_override
	m1.position = mmi.position
	m1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lod_rango(m1, d, hasta)
	add_child(m1)


# Materiales de una planta (arbusto, flor o helecho) con los ajustes de la paleta.
func _preparar_planta(malla: Mesh, viento: float, verde, arbusto: bool) -> void:
	for s in malla.get_surface_count():
		var m := malla.surface_get_material(s)
		var flor: bool = m != null and m.resource_name == "Flowers"
		var aj := {"viento": viento, "viento_vel": 1.25, "relleno": 0.12, "contraluz": Color(0.2, 0.22, 0.1)}
		if flor:
			aj.merge({"color_bajo": Color(0.85, 0.85, 0.88), "color_alto": Color(1.08, 1.05, 1.0), "saturacion": 0.9,
				"relleno": 0.16}, true)
		elif verde != null:
			aj.merge({"verde": verde, "normal_esfera": 0.65 if arbusto else 0.0, "oclusion": 0.4 if arbusto else 0.15,
				"variacion": 0.5}, true)
		else:
			aj.merge({"tinte": PALETA["planta"], "saturacion": 0.72}, true)
		malla.surface_set_material(s, _follaje(m, malla, s, aj))


# ================================================================ AJUSTES DE SOMBREADO (Mali Offline Compiler, 2026-11-07)
# Solo en esta prueba; sin las opciones todo queda como antes.
#   «veg_sin_reflejo»: el entorno no refleja el cielo (Environment.reflected_light_source = DISABLED). Mali Offline
#     Compiler: −13 a −26 % de ciclos de cálculo por píxel iluminado; en la imagen, ~3/255 de media (−0,7 % de brillo).
#   «veg_sombra_dura»: la sombra dinámica (con C+, solo Kael y la fauna) se lee 1 vez por píxel en vez de 5.
#     Es un ajuste GLOBAL del servidor de render: se fija en cada carga de la escena (si no se pide, se vuelve al valor
#     del proyecto), para que no pase de un caso del banco al siguiente.
#   «veg_terreno_simple»: el terreno sin brillo especular y con iluminación Lambert (es mate: rugosidad 0,92).
func _ajustes_sombreado() -> void:
	if perfil.get("veg_sin_reflejo", false):
		for n in get_children():
			if n is WorldEnvironment:
				n.environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	var q_proyecto := int(ProjectSettings.get_setting_with_override(
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality"))
	RenderingServer.directional_soft_shadow_filter_set_quality(
		RenderingServer.SHADOW_QUALITY_HARD if perfil.get("veg_sombra_dura", false) else q_proyecto)
	if perfil.get("veg_terreno_simple", false) and _terreno_mi != null:
		var m: StandardMaterial3D = _terreno_mi.material_override
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	print("SOMBREADO: filtro de sombra del proyecto=%d (0 = 1 lectura), sin_reflejo=%s, sombra_dura=%s, terreno_simple=%s" % [
		q_proyecto, perfil.get("veg_sin_reflejo", false), perfil.get("veg_sombra_dura", false),
		perfil.get("veg_terreno_simple", false)])
