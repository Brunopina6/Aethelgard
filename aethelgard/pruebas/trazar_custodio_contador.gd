extends SceneTree
# TRAZA (15/11), no prueba: el contador del Custodio de Porcelana (meshy_e01) turno a turno en el caso del banco
# «custodio_rotacion» (banco_pruebas.gd: partida BASE, nivel 12, GRUPOS[28], vida ×8, su interruptor), con el ATB de
# verdad y los tres héroes atacando solos (Kael con Frostfang: cada golpe suyo congela; NO es la estrategia de un
# jugador). Datos aislados (ejecutor).
# Cada turno: segundo de juego, quién actúa, y en los del Custodio el texto de su etiqueta (lo que se ve sobre su cabeza)
# y el del panel ANTES y DESPUÉS, su recarga, el especial que toca, si está congelado y cuántos turnos de héroe ha
# habido desde su turno anterior.
# Argumentos: «semilla_traza=N» (por defecto 14112026, puesta tras add_child), «pensar=S» (segundos que el «jugador»
# se queda en el menú antes de atacar: el ATB sigue corriendo, como en el teléfono), «turnos=N» (turnos suyos que se
# trazan; por defecto 11).

var BP
var PE
var c = null
var semilla := 14112026
var pensar := 0.0
var turnos_max := 11


func _initialize() -> void:
	BP = load("res://banco_pruebas.gd")
	PE = load("res://combate_meshy_e01.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semilla_traza="):
			semilla = int(a.get_slice("=", 1))
		elif a.begins_with("pensar="):
			pensar = float(a.get_slice("=", 1))
		elif a.begins_with("turnos="):
			turnos_max = int(a.get_slice("=", 1))
	_trazar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _texto(cus: Dictionary) -> String:
	return "etiqueta «%s» · panel «%s» · recarga %d · toca %s · congelado %d" % [cus["lbl_estado"].text,
		" / ".join(PE.info(cus)), int(cus.get("e01_cd", 0)), PE._siguiente(cus), int(cus.get("congelado", 0))]


func _trazar() -> void:
	await _esperar(5)
	BP.preparar_partida()
	var d: Dictionary = BP.COMBATES["custodio_rotacion"]
	BP.poner_grupo(d["activos"], BP.NIVEL_COMBATE)
	Engine.set_meta("banco_caso", "custodio_rotacion")
	Engine.set_meta("meshy_e01", true)
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", int(d["grupo"]))
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(semilla)
	var cus: Dictionary = {}
	for e in c.enemigos:
		if PE.es(e):
			cus = e
	print("TRAZA semilla %d · pensar %.1f s · Custodio PV %d, velocidad %.1f · héroes %s" % [semilla, pensar, cus["hp_max"],
		cus["vel"], ", ".join(c.heroes.map(func(h): return "%s vel %.1f" % [h["nombre"], h["vel"]]))])
	var f0 := Engine.get_process_frames()
	var suyos := 0
	var de_heroe := 0
	var en_su_turno := false
	var cont_prev: Dictionary = {}
	var decidido := -1
	var menu_desde := -1
	var antes := ""
	var etiqueta_prev := ""
	for fr in 30 * 60 * 20:
		await process_frame
		if not is_instance_valid(c) or c.estado == "fin":
			break
		var t := (Engine.get_process_frames() - f0) / 30.0
		if cus["lbl_estado"].text != etiqueta_prev:
			etiqueta_prev = cus["lbl_estado"].text
			print("  %6.1f s   etiqueta → «%s»" % [t, etiqueta_prev])
		if not en_su_turno and not is_same(c.atacante_actual, cus):
			antes = _texto(cus)                              # (lo de justo antes: su turno cuenta y escribe al empezar)
			cont_prev = (cus.get("e01_contador", {}) as Dictionary).duplicate()
		elif not en_su_turno:
			en_su_turno = true
			suyos += 1
			print("%6.1f s  TURNO SUYO %d (tras %d turnos de héroe)  ANTES: %s" % [t, suyos, de_heroe, antes])
			de_heroe = 0
		elif en_su_turno and c.atacante_actual == null:
			en_su_turno = false
			await _esperar(2)
			var cont1: Dictionary = cus.get("e01_contador", {})
			var que := "nada"
			for q in ["prensa", "porton", "sello", "guardia"]:
				if int(cont1.get(q, 0)) > int(cont_prev.get(q, 0)):
					que = q
			print("%6.1f s     hizo: %s · DESPUÉS: %s" % [t, que, _texto(cus)])
			if suyos >= turnos_max:
				break
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			if menu_desde < 0:
				menu_desde = Engine.get_process_frames()
			if (Engine.get_process_frames() - menu_desde) / 30.0 < pensar:
				continue
			menu_desde = -1
			decidido = c.turnos_heroe
			de_heroe += 1
			var alc: Array = c._alcanzables()
			print("%6.1f s  héroe: %s ataca (ATB del Custodio %.0f)" % [t, c.actor["nombre"], cus["atb"]])
			if alc.is_empty():
				c._defender()
			else:
				c._menu_objetivo("atacar", "")
				c._confirmar_objetivo(alc[0])
	print("FIN TRAZA: %d turnos suyos, contador %s, PV %d/%d, %.1f s de juego" % [suyos, cus.get("e01_contador", {}),
		cus["hp"], cus["hp_max"], (Engine.get_process_frames() - f0) / 30.0])
	c.queue_free()
	await _esperar(10)
	BP.salir()
	quit(0)
