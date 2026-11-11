extends Node2D
# El entorno de la pantalla de inicio alternativa (portada/inicio_alternativo.gd, encargo del 11/11). Todo está hecho
# por código para este juego, sin imágenes de terceros ni archivos de arte nuevos (procedencia en docs/recursos.md):
#   1. Cielo (un solo sombreador a pantalla completa): degradado nocturno violeta y azul, nebulosa lenta, estrellas que
#      titilan, dos cordilleras lejanas y la luz mágica: el haz de un cristal en lo alto de una aguja, al fondo.
#   2. Fortalezas en ruinas (polígonos generados aquí): un torreón sobre un risco a la izquierda y, a la derecha, la
#      ciudadela de la aguja con su acueducto roto. Con niebla hacia la base y la luz del cristal en lo cercano.
#   3. Niebla baja que se mueve despacio por delante de las fortalezas.
#   4. Primer plano casi negro (una columna rota, un arco partido y escombros) que enmarca y da profundidad.
#   5. Ventanas con luz dorada, el cristal con su halo y partículas: brasas que suben, ceniza que cae y chispas mágicas.
# Paralaje suave: cada capa se desplaza un poco con el tiempo, más cuanto más cerca. Pensado para el Redmi (Mali-G57,
# Compatibility): un sombreador de pantalla completa barato (ruido de valor, 3 octavas), tres capas de polígonos y
# partículas por CPU en poca cantidad. El diseño está hecho para 1280×720, el lienzo del juego.

const ANCHO := 1280.0
const ALTO := 720.0
const CRISTAL := Vector2(1080, 262)          # la luz mágica, en lo alto de la aguja (capa media)

# Cuánto se mueve cada capa (px) con el paralaje. El cielo mueve sus cordilleras por dentro (uniformes).
const MUEVE_LEJOS := 3.0
const MUEVE_MEDIO := 7.0
const MUEVE_NIEBLA := 10.0
const MUEVE_CERCA := 16.0

