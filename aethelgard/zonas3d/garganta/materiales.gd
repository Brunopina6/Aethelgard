extends RefCounted
# Materiales de la Garganta del Diablo 3D. Todo hecho por código (ruido de Godot y sombreados propios): sin texturas
# de terceros. La paleta es la de la mazmorra, distinta de la de Pastos Verdes:
#   - roca fría (gris pizarra con vetas ocre y violeta), más oscura y azulada cuanto más honda;
#   - luz fría que baja de la rendija del cielo y, desde el fondo del abismo, un resplandor de ámbar que sube y tiñe la
#     roca de abajo (el «fondo que brilla»);
#   - acentos cálidos en el camino: faroles de los peregrinos, braseros de la arena y el cofre.
# Perfiles (prototipos/calidad_proto.gd): «relieve» decide si la roca lleva mapa de normales (bajo: no). Lo demás es igual
# en los tres: cambian cantidades (nieblas, haces, partículas) en escenario.gd.

var perfil: Dictionary
var tex_grano: NoiseTexture2D           # grano fino de la roca (0 a 1: el sombreado de la roca lo suaviza)
var tex_grano_suave: NoiseTexture2D     # el mismo grano, de 0,74 a 1,06 (como Pastos Verdes): para piedra, madera y piezas
var tex_grietas: NoiseTexture2D         # celdas: las grietas de la roca
var tex_relieve: NoiseTexture2D         # normales del grano (perfiles medio y alto)
var tex_niebla: NoiseTexture2D          # nubes suaves para la niebla del abismo
var _cache := {}

# Colores de la mazmorra (también los usa escenario.gd para los colores de vértice)
const ROCA := Color(0.40, 0.385, 0.39)
const ROCA_OCRE := Color(0.53, 0.43, 0.33)
const ROCA_VIOLETA := Color(0.36, 0.34, 0.42)
const ROCA_OSCURA := Color(0.23, 0.225, 0.25)
const MUSGO := Color(0.28, 0.34, 0.20)
const AMBAR := Color(1.0, 0.56, 0.20)
const NIEBLA := Color(0.24, 0.24, 0.34)
const LUZ_CIELO := Color(0.80, 0.86, 1.0)
const FUEGO := Color(1.0, 0.62, 0.26)

