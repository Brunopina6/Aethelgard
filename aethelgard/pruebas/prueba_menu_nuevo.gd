extends SceneTree
# El menú de combate con el dedo (menu_combate.gd y combate.gd), en un combate de verdad, sin ventana y con datos
# aislados. Reescrita el 19/11 (PC-8): la de antes tocaba posiciones fijas de antes del HUD nuevo (T-099), solo
# imprimía lo que pasaba y no comprobaba nada. Ahora cada toque va al CENTRO del nodo de hoy (fila, flecha, cabecera,
# zona del enemigo), con toques SIMULADOS de verdad (InputEventScreenTouch y arrastre InputEventScreenDrag, que Godot
# convierte en clic y movimiento como en el móvil), pasados por la transformada de la ventana raíz (sin ventana mide
# 100 × 100 y el juego se escala a ella). Lo que ya prueban otras no se repite: pestañas de magia, Compás y tocar a un
# héroe (prueba_controles_nuevos), filas apagadas con el dedo (prueba_hud_combate), mando y teclado (prueba_mando).
#   1. Turno de Kael (Kael nivel 9 y Lya nivel 10 contra dos Slimes): deslizar el dedo sobre ATACAR la gira a DEFENDER
#      sin ejecutar nada; tocar su flecha la devuelve a ATACAR.
#   2. Tocar MAGIA abre su submenú; tocar la cabecera «‹ Kael» vuelve al menú.
#   3. Tocar ATACAR pide objetivo; tocar al enemigo lo ataca (Kael actúa una vez y el enemigo pierde vida).
#   4. Turno de Lya con la Armonía llena (puesta a mano: c.armonia = 1.0 y c._mostrar_menu(), un atajo de prueba, no
#      el llenado del combate): tocar INVOCACIÓN, luego Érebo y luego al enemigo invoca. Se comprueba que la Armonía
#      queda a 0 tras tocar al enemigo y que la invocación termina (vuelta al menú, enemigos derrotados o «Fin»); que
#      no se gaste dos veces no se mira aparte (revisión 19/11). Al final se huye para no dejar nada a medias.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const ARCHIVO := "user://prueba_menu_nuevo.save"

var P
var G
var c = null
var fallos: Array = []
var hechos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 10.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _pantalla(p: Vector2) -> Vector2:
	return root.get_final_transform() * p


# Un toque en «p» (coordenadas del juego, 1280 × 720): el dedo baja y sube.
func _tocar(p: Vector2, esperar := 4) -> void:
	for pulsado in [true, false]:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = _pantalla(p)
		t.pressed = pulsado
		Input.parse_input_event(t)
		await _esperar(2)
	await _esperar(esperar)


