shader_type spatial;
// Vidracrán (V12, prototipo): vidrio ámbar esmerilado, opaco (sin transparencias: nada de sobredibujado en el Mali).
// El borde se enciende (fresnel) y el interior deja ver un poco de luz atrapada; el brillo especular es de vidrio.
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform vec3 borde : source_color = vec3(1.0, 0.92, 0.72);
uniform float fuerza_borde = 0.75;
uniform float luz_interior = 0.12;
uniform float apagar = 1.0;   // 1 vivo; 0 en la derrota (sin luz propia)

void fragment() {
	vec3 c = texture(atlas, UV).rgb;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = c * 0.8;
	ROUGHNESS = 0.16;
	SPECULAR = 0.9;
	EMISSION = (borde * fr * fuerza_borde + c * luz_interior) * apagar;
}
