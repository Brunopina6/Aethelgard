extends SceneTree
# Combate automático: escribe cada mensaje nuevo del cartel superior (qué hace cada uno).

var c: Node
var ultimo := ""
var frames := 0


func _initialize() -> void:
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _process(_d: float) -> bool:
	frames += 1
	if c.registro != null and c.registro.text != ultimo:
		ultimo = c.registro.text
		print("  ", ultimo)
	return frames > 2400 or (c.estado == "fin" and frames > 60 and ultimo.begins_with("+"))
