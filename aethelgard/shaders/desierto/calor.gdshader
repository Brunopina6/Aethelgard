// Ondas de calor (V12): un plano a ras de la arena caliente que deforma lo que se ve debajo. SOLO PERFIL ALTO: lee la
// pantalla (en Compatibility, una copia del fotograma cada vez que se dibuja), que en el Mali-G57 es caro.
// Sin sombreado; el borde del plano (UV) se funde. «fuerza» en fracción de pantalla (0,004 ≈ 5 píxeles a 1280).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D pantalla : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D ruido : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float fuerza = 0.004;
uniform float velocidad = 0.5;
uniform float escala = 0.22;

varying vec3 v_mundo;

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = v_mundo.xz * escala;
	float n = texture(ruido, uv + vec2(0.0, -TIME * velocidad * 0.3)).r - 0.5;
	float m = texture(ruido, uv * 1.7 + vec2(TIME * velocidad * 0.2, 0.13)).r - 0.5;
	float borde = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x) * smoothstep(0.0, 0.3, UV.y) * smoothstep(1.0, 0.7, UV.y);
	vec2 desp = vec2(n, m) * fuerza * borde;
	ALBEDO = textureLod(pantalla, SCREEN_UV + desp, 0.0).rgb;
	ALPHA = borde;
}
