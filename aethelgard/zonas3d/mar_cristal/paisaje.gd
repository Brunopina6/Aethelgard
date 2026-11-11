extends RefCounted
# Riqueza del paisaje del Mar de Cristal (V12, 12/11, gráficos; docs/memory/agents/graficos_v12_desierto2.md). Sobre lo
# que ya había (terreno.gd), sin agrandar el mapa y sin nada que choque con el camino: cada cosa tiene una función.
#   - cristales semienterrados (una malla, una llamada, el vidrio de gráficos): rodean la trampilla y el tocón de las
#     ruinas, salpican el camino que sube a ellas (el corazón vitrificado está al norte), delatan el espejismo, alumbran
#     el nicho del esqueleto y brotan del costillar. Su borde brilla de lejos;
#   - matorrales secos y un hito de piedras (otra malla, otra llamada): al pie del cañón, a las afueras del campamento,
#     algo más verdes alrededor del oasis (donde hay agua) y un hito con un trapo junto al cobijo (el refugio de la
#     tormenta se reconoce de lejos);
#   - humo de la fogata: una columna que se ve desde casi todo el sector (dónde está el campamento) y se tuerce con el
#     viento;
#   - la caravana deja un rastro hacia el norte (un barril más), adonde marca el sello;
#   - surcos viejos del gusano en la arena que tiembla (una malla) y, solo en el alto, un remolino de polvo que vaga
#     por las dunas del este;
#   - las rocas que tapan a Kael (o el saliente del cobijo con Kael debajo) se vuelven medio transparentes.
# Sin azar en la partida: todo sale igual (semilla fija). Los cristales y matorrales no chocan.

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const RUTA_ARTE := "res://zonas3d/mar_cristal/materiales_arte.gd"
const SEMILLA := 1212

# [centro x, z, racimos, radio del corro, prismas por racimo, tamaño]
const SITIOS_CRISTAL := [
	[45.0, 23.0, 5, 3.9, 4, 1.0],      # la trampilla: un corro de vidrio alrededor de la estrella
	[52.0, 13.0, 2, 1.6, 4, 1.2],      # junto al tocón vitrificado (ruinas_columna_d)
	[37.5, 16.0, 2, 1.4, 3, 0.9],      # al oeste del arco
	[49.6, 35.5, 1, 0.0, 3, 0.7],      # el camino que sube a las ruinas: cada vez más vidrio
	[43.0, 30.5, 1, 0.0, 2, 0.6],
	[48.8, 27.5, 1, 0.0, 3, 0.8],
	[82.0, 30.0, 3, 3.0, 3, 0.9],      # el espejismo: el vidrio que hace temblar el aire
	[11.8, 30.5, 1, 0.0, 4, 0.8],      # el nicho del esqueleto
	[12.4, 27.8, 1, 0.0, 2, 0.6],
	[70.0, 37.0, 1, 0.0, 3, 0.9],      # el costillar
	[79.5, 36.2, 1, 0.0, 2, 0.7],
	[30.0, 12.0, 1, 0.0, 3, 0.8],      # destellos sueltos en las dunas del norte
	[62.0, 14.0, 1, 0.0, 2, 0.7],
	[67.0, 52.0, 1, 0.0, 2, 0.6],
	[24.0, 64.0, 1, 0.0, 2, 0.6],
]
const COLORES_CRISTAL := [Color(0.62, 0.90, 0.93), Color(0.70, 0.86, 0.98), Color(0.74, 0.68, 0.94), Color(0.66, 0.94, 0.86)]

var region: Node3D
var terreno
var perfil: Dictionary
var raiz: Node3D
var humo: CPUParticles3D
var _rocas: Array = []                            # [nodo, centro xz, radio, alto arriba, techo]
var _trans := {}                                  # material opaco -> copia medio transparente
var _tapadas := {}                                # nodo -> true
var _t_ocl := 0.0


func _init(r: Node3D, t, p: Dictionary) -> void:
	region = r
	terreno = t
	perfil = p


