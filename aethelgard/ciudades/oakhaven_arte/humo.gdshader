// Humo de chimenea (T-089): UNA imagen por chimenea que dibuja una columna de humo con ruido que sube (dos lecturas
// de una textura de ruido de 128 × 128). Nada de partículas ni de capas apiladas (guía visual, D-H05).
// Cálido en las casas (gris tibio), frío y blanco en el crematorio (#C9D3E0).
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D ruido : repeat_enable, filter_linear;
uniform vec4 color : source_color = vec4(0.62, 0.62, 0.68, 0.5);
uniform float velocidad = 0.045;
uniform float deriva = 0.22;          // cuánto se inclina con el viento (hacia el este)

varying float fase;

void vertex() {
	vec2 o = MODEL_MATRIX[3].xy;
	fase = fract(sin(dot(o, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float alto = 1.0 - UV.y;                                  // 0 en la boca, 1 arriba
	float t = TIME * velocidad + fase * 7.0;
	vec2 uv1 = vec2(UV.x * 0.8 + fase, UV.y * 0.75 + t);
	vec2 uv2 = vec2(UV.x * 1.6 - t * 0.35 + fase * 3.0, UV.y * 1.4 + t * 1.6);
	float n1 = texture(ruido, uv1).r;
	float n2 = texture(ruido, uv2).r;
	float centro = 0.5 + deriva * alto * alto + (n1 - 0.5) * 0.18 * alto;
	float ancho = mix(0.07, 0.36, smoothstep(0.0, 0.85, alto));
	float dx = abs(UV.x - centro) / ancho;
	float forma = 1.0 - smoothstep(0.35, 1.05, dx + (n2 - 0.5) * 0.55);
	float vida = smoothstep(0.0, 0.06, alto) * (1.0 - smoothstep(0.45, 1.0, alto));
	float dens = forma * vida * (0.45 + 0.75 * n2 * n1);
	COLOR = vec4(color.rgb * (0.88 + 0.22 * n1), clamp(color.a * dens, 0.0, 1.0));
}
