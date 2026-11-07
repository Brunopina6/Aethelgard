extends Node2D
# Mapa mundi de Aethelgard con exploración libre y encuentros aleatorios (Godot 4.x)
# Toca o haz clic para caminar (o arrastra). En PC también valen las flechas.
# Tecla E = provocar un encuentro (solo para pruebas).

const MAPA_TAM := Vector2(2400, 1350)
const VELOCIDAD := 220.0        # píxeles por segundo
const LONG_PASO := 20.0         # cada cuántos píxeles cuenta un "paso"
const PASOS_MIN := 40           # pasos seguros después de cada combate
const PROB_ENCUENTRO := 0.01    # probabilidad por paso una vez pasado el mínimo
const RADIO_LUGAR := 70.0       # distancia a la que aparece el botón "Entrar"
const INDICE_GARGANTA := 2      # en LUGARES

const ZONAS := {
	"bosque": Color8(40, 160, 60),
	"llanura": Color8(150, 190, 90),
	"montana": Color8(130, 120, 110),
	"nieve": Color8(235, 240, 250),
	"desierto": Color8(230, 190, 90),
	"yermo": Color8(150, 100, 170),
	"ceniza": Color8(90, 80, 100),
}

const NOMBRES_ZONA := {
	"bosque": "Bosque", "llanura": "Llanura", "montana": "Montaña", "nieve": "Nieve",
	"desierto": "Desierto", "yermo": "Yermo", "ceniza": "Ceniza",
}

# Terreno generado cuando no existen mapa_mundo.jpg / mapa_zonas.png.
const RES_TERRENO := 4                # píxeles del mundo por píxel generado
const ANCHO_CAMINO := 170.0           # ancho de tierra alrededor de cada ruta
const RUTAS := [[0, 1], [1, 2], [2, 3], [2, 6], [3, 4], [4, 5]]   # índices de LUGARES unidos por tierra
const ISLAS := [7, 8]                 # lugares en islas (solo con el Astraea)
const ZONA_LUGAR := ["llanura", "bosque", "montana", "nieve", "desierto", "llanura", "yermo", "llanura", "ceniza", "llanura"]

const LUGARES := [
	{"nombre": "Oakhaven", "pos": Vector2(520, 330), "tipo": "ciudad",
		"texto": "Ciudadela de Oakhaven: el crematorio, la Taberna del Cuervo Oxidado y el Árbol Milenario."},
	{"nombre": "Gran Bosque Verde", "pos": Vector2(720, 540), "tipo": "lugar",
		"texto": "Santuario profanado donde Lya protege el Núcleo de la Naturaleza."},
	{"nombre": "Garganta del Diablo", "pos": Vector2(1030, 640), "tipo": "lugar",
		"texto": "Desfiladero con puentes colgantes. Aquí espera Gorthor el Devorador."},
	{"nombre": "Cumbres de Ciclópea", "pos": Vector2(1250, 240), "tipo": "lugar",
		"texto": "Montañas heladas. Hogar de Glacius Niflheim."},
	{"nombre": "Mar de Arena de Calid", "pos": Vector2(1700, 390), "tipo": "lugar",
		"texto": "Desierto con ruinas sepultadas. Aquí se esconde el Lente del Sol."},
	{"nombre": "Sunken City", "pos": Vector2(1930, 570), "tipo": "ciudad",
		"texto": "Ciudad construida dentro del esqueleto de un barco de guerra antiguo."},
	{"nombre": "Valle de los Ecos", "pos": Vector2(1000, 1020), "tipo": "lugar",
		"texto": "Espejos de agua bajo un cielo estrellado. Kael se enfrenta a sí mismo."},
	{"nombre": "Templo Sumergido de Atlantis", "pos": Vector2(1560, 980), "tipo": "lugar",
		"texto": "Solo se llega con el barco volador Astraea."},
	{"nombre": "Abismo de Ceniza", "pos": Vector2(380, 1050), "tipo": "lugar",
		"texto": "La fortaleza final de Morgath. Solo se llega con el Astraea."},
	# 9: el portal sube a la ciudad flotante (isla.gd); el portal de la isla te devuelve aquí
	{"nombre": "Portal del Vacío", "pos": Vector2(650, 405), "tipo": "portal",
		"texto": "Un arco de oro con un remolino morado. Al otro lado se oye el viento."},
]
const ESCENA_PORTAL := "res://isla.tscn"
# Pastos Verdes: solo existe con la exploración 3D activa (modo3d.gd, rama experimental). Está en la ruta de
# Oakhaven al Gran Bosque, en tierra y lejos del radio de Oakhaven y del portal. Su índice es el 10.
const LUGAR_PASTOS := {"nombre": "Pastos Verdes", "pos": Vector2(660, 478), "tipo": "lugar", "zona": "llanura",
	"texto": "Colinas verdes, un puente de piedra y una cascada. Tilo enciende los faroles a pleno día."}

