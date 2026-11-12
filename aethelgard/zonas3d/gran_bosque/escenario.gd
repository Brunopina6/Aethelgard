extends RefCounted
# El escenario del Gran Bosque Verde 3D (V12, migración región a región, 12/11). Con el kit de Pastos Verdes (los árboles
# estilizados de prototipos/arbol_estilizado.gd, la hierba con viento, el agua sin refracción, el grano de ruido y los
# lotes por material) pero con su propia identidad: un bosque viejo y cerrado, más denso y oscuro que Pastos, con
# relieve (lomas, cauce, la loma del mirador), luz filtrada (manchas de sol en el suelo bajo las copas y haces de luz en
# los claros), sotobosque (helechos, setas, matas), troncos viejos y raíces, las charcas y el arroyo de la 2D con sus
# dos puentes de madera, y lugares que se reconocen: la linde de la entrada, las ruinas con el árbol que abraza la
# armadura, el campamento, el claro, el altar del fondo y el mirador.
#
# Rendimiento (Mali-G57: limita la GPU, sobre todo el follaje que se solapa):
#   - todo lo que se repite va en MultiMesh por trozos de TROZO m (se recortan solos fuera de la cámara) y con distancia
#     de dibujo por perfil;
#   - copas: «de hojas» (las matas pintadas de Pastos, alfa recortado: caras) junto a los caminos según el perfil, y
#     «macizas» (bolas bajas, opacas, sin recorte) en el resto: el bosque se ve lleno sin pagar hojas superpuestas;
#   - las sombras de las copas en el suelo van pintadas en el color de los vértices (manchas de sol); con sombras
#     reales (medio, alto), más suaves;
#   - un hueco en las copas y troncos entre la cámara y Kael (sombreado), en vez de la transparencia por pieza: sirve
#     también para los MultiMesh. Desde el 12/11 (rendimiento en el Redmi), en las copas se hace en el VÉRTICE (cada mata
#     o lóbulo se encoge hacia su centro: lo de dentro no dibuja ni un píxel); en los troncos sigue el tramado;
#   - bajo y medio (12/11): copas de hojas sin las matas de dentro, con un núcleo opaco (_copa_vieja); copas macizas con
#     una mezcla triplanar más corta; el suelo con UV en vez de triplanar. Cifras y capturas:
#     docs/memory/agents/rendimiento_v12_gran_bosque.md.

const T := preload("res://zonas3d/gran_bosque/trazado.gd")
const D := preload("res://zonas3d/gran_bosque/disposicion_2d.gd")
const Arbol := preload("res://prototipos/arbol_estilizado.gd")

const TROZO := 25.0
const ORIGEN_TROZOS := Vector2(-62.5, -50.0)
# Distancias de dibujo por perfil: [árboles, sotobosque, hierba]
const DISTANCIAS := {"bajo": [52.0, 30.0, 26.0], "medio": [60.0, 36.0, 32.0], "alto": [95.0, 55.0, 50.0]}
# Copas de hojas: hasta cuántas casillas del camino o de un rincón (más lejos, macizas). bajo: solo los árboles viejos.
const HOJAS_HASTA := {"bajo": -1.0, "medio": 4.5, "alto": 999.0}
const HELECHOS_EXTRA := {"bajo": 520, "medio": 760, "alto": 1100}
const HACES := {"bajo": 3, "medio": 5, "alto": 7}
# Orden de dibujo de lo opaco (render_priority; medido en Compatibility: en lo opaco, MAYOR = DESPUÉS): primero las
# copas macizas y los núcleos (lo que más tapa), luego lo demás opaco (0), lo recortado y, al final, el suelo y el agua.
const PRIO_TAPA := -1
const PRIO_RECORTADO := 1
const PRIO_FONDO := 2

