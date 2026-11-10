extends Node3D
# El Claro del Guardián (V9, hitos 6 y 10: «sector 3D ampliado» y «arena de jefe»), en el claro del noreste de Pastos
# Verdes 3D, donde duerme el Guardián del Bosque de «El bosque que no recuerda» (zonas3d/bosque_pastos.gd).
#
#   ClaroGuardian.crear(region, centro, estado, padre = null) -> Node3D
#
# estado: "dormido" (el Guardián duerme: runas pálidas que laten y motas de luz fría), "purificado" (flores, un árbol
# joven que brota del tocón, un manantial nuevo, runas cálidas y motas doradas) o "derrotado" (raíces secas y grises,
# raíces partidas, las runas apagadas y el claro en silencio).
#
# Qué hay: un anillo de menhires con runas y raíces enormes, abierto al este (el sendero y la salida del noreste), un
# tocón-trono con un ojo tallado detrás del sitio del Guardián, el lecho de raíces donde se arrodilla, musgo, setas,
# mojones, un cuenco de ofrendas y cintas atadas a la raíz grande (alguien viene a velar aquí), y un suelo de musgo que
# se funde con el terreno.
#
# Las piezas son un kit de Blender (zonas3d/bosque/fuente/crear_claro.py → claro_guardian.glb y, para los perfiles
# medio y bajo, claro_guardian_ligero.glb). Aquí se colocan sobre el terreno y se juntan en pocas mallas: una por
# material (piezas altas, piezas bajas, runas, agua y suelo), es decir, 4-5 llamadas de dibujo en total. Las colisiones
# son cilindros (los del GLB) en un solo cuerpo; el centro (radio LIBRE) y la entrada quedan siempre libres, y ninguna
# colisión cae en el sendero.
#
# «region» puede ser la región de Pastos Verdes 3D (o cualquier nodo con altura(x, z)): de ella salen la altura del
# terreno, el sendero, la zona prohibida y el material con grano. Sin ella, el claro se monta en llano (pruebas).

const KIT := "res://zonas3d/bosque/claro_guardian.glb"
const KIT_LIGERO := "res://zonas3d/bosque/claro_guardian_ligero.glb"
const ESTADOS := ["dormido", "purificado", "derrotado"]
const RADIO_SUELO := 6.5          # el suelo de musgo; se funde con el terreno desde el 60 %
const LIBRE := 1.6                # ninguna colisión a menos de esto del centro (el Guardián y el punto «claro»)
const ENTRADA := 40.0             # grados (0 = este, 90 = sur): por donde se entra desde el sendero
const MARGEN_SENDERO := 0.6       # ninguna colisión a menos de su radio más esto del sendero
const PRESUPUESTO := 15000        # triángulos de todo el sector
const TERRENO := "res://prototipos/sendero_puente.gd"   # el terreno de Pastos Verdes (su rejilla: TAM y PASO)