func construir(padre: Node3D) -> void:
	raiz = Node3D.new()
	raiz.name = "Paisaje"
	padre.add_child(raiz)
	_cristales()
	_matorrales()
	_rastro_caravana()
	_humo()
	_surcos()
	_remolino()


func _alto() -> bool:
	return bool(perfil.get("refraccion", false))


func _libre(p: Vector2, holgura := 1.6) -> bool:
	if T.prohibido(p.x, p.y) or T.en_camino(p.x, p.y):
		return false
	for s in [T.CARTOGRAFA, T.FOGATA, T.CARAVANA, T.TRAMPILLA, T.ESQUELETO, T.COBIJO] + T.TIENDAS:
		if p.distance_to(s) < holgura + 1.2:
			return false
	return p.distance_to(T.OASIS) > T.RADIO_ESTANQUE + 0.8


# ---------------------------------------------------------------- cristales

func _cristales() -> void:
	if not ResourceLoader.exists(RUTA_ARTE):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 0
	var bajo := not bool(perfil.get("sombras", false))
	for s in SITIOS_CRISTAL:
		var c := Vector2(s[0], s[1])
		for k in int(s[2]):
			var ang := TAU * k / maxf(float(s[2]), 1.0) + rng.randf_range(-0.4, 0.4)
			var p := c + Vector2(cos(ang), sin(ang)) * float(s[3]) * rng.randf_range(0.8, 1.15)
			if T.prohibido(p.x, p.y):
				continue
			var prismas := int(s[4]) - (1 if bajo and int(s[4]) > 2 else 0)
			var col: Color = COLORES_CRISTAL[rng.randi() % COLORES_CRISTAL.size()]
			for j in prismas:
				var off := Vector2(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.35, 0.35)) * float(s[5])
				var base := Vector3(p.x + off.x, T.altura(p.x + off.x, p.y + off.y), p.y + off.y)
				var incl := Vector3(rng.randf_range(-0.55, 0.55), 1.0, rng.randf_range(-0.55, 0.55)).normalized()
				if j == 0:
					incl = Vector3(incl.x * 0.4, 1.0, incl.z * 0.4).normalized()   # el mayor, casi derecho
				var alto: float = float(s[5]) * (1.25 if j == 0 else rng.randf_range(0.45, 0.9))
				var radio: float = alto * rng.randf_range(0.14, 0.2)
				_prisma(st, base, incl, radio, alto, col.lerp(Color(1, 1, 1), rng.randf_range(0.0, 0.25)), rng.randf() * TAU)
				n += 1
	if n == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = "Cristales"
	mi.mesh = st.commit()
	mi.material_override = load(RUTA_ARTE).mat_vidrio()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if _alto() else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(mi)


# Un prisma hexagonal con punta, enterrado un poco: la base va 0,25 m bajo la arena.
func _prisma(st: SurfaceTool, base: Vector3, eje: Vector3, radio: float, alto: float, col: Color, giro: float) -> void:
	var u := eje.cross(Vector3.FORWARD if absf(eje.z) < 0.9 else Vector3.RIGHT).normalized()
	var v := eje.cross(u).normalized()
	var abajo := base - eje * 0.25
	var cuello := base + eje * alto * 0.78
	var punta := base + eje * alto
	var anillo_a: Array = []
	var anillo_c: Array = []
	for i in 6:
		var a := giro + TAU * i / 6.0
		var d := u * cos(a) + v * sin(a)
		anillo_a.append(abajo + d * radio)
		anillo_c.append(cuello + d * radio * 0.92)
	st.set_color(col)
	for i in 6:
		var j := (i + 1) % 6
		var dentro: Vector3 = (abajo + cuello) * 0.5
		_tri(st, anillo_a[i], anillo_c[i], anillo_c[j], dentro)
		_tri(st, anillo_a[i], anillo_c[j], anillo_a[j], dentro)
		_tri(st, anillo_c[i], punta, anillo_c[j], cuello)


