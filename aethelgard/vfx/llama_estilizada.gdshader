shader_type spatial;
// Llama estilizada (tipo JRPG) para las partículas: siempre mira a la cámara, borde recortado
// en dos bandas de color (sin degradado suave) y un poco de ruido que sube para que se mueva.
// El color de cada partícula llega de la rampa de color de las partículas (COLOR).
// Mezcla normal (no aditiva): así muchas llamas juntas no se queman a blanco.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D ruido : repeat_enable, filter_linear;
uniform vec4 color_centro : source_color = vec4(1.0, 0.72, 0.2, 1.0);
uniform float corte = 0.22;             // dónde se recorta el borde
uniform float velocidad = 2.0;

varying vec4 color_particula;
varying float semilla;

void vertex() {
	// mirar siempre a la cámara conservando el tamaño de cada partícula
	mat4 m = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	m = m * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * m;
	color_particula = COLOR;
	semilla = INSTANCE_CUSTOM.x;                                 // cada partícula con su propio ruido
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	p.y *= 0.8;                                                  // un poco alargada hacia arriba
	float d = length(p) * 2.0;
	float n = texture(ruido, UV * 0.9 + vec2(semilla, -TIME * velocidad)).r;
	float forma = 1.0 - d + (n - 0.5) * 0.7 - max(0.0, -p.y) * 0.4;
	float borde = step(corte, forma);
	float nucleo = step(corte + 0.32, forma);
	ALBEDO = mix(color_particula.rgb, color_centro.rgb, nucleo);
	ALPHA = borde * color_particula.a;
}
