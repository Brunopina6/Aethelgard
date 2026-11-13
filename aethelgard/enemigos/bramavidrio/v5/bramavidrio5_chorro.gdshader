// v5 (12/11): copia literal de enemigos/bramavidrio/v4/bramavidrio4_chorro.gdshader (la v4 no se toca), para que la v5 sea independiente.
// El Aliento de Bramavidrio v4 (V12, 12/11; copia del de la v3): el chorro que NACE EN LA GARGANTA (el anclaje) y sale
// por la boca en «ataque_aliento»; lo de fuera, hacia los héroes, lo dibuja combate_bramavidrio.gd desde el mismo anclaje. Spatial; Compatibility.
// Sin sombreado y aditivo: no tapa nada ni proyecta sombra. El alfa del color de vértice es su fuerza a lo largo (1 en la
// boca, 0 al final) y «fuerza» sigue a la escala del hueso «chorro» (0,01: escondido; 1: entero). La capa de fuera es
// arena dorada; la de dentro, la luz ámbar de la garganta.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.86, 0.6);
uniform float fuerza : hint_range(0.0, 1.5) = 0.0;

void fragment() {
	// Escondido, no se dibuja: en la ventana 3D del combate (fondo transparente) un aditivo negro escribe alfa y se veía
	// un cono NEGRO en el Aliento (11/11, fotos_bramavidrio_combate: también le pasa a la v1).
	if (fuerza < 0.01) {
		discard;
	}
	float flujo = 0.55 + 0.45 * sin(UV.y * 34.0 - TIME * 38.0 + UV.x * 12.566);
	float grano = 0.7 + 0.3 * sin(UV.y * 91.0 - TIME * 61.0 + UV.x * 31.4);
	float borde = pow(abs(dot(NORMAL, VIEW)), 1.4);
	ALBEDO = color * COLOR.rgb * COLOR.a * flujo * grano * borde * fuerza * 1.6;
}
