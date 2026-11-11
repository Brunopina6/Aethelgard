extends Node3D
# Rincones de Pastos Verdes 3D (narrativa y exploración, 12/11/2026): cosas pequeñas fuera de la misión para que el
# camino no sea solo andar y combatir. Lo crea zonas3d/pastos_verdes_3d.gd (como el bosque de la fase 3) y le pregunta
# qué hay cerca (cerca_de), qué hacer al pulsar el botón (accion) y qué pasa al acabar un diálogo (tras_dialogo).
# Textos: dialogos/notas/pastos_rincones.gd y dialogos/pastos/rincon_nido.dtl.
#
#   1. Pájaros que levantan el vuelo: tres bandadas posadas en la hierba que salen volando cuando Kael se acerca y
#      vuelven a posarse al rato. Solo ambiente: no se guarda nada.
#   2. El montón de los peregrinos, al principio del camino: «Dejar una piedra». Tu piedra se queda arriba (hito
#      «rin_piedra») y quien esté en el grupo dice algo. Una vez por partida.
#   3. El nido de la urraca, en un árbol seco al este del puente: un brillo que se enciende de vez en cuando en lo
#      alto. Sin Garon nadie llega; con él, Garon aúpa a Kael (diálogo) y bajan 25 monedas y una moneda antigua (hito
#      «rin_nido», una vez por partida).
#   4. El centro del puente: «Asomarse» a la cascada. Una charla breve distinta según quién esté (solo Kael, con Lya, con
#      Garon); cada una, una vez por partida (hitos «rin_puente_solo», «rin_puente_lya» y «rin_puente_grupo»).
#
# Se guarda con claves que ya existen («hitos» e inventario): las partidas antiguas cargan igual (sin esos hitos, todo
# está por descubrir). No bloquea caminos: el montón y el nido están fuera del sendero, y el puente solo enseña un botón.
# Formas sencillas, sin modelos de terceros, como Tilo, la estela y el cofre; pocas llamadas de dibujo (bandadas en
# MultiMesh y el montón en una sola malla).

const T := preload("res://dialogos/notas/pastos_rincones.gd")
const Comentarios := preload("res://dialogos/comentarios.gd")

const RADIO := 2.0                          # metros para el botón (la región usa 2,2 para lo suyo)
const RADIO_PUENTE := 1.1                   # en el puente, solo en el centro
# Sitios aproximados (x, z): cada cosa busca su hueco libre cerca.
const SITIO_MONTON := Vector3(-14.6, 0, 11.6)      # al principio del camino, del otro lado de la cinta de los peregrinos
const SITIO_NIDO := Vector3(18.5, 0, 8.5)          # el árbol seco, en el prado al este del puente, cerca del cofre
const ALTO_SECO := 2.9                             # metros del árbol seco (el nido va en lo alto)
const ESCALA_MONTON := 1.65                        # el montón, a la altura de la cadera de Kael: de lejos se lee
const PUENTE := Vector3(9.0, 0, -2.0)              # centro del puente (RIO_X, z del puente)
const MIRA_PUENTE := Vector3(9.0, 0, -16.0)        # la cascada
# Bandadas: [centro, aves]. En prados abiertos, lejos de lo que se examina y sin un árbol justo al sur (la cámara mira
# desde +z: su copa las tapaba; capturas del 12/11).
const BANDADAS := [[Vector3(-10.5, 0, -0.5), 6], [Vector3(1.7, 0, 4.3), 5], [Vector3(19.5, 0, -0.5), 5]]
const SUSTO := 4.2                          # metros: más cerca, la bandada sale volando
const VUELO := 2.6                          # segundos en el aire antes de perderse de vista
const VUELTA := 22.0                        # segundos hasta que vuelven a posarse...
const VUELTA_LEJOS := 9.0                   # ...si Kael está a más de estos metros
const BAJADA := 1.1                         # segundos que tardan en posarse
# Segundos de cada aviso; el comentario sale cuando el aviso se va (si no, el aviso y la caja se pisaban: capturas del
# 12/11). El aviso de la región tarda 0,2 s en aparecer y 0,5 en irse.
const AVISO_PIEDRA := 1.8
const AVISO_NIDO := 2.0
const AVISO_PREMIO := 2.6

