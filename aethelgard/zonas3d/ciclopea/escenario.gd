extends RefCounted
# Lo que se ve en las Cumbres de Ciclópea 3D, primer sector (V12, especialista de mundo, 13/11): una subida de montaña
# fría con identidad propia (ni el prado de Pastos ni el bosque cerrado del Gran Bosque): nieve azulada con su relieve,
# paredes de roca que crecen hacia las cumbres, cumbres nevadas al fondo, pinos nevados y abetos achaparrados, rocas con
# su capa de nieve, lagos y un arroyo helados con su puente, las ruinas con la estatua sin brazo que mira al pico, el
# campamento con su brasero, el altar con el orbe azul y la nevada que acompaña a Kael. Luz fría de cumbre (la región).
# Rendimiento (lo aprendido en las otras regiones): ningún recortado (alpha scissor) ni transparencia en lo grande; pinos y
# rocas en MultiMesh por trozos de 25 m con su distancia por perfil; lo pequeño junto en lotes; el suelo y el hielo, con
# render_priority 2 (se dibujan después de lo que los tapa); sombras solo de pinos, rocas y piezas en medio y alto.

const T := preload("res://zonas3d/ciclopea/trazado.gd")
const D := preload("res://zonas3d/ciclopea/disposicion_2d.gd")

const TROZO := 25.0
const ORIGEN_TROZOS := Vector2(-62.5, -50.0)
# [pinos, rocas, cumbres] distancia de dibujo por perfil (m)
const DISTANCIAS := {"bajo": [46.0, 32.0, 400.0], "medio": [56.0, 40.0, 400.0], "alto": [90.0, 60.0, 400.0]}
const PINOS_EXTRA := {"bajo": 70, "medio": 110, "alto": 170}     # abetos en las laderas, fuera del paso
const COPOS := {"bajo": 50, "medio": 80, "alto": 130}

var r: Node3D
var perfil: Dictionary
var nombre_perfil := "medio"
var grano: Texture2D
var relieve: Texture2D
var obstaculos := {}
var _lotes := {}
var _mm := {}
var cofres := {}
var estatua: Node3D
var orbe: Node3D
var copos: CPUParticles3D
var fuego_pos := Vector3.ZERO
var luces: Array = []
var _flotan: Array = []
var _rng := RandomNumberGenerator.new()
var _mat_vertices: StandardMaterial3D           # pinos, rocas y cumbres: color por vértice, sin textura
var _mat_piedra: StandardMaterial3D
var _mat_madera: StandardMaterial3D
var _brillo_tex: GradientTexture2D
var tiempos := {}


func _init(region: Node3D, p: Dictionary, nombre: String) -> void:
	r = region
	perfil = p
	nombre_perfil = nombre if DISTANCIAS.has(nombre) else "medio"


func _dist(i: int) -> float:
	return float(DISTANCIAS[nombre_perfil][i])


func construir() -> void:
	_rng.seed = D.SEMILLA
	for parte in [_texturas, _materiales, T.preparar_alturas, _crear_terreno, _crear_hielo, _crear_puente, _pinos, _rocas,
			_crear_ruinas, _crear_estatua, _crear_campamento, _crear_altar, _cumbres, _cerrar_multimesh, _cerrar_lotes,
			_nevada]:
		var u := Time.get_ticks_usec()
		parte.call()
		tiempos[parte.get_method()] = (Time.get_ticks_usec() - u) / 1000.0


# ================================================================= texturas y materiales

func _texturas() -> void:
	var ruido := FastNoiseLite.new()
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido.frequency = 0.05
	ruido.fractal_octaves = 4
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.noise = ruido
	var rampa := Gradient.new()
	rampa.colors = PackedColorArray([Color(0.86, 0.88, 0.92), Color(1.04, 1.04, 1.05)])
	nt.color_ramp = rampa
	nt.generate_mipmaps = true
	grano = nt
	var nn := NoiseTexture2D.new()
	nn.width = 256
	nn.height = 256
	nn.seamless = true
	nn.noise = ruido
	nn.as_normal_map = true
	nn.bump_strength = 4.0
	nn.generate_mipmaps = true
	relieve = nn


