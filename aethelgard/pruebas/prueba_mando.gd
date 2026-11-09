extends SceneTree
# Recorrido SIN RATÓN con mando (o con teclado: prueba_teclado.gd), con eventos SIMULADOS de mando o de teclado de
# verdad (Input.parse_input_event): comprueba el mapa de entrada y el juego, no el hardware. Sin ventana. Con
# «-- 3d sin_prologo dispositivo=mando|teclado». La partida va a la ranura de prueba de la carpeta aislada.
#   1. Pantalla de carga: el texto dice qué pulsar; ↓ elige «Probar la misión desde el principio» (con el marco del
#      foco) e Intro / A la empieza: una sola acción (no la partida normal).
#   2. Pastos Verdes 3D: PV-02 se pasa con Intro / A; cada pulsación es una sola acción en Dialogic, aunque el stick
#      tiemble en el mismo fotograma.
#   3. Andar con el stick o las flechas; acercar la cámara con el stick derecho o con +. (Mando) desconectarlo
#      andando: Kael se para, se avisa y se sigue con el teclado.
#   4. Hablar con Tilo con Intro / A: la misma pulsación no pasa la primera frase; se lee el diálogo entero.
#   5. Combate: Intro / A en ATACAR pide objetivo (no ataca ya); Esc / B vuelve; → cambia de objetivo; Intro / A ataca;
#      MAGIA con dos niveles: L1 / R1 (Q / E) cambian la pestaña; HUIR con Intro / A.
#   6. Mapa: Start / Tab ponen el foco en la barra (visible), Intro / A abre la ventana con el foco dentro y Esc / B la
#      cierra y suelta la barra.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const MAPA := "res://mapa.tscn"
const CARGA := "res://carga.tscn"
const COMBATE := "res://combate.tscn"

var dispositivo := "mando"
var fallos: Array = []
var hechos: Array = []
var R
var D
var P
var G
var acciones := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("dispositivo="):
			dispositivo = a.substr(12)
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if _escena() == REGION and current_scene != null and "pasos" in current_scene:
			current_scene.pasos = 0                    # sin encuentros al azar: los combates los pide la prueba


# Espera (por tiempo real: las cargas van en segundo plano) a que se cumpla una condición.
func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await _esperar(1)
	return false


const TECLAS := {"aceptar": KEY_ENTER, "cancelar": KEY_ESCAPE, "abajo": KEY_DOWN, "arriba": KEY_UP,
	"izquierda": KEY_LEFT, "derecha": KEY_RIGHT, "menu": KEY_TAB, "pestana_sig": KEY_E, "pestana_ant": KEY_Q}
const BOTONES := {"aceptar": JOY_BUTTON_A, "cancelar": JOY_BUTTON_B, "abajo": JOY_BUTTON_DPAD_DOWN,
	"arriba": JOY_BUTTON_DPAD_UP, "izquierda": JOY_BUTTON_DPAD_LEFT, "derecha": JOY_BUTTON_DPAD_RIGHT,
	"menu": JOY_BUTTON_START, "pestana_sig": JOY_BUTTON_RIGHT_SHOULDER, "pestana_ant": JOY_BUTTON_LEFT_SHOULDER}


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


# Otro evento en el mismo fotograma, como el temblor de un stick (o una tecla que se suelta).
func _ruido() -> void:
	if dispositivo == "mando":
		var m := InputEventJoypadMotion.new()
		m.device = 0
		m.axis = JOY_AXIS_LEFT_Y
		m.axis_value = 0.04
		Input.parse_input_event(m)
	else:
		var k := InputEventKey.new()
		k.keycode = KEY_SHIFT
		k.pressed = false
		Input.parse_input_event(k)


func _pulsar(que: String, esperar := 4) -> void:
	_evento(que, true)
	_ruido()
	await _esperar(2)
	_evento(que, false)
	await _esperar(esperar)


# Andar hacia la derecha: stick izquierdo o flecha.
func _derecha(si: bool) -> void:
	if dispositivo == "mando":
		var m := InputEventJoypadMotion.new()
		m.device = 0
		m.axis = JOY_AXIS_LEFT_X
		m.axis_value = 1.0 if si else 0.0
		Input.parse_input_event(m)
	else:
		var k := InputEventKey.new()
		k.keycode = KEY_RIGHT
		k.physical_keycode = KEY_RIGHT
		k.pressed = si
		Input.parse_input_event(k)


