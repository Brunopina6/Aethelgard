extends Control
# PRUEBA (no destructiva) de la pantalla de título de REBELUM. NO sustituye el arranque del juego (carga.tscn).
# Abrir: prototipos/titulo_rebelum.tscn (F6). Estilo según docs/marca_rebelum.md:
#   noche añil con estrellas que titilan y niebla violeta; el logo fundido con el fondo y un brillo que respira;
#   motas de luz doradas y lilas que suben; pétalos de cristal que cruzan; menú con paneles añil y borde dorado.

const LOGO := "res://marca/rebelum_logo.webp"
const AÑIL := Color("0b0c26")
const INDIGO := Color("1d1b4d")
const VIOLETA := Color("6e4bd8")
const LAVANDA := Color("b9a6f5")
const ORO := Color("f2c86b")
const MARFIL := Color("fff6e3")

const SHADER_CIELO := """
shader_type canvas_item;
uniform vec4 arriba : source_color;
uniform vec4 medio : source_color;
uniform vec4 niebla : source_color;
float azar(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	vec3 c = mix(arriba.rgb, medio.rgb, smoothstep(0.0, 0.75, uv.y));
	// estrellas que titilan
	vec2 celda = floor(uv * vec2(160.0, 90.0));
	float r = azar(celda);
	if (r > 0.985) {
		vec2 f = fract(uv * vec2(160.0, 90.0)) - 0.5;
		float brillo = (0.5 + 0.5 * sin(TIME * (1.0 + r * 3.0) + r * 40.0)) * smoothstep(0.18, 0.0, length(f));
		c += vec3(0.9, 0.9, 1.0) * brillo * (1.0 - uv.y);
	}
	// niebla violeta abajo que se mueve despacio
	float n = 0.5 + 0.5 * sin(uv.x * 6.0 + TIME * 0.15) * sin(uv.x * 2.3 - TIME * 0.1 + uv.y * 4.0);
	c = mix(c, niebla.rgb, smoothstep(0.55, 1.0, uv.y) * (0.45 + 0.25 * n));
	COLOR = vec4(c, 1.0);
}
"""
# El logo trae su propio fondo oscuro: se funde con el cielo apagando sus bordes poco a poco.
const SHADER_LOGO := """
shader_type canvas_item;
uniform float pulso = 0.0;
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec2 d = (UV - 0.5) * vec2(1.0, 1.25);
	float borde = 1.0 - smoothstep(0.32, 0.52, length(d));
	float luz = max(max(t.r, t.g), t.b);
	COLOR = vec4(t.rgb * (1.0 + pulso * 0.12 * luz), t.a * borde);
}
"""

var logo: TextureRect
var mensaje: Label
var t := 0.0


func _ready() -> void:
	size = Vector2(1280, 720)
	var cielo := ColorRect.new()
	cielo.size = size
	var mc := ShaderMaterial.new()
	mc.shader = Shader.new()
	mc.shader.code = SHADER_CIELO
	mc.set_shader_parameter("arriba", AÑIL)
	mc.set_shader_parameter("medio", INDIGO)
	mc.set_shader_parameter("niebla", Color(0.32, 0.22, 0.55))
	cielo.material = mc
	add_child(cielo)
	add_child(_motas(Vector2(640, 760), Vector2(640, 40), 70, [ORO, LAVANDA], Vector2(0, -1), 30.0, 3.0))
	if ResourceLoader.exists(LOGO):
		logo = TextureRect.new()
		logo.texture = load(LOGO)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.size = Vector2(820, 560)
		logo.position = Vector2(640 - 410, -10)
		var ml := ShaderMaterial.new()
		ml.shader = Shader.new()
		ml.shader.code = SHADER_LOGO
		logo.material = ml
		logo.modulate.a = 0.0
		add_child(logo)
		create_tween().tween_property(logo, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE)
	add_child(_motas(Vector2(1320, 260), Vector2(10, 220), 9, [Color(0.85, 0.82, 1.0), Color(0.95, 0.9, 1.0)], Vector2(-1, 0.25), 60.0, 9.0, true))
	_menu()
	var version := _texto("Prueba de pantalla de título · REBELUM", 16, Color(LAVANDA, 0.6))
	version.position = Vector2(24, 688)
	add_child(version)


