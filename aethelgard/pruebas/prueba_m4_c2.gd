extends SceneTree
# M4 (los niveles III de las artes, los tomos y los accesorios de M3 y M4) y C2 (las armas especiales), en combates de
# verdad (combate.tscn), sin ventana y con datos aislados. El combate no guarda (sin «desde_mapa»).
#   M4. Hora Dorada (Kael 16): los demás aliados llenan su barra y entran UNA vez en la cola; con Kael solo, el motivo.
#       Invierno Guardián (Kael 20): corazas a todos y quien rompe la de Kael queda Congelado. Última Brasa (Lya 18):
#       quien cae se levanta una vez con el 30 % («brasa» una vez), y el segundo golpe ya lo tumba. Sonido de cada III
#       una vez, al aplicarse. Aprendizaje (16, 20, 18), los tomos (una vez) y las fichas del Diario.
#       Lágrima de ámbar (coraza al empezar) y Brasa en frasco (Brasa al empezar).
#   C2. Fauces de Gorthor (se cura parte de lo que hace), Guardiana de Ámbar (réplica en guardia), Gemelas de la
#       Muralla (cubre al aliado con poca vida), Rama del Árbol Milenario (Aliento al más herido al empezar), Hoja sin
#       Nombre (+1 de ataque por recuerdo visto) y la recompensa de Gorthor (las Fauces, una vez).
# Los combates con guion no prueban la estrategia de un jugador.

const ARCHIVO := "user://prueba_m4_c2.save"

var P
var G
var A
var I
var X
var c = null
var congelar := true
var fallos: Array = []
var hechos: Array = []
var sonidos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	A = load("res://artes.gd")
	I = load("res://inventario.gd")
	X = load("res://equipo_extra.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if congelar and c != null and is_instance_valid(c):
			for e in c.enemigos:
				e["atb"] = 0.0


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "inventario",
			"combates_ganados", "lore_visto"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


# «equipo»: [[héroe, ranura, id], ...] que se pone antes de empezar.
func _combate(activos: Dictionary, grupo: int, equipo: Array = [], tipo := "normal", lore := {}) -> void:
	_limpiar()
	G.datos()
	I.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["libros"] = {}
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	for q in equipo:
		X.conseguir(q[2])
		I.equipar(q[0], q[1], q[2])
	if not lore.is_empty():
		Engine.set_meta("lore_visto", lore)
	Engine.set_meta("zona", "ceniza")                # nivel 34: con héroes de nivel 20 no es «zona limpia» (nadie huye solo)
	Engine.set_meta("tipo_combate", tipo)
	Engine.set_meta("grupo_combate", grupo)
	congelar = true
	sonidos.clear()
	c = load("res://combate.tscn").instantiate()
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, Engine.get_process_frames()]))
	root.add_child(c)
	seed(20261109)
	for e in c.enemigos:
		e["atb"] = 0.0


func _cerrar() -> void:
	if c != null:
		c.queue_free()
		c = null
	await _esperar(5)


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _turno_de(n: String) -> bool:
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == n:
				await _esperar(3)
				return true
			c._defender()
		await _esperar(1)
	_ok(false, "no llega el turno de " + n)
	return false


func _libre() -> bool:
	return c.estado == "esperando" or c.estado == "menu"


func _hasta(cond: Callable, max := 600) -> bool:
	for i in max:
		if cond.call():
			return true
		await _esperar(1)
	return cond.call()


func _cuenta(n: String) -> int:
	return sonidos.filter(func(s): return s[0] == n).size()


func _heroes_esperan() -> void:
	for h in c.heroes:
		h["atb"] = 0.0
	for i in range(c.cola.size() - 1, -1, -1):
		if c.cola[i].get("hero", false):
			c.cola.remove_at(i)


# Que actúe un enemigo concreto (los héroes, que no les toque antes) y esperar a que acabe.
func _actua(e: Dictionary) -> void:
	_heroes_esperan()
	congelar = false
	for o in c.enemigos:
		o["atb"] = 0.0
	e["atb"] = 99.9
	var turno := false
	for i in 900:
		if c.estado == "enemigo":
			turno = true
		elif turno:
			break
		if c.estado == "menu" and c.menu.activo:
			c._defender()
		await _esperar(1)
	congelar = true


func _probar() -> void:
	await _esperar(10)
	_aprendizaje()
	await _hora_dorada()
	await _invierno()
	await _brasa()
	await _accesorios()
	await _armas()
	await _recompensa()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ---------------------------------------------------------------- M4
