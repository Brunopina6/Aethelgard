// Agua del oasis del Mar de Cristal (V12, 12/11, gráficos). Antes era un disco turquesa liso y transparente; ahora
// opaco (más barato en el Mali que mezclar): hondo y oscuro en el centro, turquesa en la orilla, ondas que mueven la
// normal (la luz del sol las dibuja), el cielo reflejado al mirar de lado y una línea de espuma que late en la orilla.
// Spatial; Compatibility. Una llamada. Sin texturas de imagen: el ruido de materiales_arte.gd.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec3 color_hondo : source_color = vec3(0.06, 0.30, 0.36);
uniform vec3 color_orilla : source_color = vec3(0.30, 0.68, 0.62);
uniform vec3 color_espuma : source_color = vec3(0.90, 0.94, 0.86);
uniform vec3 color_cielo : source_color = vec3(0.66, 0.80, 0.92);
uniform vec2 centro = vec2(74.0, 72.0);
uniform float radio = 5.2;
uniform float borde_espuma : hint_range(0.5, 1.0) = 0.9;
uniform sampler2D ruido : hint_default_white, filter_linear_mipmap, repeat_enable;

varying vec3 v_mundo;

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_mundo.xz;
	float d = length(p - centro) / radio;                       // 0 en el centro, 1 en el borde del disco
	float n = texture(ruido, p * 0.08 + vec2(TIME * 0.010, TIME * 0.007)).r;
	float n2 = texture(ruido, p * 0.21 - vec2(TIME * 0.016, 0.0)).r;
	vec3 c = mix(color_hondo, color_orilla, smoothstep(0.3, 0.95, d + (n - 0.5) * 0.18));
	vec3 nw = normalize(vec3((n - 0.5) * 0.3 + (n2 - 0.5) * 0.22, 1.0, (n2 - 0.5) * 0.3 - (n - 0.5) * 0.1));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	c = mix(c, color_cielo, clamp(fres * 0.7, 0.0, 0.6));
	float espuma = smoothstep(borde_espuma - 0.06, borde_espuma + 0.04, d + (n2 - 0.5) * 0.1);
	espuma *= 0.55 + 0.45 * sin(TIME * 1.4 + n * 14.0);
	c = mix(c, color_espuma, clamp(espuma, 0.0, 1.0) * 0.65);
	ALBEDO = c;
	ROUGHNESS = 0.14;
	SPECULAR = 0.55;
}
