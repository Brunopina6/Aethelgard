shader_type spatial;
// Magia de curación: brilla con luz propia (emisión) teñida de verde o dorado, y se puede
// desvanecer con transparencia. Las zonas oscuras del mosaico de Meshy quedan transparentes.
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled, specular_disabled;

uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform vec4 tinte : source_color = vec4(1.0, 0.85, 0.35, 1.0);   // dorado (círculo) o verde (espiral)
uniform float mezcla_tinte = 0.5;       // 0 = colores de la textura, 1 = todo del color del tinte
uniform float brillo = 1.6;
uniform float alfa = 1.0;               // 1 = visible, 0 = desaparecido (lo anima el script)

void fragment() {
	vec4 t = texture(textura, UV);
	float lum = max(t.r, max(t.g, t.b));
	vec3 c = mix(t.rgb, tinte.rgb * (0.5 + lum * 0.8), mezcla_tinte);
	float pulso = 0.9 + 0.1 * sin(TIME * 4.0 + UV.y * 12.0);         // un latido suave de luz
	ALBEDO = vec3(0.0);
	EMISSION = c * brillo * pulso;
	ALPHA = smoothstep(0.08, 0.3, lum) * alfa;
}