func _aprendizaje() -> void:
	_ok(A.ACTIVOS == {"Alba": 3, "Escarcha": 3, "Lumbre": 3}, "M4: no están enganchados los III: %s" % [A.ACTIVOS])
	_ok(A.nuevas_al_subir("Kael", {"nivel": 16}, 15, 16) == [["Alba", 3]], "M4: al subir a 16 no se aprende Hora Dorada")
	_ok(A.nuevas_al_subir("Kael", {"nivel": 20}, 19, 20) == [["Escarcha", 3]], "M4: al subir a 20 no se aprende el Invierno")
	_ok(A.nuevas_al_subir("Lya", {"nivel": 18}, 17, 18) == [["Lumbre", 3]], "M4: al subir a 18 no se aprende la Última Brasa")
	var titulos: Array = A.fichas_activas().map(func(f): return f[0])
	for t in ["Ritmo", "Aliento", "Barrera", "Brasa", "Hora Dorada", "Invierno", "Tomos"]:
		_ok(t in titulos, "M4: falta la ficha «%s» en el Diario" % t)
	_limpiar()
	G.datos()
	G.datos()["Lya"]["nivel"] = 1
	G.datos()["Lya"]["libros"] = {}
	_ok(A.dar_tomo("tomo_lumbre") == "Lya aprende Última Brasa.", "M4: el tomo de la Lumbre no enseña la Última Brasa")
	_ok(A.dar_tomo("tomo_lumbre") == "" and A.nivel("Lya", "Lumbre") == 3, "M4: el tomo se lee dos veces")
	_ok(A.dar_tomo("tomo_que_no_existe") == "", "M4: un tomo desconocido enseña algo")
	_ok(X.disponible("lagrima_ambar") and X.disponible("brasa_frasco") and X.disponible("fauces_gorthor"), "M4/C2: no están disponibles")
	hechos.append("M4: aprendizaje, fichas y tomos")


func _hora_dorada() -> void:
	_combate({"Kael": 16}, 9)
	if await _turno_de("Kael"):
		c._menu_magia(4)
		await _esperar(3)
		var f: Dictionary = c.menu.filas[2]["item"] if c.menu.filas.size() > 2 else {}
		_ok(f.get("texto", "") == "Hora Dorada" and f.get("apagado", false) and f.get("desc", "") == "Kael va solo: no hay otro aliado.",
			"M4: la Hora Dorada con Kael solo: %s" % [f])
	await _cerrar()
	_combate({"Kael": 16, "Lya": 16, "Garon": 16}, 9)
	if not await _turno_de("Kael"):
		return
	for h in c.heroes:
		h["atb"] = 10.0
	var entradas := {"Lya": 0, "Garon": 0}
	var antes := {"Lya": false, "Garon": false}
	c._elegir_hechizo("Alba", 3)
	var turnos := {"Lya": 0, "Garon": 0}
	var kael_otra := false
	for i in 1500:
		for n in entradas:
			var en: bool = c.cola.any(func(x): return x["nombre"] == n)
			if en and not antes[n]:
				entradas[n] += 1
			antes[n] = en
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Kael":
				kael_otra = true
				break
			turnos[c.actor["nombre"]] += 1
			c._defender()
		await _esperar(1)
	_ok(entradas == {"Lya": 1, "Garon": 1} and turnos == {"Lya": 1, "Garon": 1} and kael_otra,
		"M4: Hora Dorada: entradas %s, turnos %s" % [entradas, turnos])
	_ok(_cuenta("arte_hora_dorada") == 1, "M4: Hora Dorada suena %d veces" % _cuenta("arte_hora_dorada"))
	await _cerrar()
	hechos.append("M4: Hora Dorada (motivo, una entrada y un turno por aliado)")


func _invierno() -> void:
	_combate({"Kael": 20}, 9)
	if not await _turno_de("Kael"):
		return
	var kael := _heroe("Kael")
	c._elegir_hechizo("Escarcha", 3)
	await _hasta(func(): return int(kael.get("barrera", 0)) > 0, 200)
	_ok(int(kael["barrera"]) == int(kael["hp_max"] * 0.30) and kael.get("barrera_escarcha", false), "M4: el Invierno no da la coraza helada")
	_ok(_cuenta("arte_escarcha") == 1, "M4: el Invierno suena %d veces" % _cuenta("arte_escarcha"))
	await _hasta(_libre, 400)
	kael["barrera"] = 2                              # que el golpe la rompa
	var grim: Dictionary = c.enemigos[0]
	await _actua(grim)
	_ok(int(kael.get("barrera", 0)) == 0 and int(grim.get("congelado", 0)) > 0, "M4: quien rompe el Invierno no queda Congelado")
	_ok(_cuenta("barrera_rota") == 1, "M4: la coraza helada rota suena %d veces" % _cuenta("barrera_rota"))
	await _cerrar()
	hechos.append("M4: Invierno Guardián (coraza helada; quien la rompe, Congelado)")


func _brasa() -> void:
	_combate({"Kael": 18, "Lya": 18}, 9)
	if not await _turno_de("Lya"):
		return
	var kael := _heroe("Kael")
	c._elegir_hechizo("Lumbre", 3)
	await _hasta(func(): return float(kael.get("brasa", 0.0)) > 0.0, 200)
	_ok(is_equal_approx(float(kael["brasa"]), 0.30) and _cuenta("arte_lumbre") == 1, "M4: la Última Brasa no pone la Brasa o suena %d veces" % _cuenta("arte_lumbre"))
	await _hasta(_libre, 400)
	c._quitar_pv(kael, 99999)
	_ok(kael["hp"] == int(kael["hp_max"] * 0.30) and float(kael.get("brasa", 0.0)) == 0.0, "M4: con Brasa, Kael no se levanta (%d PV)" % kael["hp"])
	_ok(_cuenta("brasa") == 1, "M4: al levantarse, «brasa» suena %d veces" % _cuenta("brasa"))
	c._quitar_pv(kael, 99999)
	_ok(kael["hp"] == 0, "M4: la Brasa sirve dos veces")
	await _cerrar()
	hechos.append("M4: Última Brasa (se levanta una vez)")


