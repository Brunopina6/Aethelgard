// Surcos viejos de Bramavidrio en «la arena que tiembla» (V12, 12/11, gráficos; zonas3d/mar_cristal/paisaje.gd): cintas
// que siguen la arena, con el fondo hundido algo más oscuro y los dos bordes levantados algo más claros. Avisan de lejos
// de que ahí abajo se mueve algo. Spatial, sin luz y transparente; Compatibility. Todas en una malla: una llamada.
// UV.y va de 0 a 1 a lo ancho; el alfa del color de vértice apaga los extremos.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 color_fondo : source_color = vec3(0.50, 0.36, 0.26);
uniform vec3 color_borde : source_color = vec3(0.98, 0.88, 0.70);
uniform float fuerza : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	float v = abs(UV.y * 2.0 - 1.0);                          // 0 en el centro, 1 en los bordes
	float fondo = 1.0 - smoothstep(0.0, 0.55, v);
	float borde = smoothstep(0.55, 0.78, v) * (1.0 - smoothstep(0.82, 1.0, v));
	ALBEDO = mix(color_borde, color_fondo, fondo / max(fondo + borde, 0.001));
	ALPHA = (fondo * 0.6 + borde * 0.45) * COLOR.a * fuerza;
}
