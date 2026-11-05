extends SceneTree
# Prueba: tocar HUIR en el menú de combate.

var c: Node
var frames := 0
var hecho := false


func _initialize() -> void:
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _toque(p: Vector2) -> void:
	for pulsado in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = p
		e.global_position = p
		e.pressed = pulsado
		Input.parse_input_event(e)


func _process(_d: float) -> bool:
	frames += 1
	if not hecho and c.estado == "menu":
		hecho = true
		var textos := []
		for f in c.menu.filas:
			textos.append(f["lbl"].text)
		print("filas: ", textos)
		_toque(Vector2(900, 160 + 72 * 4 + 36))
	if hecho and frames % 30 == 0 and frames < 200:
		print("f", frames, " estado=", c.estado, " registro=", c.registro.text)
	return frames > 200