const SHADER_ROCA := """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D grano : filter_linear_mipmap, repeat_enable;
uniform sampler2D grietas : filter_linear_mipmap, repeat_enable;
#ifdef RELIEVE
uniform sampler2D relieve : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float fuerza_relieve = 0.55;
#endif
uniform float escala = 0.21;
uniform float escala_grietas = 0.075;
uniform vec3 musgo : source_color = vec3(0.28, 0.34, 0.2);
uniform vec3 brillo_abismo : source_color = vec3(1.0, 0.56, 0.2);
uniform float y_brillo = -50.0;
uniform float alcance_brillo = 40.0;
uniform float fuerza_brillo = 1.6;
uniform vec3 niebla : source_color = vec3(0.24, 0.24, 0.34);
uniform float y_niebla = -9.0;
uniform float hondo_niebla = 30.0;
// Luz rebotada: la pared del oeste, al sol, devuelve algo de luz cálida a la del este (que mira al oeste y está en
// sombra). Es una suma barata en vez de una segunda luz (en Compatibility, cada luz más redibuja lo que toca).
uniform vec3 rebote : source_color = vec3(0.50, 0.45, 0.40);
uniform float fuerza_rebote = 0.9;
varying vec3 pm;
varying vec3 nm;
void vertex() {
	pm = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	nm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 w = abs(nm);
	w = w * w * w * w;
	w /= (w.x + w.y + w.z);
	vec3 p = pm * escala;
	float g = texture(grano, p.zy).r * w.x + texture(grano, p.xz).r * w.y + texture(grano, p.xy).r * w.z;
	vec3 q = pm * escala_grietas;
	float c = texture(grietas, q.zy).r * w.x + texture(grietas, q.xz).r * w.y + texture(grietas, q.xy).r * w.z;
	float arriba = smoothstep(0.5, 0.9, nm.y);
	float grieta = (1.0 - smoothstep(0.012, 0.06, c)) * (1.0 - 0.75 * arriba);   // grietas finas, sobre todo en las paredes
	float piedrecitas = texture(grano, pm.xz * escala * 4.5).r;                   // gravilla en lo que mira arriba
	vec3 col = COLOR.rgb * (0.78 + 0.44 * g) * (1.0 - 0.5 * grieta);
	col *= mix(1.0, 0.8 + 0.4 * piedrecitas, arriba);
	col = mix(col, musgo * (0.75 + 0.5 * g), arriba * COLOR.a);
	float hondo = clamp((y_niebla - pm.y) / hondo_niebla, 0.0, 1.0);
	col = mix(col, niebla, hondo * 0.75);
	ALBEDO = col;
	float cerca = clamp(1.0 - (pm.y - y_brillo) / alcance_brillo, 0.0, 1.0);
	float mira = clamp(0.6 - nm.y * 0.5, 0.0, 1.0);
	EMISSION = brillo_abismo * cerca * cerca * mira * (0.55 + 0.45 * g) * (1.0 - 0.5 * grieta) * fuerza_brillo;
	EMISSION += col * rebote * clamp(-nm.x, 0.0, 1.0) * (1.0 - hondo) * fuerza_rebote;
	ROUGHNESS = 0.95;
#ifdef RELIEVE
	vec2 nx = (texture(relieve, p.zy).xy * 2.0 - 1.0) * fuerza_relieve;
	vec2 ny = (texture(relieve, p.xz).xy * 2.0 - 1.0) * fuerza_relieve;
	vec2 nz = (texture(relieve, p.xy).xy * 2.0 - 1.0) * fuerza_relieve;
	vec3 n = normalize(nm + vec3(0.0, nx.y, nx.x) * w.x + vec3(ny.x, 0.0, ny.y) * w.y + vec3(nz.x, nz.y, 0.0) * w.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
#endif
}
"""

# Niebla del abismo: una capa horizontal con nubes que se mueven despacio. Sin leer la profundidad (caro en el Mali):
# los cortes con la roca se disimulan porque la roca honda ya tiene el color de la niebla.
const SHADER_NIEBLA := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D nubes : filter_linear_mipmap, repeat_enable;
uniform vec4 color : source_color = vec4(0.42, 0.40, 0.52, 0.45);
uniform float escala = 0.03;
uniform float velocidad = 0.010;
varying vec3 pm;
void vertex() {
	pm = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 uv = pm.xz * escala;
	float a = texture(nubes, uv + vec2(TIME * velocidad, TIME * velocidad * 0.6)).r;
	float b = texture(nubes, uv * 1.9 + vec2(-TIME * velocidad * 0.7, 0.3)).r;
	float n = 0.25 + 0.75 * smoothstep(0.2, 0.72, a * 0.62 + b * 0.38);
	float borde = smoothstep(0.0, 0.1, UV.x) * (1.0 - smoothstep(0.9, 1.0, UV.x)) * smoothstep(0.0, 0.04, UV.y) * (1.0 - smoothstep(0.96, 1.0, UV.y));
	ALBEDO = color.rgb;
	ALPHA = color.a * n * borde;
}
"""

# El fondo del abismo: un mar de ámbar que respira, muy abajo, entre la niebla (opaco: casi no cuesta).
const SHADER_FONDO := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform sampler2D nubes : filter_linear_mipmap, repeat_enable;
uniform vec3 hondo : source_color = vec3(0.13, 0.06, 0.07);
uniform vec3 ambar : source_color = vec3(1.0, 0.56, 0.2);
uniform vec3 nucleo : source_color = vec3(1.0, 0.82, 0.5);
varying vec3 pm;
void vertex() {
	pm = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	// un resplandor suave que respira, más vivo por el centro de la garganta y apagado contra las paredes (no una
	// costra de lava: se ve a 50 m, entre la niebla)
	vec2 uv = pm.xz * 0.06;
	float a = texture(nubes, uv + vec2(TIME * 0.006, -TIME * 0.004)).r;
	float b = texture(nubes, uv * 2.1 - vec2(TIME * 0.009, 0.0)).r;
	float centro = 1.0 - smoothstep(2.0, 9.0, abs(pm.x));
	float v = smoothstep(0.3, 0.95, a * 0.6 + b * 0.4) * (0.55 + 0.45 * centro);
	float pulso = 0.85 + 0.15 * sin(TIME * 0.6 + pm.z * 0.06);
	vec3 c = mix(hondo, ambar * 0.85, v * pulso);
	c = mix(c, nucleo, smoothstep(0.7, 1.0, v) * 0.4);
	ALBEDO = c;
}
"""

