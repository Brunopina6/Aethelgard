// Vegetación del oasis (V12): palmas y juncos que se mecen. Spatial; Compatibility. Doble cara.
// El alfa del color de vértice es cuánto se dobla cada punto (0 en el arranque de la hoja, 1 en la punta); se dobla en la
// dirección del viento con un vaivén lento propio de cada planta (fase por su posición) y un temblor rápido de las hojas.
// «viento» va de 0 (calma) a 1 (tormenta).
// Con #define ESPEJISMO es el espejismo (la palmera que tiembla y no está): toda la pieza ondula de lado a lado, se
// deshace en franjas y se transparenta; «espejismo» va de 1 (se ve) a 0 (ha desaparecido).
shader_type spatial;
#ifdef ESPEJISMO
render_mode cull_disabled, diffuse_lambert, specular_disabled, blend_mix, depth_draw_never;
#else
render_mode cull_disabled, diffuse_lambert, specular_disabled;
#endif

uniform float viento : hint_range(0.0, 1.0) = 0.25;
uniform vec2 dir_viento = vec2(1.0, -0.25);
uniform float doblez = 0.45;            // metros que se dobla la punta con viento 1
uniform float temblor = 0.035;          // aleteo de las hojas
uniform float rapidez = 1.2;
uniform float traslucidez : hint_range(0.0, 1.0) = 0.3;   // las hojas al contraluz se encienden un poco
#ifdef ESPEJISMO
uniform float espejismo : hint_range(0.0, 1.0) = 1.0;
uniform vec3 tinte_espejismo : source_color = vec3(0.95, 0.88, 0.75);
#endif

varying float v_peso;

void vertex() {
#ifdef ESPEJISMO
	float w = 1.0;
#else
	float w = COLOR.a;
#endif
	mat3 m = mat3(MODEL_MATRIX);
	COLOR.rgb = pow(COLOR.rgb, vec3(2.2));    // los colores de vértice van en sRGB (fuente/crear_desierto.py)
	vec3 pw = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 d = normalize(dir_viento);
	float semilla = dot(NODE_POSITION_WORLD.xz, vec2(0.71, 0.29));
	float t = TIME * rapidez;
	float vaiven = sin(t + semilla) * 0.5 + sin(t * 0.63 + semilla * 1.7) * 0.35 + sin(t * 2.1 + semilla) * 0.15;
	float empuje = viento * (0.65 + 0.35 * vaiven) + 0.22 * vaiven * (0.35 + viento);
	float aleteo = sin(t * 5.0 * (0.6 + viento) + dot(pw, vec3(3.1, 2.3, 2.7))) * temblor * (0.3 + viento * 1.6);
	vec3 off = vec3(d.x, 0.0, d.y) * empuje * doblez * w * w;
	off.y -= abs(empuje) * doblez * 0.3 * w * w;
	off.y += aleteo * w;
#ifdef ESPEJISMO
	off = vec3(sin(pw.y * 5.0 - TIME * 4.0) * 0.12 + sin(pw.y * 13.0 + TIME * 7.0) * 0.04, 0.0, 0.0) * (0.6 + 0.4 * (1.0 - espejismo));
#endif
	VERTEX += transpose(m) * off / dot(m[0], m[0]);
	v_peso = w;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.9;
	SPECULAR = 0.1;
	EMISSION = COLOR.rgb * traslucidez * 0.15 * v_peso;
#ifdef ESPEJISMO
	float franjas = 0.55 + 0.45 * sin(SCREEN_UV.y * 120.0 + TIME * 9.0);
	ALBEDO = mix(COLOR.rgb, tinte_espejismo, 0.35);
	ALPHA = clamp(espejismo * franjas * 0.85, 0.0, 1.0);
#endif
}