var r                                       # la región (pastos_verdes_3d.gd)
var puntos: Array = []                      # {"id", "nodo", "boton", "radio"}
var monton: StaticBody3D
var piedra_tuya: MeshInstance3D
var arbol_seco: StaticBody3D
var nido: Node3D
var brillo_nido: MeshInstance3D
var bandadas: Array = []                    # {"centro", "mm", "aves": [{"base", "fase", "vel", "pos"}], "estado", "t"}
var aves_asustadas := 0                     # veces que una bandada ha salido volando (las pruebas lo miran)
var _ocupado := false                       # Kael está subiendo al nido (fundido): sin control
var _rng := RandomNumberGenerator.new()
var _t := 0.0


static func P():
	return load("res://progreso.gd")


static func presentes() -> String:
	var a: Array = load("res://grupo.gd").activos()
	if a.has("Garon"):
		return "grupo"
	if a.has("Lya"):
		return "lya"
	return "solo"


func preparar(region) -> void:
	r = region
	name = "Rincones"
	_rng.seed = 12112026                    # las bandadas salen igual cada vez
	_construir.call_deferred()


func _construir() -> void:
	await get_tree().physics_frame          # los huecos libres se miran con la física ya lista
	await get_tree().physics_frame
	if not is_instance_valid(r):
		return
	monton = _crear_monton(_sitio_fuera_del_camino(SITIO_MONTON, 1.9, 3.6))
	_punto("piedra", monton, T.BOTONES["piedra_ya" if P().hito("rin_piedra") else "piedra"], RADIO)
	var pie := _crear_nido()
	if pie != null:
		_punto("nido", pie, T.BOTONES["nido"], RADIO)
	var marca := Node3D.new()
	marca.name = "CentroPuente"
	marca.position = Vector3(PUENTE.x, 0.0, PUENTE.z)
	add_child(marca)
	_punto("puente", marca, T.BOTONES["puente"], RADIO_PUENTE)
	for b in BANDADAS:
		bandadas.append(_crear_bandada(b[0], b[1]))


func _punto(id: String, nodo: Node3D, boton: String, radio: float) -> void:
	puntos.append({"id": id, "nodo": nodo, "boton": boton, "radio": radio})


# ================================================================= lo que pregunta la región

# {"id", "boton"} de lo que hay al alcance (o {}).
func cerca_de(pos: Vector3) -> Dictionary:
	var mejor := {}
	var dmin := INF
	for p in puntos:
		if not is_instance_valid(p["nodo"]) or not disponible(p["id"]):
			continue
		var d: float = r._dist_plana(pos, p["nodo"].global_position)
		if d < p["radio"] and d < dmin:
			dmin = d
			mejor = {"id": p["id"], "boton": p["boton"]}
	return mejor


# Si el botón de ese rincón sale ahora.
func disponible(id: String) -> bool:
	match id:
		"nido":
			return not P().hito("rin_nido")
		"puente":
			return not P().hito("rin_puente_" + presentes())
	return true


func ocupado() -> bool:
	return _ocupado


func accion(id: String) -> void:
	match id:
		"piedra":
			_dejar_piedra()
		"nido":
			_mirar_nido()
		"puente":
			_asomarse()


func tras_dialogo(id: String) -> void:
	if id == T.DIALOGO_NIDO:
		_subir_al_nido()


# Cada fotograma (desde _process de la región): las bandadas y el brillo del nido.
func comprobar(pos: Vector3, delta: float) -> void:
	_t += delta
	for b in bandadas:
		_animar_bandada(b, pos, delta)


# ================================================================= 2. el montón de los peregrinos

func _dejar_piedra() -> void:
	var hacia: Vector3 = monton.global_position - r.kael.global_position
	hacia.y = 0.0
	if hacia.length() > 0.05:
		r.kael.mirar(hacia, 0.2)
	if P().hito("rin_piedra"):
		r._mostrar_aviso(T.TEXTOS["piedra_ya"], 2.2)
		return
	P().poner_hito("rin_piedra")
	_poner_piedra_tuya(monton, true)
	_quitar_y_poner_boton("piedra", T.BOTONES["piedra_ya"])
	Sonido.efecto("paso_piedra", {"pos": monton.global_position})
	r._mostrar_aviso(T.TEXTOS["piedra_dejar"], AVISO_PIEDRA)
	_comentar("piedra", AVISO_PIEDRA + 0.2)          # tras el aviso: no se pisan
	_guardar()