# [pieza, ángulo (grados; 0 = este, 90 = sur, hacia la cámara), radio (m), giro extra (grados), escala, estados]
# El frente de cada pieza mira al centro; con radio 0, «giro» es el ángulo hacia el que mira. Estados: "" = todos.
# Lo alto va detrás (norte y oeste: la cámara mira al norte) y lo bajo delante, para no tapar a Kael.
const ALTOS := [
	# el corro de piedras, abierto al este (la entrada, entre las dos piedras de la puerta)
	["menhir_puerta", -45, 4.1, 8, 0.9, ""],
	["menhir_alto", -72, 4.8, 6, 0.9, ""],
	["menhir_ancho", -100, 5.0, -6, 0.85, ""],
	["menhir_alto", -128, 5.0, -4, 1.05, ""],
	["menhir_ancho", -156, 5.0, 8, 0.8, ""],
	["menhir_alto", 176, 5.0, 10, 0.8, ""],
	["menhir_ancho", 140, 4.4, -10, 0.65, ""],     # (más adentro: al suroeste empieza el barranco del río)
	["menhir_puerta", 104, 4.6, 12, 1.0, ""],
	["menhir_puerta", 75, 4.1, -10, 1.0, ""],
	# raíces enormes que abrazan el corro por fuera
	["raiz_arco_grande", -114, 5.7, 0, 1.0, ""],
	["raiz_arco", -172, 5.3, 0, 1.0, ""],
	# el tocón-trono, detrás del Guardián
	["tocon", -118, 3.0, 0, 1.0, ""],
	["brote", -118, 3.0, 0, 1.0, "purificado"],    # brota del corte del tocón (misma posición)
]
const BAJOS := [
	["lecho", 0, 0.0, ENTRADA, 1.0, ""],
	["raiz_baja", 128, 3.5, 0, 1.0, ""],
	["raiz_baja", -60, 3.4, 15, 0.85, ""],
	["raiz_baja", 178, 3.3, 0, 0.9, ""],
	["ofrenda", -150, 1.9, 0, 1.0, "dormido,derrotado"],
	["mojon", -84, 3.7, 0, 1.0, ""],
	["mojon", 92, 3.8, 20, 0.85, ""],
	["setas", -138, 3.5, 0, 1.0, ""],
	["setas", 140, 3.9, 40, 0.9, ""],
	["setas", -70, 4.3, 80, 0.8, ""],
	["musgo", -95, 4.3, 0, 1.1, ""],
	["musgo", -150, 4.4, 30, 1.0, ""],
	["musgo", 175, 4.2, 60, 0.9, ""],
	["musgo", 125, 4.3, 0, 1.0, ""],
	["musgo", 80, 3.3, 20, 0.8, ""],
	["musgo", -60, 4.0, 45, 0.8, ""],
	["musgo", -112, 3.4, 10, 0.7, ""],
	["musgo", -20, 4.6, 70, 0.7, ""],
	["manantial", -68, 2.5, 0, 1.0, "purificado"],  # entre las raíces, a la vista desde la entrada
	["flores", 0, 0.35, 0, 1.0, "purificado"],      # donde dormía, flores
	["flores", 120, 0.7, 50, 0.9, "purificado"],
	["flores", -60, 0.8, 90, 0.9, "purificado"],
	["flores", -100, 3.6, 0, 1.0, "purificado"],
	["flores", -140, 4.0, 30, 1.0, "purificado"],
	["flores", 170, 3.9, 60, 1.0, "purificado"],
	["flores", 130, 3.8, 0, 1.0, "purificado"],
	["flores", 100, 3.3, 20, 0.9, "purificado"],
	["flores", 60, 3.0, 80, 0.8, "purificado"],
	["flores", -36, 3.3, 10, 0.9, "purificado"],
	["flores", -25, 2.5, 40, 0.8, "purificado"],
	["flores", 15, 2.4, 0, 0.8, "purificado"],
	["flores", 165, 2.4, 70, 0.9, "purificado"],
	["raiz_seca", -75, 2.2, 30, 1.0, "derrotado"],
	["raiz_seca", 160, 2.2, -40, 0.9, "derrotado"],
	["raiz_seca", 100, 2.6, 120, 0.8, "derrotado"],
]
# Las runas laten entre estos dos colores (sin sombreado); derrotado: apagadas. Motas de luz del claro.
const COLOR_RUNA := {"dormido": [Color(0.55, 0.72, 0.82), Color(0.86, 0.97, 1.0)],
	"purificado": [Color(0.62, 0.86, 0.36), Color(0.92, 1.0, 0.62)],
	"derrotado": [Color(0.2, 0.19, 0.18), Color(0.2, 0.19, 0.18)]}
const COLOR_MOTAS := {"dormido": Color(0.82, 0.95, 1.0, 0.85), "purificado": Color(1.0, 0.95, 0.55, 0.9)}

var estado := "dormido"
var triangulos := 0
var choques := 0
var mat_runa: StandardMaterial3D
var _t := 0.0


# ================================================================= crear

static func crear(region, centro: Vector3, estado_: String, padre: Node = null) -> Node3D:
	var c = load("res://zonas3d/bosque/claro_guardian.gd").new()
	c.name = "ClaroGuardian"
	c.estado = estado_ if estado_ in ESTADOS else "dormido"
	var destino: Node = padre if padre != null else region
	if destino != null:
		destino.add_child(c)
	if c.is_inside_tree():
		c.global_position = centro
	else:
		c.position = centro
	c._montar(region, centro)
	return c


static func ligero() -> bool:
	if not ResourceLoader.exists("res://prototipos/calidad_proto.gd"):
		return false
	var cal = load("res://prototipos/calidad_proto.gd")
	return cal.datos().get("modelos_ligeros", cal.actual() != "alto")


static func ruta_kit() -> String:
	return KIT_LIGERO if ligero() and ResourceLoader.exists(KIT_LIGERO) else KIT


