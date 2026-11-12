extends RefCounted
# El Viejo Observatorio de Calid (V12, 12/11; PROTOTIPO APAGADO, interruptor «naira_v12» de grupo.gd). Lo construye la
# misión de Naira (naira_mision.gd) dentro del primer sector del Mar de Cristal, al nordeste, más allá de la arena que
# tiembla (docs/v12/NAIRA.md §4.1, opción barata: el exterior de la torre, sin sala interior).
#
# Lo que hay: una torre de arenisca medio enterrada (la duna le ha subido por el lado norte), con su cornisa de bronce
# verdeado, almenas rotas, una puerta en arco hacia el sur y, arriba, el instrumento: una esfera armilar de tres aros que
# gira despacio y un anteojo apuntado al cielo. Delante, la explanada (trazado.gd, llanos_extra), un trípode con las
# plomadas colgadas (una al principio; cuatro tras la medición), el atril con el Almanaque y Naira en la puerta.
# El cielo del eclipse: estrellas (una malla de puntos) y el sol tapado con su corona, que solo se ven con el eclipse y
# con la cámara baja del momento (naira_mision.gd). Formas sencillas (como Tilo, el cofre o el nido): provisional.
# Coste: unas 30 mallas pequeñas, 1 de puntos, 2 planos del cielo y el modelo provisional de Naira (14 090 triángulos);
# sin luces nuevas. Sin medir en el Redmi.

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const TORRE := Vector2(70.0, 9.0)
const RADIO_TORRE := 3.3
const PUERTA := Vector2(70.0, 13.9)              # donde espera Naira
const ATRIL := Vector2(73.6, 13.6)
const TRIPODE := Vector2(66.4, 13.6)
const LLANO := [Vector2(70.0, 11.5), 14.0]       # la explanada (trazado.gd, llanos_extra)
const ARENISCA := Color(0.86, 0.72, 0.55)
const ARENISCA_OSCURA := Color(0.66, 0.51, 0.38)
const BRONCE := Color(0.72, 0.50, 0.26)
const VERDIN := Color(0.37, 0.62, 0.55)
const PIZARRA := Color(0.20, 0.24, 0.36)
const ARENA := Color(0.90, 0.74, 0.52)

var region: Node3D
var perfil: Dictionary
var raiz: Node3D
var naira: Node3D                                # el modelo provisional (personajes/naira/naira_3d.gd), o null
var aros: Array = []                             # los tres aros de la esfera armilar
var mat_aros: StandardMaterial3D
var plomadas: Array = []                         # las bolas de bronce colgadas del trípode
var cielo: Node3D
var _estrellas: MeshInstance3D
var _mat_estrellas: StandardMaterial3D
var _sol: Node3D
var _mat_corona: StandardMaterial3D
var _mat_luna: StandardMaterial3D
var _y := 0.0


func _init(r: Node3D, p: Dictionary) -> void:
	region = r
	perfil = p


static func prohibido(p: Vector3) -> bool:
	var q := Vector2(p.x, p.z)
	return q.distance_to(TORRE) < RADIO_TORRE + 0.35 or q.distance_to(ATRIL) < 0.8 or q.distance_to(TRIPODE) < 0.6


func construir() -> void:
	raiz = Node3D.new()
	raiz.name = "Observatorio"
	region.add_child(raiz)
	_y = T.altura(TORRE.x, TORRE.y)
	_torre()
	_instrumento()
	_dunas()
	_tripode()
	_atril()
	_choques()
	_cielo()


