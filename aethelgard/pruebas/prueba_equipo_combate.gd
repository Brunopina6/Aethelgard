extends SceneTree
# C1 (T-092) enganchado: la ranura Accesorio en un combate de verdad (combate.tscn), la tienda por lugar y los libros de
# las artes (T-091) en la tienda. Con datos aislados y su propio archivo de partida; el combate no guarda (sin
# «desde_mapa»). Ganar o huir así no prueba la estrategia de un jugador: solo que los enganches funcionan.
#   F. Farol de peregrino (Kael solo): empieza con 35 de barra (nunca 100: entra en la cola por el camino normal); sus
#      atributos no cambian; quien no lleva nada nuevo, sin efectos.
#   G. Gota de la cascada alta (Kael) y Cinta de Lumi (Lya): Kael recupera 2 PM al acabar su turno; Lya, un 5 % de sus
#      PV al empezar el suyo.
#   M. Moneda del Águila (Kael): al ganar a un Grimfang (18 monedas), 23 (+25 %, una vez), y el cartel lo dice.
#   P. Pluma de arpía (Kael), con la esquiva forzada al 100 % solo en esta prueba: los golpes no le quitan PV.
#   D. Diente de Grimfang (Kael): el umbral del crítico pasa de 0,12 a 0,20 (la misma tirada).
#   T. Tienda: el Farol en Oakhaven (220), la Moneda en Sunken City (450) y ninguno en el Gran Bosque Verde; comprar el
#      Farol lo apunta una vez; los libros de Peso del Ocaso (350) y de Segundo Aliento (450) se venden, dicen para quién
#      son y enseñan el arte (que sale ya en el combate); lo que aún no está en el juego (Lágrima, Escarcha) no se vende.

const ARCHIVO := "user://prueba_equipo_combate.save"
const MAX_FOTOGRAMAS := 5400                     # 180 s de juego por combate como mucho

var P
var G
var I
var X
var A
var c = null
var frames := 0
var f_inicio := 0
var f_fin := -1
var escenario := ""
var pendientes := ["F", "G", "M", "P", "D"]
var fallos: Array = []
var hechos: Array = []
var espera := 0
var datos := {}
var carteles: Array = []
var pv_antes := {}


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	X = load("res://equipo_extra.gd")
	A = load("res://artes.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append("%s: %s" % [escenario, texto])


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _equipar(heroe: String, id: String) -> void:
	I.agregar(id)
	_ok(I.equipar(heroe, X.RANURA, id), "no se puede equipar %s a %s en la ranura Accesorio" % [id, heroe])


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _empezar(e: String) -> void:
	escenario = e
	f_fin = -1
	datos.clear()
	carteles.clear()
	pv_antes.clear()
	_limpiar()
	G.datos()
	I.datos()
	var activos: Array = ["Kael", "Lya"] if e == "G" else ["Kael"]
	Engine.set_meta("grupo_activo", activos)
	for n in activos:
		G.datos()[n]["nivel"] = 5
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	var antes: Dictionary = G.estadisticas("Kael")
	match e:
		"F":
			_equipar("Kael", "farol_peregrino")
		"G":
			_equipar("Kael", "gota_cascada")
			_equipar("Lya", "cinta_lumi")
		"M":
			_equipar("Kael", "moneda_aguila")
		"P":
			_equipar("Kael", "pluma_arpia")
		"D":
			_equipar("Kael", "diente_grimfang")
	_ok(var_to_str(G.estadisticas("Kael")) == var_to_str(antes), "el accesorio cambia los atributos de Kael")
	Engine.set_meta("zona", "desierto")          # sin «zona limpia»: los enemigos no huyen solos
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 9)          # un Grimfang (agresivo: no huye)
	datos["oro"] = I.oro()
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(20261109)                                # como la huella: después de _ready
	for en in c.enemigos:
		en["atb"] = randf() * 30.0
	f_inicio = frames
	var kael := _heroe("Kael")
	match e:
		"F":
			_ok(kael.get("efectos", {}) == {"atb_inicio": 35.0}, "efectos del Farol: %s" % [kael.get("efectos", {})])
			_ok(is_equal_approx(float(kael["atb"]), 35.0) and not c.cola.any(func(x): return is_same(x, kael)),
				"Kael no empieza con 35 de barra fuera de la cola (%.2f)" % kael["atb"])
		"G":
			kael["mp"] = kael["mp_max"] - 5
			var lya := _heroe("Lya")
			lya["hp"] = int(lya["hp_max"] * 0.5)
			_ok(lya.get("efectos", {}) == {"regen": 0.05}, "efectos de la Cinta: %s" % [lya.get("efectos", {})])
			_ok(kael.get("efectos", {}) == {"pm_turno": 2.0}, "efectos de la Gota: %s" % [kael.get("efectos", {})])
		"M":
			c.enemigos[0]["hp"] = 1               # el primer golpe gana
		"P":
			_ok(kael.get("efectos", {}) == {"esquiva": 0.12}, "efectos de la Pluma: %s" % [kael.get("efectos", {})])
			kael["efectos"]["esquiva"] = 1.0       # solo en la prueba: siempre esquiva
		"D":
			_ok(kael.get("efectos", {}) == {"critico": 0.08}, "efectos del Diente: %s" % [kael.get("efectos", {})])
			_ok(is_equal_approx(X.prob_critico(c.PROB_CRITICO, kael["efectos"]), 0.20)
				and is_equal_approx(X.prob_critico(c.PROB_CRITICO, {}), c.PROB_CRITICO), "el umbral del crítico no es 0,20")
	for h in c.heroes:                            # quien no lleva nada nuevo: sin efectos (el equipo de hoy no da nada)
		if not (e == "G" and h["nombre"] == "Lya") and h["nombre"] != "Kael":
			_ok(h.get("efectos", {}).is_empty(), "%s tiene efectos sin accesorio: %s" % [h["nombre"], h.get("efectos")])


