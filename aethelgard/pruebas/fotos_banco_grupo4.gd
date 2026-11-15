extends SceneTree
# V12 (15/11/2026): el caso «Grupo de cuatro: Kael, Lya, Garon y Nix (prueba)» del banco de pruebas de Auditoría
# (banco_pruebas.gd), con ventana y datos aislados. El grupo de cuatro existe SOLO aquí (permiso de sesión
# «banco_grupo4», grupo.gd max_activos); el juego sigue con tres.
#   1. Coloca: los cuatro en el combate, en sitios distintos y separados, dentro de la pantalla, sin pisar a los enemigos.
#   2. Dibuja: una fila del grupo (nombre, PV, PM y ATB) por héroe, dentro de la pantalla y sin solaparse.
#   3. Turnos: con el ATB de verdad y ataques automáticos (NO es la estrategia de un jugador), los cuatro reciben turno y
#      abren su menú; se elige objetivo y el enemigo actúa. Capturas: el inicio, el menú de cada uno, la elección de
#      objetivo y un turno enemigo; y con la línea de turnos (turnos_v12) encendida, otra.
#   4. Sin el permiso (o fuera del banco), los mismos cuatro nombres dejan tres en el combate.
# Uso: -- salida=<carpeta>. Imprime «FALLO: …» y «FALLOS: n».

var salida := ""
var BP
var G
var fallos: Array = []
var hechos: Array = []
var c = null


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	BP = load("res://banco_pruebas.gd")
	G = load("res://grupo.gd")
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(salida.path_join(nombre))
	print("FOTO ", nombre)


func _combate(con_permiso: bool, turnos_v12 := false) -> void:
	BP.preparar_partida()
	var d: Dictionary = BP.COMBATES["grupo4"]
	BP.poner_grupo(d["activos"], BP.NIVEL_COMBATE)
	if not con_permiso:
		Engine.remove_meta(G.META_GRUPO4)
	Engine.set_meta("banco_caso", "grupo4")
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", int(d["grupo"]))
	Engine.set_meta("turnos_v12", turnos_v12)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	seed(15112026)
	await _esperar(40)


func _cerrar() -> void:
	c.queue_free()
	c = null
	await _esperar(10)
	Engine.remove_meta("turnos_v12")