func mat_detalle(color := Color.WHITE, escala := 0.5, por_vertice := false, rel := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = grano
	m.vertex_color_use_as_albedo = por_vertice
	m.normal_enabled = perfil.get("relieve", true)
	m.normal_texture = relieve
	m.normal_scale = rel
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * escala
	m.roughness = 0.9
	return m


func _materiales() -> void:
	_mat_vertices = StandardMaterial3D.new()
	_mat_vertices.vertex_color_use_as_albedo = true
	_mat_vertices.vertex_color_is_srgb = true            # los colores están escritos en sRGB (como se ven)
	_mat_vertices.roughness = 0.88
	_mat_piedra = mat_detalle(Color(0.62, 0.64, 0.68), 0.9, false, 1.0)
	_mat_madera = mat_detalle(Color(0.42, 0.30, 0.20), 1.4, false, 0.8)


# ================================================================= lotes, multimesh y obstáculos

func _al_lote(malla: Mesh, t: Transform3D, mat: Material) -> void:
	if not _lotes.has(mat):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_lotes[mat] = st
	_lotes[mat].append_from(malla, 0, t)


func _cerrar_lotes() -> void:
	for mat in _lotes:
		var mi := MeshInstance3D.new()
		mi.mesh = _lotes[mat].commit()
		mi.material_override = mat
		mi.name = "Lote"
		r.add_child(mi)
	_lotes.clear()


func _poner(tipo: String, malla: Mesh, mat: Material, t: Transform3D, color: Color, sombra: int, dist: float) -> void:
	var tr := Vector2i(floori((t.origin.x - ORIGEN_TROZOS.x) / TROZO), floori((t.origin.z - ORIGEN_TROZOS.y) / TROZO))
	var clave := "%d,%d|%s" % [tr.x, tr.y, tipo]
	if not _mm.has(clave):
		_mm[clave] = {"malla": malla, "mat": mat, "t": [], "c": [], "sombra": sombra, "dist": dist, "trozo": tr, "tipo": tipo}
	_mm[clave]["t"].append(t)
	_mm[clave]["c"].append(color)


func _cerrar_multimesh() -> void:
	for clave in _mm:
		var d: Dictionary = _mm[clave]
		var tr: Vector2i = d["trozo"]
		var centro := Vector3(ORIGEN_TROZOS.x + (tr.x + 0.5) * TROZO, 0.0, ORIGEN_TROZOS.y + (tr.y + 0.5) * TROZO)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = d["malla"]
		mm.instance_count = d["t"].size()
		for k in d["t"].size():
			var t: Transform3D = d["t"][k]
			t.origin -= centro
			mm.set_instance_transform(k, t)
			mm.set_instance_color(k, d["c"][k])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "MM_" + str(d["tipo"])
		mmi.multimesh = mm
		mmi.position = centro
		mmi.material_override = d["mat"]
		mmi.cast_shadow = d["sombra"]
		mmi.visibility_range_end = d["dist"]
		r.add_child(mmi)
	_mm.clear()


func obstaculo(x: float, z: float, radio: float) -> void:
	var c := Vector2i(floori(x / 2.0), floori(z / 2.0))
	if not obstaculos.has(c):
		obstaculos[c] = []
	obstaculos[c].append(Vector3(x, z, radio))


func bloqueado(x: float, z: float) -> bool:
	var c := Vector2i(floori(x / 2.0), floori(z / 2.0))
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var lista = obstaculos.get(Vector2i(c.x + dx, c.y + dz))
			if lista == null:
				continue
			for o in lista:
				var q: Vector3 = o
				if Vector2(x - q.x, z - q.y).length() < q.z + 0.22:
					return true
	return false


func _sombra() -> int:
	return GeometryInstance3D.SHADOW_CASTING_SETTING_ON if perfil.get("sombras", false) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ================================================================= el suelo: nieve, nieve pisada y roca

func _crear_terreno() -> void:
	var ruido := FastNoiseLite.new()
	ruido.seed = 41
	ruido.frequency = 0.12
	var ruido2 := FastNoiseLite.new()
	ruido2.seed = 97
	ruido2.frequency = 0.035
	var nx := T.REJILLA_N.x
	var nz := T.REJILLA_N.y
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in nz:
		for i in nx:
			var x := T.REJILLA_MIN.x + i * T.REJILLA_PASO
			var z := T.REJILLA_MIN.y + j * T.REJILLA_PASO
			var y := T.altura_rejilla(i, j)
			var dx := T.altura_rejilla(i + 1, j) - T.altura_rejilla(i - 1, j)
			var dz := T.altura_rejilla(i, j + 1) - T.altura_rejilla(i, j - 1)
			var pendiente := clampf(sqrt(dx * dx + dz * dz) / (2.0 * T.REJILLA_PASO), 0.0, 2.0)
			var c := T.casilla(x, z)
			var n1 := ruido.get_noise_2d(x, z) * 0.5 + 0.5
			var n2 := ruido2.get_noise_2d(x, z) * 0.5 + 0.5
			# nieve: blanco azulado con sombras frías a manchas (zona.gd, «nieve»)
			var col := Color(0.72, 0.79, 0.90).lerp(Color(0.88, 0.92, 0.98), smoothstep(0.35, 0.8, n1))
			col = col.lerp(Color(0.64, 0.72, 0.87), smoothstep(0.6, 0.9, n2) * 0.5)
			var dc := T.dist_rejilla(i, j)
			if dc < 1.3 or T.en_camino_2d(c):             # nieve pisada del camino, con el borde roto y huellas
				var k := 1.0 - smoothstep(0.75, 1.3, dc + (n1 - 0.5) * 0.45)
				col = col.lerp(Color(0.44, 0.44, 0.50).lerp(Color(0.42, 0.36, 0.32), n2 * 0.7), k * 0.9)
			if c.distance_to(T.lugar("ruinas")) < 4.5:
				col = col.lerp(Color(0.70, 0.72, 0.76), (1.0 - smoothstep(2.5, 4.5, c.distance_to(T.lugar("ruinas")))) * 0.4)
			var w := T.agua(c)
			if w > 0.12:                                   # la orilla helada, algo más azul
				col = col.lerp(Color(0.66, 0.78, 0.90), smoothstep(0.12, 0.4, w))
			# roca donde la pendiente no sujeta la nieve (las paredes del borde y las cumbres)
			col = col.lerp(Color(0.40, 0.42, 0.48).lerp(Color(0.52, 0.53, 0.58), n1), smoothstep(0.55, 1.0, pendiente))
			st.set_color(col)
			st.set_uv(Vector2(x, z) * 0.25)
			st.add_vertex(Vector3(x, y, z))
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			st.add_index(a); st.add_index(a + 1); st.add_index(a + nx)
			st.add_index(a + 1); st.add_index(a + nx + 1); st.add_index(a + nx)
	st.generate_normals()
	var plano: bool = nombre_perfil != "alto"
	if plano and perfil.get("relieve", true):
		st.generate_tangents()
	var malla := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Suelo"
	mi.mesh = malla
	var ms := mat_detalle(Color.WHITE, 0.4, true, 0.45)
	ms.roughness = 0.82
	ms.vertex_color_is_srgb = true
	if plano:                                          # bajo y medio: una lectura por textura en vez de tres
		ms.uv1_triplanar = false
		ms.uv1_world_triplanar = false
		ms.uv1_scale = Vector3.ONE * (0.4 / 0.25)
	ms.render_priority = 2                             # después de lo que lo tapa (pinos, rocas, piezas)
	mi.material_override = ms
	if nombre_perfil != "alto":
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "SueloChoque"
	r.add_child(cuerpo)
	cuerpo.add_child(mi)
	var col := CollisionShape3D.new()
	col.shape = malla.create_trimesh_shape()
	cuerpo.add_child(col)


# ================================================================= hielo (los lagos y el arroyo de la 2D)

func _crear_hielo() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var paso := 0.5
	var hay := false
	for cy in range(0, D.ALTO * 2):
		for cx in range(0, D.ANCHO * 2):
			var c := Vector2(cx, cy) * paso
			var centro := c + Vector2(paso, paso) * 0.5
			if T.agua(centro) < 0.36:
				continue
			hay = true
			var esquinas := [c, c + Vector2(paso, 0), c + Vector2(0, paso), c + Vector2(paso, paso)]
			for idx in [0, 1, 2, 2, 1, 3]:
				var q: Vector2 = esquinas[idx]
				var p := T.mundo(q)
				var y := T.altura_camino(q.y) + T.HIELO_Y        # por vértice: sin escalones
				var brillo := 0.5 + 0.5 * sin(q.x * 1.3 + q.y * 0.7)
				st.set_color(Color(0.42, 0.60, 0.76).lerp(Color(0.62, 0.78, 0.90), brillo * 0.7))
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(p.x, y, p.z))
	if not hay:
		return
	var mi := MeshInstance3D.new()
	mi.name = "Hielo"
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.12
	m.metallic = 0.15
	m.metallic_specular = 0.8
	m.render_priority = 2
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(mi)