# ---------------------------------------------------------------- sombreados
const HUECO := """
	float corte_h = corte_hueco(mundo);
	if (corte_h < 0.999 && corte_h < ruido_h(FRAGCOORD.xy)) {
		discard;
	}
"""
# Rendimiento (12/11, medido: docs/memory/agents/rendimiento_v12_gran_bosque.md): en las copas el hueco ya no se hace
# píxel a píxel (tramado + discard: dentro del hueco se seguían sombreando todas las capas de matas, hasta 7 por píxel en
# la entrada), sino en el vértice: cada mata (o lóbulo de copa maciza) se encoge hacia su centro (CUSTOM0) según lo que
# valga el hueco allí, y lo que está dentro no llega a dibujar ni un píxel. El borde del hueco se ve como hojas que se
# apartan, sin grano. Las copas macizas, además, quedan sin discard (opacas de verdad).
# CUSTOM0.w: 0 en las matas; en los lóbulos (núcleos, copas macizas), su radio: se mira el punto del lóbulo que da a la
# cámara, para que se vayan antes que las matas de fuera (si no, el núcleo oscuro se quedaba a la vista).
const HUECO_VERTICE := """
	vec3 centro_h = (MODEL_MATRIX * vec4(CUSTOM0.xyz, 1.0)).xyz;
	float radio_h = CUSTOM0.w * length(MODEL_MATRIX[0].xyz);
	float encoge_h = corte_hueco(centro_h + normalize(hueco_a - centro_h + vec3(0.0, 0.001, 0.0)) * radio_h);
	VERTEX = mix(CUSTOM0.xyz, VERTEX, encoge_h);
"""
const UNIFORMES_HUECO := """
uniform vec3 hueco_a = vec3(0.0, -1000.0, 0.0);
uniform vec3 hueco_b = vec3(0.0, -1000.0, 0.0);
uniform float hueco_r = 0.0;
varying vec3 mundo;
float ruido_h(vec2 p) {
	return fract(52.9829189 * fract(0.06711056 * p.x + 0.00583715 * p.y));
}
// 1: se ve; 0: dentro del hueco. Un cono de la cámara (ancho) a Kael (hueco_r), por encima de sus pies, y lo que está muy
// cerca de la cámara.
float corte_hueco(vec3 p) {
	if (hueco_r <= 0.0) {
		return 1.0;
	}
	vec3 ab_h = hueco_b - hueco_a;
	float largo_h = max(length(ab_h), 0.001);
	float t_h = clamp(dot(p - hueco_a, ab_h) / (largo_h * largo_h), 0.0, 1.0);
	float corte_h = 1.0;
	float r_h = hueco_r * mix(2.4, 1.0, t_h);
	float d_h = length(p - (hueco_a + ab_h * t_h)) / r_h;
	if (t_h < 0.985 && p.y > hueco_b.y - 0.75) {
		corte_h = smoothstep(0.62, 1.0, d_h);
	}
	return min(corte_h, smoothstep(0.44, 0.52, distance(p, hueco_a) / largo_h));
}
"""
# Copas de hojas (las de arbol_estilizado.gd, con el hueco y el tinte de cada árbol en su color)
const SHADER_HOJAS := """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 color : source_color = vec4(1.0);
uniform float viento = 0.045;
uniform vec3 translucidez : source_color = vec3(0.16, 0.22, 0.06);
%s
void vertex() {
%s
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	float s = sin(TIME * 1.3 + w.x * 0.3 + w.z * 0.2 + VERTEX.y * 0.5) * 0.65 + sin(TIME * 2.4 + VERTEX.x * 1.6) * 0.35;
	VERTEX.x += s * viento * h * 0.22;
	VERTEX.z += s * viento * h * 0.14;
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
%s
	vec4 t = texture(atlas, UV);
	ALBEDO = t.rgb * COLOR.rgb * color.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.85;
	SPECULAR = 0.12;
	BACKLIGHT = translucidez;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
"""
# Lo macizo (copas de bolas, pinos, troncos, helechos, matas, setas): color de vértice × tinte del ejemplar, algo de
# grano y viento por encima de «viento_altura».
const SHADER_MACIZO := """
shader_type spatial;
render_mode %s, diffuse_burley, specular_disabled;
uniform sampler2D grano : filter_linear_mipmap, repeat_enable;
uniform float grano_escala = 0.7;
uniform float grano_fuerza = 0.0;
uniform float viento = 0.0;
uniform float viento_altura = 1.0;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_enable;
uniform float hojas = 0.0;                       // 1: copa «pintada» con las matas de hojas del atlas (opaca, sin recorte)
uniform vec2 celda = vec2(0.0, 0.0);
uniform float hojas_escala = 0.42;
uniform vec3 hojas_fondo : source_color = vec3(0.09, 0.16, 0.07);
uniform float afilar = 1.0;                      // mezcla triplanar: 1 = la de siempre (alto)
uniform float umbral = 0.0;                      // caras que pesan menos que esto no se leen
varying vec3 nmundo;
%s
void vertex() {
%s
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = max(VERTEX.y - viento_altura, 0.0);
	float s = sin(TIME * 1.2 + w.x * 0.25 + w.z * 0.19) * 0.7 + sin(TIME * 2.1 + w.x * 0.9 + VERTEX.y) * 0.3;
	VERTEX.x += s * viento * h;
	VERTEX.z += s * viento * h * 0.6;
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	nmundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
vec3 matas(vec2 uv) {
	vec4 t = texture(atlas, celda + fract(uv) * 0.5);
	return mix(hojas_fondo, t.rgb, t.a);
}
void fragment() {
%s
	vec3 c;
	if (hojas > 0.5) {                               // (el grano, solo si no es copa pintada: antes se leía y se tiraba)
		// triplanar; con «afilar» > 1 (bajo, medio) la mezcla entre caras es más corta y la cara que casi no pesa no se
		// lee (de 3 lecturas del atlas por píxel a ~1,4; medido en el PC)
		vec3 pesos = pow(abs(nmundo), vec3(afilar));
		pesos = pesos / (pesos.x + pesos.y + pesos.z);
		vec3 m = vec3(0.0);
		if (pesos.y > umbral) {
			m += matas(mundo.xz * hojas_escala) * pesos.y;
		}
		if (pesos.x > umbral) {
			m += matas(mundo.zy * hojas_escala + 0.3) * pesos.x;
		}
		if (pesos.z > umbral) {
			m += matas(mundo.xy * hojas_escala + 0.6) * pesos.z;
		}
		m /= max(step(umbral, pesos.y) * pesos.y + step(umbral, pesos.x) * pesos.x + step(umbral, pesos.z) * pesos.z, 0.001);
		c = COLOR.rgb * m * 1.5;
	} else {
		float g = mix(1.0, texture(grano, vec2(mundo.x + mundo.z, mundo.y) * grano_escala).r * 1.2, grano_fuerza);
		c = COLOR.rgb * g;
	}
	ALBEDO = c;
	ROUGHNESS = 0.92;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
"""
const SHADER_HIERBA := """
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform vec3 abajo : source_color = vec3(0.17, 0.32, 0.12);
uniform vec3 arriba : source_color = vec3(0.45, 0.62, 0.26);
uniform float fuerza = 0.18;
varying float alto;
void vertex() {
	alto = VERTEX.y;
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float s = sin(TIME * 1.5 + w.x * 0.32 + w.z * 0.21) * 0.7 + sin(TIME * 3.1 + w.x * 1.3) * 0.3;
	VERTEX.x += s * fuerza * alto * alto * 2.0;
	VERTEX.z += s * fuerza * alto * alto;
}
void fragment() {
	ALBEDO = mix(abajo, arriba, clamp(alto / 0.5, 0.0, 1.0)) * COLOR.rgb;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}
"""
const SHADER_HAZ := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 color : source_color = vec4(1.0, 0.9, 0.62, 0.2);
void fragment() {
	float lado = smoothstep(0.0, 0.4, UV.x) * smoothstep(1.0, 0.6, UV.x);
	float alto = smoothstep(0.0, 0.35, UV.y) * smoothstep(1.0, 0.7, UV.y);
	float ondula = 0.7 + 0.3 * sin(TIME * 0.5 + UV.x * 6.0 + UV.y * 2.0);
	ALBEDO = color.rgb;
	ALPHA = color.a * lado * alto * ondula;
}
"""

var r: Node3D                                   # la región (gran_bosque_3d.gd)
var perfil: Dictionary
var nombre_perfil := "alto"
var grano: Texture2D
var relieve: Texture2D
var mats_hueco: Array = []                      # materiales con el hueco: se les pone cada fotograma
var obstaculos := {}                            # Vector2i (celda de 2 m) → [Vector3(x, z, radio)]
var _lotes := {}                                # Material → SurfaceTool
var _mm := {}                                   # "trozo|tipo" → {"malla", "mat", "t": [], "c": [], "sombra", "dist"}
var arboles: Array = []                         # [Vector3 pie, radio de copa] (las manchas de sombra)
var cofres := {}                                # id → {"nodo", "tapa", "pos", "abierto", "brillo"}
var detalle: Node3D                             # el árbol que abraza la armadura
var hoja: Node3D                                # la Hoja sin Nombre entre las raíces, mientras no se ha encontrado
var orbe: Node3D
var hojas_caen: CPUParticles3D
var _rng := RandomNumberGenerator.new()
var _mat_hojas: Dictionary = {}                 # tipo de copa → ShaderMaterial
var _mat_macizo: ShaderMaterial
var _mat_copa_maciza: Dictionary = {}
var _mat_macizo_fino: ShaderMaterial
var _mat_tronco: ShaderMaterial
var _sol_dir := Vector3(0.5, -0.75, 0.45)
var luces: Array = []                           # [OmniLight3D, energía] que parpadean (fuego)
var _flotan: Array = []                         # [Node3D, y base, fase] (el orbe)


func _init(region: Node3D, p: Dictionary, nombre: String) -> void:
	r = region
	perfil = p
	nombre_perfil = nombre if DISTANCIAS.has(nombre) else "medio"


func _dist(i: int) -> float:
	return float(DISTANCIAS[nombre_perfil][i])


var tiempos := {}                               # ms de cada parte al construir (lo miran las medidas)


func construir(sol_dir: Vector3) -> void:
	_sol_dir = sol_dir.normalized()
	_rng.seed = 7919
	for parte in [_texturas, _materiales, T.preparar_alturas, _repartir_arboles, _crear_detalle, _crear_terreno, _crear_agua,
			_crear_puentes, _crear_camino, _crear_rincones, _crear_altar, _crear_mirador, _crear_entrada, _sotobosque, _hierba,
			_cerrar_multimesh, _cerrar_lotes, _haces, _particulas]:
		var u := Time.get_ticks_usec()
		parte.call()
		tiempos[parte.get_method()] = (Time.get_ticks_usec() - u) / 1000.0


# ================================================================= texturas y materiales

func _texturas() -> void:
	var ruido := FastNoiseLite.new()
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido.frequency = 0.045
	ruido.fractal_octaves = 4
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.noise = ruido
	var rampa := Gradient.new()
	rampa.colors = PackedColorArray([Color(0.74, 0.74, 0.74), Color(1.06, 1.06, 1.06)])
	nt.color_ramp = rampa
	nt.generate_mipmaps = true
	grano = nt
	var nn := NoiseTexture2D.new()
	nn.width = 256
	nn.height = 256
	nn.seamless = true
	nn.noise = ruido
	nn.as_normal_map = true
	nn.bump_strength = 6.0
	nn.generate_mipmaps = true
	relieve = nn


func mat_detalle(color := Color.WHITE, escala := 0.5, por_vertice := false, rel := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = grano
	m.vertex_color_use_as_albedo = por_vertice
	m.normal_enabled = perfil.get("relieve", true)
	m.normal_texture = relieve
	m.normal_scale = rel
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * escala
	m.roughness = 0.92
	return m


func _shader(codigo: String) -> Shader:
	var s := Shader.new()
	s.code = codigo
	return s


func _materiales() -> void:
	# «gb_hueco_pixel» (solo para medir el antes, calidad_extra): el hueco de las copas píxel a píxel, como hasta el 12/11
	var pixel: bool = perfil.get("gb_hueco_pixel", false)
	for tipo in ["pradera", "abedul", "magico"]:
		var m := ShaderMaterial.new()
		var cod: String = SHADER_HOJAS % [UNIFORMES_HUECO, "" if pixel else HUECO_VERTICE, HUECO if pixel else ""]
		if perfil.get("gb_hojas_mipmaps", false) and float(perfil.get("gb_hojas_mip_sesgo", 0.0)) != 0.0:
			cod = cod.replace("texture(atlas, UV)", "texture(atlas, UV, %.2f)" % float(perfil.get("gb_hojas_mip_sesgo", 0.0)))
		if perfil.get("gb_hojas_ligeras", false):         # (prueba A/B: sin brillo especular ni la pasada de la sombra)
			cod = cod.replace("render_mode cull_disabled, specular_schlick_ggx;", "render_mode cull_disabled, specular_disabled, diffuse_lambert, shadows_disabled;")
		elif perfil.get("gb_hojas_sin_brillo", false):    # (prueba A/B: solo sin el brillo especular, que con 0,12 apenas se ve)
			cod = cod.replace("render_mode cull_disabled, specular_schlick_ggx;", "render_mode cull_disabled, specular_disabled;")
		m.shader = _shader(cod)
		m.set_shader_parameter("atlas", _atlas_hojas())
		m.set_shader_parameter("color", Color(0.5, 0.63, 0.46) if tipo != "magico" else Color(0.8, 0.74, 0.88))
		_mat_hojas[tipo] = m
		mats_hueco.append(m)
	_mat_macizo = ShaderMaterial.new()
	_mat_macizo.shader = _shader(SHADER_MACIZO % ["cull_back", UNIFORMES_HUECO, "", HUECO])
	_mat_macizo.set_shader_parameter("grano", grano)
	_mat_macizo.set_shader_parameter("grano_fuerza", 0.35)
	_mat_macizo.set_shader_parameter("grano_escala", 0.9)
	_mat_macizo.set_shader_parameter("viento", 0.012)
	_mat_macizo.set_shader_parameter("viento_altura", 2.2)
	mats_hueco.append(_mat_macizo)
	var cod_maciza: String = SHADER_MACIZO % ["cull_back", UNIFORMES_HUECO, "" if pixel else HUECO_VERTICE, HUECO if pixel else ""]
	if perfil.get("gb_hojas_mipmaps", false) and float(perfil.get("gb_hojas_mip_sesgo", 0.0)) != 0.0:   # (sesgo de los mipmaps)
		cod_maciza = cod_maciza.replace("texture(atlas, celda + fract(uv) * 0.5)", "texture(atlas, celda + fract(uv) * 0.5, %.2f)" % float(perfil.get("gb_hojas_mip_sesgo", 0.0)))
	var sh_maciza := _shader(cod_maciza)
	for receta in ["pradera", "abedul"]:              # las copas macizas, pintadas con las matas de Pastos
		var mc := ShaderMaterial.new()
		mc.shader = sh_maciza
		mc.set_shader_parameter("grano", grano)
		mc.set_shader_parameter("viento", 0.012)
		mc.set_shader_parameter("viento_altura", 2.2)
		mc.set_shader_parameter("atlas", _atlas_hojas())
		mc.set_shader_parameter("hojas", 1.0)
		mc.set_shader_parameter("celda", Vector2(0.0, 0.0) if receta == "pradera" else Vector2(0.5, 0.0))
		if nombre_perfil != "alto":                     # bajo y medio: mezcla triplanar más corta (menos lecturas)
			mc.set_shader_parameter("afilar", float(perfil.get("gb_afilar", 3.0)))
			mc.set_shader_parameter("umbral", float(perfil.get("gb_umbral", 0.06)))
		_mat_copa_maciza[receta] = mc
		mats_hueco.append(mc)
	_mat_macizo_fino = ShaderMaterial.new()                 # helechos, matas y setas: doble cara, sin hueco
	_mat_macizo_fino.shader = _shader(SHADER_MACIZO % ["cull_disabled", UNIFORMES_HUECO, "", ""])
	_mat_macizo_fino.set_shader_parameter("grano", grano)
	_mat_macizo_fino.set_shader_parameter("grano_fuerza", 0.2)
	_mat_macizo_fino.set_shader_parameter("viento", 0.05)
	_mat_macizo_fino.set_shader_parameter("viento_altura", 0.1)
	_mat_tronco = ShaderMaterial.new()
	_mat_tronco.shader = _shader(SHADER_MACIZO % ["cull_back", UNIFORMES_HUECO, "", HUECO])
	_mat_tronco.set_shader_parameter("grano", grano)
	_mat_tronco.set_shader_parameter("grano_fuerza", 0.6)
	_mat_tronco.set_shader_parameter("grano_escala", 1.6)
	mats_hueco.append(_mat_tronco)
	# Orden de dibujo (rend2, 12/11): primero lo opaco que tapa (copas macizas, núcleos, sotobosque), después lo que
	# tiene discard (copas de hojas, troncos y pinos con el tramado del hueco) y al final el suelo y el agua, que quedan
	# detrás de casi todo. Con la profundidad ya escrita por lo de delante, los fragmentos tapados se rechazan antes
	# de sombrearse (en el Mali, sin prepase, lo recortado no puede usar la eliminación de píxeles ocultos). La imagen
	# es la misma: la prueba de profundidad decide igual en cualquier orden.
	if perfil.get("gb_orden", true):
		for m in _mat_hojas.values() + [_mat_tronco, _mat_macizo]:
			m.render_priority = int(perfil.get("gb_prio_recortado", PRIO_RECORTADO))
		for m in _mat_copa_maciza.values():
			m.render_priority = int(perfil.get("gb_prio_tapa", PRIO_TAPA))


# Mipmaps del atlas de matas (rend2, segunda pasada, 12/11; APAGADO: «gb_hojas_mipmaps» en calidad_extra). El atlas se
# importa sin mipmaps (modelos/hojas/matas.png.import), aunque los sombreados de las hojas y de las copas pintadas piden
# filter_linear_mipmap: de lejos cada píxel lee un texel suelto de la textura de 1024² (centellea al moverse la cámara y
# en el Mali gasta caché de texturas). Con el interruptor, aquí se hace una copia con mipmaps (una vez por partida, ~5 MB
# más en memoria de vídeo) solo para el Gran Bosque: Pastos y el resto siguen con el atlas de siempre. Cambia el aspecto
# (las hojas lejanas, más suaves; con alfa recortado, algo más finas): comparación en docs/memory/agents/rendimiento_v12_rend2.md.
# «gb_hojas_mip_sesgo» (p. ej. -1.0, solo con los mipmaps): lee un mipmap más nítido (menos suave, algo más de centelleo).
static var _atlas_mip: ImageTexture


func _atlas_hojas() -> Texture2D:
	return atlas_con_mipmaps() if perfil.get("gb_hojas_mipmaps", false) else load(Arbol.ATLAS)


static func atlas_con_mipmaps() -> Texture2D:
	if _atlas_mip == null:
		var img: Image = (load(Arbol.ATLAS) as Texture2D).get_image().duplicate()
		if img.is_compressed():
			img.decompress()
		img.generate_mipmaps()
		_atlas_mip = ImageTexture.create_from_image(img)
	return _atlas_mip


# Para las medidas (medir_gpu_bosque.gd, «igualdad» y «parpadeo»): pone o quita los mipmaps en las hojas ya creadas.
func alternar_mipmaps(con: bool) -> void:
	for m in _mat_hojas.values() + _mat_copa_maciza.values():
		m.set_shader_parameter("atlas", atlas_con_mipmaps() if con else load(Arbol.ATLAS))


# El hueco entre la cámara y Kael (cada fotograma): las copas y los troncos que lo tapan no se dibujan en un cilindro.
func poner_hueco(camara: Vector3, kael: Vector3, radio: float) -> void:
	var b := kael + Vector3(0, 1.0, 0)
	for m in mats_hueco:
		m.set_shader_parameter("hueco_a", camara)
		m.set_shader_parameter("hueco_b", b)
		m.set_shader_parameter("hueco_r", radio)


# ================================================================= lotes y multimesh

func _al_lote(malla: Mesh, t: Transform3D, mat: Material) -> void:
	if not _lotes.has(mat):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_lotes[mat] = st
	_lotes[mat].append_from(malla, 0, t)


func _cerrar_lotes() -> void:
	for mat in _lotes:
		var mi := MeshInstance3D.new()
		mi.mesh = _lotes[mat].commit()
		mi.material_override = mat
		mi.name = "Lote"
		r.add_child(mi)
	_lotes.clear()


func _trozo(p: Vector3) -> Vector2i:
	return Vector2i(floori((p.x - ORIGEN_TROZOS.x) / TROZO), floori((p.z - ORIGEN_TROZOS.y) / TROZO))


# Un ejemplar de «tipo» (una malla y su material) en su trozo. sombra: GeometryInstance3D.SHADOW_CASTING_SETTING_*.
func _poner(tipo: String, malla: Mesh, mat: Material, t: Transform3D, color: Color, sombra: int, dist: float) -> void:
	var tr := _trozo(t.origin)
	var clave := "%d,%d|%s" % [tr.x, tr.y, tipo]
	if not _mm.has(clave):
		_mm[clave] = {"malla": malla, "mat": mat, "t": [], "c": [], "sombra": sombra, "dist": dist, "trozo": tr, "tipo": tipo}
	_mm[clave]["t"].append(t)
	_mm[clave]["c"].append(color)


func _cerrar_multimesh() -> void:
	for clave in _mm:
		var d: Dictionary = _mm[clave]
		var tr: Vector2i = d["trozo"]
		var centro := Vector3(ORIGEN_TROZOS.x + (tr.x + 0.5) * TROZO, 0.0, ORIGEN_TROZOS.y + (tr.y + 0.5) * TROZO)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = d["malla"]
		mm.instance_count = d["t"].size()
		for k in d["t"].size():
			var t: Transform3D = d["t"][k]
			t.origin -= centro
			mm.set_instance_transform(k, t)
			mm.set_instance_color(k, d["c"][k])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "MM_" + str(d["tipo"])
		mmi.multimesh = mm
		mmi.position = centro
		mmi.material_override = d["mat"]
		mmi.cast_shadow = d["sombra"]
		mmi.visibility_range_end = d["dist"]
		r.add_child(mmi)
	_mm.clear()


# ================================================================= obstáculos (troncos, rocas, piezas)

func obstaculo(x: float, z: float, radio: float) -> void:
	var c := Vector2i(floori(x / 2.0), floori(z / 2.0))
	if not obstaculos.has(c):
		obstaculos[c] = []
	obstaculos[c].append(Vector3(x, z, radio))


func bloqueado(x: float, z: float) -> bool:
	var c := Vector2i(floori(x / 2.0), floori(z / 2.0))
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var lista = obstaculos.get(Vector2i(c.x + dx, c.y + dz))
			if lista == null:
				continue
			for o in lista:
				var q: Vector3 = o
				if Vector2(x - q.x, z - q.y).length() < q.z + 0.22:
					return true
	return false


# ================================================================= árboles

var _mallas := {}                              # caché de mallas de esta escena


func _malla_estilizada(tipo: String) -> Dictionary:
	var factor: float = perfil.get("arbol_matas", 1.0)
	var clave := "est_%s_%.2f" % [tipo, factor]
	if not _mallas.has(clave):
		var m: Dictionary = Arbol._construir(tipo, grano, factor)
		m["copa"] = _con_centros(m["copa"])
		_mallas[clave] = m
	return _mallas[clave]


# La copa de matas con el centro de cada mata en CUSTOM0 (HUECO_VERTICE la encoge hacia él). Cada mata de
# arbol_estilizado.gd son dos triángulos (0, 1, 2 · 0, 2, 3): su centro, el punto medio de la diagonal 0-2.
func _con_centros(malla: Mesh) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.create_from(malla, 0)
	st.deindex()
	var a: Array = st.commit_to_arrays()
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var cen := PackedFloat32Array()
	cen.resize(vs.size() * 4)
	for k in range(0, vs.size() - 5, 6):
		var c: Vector3 = (vs[k] + vs[k + 2]) * 0.5
		for j in 6:
			cen[(k + j) * 4] = c.x
			cen[(k + j) * 4 + 1] = c.y
			cen[(k + j) * 4 + 2] = c.z
			cen[(k + j) * 4 + 3] = 0.0
	a[Mesh.ARRAY_CUSTOM0] = cen
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	return am


# Copa maciza: lóbulos de bolas bajas, deformadas un poco, con el color de vértice sombreado (lo de abajo y lo de dentro,
# más oscuro: no hay oclusión ambiental en Compatibility). Una malla por receta, compartida.
func _copa_maciza(receta: String) -> Mesh:
	var clave := "maciza_" + receta
	if _mallas.has(clave):
		return _mallas[clave]
	var lob: Array = Arbol.TIPOS["abedul" if receta == "abedul" else "pradera"]["lobulos"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(receta)
	var centro := Vector3.ZERO
	for l in lob:
		centro += l[0]
	centro /= lob.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)            # el centro del lóbulo (HUECO_VERTICE)
	var usados := [0, 1, 2, 3] if receta == "abedul" else [0, 1, 2, 5]   # cuatro lóbulos: la silueta, con pocos triángulos
	for k in usados:
		var l: Array = lob[k]
		var c: Vector3 = l[0]
		var rad: float = l[1] * (1.12 if receta != "abedul" else 1.0)
		var esf := SphereMesh.new()
		esf.radius = rad
		esf.height = rad * 1.75
		esf.radial_segments = 8
		esf.rings = 5
		var a := esf.get_mesh_arrays()
		var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		var sacudir := rng.randf() * 10.0
		for i in idx:
			var v: Vector3 = vs[i]
			var n: Vector3 = ns[i]
			var bulto := 1.0 + 0.09 * sin(v.x * 3.1 + sacudir) * sin(v.z * 2.7 + v.y * 1.9)
			var q: Vector3 = c + v * bulto
			var hacia := ((q - centro).normalized() * 0.6 + n * 0.4 + Vector3.UP * 0.25).normalized()
			var ao := clampf(0.55 + 0.45 * (n.y * 0.5 + 0.5) + (q.y - centro.y) * 0.08, 0.45, 1.12)
			st.set_normal(hacia)
			st.set_color(Color(ao, ao, ao))
			st.set_custom(0, Color(c.x, c.y, c.z, rad))
			st.add_vertex(q)
	var m := st.commit()
	_mallas[clave] = m
	return m


# La sombra de una copa (medio y alto con sombras): una bola baja del tamaño de la copa (36 triángulos), solo para la sombra.
func _sombra_copa(receta: String) -> Mesh:
	var clave := "sombra_" + receta
	if _mallas.has(clave):
		return _mallas[clave]
	var esf := SphereMesh.new()
	esf.radius = 1.9 if receta != "abedul" else 1.2
	esf.height = 2.6 if receta != "abedul" else 2.2
	esf.radial_segments = 6
	esf.rings = 3
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(esf, 0, Transform3D(Basis(), Vector3(0, 4.0 if receta != "abedul" else 5.2, 0)))
	var m := st.commit()
	_mallas[clave] = m
	return m


func _tronco_simple() -> Mesh:
	if _mallas.has("tronco_simple"):
		return _mallas["tronco_simple"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados := 6
	var anillos := [[0.0, 0.62], [0.4, 0.38], [1.7, 0.3], [3.3, 0.2]]   # [altura, radio] con el ensanche de la raíz
	for k in anillos.size() - 1:
		for s in lados:
			var a0 := s * TAU / lados
			var a1 := (s + 1) * TAU / lados
			var pts := []
			for q in [[k, a0], [k, a1], [k + 1, a1], [k + 1, a0]]:
				var y: float = anillos[q[0]][0]
				var rr: float = anillos[q[0]][1]
				var oscuro := 0.62 + 0.38 * clampf(y / 2.0, 0.0, 1.0)
				pts.append([Vector3(cos(q[1]) * rr, y, sin(q[1]) * rr), Color(0.30 * oscuro, 0.23 * oscuro, 0.18 * oscuro)])
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(pts[i][1])
				st.add_vertex(pts[i][0])
	st.generate_normals()
	var m := st.commit()
	_mallas["tronco_simple"] = m
	return m


# Pino: tronco y tres conos (opaco, color de vértice: más oscuro abajo y dentro).
func _pino() -> Mesh:
	if _mallas.has("pino"):
		return _mallas["pino"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados := 8
	for s in 6:                                  # tronco
		var a0 := s * TAU / 6.0
		var a1 := (s + 1) * TAU / 6.0
		var c := Color(0.30, 0.22, 0.16)
		var q := [Vector3(cos(a0) * 0.22, 0, sin(a0) * 0.22), Vector3(cos(a1) * 0.22, 0, sin(a1) * 0.22),
			Vector3(cos(a1) * 0.12, 1.6, sin(a1) * 0.12), Vector3(cos(a0) * 0.12, 1.6, sin(a0) * 0.12)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_color(c)
			st.add_vertex(q[i])
	for capa in [[1.1, 2.0, 2.6], [2.4, 1.55, 2.2], [3.6, 1.05, 1.9]]:   # [base, radio, alto]
		var y0: float = capa[0]
		var rr: float = capa[1]
		var alto: float = capa[2]
		for s in lados:
			var a0 := s * TAU / lados + y0
			var a1 := (s + 1) * TAU / lados + y0
			var abajo := Color(0.10, 0.22, 0.13) * (0.8 + 0.2 * y0 / 3.6)
			var punta := Color(0.24, 0.42, 0.22)
			var v0 := Vector3(cos(a0) * rr, y0 - 0.15 * sin(a0 * 3.0), sin(a0) * rr)
			var v1 := Vector3(cos(a1) * rr, y0 - 0.15 * sin(a1 * 3.0), sin(a1) * rr)
			var vt := Vector3(0, y0 + alto, 0)
			st.set_color(abajo); st.add_vertex(v0)
			st.set_color(abajo); st.add_vertex(v1)
			st.set_color(punta); st.add_vertex(vt)
			var vc := Vector3(0, y0 + 0.35, 0)        # la cara de abajo, en sombra
			st.set_color(abajo * 0.55); st.add_vertex(v1)
			st.set_color(abajo * 0.55); st.add_vertex(v0)
			st.set_color(abajo * 0.55); st.add_vertex(vc)
	st.generate_normals()
	var m := st.commit()
	_mallas["pino"] = m
	return m


# Un árbol de la 2D en su sitio: tronco y copa. tipo: «pradera», «abedul», «magico» o «pino».
func _arbol(tipo: String, pie: Vector3, escala: float, giro: float, tinte: Color, hojas: bool) -> void:
	var b := Basis(Vector3.UP, giro).scaled(Vector3.ONE * escala)
	var t := Transform3D(b, pie)
	var dist := _dist(0)
	var sombra := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if perfil.get("sombras", false) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if tipo == "pino":
		_poner("pino", _pino(), _mat_macizo, t, tinte, sombra, dist)
		obstaculo(pie.x, pie.z, 0.32 * escala)
		arboles.append([pie, 2.1 * escala])
		return
	var receta := "abedul" if tipo == "abedul" else "pradera"
	var tb := t
	if tipo == "abedul":
		tb = Transform3D(Basis(Vector3.UP, giro).scaled(Vector3(escala * 0.55, escala * 1.45, escala * 0.55)), pie)
	var alto: bool = nombre_perfil == "alto"
	var no := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if hojas:
		var m: Dictionary = _malla_estilizada(tipo)
		if alto:                                  # alto: el tronco con sus ramas y la sombra hoja a hoja
			_poner("tronco_" + tipo, m["tronco"], _mat_tronco, t, Color(0.82, 0.86, 0.8) if tipo != "abedul" else Color.WHITE, sombra, dist)
		else:
			_poner("tronco", _tronco_simple(), _mat_tronco, tb, Color(1.55, 1.6, 1.5) if tipo == "abedul" else Color.WHITE, sombra, dist)
		var cv := _copa_vieja(tipo)                    # bajo y medio: sin las matas de dentro y con núcleo (como los viejos)
		_poner("hojas_" + tipo, cv["copa"], _mat_hojas[tipo], t, tinte, sombra if alto else no, dist)
		if cv["nucleo"] != null:
			_poner("nucleo_" + receta, cv["nucleo"], _mat_copa_maciza[receta], t, tinte, no, dist)
	else:
		_poner("tronco", _tronco_simple(), _mat_tronco, tb, Color(1.55, 1.6, 1.5) if tipo == "abedul" else Color.WHITE, sombra, dist)
		_poner("maciza_" + receta, _copa_maciza(receta), _mat_copa_maciza[receta], t, tinte * Color(0.62, 0.70, 0.58), sombra if alto else no, dist)
	if perfil.get("sombras", false) and not alto:  # medio: la sombra de la copa, una bola baja (barata)
		_poner("sombra_" + receta, _sombra_copa(receta), _mat_macizo, t, Color.WHITE, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, dist)
	obstaculo(pie.x, pie.z, (0.42 if tipo != "abedul" else 0.26) * escala)
	arboles.append([pie, (2.3 if tipo != "abedul" else 1.5) * escala])


# Cada árbol de la 2D (OBJETOS) en su casilla, y la linde de fuera (más allá de los muros, para que la cámara nunca
# vea el final del bosque). Los sitios de los árboles viejos y de las piezas quedan libres.
var _libres: Array = []                        # [Vector3, radio]: aquí no va ningún árbol de la 2D


func _repartir_arboles() -> void:
	for c in [T.lugar("ruinas") + T.DETALLE_DESDE_RUINAS, T.MIRADOR_2D, D.META]:
		_libres.append([T.mundo(c), 3.5 if c != T.MIRADOR_2D else T.MIRADOR_RADIO * T.K + 0.6])
	for v in VIEJOS:
		_libres.append([T.mundo(v[0]), 2.2 * v[2]])
	var hasta: float = perfil.get("gb_hojas_hasta", HOJAS_HASTA[nombre_perfil])
	for o in D.OBJETOS:
		var tipo: String = o[0]
		var c: Vector2 = o[1]
		var clase := ""
		match tipo:
			"arce", "q_arbol":
				clase = "pradera"
			"glicinia":
				clase = "magico"
			"q_otono":
				clase = "pradera"
			"abedul":
				clase = "abedul"
			"q_pino":
				clase = "pino"
		if clase == "":
			continue
		var p := T.mundo(c)
		if _ocupado(p):
			continue
		p.y = T.altura(p.x, p.z) - 0.05
		var h := absi(hash(Vector2i(roundi(c.x * 100.0), roundi(c.y * 100.0))))
		var lejos := T.dist_caminos(c) > 6.0 or T.muro(c)
		var escala := (0.85 + float(h % 100) / 100.0 * 0.35) * (1.12 if lejos else 1.0)
		var giro := float(h % 628) / 100.0
		var tinte := Color(1, 1, 1)
		if tipo == "q_otono":
			tinte = Color(1.25, 0.86, 0.5)               # el árbol retorcido de la 2D: el único con hojas de otoño
		elif clase == "pradera":
			var k := float((h / 7) % 100) / 100.0
			tinte = Color(0.9 + k * 0.15, 0.95 + k * 0.1, 0.85 + k * 0.05)
		var cerca := minf(T.dist_caminos(c), T.dist_rincones(c) - 3.0)
		_arbol(clase, p, escala, giro, tinte, cerca <= hasta and clase != "pino")
	# la linde de fuera: un anillo de árboles macizos más allá del borde de la 2D (no se pisa: el terreno sube)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var x := -60.0
	while x <= 60.0:
		var z := -46.0
		while z <= 46.0:
			var c := T.casilla(x, z)
			var fuera := c.x < -0.5 or c.x > D.ANCHO + 0.5 or c.y < -0.5 or c.y > D.ALTO + 0.8
			if fuera and not (absf(c.x - D.SALIDA_X) < 3.0 and c.y > D.ALTO):
				var p := Vector3(x + rng.randf_range(-1.4, 1.4), 0.0, z + rng.randf_range(-1.4, 1.4))
				p.y = T.altura(p.x, p.z) - 0.05
				var clase := "pino" if rng.randf() < 0.3 else ("abedul" if rng.randf() < 0.15 else "pradera")
				_arbol(clase, p, rng.randf_range(1.0, 1.35), rng.randf() * TAU, Color(0.85, 0.9, 0.85), false)
			z += 3.4
		x += 3.4
	# los árboles viejos (también los que enmarcan el altar)
	for v in VIEJOS:
		_arbol_viejo(v[0], v[1], v[2], v[3])


func _ocupado(p: Vector3) -> bool:
	for l in _libres:
		if Vector2(p.x - l[0].x, p.z - l[0].z).length() < l[1]:
			return true
	return false


# Los árboles viejos (solo 3D, piezas sueltas con su choque): enmarcan la entrada, el puente, el claro, el campamento y
# el altar. [casilla, tipo, escala, giro]. El de la armadura va aparte (_crear_detalle).
const VIEJOS := [[Vector2(35.0, 52.6), "pradera", 1.6, 0.4], [Vector2(46.6, 51.4), "pradera", 1.5, 2.2],
	[Vector2(43.2, 36.4), "abedul", 1.35, 1.1], [Vector2(25.5, 23.0), "magico", 1.3, 0.7],
	[Vector2(21.5, 30.8), "pradera", 1.55, 3.0], [Vector2(21.5, 41.0), "pradera", 1.7, 1.7],
	[Vector2(33.6, 3.8), "pradera", 1.85, 0.9], [Vector2(42.6, 4.0), "pradera", 1.8, 2.6], [Vector2(38.2, 2.6), "magico", 1.5, 1.4]]


# Bajo y medio (rendimiento, 12/11): la copa de un árbol viejo sin las matas de dentro (las de «hondo» < HONDO_NUCLEO,
# la «mata de sombra» que solo se ve por los huecos) y, en su lugar, un núcleo opaco y oscuro (lóbulos al 62 %, pintado
# con las matas como las copas macizas, sin discard). Por los huecos se sigue viendo hojarasca oscura, pero cada píxel de
# la copa pasa por menos matas recortadas (la entrada tiene dos de estos árboles a cada lado del camino).
const HONDO_NUCLEO := 0.56


func _copa_vieja(tipo: String) -> Dictionary:
	var m: Dictionary = _malla_estilizada(tipo)
	if nombre_perfil == "alto" or not perfil.get("gb_viejos_nucleo", true):
		var clave_alto := "casco_" + tipo
		if not _mallas.has(clave_alto):
			_mallas[clave_alto] = {"copa": _casco_matas(m["copa"]), "nucleo": null}
		return _mallas[clave_alto]
	var hondo: float = perfil.get("gb_hondo", HONDO_NUCLEO)
	var clave := "vieja_%s_%s_%.2f" % [tipo, nombre_perfil, hondo]
	if _mallas.has(clave):
		return _mallas[clave]
	var lob: Array = Arbol.TIPOS[tipo]["lobulos"]
	var a: Array = m["copa"].surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var quedan := PackedInt32Array()
	for k in range(0, vs.size() - 5, 6):
		var mata := k / 6
		var l: Array = lob[mata % lob.size()]                  # arbol_estilizado.gd: la mata k va en el lóbulo k % n
		var centro: Vector3 = (vs[k] + vs[k + 2]) * 0.5
		if (centro - l[0]).length() / l[1] >= hondo:
			for j in 6:
				quedan.append(k + j)
	var nuevo := []
	nuevo.resize(Mesh.ARRAY_MAX)
	for t in Mesh.ARRAY_MAX:
		if a[t] == null or t == Mesh.ARRAY_INDEX:
			continue
		var por := 1
		if t == Mesh.ARRAY_CUSTOM0:
			por = 4
		elif t == Mesh.ARRAY_TANGENT:
			por = 4
		var origen = a[t]
		var dest = origen.duplicate()
		dest.resize(quedan.size() * por)
		for i in quedan.size():
			for p in por:
				dest[i * por + p] = origen[quedan[i] * por + p]
		nuevo[t] = dest
	var copa := ArrayMesh.new()
	copa.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, nuevo, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	for l in lob:
		var esf := SphereMesh.new()
		esf.radius = l[1] * 0.62
		esf.height = l[1] * 1.15
		esf.radial_segments = 8
		esf.rings = 4
		var ea := esf.get_mesh_arrays()
		var ev: PackedVector3Array = ea[Mesh.ARRAY_VERTEX]
		var en: PackedVector3Array = ea[Mesh.ARRAY_NORMAL]
		for i in ea[Mesh.ARRAY_INDEX]:
			var ao := clampf(0.42 + 0.18 * (en[i].y * 0.5 + 0.5), 0.4, 0.6)
			st.set_normal(en[i])
			st.set_color(Color(ao, ao * 1.04, ao * 0.95))
			st.set_custom(0, Color(l[0].x, l[0].y, l[0].z, l[1]))
			st.add_vertex(l[0] + ev[i])
	var res := {"copa": _casco_matas(copa), "nucleo": st.commit()}
	_mallas[clave] = res
	return res


# Rendimiento (rend2, 12/11): cada mata es un cuadro del atlas de matas, pero lo opaco (alfa >= 0,5) es solo el 26-42 %
# de su celda; el resto se rasterizaba y se descartaba (en el Mali, sin poder usar la eliminación de píxeles ocultos y
# con el sombreado hasta el descarte). Aquí cada cuadro se recorta a un octógono que contiene todo lo opaco de su celda
# (con margen: alfa >= 100/255 y 3 % más, para el filtrado y los mipmaps), el 61-68 % del cuadro: un tercio menos de
# fragmentos de hojas. Cada trozo cae dentro de uno de los dos triángulos del cuadro y sus atributos (posición, UV,
# normal, color y centro de la mata) se interpolan con los pesos de ese triángulo. Polígonos calculados sobre
# modelos/hojas/matas.png (pruebas/herramientas/casco_matas.py; prueba_casco_matas comprueba que lo cubren).
# APAGADO por defecto («gb_matas_casco», calidad_extra): no da la misma imagen al píxel. El viento del sombreado mueve
# cada vértice según su sitio (no es lineal) y la normal se guarda normalizada en los vértices nuevos: con el tiempo
# parado, en medio cambian 10 000-35 000 píxeles de 921 600 (hojas desplazadas un poco o con otra luz), sin que se
# note cuál es cuál. Comparación y medidas: docs/memory/agents/rendimiento_v12_rend2.md.
const MATAS_CASCO := [
	[Vector2(0.9685, 0.6872), Vector2(0.7341, 0.9216), Vector2(0.2971, 0.9216), Vector2(0.0296, 0.6540), Vector2(0.0296, 0.3284), Vector2(0.3030, 0.0550), Vector2(0.6892, 0.0550), Vector2(0.9685, 0.3343)],   # celda 0: 67 %
	[Vector2(0.9431, 0.6618), Vector2(0.6775, 0.9275), Vector2(0.3186, 0.9275), Vector2(0.0686, 0.6775), Vector2(0.0686, 0.3245), Vector2(0.3011, 0.0921), Vector2(0.7185, 0.0921), Vector2(0.9431, 0.3167)],   # celda 1: 61 %
	[Vector2(0.9529, 0.6501), Vector2(0.7009, 0.9021), Vector2(0.2718, 0.9021), Vector2(0.0471, 0.6775), Vector2(0.0471, 0.3499), Vector2(0.3186, 0.0784), Vector2(0.6872, 0.0784), Vector2(0.9529, 0.3440)],   # celda 2: 62 %
	[Vector2(0.9568, 0.6989), Vector2(0.7048, 0.9509), Vector2(0.3128, 0.9509), Vector2(0.0530, 0.6911), Vector2(0.0530, 0.2991), Vector2(0.2971, 0.0550), Vector2(0.7029, 0.0550), Vector2(0.9568, 0.3089)],   # celda 3: 68 %
]


func _casco_matas(malla: ArrayMesh) -> ArrayMesh:
	if not perfil.get("gb_matas_casco", false):
		return malla
	var a: Array = malla.surface_get_arrays(0)
	if a[Mesh.ARRAY_INDEX] != null or a[Mesh.ARRAY_TEX_UV] == null:
		return malla
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	# [tipo de array, valores por vértice]; lo que no esté se deja
	var campos: Array = []
	for t in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_CUSTOM0]:
		if a[t] != null:
			campos.append([t, 4 if t in [Mesh.ARRAY_TANGENT, Mesh.ARRAY_CUSTOM0] else 1])
	var sal := {}
	for c in campos:
		sal[c[0]] = []
	var poner := func(idx: Array, pesos: Array) -> void:
		for c in campos:
			var org = a[c[0]]
			if c[1] == 4:
				for j in 4:
					var x := 0.0
					for i in idx.size():
						x += org[idx[i] * 4 + j] * pesos[i]
					sal[c[0]].append(x)
			else:
				var x = org[idx[0]] * pesos[0]
				for i in range(1, idx.size()):
					x += org[idx[i]] * pesos[i]
				if c[0] == Mesh.ARRAY_NORMAL:
					x = (x as Vector3).normalized()
				sal[c[0]].append(x)
	for k in range(0, vs.size() - 5, 6):
		# el cuadro: A (celda 0,0), B (1,0), C (1,1) | A, C, D (0,1); si no es así, se deja tal cual
		var uv0 := Vector2(floorf(uvs[k].x * 2.0 + 0.01), floorf(uvs[k].y * 2.0 + 0.01)) * 0.5
		var loc: Array = []
		for j in [k, k + 1, k + 2, k + 5]:
			loc.append((uvs[j] - uv0) * 2.0)
		var cuadro: bool = (loc[0].distance_to(Vector2(0, 0)) < 0.01 and loc[1].distance_to(Vector2(1, 0)) < 0.01
			and loc[2].distance_to(Vector2(1, 1)) < 0.01 and loc[3].distance_to(Vector2(0, 1)) < 0.01
			and uvs[k + 3].is_equal_approx(uvs[k]) and uvs[k + 4].is_equal_approx(uvs[k + 2]))
		if not cuadro:
			for j in 6:
				poner.call([k + j], [1.0])
			continue
		var poli: Array = MATAS_CASCO[int(uv0.x > 0.25) + 2 * int(uv0.y > 0.25)]
		for mitad in 2:
			var trozo := _medio_plano(poli, 1.0 if mitad == 0 else -1.0)
			for i in range(1, trozo.size() - 1):
				var tri: Array = [trozo[0], trozo[i], trozo[i + 1]]
				if (tri[1] - tri[0]).cross(tri[2] - tri[0]) < 0.0:   # el mismo sentido que el triángulo original
					tri = [tri[0], tri[2], tri[1]]
				for q in tri:
					if mitad == 0:                      # A, B, C
						poner.call([k, k + 1, k + 2], [1.0 - q.x, q.x - q.y, q.y])
					else:                               # A, C, D
						poner.call([k, k + 2, k + 5], [1.0 - q.y, q.x, q.y - q.x])
	var nuevo := []
	nuevo.resize(Mesh.ARRAY_MAX)
	for c in campos:
		match c[0]:
			Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL:
				nuevo[c[0]] = PackedVector3Array(sal[c[0]])
			Mesh.ARRAY_COLOR:
				nuevo[c[0]] = PackedColorArray(sal[c[0]])
			Mesh.ARRAY_TEX_UV:
				nuevo[c[0]] = PackedVector2Array(sal[c[0]])
			_:
				nuevo[c[0]] = PackedFloat32Array(sal[c[0]])
	var r := ArrayMesh.new()
	r.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, nuevo, [], {},
		(Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) if a[Mesh.ARRAY_CUSTOM0] != null else 0)
	_sin_casco[r] = malla
	return r


var _sin_casco := {}                       # copa recortada → la de cuadros enteros (para comparar las dos)


# Pone en las copas de hojas ya creadas las mallas recortadas o las de cuadros enteros; devuelve cuántas cambió. Solo lo
# usan las medidas (pruebas/herramientas/medir_gpu_bosque.gd, «igualdad»): el juego nunca lo llama.
func alternar_casco(recortadas: bool) -> int:
	var n := 0
	for g in r.find_children("*", "GeometryInstance3D", true, false):
		var m: Mesh = null
		if g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
			m = (g as MultiMeshInstance3D).multimesh.mesh
		elif g is MeshInstance3D:
			m = (g as MeshInstance3D).mesh
		var otra: Mesh = null
		if not recortadas and _sin_casco.has(m):
			otra = _sin_casco[m]
		elif recortadas:
			for k in _sin_casco:
				if _sin_casco[k] == m:
					otra = k
		if otra != null:
			if g is MultiMeshInstance3D:
				(g as MultiMeshInstance3D).multimesh.mesh = otra
			else:
				(g as MeshInstance3D).mesh = otra
			n += 1
	return n


# El trozo del polígono (convexo, en la celda) a un lado de la diagonal u = v: lado 1, u >= v (triángulo A, B, C);
# lado -1, v >= u (A, C, D). Sutherland-Hodgman con un plano.
func _medio_plano(poli: Array, lado: float) -> Array:
	var r: Array = []
	for i in poli.size():
		var p: Vector2 = poli[i]
		var q: Vector2 = poli[(i + 1) % poli.size()]
		var dp := (p.x - p.y) * lado
		var dq := (q.x - q.y) * lado
		if dp >= 0.0:
			r.append(p)
		if dp * dq < 0.0:
			r.append(p + (q - p) * (dp / (dp - dq)))
	return r


func _arbol_viejo(c: Vector2, tipo: String, escala: float, giro: float) -> Node3D:
	var pie := T.en_mundo(c) - Vector3(0, 0.1, 0)
	var m: Dictionary = _malla_estilizada(tipo)
	var cv := _copa_vieja(tipo)
	var nodo := Node3D.new()
	nodo.name = "ArbolViejo"
	nodo.position = pie
	nodo.rotation.y = giro
	nodo.scale = Vector3.ONE * escala
	r.add_child(nodo)
	var tronco := MeshInstance3D.new()
	tronco.mesh = m["tronco"]
	tronco.material_override = _mat_tronco
	nodo.add_child(tronco)
	var copa := MeshInstance3D.new()
	copa.mesh = cv["copa"]
	copa.material_override = _mat_hojas[tipo]
	nodo.add_child(copa)
	if cv["nucleo"] != null:
		var nucleo := MeshInstance3D.new()
		nucleo.name = "Nucleo"
		nucleo.mesh = cv["nucleo"]
		nucleo.material_override = _mat_copa_maciza["abedul" if tipo == "abedul" else "pradera"]
		nucleo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nodo.add_child(nucleo)
	if perfil.get("sombras", false) and perfil.get("arbol_sombra_simple", false):
		copa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var s := MeshInstance3D.new()
		s.mesh = m["sombra"]
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		nodo.add_child(s)
	elif not perfil.get("sombras", false):
		copa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tronco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if Arbol.TIPOS[tipo].get("motas", false):
		nodo.add_child(Arbol._motas(m["centro_copa"], m["radio_copa"]))
	_raices(pie, escala, giro, 5)
	obstaculo(pie.x, pie.z, Arbol.TIPOS[tipo]["tronco"][1] * escala + 0.15)
	arboles.append([pie, m["radio_copa"] * escala * 1.1])
	return nodo


# Raíces que salen del pie de un árbol viejo y se hunden en el suelo (tubos curvos, al lote de la corteza).
var _mat_raiz: StandardMaterial3D


func _raices(pie: Vector3, escala: float, giro: float, n: int) -> void:
	if _mat_raiz == null:
		_mat_raiz = mat_detalle(Color(0.40, 0.30, 0.22), 1.3, false, 1.0)
	for k in n:
		var a := giro + k * TAU / n + _rng.randf_range(-0.3, 0.3)
		var dir := Vector3(cos(a), 0, sin(a))
		var largo := escala * _rng.randf_range(0.9, 1.5)
		var pasos := 4
		for s in pasos:
			var f0 := float(s) / pasos
			var f1 := float(s + 1) / pasos
			var p0 := pie + dir * (0.25 * escala + largo * f0)
			var p1 := pie + dir * (0.25 * escala + largo * f1)
			p0.y = T.altura(p0.x, p0.z) + 0.32 * escala * (1.0 - f0) * (1.0 - f0) - 0.04
			p1.y = T.altura(p1.x, p1.z) + 0.32 * escala * (1.0 - f1) * (1.0 - f1) - 0.04
			var cm := CylinderMesh.new()
			var r0 := 0.17 * escala * (1.0 - f0 * 0.75)
			cm.bottom_radius = r0
			cm.top_radius = 0.17 * escala * (1.0 - f1 * 0.75)
			cm.height = p0.distance_to(p1) + 0.06
			cm.radial_segments = 6
			cm.rings = 1
			var eje := (p1 - p0).normalized()
			var bx := eje.cross(Vector3.FORWARD if absf(eje.z) < 0.9 else Vector3.RIGHT).normalized()
			var b := Basis(bx, eje, bx.cross(eje).normalized())
			_al_lote(cm, Transform3D(b.orthonormalized(), (p0 + p1) * 0.5), _mat_raiz)


# ================================================================= suelo

# Manchas de luz: lo que tapan las copas, desplazado hacia donde cae la luz del sol, y unos huecos por donde se cuela.
func _cobertura() -> Dictionary:
	var res := 1.0
	var w := int(ceil((T.REJILLA_N.x - 1) * T.REJILLA_PASO / res)) + 1
	var h := int(ceil((T.REJILLA_N.y - 1) * T.REJILLA_PASO / res)) + 1
	var g := PackedFloat32Array()
	g.resize(w * h)
	var corre := Vector2(_sol_dir.x, _sol_dir.z) / maxf(-_sol_dir.y, 0.3) * 3.2     # la sombra cae a ~3 m del pie
	for a in arboles:
		var pie: Vector3 = a[0]
		var rad: float = a[1]
		var cx := (pie.x + corre.x - T.REJILLA_MIN.x) / res
		var cz := (pie.z + corre.y - T.REJILLA_MIN.y) / res
		var rr := rad / res
		for j in range(maxi(0, int(cz - rr)), mini(h, int(cz + rr) + 2)):
			for i in range(maxi(0, int(cx - rr)), mini(w, int(cx + rr) + 2)):
				var d := Vector2(i - cx, j - cz).length() / rr
				if d < 1.0:
					g[j * w + i] = minf(1.0, g[j * w + i] + (1.0 - d * d) * 0.75)
	return {"g": g, "w": w, "h": h, "res": res}


func _crear_terreno() -> void:
	var cob := _cobertura()
	var g: PackedFloat32Array = cob["g"]
	var cw: int = cob["w"]
	var ruido := FastNoiseLite.new()
	ruido.seed = 31
	ruido.frequency = 0.16
	var ruido2 := FastNoiseLite.new()
	ruido2.seed = 77
	ruido2.frequency = 0.045
	var con_sombras: bool = perfil.get("sombras", false)
	var fuerza_manchas := 0.4 if con_sombras else 0.72
	var nx := T.REJILLA_N.x
	var nz := T.REJILLA_N.y
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var claro := T.mundo(T.lugar("claro"))
	for j in nz:
		for i in nx:
			var x := T.REJILLA_MIN.x + i * T.REJILLA_PASO
			var z := T.REJILLA_MIN.y + j * T.REJILLA_PASO
			var y := T.altura_rejilla(i, j)
			var dx := T.altura_rejilla(i + 1, j) - T.altura_rejilla(i - 1, j)
			var dz := T.altura_rejilla(i, j + 1) - T.altura_rejilla(i, j - 1)
			var pendiente := clampf(sqrt(dx * dx + dz * dz) / (2.0 * T.REJILLA_PASO), 0.0, 1.0)
			var c := T.casilla(x, z)
			# suelo del bosque: musgo oscuro y hojarasca a manchas
			var n1 := ruido.get_noise_2d(x, z) * 0.5 + 0.5
			var n2 := ruido2.get_noise_2d(x, z) * 0.5 + 0.5
			var col := Color(0.18, 0.27, 0.12).lerp(Color(0.33, 0.27, 0.16), smoothstep(0.45, 0.75, n1) * 0.8)
			col = col.lerp(Color(0.26, 0.38, 0.16), smoothstep(0.55, 0.85, n2) * 0.6)
			var dc := T.dist_rejilla(i, j)
			if dc < 1.0 or T.en_camino_2d(c):            # la tierra del camino, con el borde roto
				var k := 1.0 - smoothstep(0.7, 1.25, dc + (n1 - 0.5) * 0.5)
				col = col.lerp(Color(0.46, 0.36, 0.24).lerp(Color(0.40, 0.31, 0.21), n2), k)
			var dcl := Vector2(x - claro.x, z - claro.z).length()
			if dcl < 7.0:                                # el claro: hierba al sol
				col = col.lerp(Color(0.38, 0.52, 0.22), (1.0 - smoothstep(3.5, 7.0, dcl)) * 0.75)
			var w := T.agua(c)
			if w > 0.15:                                 # orilla húmeda y fondo
				col = col.lerp(Color(0.18, 0.21, 0.14), smoothstep(0.15, 0.45, w))
			if c.distance_to(T.MIRADOR_2D) < T.MIRADOR_FALDA + 0.5 and y > 0.4:
				col = col.lerp(Color(0.46, 0.45, 0.40), smoothstep(0.35, 0.7, pendiente) * 0.85)   # la roca de la loma
			col = col.lerp(Color(0.34, 0.33, 0.30), smoothstep(0.55, 0.9, pendiente) * 0.6)
			# luz filtrada: sombra de las copas con huecos de sol
			var gi := clampi(int((x - T.REJILLA_MIN.x) / cob["res"]), 0, cw - 1)
			var gj := clampi(int((z - T.REJILLA_MIN.y) / cob["res"]), 0, int(cob["h"]) - 1)
			var cubre := g[gj * cw + gi]
			var hueco_sol := smoothstep(0.62, 0.8, ruido.get_noise_2d(x * 1.7 + 40.0, z * 1.7) * 0.5 + 0.5)
			var luz := 1.0 - fuerza_manchas * cubre * (1.0 - hueco_sol * 0.85)
			luz += 0.18 * hueco_sol * cubre                # el sol que se cuela brilla algo más
			st.set_color(Color(col.r * luz, col.g * luz, col.b * luz))
			st.set_uv(Vector2(x, z) * 0.25)
			st.add_vertex(Vector3(x, y, z))
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			st.add_index(a); st.add_index(a + 1); st.add_index(a + nx)
			st.add_index(a + 1); st.add_index(a + nx + 1); st.add_index(a + nx)
	st.generate_normals()
	# bajo y medio: el grano (y el relieve del medio) con las UV del suelo (x, z · 0,25) en vez de triplanar: 1 lectura
	# por textura en vez de 3 en toda la pantalla; el suelo es casi llano y el grano es un ruido suave (no se nota)
	var plano: bool = nombre_perfil != "alto" and perfil.get("gb_suelo_plano", true)
	if plano and perfil.get("relieve", true):       # tangentes solo para el relieve del medio (+40 ms en el PC)
		st.generate_tangents()
	var malla := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Suelo"
	mi.mesh = malla
	var ms := mat_detalle(Color.WHITE, 0.45, true, 0.5)
	if plano:
		ms.uv1_triplanar = false
		ms.uv1_world_triplanar = false
		ms.uv1_scale = Vector3.ONE * (0.45 / 0.25)
	if perfil.get("gb_orden", true):              # (rend2) el suelo, lo último de lo opaco: casi todo lo tapa
		ms.render_priority = int(perfil.get("gb_prio_fondo", PRIO_FONDO))
	mi.material_override = ms
	if nombre_perfil != "alto":                  # el suelo recibe sombra, no la da (salvo en alto: la loma del mirador)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "SueloChoque"
	r.add_child(cuerpo)
	cuerpo.add_child(mi)
	var col := CollisionShape3D.new()
	col.shape = malla.create_trimesh_shape()
	cuerpo.add_child(col)


# ================================================================= agua

# El agua del bosque: oscura y quieta, con brillos que se mueven y la orilla algo más clara. Su forma es la de la 2D
# (la máscara de agua de zona.gd, suavizada): fuera de ella no se dibuja, así la orilla no sale en escalones de la malla.
const SHADER_AGUA := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D mascara : filter_linear, repeat_disable;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec2 origen;
uniform float k = 1.25;
uniform vec2 tam = vec2(81.0, 57.0);
uniform vec3 hondo : source_color = vec3(0.04, 0.11, 0.10);
uniform vec3 orilla : source_color = vec3(0.16, 0.24, 0.17);
uniform vec3 brillo : source_color = vec3(0.9, 0.95, 0.8);
varying vec3 mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 c = (mundo.xz - origen) / k;
	float w = texture(mascara, (c + 0.5) / tam).r;
	if (w < 0.5) {
		discard;
	}
	float n1 = texture(ruido, mundo.xz * 0.07 + TIME * vec2(0.010, 0.004)).r;
	float n2 = texture(ruido, mundo.xz * 0.11 - TIME * vec2(0.006, 0.009)).r;
	n1 = clamp((n1 - 0.74) / 0.32, 0.0, 1.0);          // el grano va de 0,74 a 1,06
	n2 = clamp((n2 - 0.74) / 0.32, 0.0, 1.0);
	float destello = smoothstep(0.8, 0.94, (n1 + n2) * 0.5);
	float borde = 1.0 - smoothstep(0.5, 0.68, w);
	vec3 base = mix(hondo, orilla, borde * 0.85) * (0.92 + 0.16 * n1);
	ALBEDO = base;
	EMISSION = brillo * destello * 0.35 + orilla * borde * 0.2;
	ROUGHNESS = 0.3;
	SPECULAR = 0.35;
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4((n1 - 0.5) * 0.12, 0.0, (n2 - 0.5) * 0.12, 0.0)).xyz);
}
"""


