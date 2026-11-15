// V12, mapamundi 3D (15/11/2026): efectos pequeños de las maquetas, sin texturas y sin luz (baratos):
//   modo 0, río: franjas claras que bajan por la UV (v) sobre el azul;
//   modo 1, cascada: espuma blanca que cae deprisa;
//   modo 2, remolino del Portal del Vacío: espiral morada que gira, más brillante en el centro;
//   modo 3, llama de la hoguera: degradado de amarillo a rojo que tiembla y se deshace arriba (con transparencia);
//   modo 4, humo frío del crematorio y bruma: bola blanca azulada que se desvanece por los bordes (con transparencia).
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque;

uniform int modo = 0;
uniform vec4 color_a : source_color = vec4(0.18, 0.55, 0.72, 1.0);
uniform vec4 color_b : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform float opacidad = 1.0;
uniform float velocidad = 1.0;

void fragment() {
	vec2 uv = UV;
	vec3 c = color_a.rgb;
	float a = opacidad;
	if (modo == 0) {
		float f = sin(uv.y * 22.0 - TIME * 3.0 * velocidad + sin(uv.x * 9.0) * 1.5);
		c = mix(color_a.rgb, color_b.rgb, smoothstep(0.75, 0.98, f) * 0.6);
	} else if (modo == 1) {
		float f = fract(uv.y * 3.0 - TIME * 2.2 * velocidad + sin(uv.x * 17.0) * 0.12);
		c = mix(color_a.rgb, color_b.rgb, 0.55 + 0.45 * smoothstep(0.2, 0.9, f));
	} else if (modo == 2) {
		vec2 p = uv * 2.0 - 1.0;
		float r = length(p);
		float ang = atan(p.y, p.x);
		float espiral = sin(ang * 3.0 + r * 9.0 - TIME * 2.6 * velocidad);
		c = mix(color_a.rgb, color_b.rgb, smoothstep(0.0, 1.0, espiral * 0.5 + 0.5) * (1.0 - r));
		c += vec3(0.5, 0.35, 0.7) * pow(1.0 - clamp(r, 0.0, 1.0), 3.0);
		a = opacidad * (1.0 - smoothstep(0.9, 1.0, r));
	} else if (modo == 3) {
		float temblor = sin(TIME * 13.0 + uv.y * 9.0) * 0.06 + sin(TIME * 7.3) * 0.04;
		float x = abs(uv.x - 0.5 + temblor * uv.y) * 2.0;
		float forma = 1.0 - smoothstep(0.35 * (1.0 - uv.y) + 0.02, 0.6 * (1.0 - uv.y) + 0.05, x);
		c = mix(color_b.rgb, color_a.rgb, uv.y);
		a = opacidad * forma * (1.0 - smoothstep(0.75, 1.0, uv.y));
	} else {
		vec2 p = uv * 2.0 - 1.0;
		a = opacidad * (1.0 - smoothstep(0.3, 1.0, length(p)));
		c = color_a.rgb;
	}
	ALBEDO = c;
	ALPHA = a;
}
