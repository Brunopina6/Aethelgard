extends SceneTree
# MEDIDA (15/11), no prueba: los tres especiales del Custodio de Porcelana (meshy_e01) como conjunto, en el combate del
# banco de pruebas (banco_pruebas.gd: partida BASE, nivel 12, GRUPOS[28], su interruptor). Datos aislados (ejecutor).
#   1. Cifras: PV, defensa y velocidad de cada héroe; vida, ataque y velocidad del Custodio; la geometría (distancias en
#      el suelo) y cuántos turnos de héroe caben en uno suyo.
#   2. Un ciclo entero de su rotación (10 turnos: Prensa, G, G, Avance, G, G, Sello, G, G, G) con los héroes quietos
#      (sin ATB) y curados antes de cada turno suyo: el daño de cada especial a cada héroe, cuánto se ve cada marca
#      antes de su impacto (fotogramas a 30 fps) y si llegan a verse dos marcas a la vez.
#   3. El combate del banco con los héroes atacando solos (sin defender ni curar: el caso pesimista, no la estrategia de
#      un jugador): turnos, qué hace él y PV del grupo al final.
# «semilla_medida=N» (por defecto 14112026), puesta tras add_child.
# No declara equilibrio: solo apunta lo observado.

var BP
var PE
var c = null
var semilla := 14112026
var marcas_a_la_vez := 0


func _initialize() -> void:
	BP = load("res://banco_pruebas.gd")
	PE = load("res://combate_meshy_e01.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semilla_medida="):
			semilla = int(a.get_slice("=", 1))
	_medir.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _combate() -> Dictionary:
	BP.preparar_partida()
	var d: Dictionary = BP.COMBATES["custodio"]
	BP.poner_grupo(d["activos"], BP.NIVEL_COMBATE)
	Engine.set_meta("banco_caso", "custodio")
	Engine.set_meta("meshy_e01", true)
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", int(d["grupo"]))
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(semilla)
	for e in c.enemigos:
		e["atb"] = randf() * 30.0
	await _esperar(20)
	for e in c.enemigos:
		if PE.es(e):
			return e
	return {}


func _dist_m(a: Vector2, b: Vector2) -> float:
	var d := b - a
	return Vector2(d.x, d.y / 0.32).length() / PE.px_por_m(c)