func _texto(s: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	if ResourceLoader.exists("res://menu_combate.gd"):
		var mc = load("res://menu_combate.gd")
		var f = mc.fuente(mc.FUENTE_NOMBRE, 0, 600)
		if f != null:
			l.add_theme_font_override("font", f)
	return l


func _menu() -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	caja.position = Vector2(640 - 170, 520)
	caja.custom_minimum_size = Vector2(340, 0)
	add_child(caja)
	for datos in [["Nueva partida", _nueva], ["Explorar Pastos Verdes (3D)", _pastos], ["Opciones", _opciones]]:
		var b := Button.new()
		b.text = datos[0]
		b.custom_minimum_size = Vector2(340, 52)
		b.focus_mode = Control.FOCUS_ALL
		for estado in ["normal", "hover", "pressed", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(AÑIL, 0.72) if estado == "normal" else Color(INDIGO, 0.9)
			sb.border_color = Color(ORO, 0.55) if estado == "normal" else ORO
			sb.set_border_width_all(1 if estado == "normal" else 2)
			sb.set_corner_radius_all(8)
			sb.shadow_color = Color(VIOLETA, 0.35)
			sb.shadow_size = 0 if estado == "normal" else 10
			b.add_theme_stylebox_override(estado, sb)
		b.add_theme_color_override("font_color", MARFIL)
		b.add_theme_color_override("font_hover_color", ORO)
		b.add_theme_font_size_override("font_size", 22)
		if ResourceLoader.exists("res://menu_combate.gd"):
			var mc = load("res://menu_combate.gd")
			var f = mc.fuente(mc.FUENTE_NOMBRE, 0, 600)
			if f != null:
				b.add_theme_font_override("font", f)
		b.pressed.connect(datos[1])
		caja.add_child(b)
	mensaje = _texto("", 18, LAVANDA)
	mensaje.position = Vector2(0, 690)
	mensaje.size = Vector2(1280, 24)
	mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mensaje)


func _nueva() -> void:
	mensaje.text = "Maqueta: «Nueva partida» aún no está conectada (el juego sigue arrancando como siempre)."


func _opciones() -> void:
	mensaje.text = "Maqueta: las opciones llegarán con los perfiles de calidad."


func _pastos() -> void:
	get_tree().change_scene_to_file("res://prototipos/sendero_puente.tscn")


func _process(d: float) -> void:
	t += d
	if logo != null and logo.material != null:
		logo.material.set_shader_parameter("pulso", 0.5 + 0.5 * sin(t * 1.6))


# Motas de luz (o pétalos de cristal) que suben o cruzan despacio.
func _motas(pos: Vector2, caja: Vector2, n: int, colores: Array, dir: Vector2, vel: float, vida: float, petalo := false) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = n
	p.lifetime = vida
	p.preprocess = vida
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = caja
	p.direction = dir
	p.spread = 25.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vel * 0.6
	p.initial_velocity_max = vel
	p.angular_velocity_min = -40.0 if petalo else 0.0
	p.angular_velocity_max = 40.0 if petalo else 0.0
	p.scale_amount_min = 0.25 if not petalo else 0.35
	p.scale_amount_max = 0.7 if not petalo else 0.6
	var g := Gradient.new()
	var c0: Color = colores[0]
	var c1: Color = colores[1]
	g.colors = PackedColorArray([Color(c0, 0.0), Color(c0, 0.9), Color(c1, 0.7), Color(c1, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
	p.color_ramp = g
	var tex := GradientTexture2D.new()
	var gg := Gradient.new()
	gg.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	tex.gradient = gg
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 32 if not petalo else 64                 # textura a tamaño real (sin ampliar: nada pixelado)
	tex.height = 32 if not petalo else 24
	p.texture = tex
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = m
	return p
