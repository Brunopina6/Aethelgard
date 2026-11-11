// El aliento de Bramavidrio (V12): el chorro de polvo de vidrio que escupe en «ataque_aliento». Spatial; Compatibility.
// Sin sombreado y aditivo: no tapa nada ni proyecta sombra. El alfa del color de vértice es su fuerza a lo largo (1 en
// la boca, 0 al final) y «fuerza» sigue a la escala del hueso «chorro» (0,01: escondido; 1: entero).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 color : source_color = vec3(0.55, 0.95, 1.0);
uniform float fuerza : hint_range(0.0, 1.5) = 0.0;

void fragment() {
	if (fuerza < 0.01) { discard; }     // escondido: no escribe nada (en la ventana 3D transparente dejaba un cono negro)
	float flujo = 0.55 + 0.45 * sin(UV.y * 34.0 - TIME * 38.0 + UV.x * 12.566);
	float grano = 0.7 + 0.3 * sin(UV.y * 91.0 - TIME * 61.0 + UV.x * 31.4);
	float borde = pow(abs(dot(NORMAL, VIEW)), 1.4);
	ALBEDO = color * COLOR.rgb * COLOR.a * flujo * grano * borde * fuerza * 1.8;
}
