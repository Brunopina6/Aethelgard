// Vidrio del Mar de Cristal (V12): incrustaciones de las ruinas, la estrella de la trampilla y los cristales que brotan
// de la arena vitrificada. Spatial; Compatibility. Opaco (barato): color de vértice algo apagado, brillo especular del
// sol, borde encendido según se mire (fresnel) y un resplandor interior que late despacio, cada pieza a su ritmo.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec3 color_borde : source_color = vec3(0.86, 1.0, 1.0);
uniform float brillo_interno : hint_range(0.0, 2.0) = 0.35;
uniform float pulso : hint_range(0.0, 1.0) = 0.25;
uniform float fuerza_borde : hint_range(0.0, 2.0) = 0.7;

void vertex() {
	COLOR.rgb = pow(COLOR.rgb, vec3(2.2));    // los colores de vértice van en sRGB (fuente/crear_desierto.py)
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float p = 1.0 + pulso * sin(TIME * 1.3 + dot(NODE_POSITION_WORLD, vec3(0.7, 0.3, 0.5)));
	ALBEDO = COLOR.rgb * 0.5;
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	EMISSION = COLOR.rgb * brillo_interno * p + color_borde * fres * fuerza_borde;
}
