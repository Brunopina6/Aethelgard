// Agua viva del mapamundi pintado (T-085): sobre la textura horneada (mapa_mundo.webp) añade destellos que se
// desplazan por el mar y una espuma que «respira» hacia la orilla. Solo toca el agua (datos_agua.b = tierra).
// Coste por píxel: 4 lecturas de textura y unas 20 operaciones (malioc, Mali-G57: docs/graficos/mapamundi.md).
// Con «fuerza» = 0 el resultado es la imagen horneada tal cual.
shader_type canvas_item;

uniform sampler2D datos_agua : filter_linear, repeat_disable;   // R hondura, G cercanía a la orilla, B tierra
uniform sampler2D ruido : filter_linear, repeat_enable;          // ruido sin costuras (NoiseTexture2D)
uniform vec2 tam_mundo = vec2(2400.0, 1350.0);
uniform float fuerza = 1.0;

void fragment() {
	vec3 base = texture(TEXTURE, UV).rgb;
	vec4 d = texture(datos_agua, UV);
	float agua = 1.0 - d.b;
	vec2 p = UV * tam_mundo;
	float n1 = texture(ruido, p * (1.0 / 190.0) + TIME * vec2(0.012, 0.005)).r;
	float n2 = texture(ruido, p * (1.0 / 130.0) + TIME * vec2(-0.007, 0.010)).r;
	float brillo = smoothstep(0.86, 1.04, n1 * n2 * 2.0);       // destellos sueltos (pocos) que se mueven
	float ola = 0.5 + 0.5 * sin(TIME * 1.7 - d.g * 10.0);         // la espuma avanza hacia la orilla
	float luz = brillo * 0.07 * (1.0 - 0.5 * d.r) + d.g * d.g * ola * 0.06;
	COLOR = vec4(base + agua * fuerza * luz * vec3(0.85, 0.95, 1.0), 1.0);
}