func _quitar_y_poner_boton(id: String, boton: String) -> void:
	for p in puntos:
		if p["id"] == id:
			p["boton"] = boton


# Piedras planas apiladas, una sola malla con color por vértice (una llamada de dibujo) y un choque bajo.
func _crear_monton(p: Vector3) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "MontonPeregrinos"
	cuerpo.position = p
	add_child(cuerpo)
	var e := ESCALA_MONTON
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# [altura, radio, alto, desvío x, desvío z, gris]
	var capas := [[0.0, 0.42, 0.16, 0.0, 0.0, 0.55], [0.13, 0.36, 0.14, 0.03, -0.02, 0.62],
		[0.25, 0.3, 0.13, -0.03, 0.02, 0.5], [0.36, 0.24, 0.12, 0.02, 0.01, 0.66], [0.46, 0.18, 0.1, -0.01, -0.02, 0.58],
		[0.54, 0.13, 0.09, 0.01, 0.01, 0.7]]
	for c in capas:
		var gris: float = c[5]
		_esfera_en(st, c[1] * e, c[2] * e, 9, 3, Transform3D(Basis.from_euler(Vector3(0.0, c[0] * 7.0, 0.0)),
			Vector3(c[3], c[0] + c[2] * 0.5, c[4]) * e), Color(gris, gris * 0.97, gris * 0.92))
	# piedras sueltas al pie, como las que se caen
	for k in 4:
		var a := TAU * k / 4.0 + 0.6
		_esfera_en(st, 0.1 * e, 0.08 * e, 7, 2, Transform3D(Basis(), Vector3(cos(a) * 0.55, 0.04, sin(a) * 0.55) * e),
			Color(0.52, 0.5, 0.47))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = r._mat_detalle(Color.WHITE, 0.8, true, 1.0)
	cuerpo.add_child(mi)
	var col := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.42 * e
	cil.height = 0.6 * e
	col.shape = cil
	col.position.y = 0.3 * e
	cuerpo.add_child(col)
	_poner_piedra_tuya(cuerpo, false)
	return cuerpo


