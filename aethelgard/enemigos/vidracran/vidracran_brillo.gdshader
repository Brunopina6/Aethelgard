shader_type spatial;
// Vidracrán (V12, prototipo): el bulbo de vidrio de botella de la cola y los ojos. «intensidad» la lleva el script
// (reposo 1; enterrado 1,4; aviso: latidos a 3,5; derrota: se apaga).
render_mode cull_back, specular_schlick_ggx;
uniform sampler2D atlas : source_color, filter_linear_mipmap;
// V12, encuentro del desierto (12/11): en el combate no hay suelo que lo tape; lo que queda por debajo de esta altura
// del mundo no se dibuja (el cuerpo enterrado). Por defecto, muy abajo: no recorta nada.
uniform float suelo_y = -1000.0;
varying float alto_mundo;

void vertex() {
	alto_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}
uniform vec3 color_brillo : source_color = vec3(0.35, 1.0, 0.5);
uniform float intensidad = 1.0;

void fragment() {
	if (alto_mundo < suelo_y) {
		discard;
	}
	vec3 c = texture(atlas, UV).rgb;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = c * 0.5;
	ROUGHNESS = 0.08;
	SPECULAR = 1.0;
	EMISSION = color_brillo * (0.55 + 0.9 * fr) * intensidad * (0.85 + 0.15 * sin(TIME * 2.3));
}