func _accesorios() -> void:
	_combate({"Kael": 5, "Lya": 5}, 9, [["Kael", "accesorio", "lagrima_ambar"], ["Lya", "accesorio", "brasa_frasco"]])
	var kael := _heroe("Kael")
	var lya := _heroe("Lya")
	_ok(int(kael.get("barrera", 0)) == int(kael["hp_max"] * 0.15), "M4: la Lágrima no da coraza al empezar (%s)" % kael.get("barrera", 0))
	_ok(is_equal_approx(float(lya.get("brasa", 0.0)), 0.25), "M4: la Brasa en frasco no da Brasa al empezar")
	await _cerrar()
	hechos.append("M4: Lágrima de ámbar y Brasa en frasco")


# ---------------------------------------------------------------- C2
func _armas() -> void:
	# Fauces (Garon) y Guardiana (Kael)
	_combate({"Kael": 8, "Lya": 8, "Garon": 8}, 9, [["Garon", "arma", "fauces_gorthor"], ["Kael", "arma", "guardiana_ambar"]])
	var garon := _heroe("Garon")
	var kael := _heroe("Kael")
	var grim: Dictionary = c.enemigos[0]
	grim["hp"] = 9999
	grim["hp_max"] = 9999
	if await _turno_de("Garon"):
		garon["hp"] = int(garon["hp_max"] * 0.5)
		var pv0: int = garon["hp"]
		var e0: int = grim["hp"]
		c._menu_objetivo("atacar", "")
		c._confirmar_objetivo(grim)
		await _hasta(_libre, 400)
		var hecho: int = e0 - grim["hp"]
		_ok(hecho > 0 and garon["hp"] - pv0 == maxi(1, int(hecho * 0.15)), "C2: las Fauces curan %d con %d de daño" % [garon["hp"] - pv0, hecho])
	if await _turno_de("Kael"):
		c._defender()
		await _hasta(_libre, 400)
		for h in c.heroes:                           # que el golpe vaya a Kael
			if h != kael:
				h["hp"] = h["hp_max"]
		kael["hp"] = 40                              # el más débil: el agresivo va a por él
		var e1: int = grim["hp"]
		await _actua(grim)
		_ok(grim["hp"] < e1, "C2: la Guardiana no devuelve el golpe en guardia")
	await _cerrar()
	# Gemelas (Garon) y Rama (Lya)
	_combate({"Kael": 8, "Lya": 8, "Garon": 8}, 9, [["Garon", "arma", "gemelas_muralla"], ["Lya", "arma", "rama_milenaria"]])
	var k := _heroe("Kael")
	var g := _heroe("Garon")
	_ok(c.heroes.any(func(h): return int(h.get("aliento", 0)) == 2), "C2: la Rama no da Aliento al empezar")
	k["hp"] = int(k["hp_max"] * 0.2)
	_ok(c._cubre(k) == g, "C2: las Gemelas no cubren a Kael con poca vida")
	k["hp"] = k["hp_max"]
	_ok(c._cubre(k) == k, "C2: las Gemelas cubren a Kael con toda la vida")
	await _cerrar()
	# Hoja sin Nombre: +1 de ataque por recuerdo
	_combate({"Kael": 8}, 9, [["Kael", "arma", "hoja_sin_nombre"]])
	var atk0: int = _heroe("Kael")["atk"]
	await _cerrar()
	_combate({"Kael": 8}, 9, [["Kael", "arma", "hoja_sin_nombre"]], "normal", {"a": true, "b": true, "c": true})
	_ok(_heroe("Kael")["atk"] == atk0 + 3, "C2: la Hoja sin Nombre no suma un punto por recuerdo (%d y %d)" % [_heroe("Kael")["atk"], atk0])
	await _cerrar()
	hechos.append("C2: Fauces, Guardiana, Gemelas, Rama y Hoja sin Nombre")


func _recompensa() -> void:
	_combate({"Kael": 20, "Lya": 20, "Garon": 20}, 5, [], "jefe")
	await _esperar(5)
	c.combate_fijo = "garganta_gorthor"
	for e in c.enemigos:
		e["hp"] = 0
	var lista: Array = I.datos()["equipables"]
	lista.erase("fauces_gorthor")
	await c._fin_combate(true)
	_ok("fauces_gorthor" in I.datos()["equipables"] and c.registro.text == "Has conseguido Fauces de Gorthor.", "C2: vencer a Gorthor no da las Fauces («%s»)" % c.registro.text)
	await _cerrar()
	hechos.append("C2: las Fauces al vencer a Gorthor")
