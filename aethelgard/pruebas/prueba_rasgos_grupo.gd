extends SceneTree
# Rasgos del grupo que deben conservarse (15/11, encargo nocturno «Conserva lo ya funcional»). Sin escenas:
#   1. Solo Lya invoca: la regla del combate (combate.gd, _puede_invocar) dice que sí a Lya y que no a Kael, Garon, Nix
#      y Naira. Nix es maga negra: sin las magias de siempre (las suyas salen de magia_negra.gd).
#   2. Garon lucha con dos espadas, pero en los datos hay UNA ranura «arma»: el par (p. ej. las Gemelas de la Muralla)
#      suma su ataque y su pasiva una sola vez (la segunda espada es solo visual, garon_3d.gd DOS_ESPADAS).
#   3. Gremio: el rango Oro pide 13 de reputación (aprobado por el usuario el 14/11; progresión completa en
#      prueba_gremio_progresion).
# Kael: su paso a «Ataque rúnico» (sin Magia ni Invocación) depende del catálogo y del PDF de Kael, que no existen
# todavía (15/11): se conserva su menú de hoy. Aquí solo se comprueba que no invoca.

const ARCHIVO := "user://prueba_rasgos_grupo.save"
var fallos := 0


func _ok(c: bool, t: String) -> void:
	if not c:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	var G = load("res://grupo.gd")
	var I = load("res://inventario.gd")
	var X = load("res://equipo_extra.gd")
	# 1. solo Lya invoca
	var c: Node = load("res://combate.gd").new()
	for n in ["Kael", "Garon", "Nix", "Naira"]:
		_ok(not c._puede_invocar({"nombre": n}), "1: %s puede invocar" % n)
	_ok(c._puede_invocar({"nombre": "Lya"}), "1: Lya no puede invocar")
	c.free()
	_ok(G.HEROES.has("Nix") and G.HEROES["Nix"].get("magias", []).is_empty(), "1: Nix tiene las magias de siempre")
	_ok(load("res://magia_negra.gd").DE_RECLUTA.get("Nix", []).size() == 3, "1: Nix no tiene sus escuelas de magia negra")
	# 2. Garon: el par de espadas cuenta una vez
	G.datos()
	I.datos()
	var eq: Dictionary = I.equipo_de("Garon")
	eq.erase("arma")
	var sin_arma: Dictionary = G.estadisticas("Garon")
	var ef0: Dictionary = X.efectos_de("Garon")
	I.agregar("gemelas_muralla")
	eq["arma"] = "gemelas_muralla"
	var con_par: Dictionary = G.estadisticas("Garon")
	var ef1: Dictionary = X.efectos_de("Garon")
	var at: int = int(I.objeto("gemelas_muralla").get("ataque", 0))
	_ok(at > 0 and int(con_par["ataque"]) - int(sin_arma["ataque"]) == at,
		"2: el par de espadas suma %d de ataque y no %d" % [int(con_par["ataque"]) - int(sin_arma["ataque"]), at])
	_ok(is_equal_approx(float(ef1.get("cubrir", 0.0)) - float(ef0.get("cubrir", 0.0)), 0.30),
		"2: la pasiva del par no cuenta una vez (cubrir %s)" % ef1.get("cubrir", 0.0))
	_ok(eq.keys().count("arma") == 1 and not eq.has("arma2") and not eq.has("arma_izq"), "2: Garon tiene dos ranuras de arma")
	_ok(load("res://garon_3d.gd").DOS_ESPADAS, "2: Garon ya no lleva dos espadas en el modelo")
	# 3. Oro a 13
	var oro: Array = load("res://gremio.gd").RANGOS.filter(func(r): return r["nombre"] == "Oro")
	_ok(oro.size() == 1 and int(oro[0]["rep"]) == 13, "3: el rango Oro no pide 13 (%s)" % [oro])
	Engine.remove_meta("archivo_partida_prueba")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
