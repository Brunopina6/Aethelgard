// Humbaba, brillo (V12, 12/11; fuente/crear_humbaba.py): el ojo, el núcleo del pecho, sus vetas y las gemas del bastón.
// Spatial; Compatibility. El color de vértice (sRGB) lleva el degradado (centro casi blanco, borde turquesa hondo); el
// generador marca el NÚCLEO con UV.x ≥ 5 (su esfera y sus vetas): solo el núcleo se vuelve verde enfermizo y se agrieta
// en la fase 2 («color_nucleo», «grietas») y late más fuerte en la 3; el ojo y las gemas siguen turquesa.
// «energia»: la escala del hueso «luz» del clip (humbaba_3d.gd). Con RECORTE, como la madera.
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 color_nucleo : source_color = vec3(1.0, 1.0, 1.0);
uniform float energia : hint_range(0.0, 5.0) = 1.0;
uniform float energia_nucleo : hint_range(0.0, 5.0) = 1.0;
uniform float grietas : hint_range(0.0, 1.0) = 0.0;
uniform float apagar : hint_range(0.0, 1.0) = 1.0;
uniform float suelo = -1000.0;

varying float alto;

void vertex() {
	COLOR.rgb = pow(COLOR.rgb, vec3(2.2));
	alto = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
#ifdef RECORTE
	if (alto < suelo) {
		discard;
	}
#endif
	float es_nucleo = step(5.0, UV.x);
	vec3 c = COLOR.rgb * mix(vec3(1.0), color_nucleo, es_nucleo);
	float e = mix(energia, energia_nucleo, es_nucleo);
	// grietas del núcleo (fase 2 y 3): líneas oscuras que cruzan la esfera
	float g = abs(sin(UV.x * 37.0 + sin(UV.y * 23.0) * 2.5)) * abs(sin(UV.y * 29.0 - UV.x * 7.0));
	float raja = (1.0 - smoothstep(0.0, 0.12, g)) * grietas * es_nucleo;
	c *= 1.0 - 0.75 * raja;
	float k = (0.35 + 0.65 * clamp(e, 0.0, 4.0) / 1.0) * apagar;
	ALBEDO = c * k;
	EMISSION = c * max(e, 0.0) * 0.9 * apagar * (1.0 - 0.6 * raja);
}
