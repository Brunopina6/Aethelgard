extends RefCounted
# Árboles estilizados de fantasía luminosa para Pastos Verdes (Fase 2.1 — prueba de calidad; no reparte
# árboles por el mapa). Hechos por código, ligeros y con identidad propia:
#   «pradera»  frondoso: tronco robusto con raíz, ramas abiertas y copa ancha de 5 lóbulos.
#   «abedul»   elegante: tronco blanco esbelto con marcas oscuras y copa ligera, alta y aireada.
#   «magico»   ornamental: tronco que se retuerce, copa con flores lila y rosa y motas de luz.
# Técnica (Skill aet-vegetacion-viento / propuesta aet-paisajismo-vegetacion-premium):
#   - Tronco y ramas: tubos que se estrechan siguiendo una curva (≈ 400–700 triángulos).
#   - Copa: matas de hojas PINTADAS (modelos/hojas/matas.png) repartidas sobre varios lóbulos, orientadas hacia
#     fuera, con normales de «esfera» (luz de volumen) y sombreado interior en el color de vértice (la
#     Compatibility no tiene oclusión ambiental: las matas de dentro y de abajo se oscurecen a mano).
#   - Material de copa: doble cara, alfa recortado (barato en móvil), luz que atraviesa las hojas y viento.
# Uso: var c = load("res://prototipos/arbol_estilizado.gd"); c.crear(padre, posicion, "pradera", escala, giro, tex_grano)

const ATLAS := "res://modelos/hojas/matas.png"
const SHADER_COPA := """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 color : source_color = vec4(1.0);          // tinte (también lo usa la transparencia por oclusión)
uniform float viento = 0.05;
uniform vec3 translucidez : source_color = vec3(0.42, 0.48, 0.14);   // el sol atraviesa las hojas (luminoso)
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	float s = sin(TIME * 1.3 + w.x * 0.3 + w.z * 0.2 + VERTEX.y * 0.5) * 0.65 + sin(TIME * 2.4 + VERTEX.x * 1.6) * 0.35;
	VERTEX.x += s * viento * h * 0.22;
	VERTEX.z += s * viento * h * 0.14;
}
void fragment() {
	vec4 t = texture(atlas, UV);
	ALBEDO = t.rgb * COLOR.rgb * color.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
	BACKLIGHT = translucidez;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;                                // la cara de atrás conserva la normal de esfera
	}
}
"""

# Recetas: tronco (alto, radio base, radio arriba, curvatura, color base, color punta, marcas de abedul),
# ramas, lóbulos de la copa [centro, radio] y matas.
const TIPOS := {
	"pradera": {
		"tronco": [2.7, 0.34, 0.2, 0.18], "corteza": [Color(0.42, 0.29, 0.19), Color(0.58, 0.42, 0.28)], "abedul": false,
		"raiz": 0.55, "ramas": 4, "rama_largo": [1.4, 2.0], "rama_radio": 0.13, "giro_tronco": 0.0,
		"lobulos": [[Vector3(0, 4.1, 0), 1.9], [Vector3(1.25, 3.6, 0.35), 1.35], [Vector3(-1.2, 3.7, -0.3), 1.4],
			[Vector3(0.2, 3.5, 1.2), 1.3], [Vector3(-0.15, 3.4, -1.2), 1.3], [Vector3(0.3, 5.2, 0.1), 1.25]],
		"matas": 96, "tam": [1.05, 1.5], "celdas": [0, 3], "tinte": Color(1.0, 1.0, 1.0),
	},
	"abedul": {
		"tronco": [4.6, 0.17, 0.07, 0.25], "corteza": [Color(0.86, 0.85, 0.8), Color(0.95, 0.94, 0.9)], "abedul": true,
		"raiz": 0.24, "ramas": 3, "rama_largo": [0.9, 1.3], "rama_radio": 0.06, "giro_tronco": 0.0,
		"lobulos": [[Vector3(0, 5.6, 0), 1.25], [Vector3(0.5, 4.7, 0.2), 1.0], [Vector3(-0.45, 4.9, -0.25), 0.95],
			[Vector3(0.1, 6.6, 0.0), 0.9], [Vector3(0.0, 4.2, 0.55), 0.8]],
		"matas": 70, "tam": [0.75, 1.1], "celdas": [1], "tinte": Color(1.0, 1.0, 1.0),
	},
	"magico": {
		"tronco": [2.9, 0.3, 0.13, 0.35], "corteza": [Color(0.45, 0.38, 0.5), Color(0.66, 0.56, 0.7)], "abedul": false,
		"raiz": 0.5, "ramas": 5, "rama_largo": [1.3, 2.0], "rama_radio": 0.11, "giro_tronco": 1.6,
		"lobulos": [[Vector3(0, 4.3, 0), 1.6], [Vector3(1.4, 3.8, 0.4), 1.15], [Vector3(-1.3, 3.9, -0.4), 1.2],
			[Vector3(0.3, 3.7, 1.25), 1.05], [Vector3(-0.3, 3.6, -1.2), 1.05], [Vector3(0.0, 5.3, 0.0), 1.0]],
		"matas": 90, "tam": [0.95, 1.35], "celdas": [2, 2, 3], "tinte": Color(1.0, 1.0, 1.0), "motas": true,
	},
}

