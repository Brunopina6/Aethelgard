// Follaje de la PRUEBA de paquetes (Quaternius: copas, arbustos, flores, helechos).
// Las hojas del paquete son de un solo color plano; lo que les da volumen y "pintura" aquí:
//   - degradado de abajo (sombra fresca) a arriba (luz cálida) dentro de cada planta;
//   - oclusión: el interior de la copa es más oscuro que el borde (profundidad);
//   - variación suave de tono entre grupos de hojas (no un único verde de plástico);
//   - normales "de esfera" en las copas: la copa se ilumina como una bola, no hoja a hoja;
//   - luz que atraviesa las hojas (contraluz) y un relleno suave para que nada caiga a negro;
//   - saturación ajustable para que todo comparta la misma paleta;
//   - viento: vaivén de toda la planta + temblor de cada hoja, más fuerte arriba.
// Compatible con GL Compatibility: sin texturas de pantalla ni de profundidad.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tinte : source_color = vec4(1.0);
uniform vec4 color_bajo : source_color = vec4(0.55, 0.66, 0.62, 1.0);
uniform vec4 color_alto : source_color = vec4(1.1, 1.06, 0.9, 1.0);
uniform vec4 color_variacion : source_color = vec4(1.08, 1.04, 0.78, 1.0);   // hacia dónde varían algunos grupos
uniform float variacion : hint_range(0.0, 1.0) = 0.0;
uniform float base_y = 0.0;          // altura (en la malla) donde empieza la planta
uniform float alto = 1.0;            // altura de la planta en la malla
uniform vec3 centro = vec3(0.0, 1.0, 0.0);   // centro de la copa (en la malla)
uniform float radio = 1.0;           // radio de la copa (en la malla)
uniform float oclusion : hint_range(0.0, 1.0) = 0.0;
uniform float normal_esfera : hint_range(0.0, 1.0) = 0.0;
uniform float saturacion : hint_range(0.0, 1.5) = 1.0;
uniform float viento = 0.05;
uniform float viento_vel = 1.2;
uniform float corte : hint_range(0.0, 1.0) = 0.5;
uniform vec3 contraluz : source_color = vec3(0.25, 0.28, 0.1);
uniform float relleno : hint_range(0.0, 1.0) = 0.12;
// Experimento de sombras (Fase 2): sombra precalculada del suelo (mapa en planta). Blanco = sin efecto.
uniform sampler2D sombra_mapa : source_color, hint_default_white, filter_linear_mipmap, repeat_disable;
uniform vec3 sombra_rect = vec3(0.0, 0.0, 1.0);   // x0, z0 del mapa y 1/lado (m)

varying float v_h;
varying float v_oc;
varying float v_var;
varying vec2 v_suelo;

void vertex() {
	float h = clamp((VERTEX.y - base_y) / max(alto, 0.01), 0.0, 1.0);
	v_h = h;
	vec3 q = VERTEX - centro;
	v_oc = mix(1.0 - oclusion, 1.0, smoothstep(0.2, 0.95, length(q) / max(radio, 0.01)));
	v_var = clamp(0.5 + 0.5 * sin(VERTEX.x * 1.7 + VERTEX.y * 2.3) * sin(VERTEX.z * 1.9 - VERTEX.y * 1.1 + 0.7), 0.0, 1.0);
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float fase = TIME * viento_vel + w.x * 0.31 + w.z * 0.23;
	float temblor = sin(TIME * viento_vel * 2.9 + VERTEX.x * 2.7 + VERTEX.z * 2.1 + VERTEX.y * 1.3);
	float s = h * h;
	VERTEX.x += (sin(fase) * 0.7 + temblor * 0.3) * viento * s;
	VERTEX.z += (sin(fase * 0.83 + 1.7) * 0.45 + temblor * 0.2) * viento * s;
	v_suelo = ((MODEL_MATRIX * vec4(VERTEX, 1.0)).xz - sombra_rect.xy) * sombra_rect.z;
	if (normal_esfera > 0.0) {
		NORMAL = normalize(mix(NORMAL, normalize(q), normal_esfera));
	}
}

void fragment() {
	vec4 t = texture(albedo_tex, UV);
	vec3 degradado = mix(color_bajo.rgb, color_alto.rgb, smoothstep(0.0, 1.0, v_h));
	vec3 c = t.rgb * tinte.rgb * degradado * v_oc;
	c *= mix(vec3(1.0), color_variacion.rgb, smoothstep(0.55, 0.95, v_var) * variacion);
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = max(mix(vec3(luma), c, saturacion), vec3(0.0)) * texture(sombra_mapa, v_suelo).rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = corte;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
	BACKLIGHT = contraluz * v_oc;
	EMISSION = ALBEDO * relleno;
	if (normal_esfera > 0.0 && !FRONT_FACING) {
		NORMAL = -NORMAL;               // la cara de atrás conserva la normal de esfera
	}
}
