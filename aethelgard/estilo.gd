extends RefCounted
# Estilo común de la interfaz de Aethelgard (Godot 4.x), igual que el menú de combate (Biblia de arte):
# fondo casi negro azulado y transparente, líneas doradas finas, texto claro, órdenes en condensada
# fina (Saira Condensed) y títulos en cursiva elegante (Cormorant).
# Recursos lo mezcla con el tema por defecto de Godot al arrancar, así lo heredan todos los botones,
# textos y paneles. Los scripts pueden usar también Estilo.ventana(), Estilo.cursiva()...
#   var Estilo = load("res://estilo.gd")

const SOMBRA := Color("0B1220")
const SOMBRA_MEDIA := Color("2E3F5C")
const ORO := Color("E8C46A")
const LUZ_CLARA := Color("F4EAD2")
const BRASA := Color("FF7A3C")
const CURA := Color("8FF0B0")
const PM := Color("4D8EF0")              # barras de PM (T-099): azul, distinto del celeste de Kael
const PM_CLARO := Color("A4C6FF")        # cifras y etiqueta de los PM (se leen sobre el fondo oscuro)
const GRIS := Color(0.62, 0.64, 0.7)
const GRIS_APAGADO := Color(0.4, 0.42, 0.48)
const M := preload("res://menu_combate.gd")

static var _tema: Theme
static var _cursiva: Font
static var _normal: Font


static func cursiva() -> Font:
	if _cursiva == null:
		_cursiva = M.fuente(M.FUENTE_NOMBRE, 0, 600)
	return _cursiva


static func normal() -> Font:
	if _normal == null:
		_normal = M.fuente(M.FUENTE_ORDEN_FUERTE, 1, 0)
	return _normal


# Panel / ventana: oscuro y transparente, con una línea dorada fina arriba.
static func ventana(opacidad := 0.82) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = Color(SOMBRA, opacidad)
	e.border_color = Color(ORO, 0.7)
	e.border_width_top = 2
	e.set_corner_radius_all(3)
	e.set_content_margin_all(14)
	return e


static func _boton(fondo: float, linea: float, borde := 1) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = Color(SOMBRA, fondo)
	e.border_color = Color(ORO, linea)
	e.border_width_bottom = borde
	e.set_corner_radius_all(3)
	e.content_margin_left = 14
	e.content_margin_right = 14
	e.content_margin_top = 6
	e.content_margin_bottom = 6
	return e


# Foco: un marco dorado fino alrededor del botón. Godot 4.7 solo lo dibuja al moverse con teclado o mando
# («gui/common/show_focus_state_on_pointer_event» = 1): al tocar o hacer clic, el botón se ve como siempre.
static func _foco() -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.draw_center = false
	e.border_color = ORO
	e.set_border_width_all(2)
	e.set_corner_radius_all(4)
	e.set_expand_margin_all(3)
	return e


static func tema() -> Theme:
	if _tema != null:
		return _tema
	var t := Theme.new()
	t.default_font = normal()
	t.default_font_size = 22
	for tipo in ["Label", "Button", "LineEdit", "CheckBox", "OptionButton"]:   # en un tema de ventana hay que ponerla a cada tipo
		t.set_font("font", tipo, normal())
	# textos
	t.set_color("font_color", "Label", LUZ_CLARA)
	t.set_color("font_shadow_color", "Label", Color(SOMBRA, 0.75))
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 2)
	t.set_constant("shadow_outline_size", "Label", 4)
	t.set_color("font_outline_color", "Label", Color(SOMBRA, 0.9))
	# botones: oscuros con una línea dorada debajo; al pasar o elegir, la línea brilla
	t.set_stylebox("normal", "Button", _boton(0.62, 0.45))
	t.set_stylebox("hover", "Button", _boton(0.8, 0.95, 2))
	t.set_stylebox("pressed", "Button", _boton(0.9, 1.0, 2))
	t.set_stylebox("hover_pressed", "Button", _boton(0.9, 1.0, 2))
	t.set_stylebox("focus", "Button", _foco())         # solo con teclado o mando (Godot no lo enseña al tocar)
	t.set_stylebox("disabled", "Button", _boton(0.35, 0.12))
	t.set_color("font_color", "Button", LUZ_CLARA)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", ORO)
	t.set_color("font_hover_pressed_color", "Button", ORO)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", GRIS_APAGADO)
	t.set_color("font_outline_color", "Button", Color(SOMBRA, 0.9))
	# paneles
	t.set_stylebox("panel", "PanelContainer", ventana())
	t.set_stylebox("panel", "Panel", ventana())
	# barras finas
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(LUZ_CLARA, 0.16)
	fondo.content_margin_top = 2
	fondo.content_margin_bottom = 2
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = ORO
	t.set_stylebox("background", "ProgressBar", fondo)
	t.set_stylebox("fill", "ProgressBar", relleno)
	t.set_color("font_color", "ProgressBar", LUZ_CLARA)
	# barra de desplazamiento fina
	var guia := StyleBoxFlat.new()
	guia.bg_color = Color(LUZ_CLARA, 0.08)
	guia.content_margin_left = 3
	guia.content_margin_right = 3
	var tirador := StyleBoxFlat.new()
	tirador.bg_color = Color(ORO, 0.6)
	tirador.set_corner_radius_all(3)
	t.set_stylebox("scroll", "VScrollBar", guia)
	t.set_stylebox("grabber", "VScrollBar", tirador)
	t.set_stylebox("grabber_highlight", "VScrollBar", tirador)
	t.set_stylebox("grabber_pressed", "VScrollBar", tirador)
	_tema = t
	return t
