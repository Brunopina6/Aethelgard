extends CanvasLayer
# Puesta en escena de un diálogo importante (T-081): por ahora, el prólogo en el mapa del mundo (mapa.gd).
# - Entrada: el mapa se oscurece con una viñeta, bajan dos franjas de cine, la cámara se acerca despacio a Kael y
#   aparece el título. Después empieza el diálogo (Dialogic), por encima de todo esto.
# - Durante: «Saltar ▸▸» (o Esc / B) termina la escena. El botón no coge el foco: Intro / A siguen siendo del diálogo
#   (una pulsación, una acción; boton_dialogo.gd).
# - Salida, al acabar o al saltar: la cámara, las capas y el control vuelven como estaban. No toca la misión: quien la
#   llama ya ha marcado el prólogo como visto, y la línea de tiempo no tiene eventos de juego.

signal terminada

const OSCURO := 0.6                                # cuánto se oscurece el mapa detrás de los retratos
const ZOOM := 1.15                                 # la cámara se acerca un 15 %
const FRANJA := 46.0                               # alto de cada franja de cine (de 720)

var camara: Camera2D
var _layout: CanvasLayer = null                    # la interfaz de Dialogic (se reutiliza: se deja como estaba)
var _zoom0 := Vector2.ONE
var _capa_dialogic := 1
var _dialogic: Node
var _velo: ColorRect
var _vineta: TextureRect
var _franjas: Array = []
var _titulo: Control
var _saltar: Button
var _acabando := false
var _entrada: Array = []                           # las animaciones de entrada (se cortan si se salta antes)
var _ocultos: Array = []                           # lo que se ocultó al empezar (vuelve a verse al acabar)
var saltada := false                               # lo miran las pruebas


func empezar(linea: String, cam: Camera2D, texto_titulo := "", ocultar: Array = []) -> void:
	layer = 1
	camara = cam
	for n in ocultar:                              # lo que distrae detrás de los retratos (p. ej. el muñeco del mapa)
		if n is CanvasItem and n.visible:
			n.visible = false
			_ocultos.append(n)
	_dialogic = get_node_or_null("/root/Dialogic")
	_construir(texto_titulo)
	# El diálogo arranca YA, en el fotograma de llegada (la pantalla aún está en negro): lo que Dialogic hace la primera
	# vez (unos 60-70 ms en el PC, casi todo fuera del dibujo) se paga ahí, como antes de esta puesta en escena. Se
	# queda en pausa y transparente hasta que acaba la entrada; luego aparece con un fundido y sigue.
	if _dialogic != null:
		_dialogic.timeline_ended.connect(_al_terminar, CONNECT_ONE_SHOT)
		_dialogic.start(linea)
		_dialogic.paused = true
		var lay = _dialogic.Styles.get_layout_node()
		if lay != null and lay is CanvasLayer:     # el diálogo, por encima del velo y de las franjas
			_layout = lay
			_capa_dialogic = lay.layer
			lay.layer = layer + 1
			_ver_dialogo(0.0)
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_entrada.append(t)
	t.tween_property(_velo, "color:a", OSCURO, 0.8)
	t.tween_property(_vineta, "modulate:a", 1.0, 0.8)
	for f in _franjas:
		t.tween_property(f, "size:y", FRANJA, 0.7)
	t.tween_property(_franjas[1], "position:y", 720.0 - FRANJA, 0.7)
	if camara != null:
		_zoom0 = camara.zoom
		t.tween_property(camara, "zoom", _zoom0 * ZOOM, 1.6).set_ease(Tween.EASE_IN_OUT)
	if _titulo != null:                            # el título aparece, se queda un momento y se va
		var tt := create_tween()
		_entrada.append(tt)
		tt.tween_interval(0.35)
		tt.tween_property(_titulo, "modulate:a", 1.0, 0.5)
		tt.tween_interval(1.0)
		tt.tween_property(_titulo, "modulate:a", 0.0, 0.5)
		await tt.finished
	else:
		await t.finished
	if _acabando or _dialogic == null:
		return
	var f := create_tween()                        # el diálogo aparece y sigue
	_entrada.append(f)
	f.tween_method(_ver_dialogo, 0.0, 1.0, 0.4)
	_dialogic.paused = false


# Transparencia de la interfaz de los diálogos (sus capas de arriba), para que aparezca con un fundido.
func _ver_dialogo(a: float) -> void:
	if _layout == null or not is_instance_valid(_layout):
		return
	for h in _layout.get_children():
		if h is Control:
			h.modulate.a = a