func _medir() -> void:
	await _esperar(5)
	# 1 y 2: el ciclo aislado
	var cus := await _combate()
	var grupo_pv := 0
	for h in c.heroes:
		grupo_pv += int(h["hp_max"])
		print("HEROE %s: PV %d, defensa %d, velocidad %.1f, a %.2f m de él" % [h["nombre"], h["hp_max"], int(h.get("def", 0)),
			float(h["vel"]), _dist_m(c._suelo_de(cus), c._suelo_de(h))])
	print("CUSTODIO: PV %d, ataque %d, velocidad %.1f; px/m %.1f; PV del grupo %d" % [cus["hp_max"], cus["atk"], cus["vel"],
		PE.px_por_m(c), grupo_pv])
	var vel_h := 0.0
	for h in c.heroes:
		vel_h += float(h["vel"])
	print("RITMO: por cada turno suyo, %.2f turnos de héroe (velocidades medias %.1f frente a %.1f)" % [
		vel_h / c.heroes.size() / float(cus["vel"]) * c.heroes.size(), vel_h / c.heroes.size(), float(cus["vel"])])
	var vel0 := {}
	for h in c.heroes:
		vel0[h["nombre"]] = float(h["vel"])
	for e in c.enemigos:
		e["vel"] = 0.0
		e["atb"] = 0.0
	var total := 0
	var por_especial := {}
	for k in 10:
		for h in c.heroes:
			h["vel"] = 0.0
			h["atb"] = 0.0
			h["hp"] = h["hp_max"]
			h["defendiendo"] = false
			h.erase("e01_lento")
		cus.erase("e01_lentos")
		var hp0 := {}
		for h in c.heroes:
			hp0[h["nombre"]] = int(h["hp"])
		var cont0: Dictionary = (cus.get("e01_contador", {}) as Dictionary).duplicate()
		cus["vel"] = 10.0
		cus["atb"] = c.ATB_MAX - 0.01
		var empezado := false
		var f_marca := -1
		var f_imp := -1
		for fr in 3000:
			await process_frame
			if is_same(c.atacante_actual, cus):
				empezado = true
				cus["vel"] = 0.0
			var vivas: int = PE.nodos_vivos(c.enemigos).size() + c.escena.find_children("Marca*", "", true, false).filter(
				func(n): return not n.is_queued_for_deletion()).size()
			marcas_a_la_vez = maxi(marcas_a_la_vez, c.escena.find_children("Marca*", "", true, false).filter(
				func(n): return not n.is_queued_for_deletion()).size())
			if vivas > 0 and f_marca < 0:
				f_marca = Engine.get_process_frames()
			var at: Dictionary = cus.get("e01_ataque", {})
			if not at.is_empty() and int(at.get("t_impacto", -1)) >= 0 and f_imp < 0:
				f_imp = int(at["t_impacto"])
			if empezado and c.atacante_actual == null:
				break
		await _esperar(5)
		var cont1: Dictionary = cus.get("e01_contador", {})
		var que := "nada"
		for q in ["prensa", "porton", "sello", "guardia"]:
			if int(cont1.get(q, 0)) > int(cont0.get(q, 0)):
				que = q
				break
		var danos := {}
		var suma := 0
		for h in c.heroes:
			var d: int = hp0[h["nombre"]] - int(h["hp"])
			if d > 0:
				danos[h["nombre"]] = d
				suma += d
		total += suma
		if que != "guardia":
			por_especial[que] = suma
		print("TURNO %d: %s · daño %s = %d (%.1f %% del grupo) · marca visible %s fotogramas antes del impacto" % [k + 1, que,
			danos, suma, 100.0 * suma / grupo_pv, str(f_imp - f_marca) if f_marca >= 0 and f_imp >= 0 else "-"])
	print("CICLO: 10 turnos suyos, daño %d = %.1f %% de los PV del grupo (%s); marcas a la vez como mucho: %d" % [total,
		100.0 * total / grupo_pv, por_especial, marcas_a_la_vez])
	c.queue_free()
	await _esperar(10)
	# 3: el combate del banco, los héroes atacando solos
	cus = await _combate()
	var grupo_pv2 := 0
	for h in c.heroes:
		grupo_pv2 += int(h["hp_max"])
	var acciones: Array = []
	var quien = null
	var cont_prev: Dictionary = {}
	var decidido := -1
	for fr in 20000:
		await process_frame
		var actual = c.atacante_actual
		if quien != null and not is_same(actual, quien):
			var cont1: Dictionary = cus.get("e01_contador", {})
			for q in ["prensa", "porton", "sello", "guardia"]:
				if int(cont1.get(q, 0)) > int(cont_prev.get(q, 0)):
					acciones.append(q)
			quien = null
		if actual != null and quien == null and is_same(actual, cus):
			quien = actual
			cont_prev = (cus.get("e01_contador", {}) as Dictionary).duplicate()
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			var alc: Array = c._alcanzables()
			if alc.is_empty():
				c._defender()
			else:
				c._menu_objetivo("atacar", "")
				c._confirmar_objetivo(alc[0])
		if c.estado == "fin":
			break
	var pv_fin := 0
	for h in c.heroes:
		pv_fin += maxi(0, int(h["hp"]))
	print("BANCO (héroes atacando solos): %s en %d turnos de héroe; él hizo %s (contador %s); PV del grupo %d → %d (%.1f %% perdido)" % [
		"gana el grupo" if cus["hp"] <= 0 else "no gana", c.turnos_heroe, acciones, cus.get("e01_contador", {}), grupo_pv2, pv_fin,
		100.0 * (grupo_pv2 - pv_fin) / grupo_pv2])
	c.queue_free()
	await _esperar(10)
	for k in BP.METAS_SESION + ["zona", "tipo_combate", "grupo_combate", BP.META, "archivo_partida_prueba"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	print("FIN MEDIDA")
	quit(0)
