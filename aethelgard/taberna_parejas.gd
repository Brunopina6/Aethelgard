extends CanvasLayer
# «Las parejas del Cuervo» (V11, hito E: primer minijuego completo; docs/v11/MINIJUEGOS.md). Juego de memoria de la
# Taberna del Cuervo Oxidado: 12 cartas boca abajo (6 parejas con los símbolos del reino), se levantan dos; si son
# iguales se quedan, si no se vuelven. Hay INTENTOS intentos. Sin apuestas: ganar da un premio pequeño la primera vez en
# cada franja del día (ciudades/oakhaven_vida.gd) y se apunta el récord (menos intentos). Lo abre la mesa del Patio del
# Cuervo (ciudad_oakhaven.gd, pieza oak_mesa_parejas). Dedo, ratón y teclado o mando (flechas e Intro); Esc o Atrás
# de Android para salir. Las pruebas fijan el orden con «semilla».

signal cerrado

const SIMBOLOS := ["Fuego", "Agua", "Rayo", "Cura", "Runa", "Luna"]
const COLOR := {"Fuego": Color("FF7A3C"), "Agua": Color("3B8FD8"), "Rayo": Color("F2E36B"), "Cura": Color("7FD36B"),
	"Runa": Color("E8C46A"), "Luna": Color("B9A6FF")}
const INTENTOS := 14
const PREMIO := {"oro": 15, "objetos": {"Poción": 1}}
const ORO := Color("E8C46A")
const SUAVE := Color(0.85, 0.82, 0.74)
const COLUMNAS := 4
const TAM := Vector2(150, 150)

var semilla := -1                                 # pruebas: el orden fijo
var cartas: Array = []                            # [{"simbolo", "boca_arriba", "hecha", "nodo"}]
var levantadas: Array = []                        # índices (como mucho 2)
var intentos := 0
var parejas := 0
var esperando := false                            # dos distintas a la vista: un momento antes de volverlas
var terminado := false
var sel := 0                                      # con teclado o mando
var texto: Label
var mensaje: Label


func _ready() -> void:
	layer = 65
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.03, 0.05, 0.86)
	fondo.size = Vector2(1280, 720)
	add_child(fondo)
	var t := _etiqueta("Las parejas del Cuervo", 32, ORO)
	t.position = Vector2(60, 36)
	t.size = Vector2(700, 44)
	add_child(t)
	texto = _etiqueta("", 22, SUAVE)
	texto.position = Vector2(60, 84)
	texto.size = Vector2(700, 30)
	add_child(texto)
	mensaje = _etiqueta("Levanta dos cartas iguales. Tienes %d intentos." % INTENTOS, 22, SUAVE)
	mensaje.position = Vector2(860, 150)
	mensaje.size = Vector2(380, 300)
	mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(mensaje)
	var salir := Button.new()
	salir.text = "Salir"
	salir.custom_minimum_size = Vector2(200, 60)
	salir.position = Vector2(1000, 40)
	salir.add_theme_font_size_override("font_size", 24)
	salir.pressed.connect(cerrar_menu)
	add_child(salir)
	_repartir()


func _etiqueta(s: String, tam: int, c: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", c)
	return l


func _repartir() -> void:
	var mazo: Array = SIMBOLOS + SIMBOLOS
	var rng := RandomNumberGenerator.new()
	if semilla >= 0:
		rng.seed = semilla
	else:
		rng.randomize()
	for i in range(mazo.size() - 1, 0, -1):          # barajar (Fisher-Yates), con su propio generador
		var j := rng.randi_range(0, i)
		var x = mazo[i]
		mazo[i] = mazo[j]
		mazo[j] = x
	for i in mazo.size():
		var n := Control.new()
		n.position = Vector2(60 + (i % COLUMNAS) * (TAM.x + 16), 140 + (i / COLUMNAS) * (TAM.y + 16))
		n.size = TAM
		n.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i
		n.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
				sel = idx
				levantar(idx))
		n.draw.connect(_dibujar_carta.bind(idx))
		add_child(n)
		cartas.append({"simbolo": mazo[i], "boca_arriba": false, "hecha": false, "nodo": n})
	_pintar()


func _dibujar_carta(i: int) -> void:
	var c: Dictionary = cartas[i]
	var n: Control = c["nodo"]
	var r := Rect2(Vector2.ZERO, n.size)
	var boca: bool = c["boca_arriba"] or c["hecha"]
	n.draw_rect(r, Color(0.16, 0.13, 0.1) if boca else Color(0.12, 0.1, 0.18))
	n.draw_rect(r, ORO if i == sel and not terminado else Color(ORO, 0.35), false, 4.0 if i == sel else 2.0)
	var m := n.size * 0.5
	if not boca:                                        # dorso: el cuervo de la taberna, en un rombo
		n.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -34), m + Vector2(30, 0), m + Vector2(0, 34),
			m + Vector2(-30, 0)]), Color(ORO, 0.25))
		return
	var col: Color = COLOR[c["simbolo"]]
	if c["hecha"]:
		col = col.darkened(0.25)
	dibujar_simbolo(n, c["simbolo"], m, col, Color(0.16, 0.13, 0.1))