func _mat_agua() -> Material:
	var sm := ShaderMaterial.new()
	sm.shader = _shader(SHADER_AGUA)
	var img := Image.create(D.ANCHO + 1, D.ALTO + 1, false, Image.FORMAT_L8)
	for j in D.ALTO + 1:
		for i in D.ANCHO + 1:
			img.set_pixel(i, j, Color.WHITE if D.AGUA.unicode_at(j * (D.ANCHO + 1) + i) == 49 else Color.BLACK)
	sm.set_shader_parameter("mascara", ImageTexture.create_from_image(img))
	sm.set_shader_parameter("ruido", grano)
	var o := T.mundo(Vector2.ZERO)
	sm.set_shader_parameter("origen", Vector2(o.x, o.z))
	sm.set_shader_parameter("k", T.K)
	sm.set_shader_parameter("tam", Vector2(D.ANCHO + 1, D.ALTO + 1))
	return sm

# El arroyo y las charcas de la 2D: una lámina por grupo de agua (su rectángulo), todas en una malla.
func _crear_agua() -> void:
	var vw := D.ANCHO + 1
	var vh := D.ALTO + 1
	var visto := PackedByteArray()
	visto.resize(vw * vh)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hay := false
	for j in vh:
		for i in vw:
			if visto[j * vw + i] != 0 or D.AGUA.unicode_at(j * vw + i) != 49:
				continue
			var pila := [Vector2i(i, j)]
			visto[j * vw + i] = 1
			var mn := Vector2i(i, j)
			var mx := Vector2i(i, j)
			while not pila.is_empty():
				var q: Vector2i = pila.pop_back()
				mn = Vector2i(mini(mn.x, q.x), mini(mn.y, q.y))
				mx = Vector2i(maxi(mx.x, q.x), maxi(mx.y, q.y))
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = q + d
					if n.x < 0 or n.y < 0 or n.x >= vw or n.y >= vh or visto[n.y * vw + n.x] != 0:
						continue
					if D.AGUA.unicode_at(n.y * vw + n.x) == 49:
						visto[n.y * vw + n.x] = 1
						pila.append(n)
			var a := T.mundo(Vector2(mn) - Vector2(1.2, 1.2))
			var b := T.mundo(Vector2(mx) + Vector2(1.2, 1.2))
			var pasos_x := maxi(1, int((b.x - a.x) / 2.5))
			var pasos_z := maxi(1, int((b.z - a.z) / 2.5))
			for sj in pasos_z:
				for si in pasos_x:
					var x0 := lerpf(a.x, b.x, float(si) / pasos_x)
					var x1 := lerpf(a.x, b.x, float(si + 1) / pasos_x)
					var z0 := lerpf(a.z, b.z, float(sj) / pasos_z)
					var z1 := lerpf(a.z, b.z, float(sj + 1) / pasos_z)
					if T.altura(x0, z0) > T.AGUA_Y + 0.25 and T.altura(x1, z0) > T.AGUA_Y + 0.25 \
							and T.altura(x0, z1) > T.AGUA_Y + 0.25 and T.altura(x1, z1) > T.AGUA_Y + 0.25 \
							and T.altura((x0 + x1) * 0.5, (z0 + z1) * 0.5) > T.AGUA_Y + 0.25:
						continue                          # todo seco: sin lámina (menos píxeles de agua tapados)
					for v in [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x0, 0, z1), Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1)]:
						st.set_normal(Vector3.UP)
						st.set_uv(Vector2(v.x, v.z))
						st.add_vertex(Vector3(v.x, T.AGUA_Y, v.z))
					hay = true
	if not hay:
		return
	var mi := MeshInstance3D.new()
	mi.name = "Agua"
	mi.mesh = st.commit()
	mi.material_override = _mat_agua()
	if perfil.get("gb_orden", true):              # (rend2) con el suelo, detrás de lo demás
		mi.material_override.render_priority = int(perfil.get("gb_prio_fondo", PRIO_FONDO))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(mi)
	# piedras de la orilla y juncos en el arroyo
	var piedra := mat_detalle(Color(0.42, 0.43, 0.40), 0.8, false, 1.0)
	for k in 70:
		var c := Vector2(_rng.randf_range(2, D.ANCHO - 2), _rng.randf_range(2, D.ALTO - 2))
		var w := T.agua(c)
		if w < 0.35 or w > 0.62 or T.en_puente(c, 1.0) or T.dist_caminos(c) < 1.5:
			continue
		var p := T.en_mundo(c)
		_roca(p + Vector3(0, -0.05, 0), _rng.randf_range(0.18, 0.42), piedra)