func _acercar(si: bool) -> void:
	if dispositivo == "mando":
		var m := InputEventJoypadMotion.new()
		m.device = 0
		m.axis = JOY_AXIS_RIGHT_Y
		m.axis_value = -1.0 if si else 0.0
		Input.parse_input_event(m)
	else:
		var k := InputEventKey.new()
		k.keycode = KEY_PLUS
		k.physical_keycode = KEY_PLUS
		k.pressed = si
		Input.parse_input_event(k)


func _contar() -> void:
	if D.current_timeline != null:              # Dialogic avisa de la acción aunque no haya diálogo; solo cuenta con uno abierto
		acciones += 1


# Lee el diálogo abierto hasta el final con Intro / A; cada pulsación, una acción como mucho.
func _leer_dialogo(nombre: String) -> void:
	for i in 80:
		if D.current_timeline == null:
			break
		acciones = 0
		await _pulsar("aceptar", 14)
		if acciones > 1:
			_fallo("%s: una pulsación cuenta %d veces en el diálogo" % [nombre, acciones])
	await _hasta(func(): return D.current_timeline == null, 10.0)
	if D.current_timeline != null:
		_fallo("%s: el diálogo no se acaba con Intro / A" % nombre)


func _probar() -> void:
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	await _esperar(3)
	if dispositivo == "mando":
		Input.joy_connection_changed.emit(0, true)  # simulado: Godot emite esta señal al conectar un mando
	D.Inputs.dialogic_action_priority.connect(_contar)
	await _carga()
	if _escena() == REGION:
		await _region()
		await _combate()
		await _mapa()
	print("OK %s: %s" % [dispositivo, ", ".join(hechos)])
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# 1. Pantalla de carga.
func _carga() -> void:
	change_scene_to_file(CARGA)
	if not await _hasta(func(): return _escena() == CARGA and current_scene.listo, 180.0):
		_fallo("1: la pantalla de carga no termina")
		return
	var c = current_scene
	await _pulsar("abajo")
	var esperado: String = "PULSA A PARA EMPEZAR" if dispositivo == "mando" else "PULSA INTRO PARA EMPEZAR"
	if c.toca.text != esperado:
		_fallo("1: el texto de inicio no dice qué pulsar («%s»)" % c.toca.text)
	if c.boton_prueba == null or not c.boton_prueba.has_focus(true):
		_fallo("1: ↓ no lleva el foco (visible) a «Probar la misión desde el principio»")
	await _pulsar("aceptar", 2)
	if not c.saliendo or not Engine.get_meta("ranura_prueba", false):
		_fallo("1: Intro / A en el botón de prueba no empieza la partida de prueba")
	if P.archivo() != P.GUARDADO_EXP_PRUEBA:
		_fallo("1: la partida no va a la ranura de prueba (%s)" % P.archivo())
	if not await _hasta(func(): return _escena() == REGION and not R.cambiando, 120.0):
		_fallo("1: no se llega a Pastos Verdes 3D (%s)" % _escena())
		return
	hechos.append("pantalla de carga")