# Las piezas del kit: {nombre: {"malla": Mesh, "choques": [[Vector3 base local, radio, alto]]}}
static func piezas(ruta := "") -> Dictionary:
	var r := {}
	if ruta == "":
		ruta = ruta_kit()
	if not ResourceLoader.exists(ruta):
		push_warning("Claro del Guardián: falta el kit «%s»" % ruta)
		return r
	var raiz: Node = (load(ruta) as PackedScene).instantiate()
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var ch: Array = []
		for e in mi.get_children():
			if e is Node3D and String(e.name).begins_with("choque_"):
				var p := String(e.name).split("_")
				if p.size() >= 3:
					ch.append([(e as Node3D).position, float(p[1]) / 100.0, float(p[2]) / 100.0])
		r[String(mi.name)] = {"malla": (mi as MeshInstance3D).mesh, "choques": ch}
	raiz.free()
	return r


# ================================================================= montar

func _montar(region, centro: Vector3) -> void:
	var kit := piezas()
	var en_estado := func(cuando: String) -> bool:
		return cuando == "" or estado in cuando.split(",")
	var lotes := {}                           # "alto" | "bajo" | "runa" | "agua" -> SurfaceTool
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Choques"
	add_child(cuerpo)
	for grupo in [[ALTOS, "alto"], [BAJOS, "bajo"]]:
		for d in grupo[0]:
			if not en_estado.call(d[5]) or not kit.has(d[0]):
				continue
			var t := _transformada(region, centro, d)
			var pieza: Dictionary = kit[d[0]]
			_al_lote(lotes, pieza["malla"], t, grupo[1])
			for ch in pieza["choques"]:
				_choque(region, centro, cuerpo, t, ch, float(d[4]))
	var mat_base := _mat_base(region)
	if lotes.has("alto"):
		var mi := _malla(lotes["alto"], mat_base, "Altos", cuerpo)
		mi.add_to_group("ocluye")                # si tapa a Kael, se vuelve transparente (vista3d.gd)
	if lotes.has("bajo"):
		_malla(lotes["bajo"], mat_base, "Bajos", self)
	mat_runa = StandardMaterial3D.new()
	mat_runa.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_runa.albedo_color = COLOR_RUNA[estado][0]
	if lotes.has("runa"):
		_malla(lotes["runa"], mat_runa, "Runas", self).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if lotes.has("agua"):
		var agua := StandardMaterial3D.new()
		agua.albedo_color = Color(0.36, 0.66, 0.82)
		agua.roughness = 0.04
		agua.metallic_specular = 1.0
		agua.emission_enabled = true
		agua.emission = Color(0.1, 0.22, 0.28)
		_malla(lotes["agua"], agua, "Agua", self).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_crear_suelo(region, centro)
	_crear_motas()
	set_meta("triangulos", triangulos)
	set_meta("choques", choques)
	set_meta("estado", estado)
	set_process(estado != "derrotado")


# Dónde va una pieza: en el terreno (lo más bajo bajo su huella, para que no flote), mirando al centro.
func _transformada(region, centro: Vector3, d: Array) -> Transform3D:
	var ang := deg_to_rad(float(d[1]))
	var r := float(d[2])
	var esc := float(d[4])
	var fuera := Vector3(cos(ang), 0, sin(ang))
	var pos := fuera * r
	var giro: float
	if r < 0.01:                                 # en el centro: «giro» es hacia dónde mira su frente
		var g := deg_to_rad(float(d[3]))
		giro = atan2(cos(g), sin(g))
	else:
		giro = atan2(-fuera.x, -fuera.z) + deg_to_rad(float(d[3]))
	var b := Basis(Vector3.UP, giro).scaled(Vector3.ONE * esc)
	var huella := 0.6 * esc
	if String(d[0]).begins_with("raiz_arco"):
		huella = 2.2 * esc
	var y := INF
	for q in [Vector3.ZERO, b.x.normalized() * huella, -b.x.normalized() * huella, b.z.normalized() * huella * 0.5,
			-b.z.normalized() * huella * 0.5]:
		y = minf(y, _altura(region, centro, pos + q))
	pos.y = y - 0.03
	if d[0] == "manantial":                      # el agua, a nivel: a la altura del centro, no de lo más bajo
		pos.y = _altura(region, centro, pos * Vector3(1, 0, 1)) - 0.02
	return Transform3D(b, pos)


func _altura(region, centro: Vector3, local: Vector3) -> float:
	if region != null and region.has_method("altura"):
		return region.altura(centro.x + local.x, centro.z + local.z) - centro.y
	return 0.0


