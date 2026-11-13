// v5 (12/11): copia literal de enemigos/bramavidrio/v4/bramavidrio4_polvo.gdshader (la v4 no se toca), para que la v5 sea independiente.
// La arena que aspira Bramavidrio v4 (V12; copia de la de la v3; las cintas acaban DENTRO de la boca) en «ataque_aliento»: cintas que suben del suelo a la boca. Spatial;
// Compatibility. Sin sombreado, mezcla normal, sin escribir profundidad ni sombra. El alfa del color de vértice es su
// fuerza a lo largo (0 en el suelo, 1 en la boca); UV.y va del suelo (0) a la boca (1) y las vetas corren hacia la boca.
// «fuerza» sigue a la escala del hueso «succion» (0,01: escondida; 1: entera).
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 color : source_color = vec3(0.93, 0.80, 0.58);
uniform float fuerza : hint_range(0.0, 1.5) = 0.0;
uniform float suelo = -1000.0;

varying float alto;

void vertex() {
	alto = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	float vetas = 0.45 + 0.55 * sin(UV.y * 26.0 - TIME * 22.0 + UV.x * 9.0);
	float grano = 0.65 + 0.35 * sin(UV.y * 73.0 - TIME * 47.0 + UV.x * 23.0);
	float centro = 1.0 - pow(abs(UV.x * 2.0 - 1.0), 2.0);
	float a = COLOR.a * vetas * grano * centro * clamp(fuerza, 0.0, 1.0);
	if (alto < suelo) {
		a = 0.0;
	}
	ALBEDO = color * (0.85 + 0.3 * grano);
	ALPHA = clamp(a * 0.85, 0.0, 1.0);
}
