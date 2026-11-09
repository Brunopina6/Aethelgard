extends SceneTree
# Prueba del foco y de los controles de teclado y mando en menús y exploración 2D (T-025; entrada.gd). Eventos
# SIMULADOS (Input.parse_input_event con teclas, botones y ejes de mando de verdad, no acciones): comprueba el mapa de
# entrada de project.godot y el foco, no el hardware. Sin ventana. Con «-- sin_prologo».
#   1. El estilo del foco se ve (marco dorado) y, con el dedo, el foco existe pero no se dibuja.
#   2. Menú del grupo: el foco empieza en la pestaña; flechas, Intro, Q / E y Esc; tras pulsar «+» el foco sigue en el
#      mismo botón y, si ese botón ya no sirve, en otro de la ventana (no se pierde); una pulsación, un punto.
#   3. Tienda: comprar con el teclado deja el foco en «Comprar»; una pulsación, una compra; Esc cierra.
#   4. Diario: ↓ desplaza el texto, E cambia de pestaña, Esc cierra.
#   5. Mapa: Tab pone el foco en la barra y Kael no se mueve; Intro abre la ventana con el foco dentro; Esc la cierra y
#      el foco vuelve a su botón; Esc suelta la barra y Kael vuelve a andar; un clic también la suelta; Intro entra en
#      el lugar cercano.
#   6. Ciudad (Oakhaven): Tab, TIENDA con Intro, Esc vuelve a TIENDA; Intro habla con un vecino y la misma pulsación no
#      pasa la primera frase.
#   7. Mando: con el stick a la derecha y el mando desconectado de golpe, se suelta la dirección, se avisa y el teclado
#      sigue funcionando.

const MAPA := "res://mapa.tscn"
const ZONA := "res://zona.tscn"
const CIUDAD := "res://ciudad_oakhaven.tscn"     # Oakhaven, hecha a mano desde T-089 (hereda de zona.gd)