const REGIONES := [
	{"nombre": "OCÉANO DE BRUMA", "pos": Vector2(1330, 800), "rot": -3.0},
	{"nombre": "EL ABISMO QUEBRADO", "pos": Vector2(300, 1210), "rot": -2.0},
]

var zonas_img: Image
var terreno_tex: Texture2D
var jugador: Node2D
var sprite                # muñeco animado de Kael (muneco.gd)
var camara: Camera2D
var ui: CanvasLayer
var boton_entrar: Button
var aviso: Label
var etiqueta_zona: Label
var tween_aviso: Tween

var destino := Vector2.ZERO
var tiene_destino := false
var acum := 0.0
var pasos := 0
var cerca = null
var en_encuentro := false
var tiempo := 0.0
var zona_actual := ""
var menu_abierto: Control = null
var portal_tex: Texture2D
var lugares: Array = LUGARES      # LUGARES y, con la exploración 3D activa, Pastos Verdes (índice 10)


func _ready() -> void:
	randomize()
	if ResourceLoader.exists("res://mapa_zonas.png"):
		var tex := load("res://mapa_zonas.png") as Texture2D
		if tex:
			zonas_img = tex.get_image()
	if zonas_img == null:
		_generar_terreno()
	if load("res://modo3d.gd").activo():
		lugares = LUGARES + [LUGAR_PASTOS]
	_crear_mapa()
	_crear_jugador()
	_crear_ui()
	zona_actual = _zona_en(jugador.position)
	etiqueta_zona.text = "Zona: %s" % NOMBRES_ZONA.get(zona_actual, zona_actual)
	# escena de historia: el prólogo sale la primera vez que se abre el mapa (Dialogic)
	if not Engine.get_meta("prologo_visto", false) and has_node("/root/Dialogic") and not "sin_prologo" in OS.get_cmdline_user_args():
		Engine.set_meta("prologo_visto", true)
		get_node("/root/Dialogic").start.call_deferred("prologo")
	for a in OS.get_cmdline_user_args():          # pruebas: godot ... -- menu=Grupo
		if a.begins_with("menu="):
			_abrir_menu(a.substr(5))
	guardar_posicion()
	load("res://progreso.gd").guardar("res://mapa.tscn")   # guardado automático (progreso.gd)


# Recursos la llama al cerrar la app, para volver justo aquí.
func guardar_posicion() -> void:
	Engine.set_meta("pos_mapa", jugador.position)
	Engine.set_meta("pos_mapa_ok", true)


# ---------------------------------------------------------------- terreno generado

