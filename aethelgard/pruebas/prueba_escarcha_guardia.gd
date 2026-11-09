extends SceneTree
# M3 (Escarcha de Kael: Coraza y Muralla) y la Guardia de Garon (T-100), en combates de verdad (combate.tscn), sin
# ventana y con datos aislados. El combate no guarda (sin «desde_mapa») y la partida apunta a su propio archivo.
#   A. Escarcha: se aprende a los niveles 6 (Coraza) y 12 (Muralla), y con el libro (Muralla, 400, a la venta); la ficha
#      «Barrera» en el Diario; la pestaña sale; sin PM, la fila dice por qué. La Coraza sobre sí mismo (Kael solo
#      también puede): 30 % de sus PV, sonido «arte_escarcha» una vez al aplicarse, su seña y su cifra en el HUD. Un
#      golpe que la coraza absorbe entera (no quita PV, «barrera_absorbe» una vez) y otro que la rompe (solo el resto
#      a los PV, «barrera_rota» una vez, la seña de las esquirlas). La Muralla, a todos.
#   B. La Guardia de Garon: Zarzalín avisa que embestirá a Kael; Garon le cubre (4 PM, en guardia, «defensa» una vez,
#      su seña y el escudo en el HUD de Kael); la embestida le da a Garon, a la mitad, y Kael no pierde nada. La guardia
#      se acaba al empezar el turno de Garon, si cae Garon o si cae Kael. Con varios impactos (el golpe devastador de un
#      jefe, a todos), el de Kael también va a Garon. Sin nadie a quien cubrir, la fila dice por qué.
# Los combates con guion no prueban la estrategia de un jugador: solo que las reglas hacen lo que dicen.

const ARCHIVO := "user://prueba_escarcha_guardia.save"

var P
var G
var A
var I
var c = null
var fallos: Array = []
var hechos: Array = []
var sonidos: Array = []                           # [nombre, fotograma]


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	A = load("res://artes.gd")
	I = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if c != null and is_instance_valid(c) and congelar:
			for e in c.enemigos:
				e["atb"] = 0.0


var congelar := true


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _combate(activos: Dictionary, grupo: int, tipo := "normal") -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["libros"] = {}
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "desierto")
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


func _pedidos(n: String, desde: int) -> Array:
	return sonidos.filter(func(s): return s[0] == n and s[1] >= desde)


func _senas(tipo: String) -> Array:
	return c.escena.get_children().filter(func(x): return x.get_script() == c.SenaArte and x.tipo == tipo)


func _probar() -> void:
	await _esperar(10)
	_aprendizaje()
	await _escarcha()
	await _guardia()
	await _varios_impactos()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ---------------------------------------------------------------- A. Escarcha
func _aprendizaje() -> void:
	_ok(A.ACTIVOS["Escarcha"] == 2, "A: Escarcha no está enganchada (ACTIVOS %d)" % A.ACTIVOS["Escarcha"])
	_ok(A.nivel_usable("Kael", "Escarcha", {"nivel": 5}) == 0 and A.nivel_usable("Kael", "Escarcha", {"nivel": 6}) == 1
		and A.nivel_usable("Kael", "Escarcha", {"nivel": 12}) == 2 and A.nivel_usable("Kael", "Escarcha", {"nivel": 30}) == 2,
		"A: los niveles de la Escarcha (6 y 12; el III aún no)")
	_ok(A.nuevas_al_subir("Kael", {"nivel": 6}, 5, 6) == [["Escarcha", 1]], "A: al subir a 6 no se aprende la Coraza")
	_ok(A.nivel_usable("Kael", "Escarcha", {"nivel": 7, "libros": {"Escarcha": 2}}) == 2, "A: el libro no enseña la Muralla")
	_ok(A.libros_en_venta().has(["Escarcha", 2, 400]), "A: el libro de la Muralla no se vende")
	_ok(A.fichas_activas().any(func(f): return f[0] == "Barrera"), "A: la ficha «Barrera» no sale en el Diario")
	_ok(A.nivel_usable("Lya", "Escarcha", {"nivel": 50}) == 0 and A.nivel_usable("Garon", "Escarcha", {"nivel": 50}) == 0,
		"A: Lya o Garon aprenden Escarcha")
	hechos.append("A: aprendizaje, libro y ficha")