# 2-4. Región: PV-02, andar, desconectar el mando, hablar con Tilo.
func _region() -> void:
	var v = current_scene
	if not await _hasta(func(): return D.current_timeline != null, 30.0):
		_fallo("2: PV-02 no empieza")
	else:
		await _leer_dialogo("2 (PV-02)")
	if G.activos() != ["Kael"]:
		_fallo("2: en la partida de prueba, Kael no va solo (%s)" % G.activos())
	await _esperar(15)
	var antes: Vector3 = v.kael.global_position
	_derecha(true)
	await _esperar(30)
	_derecha(false)
	await _esperar(5)
	var andado: float = v.kael.global_position.distance_to(antes)
	if andado < 1.0:
		_fallo("3: con %s, Kael no anda (%.2f m)" % ["el stick" if dispositivo == "mando" else "las flechas", andado])
	if Input.is_action_pressed("ui_right"):
		_fallo("3: al soltar, ui_right sigue pulsada")
	if D.current_timeline != null:                 # (si al andar salta PV-03, se lee)
		await _leer_dialogo("3 (PV-03)")
	var lejos: float = v.distancia                  # cámara: acercar con el stick derecho o con +
	_acercar(true)
	await _esperar(20)
	_acercar(false)
	await _esperar(3)
	if v.distancia >= lejos - 0.5:
		_fallo("3: con %s, la cámara no se acerca (%.1f → %.1f m)" % ["el stick derecho" if dispositivo == "mando" else "+", lejos, v.distancia])
	if dispositivo == "mando":                       # desconectarlo andando
		_derecha(true)
		await _esperar(10)
		Input.joy_connection_changed.emit(0, false)
		await _esperar(5)
		var quieto: Vector3 = v.kael.global_position
		await _esperar(15)
		if v.kael.global_position.distance_to(quieto) > 0.3:
			_fallo("3: con el mando desconectado andando, Kael sigue andando solo")
		if R.lbl_aviso == null or R.lbl_aviso.text != root.get_node("Entrada").AVISO_DESCONECTADO:
			_fallo("3: no se avisa de que el mando se ha desconectado")
		var k := InputEventKey.new()                # se sigue con el teclado
		k.keycode = KEY_RIGHT
		k.physical_keycode = KEY_RIGHT
		k.pressed = true
		Input.parse_input_event(k)
		await _esperar(20)
		k = k.duplicate()
		k.pressed = false
		Input.parse_input_event(k)
		await _esperar(5)
		if v.kael.global_position.distance_to(quieto) < 0.5:
			_fallo("3: tras desconectar el mando, el teclado no mueve a Kael")
		Input.joy_connection_changed.emit(0, true)
		var m := InputEventJoypadMotion.new()      # el mando vuelve con el stick en reposo
		m.device = 0
		m.axis = JOY_AXIS_LEFT_X
		m.axis_value = 0.0
		Input.parse_input_event(m)
		await _esperar(3)
		if D.current_timeline != null:
			await _leer_dialogo("3 (PV-03)")
	hechos.append("andar")
	var q: Vector3 = v.tilo.global_position + Vector3(1.0, 0, 0.6)
	v._colocar_kael(Vector3(q.x, v.altura(q.x, q.z), q.z))
	if not await _hasta(func(): return v.cerca == "tilo" and v._bloqueo_accion <= 0.0, 10.0):
		_fallo("4: junto a Tilo no sale «Hablar con Tilo»")
		return
	acciones = 0
	_evento("aceptar", true)
	_ruido()
	await _esperar(2)
	_evento("aceptar", false)
	await _esperar(1)
	# Desde c3f5692, Tilo abre PV-03: Lya llega corriendo y el diálogo empieza ~1,2 s después.
	if not await _hasta(func(): return D.current_timeline != null, 5.0):
		_fallo("4: Intro / A junto a Tilo no abre el diálogo")
	else:
		if acciones != 0:
			_fallo("4: la pulsación que abre el diálogo de Tilo cuenta también en el diálogo (%d)" % acciones)
		if D.current_state == D.States.IDLE:
			_fallo("4: la pulsación que abre el diálogo de Tilo deja ya la primera frase entera")
		await _leer_dialogo("4 (Tilo)")
	hechos.append("hablar")


