extends Node2D
# Arboleda Mítica, la ciudad flotante (Godot 4.x). Se sube por el Portal del Vacío del mapa del mundo
# y se baja por el portal de la isla, que te deja donde cogiste el primero.
#
# Es un fondo pintado, como pide la Biblia de arte: la isla de Meshy («Myth Grove Starter Island»)
# renderizada en tres cuartos (38°) a 3072 × 3348 px, para que Kael quepa por calles y escaleras.
# Del mismo modelo salen, también renderizadas:
#   isla_paso.png   máscara de paso a 1/4 (blanco = se anda): la plaza, la orilla, las escaleras y la terraza
#   isla_suelo.png  a qué profundidad está el suelo en cada punto (1/4)
#   isla_tapa.png   a qué profundidad está lo que se alza: casas, árboles, muros (1/2)
# La «capa delantera» se hace sola: la isla se dibuja otra vez encima de Kael, pero solo donde hay algo
# más cerca de la cámara que él (shader con isla_tapa y la profundidad de sus pies). Así pasa por detrás
# de los árboles y del templo.
# Detalles animados: nubes que pasan por debajo, el remolino del portal y motas de luz.

const CARPETA := "res://isla/"
const ANCHO := 3072
const ALTO := 3348
const TROZOS := Vector2i(2, 2)
const VELOCIDAD := 200.0
const PORTAL := Vector2(1460, 2536)          # pies del portal (píxeles de la isla)
const LLEGADA := Vector2(1444, 2624)
const RADIO_PORTAL := 110.0
const RADIO_NPC := 95.0
const ESCALA_KAEL := 1.0
const NPCS := [
	{"nombre": "Guardiana Ilia", "imagen": "res://personajes/npc/maga.png", "pos": Vector2(1364, 1600),
		"frases": ["El templo de arriba guarda el Cristal del Cielo. Nadie entra sin permiso.",
			"El portal no lo abrió nadie de aquí. Apareció la misma noche que la niebla.",
			"Desde aquí arriba la niebla parece un mar. Uno muy hambriento."]},
	{"nombre": "Jardinero Orun", "imagen": "res://personajes/npc/caballero.png", "pos": Vector2(1000, 1920),
		"frases": ["Estos árboles beben de las cascadas. Si el agua se para, la isla cae.",
			"¿Ves el cristal de la plaza? Late cuando alguien con un brazalete pasa cerca…",
			"Antes subían peregrinos con un anillo partido grabado. Ya no sube nadie."]},
	{"nombre": "Niña Lumi", "imagen": "res://personajes/npc/aldeana.png", "pos": Vector2(1700, 1980),
		"frases": ["¡Hala! ¿Has subido por el portal? ¡Yo nunca he bajado!",
			"Mi abuela dice que abajo todo es gris. ¿Es verdad?",
			"Si te asomas a la orilla se ven las nubes pasar por debajo. ¡Me encanta!"]},
	{"nombre": "Mercader Vex", "imagen": "res://personajes/npc/picaro.png", "pos": Vector2(700, 2048),
		"frases": ["Compro plumas de arpía. Bueno, compraría si alguien me las trajera.",
			"El Mandoble del Averno y el Espadón de Diamante Azul… los venden abajo, en las tiendas. Caros.",
			"Aquí arriba no hay monstruos. Por eso nadie quiere irse."]},
]
const SHADER_TAPA := """
shader_type canvas_item;
uniform sampler2D tapa : filter_nearest;
uniform vec2 uv_ini;
uniform vec2 uv_tam;
uniform float z_kael;
void fragment() {
	float d = texture(tapa, uv_ini + UV * uv_tam).r;
	if (d <= z_kael + 0.012) {
		discard;
	}
	COLOR = texture(TEXTURE, UV);
}
"""
const SHADER_PORTAL := """
shader_type canvas_item;
uniform vec2 centro = vec2(0.5, 0.577);
uniform vec2 radio = vec2(0.17, 0.22);
uniform float velocidad = 0.9;
void fragment() {
	vec2 d = (UV - centro) / radio;
	float r = length(d);
	vec4 c = texture(TEXTURE, UV);
	if (r < 1.0) {                                 // el remolino gira, más deprisa en el centro
		float ang = TIME * velocidad * (1.0 - r) * 2.4;
		vec2 rd = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang))) * d;
		vec4 g = texture(TEXTURE, centro + rd * radio);
		c = mix(g, c, smoothstep(0.75, 1.0, r));
		c.rgb *= 1.0 + 0.15 * sin(TIME * 2.0 - r * 6.0);
	}
	COLOR = c;
}
"""

