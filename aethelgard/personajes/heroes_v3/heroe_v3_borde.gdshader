// Héroes v3 (V12): contorno (casco invertido) del cuerpo, como siguiente pasada del material. El grosor se mide en
// pantalla (constante con la distancia, acotado de cerca) y el color es el del vértice muy oscurecido y algo violáceo,
// como una línea de tinta del mismo tono. Sin luz.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, blend_mix, shadows_disabled;

uniform float grosor = 0.0013;               // fracción de la distancia a la cámara
uniform float grosor_max = 0.004;            // en metros (primeros planos)
uniform vec3 tinta : source_color = vec3(0.10, 0.07, 0.13);
uniform float del_color = 0.55;              // cuánto del color del vértice se conserva en la línea

void vertex() {
	vec4 vp = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 vn = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float d = max(-vp.z, 0.1);
	vp.xyz += vn * min(grosor * d, grosor_max);
	POSITION = PROJECTION_MATRIX * vp;
}

void fragment() {
	vec3 c = mix(COLOR.rgb / 12.92, pow((COLOR.rgb + 0.055) / 1.055, vec3(2.4)), step(0.04045, COLOR.rgb));
	ALBEDO = mix(tinta, c * 0.30, del_color);
}
