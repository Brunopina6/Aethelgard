extends SceneTree
# Prueba: con un diálogo abierto, simula toques de pantalla (como el móvil) y clics de ratón,
# y dice si el diálogo avanza.

var c: Node
var frames := 0
var d


func _initialize() -> void:
	c = load("res://mapa.tscn").instantiate()
	root.add_child(c)


func _evento_actual() -> int:
	return d.current_event_idx if d != null else -1


func _process(_dt: float) -> bool:
	frames += 1
	d = root.get_node_or_null("Dialogic")
	if frames in [60, 120, 180, 240, 300, 360]:
		var antes := _evento_actual()
		var modo: String = {60: "boton", 120: "toque", 180: "toque", 240: "toque", 300: "raton", 360: "toque"}[frames]
		var pos := Vector2(640, 600) if frames != 240 else Vector2(1150, 670)
		if modo == "boton":
			var b = root.get_node_or_null("BotonDialogo")
			if b != null:
				b._seguir()
		elif modo == "raton":
			var m := InputEventMouseButton.new()
			m.button_index = MOUSE_BUTTON_LEFT
			m.position = pos
			m.global_position = pos
			m.pressed = true
			Input.parse_input_event(m)
			var m2 := m.duplicate()
			m2.pressed = false
			Input.parse_input_event(m2)
		else:
			var t := InputEventScreenTouch.new()
			t.index = 0
			t.position = pos
			t.pressed = true
			Input.parse_input_event(t)
			var t2 := InputEventScreenTouch.new()
			t2.index = 0
			t2.position = pos
			t2.pressed = false
			Input.parse_input_event(t2)
		await_frames(antes, modo, pos)
	return frames > 420


func await_frames(antes: int, modo: String, pos: Vector2) -> void:
	await process_frame
	await process_frame
	await process_frame
	print("%s en %s: evento %d -> %d  %s" % [modo, pos, antes, _evento_actual(), "AVANZA" if _evento_actual() != antes else "no avanza"])