# Haces de luz que caen de la rendija del cielo (suman color, no escriben profundidad).
const SHADER_HAZ := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 color : source_color = vec4(0.75, 0.82, 1.0, 0.16);
void fragment() {
	float lados = smoothstep(0.0, 0.35, UV.x) * (1.0 - smoothstep(0.65, 1.0, UV.x));
	float alto = (1.0 - smoothstep(0.25, 1.0, UV.y)) * smoothstep(0.0, 0.08, UV.y);
	float vibra = 0.85 + 0.15 * sin(TIME * 0.6 + UV.x * 9.0);
	ALBEDO = color.rgb;
	ALPHA = color.a * lados * alto * vibra;
}
"""

# La cascada del fondo de la garganta (como la de Pastos Verdes, más fina y más fría): rayas que caen.
const SHADER_CASCADA := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;
uniform float largo = 30.0;
void fragment() {
	float t = TIME * 1.1;
	float ruido = sin(UV.x * 31.0 + sin(UV.x * 9.0) * 3.0) * 0.5 + 0.5;
	float raya = fract(UV.y * largo * 0.12 - t + ruido * 0.8);
	vec3 c = mix(vec3(0.44, 0.58, 0.72), vec3(0.93, 0.97, 1.0), smoothstep(0.45, 1.0, raya));
	float borde = smoothstep(0.0, 0.14, UV.x) * (1.0 - smoothstep(0.86, 1.0, UV.x));
	float abajo = 1.0 - smoothstep(0.7, 1.0, UV.y);
	ALBEDO = c;
	ALPHA = (0.82 - 0.3 * smoothstep(0.5, 1.0, UV.y)) * borde * abajo;
}
"""

# Hierba seca de las cornisas (la de Pastos Verdes, con viento, en ocres apagados).
const SHADER_HIERBA := """
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform vec3 abajo : source_color = vec3(0.34, 0.30, 0.20);
uniform vec3 arriba : source_color = vec3(0.72, 0.62, 0.40);
uniform float fuerza = 0.16;
varying float alto;
void vertex() {
	alto = VERTEX.y;
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float s = sin(TIME * 1.4 + w.x * 0.32 + w.z * 0.21) * 0.7 + sin(TIME * 2.9 + w.z * 1.1) * 0.3;
	VERTEX.x += s * fuerza * alto * alto * 2.0;
	VERTEX.z += s * fuerza * alto * alto;
}
void fragment() {
	ALBEDO = mix(abajo, arriba, clamp(alto / 0.45, 0.0, 1.0)) * COLOR.rgb;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}
"""


func _init(p: Dictionary) -> void:
	perfil = p
	var grano := FastNoiseLite.new()
	grano.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	grano.frequency = 0.05
	grano.fractal_octaves = 4
	grano.seed = 1211
	tex_grano = _textura(grano, 256, false)
	tex_grano_suave = _textura(grano, 256, false)
	var rampa := Gradient.new()
	rampa.colors = PackedColorArray([Color(0.74, 0.74, 0.74), Color(1.06, 1.06, 1.06)])
	tex_grano_suave.color_ramp = rampa
	var celdas := FastNoiseLite.new()
	celdas.noise_type = FastNoiseLite.TYPE_CELLULAR
	celdas.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	celdas.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	celdas.frequency = 0.035
	celdas.fractal_type = FastNoiseLite.FRACTAL_FBM
	celdas.fractal_octaves = 2
	celdas.seed = 77
	tex_grietas = _textura(celdas, 256, false)
	if perfil.get("relieve", true):
		tex_relieve = _textura(grano, 256, true)
	var nubes := FastNoiseLite.new()
	nubes.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nubes.frequency = 0.03
	nubes.fractal_octaves = 3
	nubes.seed = 5
	tex_niebla = _textura(nubes, 128, false)


