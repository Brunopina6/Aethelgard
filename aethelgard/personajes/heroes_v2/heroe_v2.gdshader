// Héroes v2 (fase B, V12): material de los héroes. Usa las MISMAS texturas del modelo de Meshy (color, relieve,
// rugosidad y metal) y añade, sin cambiar sus colores:
//   - reflejo de cielo y suelo en las partes metálicas (en Compatibility no hay sondas de reflejo: el metal puro
//     reflejaba negro y la armadura de Garon o los adornos dorados de Kael se veían apagados);
//   - un borde de luz suave (fresnel), más fuerte arriba, que separa la silueta del fondo;
//   - más relieve en el mapa de normales (tela y metal con más detalle).
// Funciona en Compatibility (GLES3): solo fragment(), sin luz propia.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

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
uniform float reflejo = 0.5;
uniform vec3 cielo : source_color = vec3(0.78, 0.84, 0.95);
uniform vec3 suelo : source_color = vec3(0.30, 0.26, 0.22);
uniform float borde = 0.2;
uniform vec3 color_borde : source_color = vec3(1.0, 0.94, 0.84);

void fragment() {
	vec4 a = texture(albedo_tex, UV) * color;
	ALBEDO = a.rgb;
	float r = rugosidad;
	if (tiene_rugosidad) {
		r *= dot(texture(rugosidad_tex, UV), canal_rugosidad);
	}
	float m = metal;
	if (tiene_metal) {
		m *= dot(texture(metal_tex, UV), canal_metal);
	}
	ROUGHNESS = r;
	METALLIC = m * 0.85;
	if (tiene_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = relieve;
	}
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 rf = reflect(-v, n);
	vec3 entorno = mix(suelo, cielo, smoothstep(-0.35, 0.55, rf.y));
	float brillo = (1.0 - r * 0.7);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = entorno * a.rgb * m * reflejo * brillo
		+ color_borde * fres * borde * (0.45 + 0.55 * clamp(n.y + 0.4, 0.0, 1.0));
}