static var _cache := {}


# opciones (según el perfil de calidad; medido en el Redmi: las copas de muchas matas recortadas que se solapan
# cuestan mucho en la GPU del móvil, sobre todo al pintarlas otra vez para la sombra):
#   "matas": factor de matas (1,0 = todas; 0,65 = menos y algo más grandes, la copa sigue llena)
#   "sombra_simple": la copa no proyecta sombra hoja a hoja; la da una forma sencilla e invisible con sus lóbulos
static func crear(padre: Node3D, pos: Vector3, tipo: String, escala: float, giro: float, grano: Texture2D, opciones := {}) -> StaticBody3D:
	var factor: float = opciones.get("matas", 1.0)
	var clave := "%s_%.2f" % [tipo, factor]
	if not _cache.has(clave):
		_cache[clave] = _construir(tipo, grano, factor)
	var c: Dictionary = _cache[clave]
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	cuerpo.rotation.y = giro
	cuerpo.scale = Vector3.ONE * escala
	padre.add_child(cuerpo)
	var tronco := MeshInstance3D.new()
	tronco.mesh = c["tronco"]
	tronco.material_override = c["mat_tronco"].duplicate()
	cuerpo.add_child(tronco)
	var copa := MeshInstance3D.new()
	copa.mesh = c["copa"]
	copa.material_override = c["mat_copa"].duplicate()   # cada árbol el suyo: se vuelve transparente solo
	cuerpo.add_child(copa)
	for mi in [tronco, copa]:
		mi.add_to_group("ocluye")
	if opciones.get("sombra_simple", false):
		copa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var sombra := MeshInstance3D.new()                   # solo da sombra (con la forma de los lóbulos)
		sombra.mesh = c["sombra"]
		sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		cuerpo.add_child(sombra)
	var col := CollisionShape3D.new()                    # copa (para la oclusión de la cámara)
	var cs := SphereShape3D.new()
	cs.radius = c["radio_copa"]
	col.shape = cs
	col.position = c["centro_copa"]
	cuerpo.add_child(col)
	var col2 := CollisionShape3D.new()                   # tronco: Kael no lo atraviesa
	var cil := CylinderShape3D.new()
	cil.radius = TIPOS[tipo]["tronco"][1] + 0.08
	cil.height = TIPOS[tipo]["tronco"][0]
	col2.shape = cil
	col2.position.y = TIPOS[tipo]["tronco"][0] * 0.5
	cuerpo.add_child(col2)
	if TIPOS[tipo].get("motas", false):
		cuerpo.add_child(_motas(c["centro_copa"], c["radio_copa"]))
	return cuerpo


