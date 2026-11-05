shader_type spatial;
// Gota de agua estilizada para las partículas: redonda, mira siempre a la cámara, con un borde
// claro y un punto de brillo arriba a la izquierda. El color llega de la rampa de las partículas.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color_brillo : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec4 color_particula;

void vertex() {
	mat4 m = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	m = m * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * m;
	color_particula = COLOR;
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;
	if (d > 1.0) {
		discard;
	}
	float borde = smoothstep(0.65, 0.95, d);
	float brillo = 1.0 - smoothstep(0.0, 0.22, length(p - vec2(-0.16, -0.16)));
	vec3 c = mix(color_particula.rgb, vec3(0.85, 0.95, 1.0), borde * 0.6);
	ALBEDO = mix(c, color_brillo.rgb, brillo);
	ALPHA = color_particula.a * (0.75 + borde * 0.25);
}
