extends Node
# Entrada (Godot 4.x, autoload «Entrada»): con qué se juega ahora y el foco de los menús para teclado y mando
# (TASKS.md, T-025; plan en docs/entrada/android_tv_dualshock4_plan.md). No consume ningún evento.
#   - modo: «puntero» (dedo o ratón), «teclado» o «mando»; cambia con el último evento de verdad.
#   - enfocar(c): da el foco a un botón. Con el dedo o el ratón no se dibuja el marco: el foco solo se ve al moverse
#     con teclado o mando (estilo.gd), así que en el móvil nada cambia.
#   - clave_enfocada() y restaurar(): las ventanas que se repintan (menus.gd, tienda.gd, diario.gd) devuelven el foco
#     al mismo botón (meta «clave») tras rehacer sus botones.
#   - Si se desconecta un mando, se sueltan las acciones que tuviera pulsadas (para que nadie siga andando solo) y se
#     avisa de que se puede seguir con la pantalla o el teclado. Nada espera a ese mando.
# Acciones del juego (project.godot): ui_accept (Intro, Espacio, A/✕), ui_cancel (Esc, B/○), menu_juego (Tab, Esc,
# Start/Options), pestana_anterior / pestana_siguiente (Q / E, RePág / AvPág, L1 / R1), camara_acercar / camara_alejar
# (+ / -, stick derecho) y las ui_* de dirección (flechas, cruceta y stick izquierdo).

signal modo_cambiado(modo: String)

const ACCIONES := ["ui_left", "ui_right", "ui_up", "ui_down", "ui_accept", "ui_cancel", "menu_juego",
	"pestana_anterior", "pestana_siguiente", "camara_acercar", "camara_alejar", "dialogic_default_action"]
const AVISO_DESCONECTADO := "Mando desconectado. Puedes seguir con la pantalla o el teclado."

var modo := "puntero"
var _inicio := 0                                 # ms al abrir (avisos de mandos que Android anuncia al arrancar)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_inicio = Time.get_ticks_msec()
	var mandos := Input.get_connected_joypads()
	for id in mandos:                              # registro técnico: qué dispositivo se anuncia como mando
		print("Entrada: dispositivo de mando %d «%s» (mapa conocido: %s)" % [id, Input.get_joy_name(id), Input.is_joy_known(id)])
	# Con pantalla táctil se empieza con el dedo aunque se anuncie un mando: el Redmi anuncia uno sin tenerlo (10/11) y
	# salía «PULSA INTRO». Con un mando de verdad, su primera pulsación pasa a «mando» (_mirar). Sin pantalla táctil
	# (Android TV), como siempre.
	if not mandos.is_empty() and not DisplayServer.is_touchscreen_available():
		modo = "mando"
	elif not _tactil():
		modo = "teclado"
	Input.joy_connection_changed.connect(_al_cambiar_mando)
	# Cada evento se mira al llegar a la ventana, antes que ningún _input: si una escena lo consume en el suyo (p. ej.
	# la pantalla de carga con ↓), el modo cambia igual.
	get_tree().root.window_input.connect(_mirar)


func _tactil() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


# Botones del propio teléfono que llegan como teclas (volumen, encendido, atrás, menú…): no son un teclado y no deben
# cambiar los textos a los de teclado. Visto en el Redmi el 10/11: bajar el volumen pasaba a «teclado».
const TECLAS_DEL_SISTEMA := [KEY_VOLUMEDOWN, KEY_VOLUMEUP, KEY_VOLUMEMUTE, KEY_BACK, KEY_MENU, KEY_STANDBY,
	KEY_MEDIAPLAY, KEY_MEDIASTOP, KEY_MEDIAPREVIOUS, KEY_MEDIANEXT, KEY_MEDIARECORD, KEY_UNKNOWN]


func _mirar(ev: InputEvent) -> void:
	var nuevo := modo
	if ev is InputEventScreenTouch or ev is InputEventScreenDrag or (ev is InputEventMouseButton and ev.pressed):
		nuevo = "puntero"
	elif ev is InputEventKey and ev.pressed and not ev.keycode in TECLAS_DEL_SISTEMA:
		nuevo = "teclado"
	elif ev is InputEventJoypadButton and ev.pressed:
		nuevo = "mando"
	elif ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.5:
		nuevo = "mando"
	if nuevo != modo:
		# registro técnico (10/11): qué evento cambia el modo, una línea por cambio (sin datos personales)
		print("Entrada: modo %s → %s por %s (dispositivo %d)" % [modo, nuevo, ev.as_text(), ev.device])
		modo = nuevo
		modo_cambiado.emit(modo)


