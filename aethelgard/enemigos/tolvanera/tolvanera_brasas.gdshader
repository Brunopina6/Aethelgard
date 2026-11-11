shader_type spatial;
// Tolvanera (V12, prototipo): las dos brasas de los ojos. Sin luz, opacas y dibujadas después del polvo
// (render_priority en el script), así se ven a través del remolino; centro amarillo y borde naranja oscuro.
// «intensidad» la baja el script en la derrota; la escala del hueso «brasa» hace el resto.
render_mode unshaded, blend_mix, cull_back, shadows_disabled;
uniform vec3 color_brasa : source_color = vec3(0.95, 0.34, 0.06);
uniform vec3 color_centro : source_color = vec3(1.0, 0.86, 0.38);
uniform float intensidad = 1.0;

void fragment() {
	float fr = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float parpadeo = 0.88 + 0.12 * sin(TIME * 11.0) * sin(TIME * 7.3);
	ALBEDO = mix(color_brasa, color_centro, smoothstep(0.55, 0.95, fr)) * parpadeo;
	ALPHA = clamp(intensidad, 0.0, 1.0);
}
