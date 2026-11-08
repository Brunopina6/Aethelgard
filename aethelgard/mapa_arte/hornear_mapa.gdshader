// Pintura del mapamundi, SOLO SIN CONEXIÓN (T-085): la usa generar_mapa.gd para hornear mapa_mundo.webp.
// No se usa en el juego: aquí el coste no importa (sombras proyectadas, varias octavas de ruido...).
// Entradas (rejilla de 2 px del mundo, ya alineada con la máscara del juego; ver datos_mapa.gd):
//   campos  R = distancia con signo a la costa en px (+ tierra, − mar), G = altura, B = campo v de mapa.gd,
//           A = cavidad (altura − altura suavizada: valles < 0, crestas > 0)
//   zonas_a = peso de bosque, llanura, montaña y nieve; zonas_b = desierto, yermo, ceniza y «sendero» (caminos)
// Luz de arriba a la izquierda, sombras azuladas (docs/guia_visual.md).
shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform sampler2D campos : filter_linear, repeat_disable;
uniform sampler2D zonas_a : filter_linear, repeat_disable;
uniform sampler2D zonas_b : filter_linear, repeat_disable;
uniform vec2 tam_mundo = vec2(2400.0, 1350.0);
uniform float paso = 2.0;
uniform vec2 abismo = vec2(380.0, 1050.0);     // el Abismo de Ceniza: lava y brasas a su alrededor

// ---------------------------------------------------------------- ruido propio (valor y gradiente)
float h21(vec2 p) {
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 23.45);
	return fract(p.x * p.y);
}
vec2 h22(vec2 p) {
	float a = h21(p);
	return vec2(a, h21(p + a * 57.0 + 11.0));
}
float vruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), u.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p, int oct) {
	float s = 0.0;
	float a = 0.5;
	float n = 0.0;
	for (int i = 0; i < 6; i++) {
		if (i >= oct) break;
		s += a * vruido(p);
		n += a;
		p = p * 2.07 + vec2(17.3, 9.1);
		a *= 0.5;
	}
	return s / n;
}

vec4 campo(vec2 p) { return texture(campos, p / tam_mundo); }

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

// rampa de 4 colores en t (0..1)
vec3 rampa4(vec3 a, vec3 b, vec3 c, vec3 d, float t) {
	t = clamp(t, 0.0, 1.0) * 3.0;
	if (t < 1.0) return mix(a, b, t);
	if (t < 2.0) return mix(b, c, t - 1.0);
	return mix(c, d, t - 2.0);
}

