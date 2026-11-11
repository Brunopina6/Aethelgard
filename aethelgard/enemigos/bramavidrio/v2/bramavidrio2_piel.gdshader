// Piel de Bramavidrio v2 (V12, rediseño del 11/11; fuente/crear_bramavidrio2.py). Spatial; Compatibility. La misma
// lógica que la v1 (enemigos/bramavidrio/bramavidrio_piel.gdshader, que no se toca): textura × color de vértice (oclusión,
// en sRGB) × «tono»; en la A de la textura (con un mínimo de 0,04), el brillo de las vetas de cristal, la línea lateral y
// las cicatrices, que late despacio y sigue a «energia» (la escala del hueso «brillo»). El alfa del COLOR DE VÉRTICE dice
// cuánto «mineral» es cada parte (1 el basalto de escamas, cráneo y cuernos; 0 la arena del vientre y la carne): el
// basalto refleja más el sol y tiene un borde de luz.
// Con RECORTE (solo en el combate) no dibuja lo que queda por debajo de «suelo» (lo enterrado).
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
	ROUGHNESS = mix(0.86, 0.42, m);
	SPECULAR = mix(0.25, 0.7, m);
	RIM = borde_mineral * m;
	RIM_TINT = 0.55;
	float pulso = 0.82 + 0.18 * sin(TIME * 1.6 + UV.y * 37.0);
	float veta = clamp((t.a - 0.04) / 0.96, 0.0, 1.0);   // el alfa guarda 0,04 + 0,96 × brillo (crear_bramavidrio2.py)
	EMISSION = color_brillo * veta * energia * pulso * 2.2;
}