# ================================================================= el puente sobre el arroyo helado

func _crear_puente() -> void:
	for pu in D.PUENTES:
		var dir := Vector3(pu[1].x, 0, pu[1].y).normalized()
		var centro := T.mundo(pu[0])
		var largo: float = (pu[2] + 2.0 * T.PUENTE_EXTRA) * T.K
		var y := T.altura_camino(pu[0].y) + 0.12
		var giro := atan2(dir.x, dir.z)
		var bas := Basis(Vector3.UP, giro)
		var tabla := BoxMesh.new()
		tabla.size = Vector3(2.2, 0.08, 0.32)
		var n := int(largo / 0.36)
		for k in n:
			var off := (k - (n - 1) * 0.5) * 0.36
			var ti := Transform3D(bas.rotated(Vector3.UP, _rng.randf_range(-0.03, 0.03)), centro + dir * off + Vector3(0, y, 0))
			_al_lote(tabla, ti, _mat_madera)
		for lado in [-1.0, 1.0]:                        # barandas con nieve encima
			var lat: Vector3 = Vector3(dir.z, 0, -dir.x) * lado * 1.15
			var bar := BoxMesh.new()
			bar.size = Vector3(0.1, 0.1, largo)
			_al_lote(bar, Transform3D(bas, centro + lat + Vector3(0, y + 0.85, 0)), _mat_madera)
			var nieve := BoxMesh.new()
			nieve.size = Vector3(0.14, 0.05, largo * 0.96)
			_al_lote(nieve, Transform3D(bas, centro + lat + Vector3(0, y + 0.92, 0)), mat_detalle(Color(0.95, 0.97, 1.0), 0.6))
			for k in 5:
				var poste := BoxMesh.new()
				poste.size = Vector3(0.12, 0.95, 0.12)
				_al_lote(poste, Transform3D(bas, centro + lat + dir * (k / 4.0 - 0.5) * largo + Vector3(0, y + 0.4, 0)), _mat_madera)
		var cuerpo := StaticBody3D.new()                # el tablero que se pisa
		cuerpo.name = "PuenteChoque"
		var col := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = Vector3(2.2, 0.2, largo)
		col.shape = caja
		cuerpo.transform = Transform3D(bas, centro + Vector3(0, y - 0.06, 0))
		cuerpo.add_child(col)
		r.add_child(cuerpo)


