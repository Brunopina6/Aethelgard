// Muestra gráfica de una calle de Oakhaven (en pruebas): lo que da luz (los cristales de los faroles, las ventanas con
// luz dentro, las velas de la hornacina). Sin sombreado: el color del vértice es la luz, con un temblor suave de llama.
shader_type spatial;
render_mode unshaded, cull_back;

uniform float energia = 1.5;
uniform float temblor = 0.10;

void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float f = 1.0 + temblor * (sin(TIME * 7.1 + w.x * 3.0) * 0.6 + sin(TIME * 12.3 + w.z * 5.0) * 0.4);
	ALBEDO = COLOR.rgb * energia * f;
}
