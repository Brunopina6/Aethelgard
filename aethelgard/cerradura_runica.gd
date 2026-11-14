extends CanvasLayer
# Cerradura rúnica (V12, fase 7: el primer minijuego de cerraduras del encargo del coordinador, §11; docs/v12/
# OAKHAVEN_JUGABLE_V12.md). Reutilizable: quien la abre le da su configuración (config) y lo que pasa al resolverla
# (al_resolver, que devuelve el texto del premio); la primera, el arcón del Concejo de Oakhaven (ciudades/oakhaven.gd
# CERRADURA, PROPUESTA).
#
# EL PUZLE: anillos concéntricos con los seis símbolos del reino (los de las parejas: taberna_parejas.gd). Arriba hay una
# marca; la cerradura se abre cuando, de fuera adentro, quedan en la marca los símbolos de config.objetivo, que se deducen
# de la inscripción de la tapa. Los anillos están ENGRANADOS: al girar uno, el de dentro gira con él un paso (el de
# dentro del todo gira solo), así que importa el orden. Siempre tiene solución (girar el de fuera, luego el del medio y
# por último el de dentro) y no hay intentos, ni tiempo, ni castigo.
#
# CONTROLES: dedo o ratón (tocar un anillo lo gira hacia el lado que se toca, o los botones ◀ ▶ de cada anillo); teclado
# o mando (↑ ↓ eligen anillo, ← → lo giran, Intro lo gira en el sentido del reloj); Esc, B, Atrás de Android o «Salir»
# la dejan sin perder nada (la próxima vez empieza igual). Resuelta, la recompensa se da UNA vez (al_resolver) y la
# cerradura ya no se vuelve a abrir (quien la usa lo comprueba con su propio estado guardado).

signal cerrado
signal resuelta

const Parejas := preload("res://taberna_parejas.gd")
const ORO := Color("E8C46A")
const SUAVE := Color(0.85, 0.82, 0.74)
const FONDO_RUNA := Color(0.13, 0.11, 0.09)
const CENTRO := Vector2(290, 300)                # dentro de la rueda (de 580 × 600)
const RADIOS := [[250.0, 182.0], [176.0, 110.0], [104.0, 44.0]]   # bandas [exterior, interior] de cada anillo
const ESCALA := [0.5, 0.42, 0.34]               # tamaño de los símbolos de cada anillo
const SUAVIZADO := 14.0                         # el giro se ve llegar (no limita nada: se puede seguir girando)

var config: Dictionary = {}                     # id, titulo, inscripcion, anillos [[símbolos]], nombres, objetivo, inicio
var al_resolver: Callable                       # -> String (el premio); la pone quien la abre
var giros: Array = []                           # pasos girados de cada anillo (positivo: sentido del reloj)
var angulos: Array = []                         # lo que se ve (se acerca a giros)
var sel := 0                                    # anillo elegido (teclado o mando)
var movimientos := 0
var terminado := false
var aviso_engranaje := false
var rueda: Control
var mensaje: Label
var botones: Array = []                         # [[◀, ▶] por anillo] (las pruebas los pulsan)
var salir: Button


# --------------------------------------------------------------------------- el puzle (sin nodos: lo usan las pruebas)

static func simbolo_arriba(cfg: Dictionary, giros_: Array, i: int) -> String:
	var a: Array = cfg["anillos"][i]
	return a[posmod(-int(giros_[i]), a.size())]


# Gira el anillo i «paso» pasos (+1 sentido del reloj, −1 al contrario); el de dentro le acompaña. Devuelve los giros.
static func girar_en(cfg: Dictionary, giros_: Array, i: int, paso: int) -> Array:
	var g := giros_.duplicate()
	g[i] = int(g[i]) + paso
	if i + 1 < g.size():
		g[i + 1] = int(g[i + 1]) + paso
	return g


static func resuelta_en(cfg: Dictionary, giros_: Array) -> bool:
	for i in giros_.size():
		if simbolo_arriba(cfg, giros_, i) != cfg["objetivo"][i]:
			return false
	return true


