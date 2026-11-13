extends Node3D
# Los refugios de montaña de las Cumbres de Ciclópea 3D (V12, especialista de mundo, 13/11): la actividad de la región
# (docs/v12/INVENTARIO_MUNDO.md §7). Tres refugios de piedra abandonados junto al camino: abajo, a media subida y cerca
# del altar. En cada uno hay leña seca y un pedernal: «Encender el refugio». Encendido:
#   - es un sitio de descanso: «Descansar junto al fuego» cura al grupo (grupo.gd, curar_todos) y guarda la partida;
#   - es un faro en la ventisca: su fuego se ve de lejos y a su lado se está al abrigo (ventisca.gd, «abrigo»);
#   - con el de abajo y el de arriba encendidos, se abre el atajo de bajada: «Bajar por el atajo» del refugio de arriba
#     lleva al de abajo (y al revés: «Subir por el atajo»).
# Recompensas modestas (sin Orbes Cristalinos): una Poción al encender cada uno y 120 monedas al tener los tres. Se
# guarda en los hitos de la partida («cc_refugio_1…3» y «cc_refugios»), y una partida antigua sin ellos empieza a oscuras.

const T := preload("res://zonas3d/ciclopea/trazado.gd")
const D := preload("res://zonas3d/ciclopea/disposicion_2d.gd")
const Progreso := preload("res://progreso.gd")
const RADIO := 2.3                       # m a la puerta para el botón
const ABRIGO := 5.0                      # m alrededor de un refugio encendido donde la ventisca apenas se nota
const PREMIO_TODOS := 120
# Dónde está cada uno: un punto del camino principal (fracción del recorrido) y a qué lado, en casillas. sitios() busca
# junto a él un hueco sin pinos, rocas, agua ni pared (siempre el mismo).
const PLAN := [[0.12, 1.0], [0.52, -1.0], [0.9, 1.0]]
const NOMBRES := ["el refugio del paso", "el refugio de media ladera", "el refugio de la cumbre"]

var r: Node3D
var escenario
var perfil := "medio"
var encendidos: Array = [false, false, false]
var fuegos: Array = []                   # Node3D del fuego de cada uno (oculto mientras está apagado)
var luces: Array = []


static func hito(i: int) -> String:
	return "cc_refugio_%d" % (i + 1)


static var _sitios: Array = []


# [casilla del centro del refugio, dirección hacia el camino (casillas, normalizada)] de cada uno.
static func sitios() -> Array:
	if not _sitios.is_empty():
		return _sitios
	var cam: Array = D.CAMINOS[0]
	var largo := 0.0
	for i in cam.size() - 1:
		largo += (cam[i] as Vector2).distance_to(cam[i + 1])
	for pl in PLAN:
		var objetivo: float = largo * pl[0]
		var acum := 0.0
		var punto: Vector2 = cam[0]
		var dir := Vector2.UP
		for i in cam.size() - 1:
			var a: Vector2 = cam[i]
			var b: Vector2 = cam[i + 1]
			var l := a.distance_to(b)
			if acum + l >= objetivo:
				punto = a.lerp(b, (objetivo - acum) / l)
				dir = (b - a).normalized()
				break
			acum += l
		var lado: Vector2 = dir.orthogonal() * float(pl[1])
		# la casilla libre más cercana al punto del camino, a 3,2-5,2 casillas de él y mejor del lado previsto
		var mejor := Vector2.INF
		var nota := INF
		for dx in range(-16, 17):
			for dy in range(-16, 17):
				var c: Vector2 = punto + Vector2(dx, dy) * 0.5
				var dc: float = T.dist_caminos(c)
				if dc < 3.2 or dc > 5.2 or not _libre(c):
					continue
				var s: float = c.distance_to(punto) + (0.0 if (c - punto).dot(lado) > 0.0 else 3.0)
				if s < nota:
					nota = s
					mejor = c
		if mejor != Vector2.INF:
			_sitios.append([mejor, (T.punto_en_camino(mejor) - mejor).normalized()])
		else:
			_sitios.append([punto + lado * 3.6, -lado])
	return _sitios


static func _libre(c: Vector2) -> bool:
	if T.muro(c) or T.agua(c) > 0.05 or T.dist_caminos(c) < 2.6 or c.y > T.ENTRADA_2D.y - 2.0:
		return false
	for o in D.OBJETOS:
		if (o[1] as Vector2).distance_to(c) < 2.4:
			return false
	for cf in D.COFRES:
		if (cf[1] as Vector2).distance_to(c) < 3.0:
			return false
	for l in D.LUGARES:
		if (l[1] as Vector2).distance_to(c) < 4.0:
			return false
	return c.distance_to(D.META) > 5.0


static func cerca_de_refugio(c: Vector2, radio: float) -> bool:
	for s in sitios():
		if (s[0] as Vector2).distance_to(c) < radio:
			return true
	return false


