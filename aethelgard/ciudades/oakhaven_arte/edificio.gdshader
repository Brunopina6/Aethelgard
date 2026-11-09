// Arte horneado de Oakhaven (T-089): la luz de la hora azul ya va pintada, así que no recibe luces 2D ni el
// CanvasModulate de la escena (unshaded). Si Kael pasa por DETRÁS (sus pies quedan al norte de la base de la imagen),
// la imagen se aclara en un círculo a su alrededor para que no se pierda.
// La base es el origen del nodo (su «y» es la que ordena frente a Kael). jugador_pos es la variable global del
// proyecto que ya usa la hierba (la pone al día zona.gd y, en la ciudad, pieza.gd).
// Coste: unas pocas operaciones por píxel, sin texturas de más.
shader_type canvas_item;
render_mode unshaded;

global uniform vec2 jugador_pos;
uniform float radio = 105.0;          // px del mundo
uniform float transparencia = 0.72;   // cuánto se aclara en el centro (0 = nada)
uniform float viento = 0.0;           // copas: vaivén en px arriba del todo (0 = quieto)
uniform float alto_px = 1.0;          // alto de la imagen, para el vaivén

varying vec2 mundo;
varying float base_y;

void vertex() {
	if (viento > 0.0) {
		vec2 o = MODEL_MATRIX[3].xy;
		float k = clamp(1.0 - UV.y, 0.0, 1.0);
		VERTEX.x += (sin(TIME * 0.9 + o.x * 0.011) * 0.7 + sin(TIME * 1.7 + o.y * 0.017) * 0.3) * viento * k * k;
	}
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	base_y = MODEL_MATRIX[3].y;
}

void fragment() {
	vec4 c = COLOR;
	float detras = step(jugador_pos.y + 10.0, base_y);
	vec2 d = (mundo - (jugador_pos + vec2(0.0, -58.0))) * vec2(1.0, 0.8);
	float hueco = (1.0 - smoothstep(radio * 0.45, radio, length(d))) * detras;
	c.a *= 1.0 - hueco * transparencia;
	COLOR = c;
}
