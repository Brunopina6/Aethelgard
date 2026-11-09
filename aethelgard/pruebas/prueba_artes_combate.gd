extends SceneTree
# M1 y M2 en un combate de verdad (combate.tscn, con los enganches de docs/diseno/combate_enganches.md aplicados en
# combate.gd el 09/11; antes jugaba con una subclase de pruebas, pruebas/combate_con_artes.gd, ya borrada):
#   A. Kael (nivel 9) y Lya (nivel 10) contra dos Slimes:
#      1. el menú de magia de Kael tiene I · II y la pestaña del Alba; el Compás del Alba gasta 6 PM, carga la Armonía
#         +0,15 y Lya entra UNA vez en la cola y tiene UN turno antes de que vuelva Kael;
#      2. Segundo Aliento: Kael, a media vida, se cura un 8 % justo al empezar su turno y le quedan 2 turnos;
#      3. Peso del Ocaso: mientras Kael lo lanza, la barra de los Slimes baja de golpe (y quien esperaba sale de la cola);
#      4. Lumbre de Retorno: Kael caído vuelve con el 25 % de sus PV, la barra a 0 y fuera de la cola, y vuelve a actuar.
#   B. Kael solo (nivel 3): la pestaña del Alba tiene el Compás apagado, con su motivo, y elegirlo no hace nada.
#   C. Kael y Lya a nivel 1: el menú de magia de Lya es el de hoy (sin pestañas; Fuego, Agua, Rayo y Cura).
#   D. Kael solo, a un punto de experiencia del nivel 3: al ganar, «Kael aprende Compás del Alba» (el aviso de las
#      artes al subir de nivel, A8), después del de subir y una sola vez.
# Ganar o huir así no prueba la estrategia de un jugador: solo que el código de los enganches funciona.
# No toca la partida de verdad: no guarda (sin «desde_mapa») y apunta a su propio archivo.

const ARCHIVO := "user://prueba_artes_combate.save"
const MAX_FOTOGRAMAS := 5400                     # 180 s de juego por combate como mucho

