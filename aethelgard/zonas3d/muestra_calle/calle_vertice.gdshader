// Muestra gráfica de una calle de Oakhaven (en pruebas): las piezas sueltas (losas del empedrado, barriles, cajones,
// macetas, la carretilla, la leña, los faroles de pie). Su luz está horneada en el color de cada vértice
// (fuente/crear_calle.py: tinte × luz / escala), no en el mapa de luz: son miles de islas pequeñas que se comían el
// mapa. Igual de barato que lo fijo: una lectura de textura por píxel.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform sampler2D textura : source_color, filter_linear_mipmap, repeat_enable;
uniform float luz_escala = 1.0;

// La sombra de Kael, dentro del propio sombreado del suelo (sin objetos transparentes: en esta escena, en Compatibility,
// una capa transparente oscura no oscurecía nada en los perfiles bajo y medio; 15/11, probado). Una mancha de contacto
// bajo los pies y una sombra larga hacia donde la echa el sol horneado (sombra_dir); muestra_calle.gd mueve kael_pos cada
// fotograma y apaga la larga cuando Kael pisa sombra.
uniform vec3 kael_pos = vec3(0.0, -100.0, 0.0);
uniform vec2 sombra_dir = vec2(1.0, 0.0);
uniform float sombra_largo = 2.6;
uniform float sombra_fuerza = 0.45;
uniform float contacto_fuerza = 0.5;
uniform float sol_kael = 1.0;                       // (15/11) 0 = Kael en sombra, 1 = al sol (sondas; muestra_calle.gd)
varying vec3 mundo;
varying float mundo_ny;

float sombra_kael() {
	// (15/11, corrección 3) contacto más legible y barato: salida temprana también por distancia; núcleo redondo y
	// oscuro bajo los pies; elipse de contacto (al sol, alargada hacia donde va la sombra; en sombra, redonda: oclusión
	// del cielo); y la sombra larga con un centro algo más ancho. Sin pasadas nuevas ni transparencias.
	vec3 d = mundo - kael_pos;
	vec2 h = d.xz;
	float r = sombra_largo + 0.6;                       // nada de la sombra llega más lejos
	if (abs(d.y) > 0.5 || dot(h, h) > r * r) {          // salida temprana: casi todo el suelo
		return 1.0;
	}
	vec2 q = vec2(-sombra_dir.y, sombra_dir.x);
	float a = dot(h, sombra_dir);
	float x = dot(h, q);
	vec2 hc = h - vec2(0.0, 0.10);                      // (hacia la cámara, al sur: que asome delante de los pies)
	float n = 1.0 - smoothstep(0.12, 0.36, length(hc));
	float eje = mix(0.40, 0.62, sol_kael);
	vec2 e = vec2((a - 0.20 * sol_kael) / eje, x / 0.42);
	float el = 1.0 - smoothstep(0.30, 1.0, dot(e, e));
	float c = max(n, 0.80 * el);
	float t = clamp(a / sombra_largo, 0.0, 1.0);
	float ancho = mix(0.18, 0.28, t);
	float l = (1.0 - smoothstep(ancho * 0.6, ancho, abs(x))) * smoothstep(-0.1, 0.12, a) * (1.0 - smoothstep(0.6, 1.0, t));
	float s = max(c * contacto_fuerza, l * sombra_fuerza);
	return 1.0 - s * smoothstep(0.45, 0.85, mundo_ny);
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	mundo_ny = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz).y;
}

void fragment() {
	ALBEDO = texture(textura, UV).rgb * COLOR.rgb * luz_escala * sombra_kael();
}