# ================================================================= pinos nevados y abetos

var _mallas := {}


# Un pino nevado: tronco y tres pisos de ramas de verde oscuro con la nieve encima (color por vértice; sin recortes).
func _malla_pino(variante: int) -> Mesh:
	var clave := "pino%d" % variante
	if _mallas.has(clave):
		return _mallas[clave]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cono(st, Vector3.ZERO, 0.16, 0.11, 1.2, 6, Color(0.36, 0.26, 0.20))
	var pisos := [[0.8, 1.35, 1.55], [1.65, 1.05, 1.35], [2.45, 0.78, 1.2], [3.2, 0.48, 0.95]] if variante == 0 else \
		[[0.6, 1.15, 1.2], [1.3, 0.85, 1.05], [1.95, 0.55, 0.95]]
	for k in pisos.size():
		var p: Array = pisos[k]
		var verde := Color(0.16, 0.30, 0.25).lerp(Color(0.22, 0.38, 0.30), k * 0.25)
		_cono(st, Vector3(0, p[0], 0), p[1], 0.0, p[2], 9, verde, true)
		# la nieve: un cono algo más pequeño y aplastado sobre cada piso, desplazado hacia arriba
		_cono(st, Vector3(0, p[0] + p[2] * 0.42, 0), p[1] * 0.72, 0.0, p[2] * 0.48, 9, Color(0.93, 0.96, 1.0), true)
	st.generate_normals()
	var m := st.commit()
	_mallas[clave] = m
	return m


func _cono(st: SurfaceTool, base: Vector3, r0: float, r1: float, alto: float, lados: int, col: Color, ondas := false) -> void:
	for k in lados:
		var a0 := TAU * k / lados
		var a1 := TAU * (k + 1) / lados
		var e0 := 1.0 + (0.12 if ondas and k % 2 == 0 else 0.0)
		var e1 := 1.0 + (0.12 if ondas and (k + 1) % 2 == 0 else 0.0)
		var p0 := base + Vector3(cos(a0) * r0 * e0, 0, sin(a0) * r0 * e0)
		var p1 := base + Vector3(cos(a1) * r0 * e1, 0, sin(a1) * r0 * e1)
		var q0 := base + Vector3(cos(a0) * r1, alto, sin(a0) * r1)
		var q1 := base + Vector3(cos(a1) * r1, alto, sin(a1) * r1)
		# (Godot: caras delanteras en el sentido de las agujas del reloj, vistas desde fuera)
		for v in [p0, p1, q0, p1, q1, q0] if r1 > 0.0 else [p0, p1, q0]:
			st.set_color(col)
			st.add_vertex(v)


func _pinos() -> void:
	var sombra := _sombra()
	var dist := _dist(0)
	for o in D.OBJETOS:
		if o[0] != "pino_nevado":
			continue
		_pino_en(o[1], sombra, dist, true)
	# abetos achaparrados en las laderas y al pie de las paredes, fuera del paso (dan bosque de montaña sin estorbar)
	var puestos := 0
	var intentos := 0
	while puestos < int(PINOS_EXTRA[nombre_perfil]) and intentos < 4000:
		intentos += 1
		var c := Vector2(_rng.randf_range(1.0, D.ANCHO - 1.0), _rng.randf_range(1.0, D.ALTO - 1.0))
		if T.dist_caminos(c) < 4.5 or T.dist_rincones(c) < 6.0 or T.agua(c) > 0.2:
			continue
		var borde := minf(minf(c.x, c.y), minf(D.ANCHO - c.x, D.ALTO - c.y))
		if borde < 2.0:
			continue
		_pino_en(c, sombra, dist, false)
		puestos += 1


func _pino_en(c: Vector2, sombra: int, dist: float, choca: bool) -> void:
	var p := T.en_mundo(c)
	var variante := 0 if _rng.randf() < 0.7 else 1
	var esc := _rng.randf_range(0.85, 1.35) * (1.0 if variante == 0 else 0.9)
	var t := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(esc, esc * _rng.randf_range(0.95, 1.15), esc)), p + Vector3(0, -0.05, 0))
	var tinte := Color(1, 1, 1).lerp(Color(0.88, 0.94, 1.0), _rng.randf())
	_poner("pino%d" % variante, _malla_pino(variante), _mat_vertices, t, tinte, sombra, dist)
	if choca:
		obstaculo(p.x, p.z, T.CHOQUE_2D["pino_nevado"] * T.K * 0.8)


# ================================================================= rocas con nieve

func _malla_roca(variante: int) -> Mesh:
	var clave := "roca%d" % variante
	if _mallas.has(clave):
		return _mallas[clave]
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 9
	sm.rings = 5
	var a := sm.get_mesh_arrays()
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var ruido := FastNoiseLite.new()
	ruido.seed = 13 + variante * 7
	ruido.frequency = 1.4
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in idx:
		var v: Vector3 = vs[i]
		var k := 1.0 + 0.28 * ruido.get_noise_3dv(v * 1.3)
		var q := Vector3(v.x * k * 1.1, maxf(v.y * k * 0.72, -0.15), v.z * k * 0.95)
		var arriba := smoothstep(0.15, 0.55, v.y)        # la nieve se queda en lo alto
		st.set_color(Color(0.44, 0.46, 0.52).lerp(Color(0.94, 0.96, 1.0), arriba))
		st.add_vertex(q)
	st.generate_normals()
	var m := st.commit()
	_mallas[clave] = m
	return m


