// Héroes v2 (fase B, V12): material de los héroes. Usa las MISMAS texturas del modelo de Meshy (color, relieve,
// rugosidad y metal) y no cambia sus colores.
//
// 13/11 (pulido de materiales; causa medida en el mapa de metal/rugosidad de Meshy: G = rugosidad ≈ 0,55 en piel, tela
// y cuero, con zonas casi a 0 (charol), y B = metal solo en adornos, hebillas y armadura):
//   - metal o no, sin medias tintas: el canal de metal pasa por un umbral suave, así la tela, el cuero y la piel no
//     sacan brillo metálico y los adornos, la armadura y las hebillas sí;
//   - lo que no es metal, mate: rugosidad mínima y reflejo especular bajo (la piel ya no parece plástico ni la tela,
//     charol); el metal conserva su brillo con una rugosidad acotada;
//   - luz envolvente (diffuse_lambert_wrap): la sombra propia es más suave y la cara se lee aunque la luz venga de
//     lado (Garganta, Gran Bosque), sin añadir luz propia;
//   - borde de luz con RIM (lo ponen las luces de la escena; antes era EMISSION y brillaba igual a oscuras);
//   - reflejo del entorno solo en lo metálico (en Compatibility no hay sondas y el metal puro salía negro): los colores
//     de cielo y suelo y su energía los toma heroe_v2_ayudante.gd del ambiente de cada región, así que en un sitio
//     oscuro el metal también se oscurece. Es lo único que va por EMISSION y nunca toca piel ni tela.
// Funciona en Compatibility (GLES3): solo fragment(), sin light() propio.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert_wrap, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 color : source_color = vec4(1.0);
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool tiene_normal = false;
uniform float relieve = 1.0;
uniform sampler2D rugosidad_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform bool tiene_rugosidad = false;
uniform vec4 canal_rugosidad = vec4(0.0, 1.0, 0.0, 0.0);
uniform sampler2D metal_tex : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform bool tiene_metal = false;
uniform vec4 canal_metal = vec4(0.0, 0.0, 1.0, 0.0);
uniform float rugosidad = 1.0;
uniform float metal = 0.0;
// metal / no metal
uniform float umbral_metal = 0.45;
uniform float rugosidad_mate = 0.72;      // mínimo para piel, tela y cuero
uniform float especular_mate = 0.28;      // 0,5 es el de Godot (plástico); la piel y la tela, menos
uniform vec2 rugosidad_metal = vec2(0.22, 0.6);
// borde de luz (RIM de Godot: lo pone cada luz)
uniform float borde = 0.2;
uniform float tinte_borde = 0.4;
// reflejo del entorno en el metal
uniform float reflejo = 0.5;
uniform vec3 cielo : source_color = vec3(0.78, 0.84, 0.95);
uniform vec3 suelo : source_color = vec3(0.30, 0.26, 0.22);
uniform float energia_entorno = 1.0;

void fragment() {
	vec4 a = texture(albedo_tex, UV) * color;
	ALBEDO = a.rgb;
	float r = rugosidad;
	if (tiene_rugosidad) {
		r *= dot(texture(rugosidad_tex, UV), canal_rugosidad);
	}
	float mt = metal;
	if (tiene_metal) {
		mt *= dot(texture(metal_tex, UV), canal_metal);
	}
	float m = smoothstep(umbral_metal - 0.12, umbral_metal + 0.12, mt);
	r = mix(max(r, rugosidad_mate), clamp(r, rugosidad_metal.x, rugosidad_metal.y), m);
	ROUGHNESS = r;
	METALLIC = m * 0.85;
	SPECULAR = mix(especular_mate, 0.5, m);
	if (tiene_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = relieve;
	}
	RIM = borde;
	RIM_TINT = tinte_borde;
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 rf = reflect(-v, n);
	vec3 entorno = mix(suelo, cielo, smoothstep(-0.35, 0.55, rf.y));
	EMISSION = entorno * a.rgb * m * reflejo * (1.0 - r * 0.7) * energia_entorno;
}