# ¿Se navega con el foco (teclado o mando)? Con el dedo o el ratón, no.
func con_foco() -> bool:
	return modo != "puntero"


# Da el foco a un botón en cuanto se pueda: puede estar recién creado, o dentro de algo que se vuelve a ver un
# fotograma después (p. ej. los botones de la zona al cerrar la tienda). Lo intenta unos pocos fotogramas.
func enfocar(c: Control) -> void:
	if c != null:
		_enfocar(c)


func _enfocar(c) -> void:
	for i in 10:
		await get_tree().process_frame
		if not is_instance_valid(c) or c.is_queued_for_deletion():
			return
		if c.is_inside_tree() and c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE:
			c.grab_focus(not con_foco())
			return


# Encadena unos botones en anillo para las flechas y la cruceta (← → y ↑ ↓ pasan al anterior y al siguiente). Hace
# falta cuando no comparten un contenedor: Godot solo busca vecinos dentro del mismo Control de arriba, y botones
# sueltos en una CanvasLayer (MAPA DEL MUNDO y TIENDA, la barra del mapa y «Misiones») no se encontrarían.
func encadenar(botones: Array) -> void:
	var n := botones.size()
	if n < 2:
		return
	for i in n:
		var b: Control = botones[i]
		var antes: NodePath = b.get_path_to(botones[posmod(i - 1, n)])
		var despues: NodePath = b.get_path_to(botones[(i + 1) % n])
		b.focus_neighbor_left = antes
		b.focus_neighbor_top = antes
		b.focus_previous = antes
		b.focus_neighbor_right = despues
		b.focus_neighbor_bottom = despues
		b.focus_next = despues


# Clave estable de un botón: su meta «clave» o, si no la tiene, su texto.
static func clave(c: Control) -> String:
	if c == null:
		return ""
	if c.has_meta("clave"):
		return str(c.get_meta("clave"))
	return str(c.get("text")) if "text" in c else c.name


# Clave del botón con el foco, si está dentro de «raiz»; si no, «».
func clave_enfocada(raiz: Node) -> String:
	var f := get_viewport().gui_get_focus_owner()
	if f != null and raiz.is_ancestor_of(f):
		return clave(f)
	return ""


# Devuelve el foco al botón de esa clave dentro de «raiz» (o, si ya no se puede usar, a «defecto» o al primero). Si la
# clave es «», el foco no estaba en la ventana: no se toca.
func restaurar(raiz: Node, clave_antes: String, defecto: Control = null) -> void:
	if clave_antes == "":
		return
	var c := buscar(raiz, clave_antes)
	if c == null:
		c = defecto if defecto != null and _usable(defecto) else primero(raiz)
	if c != null:
		c.grab_focus(not con_foco())


func buscar(raiz: Node, clave_buscada: String) -> Control:
	for n in raiz.find_children("*", "BaseButton", true, false):
		if _usable(n) and clave(n) == clave_buscada:
			return n
	return null


# El primer botón que se puede usar (en el orden del árbol).
func primero(raiz: Node) -> Control:
	for n in raiz.find_children("*", "BaseButton", true, false):
		if _usable(n):
			return n
	return null


func _usable(c: Control) -> bool:
	return is_instance_valid(c) and c.is_inside_tree() and c.is_visible_in_tree() \
		and not (c is BaseButton and c.disabled) and c.focus_mode != Control.FOCUS_NONE and not c.is_queued_for_deletion()


# Al desconectarse un mando: se sueltan sus acciones y se avisa. Al conectarse, solo se avisa.
func _al_cambiar_mando(_dispositivo: int, conectado: bool) -> void:
	if conectado:
		# Los que Android anuncia al abrir la app en un móvil no se avisan (el Redmi anuncia uno sin tenerlo, 10/11).
		if not (DisplayServer.is_touchscreen_available() and Time.get_ticks_msec() - _inicio < 5000):
			Recursos.avisar("Mando conectado.", 2.5)
		return
	for a in ACCIONES:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			Input.action_release(a)
	if modo == "mando":
		modo = "puntero" if _tactil() else "teclado"
		modo_cambiado.emit(modo)
	Recursos.avisar(AVISO_DESCONECTADO)
