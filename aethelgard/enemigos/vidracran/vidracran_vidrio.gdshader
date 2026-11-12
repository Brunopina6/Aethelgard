shader_type spatial;
// Vidracrán (V12, prototipo): vidrio ámbar esmerilado, opaco (sin transparencias: nada de sobredibujado en el Mali).
// El borde se enciende (fresnel) y el interior deja ver un poco de luz atrapada; el brillo especular es de vidrio.
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D atlas : source_color, filter_linear_mipmap;
// V12, encuentro del desierto (12/11): en el combate no hay suelo que lo tape; lo que queda por debajo de esta altura
// del mundo no se dibuja (el cuerpo enterrado). Por defecto, muy abajo: no recorta nada.
uniform float suelo_y = -1000.0;
varying float alto_mundo;

void vertex() {
	alto_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}
uniform vec3 borde : source_color = vec3(1.0, 0.92, 0.72);
uniform float fuerza_borde = 0.75;
uniform float luz_interior = 0.12;
uniform float apagar = 1.0;   // 1 vivo; 0 en la derrota (sin luz propia)

void fragment() {
	if (alto_mundo < suelo_y) {
		discard;
	}
	vec3 c = texture(atlas, UV).rgb;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	// V12, encuentro del desierto: el montón de arena del agujero (la muestra «arena» del atlas, columna 7 de la fila de
	// arriba) es arena mate, no vidrio: sin brillo ni borde encendido (en el combate se leía como un charco helado).
	float arena = step(0.75, UV.x) * step(UV.x, 0.875) * max(step(UV.y, 0.125), step(0.875, UV.y));
	ALBEDO = c * mix(0.8, 1.0, arena);
	ROUGHNESS = mix(0.16, 0.95, arena);
	SPECULAR = mix(0.9, 0.1, arena);
	EMISSION = (borde * fr * fuerza_borde + c * luz_interior) * apagar * (1.0 - arena);
}
