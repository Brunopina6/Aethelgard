// Muestra gráfica de una calle de Oakhaven (en pruebas): lo que da luz (los cristales de los faroles, las ventanas con
// luz dentro, las velas de la hornacina). Sin sombreado: el color del vértice es la luz, con un temblor suave de llama.
shader_type spatial;
render_mode unshaded, cull_back;

uniform float energia = 1.5;
uniform float temblor = 0.10;
// (15/11, revisión) en la malla «piezas» el horneado dejó el color de los cristales a 0 (faroles de pie negros): allí
// se usa este color fijo, el LUZ_FAROL de fuente/crear_calle.py.
uniform bool usar_color_fijo = false;
uniform vec3 color_fijo = vec3(1.0, 0.72, 0.36);

void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float f = 1.0 + temblor * (sin(TIME * 7.1 + w.x * 3.0) * 0.6 + sin(TIME * 12.3 + w.z * 5.0) * 0.4);
	ALBEDO = (usar_color_fijo ? color_fijo : COLOR.rgb) * energia * f;
}