# ================================================================= puentes

var _mat_madera: StandardMaterial3D
var _mat_madera_osc: StandardMaterial3D


func _crear_puentes() -> void:
	_mat_madera = mat_detalle(Color(0.52, 0.38, 0.25), 1.4, false, 1.0)
	_mat_madera_osc = mat_detalle(Color(0.36, 0.26, 0.18), 1.4, false, 1.0)
	for pu in T.puentes_3d():
		var centro := T.mundo(pu[0])
		var dir2: Vector2 = pu[1]
		var dir := Vector3(dir2.x, 0, dir2.y).normalized()
		var lado := Vector3(-dir.z, 0, dir.x)
		var largo: float = pu[2] * T.K
		var ancho := 2.2
		var extremo_a := centro - dir * largo * 0.5
		var extremo_b := centro + dir * largo * 0.5
		var y := maxf(T.altura(extremo_a.x, extremo_a.z), T.altura(extremo_b.x, extremo_b.z)) + 0.1
		y = maxf(y, T.AGUA_Y + 0.45)
		var giro := atan2(dir.x, dir.z)
		var b := Basis(Vector3.UP, giro)
		# vigas (dos troncos) y tablones atravesados
		for s: float in [-0.75, 0.75]:
			var cm := CylinderMesh.new()
			cm.top_radius = 0.16
			cm.bottom_radius = 0.18
			cm.height = largo + 0.4
			cm.radial_segments = 7
			cm.rings = 1
			_al_lote(cm, Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5), centro + lado * s + Vector3(0, y - 0.22, 0)), _mat_madera_osc)
		var tablones := int(largo / 0.32)
		for k in tablones:
			var f := (k + 0.5) / tablones - 0.5
			var p := centro + dir * f * largo + Vector3(0, y - 0.04, 0)
			var bm := BoxMesh.new()
			bm.size = Vector3(ancho + _rng.randf_range(-0.12, 0.12), 0.08, 0.28)
			_al_lote(bm, Transform3D(b * Basis(Vector3.UP, _rng.randf_range(-0.04, 0.04)), p), _mat_madera if k % 3 else _mat_madera_osc)
		# barandilla, solo sobre el agua (los extremos, abiertos: de ahí salen los caminos): postes y un pasamanos
		var tramo: float = pu[3] * T.K * 0.8
		for s: float in [-1.0, 1.0]:
			for k in 4:
				var f := (-0.5 + k / 3.0) * tramo / largo
				var p := centro + dir * f * largo + lado * s * (ancho * 0.5 - 0.05)
				var cm := CylinderMesh.new()
				cm.top_radius = 0.06
				cm.bottom_radius = 0.08
				cm.height = 1.0
				cm.radial_segments = 6
				_al_lote(cm, Transform3D(Basis(), p + Vector3(0, y + 0.45, 0)), _mat_madera_osc)
			var pm := CylinderMesh.new()
			pm.top_radius = 0.05
			pm.bottom_radius = 0.05
			pm.height = tramo
			pm.radial_segments = 6
			_al_lote(pm, Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5), centro + lado * s * (ancho * 0.5 - 0.05) + Vector3(0, y + 0.9, 0)), _mat_madera)
			_caja_choque(centro + lado * s * (ancho * 0.5 + 0.05) + Vector3(0, y + 0.5, 0), Vector3(0.2, 1.0, tramo), giro)
		_caja_choque(centro + Vector3(0, y - 0.12, 0), Vector3(ancho, 0.24, largo), giro)