func _rocas() -> void:
	var sombra := _sombra()
	for o in D.OBJETOS:
		if o[0] != "roca_nevada":
			continue
		var p := T.en_mundo(o[1])
		var esc := _rng.randf_range(0.42, 0.62)
		var t := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * esc), p)
		_poner("roca%d" % (_rng.randi() % 2), _malla_roca(_rng.randi() % 2), _mat_vertices, t, Color.WHITE, sombra, _dist(1))
		obstaculo(p.x, p.z, T.CHOQUE_2D["roca_nevada"] * T.K * 0.85)
	# peñascos grandes al pie de las paredes (silueta de montaña, fuera del paso)
	for k in 26:
		var c := Vector2(_rng.randf_range(2.0, D.ANCHO - 2.0), _rng.randf_range(2.0, D.ALTO - 3.0))
		var borde := minf(minf(c.x, c.y), D.ANCHO - c.x)
		if borde > 6.0 or T.dist_caminos(c) < 5.0:
			continue
		var p := T.en_mundo(c)
		var esc := _rng.randf_range(1.2, 2.4)
		_poner("roca%d" % (k % 2), _malla_roca(k % 2), _mat_vertices,
			Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * esc), p + Vector3(0, -0.3, 0)), Color.WHITE,
			sombra, _dist(1) + 20.0)


# ================================================================= las ruinas, la estatua, el campamento y el altar

func _crear_ruinas() -> void:
	for o in D.OBJETOS:
		var p := T.en_mundo(o[1])
		match o[0]:
			"columna":
				var alto := _rng.randf_range(1.4, 2.6)
				var cm := _cilindro(0.26, 0.3, alto, 8)
				_al_lote(cm, Transform3D(Basis(Vector3(1, 0, 0), _rng.randf_range(-0.06, 0.06)), p + Vector3(0, alto * 0.5, 0)), _mat_piedra)
				var cap := _cilindro(0.31, 0.31, 0.08, 8)
				_al_lote(cap, Transform3D(Basis(), p + Vector3(0, alto + 0.04, 0)), mat_detalle(Color(0.95, 0.97, 1.0), 0.6))
				obstaculo(p.x, p.z, T.CHOQUE_2D["columna"] * T.K)
			"muro_ruina":
				var bm := BoxMesh.new()
				bm.size = Vector3(1.4, _rng.randf_range(0.7, 1.2), 0.42)
				_al_lote(bm, Transform3D(Basis(Vector3.UP, _rng.randf() * PI), p + Vector3(0, bm.size.y * 0.5, 0)), _mat_piedra)
				obstaculo(p.x, p.z, T.CHOQUE_2D["muro_ruina"] * T.K)
			"tronco":
				var cm := _cilindro(0.2, 0.22, 1.5, 7)
				_al_lote(cm, Transform3D(Basis(Vector3.UP, _rng.randf() * PI) * Basis(Vector3(0, 0, 1), PI * 0.5), p + Vector3(0, 0.2, 0)), _mat_madera)
			"brasero":
				_brasero(p)