static func crear(region: Node3D, escenario_, perfil_: String) -> Node3D:
	var n: Node3D = load("res://zonas3d/ciclopea/refugios.gd").new()
	n.name = "Refugios"
	n.r = region
	n.escenario = escenario_
	n.perfil = perfil_
	region.add_child(n)
	n._montar()
	return n


func _montar() -> void:
	var s := sitios()
	for i in s.size():
		encendidos[i] = Progreso.hito(hito(i))
		_construir(i, s[i][0], s[i][1])


# La puerta (donde se pulsa): delante del refugio, hacia el camino.
func puerta(i: int) -> Vector3:
	var s: Array = sitios()[i]
	return T.en_mundo((s[0] as Vector2) + (s[1] as Vector2) * 1.9)


func _construir(i: int, c: Vector2, hacia: Vector2) -> void:
	var p := T.en_mundo(c)
	var nodo := Node3D.new()
	nodo.name = "Refugio%d" % (i + 1)
	nodo.position = p
	nodo.rotation.y = atan2(hacia.x, hacia.y)               # la boca, hacia el camino (+z local)
	add_child(nodo)
	var piedra: StandardMaterial3D = escenario.mat_detalle(Color(0.52, 0.53, 0.57), 1.2, false, 1.0)
	var nieve: StandardMaterial3D = escenario.mat_detalle(Color(0.95, 0.97, 1.0), 0.6)
	var madera: StandardMaterial3D = escenario.mat_detalle(Color(0.40, 0.29, 0.20), 1.4, false, 0.8)
	var juntas := {}
	var poner := func(malla: Mesh, t: Transform3D, mat: Material) -> void:
		if not juntas.has(mat):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			juntas[mat] = st
		juntas[mat].append_from(malla, 0, t)
	# tres muros de piedra (atrás y a los lados; la boca, abierta al camino) y un tejado de losas con nieve
	poner.call(_caja(Vector3(3.0, 1.7, 0.4)), Transform3D(Basis(), Vector3(0, 0.85, -1.1)), piedra)
	for l in [-1.0, 1.0]:
		poner.call(_caja(Vector3(0.4, 1.7, 2.4)), Transform3D(Basis(), Vector3(1.3 * l, 0.85, -0.1)), piedra)
	poner.call(_caja(Vector3(3.4, 0.22, 2.9)), Transform3D(Basis(Vector3(1, 0, 0), -0.12), Vector3(0, 1.85, -0.1)), piedra)
	poner.call(_caja(Vector3(3.3, 0.14, 2.7)), Transform3D(Basis(Vector3(1, 0, 0), -0.12), Vector3(0, 2.0, -0.12)), nieve)
	# el hogar: un cerco de piedras y la leña
	for k in 7:
		var a := k * TAU / 7.0
		poner.call(_caja(Vector3(0.2, 0.16, 0.2)), Transform3D(Basis(Vector3.UP, a), Vector3(cos(a) * 0.42, 0.08, -0.35 + sin(a) * 0.42)), piedra)
	for k in 3:
		var tr := Transform3D(Basis(Vector3.UP, k * 1.05) * Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(0, 0.12, -0.35))
		poner.call(_cilindro(0.06, 0.06, 0.7, 6), tr, madera)
	# un poyo de piedra para sentarse
	poner.call(_caja(Vector3(1.2, 0.4, 0.45)), Transform3D(Basis(), Vector3(0.6, 0.2, -0.75)), piedra)
	for mat in juntas:
		var mi := MeshInstance3D.new()
		mi.mesh = juntas[mat].commit()
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if escenario.perfil.get("sombras", false) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nodo.add_child(mi)
	# choques: los muros y el hogar (la boca se queda libre)
	var b := Basis(Vector3.UP, nodo.rotation.y)
	for q in [Vector3(-1.0, 0, -1.1), Vector3(0, 0, -1.1), Vector3(1.0, 0, -1.1), Vector3(-1.3, 0, -0.5), Vector3(1.3, 0, -0.5),
			Vector3(-1.3, 0, 0.5), Vector3(1.3, 0, 0.5), Vector3(0, 0, -0.35)]:
		var w: Vector3 = p + b * q
		escenario.obstaculo(w.x, w.z, 0.42)
	# el fuego (oculto mientras está apagado): llamas sin sombra y su luz (real en alto, halo pintado en bajo y medio)
	var fuego := Node3D.new()
	fuego.name = "Fuego"
	fuego.position = Vector3(0, 0.12, -0.35)
	nodo.add_child(fuego)
	var llama := StandardMaterial3D.new()
	llama.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	llama.albedo_color = Color(1.0, 0.62, 0.22)
	var llama2 := StandardMaterial3D.new()
	llama2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	llama2.albedo_color = Color(1.0, 0.88, 0.45)
	for k in 3:
		var mi := MeshInstance3D.new()
		mi.mesh = _cono(0.18 - 0.04 * k, 0.55 - 0.1 * k)
		mi.material_override = llama if k == 0 else llama2
		mi.position = Vector3(0.06 * (k - 1), 0.28 - 0.04 * k, 0.03 * k)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fuego.add_child(mi)
	var halo := Sprite3D.new()                               # el faro: se ve de lejos en la ventisca
	halo.texture = escenario._tex_brillo()
	halo.pixel_size = 3.2 / 64.0
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	halo.shaded = false
	halo.transparent = true
	halo.modulate = Color(1.0, 0.7, 0.35, 0.65)
	halo.position = Vector3(0, 0.6, 0)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fuego.add_child(halo)
	fuego.visible = encendidos[i]
	fuegos.append(fuego)
	if escenario.perfil.get("luces_faroles", false):
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.64, 0.32)
		l.light_energy = 1.5
		l.omni_range = 6.0
		l.position = Vector3(0, 0.9, -0.35)
		l.visible = encendidos[i]
		nodo.add_child(l)
		luces.append(l)
	else:
		luces.append(null)


