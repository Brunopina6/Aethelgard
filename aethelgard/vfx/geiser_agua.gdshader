shader_type spatial;
// Géiser de agua: transparente, con brillo de agua (rugosidad baja), y un ruido que sube por la UV
// (UV.y -= TIME * velocidad) para que parezca un torrente fluyendo hacia arriba.
// Refracción: el combate es 2D y detrás del géiser no hay nada en 3D que refractar, así que se
// imita deformando la textura con el ruido (como hace el agua al mirar a través de ella).
// La textura de Meshy es un mosaico de trozos: se usa casi quieta para el color y la forma.
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D textura : source_color, filter_linear_mipmap;              // color de Meshy
uniform sampler2D ruido : repeat_enable, filter_linear_mipmap;               // flujo del agua
uniform float velocidad = 1.6;          // lo rápido que sube el agua
uniform float escala_ruido = 2.2;
uniform float distorsion = 0.025;       // refracción imitada: cuánto se deforma la textura
uniform vec4 color_agua : source_color = vec4(0.25, 0.62, 1.0, 1.0);
uniform vec4 color_espuma : source_color = vec4(0.92, 0.97, 1.0, 1.0);
uniform float transparencia = 0.62;     // 1 = opaca
uniform float rugosidad = 0.06;         // baja = brillos de agua nítidos
uniform float alfa = 1.0;               // 1 = visible, 0 = desaparecido (lo anima el script)

void fragment() {
	vec2 uv = UV * escala_ruido;
	uv.y -= TIME * velocidad;                                   // el agua sube
	float n1 = texture(ruido, uv).r;
	float n2 = texture(ruido, uv * 1.9 + vec2(0.31, -TIME * velocidad * 0.5)).r;
	vec2 deforma = (vec2(n1, n2) - 0.5) * distorsion;
	vec4 base = texture(textura, UV + deforma);
	float espuma = smoothstep(0.62, 0.86, n1 * 0.6 + n2 * 0.5);
	float borde = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);   // los bordes brillan más
	vec3 c = mix(base.rgb * color_agua.rgb * 1.35, color_espuma.rgb, clamp(espuma * 0.6 + borde * 0.35, 0.0, 1.0));
	ALBEDO = c;
	ROUGHNESS = rugosidad;
	METALLIC = 0.0;
	SPECULAR = 0.8;
	EMISSION = c * 0.35;                                         // se ve bien aunque haya poca luz
	float lum = max(base.r, max(base.g, base.b));
	ALPHA = clamp((transparencia + borde * 0.3 + espuma * 0.3) * smoothstep(0.05, 0.25, lum), 0.0, 1.0) * alfa;
}
