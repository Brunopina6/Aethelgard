// Muestra gráfica de una calle de Oakhaven (en pruebas): lo fijo de la calle. La luz viene HORNEADA (Cycles, en
// fuente/crear_calle.py: sol bajo de la tarde, cielo frío, rebotes y la luz de los faroles) en un mapa de luz (UV2):
// aquí no se calcula ninguna luz, solo textura × tinte del vértice × mapa de luz. Por eso es tan barato (dos lecturas
// de textura y dos multiplicaciones por píxel) y las sombras, los rebotes y la oclusión salen iguales en todos los
// perfiles (también en el bajo, sin sombras en tiempo real).
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform sampler2D textura : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D luz : source_color, filter_linear_mipmap, repeat_disable;
uniform float luz_escala = 1.0;      // calle_luz.json, «escala»: el mapa guarda luz / escala
uniform float textura_fuerza = 1.0;  // 0 = sin textura (para la pasada de iluminación sin materiales)
uniform bool solo_luz = false;       // depuración: solo el mapa de luz

// La sombra de Kael, dentro del propio sombreado del suelo (sin objetos transparentes: en esta escena, en Compatibility,
// una capa transparente oscura no oscurecía nada en los perfiles bajo y medio; 15/11, probado). Una mancha de contacto
// bajo los pies y una sombra larga hacia donde la echa el sol horneado (sombra_dir); muestra_calle.gd mueve kael_pos cada
// fotograma y apaga la larga cuando Kael pisa sombra.
uniform vec3 kael_pos = vec3(0.0, -100.0, 0.0);
uniform vec2 sombra_dir = vec2(1.0, 0.0);
uniform float sombra_largo = 2.6;
uniform float sombra_fuerza = 0.45;
uniform float contacto_fuerza = 0.5;
varying vec3 mundo;
varying float mundo_ny;

float sombra_kael() {
	vec3 d = mundo - kael_pos;
	if (abs(d.y) > 0.5) {
		return 1.0;
	}
	vec2 h = d.xz;
	float c = 1.0 - smoothstep(0.1, 0.36, length(h));
	float a = dot(h, sombra_dir);
	float t = clamp(a / sombra_largo, 0.0, 1.0);
	float ancho = mix(0.2, 0.34, t);
	float x = abs(dot(h, vec2(-sombra_dir.y, sombra_dir.x)));
	float l = (1.0 - smoothstep(ancho * 0.35, ancho, x)) * smoothstep(-0.15, 0.1, a) * (1.0 - smoothstep(0.55, 1.0, a / sombra_largo));
	float s = max(c * contacto_fuerza, l * sombra_fuerza);
	return 1.0 - s * smoothstep(0.45, 0.85, mundo_ny);
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	mundo_ny = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz).y;
}

void fragment() {
	vec3 t = mix(vec3(0.82), texture(textura, UV).rgb, textura_fuerza);
	ALBEDO = solo_luz ? texture(luz, UV2).rgb : t * COLOR.rgb * texture(luz, UV2).rgb * luz_escala * sombra_kael();
}
