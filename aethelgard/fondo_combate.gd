extends Node2D
# Fondo del combate según la zona (Godot 4.x)
# Cielo, sol, nubes, montes lejanos con niebla, árboles, suelo en perspectiva y hierba que se mece.
# Reutiliza las texturas y dibujos de zona.gd (guardados en caché), así que gasta muy poca memoria:
# no carga ninguna imagen grande. combate.gd lo crea con construir(zona).

const HORIZONTE := 300.0          # altura del horizonte en pantalla

# cielo = [arriba, horizonte]; montes = [lejanos, cercanos]; luz = color del sol sobre el suelo y los
# modelos 3D; tono = cómo tiñe a los luchadores; arboles = dibujo de zona.gd para el fondo.
const FONDOS := {
	"llanura": {"cielo": [Color(0.32, 0.56, 0.9), Color(0.82, 0.9, 0.98)], "montes": [Color(0.5, 0.64, 0.84), Color(0.3, 0.52, 0.32)],
		"suelo": "hierba", "arboles": "abedul", "lejanos": 14, "laterales": 2, "hierba": 420, "sol": Vector2(1000, 80),
		"color_sol": Color(1.0, 0.95, 0.8), "niebla": Color(0.78, 0.88, 0.95), "luz": Color(1.0, 0.97, 0.9),
		"tono": Color(1, 1, 1), "nubes": 5, "clima": "", "picos": false},
	"bosque": {"cielo": [Color(0.26, 0.46, 0.42), Color(0.66, 0.8, 0.62)], "montes": [Color(0.32, 0.48, 0.42), Color(0.12, 0.28, 0.16)],
		"suelo": "hierba_oscura", "arboles": "arce", "lejanos": 24, "laterales": 3, "hierba": 320, "sol": Vector2(880, 30),
		"color_sol": Color(1.0, 0.95, 0.7), "niebla": Color(0.56, 0.7, 0.56), "luz": Color(0.92, 1.0, 0.86),
		"tono": Color(0.9, 0.97, 0.9), "nubes": 0, "clima": "", "picos": false, "rayos": true},
	"montana": {"cielo": [Color(0.38, 0.54, 0.8), Color(0.86, 0.89, 0.93)], "montes": [Color(0.66, 0.71, 0.8), Color(0.4, 0.42, 0.46)],
		"suelo": "grava", "arboles": "q_pino#2", "lejanos": 10, "laterales": 0, "hierba": 0, "sol": Vector2(300, 80),
		"color_sol": Color(1.0, 0.97, 0.9), "niebla": Color(0.82, 0.86, 0.9), "luz": Color(1.0, 0.98, 0.95),
		"tono": Color(0.96, 0.98, 1.0), "nubes": 4, "clima": "", "picos": true},
	"nieve": {"cielo": [Color(0.52, 0.62, 0.8), Color(0.9, 0.93, 0.97)], "montes": [Color(0.8, 0.85, 0.93), Color(0.68, 0.74, 0.86)],
		"suelo": "nieve", "arboles": "pino_nevado", "lejanos": 14, "laterales": 2, "hierba": 0, "sol": Vector2(1000, 110),
		"color_sol": Color(0.9, 0.95, 1.0), "niebla": Color(0.88, 0.9, 0.96), "luz": Color(0.92, 0.96, 1.05),
		"tono": Color(0.92, 0.96, 1.05), "nubes": 3, "clima": "nieve", "picos": true},
	"desierto": {"cielo": [Color(0.34, 0.54, 0.86), Color(0.98, 0.88, 0.7)], "montes": [Color(0.86, 0.7, 0.56), Color(0.78, 0.58, 0.38)],
		"suelo": "arena", "arboles": "roca_arenisca", "lejanos": 6, "laterales": 0, "hierba": 0, "sol": Vector2(640, 70),
		"color_sol": Color(1.0, 0.92, 0.7), "niebla": Color(0.96, 0.86, 0.7), "luz": Color(1.05, 1.0, 0.9),
		"tono": Color(1.04, 1.0, 0.93), "nubes": 2, "clima": "", "picos": false},
	"yermo": {"cielo": [Color(0.1, 0.07, 0.18), Color(0.44, 0.3, 0.5)], "montes": [Color(0.3, 0.2, 0.38), Color(0.17, 0.11, 0.21)],
		"suelo": "tierra_morada", "arboles": "q_seco#1", "lejanos": 10, "laterales": 0, "hierba": 0, "sol": Vector2(860, 100),
		"color_sol": Color(0.85, 0.7, 1.0), "niebla": Color(0.4, 0.28, 0.45), "luz": Color(0.85, 0.78, 1.0),
		"tono": Color(0.86, 0.8, 1.0), "nubes": 0, "clima": "motas", "picos": true},
	"ceniza": {"cielo": [Color(0.1, 0.04, 0.04), Color(0.55, 0.2, 0.1)], "montes": [Color(0.3, 0.12, 0.08), Color(0.11, 0.07, 0.07)],
		"suelo": "ceniza", "arboles": "q_seco#4", "lejanos": 8, "laterales": 0, "hierba": 0, "sol": Vector2(700, 160),
		"color_sol": Color(1.0, 0.4, 0.2), "niebla": Color(0.45, 0.2, 0.12), "luz": Color(1.05, 0.8, 0.7),
		"tono": Color(1.04, 0.88, 0.82), "nubes": 0, "clima": "ceniza", "picos": true},
	"ciudad": {"cielo": [Color(0.16, 0.16, 0.36), Color(0.88, 0.58, 0.46)], "montes": [Color(0.32, 0.26, 0.42), Color(0.2, 0.17, 0.27)],
		"suelo": "empedrado", "arboles": "cerezo", "lejanos": 6, "laterales": 1, "hierba": 0, "sol": Vector2(1100, 250),
		"color_sol": Color(1.0, 0.6, 0.35), "niebla": Color(0.72, 0.52, 0.5), "luz": Color(1.0, 0.86, 0.78),
		"tono": Color(1.0, 0.92, 0.9), "nubes": 3, "clima": "", "picos": false},
}

