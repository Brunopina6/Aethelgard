extends SceneTree
# El Guardián del Bosque Olvidado (fase 3, «El bosque que no recuerda»), en combates de verdad con «-- auto»:
#   A. Derrota convencional: empieza en su fase 1; al bajar del 50 % pasa a la 2 («fase2», más rápido, coraza de
#      raíces: un golpe físico le hace la mitad y el fuego ×1,5); a 0 PV, victoria. Desenlace «derrotado» en
#      «decisiones», hitos bq_resuelto y bq_derrotado, combate fijo ganado, +1 Corazón de roble y la Corteza del
#      Guardián. Repetir el combate no da el premio otra vez.
#   B. Purificación: con un Elixir de savia purificada, en la fase 1 resbala y NO se gasta; en la fase 2 se gasta y lo
#      purifica: victoria, «purificado», hito bq_purificado, el Brote del Guardián y +2 Savia clara (y no la Corteza).
#   C. Esencia de enfoque: se gasta, el héroe tiene 3 turnos de enfoque y su magia hace ×1,3 (combate_bosque.gd).
# Datos aislados; la partida en memoria (no se escribe nada).

const LIMITE := 2400
const B := preload("res://combate_bosque.gd")

var c: Node
var fase := ""
var frames := 0
var fallos := 0
var paso := 0
var Inv


