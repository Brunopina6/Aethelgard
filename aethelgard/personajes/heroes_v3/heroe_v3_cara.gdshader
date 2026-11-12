// Héroes v3 (V12): la cara (ojos, boca, cejas y marca) sobre la cabeza nueva, con el atlas propio de cara_v3.py.
// El color por vértice dice qué es cada parte: R = ojo (va a la loseta «ojos»), G = boca (loseta «boca»), B = fijo.
// Las cejas se dibujan algo por delante (sesgo hacia la cámara) para que se lean sobre las puntas del flequillo,
// como en el dibujo de anime; el sesgo es pequeño y no las saca a través de la cabeza.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://personajes/heroes_v3/heroe_v3_luz.gdshaderinc"

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform int ojos = 0;
uniform int boca = 0;
uniform float sesgo_cejas = 0.035;
uniform float brillo_ojos = 0.18;          // luz propia de los ojos (Garon: los brillos de la visera)

void vertex() {
	v_tipo = 1.0;                                     // se ilumina como la piel
	v_hebra = 0.5;
	// (si se escribe POSITION hay que escribirlo en TODOS los vértices: Godot deja de proyectar por su cuenta)
	bool ceja = COLOR.b > 0.5 && UV.x > 0.126 && UV.y > 0.834;
	vec4 vp = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	if (ceja) {
		vp.xyz += normalize(-vp.xyz) * sesgo_cejas;
	}
	POSITION = PROJECTION_MATRIX * vp;
}

void fragment() {
	vec2 uv = UV;
	if (COLOR.r > 0.5) {
		uv += vec2(float(ojos % 4) * 0.25, float(ojos / 4) * (256.0 / 768.0));
	} else if (COLOR.g > 0.5) {
		uv.x += float(boca) * 0.125;
	}
	vec4 c = texture(atlas, uv);
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ROUGHNESS = 0.8;
	SPECULAR = 0.0;
	// los ojos: brillo propio suave para que el blanco no se ensucie en la sombra
	EMISSION = COLOR.r > 0.5 ? c.rgb * brillo_ojos : vec3(0.0);
}