func _cilindro(arriba: float, abajo: float, alto: float, lados: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = arriba
	c.bottom_radius = abajo
	c.height = alto
	c.radial_segments = lados
	c.rings = 1
	return c


func _brasero(p: Vector3) -> void:
	var hierro := StandardMaterial3D.new()
	hierro.albedo_color = Color(0.25, 0.24, 0.24)
	hierro.metallic = 0.5
	hierro.roughness = 0.55
	_al_lote(_cilindro(0.34, 0.2, 0.32, 8), Transform3D(Basis(), p + Vector3(0, 0.78, 0)), hierro)
	_al_lote(_cilindro(0.05, 0.05, 0.62, 5), Transform3D(Basis(), p + Vector3(0, 0.31, 0)), hierro)
	var brasas := StandardMaterial3D.new()
	brasas.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	brasas.albedo_color = Color(1.0, 0.55, 0.18)
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.2
	sm.radial_segments = 8
	sm.rings = 3
	_al_lote(sm, Transform3D(Basis(), p + Vector3(0, 0.95, 0)), brasas)
	obstaculo(p.x, p.z, 0.35)
	fuego_pos = p + Vector3(0, 0.95, 0)
	_luz(fuego_pos + Vector3(0, 0.5, 0), Color(1.0, 0.62, 0.3), 1.6, 7.0, true)


# La estatua sin brazo (progreso.gd, «ciclopea_estatua»: «Un caballero de piedra sin brazo izquierdo. Mira hacia el
# pico.»): un caballero en pie sobre su peana, de piedra gastada con nieve en los hombros, mirando al norte (al pico).
func _crear_estatua() -> void:
	if D.DETALLES.is_empty():
		return
	var c: Vector2 = D.DETALLES[0][1]
	var p := T.en_mundo(c)
	estatua = Node3D.new()
	estatua.name = "EstatuaSinBrazo"
	estatua.position = p
	estatua.rotation.y = PI                               # mira a −z: el norte, hacia el pico
	r.add_child(estatua)
	var piedra := mat_detalle(Color(0.66, 0.66, 0.68), 1.1, false, 1.0)
	var nieve := mat_detalle(Color(0.95, 0.97, 1.0), 0.6)
	var partes := [
		[_caja(Vector3(1.0, 0.45, 1.0)), Vector3(0, 0.22, 0), Vector3.ZERO, piedra],                 # peana
		[_caja(Vector3(1.04, 0.06, 1.04)), Vector3(0, 0.47, 0), Vector3.ZERO, nieve],
		[_cilindro(0.17, 0.2, 0.9, 7), Vector3(-0.13, 0.95, 0), Vector3.ZERO, piedra],               # piernas
		[_cilindro(0.17, 0.2, 0.9, 7), Vector3(0.13, 0.95, 0), Vector3.ZERO, piedra],
		[_cilindro(0.34, 0.28, 0.85, 8), Vector3(0, 1.75, 0), Vector3.ZERO, piedra],                 # torso con peto
		[_esfera(0.2, 0.42), Vector3(0, 2.36, 0.02), Vector3(-0.25, 0, 0), piedra],                    # yelmo, alzado al pico
		[_caja(Vector3(0.24, 0.04, 0.06)), Vector3(0, 2.38, 0.2), Vector3(-0.25, 0, 0), _mat_madera],  # la ranura, oscura
		[_esfera(0.17, 0.24), Vector3(-0.38, 2.08, 0), Vector3.ZERO, piedra],                         # hombro derecho
		[_esfera(0.15, 0.2), Vector3(0.36, 2.06, 0), Vector3.ZERO, piedra],                           # hombro izquierdo, sin brazo
		[_caja(Vector3(0.22, 0.06, 0.22)), Vector3(-0.38, 2.2, 0), Vector3.ZERO, nieve],              # nieve en los hombros
		[_caja(Vector3(0.18, 0.05, 0.18)), Vector3(0.36, 2.16, 0), Vector3.ZERO, nieve],
		[_cilindro(0.09, 0.1, 0.7, 6), Vector3(-0.44, 1.7, 0.05), Vector3(0.2, 0, 0.12), piedra],    # brazo derecho, con la espada
		[_caja(Vector3(0.07, 1.25, 0.03)), Vector3(-0.5, 1.0, 0.2), Vector3(0.15, 0, 0), piedra],     # la espada, apoyada
		[_caja(Vector3(0.2, 0.18, 0.12)), Vector3(0.4, 1.86, 0.02), Vector3(0, 0, -0.4), piedra],     # el muñón roto
	]
	# el brazo que falta, caído entre la nieve al pie de la peana
	partes.append([_cilindro(0.09, 0.1, 0.72, 6), Vector3(0.9, 0.12, -0.5), Vector3(0, 0.7, PI * 0.5), piedra])
	# todo en una malla por material (3 llamadas de dibujo en vez de 16; con sombra, 6 en vez de 32)
	var juntas := {}
	for pt in partes:
		if not juntas.has(pt[3]):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			juntas[pt[3]] = st
		juntas[pt[3]].append_from(pt[0], 0, Transform3D(Basis.from_euler(pt[2]), pt[1]))
	for mat in juntas:
		var mi := MeshInstance3D.new()
		mi.mesh = juntas[mat].commit()
		mi.material_override = mat
		mi.cast_shadow = _sombra()
		estatua.add_child(mi)
	obstaculo(p.x, p.z, 0.75)


func _crear_campamento() -> void:
	var cam := T.en_mundo(T.lugar("campamento"))
	# una tienda de lona tensada y una pila de leña nevada junto al brasero de la 2D
	var lona := mat_detalle(Color(0.58, 0.46, 0.34), 1.2, false, 0.5)
	var tienda := PrismMesh.new()
	tienda.size = Vector3(2.0, 1.3, 1.9)
	var pt := cam + Vector3(-2.4, 0.65, -2.0)
	pt.y = T.altura(pt.x, pt.z) + 0.65
	_al_lote(tienda, Transform3D(Basis(Vector3.UP, 0.4), pt), lona)
	obstaculo(pt.x, pt.z, 1.0)
	var techo := PrismMesh.new()
	techo.size = Vector3(2.04, 0.1, 1.92)
	for k in 4:
		var tronco := _cilindro(0.09, 0.09, 1.1, 6)
		var q := cam + Vector3(2.2, 0, -1.6 + k * 0.2)
		q.y = T.altura(q.x, q.z) + 0.1 + (k % 2) * 0.14
		_al_lote(tronco, Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), q), _mat_madera)