func _escarcha() -> void:
	_combate({"Kael": 12}, 9)
	if not await _turno_de("Kael"):
		return
	var kael := _heroe("Kael")
	var m = c.menu
	c._menu_magia(0)
	await _esperar(3)
	var tabs: Array = m._pestanas.map(func(p): return p.get("icono", p["texto"]))
	_ok("Escarcha" in tabs, "A: no sale la pestaña de la Escarcha (%s)" % [tabs])
	# sin PM: la Coraza dice por qué
	var pm0: int = kael["mp"]
	kael["mp"] = 0
	c._menu_magia(5)
	await _esperar(3)
	var f0: Dictionary = m.filas[0]["item"] if not m.filas.is_empty() else {}
	_ok(f0.get("texto", "") == "Coraza de Escarcha" and f0.get("apagado", false) and f0.get("desc", "") == "Necesitas 7 PM: tienes 0.",
		"A: la Coraza sin PM: %s" % [f0])
	kael["mp"] = pm0
	c._menu_magia(5)
	await _esperar(3)
	_ok(m.filas.map(func(f): return f["item"]["texto"]) == ["Coraza de Escarcha", "Muralla de Escarcha"], "A: las filas de la Escarcha")
	# la Coraza sobre sí mismo (Kael va solo)
	var desde := Engine.get_process_frames()
	c._elegir_hechizo("Escarcha", 1)
	await _esperar(3)
	_ok(c.estado == "objetivo" and c.objetivos_posibles.size() == 1, "A: la Coraza no pide a Kael (solo)")
	c._confirmar_objetivo(kael)
	var f_coraza := -1
	for i in 200:
		if int(kael.get("barrera", 0)) > 0:
			f_coraza = Engine.get_process_frames()
			break
		await _esperar(1)
	var esperado := int(kael["hp_max"] * 0.30)
	_ok(int(kael.get("barrera", 0)) == esperado and kael["mp"] == pm0 - 7, "A: la Coraza da %s (esperado %d) y gasta %d PM" % [kael.get("barrera", 0), esperado, pm0 - kael["mp"]])
	var p := _pedidos("arte_escarcha", desde)
	_ok(p.size() == 1 and absi(p[0][1] - f_coraza) <= 1, "A: el sonido de la Coraza: %s (aplicada en %d)" % [p, f_coraza])
	_ok(not _senas("escarcha").is_empty() and _senas("escarcha")[0].get_child_count() == 0, "A: no hay seña de la Coraza (o usa nodos)")
	_ok(A.texto_estado(kael, "barrera") == str(esperado) and "barrera" in A.estados_de(kael), "A: el HUD no enseña la coraza")
	await _hasta(_libre, 400)
	# un golpe que la coraza absorbe entero, y otro que la rompe
	var pv0: int = kael["hp"]
	desde = Engine.get_process_frames()
	var real: int = c._quitar_pv(kael, 10)
	_ok(real == 0 and kael["hp"] == pv0 and int(kael["barrera"]) == esperado - 10, "A: la coraza no absorbe 10 (llegan %d)" % real)
	_ok(_pedidos("barrera_absorbe", desde).size() == 1 and _pedidos("barrera_rota", desde).is_empty(), "A: el sonido al absorber")
	await _esperar(2)                                 # otro fotograma: los sonidos de cada golpe, por separado
	desde = Engine.get_process_frames()
	var golpe2: int = (esperado - 10) + 15           # más de lo que le queda: se rompe y llegan 15
	real = c._quitar_pv(kael, golpe2)
	var resto := 15
	_ok(real == resto and kael["hp"] == pv0 - resto and int(kael.get("barrera", 0)) == 0, "A: al romperse llegan %d (esperado %d)" % [real, resto])
	_ok(_pedidos("barrera_rota", desde).size() == 1 and _pedidos("barrera_absorbe", desde).is_empty(), "A: el sonido al romperse")
	_ok(not _senas("escarcha_rota").is_empty(), "A: no saltan las esquirlas al romperse")
	_ok(not "barrera" in A.estados_de(kael), "A: el HUD sigue enseñando la coraza rota")
	await _cerrar()
	# la Muralla, a todos (y un golpe de verdad a quien la lleva)
	_combate({"Kael": 12, "Lya": 10, "Garon": 10}, 9)
	if not await _turno_de("Kael"):
		return
	desde = Engine.get_process_frames()
	c._elegir_hechizo("Escarcha", 2)
	await _hasta(func(): return c.heroes.all(func(h): return int(h.get("barrera", 0)) > 0), 200)
	for h in c.heroes:
		_ok(int(h.get("barrera", 0)) == int(h["hp_max"] * 0.20), "A: la Muralla da a %s %s" % [h["nombre"], h.get("barrera", 0)])
	_ok(_pedidos("arte_escarcha", desde).size() == 1 and _senas("escarcha").size() == 3, "A: la Muralla suena %d veces y tiene %d señas"
		% [_pedidos("arte_escarcha", desde).size(), _senas("escarcha").size()])
	await _hasta(_libre, 400)
	# un golpe de verdad (Grimfang) sobre Kael: un impacto; la coraza absorbe antes que los PV
	var kael2 := _heroe("Kael")
	var b0: int = kael2["barrera"]
	var pv1: int = kael2["hp"]
	congelar = false
	var grim: Dictionary = c.enemigos[0]
	_heroes_esperan()
	grim["atb"] = 99.9
	var vio: bool = await _hasta(func(): return c.estado == "enemigo", 300)
	await _hasta(func(): return c.estado != "enemigo", 400)
	congelar = true
	var golpeado: Array = c.heroes.filter(func(h): return int(h.get("barrera", 0)) < int(h["hp_max"] * 0.20))
	_ok(vio and golpeado.size() == 1, "A: el golpe de Grimfang no toca una sola coraza (%d)" % golpeado.size())
	if golpeado.size() == 1:
		var g: Dictionary = golpeado[0]
		_ok(g["hp"] == g["hp_max"] or int(g["barrera"]) == 0, "A: con coraza, %s pierde PV sin romperla" % g["nombre"])
	await _cerrar()
	hechos.append("A: Escarcha (Coraza sobre sí mismo, absorber, romper, Muralla, golpe de verdad)")


