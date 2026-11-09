// Halo de un farol, una vela o una ventana (T-089): un círculo suave que SUMA luz, con un parpadeo de llama. Hace las
// veces de luz sin serlo: las luces 2D de verdad solo en el perfil alto (guía visual, D-H05). Sin textura: el
// degradado sale de UV (el sprite lleva una imagen blanca de 4 × 4 escalada).
shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 color : source_color = vec4(1.0, 0.72, 0.38, 1.0);
uniform float fuerza = 0.5;
uniform float parpadeo = 1.0;         // 0 = fija (ventanas), 1 = llama

varying float fase;

void vertex() {
	vec2 o = MODEL_MATRIX[3].xy;
	fase = fract(sin(dot(o, vec2(41.31, 17.77))) * 43758.5453) * 6.2832;
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float h = pow(max(1.0 - d, 0.0), 2.4);
	float p = 1.0 + parpadeo * (0.07 * sin(TIME * 7.1 + fase) + 0.05 * sin(TIME * 12.7 + fase * 1.9) - 0.04);
	COLOR = vec4(color.rgb * h * fuerza * p, 1.0);
}
