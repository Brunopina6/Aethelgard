extends SceneTree
# Las pestañas nuevas de magia (T-091) y la ranura Accesorio (T-092) con teclado, mando y el dedo. Eventos SIMULADOS de
# verdad (Input.parse_input_event): teclas, botones de mando y toques de pantalla, que el juego recibe como clics, igual
# que en el móvil. Comprueba el mapa de entrada y los menús, no el hardware. Sin ventana y con datos aislados; el
# combate no guarda (sin «desde_mapa») y la partida apunta a su propio archivo.
#   1. Combate (Kael nivel 9 y Lya nivel 10 contra dos Slimes), una vez con cada uno: MAGIA → la pestaña del Alba (E / R1
#      o tocándola; Q / L1 vuelven a la II) → Compás del Alba → Lya como objetivo → se lanza (6 PM menos y el cartel).
#   2. Menú Grupo, fila Accesorio: se ve al abrir, sin desplazar la lista; con ↓ (cruceta) desde el ▶ de Amuleto se
#      llega a su ▶; Intro / A pone el Farol y el foco sigue ahí; ← lleva a su ◀ e Intro / A lo quita. Con el dedo,
#      tocar ▶ lo pone y ◀ lo quita.

const ARCHIVO := "user://prueba_controles_nuevos.save"
const TECLAS := {"aceptar": KEY_ENTER, "cancelar": KEY_ESCAPE, "abajo": KEY_DOWN, "arriba": KEY_UP,
	"izquierda": KEY_LEFT, "derecha": KEY_RIGHT, "pestana_sig": KEY_E, "pestana_ant": KEY_Q}
const BOTONES := {"aceptar": JOY_BUTTON_A, "cancelar": JOY_BUTTON_B, "abajo": JOY_BUTTON_DPAD_DOWN,
	"arriba": JOY_BUTTON_DPAD_UP, "izquierda": JOY_BUTTON_DPAD_LEFT, "derecha": JOY_BUTTON_DPAD_RIGHT,
	"pestana_sig": JOY_BUTTON_RIGHT_SHOULDER, "pestana_ant": JOY_BUTTON_LEFT_SHOULDER}

var P
var G
var I
var Ent
var dispositivo := "teclado"
var fallos: Array = []
var hechos: Array = []
var c = null


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append("%s: %s" % [dispositivo, t])
	print("FALLO: %s: %s" % [dispositivo, t])


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _evento(que: String, pulsado: bool) -> void:
	if dispositivo == "mando":
		var b := InputEventJoypadButton.new()
		b.device = 0
		b.button_index = BOTONES[que]
		b.pressed = pulsado
		Input.parse_input_event(b)
	else:
		var k := InputEventKey.new()
		k.keycode = TECLAS[que]
		k.physical_keycode = TECLAS[que]
		k.pressed = pulsado
		Input.parse_input_event(k)


func _pulsar(que: String, esperar := 4) -> void:
	_evento(que, true)
	await _esperar(2)
	_evento(que, false)
	await _esperar(esperar)


# Un toque de pantalla en «p» (coordenadas del juego, 1280 × 720): el dedo baja y sube. Sin ventana, la ventana raíz
# mide 100 × 100 y el juego se escala a ella (stretch canvas_items): el toque va en coordenadas de esa ventana, como el
# de un móvil va en las de su pantalla (comprobado el 09/11: sin pasar por la transformada, no toca nada).
func _tocar(p: Vector2, esperar := 4) -> void:
	for pulsado in [true, false]:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = root.get_final_transform() * p
		t.pressed = pulsado
		Input.parse_input_event(t)
		await _esperar(2)
	await _esperar(esperar)


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	Ent = root.get_node("Entrada")
	await _esperar(5)
	await _combate()
	await _menu_grupo()
	if c != null:
		c.queue_free()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", ", ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ---------------------------------------------------------------- 1. combate
func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


