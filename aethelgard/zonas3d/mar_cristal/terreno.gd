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
var arrastre_raiz: Node3D                         # la arena arrastrada de gráficos (sigue a Kael)
var _viento_puesto := -1.0
var _modelos := 0                                 # cuántas piezas de gráficos se han puesto (lo miran las pruebas)
var espejismo_modelo := false

const RUTA_ARTE := "res://zonas3d/mar_cristal/materiales_arte.gd"
const COLORES_ARENA := {"color_arena": Vector3(0.80, 0.63, 0.44), "color_valle": Vector3(0.66, 0.49, 0.35),   # vec3 del sombreado
	"color_claro": Vector3(0.90, 0.79, 0.61), "color_sombra": Vector3(0.52, 0.48, 0.58)}
# Los nombres de terreno.gd frente a los de gráficos (docs/memory/agents/graficos_v12_desierto.md).
const ALIAS := {"tienda": "tienda_a", "palmera_1": "palmera_a", "palmera_2": "palmera_b", "ruinas_trampilla": "trampilla",
	"huesos_colosales": "huesos_costillas", "ruinas_columna": "ruinas_columna_a"}
# Alto de cada roca de gráficos (m), para escalarla al alto de cada roca del trazado.
const ALTO_ROCA := {"roca_canon_a": 9.0, "roca_canon_b": 7.0, "roca_canon_c": 3.0, "roca_canon_d": 6.0}


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


# La arena: el sombreado de gráficos (materiales_arte.gd, mat_arena: el mismo que los montones de las piezas, así se
# funden); sin él, un material con los colores por vértice.
func _material_arena() -> Material:
	if ResourceLoader.exists(RUTA_ARTE):
		var m = load(RUTA_ARTE).mat_arena(perfil)
		if m != null:
			# 11/11, 13:20: con la luz de la región, los colores de fábrica se veían naranja tostado. Arena dorada clara
			# (el mismo material sirve a los montones de las piezas: siguen fundiéndose con el suelo).
			for par in COLORES_ARENA:
				m.set_shader_parameter(par, COLORES_ARENA[par])
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
	var pend := T.altura(x + 0.8, z) - T.altura(x - 0.8, z) + 0.5 * (T.altura(x, z + 0.8) - T.altura(x, z - 0.8))
	if not mat_arena is StandardMaterial3D:
		# el sombreado de gráficos MULTIPLICA su color por el de vértice (ALBEDO = c · COLOR): aquí solo un matiz casi
		# blanco (11/11, 13:25: con los colores de arena de abajo, dos naranjas multiplicados daban arena de lava)
		var v := lerpf(0.94, 1.0, clampf(y / 3.0, 0.0, 1.0)) - clampf(-pend * 0.2, 0.0, 0.16)
		var t := Color(v, v, v)
		if T.en_camino(x, z):
			t = t * Color(0.93, 0.90, 0.86)                     # pisado y más pardo
		if T.en_temblor(x, z):
			t = t * Color(0.95, 0.94, 0.93)                     # la arena que tiembla, algo más oscura
		return t
	var c := ARENA.lerp(ARENA_CLARA, clampf(y / 3.0, 0.0, 1.0))
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
	for i in T.ROCAS.size():
		var r: Array = T.ROCAS[i]
		var c := Vector3(r[0], T.altura(r[0], r[1]), r[1])
		var m := _roca(c, r[2], r[3])                            # su choque se queda: es el de trazado.gd (prohibido)
		var alto: float = r[3]
		var id := "roca_canon_c" if alto < 4.0 else ("roca_canon_d" if alto < 6.0 else ("roca_canon_a" if i % 2 == 0 else "roca_canon_b"))
		var esc := clampf(alto / ALTO_ROCA[id], 0.5, 1.6)
		var giro := fposmod(r[0] * 1.7 + r[1] * 0.9, TAU)
		if poner_modelo(id, c + Vector3(0, -0.3, 0), esc, null, null, giro):
			m.visible = false
			_deformar(raiz.get_child(raiz.get_child_count() - 1), r[2], alto, i)
			if alto >= 4.0:                                     # un bloque caído a su pie, del lado del sol
				var pie := c + Vector3(cos(giro) * r[2] * 0.9, -0.2, sin(giro) * r[2] * 0.9)
				pie.y = T.altura(pie.x, pie.z) - 0.2
				if poner_modelo("roca_canon_c", pie, clampf(r[2] / 5.0, 0.45, 0.9), null, null, giro + 1.3):
					_deformar(raiz.get_child(raiz.get_child_count() - 1), r[2] * 0.4, 1.4, i + 7)
	_paredes_canon()


