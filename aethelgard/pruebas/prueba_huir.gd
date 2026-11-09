extends SceneTree
# Prueba: tocar HUIR en el menú de combate. Comprueba que el grupo huye («¡El grupo huye!» y el combate termina).
# Sin ventana, la ventana raíz mide 100 × 100 y el juego (1280 × 720) se escala a ella: el clic va en las coordenadas
# de esa ventana (root.get_final_transform()). Antes del 09/11 iba en las del juego, caía fuera y la prueba salía
# SUPERADA sin haber tocado HUIR (solo imprimía el estado). El combate no guarda: no viene de un mapa.

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
		e.position = root.get_final_transform() * p
		e.global_position = e.position
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
		_toque(Vector2(900, 160 + 72 * 4 + 36))     # el centro de la fila HUIR (la quinta)
	if hecho and frames % 30 == 0 and frames < 200:
		print("f", frames, " estado=", c.estado, " registro=", c.registro.text)
	if frames > 200:
		if c.estado == "fin" and c.registro.text == "¡El grupo huye!":
			print("OK: tocar HUIR hace huir al grupo")
			print("FALLOS: 0")
		else:
			print("FALLO: tocar HUIR no hace huir al grupo (estado %s, cartel «%s»)" % [c.estado, c.registro.text])
			print("FALLOS: 1")
		return true
	return false
