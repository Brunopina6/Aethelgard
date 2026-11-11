// Arena arrastrada por el viento (V12): cintas finas casi a ras de suelo, alineadas con el viento, por las que corren
// vetas de arena. Spatial, sin sombreado y transparente; Compatibility. Una sola malla (todas las cintas): una llamada.
// La malla y su número de cintas los pone materiales_arte.gd según el perfil. «intensidad» va de 0 (no se ve: el nodo se
// oculta) a 1 (tormenta: más vetas, más rápidas y más opacas). El UV de la cinta (u a lo largo, v a lo ancho) hace el
// borde suave; las vetas salen del mundo, así que la cinta puede seguir a Kael sin que las vetas «viajen» con él.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D ruido : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 color : source_color = vec3(0.96, 0.82, 0.60);
uniform float intensidad : hint_range(0.0, 1.0) = 0.3;
uniform vec2 dir_viento = vec2(1.0, -0.25);
uniform float velocidad = 3.0;
uniform float escala = 0.09;
uniform float alfa_max : hint_range(0.0, 1.0) = 0.5;

varying vec3 v_mundo;
varying float v_alfa;

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_alfa = COLOR.a;
}

void fragment() {
	vec2 d = normalize(dir_viento);
	vec2 perp = vec2(-d.y, d.x);
	vec2 q = vec2(dot(v_mundo.xz, d), dot(v_mundo.xz, perp));
	float sp = velocidad * (0.4 + intensidad * 1.8);
	float a = texture(ruido, vec2(q.x * escala * 0.35 - TIME * sp * 0.045, q.y * escala * 3.0 + v_mundo.y)).r;
	float b = texture(ruido, vec2(q.x * escala * 0.9 - TIME * sp * 0.11, q.y * escala * 7.0 + 0.3)).r;
	float vetas = smoothstep(0.42 - intensidad * 0.12, 0.8, a) * smoothstep(0.3, 0.72, b);
	float borde = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x) * smoothstep(0.0, 0.5, UV.y) * smoothstep(1.0, 0.5, UV.y);
	ALBEDO = color;
	ALPHA = vetas * borde * v_alfa * alfa_max * smoothstep(0.0, 0.3, intensidad) * (0.4 + 0.6 * intensidad);
}