# La piedra de Kael: algo más clara, arriba del todo. Al dejarla, cae un poco y se asienta.
func _poner_piedra_tuya(cuerpo: Node3D, animar: bool) -> void:
	if piedra_tuya != null or not P().hito("rin_piedra"):
		return
	var s := SphereMesh.new()
	s.radius = 0.09 * ESCALA_MONTON
	s.height = 0.08 * ESCALA_MONTON
	s.radial_segments = 8
	s.rings = 3
	piedra_tuya = MeshInstance3D.new()
	piedra_tuya.name = "PiedraTuya"
	piedra_tuya.mesh = s
	piedra_tuya.material_override = r._mat_detalle(Color(0.9, 0.88, 0.8), 0.8, false, 0.8)
	var arriba := 0.63 * ESCALA_MONTON
	piedra_tuya.position = Vector3(0.0, arriba, 0.0)
	piedra_tuya.rotation.z = 0.12
	cuerpo.add_child(piedra_tuya)
	if animar:
		piedra_tuya.position.y = arriba + 0.6
		var t := piedra_tuya.create_tween()
		t.tween_property(piedra_tuya, "position:y", arriba, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(piedra_tuya, "rotation:z", 0.0, 0.15)


# ================================================================= 3. el nido de la urraca

# Un árbol seco, sin copa, en el prado del este (se ve desde el cofre del árbol mágico): el nido va en la horquilla de
# arriba, a la vista de la cámara (que mira desde +z y nunca gira), con un brillo que se enciende a ratos. En un árbol
# con copa, la copa lo tapaba desde el camino (capturas del 12/11). Devuelve el punto del pie donde sale el botón.
func _crear_nido() -> Node3D:
	var base := _sitio_libre(SITIO_NIDO, 0.9)
	arbol_seco = StaticBody3D.new()
	arbol_seco.name = "ArbolSeco"
	arbol_seco.position = base
	arbol_seco.rotation.y = 0.5
	add_child(arbol_seco)
	var madera: StandardMaterial3D = r._mat_detalle(Color(0.6, 0.53, 0.45), 0.6, false, 1.0)
	var oscura: StandardMaterial3D = r._mat_detalle(Color(0.45, 0.38, 0.31), 0.6, false, 1.0)
	# [radio arriba, radio abajo, alto, posición, giro, material]
	var piezas := [[0.13, 0.24, ALTO_SECO, Vector3(0, ALTO_SECO * 0.5, 0), Vector3(0, 0, 0.04), madera],
		[0.05, 0.1, 1.1, Vector3(-0.32, ALTO_SECO - 0.25, 0.0), Vector3(0, 0, 0.75), madera],      # rama de la horquilla
		[0.04, 0.09, 0.9, Vector3(0.28, ALTO_SECO - 0.45, 0.05), Vector3(0.1, 0, -0.8), madera],
		[0.03, 0.07, 0.7, Vector3(0.18, 1.35, -0.1), Vector3(0.5, 0, -1.0), oscura],              # muñón
		[0.24, 0.42, 0.35, Vector3(0, 0.17, 0), Vector3.ZERO, oscura]]                             # raíz
	for p in piezas:
		var c := CylinderMesh.new()
		c.top_radius = p[0]
		c.bottom_radius = p[1]
		c.height = p[2]
		c.radial_segments = 8
		c.rings = 1
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = p[5]
		mi.position = p[3]
		mi.rotation = p[4]
		arbol_seco.add_child(mi)
	var col := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.32
	cil.height = ALTO_SECO
	col.shape = cil
	col.position.y = ALTO_SECO * 0.5
	arbol_seco.add_child(col)
	nido = Node3D.new()
	nido.name = "NidoUrraca"
	nido.position = base + Vector3(-0.05, ALTO_SECO - 0.05, 0.1)
	add_child(nido)
	var ramitas := TorusMesh.new()
	ramitas.inner_radius = 0.1
	ramitas.outer_radius = 0.3
	ramitas.rings = 12
	ramitas.ring_segments = 6
	var mn := MeshInstance3D.new()
	mn.mesh = ramitas
	mn.material_override = r._mat_detalle(Color(0.42, 0.3, 0.18), 1.5, false, 1.0)
	mn.scale = Vector3(1.0, 0.75, 1.0)
	nido.add_child(mn)
	var hueco := CylinderMesh.new()                        # el fondo del nido, oscuro
	hueco.top_radius = 0.17
	hueco.bottom_radius = 0.12
	hueco.height = 0.06
	hueco.radial_segments = 10
	var mh := MeshInstance3D.new()
	mh.mesh = hueco
	mh.material_override = r._mat_simple(Color(0.2, 0.14, 0.08))
	mh.position.y = 0.02
	nido.add_child(mh)
	if not P().hito("rin_nido"):
		# Señal que guía sin invadir: un brillo pequeño que se enciende un momento cada pocos segundos, como un reflejo.
		brillo_nido = r._destello(nido, Vector3(0.05, 0.14, 0.08), 0.05)
		brillo_nido.name = "BrilloNido"
		var t := brillo_nido.create_tween().set_loops()
		t.tween_interval(3.0)
		t.tween_property(brillo_nido, "scale", Vector3.ONE * 0.7, 0.25).set_trans(Tween.TRANS_SINE)
		t.tween_property(brillo_nido, "scale", Vector3.ONE * 0.05, 0.5).set_trans(Tween.TRANS_SINE)
	# el pie del árbol, del lado de la cámara (el tronco choca: el botón sale al llegar a él)
	var pie := Node3D.new()
	pie.name = "PieNido"
	var q := base + Vector3(0.0, 0.0, 0.9)
	pie.position = Vector3(q.x, r.altura(q.x, q.z), q.z)
	add_child(pie)
	return pie


# Hueco libre cerca de «c» (fuera de lo prohibido y del camino), en el suelo.
func _sitio_libre(c: Vector3, holgura: float) -> Vector3:
	for radio in [0.0, 0.7, 1.4, 2.1, 2.8]:
		for k in 8:
			var a := TAU * k / 8.0
			var q: Vector3 = c + Vector3(cos(a), 0, sin(a)) * radio
			if r._prohibido(q) or r._dist_sendero(q) < 2.0:
				continue
			q.y = r.altura(q.x, q.z)
			if r._hueco_libre(q, holgura):
				return q
	return Vector3(c.x, r.altura(c.x, c.z), c.z)


func _mirar_nido() -> void:
	if P().hito("rin_nido"):
		r._mostrar_aviso(T.TEXTOS["nido_vacio"], 2.2)
		return
	var hacia: Vector3 = nido.global_position - r.kael.global_position
	hacia.y = 0.0
	if hacia.length() > 0.05:
		r.kael.mirar(hacia, 0.2)
	if presentes() != "grupo":                       # sin Garon nadie llega: hay que volver
		r._mostrar_aviso(T.TEXTOS["nido_lejos"], AVISO_NIDO)
		_comentar("nido_lejos", AVISO_NIDO + 0.2)
		return
	if not r._empezar_dialogo(T.DIALOGO_NIDO):       # sin Dialogic (o con otro abierto), sube igual
		_subir_al_nido()


# Garon aúpa a Kael: fundido corto (subir y bajar), y el premio. El hito va antes que el premio: se da una sola vez
# aunque se pulse dos veces, y se guarda con él.
func _subir_al_nido() -> void:
	if P().hito("rin_nido") or _ocupado:
		return
	P().poner_hito("rin_nido")
	var Inv = load("res://inventario.gd")            # el premio va con el hito y se guarda ya: si la app se cierra
	Inv.ganar_oro(T.NIDO_MONEDAS)                    # durante el fundido, no se pierde ni se repite
	Inv.agregar_objeto(T.NIDO_OBJETO, 1)
	_guardar()
	_ocupado = true
	r._parar_kael()
	r.boton_accion.visible = false
	var t := create_tween()
	t.tween_property(r.fundido, "color", Color(0, 0, 0, 0.92), 0.35)
	t.tween_callback(func():
		Sonido.efecto("paso_hojas", {"pos": nido.global_position})
		if brillo_nido != null:
			brillo_nido.queue_free()
			brillo_nido = null)
	t.tween_interval(0.7)
	t.tween_property(r.fundido, "color", Color(0, 0, 0, 0), 0.35)
	await t.finished
	Sonido.efecto("tesoro")
	r._mostrar_aviso(T.TEXTOS["nido_premio"] % T.NIDO_MONEDAS, AVISO_PREMIO)
	_ocupado = false
	_comentar("nido_premio", AVISO_PREMIO + 0.2)


# ================================================================= 4. el centro del puente

func _asomarse() -> void:
	var quien := presentes()
	var hacia: Vector3 = MIRA_PUENTE - r.kael.global_position
	hacia.y = 0.0
	r._parar_kael()
	r.kael.mirar(hacia, 0.35)
	if P().hito("rin_puente_" + quien):
		return
	P().poner_hito("rin_puente_" + quien)
	_comentar("puente", 0.5)
	_guardar()


# ================================================================= 1. pájaros que levantan el vuelo

# Un pajarillo de formas sencillas (cuerpo, pecho, cabeza, pico, cola y alas), en una sola malla con color por vértice.
# Más grande que uno de verdad (unos 30 cm): con la cámara a 20 m, uno de 12 cm no se veía (capturas del 12/11). Lomo
# castaño y pecho claro, para que se lean sobre la hierba.
const ESCALA_AVE := 2.2


static func _malla_ave() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var partes := [[0.055, 0.07, Vector3(0, 0.05, 0), Vector3(1.0, 1.0, 1.35), Color(0.62, 0.38, 0.2)],      # cuerpo
		[0.04, 0.04, Vector3(0, 0.042, 0.025), Vector3(1.05, 0.9, 1.1), Color(0.95, 0.88, 0.74)],                # pecho
		[0.035, 0.07, Vector3(0, 0.1, 0.06), Vector3.ONE, Color(0.3, 0.22, 0.16)],                               # cabeza
		[0.012, 0.024, Vector3(0, 0.1, 0.1), Vector3(1.0, 1.0, 1.6), Color(0.95, 0.72, 0.25)],                   # pico
		[0.028, 0.05, Vector3(0, 0.07, -0.08), Vector3(1.2, 0.4, 1.6), Color(0.28, 0.2, 0.15)],                  # cola
		[0.04, 0.05, Vector3(0.05, 0.065, -0.01), Vector3(0.45, 0.5, 1.5), Color(0.4, 0.26, 0.15)],              # alas
		[0.04, 0.05, Vector3(-0.05, 0.065, -0.01), Vector3(0.45, 0.5, 1.5), Color(0.4, 0.26, 0.15)]]
	for pt in partes:
		var xf := Transform3D(Basis.from_scale(pt[3] * ESCALA_AVE), pt[2] * ESCALA_AVE)
		_esfera_en(st, pt[0], pt[1], 7, 4, xf, pt[4])
	return st.commit()


# Añade a «st» una esfera (o un elipsoide, con la escala de «xf») con su color en cada vértice: así varias piezas van en
# una sola malla y una sola llamada de dibujo (append_from no conserva un color propio por pieza).
static func _esfera_en(st: SurfaceTool, radio: float, alto: float, lados: int, anillos: int, xf: Transform3D, color: Color) -> void:
	var s := SphereMesh.new()
	s.radius = radio
	s.height = alto
	s.radial_segments = lados
	s.rings = anillos
	var arr := s.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var normales := xf.basis.inverse().transposed()
	for i in idx:
		st.set_color(color)
		st.set_normal((normales * n[i]).normalized())
		st.add_vertex(xf * v[i])


func _crear_bandada(c: Vector3, n: int) -> Dictionary:
	var centro := Vector3(c.x, r.altura(c.x, c.z), c.z)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _malla_ave()
	mm.instance_count = n
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Bandada"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mmi.material_override = mat
	add_child(mmi)
	var aves: Array = []
	for k in n:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(0.2, 1.3)
		var q := centro + Vector3(cos(a) * d, 0.0, sin(a) * d)
		q.y = r.altura(q.x, q.z)
		aves.append({"base": q, "giro": _rng.randf() * TAU, "fase": _rng.randf() * 10.0, "vel": Vector3.ZERO, "pos": q})
	var b := {"centro": centro, "mm": mm, "mmi": mmi, "aves": aves, "estado": "posadas", "t": 0.0}
	_dibujar_posadas(b)
	return b


func _animar_bandada(b: Dictionary, kp: Vector3, delta: float) -> void:
	var dist: float = r._dist_plana(kp, b["centro"])
	match b["estado"]:
		"posadas":
			if dist < SUSTO and not r.cinematica:
				_asustar(b, kp)
			elif dist < 30.0:                           # lejos no se ve: no se anima
				_dibujar_posadas(b)
		"vuelo":
			b["t"] += delta
			for k in b["aves"].size():
				var a: Dictionary = b["aves"][k]
				a["vel"].y = minf(a["vel"].y + 2.4 * delta, 4.5)   # suben cada vez más
				a["pos"] += a["vel"] * delta
				var aleteo: float = 1.0 + 0.7 * sin((_t + a["fase"]) * 38.0)
				var mira: Basis = Basis.looking_at(-a["vel"].normalized() if a["vel"].length() > 0.01 else Vector3.FORWARD)
				b["mm"].set_instance_transform(k, Transform3D(mira * Basis.from_scale(Vector3(aleteo, 1.0 / aleteo, 1.0)), a["pos"]))
			if b["t"] >= VUELO:
				b["estado"] = "fuera"
				b["t"] = VUELTA
				b["mmi"].visible = false
		"fuera":
			b["t"] -= delta
			if b["t"] <= 0.0 and dist > VUELTA_LEJOS:
				b["estado"] = "bajando"
				b["t"] = 0.0
				b["mmi"].visible = true
		"bajando":
			b["t"] += delta
			var k2: float = clampf(b["t"] / BAJADA, 0.0, 1.0)
			for k in b["aves"].size():
				var a: Dictionary = b["aves"][k]
				var alto := (1.0 - k2) * (1.0 - k2) * 2.2
				var aleteo: float = 1.0 + 0.5 * sin((_t + a["fase"]) * 30.0) * (1.0 - k2)
				var p: Vector3 = a["base"] + Vector3(0, alto, 0)
				b["mm"].set_instance_transform(k, Transform3D(Basis(Vector3.UP, a["giro"]) * Basis.from_scale(Vector3(aleteo, 1.0, 1.0)), p))
			if k2 >= 1.0:
				b["estado"] = "posadas"
				b["mmi"].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # posadas, sin sombra (ahorra)
			elif dist < SUSTO:
				_asustar(b, kp)


# Posadas: picotean (se agachan un poco a ratos) y se giran de vez en cuando.
func _dibujar_posadas(b: Dictionary) -> void:
	for k in b["aves"].size():
		var a: Dictionary = b["aves"][k]
		var f: float = _t * 1.3 + a["fase"]
		var pica := maxf(0.0, sin(f * 2.7)) * 0.35
		var giro: float = a["giro"] + 0.4 * sin(f * 0.37)
		var bas := Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, pica)
		b["mm"].set_instance_transform(k, Transform3D(bas, a["base"]))


