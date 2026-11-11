extends RefCounted
# El escenario del primer sector del Mar de Cristal (V12): la arena con sus dunas (una malla con colores por vértice y
# su choque), el estanque del oasis, las rocas del cañón, la roca saliente del cobijo y los sitios (campamento, restos de
# la caravana, ruinas, huesos, esqueleto, espejismo). Mientras no estén los modelos de gráficos
# (modelos/desierto/*.glb, rama claude/v12-desierto-arte), cada sitio se monta con piezas sencillas; cuando estén, se
# usan los suyos (poner_modelo). Nada de esto lleva azar: siempre sale igual.

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const PASO := 1.5                                # metros entre vértices de la arena
const ARENA_CLARA := Color(0.98, 0.84, 0.60)
const ARENA := Color(0.90, 0.71, 0.47)
const ARENA_SOMBRA := Color(0.74, 0.52, 0.36)
const ARENA_CAMINO := Color(0.80, 0.64, 0.46)
const ROCA := Color(0.62, 0.43, 0.33)
const ROCA_CLARA := Color(0.78, 0.58, 0.44)

var region: Node3D
var perfil: Dictionary
var raiz: Node3D
var mat_arena: Material
var mat_roca: StandardMaterial3D
var mats := {}
var arco_ruinas: Node3D                           # el arco: medio enterrado hasta la tormenta (revelar_ruinas)
var trampilla: Node3D
var espejismo: Node3D
var cofre_espejismo: Node3D
var telas: Array = []                             # lo que se mueve con el viento (tiendas, tela rota, juncos)
var palmeras: Array = []


func _init(r: Node3D, p: Dictionary) -> void:
	region = r
	perfil = p


func construir() -> void:
	raiz = Node3D.new()
	raiz.name = "MarCristal"
	region.add_child(raiz)
	mat_arena = _material_arena()
	mat_roca = _liso(ROCA, 0.95)
	_arena()
	_estanque()
	_rocas()
	_saliente()
	_campamento()
	_caravana()
	_oasis()
	_ruinas()
	_huesos()
	_esqueleto()
	_espejismo()


# ---------------------------------------------------------------- materiales

func _liso(c: Color, rugosidad := 0.9) -> StandardMaterial3D:
	var k := c.to_html()
	if mats.has(k):
		return mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	mats[k] = m
	return m


# La arena: el shader de gráficos si ya está (materiales_arte.gd), si no un material con los colores por vértice.
func _material_arena() -> Material:
	var ruta := "res://zonas3d/mar_cristal/materiales_arte.gd"
	if ResourceLoader.exists(ruta):
		var a = load(ruta)
		if a.has_method("material_arena"):
			var m = a.material_arena(perfil)
			if m != null:
				return m
	var s := StandardMaterial3D.new()
	s.vertex_color_use_as_albedo = true
	s.roughness = 1.0
	return s


# ---------------------------------------------------------------- arena

func _arena() -> void:
	var nx := int(T.TAM.x / PASO) + 1
	var nz := int(T.TAM.y / PASO) + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz - 1:
		for ix in nx - 1:
			var esquinas := [Vector2(ix, iz), Vector2(ix + 1, iz), Vector2(ix + 1, iz + 1), Vector2(ix, iz + 1)]
			var v: Array = esquinas.map(func(e): return _vertice(e.x * PASO, e.y * PASO))
			for tri in [[0, 1, 2], [0, 2, 3]]:
				for k in tri:
					st.set_color(_color_arena(v[k].x, v[k].z, v[k].y))
					st.add_vertex(v[k])
	st.generate_normals()
	var malla := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Arena"
	mi.mesh = malla
	mi.material_override = mat_arena
	raiz.add_child(mi)
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = malla.create_trimesh_shape()
	cuerpo.add_child(forma)
	raiz.add_child(cuerpo)


func _vertice(x: float, z: float) -> Vector3:
	return Vector3(x, T.altura(x, z), z)


