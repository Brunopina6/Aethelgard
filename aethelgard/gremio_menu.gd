extends CanvasLayer
# El tablón del Gremio de aventureros (V11, hito C; gremio.gd): rango, reputación y los contratos con su estado.
# Cada contrato se acepta, se sigue (progreso) y se cobra aquí. Botones grandes para el dedo; Esc, Atrás de Android o
# «Cerrar» lo cierran. Lo abre la pieza oak_tablon_gremio de la ciudad 2D (ciudad_oakhaven.gd).

signal cerrado

const Gremio := preload("res://gremio.gd")
const ORO := Color("E8C46A")
const SUAVE := Color(0.85, 0.82, 0.74)
const BIEN := Color(0.6, 1.0, 0.55)
const APAGADO := Color(0.6, 0.6, 0.62)

var lista: VBoxContainer
var cabecera: Label
var mensaje: Label
var botones := {}                                 # id → Button (las pruebas los pulsan)


func _ready() -> void:
	layer = 65
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.6)
	fondo.size = Vector2(1280, 720)
	add_child(fondo)
	var panel := Panel.new()
	panel.position = Vector2(120, 40)
	panel.size = Vector2(1040, 640)
	add_child(panel)
	var t := _texto("Tablón del Gremio de aventureros", 30, ORO)
	t.position = Vector2(150, 56)
	t.size = Vector2(780, 40)
	add_child(t)
	cabecera = _texto("", 22, SUAVE)
	cabecera.position = Vector2(150, 100)
	cabecera.size = Vector2(780, 30)
	add_child(cabecera)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(180, 56)
	cerrar.position = Vector2(960, 54)
	cerrar.add_theme_font_size_override("font_size", 24)
	cerrar.pressed.connect(cerrar_menu)
	add_child(cerrar)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(150, 144)
	scroll.size = Vector2(990, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	lista = VBoxContainer.new()
	lista.custom_minimum_size = Vector2(970, 0)
	lista.add_theme_constant_override("separation", 10)
	scroll.add_child(lista)
	mensaje = _texto("", 20, BIEN)
	mensaje.position = Vector2(150, 624)
	mensaje.size = Vector2(990, 40)
	add_child(mensaje)
	_pintar()


func _texto(s: String, tam: int, c: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _pintar() -> void:
	var falta := Gremio.falta_rango()
	cabecera.text = "Rango %s · Reputación %d%s" % [Gremio.nombre_rango(), Gremio.reputacion(),
		"" if falta == 0 else " (faltan %d para el siguiente)" % falta]
	for n in lista.get_children():
		n.queue_free()
	botones.clear()
	for c in Gremio.CONTRATOS:
		var id: String = c["id"]
		var e := Gremio.estado(id)
		var fila := HBoxContainer.new()
		fila.custom_minimum_size = Vector2(970, 118)
		var izq := VBoxContainer.new()
		izq.custom_minimum_size = Vector2(740, 118)
		var nombre := _texto("%s%s" % ["✓ " if e == "hecho" else "", c["nombre"]], 24, APAGADO if e in ["hecho", "bloqueado"] else ORO)
		izq.add_child(nombre)
		var detalle := _texto(_detalle(c, e), 17, APAGADO if e in ["hecho", "bloqueado"] else SUAVE)
		detalle.custom_minimum_size = Vector2(740, 0)
		izq.add_child(detalle)
		fila.add_child(izq)
		var b := Button.new()
		b.custom_minimum_size = Vector2(210, 64)
		b.add_theme_font_size_override("font_size", 22)
		match e:
			"disponible":
				b.text = "Aceptar"
				b.pressed.connect(_aceptar.bind(id))
			"aceptado":
				b.text = "%d / %d" % [Gremio.progreso(id), Gremio.total(id)]
				b.disabled = true
			"listo":
				b.text = "Cobrar"
				b.pressed.connect(_cobrar.bind(id))
			"hecho":
				b.text = "Hecho"
				b.disabled = true
			_:
				b.text = "Rango %s" % Gremio.RANGOS[int(c["rango"])]["nombre"]
				b.disabled = true
		fila.add_child(b)
		botones[id] = b
		lista.add_child(fila)


func _detalle(c: Dictionary, e: String) -> String:
	var que := ""
	match c["tipo"]:
		"derrotar":
			que = "Derrotar: %d" % int(c["n"])
		"entregar":
			que = "Entregar: %d %s" % [int(c["n"]), c["que"]]
		"cumplir":
			que = "Hacerlo y volver al tablón"
	var p: Dictionary = c["premio"]
	var premio := "%d monedas, +%d de reputación" % [int(p.get("oro", 0)), int(p.get("rep", 0))]
	for o in p.get("objetos", {}):
		premio += ", %d %s" % [int(p["objetos"][o]), o]
	return "%s  ·  %s  ·  Premio: %s" % [c["texto"], que, premio]


func _aceptar(id: String) -> void:
	if Gremio.aceptar(id):
		Sonido.efecto("ui_tic")
		mensaje.text = "Contrato aceptado: «%s». Lo verás aquí cuando esté hecho." % Gremio.contrato(id)["nombre"]
	_pintar()


func _cobrar(id: String) -> void:
	var t := Gremio.cobrar(id)
	if t != "":
		Sonido.efecto("ui_equipar")
		mensaje.text = t
	_pintar()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree() and not is_queued_for_deletion():
		cerrar_menu()


func cerrar_menu() -> void:
	if is_queued_for_deletion():
		return
	cerrado.emit()
	queue_free()