var paso_img: Image
var suelo_img: Image
var jugador: Node2D
var sprite
var camara: Camera2D
var mundo_y: Node2D
var mats_tapa: Array = []
var ui: CanvasLayer
var aviso: Label
var tween_aviso: Tween
var boton: Button
var fundido: ColorRect
var destino := Vector2.ZERO
var tiene_destino := false
var saliendo := false
var z_kael := 0.5
var npcs: Array = []                 # [sprite, datos, frase]
var npc_cerca = null
var portal_cerca := false
var luz_tex: GradientTexture2D
var aditivo: CanvasItemMaterial


func _ready() -> void:
	var R = get_node_or_null("/root/Recursos")
	paso_img = _tex(CARPETA + "isla_paso.png").get_image()
	suelo_img = _tex(CARPETA + "isla_suelo.png").get_image()
	_crear_recursos()
	_crear_cielo()
	_crear_isla()
	_crear_jugador()
	_crear_npcs()
	_crear_portal()
	_crear_motas()
	_crear_ui()
	if R != null:
		guardar_posicion()
		load("res://progreso.gd").guardar(scene_file_path)
	_mostrar_aviso("La ciudad flotante. Aquí la niebla no llega.")


# Las imágenes de la isla son solo de esta zona: Recursos las suelta al volver al mapa.
func _tex(ruta: String) -> Texture2D:
	var R = get_node_or_null("/root/Recursos")
	return R.obtener(ruta, "zona") if R != null else load(ruta)


func _crear_recursos() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	luz_tex = GradientTexture2D.new()
	luz_tex.gradient = g
	luz_tex.fill = GradientTexture2D.FILL_RADIAL
	luz_tex.fill_from = Vector2(0.5, 0.5)
	luz_tex.fill_to = Vector2(1.0, 0.5)
	luz_tex.width = 128
	luz_tex.height = 128
	aditivo = CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


# ================================================================= escenario

# Cielo: degradado fijo detrás y nubes que pasan despacio por debajo de la isla.
func _crear_cielo() -> void:
	var fondo := CanvasLayer.new()
	fondo.layer = -10
	add_child(fondo)
	var cielo := TextureRect.new()
	var gc := Gradient.new()
	gc.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	gc.colors = PackedColorArray([Color("7FA0D8"), Color("C9D9EE"), Color("F4EAD2")])
	var tc := GradientTexture2D.new()
	tc.gradient = gc
	tc.fill_from = Vector2(0, 0)
	tc.fill_to = Vector2(0, 1)
	tc.width = 4
	tc.height = 128
	cielo.texture = tc
	cielo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cielo.stretch_mode = TextureRect.STRETCH_SCALE
	cielo.size = Vector2(1280, 720)
	fondo.add_child(cielo)
	var nubes := CPUParticles2D.new()                # nubes grandes y suaves (pocas: no cuestan)
	nubes.texture = luz_tex
	nubes.amount = 14
	nubes.lifetime = 40.0
	nubes.preprocess = 40.0
	nubes.local_coords = false
	nubes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	nubes.emission_rect_extents = Vector2(60, ALTO * 0.5)
	nubes.position = Vector2(-500, ALTO * 0.5)
	nubes.direction = Vector2(1, 0)
	nubes.spread = 0.0
	nubes.gravity = Vector2.ZERO
	nubes.initial_velocity_min = 25.0
	nubes.initial_velocity_max = 45.0
	nubes.scale_amount_min = 4.0
	nubes.scale_amount_max = 8.0
	nubes.color = Color(1, 1, 1, 0.35)
	nubes.z_index = -5
	add_child(nubes)