func _crear_altar() -> void:
	var p := T.en_mundo(D.META)
	var nieve := mat_detalle(Color(0.95, 0.97, 1.0), 0.6)
	var bm := BoxMesh.new()
	bm.size = Vector3(3.2, 0.24, 2.8)
	_al_lote(bm, Transform3D(Basis(), p + Vector3(0, 0.06, 0)), _mat_piedra)
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(1.3, 0.85, 0.9)
	_al_lote(bm2, Transform3D(Basis(), p + Vector3(0, 0.6, -0.3)), _mat_piedra)
	var bm3 := BoxMesh.new()
	bm3.size = Vector3(1.4, 0.08, 1.0)
	_al_lote(bm3, Transform3D(Basis(), p + Vector3(0, 1.07, -0.3)), nieve)
	obstaculo(p.x, p.z - 0.3 * 1.0, 0.8)
	for k in 6:                                         # menhires con escarcha alrededor
		var a := k * TAU / 6.0 + 0.4
		var mh := BoxMesh.new()
		mh.size = Vector3(0.36, _rng.randf_range(1.0, 1.8), 0.3)
		var q := p + Vector3(cos(a) * 2.8, 0, sin(a) * 2.4)
		q.y = T.altura(q.x, q.z) + mh.size.y * 0.5 - 0.05
		_al_lote(mh, Transform3D(Basis(Vector3.UP, a), q), _mat_piedra)
		obstaculo(q.x, q.z, 0.3)
	orbe = Node3D.new()
	orbe.name = "Orbe"
	orbe.position = p + Vector3(0, 2.0, -0.3)
	r.add_child(orbe)
	var esf := MeshInstance3D.new()
	esf.mesh = _esfera(0.2, 0.4)
	var mo := StandardMaterial3D.new()
	mo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mo.albedo_color = Color(0.75, 0.95, 1.0)
	esf.material_override = mo
	esf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orbe.add_child(esf)
	var halo := Sprite3D.new()
	halo.texture = _tex_brillo()
	halo.pixel_size = 1.6 / 64.0
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	halo.shaded = false
	halo.transparent = true
	halo.modulate = Color(0.5, 0.9, 1.0, 0.7)               # zona.gd: el altar de la nieve
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orbe.add_child(halo)
	_flotan.append([orbe, orbe.position.y, 0.0])
	_luz(p + Vector3(0, 1.8, -0.3), Color(0.5, 0.9, 1.0), 1.4, 8.0)


# Las cumbres del fondo: montañas nevadas fuera del mapa (al norte, al este y al oeste), una sola malla.
func _cumbres() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var picos := []
	for k in 13:
		var a := lerpf(-PI * 0.95, -PI * 0.05, k / 12.0)      # un arco del oeste al este por el norte
		var d := _rng.randf_range(72.0, 95.0)
		picos.append([Vector3(cos(a) * d, 0, sin(a) * d - 6.0), _rng.randf_range(16.0, 30.0), _rng.randf_range(18.0, 28.0)])
	for pk in picos:
		var base: Vector3 = pk[0]
		var alto: float = pk[1]
		var radio: float = pk[2]
		var lados := 7
		for k in lados:
			var a0 := TAU * k / lados + base.x
			var a1 := TAU * (k + 1) / lados + base.x
			var p0 := base + Vector3(cos(a0), 0, sin(a0)) * radio * (0.85 + 0.3 * absf(sin(a0 * 3.0)))
			var p1 := base + Vector3(cos(a1), 0, sin(a1)) * radio * (0.85 + 0.3 * absf(sin(a1 * 3.0)))
			var cima := base + Vector3(0, alto, 0)
			var m0 := p0.lerp(cima, 0.55)
			var m1 := p1.lerp(cima, 0.55)
			var roca := Color(0.42, 0.45, 0.54)
			var nieve := Color(0.92, 0.95, 1.0)
			for v in [[p0, roca], [p1, roca], [m0, roca], [p1, roca], [m1, roca], [m0, roca], [m0, nieve], [m1, nieve], [cima, nieve]]:
				st.set_color(v[1])
				st.add_vertex(v[0])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Cumbres"
	mi.mesh = st.commit()
	mi.material_override = _mat_vertices
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(mi)


# ================================================================= nevada, luces y detalles

func _nevada() -> void:
	copos = CPUParticles3D.new()
	copos.name = "Nevada"
	copos.amount = int(COPOS[nombre_perfil])
	copos.lifetime = 6.0
	copos.preprocess = 6.0
	copos.local_coords = false
	copos.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	copos.emission_box_extents = Vector3(13, 0.5, 9)
	copos.direction = Vector3(0.25, -1, 0.1)
	copos.spread = 18.0
	copos.initial_velocity_min = 0.6
	copos.initial_velocity_max = 1.0
	copos.gravity = Vector3(0.25, -0.35, 0.0)
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var m := StandardMaterial3D.new()                      # opaco: sin mezcla (barato en el Mali)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(0.96, 0.98, 1.0)
	q.material = m
	copos.mesh = q
	copos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(copos)


func _tex_brillo() -> GradientTexture2D:
	if _brillo_tex == null:
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		_brillo_tex = GradientTexture2D.new()
		_brillo_tex.gradient = g
		_brillo_tex.fill = GradientTexture2D.FILL_RADIAL
		_brillo_tex.fill_from = Vector2(0.5, 0.5)
		_brillo_tex.fill_to = Vector2(1.0, 0.5)
		_brillo_tex.width = 64
		_brillo_tex.height = 64
	return _brillo_tex