# 5. Combate.
func _combate() -> void:
	var v = current_scene
	G.aprender("Kael", "Fuego", 2)                    # dos niveles de magia: dos pestañas
	v._encuentro()
	if not await _hasta(func(): return _escena() == COMBATE and not R.cambiando, 60.0):
		_fallo("5: no se entra en el combate")
		return
	var c = current_scene
	var magia_probada := false
	var huida := false
	for turno in 6:
		if not await _hasta(func(): return c.estado == "menu" and c.menu.activo, 40.0):
			_fallo("5: no llega el menú de un héroe")
			return
		await _esperar(3)
		var quien: String = c.menu.heroe_actual.get("nombre", "")
		if turno == 0:                                  # ATACAR pide objetivo, Esc / B vuelve, → y Intro / A atacan
			await _ir_a_fila(c, "ATACAR")
			await _pulsar("aceptar", 3)
			if c.estado != "objetivo":
				_fallo("5: Intro / A en ATACAR no pide objetivo o ataca ya (estado %s)" % c.estado)
				continue
			await _pulsar("cancelar", 3)
			if c.estado != "menu":
				_fallo("5: Esc / B al elegir objetivo no vuelve al menú (estado %s)" % c.estado)
			await _pulsar("aceptar", 3)
			var primero = c.objetivo_apuntado
			await _pulsar("derecha", 3)
			if c.objetivos_posibles.size() > 1 and c.objetivo_apuntado == primero:
				_fallo("5: → no cambia de objetivo")
			await _pulsar("aceptar", 3)
			if c.estado == "objetivo" or c.estado == "menu":
				_fallo("5: Intro / A no ataca al objetivo (estado %s)" % c.estado)
			continue
		if quien == "Kael" and not magia_probada:       # MAGIA: L1 / R1 (Q / E) cambian la pestaña
			magia_probada = true
			await _ir_a_fila(c, "MAGIA")
			await _pulsar("aceptar", 3)
			if c.estado != "magia" or c.menu._pestanas.size() < 2:
				_fallo("5: MAGIA no abre las pestañas de nivel (estado %s, %d pestañas)" % [c.estado, c.menu._pestanas.size()])
			else:
				var antes: int = c.magia_nivel_menu.get("Kael", 1)
				await _pulsar("pestana_sig", 3)
				if c.magia_nivel_menu.get("Kael", 1) == antes:
					_fallo("5: L1 / R1 (Q / E) no cambian la pestaña de magia")
				await _pulsar("cancelar", 3)
				if c.estado != "menu":
					_fallo("5: Esc / B en la magia no vuelve al menú")
			if c.estado == "menu":
				await _ir_a_fila(c, "HUIR")
				await _pulsar("aceptar", 3)
				huida = true
				break
			continue
		if turno >= 3:                                  # sin Kael a mano: se huye igual
			await _ir_a_fila(c, "HUIR")
			await _pulsar("aceptar", 3)
			huida = true
			break
		await _ir_a_fila(c, "ATACAR")                   # el turno de otro héroe: atacar
		await _pulsar("aceptar", 3)
		await _pulsar("aceptar", 3)
	if not magia_probada:
		_fallo("5: Kael no llegó a tener turno para probar la magia")
	if not huida or not await _hasta(func(): return _escena() == REGION and not R.cambiando, 60.0):
		_fallo("5: HUIR con Intro / A no vuelve a la región (%s)" % _escena())
		return
	hechos.append("combate")


# Mueve la selección del menú de combate con ↑ ↓ (cruceta) hasta la fila que empieza por «texto».
func _ir_a_fila(c, texto: String) -> void:
	for i in 8:
		var m = c.menu
		if m.sel >= 0 and m.sel < m.filas.size() and str(m.filas[m.sel]["item"].get("texto", "")).begins_with(texto):
			return
		await _pulsar("abajo", 2)
	_fallo("5: con ↓ no se llega a la fila %s" % texto)


# 6. Mapa: la barra con Start / Tab.
func _mapa() -> void:
	var v = current_scene
	if D.current_timeline != null:
		await _leer_dialogo("6")
	v._salir()
	if not await _hasta(func(): return _escena() == MAPA and not R.cambiando, 60.0):
		_fallo("6: no se sale al mapa (%s)" % _escena())
		return
	var m = current_scene
	await _esperar(10)
	await _pulsar("menu")
	var f = root.get_viewport().gui_get_focus_owner()
	if not m.barra_activa or f == null or not f.has_focus(true):
		_fallo("6: Start / Tab no ponen el foco (visible) en la barra")
	await _pulsar("aceptar")
	if m.menu_abierto == null or not m.menu_abierto.is_ancestor_of(root.get_viewport().gui_get_focus_owner()):
		_fallo("6: Intro / A en la barra no abre la ventana con el foco dentro")
	await _pulsar("cancelar")
	await _esperar(2)
	await _pulsar("cancelar")
	if m.menu_abierto != null or m.barra_activa:
		_fallo("6: Esc / B no cierran la ventana y la barra")
	hechos.append("mapa")