func _initialize() -> void:
	if not "auto" in OS.get_cmdline_user_args():
		print("FALLO: falta «-- auto»")
		quit(1)
		return
	Inv = load("res://inventario.gd")
	seed(11)
	for k in ["decisiones", "combates_ganados", "hitos", "inventario", "investigaciones"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	_empezar("A")


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: [%s] %s" % [fase, t])


func _empezar(f: String) -> void:
	if c != null:
		c.queue_free()
		c = null
	fase = f
	frames = 0
	paso = 0
	Engine.time_scale = 1.0
	Engine.set_meta("grupo_combate", 11)
	Engine.set_meta("combate_fijo", B.COMBATE)
	Engine.set_meta("desde_mapa", false)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _guardian() -> Dictionary:
	for e in c.enemigos:
		if B.es_guardian(e):
			return e
	return {}


func _terminar(siguiente: String) -> void:
	print("caso %s: terminado en %d fotogramas" % [fase, frames])
	if siguiente == "":
		print("FALLOS: %d" % fallos)
		quit(1 if fallos > 0 else 0)
	else:
		_empezar(siguiente)


func _process(_d: float) -> bool:
	if c == null or not is_instance_valid(c):
		return false
	frames += 1
	if frames > LIMITE:
		_fallo("no termina (paso %d, estado %s)" % [paso, c.estado])
		_terminar("" if fase == "C" else {"A": "A2", "A2": "B", "B": "C"}[fase])
		return false
	var g := _guardian()
	match fase:
		"A", "A2":
			_caso_a(g)
		"B":
			_caso_b(g)
		"C":
			_caso_c(g)
	return false


func _caso_a(g: Dictionary) -> void:
	if g.is_empty():
		return
	if paso == 0 and frames > 30:
		if g.get("fase2", false):
			_fallo("empieza en la fase 2")
		var golpe: int = B.dano_recibido(100, "", {"nombre": "Kael"}, g, false)
		if golpe != 100:
			_fallo("en la fase 1 un golpe físico de 100 hace %d" % golpe)
		c._quitar_pv(g, g["hp"] - int(g["hp_max"] * 0.45))     # baja del 50 %
		paso = 1
	elif paso == 1 and g.get("fase2", false) and not g.get("fase2_pendiente", false) and c.estado != "accion":
		if B.dano_recibido(100, "", {"nombre": "Kael"}, g, false) != 50:
			_fallo("en la fase 2 la coraza no reduce el golpe físico a la mitad")
		if B.dano_recibido(100, "Fuego", {"nombre": "Lya"}, g, false) != 150:
			_fallo("en la fase 2 el fuego no hace ×1,5")
		c._quitar_pv(g, g["hp"])
		c._comprobar_fin()                            # como tras un golpe del juego
		paso = 2
	elif paso == 2 and c.estado == "fin" or paso == 2 and not is_instance_valid(c):
		paso = 3
	elif paso == 2 and frames % 30 == 0 and c.enemigos.all(func(e): return e["hp"] <= 0) and c.estado in ["fin", "esperando"]:
		paso = 3
	if paso == 3 or (paso == 2 and Engine.get_meta("combates_ganados", {}).get(B.COMBATE, false) and frames % 60 == 0):
		_comprobar_a()


var _a_hecho := {}


func _comprobar_a() -> void:
	if _a_hecho.has(fase):
		return
	if not Engine.get_meta("combates_ganados", {}).get(B.COMBATE, false):
		return
	_a_hecho[fase] = true
	var P = load("res://progreso.gd")
	if fase == "A":
		if B.desenlace() != "derrotado":
			_fallo("desenlace «%s» y debía ser «derrotado»" % B.desenlace())
		if not P.hito("bq_resuelto") or not P.hito("bq_derrotado"):
			_fallo("faltan los hitos bq_resuelto o bq_derrotado")
		if Inv.cantidad("Corazón de roble") != 1:
			_fallo("Corazón de roble: %d y debía ser 1" % Inv.cantidad("Corazón de roble"))
		if not "corteza_guardian" in Inv.datos()["equipables"]:
			_fallo("no se recibe la Corteza del Guardián")
		_terminar("A2")
	else:                                               # A2: el mismo combate otra vez, sin premio
		if Inv.cantidad("Corazón de roble") != 1:
			_fallo("repetir el combate duplica el premio (Corazón de roble: %d)" % Inv.cantidad("Corazón de roble"))
		Engine.remove_meta("decisiones")
		Engine.remove_meta("combates_ganados")
		Engine.remove_meta("hitos")
		Inv.agregar_objeto(B.ELIXIR, 1)
		_terminar("B")


func _caso_b(g: Dictionary) -> void:
	if g.is_empty() or c.heroes.is_empty():
		return
	if paso == 0 and frames > 30 and c.estado == "esperando":
		c.actor = c.heroes[0]
		c._usar_elixir(B.ELIXIR, g)                    # fase 1: resbala
		if Inv.cantidad(B.ELIXIR) != 1:
			_fallo("en la fase 1 el elixir se gastó")
		if g["hp"] <= 0 or B.desenlace() != "":
			_fallo("en la fase 1 el elixir lo resolvió")
		c._quitar_pv(g, g["hp"] - int(g["hp_max"] * 0.4))
		paso = 1
	elif paso == 1 and g.get("fase2", false) and not g.get("fase2_pendiente", false) and c.estado == "esperando":
		c.actor = c.heroes[0]
		c._usar_elixir(B.ELIXIR, g)
		paso = 2
	elif paso == 2 and Engine.get_meta("combates_ganados", {}).get(B.COMBATE, false) and frames % 30 == 0:
		var P = load("res://progreso.gd")
		if Inv.cantidad(B.ELIXIR) != 0:
			_fallo("en la fase 2 el elixir no se gastó")
		if B.desenlace() != "purificado":
			_fallo("desenlace «%s» y debía ser «purificado»" % B.desenlace())
		if not P.hito("bq_purificado"):
			_fallo("falta el hito bq_purificado")
		if not "brote_guardian" in Inv.datos()["equipables"]:
			_fallo("no se recibe el Brote del Guardián")
		if Inv.cantidad("Savia clara") != 2:
			_fallo("Savia clara: %d y debía ser 2" % Inv.cantidad("Savia clara"))
		_terminar("C")


func _caso_c(g: Dictionary) -> void:
	if c.heroes.is_empty() or g.is_empty():
		return
	if paso == 0 and frames > 30 and c.estado == "esperando":
		Inv.agregar_objeto(B.ESENCIA, 1)
		var h: Dictionary = c.heroes[0]
		c.actor = h
		c._usar_objeto(B.ESENCIA, h)
		if Inv.cantidad(B.ESENCIA) != 0:
			_fallo("la Esencia no se gastó")
		if int(h.get("enfoque_turnos", 0)) != B.TURNOS_ENFOQUE:
			_fallo("el héroe no tiene %d turnos de enfoque" % B.TURNOS_ENFOQUE)
		var base: int = B.dano_recibido(100, "Agua", {"nombre": "Kael"}, {"clave": "slime"}, false)
		var con: int = B.dano_recibido(100, "Agua", h, {"clave": "slime"}, false)
		if base != 100 or con != 130:
			_fallo("la magia con enfoque hace %d (sin él, %d); debía ser 130 y 100" % [con, base])
		if B.dano_recibido(100, "", h, {"clave": "slime"}, false) != 100:
			_fallo("el enfoque cambia los golpes físicos")
		if B.dano_recibido(100, "Fuego", {"nombre": "Lya"}, {"clave": "guardian_bosque", "fase2": true}, true) != 188:
			_fallo("la ventaja de Lya (×1,25) con fuego en la fase 2 no da 188")
		paso = 1
	elif paso == 1 and frames > 120:
		_terminar("")