static func _construir(tipo: String, grano: Texture2D, factor := 1.0) -> Dictionary:
	var t: Dictionary = TIPOS[tipo]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(tipo)
	# ---------------- tronco y ramas
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var alto: float = t["tronco"][0]
	var r0: float = t["tronco"][1]
	var r1: float = t["tronco"][2]
	var curva: float = t["tronco"][3]
	var eje: Array = []
	for k in 9:
		var f := k / 8.0
		var off := Vector3(sin(f * PI * 1.2) * curva, 0, cos(f * PI * 0.9) * curva * 0.5 - curva * 0.5)
		if t["giro_tronco"] > 0.0:
			off = Vector3(cos(f * t["giro_tronco"] * TAU), 0, sin(f * t["giro_tronco"] * TAU)) * curva * f
		var r := lerpf(r0, r1, f)
		if f < 0.12:
			r = lerpf(t["raiz"], r0, f / 0.12)             # ensanche de la raíz
		eje.append([Vector3(0, f * alto, 0) + off, r])
	_tubo(st, eje, t, 0.0)
	var cima: Vector3 = eje[eje.size() - 1][0]
	var lob: Array = t["lobulos"]
	for k in t["ramas"]:
		var destino: Vector3 = lob[(k + 1) % lob.size()][0] * Vector3(0.75, 0.88, 0.75)
		var inicio: Vector3 = eje[5 + (k % 3)][0]
		var largo := rng.randf_range(t["rama_largo"][0], t["rama_largo"][1])
		var dir := (destino - inicio).normalized()
		var rama: Array = []
		for j in 5:
			var f := j / 4.0
			var p := inicio + dir * largo * f + Vector3(0, sin(f * PI) * 0.25, 0)
			rama.append([p, lerpf(t["rama_radio"], t["rama_radio"] * 0.35, f)])
		_tubo(st, rama, t, 0.25)
	st.generate_normals()
	var tronco := st.commit()
	var mt := StandardMaterial3D.new()
	mt.vertex_color_use_as_albedo = true
	mt.albedo_texture = grano
	mt.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mt.roughness = 0.9
	# ---------------- copa
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centro := Vector3.ZERO
	var peso := 0.0
	for l in lob:
		centro += l[0] * l[1]
		peso += l[1]
	centro /= peso
	var radio_total := 0.0
	for l in lob:
		radio_total = maxf(radio_total, (l[0] - centro).length() + l[1])
	var n: int = maxi(lob.size() * 4, int(t["matas"] * factor))
	var agrandar := 0.92 / sqrt(clampf(factor, 0.3, 1.0)) if factor < 1.0 else 1.0   # menos matas, algo más grandes
	for k in n:
		var l: Array = lob[k % lob.size()]
		var c: Vector3 = l[0]
		var rl: float = l[1]
		var yk := 1.0 - (k / float(lob.size()) + 0.5) / (n / float(lob.size())) * 2.0
		yk = clampf(yk + rng.randf_range(-0.15, 0.15), -0.95, 0.98)
		var ang := k * 2.39996 + rng.randf() * 0.4
		var dl := Vector3(cos(ang) * sqrt(1.0 - yk * yk), yk, sin(ang) * sqrt(1.0 - yk * yk))
		var hondo := rng.randf_range(0.35, 0.95)
		var p := c + dl * rl * hondo
		var tam := rl * rng.randf_range(t["tam"][0], t["tam"][1]) * agrandar
		var fuera := (dl * 0.7 + (p - centro).normalized() * 0.3 + Vector3(rng.randf_range(-0.25, 0.25), 0.2, rng.randf_range(-0.25, 0.25))).normalized()
		var lado := fuera.cross(Vector3.UP if absf(fuera.y) < 0.95 else Vector3.RIGHT).normalized().rotated(fuera, rng.randf_range(-PI, PI))
		var arriba := lado.cross(fuera).normalized()
		var celdas: Array = t["celdas"]
		var celda: int = celdas[rng.randi() % celdas.size()]
		if tipo == "pradera" and (hondo < 0.55 or dl.y < -0.3):
			celda = 3                                     # dentro y abajo: la mata de sombra
		var uv0 := Vector2((celda % 2) * 0.5, (celda / 2) * 0.5)
		# sombreado interior: lo de dentro y lo de abajo más oscuro (oclusión ambiental pintada)
		var ao := clampf(0.7 + hondo * 0.3 + (p.y - centro.y) / radio_total * 0.3, 0.6, 1.15)   # interior sombreado pero luminoso
		var col := Color(ao, ao, ao)
		var esq := [[-1, 1, 0, 0], [1, 1, 1, 0], [1, -1, 1, 1], [-1, -1, 0, 1]]
		var v := []
		for e in esq:
			v.append([p + lado * e[0] * tam * 0.5 + arriba * e[1] * tam * 0.5, uv0 + Vector2(e[2], e[3]) * 0.5])
		for i in [0, 1, 2, 0, 2, 3]:
			var q: Vector3 = v[i][0]
			var nl := ((q - c).normalized() * 0.55 + (q - centro).normalized() * 0.45 + Vector3.UP * 0.35).normalized()
			sc.set_normal(nl)
			sc.set_color(col)
			sc.set_uv(v[i][1])
			sc.add_vertex(q)
	var copa := sc.commit()
	var mc := ShaderMaterial.new()
	mc.shader = Shader.new()
	mc.shader.code = SHADER_COPA
	mc.set_shader_parameter("atlas", load(ATLAS))
	mc.set_shader_parameter("color", t["tinte"])
	# forma sencilla para la sombra (perfiles medio/bajo): una bola baja de polígonos por lóbulo
	var ss := SurfaceTool.new()
	ss.begin(Mesh.PRIMITIVE_TRIANGLES)
	for l in lob:
		var esfera := SphereMesh.new()
		esfera.radius = l[1] * 0.85
		esfera.height = l[1] * 1.6
		esfera.radial_segments = 8
		esfera.rings = 4
		ss.append_from(esfera, 0, Transform3D(Basis(), l[0]))
	return {"tronco": tronco, "copa": copa, "mat_tronco": mt, "mat_copa": mc, "centro_copa": centro,
		"radio_copa": radio_total * 0.8, "sombra": ss.commit()}


