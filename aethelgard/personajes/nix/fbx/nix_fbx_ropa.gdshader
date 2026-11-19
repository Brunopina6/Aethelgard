// Nix desde el FBX (piloto APAGADO, 19/11, C-6): material de la ROPA = el de los héroes v2 (heroe_v2.gdshader, copiado
// tal cual; si cambia aquél, cambiar también éste) + EMISIÓN DE LOS ORNAMENTOS con tres intensidades (básica, fuerte y
// suprema) que pone nix_3d.gd según la habilidad («ornamentos»: 0 = apagada, que es lo normal: entonces el resultado
// es exactamente el de heroe_v2.gdshader).
//
// Sin textura nueva: la máscara son los propios datos del atlas de la ropa (fuente_blender/p8_dibujos.py):
//   - el ORO tiene metal = 1 y nada más lo tiene (tela, forro, cuero y botas: 0): es la «m» que el material ya calcula
//     para el brillo metálico (mismo umbral);
//   - las AMATISTAS, rugosidad 0,12 (el oro 0,36; tela, cuero y suela ≥ 0,55) y color violeta.
// De cerca la emisión es el color del propio texel por la máscara (nítida; donde la compresión marca de metal un texel
// de tela negra, su color negro no emite). De lejos (≥ 6 texeles por píxel: el combate y la exploración) los ribetes
// finos ocupan menos de un píxel y el umbral del mipmap (metal medio < 0,33) los borraba: allí la puerta es mucho más
// baja (metal medio desde 0,03) y la emisión es el color MEDIO del mipmap, que ya es «dorado × cobertura» porque la
// tela negra casi no aporta: la energía media se conserva, sin parpadeos, y los bloques de la compresión que marcan
// metal en tela negra siguen sin emitir.
// Lo pone nix_fbx.gd (poner_ornamentos) solo en la malla «ropa_nix» cuando el interruptor nix_fbx está encendido.
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
uniform float umbral_metal = 0.45;
uniform float rugosidad_mate = 0.72;
uniform float especular_mate = 0.28;
uniform vec2 rugosidad_metal = vec2(0.22, 0.6);
uniform float borde = 0.2;
uniform float tinte_borde = 0.4;
uniform float reflejo = 0.5;
uniform vec3 cielo : source_color = vec3(0.78, 0.84, 0.95);
uniform vec3 suelo : source_color = vec3(0.30, 0.26, 0.22);
uniform float energia_entorno = 1.0;
// ornamentos: nivel (0 apagada; nix_fbx.gd NIVELES), color de lejos, amatistas y la distancia de «lejos»
uniform float ornamentos = 0.0;
uniform vec2 puerta_lejos = vec2(0.03, 0.2);                      // metal medio del mipmap: de lejos, desde dónde emite
uniform vec2 gema_rugosidad = vec2(0.18, 0.28);                   // amatista por debajo del primero (0,12); oro 0,36
uniform vec2 gema_violeta = vec2(0.45, 0.75);                     // (azul - verde) / máximo, en color lineal
uniform float gema_brillo = 1.0;
uniform vec2 orn_densidad = vec2(1.5, 6.0);                       // texeles por píxel: de cerca hasta, de lejos desde

void fragment() {
	vec4 a = texture(albedo_tex, UV) * color;
	ALBEDO = a.rgb;
	float r = rugosidad;
	if (tiene_rugosidad) {
		r *= dot(texture(rugosidad_tex, UV), canal_rugosidad);
	}
	float r0 = r;
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
	// ornamentos: «ornamentos» es un uniforme (igual en todo el dibujo), así que la rama y sus derivadas son uniformes;
	// apagada (lo normal) no se calcula nada más
	if (ornamentos > 0.0) {
		vec2 tpp = fwidth(UV) * vec2(textureSize(albedo_tex, 0));
		float lejos = smoothstep(orn_densidad.x, orn_densidad.y, max(tpp.x, tpp.y));
		float mx = max(a.r, max(a.g, a.b));
		vec3 c = a.rgb / max(mx, 0.001);
		float gema = (1.0 - smoothstep(gema_rugosidad.x, gema_rugosidad.y, r0))
			* smoothstep(gema_violeta.x, gema_violeta.y, c.b - c.g) * smoothstep(0.05, 0.2, c.r - c.g);
		vec3 cerca = a.rgb * max(m, gema * gema_brillo);
		vec3 lejano = a.rgb * smoothstep(puerta_lejos.x, puerta_lejos.y, mt);
		EMISSION += mix(cerca, lejano, lejos) * ornamentos;
	}
}