func _asustar(b: Dictionary, kp: Vector3) -> void:
	b["mmi"].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON   # en el aire, la sombra dice a qué altura van
	b["estado"] = "vuelo"
	b["t"] = 0.0
	aves_asustadas += 1
	var lejos := Vector3(b["centro"].x - kp.x, 0.0, b["centro"].z - kp.z).normalized()
	if lejos.length() < 0.1:
		lejos = Vector3.FORWARD
	for a in b["aves"]:
		var dir: Vector3 = lejos.rotated(Vector3.UP, _rng.randf_range(-0.7, 0.7))
		a["vel"] = dir * _rng.randf_range(3.0, 4.6) + Vector3(0, _rng.randf_range(2.2, 3.2), 0)   # un salto y arriba
		a["pos"] = a["base"]
	Sonido.efecto("rafaga_hierba", {"pos": b["centro"]})
	Sonido.efecto("pajaro", {"pos": b["centro"] + Vector3(0, 1.5, 0), "retraso": 0.12})


# ================================================================= ayudas

# Hueco libre cerca de «c», a una distancia del sendero entre «dmin» y «dmax», fuera de lo prohibido.
func _sitio_fuera_del_camino(c: Vector3, dmin: float, dmax: float) -> Vector3:
	for radio in [0.0, 0.6, 1.2, 1.8, 2.4, 3.0]:
		for k in 8:
			var a := TAU * k / 8.0
			var q: Vector3 = c + Vector3(cos(a), 0, sin(a)) * radio
			var ds: float = r._dist_sendero(q)
			if ds < dmin or ds > dmax or r._prohibido(q):
				continue
			q.y = r.altura(q.x, q.z)
			if r._hueco_libre(q, 0.6):
				return q
	return Vector3(c.x, r.altura(c.x, c.z), c.z)