func _caja_choque(pos: Vector3, tam: Vector3, giro := 0.0) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	cuerpo.rotation.y = giro
	r.add_child(cuerpo)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = tam
	col.shape = bs
	cuerpo.add_child(col)
	return cuerpo


# ================================================================= el camino

# Tierra pisada (en el color del suelo) con piedras planas sueltas y alguna raíz que lo cruza.
func _crear_camino() -> void:
	var piedra := mat_detalle(Color(0.55, 0.53, 0.48), 1.2, false, 1.0)
	for cam in D.CAMINOS:
		for i in cam.size() - 1:
			var a: Vector2 = cam[i]
			var b: Vector2 = cam[i + 1]
			var n := int(a.distance_to(b) / 1.6)
			for k in n:
				var c: Vector2 = a.lerp(b, (k + _rng.randf()) / maxf(n, 1)) + Vector2(_rng.randf_range(-0.9, 0.9), _rng.randf_range(-0.9, 0.9))
				if T.en_puente(c, 0.6) or T.agua(c) > 0.2 or c.y > D.ALTO - 1.0:
					continue
				var p := T.en_mundo(c)
				if _rng.randf() < 0.55:
					var cm := CylinderMesh.new()
					cm.top_radius = _rng.randf_range(0.18, 0.32)
					cm.bottom_radius = cm.top_radius + 0.04
					cm.height = 0.1
					cm.radial_segments = 7
					cm.rings = 1
					_al_lote(cm, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.0, 1.0, _rng.randf_range(0.7, 1.0))), p + Vector3(0, 0.0, 0)), piedra)