func _al_lote(lotes: Dictionary, malla: Mesh, t: Transform3D, grupo: String) -> void:
	for s in malla.get_surface_count():
		var m := malla.surface_get_material(s)
		var nombre := m.resource_name if m != null else ""
		var lote := grupo
		if nombre.begins_with("runa"):
			lote = "runa"
		elif nombre.begins_with("agua"):
			lote = "agua"
		if not lotes.has(lote):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			lotes[lote] = st
		lotes[lote].append_from(malla, s, t)


func _choque(region, centro: Vector3, cuerpo: StaticBody3D, t: Transform3D, ch: Array, esc: float) -> void:
	var base: Vector3 = t * (ch[0] as Vector3)
	var radio: float = ch[1] * esc
	var alto: float = ch[2] * esc
	var plano := Vector2(base.x, base.z)
	if plano.length() < LIBRE + radio:
		return                                   # el centro siempre libre
	var mundo := centro + Vector3(base.x, 0, base.z)
	if region != null and region.has_method("_dist_sendero") and region._dist_sendero(mundo) < radio + MARGEN_SENDERO:
		return                                   # nunca en el sendero
	var col := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = radio
	cil.height = alto
	col.shape = cil
	col.position = Vector3(base.x, _altura(region, centro, Vector3(base.x, 0, base.z)) + alto * 0.5, base.z)
	cuerpo.add_child(col)
	choques += 1