const SH_CIELO := """
shader_type canvas_item;
uniform vec2 faro = vec2(0.844, 0.364);
uniform vec2 desp_lejos = vec2(0.0);
uniform vec2 desp_medio = vec2(0.0);
uniform float intensidad_faro = 1.0;

float hash(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm3(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 3; i++) { v += a * ruido(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; } return v; }
float ruido1(float x) { float i = floor(x); float f = fract(x); f = f * f * (3.0 - 2.0 * f); return mix(hash(vec2(i, 0.0)), hash(vec2(i + 1.0, 0.0)), f); }
float cresta(float x) { float v = 0.0; float a = 0.5; for (int i = 0; i < 4; i++) { v += a * ruido1(x); x = x * 2.1 + 3.7; a *= 0.5; } return v; }

void fragment() {
	vec2 uv = UV;
	float aspecto = 1280.0 / 720.0;
	float y = uv.y;
	vec3 cenit = vec3(0.016, 0.018, 0.05);
	vec3 medio = vec3(0.075, 0.05, 0.16);
	vec3 horiz = vec3(0.27, 0.15, 0.33);
	vec3 col = mix(cenit, medio, smoothstep(0.0, 0.5, y));
	col = mix(col, horiz, smoothstep(0.42, 0.7, y));
	// halo del cristal: azul cerca y un poso dorado más amplio en el horizonte
	vec2 d = (uv - faro) * vec2(aspecto, 1.0);
	float dist = length(d);
	col += vec3(0.9, 0.62, 0.3) * 0.09 * exp(-dist * 2.6) * smoothstep(0.2, 0.6, y);
	col += vec3(0.42, 0.52, 1.0) * 0.20 * exp(-dist * 6.0) * intensidad_faro;
	// nebulosa: jirones lentos, violeta a la izquierda y azul a la derecha
	vec2 q = vec2(uv.x * aspecto, y) * 2.0 + vec2(TIME * 0.006, 0.0);
	float n = fbm3(q + vec2(ruido(q * 0.8 + TIME * 0.01), 0.0) * 0.9);
	float banda = smoothstep(0.0, 0.3, y) * (1.0 - smoothstep(0.5, 0.68, y));
	col += mix(vec3(0.20, 0.10, 0.34), vec3(0.11, 0.17, 0.40), uv.x) * smoothstep(0.38, 0.85, n) * 0.95 * banda;
	// estrellas: pocas, en lo alto, cada una con su ritmo
	vec2 sg = uv * vec2(aspecto, 1.0) * 70.0;
	vec2 celda = floor(sg);
	float h = hash(celda);
	if (h > 0.955) {
		vec2 sitio = vec2(hash(celda + 3.1), hash(celda + 7.7)) - 0.5;
		float r = length(fract(sg) - 0.5 - sitio * 0.6);
		float titila = 0.55 + 0.45 * sin(TIME * (0.7 + h * 2.5) + h * 40.0);
		float brillo = smoothstep(0.13, 0.0, r) * titila * (1.0 - smoothstep(0.3, 0.58, y)) * (0.35 + (h - 0.955) * 14.0);
		col += mix(vec3(0.8, 0.84, 1.0), vec3(1.0, 0.88, 0.7), step(0.985, h)) * brillo;
	}
	// el haz del cristal, hacia el cielo, que respira despacio
	float bx = abs((uv.x - faro.x) * aspecto);
	float arriba = 1.0 - smoothstep(faro.y - 0.01, faro.y + 0.01, y);
	float vida = 0.82 + 0.12 * sin(TIME * 0.9) + 0.10 * ruido(vec2(y * 7.0 - TIME * 0.35, 1.3));
	float sube = smoothstep(-0.15, faro.y, y);
	col += vec3(0.55, 0.70, 1.0) * exp(-bx * bx * 1400.0) * sube * arriba * 0.55 * vida * intensidad_faro;
	col += vec3(0.50, 0.42, 1.0) * exp(-bx * bx * 70.0) * sube * arriba * 0.07 * vida * intensidad_faro;
	// cordillera lejana y otra más cerca, con la niebla en su falda
	float x1 = (uv.x + desp_lejos.x) * aspecto * 2.4;
	float m1 = 0.57 - cresta(x1 + 3.0) * 0.15 + desp_lejos.y;
	float a1 = smoothstep(m1, m1 + 0.003, y);
	vec3 c1 = mix(vec3(0.17, 0.11, 0.27), vec3(0.24, 0.16, 0.33), smoothstep(m1, m1 + 0.12, y));
	col = mix(col, c1, a1);
	float x2 = (uv.x + desp_medio.x) * aspecto * 1.7;
	float m2 = 0.665 - cresta(x2 + 11.0) * 0.13 + desp_medio.y;
	float a2 = smoothstep(m2, m2 + 0.003, y);
	vec3 c2 = mix(vec3(0.075, 0.05, 0.14), vec3(0.15, 0.10, 0.24), smoothstep(m2, m2 + 0.2, y));
	col = mix(col, c2, a2);
	// el haz ilumina un poco las crestas que tiene delante
	col += vec3(0.25, 0.30, 0.6) * 0.18 * exp(-dist * 7.0) * max(a1, a2);
	COLOR = vec4(col, 1.0);
}
"""

# Fortalezas de la capa media: color de silueta, niebla hacia la base y la luz del cristal cerca de él.
const SH_RUINAS := """
shader_type canvas_item;
uniform vec2 cristal = vec2(1080.0, 262.0);
uniform vec3 color_alto = vec3(0.05, 0.036, 0.095);
uniform vec3 color_bajo = vec3(0.15, 0.10, 0.23);
uniform float base_alta = 380.0;
uniform float base_baja = 640.0;
uniform float luz = 1.0;
varying vec2 pos;
void vertex() { pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	float f = smoothstep(base_alta, base_baja, pos.y);
	vec3 col = mix(color_alto, color_bajo, f);
	float d = length(pos - cristal);
	col += vec3(0.22, 0.28, 0.55) * exp(-d / 150.0) * 0.6 * luz;
	col += vec3(0.5, 0.35, 0.15) * exp(-d / 60.0) * 0.25 * luz;
	COLOR = vec4(col, 1.0);
}
"""

const SH_NIEBLA := """
shader_type canvas_item;
uniform vec3 color = vec3(0.34, 0.27, 0.52);
uniform float fuerza = 0.30;
float hash(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 p = UV * vec2(5.0, 2.2);
	float n = 0.65 * ruido(p + vec2(TIME * 0.025, 0.0)) + 0.35 * ruido(p * 2.3 + vec2(-TIME * 0.04, TIME * 0.01));
	float perfil = smoothstep(0.0, 0.45, UV.y) * (1.0 - smoothstep(0.7, 1.0, UV.y));
	COLOR = vec4(color, fuerza * perfil * smoothstep(0.25, 0.85, n));
}
"""