# ---------------------------------------------------------------- B. la Guardia de Garon
func _guardia() -> void:
	_combate({"Kael": 3, "Lya": 3, "Garon": 4}, 10)
	var z: Dictionary = c.enemigos[0]
	if not await _turno_de("Garon"):
		return
	var kael := _heroe("Kael")
	var garon := _heroe("Garon")
	var m = c.menu
	# Zarzalín ya ha avisado: embestirá a Kael
	z["cargando"] = true
	z["objetivo_carga"] = kael
	c._menu_esgrima()
	await _esperar(3)
	var filas: Array = m.filas.map(func(f): return f["item"]["texto"])
	_ok(filas == ["Juicio", "Giro", "Guardia"], "B: las filas de Esgrima: %s" % [filas])
	var pm0: int = garon["mp"]
	var desde := Engine.get_process_frames()
	c._elegir_guardia()
	await _esperar(3)
	_ok(c.estado == "objetivo" and c.objetivos_posibles.size() == 2 and not garon in c.objetivos_posibles, "B: la Guardia no pide un aliado")
	c._confirmar_objetivo(kael)
	await _esperar(3)
	_ok(kael.get("guardia_de", "") == "Garon" and garon.get("defendiendo", false) and garon["mp"] == pm0 - 4,
		"B: la Guardia no cubre a Kael, no pone a Garon en guardia o no gasta 4 PM")
	_ok(_pedidos("defensa", desde).size() == 1 and not _senas("guardia").is_empty(), "B: la Guardia no suena una vez o no tiene seña")
	_ok("guardia" in A.estados_de(kael), "B: el HUD no enseña el escudo junto a Kael")
	await _hasta(_libre, 400)
	# la embestida va a Garon, a la mitad; Kael no pierde nada
	var pv_k: int = kael["hp"]
	var pv_g: int = garon["hp"]
	congelar = false
	_heroes_esperan()
	z["atb"] = 99.9
	var turno := false
	for i in 600:
		if c.estado == "enemigo":
			turno = true
		elif turno:
			break
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary and c.actor["nombre"] != "Garon":
			c._defender()
		await _esperar(1)
	congelar = true
	var dano: int = pv_g - garon["hp"]
	var sin_guardia: int = int(z["atk"] * 1.8 * (1.5 if z.get("furia", false) else 1.0)) + 3 - int(garon.get("def", 0) / 2.0)
	_ok(kael["hp"] == pv_k, "B: Kael pierde %d PV estando cubierto" % (pv_k - kael["hp"]))
	_ok(dano >= 1 and dano <= int(sin_guardia * 0.5) + 1, "B: Garon recibe %d (sin guardia, hasta %d)" % [dano, sin_guardia])
	# al empezar el turno de Garon, la guardia se acaba
	if await _turno_de("Garon"):
		_ok(kael.get("guardia_de", "") == "" and not garon.get("defendiendo", false), "B: la guardia sigue en el turno de Garon")
		# otra vez, y Garon cae: se acaba; el golpe va a Kael
		c._guardia(kael)
		await _hasta(_libre, 400)
		c._quitar_pv(garon, 99999)
		c._restablecer_color(garon)
		_ok(kael.get("guardia_de", "") == "" and c._cubre(kael) == kael, "B: con Garon caído, Kael sigue cubierto")
	await _cerrar()
	# sin nadie a quien cubrir
	_combate({"Kael": 3, "Lya": 3, "Garon": 4}, 10)
	if await _turno_de("Garon"):
		c._quitar_pv(_heroe("Kael"), 99999)
		c._quitar_pv(_heroe("Lya"), 99999)
		c._menu_esgrima()
		await _esperar(3)
		var fg: Dictionary = c.menu.filas[2]["item"] if c.menu.filas.size() > 2 else {}
		_ok(fg.get("apagado", false) and fg.get("desc", "") == "No hay a quién cubrir.", "B: la Guardia sin nadie: %s" % [fg])
		# el aliado que cae deja de estar cubierto
	await _cerrar()
	_combate({"Kael": 3, "Lya": 3, "Garon": 4}, 10)
	if await _turno_de("Garon"):
		var k := _heroe("Kael")
		c._guardia(k)
		await _hasta(_libre, 400)
		c._quitar_pv(k, 99999)
		_ok(k.get("guardia_de", "") == "" and c._cubre(k) == k, "B: Kael caído sigue cubierto")
	await _cerrar()
	hechos.append("B: la Guardia ante la embestida de Zarzalín, su fin, Garon caído, Kael caído y sin nadie")