# Más clara en las crestas y la cara al sol (sureste), más oscura en los senos; el camino, pisado y más pardo.
func _color_arena(x: float, z: float, y: float) -> Color:
	var c := ARENA.lerp(ARENA_CLARA, clampf(y / 3.0, 0.0, 1.0))
	var pend := T.altura(x + 0.8, z) - T.altura(x - 0.8, z) + 0.5 * (T.altura(x, z + 0.8) - T.altura(x, z - 0.8))
	c = c.lerp(ARENA_SOMBRA, clampf(-pend * 0.45, 0.0, 0.55))
	if T.en_camino(x, z):
		c = c.lerp(ARENA_CAMINO, 0.55)
	if T.en_temblor(x, z):
		c = c.darkened(0.06)                                    # la arena que tiembla, algo más oscura y suelta
	return c


func _estanque() -> void:
	var agua := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = T.RADIO_ESTANQUE + 0.6
	disco.bottom_radius = T.RADIO_ESTANQUE + 0.6
	disco.height = 0.05
	disco.radial_segments = 32
	agua.mesh = disco
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.20, 0.62, 0.66, 0.82)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.08
	m.metallic_specular = 0.9
	agua.material_override = m
	agua.position = Vector3(T.OASIS.x, -0.62, T.OASIS.y)
	agua.name = "Estanque"
	raiz.add_child(agua)


# ---------------------------------------------------------------- rocas y cobijo