# El comentario de ese momento para quien está ahora en el grupo, un poco después (deja leer el aviso). Si había otro
# comentario en pantalla, se quita: este responde a lo que acaba de hacer el jugador.
func _comentar(momento: String, retraso: float) -> void:
	var variantes: Dictionary = T.COMENTARIOS.get(momento, {})
	var c: Dictionary = variantes.get(presentes(), {})
	if c.is_empty():
		return
	c = c.duplicate(true)
	c["momento"] = "rincon_" + momento
	var a: Array = load("res://grupo.gd").activos()
	if c.has("respuesta") and not a.has(c["respuesta"]["quien"]):
		c.erase("respuesta")
	if not a.has(c["quien"]):
		return
	# con un temporizador y no con await: si la escena se va antes (salir, un combate), la conexión muere con el nodo
	get_tree().create_timer(retraso, false).timeout.connect(_mostrar_comentario.bind(c))


func _mostrar_comentario(c: Dictionary) -> void:
	if not is_instance_valid(r) or r._capa_ui == null or r.ocupado() or r.cinematica or r.saliendo:
		return
	r._quitar_comentarios()
	Comentarios.mostrar(r._capa_ui, c)


func _guardar() -> void:
	r.guardar_posicion()
	P().guardar(r.scene_file_path)
