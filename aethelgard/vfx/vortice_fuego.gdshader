shader_type spatial;
// Vórtice de fuego: las llamas suben por la malla (UV.y -= TIME * velocidad) y brillan (EMISSION).
// La textura de Meshy es un mosaico de trozos, así que se usa quieta para el color y la forma,
// y lo que se desplaza hacia arriba es una textura de flujo de llamas (ruido) que la recorre.
// Mezcla normal con transparencia: conserva el color naranja también sobre fondos claros.
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled, specular_disabled;

uniform sampler2D textura : source_color, filter_linear_mipmap;              // color de Meshy
uniform sampler2D flujo : repeat_enable, filter_linear_mipmap;               // llamas que suben
uniform float velocidad = 1.4;          // lo rápido que suben las llamas
uniform float escala_flujo = 2.5;       // cuántas veces se repite el flujo
uniform vec4 color_fuego : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform vec4 color_nucleo : source_color = vec4(1.0, 0.7, 0.25, 1.0);
uniform float brillo = 2.0;             // fuerza de la emisión (más alto = más blanco)
uniform float alfa = 1.0;               // 1 = visible, 0 = desaparecido (lo anima el script)

void fragment() {
	vec4 base = texture(textura, UV);
	vec2 uv = UV * escala_flujo;
	uv.y -= TIME * velocidad;                                   // desplaza las llamas hacia arriba
	float f1 = texture(flujo, uv).r;
	float f2 = texture(flujo, uv * 1.7 + vec2(0.37, -TIME * velocidad * 0.6)).r;
	float llama = smoothstep(0.35, 0.85, f1 * 0.65 + f2 * 0.45);
	float lum = max(base.r, max(base.g, base.b));
	vec3 c = mix(base.rgb * color_fuego.rgb, color_nucleo.rgb, llama * 0.7);
	ALBEDO = vec3(0.0);
	EMISSION = c * brillo * (0.45 + llama * 0.9);
	ALPHA = clamp(lum * (0.6 + llama * 0.6), 0.0, 1.0) * alfa;
}