func _malla(st: SurfaceTool, mat: Material, nombre: String, padre: Node) -> MeshInstance3D:
	var arrays := st.commit_to_arrays()
	if estado != "dormido" and nombre in ["Altos", "Bajos"]:
		_tenir(arrays)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = am
	mi.material_override = mat
	padre.add_child(mi)
	var indices = arrays[Mesh.ARRAY_INDEX]
	triangulos += (indices.size() if indices != null and indices.size() > 0 else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	return mi


# Purificado: el musgo y las hojas, más vivos. Derrotado: todo seco y gris (la corteza, el musgo y las setas).
func _tenir(arrays: Array) -> void:
	var cols = arrays[Mesh.ARRAY_COLOR]
	if cols == null or cols.size() == 0:
		return
	for i in cols.size():
		var c: Color = cols[i]
		var verde := c.g > c.r * 1.08 and c.g > c.b * 1.25
		if estado == "purificado":
			if verde:
				c = Color(c.r * 0.92, minf(c.g * 1.12, 1.0), c.b * 0.85)
		else:
			var luz := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			var gris := Color(luz * 1.02, luz * 0.98, luz * 0.92)
			c = c.lerp(gris, 0.85 if verde else 0.6)
			if verde:
				c = c.lerp(Color(0.46, 0.41, 0.33), 0.45)   # el musgo, pardo y seco
		cols[i] = c
	arrays[Mesh.ARRAY_COLOR] = cols


func _mat_base(region) -> Material:
	if region != null and region.has_method("_mat_detalle") and region.get("tex_detalle") != null:
		return region._mat_detalle(Color.WHITE, 0.9, true, 0.8)   # el mismo grano y relieve que rocas y terreno
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.9
	return m


# ================================================================= suelo

# Un manto de musgo (o de flores, o de tierra seca) sobre el terreno, en la misma rejilla que el terreno de la región y
# 3 cm por encima: no se cruza con él. Por fuera se funde con el color del terreno; junto al sendero no se nota.
func _crear_suelo(region, centro: Vector3) -> void:
	var con_terreno: bool = region != null and region.has_method("altura") and region.has_method("_color_terreno")
	var paso := 0.6
	var x0 := -52.0
	var z0 := -55.0
	if con_terreno and ResourceLoader.exists(TERRENO):
		var S = load(TERRENO)                    # la rejilla del terreno de la región (_crear_terreno)
		paso = S.PASO
		x0 = -S.TAM * 0.5 + 3.0
		z0 = -S.TAM * 0.5
	elif not con_terreno:
		x0 = centro.x - RADIO_SUELO - 1.0
		z0 = centro.z - RADIO_SUELO - 1.0
	var j0 := int(floor((centro.x - RADIO_SUELO - x0) / paso))
	var i0 := int(floor((centro.z - RADIO_SUELO - z0) / paso))
	var n := int(ceil(RADIO_SUELO * 2.0 / paso)) + 2
	var vert := {}
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cuenta := 0
	var idx := {}
	for i in n + 1:
		for j in n + 1:
			var x := x0 + (j0 + j) * paso
			var z := z0 + (i0 + i) * paso
			var d := Vector2(x - centro.x, z - centro.z).length()
			if d > RADIO_SUELO + paso * 1.5:
				continue
			var y := centro.y
			var color := Color(0.4, 0.55, 0.25)
			var w := 1.0 - smoothstep(RADIO_SUELO * 0.6, RADIO_SUELO, d)
			if con_terreno:
				y = region.altura(x, z)
				var dx: float = region.altura(x + paso, z) - region.altura(x - paso, z)
				var dz: float = region.altura(x, z + paso) - region.altura(x, z - paso)
				var pendiente := clampf(sqrt(dx * dx + dz * dz) / (2.0 * paso), 0.0, 1.0)
				color = region._color_terreno(x, z, y, pendiente)
				if region.has_method("_dist_sendero"):
					w *= smoothstep(1.7, 2.6, region._dist_sendero(Vector3(x, 0, z)))
				if y < -0.3 or (region.has_method("_prohibido") and region._prohibido(Vector3(x, y, z))):
					w = 0.0
			color = color.lerp(_color_suelo(x, z, d), w)
			st.set_color(color)
			st.add_vertex(Vector3(x - centro.x, y - centro.y + 0.03, z - centro.z))
			idx[Vector2i(i, j)] = cuenta
			cuenta += 1
	for i in n:
		for j in n:
			var k := [Vector2i(i, j), Vector2i(i, j + 1), Vector2i(i + 1, j), Vector2i(i + 1, j + 1)]
			if not (idx.has(k[0]) and idx.has(k[1]) and idx.has(k[2]) and idx.has(k[3])):
				continue
			# la misma diagonal que el terreno (sendero_puente.gd, _crear_terreno): las caras quedan paralelas
			st.add_index(idx[k[0]]); st.add_index(idx[k[1]]); st.add_index(idx[k[2]])
			st.add_index(idx[k[1]]); st.add_index(idx[k[3]]); st.add_index(idx[k[2]])
	if cuenta == 0:
		return
	st.generate_normals()
	var mat: Material
	if region != null and region.has_method("_mat_detalle") and region.get("tex_detalle") != null:
		mat = region._mat_detalle(Color.WHITE, 0.45, true, 0.5)   # el material del terreno: el grano empalma
	else:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.95
		mat = m
	var mi := _malla(st, mat, "Suelo", self)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _color_suelo(x: float, z: float, d: float) -> Color:
	var r1 := 0.5 + 0.5 * sin(x * 1.7 + z * 0.9) * cos(z * 1.3 - x * 0.4)
	var r2 := 0.5 + 0.5 * sin(x * 3.1 - z * 2.3)
	match estado:
		"purificado":
			var c := Color(0.32, 0.58, 0.2).lerp(Color(0.5, 0.7, 0.24), r1)
			return c.lerp(Color(0.62, 0.72, 0.3), r2 * 0.25)
		"derrotado":
			var c := Color(0.42, 0.38, 0.31).lerp(Color(0.55, 0.51, 0.43), r1)
			return c.lerp(Color(0.3, 0.27, 0.22), (1.0 - smoothstep(0.8, 2.4, d)) * 0.6)
		_:
			# musgo espeso y oscuro donde duerme; alrededor, una hierba pálida, sin color (el olvido)
			var musgo := Color(0.24, 0.36, 0.14).lerp(Color(0.36, 0.5, 0.18), r1)
			var palida := Color(0.5, 0.56, 0.42).lerp(Color(0.6, 0.64, 0.52), r2)
			var c := musgo.lerp(palida, smoothstep(2.2, 4.2, d) * 0.55)
			return c.lerp(Color(0.26, 0.24, 0.17), (1.0 - smoothstep(0.6, 1.9, d)) * 0.35)


# ================================================================= motas de luz

func _crear_motas() -> void:
	if not COLOR_MOTAS.has(estado):
		return                                   # derrotado: el claro en silencio
	var p := CPUParticles3D.new()
	p.name = "Motas"
	p.amount = 10 if ligero() else 18
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(4.2, 0.9, 4.2)
	p.position = Vector3(0, 1.2, 0)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.18
	p.gravity = Vector3(0, 0.05, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	var c: Color = COLOR_MOTAS[estado]
	g.colors = PackedColorArray([Color(c, 0.0), c, Color(c, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)


# ================================================================= vida

func _process(delta: float) -> void:
	_t += delta
	if mat_runa != null:                         # las runas laten despacio (dormido: frío; purificado: cálido)
		var par: Array = COLOR_RUNA[estado]
		mat_runa.albedo_color = (par[0] as Color).lerp(par[1], 0.5 + 0.5 * sin(_t * 1.4))
