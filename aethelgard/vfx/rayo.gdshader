shader_type spatial;
// Rayo que cae del cielo: brilla con emisión cian/blanca eléctrica (con bloom en la ventana 3D).
// Del mosaico de Meshy solo se ve lo blanco (el rayo) y lo azul (las chispas); el gris del disco
// del suelo se vuelve transparente. Un parpadeo rápido hace que la luz vibre.
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled, specular_disabled;

uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform vec4 color_borde : source_color = vec4(0.35, 0.85, 1.0, 1.0);    // cian eléctrico
uniform vec4 color_nucleo : source_color = vec4(0.92, 0.98, 1.0, 1.0);   // casi blanco
uniform float brillo = 4.0;             // fuerza de la emisión (y del bloom)
uniform float alfa = 1.0;               // 1 = visible, 0 = desaparecido (lo anima el script)

void fragment() {
	vec4 t = texture(textura, UV);
	float mx = max(t.r, max(t.g, t.b));
	float mn = min(t.r, min(t.g, t.b));
	float color_azul = (mx - mn) * step(t.r, t.b);               // lo azul de las chispas
	float blanco = smoothstep(0.78, 0.97, mx) * (1.0 - smoothstep(0.1, 0.35, mx - mn));
	float parpadeo = 0.8 + 0.2 * sin(TIME * 90.0) * sin(TIME * 37.0);
	vec3 c = mix(color_borde.rgb, color_nucleo.rgb, blanco);
	ALBEDO = vec3(0.0);
	EMISSION = c * brillo * parpadeo;
	ALPHA = clamp(max(blanco, color_azul * 1.6), 0.0, 1.0) * alfa;
}
