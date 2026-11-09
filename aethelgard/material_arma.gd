extends RefCounted
# Material de las armas de Meshy (Godot 4.x): color, relieve, metal, rugosidad y brillo.
# Con el renderizador Compatibility (el del móvil), un StandardMaterial3D con textura de emisión pinta
# el arma entera de blanco. Aquí el brillo se suma en un shader propio y sale como debe: solo las
# runas, la lava o el cristal brillan (Biblia de arte: brillo solo en armas encantadas y magia).
# Uso:  mi.material_override = load("res://material_arma.gd").crear(color, normal, metal, rugosidad, brillo)
# Cada ruta puede ser "" o no existir (esa parte no se usa).

const SHADER := """
shader_type spatial;
uniform sampler2D color_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D metal_tex : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D rugosidad_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D brillo_tex : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform bool con_normal = false;
uniform bool con_metal = false;
uniform bool con_rugosidad = false;
uniform float metal_max = 1.0;     // el cetro de Lya usa 0,4 (sin cielo que reflejar, el metal puro se ve negro)
uniform float energia = 1.4;       // fuerza del brillo
uniform vec3 tinte : source_color = vec3(1.0);    // armas especiales (T-092, C2): el color de la hoja (blanco = como siempre)
uniform vec3 color_brillo : source_color = vec3(1.0);  // y el de su brillo
uniform float aura = 0.0;          // un filo de luz en el borde (0 = nada): se lee sin luces ni partículas
uniform float fuerza_tinte = 0.0;  // cuánto toma la hoja el color del tinte (0 = la textura tal cual)
void fragment() {
	vec3 c = texture(color_tex, UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));    // su luz, con el color del tinte (también en hojas oscuras)
	ALBEDO = mix(c, tinte * clamp(0.35 + l * 1.3, 0.0, 1.2), fuerza_tinte);
	if (con_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	METALLIC = con_metal ? texture(metal_tex, UV).r * metal_max : 0.0;
	ROUGHNESS = con_rugosidad ? texture(rugosidad_tex, UV).r : 0.6;
	EMISSION = texture(brillo_tex, UV).rgb * energia * color_brillo;
	if (aura > 0.0) {
		float borde = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		EMISSION += color_brillo * aura * borde * borde;
	}
}
"""

static var _shader: Shader


static func crear(color: String, normal: String, metal: String, rugosidad: String, brillo: String,
		metal_max := 1.0) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	if _hay(color):
		m.set_shader_parameter("color_tex", load(color))
	if _hay(normal):
		m.set_shader_parameter("normal_tex", load(normal))
		m.set_shader_parameter("con_normal", true)
	if _hay(metal):
		m.set_shader_parameter("metal_tex", load(metal))
		m.set_shader_parameter("con_metal", true)
		m.set_shader_parameter("metal_max", metal_max)
	if _hay(rugosidad):
		m.set_shader_parameter("rugosidad_tex", load(rugosidad))
		m.set_shader_parameter("con_rugosidad", true)
	if _hay(brillo):
		m.set_shader_parameter("brillo_tex", load(brillo))
	return m


# El mismo material para un arma del inventario (inventario.gd, ARMAS; y las especiales de equipo_extra.gd, con su
# «tinte» y su «color_brillo»).
static func de_arma(arma: Dictionary, metal_max := 1.0) -> ShaderMaterial:
	var m := crear(arma.get("color", ""), arma.get("normal", ""), arma.get("metal", ""), arma.get("rugosidad", ""),
		arma.get("brillo", ""), metal_max)
	_aplicar_tinte(m, arma)
	return m


# Armas especiales (C2): la hoja se tiñe y su brillo toma su color, con un filo de luz en el borde (aura) para que se
# distingan también sin textura de brillo. Es solo color en el shader: sin luces ni partículas (barato en Mali).
const AURA_ESPECIAL := 0.9
const FUERZA_TINTE := 0.7
const METAL_ESPECIAL := 0.45       # sin cielo que reflejar, el metal puro se ve negro y se come el tinte


static func _aplicar_tinte(m: ShaderMaterial, arma: Dictionary) -> void:
	if arma.has("tinte"):
		m.set_shader_parameter("tinte", arma["tinte"])
		m.set_shader_parameter("fuerza_tinte", FUERZA_TINTE)
		if m.get_shader_parameter("con_metal"):
			m.set_shader_parameter("metal_max", minf(float(m.get_shader_parameter("metal_max")), METAL_ESPECIAL))
	if arma.has("color_brillo"):
		m.set_shader_parameter("color_brillo", arma["color_brillo"])
		m.set_shader_parameter("aura", AURA_ESPECIAL)


# Tiñe las mallas de un arma ya montada (las de Garon se cargan por su modelo, sin saber qué arma son): cada
# MeshInstance3D con este material recibe el tinte del arma. Sin «tinte» ni «color_brillo», no cambia nada.
static func tenir(nodo: Node, arma: Dictionary) -> int:
	if nodo == null or not (arma.has("tinte") or arma.has("color_brillo")):
		return 0
	var n := 0
	for mi in [nodo] + nodo.find_children("*", "MeshInstance3D", true, false):
		if mi is MeshInstance3D and mi.material_override is ShaderMaterial and mi.material_override.shader == _shader:
			mi.material_override = mi.material_override.duplicate()   # (las de siempre comparten el suyo)
			_aplicar_tinte(mi.material_override, arma)
			n += 1
	return n


# Para un modelo con texturas de igual nombre: <base>_color.jpg/png, _normal, _metal, _rugosidad, _brillo.
static func de_base(base: String, metal_max := 1.0) -> ShaderMaterial:
	var color := base + "_color.jpg" if ResourceLoader.exists(base + "_color.jpg") else base + "_color.png"
	return crear(color, base + "_normal.png", base + "_metal.png", base + "_rugosidad.png", base + "_brillo.png", metal_max)


static func _hay(ruta: String) -> bool:
	return ruta != "" and ResourceLoader.exists(ruta)
