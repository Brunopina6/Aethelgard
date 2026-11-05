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
void fragment() {
	ALBEDO = texture(color_tex, UV).rgb;
	if (con_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	METALLIC = con_metal ? texture(metal_tex, UV).r * metal_max : 0.0;
	ROUGHNESS = con_rugosidad ? texture(rugosidad_tex, UV).r : 0.6;
	EMISSION = texture(brillo_tex, UV).rgb * energia;
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


# El mismo material para un arma del inventario (inventario.gd, ARMAS).
static func de_arma(arma: Dictionary, metal_max := 1.0) -> ShaderMaterial:
	return crear(arma.get("color", ""), arma.get("normal", ""), arma.get("metal", ""), arma.get("rugosidad", ""),
		arma.get("brillo", ""), metal_max)


# Para un modelo con texturas de igual nombre: <base>_color.jpg/png, _normal, _metal, _rugosidad, _brillo.
static func de_base(base: String, metal_max := 1.0) -> ShaderMaterial:
	var color := base + "_color.jpg" if ResourceLoader.exists(base + "_color.jpg") else base + "_color.png"
	return crear(color, base + "_normal.png", base + "_metal.png", base + "_rugosidad.png", base + "_brillo.png", metal_max)


static func _hay(ruta: String) -> bool:
	return ruta != "" and ResourceLoader.exists(ruta)