func _mat(c: Color, rug := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	m.metallic = metal
	return m


func _malla(m: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, escala := Vector3.ONE, padre: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = escala
	(padre if padre != null else raiz).add_child(mi)
	return mi


func _cilindro(arriba: float, abajo: float, alto: float, lados := 20) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = arriba
	c.bottom_radius = abajo
	c.height = alto
	c.radial_segments = lados
	return c


func _caja(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b


# ---------------------------------------------------------------- la torre

func _torre() -> void:
	var c := Vector3(TORRE.x, _y, TORRE.y)
	var piedra := _mat(ARENISCA)
	var oscura := _mat(ARENISCA_OSCURA)
	# el tambor: 7 m, de los que 2 quedan bajo la arena
	_malla(_cilindro(3.0, RADIO_TORRE, 7.0, 28), piedra, c + Vector3(0, 1.5, 0))
	for y in [1.4, 3.5]:                                        # dos franjas de sillares más oscuros
		_malla(_cilindro(3.12 - y * 0.03, 3.16 - y * 0.03, 0.26, 28), oscura, c + Vector3(0, y, 0))
	_malla(_cilindro(3.28, 3.08, 0.36, 28), _mat(VERDIN, 0.6, 0.35), c + Vector3(0, 5.15, 0))   # cornisa de bronce verdeado
	_malla(_cilindro(2.95, 2.95, 0.12, 28), _mat(ARENISCA_OSCURA, 0.95), c + Vector3(0, 5.36, 0))   # el suelo de arriba
	var almena := _caja(Vector3(0.75, 0.75, 0.45))
	for i in 12:                                                # almenas: faltan tres (rotas)
		if i in [2, 3, 8]:
			continue
		var a := TAU * i / 12.0
		_malla(almena, piedra, c + Vector3(sin(a) * 3.0, 5.7, cos(a) * 3.0), Vector3(0, a, 0))
	# la puerta en arco, hacia el sur (+z): un hueco oscuro con su marco de bronce y la arena metida en el umbral
	var hueco := _mat(Color(0.10, 0.08, 0.09), 1.0)
	_malla(_caja(Vector3(1.4, 2.0, 0.8)), hueco, c + Vector3(0, 1.0, 3.0))
	var arco := _cilindro(0.7, 0.7, 0.8, 16)
	_malla(arco, hueco, c + Vector3(0, 2.0, 3.0), Vector3(PI / 2.0, 0, 0))
	var bronce := _mat(BRONCE, 0.45, 0.6)
	for lado in [-1.0, 1.0]:
		_malla(_caja(Vector3(0.18, 2.1, 0.22)), bronce, c + Vector3(lado * 0.82, 1.05, 3.38))
	var dintel := TorusMesh.new()
	dintel.inner_radius = 0.72
	dintel.outer_radius = 0.92
	dintel.rings = 20
	_malla(dintel, bronce, c + Vector3(0, 2.0, 3.36), Vector3(PI / 2.0, 0, 0), Vector3(1, 1, 0.6))
	_malla(SphereMesh.new(), _mat(ARENA, 1.0), c + Vector3(0.2, -0.15, 3.3), Vector3.ZERO, Vector3(1.6, 0.35, 0.9))
	for a in [-0.55, 0.05, 0.6]:                                # saeteras en lo alto
		_malla(_caja(Vector3(0.22, 0.75, 0.5)), hueco, c + Vector3(sin(a) * 3.02, 4.2, cos(a) * 3.02), Vector3(0, a, 0))


# ---------------------------------------------------------------- el instrumento de arriba

func _instrumento() -> void:
	var c := Vector3(TORRE.x, _y + 5.42, TORRE.y)
	var bronce := _mat(BRONCE, 0.4, 0.65)
	_malla(_cilindro(0.35, 0.55, 0.9, 12), _mat(ARENISCA_OSCURA), c + Vector3(0, 0.45, 0))   # el pedestal
	mat_aros = _mat(BRONCE, 0.35, 0.7)
	mat_aros.emission_enabled = true
	mat_aros.emission = Color(1.0, 0.82, 0.48)
	mat_aros.emission_energy_multiplier = 0.0
	var centro := c + Vector3(0, 1.9, 0)
	var eje := Node3D.new()                                      # el eje del polo, inclinado
	eje.position = centro
	eje.rotation = Vector3(deg_to_rad(28.0), 0, 0)
	raiz.add_child(eje)
	for i in 3:
		var t := TorusMesh.new()
		t.inner_radius = 1.08 - i * 0.16
		t.outer_radius = 1.16 - i * 0.16
		t.rings = 32
		t.ring_segments = 6
		var aro := _malla(t, mat_aros, Vector3.ZERO, Vector3(PI / 2.0 if i != 1 else 0.0, i * 0.9, 0), Vector3.ONE, eje)
		aros.append(aro)
	_malla(_cilindro(0.04, 0.04, 2.6, 6), bronce, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, eje)    # el eje
	var nucleo := SphereMesh.new()
	nucleo.radius = 0.2
	nucleo.height = 0.4
	_malla(nucleo, _mat(PIZARRA, 0.5, 0.2), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, eje)
	# el anteojo, apoyado en el parapeto y apuntado al cielo del noreste
	var anteojo := Node3D.new()
	anteojo.position = c + Vector3(1.9, 0.9, -1.2)
	anteojo.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(-35.0), 0)
	raiz.add_child(anteojo)
	_malla(_cilindro(0.16, 0.2, 2.6, 12), bronce, Vector3(0, 0, -1.0), Vector3(PI / 2.0, 0, 0), Vector3.ONE, anteojo)
	_malla(_cilindro(0.23, 0.23, 0.3, 12), _mat(VERDIN, 0.6, 0.35), Vector3(0, 0, -2.2), Vector3(PI / 2.0, 0, 0), Vector3.ONE, anteojo)


# ---------------------------------------------------------------- la arena que la entierra

func _dunas() -> void:
	var arena := _mat(ARENA, 1.0)
	var esfera := SphereMesh.new()
	esfera.radial_segments = 20
	esfera.rings = 10
	for d in [[Vector3(-3.4, -0.2, -1.0), Vector3(3.2, 1.3, 3.0)], [Vector3(3.3, -0.3, -1.6), Vector3(3.0, 1.1, 3.4)],
			[Vector3(0.0, -0.4, -4.0), Vector3(6.2, 2.4, 3.2)], [Vector3(-2.6, -0.3, 2.0), Vector3(1.6, 0.45, 1.3)]]:
		_malla(esfera, arena, Vector3(TORRE.x, _y, TORRE.y) + d[0], Vector3.ZERO, d[1])


# ---------------------------------------------------------------- el trípode de las plomadas y el atril

func _tripode() -> void:
	var c := Vector3(TRIPODE.x, T.altura(TRIPODE.x, TRIPODE.y), TRIPODE.y)
	var madera := _mat(Color(0.45, 0.32, 0.20))
	for i in 3:                                                  # tres patas que se juntan arriba
		var a := TAU * i / 3.0 + 0.4
		var pie := Vector3(sin(a) * 0.75, 0, cos(a) * 0.75)
		var arriba := Vector3(0, 2.3, 0)
		var pata := _malla(_cilindro(0.035, 0.05, pie.distance_to(arriba), 6), madera, c + (pie + arriba) * 0.5)
		pata.look_at(c + arriba, Vector3.UP if absf((arriba - pie).normalized().dot(Vector3.UP)) < 0.99 else Vector3.FORWARD)
		pata.rotate_object_local(Vector3.RIGHT, -PI / 2.0)       # el eje del cilindro (+Y), hacia arriba
	_malla(_cilindro(0.03, 0.03, 1.5, 6), madera, c + Vector3(0, 2.22, 0), Vector3(0, 0, PI / 2.0))   # el travesaño
	colgar(1)


# n plomadas colgadas (1 al principio: la que pisó Kael; 4 tras la medición).
func colgar(n: int) -> void:
	for p in plomadas:
		p.queue_free()
	plomadas.clear()
	var c := Vector3(TRIPODE.x, T.altura(TRIPODE.x, TRIPODE.y), TRIPODE.y)
	var hilo := _mat(Color(0.85, 0.80, 0.70), 1.0)
	var bronce := _mat(BRONCE, 0.4, 0.65)
	var bola := SphereMesh.new()
	bola.radius = 0.09
	bola.height = 0.22
	for i in n:
		var x := -0.6 + 0.4 * i
		var nodo := Node3D.new()
		nodo.position = c + Vector3(x, 2.2, 0)
		raiz.add_child(nodo)
		var largo := 1.3 + 0.15 * (i % 2)
		_malla(_cilindro(0.008, 0.008, largo, 4), hilo, Vector3(0, -largo * 0.5, 0), Vector3.ZERO, Vector3.ONE, nodo)
		_malla(bola, bronce, Vector3(0, -largo - 0.06, 0), Vector3.ZERO, Vector3.ONE, nodo)
		plomadas.append(nodo)


func _atril() -> void:
	var c := Vector3(ATRIL.x, T.altura(ATRIL.x, ATRIL.y), ATRIL.y)
	var piedra := _mat(ARENISCA_OSCURA)
	_malla(_caja(Vector3(0.9, 0.8, 0.6)), piedra, c + Vector3(0, 0.4, 0), Vector3(0, -0.3, 0))
	var libro := _caja(Vector3(0.62, 0.09, 0.44))
	_malla(libro, _mat(Color(0.14, 0.20, 0.44), 0.8), c + Vector3(0, 0.86, 0), Vector3(-0.25, -0.3, 0))   # el Almanaque
	_malla(_caja(Vector3(0.08, 0.1, 0.46)), _mat(BRONCE, 0.4, 0.65), c + Vector3(0.24, 0.87, 0.06), Vector3(-0.25, -0.3, 0))
	var vela := _cilindro(0.04, 0.05, 0.22, 8)                   # una vela apagada y un lápiz: aquí se apunta
	_malla(vela, _mat(Color(0.95, 0.92, 0.82)), c + Vector3(-0.32, 0.91, -0.12))


func _choques() -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "ChoqueObservatorio"
	for f in [[CylinderShape3D, Vector3(TORRE.x, _y + 3.0, TORRE.y), RADIO_TORRE + 0.1, 8.0],
			[BoxShape3D, Vector3(ATRIL.x, T.altura(ATRIL.x, ATRIL.y) + 0.4, ATRIL.y), 0.0, 0.0]]:
		var cs := CollisionShape3D.new()
		var s = f[0].new()
		if s is CylinderShape3D:
			s.radius = f[2]
			s.height = f[3]
		else:
			s.size = Vector3(0.9, 0.8, 0.6)
		cs.shape = s
		cs.position = f[1]
		cuerpo.add_child(cs)
	raiz.add_child(cuerpo)


# ---------------------------------------------------------------- Naira, en la puerta

func poner_naira() -> void:
	if naira != null or not ResourceLoader.exists("res://personajes/naira/naira_3d.gd"):
		return
	var n = load("res://personajes/naira/naira_3d.gd").new()
	n.name = "NairaObservatorio"
	raiz.add_child(n)
	if n.get("anim") == null or n.get("skel") == null:          # sin modelo, no sale (la misión sigue igual)
		n.queue_free()
		return
	n.scale = Vector3.ONE * (1.55 / 1.7)                         # como en la exploración (grupo_3d.gd, ESCALA)
	n.global_position = Vector3(PUERTA.x, T.altura(PUERTA.x, PUERTA.y), PUERTA.y)
	if n.has_method("reposo"):
		n.reposo()
	if n.has_method("mirar"):
		n.mirar(Vector3(0.25, 0, 1.0), 0.01)                     # hacia el sur: hacia quien llega
	naira = n


func concentrar(si: bool) -> void:
	if naira == null:
		return
	if si and naira.has_method("concentrar"):
		naira.concentrar()
	elif not si and naira.has_method("reposo"):
		naira.reposo()


# Se va con el grupo (nr_union): un fundido corto y fuera.
func quitar_naira() -> void:
	if naira == null:
		return
	var n := naira
	naira = null
	var t := n.create_tween()
	t.tween_property(n, "scale", Vector3.ONE * 0.01, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(n.queue_free)


# ---------------------------------------------------------------- el cielo del eclipse

func _cielo() -> void:
	cielo = Node3D.new()
	cielo.name = "CieloEclipse"
	cielo.visible = false
	raiz.add_child(cielo)
	# estrellas: una sola malla de puntos sobre una cúpula hacia el norte (adonde mira la cámara)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4141
	var pts := PackedVector3Array()
	var cols := PackedColorArray()
	var centro := Vector3(TORRE.x, 0.0, TORRE.y + 14.0)
	var cuantas := {"bajo": 180, "medio": 260, "alto": 340}
	for i in int(cuantas.get(str(region.get("nombre_perfil")), 260)):
		var az := rng.randf_range(-1.2, 1.2)
		var el := asin(rng.randf_range(0.02, 0.85))
		pts.append(centro + Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el)) * 170.0)
		var b := rng.randf_range(0.45, 1.0)
		cols.append(Color(b, b, minf(1.0, b * 1.15), 1.0))
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pts
	arr[Mesh.ARRAY_COLOR] = cols
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arr)
	_mat_estrellas = StandardMaterial3D.new()
	_mat_estrellas.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_estrellas.vertex_color_use_as_albedo = true
	_mat_estrellas.use_point_size = true
	_mat_estrellas.point_size = 3.0 if str(region.get("nombre_perfil")) == "alto" else 2.5
	_mat_estrellas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_estrellas.disable_fog = true
	_mat_estrellas.albedo_color = Color(1, 1, 1, 0)
	_estrellas = MeshInstance3D.new()
	_estrellas.name = "Estrellas"
	_estrellas.mesh = malla
	_estrellas.material_override = _mat_estrellas
	_estrellas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_estrellas.extra_cull_margin = 400.0
	cielo.add_child(_estrellas)
	# el sol tapado: la corona (un halo dorado que suma luz) y el disco negro de delante
	_sol = Node3D.new()
	_sol.name = "SolTapado"
	cielo.add_child(_sol)
	_mat_corona = _mat_cielo(_degradado([0.0, 0.30, 0.42, 0.62, 1.0],
		[Color(1, 0.95, 0.8, 1), Color(1, 0.93, 0.75, 1), Color(1, 0.84, 0.55, 0.85), Color(1, 0.7, 0.35, 0.25), Color(1, 0.6, 0.3, 0)]), true)
	_mat_luna = _mat_cielo(_degradado([0.0, 0.40, 0.43, 1.0],
		[Color(0.02, 0.02, 0.05, 1), Color(0.02, 0.02, 0.05, 1), Color(0.02, 0.02, 0.05, 0), Color(0, 0, 0, 0)]), false)
	_mat_luna.render_priority = 1
	for d in [[_mat_corona, 26.0, 0.0], [_mat_luna, 26.0, 0.5]]:   # la luna, delante (hacia la cámara, al sur)
		var q := QuadMesh.new()
		q.size = Vector2(d[1], d[1])
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = d[0]
		mi.position = Vector3(0, 0, d[2])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 200.0
		_sol.add_child(mi)