# La isla en trozos (texturas de 1536 × 1674) y, encima de Kael, los mismos trozos con el shader
# que solo deja lo que está más cerca de la cámara que él.
func _crear_isla() -> void:
	var tapa := _tex(CARPETA + "isla_tapa.png")
	var tw := ANCHO / TROZOS.x
	var th := ALTO / TROZOS.y
	for j in TROZOS.y:
		for i in TROZOS.x:
			var tex := _tex(CARPETA + "isla_color_%d_%d.png" % [i, j])
			var base := Sprite2D.new()
			base.texture = tex
			base.centered = false
			base.position = Vector2(i * tw, j * th)
			base.z_index = 0
			add_child(base)
			var encima := Sprite2D.new()
			encima.texture = tex
			encima.centered = false
			encima.position = base.position
			encima.z_index = 3
			var m := ShaderMaterial.new()
			m.shader = Shader.new()
			m.shader.code = SHADER_TAPA
			m.set_shader_parameter("tapa", tapa)
			m.set_shader_parameter("uv_ini", Vector2(float(i) / TROZOS.x, float(j) / TROZOS.y))
			m.set_shader_parameter("uv_tam", Vector2(1.0 / TROZOS.x, 1.0 / TROZOS.y))
			m.set_shader_parameter("z_kael", z_kael)
			encima.material = m
			add_child(encima)
			mats_tapa.append(m)
	mundo_y = Node2D.new()
	mundo_y.y_sort_enabled = true
	mundo_y.z_index = 2
	add_child(mundo_y)


func _crear_jugador() -> void:
	jugador = Node2D.new()
	jugador.position = LLEGADA
	if Engine.get_meta("pos_isla_ok", false):
		jugador.position = Engine.get_meta("pos_isla")
	mundo_y.add_child(jugador)
	var s := Sprite2D.new()
	s.texture = luz_tex
	s.modulate = Color(0.04, 0.07, 0.13, 0.45)
	s.scale = Vector2(0.45, 0.16)
	jugador.add_child(s)
	sprite = load("res://muneco.gd").new()
	sprite.scale = Vector2.ONE * ESCALA_KAEL
	jugador.add_child(sprite)
	Sonido.pasos_2d(sprite, func(): return "piedra")   # las calles de piedra de la ciudad (sonido.gd, T-083)
	camara = Camera2D.new()
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = ANCHO
	camara.limit_bottom = ALTO
	camara.position_smoothing_enabled = true
	camara.position_smoothing_speed = 7.0
	jugador.add_child(camara)
	camara.make_current()
	camara.reset_smoothing()
	_poner_z()