# Espera al menú de Kael; a Lya, mientras, la pone en guardia (sin teclas: no es lo que se prueba). Si Lya ya espera
# su turno (barra llena o en la cola), el Compás sale apagado con su motivo («Ya esperan su turno»): la prueba le vacía
# la barra antes de abrir MAGIA, para lanzarlo con cada dispositivo.
func _turno_de_kael() -> bool:
	var limite := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < limite:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Kael":
				var lya := _heroe("Lya")
				lya["atb"] = 0.0
				for i in range(c.cola.size() - 1, -1, -1):
					if is_same(c.cola[i], lya):
						c.cola.remove_at(i)
				await _esperar(3)
				return true
			c._defender()
		await _esperar(1)
	return false


func _fila_sel(texto: String) -> bool:
	var m = c.menu
	return m.sel >= 0 and m.sel < m.filas.size() and str(m.filas[m.sel]["item"].get("texto", "")).begins_with(texto)


func _centro_fila(texto: String) -> Vector2:
	for f in c.menu.filas:
		if str(f["item"].get("texto", "")).begins_with(texto):
			return f["nodo"].get_global_rect().get_center()
	return Vector2(-1, -1)


# Pestañas de magia que se ven ahora: nodos de capa_filas en la fila de arriba (y = Y_FILAS), de izquierda a derecha.
func _nodos_pestana() -> Array:
	var r: Array = c.menu.capa_filas.get_children().filter(_es_pestana)
	r.sort_custom(func(a, b): return a.position.x < b.position.x)
	return r


func _es_pestana(n: Node) -> bool:
	return not n.is_queued_for_deletion() and is_equal_approx(n.position.y, c.menu.Y_FILAS) \
		and is_equal_approx(n.size.y, c.menu.FILA_SUB)


func _pestanas() -> Array:
	return c.menu._pestanas.map(func(p): return p.get("icono", p["texto"]))


func _combate() -> void:
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
	for d in ["teclado", "mando", "tactil"]:
		dispositivo = d
		if not await _turno_de_kael():
			_fallo("no llega el turno de Kael")
			return
		var kael := _heroe("Kael")
		var pm: int = kael["mp"]
		# MAGIA
		if d == "tactil":
			await _tocar(_centro_fila("MAGIA"))
		else:
			for i in 6:
				if _fila_sel("MAGIA"):
					break
				await _pulsar("abajo", 2)
			await _pulsar("aceptar")
		if c.estado != "magia":
			_fallo("MAGIA no abre el menú de magia (estado %s)" % c.estado)
			continue
		if _pestanas() != ["I", "II", "Alba"]:
			_fallo("las pestañas de Kael (nivel 9) son %s" % [_pestanas()])
		# la pestaña del Alba (y vuelta atrás con Q / L1)
		if d == "tactil":
			var tabs := _nodos_pestana()
			if tabs.size() != 3 or not is_equal_approx(tabs[2].size.x, 64.0):
				_fallo("las pestañas en pantalla no son tres con la del Alba de 64 px")
			else:
				await _tocar(tabs[2].get_global_rect().get_center())
		else:
			for i in 3:
				if c.magia_nivel_menu.get("Kael", 1) == 4:
					break
				await _pulsar("pestana_sig")
			await _pulsar("pestana_ant")
			if c.magia_nivel_menu.get("Kael", 1) != 2:
				_fallo("Q / L1 desde el Alba no vuelve a la pestaña II (%d)" % c.magia_nivel_menu.get("Kael", 1))
			await _pulsar("pestana_sig")
		if c.magia_nivel_menu.get("Kael", 1) != 4 or c.menu._pestana != 2:
			_fallo("no se llega a la pestaña del Alba (%d, pestaña %d)" % [c.magia_nivel_menu.get("Kael", 1), c.menu._pestana])
			continue
		var filas: Array = c.menu.filas.map(func(f): return f["item"]["texto"])
		if filas != ["Compás del Alba", "Peso del Ocaso"]:
			_fallo("la pestaña del Alba tiene %s" % [filas])
		# Compás del Alba → Lya
		if d == "tactil":
			await _tocar(_centro_fila("Compás del Alba"))
		else:
			if not _fila_sel("Compás del Alba"):
				_fallo("al abrir la pestaña del Alba no está elegido el Compás")
			await _pulsar("aceptar")
		if c.estado != "objetivo" or c.objetivos_posibles.size() != 1 or c.objetivos_posibles[0]["nombre"] != "Lya":
			_fallo("el Compás no pide a Lya como objetivo (estado %s)" % c.estado)
			continue
		if d == "tactil":
			await _tocar(c._a_pantalla(c._centro(_heroe("Lya"))))
		else:
			await _pulsar("aceptar")
		var lanzado := false
		for i in 30:
			if c.registro.text == "Kael lanza Compás del Alba":
				lanzado = true
				break
			await _esperar(1)
		if not lanzado or kael["mp"] != pm - 6:
			_fallo("el Compás no se lanza (cartel «%s», PM %d → %d)" % [c.registro.text, pm, kael["mp"]])
			continue
		hechos.append("combate con " + d)
	# se acaba huyendo (como en el juego), para no dejar nada a medias al borrar el combate
	dispositivo = "fin"
	if await _turno_de_kael():
		c._escapar()
	var limite := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < limite and c.menu.heroe_actual.get("nombre", "") != "Fin":
		await _esperar(1)
	if c.menu.heroe_actual.get("nombre", "") != "Fin":
		_fallo("el combate no termina al huir")


