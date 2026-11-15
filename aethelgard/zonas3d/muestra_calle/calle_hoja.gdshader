// Muestra gráfica de una calle de Oakhaven (en pruebas): la vegetación (matas, hojas, flores). La luz está horneada en
// el color de cada vértice (fuente/crear_calle.py: tinte × luz / escala) y el alfa del vértice dice cuánto se mueve con
// el viento (0 en la base, 1 en la punta). Geometría opaca (sin recorte alfa: en Mali, el descarte por píxel rompe el
// borrado temprano de lo tapado), de dos caras.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D textura : source_color, filter_linear_mipmap, repeat_enable;
uniform float luz_escala = 1.0;
uniform float viento = 1.0;          // 0 en el perfil que no lo quiera

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
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	mundo = w;
	mundo_ny = 1.0;
	float f = COLOR.a * viento;
	float t = TIME;
	float rafaga = 0.75 + 0.25 * sin(t * 0.47 + w.x * 0.11);
	VERTEX.x += (sin(t * 1.9 + w.x * 0.7 + w.z * 0.5) * 0.6 + sin(t * 3.7 + w.z * 1.3) * 0.25) * 0.05 * f * rafaga;
	VERTEX.z += cos(t * 1.4 + w.x * 0.5 + w.y) * 0.03 * f * rafaga;
}

void fragment() {
	ALBEDO = texture(textura, UV).rgb * COLOR.rgb * luz_escala * sombra_kael();
}
