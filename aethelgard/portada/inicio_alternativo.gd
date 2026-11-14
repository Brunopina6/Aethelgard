extends "res://carga.gd"
# Pantalla de inicio ALTERNATIVA, en pruebas (encargo del 11/11). No sustituye a la original (carga.tscn), que sigue
# siendo la escena principal; solo se usa si se elige (portada/eleccion.gd: Ajustes en la versión experimental o
# «-- portada_alternativa»).
#
# La carga es LA MISMA que la de siempre: este guion hereda de carga.gd y usa sus pasos sin cambiarlos (archivos en
# segundo plano, sombreadores fuera de la vista, interfaz de los diálogos y cachés de las zonas), así que prepara lo
# mismo y en el mismo orden. Lo que cambia es lo que se ve y el menú:
#   - el entorno (portada/fondo_portada.gd): cielo nocturno, ruinas y fortalezas, niebla, la luz de un cristal,
#     cenizas y brasas, con paralaje suave;
#   - el MISMO logo (marca/logo_rebelum.webp, sin tocar, en el mismo sitio, tamaño y modo aditivo que en carga.gd), con
#     un aura que respira y un destello que lo recorre de vez en cuando por encima, y el subtítulo «Cónclave de las
#     Cenizas»;
#   - la carga y el menú, separados: una línea fina mientras carga; al terminar, la línea se apaga, suena una campana
#     suave y aparece «TOCA PARA EMPEZAR» (o Intro / A); al pulsarlo sale el menú:
#       Continuar (solo si hay partida), Nueva partida (si ya hay una, pide confirmación y hace antes una copia de
#       seguridad), Opciones (los Ajustes de siempre, menus.gd) y Créditos (pantalla sencilla y honesta).
#     «Cargar partida» no está: el juego tiene UNA sola partida por versión (progreso.gd: partida.save o
#     partida_exp.save); la ranura de prueba es una herramienta de desarrollo, no una ranura del jugador.
#   - los accesos de pruebas (los dos de carga.gd, con el mismo texto y la misma acción), con otro estilo y solo donde
#     los enseña hoy carga.gd: con la exploración 3D activa (APK experimental y de Auditoría, o «-- 3d»).
# Con teclado o mando: ↑ ↓ por el menú (da la vuelta), ← → a los accesos de pruebas, Intro / A elige y Esc / B vuelve.

const Fondo := preload("res://portada/fondo_portada.gd")
const Estilo := preload("res://estilo.gd")

const LOGO_POS := Vector2(370, 14)                # como en carga.gd
const LOGO_TAM := Vector2(540, 381)
const CENTRO_LOGO := Vector2(640, 204)
const LINEA_Y := 434.0
const LINEA_ANCHO := 320.0
const MENU_Y := 438.0
const BLOQUEO_TOQUE := 0.35                       # el toque que abre el menú no pulsa lo que aparece debajo
const CADA_DESTELLO := 9.0

const SH_DESTELLO := """
shader_type canvas_item;
render_mode blend_add;
uniform float fase = -1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = max(c.r, max(c.g, c.b));
	float x = UV.x * 1.4 - UV.y * 0.5;
	float banda = exp(-pow((x - fase) * 7.0, 2.0));
	COLOR = vec4(c.rgb * banda * 0.55 * smoothstep(0.3, 0.85, lum), 1.0);
}
"""

var estado := "cargando"                          # cargando → toca → menu; encima del menú: confirmar, creditos, opciones
var fondo: Node2D
var ui: CanvasLayer
var capa_ventanas: CanvasLayer
var logo: TextureRect
var aura: TextureRect
var destello: TextureRect
var mat_destello: ShaderMaterial
var subtitulo: Label
var adornos: Array = []
var linea_fondo_alt: ColorRect
var linea_alt: ColorRect
var punta: TextureRect
var cifra: Label
var frase_alt: Label
var fondo_menu: TextureRect
var menu: VBoxContainer
var botones_menu: Array = []
var selector: Node2D
var selector_barra: TextureRect
var rombos: Array = []
var pruebas_titulo: Label
var ventana: Control                              # la ventana abierta encima del menú (confirmar, créditos, opciones)
var ambiente: AudioStreamPlayer
var menu_desde := -10.0
var destello_t := 0.0
var t_listo := -1.0                               # segundos hasta acabar la carga (lo leen las pruebas y las medidas)
var elegido: Button
var fuente_menu: Font
var tween_frase: Tween


func _ready() -> void:
	Engine.max_fps = 60
	_crear_portada()
	pendientes = Recursos.listar()
	var estilo: String = Recursos.ruta_estilo_dialogos()
	if estilo != "" and ResourceLoader.exists(estilo):
		pendientes.append(estilo)
	total = maxi(1, pendientes.size())
	print("Portada alternativa: %d archivos comunes" % pendientes.size())


