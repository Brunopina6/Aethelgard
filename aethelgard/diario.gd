extends Control
# Diario (Godot 4.x): lo que el jugador ha descubierto mirando el escenario y un repaso del combate.
#   Detalles: los detalles de lore de cada acto (progreso.gd). Los que faltan salen como «???».
#     Con todos los de un acto se desbloquea su página extra.
#   Combate: una ficha corta de cada mecánica, para quien la olvide.
# Se crea por código desde el mapa:  var d = load("res://diario.gd").new(); ui.add_child(d)
# Al cerrarse emite "cerrado" y se borra solo.
# Con teclado o mando (entrada.gd): el foco empieza en la pestaña activa; ↑ ↓ desplazan el texto, Q / E (L1 / R1)
# cambian de pestaña y Esc / B cierran.

signal cerrado

const Estilo := preload("res://estilo.gd")
const FICHAS := [
	["Barra ATB", "Cuando la barra de un héroe se llena, entra su menú."],
	["Atacar y Defender", "Desliza ATACAR para girarlo a DEFENDER: recibes la mitad de daño."],
	["Magia", "El nivel I va a un enemigo; el II y el III, a todos. El Fuego quema."],
	["Invocación", "Cada acción carga la Armonía. Llena, invoca a Ladrón de Corazones."],
	["Congelado", "Los golpes con Frostfang congelan: el enemigo pierde Vitalidad dos rondas."],
	["Huir", "En los combates normales siempre funciona. Ante un jefe, no."],
	["Objetos", "Poción: PV. Éter: PM. Incienso de Ceniza: un rato sin encuentros."],
]

const PESTANAS := ["Detalles", "Combate"]

var pestana := "Detalles"
var cuerpo: VBoxContainer
var marco: ScrollContainer
var botones: Array = []


func _ready() -> void:
	add_to_group("menu_quieto")                  # Recursos activa el modo ahorro mientras está abierto
	size = Vector2(1280, 720)
	var oscuro := ColorRect.new()
	oscuro.color = Color(Estilo.SOMBRA, 0.55)
	oscuro.size = size
	add_child(oscuro)
	var panel := PanelContainer.new()
	panel.position = Vector2(90, 40)
	panel.custom_minimum_size = Vector2(1100, 600)
	panel.add_theme_stylebox_override("panel", Estilo.ventana(0.88))
	add_child(panel)
	var todo := VBoxContainer.new()
	todo.add_theme_constant_override("separation", 12)
	panel.add_child(todo)
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 10)
	todo.add_child(arriba)
	arriba.add_child(_texto("Diario", 38, Estilo.ORO, true))
	for p in PESTANAS:
		var b := Button.new()
		b.text = p
		b.custom_minimum_size = Vector2(170, 44)
		b.set_meta("p", p)
		b.set_meta("clave", "pestana:" + p)
		b.pressed.connect(_ir_a_pestana.bind(p))
		arriba.add_child(b)
		botones.append(b)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(hueco)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(150, 44)
	cerrar.set_meta("clave", "cerrar")
	cerrar.pressed.connect(_cerrar)
	arriba.add_child(cerrar)
	marco = ScrollContainer.new()
	marco.custom_minimum_size = Vector2(1080, 520)
	todo.add_child(marco)
	cuerpo = VBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 6)
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.add_child(cuerpo)
	_pintar()
	Entrada.enfocar(botones[PESTANAS.find(pestana)])


func _ir_a_pestana(p: String) -> void:
	if p != pestana:
		Sonido.efecto("libro_hoja")                  # se pasa la hoja (sonido.gd, T-083; abrir el Diario ya suena)
	pestana = p
	marco.scroll_vertical = 0
	_pintar()


func _cerrar() -> void:
	if is_queued_for_deletion():
		return
	Sonido.efecto("libro_cerrar")                    # el libro se cierra (sonido.gd, T-083)
	cerrado.emit()
	queue_free()


# Teclado y mando: el diario es texto, así que ↑ ↓ lo desplazan; Q / E (L1 / R1) cambian de pestaña; Esc / B cierran.
func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		_cerrar()
	elif ev.is_action_pressed("pestana_anterior") or ev.is_action_pressed("pestana_siguiente"):
		var paso := -1 if ev.is_action_pressed("pestana_anterior") else 1
		var p: String = PESTANAS[posmod(PESTANAS.find(pestana) + paso, PESTANAS.size())]
		_ir_a_pestana(p)
		botones[PESTANAS.find(p)].grab_focus(not Entrada.con_foco())
	elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("ui_up"):
		marco.scroll_vertical += 80 if ev.is_action_pressed("ui_down") else -80
	else:
		return
	get_viewport().set_input_as_handled()


func _pintar() -> void:
	for c in cuerpo.get_children():
		cuerpo.remove_child(c)
		c.queue_free()
	for b in botones:
		b.add_theme_color_override("font_color", Estilo.ORO if b.get_meta("p") == pestana else Estilo.LUZ_CLARA)
	if pestana == "Combate":
		for f in FICHAS:
			cuerpo.add_child(_texto(f[0], 30, Estilo.ORO, true))
			cuerpo.add_child(_texto(f[1], 20, Estilo.LUZ_CLARA))
		return
	var Progreso = load("res://progreso.gd")
	var lugares: Array = load("res://mapa.gd").LUGARES
	for a in Progreso.ACTOS:
		cuerpo.add_child(_texto(a["nombre"], 32, Estilo.ORO, true))
		var vistos := 0
		var total := 0
		for l in a["lugares"]:
			for d in Progreso.detalles_de(l):
				total += 1
				if Progreso.visto(d["id"]):
					vistos += 1
					cuerpo.add_child(_texto("%s · %s" % [d["nombre"], lugares[l]["nombre"]], 22, Estilo.LUZ_CLARA))
					cuerpo.add_child(_texto("      " + d["texto"], 20, Estilo.GRIS, true))
				else:
					cuerpo.add_child(_texto("???  · %s" % lugares[l]["nombre"], 22, Estilo.GRIS_APAGADO))
		if vistos == total:
			cuerpo.add_child(_texto("Página: %s" % a["escena"], 26, Estilo.CURA, true))
			var t := _texto(a["texto"], 21, Estilo.LUZ_CLARA, true)
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			t.custom_minimum_size = Vector2(1040, 0)
			cuerpo.add_child(t)
		else:
			cuerpo.add_child(_texto("Página por descubrir (%d de %d detalles)" % [vistos, total], 18, Estilo.GRIS))
		cuerpo.add_child(Control.new())


func _texto(t: String, tam: int, color: Color, cursiva := false) -> Label:
	var l := Label.new()
	l.text = t
	if cursiva:
		l.add_theme_font_override("font", Estilo.cursiva())
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l
