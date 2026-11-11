// Piel de Bramavidrio (V12; fuente/crear_bramavidrio.py). Spatial; Compatibility. Opaca: textura × color de vértice
// (oclusión y tintes, en sRGB) y, en la A de la textura (con un mínimo de 0,04), el brillo de las grietas y cicatrices
// selladas con vidrio, que late despacio y sigue a «energia» (la escala del hueso «brillo» de cada clip).
// Pasada 2: el alfa del COLOR DE VÉRTICE dice cuánto «mineral» es cada parte (1 las placas de basalto, la cabeza y las
// mandíbulas laterales; 0,5 los dientes; 0 la carne, el vientre y la arena de las juntas): el basalto refleja más el
// sol y tiene un borde de luz, para que lea como piedra pulida por la arena.
// Con RECORTE (solo en el combate: bramavidrio_3d.gd lo añade al código) no dibuja lo que queda por debajo de «suelo»:
// la parte enterrada del cuerpo. En la exploración no hace falta (la tapa el terreno) y así no se paga el «discard».
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_back;

uniform sampler2D textura : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 color_brillo : source_color = vec3(0.45, 0.95, 1.0);
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
	ROUGHNESS = mix(0.86, 0.4, m);
	SPECULAR = mix(0.25, 0.7, m);
	RIM = borde_mineral * m;
	RIM_TINT = 0.55;
	float pulso = 0.82 + 0.18 * sin(TIME * 1.6 + UV.y * 37.0);
	float grieta = clamp((t.a - 0.04) / 0.96, 0.0, 1.0);   // el alfa guarda 0,04 + 0,96 × brillo (crear_bramavidrio.py)
	EMISSION = color_brillo * grieta * energia * pulso * 2.2;
}