func _degradado(offs: Array, colores: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(colores)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


func _mat_cielo(tex: Texture2D, suma: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.disable_fog = true
	m.no_depth_test = false
	if suma:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m


# El sol, donde lo ve la cámara baja del momento (detrás y por encima de la torre, desde donde está Kael).
func poner_sol(kael_pos: Vector3) -> void:
	if _sol != null:
		_sol.global_position = Vector3(TORRE.x + 16.0, kael_pos.y + 22.0, kael_pos.z - 104.0)   # arriba a la derecha de la torre


# Cada fotograma: los aros giran; con el eclipse, el cielo aparece y los aros se encienden un poco.
func animar(t: float, eclipse: float) -> void:
	for i in aros.size():
		aros[i].rotation.z = t * (0.10 + 0.06 * i) * (1.0 if i % 2 == 0 else -1.0)
	if mat_aros != null:
		mat_aros.emission_energy_multiplier = 0.9 * eclipse
	if cielo == null:
		return
	cielo.visible = eclipse > 0.02
	if not cielo.visible:
		return
	_mat_estrellas.albedo_color.a = smoothstep(0.45, 1.0, eclipse)
	_mat_luna.albedo_color.a = clampf(eclipse * 1.6, 0.0, 1.0)
	_mat_corona.albedo_color = Color(1, 1, 1, smoothstep(0.55, 1.0, eclipse))
