extends SceneTree
# V12 (14/11, fase 7): la PROPUESTA «Las tres marcas del cantero» y la losa del cantero (ciudades/oakhaven_propuestas.gd;
# interruptor «oakhaven_propuestas_v12», APAGADO), con datos aislados y su propia partida.
# Sin «3d» (lista: prueba_oakhaven_propuestas):
#   1. Apagada no cambia nada: las mismas piezas, sin losa, las señales no hacen nada, el arcón no da la nota y la misión
#      no sale en el Diario aunque el arcón esté abierto.
#   2. Encendida, los datos: cuatro piezas en sitios pisables y a 2,5 casillas o más de todo lo que se examina; textos
#      sin nada reservado (D-033, D-073); la losa siempre tiene solución y su combinación es la que se deduce de las
#      marcas (ordenadas por sus muescas: Rayo, Agua, Luna), que no sale escrita en ningún texto.
#   3. Encendida, la misión entera: el arcón da la nota y empieza; cada marca, una vez, al Diario (pista) y con las tres
#      el paso siguiente; la losa da su premio UNA vez y la misión acaba; guardar y cargar; partida antigua.
#   4. En la ciudad 2D (encendida): «Examinar la marca» apunta la marca; «Girar los anillos» en la losa abre su cerradura
#      (la de la losa, no la del arcón) y resolverla la abre.
# Con «3d» (lista: prueba_oakhaven_propuestas_3d):
#   5. Oakhaven 3D apagada: nada nuevo. Encendida: las cuatro piezas con su botón y alcanzables, la losa en el suelo, una
#      marca se apunta y la losa se abre con su cerradura.
# Imprime «FALLOS: n».

