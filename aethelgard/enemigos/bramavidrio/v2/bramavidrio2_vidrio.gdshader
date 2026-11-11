// Vidrio de Bramavidrio v2 (V12): las espinas y la membrana de la vela, las aletas, los abanicos de las mejillas, los
// ojos, la línea lateral y (con GARGANTA) la luz del fondo de la boca. Spatial; Compatibility. Opaco (barato): color de
// vértice (en sRGB; la membrana va de turquesa hondo en la base a cian en el borde), reflejo del sol, borde encendido
// según se mire y una onda de luz que recorre el cuerpo. «energia» es la escala del hueso «brillo» (o «garganta»).
// La membrana lleva su propia cara de atrás (crear_bramavidrio2.py), así que aquí se sigue descartando la de atrás.
// Con RECORTE (solo en el combate) no dibuja lo enterrado.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_back;

uniform vec3 color_borde : source_color = vec3(0.80, 1.0, 1.0);
uniform float energia : hint_range(0.0, 4.0) = 1.0;
uniform float suelo = 0.0;

varying float alto;
varying float onda;

void vertex() {
	COLOR.rgb = pow(COLOR.rgb, vec3(2.2));
	alto = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	onda = 0.72 + 0.28 * sin(TIME * 2.4 - length(VERTEX) * 0.45);
}

void fragment() {
#ifdef RECORTE
	if (alto < suelo) {
		discard;
	}
#endif
#ifdef GARGANTA
	ALBEDO = vec3(0.0);
	EMISSION = vec3(0.55, 0.95, 1.0) * COLOR.rgb * energia * 2.2;
#else
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = COLOR.rgb * 0.5;
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	EMISSION = (COLOR.rgb * 1.1 * onda + color_borde * fres * 0.5) * energia;
#endif
}
