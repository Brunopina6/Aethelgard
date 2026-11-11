// Arena del Mar de Cristal (V12). Spatial; funciona en Compatibility. Sin texturas de imagen: solo un ruido de 128×128
// que genera Godot (zonas3d/mar_cristal/materiales_arte.gd) y unas cuentas.
//   - Ondas de viento (ripples) en coordenadas del mundo, por rodales, con perfil asimétrico (lomo largo a barlovento,
//     cara corta a sotavento). Casi no se pintan: cambian la normal, así que las dibuja la luz rasante. De lejos se
//     apagan solas (no parpadean cuando una onda ocupa pocos píxeles).
//   - Color cálido que cambia con la luz (light()): lo iluminado, del color del sol; la sombra, con el rebote ocre rosado
//     de la arena de alrededor (nunca gris); y un brillo rasante en los lomos al contraluz.
//   - Viento: vetas de arena suelta que corren sobre el suelo. «viento» va de 0 (calma) a 1 (tormenta).
//   - Perfil alto (#define BRILLOS): destellos de los granos de vidrio del Mar de Cristal, que titilan al moverse la cámara.
//   - El color de vértice multiplica (1 = tal cual): oscurece donde la arena toca la piedra y deja al terreno pintar zonas.
shader_type spatial;
render_mode diffuse_lambert;

uniform sampler2D ruido : hint_default_white, filter_linear_mipmap, repeat_enable;

group_uniforms colores;
uniform vec3 color_arena : source_color = vec3(0.82, 0.62, 0.41);
uniform vec3 color_valle : source_color = vec3(0.71, 0.49, 0.32);    // manchas y senos de las ondas
uniform vec3 color_claro : source_color = vec3(0.92, 0.78, 0.58);    // lomos y arena suelta
uniform float escala_manchas = 0.035;
uniform float contraste_manchas : hint_range(0.0, 1.0) = 0.6;

group_uniforms luz;
uniform vec3 color_sombra : source_color = vec3(0.66, 0.38, 0.30);   // tinte del rebote en la sombra
uniform float fuerza_sombra : hint_range(0.0, 1.0) = 0.32;
uniform float envoltura : hint_range(0.0, 1.0) = 0.3;                // suaviza el paso de luz a sombra
uniform float rasante : hint_range(0.0, 2.0) = 0.45;                 // brillo al contraluz en los lomos

group_uniforms ondas;
uniform float onda_largo = 0.85;           // metros entre cresta y cresta
uniform float onda_fuerza : hint_range(0.0, 1.5) = 0.6;
uniform float onda_torcer = 0.6;           // cuánto serpentean

group_uniforms viento;
uniform vec2 dir_viento = vec2(1.0, -0.25);   // hacia dónde sopla (x este, y = z del mundo, sur)
uniform float viento : hint_range(0.0, 1.0) = 0.25;
uniform float velocidad_vetas = 1.0;
uniform float fuerza_vetas : hint_range(0.0, 1.0) = 0.55;

#ifdef BRILLOS
group_uniforms brillos;
uniform vec3 color_destello : source_color = vec3(0.85, 1.0, 1.0);
uniform float destellos : hint_range(0.0, 3.0) = 1.2;
#endif

#ifdef SOMBRA_HORNEADA
// Perfil sin sombras (12/11): las sombras de las piezas, horneadas por la región en una textura del tamaño del sector
// (zonas3d/mar_cristal/sombras_bajo.gd). Negra (sin sombra) si nadie la pone. Sirve al suelo y a los montones de las
// piezas, que comparten material: la sombra pasa de uno a otro sin costura.
group_uniforms sombra_horneada;
uniform sampler2D sombra_horneada : hint_default_black, filter_linear, repeat_disable;
uniform vec4 sombra_rect = vec4(0.0, 0.0, 0.01, 0.01);    // x0, z0, 1/ancho, 1/fondo (metros)
uniform vec3 sombra_tinte : source_color = vec3(0.66, 0.62, 0.72);
uniform float sombra_fuerza : hint_range(0.0, 1.0) = 0.0;
#endif

varying vec3 v_mundo;

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	COLOR.rgb = pow(COLOR.rgb, vec3(2.2));    // los colores de vértice van en sRGB (fuente/crear_desierto.py)
}

