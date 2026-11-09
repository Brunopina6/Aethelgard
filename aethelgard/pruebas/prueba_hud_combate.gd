extends SceneTree
# El HUD de combate (T-099, y la parte de T-100 y T-101 que va en el HUD), en combates de verdad (combate.tscn), sin
# ventana y con datos aislados. El combate no guarda (sin «desde_mapa») y la partida apunta a su propio archivo.
#   1. Grupos de 1, 2 y 3: una fila por héroe presente con su barra de PM y su cifra «actual/máximo» (también Garon), las
#      etiquetas PV · PM · ATB encima, nada del grupo recoge toques, y el bloque no pisa órdenes, explicaciones, la vida
#      de los enemigos ni las zonas para elegir objetivo.
#   2. Los PM, con los valores de verdad: magia (Fuego), Esgrima (Juicio), Embuir, Éter, el máximo que cambia, 0 PM y un
#      héroe caído; a la vista con el turno de un enemigo y con el menú cerrado; la barra llega a su valor.
#   3. Motivos de lo apagado: MAGIA, ESGRIMA y EMBUIR sin PM, OBJETO sin objetos, HUIR contra un jefe; las magias que no
#      se pueden pagar; el Compás con Lya esperando. Con el mando (↓ llega a la fila apagada y A no hace nada) y con el
#      dedo (tocarla la elige y enseña el motivo).
#   4. Érebo en el HUD: «N %», «INVOCACIÓN LISTA», «LYA HA CAÍDO» y, sin Lya, «Nadie puede invocar»; las reglas, las de
#      siempre (lista = Armonía llena y Lya en pie).
#   5. Señas de las artes: Compás (anillo «alba» sobre Lya, Kael se vuelve hacia ella), Peso del Ocaso («ocaso» sobre
#      cada enemigo), Lumbre de Retorno («lumbre», la fila de Kael se ilumina, «¡Kael vuelve!») y Segundo Aliento (una
#      hoja por turno y los turnos junto al icono). Cada sonido se pide UNA vez y en el fotograma en que el arte se aplica
#      (con la señal «sonido_pedido»: vale aunque el archivo de sonido aún no esté en el catálogo). Las señas no usan
#      partículas: se ven igual en el perfil bajo.
# Los combates con guion no prueban la estrategia de un jugador: solo que el HUD dice la verdad y no estorba.

const ARCHIVO := "user://prueba_hud_combate.save"
const BOTONES := {"aceptar": JOY_BUTTON_A, "abajo": JOY_BUTTON_DPAD_DOWN, "arriba": JOY_BUTTON_DPAD_UP}

