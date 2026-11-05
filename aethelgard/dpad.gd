extends Control
# Cruceta táctil (D-pad analógico) para mover al personaje en el móvil (Godot 4.x).
# Se arrastra el dedo desde el centro: cuanto más lejos, más rápido. Pulsa las acciones
# ui_left / ui_right / ui_up / ui_down, las mismas que las flechas del teclado, así que
# mapa.gd y zona.gd no necesitan cambios para moverse con ella.
# Uso: var d = load("res://dpad.gd").new(); d.position = Vector2(30, 450); ui.add_child(d)

const RADIO := 90.0             # radio de la cruceta en píxeles
const ZONA_MUERTA := 0.2        # por debajo de esto no se mueve
const COLOR_BASE := Color(0.35, 0.68, 0.95, 0.30)
const COLOR_BORDE := Color(0.92, 0.96, 1.0, 0.75)
const COLOR_FLECHA := Color(1, 1, 1, 0.8)

var dedo := -1                  # índice del dedo que la usa (-2 = ratón, para probar en PC)
var vector := Vector2.ZERO      # dirección actual (-1..1)


func _ready() -> void:
	size = Vector2(RADIO, RADIO) * 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP    # lo que se toca aquí no mueve al personaje por toque


func _centro() -> Vector2:
	return size * 0.5


func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed and dedo < 0:
			dedo = e.index
			_mover(e.position)
		elif not e.pressed and e.index == dedo:
			_soltar()
		accept_event()
	elif e is InputEventScreenDrag:
		if e.index == dedo:
			_mover(e.position)
		accept_event()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and dedo == -1:
			dedo = -2
			_mover(e.position)
		elif not e.pressed and dedo == -2:
			_soltar()
		accept_event()
	elif e is InputEventMouseMotion and dedo == -2:
		_mover(e.position)
		accept_event()


func _mover(p: Vector2) -> void:
	var d := (p - _centro()) / RADIO
	if d.length() > 1.0:
		d = d.normalized()
	vector = d if d.length() > ZONA_MUERTA else Vector2.ZERO
	_aplicar("ui_right", vector.x)
	_aplicar("ui_left", -vector.x)
	_aplicar("ui_down", vector.y)
	_aplicar("ui_up", -vector.y)
	queue_redraw()


func _aplicar(accion: String, fuerza: float) -> void:
	if fuerza > ZONA_MUERTA:
		Input.action_press(accion, clampf(fuerza, 0.0, 1.0))
	else:
		Input.action_release(accion)


func _soltar() -> void:
	dedo = -1
	vector = Vector2.ZERO
	for a in ["ui_right", "ui_left", "ui_down", "ui_up"]:
		Input.action_release(a)
	queue_redraw()


func _exit_tree() -> void:
	_soltar()                                    # que no se quede «pulsada» al cambiar de escena


func _notification(n: int) -> void:
	if n == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_soltar()


func _draw() -> void:
	var c := _centro()
	draw_circle(c, RADIO, COLOR_BASE)
	draw_arc(c, RADIO, 0.0, TAU, 48, COLOR_BORDE, 3.0, true)
	for i in 4:                                  # flechas arriba, derecha, abajo, izquierda
		var a := -PI * 0.5 + i * PI * 0.5
		var dir := Vector2(cos(a), sin(a))
		var lado := dir.orthogonal()
		var punta := c + dir * (RADIO - 12.0)
		var base := c + dir * (RADIO - 36.0)
		draw_colored_polygon(PackedVector2Array([punta, base + lado * 13.0, base - lado * 13.0]), COLOR_FLECHA)
	var pomo := c + vector * (RADIO - 30.0)
	draw_circle(pomo, 30.0, Color(0.92, 0.96, 1.0, 0.55 if dedo != -1 else 0.35))
	draw_arc(pomo, 30.0, 0.0, TAU, 32, COLOR_BORDE, 2.0, true)