# ================================================================= aspecto

func _crear_portada() -> void:
	fondo = Fondo.new()
	add_child(fondo)
	ui = CanvasLayer.new()
	ui.layer = 1
	add_child(ui)
	capa_ventanas = CanvasLayer.new()
	capa_ventanas.layer = 5
	add_child(capa_ventanas)
	var brillo_tex: GradientTexture2D = Fondo.textura_brillo(128)
	var ad := Fondo.aditivo()

	# Un hueco oscuro detrás del logo: el logo va en modo aditivo (como en carga.gd) y así se ve igual que sobre negro.
	var hueco := _radial(Color(0, 0, 0, 0.82), Color(0, 0, 0, 0))
	hueco.position = CENTRO_LOGO - Vector2(470, 300)
	hueco.size = Vector2(940, 600)
	ui.add_child(hueco)
	aura = TextureRect.new()
	aura.texture = brillo_tex
	aura.material = ad
	aura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aura.stretch_mode = TextureRect.STRETCH_SCALE
	aura.position = CENTRO_LOGO - Vector2(330, 230)
	aura.size = Vector2(660, 460)
	aura.modulate = Color(0.55, 0.4, 0.95, 0.0)
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(aura)
	# El logotipo de REBELUM, el mismo archivo y la misma colocación que en carga.gd.
	logo = TextureRect.new()
	logo.texture = load("res://marca/logo_rebelum.webp")
	logo.material = ad
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = LOGO_POS
	logo.size = LOGO_TAM
	logo.modulate.a = 0.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(logo)
	# El destello: otra pasada del logo, solo con una franja de luz que lo cruza en diagonal (no cambia el logo).
	destello = TextureRect.new()
	destello.texture = logo.texture
	mat_destello = ShaderMaterial.new()
	mat_destello.shader = Shader.new()
	mat_destello.shader.code = SH_DESTELLO
	mat_destello.set_shader_parameter("fase", -1.0)
	destello.material = mat_destello
	destello.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	destello.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	destello.position = LOGO_POS
	destello.size = LOGO_TAM
	destello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(destello)
	# «CÓNCLAVE DE LAS CENIZAS», como en carga.gd, con dos filetes dorados a los lados.
	var f_sub: Font = M.fuente(M.FUENTE_ORDEN, 9, 0)
	subtitulo = _etiqueta("CÓNCLAVE DE LAS CENIZAS", f_sub, 22, Color(M.ORO, 0.9))
	subtitulo.position = Vector2(0, 372)
	subtitulo.modulate.a = 0.0
	ui.add_child(subtitulo)
	var ancho_sub: float = f_sub.get_string_size(subtitulo.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	for lado in [-1, 1]:
		var filete := _filete(lado)
		filete.position = Vector2(640 + lado * (ancho_sub * 0.5 + 18) - (110 if lado < 0 else 0), 388)
		filete.modulate.a = 0.0
		ui.add_child(filete)
		adornos.append(filete)

	# La carga: una línea fina con una chispa en la punta y la cifra pequeña debajo.
	linea_fondo_alt = ColorRect.new()
	linea_fondo_alt.color = Color(M.ORO, 0.14)
	linea_fondo_alt.position = Vector2(640 - LINEA_ANCHO * 0.5, LINEA_Y)
	linea_fondo_alt.size = Vector2(LINEA_ANCHO, 1)
	linea_fondo_alt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(linea_fondo_alt)
	linea_alt = ColorRect.new()
	linea_alt.color = Color(M.ORO, 0.9)
	linea_alt.position = linea_fondo_alt.position
	linea_alt.size = Vector2(0, 1)
	linea_alt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(linea_alt)
	punta = TextureRect.new()
	punta.texture = brillo_tex
	punta.material = ad
	punta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	punta.stretch_mode = TextureRect.STRETCH_SCALE
	punta.size = Vector2(40, 14)
	punta.modulate = Color(1.0, 0.85, 0.5, 0.8)
	punta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(punta)
	cifra = _etiqueta("0 %", M.fuente(M.FUENTE_ORDEN, 3, 0), 15, Color(M.GRIS, 0.8))
	cifra.position = Vector2(0, LINEA_Y + 8)
	ui.add_child(cifra)
	toca = _etiqueta("TOCA PARA EMPEZAR", M.fuente(M.FUENTE_ORDEN, 8, 0), 24, M.LUZ_CLARA)
	toca.position = Vector2(0, 462)
	toca.modulate.a = 0.0
	ui.add_child(toca)
	frase_alt = _etiqueta(FRASES[0], M.fuente(M.FUENTE_NOMBRE, 0, 500), 26, Color(M.LUZ_CLARA, 0.72))
	frase_alt.position = Vector2(0, 636)
	ui.add_child(frase_alt)
	_texto_empezar(Entrada.modo)
	Entrada.modo_cambiado.connect(_texto_empezar)

	# El menú (se llena al abrirlo: Continuar depende de si hay partida).
	fondo_menu = _radial(Color(0, 0, 0, 0.6), Color(0, 0, 0, 0))
	fondo_menu.position = Vector2(290, 400)
	fondo_menu.size = Vector2(700, 300)
	fondo_menu.modulate.a = 0.0
	ui.add_child(fondo_menu)
	selector = Node2D.new()
	selector.modulate.a = 0.0
	ui.add_child(selector)
	selector_barra = TextureRect.new()
	selector_barra.texture = _barra_tex()
	selector_barra.material = ad
	selector_barra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selector_barra.stretch_mode = TextureRect.STRETCH_SCALE
	selector_barra.position = Vector2(-230, -22)
	selector_barra.size = Vector2(460, 44)
	selector_barra.modulate = Color(1.0, 0.8, 0.45, 0.5)
	selector_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selector.add_child(selector_barra)
	for lado in [-1, 1]:
		var r := Polygon2D.new()
		r.polygon = PackedVector2Array([Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)])
		r.color = M.ORO
		r.position = Vector2(lado * 120, 0)
		selector.add_child(r)
		rombos.append(r)
	menu = VBoxContainer.new()
	menu.position = Vector2(440, MENU_Y)
	menu.size = Vector2(400, 0)
	menu.add_theme_constant_override("separation", 2)
	menu.visible = false
	ui.add_child(menu)
	fuente_menu = M.fuente(M.FUENTE_ORDEN_FUERTE, 5, 0)

	# Los accesos de pruebas: los mismos dos de carga.gd, con otro estilo. En esta pantalla, solo en la compilación de
	# Auditoría (característica «auditoria» de su preset) o en desarrollo (editor, o con «-- 3d» al arrancar), como pidió
	# el usuario el 11/11; la APK experimental no los enseña aquí.
	if load("res://modo3d.gd").activo() and modo_pruebas():
		pruebas_titulo = _etiqueta("PRUEBAS · solo en la versión de pruebas", M.fuente(M.FUENTE_ORDEN, 3, 0), 14,
			Color(0.62, 0.9, 0.9, 0.8))
		pruebas_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		pruebas_titulo.position = Vector2(22, 628)
		pruebas_titulo.visible = false
		ui.add_child(pruebas_titulo)
		boton_prologo = _boton_prueba("Probar el prólogo (partida nueva)", Vector2(20, 652), Vector2(350, 56))
		boton_prologo.pressed.connect(func(): _empezar(true, true))
		boton_prueba = _boton_prueba("Probar la misión desde el principio", Vector2(860, 652), Vector2(400, 56))
		boton_prueba.pressed.connect(func(): _empezar(true))
	# V12 (14/11): el banco de pruebas de Auditoría (banco_pruebas.gd), arriba a la derecha y solo en Auditoría o en el
	# editor. Su partida es aparte: la de siempre no se toca.
	if load("res://banco_pruebas.gd").permitido():
		boton_banco = _boton_prueba("Banco de pruebas (Auditoría)", Vector2(900, 16), Vector2(360, 56))
		boton_banco.pressed.connect(_abrir_banco)

	sonidos = M.sonidos_ui()
	reproductor = AudioStreamPlayer.new()
	reproductor.volume_db = -4.0
	reproductor.bus = &"Interfaz"
	add_child(reproductor)
	# Ambiente: el viento del mapa (CC0, audio/ambiente/viento.wav), bajo, que entra despacio.
	ambiente = AudioStreamPlayer.new()
	ambiente.stream = load("res://audio/ambiente/viento.wav")
	ambiente.bus = &"Ambiente"
	ambiente.volume_db = -42.0
	add_child(ambiente)
	ambiente.play()
	create_tween().tween_property(ambiente, "volume_db", -18.0, 4.0)

	# Entrada lenta: el logo aparece con un fundido, y luego el subtítulo.
	var tw := create_tween()
	tw.tween_property(logo, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(aura, "modulate:a", 0.14, 2.0)
	tw.tween_property(subtitulo, "modulate:a", 1.0, 0.8)
	for a in adornos:
		tw.parallel().tween_property(a, "modulate:a", 1.0, 0.8)


func _radial(dentro: Color, fuera: Color) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([dentro, fuera])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# Franja de luz que se apaga hacia los lados y hacia arriba y abajo (el selector del menú): un radial muy aplanado.
func _barra_tex() -> GradientTexture2D:
	var v := Gradient.new()
	v.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	v.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var r := GradientTexture2D.new()
	r.gradient = v
	r.fill = GradientTexture2D.FILL_RADIAL
	r.fill_from = Vector2(0.5, 0.5)
	r.fill_to = Vector2(1.0, 0.5)
	r.width = 128
	r.height = 16
	return r


# Filete dorado que se desvanece hacia fuera, con un rombo pequeño en el extremo de dentro.
func _filete(lado: int) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var dentro := Color(M.ORO, 0.8)
	var fuera := Color(M.ORO, 0.0)
	g.colors = PackedColorArray([fuera, dentro] if lado < 0 else [dentro, fuera])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 64
	t.height = 1
	var l := TextureRect.new()
	l.texture = t
	l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	l.stretch_mode = TextureRect.STRETCH_SCALE
	l.size = Vector2(110, 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(l)
	var r := Polygon2D.new()
	r.polygon = PackedVector2Array([Vector2(0, -3.5), Vector2(3.5, 0), Vector2(0, 3.5), Vector2(-3.5, 0)])
	r.color = Color(M.ORO, 0.9)
	r.position = Vector2(110 if lado < 0 else 0, 0.5)
	c.add_child(r)
	return c


# ¿Se enseñan los accesos de pruebas? Auditoría (característica de su preset), el editor, o arrancado con «-- 3d».
static func modo_pruebas() -> bool:
	return OS.has_feature("auditoria") or OS.has_feature("editor") or "3d" in OS.get_cmdline_user_args()


func _boton_prueba(texto: String, pos: Vector2, tam: Vector2) -> Button:
	var b := Button.new()
	b.text = texto
	b.position = pos
	b.custom_minimum_size = tam
	b.add_theme_font_size_override("font_size", 20)
	b.focus_mode = Control.FOCUS_ALL
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.02, 0.07, 0.08, 0.72)
	normal.border_color = Color(0.4, 0.8, 0.8, 0.55)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.set_content_margin_all(8)
	var encima := normal.duplicate()
	encima.border_color = Color(0.55, 0.95, 0.95, 0.95)
	encima.bg_color = Color(0.03, 0.11, 0.12, 0.85)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", encima)
	b.add_theme_stylebox_override("pressed", encima)
	b.add_theme_color_override("font_color", Color(0.75, 0.95, 0.95))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.visible = false
	b.modulate.a = 0.0
	ui.add_child(b)
	return b


func _boton_menu(clave: String, texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.set_meta("clave", "portada:" + clave)
	b.set_meta("opcion", clave)
	b.custom_minimum_size = Vector2(400, 50)
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", fuente_menu)
	b.add_theme_font_size_override("font_size", 24)
	var vacio := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, vacio)
	b.add_theme_color_override("font_color", Color(M.LUZ_CLARA, 0.72))
	for s in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, M.ORO)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	b.add_theme_constant_override("outline_size", 6)
	b.focus_entered.connect(_seleccionar.bind(b))
	b.mouse_entered.connect(func():
		if estado == "menu" and not saliendo:
			b.grab_focus(not Entrada.con_foco()))
	b.pressed.connect(_elegir.bind(b))
	return b