const ARCHIVO := "user://prueba_oakhaven_propuestas.save"
const T := 64.0
const INTERRUPTOR := "oakhaven_propuestas_v12"
const LOSA := "oak_losa_cantero"
const MARCAS := ["oak_marca_torre", "oak_marca_fuente", "oak_marca_raiz"]
const PROHIBIDO := ["erebo", "corazon", "olvido", "rocio", "cripta", "trampilla", "conclave", "hermano", "recuerd"]
var Oak
var Prop
var P
var Inv
var E
var C
var fallos := 0


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	Oak = load("res://ciudades/oakhaven.gd")
	Prop = load("res://ciudades/oakhaven_propuestas.gd")
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	E = load("res://encargos.gd")
	C = load("res://cerradura_runica.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "oak_franja", "oak_franja_t", "pos_3d", "pos_zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("pos_zona_ok", false)


func _probar() -> void:
	await _esperar(3)
	_limpiar()
	if "3d" in OS.get_cmdline_user_args():
		await _en_3d()
	else:
		_apagada()
		_datos()
		_mision()
		await _ciudad()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _plano(t: String) -> String:
	var p := t.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"]]:
		p = p.replace(par[0], par[1])
	return p


# 1. Apagada.
func _apagada() -> void:
	Engine.set_meta(INTERRUPTOR, false)
	_ok(Oak.piezas_activas() == Oak.PIEZAS and Oak.pieza(LOSA).is_empty() and Oak.config_cerradura(LOSA).is_empty(),
		"1: apagada, hay piezas o cerradura nuevas")
	_ok(Oak.aplicar_senal("oak:cantero_marca_1") == "" and not P.estado(Oak.NOMBRE, "cantero_marca_1"),
		"1: apagada, una marca se apunta")
	var t: String = Oak.abrir_cerradura()
	_ok(t.begins_with("Dentro del arcón") and not t.contains("cantero"), "1: apagada, el arcón da la nota («%s»)" % t)
	_ok(E.estado(E.de("prop_cantero")) == "oculto", "1: apagada, la misión sale en el Diario")
	_ok(Oak.abrir_cerradura(LOSA) == "", "1: apagada, la losa se abre")
	_limpiar()


# 2. Los datos.
func _datos() -> void:
	Engine.set_meta(INTERRUPTOR, true)
	var nuevas: Array = Prop.PIEZAS
	_ok(nuevas.size() == 4 and Oak.piezas_activas().size() == Oak.PIEZAS.size() + 4, "2: encendida, no salen las cuatro piezas")
	var puntos: Array = []
	for lista in [Oak.NPCS, Oak.COFRES, Oak.PIEZAS, Oak.NOTAS]:
		for d in lista:
			if d.has("casilla"):
				puntos.append([d["id"], d["casilla"]])
	for id in Oak.SITIOS_DETALLE:
		puntos.append([id, Oak.SITIOS_DETALLE[id]])
	for p in nuevas:
		var c: Vector2 = p["casilla"]
		var pisable := false
		var choca := false
		for l in Oak.LUGARES:
			if (l["rect"] as Rect2).has_point(c):
				pisable = pisable or l["pisable"]
				choca = choca or not l["pisable"]
		_ok(pisable and not choca, "2: %s en %s no está en un sitio pisable" % [p["id"], c])
		for q in puntos:
			_ok(c.distance_to(q[1]) >= 2.5, "2: %s a %.1f de %s" % [p["id"], c.distance_to(q[1]), q[0]])
		puntos.append([p["id"], c])
		_ok(Oak.error_condicion(p["si"]) == "", "2: condición mal en %s" % p["id"])
		for k in ["texto", "texto_sin"]:
			for x in PROHIBIDO:
				_ok(not _plano(str(p[k])).contains(x), "2: «%s» en %s de %s" % [x, k, p["id"]])
	var textos: String = Prop.NOTA + " " + Prop.CERRADURA["inscripcion"]
	for m in Prop.MISIONES:
		textos += " " + m["resumen"] + " " + m["pago"]
		for x in m["pistas"]:
			textos += " " + x["texto"]
	for x in PROHIBIDO:
		_ok(not _plano(textos).contains(x), "2: «%s» en los textos de la propuesta" % x)
	# la deducción: las marcas, ordenadas por sus muescas, dan la combinación; ningún texto la da hecha
	var orden := {"una sola muesca": 1, "dos muescas": 2, "tres muescas": 3}
	var por_muescas := []
	for id in MARCAS:
		var t: String = Oak.pieza(id)["texto"]
		for k in orden:
			if t.to_lower().contains(k):
				for s in ["Rayo", "Agua", "Luna", "Fuego", "Cura", "Runa"]:
					if t.contains("runa de " + s):
						por_muescas.append([orden[k], s])
	por_muescas.sort_custom(func(a, b): return a[0] < b[0])
	_ok(por_muescas.map(func(x): return x[1]) == Prop.CERRADURA["objetivo"],
		"2: las marcas no dan la combinación de la losa (%s frente a %s)" % [por_muescas, Prop.CERRADURA["objetivo"]])
	_ok(not textos.contains("Rayo, Agua") and not textos.contains("Rayo, agua"), "2: un texto da la combinación hecha")
	var cfg: Dictionary = Prop.CERRADURA
	_ok(not C.resuelta_en(cfg, cfg["inicio"]), "2: la losa empieza resuelta")
	for a in 6:
		for b in 6:
			for c in 6:
				var x: Array = [a, b, c]
				for paso in C.solucion(cfg, x):
					x = C.girar_en(cfg, x, paso[0], paso[1])
				_ok(C.resuelta_en(cfg, x), "2: la losa no tiene solución desde %s" % [[a, b, c]])


# 3. La misión entera.
func _mision() -> void:
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	var mis: Dictionary = E.de("prop_cantero")
	_ok(E.estado(mis) == "oculto", "3: la misión sale antes de abrir el arcón")
	var t: String = Oak.abrir_cerradura()
	_ok(t.contains(Prop.NOTA), "3: el arcón no da la nota del cantero («%s»)" % t)
	_ok(E.estado(mis) == "activo" and E.paso_actual(mis).get("id", "") == "marcas", "3: la nota no empieza la misión")
	var pistas0: int = E.pistas_conocidas(mis).size()
	for i in MARCAS.size():
		var p: Dictionary = Oak.pieza(MARCAS[i])
		var aviso: String = Oak.aplicar_senal(p["senal"])
		_ok(aviso.contains("(%d de 3)" % (i + 1)), "3: la marca %s no se apunta («%s»)" % [MARCAS[i], aviso])
		_ok(Oak.aplicar_senal(p["senal"]) == "", "3: la marca %s se apunta dos veces" % MARCAS[i])
		_ok(E.pistas_conocidas(mis).size() == pistas0 + i + 1, "3: el Diario no apunta la marca %s" % MARCAS[i])
	_ok(E.paso_actual(mis).get("id", "") == "losa", "3: con las tres marcas no se pasa a la losa")
	var oro0: int = Inv.oro()
	var incienso0: int = Inv.cantidad("Incienso de Ceniza")
	Oak.ver_cerradura(LOSA)
	t = Oak.abrir_cerradura(LOSA)
	_ok(t.begins_with("Bajo la losa") and Inv.oro() == oro0 + 80 and Inv.cantidad("Incienso de Ceniza") == incienso0 + 1,
		"3: la losa no da su premio («%s»)" % t)
	_ok(Oak.abrir_cerradura(LOSA) == "" and Inv.oro() == oro0 + 80, "3: la losa da el premio dos veces")
	_ok(E.estado(mis) == "hecho" and Oak.cerradura_abierta() and Oak.cerradura_abierta(LOSA), "3: la misión no acaba")
	# guardar y cargar, y partida antigua
	var d: Dictionary = P.volcar("res://mapa.tscn")
	_ok(P.escribir(d, ARCHIVO), "3: no se pudo escribir la partida")
	_limpiar()
	var leida = P.leer(ARCHIVO)
	if leida is Dictionary:
		P.restaurar(leida)
	_ok(E.estado(mis) == "hecho" and Oak.abrir_cerradura(LOSA) == "", "3: tras cargar, la losa no sigue abierta")
	var vieja: Dictionary = (leida as Dictionary).duplicate(true) if leida is Dictionary else {}
	vieja.erase("mazmorras")
	P.restaurar(vieja)
	_ok(E.estado(mis) == "oculto" and not Oak.cerradura_abierta(LOSA), "3: una partida antigua no empieza de cero")
	_limpiar()


func _dar_con(z, id: String) -> Array:
	for e in z.piezas:
		if e[1]["id"] == id:
			return e
	return []


# 4. En la ciudad 2D, encendida.
func _ciudad() -> void:
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad"})
	var marca: Vector2 = Oak.pieza("oak_marca_fuente")["casilla"]
	Engine.set_meta("pos_zona", (marca + Vector2(0, 0.6)) * T)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	change_scene_to_file("res://ciudad_oakhaven.tscn")
	await _esperar(40)
	var z = current_scene
	if z == null or not z.has_method("_abrir_cerradura"):
		_ok(false, "4: no se cargó la ciudad 2D")
		return
	_ok(_dar_con(z, LOSA).size() == 3 and _dar_con(z, "oak_marca_raiz").size() == 3, "4: la ciudad no pone las piezas nuevas")
	_ok(z.boton_examinar.text == "Examinar la marca", "4: junto a la fuente no se ofrece la marca («%s»)" % z.boton_examinar.text)
	z._accion()
	await _esperar(2)
	_ok(P.estado(Oak.NOMBRE, "cantero_marca_2"), "4: examinar la marca no la apunta")
	var losa: Array = _dar_con(z, LOSA)
	z.jugador.position = losa[2] + Vector2(0, 0.6 * T)
	await _esperar(4)
	_ok(z.boton_examinar.text == "Girar los anillos", "4: junto a la losa no se ofrece girar («%s»)" % z.boton_examinar.text)
	z._accion()
	await _esperar(3)
	var m = z.cerradura_abierta
	_ok(m != null and m.config.get("id", "") == LOSA, "4: la losa no abre su propia cerradura")
	if m == null:
		return
	for p in C.solucion(m.config, m.giros):
		m.girar(p[0], p[1])
	m.cerrar_menu()
	await _esperar(4)
	_ok(Oak.cerradura_abierta(LOSA) and not Oak.cerradura_abierta(), "4: resolver la losa no la abre (o abre el arcón)")


# 5. Oakhaven 3D.
func _alcanzable(v, p: Vector3, radio: float) -> bool:
	for k in 24:
		var q: Vector3 = p + Vector3(cos(k * TAU / 8.0), 0, sin(k * TAU / 8.0)) * (0.5 + 0.35 * (k / 8))
		q.y = p.y
		if not v._prohibido(q) and Vector2(q.x - p.x, q.z - p.z).length() < radio:
			return true
	return false


func _en_3d() -> void:
	Engine.set_meta(INTERRUPTOR, false)
	Engine.set_meta("partida_lista", true)
	change_scene_to_file("res://zonas3d/oakhaven_3d.tscn")
	await _esperar(25)
	var v = current_scene
	if v == null or v.get("vida") == null:
		_ok(false, "5: no se cargó Oakhaven 3D")
		return
	var ids: Array = v.vida.piezas().map(func(x): return x[0])
	_ok(not ("pieza:" + LOSA) in ids and not v.vida.arcon.has("losa"), "5: apagada, la 3D pone la losa")
	Engine.set_meta(INTERRUPTOR, true)
	change_scene_to_file("res://zonas3d/oakhaven_3d.tscn")
	await _esperar(25)
	v = current_scene
	var vida = v.vida
	_ok(vida.arcon.has("losa"), "5: encendida, no está la losa en el suelo")
	for pz in vida.piezas():
		var id := String(pz[0]).trim_prefix("pieza:")
		if not Oak.pieza(id).is_empty() and Prop.PIEZAS.any(func(p): return p["id"] == id):
			_ok(_alcanzable(v, pz[1], pz[2]), "5: %s no se alcanza" % id)
			ids.append(id)
	for p in Prop.PIEZAS:
		_ok(vida.piezas().any(func(x): return x[0] == "pieza:" + p["id"]), "5: la 3D no ofrece %s" % p["id"])
	vida.usar_pieza("oak_marca_torre")
	await _esperar(2)
	_ok(P.estado(Oak.NOMBRE, "cantero_marca_1") and vida.ultimo_aviso.contains("Marca del cantero (1 de 3)"),
		"5: la marca de la torre no se apunta («%s»)" % vida.ultimo_aviso)
	vida.usar_pieza(LOSA)
	await _esperar(3)
	var m = vida.abierto
	_ok(m != null and m.config.get("id", "") == LOSA and v.ocupado(), "5: la losa no abre su cerradura en 3D")
	if m == null:
		return
	for p in C.solucion(m.config, m.giros):
		m.girar(p[0], p[1])
	m.cerrar_menu()
	await _esperar(3)
	_ok(Oak.cerradura_abierta(LOSA) and vida.abierto == null, "5: resolver la losa en 3D no la abre")
	var ofrece := ""
	for pz in vida.piezas():
		if pz[0] == "pieza:" + LOSA:
			ofrece = pz[3]
	_ok(ofrece == "Examinar", "5: abierta, la losa no pasa a «Examinar» («%s»)" % ofrece)
