shader_type spatial;
// CIUDAD DE OAKHAVEN (V12, 16/11, M0; EXPERIMENTAL): las piezas OCULTABLES de un sector montado en UNA malla («Aclarados»,
// sector.gd), medio transparentes (alfa 0,28: lo mismo que la copia transparente del material del blockout de antes,
// blockout.gd, material(true)). Solo se dibujan las aclaradas («aclarado[i - 1]», i = UV2.x); las demás van a un punto
// (triángulos sin área). La malla entera se oculta mientras no hay nada aclarado: sin coste.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float aclarado[64];

void vertex() {
	int i = int(UV2.x + 0.5);
	if (i <= 0 || aclarado[i - 1] < 0.5) {
		VERTEX = vec3(0.0);
	}
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = 0.28 * COLOR.a;
	METALLIC = 0.0;
	SPECULAR = 0.5;
	ROUGHNESS = 1.0;
}
