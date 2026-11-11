// Tela al viento del Mar de Cristal (V12): tiendas, banderines, la lona del carro. Spatial; Compatibility.
// Se mueve en los vértices: ondas que corren en la dirección del viento, con la fase de cada pieza (su posición) para que
// no se muevan todas a la vez. El alfa del color de vértice dice cuánto se mueve cada punto (0 = atado al poste o a la
// estaca, 1 = borde libre); lo pone el guion de Blender (fuente/crear_desierto.py). Doble cara.
// «viento» va de 0 (calma: un vaivén suave) a 1 (tormenta: la tela golpea). La sombra de los pliegues sigue a la onda.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform float viento : hint_range(0.0, 1.0) = 0.25;
uniform vec2 dir_viento = vec2(1.0, -0.25);
uniform float amplitud = 0.09;          // metros de vaivén (se multiplica: calma ×0,3, tormenta ×2)
uniform float rapidez = 2.2;
uniform float sombra_pliegue : hint_range(0.0, 0.6) = 0.2;
uniform float luz_tela : hint_range(0.0, 1.0) = 0.25;   // la luz que pasa a través (la cara de atrás no se apaga)

varying float v_ola;
varying float v_peso;

void vertex() {
	float w = COLOR.a;
	COLOR.rgb = pow(COLOR.rgb, vec3(2.2));    // los colores de vértice van en sRGB (fuente/crear_desierto.py)
	mat3 m = mat3(MODEL_MATRIX);
	vec3 pw = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 d = normalize(dir_viento);
	float semilla = dot(NODE_POSITION_WORLD.xz, vec2(0.37, 0.61));
	float t = TIME * rapidez * (0.55 + viento * 1.3);
	float f = dot(pw.xz, d) * 2.1 + pw.y * 1.3 - t + semilla;
	float ola = sin(f) * 0.6 + sin(f * 2.3 + pw.x * 1.7 - t * 0.7) * 0.28 + sin(t * 0.37 + semilla) * 0.22;
	float a = amplitud * (0.3 + viento * 1.7) * w;
	vec3 nw = normalize(m * NORMAL);
	vec3 off = nw * ola * a + vec3(d.x, 0.0, d.y) * (0.6 + 0.4 * ola) * a * viento;
	VERTEX += transpose(m) * off / dot(m[0], m[0]);
	v_ola = ola;
	v_peso = w;
}

void fragment() {
	ALBEDO = COLOR.rgb * (1.0 - sombra_pliegue * v_ola * min(1.0, v_peso * 2.0));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;            // mate: sin reflejo del cielo
	EMISSION = COLOR.rgb * luz_tela * 0.12;
}