func _crear_npcs() -> void:
	for d in NPCS:
		if not ResourceLoader.exists(d["imagen"]):
			continue
		var tex: Texture2D = load(d["imagen"])
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		s.scale = Vector2.ONE * 0.5
		s.position = d["pos"]
		mundo_y.add_child(s)
		var sombra := Sprite2D.new()
		sombra.texture = luz_tex
		sombra.modulate = Color(0.04, 0.07, 0.13, 0.4)
		sombra.scale = Vector2(0.45, 0.15) / s.scale
		sombra.show_behind_parent = true
		s.add_child(sombra)
		var t := create_tween().set_loops()               # respiran
		t.tween_property(s, "scale:y", 0.51, 1.3 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
		t.tween_property(s, "scale:y", 0.5, 1.3 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
		npcs.append([s, d, 0])


func _crear_portal() -> void:
	var tex: Texture2D = load("res://objetos/portal.png")
	var p := Sprite2D.new()
	p.texture = tex
	p.centered = false
	p.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height() + 40)
	p.scale = Vector2.ONE * 0.42
	p.position = PORTAL
	var m := ShaderMaterial.new()
	m.shader = Shader.new()
	m.shader.code = SHADER_PORTAL
	p.material = m
	mundo_y.add_child(p)
	var brillo := Sprite2D.new()                      # resplandor morado que late
	brillo.texture = luz_tex
	brillo.material = aditivo
	brillo.modulate = Color("8E5BD8")
	brillo.modulate.a = 0.5
	brillo.scale = Vector2(2.2, 2.8)
	brillo.position = PORTAL + Vector2(0, -130)
	brillo.z_index = 1
	add_child(brillo)
	var t := create_tween().set_loops()
	t.tween_property(brillo, "modulate:a", 0.25, 1.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(brillo, "modulate:a", 0.5, 1.4).set_trans(Tween.TRANS_SINE)


# Motas de luz que flotan sobre la plaza.
func _crear_motas() -> void:
	var m := CPUParticles2D.new()
	m.texture = luz_tex
	m.material = aditivo
	m.amount = 30
	m.lifetime = 7.0
	m.preprocess = 7.0
	m.position = Vector2(1373, 1950)
	m.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	m.emission_rect_extents = Vector2(700, 500)
	m.gravity = Vector2(0, -8)
	m.initial_velocity_min = 2.0
	m.initial_velocity_max = 10.0
	m.scale_amount_min = 0.04
	m.scale_amount_max = 0.1
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color("F4EAD2", 0.0), Color("F4EAD2", 0.8), Color("8FF0B0", 0.0)])
	m.color_ramp = g
	m.z_index = 4
	add_child(m)


# ================================================================= interfaz

func _crear_ui() -> void:
	var Estilo = load("res://estilo.gd")
	ui = CanvasLayer.new()
	add_child(ui)
	var titulo := Label.new()
	titulo.text = "Arboleda Mítica"
	titulo.position = Vector2(20, 6)
	titulo.add_theme_font_override("font", Estilo.cursiva())
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.add_theme_constant_override("outline_size", 6)
	ui.add_child(titulo)
	var linea := ColorRect.new()
	linea.color = Color("3FA86B", 0.9)                # acento verde del bosque
	linea.position = Vector2(22, 60)
	linea.size = Vector2(220, 2)
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(linea)
	var sub := Label.new()
	sub.text = "CIUDAD FLOTANTE"
	sub.position = Vector2(22, 64)
	sub.add_theme_font_override("font", load("res://menu_combate.gd").fuente("res://fuentes/SairaCondensed-Light.ttf", 4, 0))
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Estilo.GRIS)
	ui.add_child(sub)
	boton = Button.new()
	boton.position = Vector2(520, 600)
	boton.custom_minimum_size = Vector2(240, 52)
	boton.add_theme_font_size_override("font_size", 22)
	boton.visible = false
	boton.pressed.connect(_accion)
	boton.focus_mode = Control.FOCUS_NONE              # con teclado o mando, Intro / A (ui_accept)
	ui.add_child(boton)
	aviso = Label.new()
	aviso.position = Vector2(190, 110)
	aviso.size = Vector2(900, 60)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_font_override("font", Estilo.cursiva())
	aviso.add_theme_font_size_override("font_size", 32)
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.modulate.a = 0.0
	ui.add_child(aviso)
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or "dpad" in OS.get_cmdline_user_args():
		var dpad = load("res://dpad.gd").new()
		dpad.position = Vector2(40, 440)
		ui.add_child(dpad)
	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 1)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fundido)
	create_tween().tween_property(fundido, "color:a", 0.0, 0.6)


func _mostrar_aviso(texto: String) -> void:
	aviso.text = texto
	if tween_aviso != null and tween_aviso.is_valid():
		tween_aviso.kill()
	tween_aviso = create_tween()
	tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	tween_aviso.tween_interval(3.4)
	tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


# ================================================================= movimiento