# ---------------------------------------------------------------- 2. menú Grupo
func _foco() -> Control:
	return root.get_viewport().gui_get_focus_owner()


func _clave_foco() -> String:
	return Ent.clave(_foco()) if _foco() != null else ""


func _accesorio() -> String:
	return I.equipo_de("Kael").get("accesorio", "")


func _menu_grupo() -> void:
	if c != null:
		c.queue_free()
		c = null
	_limpiar()
	G.datos()
	I.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	I.agregar("farol_peregrino")
	var m = load("res://menus.gd").new()
	m.pestana = "Grupo"
	root.add_child(m)
	await _esperar(6)
	for d in ["teclado", "mando", "tactil"]:
		dispositivo = d
		I.equipar("Kael", "accesorio", "")
		m._pintar_de_nuevo()
		await _esperar(2)
		var mas = Ent.buscar(m, "ranura:accesorio:1")
		var menos = Ent.buscar(m, "ranura:accesorio:-1")
		if mas == null or menos == null:
			_fallo("no están los botones ◀ ▶ de la fila Accesorio")
			continue
		if not m.marco.get_global_rect().encloses(mas.get_global_rect()):
			_fallo("la fila Accesorio no se ve al abrir el menú (hay que desplazar la lista): ▶ en %s, la lista en %s" % [
				mas.get_global_rect(), m.marco.get_global_rect()])
		if d == "tactil":
			await _tocar(mas.get_global_rect().get_center())
			if _accesorio() != "farol_peregrino":
				_fallo("tocar ▶ no pone el Farol (%s)" % _accesorio())
			menos = Ent.buscar(m, "ranura:accesorio:-1")
			await _tocar(menos.get_global_rect().get_center())
			if _accesorio() != "":
				_fallo("tocar ◀ no quita el Farol (%s)" % _accesorio())
		else:
			var amuleto = Ent.buscar(m, "ranura:amuleto:1")
			amuleto.grab_focus()
			await _esperar(2)
			await _pulsar("abajo")
			if _clave_foco() != "ranura:accesorio:1":
				_fallo("↓ desde el ▶ de Amuleto no lleva al ▶ de Accesorio («%s»)" % _clave_foco())
				continue
			await _pulsar("aceptar")
			if _accesorio() != "farol_peregrino" or _clave_foco() != "ranura:accesorio:1":
				_fallo("Intro / A en ▶ no pone el Farol o pierde el foco (%s, «%s»)" % [_accesorio(), _clave_foco()])
			await _pulsar("izquierda")
			if _clave_foco() != "ranura:accesorio:-1":
				_fallo("← desde el ▶ de Accesorio no lleva a su ◀ («%s»)" % _clave_foco())
			await _pulsar("aceptar")
			if _accesorio() != "":
				_fallo("Intro / A en ◀ no quita el Farol (%s)" % _accesorio())
		hechos.append("Accesorio con " + d)
	m._cerrar()
	await _esperar(2)
