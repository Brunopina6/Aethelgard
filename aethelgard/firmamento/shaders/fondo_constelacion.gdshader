shader_type canvas_item;
// Firmamento de los Ecos, concepto «constelación» (V12, PROTOTIPO APAGADO): noche profunda, una nebulosa tenue del
// color del héroe y dos capas de estrellas que titilan, con paralaje al desplazar el tablero. Sin texturas y sin
// bucles: una sola celda por capa (coste medido con malioc en docs/memory/agents/interfaz_v12_orbes.md).
uniform vec3 color_heroe : source_color = vec3(0.56, 0.83, 1.0);
uniform vec2 tam = vec2(1280.0, 720.0);
uniform vec2 centro = vec2(430.0, 380.0);
uniform vec2 desplazamiento = vec2(0.0);
uniform float pulso = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float estrellas(vec2 p, float escala, float umbral, float t) {
	vec2 g = p / escala;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id);
	vec2 o = (vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5) * 0.7;
	float d = length(f - o);
	float titila = 0.55 + 0.45 * sin(t * (0.8 + h * 2.5) + h * 40.0);
	return smoothstep(0.09, 0.0, d) * titila * step(umbral, h);
}

void fragment() {
	vec2 px = UV * tam;
	vec2 c = (px - centro) / tam.y;
	float r = length(c);
	vec3 col = mix(vec3(0.03, 0.045, 0.11), vec3(0.006, 0.008, 0.025), smoothstep(0.0, 1.0, r));
	vec2 q = (px + desplazamiento * 0.25) / tam.y * 2.4;
	float n = ruido(q * 1.4 + TIME * 0.01) * 0.6 + ruido(q * 3.2 - TIME * 0.013) * 0.4;
	n = smoothstep(0.42, 0.95, n);
	col += color_heroe * n * 0.09 + vec3(0.22, 0.08, 0.36) * n * 0.07;
	col += vec3(0.85, 0.9, 1.0) * estrellas(px + desplazamiento * 0.15, 9.0, 0.84, TIME) * 0.85;
	col += vec3(0.75, 0.85, 1.0) * estrellas(px + desplazamiento * 0.4, 24.0, 0.72, TIME * 0.7) * 0.9;
	col += color_heroe * 0.10 * exp(-r * r * 7.0);
	col *= 1.0 + pulso * 0.4;
	COLOR = vec4(col, 1.0);
}
