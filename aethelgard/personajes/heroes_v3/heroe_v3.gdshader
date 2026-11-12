// Héroes v3 (V12): material del cuerpo. El color (en sRGB), la oclusión y el TIPO de material vienen en el color por
// vértice del GLB (crear_heroes_v3.py; alfa = tipo / 7) y el detalle (trama, hebras, grano y pliegues) de una
// textura pequeña común a los tres (heroe_v3_detalle.png), con las UV de la geometría en metros. La luz es la de
// heroe_v3_luz.gdshaderinc. El reflejo del entorno en el metal toma cielo, suelo y energía del ambiente de la región,
// como los v2 (heroe_v2_ayudante.gd los escribe aquí con los mismos nombres).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://personajes/heroes_v3/heroe_v3_luz.gdshaderinc"

uniform sampler2D detalle : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float fuerza_detalle = 1.0;
uniform vec4 color : source_color = vec4(1.0);
uniform float reflejo = 0.55;
uniform vec3 cielo : source_color = vec3(0.78, 0.84, 0.95);
uniform vec3 suelo : source_color = vec3(0.30, 0.26, 0.22);
uniform float energia_entorno = 1.0;
uniform float brillo_cristal = 0.35;
uniform vec3 destello = vec3(0.0);           // para golpes o magia (lo suma el juego si quiere)

vec3 a_lineal(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

void vertex() {
	v_tipo = floor(COLOR.a * 7.0 + 0.5);
}

void fragment() {
	vec3 a = a_lineal(COLOR.rgb) * color.rgb;
	float t = v_tipo;
	// detalle por tipo (cada tipo, su escala: las UV van en metros)
	float k = 1.0;
	v_hebra = 0.5;
	if (t < 0.5) {                                 // tela: trama y pliegues largos
		vec4 d = texture(detalle, UV * vec2(4.0, 2.2));
		vec4 d2 = texture(detalle, UV * 9.0);
		k = (1.0 + (d.a - 0.5) * 0.16) * (1.0 + (d2.r - 0.5) * 0.12);
	} else if (t > 4.5 && t < 5.5) {               // pelo: hebras a lo largo del mechón
		vec4 d = texture(detalle, UV * vec2(16.0, 1.5));
		v_hebra = d.g;
		k = 0.72 + d.g * 0.56;
	} else if (t > 1.5 && t < 2.5) {               // cuero
		k = 1.0 + (texture(detalle, UV * 7.0).b - 0.5) * 0.30;
	} else if (t > 2.5 && t < 3.5) {               // metal
		k = 1.0 + (texture(detalle, UV * 5.0).b - 0.5) * 0.25;
	} else if (t > 0.5 && t < 1.5) {               // piel: casi nada
		k = 1.0 + (texture(detalle, UV * 6.0).b - 0.5) * 0.04;
	}
	a *= mix(1.0, k, fuerza_detalle);
	ALBEDO = a;
	float metal = (t > 2.5 && t < 3.5) ? 1.0 : 0.0;
	ROUGHNESS = metal > 0.5 ? 0.35 : 0.8;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 rf = reflect(-v, n);
	vec3 entorno = mix(suelo, cielo, smoothstep(-0.35, 0.55, rf.y));
	EMISSION = entorno * a * metal * reflejo * 0.5 * energia_entorno + destello;
	if (t > 3.5 && t < 4.5) {
		EMISSION += a * brillo_cristal;          // los cristales tienen algo de luz propia
	}
}