# Rompe la silueta de una roca de gráficos para que no parezca un cilindro: más ancha que alta si su radio lo pide,
# estirada en un sentido, y algo inclinada. Siempre igual para la misma roca (sin azar).
func _deformar(n: Node, radio: float, alto: float, semilla: int) -> void:
	if not n is Node3D:
		return
	var nd := n as Node3D
	var k := float(semilla)
	var ancho := clampf(radio / maxf(alto * 0.6, 1.0), 0.8, 1.2)        # 13:30: con 1,7 parecían tartas de pisos
	nd.scale = Vector3(nd.scale.x * ancho * (1.0 + 0.18 * sin(k * 1.9)), nd.scale.y * (1.2 + 0.15 * cos(k * 2.3)),
		nd.scale.z * ancho * (1.0 - 0.15 * sin(k * 1.9)))
	nd.rotation.x = deg_to_rad(4.0 * sin(k * 3.1))
	nd.rotation.z = deg_to_rad(4.0 * cos(k * 2.7))


# Las paredes del cañón del oeste: paños de pared de gráficos (roca_canon_b, 12 m de norte a sur) fuera de lo que se
# anda (x < 2), de z 16 a 84, con alturas que suben y bajan; solo con las piezas de gráficos.
func _paredes_canon() -> void:
	if _modelos == 0:
		return
	var z := 16.0
	var k := 0
	while z < 86.0:
		var alto := 1.0 + 0.25 * sin(k * 1.7)
		var p := Vector3(0.5 + 0.8 * sin(k * 2.1), 0.0, z)
		p.y = T.altura(p.x, p.z) - 0.4
		if poner_modelo("roca_canon_b", p, 1.0, null, null, deg_to_rad(5.0 * sin(k * 1.3))):
			var n: Node3D = raiz.get_child(raiz.get_child_count() - 1)
			n.scale = Vector3(1.2, alto, 1.0)
		z += 11.0
		k += 1


# La roca saliente del cobijo: un pilar al oeste y un techo de roca a 3,4 m; debajo se puede estar.
func _saliente() -> void:
	var s: Array = T.SALIENTE
	var base := Vector3(s[0] - 2.6, 0.0, s[1])
	var pilar := _roca(base, 1.6, s[3] + 0.6)
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
	# el modelo: su origen es el sitio del cobijo, la masa al oeste. Los choques de aquí se quedan (los de las pruebas)
	if poner_modelo("roca_cobijo", Vector3(T.COBIJO.x, T.altura(T.COBIJO.x, T.COBIJO.y), T.COBIJO.y), 1.0, null):
		pilar.visible = false
		techo.visible = false


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
	for k in T.TIENDAS.size():
		var t: Vector2 = T.TIENDAS[k]
		var c := _suelo(t)
		if poner_modelo("tienda_a" if k == 0 else "tienda_b", c, 1.0, null, null, 0.0, true):
			continue
		# una tienda de dos aguas: dos telas inclinadas y un poste
		var a := _tela(c + Vector3(-0.9, 1.0, 0), Vector2(2.2, 3.2), Color(0.86, 0.36, 0.22), 0.0)
		a.rotation = Vector3(0, PI / 2.0, deg_to_rad(52))
		var b := _tela(c + Vector3(0.9, 1.0, 0), Vector2(2.2, 3.2), Color(0.93, 0.78, 0.52), 0.0)
		b.rotation = Vector3(0, PI / 2.0, deg_to_rad(-52))
		_caja(c + Vector3(0, 0, 1.6), Vector3(0.12, 2.0, 0.12), Color(0.45, 0.30, 0.18), 0.0, true)
		_caja(c + Vector3(0, 0, -1.6), Vector3(0.12, 2.0, 0.12), Color(0.45, 0.30, 0.18), 0.0, true)
	var f := _suelo(T.FOGATA)
	if poner_modelo("fogata", f, 1.0, null):
		_fuego(f + Vector3(0, 0.25, 0))
	else:
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
	_caja(_suelo(T.CAMPAMENTO + Vector2(-7.5, 1.5)), Vector3(1.0, 0.7, 0.7), Color(0.55, 0.38, 0.22), 0.3, true)   # fardos, junto a la jaima (fuera del paso)
	_caja(_suelo(T.CAMPAMENTO + Vector2(-8.3, 0.4)), Vector3(0.8, 0.6, 0.6), Color(0.62, 0.45, 0.28), -0.2, true)