func _roca(c: Vector3, radio: float, alto: float, chocar := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = radio * 0.62
	cil.bottom_radius = radio
	cil.height = alto
	cil.radial_segments = 7
	cil.rings = 2
	mi.mesh = cil
	mi.material_override = mat_roca
	mi.position = c + Vector3(0, alto * 0.5 - 0.3, 0)
	mi.rotation.y = fposmod(c.x * 1.7 + c.z * 0.9, TAU)
	raiz.add_child(mi)
	if chocar:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = radio * 0.85
		cs.height = alto
		forma.shape = cs
		cuerpo.add_child(forma)
		cuerpo.position = mi.position
		raiz.add_child(cuerpo)
	return mi


func _rocas() -> void:
	for r in T.ROCAS:
		var c := Vector3(r[0], T.altura(r[0], r[1]), r[1])
		var m := _roca(c, r[2], r[3])
		if poner_modelo("roca_canon_%d" % (int(r[0] + r[1]) % 3 + 1), c, float(r[2]) / 4.0, m):
			m.visible = false


# La roca saliente del cobijo: un pilar al oeste y un techo de roca a 3,4 m; debajo se puede estar.
func _saliente() -> void:
	var s: Array = T.SALIENTE
	var base := Vector3(s[0] - 2.6, 0.0, s[1])
	_roca(base, 1.6, s[3] + 0.6)
	var techo := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(s[2] * 1.9, 0.9, s[2] * 1.6)
	techo.mesh = caja
	techo.material_override = _liso(ROCA_CLARA, 0.95)
	techo.position = Vector3(s[0], s[3] + 0.45, s[1])
	techo.rotation.z = deg_to_rad(-6.0)
	raiz.add_child(techo)
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = caja.size
	forma.shape = bs
	cuerpo.add_child(forma)
	cuerpo.position = techo.position
	raiz.add_child(cuerpo)
	poner_modelo("roca_cobijo", Vector3(s[0], 0.0, s[1]), 1.0, null)


# ---------------------------------------------------------------- sitios

func _caja(pos: Vector3, tam: Vector3, c: Color, rot := 0.0, chocar := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = _liso(c)
	mi.position = pos + Vector3(0, tam.y * 0.5, 0)
	mi.rotation.y = rot
	raiz.add_child(mi)
	if chocar:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = tam
		forma.shape = bs
		cuerpo.add_child(forma)
		cuerpo.position = mi.position
		cuerpo.rotation.y = rot
		raiz.add_child(cuerpo)
	return mi


func _suelo(p: Vector2) -> Vector3:
	return Vector3(p.x, T.altura(p.x, p.y), p.y)


func _tela(pos: Vector3, tam: Vector2, c: Color, rot := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = tam
	q.subdivide_width = 4
	q.subdivide_depth = 2
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = rot
	raiz.add_child(mi)
	telas.append(mi)
	return mi


func _campamento() -> void:
	for t in T.TIENDAS:
		var c := _suelo(t)
		if poner_modelo("tienda", c, 1.0, null):
			continue
		# una tienda de dos aguas: dos telas inclinadas y un poste
		var a := _tela(c + Vector3(-0.9, 1.0, 0), Vector2(2.2, 3.2), Color(0.86, 0.36, 0.22), 0.0)
		a.rotation = Vector3(0, PI / 2.0, deg_to_rad(52))
		var b := _tela(c + Vector3(0.9, 1.0, 0), Vector2(2.2, 3.2), Color(0.93, 0.78, 0.52), 0.0)
		b.rotation = Vector3(0, PI / 2.0, deg_to_rad(-52))
		_caja(c + Vector3(0, 0, 1.6), Vector3(0.12, 2.0, 0.12), Color(0.45, 0.30, 0.18), 0.0, true)
		_caja(c + Vector3(0, 0, -1.6), Vector3(0.12, 2.0, 0.12), Color(0.45, 0.30, 0.18), 0.0, true)
	var f := _suelo(T.FOGATA)
	if not poner_modelo("fogata", f, 1.0, null):
		for i in 7:
			var ang := TAU * i / 7.0
			_caja(f + Vector3(cos(ang) * 0.55, 0, sin(ang) * 0.55), Vector3(0.28, 0.2, 0.28), Color(0.45, 0.42, 0.40))
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.6, 0.3)
	luz.light_energy = 1.6
	luz.omni_range = 7.0
	luz.position = f + Vector3(0, 0.8, 0)
	luz.name = "LuzFogata"
	raiz.add_child(luz)
	_caja(_suelo(T.CAMPAMENTO + Vector2(4.0, 3.0)), Vector3(1.0, 0.7, 0.7), Color(0.55, 0.38, 0.22), 0.3, true)   # fardos
	_caja(_suelo(T.CAMPAMENTO + Vector2(5.0, 2.0)), Vector3(0.8, 0.6, 0.6), Color(0.62, 0.45, 0.28), -0.2, true)


func _caravana() -> void:
	var c := _suelo(T.CARAVANA)
	if poner_modelo("caravana_restos", c, 1.0, null):
		return
	_caja(c + Vector3(0, -0.35, 0), Vector3(2.4, 1.0, 4.0), Color(0.48, 0.32, 0.20), 0.45, true)       # el carro volcado
	for p in [Vector3(-2.2, 0, 1.6), Vector3(1.9, 0, -2.0), Vector3(2.8, 0, 1.0)]:
		_caja(c + p - Vector3(0, 0.25, 0), Vector3(0.8, 0.8, 0.8), Color(0.62, 0.46, 0.28), p.x, true)    # cajas medio enterradas
	var t := _tela(c + Vector3(-1.0, 1.0, -1.6), Vector2(1.8, 1.2), Color(0.70, 0.28, 0.22), 0.6)
	t.rotation.x = deg_to_rad(-20)


func _oasis() -> void:
	for i in 7:
		var ang := TAU * i / 7.0 + 0.3
		var p := T.OASIS + Vector2(cos(ang), sin(ang)) * (T.RADIO_ESTANQUE + 2.2 + 0.6 * (i % 2))
		var c := _suelo(p)
		var modelo := "palmera_%d" % (i % 2 + 1)
		if poner_modelo(modelo, c, 1.0 + 0.12 * (i % 3), null):
			continue
		var tronco := _caja(c, Vector3(0.35, 4.6 + 0.6 * (i % 3), 0.35), Color(0.52, 0.38, 0.24), ang, false)
		tronco.rotation.z = deg_to_rad(6.0 * (1 if i % 2 == 0 else -1))
		var copa := Node3D.new()
		copa.position = c + Vector3(0, 4.8 + 0.6 * (i % 3), 0)
		raiz.add_child(copa)
		for h in 6:
			var hoja := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.7, 2.6)
			hoja.mesh = q
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.30, 0.56, 0.24)
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			hoja.material_override = m
			hoja.rotation = Vector3(deg_to_rad(-62), TAU * h / 6.0, 0)
			hoja.position = Vector3(cos(TAU * h / 6.0), -0.3, -sin(TAU * h / 6.0)) * 1.0
			copa.add_child(hoja)
		palmeras.append(copa)
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = 0.3
		cs.height = 3.0
		forma.shape = cs
		cuerpo.add_child(forma)
		cuerpo.position = c + Vector3(0, 1.5, 0)
		raiz.add_child(cuerpo)
	for i in 10:                                                 # juncos en la orilla
		var ang := TAU * i / 10.0
		var p := T.OASIS + Vector2(cos(ang), sin(ang)) * (T.RADIO_ESTANQUE + 0.6)
		var j := _tela(_suelo(p) + Vector3(0, 0.5, 0), Vector2(0.5, 1.1), Color(0.42, 0.58, 0.28), ang)
		j.name = "Junco%d" % i