var P
var G
var I
var A
var M
var c = null
var congelar := true
var fotograma := 0
var fallos: Array = []
var hechos: Array = []
var sonidos: Array = []                           # [nombre, fotograma]


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	A = load("res://artes.gd")
	M = load("res://menu_combate.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		fotograma += 1
		if congelar and c != null and is_instance_valid(c):
			for e in c.enemigos:
				e["atb"] = 0.0


func _hasta(cond: Callable, max := 600) -> bool:
	for i in max:
		if cond.call():
			return true
		await _esperar(1)
	return cond.call()


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "inventario"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _fila_grupo(n: String) -> Dictionary:
	for g in c.menu.grupo:
		if g["heroe"]["nombre"] == n:
			return g
	return {}


func _pulsar(que: String) -> void:
	for pulsado in [true, false]:
		var b := InputEventJoypadButton.new()
		b.device = 0
		b.button_index = BOTONES[que]
		b.pressed = pulsado
		Input.parse_input_event(b)
		await _esperar(2)
	await _esperar(3)


# Un toque en «p» (coordenadas del juego): sin ventana, la ventana raíz mide 100 × 100 (prueba_controles_nuevos.gd).
func _tocar(p: Vector2) -> void:
	for pulsado in [true, false]:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = root.get_final_transform() * p
		t.pressed = pulsado
		Input.parse_input_event(t)
		await _esperar(2)
	await _esperar(3)


func _combate(activos: Dictionary, zona := "desierto", grupo := 2, tipo := "normal") -> void:
	_limpiar()
	G.datos()
	I.datos()
	Engine.set_meta("grupo_activo", activos.keys())
	for n in activos:
		G.datos()[n]["nivel"] = activos[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["libros"] = {}
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", zona)
	Engine.set_meta("tipo_combate", tipo)
	Engine.set_meta("grupo_combate", grupo)
	congelar = true
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	c.sonido_pedido.connect(func(n: String): sonidos.append([n, fotograma]))
	for e in c.enemigos:
		e["atb"] = 0.0


func _cerrar() -> void:
	if c != null:
		c.queue_free()
		c = null
	await _esperar(5)


# Espera al menú de un héroe; a los demás los pone en guardia.
func _turno_de(n: String) -> bool:
	for i in 2400:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == n:
				await _esperar(4)
				return true
			c._defender()
		await _esperar(1)
	_ok(false, "no llega el turno de " + n)
	return false


func _libre() -> bool:
	return c.estado == "esperando" or c.estado == "menu"


func _probar() -> void:
	await _esperar(10)
	await _grupos()
	await _pm()
	await _motivos()
	await _erebo()
	await _senas()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ---------------------------------------------------------------- 1. grupos de 1, 2 y 3
# El rectángulo de lo que se ve de una etiqueta (su texto, con su alineación), en la pantalla del juego.
func _caja_texto(l: Label) -> Rect2:
	var f: Font = l.get_theme_font("font")
	var tam: int = l.get_theme_font_size("font_size")
	var ancho := f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var r := l.get_global_rect()
	var x := r.position.x
	if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x = r.end.x - ancho
	elif l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x = r.position.x + (r.size.x - ancho) * 0.5
	return Rect2(x, r.position.y, ancho, r.size.y)


# Todo lo que dibuja el bloque del grupo (etiquetas de columna, nombres, PV, PM y sus barras, ATB).
func _cajas_grupo() -> Array:
	var r: Array = []
	for l in c.menu.etiquetas_grupo:
		r.append(_caja_texto(l))
	for g in c.menu.grupo:
		for k in ["nombre", "pv", "pm"]:
			r.append(_caja_texto(g[k]))
		for k in ["pm_fondo", "fondo"]:
			r.append(g[k].get_global_rect())
	return r


func _pisa(a: Rect2, cajas: Array) -> bool:
	for b in cajas:
		if a.grow(-1.0).intersects(b.grow(-1.0)):
			return true
	return false


func _grupos() -> void:
	var todos := {"Kael": 10, "Lya": 10, "Garon": 10}
	for n in [1, 2, 3]:
		var activos := {}
		for k in todos.keys().slice(0, n):
			activos[k] = todos[k]
		_combate(activos, "desierto", {1: 7, 2: 8, 3: 2}[n])
		await _turno_de("Kael")
		var m = c.menu
		_ok(m.grupo.size() == n, "%d: el grupo tiene %d filas" % [n, m.grupo.size()])
		_ok(m.etiquetas_grupo.map(func(l): return l.text) == ["PV", "PM", "ATB"], "%d: las etiquetas de las columnas" % n)
		var pv0: Label = m.grupo[0]["pv"]
		for l in m.etiquetas_grupo:                  # su centro, bastante más arriba que el de las cifras del primero
			_ok(l.position.y + l.size.y * 0.5 < pv0.position.y + pv0.size.y * 0.5 - 18.0,
				"%d: la etiqueta %s no va encima de la primera fila" % [n, l.text])
		for g in m.grupo:
			var h: Dictionary = g["heroe"]
			_ok(g["pm"].text == "%d/%d" % [h["mp"], h["mp_max"]], "%d: los PM de %s dicen %s" % [n, h["nombre"], g["pm"].text])
			_ok(g["pm"].is_visible_in_tree() and g["pm_relleno"].is_visible_in_tree(), "%d: los PM de %s no se ven" % [n, h["nombre"]])
			_ok(absf(g["pm_relleno"].size.x - M.ANCHO_PM * float(h["mp"]) / h["mp_max"]) < 1.0, "%d: la barra de PM de %s" % [n, h["nombre"]])
			_ok(g["pm_relleno"].color == M.PM_AZUL, "%d: la barra de PM de %s no es azul" % [n, h["nombre"]])
			for k in ["nombre", "pv", "pm", "pm_fondo", "pm_relleno", "pm_rastro", "fondo", "relleno", "brillo", "estados", "destello"]:
				_ok(g[k].mouse_filter == Control.MOUSE_FILTER_IGNORE, "%d: %s de %s recoge toques" % [n, k, h["nombre"]])
		for l in m.etiquetas_grupo + [m.armonia_estado]:
			_ok(l.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%d: la etiqueta %s recoge toques" % [n, l.text])
		var cajas := _cajas_grupo()
		for i in cajas.size():                       # nada del bloque se sale de la pantalla ni del lado del menú
			_ok(cajas[i].position.x >= m.X_TEXTO - 1.0 and cajas[i].end.x <= m.X_DERECHA + 1.0 and cajas[i].end.y <= 712.0,
				"%d: una pieza del grupo se sale (%s)" % [n, cajas[i]])
		# órdenes (Kael tiene las cinco), y el submenú más alto de Kael con su explicación
		for f in m.filas:
			_ok(not _pisa(f["nodo"].get_global_rect(), cajas), "%d: la orden %s pisa el grupo" % [n, f["item"]["texto"]])
		c._menu_magia(1)
		await _esperar(3)
		_ok(not _pisa(Rect2(m.desc.global_position, Vector2(m.desc.size.x, m.desc.get_line_count() * m.desc.get_line_height())), cajas),
			"%d: la explicación de la magia pisa el grupo" % n)
		for f in m.filas:
			_ok(not _pisa(f["nodo"].get_global_rect(), cajas), "%d: la fila %s pisa el grupo" % [n, f["item"]["texto"]])
		# la vida y los estados de los enemigos
		for e in c.enemigos:
			_ok(not _pisa(_caja_texto(e["lbl_hp"]), cajas) and not _pisa(e["barra_hp"].get_global_rect(), cajas),
				"%d: la vida de %s pisa el grupo" % [n, e["nombre"]])
		# las zonas para elegir objetivo: enemigos y, con más de uno, aliados
		c._menu_objetivo("atacar", "")
		await _esperar(3)
		for z in c.capa_zonas.get_children():
			_ok(not _pisa(z.get_global_rect(), cajas), "%d: una zona de objetivo (enemigo) pisa el grupo" % n)
		c._atras()
		await _esperar(2)
		if n >= 2:
			c._elegir_hechizo("Alba", 1)
			await _esperar(3)
			_ok(c.estado == "objetivo" and c.capa_zonas.get_child_count() == n - 1, "%d: el Compás no pide aliado" % n)
			for z in c.capa_zonas.get_children():
				_ok(not _pisa(z.get_global_rect(), cajas), "%d: una zona de objetivo (aliado) pisa el grupo" % n)
			c._atras()
			await _esperar(2)
		await _cerrar()
	hechos.append("1: grupos de 1, 2 y 3 (filas, etiquetas, sin toques, sin pisar órdenes, explicaciones, vidas ni zonas)")


# ---------------------------------------------------------------- 2. los PM de verdad
func _comprobar_pm(n: String, que: String) -> void:
	var g := _fila_grupo(n)
	var h: Dictionary = g["heroe"]
	_ok(g["pm"].text == "%d/%d" % [h["mp"], h["mp_max"]], "%s: los PM de %s dicen %s y son %d/%d" % [que, n, g["pm"].text, h["mp"], h["mp_max"]])
	_ok(is_equal_approx(g["pm_meta"], float(h["mp"]) / maxi(1, h["mp_max"])), "%s: la barra de %s no va a su valor" % [que, n])
	_ok(g["pm"].is_visible_in_tree() and g["pm_relleno"].is_visible_in_tree(), "%s: los PM de %s no se ven" % [que, n])


func _barra_llega(n: String, que: String) -> void:
	await _esperar(24)                               # 0,8 s: rastro y subida, acabados
	var g := _fila_grupo(n)
	var h: Dictionary = g["heroe"]
	var ancho: float = M.ANCHO_PM * float(h["mp"]) / maxi(1, h["mp_max"])
	_ok(absf(g["pm_relleno"].size.x - ancho) < 1.0 and absf(g["pm_rastro"].size.x - ancho) < 1.0,
		"%s: la barra de %s mide %.1f (rastro %.1f) y debería %.1f" % [que, n, g["pm_relleno"].size.x, g["pm_rastro"].size.x, ancho])


func _pm() -> void:
	_combate({"Kael": 10, "Lya": 10, "Garon": 10}, "desierto", 2)
	if not await _turno_de("Kael"):
		return
	var kael := _heroe("Kael")
	var lya := _heroe("Lya")
	var garon := _heroe("Garon")
	var pm0: int = kael["mp"]
	c._elegir_hechizo("Fuego", 1, true)              # magia: 8 PM
	await _esperar(2)
	_ok(kael["mp"] == pm0 - 8, "magia: Fuego no gasta 8 PM")
	_comprobar_pm("Kael", "magia")
	# el menú cerrado y el turno de un enemigo: los PM siguen a la vista
	_ok(not c.menu.bloque.visible or not c.menu.activo, "magia: el menú sigue abierto mientras se lanza")
	await _barra_llega("Kael", "magia")
	await _hasta(_libre, 400)
	congelar = false
	for e in c.enemigos:
		e["atb"] = 0.0
	c.enemigos.filter(func(e): return e["hp"] > 0)[0]["atb"] = 99.9
	var visto := false
	for i in 400:
		if c.estado == "enemigo":
			for n in ["Kael", "Lya", "Garon"]:
				_comprobar_pm(n, "turno del enemigo")
			_ok(not c.menu.bloque.visible, "turno del enemigo: el menú está abierto")
			visto = true
			break
		if c.estado == "menu" and c.menu.activo:
			c._defender()
		await _esperar(1)
	_ok(visto, "no llega el turno de un enemigo")
	await _hasta(func(): return c.estado != "enemigo", 400)
	congelar = true
	# Esgrima y Embuir (Garon)
	if not await _turno_de("Garon"):
		return
	pm0 = garon["mp"]
	c._tecnica_garon("Juicio", c.enemigos.filter(func(e): return e["hp"] > 0)[0])
	await _esperar(2)
	_ok(garon["mp"] == pm0 - 6, "Esgrima: Juicio no gasta 6 PM")
	_comprobar_pm("Garon", "Esgrima")
	await _barra_llega("Garon", "Esgrima")
	await _hasta(_libre, 400)
	if not await _turno_de("Garon"):
		return
	pm0 = garon["mp"]
	c._embuir("Fuego")
	await _esperar(2)
	_ok(garon["mp"] == pm0 - 5, "Embuir no gasta 5 PM")
	_comprobar_pm("Garon", "Embuir")
	await _barra_llega("Garon", "Embuir")
	await _hasta(_libre, 400)
	# Éter: sube
	if not await _turno_de("Lya"):
		return
	lya["mp"] = 3
	await _esperar(30)
	I.agregar_objeto("Éter", 1)
	c._usar_objeto("Éter", lya)
	await _esperar(2)
	_ok(lya["mp"] == mini(28, lya["mp_max"]), "Éter: Lya no recupera 25 PM (%d)" % lya["mp"])
	_comprobar_pm("Lya", "Éter")
	await _barra_llega("Lya", "Éter")
	await _hasta(_libre, 400)
	# el máximo cambia (al subir de nivel cambia así: combate.gd _repartir_exp)
	kael["mp_max"] += 10
	await _esperar(2)
	_comprobar_pm("Kael", "máximo")
	await _barra_llega("Kael", "máximo")
	# 0 PM
	kael["mp"] = 0
	await _esperar(2)
	_comprobar_pm("Kael", "0 PM")
	await _barra_llega("Kael", "0 PM")
	_ok(_fila_grupo("Kael")["pm_relleno"].size.x < 0.5, "0 PM: la barra no queda vacía")
	_ok(_fila_grupo("Kael")["pm"].get_theme_color("font_color").a < 0.8, "0 PM: la cifra no se apaga")
	# caído
	c._quitar_pv(lya, 99999)
	await _esperar(3)
	var gl := _fila_grupo("Lya")
	_ok(gl["pm"].get_theme_color("font_color") == M.GRIS_APAGADO and gl["pv"].get_theme_color("font_color") == M.GRIS_APAGADO,
		"caída: los PV y los PM de Lya no se apagan")
	_ok(gl["pm_relleno"].color != M.PM_AZUL and gl["relleno"].color.a < 0.5, "caída: sus barras no se apagan")
	_comprobar_pm("Lya", "caída")
	await _cerrar()
	hechos.append("2: PM con Fuego, Juicio, Embuir, Éter, el máximo, 0 PM y Lya caída; a la vista con el enemigo y el menú cerrado")


# ---------------------------------------------------------------- 3. motivos de lo apagado
func _fila(texto: String) -> int:
	for i in c.menu.filas.size():
		if str(c.menu.filas[i]["item"].get("texto", "")) == texto:
			return i
	return -1


func _motivo_orden(texto: String) -> String:
	var i := _fila(texto)
	if i < 0 or not c.menu.filas[i].has("motivo"):
		return ""
	var l: Label = c.menu.filas[i]["motivo"]
	return l.text if l.is_visible_in_tree() else ""


func _motivos() -> void:
	_combate({"Kael": 10, "Lya": 10, "Garon": 10}, "desierto", 2)
	if not await _turno_de("Kael"):
		return
	var kael := _heroe("Kael")
	var m = c.menu
	kael["mp"] = 0
	c._mostrar_menu()
	await _esperar(4)
	_ok(m.filas[_fila("MAGIA")]["item"]["apagado"] and _motivo_orden("MAGIA") == "Necesitas 6 PM",
		"MAGIA sin PM no dice por qué («%s»)" % _motivo_orden("MAGIA"))
	_ok(_motivo_orden("INVOCACIÓN").begins_with("Armonía al "), "INVOCACIÓN no dice cuánta Armonía falta («%s»)" % _motivo_orden("INVOCACIÓN"))
	_ok(_motivo_orden("ATACAR") == "" and _motivo_orden("OBJETO") == "", "una orden encendida tiene motivo")
	# mando: ↓ desde ATACAR llega a MAGIA (apagada); A no la abre; ↓ sigue a INVOCACIÓN
	_ok(m.sel == 0, "el menú no empieza en ATACAR")
	await _pulsar("abajo")
	_ok(m.sel == _fila("MAGIA"), "mando: ↓ se salta MAGIA apagada (fila %d)" % m.sel)
	_ok(m.filas[m.sel]["motivo"].get_theme_color("font_color").a > 0.85, "mando: el motivo de la fila elegida no se aclara")
	await _pulsar("aceptar")
	_ok(c.estado == "menu" and m.sel == _fila("MAGIA"), "mando: A en MAGIA apagada hace algo (estado %s)" % c.estado)
	await _pulsar("abajo")
	_ok(m.sel == _fila("INVOCACIÓN"), "mando: ↓ desde MAGIA no llega a INVOCACIÓN (fila %d)" % m.sel)
	# el dedo: tocar MAGIA la elige (y su motivo ya está a la vista); no la abre
	var centro: Vector2 = m.filas[_fila("MAGIA")]["nodo"].get_global_rect().get_center()
	await _tocar(centro)
	_ok(m.sel == _fila("MAGIA") and c.estado == "menu", "dedo: tocar MAGIA apagada no la elige o la abre (fila %d, %s)" % [m.sel, c.estado])
	# el submenú de magia (todas sin pagar): la primera, elegida, dice cuántos PM faltan
	c._menu_magia(1)
	await _esperar(4)
	_ok(m.sel == 0 and m.desc.text == "Necesitas 8 PM: tienes 0.", "magias sin PM: «%s» (fila %d)" % [m.desc.text, m.sel])
	_ok(m.filas.all(func(f): return f["item"].get("falta_pm", false)), "magias sin PM: el coste no avisa")
	await _pulsar("abajo")
	_ok(m.sel == 1 and m.desc.text == "Necesitas 7 PM: tienes 0.", "mando en Rayo: «%s» (fila %d)" % [m.desc.text, m.sel])
	# el Compás con Lya y Garon esperando su turno (y el mando y el dedo sobre él)
	kael["mp"] = 34
	var lya := _heroe("Lya")
	var espera := "Lya y Garon ya esperan su turno."
	lya["atb"] = 99.95
	_heroe("Garon")["atb"] = 99.95
	await _esperar(3)
	c._menu_magia(4)
	await _esperar(4)
	var i_compas := _fila("Compás del Alba")
	_ok(i_compas == 0 and m.filas[0]["item"]["apagado"] and m.filas[0]["item"]["desc"] == espera,
		"el Compás con Lya y Garon esperando: %s" % [m.filas[0]["item"] if not m.filas.is_empty() else {}])
	_ok(m.sel == 1, "el Compás apagado: la elegida al abrir no es Peso del Ocaso (fila %d)" % m.sel)
	await _pulsar("arriba")
	_ok(m.sel == 0 and m.desc.text == espera, "mando: ↑ no llega al Compás o no dice por qué («%s»)" % m.desc.text)
	await _pulsar("abajo")
	await _tocar(m.filas[0]["nodo"].get_global_rect().get_center())
	_ok(m.sel == 0 and m.desc.text == espera and c.estado == "magia", "dedo: tocar el Compás apagado («%s», %s)" % [m.desc.text, c.estado])
	c._mostrar_menu()
	c._defender()
	await _hasta(_libre, 400)
	# Garon sin PM: ESGRIMA y EMBUIR; sin objetos: OBJETO
	if not await _turno_de("Garon"):
		return
	_heroe("Garon")["mp"] = 0
	for o in ["Poción", "Éter"]:
		while I.cantidad(o) > 0:
			I.gastar(o)
	c._mostrar_menu()
	await _esperar(4)
	_ok(_motivo_orden("ESGRIMA") == "Necesitas 6 PM" and _motivo_orden("EMBUIR") == "Necesitas 5 PM",
		"Garon sin PM: «%s» y «%s»" % [_motivo_orden("ESGRIMA"), _motivo_orden("EMBUIR")])
	_ok(_motivo_orden("OBJETO") == "No quedan objetos", "sin objetos: «%s»" % _motivo_orden("OBJETO"))
	c._menu_esgrima()
	await _esperar(3)
	_ok(m.desc.text == "Necesitas 6 PM: tienes 0.", "Esgrima sin PM: «%s»" % m.desc.text)
	c._menu_embuir()
	await _esperar(3)
	_ok(m.desc.text == "Necesitas 5 PM: tienes 0.", "Embuir sin PM: «%s»" % m.desc.text)
	c._menu_pocion()
	await _esperar(3)
	_ok(m.desc.text == "No te queda ninguno.", "objetos sin ninguno: «%s»" % m.desc.text)
	await _cerrar()
	# contra un jefe no se huye
	_combate({"Kael": 10, "Lya": 10}, "desierto", 8, "jefe")
	if await _turno_de("Kael"):
		_ok(_motivo_orden("HUIR") == "No se puede huir", "HUIR contra un jefe: «%s»" % _motivo_orden("HUIR"))
	await _cerrar()
	hechos.append("3: motivos de MAGIA, ESGRIMA, EMBUIR, OBJETO, HUIR, magias, Esgrima, Embuir, objetos y el Compás; con el mando y con el dedo")


# ---------------------------------------------------------------- 4. Érebo en el HUD
func _erebo() -> void:
	_combate({"Kael": 5}, "llanura", 7)
	if await _turno_de("Kael"):
		_ok(_motivo_orden("INVOCACIÓN") == "Nadie puede invocar" and c.menu.armonia_estado.text == "0 %",
			"Kael solo: «%s» y «%s»" % [_motivo_orden("INVOCACIÓN"), c.menu.armonia_estado.text])
		_ok(not c.menu.armonia_estado.text.contains("LYA") and not _motivo_orden("INVOCACIÓN").contains("Lya"),
			"Kael solo: el HUD nombra a Lya antes de conocerla")
	await _cerrar()
	_combate({"Kael": 10, "Lya": 10}, "desierto", 8)
	if not await _turno_de("Kael"):
		return
	var lya := _heroe("Lya")
	var m = c.menu
	c.armonia = 0.45
	c.menu.poner_armonia(0.45)
	c._mostrar_menu()
	await _esperar(3)
	_ok(m.armonia_estado.text == "45 %" and _motivo_orden("INVOCACIÓN") == "Armonía al 45 %",
		"Armonía al 45 %%: «%s» y «%s»" % [m.armonia_estado.text, _motivo_orden("INVOCACIÓN")])
	c.armonia = 1.0
	c.menu.poner_armonia(1.0)
	c._mostrar_menu()
	await _esperar(3)
	_ok(m.armonia_estado.text == "INVOCACIÓN LISTA" and not m.filas[_fila("INVOCACIÓN")]["item"]["apagado"] and m.invocacion_lista,
		"Armonía llena y Lya en pie: «%s»" % m.armonia_estado.text)
	c._quitar_pv(lya, 99999)
	c._mostrar_menu()
	await _esperar(3)
	_ok(m.armonia_estado.text == "LYA HA CAÍDO" and _motivo_orden("INVOCACIÓN") == "Lya ha caído"
		and m.filas[_fila("INVOCACIÓN")]["item"]["apagado"], "Lya caída: «%s» y «%s»" % [m.armonia_estado.text, _motivo_orden("INVOCACIÓN")])
	# las reglas, las de siempre: lista = Armonía llena y Lya en pie
	for v in [0.0, 0.45, 0.9999, 1.0]:
		for pv in [0, 50]:
			c.armonia = v
			lya["hp"] = pv
			_ok(c._estado_invocacion()["lista"] == (v >= 1.0 and pv > 0), "las reglas de la invocación cambian (%.4f, %d PV)" % [v, pv])
	await _cerrar()
	hechos.append("4: Érebo en el HUD (sin Lya, 45 %, lista, Lya caída) con las reglas de siempre")


# ---------------------------------------------------------------- 5. señas de las artes
func _senas_de(tipo: String) -> Array:
	return c.escena.get_children().filter(func(n): return n.get_script() == c.SenaArte and n.tipo == tipo)


func _pedidos(nombre: String, desde: int) -> Array:
	return sonidos.filter(func(s): return s[0] == nombre and s[1] >= desde)


func _senas() -> void:
	_combate({"Kael": 10, "Lya": 10}, "desierto", 8)
	if not await _turno_de("Kael"):
		return
	var kael := _heroe("Kael")
	var lya := _heroe("Lya")
	lya["atb"] = 0.0
	# Compás del Alba sobre Lya: Kael se vuelve hacia ella; el anillo y el sonido, en el fotograma en que su barra sube
	var k3d = c._p3d(kael)
	var giro0: float = k3d.pivote.rotation.y if k3d != null else 0.0
	var desde := fotograma
	var atb0: float = lya["atb"]
	c._lanzar_arte("Alba", 1, [lya])
	await _esperar(8)
	if k3d != null:
		_ok(absf(wrapf(k3d.pivote.rotation.y - giro0, -PI, PI)) > 0.5, "Compás: Kael no se vuelve hacia Lya")
	var f_atb := -1
	for i in 120:
		if lya["atb"] > atb0 + 40.0:
			f_atb = fotograma
			break
		await _esperar(1)
	var pedidos := _pedidos("arte_alba", desde)
	_ok(pedidos.size() == 1 and f_atb >= 0 and absi(pedidos[0][1] - f_atb) <= 1,
		"Compás: el sonido se pide %d veces (fotograma %s; la barra sube en el %d)" % [pedidos.size(), pedidos, f_atb])
	var anillos := _senas_de("alba")
	_ok(anillos.size() == 1 and anillos[0].position.distance_to(c._centro(lya)) < 1.0, "Compás: no hay un anillo sobre Lya")
	_ok(anillos.size() == 1 and anillos[0].get_child_count() == 0, "Compás: el anillo usa nodos (partículas) además del dibujo")
	await _hasta(_libre, 400)
	await _esperar(20)
	if k3d != null:
		_ok(absf(wrapf(k3d.pivote.rotation.y - giro0, -PI, PI)) < 0.15, "Compás: Kael no vuelve a mirar al frente")
	_ok(_senas_de("alba").is_empty(), "Compás: el anillo no se borra")
	_ok(_pedidos("arte_alba", desde).size() == 1, "Compás: el sonido se repite")
	# Peso del Ocaso (Kael otra vez): un anillo violeta por enemigo, un sonido
	if not await _turno_de("Kael"):
		return
	desde = fotograma
	var vivos: int = c.enemigos.filter(func(e): return e["hp"] > 0).size()
	c._elegir_hechizo("Alba", 2)
	var hay_ocaso := await _hasta(func(): return not _senas_de("ocaso").is_empty(), 200)
	_ok(hay_ocaso and _senas_de("ocaso").size() == vivos, "Peso del Ocaso: %d anillos para %d enemigos" % [_senas_de("ocaso").size(), vivos])
	await _hasta(_libre, 400)
	_ok(_pedidos("arte_ocaso", desde).size() == 1, "Peso del Ocaso: el sonido se pide %d veces" % _pedidos("arte_ocaso", desde).size())
	# Lumbre de Retorno: Kael cae; la brasa vuela, y al llegar vuelve (sonido «renacer» en ese fotograma)
	if not await _turno_de("Lya"):
		return
	c._quitar_pv(kael, 99999)
	c._restablecer_color(kael)
	await _esperar(3)
	desde = fotograma
	c._lanzar_arte("Lumbre", 1, [kael])
	var hay_brasa := await _hasta(func(): return not _senas_de("lumbre").is_empty(), 200)
	_ok(hay_brasa and kael["hp"] <= 0, "Lumbre: no sale la brasa antes de que vuelva")
	var f_vuelve := -1
	for i in 200:
		if kael["hp"] > 0:
			f_vuelve = fotograma
			break
		await _esperar(1)
	pedidos = _pedidos("renacer", desde)
	_ok(pedidos.size() == 1 and absi(pedidos[0][1] - f_vuelve) <= 1, "Lumbre: el sonido %s y vuelve en el %d" % [pedidos, f_vuelve])
	await _esperar(2)
	_ok(_fila_grupo("Kael")["destello"].visible, "Lumbre: la fila de Kael no se ilumina en el HUD")
	_ok(c.capa.get_children().any(func(n): return n is Label and n.text == "¡Kael vuelve!"), "Lumbre: no se dice quién vuelve")
	await _hasta(_libre, 400)
	_ok(_pedidos("renacer", desde).size() == 1, "Lumbre: el sonido se repite")
	# Segundo Aliento: una hoja por turno, los turnos junto al icono, y al empezar el turno, la hoja y el sonido
	if not await _turno_de("Lya"):
		return
	kael["hp"] = int(kael["hp_max"] * 0.5)
	desde = fotograma
	c._elegir_hechizo("Lumbre", 2)
	var hay_hojas := await _hasta(func(): return not _senas_de("aliento").is_empty(), 200)
	var senas := _senas_de("aliento")
	_ok(hay_hojas and senas.size() == 2 and senas.all(func(s): return s.hojas == 3), "Segundo Aliento: %d señas" % senas.size())
	_ok(A.texto_estado(kael, "aliento") == "3", "Segundo Aliento: no se ven sus 3 turnos")
	await _hasta(_libre, 400)
	_ok(_pedidos("arte_lumbre", desde).size() == 1, "Segundo Aliento: el sonido se pide %d veces" % _pedidos("arte_lumbre", desde).size())
	desde = fotograma
	if not await _turno_de("Kael"):
		return
	_ok(int(kael["aliento"]) == 2 and A.texto_estado(kael, "aliento") == "2", "Aliento: no cuenta un turno menos")
	_ok(_pedidos("aliento", desde).size() == 1, "Aliento: al curar, el sonido se pide %d veces" % _pedidos("aliento", desde).size())
	_ok(not _senas_de("hoja").is_empty(), "Aliento: no sube la hoja del turno")
	await _cerrar()
	hechos.append("5: señas del Compás (y el gesto de Kael), Peso del Ocaso, Lumbre de Retorno y Segundo Aliento, con el sonido una vez y a tiempo")