const SHADER_SUELO := """
shader_type canvas_item;
uniform sampler2D suelo : repeat_enable, filter_linear_mipmap;
uniform vec4 niebla : source_color;
uniform vec4 luz : source_color;
uniform float alto = 420.0;
void fragment() {
	float s = (UV.y * alto + 3.0) / alto;          // 0 en el horizonte, 1 abajo
	float z = 1.0 / s;
	vec2 p = vec2((UV.x - 0.5) * 1280.0 / 260.0 * z, z * 1.6);
	vec3 c = texture(suelo, p).rgb * luz.rgb;
	float foco = exp(-pow((UV.x - 0.55) * 1.7, 2.0)) * smoothstep(0.15, 0.6, s);   // más luz donde pelean
	c *= 0.8 + 0.3 * foco;
	COLOR = vec4(mix(niebla.rgb, c, smoothstep(0.0, 0.22, s)), 1.0);
}
"""

var datos: Dictionary
var luz_3d := Color(1.0, 0.8, 0.6)       # para las luces de los modelos 3D
var relleno_3d := Color(0.55, 0.6, 1.0)
var tono := Color(1, 1, 1)
var glow: GradientTexture2D


func construir(zona: String) -> void:
	if zona == "garganta":                        # la mazmorra de la Garganta usa el fondo de montaña
		zona = "montana"
	datos = FONDOS.get(zona, FONDOS["llanura"])
	luz_3d = datos["luz"]
	relleno_3d = datos["cielo"][0].lightened(0.2)
	tono = datos["tono"]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	glow = GradientTexture2D.new()
	glow.gradient = g
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	glow.width = 128
	glow.height = 128

	var z = load("res://zona.gd").new()           # solo para usar sus texturas y dibujos (no se añade a la escena)
	_cielo()
	_sol()
	_nubes()
	_montes(HORIZONTE - 80.0, 70.0, datos["montes"][0], 0.012, 3, 0.45)
	_montes(HORIZONTE - 28.0, 34.0, datos["montes"][1], 0.02, 7, 0.2)
	_arboles_lejanos(z)
	_banda_niebla()
	_suelo(z)
	_hierba(z)
	_laterales(z)
	_clima()
	z.free()


func _cielo() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([datos["cielo"][0], datos["cielo"][1]])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 4
	t.height = 128
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = Vector2(1280, HORIZONTE + 10)
	add_child(r)


func _brillo(pos: Vector2, color: Color, tam: float, aditivo := true) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = glow
	s.position = pos
	s.scale = Vector2(tam, tam)
	s.modulate = color
	if aditivo:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		s.material = m
	add_child(s)
	return s


