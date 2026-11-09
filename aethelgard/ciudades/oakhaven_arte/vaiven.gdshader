// Vaivén (T-089): el letrero del cuervo colgando de su brazo, la ropa tendida… Gira la imagen alrededor del origen
// del nodo (el punto del que cuelga), unos grados, con una racha lenta. Arte horneado: unshaded.
shader_type canvas_item;
render_mode unshaded;

uniform float grados = 5.0;
uniform float rapidez = 1.3;

void vertex() {
	vec2 o = MODEL_MATRIX[3].xy;
	float f = fract(sin(dot(o, vec2(3.17, 9.71))) * 4375.85) * 6.2832;
	float a = radians(grados) * (sin(TIME * rapidez + f) * 0.75 + sin(TIME * rapidez * 2.3 + f * 1.7) * 0.25);
	float c = cos(a);
	float s = sin(a);
	VERTEX = mat2(vec2(c, s), vec2(-s, c)) * VERTEX;
}
