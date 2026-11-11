// Mancha de sombra bajo un personaje (V12, 12/11, gráficos): solo en el perfil sin sombras del Mar de Cristal
// (zonas3d/mar_cristal/sombras_bajo.gd). Un tinte frío y oscuro, con el borde muy suave (por alfa: con «blend_mul» el
// blanco del borde pasaba por el mapeo de tonos y el cuadro se veía). Spatial, sin luz ni niebla; Compatibility.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 tinte : source_color = vec3(0.22, 0.18, 0.26);
uniform float fuerza : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float k = 1.0 - smoothstep(0.1, 1.0, length(d));
	ALBEDO = tinte;
	ALPHA = k * k * fuerza;
}