func _se_anda(p: Vector2) -> bool:
	var x := int(p.x / 4.0)
	var y := int(p.y / 4.0)
	if x < 0 or y < 0 or x >= paso_img.get_width() or y >= paso_img.get_height():
		return false
	if paso_img.get_pixel(x, y).r < 0.5:
		return false
	for n in npcs:                                   # los NPC no se atraviesan
		if p.distance_to(n[0].position) < 22.0:
			return false
	return true


# Profundidad del suelo bajo los pies de Kael: lo que esté más cerca de la cámara le tapa.
func _poner_z() -> void:
	var x := clampi(int(jugador.position.x / 4.0), 0, suelo_img.get_width() - 1)
	var y := clampi(int(jugador.position.y / 4.0), 0, suelo_img.get_height() - 1)
	var z := suelo_img.get_pixel(x, y).r
	if z > 0.0 and absf(z - z_kael) > 0.001:
		z_kael = z
		for m in mats_tapa:
			m.set_shader_parameter("z_kael", z_kael)


func _unhandled_input(event: InputEvent) -> void:
	if saliendo or _en_dialogo():                  # con un diálogo abierto, el personaje no recibe órdenes
		return
	if event.is_action_pressed("ui_accept") and boton.visible:
		get_viewport().set_input_as_handled()     # teclado y mando: hablar o bajar al mundo
		_accion()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		destino = get_global_mouse_position()
		tiene_destino = true
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		destino = get_global_mouse_position()
		tiene_destino = true


func _en_dialogo() -> bool:
	return has_node("/root/Dialogic") and get_node("/root/Dialogic").current_timeline != null


func _process(delta: float) -> void:
	if saliendo or _en_dialogo():
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
	var antes := jugador.position
	if dir != Vector2.ZERO:
		var d := dir * VELOCIDAD * delta
		if _se_anda(antes + d):
			jugador.position = antes + d
		elif _se_anda(antes + Vector2(d.x, 0)):
			jugador.position = antes + Vector2(d.x, 0)
		elif _se_anda(antes + Vector2(0, d.y)):
			jugador.position = antes + Vector2(0, d.y)
		else:
			tiene_destino = false
	var movido := jugador.position - antes
	sprite.actualizar(movido, movido.length() / maxf(VELOCIDAD * delta, 0.001), delta)
	if movido.length() > 0.1:
		_poner_z()
	_comprobar_cerca()


func _comprobar_cerca() -> void:
	portal_cerca = jugador.position.distance_to(PORTAL) < RADIO_PORTAL
	npc_cerca = null
	var mejor := RADIO_NPC
	for n in npcs:
		var dd: float = jugador.position.distance_to(n[0].position)
		if dd < mejor:
			mejor = dd
			npc_cerca = n
	if npc_cerca != null:
		boton.text = "Hablar con " + npc_cerca[1]["nombre"].get_slice(" ", 1)
	elif portal_cerca:
		boton.text = "Bajar al mundo"
	boton.visible = npc_cerca != null or portal_cerca


func _accion() -> void:
	if npc_cerca != null:
		var frases: Array = npc_cerca[1]["frases"]
		_mostrar_aviso("%s: «%s»" % [npc_cerca[1]["nombre"], frases[npc_cerca[2] % frases.size()]])
		npc_cerca[2] += 1
	elif portal_cerca:
		_bajar()


# Baja por el portal: vuelve al mapa del mundo, junto al Portal del Vacío por el que subió.
func _bajar() -> void:
	if saliendo:
		return
	saliendo = true
	Engine.set_meta("pos_isla_ok", false)
	Sonido.efecto("portal")                            # sonido.gd
	var t := create_tween()
	t.tween_property(fundido, "color", Color("8E5BD8", 1.0), 0.35)
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.3)
	await t.finished
	var R = get_node_or_null("/root/Recursos")
	if R != null:
		R.cambiar_escena("res://mapa.tscn")
	else:
		get_tree().change_scene_to_file("res://mapa.tscn")


# Recursos la llama al cerrar la app, para volver justo aquí.
func guardar_posicion() -> void:
	Engine.set_meta("pos_isla", jugador.position)
	Engine.set_meta("pos_isla_ok", true)