# Una solución (para las pruebas): de fuera adentro, el giro más corto que pone cada símbolo en la marca.
static func solucion(cfg: Dictionary, giros_: Array) -> Array:
	var g := giros_.duplicate()
	var pasos: Array = []
	for i in g.size():
		var a: Array = cfg["anillos"][i]
		var n := a.size()
		var falta := posmod(-a.find(cfg["objetivo"][i]) - int(g[i]), n)   # pasos de reloj que faltan
		var paso := 1 if falta <= n / 2 else -1
		for k in (falta if paso == 1 else n - falta):
			g = girar_en(cfg, g, i, paso)
			pasos.append([i, paso])
	return pasos


# --------------------------------------------------------------------------- la ventana

func _ready() -> void:
	layer = 65
	var anillos: Array = config.get("anillos", [])
	giros = (config.get("inicio", []) as Array).duplicate()
	giros.resize(anillos.size())
	for i in giros.size():
		giros[i] = int(giros[i]) if giros[i] != null else 0
	angulos = giros.map(func(g): return float(g))
	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.03, 0.05, 0.88)
	fondo.size = Vector2(1280, 720)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)
	var t := _etiqueta(str(config.get("titulo", "Cerradura rúnica")), 32, ORO)
	t.position = Vector2(60, 26)
	t.size = Vector2(620, 44)
	add_child(t)
	rueda = Control.new()
	rueda.position = Vector2(40, 90)
	rueda.size = Vector2(580, 600)
	rueda.mouse_filter = Control.MOUSE_FILTER_STOP
	rueda.draw.connect(_dibujar_rueda)
	rueda.gui_input.connect(_tocar_rueda)
	add_child(rueda)
	var grabado := _etiqueta("Grabado en la tapa:\n«%s»" % str(config.get("inscripcion", "")), 24, SUAVE)
	grabado.position = Vector2(680, 100)
	grabado.size = Vector2(540, 120)
	grabado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(grabado)
	var nombres: Array = config.get("nombres", [])
	for i in anillos.size():
		var y := 250.0 + i * 96.0
		var l := _etiqueta("Anillo %s" % (nombres[i] if i < nombres.size() else str(i + 1)), 24, SUAVE)
		l.position = Vector2(680, y + 16)
		l.size = Vector2(250, 40)
		add_child(l)
		var fila: Array = []
		for k in 2:
			var b := Button.new()
			b.text = "◀" if k == 0 else "▶"
			b.custom_minimum_size = Vector2(110, 80)
			b.size = Vector2(110, 80)
			b.position = Vector2(950 + k * 130, y)
			b.add_theme_font_size_override("font_size", 34)
			b.focus_mode = Control.FOCUS_NONE           # el foco de teclado es el anillo elegido, no el botón
			b.pressed.connect(girar.bind(i, -1 if k == 0 else 1))
			add_child(b)
			fila.append(b)
		botones.append(fila)
	mensaje = _etiqueta("Toca un anillo para girarlo hacia ese lado, o usa ◀ ▶.", 22, SUAVE)
	mensaje.position = Vector2(680, 548)
	mensaje.size = Vector2(540, 130)
	mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(mensaje)
	salir = Button.new()
	salir.text = "Salir"
	salir.custom_minimum_size = Vector2(200, 60)
	salir.position = Vector2(1020, 26)
	salir.add_theme_font_size_override("font_size", 24)
	salir.pressed.connect(cerrar_menu)
	add_child(salir)