# ================================================================= carga (los mismos pasos que carga.gd)

func _process(delta: float) -> void:
	tiempo += delta
	match fase:
		"archivos":
			_paso_archivos()
			progreso = 0.7 * float(hechos) / total
		"shaders":
			_paso_shaders()
			progreso = 0.7 + 0.2 * float(frames_shader) / FRAMES_SHADERS
		"dialogos":
			_paso_dialogos()
			progreso = 0.9
		"zonas":
			_paso_zonas()
			progreso = 0.9 + 0.1 * (1.0 - float(tareas_zona.size()) / tareas_total)
	if not listo:
		linea_alt.size.x = lerpf(linea_alt.size.x, LINEA_ANCHO * progreso, minf(1.0, delta * 10.0))
		punta.position = linea_alt.position + Vector2(linea_alt.size.x - 20, -7)
		cifra.text = "%d %%" % int(round(progreso * 100.0))
	if estado in ["cargando", "toca"] and int(tiempo / 4.0) != frase_i:   # la frase cambia cada 4 s, como en carga.gd
		frase_i = int(tiempo / 4.0)
		tween_frase = create_tween()
		tween_frase.tween_property(frase_alt, "modulate:a", 0.0, 0.5)
		tween_frase.tween_callback(func(): frase_alt.text = FRASES[frase_i % FRASES.size()])
		tween_frase.tween_property(frase_alt, "modulate:a", 1.0, 0.5)
	if fase == "fin" and tiempo >= MINIMO and not listo:
		listo = true
		t_listo = tiempo
		print("Carga terminada en %.1f s (%d archivos, %d fallos) · portada alternativa" % [tiempo, hechos, fallos])
		_carga_lista()
		if "auto" in OS.get_cmdline_user_args():     # pruebas: entra solo, como en carga.gd
			_empezar.call_deferred()
	_animar(delta)


