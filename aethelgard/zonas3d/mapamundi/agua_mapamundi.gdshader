// V12, mapamundi 3D (15/11/2026): el mar de la maqueta. Opaco (sin copiar la pantalla: barato en el Mali-G57) y sin
// texturas: el color del vértice (R) dice lo cerca que está la costa (1 en la orilla, 0 en alta mar). Pinta el bajío
// turquesa claro, el azul hondo, olas que llegan a la orilla en bandas paralelas a la costa, la espuma del borde y un
// rizo suave que brilla con el sol.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 hondo : source_color = vec4(0.04, 0.17, 0.38, 1.0);
uniform vec4 medio : source_color = vec4(0.07, 0.35, 0.56, 1.0);
uniform vec4 bajio : source_color = vec4(0.22, 0.66, 0.70, 1.0);
uniform vec4 espuma : source_color = vec4(0.96, 0.98, 1.0, 1.0);
uniform float velocidad = 0.55;
uniform float olas_altura = 0.05;

varying float somero;
varying vec3 pos_mundo;

void vertex() {
	somero = COLOR.r;
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float o = sin(pos_mundo.x * 0.33 + TIME * 1.1) * cos(pos_mundo.z * 0.29 - TIME * 0.8);
	VERTEX.y += o * olas_altura * (1.0 - somero * 0.7);
}

void fragment() {
	float s = somero;
	vec3 c = mix(hondo.rgb, medio.rgb, smoothstep(0.0, 0.55, s));
	c = mix(c, bajio.rgb, smoothstep(0.62, 0.97, s));
	// olas que llegan: bandas que avanzan hacia la orilla, rotas por un poco de ondulación
	float onda = sin(s * 34.0 - TIME * velocidad * 3.2 + sin(pos_mundo.x * 0.45 + pos_mundo.z * 0.2) * 1.3);
	float esp = smoothstep(0.88, 0.98, onda) * smoothstep(0.80, 0.95, s) * 0.6;
	esp += smoothstep(0.968, 0.996, s);                         // la orilla
	// rizo: dos ondas cruzadas que cambian el brillo y la normal
	float r1 = sin(pos_mundo.x * 1.7 + TIME * 1.5) * sin(pos_mundo.z * 1.3 - TIME * 1.1);
	float r2 = sin((pos_mundo.x + pos_mundo.z) * 0.9 - TIME * 0.7);
	c *= 1.0 + 0.05 * r1 + 0.03 * r2;
	ALBEDO = mix(c, espuma.rgb, clamp(esp, 0.0, 1.0) * 0.85);
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(r1 * 0.06, 0.0, r2 * 0.06, 0.0)).xyz);
	ROUGHNESS = 0.16;
	SPECULAR = 0.45;
	METALLIC = 0.0;
}