var cielo: ColorRect
var mat_cielo: ShaderMaterial
var capa_medio: Node2D
var capa_niebla: Node2D
var capa_cerca: Node2D
var mat_ruinas: ShaderMaterial
var mat_cerca: ShaderMaterial
var ventanas: Array = []                    # [nodo, fase]
var halo_cristal: Sprite2D
var nucleo_cristal: Sprite2D
var tiempo := 0.0
var brillo: GradientTexture2D
var intensidad := 0.0                    # 0 en calma, 1 con el rock de la canción del título (inicio_alternativo.gd)
var destello := 0.0                      # un golpe de luz que se apaga solo (al entrar el rock)


func _ready() -> void:
	brillo = textura_brillo()
	cielo = ColorRect.new()
	cielo.size = Vector2(ANCHO, ALTO)
	cielo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat_cielo = _material(SH_CIELO)
	mat_cielo.set_shader_parameter("faro", CRISTAL / Vector2(ANCHO, ALTO))
	cielo.material = mat_cielo
	add_child(cielo)

	capa_medio = Node2D.new()
	add_child(capa_medio)
	mat_ruinas = _material(SH_RUINAS)
	mat_ruinas.set_shader_parameter("cristal", CRISTAL)
	_fortaleza_izquierda()
	_fortaleza_derecha()
	_cristal()
	_ventanas()

	capa_niebla = Node2D.new()
	add_child(capa_niebla)
	var niebla := ColorRect.new()
	niebla.position = Vector2(-40, 440)
	niebla.size = Vector2(ANCHO + 80, 300)
	niebla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	niebla.material = _material(SH_NIEBLA)
	capa_niebla.add_child(niebla)

	_particulas()

	capa_cerca = Node2D.new()
	add_child(capa_cerca)
	_primer_plano()
	_vineta()