# Una luz real en el alto (luces_faroles); en bajo y medio, un halo pintado en la nieve (como el Gran Bosque).
func _luz(p: Vector3, color: Color, energia: float, alcance: float, parpadea := false) -> void:
	if perfil.get("luces_faroles", false):
		var l := OmniLight3D.new()
		l.light_color = color
		l.light_energy = energia
		l.omni_range = alcance
		l.shadow_enabled = false
		l.position = p
		r.add_child(l)
		if parpadea:
			luces.append([l, energia])
		return
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(color, 0.30), Color(color, 0.09), Color(color, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_texture = tex
	var disco := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(alcance, alcance) * 0.8
	disco.mesh = pm
	disco.material_override = m
	disco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disco.position = Vector3(p.x, T.altura(p.x, p.z) + 0.1, p.z)
	r.add_child(disco)


func _caja(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b


func _esfera(radio: float, alto: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radio
	s.height = alto
	s.radial_segments = 10
	s.rings = 6
	return s


func destello(padre: Node3D, pos: Vector3, tam: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(tam, tam) * 8.0
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _tex_brillo()
	m.albedo_color = color
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	padre.add_child(mi)
	_flotan.append([mi, -1.0, randf() * TAU])
	return mi


# ================================================================= cofres (como los del Gran Bosque; su id es el de la 2D)

func crear_cofre(id: String, c: Vector2, abierto: bool, mira := Vector3(0, 0, 1)) -> void:
	var p := T.en_mundo(c)
	var nodo := Node3D.new()
	nodo.name = "Cofre_" + id
	nodo.position = p
	nodo.rotation.y = atan2(mira.x, mira.z)
	r.add_child(nodo)
	var madera := mat_detalle(Color(0.50, 0.32, 0.18), 1.6, false, 1.0)
	var hierro := StandardMaterial3D.new()
	hierro.albedo_color = Color(0.34, 0.33, 0.33)
	hierro.metallic = 0.6
	hierro.roughness = 0.5
	var caja := MeshInstance3D.new()
	caja.mesh = _caja(Vector3(0.9, 0.42, 0.56))
	caja.material_override = madera
	caja.position.y = 0.21
	nodo.add_child(caja)
	for x in [-0.32, 0.32]:
		var banda := MeshInstance3D.new()
		banda.mesh = _caja(Vector3(0.07, 0.44, 0.58))
		banda.material_override = hierro
		banda.position = Vector3(x, 0.21, 0)
		nodo.add_child(banda)
	var bisagra := Node3D.new()
	bisagra.position = Vector3(0, 0.42, -0.28)
	nodo.add_child(bisagra)
	var tapa := MeshInstance3D.new()
	var cm := _cilindro(0.28, 0.28, 0.9, 10)
	tapa.mesh = cm
	tapa.material_override = madera
	tapa.rotation.z = PI * 0.5
	tapa.scale = Vector3(1, 1, 0.55)
	tapa.position = Vector3(0, 0.0, 0.28)
	bisagra.add_child(tapa)
	var escarcha := MeshInstance3D.new()                  # un poco de nieve en la tapa (se va al abrir)
	escarcha.name = "Nieve"
	escarcha.mesh = _caja(Vector3(0.7, 0.04, 0.3))
	escarcha.material_override = mat_detalle(Color(0.95, 0.97, 1.0), 0.6)
	escarcha.position = Vector3(0, 0.15, 0.3)
	bisagra.add_child(escarcha)
	if abierto:
		bisagra.rotation.x = deg_to_rad(-105.0)
		escarcha.visible = false
	var brillo: MeshInstance3D = null
	if not abierto:
		brillo = destello(nodo, Vector3(0, 0.75, 0.1), 0.05, Color(0.75, 0.9, 1.0))
	cofres[id] = {"nodo": nodo, "tapa": bisagra, "pos": p, "abierto": abierto, "brillo": brillo, "nieve": escarcha}
	obstaculo(p.x, p.z, 0.45)


func abrir_cofre(id: String) -> void:
	var cf: Dictionary = cofres.get(id, {})
	if cf.is_empty():
		return
	cf["abierto"] = true
	if cf["brillo"] != null and is_instance_valid(cf["brillo"]):
		cf["brillo"].queue_free()
	cf["brillo"] = null
	if cf.has("nieve") and is_instance_valid(cf["nieve"]):
		cf["nieve"].visible = false
	var t: Tween = cf["tapa"].create_tween()
	t.tween_property(cf["tapa"], "rotation:x", deg_to_rad(-105.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Cada fotograma: la nevada sigue a Kael, el orbe flota, los destellos laten y el brasero parpadea.
func animar(t: float, kael: Vector3) -> void:
	if copos != null:
		copos.global_position = kael + Vector3(-2.0, 7.0, -3.0)
	for f in _flotan:
		if not is_instance_valid(f[0]):
			continue
		var n: Node3D = f[0]
		if f[1] >= 0.0:
			n.position.y = f[1] + sin(t * 1.6) * 0.12
		else:
			n.scale = Vector3.ONE * (0.75 + 0.3 * sin(t * 3.2 + f[2]))
	for l in luces:
		l[0].light_energy = l[1] * (0.82 + 0.18 * sin(t * 13.0) * sin(t * 7.3 + 1.0))