# La carga ha terminado: la línea se llena, brilla y se apaga; suena una campana suave y sale «TOCA PARA EMPEZAR».
func _carga_lista() -> void:
	linea_alt.size.x = LINEA_ANCHO
	cifra.text = "100 %"
	punta.position = linea_alt.position + Vector2(LINEA_ANCHO - 20, -7)
	var tw := create_tween()
	tw.tween_property(linea_alt, "color", Color(1.0, 0.92, 0.7, 1.0), 0.25)
	tw.parallel().tween_property(punta, "modulate:a", 1.0, 0.25)
	tw.tween_property(linea_alt, "modulate:a", 0.0, 0.7)
	tw.parallel().tween_property(linea_fondo_alt, "modulate:a", 0.0, 0.7)
	tw.parallel().tween_property(punta, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(cifra, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(linea_alt, "position:x", 640.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(linea_alt, "size:x", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		if estado == "cargando":
			estado = "toca")
	tw.tween_property(toca, "modulate:a", 1.0, 0.6)
	destello_t = CADA_DESTELLO - 0.6                  # el primer destello del logo, enseguida
	var campana := AudioStreamPlayer.new()
	campana.stream = _campana()
	campana.bus = &"Interfaz"
	campana.volume_db = -10.0
	add_child(campana)
	campana.play()


# Campana suave hecha por código (sin archivos): do, sol y do agudo con un batido lento y una cola larga.
static func _campana() -> AudioStreamWAV:
	var hz := 22050
	var m := PackedFloat32Array()
	var parciales := [[523.25, 1.0], [784.0, 0.45], [1046.5, 0.3], [1569.0, 0.12]]
	for i in int(hz * 2.6):
		var t := float(i) / hz
		var env := minf(1.0, t * 80.0) * exp(-t * 1.7)
		var v := 0.0
		for p in parciales:
			v += p[1] * (sin(TAU * p[0] * t) + 0.5 * sin(TAU * (p[0] + 0.7) * t))
		m.append(v * env * 0.07)
	return M._wav(m, hz)


# ---------------------------------------------------------------- la canción del título (V12, 11/11)
# «REBELUM — When the World Forgets» la pone musica.gd (contexto «titulo»: una sola reproducción, bus Musica, sigue
# sin cortes de la carga al menú y funde al entrar en el juego). Aquí solo se siguen sus momentos para las luces:
# el logo respira con la introducción; al entrar el grupo (TITULO_ROCK) un destello del cristal y la escena se aviva;
# en la gran subida (TITULO_SUBIDA), un poco más. Todo suave y lejos de las opciones del menú. Si la canción no está
# (es privada: fuera de Git), todo sigue como antes.
var intensidad_cancion := 0.0
var _rock_visto := false
var _subida_vista := false
var _ultima_pos := -1.0


func _seguir_cancion(delta: float) -> void:
	var mu = get_node_or_null("/root/Musica")
	if mu == null or mu.contexto != "titulo":
		return
	var pos: float = mu.posicion_musica()
	if pos < 0.0:
		return
	if pos + 1.0 < _ultima_pos:                   # la canción ha vuelto a empezar (bucle): otra vez en calma
		_rock_visto = false
		_subida_vista = false
	_ultima_pos = pos
	var meta := 0.0
	if pos >= mu.TITULO_ROCK:
		meta = 0.6
		if not _rock_visto:
			_rock_visto = true
			fondo.set("destello", 1.0)
	if pos >= mu.TITULO_SUBIDA:
		meta = 1.0
		if not _subida_vista:
			_subida_vista = true
			fondo.set("destello", 0.7)
	intensidad_cancion = move_toward(intensidad_cancion, meta, delta * 0.5)
	fondo.set("intensidad", intensidad_cancion)
	if ambiente != null and ambiente.playing and tiempo > 4.5 and not ambiente.has_meta("bajado"):
		ambiente.set_meta("bajado", true)          # con la canción, el viento casi no se oye (no la ensucia)
		create_tween().tween_property(ambiente, "volume_db", -30.0, 3.0)


func _animar(delta: float) -> void:
	var t := tiempo
	_seguir_cancion(delta)
	aura.modulate.a = (0.11 + 0.06 * sin(t * 0.8) + 0.07 * intensidad_cancion) * logo.modulate.a
	if listo:
		destello_t += delta
		if destello_t >= CADA_DESTELLO:
			destello_t = 0.0
		mat_destello.set_shader_parameter("fase", lerpf(-0.7, 1.6, destello_t / 2.4) if destello_t < 2.4 else -1.0)
	if estado == "toca":
		toca.modulate.a = 0.5 + 0.4 * sin(t * 2.4)


# ================================================================= menú

func _abrir_menu() -> void:
	estado = "menu"
	menu_desde = tiempo
	if tween_frase != null and tween_frase.is_valid():
		tween_frase.kill()                          # la frase que estaba cambiando no vuelve a salir encima del menú
	Sonido.efecto("ui_abrir")
	var tw := create_tween()
	tw.tween_property(toca, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(frase_alt, "modulate:a", 0.0, 0.25)
	if botones_menu.is_empty():
		var opciones := []
		if load("res://progreso.gd").hay_partida():
			opciones.append(["continuar", "CONTINUAR"])
		opciones.append_array([["nueva", "NUEVA PARTIDA"], ["opciones", "OPCIONES"], ["creditos", "CRÉDITOS"]])
		for o in opciones:
			var b := _boton_menu(o[0], o[1])
			menu.add_child(b)
			botones_menu.append(b)
		_enlazar_foco()
	menu.visible = true
	fondo_menu.modulate.a = 0.0
	tw.parallel().tween_property(fondo_menu, "modulate:a", 1.0, 0.5)
	for i in botones_menu.size():
		var b: Button = botones_menu[i]
		b.modulate.a = 0.0
		tw.parallel().tween_property(b, "modulate:a", 1.0, 0.35).set_delay(0.12 + 0.07 * i)
	tw.parallel().tween_property(selector, "modulate:a", 1.0, 0.4).set_delay(0.2)
	for b in [boton_prologo, boton_prueba, boton_banco]:
		if b != null:
			b.visible = true
			tw.parallel().tween_property(b, "modulate:a", 1.0, 0.4).set_delay(0.4)
	if pruebas_titulo != null:
		pruebas_titulo.visible = true
	_enfocar(elegido if elegido != null and is_instance_valid(elegido) else botones_menu[0])


func _volver_a_toca() -> void:
	estado = "toca"
	Sonido.efecto("ui_atras")
	var f := get_viewport().gui_get_focus_owner()
	if f != null:
		f.release_focus()
	var tw := create_tween()
	for b in botones_menu:
		tw.parallel().tween_property(b, "modulate:a", 0.0, 0.2)
	tw.parallel().tween_property(selector, "modulate:a", 0.0, 0.2)
	tw.parallel().tween_property(fondo_menu, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(frase_alt, "modulate:a", 1.0, 0.4)
	for b in [boton_prologo, boton_prueba, boton_banco]:
		if b != null:
			tw.parallel().tween_property(b, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		if estado == "toca":
			menu.visible = false
			for b in [boton_prologo, boton_prueba, boton_banco]:
				if b != null:
					b.visible = false
			if pruebas_titulo != null:
				pruebas_titulo.visible = false)


# ↑ ↓ dan la vuelta en el menú; ← → llevan a los accesos de pruebas, y ↑ desde ellos vuelve al menú.
func _enlazar_foco() -> void:
	var n := botones_menu.size()
	for i in n:
		var b: Button = botones_menu[i]
		b.focus_neighbor_top = b.get_path_to(botones_menu[posmod(i - 1, n)])
		b.focus_neighbor_bottom = b.get_path_to(botones_menu[(i + 1) % n])
		b.focus_previous = b.focus_neighbor_top
		b.focus_next = b.focus_neighbor_bottom
		b.focus_neighbor_left = b.get_path_to(boton_prologo) if boton_prologo != null else NodePath(".")
		b.focus_neighbor_right = b.get_path_to(boton_prueba) if boton_prueba != null else NodePath(".")
	if boton_prologo != null and boton_prueba != null:
		for b in [boton_prologo, boton_prueba]:
			b.focus_neighbor_top = b.get_path_to(botones_menu[0])
			b.focus_neighbor_bottom = NodePath(".")
		boton_prologo.focus_neighbor_right = boton_prologo.get_path_to(boton_prueba)
		boton_prologo.focus_neighbor_left = NodePath(".")
		boton_prueba.focus_neighbor_left = boton_prueba.get_path_to(boton_prologo)
		boton_prueba.focus_neighbor_right = NodePath(".")
	if boton_banco != null and boton_prueba != null:  # V12 (14/11): → desde «Probar la misión» lleva al banco, y ↓ / ← vuelven
		boton_prueba.focus_neighbor_right = boton_prueba.get_path_to(boton_banco)
		boton_banco.focus_neighbor_bottom = boton_banco.get_path_to(boton_prueba)
		boton_banco.focus_neighbor_left = boton_banco.get_path_to(boton_prueba)
		boton_banco.focus_neighbor_top = NodePath(".")
		boton_banco.focus_neighbor_right = NodePath(".")


func _enfocar(b: Control) -> void:
	Entrada.enfocar(b)


# El selector (franja de luz y dos rombos) va al botón elegido, con el ratón, el dedo, el teclado o el mando.
func _seleccionar(b: Button) -> void:
	if not b in botones_menu:
		return
	var nuevo := b != elegido
	elegido = b
	await get_tree().process_frame                  # (recién creado, el contenedor aún no lo ha colocado)
	if not is_instance_valid(b) or elegido != b:
		return
	var centro := Vector2(640, b.global_position.y + b.size.y * 0.5)
	var ancho: float = fuente_menu.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if selector.modulate.a < 0.05 or not nuevo:
		selector.position = centro
	else:
		tw.tween_property(selector, "position", centro, 0.16)
	for i in rombos.size():
		var lado := -1 if i == 0 else 1
		tw.parallel().tween_property(rombos[i], "position:x", lado * (ancho * 0.5 + 24), 0.16)
	if nuevo and estado == "menu" and tiempo - menu_desde > 0.3:
		Sonido.efecto("ui_tic")


func _elegir(b: Button) -> void:
	if saliendo or estado != "menu" or tiempo - menu_desde < BLOQUEO_TOQUE:
		return
	_seleccionar(b)
	var destello_sel := create_tween()                # un golpe de luz discreto en la franja al elegir
	destello_sel.tween_property(selector_barra, "modulate:a", 1.0, 0.08)
	destello_sel.tween_property(selector_barra, "modulate:a", 0.5, 0.35)
	match String(b.get_meta("opcion")):
		"continuar":
			_empezar()
		"nueva":
			if load("res://progreso.gd").hay_partida():
				_abrir_confirmar()
			else:
				_empezar()                         # sin partida, carga.gd ya empieza una nueva (en el mapa, con el prólogo)
		"opciones":
			_abrir_opciones()
		"creditos":
			_abrir_creditos()


# Al salir hacia el juego: el ambiente se apaga con el fundido a negro de carga.gd.
func _empezar(prueba := false, prologo := false) -> void:
	if saliendo:
		return
	if ambiente != null:
		create_tween().tween_property(ambiente, "volume_db", -50.0, 0.6)
	super(prueba, prologo)


# ================================================================= ventanas sobre el menú

func _ventana_base(ancho: float, alto: float) -> VBoxContainer:
	var oscuro := ColorRect.new()
	oscuro.color = Color(0, 0, 0, 0.55)
	oscuro.size = Vector2(1280, 720)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Estilo.ventana(0.92))
	panel.position = Vector2(640 - ancho * 0.5, 360 - alto * 0.5)
	panel.custom_minimum_size = Vector2(ancho, alto)
	oscuro.add_child(panel)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	panel.add_child(caja)
	ventana = oscuro
	oscuro.modulate.a = 0.0
	capa_ventanas.add_child(oscuro)
	create_tween().tween_property(oscuro, "modulate:a", 1.0, 0.2)
	return caja


func _texto(t: String, tam: int, color: Color, cursiva := false) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if cursiva:
		l.add_theme_font_override("font", Estilo.cursiva())
	return l


func _boton_ventana(texto: String, clave: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.set_meta("clave", "portada:" + clave)
	b.custom_minimum_size = Vector2(240, 54)
	b.add_theme_font_size_override("font_size", 22)
	return b


# Nueva partida con una partida guardada: se pregunta, y por defecto el foco está en «Volver».
func _abrir_confirmar() -> void:
	estado = "confirmar"
	Sonido.efecto("ui_confirmar")
	var caja := _ventana_base(700, 270)
	caja.add_child(_texto("¿Empezar una partida nueva?", 30, M.ORO, true))
	caja.add_child(_texto("Ya hay una partida guardada. La nueva ocupará su lugar en cuanto el juego guarde. "
		+ "Antes se guarda aparte una copia de seguridad de la actual.", 20, M.LUZ_CLARA))
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 24)
	var volver := _boton_ventana("Volver", "volver")
	volver.pressed.connect(_cerrar_ventana)
	var si := _boton_ventana("Empezar de nuevo", "nueva_si")
	si.pressed.connect(_empezar_nueva)
	fila.add_child(volver)
	fila.add_child(si)
	caja.add_child(fila)
	Entrada.enfocar(volver)


func _abrir_creditos() -> void:
	estado = "creditos"
	Sonido.efecto("ui_confirmar")
	var caja := _ventana_base(820, 400)
	caja.add_child(_texto("Créditos", 32, M.ORO, true))
	caja.add_child(_texto("REBELUM · Cónclave de las Cenizas. Un juego en desarrollo.", 21, M.LUZ_CLARA))
	for linea_c in [
		"Motor: Godot Engine (licencia MIT). Diálogos: Dialogic (licencia MIT).",
		"Letras: Cormorant y Saira Condensed (SIL Open Font License).",
		"Ambientes: grabaciones CC0 de OpenGameArt. Efectos: paquetes GDC de Sonniss y bibliotecas CC0.",
		"Personajes 3D: modelos hechos con Meshy. Escenarios, monstruos y esta pantalla: hechos para el juego.",
		"Los créditos completos, con cada autor y licencia, están pendientes."]:
		caja.add_child(_texto(linea_c, 18, Color(M.LUZ_CLARA, 0.82)))
	var volver := _boton_ventana("Volver", "volver")
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(_cerrar_ventana)
	caja.add_child(volver)
	Entrada.enfocar(volver)


# Los Ajustes de siempre (menus.gd), solo con su pestaña de Ajustes: aquí aún no hay partida cargada.
func _abrir_opciones() -> void:
	estado = "opciones"
	var m = load("res://menus.gd").new()
	m.solo_ajustes = true
	m.pestana = "Ajustes"
	m.cerrado.connect(_al_cerrar_opciones)
	ventana = m
	capa_ventanas.add_child(m)


func _al_cerrar_opciones() -> void:
	ventana = null
	estado = "menu"
	menu_desde = tiempo - BLOQUEO_TOQUE * 0.5           # el toque de «Cerrar» no elige nada del menú
	_enfocar(elegido)


func _cerrar_ventana() -> void:
	if ventana == null or estado in ["menu", "opciones"]:
		return
	Sonido.efecto("ui_cerrar")
	var v := ventana
	ventana = null
	estado = "menu"
	menu_desde = tiempo - BLOQUEO_TOQUE * 0.5
	var tw := create_tween()
	tw.tween_property(v, "modulate:a", 0.0, 0.15)
	tw.tween_callback(v.queue_free)
	_enfocar(elegido)


# Partida nueva habiendo una guardada (confirmado): copia de seguridad de la actual y, después, lo mismo que hace
# progreso.cargar() cuando no hay archivo. Si la copia no se puede hacer, no se empieza nada.
func _empezar_nueva() -> void:
	if saliendo:
		return
	var P = load("res://progreso.gd")
	var copia := respaldar(P.archivo())
	if copia == "":
		Recursos.avisar("No se pudo hacer la copia de seguridad de la partida: no se empieza una nueva.")
		_cerrar_ventana()
		return
	print("Portada alternativa: copia de seguridad de la partida en ", copia)
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	if load("res://modo3d.gd").activo():               # la versión experimental empieza con la misión: Kael, solo
		load("res://grupo.gd").empezar_solo()
	if ambiente != null:
		create_tween().tween_property(ambiente, "volume_db", -50.0, 0.6)
	saliendo = true
	for b in [boton_prueba, boton_prologo]:
		if b != null:
			b.visible = false
	reproductor.stream = sonidos["confirmar"]
	reproductor.play()
	var negro := ColorRect.new()
	negro.color = Color(0, 0, 0, 0)
	negro.size = Vector2(1280, 720)
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	capa.add_child(negro)
	var t := create_tween()
	t.tween_property(negro, "color:a", 1.0, 0.6)
	await t.finished
	Recursos.cambiar_escena(SIGUIENTE)


# Copia aparte los archivos de la partida (principal, .bak y .tmp, los que haya) con la fecha en el nombre. Devuelve
# la ruta de la copia principal, o "" si algo falló.
static func respaldar(archivo: String) -> String:
	var sello := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var hecha := ""
	for extra in ["", ".bak", ".tmp"]:
		var origen: String = archivo + str(extra)
		if not FileAccess.file_exists(origen):
			continue
		var destino: String = "%s.antes_de_nueva_%s%s" % [archivo, sello, extra]
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(origen), ProjectSettings.globalize_path(destino)) != OK \
				or FileAccess.get_file_as_string(destino) != FileAccess.get_file_as_string(origen):
			return ""
		if hecha == "":
			hecha = destino
	return hecha


# ================================================================= entrada

func _input(ev: InputEvent) -> void:
	if saliendo:
		return
	match estado:
		"toca":
			if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed) \
					or ev.is_action_pressed("ui_accept"):
				get_viewport().set_input_as_handled()
				reproductor.stream = sonidos["confirmar"]
				reproductor.play()
				_abrir_menu()
		"menu":
			if ev.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				_volver_a_toca()
		"confirmar", "creditos":
			if ev.is_action_pressed("ui_cancel"):
				get_viewport().set_input_as_handled()
				_cerrar_ventana()


# V12 (14/11): entra en el banco de pruebas de Auditoría, sin cargar la partida de siempre (el banco usa la suya).
func _abrir_banco() -> void:
	if saliendo or estado != "menu":
		return
	saliendo = true
	Sonido.efecto("ui_tic")
	Recursos.cambiar_escena("res://banco_pruebas.tscn")