# Deslizar el dedo de «a» a «b» en 4 pasos.
func _deslizar(a: Vector2, b: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = _pantalla(a)
	t.pressed = true
	Input.parse_input_event(t)
	await _esperar(2)
	var ant := a
	for i in 4:
		var p := a.lerp(b, (i + 1) / 4.0)
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = _pantalla(p)
		d.relative = _pantalla(p) - _pantalla(ant)
		Input.parse_input_event(d)
		ant = p
		await _esperar(1)
	t = InputEventScreenTouch.new()
	t.index = 0
	t.position = _pantalla(b)
	t.pressed = false
	Input.parse_input_event(t)
	await _esperar(6)


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _fila(texto: String) -> Dictionary:
	for f in c.menu.filas:
		if str(f["item"].get("texto", "")).begins_with(texto):
			return f
	return {}


func _centro_fila(texto: String) -> Vector2:
	var f := _fila(texto)
	return f["nodo"].get_global_rect().get_center() if not f.is_empty() else Vector2(-1, -1)


func _carta() -> Dictionary:
	for f in c.menu.filas:
		if f["item"].get("tipo", "") == "carta":
			return f
	return {}


# Espera el menú de «quien»; a los demás, mientras, los pone en guardia (sin toques: no es lo que se prueba).
func _turno_de(quien: String) -> bool:
	var limite := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < limite:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == quien:
				await _esperar(3)
				return true
			c._defender()
		await _esperar(1)
	return false


func _vida_enemigos() -> int:
	var total := 0
	for e in c.enemigos:
		total += maxi(0, int(e["hp"]))
	return total


func _vivo() -> Dictionary:
	for e in c.enemigos:
		if e["hp"] > 0:
			return e
	return {}


func _probar() -> void:
	await _esperar(5)
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in {"Kael": 9, "Lya": 10}:
		G.datos()[n]["nivel"] = {"Kael": 9, "Lya": 10}[n]
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "desierto")          # sin «zona limpia»: los Slimes no huyen solos
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 8)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _kael()
	await _lya()
	await _huir()
	if c != null:
		c.queue_free()
	await _esperar(3)
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK menú con el dedo: ", ", ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1-3. Kael: la carta, MAGIA y atrás, ATACAR y el enemigo.
func _kael() -> void:
	if not await _turno_de("Kael"):
		_fallo("1: no llega el turno de Kael")
		return
	var kael := _heroe("Kael")
	# 1. deslizar sobre ATACAR → DEFENDER (sin ejecutar), y la flecha → ATACAR
	var carta := _carta()
	if carta.is_empty() or carta["lado"] != "a":
		_fallo("1: el menú de Kael no empieza con la carta en ATACAR (%s)" % [carta.get("lado", "sin carta")])
		return
	var r: Rect2 = carta["nodo"].get_global_rect()
	await _deslizar(r.get_center() - Vector2(60, 0), r.get_center() + Vector2(60, 0))
	carta = _carta()
	if carta.is_empty() or carta["lado"] != "b" or c.menu.carta_lado.get("Kael", "a") != "b":
		_fallo("1: deslizar el dedo sobre ATACAR no la gira a DEFENDER (lado %s)" % [carta.get("lado", "?")])
	elif c.estado != "menu" or c.actor != kael:
		_fallo("1: deslizar sobre la carta ha ejecutado algo (estado %s)" % c.estado)
	else:
		hechos.append("deslizar gira a DEFENDER")
	print("1. deslizar sobre ATACAR: lado %s, estado %s" % [carta.get("lado", "?"), c.estado])
	if carta.is_empty():                              # el menú ya no está (p. ej. ha ejecutado ATACAR): no se sigue
		return
	var flecha: Control = null
	for h in carta["nodo"].get_children():
		if h is Control and h.gui_input.is_connected(c.menu._toque_flecha):
			flecha = h
			break
	if flecha == null:
		_fallo("1: la carta no tiene su flecha que se toca")
	else:
		await _tocar(flecha.get_global_rect().get_center())
		carta = _carta()
		if carta.get("lado", "?") != "a" or c.estado != "menu":   # (revisión 19/11) sin carta: FALLO, no error de script
			_fallo("1: tocar la flecha no devuelve la carta a ATACAR (lado %s, estado %s)" % [carta.get("lado", "sin carta"), c.estado])
		else:
			hechos.append("flecha vuelve a ATACAR")
		print("1. flecha: lado %s, estado %s" % [carta.get("lado", "sin carta"), c.estado])
	# 2. MAGIA y la cabecera «‹ Kael»
	await _tocar(_centro_fila("MAGIA"))
	if c.estado != "magia" or not c.menu.submenu_abierto:
		_fallo("2: tocar MAGIA no abre su submenú (estado %s)" % c.estado)
	else:
		await _tocar(c.menu.cab.get_global_rect().get_center())
		if c.estado != "menu" or c.menu.submenu_abierto or _fila("ATACAR").is_empty():
			_fallo("2: tocar la cabecera «‹ Kael» no vuelve al menú (estado %s, submenú %s)" % [c.estado, c.menu.submenu_abierto])
		else:
			hechos.append("MAGIA y vuelta con la cabecera")
	print("2. MAGIA y cabecera: estado %s, submenú %s" % [c.estado, c.menu.submenu_abierto])
	# 3. ATACAR y el enemigo
	await _tocar(_centro_fila("ATACAR"))
	if c.estado != "objetivo" or c.objetivos_posibles.is_empty():
		_fallo("3: tocar ATACAR no pide objetivo (estado %s)" % c.estado)
		return
	var vida := _vida_enemigos()
	var e := _vivo()
	await _tocar(c._a_pantalla(c._centro(e)))
	if not await _hasta(func(): return c.estado != "objetivo", 2.0):
		_fallo("3: tocar al enemigo no lo elige (sigue en «objetivo»)")
		return
	if not await _hasta(func(): return _vida_enemigos() < vida, 15.0):
		_fallo("3: Kael no quita vida al enemigo tocado (%d → %d)" % [vida, _vida_enemigos()])
	else:
		hechos.append("ATACAR tocando al enemigo (%d → %d PV)" % [vida, _vida_enemigos()])
	print("3. ATACAR y enemigo: vida de los enemigos %d → %d" % [vida, _vida_enemigos()])


# 4. Lya invoca con el dedo.
func _lya() -> void:
	if _vivo().is_empty():
		_fallo("4: no queda ningún enemigo para la invocación")
		return
	if not await _turno_de("Lya"):
		_fallo("4: no llega el turno de Lya")
		return
	c.armonia = 1.0
	c.menu.poner_armonia(1.0)
	c._mostrar_menu()                                 # el menú, con la Armonía llena (como al llenarse en el turno)
	await _esperar(4)
	var fila := _fila("INVOCACIÓN")
	if fila.is_empty() or fila["item"].get("apagado", false):
		_fallo("4: con la Armonía llena, Lya no tiene INVOCACIÓN encendida (%s)" % [fila.get("item", {}).get("motivo", "sin fila")])
		return
	await _tocar(_centro_fila("INVOCACIÓN"))
	if c.estado != "invocacion" or _fila("Érebo").is_empty():
		_fallo("4: tocar INVOCACIÓN no abre su submenú con Érebo (estado %s)" % c.estado)
		return
	await _tocar(_centro_fila("Érebo"))
	if c.estado != "objetivo":
		_fallo("4: tocar Érebo no pide objetivo (estado %s)" % c.estado)
		return
	await _tocar(c._a_pantalla(c._centro(_vivo())))
	if not await _hasta(func(): return c.armonia < 0.01 and c.estado != "objetivo", 3.0):
		_fallo("4: tocar al enemigo no invoca (estado %s, Armonía %.2f)" % [c.estado, c.armonia])
		return
	print("4. invocación: «%s», estado %s" % [c.registro.text, c.estado])
	# que termine (o saltarla, como el jugador) y el combate siga
	if not await _hasta(_tras_invocar, 120.0):
		_fallo("4: la invocación no termina en 120 s (estado %s)" % c.estado)
		return
	hechos.append("INVOCACIÓN → Érebo → enemigo con el dedo")


func _tras_invocar() -> bool:
	return c.estado == "menu" or c.enemigos.all(func(x): return x["hp"] <= 0) or c.menu.heroe_actual.get("nombre", "") == "Fin"


func _huir() -> void:
	if c.menu.heroe_actual.get("nombre", "") == "Fin" or c.enemigos.all(func(x): return x["hp"] <= 0):
		return
	if await _turno_de("Kael"):
		c._escapar()
	if not await _hasta(func(): return c.menu.heroe_actual.get("nombre", "") == "Fin", 20.0):
		_fallo("el combate no termina al huir")