# ================================================================= rocas

func _roca(p: Vector3, rad: float, mat: Material, choca := false) -> void:
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 1.3
	sm.radial_segments = 8
	sm.rings = 5
	var b := Basis.from_euler(Vector3(_rng.randf(), _rng.randf() * TAU, _rng.randf()) * 0.4).scaled(
		Vector3(_rng.randf_range(0.9, 1.3), _rng.randf_range(0.7, 1.0), _rng.randf_range(0.9, 1.2)))
	_al_lote(sm, Transform3D(b, p), mat)
	if choca:
		obstaculo(p.x, p.z, rad * 1.05)


var _mat_roca_musgo: StandardMaterial3D


func _roca_musgo() -> StandardMaterial3D:
	if _mat_roca_musgo == null:
		_mat_roca_musgo = mat_detalle(Color(0.46, 0.50, 0.40), 0.8, false, 1.0)
	return _mat_roca_musgo


# ================================================================= sotobosque y hierba

func _helecho() -> Mesh:
	if _mallas.has("helecho"):
		return _mallas["helecho"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hojas := 6
	for k in hojas:
		var a := k * TAU / hojas + 0.3 * sin(k * 2.0)
		var dir := Vector3(cos(a), 0, sin(a))
		var lado := Vector3(-dir.z, 0, dir.x)
		var largo := 0.75 + 0.15 * sin(k * 1.7)
		var pts := []
		for s in 4:                                  # la fronda se arquea y se estrecha
			var f := s / 3.0
			var p := dir * largo * f + Vector3(0, sin(f * 2.2) * 0.42, 0)
			var w := 0.15 * (1.0 - f * 0.85)
			pts.append([p - lado * w, p + lado * w, f])
		for s in 3:
			var c0 := Color(0.17, 0.33, 0.13).lerp(Color(0.38, 0.56, 0.22), pts[s][2])
			var c1 := Color(0.17, 0.33, 0.13).lerp(Color(0.38, 0.56, 0.22), pts[s + 1][2])
			var q := [[pts[s][0], c0], [pts[s][1], c0], [pts[s + 1][1], c1], [pts[s + 1][0], c1]]
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(q[i][1])
				st.add_vertex(q[i][0])
	st.generate_normals()
	var m := st.commit()
	_mallas["helecho"] = m
	return m


func _mata() -> Mesh:
	if _mallas.has("mata"):
		return _mallas["mata"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for l in [[Vector3(0, 0.32, 0), 0.5], [Vector3(0.38, 0.24, 0.12), 0.38], [Vector3(-0.32, 0.22, -0.18), 0.4]]:
		var esf := SphereMesh.new()
		esf.radius = l[1]
		esf.height = l[1] * 1.6
		esf.radial_segments = 8
		esf.rings = 5
		var a := esf.get_mesh_arrays()
		var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		for i in a[Mesh.ARRAY_INDEX]:
			var n: Vector3 = ns[i]
			var ao := 0.55 + 0.45 * (n.y * 0.5 + 0.5)
			st.set_normal((n + Vector3.UP * 0.3).normalized())
			st.set_color(Color(0.22 * ao, 0.40 * ao, 0.17 * ao))
			st.add_vertex(l[0] + vs[i])
	var m := st.commit()
	_mallas["mata"] = m
	return m


func _seta() -> Mesh:
	if _mallas.has("seta"):
		return _mallas["seta"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in [[Vector3(0, 0, 0), 1.0], [Vector3(0.14, 0, 0.08), 0.7], [Vector3(-0.1, 0, 0.12), 0.55]]:
		var o: Vector3 = s[0]
		var e: float = s[1]
		var pie := CylinderMesh.new()
		pie.top_radius = 0.035 * e
		pie.bottom_radius = 0.045 * e
		pie.height = 0.16 * e
		pie.radial_segments = 5
		pie.rings = 1
		var sombrero := CylinderMesh.new()
		sombrero.top_radius = 0.01
		sombrero.bottom_radius = 0.13 * e
		sombrero.height = 0.08 * e
		sombrero.radial_segments = 7
		sombrero.rings = 1
		for parte in [[pie, o + Vector3(0, 0.08 * e, 0), Color(0.86, 0.82, 0.72)], [sombrero, o + Vector3(0, 0.19 * e, 0), Color(0.78, 0.36, 0.18)]]:
			var a: Array = parte[0].get_mesh_arrays()
			var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
			for i in a[Mesh.ARRAY_INDEX]:
				st.set_normal(ns[i])
				st.set_color(parte[2])
				st.add_vertex(parte[1] + vs[i])
	var m := st.commit()
	_mallas["seta"] = m
	return m


func _flor() -> Mesh:
	if _mallas.has("flor"):
		return _mallas["flor"]
	var f := SphereMesh.new()
	f.radius = 0.07
	f.height = 0.14
	f.radial_segments = 6
	f.rings = 3
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := f.get_mesh_arrays()
	for i in a[Mesh.ARRAY_INDEX]:
		st.set_normal(a[Mesh.ARRAY_NORMAL][i])
		st.set_color(Color.WHITE)
		st.add_vertex(a[Mesh.ARRAY_VERTEX][i])
	var m := st.commit()
	_mallas["flor"] = m
	return m


func _sotobosque() -> void:
	var dist := _dist(1)
	var no := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var colores_flor := [Color(0.55, 0.62, 1.0), Color(0.97, 0.95, 0.88), Color(1.0, 0.85, 0.35), Color(0.9, 0.55, 0.75)]
	for o in D.OBJETOS:
		var tipo: String = o[0]
		var c: Vector2 = o[1]
		var p := T.en_mundo(c)
		var h := absi(hash(Vector2i(roundi(c.x * 100.0), roundi(c.y * 100.0))))
		var giro := float(h % 628) / 100.0
		match tipo:
			"helecho", "q_helecho", "q_planta":
				for k in 2:
					var q := p + Vector3(_rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.5, 0.5))
					q.y = T.altura(q.x, q.z)
					_poner("helecho", _helecho(), _mat_macizo_fino, Transform3D(Basis(Vector3.UP, giro + k).scaled(Vector3.ONE * _rng.randf_range(0.9, 1.4)), q), Color(1, 1, 1), no, dist)
			"arbusto", "q_arbusto":
				_poner("mata", _mata(), _mat_macizo_fino, Transform3D(Basis(Vector3.UP, giro).scaled(Vector3.ONE * _rng.randf_range(0.9, 1.5)), p), Color(0.9 + _rng.randf() * 0.2, 1, 0.9), no, dist)
			"q_setas":
				_poner("seta", _seta(), _mat_macizo_fino, Transform3D(Basis(Vector3.UP, giro).scaled(Vector3.ONE * _rng.randf_range(0.9, 1.6)), p), Color(1, 1, 1), no, dist)
			"q_roca":
				_roca(p + Vector3(0, 0.1, 0), _rng.randf_range(0.35, 0.8), _roca_musgo(), true)
			"flor_azul", "q_flores", "q_flores_amarillas", "hierba_alta":
				var col: Color = colores_flor[0] if tipo == "flor_azul" else (colores_flor[2] if tipo == "q_flores_amarillas" else colores_flor[1 + h % 3])
				for k in 9:
					var q := p + Vector3(_rng.randf_range(-0.7, 0.7), 0, _rng.randf_range(-0.7, 0.7))
					q.y = T.altura(q.x, q.z) + _rng.randf_range(0.18, 0.34)
					if tipo == "hierba_alta":
						continue
					_poner("flor", _flor(), _mat_flor(), Transform3D(Basis(), q), col, no, dist)
	# más helechos y setas: al pie de los árboles y en la orilla de los caminos (el bosque viejo)
	var n: int = HELECHOS_EXTRA[nombre_perfil]
	var puestos := 0
	var intentos := 0
	while puestos < n and intentos < n * 6:
		intentos += 1
		var c := Vector2(_rng.randf_range(2.5, D.ANCHO - 2.5), _rng.randf_range(2.5, D.ALTO - 1.5))
		var dc := T.dist_caminos(c)
		if dc < 1.15 or T.agua(c) > 0.3 or T.dist_rincones(c) < 2.2 or T.muro(c) or T.en_puente(c, 1.0):
			continue
		if dc > 4.0 and _rng.randf() < 0.55:
			continue                                 # más junto a los caminos, donde se ve
		var p := T.en_mundo(c)
		if bloqueado(p.x, p.z):
			continue
		if _rng.randf() < 0.86:
			_poner("helecho", _helecho(), _mat_macizo_fino, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.5)), p), Color(_rng.randf_range(0.85, 1.1), 1, _rng.randf_range(0.85, 1.0)), no, dist)
		else:
			_poner("seta", _seta(), _mat_macizo_fino, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.4)), p), Color(1, 1, 1), no, dist)
		puestos += 1


var _mat_flor_cache: StandardMaterial3D


func _mat_flor() -> StandardMaterial3D:
	if _mat_flor_cache == null:
		_mat_flor_cache = StandardMaterial3D.new()
		_mat_flor_cache.vertex_color_use_as_albedo = true
		_mat_flor_cache.roughness = 0.8
	return _mat_flor_cache


# Hierba: menos que en Pastos (el suelo del bosque es de musgo y hojas), en el claro, junto a los rincones y en el borde
# de los caminos; en trozos que se recortan.
func _hierba() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a := k * PI / 3.0
		var d := Vector3(cos(a), 0, sin(a)) * 0.07
		st.set_normal(Vector3.UP)
		st.add_vertex(-d)
		st.add_vertex(d)
		st.add_vertex(Vector3(0, 0.45, 0) + d * 0.2)
	var hoja_h := st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = _shader(SHADER_HIERBA)
	var n := int(int(perfil.get("hierba", 3000)) * 0.45)
	var claro := T.lugar("claro")
	var puestos := 0
	var intentos := 0
	var dist := _dist(2)
	while puestos < n and intentos < n * 5:
		intentos += 1
		var c: Vector2
		var u := _rng.randf()
		if u < 0.35:
			c = claro + Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * 5.5
		elif u < 0.6:
			var l: Array = D.LUGARES[_rng.randi() % D.LUGARES.size()]
			c = l[1] + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(2.0, 5.0)
		else:
			c = Vector2(_rng.randf_range(2, D.ANCHO - 2), _rng.randf_range(2, D.ALTO - 1))
			var dc := T.dist_caminos(c)
			if dc < 0.9 or dc > 2.6:
				continue
		if T.agua(c) > 0.3 or T.muro(c) or T.en_camino_2d(c) and c.distance_to(claro) > 3.0:
			continue
		var p := T.en_mundo(c)
		var e := _rng.randf_range(0.6, 1.3)
		var tono := _rng.randf_range(0.85, 1.1)
		_poner("hierba", hoja_h, mat, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(e, e * _rng.randf_range(0.8, 1.3), e)), p), Color(tono, tono, tono * 0.95), GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, dist)
		puestos += 1


# ================================================================= rincones de la 2D

var _mat_piedra_ruina: StandardMaterial3D