# Un triángulo con su normal de cara (Godot: de frente en el sentido de las agujas). Con «dentro», se gira si mira hacia
# ese punto (así las caras de prismas y cajas miran siempre afuera).
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, dentro := Vector3.INF) -> void:
	var nrm := (c - a).cross(b - a).normalized()
	if dentro != Vector3.INF and nrm.dot(a - dentro) < 0.0:
		var x := b
		b = c
		c = x
		nrm = -nrm
	for q in [a, b, c]:
		st.set_normal(nrm)
		st.add_vertex(q)


# ---------------------------------------------------------------- matorrales y el hito del cobijo

func _matorrales() -> void:
	if not ResourceLoader.exists(RUTA_ARTE):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA + 7
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sitios: Array = []
	# al pie del cañón (donde la roca da algo de sombra y retiene el agua de la noche)
	for k in 9:
		sitios.append([Vector2(rng.randf_range(14.0, 24.0), rng.randf_range(20.0, 82.0)), false])
	# a las afueras del campamento
	for k in 5:
		var a := rng.randf_range(0.0, TAU)
		sitios.append([T.CAMPAMENTO + Vector2(cos(a), sin(a)) * rng.randf_range(10.0, 14.0), false])
	# alrededor del oasis, más verdes
	for k in 7:
		var a := TAU * k / 7.0 + rng.randf_range(-0.3, 0.3)
		sitios.append([T.OASIS + Vector2(cos(a), sin(a)) * rng.randf_range(T.RADIO_OASIS + 0.5, T.RADIO_OASIS + 4.0), true])
	# sueltos por las dunas
	for k in 6:
		sitios.append([Vector2(rng.randf_range(24.0, 86.0), rng.randf_range(8.0, 104.0)), false])
	var puestos := 0
	for s in sitios:
		var p: Vector2 = s[0]
		if not _libre(p) or T.en_temblor(p.x, p.y):
			continue
		_mata(st, Vector3(p.x, T.altura(p.x, p.y), p.y), rng, s[1])
		puestos += 1
	_hito(st, Vector2(T.COBIJO.x + 5.6, T.COBIJO.y - 1.4))
	var mi := MeshInstance3D.new()
	mi.name = "Matorrales"
	mi.mesh = st.commit()
	mi.material_override = load(RUTA_ARTE).mat_base(perfil)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(perfil.get("sombras", false)) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(mi)


# Una mata seca: ramitas finas que salen del suelo hacia fuera (las dos caras), algunas con hojas pequeñas.
func _mata(st: SurfaceTool, base: Vector3, rng: RandomNumberGenerator, verde: bool) -> void:
	var tam := rng.randf_range(0.5, 0.95)
	var ramas := rng.randi_range(9, 13)
	for i in ramas:
		var a := TAU * i / ramas + rng.randf_range(-0.35, 0.35)
		var fuera := Vector3(cos(a), 0.0, sin(a))
		# la rama sube y se abre en dos tramos (una mata redonda y enmarañada, no un manojo de pinchos)
		var codo := base + fuera * tam * rng.randf_range(0.12, 0.25) + Vector3.UP * tam * rng.randf_range(0.3, 0.5)
		var punta := codo + fuera * tam * rng.randf_range(0.25, 0.45) + Vector3.UP * tam * rng.randf_range(0.1, 0.35)
		var lado := fuera.cross(Vector3.UP).normalized() * 0.022
		var c := Color(0.44, 0.37, 0.30).lerp(Color(0.60, 0.54, 0.44), rng.randf())
		st.set_color(c)
		_doble(st, base - lado * 1.4, base + lado * 1.4, codo)
		_doble(st, codo - lado, codo + lado, punta)
		var hojas := 2 if verde else (1 if rng.randf() < 0.45 else 0)
		for h in hojas:                                         # hojitas sueltas: rombos pequeños, verdes junto al oasis
			var sitio := codo.lerp(punta, rng.randf_range(0.3, 1.0))
			var cv := Color(0.40, 0.48, 0.27).lerp(Color(0.56, 0.60, 0.36), rng.randf()) if verde else c.lerp(Color(0.52, 0.50, 0.36), 0.6)
			var r := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 0.8), rng.randf_range(-1, 1)).normalized() * 0.07
			var q := r.cross(Vector3.UP).normalized() * 0.045
			st.set_color(cv)
			_doble(st, sitio - r, sitio + q, sitio + r)
			_doble(st, sitio - r, sitio + r, sitio - q)