# Varios impactos: el golpe devastador de un jefe (a todos). El de Kael, cubierto, también va a Garon.
func _varios_impactos() -> void:
	_combate({"Kael": 8, "Lya": 8, "Garon": 8}, 4, "jefe")
	var jefe: Dictionary = c.enemigos.filter(func(e): return e.get("personalidad", "") == "jefe")[0]
	if not await _turno_de("Garon"):
		return
	var kael := _heroe("Kael")
	var garon := _heroe("Garon")
	c._guardia(kael)
	await _hasta(_libre, 400)
	jefe["cargando"] = true
	var pv_k: int = kael["hp"]
	var cambios_g := [0]
	var pv_g := [garon["hp"]]
	congelar = false
	for e in c.enemigos:
		e["atb"] = 0.0
	_heroes_esperan()
	jefe["atb"] = 99.9
	var turno := false
	for i in 900:
		if garon["hp"] != pv_g[0]:
			cambios_g[0] += 1
			pv_g[0] = garon["hp"]
		if c.estado == "enemigo":
			turno = true
		elif turno:
			break
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			c._defender()
		await _esperar(1)
	congelar = true
	_ok(kael["hp"] == pv_k, "varios: Kael pierde %d PV estando cubierto" % (pv_k - kael["hp"]))
	_ok(c.cubiertos >= 1 and garon["hp"] < garon["hp_max"], "varios: la Guardia no lleva a Garon el golpe de Kael (%d)" % c.cubiertos)
	await _cerrar()
	hechos.append("varios impactos: el golpe devastador del jefe")


# Antes de que actúe un enemigo: los héroes, con la barra vacía y fuera de la cola (que no les toque antes).
func _heroes_esperan() -> void:
	for h in c.heroes:
		h["atb"] = 0.0
	for i in range(c.cola.size() - 1, -1, -1):
		if c.cola[i].get("hero", false):
			c.cola.remove_at(i)