func _process(_d: float) -> bool:
	frames += 1
	if frames < 10:                               # el paso de --fixed-fps 30 se asienta en los primeros fotogramas
		return false
	if c == null:
		if espera > 0:
			espera -= 1
			return false
		if pendientes.is_empty():
			_tienda()
			_terminar()
			return true
		_empezar(pendientes.pop_front())
		return false
	_vigilar()
	if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
		_turno(c.actor)
	if c.estado == "fin" and f_fin < 0:
		f_fin = frames
	var acabado: bool = f_fin >= 0 and (c.menu.heroe_actual.get("nombre", "") == "Fin" or frames - f_fin > 900)
	if acabado or frames - f_inicio > MAX_FOTOGRAMAS:
		_cerrar()
	return false


func _vigilar() -> void:
	if carteles.is_empty() or carteles.back() != c.registro.text:
		carteles.append(c.registro.text)
	if escenario == "P":
		var kael := _heroe("Kael")
		if kael["hp"] < pv_antes.get("Kael", kael["hp"]):
			datos["herido"] = true
		pv_antes["Kael"] = kael["hp"]


func _turno(h: Dictionary) -> void:
	var n: String = h["nombre"]
	match escenario:
		"F", "D":
			datos["turno"] = true
			c._escapar()
		"G":
			if n == "Lya":
				if not datos.has("cura_lya"):
					var lya := h
					datos["cura_lya"] = true
					var esperada := mini(maxi(1, int(lya["hp_max"] * 0.05)), lya["hp_max"] - int(lya["hp_max"] * 0.5))
					_ok(lya["hp"] == int(lya["hp_max"] * 0.5) + esperada,
						"la Cinta no cura a Lya un 5 %% al empezar su turno (%d de %d)" % [lya["hp"], lya["hp_max"]])
				c._defender()
			else:
				if not datos.has("pm_kael"):
					datos["pm_kael"] = h["mp"]
					c._defender()                # al acabar este turno, +2 PM
				else:
					_ok(datos["pm_kael"] == h["mp_max"] - 5 and h["mp"] == datos["pm_kael"] + 2,
						"la Gota no da 2 PM al acabar el turno (%d → %d)" % [datos["pm_kael"], h["mp"]])
					datos["turno"] = true
					c._escapar()
		"M":
			c._menu_objetivo("atacar", "")
			c._confirmar_objetivo(c.enemigos.filter(func(x): return x["hp"] > 0)[0])
			datos["turno"] = true
		"P":
			datos["turnos_p"] = datos.get("turnos_p", 0) + 1
			if datos["turnos_p"] >= 3:
				datos["turno"] = true
				c._escapar()
			else:
				c._defender()


func _cerrar() -> void:
	_ok(c.estado == "fin", "el combate no terminó (estado %s)" % c.estado)
	_ok(datos.get("turno", false), "no llegó al turno que se comprueba")
	match escenario:
		"G":
			_ok(datos.has("cura_lya"), "Lya no tuvo turno")
		"M":
			var ganado: int = I.oro() - int(datos["oro"])
			_ok(ganado == 23, "la Moneda da %d monedas y no 23 (18 + 25 %%)" % ganado)
			_ok(carteles.any(func(t): return str(t).ends_with("+23 monedas")), "el cartel no dice +23 monedas: %s" % [carteles])
		"P":
			var ataques: int = carteles.filter(func(t): return str(t) == "Grimfang ataca a Kael").size()
			_ok(ataques >= 1, "el Grimfang no atacó a Kael: %s" % [carteles])
			_ok(not datos.get("herido", false), "con la esquiva al 100 %, un golpe le quitó PV a Kael")
	if fallos.filter(func(f): return str(f).begins_with(escenario + ":")).is_empty():
		hechos.append(escenario)
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	espera = 3