# Las llamas de la fogata de gráficos (el modelo deja el fuego a la región): pocas partículas que suben y se apagan.
func _fuego(p: Vector3) -> void:
	var fu := CPUParticles3D.new()
	fu.name = "Fuego"
	fu.amount = 18
	fu.lifetime = 0.7
	fu.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fu.emission_sphere_radius = 0.18
	fu.direction = Vector3.UP
	fu.spread = 12.0
	fu.gravity = Vector3(0, 1.2, 0)
	fu.initial_velocity_min = 0.4
	fu.initial_velocity_max = 0.9
	fu.scale_amount_min = 0.6
	fu.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.28, 0.36)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.55, 0.18, 0.85)
	q.material = m
	fu.mesh = q
	fu.position = p
	fu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(fu)


func _caravana() -> void:
	var c := _suelo(T.CARAVANA)
	if poner_modelo("caravana_carro", c, 1.0, null, null, 0.45, true):
		for pz in [["caravana_cajas", Vector2(-2.6, 1.8), 0.3], ["caravana_barril", Vector2(2.8, -1.4), 1.1],
				["caravana_tela", Vector2(-1.2, -2.6), -0.4]]:
			var p: Vector2 = T.CARAVANA + pz[1]
			poner_modelo(pz[0], _suelo(p), 1.0, null, null, pz[2], true)
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
		var modelo := "palmera_a" if i % 2 == 0 else "palmera_b"
		if poner_modelo(modelo, c, 0.85 + 0.1 * (i % 3), null, null, ang * 2.3):
			_tronco_choque(c)
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
		_tronco_choque(c)
	for i in 10:                                                 # juncos en la orilla (gráficos: 5 matas)
		var ang := TAU * i / 10.0
		var p := T.OASIS + Vector2(cos(ang), sin(ang)) * (T.RADIO_ESTANQUE + 0.6)
		if i % 2 == 0 and poner_modelo("juncos", _suelo(p), 1.0, null, null, ang):
			continue
		if _modelos > 0:
			continue
		var j := _tela(_suelo(p) + Vector3(0, 0.5, 0), Vector2(0.5, 1.1), Color(0.42, 0.58, 0.28), ang)
		j.name = "Junco%d" % i