var fallos: Array = []
var hechos: Array = []
var Ent
var R
var D


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _tecla(codigo: Key, pulsada: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = pulsada
	Input.parse_input_event(e)


# Pulsa y suelta una tecla, como una persona (soltar dos fotogramas después).
func _pulsar(codigo: Key, esperar := 4) -> void:
	_tecla(codigo, true)
	await _esperar(2)
	_tecla(codigo, false)
	await _esperar(esperar)


func _foco() -> Control:
	return root.get_viewport().gui_get_focus_owner()


func _clave_foco() -> String:
	return Ent.clave(_foco()) if _foco() != null else ""


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _probar() -> void:
	Ent = root.get_node("Entrada")
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	await _esperar(3)
	R.precalentar_dialogos()                       # como la pantalla de carga: la interfaz de los diálogos ya está
	await _esperar(3)
	await _estilo()
	await _menu_grupo()
	await _tienda()
	await _diario()
	await _mapa()
	await _ciudad()
	await _mando_desconectado()
	print("OK foco: ", ", ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1. Estilo del foco y foco oculto con el dedo.
func _estilo() -> void:
	var e = ThemeDB.get_default_theme().get_stylebox("focus", "Button")
	if not (e is StyleBoxFlat) or e.border_width_top < 2:
		_fallo("1: el estilo del foco de Button no se ve (%s)" % e)
	var toque := InputEventScreenTouch.new()      # con el dedo: el foco existe, pero sin marco
	toque.position = Vector2(5, 5)
	toque.pressed = true
	Input.parse_input_event(toque)
	await _esperar(1)
	toque = toque.duplicate()
	toque.pressed = false
	Input.parse_input_event(toque)
	await _esperar(1)
	if Ent.modo != "puntero":
		_fallo("1: un toque no pone el modo puntero (%s)" % Ent.modo)
	var m = load("res://menus.gd").new()
	root.add_child(m)
	await _esperar(2)
	if _foco() == null or not m.is_ancestor_of(_foco()):
		_fallo("1: con el dedo, la ventana no tiene el foco")
	elif _foco().has_focus(true):
		_fallo("1: con el dedo, el marco del foco se dibuja")
	m._cerrar()
	await _esperar(2)
	hechos.append("estilo")


# 2. Menú del grupo con el teclado.
func _menu_grupo() -> void:
	var G = load("res://grupo.gd")
	G.datos()["Kael"]["puntos"] = 2
	var fuerza_antes: int = G.datos()["Kael"]["atributos"]["fuerza"]
	await _pulsar(KEY_SHIFT)                       # una tecla cualquiera: modo teclado
	if Ent.modo != "teclado":
		_fallo("2: una tecla no pone el modo teclado (%s)" % Ent.modo)
	var m = load("res://menus.gd").new()
	m.pestana = "Grupo"
	var cerrado := [false]
	m.cerrado.connect(func(): cerrado[0] = true)
	root.add_child(m)
	await _esperar(2)
	if _clave_foco() != "pestana:Grupo" or not _foco().has_focus(true):
		_fallo("2: al abrir, el foco no está (visible) en la pestaña Grupo («%s»)" % _clave_foco())
	await _pulsar(KEY_RIGHT)
	if _clave_foco() != "pestana:Objetos":
		_fallo("2: → no lleva el foco a Objetos («%s»)" % _clave_foco())
	await _pulsar(KEY_ENTER)
	if m.pestana != "Objetos" or _clave_foco() != "pestana:Objetos":
		_fallo("2: Intro en Objetos no cambia de pestaña o pierde el foco (%s, «%s»)" % [m.pestana, _clave_foco()])
	await _pulsar(KEY_E)
	if m.pestana != "Habilidades" or _clave_foco() != "pestana:Habilidades":
		_fallo("2: E no pasa a Habilidades con el foco en su pestaña (%s, «%s»)" % [m.pestana, _clave_foco()])
	await _pulsar(KEY_Q)
	await _pulsar(KEY_Q)
	if m.pestana != "Grupo":
		_fallo("2: Q no vuelve a Grupo (%s)" % m.pestana)
	var mas = Ent.buscar(m, "mas:fuerza")
	if mas == null:
		_fallo("2: no hay botón «+» de fuerza")
	else:
		mas.grab_focus()
		await _pulsar(KEY_ENTER)
		if G.datos()["Kael"]["atributos"]["fuerza"] != fuerza_antes + 1:
			_fallo("2: una pulsación de Intro no sube la fuerza exactamente 1 (%d → %d)" % [fuerza_antes, G.datos()["Kael"]["atributos"]["fuerza"]])
		if _clave_foco() != "mas:fuerza":
			_fallo("2: tras repintar, el foco no vuelve a «+» de fuerza («%s»)" % _clave_foco())
		await _pulsar(KEY_ENTER)                   # el último punto: el «+» se apaga
		if _foco() == null or not m.is_ancestor_of(_foco()) or _foco().disabled:
			_fallo("2: al apagarse el «+», el foco se pierde o queda en un botón apagado («%s»)" % _clave_foco())
	await _pulsar(KEY_ESCAPE)
	if not cerrado[0] or not m.is_queued_for_deletion():
		_fallo("2: Esc no cierra el menú")
	await _esperar(2)
	hechos.append("menú del grupo")


# 3. Tienda con el teclado.
func _tienda() -> void:
	var Inv = load("res://inventario.gd")
	Inv.ganar_oro(200)
	var t = load("res://tienda.gd").new()
	t.pestana = "Objetos"
	root.add_child(t)
	await _esperar(2)
	if _clave_foco() != "pestana:Objetos":
		_fallo("3: al abrir la tienda, el foco no está en Objetos («%s»)" % _clave_foco())
	for i in 8:
		if _clave_foco() == "comprar:Poción":
			break
		await _pulsar(KEY_DOWN)
	if _clave_foco() != "comprar:Poción":
		_fallo("3: con ↓ no se llega a «Comprar» de la Poción («%s»)" % _clave_foco())
	else:
		var antes: int = Inv.cantidad("Poción")
		var oro: int = Inv.oro()
		await _pulsar(KEY_ENTER)
		if Inv.cantidad("Poción") != antes + 1 or Inv.oro() != oro - t.OBJETOS["Poción"]:
			_fallo("3: una pulsación no compra exactamente una Poción (%d → %d, %d → %d monedas)" % [antes, Inv.cantidad("Poción"), oro, Inv.oro()])
		if _clave_foco() != "comprar:Poción":
			_fallo("3: tras comprar, el foco no sigue en «Comprar» («%s»)" % _clave_foco())
	await _pulsar(KEY_ESCAPE)
	if not t.is_queued_for_deletion():
		_fallo("3: Esc no cierra la tienda")
	await _esperar(2)
	hechos.append("tienda")


# 4. Diario con el teclado.
func _diario() -> void:
	var d = load("res://diario.gd").new()
	root.add_child(d)
	await _esperar(3)
	if _clave_foco() != "pestana:Detalles":
		_fallo("4: al abrir el diario, el foco no está en Detalles («%s»)" % _clave_foco())
	var max_scroll: float = d.marco.get_v_scroll_bar().max_value - d.marco.size.y
	await _pulsar(KEY_DOWN)
	if max_scroll > 10.0 and d.marco.scroll_vertical <= 0:
		_fallo("4: ↓ no desplaza el texto del diario")
	await _pulsar(KEY_E)
	if d.pestana != "Combate":
		_fallo("4: E no pasa a la pestaña Combate (%s)" % d.pestana)
	await _pulsar(KEY_ESCAPE)
	if not d.is_queued_for_deletion():
		_fallo("4: Esc no cierra el diario")
	await _esperar(2)
	hechos.append("diario")


# 5. Mapa: barra, ventanas, andar y entrar.
func _mapa() -> void:
	change_scene_to_file(MAPA)
	for i in 300:
		await _esperar(1)
		if _escena() == MAPA and current_scene.jugador != null and not R.cambiando:
			break
	var m = current_scene
	if _escena() != MAPA:
		_fallo("5: el mapa no carga")
		return
	await _esperar(10)
	await _pulsar(KEY_TAB)
	if not m.barra_activa or _clave_foco() != "Grupo" or not _foco().has_focus(true):
		_fallo("5: Tab no pone el foco (visible) en GRUPO (%s, «%s»)" % [m.barra_activa, _clave_foco()])
	var antes: Vector2 = m.jugador.position
	_tecla(KEY_RIGHT, true)                        # → mueve el foco, no a Kael
	await _esperar(12)
	_tecla(KEY_RIGHT, false)
	await _esperar(3)
	if m.jugador.position.distance_to(antes) > 0.5:
		_fallo("5: con la barra activa, → mueve a Kael (%.1f px)" % m.jugador.position.distance_to(antes))
	if _clave_foco() != "Objetos":
		_fallo("5: → en la barra no lleva el foco a OBJETOS («%s»)" % _clave_foco())
	await _pulsar(KEY_ENTER)
	if m.menu_abierto == null or m.menu_abierto.pestana != "Objetos" or not m.menu_abierto.is_ancestor_of(_foco()):
		_fallo("5: Intro en OBJETOS no abre la ventana con el foco dentro")
	await _pulsar(KEY_ESCAPE)
	await _esperar(2)
	if m.menu_abierto != null or _clave_foco() != "Objetos":
		_fallo("5: Esc no cierra la ventana o el foco no vuelve a OBJETOS («%s»)" % _clave_foco())
	await _pulsar(KEY_ESCAPE)
	if m.barra_activa or _foco() != null:
		_fallo("5: Esc no suelta la barra (%s, «%s»)" % [m.barra_activa, _clave_foco()])
	antes = m.jugador.position
	_tecla(KEY_RIGHT, true)
	await _esperar(12)
	_tecla(KEY_RIGHT, false)
	await _esperar(3)
	if m.jugador.position.distance_to(antes) < 5.0:
		_fallo("5: sin la barra, → no mueve a Kael")
	await _pulsar(KEY_TAB)
	var clic := InputEventMouseButton.new()        # un clic en el mapa suelta la barra y Kael va hacia allí
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.position = Vector2(700, 300)
	clic.global_position = clic.position
	clic.pressed = true
	Input.parse_input_event(clic)
	await _esperar(1)
	clic = clic.duplicate()
	clic.pressed = false
	Input.parse_input_event(clic)
	await _esperar(2)
	if m.barra_activa or not m.tiene_destino:
		_fallo("5: un clic con la barra activa no la suelta ni manda andar (%s, %s)" % [m.barra_activa, m.tiene_destino])
	m.tiene_destino = false
	var oak: Vector2 = m.lugares[0]["pos"]           # Oakhaven: Intro entra
	m.jugador.position = oak + Vector2(20, 0)
	await _esperar(4)
	if not m.boton_entrar.visible:
		_fallo("5: junto a Oakhaven no sale «Entrar»")
	await _pulsar(KEY_ENTER, 1)
	if not m.en_encuentro:
		_fallo("5: Intro junto a Oakhaven no entra")
	hechos.append("mapa")


# 6. Ciudad: botones con el foco, tienda y hablar con un vecino.
func _ciudad() -> void:
	var limite := Time.get_ticks_msec() + 60000     # la zona se carga en segundo plano: se espera por tiempo real
	while Time.get_ticks_msec() < limite:
		await _esperar(1)
		if _escena() in [ZONA, CIUDAD] and not R.cambiando and current_scene.jugador != null:
			break
	var z = current_scene
	if not _escena() in [ZONA, CIUDAD] or not z.es_ciudad:
		_fallo("6: no se entra en la ciudad (%s)" % _escena())
		return
	await _esperar(10)
	await _pulsar(KEY_TAB)
	if not z.barra_activa or _clave_foco() != "MAPA DEL MUNDO":
		_fallo("6: Tab no pone el foco en MAPA DEL MUNDO («%s»)" % _clave_foco())
	for i in 6:                                     # ← (y ↓ si ← no lleva a ningún sitio) hasta TIENDA
		if _clave_foco() == "TIENDA":
			break
		var antes_foco := _clave_foco()
		await _pulsar(KEY_LEFT)
		if _clave_foco() == antes_foco:
			await _pulsar(KEY_DOWN)
	if _clave_foco() != "TIENDA":
		_fallo("6: con las flechas no se llega a TIENDA («%s»)" % _clave_foco())
	else:
		await _pulsar(KEY_ENTER)
		if not z.tienda_abierta or _clave_foco() != "pestana:Objetos":
			_fallo("6: Intro en TIENDA no abre la tienda con el foco en Objetos («%s»)" % _clave_foco())
		await _pulsar(KEY_ESCAPE)
		await _esperar(2)
		if z.tienda_abierta or _clave_foco() != "TIENDA":
			_fallo("6: al cerrar la tienda, el foco no vuelve a TIENDA («%s»)" % _clave_foco())
	await _pulsar(KEY_ESCAPE)
	if z.barra_activa:
		_fallo("6: Esc no suelta los botones de la ciudad")
	var vecino = null                               # un vecino con diálogo de Dialogic
	for n in z.npcs:
		if z._dialogo_npc(n) != "":                   # el que toca ahora (en Oakhaven, según la partida)
			vecino = n
			break
	if vecino == null:
		_fallo("6: no hay vecinos con diálogo en Oakhaven")
	else:
		z.jugador.position = vecino[0].position + Vector2(30, 0)
		await _esperar(4)
		if not z.boton_examinar.visible:
			_fallo("6: junto a %s no sale el botón de hablar" % vecino[1]["nombre"])
		_tecla(KEY_ENTER, true)
		var e := InputEventKey.new()               # otro evento en el mismo fotograma (como el temblor de un stick)
		e.keycode = KEY_SHIFT
		e.pressed = false
		Input.parse_input_event(e)
		await _esperar(2)
		_tecla(KEY_ENTER, false)
		await _esperar(1)
		if D.current_timeline == null:
			_fallo("6: Intro junto a %s no abre su diálogo" % vecino[1]["nombre"])
		elif D.current_state != D.States.REVEALING_TEXT and D.current_state != D.States.ANIMATING:
			_fallo("6: la misma pulsación que abre el diálogo pasa ya la primera frase (estado %d)" % D.current_state)
		D.end_timeline(true)
		await _esperar(3)
	hechos.append("ciudad")


# 7. Mando simulado: desconectarlo con el stick apretado.
func _mando_desconectado() -> void:
	Input.joy_connection_changed.emit(0, true)       # simulado: la señal que Godot emite al conectar un mando
	await _esperar(1)
	var b := InputEventJoypadButton.new()           # X: sin acción en el juego (no habla con nadie)
	b.device = 0
	b.button_index = JOY_BUTTON_X
	b.pressed = true
	Input.parse_input_event(b)
	await _esperar(1)
	b = b.duplicate()
	b.pressed = false
	Input.parse_input_event(b)
	await _esperar(1)
	if Ent.modo != "mando":
		_fallo("7: un botón del mando no pone el modo mando (%s)" % Ent.modo)
	var eje := InputEventJoypadMotion.new()
	eje.device = 0
	eje.axis = JOY_AXIS_LEFT_X
	eje.axis_value = 1.0
	Input.parse_input_event(eje)
	await _esperar(2)
	if not Input.is_action_pressed("ui_right"):
		_fallo("7: el stick a la derecha no pulsa ui_right")
	Input.joy_connection_changed.emit(0, false)      # simulado: desconectado de golpe (sin soltar el stick)
	await _esperar(2)
	if Input.is_action_pressed("ui_right"):
		_fallo("7: al desconectar el mando, ui_right sigue pulsada")
	if Ent.modo == "mando":
		_fallo("7: al desconectar el mando, el modo sigue en mando")
	if R.lbl_aviso == null or R.lbl_aviso.text != Ent.AVISO_DESCONECTADO:
		_fallo("7: no se avisa de que el mando se ha desconectado")
	var z = current_scene                           # se puede seguir con el teclado
	if z != null and "barra_activa" in z:
		await _pulsar(KEY_TAB)
		if not z.barra_activa:
			_fallo("7: tras desconectar el mando, el teclado no responde")
		await _pulsar(KEY_ESCAPE)
	hechos.append("mando desconectado")
