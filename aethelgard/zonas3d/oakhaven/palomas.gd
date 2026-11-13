extends MultiMeshInstance3D
# Las palomas de la plaza (V12, mundo vivo de Oakhaven; oakhaven_vida.gd ya las tenÃ­a como datos de fauna): una bandada
# pequeÃ±a que picotea el grano de la abuela y levanta el vuelo si Kael se le echa encima; vuelve al rato.
# UNA llamada de dibujo para todas (MultiMesh con una malla de bolas de vÃ©rtices de color). Solo se mueven si se ven y
# Kael estÃ¡ cerca (mundo_vivo.gd llama a animar()); fuera de eso, quietas o escondidas.

const CUANTAS := 7
const RADIO := 0.7
const ESPANTA := 2.3             # m: Kael mÃ¡s cerca que esto y salen volando
const VUELTA := 16.0             # s hasta que vuelven
var centro := Vector2.ZERO
var aves: Array = []             # {p (Vector2), ang, fase, picar, alto, vuelo (Vector3) }
var volando := 0.0               # s de vuelo (0: en el suelo)
var fuera := 0.0                 # s que faltan para volver
var _dir := Vector2.ZERO


static func crear(centro_: Vector2, y: float) -> MultiMeshInstance3D:
	var n: MultiMeshInstance3D = load("res://zonas3d/oakhaven/palomas.gd").new()
	n.name = "Palomas"
	n.centro = centro_
	n.position = Vector3(centro_.x, y, centro_.y)
	n._montar()
	return n


func _montar() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_bola(st, Vector3(0, 0.085, 0), Vector3(0.065, 0.06, 0.1), Color(0.56, 0.59, 0.67))      # cuerpo
	_bola(st, Vector3(0, 0.15, 0.085), Vector3(0.04, 0.04, 0.045), Color(0.36, 0.42, 0.52))  # cabeza tornasolada
	_bola(st, Vector3(0, 0.1, -0.1), Vector3(0.045, 0.014, 0.065), Color(0.40, 0.43, 0.52))  # cola
	_bola(st, Vector3(0, 0.145, 0.13), Vector3(0.012, 0.01, 0.022), Color(0.85, 0.55, 0.30))  # pico
	for l in [-1.0, 1.0]:
		_bola(st, Vector3(0.05 * l, 0.095, -0.01), Vector3(0.018, 0.04, 0.075), Color(0.48, 0.51, 0.60))   # alas
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mesh.surface_set_material(0, mat)
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = CUANTAS
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in CUANTAS:
		var a := TAU * i / CUANTAS + randf() * 0.5
		aves.append({"p": Vector2(cos(a), sin(a)) * RADIO * randf_range(0.3, 1.0), "ang": randf() * TAU,
			"fase": randf() * 10.0, "picar": 0.0, "vuelo": Vector3.ZERO})
	_poner_todas()


func _bola(st: SurfaceTool, c: Vector3, r: Vector3, color: Color) -> void:
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 8
	s.rings = 4
	var a := s.get_mesh_arrays()
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	for i in idx:
		st.set_color(color)
		st.set_normal((ns[i] / r).normalized())
		st.add_vertex(c + vs[i] * r)


func _poner_todas() -> void:
	for i in CUANTAS:
		var av: Dictionary = aves[i]
		var b := Basis(Vector3.UP, av["ang"]) * Basis(Vector3.RIGHT, av["picar"])
		var p: Vector2 = av["p"]
		multimesh.set_instance_transform(i, Transform3D(b, Vector3(p.x, 0, p.y) + av["vuelo"]))


# Cada fotograma en que se ven: andan a saltitos, picotean; si Kael se acerca, vuelan.
func animar(delta: float, kael: Vector3) -> void:
	var dk := Vector2(kael.x - global_position.x, kael.z - global_position.z)
	if fuera > 0.0:
		fuera -= delta
		if fuera <= 0.0 and dk.length() > ESPANTA * 3.0:
			visible = true
			volando = 0.0
			for av in aves:
				av["vuelo"] = Vector3.ZERO
		return
	if volando > 0.0:
		volando += delta
		for av in aves:
			var k := volando * (1.0 + float(av["fase"]) * 0.05)
			av["vuelo"] = Vector3(_dir.x * k * 5.0, k * k * 2.2 + k * 1.5, _dir.y * k * 5.0)
			av["picar"] = -0.5
		_poner_todas()
		if volando > 1.8:
			visible = false
			fuera = VUELTA
		return
	if dk.length() < ESPANTA:
		volando = 0.001
		_dir = (-dk).normalized() if dk.length() > 0.01 else Vector2.RIGHT
		var son = get_node_or_null("/root/Sonido")
		if son != null and son.has_method("efecto"):
			son.efecto("pajaro")
		return
	for av in aves:
		av["fase"] += delta
		var f: float = av["fase"]
		av["picar"] = maxf(0.0, sin(f * 6.0)) * 0.7 if fmod(f, 4.0) < 2.0 else 0.0
		if fmod(f, 4.0) > 3.6:                                   # un saltito hacia otro grano
			var np: Vector2 = av["p"] + Vector2(sin(av["ang"]), cos(av["ang"])) * 0.25 * delta
			if np.length() < RADIO:
				av["p"] = np
			else:
				av["ang"] += PI * 0.6
		elif fmod(f, 7.0) < delta:
			av["ang"] += randf_range(-1.2, 1.2)
	_poner_todas()