// ---------------------------------------------------------------- agua
vec3 agua(vec2 p, float sdf, float px_v) {
	float d = -sdf;                                            // distancia a la costa (px), > 0 en el mar
	float n1 = fbm(p * 0.006, 4);
	float n2 = fbm(p * 0.02 + 40.0, 3);
	// plataforma: el agua poco honda llega más lejos en unos sitios que en otros
	float hondo = d * (0.8 + 0.5 * n1);
	vec3 turquesa_claro = vec3(0.47, 0.84, 0.80);
	vec3 turquesa = vec3(0.24, 0.66, 0.74);
	vec3 azul_plataforma = vec3(0.16, 0.47, 0.68);
	vec3 azul = vec3(0.12, 0.33, 0.58);
	vec3 anil = vec3(0.085, 0.20, 0.45);
	vec3 noche = vec3(0.065, 0.13, 0.33);
	vec3 c;
	if (hondo < 34.0) c = rampa4(turquesa_claro, turquesa, azul_plataforma, azul, pow(smoothstep(0.0, 34.0, hondo), 0.8));
	else c = rampa4(azul, mix(azul, anil, 0.35), anil, noche, smoothstep(34.0, 320.0, hondo));
	// manchas grandes (corrientes y sombras de nubes) y textura fina del oleaje
	c *= 0.93 + 0.12 * n1 + 0.05 * (n2 - 0.5);
	// destellos de luz en lo poco hondo (cáusticas suaves)
	float caus = smoothstep(0.62, 0.9, fbm(p * 0.09 + vec2(n2 * 4.0), 3));
	c += vec3(0.08, 0.10, 0.09) * caus * (1.0 - smoothstep(3.0, 22.0, d));
	// anillos de oleaje paralelos a la costa, rotos como a pincel
	float rotura = fbm(p * 0.035 + 7.0, 3);
	for (int k = 0; k < 3; k++) {
		float dk = 8.0 + float(k) * 11.0 + float(k * k) * 4.0;
		float ancho_l = 1.0 - 0.15 * float(k);
		float linea = 1.0 - smoothstep(ancho_l * 0.5, ancho_l * 0.5 + 0.8, abs(d - dk - (n2 - 0.5) * 5.0));
		float corte = smoothstep(0.36 + 0.07 * float(k), 0.46 + 0.07 * float(k), rotura);
		c = mix(c, vec3(0.84, 0.96, 1.0), linea * corte * (0.50 - 0.13 * float(k)));
	}
	// espuma en la orilla: una línea fina y clara
	float espuma = 1.0 - smoothstep(0.4, 1.8 + 1.2 * n2, d);
	c = mix(c, vec3(0.95, 1.0, 0.98), espuma * 0.8);
	// trazos de ola sueltos en el mar abierto (pequeños arcos claros)
	vec2 celda = floor(p / 46.0);
	vec2 r = h22(celda);
	if (r.x > 0.55 && d > 60.0) {
		vec2 cen = (celda + 0.25 + 0.5 * h22(celda + 3.1)) * 46.0;
		vec2 q = (p - cen) * vec2(1.0, 2.2);
		float rad = 7.0 + 4.0 * r.y;
		float arco = 1.0 - smoothstep(0.55, 1.4, abs(length(q) - rad));
		arco *= step(q.y, -rad * 0.35) ;                         // solo la parte de arriba del círculo
		c = mix(c, vec3(0.70, 0.84, 1.0), arco * 0.35 * smoothstep(60.0, 120.0, d));
	}
	return c;
}

// lago (agua dulce sin oleaje: más verde y clara) o, en la ceniza, lava con costra
vec3 lago_color(vec2 p, float d, float ceniza) {
	float n = fbm(p * 0.05, 3);
	vec3 c = mix(vec3(0.42, 0.80, 0.74), vec3(0.16, 0.52, 0.62), smoothstep(0.0, 22.0, d * (0.8 + 0.4 * n)));
	c = mix(c, vec3(0.92, 1.0, 0.96), (1.0 - smoothstep(0.4, 1.6, d)) * 0.7);
	// lava: costra oscura con grietas que brillan y un borde incandescente
	float grietas = 1.0 - smoothstep(0.02, 0.09, abs(fbm(p * 0.07 + 3.0, 4) - 0.5));
	vec3 lava = mix(vec3(0.20, 0.07, 0.05), vec3(0.55, 0.12, 0.04), n);
	lava = mix(lava, vec3(1.0, 0.55, 0.16), grietas * 0.9);
	lava = mix(lava, vec3(1.0, 0.72, 0.30), (1.0 - smoothstep(0.5, 4.0, d)) * 0.85);
	return mix(c, lava, ceniza);
}