func _doble(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, b)


# El hito de piedras del cobijo: cinco lajas apiladas y un palo con un trapo azul desteñido (el trapo lo mueve el viento,
# como las telas del campamento). Señala de lejos dónde esperar la tormenta.
func _hito(st: SurfaceTool, p: Vector2) -> void:
	var y := T.altura(p.x, p.y)
	var alto := 0.0
	for i in 5:
		var tam := Vector3(0.75 - i * 0.1, 0.22, 0.6 - i * 0.07)
		var c := Color(0.62, 0.50, 0.40).lerp(Color(0.72, 0.60, 0.48), float(i % 2))
		_caja(st, Vector3(p.x + 0.04 * sin(i * 2.0), y + alto, p.y + 0.04 * cos(i * 1.7)), tam, 0.5 * i, c)
		alto += tam.y * 0.92
	_caja(st, Vector3(p.x, y + alto - 0.1, p.y), Vector3(0.06, 1.5, 0.06), 0.0, Color(0.45, 0.33, 0.22))
	var trapo := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.55, 0.42)
	trapo.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.34, 0.46, 0.62)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	trapo.material_override = m
	trapo.position = Vector3(p.x + 0.3, y + alto + 1.18, p.y)
	trapo.name = "TrapoCobijo"
	raiz.add_child(trapo)
	terreno.telas.append(trapo)


func _caja(st: SurfaceTool, base: Vector3, tam: Vector3, giro: float, c: Color) -> void:
	var b := Basis(Vector3.UP, giro)
	var h := tam * 0.5
	var esq: Array = []
	for k in 8:
		var e := Vector3(h.x * (1 if k & 1 else -1), tam.y * (1 if k & 2 else 0), h.z * (1 if k & 4 else -1))
		esq.append(base + b * e)
	st.set_color(c)
	for cara in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]:
		var dentro := base + Vector3(0, tam.y * 0.5, 0)
		_tri(st, esq[cara[0]], esq[cara[2]], esq[cara[1]], dentro)
		_tri(st, esq[cara[0]], esq[cara[3]], esq[cara[2]], dentro)


# ---------------------------------------------------------------- la caravana y el humo

func _rastro_caravana() -> void:
	terreno.poner_modelo("caravana_barril", Vector3(51.6, T.altura(51.6, 54.6) - 0.15, 54.6), 0.9, null, null, 2.2, true)


func _humo() -> void:
	humo = CPUParticles3D.new()
	humo.name = "Humo"
	humo.amount = {"bajo": 7, "medio": 10}.get(str(region.get("nombre_perfil")), 14)
	humo.lifetime = 6.0
	humo.preprocess = 6.0
	humo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	humo.emission_sphere_radius = 0.15
	humo.direction = Vector3.UP
	humo.spread = 8.0
	humo.initial_velocity_min = 0.8
	humo.initial_velocity_max = 1.1
	humo.gravity = Vector3(0.22, 0.12, -0.06)                  # se tuerce hacia donde sopla (al este)
	humo.scale_amount_min = 0.9
	humo.scale_amount_max = 1.2
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.35))
	curva.add_point(Vector2(1.0, 2.6))
	humo.scale_amount_curve = curva
	var rampa := Gradient.new()
	rampa.offsets = PackedFloat32Array([0.0, 0.15, 0.7, 1.0])
	rampa.colors = PackedColorArray([Color(0.42, 0.38, 0.36, 0.0), Color(0.46, 0.42, 0.40, 0.55),
		Color(0.78, 0.74, 0.70, 0.32), Color(0.92, 0.88, 0.82, 0.0)])
	humo.color_ramp = rampa
	var q := QuadMesh.new()
	q.size = Vector2(1.2, 1.2)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _bola()
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = m
	humo.mesh = q
	humo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	humo.position = Vector3(T.FOGATA.x, T.altura(T.FOGATA.x, T.FOGATA.y) + 0.9, T.FOGATA.y)
	raiz.add_child(humo)