# Crea un continente que une los lugares de RUTAS, islas para ISLAS y océano alrededor.
# Rellena zonas_img (máscara + colores de zona, como mapa_zonas.png) y terreno_tex (el dibujo).
func _generar_terreno() -> void:
	var ruido := FastNoiseLite.new()
	ruido.seed = 7
	ruido.frequency = 0.004
	ruido.fractal_octaves = 4
	var ruido_zona := FastNoiseLite.new()
	ruido_zona.seed = 21
	ruido_zona.frequency = 0.006
	var w := int(MAPA_TAM.x) / RES_TERRENO
	var h := int(MAPA_TAM.y) / RES_TERRENO
	var mascara := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var dibujo := Image.create(w, h, false, Image.FORMAT_RGB8)
	var mar := Color8(28, 58, 110)
	var mar_hondo := Color8(14, 30, 70)
	var arena := Color8(214, 196, 140)
	for y in h:
		for x in w:
			var p := Vector2(x, y) * RES_TERRENO
			var n := ruido.get_noise_2d(p.x, p.y)
			# distancia a la ruta o isla más cercana
			var d := 1e9
			for r in RUTAS:
				d = min(d, _dist_segmento(p, LUGARES[r[0]]["pos"], LUGARES[r[1]]["pos"]))
			var d_isla := 1e9
			for i in ISLAS:
				d_isla = min(d_isla, p.distance_to(LUGARES[i]["pos"]) * 1.4)
			var v: float = 1.0 - min(d, d_isla) / ANCHO_CAMINO + n * 0.9
			if v < 0.0:
				var hondo: float = clamp(-v * 0.8, 0.0, 1.0)
				dibujo.set_pixel(x, y, mar.lerp(mar_hondo, hondo).lightened(ruido_zona.get_noise_2d(p.x, p.y) * 0.08))
				continue
			# zona: la del lugar más cercano, con bordes irregulares
			var pz := p + Vector2(ruido_zona.get_noise_2d(p.x, p.y), ruido_zona.get_noise_2d(p.x + 911.0, p.y)) * 260.0
			var mejor := 0
			var dmin := 1e9
			for i in LUGARES.size():
				var dd: float = pz.distance_to(LUGARES[i]["pos"])
				if dd < dmin:
					dmin = dd
					mejor = i
			var zc: Color = ZONAS[ZONA_LUGAR[mejor]]
			mascara.set_pixel(x, y, Color(zc.r, zc.g, zc.b, 1.0))
			var c := zc.darkened(0.15).lightened(n * 0.25)
			if v < 0.08:
				c = arena                                   # costa
			dibujo.set_pixel(x, y, c)
	mascara.resize(int(MAPA_TAM.x / 2), int(MAPA_TAM.y / 2), Image.INTERPOLATE_NEAREST)
	zonas_img = mascara
	terreno_tex = ImageTexture.create_from_image(dibujo)


func _dist_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


# ---------------------------------------------------------------- construcción

func _crear_mapa() -> void:
	if ResourceLoader.exists("res://mapa_mundo.jpg"):
		var fondo := Sprite2D.new()
		fondo.texture = load("res://mapa_mundo.jpg")
		fondo.centered = false
		add_child(fondo)
	elif terreno_tex != null:
		var fondo := Sprite2D.new()
		fondo.texture = terreno_tex
		fondo.centered = false
		fondo.scale = Vector2(RES_TERRENO, RES_TERRENO)
		fondo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(fondo)
	else:
		var plano := ColorRect.new()
		plano.color = Color(0.1, 0.12, 0.25)
		plano.size = MAPA_TAM
		add_child(plano)

	var marcas := Node2D.new()
	add_child(marcas)
	marcas.draw.connect(func(): _dibujar_marcas(marcas))

	for l in lugares:
		var et := Label.new()
		et.text = l["nombre"]
		et.size = Vector2(260, 26)
		et.position = l["pos"] + Vector2(-130, 20)
		et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		et.add_theme_font_size_override("font_size", 20)
		et.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
		et.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
		et.add_theme_constant_override("outline_size", 7)
		marcas.add_child(et)

	for r in REGIONES:
		var rl := Label.new()
		rl.text = r["nombre"]
		rl.size = Vector2(600, 44)
		rl.position = r["pos"] - rl.size * 0.5
		rl.pivot_offset = rl.size * 0.5
		rl.rotation_degrees = r["rot"]
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.add_theme_font_size_override("font_size", 34)
		rl.add_theme_color_override("font_color", Color(0.88, 0.82, 1.0, 0.6))
		rl.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.12, 0.7))
		rl.add_theme_constant_override("outline_size", 6)
		marcas.add_child(rl)