# Tubo que se estrecha a lo largo de un eje [[punto, radio], ...]; color de corteza con degradado (y marcas
# oscuras si es abedul); UV: vuelta y altura (para el grano de la textura).
static func _tubo(st: SurfaceTool, eje: Array, t: Dictionary, desfase: float) -> void:
	const LADOS := 8
	var n := eje.size()
	for k in n - 1:
		for s in LADOS:
			var a0 := s * TAU / LADOS
			var a1 := (s + 1) * TAU / LADOS
			var quad := [[k, a0], [k, a1], [k + 1, a1], [k + 1, a0]]
			var pts := []
			for q in quad:
				var p: Vector3 = eje[q[0]][0]
				var r: float = eje[q[0]][1]
				var adelante: Vector3 = (eje[mini(q[0] + 1, n - 1)][0] - eje[maxi(q[0] - 1, 0)][0]).normalized()
				var lado := adelante.cross(Vector3.FORWARD if absf(adelante.z) < 0.9 else Vector3.RIGHT).normalized()
				var otro := adelante.cross(lado).normalized()
				var pos := p + (lado * cos(q[1]) + otro * sin(q[1])) * r
				var f := float(q[0]) / (n - 1)
				var col: Color = t["corteza"][0].lerp(t["corteza"][1], clampf(f * 0.8 + desfase, 0.0, 1.0))
				if t["abedul"]:
					var marca := sin(pos.y * 9.0 + q[1] * 2.0) * sin(pos.y * 3.3 + 1.0)
					if marca > 0.55:
						col = Color(0.2, 0.18, 0.17)           # marcas oscuras del abedul
				col = col * (0.75 + 0.25 * clampf(pos.y / 1.2, 0.0, 1.0))   # base algo más oscura
				pts.append([pos, Vector2(q[1] / TAU * 2.0, pos.y * 0.6), col])
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(pts[i][2])
				st.set_uv(pts[i][1])
				st.add_vertex(pts[i][0])


# Motas de luz del árbol mágico: pocas partículas que suben despacio (casi gratis).
static func _motas(centro: Vector3, radio: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 4.0
	p.preprocess = 4.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radio * 1.1
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.35
	p.gravity = Vector3(0, 0.05, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	var g := GradientTexture2D.new()
	var gg := Gradient.new()
	gg.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.gradient = gg
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	m.albedo_texture = g
	q.material = m
	p.mesh = q
	var rampa := Gradient.new()
	rampa.colors = PackedColorArray([Color(1.0, 0.85, 0.55, 0.0), Color(1.0, 0.9, 0.6, 1.0), Color(0.85, 0.7, 1.0, 0.0)])
	rampa.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	p.color_ramp = rampa
	p.position = centro
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p
