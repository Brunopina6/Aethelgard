// Humbaba, madera (V12, 12/11; fuente/crear_humbaba.py). Spatial; Compatibility. La textura (WebP, repetible) es el
// detalle de la corteza en gris (surcos, fibras, grietas) y en su A guarda las vetas turquesa (0,04 + 0,96 × brillo);
// el COLOR DE VÉRTICE pone el color de cada parte (corteza, musgo, garras: en sRGB) y en su A cuánto puede brillar la
// veta (0 en el musgo y las garras). La luz de las vetas sigue a «energia» (la escala del hueso «luz» de cada clip, que
// pone humbaba_3d.gd) y a «color_luz» (turquesa; verde enfermizo en la fase 2). «grietas» abre más vetas (fases 2 y 3).
// Con RECORTE (en el combate) no dibuja lo que queda bajo «suelo» (las garras y el bastón hundidos en la tierra).
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_back;

uniform sampler2D textura : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 color_luz : source_color = vec3(0.3, 0.98, 0.86);
uniform float energia : hint_range(0.0, 5.0) = 1.0;
uniform float grietas : hint_range(0.0, 1.0) = 0.0;
uniform float apagar : hint_range(0.0, 1.0) = 1.0;
uniform float suelo = -1000.0;
uniform float tono : hint_range(0.3, 2.0) = 1.35;   // (la madera oscura de la lámina, legible con la luz del combate)

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
	vec4 t = texture(textura, UV);
	ALBEDO = t.rgb * COLOR.rgb * tono * mix(0.55, 1.0, apagar);
	ROUGHNESS = 0.88;
	SPECULAR = 0.25;
	float veta = clamp((t.a - 0.04) / 0.96, 0.0, 1.0);
	float mascara = clamp(COLOR.a + grietas * 0.6 * step(0.001, COLOR.a + 0.001), 0.0, 1.0);
	float pulso = 0.82 + 0.18 * sin(TIME * 1.7 + UV.y * 11.0);
	EMISSION = color_luz * veta * mascara * energia * pulso * 1.6 * apagar;
}