func _dibujar_marcas(n: Node2D) -> void:
	for l in lugares:
		var p: Vector2 = l["pos"]
		if l["tipo"] == "portal":                     # la foto del portal de Meshy, en pequeño
			if portal_tex == null and ResourceLoader.exists("res://objetos/portal.png"):
				portal_tex = load("res://objetos/portal.png")
			if portal_tex != null:
				var tam := Vector2(64, 73)
				n.draw_texture_rect(portal_tex, Rect2(p - Vector2(tam.x * 0.5, tam.y - 10), tam), false)
			continue
		if l["tipo"] == "ciudad":
			n.draw_circle(p + Vector2(2, 4), 17, Color(0, 0, 0, 0.45))
			n.draw_circle(p, 16, Color8(250, 226, 140))
			n.draw_circle(p, 11, Color8(110, 56, 40))
			n.draw_rect(Rect2(p + Vector2(-5, -9), Vector2(10, 14)), Color8(250, 226, 140))
		else:
			n.draw_circle(p + Vector2(2, 4), 13, Color(0, 0, 0, 0.45))
			var rombo := PackedVector2Array([p + Vector2(0, -15), p + Vector2(13, 0), p + Vector2(0, 15), p + Vector2(-13, 0)])
			n.draw_colored_polygon(rombo, Color8(235, 120, 60))
			rombo.append(rombo[0])
			n.draw_polyline(rombo, Color8(255, 230, 170), 2.0)


func _crear_jugador() -> void:
	jugador = Node2D.new()
	jugador.position = LUGARES[0]["pos"] + Vector2(0, 55)
	if Engine.get_meta("pos_mapa_ok", false):
		jugador.position = Engine.get_meta("pos_mapa")
	add_child(jugador)

	jugador.draw.connect(_dibujar_sombra)

	sprite = load("res://muneco.gd").new()       # corre en 4 direcciones y respira quieto
	jugador.add_child(sprite)

	camara = Camera2D.new()
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = int(MAPA_TAM.x)
	camara.limit_bottom = int(MAPA_TAM.y)
	camara.position_smoothing_enabled = true
	camara.position_smoothing_speed = 7.0
	jugador.add_child(camara)
	camara.make_current()
	camara.reset_smoothing()


func _dibujar_sombra() -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a) * 20.0, sin(a) * 7.0))
	jugador.draw_colored_polygon(pts, Color(0, 0, 0, 0.35))


# Estilo común (estilo.gd): oscuro transparente con línea dorada fina, como el menú de combate.
func _estilo_ventana() -> StyleBoxFlat:
	var e: StyleBoxFlat = load("res://estilo.gd").ventana(0.72)
	e.set_content_margin_all(6)
	return e


