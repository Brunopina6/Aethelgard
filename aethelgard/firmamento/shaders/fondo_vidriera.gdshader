shader_type canvas_item;
// Firmamento de los Ecos, concepto «vidriera / geoda» (V12, PROTOTIPO APAGADO): el interior de una geoda (facetas de
// Voronoi, 3×3 celdas) en amatista oscura, con haces de luz que salen del rosetón. Sin texturas.
uniform vec3 color_heroe : source_color = vec3(0.56, 0.83, 1.0);
uniform vec2 tam = vec2(1280.0, 720.0);
uniform vec2 centro = vec2(430.0, 380.0);
uniform vec2 desplazamiento = vec2(0.0);
uniform float pulso = 0.0;
uniform float zoom = 1.0;

vec2 hash2(vec2 p) {
	// sin «sin()»: más barato en Mali (malioc -c Mali-G57: 10,4 → 8,6 ciclos) y sin problemas de precisión
	vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	q += dot(q, q.yzx + 33.33);
	return fract((q.xx + q.yz) * q.zy);
}

void fragment() {
	vec2 px = UV * tam;
	vec2 g = (px + desplazamiento * 0.3) / 70.0;
	vec2 i = floor(g);
	vec2 f = fract(g);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 celda = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 b = vec2(float(x), float(y));
			vec2 o = hash2(i + b);
			vec2 rr = b + o - f;
			float d = dot(rr, rr);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				celda = i + b;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	float borde = smoothstep(0.0, 0.10, sqrt(d2) - sqrt(d1));
	float tono = hash2(celda).x;
	vec2 c = (px - centro) / (tam.y * zoom);
	float r = length(c);
	float a = atan(c.y, c.x);
	vec3 amatista = mix(vec3(0.10, 0.05, 0.16), vec3(0.16, 0.08, 0.22), tono);
	vec3 col = amatista * (0.55 + 0.45 * borde);
	col += vec3(0.55, 0.4, 0.75) * (1.0 - borde) * 0.10;
	col *= smoothstep(1.3, 0.2, r) * 0.8 + 0.25;
	float haz = pow(max(0.0, sin(a * 6.0 + TIME * 0.05)), 6.0) * smoothstep(1.2, 0.3, r);
	col += mix(color_heroe, vec3(0.8, 0.6, 1.0), 0.5) * haz * 0.05;
	col += color_heroe * 0.08 * exp(-r * r * 6.0);
	col *= 1.0 + pulso * 0.35;
	COLOR = vec4(col, 1.0);
}