static func _bola() -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 32
	t.height = 32
	return t


# Con tormenta, el humo se lo lleva el viento (casi tumbado).
func viento(v: float) -> void:
	if humo != null:
		humo.gravity = Vector3(0.22 + 2.2 * maxf(0.0, v - 0.25), 0.12 - 0.08 * v, -0.06)


# ---------------------------------------------------------------- rocas que tapan a Kael

# Después de montar todo: las rocas de gráficos (y el cobijo) que pueden tapar a Kael.
func preparar_oclusion() -> void:
	for par in terreno.piezas_puestas:
		var n: Node3D = par[0]
		var id: String = par[1]
		if not is_instance_valid(n) or not (id.begins_with("roca") or id.begins_with("huesos")):
			continue
		var caja := _caja_mundo(n)
		if caja.size.y < 2.5:
			continue
		var c := Vector2(caja.get_center().x, caja.get_center().z)
		_rocas.append([n, c, minf(caja.size.x, caja.size.z) * 0.5, caja.end.y, id == "roca_cobijo"])


static func _caja_mundo(n: Node3D) -> AABB:
	var caja := AABB()
	var hay := false
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var b: AABB = m.global_transform * m.get_aabb()
		caja = b if not hay else caja.merge(b)
		hay = true
	return caja


func actualizar(delta: float) -> void:
	_mover_remolino(delta)
	_t_ocl -= delta
	if _t_ocl > 0.0 or _rocas.is_empty():
		return
	_t_ocl = 0.12
	var cam = region.get("cam")
	var kael = region.get("kael")
	if cam == null or kael == null:
		return
	var a: Vector3 = cam.global_position
	var b: Vector3 = kael.global_position + Vector3(0, 1.0, 0)
	var a2 := Vector2(a.x, a.z)
	var b2 := Vector2(b.x, b.z)
	var ab := b2 - a2
	for r in _rocas:
		var c: Vector2 = r[1]
		var tapa := false
		var t := clampf((c - a2).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		if t > 0.05 and t < 0.98 and (a2 + ab * t).distance_to(c) < float(r[2]) * 0.95:
			tapa = float(r[3]) > lerpf(a.y, b.y, t) - 0.3
		if r[4] and b2.distance_to(T.COBIJO) < T.RADIO_COBIJO - 0.6:
			tapa = true                                         # Kael bajo el saliente del cobijo
		if tapa != _tapadas.has(r[0]):
			_transparente(r[0], tapa)


func _transparente(n: Node3D, si: bool) -> void:
	if si:
		_tapadas[n] = true
	else:
		_tapadas.erase(n)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for i in m.get_surface_override_material_count():
			var mat := m.get_surface_override_material(i)
			if si and mat is StandardMaterial3D:
				m.set_surface_override_material(i, _copia(mat))
				m.set_meta("opaco_%d" % i, mat)
			elif not si and m.has_meta("opaco_%d" % i):
				m.set_surface_override_material(i, m.get_meta("opaco_%d" % i))
				m.remove_meta("opaco_%d" % i)


func _copia(m: StandardMaterial3D) -> StandardMaterial3D:
	if not _trans.has(m):
		var t := m.duplicate() as StandardMaterial3D
		t.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		t.albedo_color = Color(m.albedo_color, 0.3)
		t.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		_trans[m] = t
	return _trans[m]


# ---------------------------------------------------------------- la arena que tiembla y el remolino

# [inicio x, z, dirección x, z, largo, amplitud, frecuencia]: surcos viejos que cruzan la arena del gusano sin pisar el
# costillar ni el espejismo.
const SURCOS := [[61.5, 46.0, 1.0, -0.45, 24.0, 1.8, 0.25], [62.0, 23.5, 1.0, 0.22, 21.0, 1.5, 0.3],
	[80.5, 48.5, 0.12, -1.0, 13.0, 1.2, 0.35]]
const ANCHO_SURCO := 1.5


func _surcos() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in SURCOS:
		var ini := Vector2(s[0], s[1])
		var dir := Vector2(s[2], s[3]).normalized()
		var lat := Vector2(-dir.y, dir.x)
		var largo: float = s[4]
		var pasos := int(largo)
		var prev: Array = []
		for i in pasos + 1:
			var d := largo * i / pasos
			var c := ini + dir * d + lat * float(s[5]) * sin(d * float(s[6]))
			var a := 1.0 - smoothstep(0.7, 1.0, absf(d / largo * 2.0 - 1.0))     # se apaga en los extremos
			var izq := c - lat * ANCHO_SURCO * 0.5
			var der := c + lat * ANCHO_SURCO * 0.5
			var fila := [Vector3(izq.x, T.altura(izq.x, izq.y) + 0.12, izq.y), Vector3(der.x, T.altura(der.x, der.y) + 0.12, der.y), a]
			if not prev.is_empty():
				for k in [[prev, 0, 0.0], [prev, 1, 1.0], [fila, 1, 1.0], [prev, 0, 0.0], [fila, 1, 1.0], [fila, 0, 0.0]]:
					var f: Array = k[0]
					st.set_color(Color(1, 1, 1, f[2]))
					st.set_uv(Vector2(0.0, k[2]))
					st.set_normal(Vector3.UP)
					st.add_vertex(f[k[1]])
			prev = fila
	var mi := MeshInstance3D.new()
	mi.name = "Surcos"
	mi.mesh = st.commit()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/desierto/surco.gdshader")
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(mi)


# Un remolino de polvo que vaga despacio por las dunas abiertas del este (solo en el alto: partículas con transparencia,
# lejos de Kael). Se ve desde casi todo el sector y dice de dónde sopla.
var remolino: CPUParticles3D
var _t_rem := 0.0
const CENTRO_REMOLINO := Vector2(70.0, 56.0)


func _remolino() -> void:
	if not _alto():
		return
	remolino = CPUParticles3D.new()
	remolino.name = "Remolino"
	remolino.amount = 30
	remolino.lifetime = 2.6
	remolino.preprocess = 3.0
	remolino.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	remolino.emission_ring_axis = Vector3.UP
	remolino.emission_ring_radius = 0.5
	remolino.emission_ring_inner_radius = 0.2
	remolino.emission_ring_height = 0.2
	remolino.direction = Vector3.UP
	remolino.spread = 10.0
	remolino.initial_velocity_min = 1.8
	remolino.initial_velocity_max = 2.6
	remolino.gravity = Vector3(0.3, 0.2, 0.0)
	remolino.tangential_accel_min = 5.0
	remolino.tangential_accel_max = 7.0
	remolino.radial_accel_min = 0.4
	remolino.radial_accel_max = 0.9
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.4))
	curva.add_point(Vector2(1.0, 2.2))
	remolino.scale_amount_curve = curva
	var rampa := Gradient.new()
	rampa.offsets = PackedFloat32Array([0.0, 0.2, 0.75, 1.0])
	rampa.colors = PackedColorArray([Color(0.86, 0.74, 0.56, 0.0), Color(0.86, 0.74, 0.56, 0.38),
		Color(0.92, 0.84, 0.68, 0.2), Color(0.95, 0.88, 0.74, 0.0)])
	remolino.color_ramp = rampa
	var q := QuadMesh.new()
	q.size = Vector2(0.8, 0.8)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _bola()
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = m
	remolino.mesh = q
	remolino.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(remolino)
	_mover_remolino(0.0)


func _mover_remolino(delta: float) -> void:
	if remolino == null:
		return
	_t_rem += delta
	var p := CENTRO_REMOLINO + Vector2(cos(_t_rem * 0.05) * 9.0, sin(_t_rem * 0.07) * 7.0)
	remolino.position = Vector3(p.x, T.altura(p.x, p.y) + 0.1, p.y)
