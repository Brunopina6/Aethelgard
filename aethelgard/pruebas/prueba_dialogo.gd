extends SceneTree
# Prueba de Dialogic: abre una escena; en la zona habla con el NPC más cercano. Cada 25
# fotogramas pulsa la acción de avanzar el texto y dice qué se está mostrando.

var esc: Node
var frames := 0


func _initialize() -> void:
	var nombre := "mapa"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("escena="):
			nombre = a.substr(7)
	esc = load("res://%s.tscn" % nombre).instantiate()
	root.add_child(esc)


func _process(_d: float) -> bool:
	frames += 1
	var d = root.get_node_or_null("Dialogic")
	if frames == 8 and esc.has_method("_accion"):
		esc._comprobar_cerca()
		esc._accion()
	if frames > 12 and frames % 25 == 0 and d != null:
		var activo: bool = d.current_timeline != null
		print("f", frames, " dialogo activo=", activo, " ui visible=", esc.ui.visible)
		var e := InputEventAction.new()
		e.action = "dialogic_default_action"
		e.pressed = true
		Input.parse_input_event(e)
		var e2 := InputEventAction.new()
		e2.action = "dialogic_default_action"
		e2.pressed = false
		Input.parse_input_event(e2)
	return frames > 330