func _ruinas() -> void:
	var c := _suelo(T.RUINAS)
	arco_ruinas = Node3D.new()
	arco_ruinas.name = "Arco"
	arco_ruinas.position = c
	raiz.add_child(arco_ruinas)
	if not poner_modelo("ruinas_arco", Vector3.ZERO, 1.0, null, arco_ruinas):
		var piedra := _liso(Color(0.86, 0.74, 0.58), 0.9)
		for x in [-3.0, 3.0]:
			var col := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(1.4, 6.0, 1.4)
			col.mesh = b
			col.material_override = piedra
			col.position = Vector3(x, 3.0, 0)
			arco_ruinas.add_child(col)
		var din := MeshInstance3D.new()
		var bd := BoxMesh.new()
		bd.size = Vector3(8.0, 1.2, 1.6)
		din.mesh = bd
		din.material_override = piedra
		din.position = Vector3(0, 6.5, 0)
		arco_ruinas.add_child(din)
		var vidrio := MeshInstance3D.new()                       # el ojo de vidrio en la clave del arco
		var s := SphereMesh.new()
		s.radius = 0.45
		s.height = 0.9
		vidrio.mesh = s
		var mv := StandardMaterial3D.new()
		mv.albedo_color = Color(0.55, 0.92, 0.98, 0.85)
		mv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mv.emission_enabled = true
		mv.emission = Color(0.35, 0.8, 0.9)
		mv.emission_energy_multiplier = 0.6
		vidrio.material_override = mv
		vidrio.position = Vector3(0, 6.5, 0.85)
		arco_ruinas.add_child(vidrio)
	for p in [Vector2(-8.0, 3.0), Vector2(8.5, 2.0), Vector2(-6.0, -4.0), Vector2(7.0, -5.0)]:   # columnas caídas
		if not poner_modelo("ruinas_columna", c + Vector3(p.x, -0.5, p.y), 1.0, null):
			_caja(c + Vector3(p.x, -0.6, p.y), Vector3(1.1, 2.4 + absf(p.x) * 0.1, 1.1), Color(0.84, 0.72, 0.56), p.y, true)
	trampilla = Node3D.new()
	trampilla.name = "Trampilla"
	trampilla.position = _suelo(T.TRAMPILLA)
	raiz.add_child(trampilla)
	if not poner_modelo("ruinas_trampilla", Vector3.ZERO, 1.0, null, trampilla):
		var losa := MeshInstance3D.new()
		var bl := BoxMesh.new()
		bl.size = Vector3(2.0, 0.25, 2.0)
		losa.mesh = bl
		losa.material_override = _liso(Color(0.70, 0.62, 0.52))
		losa.position.y = 0.05
		trampilla.add_child(losa)


func _huesos() -> void:
	var c := Vector3(74.0, T.altura(74.0, 34.0), 34.0)
	if poner_modelo("huesos_colosales", c, 1.0, null):
		return
	for i in 6:                                                 # costillas: arcos de hueso que salen de la arena
		var cost := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 2.6 + i * 0.15
		t.outer_radius = 3.0 + i * 0.15
		cost.mesh = t
		cost.material_override = _liso(Color(0.93, 0.89, 0.80))
		cost.position = c + Vector3(i * 1.4 - 3.5, -0.6, 0)
		cost.rotation = Vector3(0, PI / 2.0, PI / 2.0)
		raiz.add_child(cost)