func _etiqueta(s: String, tam: int, c: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", c)
	return l


func _process(delta: float) -> void:
	var cambia := false
	for i in angulos.size():
		var a: float = angulos[i]
		var objetivo := float(giros[i])
		if absf(a - objetivo) > 0.001:
			angulos[i] = lerpf(a, objetivo, clampf(delta * SUAVIZADO, 0.0, 1.0))
			cambia = true
	if cambia:
		rueda.queue_redraw()


func simbolo(i: int) -> String:
	return simbolo_arriba(config, giros, i)


# Gira el anillo i (dedo, ratón, teclado, mando o las pruebas). Devuelve si giró.
func girar(i: int, paso: int) -> bool:
	if terminado or i < 0 or i >= giros.size() or paso == 0:
		return false
	sel = i
	giros = girar_en(config, giros, i, signi(paso))
	movimientos += 1
	Sonido.efecto("ui_tic")
	if i + 1 < giros.size() and not aviso_engranaje:
		aviso_engranaje = true
		mensaje.text = "El anillo de dentro también se ha movido: los anillos están engranados."
	rueda.queue_redraw()
	if resuelta_en(config, giros):
		_abrir()
	return true


func _abrir() -> void:
	terminado = true
	var premio := ""
	if al_resolver.is_valid():
		premio = str(al_resolver.call())
	Sonido.efecto("tesoro")
	mensaje.text = "¡Clac! Los anillos encajan y la tapa se abre." + ("" if premio == "" else " " + premio)
	salir.text = "Cerrar"
	for fila in botones:
		for b in fila:
			(b as Button).disabled = true
	resuelta.emit()
	rueda.queue_redraw()


func _tocar_rueda(ev: InputEvent) -> void:
	var p := Vector2.ZERO
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		p = ev.position
	elif ev is InputEventScreenTouch and ev.pressed:
		p = ev.position
	else:
		return
	var d := p.distance_to(CENTRO)
	for i in RADIOS.size():
		if i < giros.size() and d <= RADIOS[i][0] + 6.0 and d >= RADIOS[i][1] - 6.0:
			girar(i, 1 if p.x >= CENTRO.x else -1)      # a la derecha, con el reloj; a la izquierda, al revés
			rueda.accept_event()
			return


func _dibujar_rueda() -> void:
	var c := CENTRO
	rueda.draw_circle(c, RADIOS[0][0] + 14.0, Color(0.09, 0.075, 0.06))
	for i in giros.size():
		var r_ext: float = RADIOS[i][0]
		var r_int: float = RADIOS[i][1]
		var medio := (r_ext + r_int) * 0.5
		var ancho := r_ext - r_int
		var elegido := i == sel and not terminado
		# (sin pistas: un anillo bien puesto no se marca hasta que se abre la cerradura)
		rueda.draw_arc(c, medio, 0.0, TAU, 72, Color(0.3, 0.25, 0.12) if terminado else Color(0.2, 0.16, 0.12), ancho, true)
		rueda.draw_arc(c, r_ext, 0.0, TAU, 72, Color(ORO, 0.9 if elegido else 0.3), 4.0 if elegido else 2.0, true)
		var a: Array = config["anillos"][i]
		var n := a.size()
		for k in n:
			var ang := -PI / 2.0 + (k + float(angulos[i])) * TAU / n
			var pos := c + Vector2(cos(ang), sin(ang)) * medio
			var col: Color = Parejas.COLOR.get(a[k], SUAVE)
			Parejas.dibujar_simbolo(rueda, a[k], pos, col, Color(0.2, 0.16, 0.12), ESCALA[i] if i < ESCALA.size() else 0.3)
	rueda.draw_circle(c, RADIOS[giros.size() - 1][1] - 4.0, Color(0.16, 0.13, 0.1))
	rueda.draw_arc(c, RADIOS[giros.size() - 1][1] - 4.0, 0.0, TAU, 48, Color(ORO, 0.5), 2.0, true)
	# la marca, arriba
	var top := c + Vector2(0, -RADIOS[0][0] - 4.0)
	rueda.draw_colored_polygon(PackedVector2Array([top + Vector2(-16, -22), top + Vector2(16, -22), top + Vector2(0, 4)]),
		ORO if not terminado else Color(0.6, 1.0, 0.55))
	rueda.draw_line(c + Vector2(0, -RADIOS[0][0]), c + Vector2(0, -RADIOS[giros.size() - 1][1]), Color(ORO, 0.35), 2.0)


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar_menu()
		return
	if terminado:
		if ev.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			cerrar_menu()
		return
	if ev.is_action_pressed("ui_down") or ev.is_action_pressed("ui_up"):
		sel = posmod(sel + (1 if ev.is_action_pressed("ui_down") else -1), giros.size())
		rueda.queue_redraw()
	elif ev.is_action_pressed("ui_right") or ev.is_action_pressed("ui_accept"):
		girar(sel, 1)
	elif ev.is_action_pressed("ui_left"):
		girar(sel, -1)
	else:
		return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree() and not is_queued_for_deletion():
		cerrar_menu()


func cerrar_menu() -> void:
	if is_queued_for_deletion():
		return
	cerrado.emit()
	queue_free()