void fragment() {
	vec2 p = v_mundo.xz;
	vec2 d = normalize(dir_viento);
	vec2 perp = vec2(-d.y, d.x);
	float n1 = texture(ruido, p * escala_manchas).r;
	float n2 = texture(ruido, p * 0.045 + vec2(0.37, 0.71)).r;

	// ondas: crestas perpendiculares al viento, torcidas por el ruido; por rodales (donde el viento las ha peinado)
	float fase = dot(p, d) / onda_largo + (n2 - 0.5) * onda_torcer * 2.0 + dot(p, perp) * 0.04;
	float s = fract(fase) * 6.2831853;
	float alto_onda = 0.5 + 0.5 * sin(s - 0.45 * sin(s));          // lomo largo y cara corta
	float pend = cos(s - 0.45 * sin(s)) * (1.0 - 0.45 * cos(s));
	float vis = 1.0 - smoothstep(0.16, 0.42, fwidth(fase));
	float rodal = smoothstep(0.32, 0.72, texture(ruido, p * 0.018 + vec2(0.61, 0.13)).r);
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float llano = smoothstep(0.5, 0.92, nw.y);
	float k = onda_fuerza * vis * llano * (0.25 + 0.75 * rodal) * 0.3;
	nw = normalize(nw - vec3(d.x, 0.0, d.y) * pend * k);
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);

	// color: manchas grandes, senos algo más oscuros, lomos algo más claros
	float m = mix(0.5, n1, contraste_manchas);
	vec3 c = mix(color_valle, color_arena, smoothstep(0.15, 0.85, m + (alto_onda - 0.5) * 0.12 * vis * rodal));
	c = mix(c, color_claro, smoothstep(0.62, 0.95, n1) * 0.45);

	// vetas de arena suelta que corren con el viento
	vec2 q = vec2(dot(p, d), dot(p, perp));
	float t = TIME * velocidad_vetas * (0.35 + viento * 1.4);
	float v1 = texture(ruido, vec2(q.x * 0.04 - t * 0.09, q.y * 0.55)).r;
	float v2 = texture(ruido, vec2(q.x * 0.10 - t * 0.21, q.y * 1.4 + 0.5)).r;
	float vetas = smoothstep(0.5, 0.82, v1 * 0.55 + v2 * 0.65) * smoothstep(0.03, 0.5, viento);
	c = mix(c, color_claro, vetas * fuerza_vetas * llano);

	ALBEDO = c * COLOR.rgb;
#ifdef SOMBRA_HORNEADA
	float sh = texture(sombra_horneada, (p - sombra_rect.xy) * sombra_rect.zw).r;
	ALBEDO *= mix(vec3(1.0), sombra_tinte, sh * sombra_fuerza);
#endif
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;            // mate: sin reflejo del cielo (con él, la arena al sol se quemaba a blanco)

#ifdef BRILLOS
	// granos de vidrio: una celda de 9 cm de cada muchas se enciende según desde dónde se mire
	vec2 celda = floor(p * 11.0);
	vec3 vw = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float h = fract(sin(dot(celda, vec2(12.9898, 78.233))) * 43758.5453);
	float ang = fract(h * 7.13 + dot(vw.xz, vec2(3.1, 2.3)) * 1.5);
	float chispa = step(0.993, h) * smoothstep(0.82, 1.0, 1.0 - abs(ang - 0.5) * 2.0);
	float cerca = 1.0 - smoothstep(0.08, 0.25, fwidth(p.x * 11.0));
	EMISSION = color_destello * chispa * cerca * destellos * llano;
#endif
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float w = clamp((ndl + envoltura) / (1.0 + envoltura), 0.0, 1.0);
	vec3 luz = LIGHT_COLOR * ATTENUATION * w;
	// sombra cálida: donde no llega el sol (o la cara le da la espalda), el rebote de la arena iluminada
	float sol = ATTENUATION * clamp(ndl * 3.0 + 0.2, 0.0, 1.0);
	vec3 rebote = LIGHT_COLOR * color_sombra * fuerza_sombra * (1.0 - sol);
	// brillo rasante en los lomos al contraluz
	float vd = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 borde = LIGHT_COLOR * ATTENUATION * pow(vd, 4.0) * rasante * clamp(ndl, 0.0, 1.0);
	DIFFUSE_LIGHT += (luz + rebote + borde) / PI;
}