# Un símbolo del reino centrado en «m» («fondo»: el color de detrás, para la luna). «escala» 1 es el de las cartas;
# V12 (fase 7): también lo usa la cerradura rúnica (cerradura_runica.gd), más pequeño.
static func dibujar_simbolo(n: CanvasItem, simbolo: String, m: Vector2, col: Color, fondo: Color, escala := 1.0) -> void:
	var e := escala
	match simbolo:
		"Fuego":
			n.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -44) * e, m + Vector2(26, 10) * e,
				m + Vector2(0, 40) * e, m + Vector2(-26, 10) * e]), col)
		"Agua":
			n.draw_circle(m + Vector2(0, 10) * e, 28 * e, col)
			n.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -42) * e, m + Vector2(22, 0) * e,
				m + Vector2(-22, 0) * e]), col)
		"Rayo":
			n.draw_colored_polygon(PackedVector2Array([m + Vector2(8, -44) * e, m + Vector2(-20, 6) * e,
				m + Vector2(-2, 6) * e, m + Vector2(-10, 44) * e, m + Vector2(22, -8) * e, m + Vector2(4, -8) * e]), col)
		"Cura":
			n.draw_rect(Rect2(m + Vector2(-10, -36) * e, Vector2(20, 72) * e), col)
			n.draw_rect(Rect2(m + Vector2(-36, -10) * e, Vector2(72, 20) * e), col)
		"Runa":
			n.draw_arc(m, 34 * e, 0, TAU, 32, col, maxf(5.0 * e, 2.0), true)
			n.draw_line(m + Vector2(0, -26) * e, m + Vector2(0, 26) * e, col, maxf(5.0 * e, 2.0))
			n.draw_line(m + Vector2(-18, -8) * e, m + Vector2(18, 8) * e, col, maxf(5.0 * e, 2.0))
		"Luna":
			n.draw_circle(m, 34 * e, col)
			n.draw_circle(m + Vector2(14, -8) * e, 30 * e, fondo)


func _pintar() -> void:
	texto.text = "Parejas %d de %d · Intentos %d de %d" % [parejas, SIMBOLOS.size(), intentos, INTENTOS]
	for c in cartas:
		(c["nodo"] as Control).queue_redraw()


# Levantar la carta i (dedo, ratón, Intro o las pruebas). Devuelve si se levantó.
func levantar(i: int) -> bool:
	if terminado or esperando or i < 0 or i >= cartas.size():
		return false
	var c: Dictionary = cartas[i]
	if c["hecha"] or c["boca_arriba"]:
		return false
	c["boca_arriba"] = true
	levantadas.append(i)
	Sonido.efecto("ui_tic")
	if levantadas.size() == 2:
		intentos += 1
		var a: Dictionary = cartas[levantadas[0]]
		var b: Dictionary = cartas[levantadas[1]]
		if a["simbolo"] == b["simbolo"]:
			a["hecha"] = true
			b["hecha"] = true
			parejas += 1
			levantadas.clear()
			Sonido.efecto("ui_equipar")
			if parejas == SIMBOLOS.size():
				_acabar(true)
		else:
			esperando = true
			get_tree().create_timer(0.8).timeout.connect(_volver_cartas)
		if not terminado and intentos >= INTENTOS and parejas < SIMBOLOS.size():
			_acabar(false)
	_pintar()
	return true


func _volver_cartas() -> void:
	if not is_inside_tree():
		return
	for i in levantadas:
		cartas[i]["boca_arriba"] = false
	levantadas.clear()
	esperando = false
	_pintar()


func _acabar(gana: bool) -> void:
	terminado = true
	esperando = false
	if not gana:
		mensaje.text = "Se acabaron los intentos. La posadera recoge las cartas: «Otra ronda cuando quieras»."
		return
	var t: String = load("res://ciudades/taberna_juegos.gd").ganar("parejas", intentos, PREMIO)
	mensaje.text = t


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar_menu()
		return
	var paso := 0
	if ev.is_action_pressed("ui_right"):
		paso = 1
	elif ev.is_action_pressed("ui_left"):
		paso = -1
	elif ev.is_action_pressed("ui_down"):
		paso = COLUMNAS
	elif ev.is_action_pressed("ui_up"):
		paso = -COLUMNAS
	if paso != 0:
		sel = posmod(sel + paso, cartas.size())
		get_viewport().set_input_as_handled()
		_pintar()
	elif ev.is_action_pressed("ui_accept"):
		levantar(sel)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree() and not is_queued_for_deletion():
		cerrar_menu()


func cerrar_menu() -> void:
	if is_queued_for_deletion():
		return
	cerrado.emit()
	queue_free()