func _sol() -> void:
	var c: Color = datos["color_sol"]
	_brillo(datos["sol"], Color(c, 0.25), 6.0)
	_brillo(datos["sol"], Color(c, 0.6), 1.6)
	_brillo(datos["sol"], Color(1, 1, 1, 0.9), 0.45)
	if datos.get("rayos", false):                  # rayos de sol entre las copas
		for i in 5:
			var r := _brillo(datos["sol"] + Vector2(-260 + i * 120, 220), Color(c, 0.0), 1.0)
			r.scale = Vector2(0.9, 6.0)
			r.rotation_degrees = 20.0 + i * 3.0
			var t := create_tween().set_loops()
			t.tween_property(r, "modulate:a", 0.12, 3.0 + i * 0.4)
			t.tween_property(r, "modulate:a", 0.03, 3.0 + i * 0.4)


func _nubes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in datos["nubes"]:
		var nube := Node2D.new()
		nube.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(40, HORIZONTE - 120))
		add_child(nube)
		for b in 6:
			var s := Sprite2D.new()
			s.texture = glow
			s.position = Vector2(rng.randf_range(-90, 90), rng.randf_range(-14, 14))
			s.scale = Vector2(rng.randf_range(1.1, 1.8), rng.randf_range(0.6, 0.9))
			s.modulate = Color(1, 1, 1, 0.35)
			nube.add_child(s)
		var t := create_tween().set_loops()
		t.tween_property(nube, "position:x", nube.position.x + 120.0, rng.randf_range(40.0, 70.0))
		t.tween_property(nube, "position:x", nube.position.x, rng.randf_range(40.0, 70.0))


# Montes: línea irregular con niebla abajo (los lejanos casi del color del cielo).
func _montes(base: float, amp: float, color: Color, frec: float, sem: int, niebla_k: float) -> void:
	var r := FastNoiseLite.new()
	r.seed = sem
	r.frequency = frec
	var puntos := PackedVector2Array()
	var colores := PackedColorArray()
	var arriba := color.lerp(datos["niebla"], niebla_k)
	var abajo := color.lerp(datos["niebla"], niebla_k + 0.35)
	for i in 81:
		var x := i * 16.0
		var n := r.get_noise_1d(x)
		if datos["picos"]:
			n = 1.0 - absf(n) * 2.2                   # crestas afiladas
		puntos.append(Vector2(x, base - n * amp))
		colores.append(arriba)
	puntos.append(Vector2(1280, HORIZONTE + 6))
	colores.append(abajo)
	puntos.append(Vector2(0, HORIZONTE + 6))
	colores.append(abajo)
	var p := Polygon2D.new()
	p.polygon = puntos
	p.vertex_colors = colores
	add_child(p)


func _arboles_lejanos(z) -> void:
	var tipo: String = datos["arboles"]
	var d: Dictionary = z._objeto(tipo)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var tinte: Color = Color(1, 1, 1).lerp(datos["niebla"], 0.55)
	var lista: Array = []
	for i in datos["lejanos"]:
		lista.append(Vector2(rng.randf_range(-40, 1320), HORIZONTE + rng.randf_range(-6, 12)))
	lista.sort_custom(func(a, b): return a.y < b.y)
	for p: Vector2 in lista:
		var s := Sprite2D.new()
		s.texture = d["tex"]
		s.centered = false
		s.offset = -d["origen"]
		s.position = p
		var e: float = rng.randf_range(0.22, 0.38) * (1.0 + (p.y - HORIZONTE) / 60.0) * d.get("escala", 1.0)
		s.scale = Vector2(e * (1.0 if rng.randf() < 0.5 else -1.0), e)
		s.modulate = tinte
		add_child(s)