func _crear_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	# barra inferior
	var barra := PanelContainer.new()
	barra.position = Vector2(170, 640)
	barra.custom_minimum_size = Vector2(940, 68)
	barra.add_theme_stylebox_override("panel", _estilo_ventana())
	ui.add_child(barra)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	barra.add_child(fila)
	for n in ["Mapa", "Grupo", "Objetos", "Diario", "Viaje rápido", "Habilidades"]:
		var b := Button.new()
		b.text = n.to_upper()
		b.flat = true
		b.custom_minimum_size = Vector2(140, 52)
		b.add_theme_font_override("font", load("res://menu_combate.gd").fuente("res://fuentes/SairaCondensed-Medium.ttf", 3, 0))
		b.add_theme_font_size_override("font_size", 20)
		if n == "Mapa":
			b.add_theme_color_override("font_color", load("res://estilo.gd").ORO)
		b.pressed.connect(_boton_menu.bind(n))
		fila.add_child(b)

	# registro de misiones
	var mis := Button.new()
	mis.text = "Misiones"
	mis.position = Vector2(8, 280)
	mis.custom_minimum_size = Vector2(120, 48)
	mis.add_theme_font_size_override("font_size", 20)
	mis.pressed.connect(_boton_menu.bind("Misiones"))
	ui.add_child(mis)

	# brújula
	var br := Control.new()
	br.position = Vector2(1160, 14)
	br.size = Vector2(104, 104)
	br.mouse_filter = Control.MOUSE_FILTER_IGNORE
	br.draw.connect(func(): _dibujar_brujula(br))
	ui.add_child(br)

	# zona actual
	etiqueta_zona = Label.new()
	etiqueta_zona.position = Vector2(16, 14)
	etiqueta_zona.add_theme_font_override("font", load("res://estilo.gd").cursiva())
	etiqueta_zona.add_theme_font_size_override("font_size", 28)
	etiqueta_zona.add_theme_constant_override("outline_size", 6)
	ui.add_child(etiqueta_zona)

	# botón para entrar a un lugar
	boton_entrar = Button.new()
	boton_entrar.position = Vector2(470, 574)
	boton_entrar.custom_minimum_size = Vector2(340, 52)
	boton_entrar.add_theme_font_size_override("font_size", 22)
	boton_entrar.visible = false
	boton_entrar.pressed.connect(_entrar)
	ui.add_child(boton_entrar)

	# mensajes
	aviso = Label.new()
	aviso.position = Vector2(190, 100)
	aviso.size = Vector2(900, 60)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_font_override("font", load("res://estilo.gd").cursiva())
	aviso.add_theme_font_size_override("font_size", 32)
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.modulate.a = 0.0
	ui.add_child(aviso)

	# cruceta para mover al personaje con el dedo (en el móvil, o probando con -- dpad)
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or "dpad" in OS.get_cmdline_user_args():
		var dpad = load("res://dpad.gd").new()
		dpad.position = Vector2(30, 440)
		ui.add_child(dpad)


