extends Node3D
# Fauna de prueba hecha con formas simples (PROTOTIPO, Fase 2): un conejo que da saltitos por su zona
# y huye si Kael se acerca, y un pájaro que planea en círculos batiendo las alas.
# Sustituibles por modelos de Meshy sin cambiar el comportamiento.

@export var tipo := "conejo"          # "conejo" | "pajaro"
var kael: Node3D                      # para que el conejo huya
var casa := Vector3.ZERO
var radio := 4.0

var _cuerpo: Node3D
var _alas: Array = []
var _destino := Vector3.ZERO
var _espera := 1.0
var _salto := 0.0
var _t := 0.0
var _vel := 1.4


func _ready() -> void:
	casa = global_position
	_t = randf() * 10.0
	if tipo == "pajaro":
		_hacer_pajaro()
	else:
		_hacer_conejo()
		_destino = casa


func _bola(r: float, c: Color, pos: Vector3, esc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 6
	mi.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	mi.material_override = m
	mi.position = pos
	mi.scale = esc
	_cuerpo.add_child(mi)
	return mi


func _hacer_conejo() -> void:
	_cuerpo = Node3D.new()
	add_child(_cuerpo)
	var piel := Color(0.93, 0.89, 0.82)
	_bola(0.17, piel, Vector3(0, 0.17, 0), Vector3(1.0, 0.9, 1.3))
	_bola(0.11, piel, Vector3(0, 0.3, 0.2))
	_bola(0.05, Color.WHITE, Vector3(0, 0.2, -0.22))                   # cola
	for x in [-0.04, 0.04]:
		_bola(0.03, piel, Vector3(x, 0.45, 0.17), Vector3(0.8, 3.2, 0.6))   # orejas
		_bola(0.018, Color(0.1, 0.05, 0.05), Vector3(x * 1.6, 0.33, 0.29))  # ojos


func _hacer_pajaro() -> void:
	_cuerpo = Node3D.new()
	add_child(_cuerpo)
	var azul := Color(0.3, 0.55, 0.95)
	_bola(0.09, azul, Vector3.ZERO, Vector3(0.9, 0.8, 1.5))
	_bola(0.06, azul, Vector3(0, 0.05, 0.13))
	for lado in [-1.0, 1.0]:
		var pivote := Node3D.new()
		pivote.position = Vector3(0.06 * lado, 0.03, 0)
		_cuerpo.add_child(pivote)
		var ala := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.28, 0.14)
		ala.mesh = q
		ala.rotation_degrees.x = -90.0
		ala.position = Vector3(0.14 * lado, 0, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = azul.lightened(0.15)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		ala.material_override = m
		pivote.add_child(ala)
		_alas.append([pivote, lado])


func _process(delta: float) -> void:
	_t += delta
	if tipo == "pajaro":
		_volar(delta)
	else:
		_saltar(delta)


# Planea en círculo alrededor de su casa, sube y baja un poco y bate las alas a ratos.
func _volar(_delta: float) -> void:
	var ang := _t * 0.35
	var p := casa + Vector3(cos(ang) * radio, sin(_t * 0.7) * 0.6, sin(ang) * radio)
	var antes := global_position
	global_position = p
	var dir := p - antes
	if dir.length() > 0.0001:
		look_at(p + dir, Vector3.UP)
		rotate_object_local(Vector3.UP, PI)          # el pico mira hacia +Z del cuerpo
	var batiendo := fmod(_t, 4.0) < 1.6
	var a := sin(_t * 18.0) * 0.9 if batiendo else 0.15
	for par in _alas:
		par[0].rotation.z = a * par[1]


# Saltitos entre puntos de su zona; si Kael se acerca, huye más rápido en dirección contraria.
func _saltar(delta: float) -> void:
	var huye := false
	if kael != null:
		var d := global_position - kael.global_position
		d.y = 0.0
		if d.length() < 3.0:
			huye = true
			_destino = global_position + d.normalized() * 3.5
			_espera = 0.0
	if _espera > 0.0:
		_espera -= delta
		_cuerpo.position.y = 0.0
		return
	var falta := _destino - global_position
	falta.y = 0.0
	if falta.length() < 0.15:
		_espera = randf_range(0.8, 2.5)
		var a := randf() * TAU
		_destino = casa + Vector3(cos(a), 0, sin(a)) * randf_range(0.5, radio)
		return
	var v := (_vel * 2.2 if huye else _vel)
	var paso := falta.normalized() * v * delta
	var nuevo := global_position + paso
	var y := _suelo(nuevo)
	if is_nan(y):                                 # no hay suelo (barranco): otro destino
		_destino = casa
		return
	global_position = Vector3(nuevo.x, y, nuevo.z)
	look_at(global_position - falta, Vector3.UP)
	_salto += delta * (9.0 if huye else 6.0)
	_cuerpo.position.y = absf(sin(_salto)) * 0.18


func _suelo(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.0, 0), p + Vector3(0, -1.5, 0))
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	return r["position"].y if not r.is_empty() else NAN