func _crear_rincones() -> void:
	_mat_piedra_ruina = mat_detalle(Color(0.60, 0.60, 0.55), 0.9, false, 1.0)
	var musgo := mat_detalle(Color(0.34, 0.46, 0.24), 0.9, false, 0.8)
	for o in D.OBJETOS:
		var tipo: String = o[0]
		var c: Vector2 = o[1]
		var p := T.en_mundo(c)
		var h := absi(hash(Vector2i(roundi(c.x * 100.0), roundi(c.y * 100.0))))
		match tipo:
			"columna":                               # columnas de las ruinas: alguna rota
				var alto := 1.4 + float(h % 100) / 100.0 * 1.8
				var rota := h % 3 != 0
				_al_lote(_cilindro(0.5, 0.55, 0.3, 8), Transform3D(Basis(), p + Vector3(0, 0.12, 0)), _mat_piedra_ruina)
				_al_lote(_cilindro(0.3, 0.33, alto, 8), Transform3D(Basis(), p + Vector3(0, alto * 0.5 + 0.25, 0)), _mat_piedra_ruina)
				if rota:
					_al_lote(_cilindro(0.02, 0.3, 0.35, 8), Transform3D(Basis(Vector3.FORWARD, 0.25), p + Vector3(0, alto + 0.4, 0)), _mat_piedra_ruina)
					var caida := p + Vector3(cos(h * 0.1), 0, sin(h * 0.1)) * 1.4
					caida.y = T.altura(caida.x, caida.z) + 0.25
					_al_lote(_cilindro(0.3, 0.3, 0.9, 8), Transform3D(Basis(Vector3(cos(h * 0.1), 0, sin(h * 0.1)).cross(Vector3.UP).normalized(), PI * 0.5), caida), _mat_piedra_ruina)
				else:
					var bm := BoxMesh.new()
					bm.size = Vector3(0.85, 0.28, 0.85)
					_al_lote(bm, Transform3D(Basis(), p + Vector3(0, alto + 0.39, 0)), _mat_piedra_ruina)
				_al_lote(_cilindro(0.34, 0.36, 0.12, 8), Transform3D(Basis(), p + Vector3(0, minf(alto, 1.2) + 0.25, 0)), musgo)
				_cilindro_choque(p, 0.4, alto + 0.5)
			"muro_ruina":                            # un lienzo de muro roto: sillares que faltan
				var giro := float(h % 314) / 100.0
				var b := Basis(Vector3.UP, giro)
				for fila in 3:
					for col in 4:
						if (h >> (fila * 4 + col)) & 1 == 1 and fila > 0:
							continue
						var bm := BoxMesh.new()
						bm.size = Vector3(0.62, 0.42, 0.55)
						var off := Vector3((col - 1.5) * 0.64 + (0.3 if fila % 2 else 0.0), 0.21 + fila * 0.43, 0)
						_al_lote(bm, Transform3D(b * Basis(Vector3.UP, _rng.randf_range(-0.05, 0.05)), p + b * off), _mat_piedra_ruina if (fila + col) % 3 else musgo)
				_caja_choque(p + Vector3(0, 0.6, 0), Vector3(2.7, 1.2, 0.6), giro)
			"brasero":                               # el fuego del campamento: un círculo de piedras y leña
				_hoguera(p)
			"tronco":                                # troncos para sentarse alrededor del fuego
				var hacia := (T.mundo(T.lugar("campamento")) - p)
				hacia.y = 0
				var giro := atan2(hacia.x, hacia.z) + PI * 0.5
				var cm := _cilindro(0.24, 0.26, 1.6, 9)
				_al_lote(cm, Transform3D(Basis(Vector3.UP, giro) * Basis(Vector3.FORWARD, PI * 0.5), p + Vector3(0, 0.22, 0)), _mat_madera_osc)
				_caja_choque(p + Vector3(0, 0.25, 0), Vector3(1.6, 0.5, 0.5), giro)


func _cilindro(arriba: float, abajo: float, alto: float, lados: int) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = arriba
	cm.bottom_radius = abajo
	cm.height = alto
	cm.radial_segments = lados
	cm.rings = 1
	return cm


func _cilindro_choque(p: Vector3, radio: float, alto: float) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = p + Vector3(0, alto * 0.5, 0)
	r.add_child(cuerpo)
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = radio
	cs.height = alto
	col.shape = cs
	cuerpo.add_child(col)


var fuego_pos := Vector3.ZERO


func _hoguera(p: Vector3) -> void:
	fuego_pos = p
	var piedra := mat_detalle(Color(0.40, 0.39, 0.37), 0.9, false, 1.0)
	for k in 9:
		var a := k * TAU / 9.0
		_roca(p + Vector3(cos(a) * 0.62, 0.06, sin(a) * 0.62), 0.17, piedra)
	for k in 3:
		var a := k * TAU / 3.0 + 0.4
		var cm := _cilindro(0.05, 0.07, 0.9, 6)
		var dir := Vector3(cos(a), 0, sin(a))
		_al_lote(cm, Transform3D(Basis(dir.cross(Vector3.UP).normalized(), 0.55), p + dir * 0.22 + Vector3(0, 0.3, 0)), _mat_madera_osc)
	var brasas := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.32
	bm.height = 0.18
	bm.radial_segments = 8
	bm.rings = 3
	brasas.mesh = bm
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.25, 0.08, 0.03)
	mb.emission_enabled = true
	mb.emission = Color(1.0, 0.35, 0.08)
	mb.emission_energy_multiplier = 1.6
	brasas.material_override = mb
	brasas.position = p + Vector3(0, 0.05, 0)
	brasas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(brasas)
	var llamas := CPUParticles3D.new()
	llamas.name = "Llamas"
	llamas.amount = 14
	llamas.lifetime = 0.7
	llamas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	llamas.emission_sphere_radius = 0.18
	llamas.direction = Vector3.UP
	llamas.spread = 12.0
	llamas.initial_velocity_min = 0.6
	llamas.initial_velocity_max = 1.1
	llamas.gravity = Vector3(0, 0.4, 0)
	llamas.scale_amount_min = 0.6
	llamas.scale_amount_max = 1.1
	var q := QuadMesh.new()
	q.size = Vector2(0.3, 0.42)
	var ml := StandardMaterial3D.new()
	ml.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ml.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	ml.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ml.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ml.vertex_color_use_as_albedo = true
	ml.albedo_texture = _tex_brillo()
	q.material = ml
	llamas.mesh = q
	var rampa := Gradient.new()
	rampa.colors = PackedColorArray([Color(1.0, 0.85, 0.4, 0.0), Color(1.0, 0.6, 0.15, 0.9), Color(0.8, 0.2, 0.05, 0.0)])
	rampa.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	llamas.color_ramp = rampa
	llamas.position = p + Vector3(0, 0.15, 0)
	llamas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(llamas)
	_luz(p + Vector3(0, 0.8, 0), Color(1.0, 0.62, 0.3), 1.6, 7.0, true)
	obstaculo(p.x, p.z, 0.75)


var _brillo_tex: GradientTexture2D


func _tex_brillo() -> GradientTexture2D:
	if _brillo_tex == null:
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		_brillo_tex = GradientTexture2D.new()
		_brillo_tex.gradient = g
		_brillo_tex.fill = GradientTexture2D.FILL_RADIAL
		_brillo_tex.fill_from = Vector2(0.5, 0.5)
		_brillo_tex.fill_to = Vector2(1.0, 0.5)
		_brillo_tex.width = 64
		_brillo_tex.height = 64
	return _brillo_tex


