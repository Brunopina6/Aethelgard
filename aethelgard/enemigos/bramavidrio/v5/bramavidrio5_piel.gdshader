// Piel de Bramavidrio v5 «la v4 resuelta» (V12, 12/11; fuente/crear_bramavidrio5.py; copia de la de la v4, que no se
// toca). Spatial; Compatibility. La misma lógica que la v1-v4: textura × color de vértice (oclusión, en sRGB) × «tono»;
// en la A de la textura (con un mínimo de 0,04), el brillo de las runas y vetas, que late despacio y sigue a «energia»
// (la escala del hueso «brillo»). El alfa del COLOR DE VÉRTICE dice cuánto «mineral» es cada parte (1 la coraza de
// basalto y piedra, cráneo, cuernos y mandíbulas; 0 la carne, las encías y el vientre): el mineral refleja más el sol y
// tiene un borde de luz.
// v5: con NORMALES (alto y medio), el mapa de normales horneado de las alturas que pinta la textura (cantos biselados,
// grietas, runas grabadas, zarpazos, estrías y arrugas de la carne); más marcado en el mineral que en la carne.
// Con RECORTE (solo en el combate) no dibuja lo que queda por debajo de «suelo» (lo enterrado).
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_back;

uniform sampler2D textura : source_color, filter_linear_mipmap, repeat_disable;
#ifdef NORMALES
uniform sampler2D normales : hint_normal, filter_linear_mipmap, repeat_disable;
uniform float fuerza_normales : hint_range(0.0, 2.0) = 1.0;
#endif
uniform vec3 color_brillo : source_color = vec3(1.0, 0.72, 0.3);   // las runas doradas y la luz del fondo de la boca
uniform float energia : hint_range(0.0, 3.0) = 1.0;
uniform float suelo = 0.0;
uniform float tono : hint_range(0.3, 1.5) = 1.0;
uniform float borde_mineral : hint_range(0.0, 1.0) = 0.45;

varying float alto;

void vertex() {
	COLOR.rgb = pow(COLOR.rgb, vec3(2.2));    // los colores de vértice van en sRGB (el alfa, tal cual)
	alto = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
#ifdef RECORTE
	if (alto < suelo) {
		discard;
	}
#endif
	vec4 t = texture(textura, UV);
	float m = COLOR.a;
	ALBEDO = t.rgb * COLOR.rgb * tono;
	ROUGHNESS = mix(0.86, 0.42, m);
	SPECULAR = mix(0.25, 0.7, m);
	RIM = borde_mineral * m;
	RIM_TINT = 0.55;
#ifdef NORMALES
	NORMAL_MAP = texture(normales, UV).rgb;
	NORMAL_MAP_DEPTH = fuerza_normales * mix(0.7, 1.15, m);
#endif
	float pulso = 0.82 + 0.18 * sin(TIME * 1.6 + UV.y * 37.0);
	float veta = clamp((t.a - 0.04) / 0.96, 0.0, 1.0);   // el alfa guarda 0,04 + 0,96 × brillo (crear_bramavidrio5.py)
	EMISSION = color_brillo * veta * energia * pulso * 2.2;
}
