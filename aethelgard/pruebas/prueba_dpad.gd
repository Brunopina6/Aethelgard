extends SceneTree
# Prueba: busca la cruceta en la escena, simula un dedo empujando hacia una dirección y mira si
# el jugador se mueve hacia allí. Uso: --script prueba_dpad.gd -- escena=zona dpad

var esc: Node
var frames := 0
var dpad: Control
var antes := Vector2.ZERO


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
			print("NO HAY CRUCETA")
			return true
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
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = false
		dpad._gui_input(t)
	if frames == 80:
		print("al soltar: ui_right pulsado = ", Input.is_action_pressed("ui_right"))
		return true
	return false