func _caja(tam: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = tam
	return bm


func _cilindro(a: float, b: float, alto: float, lados: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = a
	c.bottom_radius = b
	c.height = alto
	c.radial_segments = lados
	c.rings = 1
	return c


func _cono(radio: float, alto: float) -> CylinderMesh:
	var c := _cilindro(0.0, radio, alto, 6)
	return c


# ================================================================= lo que se usa (lo pide la región)

func todos() -> bool:
	return not encendidos.has(false)


func atajo_abierto() -> bool:
	return encendidos[0] and encendidos[2]


# [id, sitio, radio, texto]
func piezas() -> Array:
	var lista: Array = []
	for i in fuegos.size():
		var texto := "Descansar junto al fuego" if encendidos[i] else "Encender el refugio"
		lista.append(["refugio:%d" % i, puerta(i), RADIO, texto])
	if atajo_abierto():                                     # el atajo, un paso a un lado de la puerta
		var arriba := puerta(2) + (puerta(2) - T.en_mundo(sitios()[2][0])).normalized().cross(Vector3.UP) * 1.6
		var abajo := puerta(0) + (puerta(0) - T.en_mundo(sitios()[0][0])).normalized().cross(Vector3.UP) * 1.6
		lista.append(["atajo:bajar", arriba, 1.4, "Bajar por el atajo"])
		lista.append(["atajo:subir", abajo, 1.4, "Subir por el atajo"])
	return lista


func atiende(id: String) -> bool:
	return id.begins_with("refugio:") or id.begins_with("atajo:")


# Devuelve los avisos que hay que enseñar y, si toca, adónde llevar a Kael («destino»).
func accion(id: String) -> Dictionary:
	if id.begins_with("atajo:"):
		var a: Array = sitios()[0] if id == "atajo:bajar" else sitios()[2]
		return {"avisos": ["Por el atajo, entre las rocas, hasta %s." % (NOMBRES[0] if id == "atajo:bajar" else NOMBRES[2])],
			"destino": T.en_mundo((a[0] as Vector2) + (a[1] as Vector2) * 2.6), "guardar": true}
	var i := int(id.trim_prefix("refugio:"))
	if encendidos[i]:
		load("res://grupo.gd").curar_todos()
		return {"avisos": ["Junto al fuego, el grupo recupera fuerzas."], "guardar": true, "curar": true}
	encendidos[i] = true
	Progreso.poner_hito(hito(i))
	fuegos[i].visible = true
	if luces[i] != null:
		luces[i].visible = true
	var inv = load("res://inventario.gd")
	inv.agregar_objeto("Poción", 1)
	var avisos: Array = ["Leña seca y un pedernal en la repisa: %s vuelve a tener fuego." % NOMBRES[i], "Has encontrado 1 Poción."]
	if todos() and not Progreso.hito("cc_refugios"):
		Progreso.poner_hito("cc_refugios")
		inv.ganar_oro(PREMIO_TODOS)
		avisos.append("Los tres refugios arden: la subida ya tiene sus faros. (+%d monedas)" % PREMIO_TODOS)
	elif atajo_abierto():
		avisos.append("Con los refugios de abajo y de arriba encendidos, el atajo de bajada se puede usar.")
	return {"avisos": avisos, "guardar": true, "encendido": i}


# Cuánto abrigo tiene Kael en p (0 a la intemperie, 1 junto a un refugio encendido).
func abrigo_en(p: Vector3) -> float:
	var mejor := 0.0
	for i in fuegos.size():
		if not encendidos[i]:
			continue
		var q := T.en_mundo(sitios()[i][0])
		var d := Vector2(p.x - q.x, p.z - q.z).length()
		mejor = maxf(mejor, 1.0 - smoothstep(ABRIGO * 0.5, ABRIGO, d))
	return mejor


func animar(t: float) -> void:
	for i in fuegos.size():
		if encendidos[i]:
			var f: Node3D = fuegos[i]
			f.scale = Vector3(1.0, 0.85 + 0.2 * sin(t * 9.0 + i) * sin(t * 5.3), 1.0)
