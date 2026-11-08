extends CanvasLayer
# Avanzar los diálogos de Dialogic en el móvil (Godot 4.x). Se carga solo (autoload «BotonDialogo»).
# Mientras hay un diálogo: botón «Seguir ▶» junto al cuadro de texto, y tocar en cualquier parte
# del cuadro de texto también avanza. Funciona con toques de pantalla y con el ratón.
# Las elecciones de Dialogic (si se añaden) salen más arriba y no quedan tapadas.

const ZONA_TEXTO := Rect2(0, 470, 1280, 250)      # parte de abajo de la pantalla (el cuadro de texto)

var zona: Control
var boton: Button
var _ultimo := 0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	zona = Control.new()
	zona.position = ZONA_TEXTO.position
	zona.size = ZONA_TEXTO.size
	zona.mouse_filter = Control.MOUSE_FILTER_STOP
	zona.gui_input.connect(_al_tocar)
	add_child(zona)
	boton = Button.new()
	boton.text = "SEGUIR ▸"
	boton.position = Vector2(1080, 640)
	boton.custom_minimum_size = Vector2(180, 64)
	boton.add_theme_font_override("font", load("res://menu_combate.gd").fuente("res://fuentes/SairaCondensed-Medium.ttf", 5, 0))
	boton.add_theme_font_size_override("font_size", 28)
	boton.add_theme_color_override("font_color", Color("F4EAD2"))
	var e := StyleBoxFlat.new()                     # estilo del menú de combate: oscuro con línea dorada fina
	e.bg_color = Color(0.043, 0.071, 0.125, 0.78)
	e.border_color = Color("E8C46A")
	e.set_border_width_all(2)
	e.set_corner_radius_all(4)
	for s in ["normal", "hover", "pressed", "focus"]:
		boton.add_theme_stylebox_override(s, e)
	boton.pressed.connect(_seguir)
	add_child(boton)
	visible = false


func _process(_d: float) -> void:
	var d = get_node_or_null("/root/Dialogic")
	visible = d != null and d.current_timeline != null
	if visible:
		estilar()


# Biblia de arte: el nombre y el cuadro de texto de Dialogic con el estilo del menú de combate. Se aplica una vez a cada
# nodo. La interfaz de los diálogos se reutiliza (recursos.gd, precalentar_dialogos), así que carga.gd lo llama ya en la
# pantalla de carga y el primer diálogo no tiene que hacerlo.
func estilar() -> void:
	var Estilo = load("res://estilo.gd")
	for n in get_tree().get_nodes_in_group("dialogic_name_label"):
		if not n.has_meta("cursiva"):                  # nombre en cursiva (su color lo pone Dialogic) sin caja
			n.set_meta("cursiva", true)
			n.add_theme_font_override("font", Estilo.cursiva())
			n.add_theme_font_size_override("font_size", 38)
			n.add_theme_color_override("font_outline_color", Color(Estilo.SOMBRA, 0.95))
			n.add_theme_constant_override("outline_size", 8)
			var caja := _caja_de(n)
			if caja != null:
				caja.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for n in get_tree().get_nodes_in_group("dialogic_dialog_text"):
		if not n.has_meta("estilo"):                   # caja oscura transparente con la línea dorada fina
			n.set_meta("estilo", true)
			n.add_theme_font_override("normal_font", Estilo.normal())
			n.add_theme_font_size_override("normal_font_size", 26)
			n.add_theme_color_override("default_color", Estilo.LUZ_CLARA)
			var caja := _caja_de(n)
			if caja != null:
				caja.add_theme_stylebox_override("panel", Estilo.ventana(0.8))


# Primer panel que envuelve a un nodo del diálogo (la caja que se ve detrás).
func _caja_de(n: Node) -> Control:
	var p := n.get_parent()
	for i in 3:
		if p is PanelContainer or p is Panel:
			return p
		if p == null:
			return null
		p = p.get_parent()
	return null



func _al_tocar(ev: InputEvent) -> void:
	if (ev is InputEventScreenTouch or ev is InputEventMouseButton) and ev.pressed:
		_seguir()
		zona.accept_event()


# Avanza el texto (si aún se está escribiendo, lo completa). Un toque del móvil genera también un
# clic de ratón: se ignora el segundo si llega casi a la vez.
func _seguir() -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo < 150:
		return
	_ultimo = ahora
	var d = get_node_or_null("/root/Dialogic")
	if d != null and d.current_timeline != null:
		d.Inputs.handle_input()