func _probar() -> void:
	DirAccess.make_dir_recursive_absolute(salida)
	await _esperar(5)
	# 1 y 2: colocar y dibujar
	await _combate(true)
	var nombres: Array = c.heroes.map(func(h): return h["nombre"])
	_ok(nombres == ["Kael", "Lya", "Garon", "Nix"], "1: héroes en el combate %s" % [nombres])
	var vp: Vector2 = root.get_visible_rect().size
	var pies := {}
	for h in c.heroes:
		pies[h["nombre"]] = c._suelo_de(h)
		print("SITIO %s: pos %s, pies %s, centro %s" % [h["nombre"], h["pos"], c._suelo_de(h), c._centro(h)])
		_ok(Rect2(Vector2.ZERO, Vector2(1280, 720)).grow(-10).has_point(c._suelo_de(h)), "1: %s fuera de la pantalla" % h["nombre"])
	var minimo := 1e9
	for i in c.heroes.size():
		for j in range(i + 1, c.heroes.size()):
			minimo = minf(minimo, (pies[c.heroes[i]["nombre"]] as Vector2).distance_to(pies[c.heroes[j]["nombre"]]))
	_ok(minimo > 70.0, "1: dos héroes a %.0f px (pisándose)" % minimo)
	var min_enemigo := 1e9
	for h in c.heroes:
		for e in c.enemigos:
			min_enemigo = minf(min_enemigo, c._suelo_de(h).distance_to(c._suelo_de(e)))
	_ok(min_enemigo > 120.0, "1: un héroe a %.0f px de un enemigo" % min_enemigo)
	var filas: Array = c.menu.grupo
	_ok(filas.size() == 4, "2: %d filas del grupo (4)" % filas.size())
	var ys: Array = []
	for g in filas:
		var n: Control = g["nombre"]
		var r := n.get_global_rect()
		ys.append(r.position.y)
		_ok(r.end.y <= 720.0 and r.position.y >= 0.0, "2: la fila de %s se sale (%s)" % [g["heroe"]["nombre"], r])
	for i in range(1, ys.size()):
		_ok(ys[i] - ys[i - 1] >= 30.0, "2: filas del grupo solapadas (%s)" % [ys])
	hechos.append("1-2: cuatro en el combate (pies a ≥ %.0f px entre sí y ≥ %.0f px de los enemigos), 4 filas del grupo en y %s (ventana %s)" % [
		minimo, min_enemigo, ys, vp])
	await _foto("g4_inicio.png")
	# 3: turnos con el ATB de verdad
	var con_menu := {}
	var orden: Array = []
	var foto_objetivo := false
	var foto_enemigo := false
	var decidido := -1
	for fr in 30 * 90:
		await process_frame
		if c.estado == "fin":
			break
		if c.estado == "enemigo" and not foto_enemigo and c.atacante_actual != null:
			foto_enemigo = true
			await _esperar(20)
			await _foto("g4_turno_enemigo.png")
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			var n: String = c.actor["nombre"]
			orden.append(n)
			for h in c.heroes:                          # (que nadie caiga: se mira el reparto de turnos)
				h["hp"] = h["hp_max"]
			if not con_menu.has(n):
				con_menu[n] = true
				await _esperar(15)
				await _foto("g4_menu_%s.png" % n.to_lower())
			var alc: Array = c._alcanzables()
			if alc.is_empty():
				c._defender()
				continue
			c._menu_objetivo("atacar", "")
			if not foto_objetivo:
				foto_objetivo = true
				await _esperar(10)
				await _foto("g4_objetivo.png")
			c._confirmar_objetivo(alc[0])
		if con_menu.size() == 4 and orden.size() >= 8 and foto_enemigo:
			break
	for n in ["Kael", "Lya", "Garon", "Nix"]:
		_ok(con_menu.has(n), "3: %s no ha tenido turno (orden %s)" % [n, orden])
	_ok(foto_enemigo, "3: ningún enemigo ha actuado")
	hechos.append("3: turnos de héroe en orden %s; los cuatro abren su menú y atacan; un enemigo actúa" % [orden])
	await _cerrar()
	# 3b: la línea de turnos (apagada en el juego) con cuatro
	await _combate(true, true)
	var linea = null
	for n in c.find_children("*", "Control", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("combate_turnos_v12.gd"):
			linea = n
	if linea != null:
		var previstos: Array = linea.prever()
		var en_linea := {}
		for x in previstos:
			if x["f"].get("hero", false):
				en_linea[x["f"]["nombre"]] = true
		# (enseña los 6 turnos siguientes: el más lento, Garon, puede no caber; Nix, la cuarta, tiene que poder salir)
		var validos: bool = previstos.all(func(x): return c.heroes.has(x["f"]) or c.enemigos.has(x["f"]))
		_ok(validos and en_linea.has("Nix") and previstos.size() == linea.N, "3b: la línea de turnos prevé %s (%d)" % [
			en_linea.keys(), previstos.size()])
		hechos.append("3b: línea de turnos (turnos_v12): %d turnos previstos, héroes %s" % [previstos.size(), en_linea.keys()])
	else:
		print("AVISO: sin línea de turnos (turnos_v12) en este combate")
	await _esperar(60)
	await _foto("g4_linea_turnos.png")
	await _cerrar()
	# 4: sin el permiso, tres
	await _combate(false)
	var sin: Array = c.heroes.map(func(h): return h["nombre"])
	_ok(sin.size() == 3 and not "Nix" in sin and G.activos().size() == 3, "4: sin el permiso, %s en el combate y activos %s" % [sin, G.activos()])
	hechos.append("4: sin el permiso de sesión, los mismos cuatro nombres dejan %s" % [sin])
	await _foto("g4_sin_permiso.png")
	await _cerrar()
	BP.salir()
	_ok(not Engine.has_meta(G.META_GRUPO4) and G.max_activos() == G.MAX_ACTIVOS, "5: al salir del banco queda el permiso")
	print("OK: ", "\n    ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