func _banda_niebla() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	var n: Color = datos["niebla"]
	g.colors = PackedColorArray([Color(n, 0.0), Color(n, 0.4), Color(n, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 4
	t.height = 64
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = Vector2(0, HORIZONTE - 70)
	r.size = Vector2(1280, 90)
	add_child(r)


# Suelo en perspectiva: la textura de la zona se repite hasta el horizonte y se funde con la niebla.
func _suelo(z) -> void:
	var nombre: String = datos["suelo"]
	var img: Image = z._cargar_cache("suelo_" + nombre, z._textura.bind(nombre, 256))
	img.generate_mipmaps()
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER_SUELO
	mat.set_shader_parameter("suelo", ImageTexture.create_from_image(img))
	mat.set_shader_parameter("niebla", datos["niebla"])
	mat.set_shader_parameter("luz", datos["luz"])
	mat.set_shader_parameter("alto", 720.0 - HORIZONTE)
	var r := ColorRect.new()
	r.position = Vector2(0, HORIZONTE)
	r.size = Vector2(1280, 720.0 - HORIZONTE)
	r.material = mat
	add_child(r)


# Matas de hierba sobre el suelo: más pequeñas y neblinosas cuanto más lejos.
func _hierba(z) -> void:
	var cuantas: int = datos["hierba"]
	if cuantas <= 0:
		return
	var mat: ShaderMaterial = z.material_hierba()       # misma foto y shader que en las zonas
	var tex: Texture2D = z.matas_tex
	var foto: bool = ResourceLoader.exists(z.TEXTURA_HIERBA)
	RenderingServer.global_shader_parameter_set("jugador_pos", Vector2(-9999, -9999))   # aquí nadie aparta la hierba
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var pos: Array = []
	for i in cuantas:
		var s := pow(rng.randf(), 0.7)                # más matas cerca
		pos.append(Vector2(rng.randf_range(-20, 1300), HORIZONTE + 8.0 + s * (720.0 - HORIZONTE)))
	pos.sort_custom(func(a, b): return a.y < b.y)
	var malla: ArrayMesh = z.malla_hierba()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = malla
	mm.instance_count = pos.size()
	for i in pos.size():
		var p: Vector2 = pos[i]
		var s := (p.y - HORIZONTE) / (720.0 - HORIZONTE)
		var e := 0.2 + s * 1.2
		mm.set_instance_transform_2d(i, Transform2D(0.0, Vector2(e, e), 0.0, p))
		mm.set_instance_color(i, Color(datos["luz"]).lerp(datos["niebla"], (1.0 - s) * 0.6).darkened(rng.randf_range(0.0, 0.2)))
		var variante := 0 if foto else (3 if rng.randf() < 0.12 else rng.randi_range(0, 2))
		mm.set_instance_custom_data(i, Color(variante, p.x, p.y, rng.randf() * TAU))
	var h := MultiMeshInstance2D.new()
	h.multimesh = mm
	h.texture = tex
	h.material = mat
	h.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(h)


# Árboles grandes en los bordes, que enmarcan la escena.
func _laterales(z) -> void:
	var n: int = datos["laterales"]
	if n <= 0:
		return
	var d: Dictionary = z._objeto(datos["arboles"])
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = z.SHADER_VIENTO
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for lado in [-1, 1]:
		for i in n:
			var s := Sprite2D.new()
			s.texture = d["tex"]
			s.centered = false
			s.offset = -d["origen"]
			var x := (rng.randf_range(-70, 40) + i * 55.0) if lado < 0 else (1280.0 - rng.randf_range(-70, 40) - i * 55.0)
			s.position = Vector2(x, HORIZONTE + 120.0 + i * 40.0 + rng.randf_range(0, 30))
			var e: float = (rng.randf_range(0.9, 1.15) + i * 0.1) * d.get("escala", 1.0)
			s.scale = Vector2(e * lado, e)
			s.modulate = Color(0.85, 0.85, 0.85)
			s.material = mat
			add_child(s)


func _clima() -> void:
	var tipo: String = datos["clima"]
	if tipo == "":
		return
	var p := CPUParticles2D.new()
	p.texture = glow
	p.position = Vector2(640, 300)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 380)
	p.amount = 60 if OS.has_feature("mobile") else 90   # móvil: como mucho 60 partículas a la vez
	p.lifetime = 6.0
	p.preprocess = 6.0
	var c1 := Color(1, 1, 1, 0.8)
	match tipo:
		"nieve":
			p.gravity = Vector2(12, 50)
			p.scale_amount_min = 0.03
			p.scale_amount_max = 0.07
		"ceniza":
			p.gravity = Vector2(8, -14)
			p.scale_amount_min = 0.03
			p.scale_amount_max = 0.06
			c1 = Color(1.0, 0.55, 0.2, 0.9)
		"motas":
			p.gravity = Vector2(0, -10)
			p.scale_amount_min = 0.03
			p.scale_amount_max = 0.06
			c1 = Color(0.8, 0.5, 1.0, 0.9)
	if tipo != "nieve":
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = m
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	g.colors = PackedColorArray([Color(c1, 0.0), c1, Color(c1, 0.0)])
	p.color_ramp = g
	add_child(p)
