shader_type spatial;
// Tolvanera (V12, prototipo): polvo que gira y sube por el embudo. UV cilíndricas del modelo: u alrededor, v de abajo
// arriba (en la falda, de dentro afuera). Sin luz (el polvo no tiene caras): el color lo da el ruido.
// Transparente: dos capas (núcleo y polvo) más la falda; cull_back y sin escribir profundidad (presupuesto del Mali).
render_mode unshaded, cull_back, depth_draw_never, blend_mix, shadows_disabled;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec3 color_polvo : source_color = vec3(0.86, 0.72, 0.50);
uniform vec3 color_sombra : source_color = vec3(0.52, 0.40, 0.27);
uniform vec3 color_barro : source_color = vec3(0.30, 0.22, 0.15);
uniform float alfa = 0.7;
uniform float velocidad = 0.55;   // vueltas por segundo (en u)
uniform float subida = 0.30;
uniform float vetas_u = 2.0;
uniform float barro = 0.0;        // 0..1: el Agua lo asienta
uniform float desvanecer = 1.0;   // 1 entero; 0 deshecho

void fragment() {
	vec2 uv = UV;
	float n1 = texture(ruido, vec2(uv.x * vetas_u + TIME * velocidad, uv.y * 1.3 - TIME * subida)).r;
	float n2 = texture(ruido, vec2(uv.x * (vetas_u + 1.0) - TIME * velocidad * 1.4 + 0.37, uv.y * 2.1 - TIME * subida * 0.6 + 0.11)).r;
	float vetas = smoothstep(0.30, 0.85, n1 * 0.65 + n2 * 0.55);
	float frente = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float extremos = smoothstep(0.0, 0.10, uv.y) * smoothstep(1.0, 0.80, uv.y);
	vec3 col = mix(color_sombra, color_polvo, clamp(vetas * 0.75 + 0.25 * uv.y, 0.0, 1.0));
	col = mix(col, color_barro, barro);
	ALBEDO = col;
	ALPHA = clamp(alfa * (0.30 + vetas) * mix(0.35, 1.0, frente) * extremos * desvanecer * (1.0 + barro * 0.4), 0.0, 1.0);
}