func _esqueleto() -> void:
	var c := _suelo(T.ESQUELETO)
	if not poner_modelo("esqueleto", c, 1.0, null):
		_caja(c, Vector3(0.6, 0.5, 1.4), Color(0.92, 0.88, 0.80), 0.4)


func _espejismo() -> void:
	espejismo = Node3D.new()
	espejismo.name = "Espejismo"
	espejismo.position = _suelo(T.ESPEJISMO)
	raiz.add_child(espejismo)
	var p := MeshInstance3D.new()                               # una palmera que tiembla y no está
	var q := QuadMesh.new()
	q.size = Vector2(3.0, 5.0)
	p.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.85, 0.70, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	p.material_override = m
	p.position.y = 2.6
	espejismo.add_child(p)
	cofre_espejismo = _caja(espejismo.position + Vector3(0.6, 0, 0.6), Vector3(0.9, 0.6, 0.6), Color(0.40, 0.70, 0.78), 0.4)
	cofre_espejismo.visible = false


# ---------------------------------------------------------------- lo que cambia

# Antes de la tormenta, el arco de las ruinas está casi enterrado; después, se ve entero (misión, paso 5).
func poner_ruinas(reveladas: bool) -> void:
	if arco_ruinas != null:
		arco_ruinas.position.y = T.altura(T.RUINAS.x, T.RUINAS.y) - (0.0 if reveladas else 4.2)


# Al amainar la tormenta de la misión, el arco sale de la arena poco a poco (y su polvo).
func destapar_ruinas() -> void:
	if arco_ruinas == null:
		return
	var t := arco_ruinas.create_tween()
	t.tween_property(arco_ruinas, "position:y", T.altura(T.RUINAS.x, T.RUINAS.y), 2.5).set_trans(Tween.TRANS_SINE)


# El espejismo se apaga y deja ver el cofre de verdad (mision.gd); al abrirlo, la tapa se ladea.
func revelar_cofre() -> void:
	if espejismo != null:
		espejismo.get_child(0).visible = false
	if cofre_espejismo != null:
		cofre_espejismo.visible = true


func abrir_cofre() -> void:
	revelar_cofre()
	if cofre_espejismo != null:
		cofre_espejismo.rotation.x = deg_to_rad(-12.0)


# La trampilla de las ruinas se abre al usar la Llave de vidrio: la losa se aparta a un lado.
func abrir_trampilla() -> void:
	if trampilla == null:
		return
	var t := trampilla.create_tween()
	t.tween_property(trampilla, "position:x", trampilla.position.x + 1.8, 0.8).set_trans(Tween.TRANS_SINE)


# Lo que se mueve con el viento: las telas y las copas, más con la tormenta. Barato: unas pocas rotaciones.
func animar(t: float, viento: float) -> void:
	for i in telas.size():
		var n: MeshInstance3D = telas[i]
		if is_instance_valid(n):
			n.rotation.x = sin(t * (2.2 + viento * 3.0) + i * 0.7) * (0.05 + 0.18 * viento)
	for i in palmeras.size():
		var c: Node3D = palmeras[i]
		c.rotation.z = sin(t * (1.1 + viento * 2.0) + i) * (0.04 + 0.14 * viento)
	if espejismo != null:
		espejismo.get_child(0).position.x = sin(t * 3.1) * 0.15


# Un modelo de gráficos si ya existe (modelos/desierto/<nombre>.glb, o su versión _ligero en los perfiles bajos). Devuelve
# si lo puso; sin él, la región monta su pieza sencilla. «padre»: dónde ponerlo (por defecto, la raíz).
func poner_modelo(nombre: String, pos: Vector3, escala: float, _provisional, padre: Node3D = null) -> bool:
	var ruta := "res://modelos/desierto/%s.glb" % nombre
	var ligera := "res://modelos/desierto/%s_ligero.glb" % nombre
	if perfil.get("ligeros", false) and ResourceLoader.exists(ligera):
		ruta = ligera
	if not ResourceLoader.exists(ruta):
		return false
	var escena: PackedScene = load(ruta)
	var n: Node3D = escena.instantiate()
	n.position = pos
	n.scale = Vector3.ONE * escala
	(padre if padre != null else raiz).add_child(n)
	return true