func _textura(n: FastNoiseLite, tam: int, normal: bool) -> NoiseTexture2D:
	var t := NoiseTexture2D.new()
	t.width = tam
	t.height = tam
	t.seamless = true
	t.noise = n
	t.generate_mipmaps = true
	if normal:
		t.as_normal_map = true
		t.bump_strength = 7.0
	return t


func _shader(codigo: String, defines: Array = []) -> Shader:
	var clave := "sh_%d_%s" % [codigo.hash(), str(defines)]
	if not _cache.has(clave):
		var s := Shader.new()
		var pre := ""
		for d in defines:
			pre += "#define %s\n" % d
		var i := codigo.find("\n", codigo.find("shader_type"))
		s.code = codigo.substr(0, i + 1) + pre + codigo.substr(i + 1)
		_cache[clave] = s
	return _cache[clave]


# ---------------------------------------------------------------- roca

# Roca de la garganta (paredes, cornisas, acantilados, pilares). El color sale de los vértices (estratos, humedad,
# musgo en el canal alfa) y del grano; abajo se tiñe de niebla y se enciende con el ámbar del fondo.
func roca(brillo := 1.0) -> ShaderMaterial:
	var clave := "roca_%.2f" % brillo
	if _cache.has(clave):
		return _cache[clave]
	var m := ShaderMaterial.new()
	m.shader = _shader(SHADER_ROCA, ["RELIEVE"] if perfil.get("relieve", true) else [])
	m.set_shader_parameter("grano", tex_grano)
	m.set_shader_parameter("grietas", tex_grietas)
	if perfil.get("relieve", true):
		m.set_shader_parameter("relieve", tex_relieve)
	m.set_shader_parameter("musgo", MUSGO)
	m.set_shader_parameter("brillo_abismo", AMBAR)
	m.set_shader_parameter("niebla", NIEBLA)
	m.set_shader_parameter("fuerza_brillo", 1.1 * brillo)
	_cache[clave] = m
	return m


# ---------------------------------------------------------------- materiales sencillos (también para lo que se vuelve
# medio transparente al tapar a Kael: vista3d.gd solo sabe hacerlo con StandardMaterial3D)

func detalle(color: Color, escala := 0.6, relieve := 0.6, rugosidad := 0.9) -> StandardMaterial3D:
	var clave := "det_%s_%.2f_%.2f_%.2f" % [color.to_html(), escala, relieve, rugosidad]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = tex_grano_suave
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * escala
	m.roughness = rugosidad
	if perfil.get("relieve", true) and relieve > 0.0:
		m.normal_enabled = true
		m.normal_texture = tex_relieve
		m.normal_scale = relieve
	_cache[clave] = m
	return m


func piedra() -> StandardMaterial3D:
	return detalle(Color(0.50, 0.48, 0.52), 0.9, 0.9)


func piedra_tallada() -> StandardMaterial3D:              # la de los peregrinos: algo más clara y cálida
	return detalle(Color(0.58, 0.55, 0.52), 0.9, 0.8)


func madera() -> StandardMaterial3D:
	var clave := "madera"
	if _cache.has(clave):
		return _cache[clave]
	var m := detalle(Color(0.42, 0.30, 0.21), 1.0, 0.7).duplicate() as StandardMaterial3D
	m.uv1_scale = Vector3(0.6, 3.0, 0.6)                   # la veta estirada a lo largo
	_cache[clave] = m
	return m


func madera_vieja() -> StandardMaterial3D:
	return detalle(Color(0.36, 0.28, 0.22), 1.2, 0.7)