// ---------------------------------------------------------------- tierra
vec3 bioma_color(vec4 za, vec4 zb, vec2 p, float h, float pendiente, float sdf, float cav) {
	float n = fbm(p * 0.03, 4);
	float nf = fbm(p * 0.16 + 3.0, 3);
	float ng = fbm(p * 0.008 + 11.0, 3);
	// llanura: verde amarillento y saturado, con prados más claros y zonas más frescas
	vec3 llanura = mix(vec3(0.50, 0.72, 0.26), vec3(0.70, 0.83, 0.33), smoothstep(0.35, 0.7, ng));
	llanura = mix(llanura, vec3(0.42, 0.66, 0.30), smoothstep(0.55, 0.8, n) * 0.6);
	llanura *= 0.92 + 0.16 * nf;
	// bosque: suelo verde hondo (los árboles se pintan aparte)
	vec3 bosque = mix(vec3(0.20, 0.45, 0.20), vec3(0.28, 0.55, 0.24), n) * (0.9 + 0.2 * nf);
	// montaña: laderas con hierba abajo y roca gris cálida arriba
	vec3 roca = mix(vec3(0.58, 0.53, 0.47), vec3(0.72, 0.67, 0.59), nf);
	vec3 ladera = mix(vec3(0.47, 0.62, 0.32), vec3(0.56, 0.62, 0.38), n);
	vec3 montana = mix(ladera, roca, smoothstep(0.18, 0.42, h + 0.25 * pendiente + 0.1 * (n - 0.5)));
	montana = mix(montana, vec3(0.95, 0.96, 1.0), smoothstep(0.78, 0.9, h + 0.08 * (nf - 0.5)) * (1.0 - smoothstep(0.55, 0.9, pendiente)));
	// nieve: blanca con roca en las pendientes fuertes
	vec3 nieve = mix(vec3(0.90, 0.93, 0.98), vec3(0.97, 0.98, 1.0), nf);
	nieve = mix(nieve, vec3(0.62, 0.60, 0.66) * (0.85 + 0.3 * nf), smoothstep(0.62, 0.92, pendiente) * 0.7);
	// desierto: arena cálida
	vec3 desierto = mix(vec3(0.89, 0.73, 0.45), vec3(0.95, 0.83, 0.55), ng) * (0.95 + 0.1 * nf);
	// yermo: brezo violeta con claros lavanda
	vec3 yermo = mix(vec3(0.52, 0.40, 0.66), vec3(0.66, 0.55, 0.80), smoothstep(0.4, 0.72, n));
	yermo = mix(yermo, vec3(0.42, 0.33, 0.56), smoothstep(0.6, 0.8, ng) * 0.7) * (0.92 + 0.16 * nf);
	// ceniza: gris ceniza oscuro
	vec3 ceniza = mix(vec3(0.27, 0.25, 0.30), vec3(0.38, 0.35, 0.40), n) * (0.9 + 0.2 * nf);
	float total = za.r + za.g + za.b + za.a + zb.r + zb.g + zb.b + 1e-4;
	vec3 c = (bosque * za.r + llanura * za.g + montana * za.b + nieve * za.a + desierto * zb.r + yermo * zb.g + ceniza * zb.b) / total;
	return c;
}