# Una luz: real en el alto (luces_faroles); en bajo y medio, un halo pintado en el suelo y un resplandor (sendero_puente.gd,
# _halo_falso: en Compatibility cada luz redibuja lo que toca; medido en el Redmi, ~7 ms por dos luces).
func _luz(p: Vector3, color: Color, energia: float, alcance: float, parpadea := false) -> void:
	if perfil.get("luces_faroles", false):
		var l := OmniLight3D.new()
		l.light_color = color
		l.light_energy = energia
		l.omni_range = alcance
		l.shadow_enabled = false
		l.position = p
		r.add_child(l)
		if parpadea:
			luces.append([l, energia])
		return
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(color, 0.32), Color(color, 0.10), Color(color, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_texture = tex
	var disco := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(alcance, alcance) * 0.8
	disco.mesh = pm
	disco.material_override = m
	disco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disco.position = Vector3(p.x, T.altura(p.x, p.z) + 0.1, p.z)
	r.add_child(disco)


# ================================================================= el altar del fondo

func _crear_altar() -> void:
	var p := T.en_mundo(D.META)
	var piedra := mat_detalle(Color(0.58, 0.60, 0.56), 0.9, false, 1.0)
	var musgo := mat_detalle(Color(0.32, 0.46, 0.24), 0.9, false, 0.8)
	var bm := BoxMesh.new()
	bm.size = Vector3(3.4, 0.22, 2.8)
	_al_lote(bm, Transform3D(Basis(), p + Vector3(0, 0.06, 0)), piedra)
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(2.4, 0.22, 2.0)
	_al_lote(bm2, Transform3D(Basis(), p + Vector3(0, 0.26, -0.15)), piedra)
	var bm3 := BoxMesh.new()
	bm3.size = Vector3(1.3, 0.8, 0.9)
	_al_lote(bm3, Transform3D(Basis(), p + Vector3(0, 0.75, -0.3)), piedra)
	var bm4 := BoxMesh.new()
	bm4.size = Vector3(1.5, 0.14, 1.05)
	_al_lote(bm4, Transform3D(Basis(), p + Vector3(0, 1.2, -0.3)), musgo)
	_caja_choque(p + Vector3(0, 0.6, -0.3), Vector3(1.4, 1.2, 1.0))
	# piedras caídas alrededor, cubiertas de musgo
	for k in 6:
		var a := k * TAU / 6.0 + 0.3
		_roca(p + Vector3(cos(a) * 2.6, 0.1, sin(a) * 2.2), _rng.randf_range(0.25, 0.45), _roca_musgo())
	# el orbe de luz verde que flota sobre el altar (como el de la 2D)
	orbe = Node3D.new()
	orbe.name = "Orbe"
	orbe.position = p + Vector3(0, 2.0, -0.3)
	r.add_child(orbe)
	var esf := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.4
	sm.radial_segments = 12
	sm.rings = 6
	esf.mesh = sm
	var mo := StandardMaterial3D.new()
	mo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mo.albedo_color = Color(0.7, 1.0, 0.72)
	mo.emission_enabled = true
	mo.emission = Color(0.5, 1.0, 0.55)
	mo.emission_energy_multiplier = 2.5
	esf.material_override = mo
	esf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orbe.add_child(esf)
	var halo := Sprite3D.new()
	halo.texture = _tex_brillo()
	halo.pixel_size = 1.6 / 64.0
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	halo.shaded = false
	halo.transparent = true
	halo.modulate = Color(0.5, 1.0, 0.55, 0.7)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orbe.add_child(halo)
	_flotan.append([orbe, orbe.position.y, 0.0])
	_luz(p + Vector3(0, 1.8, -0.3), Color(0.5, 1.0, 0.55), 1.4, 8.0)


# ================================================================= el detalle: el árbol que abraza la armadura

func _crear_detalle() -> void:
	var c := T.lugar("ruinas") + T.DETALLE_DESDE_RUINAS
	detalle = _arbol_viejo(c + Vector2(0, -0.7), "pradera", 1.75, 2.8)
	detalle.name = "ArbolArmadura"
	var pie := T.en_mundo(c + Vector2(0, -0.7))
	var acero := StandardMaterial3D.new()
	acero.albedo_color = Color(0.62, 0.64, 0.62)
	acero.metallic = 0.45
	acero.roughness = 0.55
	acero.albedo_texture = grano
	var oro := StandardMaterial3D.new()
	oro.albedo_color = Color(0.95, 0.74, 0.30)
	oro.metallic = 0.85
	oro.roughness = 0.32
	oro.emission_enabled = true
	oro.emission = Color(0.5, 0.36, 0.1)
	oro.emission_energy_multiplier = 0.35
	var corteza := mat_detalle(Color(0.40, 0.30, 0.22), 1.3, false, 1.0)
	acero.emission_enabled = true                         # que se lea a la sombra del árbol
	acero.emission = Color(0.12, 0.13, 0.12)
	var cuero := StandardMaterial3D.new()
	cuero.albedo_color = Color(0.25, 0.2, 0.15)
	# Un caballero sentado contra el tronco, como si se hubiera quedado dormido: el árbol ha crecido alrededor de él. El
	# brazo izquierdo, de oro, cae hasta el suelo entre las raíces (progreso.gd: «Su brazo izquierdo es de oro»).
	var armadura := Node3D.new()
	armadura.name = "Armadura"
	armadura.position = pie + Vector3(0.0, 0.0, 0.78)
	r.add_child(armadura)
	obstaculo(armadura.position.x, armadura.position.z + 0.3, 0.75)
	armadura.scale = Vector3.ONE * 1.25
	var partes := [
		# [malla, posición, giro (x, y, z), escala, material]
		[_capsula(0.3, 0.92), Vector3(0, 0.98, 0), Vector3(-0.18, 0, 0), Vector3(1.15, 1, 0.72), acero],        # peto
		[_esfera(0.22, 0.46), Vector3(0.06, 1.62, 0.04), Vector3(0.3, 0.2, 0.32), Vector3.ONE, acero],          # yelmo, ladeado
		[_caja(Vector3(0.26, 0.04, 0.05)), Vector3(0.07, 1.62, 0.25), Vector3(0.3, 0.2, 0.32), Vector3.ONE, cuero], # la ranura
		[_esfera(0.17, 0.26), Vector3(-0.34, 1.32, 0.02), Vector3(0, 0, 0.3), Vector3(1, 1, 1.1), acero],       # hombreras (mira hacia +z:
		[_esfera(0.17, 0.26), Vector3(0.34, 1.32, 0.02), Vector3(0, 0, -0.3), Vector3(1, 1, 1.1), oro],         # su izquierda es +x)
		[_esfera(0.12, 0.2), Vector3(0.7, 0.16, 0.66), Vector3(0, -0.4, 0), Vector3(1.1, 0.8, 1.4), oro],       # guantelete en el suelo
	]
	for pt in partes:
		var mi := MeshInstance3D.new()
		mi.mesh = pt[0]
		mi.position = pt[1]
		mi.rotation = pt[2]
		mi.scale = pt[3]
		mi.material_override = pt[4]
		armadura.add_child(mi)
	# brazos y piernas, de articulación a articulación: el derecho cae junto al cuerpo; el izquierdo, de oro, baja hasta
	# el suelo entre las raíces; sentado, con las rodillas algo levantadas
	for hueso in [[Vector3(-0.38, 1.28, 0.02), Vector3(-0.46, 0.86, 0.12), 0.085, acero], [Vector3(-0.46, 0.86, 0.12), Vector3(-0.4, 0.5, 0.32), 0.075, acero],
			[Vector3(0.38, 1.28, 0.02), Vector3(0.6, 0.8, 0.24), 0.095, oro], [Vector3(0.6, 0.8, 0.24), Vector3(0.7, 0.22, 0.6), 0.085, oro],
			[Vector3(0.16, 0.42, 0.05), Vector3(0.2, 0.5, 0.6), 0.115, acero], [Vector3(0.2, 0.5, 0.6), Vector3(0.22, 0.08, 0.86), 0.09, acero],
			[Vector3(-0.16, 0.42, 0.05), Vector3(-0.22, 0.38, 0.62), 0.115, acero], [Vector3(-0.22, 0.38, 0.62), Vector3(-0.24, 0.08, 0.96), 0.09, acero]]:
		_hueso(armadura, hueso[0], hueso[1], hueso[2], hueso[3])	# la corteza que la abraza: ramas que cruzan el peto, sujetan el yelmo y bajan por las piernas
	for ab in [[Vector3(-0.6, 0.62, -0.25), Vector3(0.55, 1.32, 0.12)], [Vector3(0.62, 0.7, -0.25), Vector3(-0.42, 1.2, 0.2)],
			[Vector3(-0.5, 1.95, -0.3), Vector3(0.42, 1.48, 0.12)], [Vector3(0.55, 0.1, 0.1), Vector3(0.1, 0.45, 0.55)],
			[Vector3(-0.2, 1.75, -0.35), Vector3(-0.05, 1.05, 0.22)]]:
		var a: Vector3 = ab[0]
		var b: Vector3 = ab[1]
		var cm := _cilindro(0.06, 0.1, a.distance_to(b), 6)
		var eje := (b - a).normalized()
		var x := eje.cross(Vector3.FORWARD if absf(eje.z) < 0.9 else Vector3.RIGHT).normalized()
		var bas := Basis(x, eje, x.cross(eje)).orthonormalized()
		_al_lote(cm, Transform3D(bas.scaled(Vector3.ONE * 1.25), armadura.position + (a + b) * 0.5 * 1.25), corteza)	# la Hoja sin Nombre, entre las raíces junto a la armadura, mientras no se ha encontrado (la pone la región)


func poner_hoja(si: bool) -> void:
	if not si:
		if hoja != null:
			hoja.queue_free()
			hoja = null
		return
	if hoja != null:
		return
	var c := T.lugar("ruinas") + T.DETALLE_DESDE_RUINAS
	var pie := T.en_mundo(c + Vector2(0.9, 0.1))
	hoja = Node3D.new()
	hoja.name = "HojaSinNombre"
	hoja.position = pie
	hoja.rotation = Vector3(0.0, 0.7, 1.15)                   # apoyada, medio tumbada entre las raíces
	r.add_child(hoja)
	var acero := StandardMaterial3D.new()
	acero.albedo_color = Color(0.72, 0.74, 0.76)
	acero.metallic = 0.75
	acero.roughness = 0.3
	var cuero := StandardMaterial3D.new()
	cuero.albedo_color = Color(0.32, 0.20, 0.13)
	for pt in [[Vector3(0.05, 0.85, 0.02), Vector3(0.0, 0.62, 0), acero], [Vector3(0.32, 0.05, 0.06), Vector3(0, 0.28, 0), acero],
			[Vector3(0.05, 0.24, 0.05), Vector3(0, 0.12, 0), cuero]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pt[0]
		mi.mesh = bm
		mi.material_override = pt[2]
		mi.position = pt[1]
		hoja.add_child(mi)
	var brillo := destello(hoja, Vector3(0, 0.7, 0), 0.06, Color(0.85, 0.92, 1.0))
	brillo.name = "Destello"


func _capsula(radio: float, alto: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = radio
	c.height = alto
	c.radial_segments = 10
	c.rings = 4
	return c


# Una cápsula de «a» a «b» (un brazo, una pierna) dentro de «padre».
func _hueso(padre: Node3D, a: Vector3, b: Vector3, radio: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _capsula(radio, a.distance_to(b) + radio * 2.0)
	var eje := (b - a).normalized()
	var x := eje.cross(Vector3.FORWARD if absf(eje.z) < 0.9 else Vector3.RIGHT).normalized()
	mi.transform = Transform3D(Basis(x, eje, x.cross(eje)).orthonormalized(), (a + b) * 0.5)
	mi.material_override = mat
	padre.add_child(mi)


func _caja(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b


func _esfera(radio: float, alto: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radio
	s.height = alto
	s.radial_segments = 10
	s.rings = 6
	return s


# Un destello pequeño (lo que falta por coger), que late (lo anima la región por su escala).
func destello(padre: Node3D, pos: Vector3, tam: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(tam, tam) * 8.0
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _tex_brillo()
	m.albedo_color = color
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	padre.add_child(mi)
	_flotan.append([mi, -1.0, randf() * TAU])
	return mi


# ================================================================= cofres

# Un cofre de madera con herrajes y tapa curva que se abre (como el de Pastos Verdes). Su id es el de la 2D.
func crear_cofre(id: String, c: Vector2, abierto: bool, mira := Vector3(0, 0, 1)) -> void:
	var p := T.en_mundo(c)
	var nodo := Node3D.new()
	nodo.name = "Cofre_" + id
	nodo.position = p
	nodo.rotation.y = atan2(mira.x, mira.z)
	r.add_child(nodo)
	var madera := mat_detalle(Color(0.50, 0.32, 0.18), 1.6, false, 1.0)
	var hierro := StandardMaterial3D.new()
	hierro.albedo_color = Color(0.32, 0.30, 0.28)
	hierro.metallic = 0.6
	hierro.roughness = 0.5
	var caja := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 0.42, 0.56)
	caja.mesh = bm
	caja.material_override = madera
	caja.position.y = 0.21
	nodo.add_child(caja)
	for x in [-0.32, 0.32]:
		var banda := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.07, 0.44, 0.58)
		banda.mesh = bb
		banda.material_override = hierro
		banda.position = Vector3(x, 0.21, 0)
		nodo.add_child(banda)
	var bisagra := Node3D.new()
	bisagra.position = Vector3(0, 0.42, -0.28)
	nodo.add_child(bisagra)
	var tapa := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.28
	cm.bottom_radius = 0.28
	cm.height = 0.9
	cm.radial_segments = 10
	cm.rings = 1
	tapa.mesh = cm
	tapa.material_override = madera
	tapa.rotation.z = PI * 0.5
	tapa.scale = Vector3(1, 1, 0.55)
	tapa.position = Vector3(0, 0.0, 0.28)
	bisagra.add_child(tapa)
	if abierto:
		bisagra.rotation.x = deg_to_rad(-105.0)
	var brillo: MeshInstance3D = null
	if not abierto:
		brillo = destello(nodo, Vector3(0, 0.75, 0.1), 0.05, Color(1.0, 0.86, 0.45))
	cofres[id] = {"nodo": nodo, "tapa": bisagra, "pos": p, "abierto": abierto, "brillo": brillo}
	obstaculo(p.x, p.z, 0.45)


func abrir_cofre(id: String) -> void:
	var cf: Dictionary = cofres.get(id, {})
	if cf.is_empty():
		return
	cf["abierto"] = true
	if cf["brillo"] != null and is_instance_valid(cf["brillo"]):
		cf["brillo"].queue_free()
	cf["brillo"] = null
	var t: Tween = cf["tapa"].create_tween()
	t.tween_property(cf["tapa"], "rotation:x", deg_to_rad(-105.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ================================================================= el mirador y la entrada

func _crear_mirador() -> void:
	var centro := T.mundo(T.MIRADOR_2D)
	var roca := mat_detalle(Color(0.50, 0.50, 0.47), 0.6, false, 1.2)
	# peñas al borde de la meseta (la rampa queda libre)
	var hacia_rampa := (T.mundo(T.RAMPA_2D) - centro).normalized()
	for k in 14:
		var a := k * TAU / 14.0
		var d := Vector3(cos(a), 0, sin(a))
		if d.dot(hacia_rampa) > 0.75:
			continue
		var p := centro + d * (T.MIRADOR_RADIO * T.K + 0.5)
		p.y = T.altura(p.x, p.z)
		_roca(p + Vector3(0, 0.2, 0), _rng.randf_range(0.5, 0.95), roca, true)
	# losas planas arriba y un pino solo, torcido por el viento
	for k in 4:
		var q := centro + Vector3(_rng.randf_range(-1.5, 1.5), 0, _rng.randf_range(-1.5, 1.5))
		var cm := _cilindro(0.55, 0.6, 0.12, 7)
		_al_lote(cm, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), q + Vector3(0, T.altura(q.x, q.z) + 0.02, 0)), roca)
	var pino_p := centro + Vector3(-1.2, 0, -2.5)          # al norte de la meseta: no tapa a Kael desde la cámara
	pino_p.y = T.altura(pino_p.x, pino_p.z)
	_poner("pino", _pino(), _mat_macizo, Transform3D(Basis(Vector3.FORWARD, 0.12).scaled(Vector3.ONE * 1.1), pino_p), Color.WHITE,
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON if perfil.get("sombras", false) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, _dist(0))
	obstaculo(pino_p.x, pino_p.z, 0.35)


# La linde de la entrada: dos troncos caídos a los lados del camino, como una puerta del bosque.
func _crear_entrada() -> void:
	for lado: float in [-1.0, 1.0]:
		var c := T.ENTRADA_2D + Vector2(lado * 2.6, -1.5)
		var p := T.en_mundo(c)
		var cm := _cilindro(0.3, 0.36, 3.2, 9)
		var giro := 0.35 * lado
		_al_lote(cm, Transform3D(Basis(Vector3.UP, giro) * Basis(Vector3.FORWARD, PI * 0.5), p + Vector3(lado * 0.8, 0.28, 0)), _mat_madera_osc)
		_caja_choque(p + Vector3(lado * 0.8, 0.3, 0), Vector3(3.2, 0.6, 0.7), giro)
		_roca(p + Vector3(lado * 2.6, 0.1, 0.6), 0.6, _roca_musgo(), true)


# ================================================================= luz y vida

# Haces de luz que bajan por los huecos de las copas: en el claro, el campamento, las ruinas, el altar y el puente.
func _haces() -> void:
	var sitios := [T.lugar("claro"), D.META + Vector2(0, 1.5), T.lugar("ruinas"), T.lugar("campamento"),
		D.PUENTES[0][0] + Vector2(2.0, 0.0), T.MIRADOR_2D, Vector2(40.5, 44.0)]
	var n: int = HACES[nombre_perfil]
	var mat := ShaderMaterial.new()
	mat.shader = _shader(SHADER_HAZ)
	mat.set_shader_parameter("color", Color(1.0, 0.9, 0.62, 0.10 if nombre_perfil == "bajo" else 0.13))
	var hacia := -_sol_dir
	for k in mini(n, sitios.size()):
		var p := T.en_mundo(sitios[k])
		for s in 2:
			var mi := MeshInstance3D.new()
			mi.name = "Haz"
			var q := QuadMesh.new()
			q.size = Vector2(3.0 + s * 1.2, 11.0)
			mi.mesh = q
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# el haz va de arriba (hacia el sol) al suelo; se inclina con la luz y mira algo hacia la cámara
			var centro := p + hacia * 5.5 + Vector3(s * 0.9 - 0.45, 0, 0)
			var eje := hacia.normalized()
			var x := Vector3(1, 0, 0) if s == 0 else Vector3(0.8, 0, 0.6)
			x = (x - eje * x.dot(eje)).normalized()
			var zz := x.cross(eje).normalized()
			mi.transform = Transform3D(Basis(x.normalized(), eje, zz).orthonormalized(), centro)
			r.add_child(mi)


func _particulas() -> void:
	# hojas que caen alrededor de Kael (las sigue la región)
	hojas_caen = CPUParticles3D.new()
	hojas_caen.name = "HojasCaen"
	hojas_caen.amount = 14 if nombre_perfil == "bajo" else (22 if nombre_perfil == "medio" else 36)
	hojas_caen.lifetime = 7.0
	hojas_caen.preprocess = 7.0
	hojas_caen.local_coords = false
	hojas_caen.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	hojas_caen.emission_box_extents = Vector3(11, 0.4, 7)
	hojas_caen.direction = Vector3(0.3, -1, 0.1)
	hojas_caen.spread = 25.0
	hojas_caen.initial_velocity_min = 0.4
	hojas_caen.initial_velocity_max = 0.8
	hojas_caen.gravity = Vector3(0.15, -0.35, 0.05)
	hojas_caen.angular_velocity_min = -120.0
	hojas_caen.angular_velocity_max = 120.0
	var q := QuadMesh.new()
	q.size = Vector2(0.16, 0.11)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	q.material = m
	hojas_caen.mesh = q
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.62, 0.66, 0.22, 0.0), Color(0.72, 0.58, 0.20, 1.0), Color(0.55, 0.40, 0.16, 1.0), Color(0.5, 0.36, 0.14, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.1, 0.85, 1.0])
	hojas_caen.color_ramp = g
	hojas_caen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.add_child(hojas_caen)
	# luciérnagas: motas de luz en el altar y en las ruinas
	for c in [D.META, T.lugar("ruinas")]:
		var p := T.en_mundo(c)
		var motas: CPUParticles3D = Arbol._motas(Vector3.ZERO, 3.0)
		motas.name = "Motas"
		motas.amount = 12 if nombre_perfil == "bajo" else 20
		motas.position = p + Vector3(0, 1.4, 0)
		r.add_child(motas)
	# mariposas en el claro
	var mp := CPUParticles3D.new()
	mp.name = "Mariposas"
	mp.amount = 8
	mp.lifetime = 6.0
	mp.preprocess = 6.0
	mp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mp.emission_box_extents = Vector3(3.5, 0.6, 3.5)
	mp.direction = Vector3(1, 0.3, 0)
	mp.spread = 180.0
	mp.initial_velocity_min = 0.2
	mp.initial_velocity_max = 0.5
	mp.gravity = Vector3.ZERO
	var qm := QuadMesh.new()
	qm.size = Vector2(0.14, 0.1)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mm.vertex_color_use_as_albedo = true
	mm.cull_mode = BaseMaterial3D.CULL_DISABLED
	qm.material = mm
	mp.mesh = qm
	var gm := Gradient.new()
	gm.colors = PackedColorArray([Color(1, 0.95, 0.6, 0.0), Color(1, 0.95, 0.6, 1), Color(0.75, 0.85, 1.0, 1), Color(0.75, 0.85, 1.0, 0.0)])
	gm.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	mp.color_ramp = gm
	mp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mp.position = T.en_mundo(T.lugar("claro")) + Vector3(0, 1.0, 0)
	r.add_child(mp)


# Cada fotograma: el viento de las hojas sigue a Kael, el orbe flota, los destellos laten y el fuego parpadea.
func animar(t: float, kael: Vector3) -> void:
	if hojas_caen != null:
		hojas_caen.global_position = kael + Vector3(0, 5.5, -3.0)
	for f in _flotan:
		if not is_instance_valid(f[0]):
			continue
		var n: Node3D = f[0]
		if f[1] >= 0.0:
			n.position.y = f[1] + sin(t * 1.6) * 0.12
		else:
			n.scale = Vector3.ONE * (0.75 + 0.3 * sin(t * 3.2 + f[2]))
	for l in luces:
		l[0].light_energy = l[1] * (0.82 + 0.18 * sin(t * 13.0) * sin(t * 7.3 + 1.0))