func _material(codigo: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = Shader.new()
	m.shader.code = codigo
	return m


# Punto de luz suave (blanco que se apaga hacia fuera). También lo usa inicio_alternativo.gd.
static func textura_brillo(tam := 64) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = tam
	t.height = tam
	return t


static func aditivo() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


# ================================================================= capa media: las fortalezas

func _poligono(capa: Node2D, puntos: PackedVector2Array, material: Material = null, color := Color.WHITE) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = puntos
	p.color = color
	p.antialiased = true
	if material != null:
		p.material = material
	capa.add_child(p)
	return p


# Una torre: cuerpo recto y, encima, almenas, tejado cónico o un remate roto.
func _torre(x: float, base: float, ancho: float, alto: float, remate: String, semilla := 0) -> PackedVector2Array:
	var arriba := base - alto
	var p := PackedVector2Array([Vector2(x, base)])
	match remate:
		"conico":
			p.append_array([Vector2(x, arriba), Vector2(x - 6, arriba), Vector2(x + ancho * 0.5, arriba - ancho * 1.5),
				Vector2(x + ancho + 6, arriba), Vector2(x + ancho, arriba)])
		"aguja":
			p.append_array([Vector2(x, arriba), Vector2(x + ancho * 0.18, arriba - 18), Vector2(x + ancho * 0.5, arriba - ancho * 2.4),
				Vector2(x + ancho * 0.82, arriba - 18), Vector2(x + ancho, arriba)])
		"roto":
			var r := RandomNumberGenerator.new()
			r.seed = 31 + semilla
			var n := 6
			for i in n + 1:
				var t := float(i) / n
				p.append(Vector2(x + ancho * t, arriba + r.randf_range(-4, 22) * sin(t * PI + 0.3)))
		_:                                             # almenas
			p.append(Vector2(x - 3, arriba + 6))
			p.append(Vector2(x - 3, arriba))
			var dientes := maxi(2, int(ancho / 12.0))
			var paso := (ancho + 6) / (dientes * 2 - 1)
			for i in dientes * 2 - 1:
				var x0 := x - 3 + paso * i
				var y0 := arriba - 9 if i % 2 == 0 else arriba
				p.append_array([Vector2(x0, y0), Vector2(x0 + paso, y0)])
			p.append(Vector2(x + ancho + 3, arriba))
			p.append(Vector2(x + ancho + 3, arriba + 6))
	p.append(Vector2(x + ancho, base))
	return p


# Un lienzo de muralla con almenas entre dos puntos.
func _muro(x0: float, x1: float, base: float, alto: float) -> PackedVector2Array:
	var arriba := base - alto
	var p := PackedVector2Array([Vector2(x0, base), Vector2(x0, arriba)])
	var x := x0
	var diente := 8.0
	var i := 0
	while x < x1:
		var y0 := arriba - 7 if i % 2 == 0 else arriba
		var x2 := minf(x + diente, x1)
		p.append_array([Vector2(x, y0), Vector2(x2, y0)])
		x = x2
		i += 1
	p.append_array([Vector2(x1, arriba), Vector2(x1, base)])
	return p


# Un arco (medio anillo) entre dos pilares; «roto» lo deja partido por la derecha.
func _arco(cx: float, arranque: float, radio: float, grosor: float, roto := false) -> PackedVector2Array:
	var p := PackedVector2Array()
	var fin := 0.38 if roto else 0.0
	var n := 14
	for i in n + 1:
		var a := PI + (PI - fin) * float(i) / n
		p.append(Vector2(cx + cos(a) * (radio + grosor), arranque + sin(a) * (radio + grosor)))
	for i in n + 1:
		var a := PI + (PI - fin) * float(n - i) / n
		p.append(Vector2(cx + cos(a) * radio, arranque + sin(a) * radio))
	return p


func _risco(puntos: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for v in puntos:
		p.append(v)
	return p


func _fortaleza_izquierda() -> void:
	var c := capa_medio
	var m := mat_ruinas
	_poligono(c, _risco([Vector2(-60, 740), Vector2(-60, 470), Vector2(20, 452), Vector2(90, 466), Vector2(160, 458),
		Vector2(240, 470), Vector2(300, 492), Vector2(352, 530), Vector2(395, 575), Vector2(430, 640), Vector2(470, 740)]), m)
	_poligono(c, _muro(30, 290, 470, 46), m)
	_poligono(c, _torre(118, 470, 50, 150, "conico"), m)
	_poligono(c, _torre(40, 470, 34, 92, "almenas"), m)
	_poligono(c, _torre(206, 470, 42, 112, "roto", 1), m)
	_poligono(c, _torre(262, 478, 30, 70, "almenas"), m)
	# un puente roto que baja del risco hacia el valle
	_poligono(c, _risco([Vector2(292, 486), Vector2(392, 512), Vector2(392, 524), Vector2(292, 500)]), m)
	_poligono(c, _risco([Vector2(330, 498), Vector2(342, 501), Vector2(342, 580), Vector2(330, 576)]), m)
	_poligono(c, _risco([Vector2(372, 507), Vector2(383, 510), Vector2(386, 520), Vector2(380, 600), Vector2(372, 596)]), m)


func _fortaleza_derecha() -> void:
	var c := capa_medio
	var m := mat_ruinas
	_poligono(c, _risco([Vector2(820, 740), Vector2(870, 600), Vector2(920, 548), Vector2(980, 520), Vector2(1040, 508),
		Vector2(1120, 504), Vector2(1200, 516), Vector2(1260, 506), Vector2(1340, 512), Vector2(1340, 740)]), m)
	# acueducto roto delante de la ciudadela
	_poligono(c, _risco([Vector2(880, 560), Vector2(1010, 512), Vector2(1010, 524), Vector2(880, 572)]), m)
	for i in 3:
		var cx := 906.0 + i * 38.0
		var arranque := 556.0 - i * 14.0
		_poligono(c, _arco(cx, arranque, 13.0, 6.0, i == 0), m)
		_poligono(c, _risco([Vector2(cx + 13, arranque), Vector2(cx + 19, arranque), Vector2(cx + 19, arranque + 80),
			Vector2(cx + 13, arranque + 80)]), m)
	_poligono(c, _muro(960, 1260, 512, 54), m)
	_poligono(c, _torre(984, 512, 36, 118, "roto", 2), m)
	_poligono(c, _torre(1060, 512, 40, 182, "aguja"), m)
	_poligono(c, _torre(1150, 516, 44, 132, "conico"), m)
	_poligono(c, _torre(1214, 512, 30, 84, "almenas"), m)
	# un contrafuerte que sube hacia la aguja
	_poligono(c, _risco([Vector2(1040, 512), Vector2(1060, 400), Vector2(1060, 512)]), m)
	_poligono(c, _risco([Vector2(1100, 400), Vector2(1122, 512), Vector2(1100, 512)]), m)


# El cristal de la aguja: un rombo claro con un núcleo brillante y un halo grande que respira.
func _cristal() -> void:
	var ad := aditivo()
	halo_cristal = Sprite2D.new()
	halo_cristal.texture = brillo
	halo_cristal.material = ad
	halo_cristal.position = CRISTAL
	halo_cristal.scale = Vector2.ONE * 3.6
	halo_cristal.modulate = Color(0.45, 0.5, 1.0, 0.45)
	capa_medio.add_child(halo_cristal)
	var rombo := _poligono(capa_medio, PackedVector2Array([CRISTAL + Vector2(0, -15), CRISTAL + Vector2(6, 0),
		CRISTAL + Vector2(0, 13), CRISTAL + Vector2(-6, 0)]), null, Color(0.78, 0.86, 1.0))
	rombo.material = ad
	nucleo_cristal = Sprite2D.new()
	nucleo_cristal.texture = brillo
	nucleo_cristal.material = ad
	nucleo_cristal.position = CRISTAL
	nucleo_cristal.scale = Vector2.ONE * 0.9
	nucleo_cristal.modulate = Color(0.85, 0.9, 1.0, 0.9)
	capa_medio.add_child(nucleo_cristal)


# Ventanas con luz dorada en las torres: pocas, pequeñas, que parpadean como velas.
func _ventanas() -> void:
	var sitios := [Vector2(143, 372), Vector2(143, 408), Vector2(55, 420), Vector2(226, 430), Vector2(275, 448),
		Vector2(1001, 452), Vector2(1080, 420), Vector2(1080, 372), Vector2(1172, 440), Vector2(1172, 470),
		Vector2(1228, 470)]
	var ad := aditivo()
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var rects: Array = []
	for s in sitios:                             # primero todas las ventanas y luego sus halos: así se dibujan juntos
		var v := ColorRect.new()
		v.position = s - Vector2(1.5, 3)
		v.size = Vector2(3, 6)
		v.color = Color(1.0, 0.78, 0.42)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		capa_medio.add_child(v)
		rects.append(v)
	for i in sitios.size():
		var s: Vector2 = sitios[i]
		var g := Sprite2D.new()
		g.texture = brillo
		g.material = ad
		g.position = s
		g.scale = Vector2.ONE * 0.42
		g.modulate = Color(1.0, 0.7, 0.32, 0.5)
		capa_medio.add_child(g)
		ventanas.append([rects[i], g, r.randf() * TAU, r.randf_range(1.5, 3.2)])


# ================================================================= primer plano

func _primer_plano() -> void:
	var c := capa_cerca
	# Casi negro, pero violáceo y con la luz del cristal en lo que tiene cerca (el mismo sombreador que las ruinas,
	# más oscuro): no son barras negras, sino piedra en sombra.
	var m := _material(SH_RUINAS)
	m.set_shader_parameter("color_alto", Vector3(0.05, 0.036, 0.085))
	m.set_shader_parameter("color_bajo", Vector3(0.014, 0.011, 0.026))
	m.set_shader_parameter("base_alta", 200.0)
	m.set_shader_parameter("base_baja", 700.0)
	m.set_shader_parameter("luz", 0.55)
	mat_cerca = m
	var negro := Color(0.014, 0.011, 0.026)
	var borde := Color(0.16, 0.12, 0.27)
	# columna rota a la izquierda, con su capitel (estrecha: enmarca sin tapar el torreón)
	_poligono(c, _risco([Vector2(-40, 760), Vector2(-40, 262), Vector2(-14, 250), Vector2(4, 262), Vector2(20, 242),
		Vector2(36, 256), Vector2(46, 248), Vector2(50, 760)]), m)
	_poligono(c, _risco([Vector2(-40, 326), Vector2(62, 326), Vector2(62, 310), Vector2(-40, 310)]), m)
	_poligono(c, _risco([Vector2(48, 310), Vector2(62, 310), Vector2(62, 312), Vector2(48, 312)]), null, borde)
	_poligono(c, _risco([Vector2(48, 330), Vector2(50, 330), Vector2(50, 700), Vector2(48, 700)]), null, borde)
	# un tambor de columna caído en el suelo
	_poligono(c, _risco([Vector2(56, 704), Vector2(222, 672), Vector2(232, 698), Vector2(70, 734)]), m)
	# el arco partido arriba a la derecha y su pilar
	_poligono(c, _risco([Vector2(1240, 760), Vector2(1240, 214), Vector2(1330, 200), Vector2(1330, 760)]), m)
	_poligono(c, _arco_partido(), m)
	_poligono(c, _risco([Vector2(1240, 216), Vector2(1243, 216), Vector2(1243, 560), Vector2(1240, 560)]), null, borde)
	# escombros por abajo (bajos en el centro, para no tapar los textos)
	var p := PackedVector2Array([Vector2(-40, 760), Vector2(-40, 690)])
	var r := RandomNumberGenerator.new()
	r.seed = 11
	var x := -40.0
	while x < ANCHO + 40:
		var centro := 1.0 - smoothstep(0.0, 380.0, absf(x - 640.0))
		var y := 690.0 + centro * 22.0 + r.randf_range(-7, 5)
		p.append(Vector2(x, y))
		x += r.randf_range(14, 34)
	p.append_array([Vector2(ANCHO + 40, 680), Vector2(ANCHO + 40, 760)])
	_poligono(c, p, null, negro)


# Un arco que arranca del pilar de la derecha y se parte en el aire, por encima de la aguja.
func _arco_partido() -> PackedVector2Array:
	var p := PackedVector2Array()
	var cx := 1076.0
	var cy := 218.0
	var exterior := 200.0
	var interior := 166.0
	var desde := deg_to_rad(4.0)
	var hasta := deg_to_rad(-66.0)
	var n := 12
	for i in n + 1:
		var a := lerpf(desde, hasta, float(i) / n)
		p.append(Vector2(cx + cos(a) * exterior, cy + sin(a) * exterior))
	# la rotura: un corte irregular
	var a_fin := hasta
	p.append(Vector2(cx + cos(a_fin) * (exterior - 14), cy + sin(a_fin) * (exterior - 14) + 9))
	p.append(Vector2(cx + cos(a_fin + 0.03) * (interior + 12), cy + sin(a_fin + 0.03) * (interior + 12) - 3))
	for i in n + 1:
		var a := lerpf(hasta + 0.04, desde, float(i) / n)
		p.append(Vector2(cx + cos(a) * interior, cy + sin(a) * interior))
	return p


# Viñeta: oscurece los bordes para llevar la vista al centro.
func _vineta() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.18), Color(0, 0, 0, 0.72)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.42)
	t.fill_to = Vector2(1.08, 0.42)
	t.width = 128
	t.height = 72
	var v := TextureRect.new()
	v.texture = t
	v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	v.stretch_mode = TextureRect.STRETCH_SCALE
	v.size = Vector2(ANCHO, ALTO)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)