void fragment() {
	vec2 p = UV * tam_mundo;
	vec4 f = campo(p);
	float sdf = f.r;
	float v = f.b;
	// distancia exacta a la costa en px de pantalla a partir del campo continuo (borde suave sin escalones)
	float gv = max(length(vec2(dFdx(v), dFdy(v))), 1e-5);
	float costa_px = v / gv;                                  // > 0 tierra
	float tierra = smoothstep(-0.7, 0.7, costa_px);
	float sdf_cerca = mix(costa_px, sdf, smoothstep(4.0, 8.0, abs(sdf)));   // cerca de la costa, la medida exacta

	// ---- agua: océano o lago (zb.a), y en la ceniza los lagos son de lava
	vec4 za = texture(zonas_a, p / tam_mundo);
	vec4 zb = texture(zonas_b, p / tam_mundo);
	vec3 c_agua = agua(p, min(sdf_cerca, -0.01), costa_px);
	float es_lago = smoothstep(0.3, 0.7, zb.a);
	float volcan = max(smoothstep(0.3, 0.6, zb.b), 1.0 - smoothstep(150.0, 230.0, distance(p, abismo)));
	if (es_lago > 0.0) {
		c_agua = mix(c_agua, lago_color(p, max(-sdf_cerca, 0.0), volcan), es_lago);
	}

	// ---- tierra: relieve
	float e = paso;
	float hx = campo(p + vec2(e, 0.0)).g - campo(p - vec2(e, 0.0)).g;
	float hy = campo(p + vec2(0.0, e)).g - campo(p - vec2(0.0, e)).g;
	float relieve = 95.0;                                      // exageración del relieve para el sombreado
	vec3 nrm = normalize(vec3(-hx * relieve / (2.0 * e), -hy * relieve / (2.0 * e), 1.0));
	vec3 luz = normalize(vec3(-1.0, -1.15, 1.25));
	float lamb = dot(nrm, luz);
	float plano = dot(vec3(0.0, 0.0, 1.0), luz);
	float pendiente = 1.0 - nrm.z;
	pendiente = clamp(pendiente * 3.0, 0.0, 1.0);
	// sombra proyectada: marcha hacia la luz
	float h0 = f.g;
	float sombra = 1.0;
	vec2 dir = normalize(vec2(-1.0, -1.15));
	float tan_sol = 0.0055;                                    // altura por px que sube el rayo
	for (int i = 1; i <= 28; i++) {
		float t = float(i) * 5.0;
		float hr = campo(p + dir * t).g;
		float exceso = hr - (h0 + t * tan_sol);
		sombra = min(sombra, 1.0 - smoothstep(0.0, 0.05, exceso));
	}
	vec3 c_tierra = bioma_color(za, zb, p, h0, pendiente, sdf, f.a);
	// orilla: arena en las costas bajas, roca oscura en las de montaña, nieve y ceniza
	float n_or = fbm(p * 0.05, 3);
	float playa = 1.0 - smoothstep(2.5 + 4.0 * n_or, 5.5 + 5.0 * n_or, sdf_cerca);
	float rocosa = clamp(za.b + za.a + zb.b, 0.0, 1.0);
	vec3 arena = mix(vec3(0.93, 0.85, 0.64), vec3(0.97, 0.91, 0.72), n_or);
	vec3 roca_orilla = mix(vec3(0.42, 0.40, 0.42), vec3(0.55, 0.52, 0.52), n_or);
	c_tierra = mix(c_tierra, mix(arena, roca_orilla, rocosa), playa * (1.0 - zb.r * 0.0));
	// luz: cálida en las caras al sol, azulada en las de sombra (más clara sobre la nieve); cavidad en los valles
	float k = (lamb - plano * 0.88) * 1.35;
	float blanco = clamp(za.a + smoothstep(0.78, 0.9, h0) * za.b, 0.0, 1.0);
	vec3 luz_c = mix(vec3(1.0, 0.95, 0.84), vec3(1.0, 0.99, 0.95), blanco);
	vec3 sombra_c = mix(vec3(0.60, 0.63, 0.82), vec3(0.72, 0.80, 0.97), blanco);
	vec3 tono = k > 0.0 ? mix(vec3(1.0), luz_c * 1.08, clamp(k, 0.0, 1.0)) : mix(vec3(1.0), sombra_c, clamp(-k, 0.0, 1.0));
	c_tierra *= tono;
	c_tierra *= mix(vec3(1.0), sombra_c, (1.0 - sombra) * 0.42);
	c_tierra *= 1.0 + clamp(f.a * 2.2, -0.16, 0.08);
	c_tierra = min(c_tierra, vec3(1.0));
	// vetas de brasa en la ceniza, más vivas cerca de la fortaleza
	float vetas = 1.0 - smoothstep(0.012, 0.05, abs(fbm(p * 0.035 + 9.0, 4) - 0.5));
	float cerca_abismo = 1.0 - smoothstep(60.0, 240.0, distance(p, abismo));
	vec3 brasa = vec3(1.0, 0.45, 0.16);
	c_tierra = mix(c_tierra, brasa, vetas * zb.b * (0.35 + 0.5 * cerca_abismo) * smoothstep(8.0, 20.0, sdf));
	// línea de tinta de la costa (fina, para que se lea en el móvil)
	float tinta = 1.0 - smoothstep(0.55, 1.5, abs(costa_px + 0.3));
	vec3 c = mix(c_agua, c_tierra, tierra);
	c = mix(c, vec3(0.13, 0.22, 0.25), tinta * 0.55);
	// bruma del borde del mundo (el Océano de Bruma se cierra en niebla)
	vec2 borde = min(p, tam_mundo - p);
	float b = 1.0 - smoothstep(0.0, 170.0, min(borde.x, borde.y) + 120.0 * (fbm(p * 0.006 + 5.0, 4) - 0.35));
	c = mix(c, vec3(0.60, 0.64, 0.84), b * 0.40);
	// tramado mínimo contra las bandas de 8 bits
	c += (h21(p + 0.5) - 0.5) / 255.0;
	COLOR = vec4(c, 1.0);
}