var P
var G
var A
var c = null
var frames := 0
var f_inicio := 0
var f_fin := -1
var escenario := ""
var pendientes := ["A", "B", "C", "D"]
var carteles: Array = []                         # D: los textos del cartel, en orden
var fallos: Array = []
var paso := 0
var espera := 0
var en_cola_antes := {}                          # nombre → estaba en la cola al mirar la vez anterior
var entradas := {}                               # nombre → veces que ha entrado en la cola
var turnos := {}                                 # nombre → turnos empezados
var atb_antes := {}
var pv_antes := {}
var sube := {}                                   # nombre → PV ganados desde la vez anterior
var retrasos := {}                               # enemigo → bajada de su barra mientras Kael lanza
var datos := {}


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	A = load("res://artes.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append("%s: %s" % [escenario, texto])


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _empezar(e: String) -> void:
	escenario = e
	paso = 0
	f_fin = -1
	for d in [datos, entradas, turnos, en_cola_antes, atb_antes, pv_antes, sube, retrasos]:
		d.clear()
	_limpiar()
	carteles.clear()
	G.datos()
	var niveles: Dictionary = {"A": {"Kael": 9, "Lya": 10}, "B": {"Kael": 3}, "C": {"Kael": 1, "Lya": 1},
		"D": {"Kael": 2}}[e]
	Engine.set_meta("grupo_activo", niveles.keys())
	for n in niveles:
		G.datos()[n]["nivel"] = niveles[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["libros"] = {}
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	if e == "D":                                  # a un punto del nivel 3: cualquier victoria lo sube
		G.datos()["Kael"]["exp"] = G.exp_para(2) - 1
	Engine.set_meta("zona", "desierto" if e == "A" else "llanura")   # sin «zona limpia»: los Slimes no huyen solos
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", {"B": 7, "D": 9}.get(e, 8))   # D: un Grimfang (no huye: la victoria da experiencia)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	if e == "D":
		c.enemigos[0]["hp"] = 1                   # el primer golpe gana
	seed(20261109)                                # como la huella: después de _ready
	for en in c.enemigos:
		en["atb"] = randf() * 30.0
	f_inicio = frames


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _process(_d: float) -> bool:
	frames += 1
	if frames < 10:                               # el paso de --fixed-fps 30 se asienta en los primeros fotogramas
		return false
	if c == null:
		if espera > 0:
			espera -= 1
			return false
		if pendientes.is_empty():
			_terminar()
			return true
		_empezar(pendientes.pop_front())
		return false
	_vigilar()
	if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
		var n: String = c.actor["nombre"]
		turnos[n] = turnos.get(n, 0) + 1
		match escenario:
			"A":
				_turno_a(c.actor)
			"B":
				_turno_b(c.actor)
			"C":
				_turno_c(c.actor)
			"D":
				c._menu_objetivo("atacar", "")      # ataca hasta ganar
				c._confirmar_objetivo(c.enemigos.filter(func(x): return x["hp"] > 0)[0])
				paso = 1
	if c.estado == "fin" and f_fin < 0:
		f_fin = frames
	var acabado: bool = f_fin >= 0 and (c.menu.heroe_actual.get("nombre", "") == "Fin" or frames - f_fin > 900)
	if acabado or frames - f_inicio > MAX_FOTOGRAMAS:
		_ok(c.estado == "fin", "el combate no terminó (paso %d, estado %s)" % [paso, c.estado])
		_ok(paso >= int({"A": 5, "B": 1, "C": 1, "D": 1}[escenario]), "se quedó en el paso %d" % paso)
		if escenario == "D":
			var sube := carteles.find("¡Kael sube al nivel 3!")
			var aprende := carteles.find("Kael aprende Compás del Alba")
			_ok(sube >= 0 and aprende > sube and carteles.count("Kael aprende Compás del Alba") == 1,
				"el aviso de las artes al subir de nivel no sale bien: %s" % [carteles])
			_ok(not carteles.any(func(t): return str(t).contains("Peso del Ocaso") or str(t).contains("Lumbre")),
				"al subir al 3 avisa de algo más que el Compás: %s" % [carteles])
		c.queue_free()
		c = null
		Engine.time_scale = 1.0
		espera = 3
	return false


# Lo que pasa entre turnos: quién entra en la cola, PV que suben, barras que bajan mientras Kael lanza y Kael que vuelve.
func _vigilar() -> void:
	if carteles.is_empty() or carteles.back() != c.registro.text:
		carteles.append(c.registro.text)
	var lanza_kael: bool = c.estado == "accion" and c.actor is Dictionary and c.actor.get("nombre", "") == "Kael"
	for f in c.heroes + c.enemigos:
		var n: String = f["nombre"]
		var dentro: bool = c.cola.any(func(x): return is_same(x, f))
		if dentro and not en_cola_antes.get(n, false):
			entradas[n] = entradas.get(n, 0) + 1
		en_cola_antes[n] = dentro
		if lanza_kael and not f["hero"] and atb_antes.has(n) and f["atb"] < atb_antes[n] - 20.0:
			retrasos[n] = atb_antes[n] - f["atb"]
		atb_antes[n] = f["atb"]
		sube[n] = f["hp"] - pv_antes.get(n, f["hp"])
		pv_antes[n] = f["hp"]
	if escenario == "A" and paso == 4 and not datos.has("vuelve"):
		var kael := _heroe("Kael")
		if kael["hp"] > 0:
			datos["vuelve"] = true
			var esperado := maxi(1, int(kael["hp_max"] * 0.25))
			_ok(kael["hp"] == esperado, "Lumbre de Retorno: Kael vuelve con %d PV y no %d" % [kael["hp"], esperado])
			_ok(kael["atb"] < 1.0 and not c.cola.any(func(x): return is_same(x, kael)), "Kael vuelve con barra o en la cola")


func _pestanas() -> Array:
	return c.menu._pestanas.map(func(p): return p.get("icono", p["texto"]))


func _textos() -> Array:
	return c.menu.filas.map(func(f): return f["item"]["texto"])


# Abre la pestaña de la familia como el jugador y lanza el arte por el mismo camino que el menú.
func _arte(fam: String, nv: int, objetivo = null) -> void:
	c._menu_magia(4 + A.familias_de(c.actor["nombre"]).find(fam))
	c._elegir_hechizo(fam, nv)
	if objetivo != null:
		_ok(c.estado == "objetivo", "%s %d no pide objetivo" % [fam, nv])
		c._confirmar_objetivo(objetivo)


func _turno_a(h: Dictionary) -> void:
	var n: String = h["nombre"]
	var kael := _heroe("Kael")
	var lya := _heroe("Lya")
	match paso:
		0:
			if n != "Kael":
				c._defender()
				return
			c._menu_magia(0)
			_ok(_pestanas() == ["I", "II", "Alba"], "las pestañas de Kael (nivel 9) son %s" % [_pestanas()])
			c._menu_magia(4)
			_ok(_textos() == ["Compás del Alba", "Peso del Ocaso"], "la pestaña del Alba tiene %s" % [_textos()])
			_ok(not c.menu.filas[0]["item"]["apagado"], "el Compás sale apagado con Lya en pie")
			datos["pm"] = h["mp"]
			datos["armonia"] = c.armonia
			entradas["Lya"] = 0
			turnos["Lya"] = 0
			_arte("Alba", 1, lya)
			paso = 1
		1:
			if n == "Kael":
				_ok(false, "Kael vuelve a actuar antes que Lya tras el Compás")
				c._defender()
				return
			_ok(kael["mp"] == datos["pm"] - 6, "el Compás gasta %d PM y no 6" % (datos["pm"] - kael["mp"]))
			_ok(is_equal_approx(c.armonia, minf(1.0, datos["armonia"] + 0.15)), "la Armonía no sube 0,15 con el Compás")
			_ok(entradas.get("Lya", 0) == 1, "tras el Compás, Lya entra %d veces en la cola" % entradas.get("Lya", 0))
			kael["hp"] = int(kael["hp_max"] * 0.5)
			_arte("Lumbre", 2)
			paso = 2
		2:
			if n != "Kael":
				c._defender()
				return
			_ok(turnos.get("Lya", 0) == 1, "Lya tuvo %d turnos entre el Compás y el siguiente de Kael" % turnos.get("Lya", 0))
			var esperada := mini(maxi(1, int(kael["hp_max"] * 0.08)), kael["hp_max"] - (kael["hp"] - sube["Kael"]))
			_ok(sube["Kael"] == esperada, "el Aliento cura a Kael %d al empezar su turno y no %d" % [sube["Kael"], esperada])
			_ok(kael.get("aliento", 0) == 2, "al Aliento de Kael le quedan %d turnos y no 2" % kael.get("aliento", 0))
			for e in c.enemigos:                      # barras conocidas que no llegan a 100 mientras Kael lanza
				if e["hp"] > 0 and not c.cola.any(func(x): return is_same(x, e)):
					e["atb"] = 60.0
			retrasos.clear()
			_arte("Alba", 2)
			paso = 3
		3:
			if n != "Lya":
				c._defender()
				return
			var vivos: Array = c.enemigos.filter(func(e): return e["hp"] > 0)
			_ok(not vivos.is_empty() and vivos.all(func(e): return retrasos.get(e["nombre"], 0.0) >= 30.0),
				"el Ocaso no baja la barra de los Slimes: %s" % [retrasos])
			c._quitar_pv(kael, 99999)               # Kael cae (como si le hubieran golpeado)
			c._restablecer_color(kael)
			c._menu_magia(4)
			_ok(_textos() == ["Lumbre de Retorno", "Segundo Aliento"] and not c.menu.filas[0]["item"]["apagado"],
				"con Kael caído, la Lumbre de Retorno no está lista: %s" % [_textos()])
			_arte("Lumbre", 1, kael)
			paso = 4
		4:
			if n != "Kael":
				c._defender()
				return
			_ok(datos.has("vuelve"), "Kael no volvió con la Lumbre de Retorno")
			c._escapar()                             # vuelve a actuar: basta
			paso = 5


func _turno_b(h: Dictionary) -> void:
	c._menu_magia(0)
	_ok(_pestanas() == ["I", "Alba"], "las pestañas de Kael solo (nivel 3) son %s" % [_pestanas()])
	c._menu_magia(4)
	var f: Dictionary = c.menu.filas[0]["item"] if not c.menu.filas.is_empty() else {}
	_ok(f.get("texto", "") == "Compás del Alba" and f.get("apagado", false) and f.get("desc", "") == "Kael va solo: no hay otro aliado.",
		"el Compás de Kael solo: %s" % [f])
	var pm: int = h["mp"]
	c._elegir_hechizo("Alba", 1)
	_ok(c.estado == "magia" and h["mp"] == pm, "elegir el Compás apagado hace algo (estado %s)" % c.estado)
	c._atras()
	c._escapar()
	paso = 1


func _turno_c(h: Dictionary) -> void:
	if h["nombre"] != "Lya":
		c._defender()
		return
	c._menu_magia(0)
	_ok(_pestanas().is_empty() and _textos() == ["Fuego", "Agua", "Rayo", "Cura"],
		"el menú de Lya a nivel 1 no es el de hoy: %s %s" % [_pestanas(), _textos()])
	c._atras()
	c._escapar()
	paso = 1


func _terminar() -> void:
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	if fallos.is_empty():
		print("OK A: Compás (una entrada en la cola, un turno de Lya, 6 PM, Armonía +0,15), Segundo Aliento, Peso del Ocaso y Lumbre de Retorno")
		print("OK B: Compás apagado con Kael solo, con su motivo")
		print("OK C: el menú de magia de Lya a nivel 1, como hoy")
		print("OK D: al subir al nivel 3, «Kael aprende Compás del Alba», una vez y tras «sube al nivel 3»")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