func liso(color: Color, rugosidad := 0.9, metal := 0.0) -> StandardMaterial3D:
	var clave := "liso_%s_%.2f_%.2f" % [color.to_html(), rugosidad, metal]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rugosidad
	m.metallic = metal
	_cache[clave] = m
	return m


func cuerda() -> StandardMaterial3D:
	return liso(Color(0.60, 0.52, 0.38), 1.0)


func hierro() -> StandardMaterial3D:
	return liso(Color(0.26, 0.26, 0.30), 0.55, 0.6)


func bronce() -> StandardMaterial3D:
	var clave := "bronce"
	if _cache.has(clave):
		return _cache[clave]
	var m := liso(Color(0.80, 0.60, 0.30), 0.4, 0.7).duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color(1.0, 0.7, 0.3)
	m.emission_energy_multiplier = 0.25
	_cache[clave] = m
	return m


func hueso() -> StandardMaterial3D:
	return liso(Color(0.86, 0.82, 0.72), 0.85)


func tela(color: Color) -> StandardMaterial3D:
	var clave := "tela_%s" % color.to_html()
	if _cache.has(clave):
		return _cache[clave]
	var m := liso(color, 1.0).duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[clave] = m
	return m


# Algo que brilla con luz propia (cristales, llamas, faroles): sin sombreado.
func brillo(color: Color, energia := 1.0) -> StandardMaterial3D:
	var clave := "brillo_%s_%.2f" % [color.to_html(), energia]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color.r * energia, color.g * energia, color.b * energia)
	_cache[clave] = m
	return m


# Cristal de ámbar: se ilumina con la escena y además brilla.
func cristal_ambar() -> StandardMaterial3D:
	var clave := "cristal_ambar"
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.62, 0.22)
	m.roughness = 0.25
	m.emission_enabled = true
	m.emission = AMBAR
	m.emission_energy_multiplier = 1.6
	_cache[clave] = m
	return m


# ---------------------------------------------------------------- efectos

func niebla(color: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(SHADER_NIEBLA)
	m.set_shader_parameter("nubes", tex_niebla)
	m.set_shader_parameter("color", color)
	return m


func fondo() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(SHADER_FONDO)
	m.set_shader_parameter("nubes", tex_niebla)
	m.set_shader_parameter("ambar", AMBAR)
	return m


func haz(color: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(SHADER_HAZ)
	m.set_shader_parameter("color", color)
	return m


func cascada() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(SHADER_CASCADA)
	return m


func hierba() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(SHADER_HIERBA)
	return m


# Degradado redondo para halos y destellos (como el de los faroles de Pastos Verdes).
func textura_halo(c0: Color, c1: Color) -> GradientTexture2D:
	var clave := "halo_%s_%s" % [c0.to_html(), c1.to_html()]
	if _cache.has(clave):
		return _cache[clave]
	var g := Gradient.new()
	g.colors = PackedColorArray([c0, Color(c1, c1.a * 0.35), Color(c1, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	_cache[clave] = t
	return t


# Disco de luz pintado en el suelo (suma color, no escribe profundidad) y resplandor que mira a la cámara: el «halo
# falso» de los faroles de Pastos Verdes (medido allí: dos luces reales costaban ~7 ms en el Redmi).
func halo_suelo(color: Color) -> StandardMaterial3D:
	var clave := "halo_suelo_%s" % color.to_html()
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_texture = textura_halo(Color(color, 0.30), Color(color, 0.10))
	_cache[clave] = m
	return m


func halo_aire(color: Color, fuerza := 0.9) -> StandardMaterial3D:
	var clave := "halo_aire_%s_%.2f" % [color.to_html(), fuerza]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = textura_halo(Color(color, fuerza), Color(color, fuerza * 0.4))
	_cache[clave] = m
	return m


# Partícula aditiva que mira a la cámara (polvo, brasas, chispas).
func mota(color: Color) -> StandardMaterial3D:
	var clave := "mota_%s" % color.to_html()
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = textura_halo(Color(1, 1, 1, 1), Color(1, 1, 1, 0.5))
	m.albedo_color = color
	_cache[clave] = m
	return m