# ================================================================= partículas

func _particulas() -> void:
	var ad := aditivo()
	# brasas que suben despacio (oro y brasa, como la carga de siempre, pero menos y más lentas)
	var brasas := CPUParticles2D.new()
	brasas.texture = brillo
	brasas.material = ad
	brasas.amount = 44
	brasas.lifetime = 13.0
	brasas.preprocess = 13.0
	brasas.position = Vector2(640, 740)
	brasas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	brasas.emission_rect_extents = Vector2(700, 10)
	brasas.direction = Vector2(0.15, -1)
	brasas.spread = 22.0
	brasas.gravity = Vector2(1.5, -2.5)
	brasas.initial_velocity_min = 14.0
	brasas.initial_velocity_max = 34.0
	brasas.scale_amount_min = 0.06
	brasas.scale_amount_max = 0.17
	var rampa := Gradient.new()
	rampa.offsets = PackedFloat32Array([0.0, 0.15, 0.65, 1.0])
	rampa.colors = PackedColorArray([Color(1.0, 0.8, 0.45, 0.0), Color(1.0, 0.8, 0.45, 0.85),
		Color(1.0, 0.48, 0.24, 0.5), Color(1.0, 0.48, 0.24, 0.0)])
	brasas.color_ramp = rampa
	add_child(brasas)
	# ceniza gris violácea que cae flotando, de lado
	var ceniza := CPUParticles2D.new()
	ceniza.texture = brillo
	ceniza.amount = 26
	ceniza.lifetime = 18.0
	ceniza.preprocess = 18.0
	ceniza.position = Vector2(560, -20)
	ceniza.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ceniza.emission_rect_extents = Vector2(760, 10)
	ceniza.direction = Vector2(0.5, 1)
	ceniza.spread = 20.0
	ceniza.gravity = Vector2(2.0, 3.0)
	ceniza.initial_velocity_min = 8.0
	ceniza.initial_velocity_max = 18.0
	ceniza.angular_velocity_min = -40.0
	ceniza.angular_velocity_max = 40.0
	ceniza.scale_amount_min = 0.06
	ceniza.scale_amount_max = 0.14
	var rampa_c := Gradient.new()
	rampa_c.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	rampa_c.colors = PackedColorArray([Color(0.78, 0.74, 0.88, 0.0), Color(0.8, 0.76, 0.9, 0.55),
		Color(0.8, 0.76, 0.9, 0.4), Color(0.78, 0.74, 0.88, 0.0)])
	ceniza.color_ramp = rampa_c
	add_child(ceniza)
	# chispas mágicas alrededor del cristal (van con la capa media)
	var chispas := CPUParticles2D.new()
	chispas.texture = brillo
	chispas.material = ad
	chispas.amount = 14
	chispas.lifetime = 5.0
	chispas.preprocess = 5.0
	chispas.position = CRISTAL + Vector2(0, 30)
	chispas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	chispas.emission_sphere_radius = 34.0
	chispas.direction = Vector2(0, -1)
	chispas.spread = 35.0
	chispas.gravity = Vector2(0, -3)
	chispas.initial_velocity_min = 5.0
	chispas.initial_velocity_max = 14.0
	chispas.scale_amount_min = 0.03
	chispas.scale_amount_max = 0.08
	var rampa_m := Gradient.new()
	rampa_m.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	rampa_m.colors = PackedColorArray([Color(0.6, 0.75, 1.0, 0.0), Color(0.7, 0.8, 1.0, 0.9), Color(0.65, 0.5, 1.0, 0.0)])
	chispas.color_ramp = rampa_m
	capa_medio.add_child(chispas)