# ---------------------------------------------------------------- T. tienda
func _tienda() -> void:
	escenario = "T"
	_limpiar()
	G.datos()
	I.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	I.ganar_oro(5000)
	var lugares := {0: {"farol_peregrino": 220}, 5: {"moneda_aguila": 450}, 1: {}}
	for indice in lugares:
		Engine.set_meta("lugar", {"indice": indice, "nombre": "x", "tipo": "ciudad", "zona": "llanura", "texto": "x"})
		var t = load("res://tienda.gd").new()
		t.pestana = "Equipo"
		root.add_child(t)
		var extra: Dictionary = {}
		var precios: Dictionary = t._precios_equipo()
		for id in precios:
			if X.es_extra(id):
				extra[id] = precios[id]
		_ok(extra == lugares[indice], "la tienda del lugar %d vende %s y no %s" % [indice, extra, lugares[indice]])
		for id in t.EQUIPO:
			_ok(precios.get(id, -1) == t.EQUIPO[id], "la tienda del lugar %d cambia el precio de %s" % [indice, id])
		_ok(not precios.has("lagrima_ambar") and not precios.has("hoja_sin_nombre"), "se vende algo de M3 o C2")
		if indice == 0:
			var oro: int = I.oro()
			t._comprar_equipo("farol_peregrino")
			_ok(I.oro() == oro - 220 and "farol_peregrino" in I.datos()["equipables"], "comprar el Farol no cuesta 220 o no lo da")
			_ok(t.lbl_aviso.text.begins_with("Has comprado Farol de peregrino."), "aviso de compra: %s" % t.lbl_aviso.text)
			var b = root.get_node("Entrada").buscar(t, "comprar:Farol de peregrino")
			_ok(b == null, "tras comprarlo, el Farol se puede volver a comprar")
			_ok(I.opciones("Kael", X.RANURA) == ["farol_peregrino"] and I.opciones("Garon", X.RANURA) == ["farol_peregrino"],
				"el Farol no sale en la ranura Accesorio de Kael y Garon")
		t.queue_free()
	# libros de las artes (pestaña Magias): los de M1 y M2, para quien usa la familia, y enseñan
	G.datos()["Kael"]["nivel"] = 1
	G.datos()["Lya"]["nivel"] = 1
	var t2 = load("res://tienda.gd").new()
	t2.pestana = "Magias"
	root.add_child(t2)
	var filas := {}
	for f in t2.cuerpo.get_children():
		var textos: Array = f.get_children().filter(func(x): return x is Label).map(func(x): return x.text)
		if not textos.is_empty():
			filas[textos[0]] = textos
	var alba = filas.get("Libro de Peso del Ocaso (Alba II)", [])
	var lumbre = filas.get("Libro de Segundo Aliento (Lumbre II)", [])
	_ok(not alba.is_empty() and alba[1] == "Para: Kael" and alba[3] == "350", "fila del libro del Alba: %s" % [alba])
	_ok(not lumbre.is_empty() and lumbre[1] == "Para: Lya" and lumbre[3] == "450", "fila del libro de la Lumbre: %s" % [lumbre])
	_ok(not filas.keys().any(func(k): return str(k).contains("Escarcha") or str(k).contains("Hora Dorada")),
		"se vende un libro que aún no está en el juego: %s" % [filas.keys()])
	_ok(filas.has("Libro de Llamarada (Fuego II)") and filas.size() >= 10, "los libros de siempre no están: %s" % [filas.keys()])
	var oro2: int = I.oro()
	t2._comprar_libro(["Alba", 2, 350])
	_ok(I.oro() == oro2 - 350 and A.nivel("Kael", "Alba") == 2, "el libro no enseña Peso del Ocaso a Kael (nivel %d)" % A.nivel("Kael", "Alba"))
	_ok(t2.lbl_aviso.text == "Kael aprende Peso del Ocaso.", "aviso del libro: %s" % t2.lbl_aviso.text)
	var hechizos: Array = A.hechizos("Kael").map(func(h): return "%s %d" % [h[0], h[1]])
	_ok(hechizos == ["Alba 1", "Alba 2"], "tras el libro, Kael (nivel 1) puede usar %s" % [hechizos])
	t2._comprar_libro(["Lumbre", 2, 450])
	_ok(A.nivel("Lya", "Lumbre") == 2 and A.nivel("Kael", "Lumbre") == 0, "el libro de la Lumbre no es para Lya")
	_ok(root.get_node("Entrada").buscar(t2, "comprar:Libro de Peso del Ocaso (Alba II)") == null, "el libro del Alba se puede comprar dos veces")
	t2.queue_free()
	if fallos.filter(func(f): return str(f).begins_with("T:")).is_empty():
		hechos.append("T")


func _terminar() -> void:
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", ", ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
