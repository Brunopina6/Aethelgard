extends Control
# V12, mapamundi 3D (15/11/2026): la ventana del VIAJE RÁPIDO (primera entrega: Oakhaven y el campamento de Pastos
# Verdes). Solo enseña los destinos que la partida ya conoce (datos.gd, destinos_conocidos): los demás no aparecen, ni
# su nombre. Cada destino, con su nombre y su región. El viaje es gratis y se llega a salvo (el mapamundi lo hace).
# Toque o clic en un destino; con teclado o mando, ↑ ↓ e Intro / A; Esc / B o «Cancelar» la cierra sin hacer nada.

signal elegido(id: String)
signal cerrado

const D := preload("res://zonas3d/mapamundi/datos.gd")
const Estilo := preload("res://estilo.gd")

var destinos: Array = []
var desde := Vector2.INF                  # dónde está Kael (para «ya estás aquí»)
var botones: Array = []
var boton_cancelar: Button
var nota: Label
var _cerrando := false


func preparar(lista: Array, donde: Vector2) -> void:
	destinos = lista
	desde = donde


func _ready() -> void:
	name = "MenuViaje"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP           # los toques no llegan al mapamundi (Kael no anda)
	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.03, 0.06, 0.55)
	velo.size = Vector2(1280, 720)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Estilo.ventana(0.9))
	panel.custom_minimum_size = Vector2(560, 0)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var titulo := Label.new()
	titulo.text = "Viaje rápido"
	titulo.add_theme_font_override("font", Estilo.cursiva())
	titulo.add_theme_font_size_override("font_size", 38)
	titulo.add_theme_color_override("font_color", Estilo.ORO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(titulo)
	var sub := Label.new()
	sub.text = "Elige un lugar que ya conoces. El viaje es gratis y llegas a salvo."
	sub.add_theme_font_size_override("font_size", 18)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(520, 0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	if destinos.is_empty():
		var vacio := Label.new()
		vacio.text = "Aún no conoces ningún destino.\nVisita un lugar para poder volver a él."
		vacio.add_theme_font_size_override("font_size", 22)
		vacio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(vacio)
	for id in destinos:
		var s: Dictionary = D.SITIOS[id]
		var b := Button.new()
		b.name = "Destino_" + id
		b.set_meta("clave", "viaje:" + id)
		b.custom_minimum_size = Vector2(520, 76)
		b.focus_mode = Control.FOCUS_ALL
		var motivo := D.motivo_destino(id, desde)
		var aqui := motivo.begins_with("Ya estás")
		b.text = "%s\n%s%s" % [s["nombre"], D.DESTINOS[id]["region"], "  ·  estás aquí" if aqui else ""]
		b.add_theme_font_size_override("font_size", 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = aqui
		b.pressed.connect(_elegir.bind(id))
		col.add_child(b)
		botones.append(b)
	nota = Label.new()
	nota.add_theme_font_size_override("font_size", 18)
	nota.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.custom_minimum_size = Vector2(520, 0)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nota.visible = false
	col.add_child(nota)
	boton_cancelar = Button.new()
	boton_cancelar.name = "Cancelar"
	boton_cancelar.text = "Cancelar"
	boton_cancelar.set_meta("clave", "viaje:cancelar")
	boton_cancelar.custom_minimum_size = Vector2(520, 56)
	boton_cancelar.add_theme_font_size_override("font_size", 22)
	boton_cancelar.focus_mode = Control.FOCUS_ALL
	boton_cancelar.pressed.connect(cerrar)
	col.add_child(boton_cancelar)
	panel.reset_size()
	panel.position = (Vector2(1280, 720) - panel.get_combined_minimum_size()) * 0.5
	var primero: Control = boton_cancelar
	for b in botones:
		if not b.disabled:
			primero = b
			break
	var ent = get_node_or_null("/root/Entrada")
	if ent != null:
		ent.enfocar(primero)
	var son = get_node_or_null("/root/Sonido")
	if son != null:
		son.efecto("pagina")


func _input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("menu_juego"):
		get_viewport().set_input_as_handled()
		cerrar()


func avisar(texto: String) -> void:
	nota.text = texto
	nota.visible = texto != ""


func _elegir(id: String) -> void:
	if _cerrando:
		return
	elegido.emit(id)


func cerrar() -> void:
	if _cerrando:
		return
	_cerrando = true
	var son = get_node_or_null("/root/Sonido")
	if son != null:
		son.efecto("ui_tic")
	cerrado.emit()
	queue_free()
