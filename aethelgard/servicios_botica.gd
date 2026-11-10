extends CanvasLayer
# La botica de Mirta (V10): «¿Qué necesitáis?». Comprar ingredientes (la tienda de siempre, pestaña Botica) o la
# alquimia de Lya (el mismo taller, si Lya está en el grupo). Botones grandes; Esc cierra. (servicios.gd)

signal cerrado

const ORO := Color("E8C46A")
var abierto: Node = null


func _ready() -> void:
	layer = 65
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.55)
	fondo.size = Vector2(1280, 720)
	add_child(fondo)
	var panel := Panel.new()
	panel.position = Vector2(390, 210)
	panel.size = Vector2(500, 300)
	add_child(panel)
	var t := Label.new()
	t.text = "Mirta: «¿Qué necesitáis?»"
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", ORO)
	t.position = Vector2(420, 230)
	add_child(t)
	var y := 290.0
	var opciones: Array = [["Comprar ingredientes", _comprar]]
	if load("res://grupo.gd").activos().has("Lya") and load("res://progreso.gd").hito("bq_alquimia"):
		opciones.append(["Alquimia de Lya", _alquimia])
	opciones.append(["Nada, gracias", cerrar])
	var primero: Button = null
	for o in opciones:
		var b := Button.new()
		b.text = o[0]
		b.custom_minimum_size = Vector2(420, 56)
		b.position = Vector2(430, y)
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(o[1])
		add_child(b)
		if primero == null:
			primero = b
		y += 66.0
	var E = get_node_or_null("/root/Entrada")
	if E != null and E.con_foco() and primero != null:
		E.enfocar(primero)


func _unhandled_input(ev: InputEvent) -> void:
	if abierto == null and ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()


func _comprar() -> void:
	Sonido.efecto("ui_tic")
	var capa := CanvasLayer.new()
	capa.layer = 66
	add_child(capa)
	var tienda = load("res://tienda.gd").new()
	tienda.pestana = "Botica"
	tienda.solo_botica = true
	tienda.cerrado.connect(func():
		capa.queue_free()
		abierto = null)
	capa.add_child(tienda)
	abierto = tienda


func _alquimia() -> void:
	Sonido.efecto("ui_tic")
	var a = load("res://alquimia_menu.gd").new()
	a.taller = "alquimia"
	a.cerrado.connect(func(): abierto = null)
	add_child(a)
	abierto = a


func cerrar() -> void:
	cerrado.emit()
	queue_free()