func _dibujar_brujula(c: Control) -> void:
	var centro := Vector2(52, 52)
	c.draw_circle(centro, 50, Color(0.05, 0.08, 0.2, 0.8))
	c.draw_arc(centro, 50, 0, TAU, 48, Color8(205, 215, 255), 2.0)
	var fuente := ThemeDB.fallback_font
	c.draw_string(fuente, Vector2(46, 20), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	c.draw_string(fuente, Vector2(46, 96), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	c.draw_string(fuente, Vector2(86, 58), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	c.draw_string(fuente, Vector2(8, 58), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(52, 24), Vector2(60, 52), Vector2(44, 52)]), Color8(220, 60, 60))
	c.draw_colored_polygon(PackedVector2Array([Vector2(52, 80), Vector2(60, 52), Vector2(44, 52)]), Color8(230, 230, 240))


# ---------------------------------------------------------------- entrada y movimiento

func _unhandled_input(event: InputEvent) -> void:
	if en_encuentro or menu_abierto != null or _en_dialogo():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		destino = get_global_mouse_position()
		tiene_destino = true
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		destino = get_global_mouse_position()
		tiene_destino = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_encuentro()


func _process(delta: float) -> void:
	tiempo += delta
	ui.visible = not _en_dialogo()                # los menús no tapan el cuadro de diálogo
	if en_encuentro or menu_abierto != null or _en_dialogo():
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		tiene_destino = false
	elif tiene_destino:
		var falta := destino - jugador.position
		if falta.length() < 6.0:
			tiene_destino = false
		else:
			dir = falta.normalized()

	var movido := Vector2.ZERO
	if dir != Vector2.ZERO:
		var antes := jugador.position
		_mover(dir * VELOCIDAD * delta)
		movido = jugador.position - antes
	sprite.actualizar(movido, movido.length() / maxf(VELOCIDAD * delta, 0.001), delta)
	_comprobar_cerca()


func _mover(d: Vector2) -> void:
	var nueva := jugador.position + d
	if _es_tierra(nueva):
		jugador.position = nueva
	elif _es_tierra(jugador.position + Vector2(d.x, 0)):
		jugador.position += Vector2(d.x, 0)
	elif _es_tierra(jugador.position + Vector2(0, d.y)):
		jugador.position += Vector2(0, d.y)
	else:
		tiene_destino = false
		return
	acum += d.length()
	if acum >= LONG_PASO:
		acum -= LONG_PASO
		_paso()


func _paso() -> void:
	pasos += 1
	var zona := _zona_en(jugador.position)
	if zona != zona_actual:
		zona_actual = zona
		etiqueta_zona.text = "Zona: %s" % NOMBRES_ZONA.get(zona, zona)
	if load("res://progreso.gd").paso_incienso():
		_mostrar_aviso("El Incienso de Ceniza se ha consumido.")
	if cerca != null:
		return   # en las ciudades no hay encuentros
	# progreso.gd: pasos seguros, luego sube despacio; casi nada si la zona ya está «limpia» o con incienso
	if randf() < load("res://progreso.gd").prob_encuentro(PROB_ENCUENTRO, pasos, PASOS_MIN, zona):
		_encuentro()


func _es_tierra(p: Vector2) -> bool:
	if zonas_img == null:
		return Rect2(Vector2.ZERO, MAPA_TAM).has_point(p)
	var x := int(p.x * 0.5)
	var y := int(p.y * 0.5)
	if x < 0 or y < 0 or x >= zonas_img.get_width() or y >= zonas_img.get_height():
		return false
	return zonas_img.get_pixel(x, y).a > 0.5


func _zona_en(p: Vector2) -> String:
	if zonas_img == null or not _es_tierra(p):
		return "llanura"
	var c := zonas_img.get_pixel(int(p.x * 0.5), int(p.y * 0.5))
	var mejor := "llanura"
	var dmin := 1000000.0
	for k in ZONAS:
		var z: Color = ZONAS[k]
		var dd := Vector3(c.r, c.g, c.b).distance_squared_to(Vector3(z.r, z.g, z.b))
		if dd < dmin:
			dmin = dd
			mejor = k
	return mejor


func _comprobar_cerca() -> void:
	var mejor = null
	for l in lugares:
		if jugador.position.distance_to(l["pos"]) < RADIO_LUGAR:
			mejor = l
	if mejor != cerca:
		cerca = mejor
		boton_entrar.visible = cerca != null
		if cerca != null:
			boton_entrar.text = "Cruzar el portal" if cerca["tipo"] == "portal" else "Entrar: %s" % cerca["nombre"]


# ---------------------------------------------------------------- encuentros

func _encuentro() -> void:
	if en_encuentro:
		return
	en_encuentro = true
	tiene_destino = false
	Engine.set_meta("zona", _zona_en(jugador.position))
	Engine.set_meta("pos_mapa", jugador.position)
	Engine.set_meta("pos_mapa_ok", true)
	Engine.set_meta("desde_mapa", true)
	Engine.set_meta("tipo_combate", "normal")   # los jefes usarán "jefe" o "superjefe"
	Engine.set_meta("escena_retorno", "res://mapa.tscn")
	_mostrar_aviso("¡Emboscada!")

	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.size = Vector2(1280, 720)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(flash)
	var t := create_tween()
	for i in 3:
		t.tween_property(flash, "color:a", 0.85, 0.07)
		t.tween_property(flash, "color:a", 0.0, 0.07)
	t.tween_property(flash, "color", Color(0, 0, 0, 1), 0.45)
	await t.finished
	Recursos.cambiar_escena("res://combate.tscn")


# ---------------------------------------------------------------- menús y mensajes

func _boton_menu(nombre: String) -> void:
	match nombre:
		"Mapa":
			_mostrar_aviso("Estás en el mapa del mundo.")
		"Viaje rápido":
			_mostrar_aviso("El viaje rápido se desbloquea con el barco volador Astraea.")
		"Misiones":
			_mostrar_aviso("Objetivo: escapa de Oakhaven y llega al Gran Bosque Verde.")
		"Grupo", "Objetos", "Habilidades", "Diario":
			_abrir_menu(nombre)
		_:
			_mostrar_aviso("%s: aún por construir." % nombre)


# ---------------------------------------------------------------- menús del grupo

# Grupo (nivel, atributos y equipo), Objetos y Habilidades: ventana de menus.gd.
func _abrir_menu(pestana: String) -> void:
	if menu_abierto != null or not ResourceLoader.exists("res://menus.gd"):
		return
	tiene_destino = false
	if pestana == "Diario":                       # detalles descubiertos y fichas de combate (diario.gd)
		menu_abierto = load("res://diario.gd").new()
	else:
		menu_abierto = load("res://menus.gd").new()
		menu_abierto.pestana = pestana
	menu_abierto.cerrado.connect(func(): menu_abierto = null)
	ui.add_child(menu_abierto)


# Entra al mapa de la zona (zona.tscn). Al salir, el jugador vuelve aquí.
func _entrar() -> void:
	if cerca == null or en_encuentro:
		return
	en_encuentro = true
	tiene_destino = false
	var i := lugares.find(cerca)
	if cerca["tipo"] == "portal":                     # sube a la ciudad flotante; al bajar se vuelve aquí
		Engine.set_meta("pos_mapa", jugador.position)
		Engine.set_meta("pos_mapa_ok", true)
		Engine.set_meta("pos_isla_ok", false)
		var flash := ColorRect.new()
		flash.color = Color("8E5BD8", 0.0)
		flash.size = Vector2(1280, 720)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(flash)
		var tp := create_tween()
		tp.tween_property(flash, "color:a", 1.0, 0.4)
		tp.tween_property(flash, "color", Color(0, 0, 0, 1), 0.3)
		await tp.finished
		Recursos.cambiar_escena(ESCENA_PORTAL)
		return
	Engine.set_meta("lugar", {"indice": i, "nombre": cerca["nombre"], "tipo": cerca["tipo"],
		"zona": cerca.get("zona", ZONA_LUGAR[i] if i < ZONA_LUGAR.size() else "llanura"), "texto": cerca["texto"]})
	Engine.set_meta("pos_mapa", jugador.position)
	Engine.set_meta("pos_mapa_ok", true)
	Engine.set_meta("pos_zona_ok", false)
	var negro := ColorRect.new()
	negro.color = Color(0, 0, 0, 0)
	negro.size = Vector2(1280, 720)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(negro)
	var t := create_tween()
	t.tween_property(negro, "color:a", 1.0, 0.5)
	await t.finished
	# la Garganta del Diablo es una mazmorra hecha a mano (garganta.gd); las regiones 3D (modo3d.gd) tienen su
	# escena; el resto, zonas generadas
	var region_3d: String = load("res://modo3d.gd").escena_de(i)
	if region_3d != "":
		Engine.set_meta("pos_3d_ok", false)          # entra por el principio del camino
		Recursos.cambiar_escena(region_3d)
		return
	Recursos.cambiar_escena("res://garganta.tscn" if i == INDICE_GARGANTA else "res://zona.tscn")


func _mostrar_aviso(texto: String) -> void:
	aviso.text = texto
	if tween_aviso != null and tween_aviso.is_valid():
		tween_aviso.kill()
	tween_aviso = create_tween()
	tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	tween_aviso.tween_interval(2.8)
	tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


func _en_dialogo() -> bool:
	return has_node("/root/Dialogic") and get_node("/root/Dialogic").current_timeline != null
