shader_type spatial;
// CIUDAD DE OAKHAVEN (V12, 16/11, M0; EXPERIMENTAL): el blockout de un sector montado en UNA malla, ocultables incluidos
// (sector.gd). Es el material del blockout (blockout.gd, material(): color en los vértices, rugosidad 1; lo mismo que el
// StandardMaterial3D de antes, escrito a mano) más el ACLARADO POR PIEZA: cada vértice de una pieza ocultable lleva su
// índice en UV2.x (1, 2…; 0 = lo que nunca se aclara) y «aclarado[i - 1]» dice si esa pieza está aclarada. Lo aclarado se
// quita de esta malla (sus vértices van a un punto: triángulos sin área, ni se dibujan ni dan sombra, como antes el
// material transparente) y se dibuja en la malla «Aclarados» con blockout_claro.gdshader.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float aclarado[64];

void vertex() {
	int i = int(UV2.x + 0.5);
	if (i > 0 && aclarado[i - 1] > 0.5) {
		VERTEX = vec3(0.0);
	}
}

void fragment() {
	ALBEDO = COLOR.rgb;
	METALLIC = 0.0;
	SPECULAR = 0.5;
	ROUGHNESS = 1.0;
}
