extends SceneTree
# Prueba: busca la cruceta en la escena, simula un dedo empujando hacia una dirección y mira si
# el jugador se mueve hacia allí. Uso: --script prueba_dpad.gd -- escena=zona dpad

var esc: Node
var frames := 0
var dpad: Control
var antes := Vector2.ZERO
var fallos := 0


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _terminar() -> bool:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true




func _initialize() -> void:
	var nombre := "zona"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("escena="):
			nombre = a.substr(7)
	esc = load("res://%s.tscn" % nombre).instantiate()
	root.add_child(esc)


func _process(_d: float) -> bool:
	frames += 1
	if frames == 5:
		for n in esc.ui.get_children():
			if n.get_script() != null and n.get_script().resource_path.ends_with("dpad.gd"):
				dpad = n
		if dpad == null:
			_fallo("no hay cruceta en la escena")
			return _terminar()
		antes = esc.jugador.position
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = true
		t.position = dpad._centro() + Vector2(80, -10)
		dpad._gui_input(t)
		print("cruceta en ", dpad.position, " vector ", dpad.vector)
	if frames == 65:
		var d: Vector2 = esc.jugador.position - antes
		print("se ha movido ", d.round(), "  -> ", "OK hacia la derecha" if d.x > 20 else "NO se mueve")
		if d.x <= 20:
			_fallo("empujando la cruceta a la derecha, Kael no se mueve a la derecha (%s)" % d.round())
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = false
		dpad._gui_input(t)
	if frames == 80:
		print("al soltar: ui_right pulsado = ", Input.is_action_pressed("ui_right"))
		if Input.is_action_pressed("ui_right"):
			_fallo("al soltar la cruceta, la derecha sigue pulsada")
		return _terminar()
	return false