func _tronco_choque(c: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.3
	cs.height = 3.0
	forma.shape = cs
	cuerpo.add_child(forma)
	cuerpo.position = c + Vector3(0, 1.5, 0)
	raiz.add_child(cuerpo)


func _ruinas() -> void:
	var c := _suelo(T.RUINAS)
	arco_ruinas = Node3D.new()
	arco_ruinas.name = "Arco"
	arco_ruinas.position = c
	raiz.add_child(arco_ruinas)
	if not poner_modelo("ruinas_arco", Vector3.ZERO, 1.0, null, arco_ruinas, 0.0, true):
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
	var columnas := [["ruinas_columna_a", Vector2(-8.0, 3.0), 0.2], ["ruinas_columna_b", Vector2(8.5, 2.0), -0.3],
		["ruinas_columna_c", Vector2(-6.0, -4.0), 0.5], ["ruinas_columna_d", Vector2(7.0, -5.0), 1.2],
		["ruinas_muro", Vector2(-9.5, -1.5), 1.45]]
	for col in columnas:
		var p: Vector2 = col[1]
		var sitio := _suelo(T.RUINAS + p)
		if not poner_modelo(col[0], sitio, 1.0, null, null, col[2], true) and col[0] != "ruinas_muro":
			_caja(c + Vector3(p.x, -0.6, p.y), Vector3(1.1, 2.4 + absf(p.x) * 0.1, 1.1), Color(0.84, 0.72, 0.56), p.y, true)
	trampilla = Node3D.new()
	trampilla.name = "Trampilla"
	trampilla.position = _suelo(T.TRAMPILLA)
	raiz.add_child(trampilla)
	if not poner_modelo("trampilla", Vector3.ZERO, 1.0, null, trampilla):
		var losa := MeshInstance3D.new()
		var bl := BoxMesh.new()
		bl.size = Vector3(2.0, 0.25, 2.0)
		losa.mesh = bl
		losa.material_override = _liso(Color(0.70, 0.62, 0.52))
		losa.position.y = 0.05
		trampilla.add_child(losa)


func _huesos() -> void:
	var c := Vector3(74.0, T.altura(74.0, 34.0), 34.0)
	if poner_modelo("huesos_costillas", c, 1.0, null, null, 0.0, true):
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
	if ResourceLoader.exists(RUTA_ARTE) and ResourceLoader.exists("res://modelos/desierto/palmera_a.glb"):
		var Arte = load(RUTA_ARTE)                              # la palmera de gráficos con el sombreado del espejismo
		var pm: Node3D = Arte.modelo("palmera_a", perfil, true)
		espejismo.add_child(pm)
		espejismo_modelo = true
		Arte.mat_espejismo().set_shader_parameter("espejismo", 1.0)
		cofre_espejismo = _caja(espejismo.position + Vector3(0.6, 0, 0.6), Vector3(0.9, 0.6, 0.6), Color(0.40, 0.70, 0.78), 0.4)
		cofre_espejismo.visible = false
		return
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
		# el GLB ya trae 2,4 m bajo la arena: antes de la tormenta asoma su clave (algo menos de 1 m); el sencillo, más
		var hundir := 3.0 if _modelos > 0 else 4.2
		arco_ruinas.position.y = T.altura(T.RUINAS.x, T.RUINAS.y) - (0.0 if reveladas else hundir)


# Al amainar la tormenta de la misión, el arco sale de la arena poco a poco (y su polvo).
func destapar_ruinas() -> void:
	if arco_ruinas == null:
		return
	var t := arco_ruinas.create_tween()
	t.tween_property(arco_ruinas, "position:y", T.altura(T.RUINAS.x, T.RUINAS.y), 2.5).set_trans(Tween.TRANS_SINE)


# El espejismo se apaga y deja ver el cofre de verdad (mision.gd): con la palmera de gráficos, su sombreado baja
# «espejismo» de 1 a 0 y la pieza se oculta; sin ella, el cuadro se oculta. Al abrirlo, la tapa se ladea.
func revelar_cofre() -> void:
	if espejismo != null and espejismo.get_child_count() > 0:
		var pieza := espejismo.get_child(0)
		if espejismo_modelo:
			var m: ShaderMaterial = load(RUTA_ARTE).mat_espejismo()
			var t := espejismo.create_tween()
			t.tween_method(func(v): m.set_shader_parameter("espejismo", v), 1.0, 0.0, 1.2)
			t.tween_callback(func(): pieza.visible = false)
		else:
			pieza.visible = false
	if cofre_espejismo != null:
		cofre_espejismo.visible = true


func abrir_cofre() -> void:
	revelar_cofre()
	if cofre_espejismo != null:
		cofre_espejismo.rotation.x = deg_to_rad(-12.0)


# La trampilla de las ruinas se abre con la Llave de vidrio: la tapa de gráficos gira en su bisagra (al norte); sin
# ella, la losa se aparta a un lado.
func abrir_trampilla() -> void:
	if trampilla == null:
		return
	var tapas := trampilla.find_children("trampilla_tapa*", "Node3D", true, false)
	var t := trampilla.create_tween()
	if not tapas.is_empty():
		t.tween_property(tapas[0], "rotation:x", -deg_to_rad(105.0), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		t.tween_property(trampilla, "position:x", trampilla.position.x + 1.8, 0.8).set_trans(Tween.TRANS_SINE)


# Lo que se mueve con el viento: las telas y las copas sencillas (rotaciones baratas) y, con gráficos, sus sombreados
# (telas, hojas, arena) y la arena arrastrada, que sigue a Kael. Los sombreados solo se tocan si el viento cambia.
func animar(t: float, viento: float, pos_kael := Vector3.INF) -> void:
	for i in telas.size():
		var n: MeshInstance3D = telas[i]
		if is_instance_valid(n):
			n.rotation.x = sin(t * (2.2 + viento * 3.0) + i * 0.7) * (0.05 + 0.18 * viento)
	for i in palmeras.size():
		var c: Node3D = palmeras[i]
		c.rotation.z = sin(t * (1.1 + viento * 2.0) + i) * (0.04 + 0.14 * viento)
	if espejismo != null and not espejismo_modelo and espejismo.get_child_count() > 0:
		espejismo.get_child(0).position.x = sin(t * 3.1) * 0.15
	if arrastre_raiz != null and pos_kael != Vector3.INF:
		arrastre_raiz.position = Vector3(pos_kael.x, T.altura(pos_kael.x, pos_kael.z), pos_kael.z)
	if _modelos > 0 and absf(viento - _viento_puesto) > 0.03:
		_viento_puesto = viento
		load(RUTA_ARTE).intensidad_viento(arrastre_raiz, viento)


# La arena arrastrada de gráficos (cintas y granos, por perfil) y, solo en el perfil alto, ondas de calor sobre las
# dunas abiertas. Lo llama la región al montar la escena.
func efectos_arte() -> void:
	if not ResourceLoader.exists(RUTA_ARTE):
		return
	var Arte = load(RUTA_ARTE)
	arrastre_raiz = Node3D.new()
	arrastre_raiz.name = "Arrastre"
	raiz.add_child(arrastre_raiz)
	arrastre_raiz.add_child(Arte.arena_arrastrada(perfil))
	for sitio in [Vector2(66.0, 60.0), Vector2(78.0, 32.0)]:
		var cal: MeshInstance3D = Arte.calor(perfil)
		if cal != null:
			cal.position = _suelo(sitio) + Vector3(0, 0.35, 0)
			raiz.add_child(cal)


# Al salir de la región: suelta la caché de materiales de gráficos.
func liberar() -> void:
	if ResourceLoader.exists(RUTA_ARTE):
		load(RUTA_ARTE).liberar()


# Un modelo de gráficos (modelos/desierto/<id>.glb, con su versión ligera en los perfiles medio y bajo y los materiales
# de materiales_arte.gd). «nombre» puede ser un alias (ALIAS). Devuelve si lo puso; sin él, la región monta su pieza
# sencilla. «padre»: dónde ponerlo (por defecto, la raíz); «giro»: en y; «chocar»: añade las cajas de choque del GLB.
func poner_modelo(nombre: String, pos: Vector3, escala: float, _provisional, padre: Node3D = null, giro := 0.0,
		chocar := false) -> bool:
	var id: String = ALIAS.get(nombre, nombre)
	if not ResourceLoader.exists("res://modelos/desierto/%s.glb" % id) or not ResourceLoader.exists(RUTA_ARTE):
		return false
	var n: Node3D = load(RUTA_ARTE).modelo(id, perfil)
	n.position = pos
	n.rotation.y = giro
	n.scale = Vector3.ONE * escala
	var donde: Node3D = padre if padre != null else raiz
	donde.add_child(n)
	if chocar:
		var cuerpo: StaticBody3D = load(RUTA_ARTE).choques(n)
		if cuerpo.get_child_count() > 0:
			donde.add_child(cuerpo)
		else:
			cuerpo.free()
	_modelos += 1
	return true