# ================================================================= movimiento

func _process(delta: float) -> void:
	tiempo += delta
	var t := tiempo
	var deriva := Vector2(sin(t * 0.045), sin(t * 0.031 + 1.0) * 0.4)
	mat_cielo.set_shader_parameter("desp_lejos", -deriva * MUEVE_LEJOS / ANCHO)
	mat_cielo.set_shader_parameter("desp_medio", -deriva * (MUEVE_LEJOS + MUEVE_MEDIO) * 0.5 / ANCHO)
	capa_medio.position = deriva * MUEVE_MEDIO
	capa_niebla.position = deriva * MUEVE_NIEBLA
	capa_cerca.position = deriva * MUEVE_CERCA
	var cristal_ahora := CRISTAL + capa_medio.position
	mat_cielo.set_shader_parameter("faro", cristal_ahora / Vector2(ANCHO, ALTO))
	mat_ruinas.set_shader_parameter("cristal", cristal_ahora)   # el sombreador trabaja en coordenadas de pantalla
	mat_cerca.set_shader_parameter("cristal", cristal_ahora - capa_medio.position + capa_cerca.position)
	var pulso := 0.5 + 0.5 * sin(t * (0.9 + 0.5 * intensidad))
	destello = move_toward(destello, 0.0, delta * 0.8)
	halo_cristal.modulate.a = minf(1.0, 0.36 + 0.14 * pulso + 0.22 * intensidad + 0.5 * destello)
	nucleo_cristal.scale = Vector2.ONE * (0.82 + 0.12 * pulso + 0.12 * intensidad + 0.25 * destello)
	for v in ventanas:
		var a: float = minf(1.0, 0.75 + 0.25 * sin(t * v[3] + v[2]) * sin(t * v[3] * 0.37 + v[2] * 2.0) + 0.15 * intensidad)
		v[0].modulate.a = a
		v[1].modulate.a = 0.5 * a
