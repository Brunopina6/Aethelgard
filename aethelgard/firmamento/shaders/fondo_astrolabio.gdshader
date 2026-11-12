shader_type canvas_item;
// Firmamento de los Ecos, concepto «astrolabio» (V12, PROTOTIPO APAGADO): fondo de bronce oscuro con vetas radiales
// muy tenues (metal torneado), polvo de estrellas cálido y un halo del color del héroe en el eje. Sin texturas.
uniform vec3 color_heroe : source_color = vec3(0.56, 0.83, 1.0);
uniform vec2 tam = vec2(1280.0, 720.0);
uniform vec2 centro = vec2(430.0, 380.0);
uniform vec2 desplazamiento = vec2(0.0);
uniform float pulso = 0.0;
uniform float zoom = 1.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float estrellas(vec2 p, float escala, float umbral) {
	vec2 g = p / escala;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash(id);
	vec2 o = (vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5) * 0.7;
	return smoothstep(0.08, 0.0, length(f - o)) * step(umbral, h) * (0.6 + 0.4 * sin(TIME * 1.3 + h * 30.0));
}

void fragment() {
	vec2 px = UV * tam;
	vec2 c = (px - centro) / (tam.y * zoom);
	float r = length(c);
	float a = atan(c.y, c.x);
	vec3 col = mix(vec3(0.075, 0.06, 0.055), vec3(0.012, 0.016, 0.03), smoothstep(0.05, 1.1, r));
	float vetas = sin(a * 140.0 + sin(r * 40.0) * 0.8) * 0.5 + 0.5;
	col += vec3(0.55, 0.40, 0.20) * vetas * 0.028 * smoothstep(0.95, 0.15, r);
	float anillo = smoothstep(0.012, 0.0, abs(r - 0.82)) + smoothstep(0.006, 0.0, abs(r - 0.9));
	col += vec3(0.6, 0.45, 0.22) * anillo * 0.05;
	col += vec3(1.0, 0.88, 0.7) * estrellas(px + desplazamiento * 0.2, 15.0, 0.86) * 0.45;
	col += color_heroe * 0.09 * exp(-r * r * 5.0);
	col *= 1.0 + pulso * 0.35;
	vec2 v = UV - 0.5;
	col *= 1.0 - dot(v, v) * 0.9;
	COLOR = vec4(col, 1.0);
}