func _construir(texto_titulo: String) -> void:
	var E = load("res://estilo.gd")
	_velo = ColorRect.new()
	_velo.color = Color(E.SOMBRA, 0.0)
	_velo.size = Vector2(1280, 720)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_velo)
	var g := Gradient.new()                        # viñeta: el centro limpio y los bordes en sombra
	g.set_color(0, Color(E.SOMBRA, 0.0))
	g.set_color(1, Color(E.SOMBRA, 0.75))
	g.set_offset(0, 0.45)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 1.05)
	tex.width = 256
	tex.height = 144
	_vineta = TextureRect.new()
	_vineta.texture = tex
	_vineta.size = Vector2(1280, 720)
	_vineta.stretch_mode = TextureRect.STRETCH_SCALE
	_vineta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vineta.modulate.a = 0.0
	_vineta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vineta)
	for i in 2:
		var f := ColorRect.new()
		f.color = Color(E.SOMBRA, 0.96)
		f.size = Vector2(1280, 0)
		f.position = Vector2(0, 0 if i == 0 else 720)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(f)
		_franjas.append(f)
	if texto_titulo != "":
		var caja := VBoxContainer.new()
		caja.alignment = BoxContainer.ALIGNMENT_CENTER
		caja.position = Vector2(0, 190)
		caja.size = Vector2(1280, 120)
		caja.modulate.a = 0.0
		caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := Label.new()
		l.text = texto_titulo
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", E.cursiva())
		l.add_theme_font_size_override("font_size", 64)
		l.add_theme_color_override("font_color", E.ORO)
		l.add_theme_color_override("font_outline_color", Color(E.SOMBRA, 0.9))
		l.add_theme_constant_override("outline_size", 10)
		caja.add_child(l)
		var linea := ColorRect.new()
		linea.color = Color(E.ORO, 0.8)
		linea.custom_minimum_size = Vector2(240, 2)
		linea.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		caja.add_child(linea)
		add_child(caja)
		_titulo = caja
	_saltar = Button.new()
	_saltar.text = "Saltar  ▸▸"
	_saltar.focus_mode = Control.FOCUS_NONE        # Intro / A son del diálogo
	_saltar.add_theme_font_size_override("font_size", 20)
	_saltar.position = Vector2(1100, 6)
	_saltar.custom_minimum_size = Vector2(160, 36)
	_saltar.set_meta("clave", "saltar")
	_saltar.pressed.connect(saltar)
	add_child(_saltar)


func _unhandled_input(ev: InputEvent) -> void:
	if not _acabando and ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		saltar()


# Termina la escena ya, esté donde esté (también durante la entrada).
func saltar() -> void:
	if _acabando:
		return
	saltada = true
	if _dialogic != null and _dialogic.current_timeline != null:
		_dialogic.end_timeline(true)                # _al_terminar llega por timeline_ended
	else:
		_al_terminar()


func _al_terminar() -> void:
	if _acabando:
		return
	_acabando = true
	for e in _entrada:
		if e != null and e.is_valid():
			e.kill()
	if _dialogic != null and _dialogic.timeline_ended.is_connected(_al_terminar):
		_dialogic.timeline_ended.disconnect(_al_terminar)
	if _dialogic != null:
		_dialogic.paused = false                    # (si se saltó durante la entrada, seguía en pausa)
	if _layout != null and is_instance_valid(_layout):
		_layout.layer = _capa_dialogic
		_ver_dialogo(1.0)                           # la interfaz se reutiliza: se deja opaca para el siguiente
	if _saltar != null:
		_saltar.visible = false
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_velo, "color:a", 0.0, 0.6)
	t.tween_property(_vineta, "modulate:a", 0.0, 0.6)
	t.tween_property(_franjas[0], "size:y", 0.0, 0.6)
	t.tween_property(_franjas[1], "size:y", 0.0, 0.6)
	t.tween_property(_franjas[1], "position:y", 720.0, 0.6)
	if _titulo != null:
		t.tween_property(_titulo, "modulate:a", 0.0, 0.3)
	if camara != null and is_instance_valid(camara):
		t.tween_property(camara, "zoom", _zoom0, 0.8)
	await t.finished
	for n in _ocultos:
		if is_instance_valid(n):
			n.visible = true
	terminada.emit()
	queue_free()
