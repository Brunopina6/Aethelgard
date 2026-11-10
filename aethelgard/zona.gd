extends Node2D
# Mapa de una zona de Aethelgard hecho con casillas (Godot 4.x)
# Se entra desde el mapa del mundo con el botón «Entrar». El lugar llega en Engine.get_meta("lugar").
# Capas TileMapLayer: suelo, camino, agua y muros. Encima: árboles, rocas, luces, sombras y clima.
# Todo se genera por código y siempre igual para el mismo lugar.
# Texturas: si existe res://texturas/<nombre>.png (por ejemplo res://texturas/hierba.png) se usa
# esa imagen en vez de la generada, así se puede poner arte de verdad sin tocar el script.
# Toca o haz clic para caminar (o arrastra). En PC también valen las flechas. Tecla E = encuentro (pruebas).

const T := 64                     # tamaño de una casilla en píxeles
const ANCHO := 80                 # casillas de ancho
const ALTO := 56                  # casillas de alto
const COLUMNAS := 16              # casillas por fila en la imagen de casillas (atlas)
const FILA_CAMINO := 1            # filas del atlas: 0 suelo, 1-4 camino, 5-8 agua, 9 muros
const FILA_AGUA := 5
const FILA_MUROS := 9
const VELOCIDAD := 240.0
const LONG_PASO := 20.0
const PASOS_MIN := 40
const PROB_ENCUENTRO := 0.012
const RADIO_ALTAR := 110.0
const VERSION_CACHE := 8      # súbelo si cambias cómo se dibujan las texturas

# Cada tipo de zona: texturas, objetos (con su peso), luz ambiente, luz del jugador y clima.
const ESTILOS := {
	"bosque": {"suelo": "hierba_oscura", "camino": "tierra", "agua": "agua", "muro": "roca_musgo",
		"objetos": {"arce": 3, "abedul": 2, "q_arbol": 4, "q_pino": 2, "q_otono": 1, "helecho": 2, "q_helecho": 3, "q_setas": 3,
			"q_arbusto": 2, "q_planta": 2, "flor_azul": 1, "hierba_alta": 2, "glicinia": 1, "q_roca": 2},
		"densidad": 0.24, "umbral_agua": 0.28, "linde": ["arce", "abedul", "q_arbol", "q_pino", "q_arbol"],
		"hierba_alta": 0.45, "tono_hierba": Color(0.62, 0.78, 0.6),
		"ambiente": Color(0.6, 0.7, 0.62), "luz": 0.7, "rayos": true, "clima": "hojas", "altar": Color(0.5, 1.0, 0.55)},
	"llanura": {"suelo": "hierba", "camino": "tierra", "agua": "agua", "muro": "roca_musgo",
		"objetos": {"arce": 2, "abedul": 2, "q_arbol": 3, "q_otono": 2, "cerezo": 2, "flor_azul": 2, "q_flores": 3, "q_flores_amarillas": 3,
			"q_arbusto_flor": 2, "q_arbusto": 2, "hierba_alta": 2, "q_roca": 2},
		"densidad": 0.09, "umbral_agua": 0.3, "linde": ["arce", "abedul", "q_arbol", "q_otono"],
		"hierba_alta": 0.95, "tono_hierba": Color(1.0, 1.0, 1.0),
		"ambiente": Color(1.0, 0.97, 0.9), "luz": 0.0, "rayos": false, "clima": "polen", "altar": Color(1.0, 0.85, 0.4)},
	"montana": {"suelo": "grava", "camino": "tierra", "agua": "agua", "muro": "roca",
		"objetos": {"pino_alto": 2, "q_pino": 4, "q_seco": 1, "q_roca": 5, "q_hierba_seca": 2}, "densidad": 0.08, "umbral_agua": 0.4,
		"ambiente": Color(0.82, 0.86, 0.95), "luz": 0.0, "rayos": false, "clima": "", "altar": Color(0.75, 0.85, 1.0)},
	"nieve": {"suelo": "nieve", "camino": "nieve_pisada", "agua": "hielo", "muro": "roca_nevada",
		"objetos": {"pino_nevado": 5, "roca_nevada": 2}, "densidad": 0.09, "umbral_agua": 0.32,
		"ambiente": Color(0.78, 0.84, 1.0), "luz": 0.4, "rayos": false, "clima": "nieve", "altar": Color(0.5, 0.9, 1.0)},
	"desierto": {"suelo": "arena", "camino": "arena_dura", "agua": "agua", "muro": "arenisca",
		"objetos": {"roca_arenisca": 4, "arbusto_seco": 2, "q_hierba_seca": 3, "q_seco": 2, "platanera": 1}, "densidad": 0.05, "umbral_agua": 0.45,
		"ambiente": Color(1.0, 0.93, 0.8), "luz": 0.0, "rayos": false, "clima": "polvo", "altar": Color(1.0, 0.8, 0.35)},
	"yermo": {"suelo": "tierra_morada", "camino": "tierra", "agua": "veneno", "muro": "roca_oscura",
		"objetos": {"cristal": 3, "roca_oscura": 2, "q_seco": 5, "q_setas": 2, "q_hierba_seca": 2, "glicinia": 2}, "densidad": 0.07, "umbral_agua": 0.3,
		"ambiente": Color(0.42, 0.36, 0.55), "luz": 1.0, "rayos": false, "clima": "motas", "altar": Color(0.8, 0.45, 1.0)},
	"ceniza": {"suelo": "ceniza", "camino": "basalto", "agua": "lava", "muro": "basalto",
		"objetos": {"roca_oscura": 4, "q_seco": 4, "brasero": 1}, "densidad": 0.06, "umbral_agua": 0.3,
		"ambiente": Color(0.4, 0.32, 0.34), "luz": 1.1, "rayos": false, "clima": "ceniza", "altar": Color(1.0, 0.35, 0.2)},
	"ciudad": {"suelo": "hierba", "camino": "empedrado", "agua": "agua", "muro": "piedra",
		"objetos": {"arce": 1, "q_arbol": 1, "cerezo": 2, "flor_azul": 1, "q_flores": 2, "q_flores_amarillas": 2, "q_arbusto_flor": 2}, "densidad": 0.05, "umbral_agua": 9.0,
		"hierba_alta": 0.3, "tono_hierba": Color(0.85, 0.9, 0.85),
		"ambiente": Color(0.62, 0.58, 0.74), "luz": 0.8, "rayos": false, "clima": "", "altar": Color(1.0, 0.8, 0.5)},
	# mazmorra de la Garganta del Diablo (garganta.gd): cornisas de roca sobre un abismo con niebla
	"garganta": {"suelo": "grava", "camino": "empedrado", "agua": "abismo", "muro": "roca",
		"objetos": {"q_pino": 2, "q_roca": 5, "q_hierba_seca": 2, "q_seco": 1}, "densidad": 0.04, "umbral_agua": 9.0,
		"ambiente": Color(0.7, 0.72, 0.84), "luz": 0.7, "rayos": false, "clima": "polvo", "altar": Color(0.9, 0.5, 0.3)},
}

const NOMBRES_ESTILO := {
	"bosque": "Bosque", "llanura": "Llanura", "montana": "Montaña", "nieve": "Nieve",
	"desierto": "Desierto", "yermo": "Yermo", "ceniza": "Ceniza", "ciudad": "Ciudad", "garganta": "Desfiladero",
}

# Texturas generadas: colores de oscuro a claro, tamaño del ruido y detalles.
# "celdas" = piedras/grietas (ruido celular), "brillo_celdas" = las líneas brillan (agua, lava).
const TEXTURAS := {
	"hierba": {"colores": [Color8(46, 104, 18), Color8(74, 146, 28), Color8(110, 182, 40), Color8(158, 214, 64)], "frec": 0.03, "motas": [Color8(196, 236, 96), 0.05]},
	"hierba_oscura": {"colores": [Color8(26, 48, 22), Color8(44, 76, 34), Color8(66, 100, 44), Color8(98, 120, 56)], "frec": 0.03, "motas": [Color8(90, 70, 40), 0.04]},
	"tierra": {"colores": [Color8(84, 64, 42), Color8(110, 84, 56), Color8(132, 106, 74), Color8(156, 132, 96)], "frec": 0.025, "motas": [Color8(70, 58, 44), 0.015]},
	"grava": {"colores": [Color8(84, 82, 78), Color8(112, 108, 100), Color8(140, 134, 124), Color8(170, 164, 150)], "frec": 0.05, "celdas": 0.09, "fuerza_celdas": 0.35, "motas": [Color8(60, 58, 55), 0.08]},
	"roca": {"colores": [Color8(70, 68, 66), Color8(100, 96, 92), Color8(132, 126, 118), Color8(160, 154, 146)], "frec": 0.035, "celdas": 0.05},
	"roca_musgo": {"colores": [Color8(52, 60, 44), Color8(80, 88, 66), Color8(108, 112, 88), Color8(130, 136, 104)], "frec": 0.035, "celdas": 0.05},
	"nieve": {"colores": [Color8(176, 190, 212), Color8(206, 218, 234), Color8(230, 238, 248), Color8(250, 252, 255)], "frec": 0.025, "motas": [Color8(255, 255, 255), 0.03]},
	"nieve_pisada": {"colores": [Color8(150, 160, 180), Color8(178, 188, 206), Color8(200, 208, 222), Color8(220, 226, 236)], "frec": 0.05},
	"roca_nevada": {"colores": [Color8(90, 96, 110), Color8(140, 150, 168), Color8(200, 210, 226), Color8(240, 244, 250)], "frec": 0.035, "celdas": 0.05},
	"hielo": {"colores": [Color8(110, 160, 200), Color8(150, 196, 226), Color8(190, 222, 240), Color8(225, 242, 252)], "frec": 0.02, "celdas": 0.03, "brillo_celdas": true},
	"arena": {"colores": [Color8(176, 140, 86), Color8(206, 170, 112), Color8(226, 194, 138), Color8(240, 214, 164)], "frec": 0.02, "motas": [Color8(150, 115, 70), 0.05]},
	"arena_dura": {"colores": [Color8(150, 116, 74), Color8(176, 140, 92), Color8(196, 162, 112), Color8(214, 184, 136)], "frec": 0.05},
	"arenisca": {"colores": [Color8(140, 96, 62), Color8(176, 126, 82), Color8(204, 156, 106), Color8(226, 184, 132)], "frec": 0.03, "celdas": 0.05},
	"tierra_morada": {"colores": [Color8(46, 34, 52), Color8(70, 52, 78), Color8(96, 72, 100), Color8(124, 96, 124)], "frec": 0.035, "motas": [Color8(170, 120, 200), 0.02]},
	"roca_oscura": {"colores": [Color8(34, 28, 40), Color8(56, 48, 64), Color8(80, 70, 90), Color8(108, 96, 118)], "frec": 0.035, "celdas": 0.05},
	"veneno": {"colores": [Color8(40, 70, 30), Color8(70, 110, 40), Color8(110, 160, 60), Color8(170, 210, 90)], "frec": 0.02, "celdas": 0.03, "brillo_celdas": true},
	"ceniza": {"colores": [Color8(42, 38, 40), Color8(64, 58, 60), Color8(88, 82, 82), Color8(116, 110, 108)], "frec": 0.03, "motas": [Color8(160, 70, 30), 0.01]},
	"basalto": {"colores": [Color8(24, 22, 24), Color8(40, 36, 38), Color8(60, 54, 56), Color8(84, 76, 76)], "frec": 0.035, "celdas": 0.05},
	"lava": {"colores": [Color8(90, 16, 6), Color8(180, 50, 10), Color8(240, 120, 20), Color8(255, 210, 90)], "frec": 0.02, "celdas": 0.03, "brillo_celdas": true},
	"agua": {"colores": [Color8(16, 46, 70), Color8(24, 70, 100), Color8(40, 100, 130), Color8(70, 140, 160)], "frec": 0.02, "celdas": 0.03, "brillo_celdas": true},
	"empedrado": {"colores": [Color8(92, 88, 84), Color8(120, 114, 106), Color8(148, 140, 128), Color8(172, 164, 150)], "frec": 0.06, "celdas": 0.07},
	"piedra": {"colores": [Color8(86, 82, 80), Color8(112, 106, 100), Color8(138, 130, 120), Color8(160, 152, 140)], "frec": 0.04, "ladrillos": true},
	"tejado": {"colores": [Color8(96, 40, 28), Color8(130, 58, 38), Color8(160, 80, 50), Color8(186, 104, 66)], "frec": 0.05, "tejas": true},
	"abismo": {"colores": [Color8(5, 7, 13), Color8(12, 16, 28), Color8(26, 32, 48), Color8(54, 62, 82)], "frec": 0.015},
}

# Líquidos: color del fondo, del borde (espuma, costra...) y si oscurecen la orilla.
const LIQUIDOS := {
	"agua": {"hondo": Color8(8, 26, 46), "borde": Color(0.8, 0.9, 0.95), "orilla": true, "brillo": 0.12, "vel": 1.0},
	"hielo": {"hondo": Color8(120, 170, 210), "borde": Color(0.95, 0.98, 1.0), "orilla": false, "brillo": 0.08, "vel": 0.2},
	"lava": {"hondo": Color8(255, 220, 120), "borde": Color8(40, 20, 16), "orilla": true, "brillo": 0.3, "vel": 0.4},
	"veneno": {"hondo": Color8(30, 50, 20), "borde": Color8(190, 230, 110), "orilla": true, "brillo": 0.15, "vel": 0.6},
	"abismo": {"hondo": Color8(3, 4, 9), "borde": Color(0.55, 0.6, 0.7), "orilla": true, "brillo": 0.03, "vel": 0.25},
}

# Objetos: tamaño del dibujo, punto de apoyo (pies), ancho de la sombra, radio de choque y luz.
const OBJETOS := {
	"arbol": {"tam": Vector2i(192, 232), "origen": Vector2(96, 226), "sombra": 160.0, "choque": 30.0, "mece": true},
	"arbusto": {"tam": Vector2i(112, 84), "origen": Vector2(56, 78), "sombra": 100.0, "choque": 26.0, "mece": true},
	"arbusto_seco": {"tam": Vector2i(96, 80), "origen": Vector2(48, 76), "sombra": 60.0, "choque": 18.0, "mece": true},
	"pino": {"tam": Vector2i(128, 220), "origen": Vector2(64, 214), "sombra": 100.0, "choque": 28.0, "mece": true},
	"pino_nevado": {"tam": Vector2i(128, 220), "origen": Vector2(64, 214), "sombra": 100.0, "choque": 28.0, "mece": true},
	"roca": {"tam": Vector2i(104, 80), "origen": Vector2(52, 72), "sombra": 100.0, "choque": 26.0},
	"roca_nevada": {"tam": Vector2i(104, 80), "origen": Vector2(52, 72), "sombra": 100.0, "choque": 26.0},
	"roca_arenisca": {"tam": Vector2i(104, 80), "origen": Vector2(52, 72), "sombra": 100.0, "choque": 26.0},
	"roca_oscura": {"tam": Vector2i(104, 80), "origen": Vector2(52, 72), "sombra": 100.0, "choque": 26.0},
	"cristal": {"tam": Vector2i(80, 112), "origen": Vector2(40, 106), "sombra": 60.0, "choque": 16.0,
		"luz": Color(0.75, 0.45, 1.0), "luz_pos": Vector2(0, -50), "energia": 0.9},
	"brasero": {"tam": Vector2i(56, 64), "origen": Vector2(28, 60), "sombra": 50.0, "choque": 16.0,
		"luz": Color(1.0, 0.6, 0.25), "luz_pos": Vector2(0, -44), "energia": 1.2, "fuego": true},
	"farola": {"tam": Vector2i(40, 150), "origen": Vector2(20, 146), "sombra": 30.0, "choque": 8.0,
		"luz": Color(1.0, 0.78, 0.45), "luz_pos": Vector2(0, -124), "energia": 1.0, "fuego": true},
	"altar": {"tam": Vector2i(112, 120), "origen": Vector2(56, 112), "sombra": 100.0, "choque": 34.0},
	"columna": {"tam": Vector2i(64, 150), "origen": Vector2(32, 144), "sombra": 60.0, "choque": 20.0},
	"muro_ruina": {"tam": Vector2i(120, 80), "origen": Vector2(60, 74), "sombra": 110.0, "choque": 34.0},
	"tronco": {"tam": Vector2i(110, 50), "origen": Vector2(55, 44), "sombra": 100.0, "choque": 0.0},
	"cofre": {"tam": Vector2i(64, 56), "origen": Vector2(32, 52), "sombra": 60.0, "choque": 18.0},
	"cofre_abierto": {"tam": Vector2i(64, 72), "origen": Vector2(32, 68), "sombra": 60.0, "choque": 18.0},
	# detalle de lore (progreso.gd): piedra con el anillo dorado partido del brazalete
	"estela": {"tam": Vector2i(72, 120), "origen": Vector2(36, 114), "sombra": 70.0, "choque": 20.0},
	# piezas de mazmorra (garganta.gd)
	"guardado": {"tam": Vector2i(64, 112), "origen": Vector2(32, 106), "sombra": 60.0, "choque": 16.0,
		"luz": Color(0.55, 1.0, 0.65), "luz_pos": Vector2(0, -56), "energia": 0.9},
	"palanca": {"tam": Vector2i(64, 96), "origen": Vector2(32, 90), "sombra": 60.0, "choque": 18.0},
	"palanca_bajada": {"tam": Vector2i(64, 96), "origen": Vector2(32, 90), "sombra": 60.0, "choque": 18.0},
	"ascensor": {"tam": Vector2i(112, 132), "origen": Vector2(56, 124), "sombra": 110.0, "choque": 0.0},
	"puerta": {"tam": Vector2i(150, 212), "origen": Vector2(75, 206), "sombra": 140.0, "choque": 0.0},
	"puerta_abierta": {"tam": Vector2i(150, 212), "origen": Vector2(75, 206), "sombra": 140.0, "choque": 0.0},
}
const RADIO_DETALLE := 90.0      # distancia para examinar un detalle de lore
const RADIO_BRAZALETE := 260.0   # el brazalete de Kael brilla al acercarse a un detalle sin ver

# Vegetación de Meshy: fotos de los modelos 3D (carpeta decorado). "escala" = tamaño en el mapa.
const DECORADO := {
	"arce": {"imagen": "res://decorado/arce.png", "escala": 0.62, "choque": 34.0},
	"abedul": {"imagen": "res://decorado/abedul.png", "escala": 0.62, "choque": 24.0},
	"pino_alto": {"imagen": "res://decorado/pino.png", "escala": 0.6, "choque": 36.0},
	"glicinia": {"imagen": "res://decorado/glicinia.png", "escala": 0.62, "choque": 34.0},
	"cerezo": {"imagen": "res://decorado/cerezo.png", "escala": 0.62, "choque": 34.0},
	"helecho": {"imagen": "res://decorado/helecho.png", "escala": 0.75, "choque": 16.0},
	"flor_azul": {"imagen": "res://decorado/flor_azul.png", "escala": 0.55, "choque": 12.0},
	"hierba_alta": {"imagen": "res://decorado/hierba_alta.png", "escala": 0.42, "choque": 0.0},
	"platanera": {"imagen": "res://decorado/platanera.png", "escala": 0.6, "choque": 28.0},
	# Quaternius Stylized Nature MegaKit (CC0). "variantes" = cuántas fotos hay (<imagen>_1.png ... _N.png):
	# cada planta coge una al azar según su posición.
	"q_arbol": {"imagen": "res://decorado/quaternius/commontree.png", "variantes": 5, "escala": 0.62, "choque": 30.0},
	"q_pino": {"imagen": "res://decorado/quaternius/pine.png", "variantes": 5, "escala": 0.6, "choque": 30.0},
	"q_otono": {"imagen": "res://decorado/quaternius/twistedtree.png", "variantes": 5, "escala": 0.62, "choque": 32.0},
	"q_seco": {"imagen": "res://decorado/quaternius/deadtree.png", "variantes": 5, "escala": 0.6, "choque": 22.0},
	"q_arbusto": {"imagen": "res://decorado/quaternius/bush_common.png", "escala": 0.7, "choque": 24.0},
	"q_arbusto_flor": {"imagen": "res://decorado/quaternius/bush_common_flowers.png", "escala": 0.7, "choque": 24.0},
	"q_planta": {"imagen": "res://decorado/quaternius/plant_1_big.png", "escala": 0.7, "choque": 0.0},
	"q_planta_morada": {"imagen": "res://decorado/quaternius/plant_7_big.png", "escala": 0.7, "choque": 0.0},
	"q_helecho": {"imagen": "res://decorado/quaternius/fern_1.png", "escala": 0.75, "choque": 0.0},
	"q_flores": {"imagen": "res://decorado/quaternius/flower_3_group.png", "escala": 0.7, "choque": 0.0},
	"q_flores_amarillas": {"imagen": "res://decorado/quaternius/flower_4_group.png", "escala": 0.7, "choque": 0.0},
	"q_hierba_seca": {"imagen": "res://decorado/quaternius/grass_wispy_tall.png", "escala": 0.7, "choque": 0.0},
	"q_setas": {"imagen": "res://decorado/quaternius/mushroom_common.png", "escala": 0.75, "choque": 0.0},
	"q_setas_naranja": {"imagen": "res://decorado/quaternius/mushroom_laetiporus.png", "escala": 0.75, "choque": 0.0},
	"q_roca": {"imagen": "res://decorado/quaternius/rock_medium.png", "variantes": 3, "escala": 0.75, "choque": 28.0},
}

const ROCAS := {
	"roca": [Color8(60, 58, 56), Color8(96, 92, 88), Color8(136, 130, 122), Color8(176, 170, 160)],
	"roca_nevada": [Color8(70, 76, 90), Color8(110, 118, 134), Color8(150, 158, 172), Color8(190, 196, 208)],
	"roca_arenisca": [Color8(110, 70, 44), Color8(156, 106, 68), Color8(196, 146, 98), Color8(226, 186, 136)],
	"roca_oscura": [Color8(26, 22, 30), Color8(48, 42, 54), Color8(74, 66, 82), Color8(104, 96, 112)],
}

const SHADER_AGUA := """
shader_type canvas_item;
uniform float brillo = 0.12;
uniform float velocidad = 1.0;
varying vec2 mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec4 c = COLOR;
	float a = sin(mundo.x * 0.045 + TIME * 1.3 * velocidad + sin(mundo.y * 0.03 + TIME * 0.7) * 2.0);
	float b = sin(mundo.y * 0.06 - TIME * 1.1 * velocidad + sin(mundo.x * 0.025 - TIME * 0.5) * 2.0);
	float s = smoothstep(0.7, 1.0, a * b);
	c.rgb += vec3(s * brillo) * smoothstep(0.85, 1.0, c.a);
	COLOR = c;
}
"""

# Hierba alta: miles de matas en MultiMesh (por trozos, ver _crear_hierba). Todo el movimiento se
# calcula en el vertex shader, sin coste de CPU:
#  - viento: senos con el tiempo, solo en la parte de arriba (UV.y hace de máscara: la raíz no se mueve)
#  - jugador: las matas cercanas se aplastan y se apartan. Su posición llega en la variable global
#    de shader "jugador_pos" (Configuración del Proyecto > Shader Globals), que zona.gd actualiza
#    solo cuando el jugador se mueve: un único dato para todos los trozos.
# Alpha scissor: los píxeles casi transparentes se descartan (discard) en vez de mezclarse.
const SHADER_HIERBA := """
shader_type canvas_item;
global uniform vec2 jugador_pos;
uniform float variantes = 1.0;          // columnas de la textura (1 = foto; 4 = matas dibujadas)
uniform float altura = 56.0;
uniform float corte_alfa : hint_range(0.0, 1.0) = 0.32;
uniform float brillo = 1.35;            // los mipmaps de la foto la oscurecen un poco al verla pequeña
varying float punta;
varying float racha;
void vertex() {
	vec2 pos = INSTANCE_CUSTOM.yz;
	punta = 1.0 - UV.y;                                         // 0 en la raíz, 1 en la punta
	float t2 = punta * punta;
	vec2 d = pos - jugador_pos;
	float empuje = smoothstep(80.0, 12.0, length(d));
	racha = sin(TIME * 0.9 - pos.x * 0.006 - pos.y * 0.003) * 0.5 + 0.5;
	float viento = sin(TIME * 2.0 + pos.x * 0.02 + pos.y * 0.013 + INSTANCE_CUSTOM.w) * 3.0 + racha * 7.0;
	VERTEX.x += (viento + sign(d.x + 0.01) * empuje * 16.0) * t2;
	VERTEX.y += punta * altura * empuje * 0.55;
	UV.x = (UV.x + INSTANCE_CUSTOM.x) / variantes;
}
void fragment() {
	// COLOR ya trae la textura multiplicada por el color de cada mata
	if (COLOR.a < corte_alfa) {
		discard;                                                 // alpha scissor
	}
	COLOR = vec4(COLOR.rgb * brillo * (0.8 + punta * 0.35) * (1.0 + racha * punta * 0.18), 1.0);   // raíz en sombra, puntas al sol
}
"""
const TEXTURA_HIERBA := "res://texturas/hierba_mata.png"   # foto de una mata (si no está, se dibujan)
const TROZO_HIERBA := 512.0             # lado de cada trozo: Godot no dibuja los que están fuera de pantalla

# Las plantas se mecen con el viento (más arriba, más se mueven).
const SHADER_VIENTO := """
shader_type canvas_item;
uniform float fuerza = 3.0;
void vertex() {
	vec2 origen = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float k = 1.0 - UV.y;
	VERTEX.x += sin(TIME * 1.4 + origen.x * 0.013 + origen.y * 0.007) * fuerza * k * k;
}
"""

var lugar: Dictionary
var estilo: Dictionary
var nombre_estilo := ""
var es_ciudad := false
var semilla := 0

# Disposición: los vértices (esquinas de casilla) dicen dónde hay camino o agua; las casillas, los muros.
var caminos: Array = []           # listas de puntos (en casillas)
var ancho_camino := 0.85
var plaza := Vector2(-100, -100)
var meta := Vector2.ZERO          # final del camino: el altar o monumento del lugar
var salida_x := ANCHO * 0.5
var camino_v := PackedByteArray()
var agua_v := PackedByteArray()
var muros := PackedByteArray()
var colocados: Array = []         # objetos a colocar: {"tipo", "pos"}
var lugares_interes: Array = []   # {"tipo": ruinas/campamento/claro, "pos"} (en casillas)
var puentes: Array = []           # [centro (px), dirección del camino, largo (px)]
var cofres: Array = []            # [sprite, id, abierto]
var cofre_cerca = null
var detalles: Array = []          # detalles de lore: [sprite, datos de progreso.gd]
var detalle_cerca = null
var brillados := {}               # detalles por los que ya brilló el brazalete (hasta alejarse)

var mundo_y: Node2D               # objetos y jugador ordenados por altura (los de delante tapan)
var sombras: Node2D
var jugador: CharacterBody2D
var sprite                # muñeco animado de Kael (muneco.gd)
var camara: Camera2D
var luz_jugador: PointLight2D
var luces_fuego: Array = []
var texturas_obj := {}
var luz_tex: GradientTexture2D
var sombra_tex: GradientTexture2D
var mat_aditivo: CanvasItemMaterial
var mat_viento: ShaderMaterial
var mat_hierba: ShaderMaterial
var matas_tex: Texture2D
var hierba_pies: Sprite2D           # matas delante de los pies del jugador cuando pisa hierba alta
var altar: Node2D

var ui: CanvasLayer
var boton_examinar: Button
var botones_hud: Array = []         # MAPA DEL MUNDO, TIENDA y POSADA: el foco solo entra con teclado o mando
var barra_activa := false           # el foco está en esos botones: el jugador no se mueve
var ultimo_de_barra := "MAPA DEL MUNDO"
var npcs: Array = []                # [sprite, datos, frase siguiente]
var npc_cerca = null
var tienda_abierta := false
var lbl_oro: Label
var aviso: Label
var tween_aviso: Tween
var fundido: ColorRect

var destino := Vector2.ZERO
var tiene_destino := false
var acum := 0.0
var pasos := 0
var tiempo := 0.0
var saliendo := false

# Comentarios de los héroes al explorar (dialogos/comentarios.gd, narrativa): al llegar a un lugar por primera vez en
# la sesión y tras abrir un cofre. Solo se ven: no cambian la partida.
const Comentarios := preload("res://dialogos/comentarios.gd")
const Hallazgos := preload("res://hallazgos.gd")     # tomos, armas y accesorios que se encuentran (narrativa)
const LLEGADA_COMENTARIO := 2.8           # s tras entrar: después del fundido y del aviso del lugar
var llegada_t := LLEGADA_COMENTARIO       # cuenta atrás del comentario al llegar (< 0: ya pasó)
var comentario_pendiente := ""            # momento que espera su turno (el del cofre, tras el premio)
var comentario_t := 0.0


func _ready() -> void:
	randomize()
	_leer_lugar()
	_crear_recursos()
	_generar_disposicion()
	_crear_capas()
	_crear_objetos()
	_crear_jugador()
	Sonido.pasos_zona(self)                       # pasos según el suelo, la hierba, el camino o un puente (sonido.gd)
	Sonido.agua_zona(self)                        # el río suena al acercarse (sonido.gd, T-083)
	_crear_iluminacion()
	_crear_clima()
	_crear_ui()
	guardar_posicion()
	load("res://progreso.gd").guardar(scene_file_path)   # guardado automático al entrar en cada zona
	if es_ciudad:
		_mostrar_aviso("%s: la tienda y la posada están abiertas." % lugar["nombre"])
		if "tienda" in OS.get_cmdline_user_args():     # pruebas: -- tienda
			_abrir_tienda.call_deferred()
		for a in OS.get_cmdline_user_args():
			if a.begins_with("tienda="):
				_abrir_tienda.call_deferred(a.substr(7))


# ================================================================= lugar y disposición

func _leer_lugar() -> void:
	lugar = Engine.get_meta("lugar", {"indice": 1, "nombre": "Gran Bosque Verde", "tipo": "lugar", "zona": "bosque",
		"texto": "Santuario profanado donde Lya protege el Núcleo de la Naturaleza."})
	nombre_estilo = "ciudad" if lugar["tipo"] == "ciudad" else lugar["zona"]
	for a in OS.get_cmdline_user_args():          # pruebas: godot ... -- estilo=nieve
		if a.begins_with("estilo=") and ESTILOS.has(a.substr(7)):
			nombre_estilo = a.substr(7)
	if not ESTILOS.has(nombre_estilo):
		nombre_estilo = "llanura"
	estilo = ESTILOS[nombre_estilo]
	es_ciudad = nombre_estilo == "ciudad"
	semilla = 1000 + int(lugar["indice"]) * 7919


func _generar_disposicion() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var ruido := FastNoiseLite.new()
	ruido.seed = semilla
	ruido.frequency = 0.09
	var ruido_agua := FastNoiseLite.new()
	ruido_agua.seed = semilla + 5
	ruido_agua.frequency = 0.07
	ruido_agua.fractal_octaves = 3

	# caminos: desde la salida (abajo) hasta el altar (arriba), con una rama lateral
	var pts := PackedVector2Array([Vector2(salida_x, ALTO + 1), Vector2(salida_x, ALTO - 4)])
	var x := salida_x
	if es_ciudad:
		ancho_camino = 1.5
		plaza = Vector2(salida_x, ALTO * 0.45)
		pts.append(plaza)
		meta = Vector2(salida_x, 5)
		pts.append(meta)
		caminos.append(pts)
		caminos.append(PackedVector2Array([Vector2(6, plaza.y), Vector2(ANCHO - 6, plaza.y)]))
	else:
		# camino principal serpenteando hacia el altar del norte
		for y in [ALTO - 10, ALTO - 19, ALTO - 28, ALTO - 37, ALTO - 45]:
			x = clampf(x + rng.randf_range(-12, 12), 10, ANCHO - 10)
			pts.append(Vector2(x, y))
		meta = Vector2(clampf(x + rng.randf_range(-6, 6), 10, ANCHO - 10), 5)
		pts.append(meta)
		caminos.append(pts)
		# ramas que llevan a lugares escondidos: ruinas con cofre, un campamento, un claro con cofre
		var tipos := ["ruinas", "campamento", "claro"]
		for i in 3:
			var desde: Vector2 = pts[i + 2]
			var lado := -1.0 if (desde.x > ANCHO * 0.5) != (i == 1) else 1.0
			var fin := Vector2(clampf(desde.x + lado * rng.randf_range(18, 26), 9, ANCHO - 9),
				clampf(desde.y + rng.randf_range(-6, 4), 8, ALTO - 10))
			var medio := desde.lerp(fin, 0.5) + Vector2(0, rng.randf_range(-4, 4))
			caminos.append(PackedVector2Array([desde, medio, fin]))
			lugares_interes.append({"tipo": tipos[i], "pos": fin})

	# río que cruza la zona de lado a lado (no en ciudades ni desiertos); donde lo cruza un camino hay puente
	var hay_rio := not es_ciudad and nombre_estilo != "desierto"
	var rio_base := ALTO * rng.randf_range(0.45, 0.62)
	var rio_ancho := 1.7

	var vw := ANCHO + 1
	camino_v.resize(vw * (ALTO + 1))
	agua_v.resize(vw * (ALTO + 1))
	for vy in ALTO + 1:
		for vx in vw:
			var p := Vector2(vx, vy)
			var d := _dist_caminos(p) + ruido.get_noise_2d(vx * 3.0, vy * 3.0) * 0.5
			var en_camino := d < ancho_camino or p.distance_to(plaza) < 4.5 + ruido.get_noise_2d(vx * 5.0, vy * 5.0)
			for l in lugares_interes:                # los lugares escondidos tienen un claro de tierra
				if p.distance_to(l["pos"]) < 3.2 + ruido.get_noise_2d(vx * 4.0, vy * 4.0) * 1.5:
					en_camino = true
			camino_v[vy * vw + vx] = 1 if en_camino else 0
			var borde := minf(minf(vx, vy), minf(ANCHO - vx, ALTO - vy))
			var agua: bool = d > ancho_camino + 2.5 and borde > 4 and ruido_agua.get_noise_2d(vx, vy) > estilo["umbral_agua"]
			if hay_rio and borde > 1:
				var ry := _rio_y(vx, rio_base, ruido)
				if absf(vy - ry) < rio_ancho + ruido.get_noise_2d(vx * 2.0, 300.0) * 0.6:
					agua = true
			for l in lugares_interes:
				if p.distance_to(l["pos"]) < 5.0:
					agua = false
			agua_v[vy * vw + vx] = 1 if agua else 0
	if hay_rio:
		_poner_puentes(rio_base, ruido)

	# muros alrededor (con la salida abierta) y casas en la ciudad
	muros.resize(ANCHO * ALTO)
	for y in ALTO:
		for xx in ANCHO:
			var c := Vector2(xx + 0.5, y + 0.5)
			var borde := minf(minf(c.x, c.y), minf(ANCHO - c.x, ALTO - c.y))
			var grosor := 1.0 if es_ciudad else 1.6 + (ruido.get_noise_2d(xx * 2.0 + 500.0, y * 2.0) + 0.5) * 2.2
			muros[y * ANCHO + xx] = 1 if borde < grosor and _dist_caminos(c) > ancho_camino + 0.6 else 0
	if es_ciudad:
		var casas := 0
		for intento in 260:
			var w := rng.randi_range(3, 6)
			var h := rng.randi_range(3, 4)
			var cx := rng.randi_range(2, ANCHO - 2 - w)
			var cy := rng.randi_range(2, ALTO - 3 - h)
			if _hueco_libre(cx, cy, w, h) and casas < 34:
				for yy in h:
					for xx in w:
						muros[(cy + yy) * ANCHO + cx + xx] = 2
				casas += 1

	# árboles, rocas...
	var pesos: Dictionary = estilo["objetos"]
	var total := 0
	for k in pesos:
		total += pesos[k]
	var spawn := Vector2(salida_x, ALTO - 2.5)
	for y in range(1, ALTO - 1):
		for xx in range(1, ANCHO - 1):
			if muros[y * ANCHO + xx] != 0:
				continue
			var c := Vector2(xx + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9))
			if _dist_caminos(c) < ancho_camino + 1.0 or c.distance_to(plaza) < 6.0:
				continue
			if _peso(agua_v, c) > 0.05 or c.distance_to(spawn) < 4.0 or c.distance_to(meta) < 3.0:
				continue
			if _cerca_de_lugar(c, 5.5) or _en_puente(c * T, 40.0):
				continue
			var borde := minf(minf(c.x, c.y), minf(ANCHO - c.x, ALTO - c.y))
			var dens: float = estilo["densidad"] * (2.0 if borde < 6.0 else 1.0)
			if rng.randf() >= dens:
				continue
			var r := rng.randi_range(1, total)
			for k in pesos:
				r -= pesos[k]
				if r <= 0:
					colocados.append({"tipo": k, "pos": c * T})
					break
	if estilo.has("linde"):                        # bosques y llanuras: la linde son árboles, no rocas
		for y in ALTO:
			for xx in ANCHO:
				if muros[y * ANCHO + xx] == 1 and rng.randf() < 0.6:
					var c := Vector2(xx + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9))
					var lindes: Array = estilo["linde"]
					colocados.append({"tipo": lindes[rng.randi() % lindes.size()] if rng.randf() < 0.8 else "arbusto", "pos": c * T})
	_poner_lugares(rng)
	if es_ciudad:                                  # farolas a los lados de las calles
		for cam in caminos:
			for i in cam.size() - 1:
				var a: Vector2 = cam[i]
				var b: Vector2 = cam[i + 1]
				var n := int(a.distance_to(b) / 5.0)
				var lateral := (b - a).normalized().orthogonal() * (ancho_camino + 0.8)
				for j in n:
					var p := a.lerp(b, (j + 0.5) / n) + lateral * (1.0 if j % 2 == 0 else -1.0)
					if p.y < ALTO - 1.5 and p.distance_to(plaza) > 5.0 and muros[int(p.y) * ANCHO + int(p.x)] == 0:
						colocados.append({"tipo": "farola", "pos": p * T})


# ---------------------------------------------------------------- río, puentes y lugares escondidos

# Altura del río (en casillas) en cada columna: una curva suave con algo de ruido.
func _rio_y(x: float, base: float, ruido: FastNoiseLite) -> float:
	return base + sin(x * 0.09 + semilla) * 4.5 + ruido.get_noise_2d(x * 1.5, 900.0) * 3.0


# Donde un camino cruza el río se pone un puente (el agua sigue debajo, pero se puede pasar).
func _poner_puentes(base: float, ruido: FastNoiseLite) -> void:
	for cam in caminos:
		for i in cam.size() - 1:
			var a: Vector2 = cam[i]
			var b: Vector2 = cam[i + 1]
			var pasos := int(a.distance_to(b) * 4.0)
			var antes := 0.0
			for k in pasos + 1:
				var p := a.lerp(b, float(k) / maxi(pasos, 1))
				var lado := signf(p.y - _rio_y(p.x, base, ruido))
				if k > 0 and lado != antes and lado != 0.0:
					var centro := Vector2(p.x, _rio_y(p.x, base, ruido))
					var ya := false
					for pu in puentes:
						if pu[0].distance_to(centro * T) < T * 4:
							ya = true
					if not ya:
						puentes.append([centro * T, (b - a).normalized(), T * 6.0])
				antes = lado


func _en_puente(p: Vector2, margen := 0.0) -> bool:
	for pu in puentes:
		var d: Vector2 = p - pu[0]
		var dir: Vector2 = pu[1]
		if absf(d.dot(dir)) < pu[2] * 0.5 + margen and absf(d.dot(dir.orthogonal())) < T * 1.1 + margen:
			return true
	return false


func _cerca_de_lugar(c: Vector2, r: float) -> bool:
	for l in lugares_interes:
		if c.distance_to(l["pos"]) < r:
			return true
	return false


# Cada lugar escondido tiene su decorado: ruinas (columnas y muros rotos con un cofre),
# un campamento (hoguera, troncos y un cofre) o un claro con flores y un cofre.
func _poner_lugares(rng: RandomNumberGenerator) -> void:
	for l in lugares_interes:
		var c: Vector2 = l["pos"]
		match l["tipo"]:
			"ruinas":
				for i in 7:
					var a := TAU * i / 7.0 + rng.randf_range(-0.2, 0.2)
					var r := rng.randf_range(2.6, 3.6)
					colocados.append({"tipo": "columna" if i % 2 == 0 else "muro_ruina", "pos": (c + Vector2(cos(a), sin(a) * 0.8) * r) * T})
				colocados.append({"tipo": "cofre", "pos": (c + Vector2(0, -0.6)) * T})
			"campamento":
				colocados.append({"tipo": "brasero", "pos": c * T})
				for i in 3:
					var a := TAU * i / 3.0 + 0.5
					colocados.append({"tipo": "tronco", "pos": (c + Vector2(cos(a), sin(a) * 0.7) * 1.8) * T})
				colocados.append({"tipo": "cofre", "pos": (c + Vector2(2.6, -1.2)) * T})
			"claro":
				for i in 8:
					var a := rng.randf() * TAU
					colocados.append({"tipo": "q_flores" if i % 2 == 0 else "q_flores_amarillas", "pos": (c + Vector2(cos(a), sin(a)) * rng.randf_range(2.0, 3.5)) * T})
				colocados.append({"tipo": "cofre", "pos": c * T})


# ¿Cabe una casa aquí? Sin muros alrededor y lejos de calles y plaza.
func _hueco_libre(cx: int, cy: int, w: int, h: int) -> bool:
	for y in range(cy - 1, cy + h + 1):
		for x in range(cx - 1, cx + w + 1):
			if x < 0 or y < 0 or x >= ANCHO or y >= ALTO or muros[y * ANCHO + x] != 0:
				return false
			var c := Vector2(x + 0.5, y + 0.5)
			if _dist_caminos(c) < ancho_camino + 1.0 or c.distance_to(plaza) < 6.0 or c.distance_to(meta) < 3.0:
				return false
	return true


func _dist_caminos(p: Vector2) -> float:
	var d := 1e9
	for cam in caminos:
		for i in cam.size() - 1:
			d = minf(d, p.distance_to(Geometry2D.get_closest_point_to_segment(p, cam[i], cam[i + 1])))
	return d


# Cuánto hay de camino o agua en un punto (0 nada, 1 lleno), mezclando las cuatro esquinas.
func _peso(v: PackedByteArray, p: Vector2) -> float:
	var vw := ANCHO + 1
	var x := clampi(int(p.x), 0, ANCHO - 1)
	var y := clampi(int(p.y), 0, ALTO - 1)
	var u := clampf(p.x - x, 0.0, 1.0)
	var w := clampf(p.y - y, 0.0, 1.0)
	var arriba := lerpf(v[y * vw + x], v[y * vw + x + 1], u)
	var abajo := lerpf(v[(y + 1) * vw + x], v[(y + 1) * vw + x + 1], u)
	return lerpf(arriba, abajo, w)


# ================================================================= casillas (TileMapLayer)

func _crear_capas() -> void:
	var atlas := _cargar_cache("atlas_" + nombre_estilo + _firma_texturas(), _crear_atlas)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.add_occlusion_layer()
	var fuente := TileSetAtlasSource.new()
	fuente.texture = ImageTexture.create_from_image(atlas)
	fuente.texture_region_size = Vector2i(T, T)
	ts.add_source(fuente, 0)
	for fila in FILA_MUROS + 1:
		for col in COLUMNAS:
			fuente.create_tile(Vector2i(col, fila))
	# los muros chocan y hacen sombra con las luces
	var m := T * 0.5
	var cuadrado := PackedVector2Array([Vector2(-m, -m), Vector2(m, -m), Vector2(m, m), Vector2(-m, m)])
	for col in 5:                                  # la 5ª casilla es transparente: muro invisible (linde de árboles)
		var td := fuente.get_tile_data(Vector2i(col, FILA_MUROS), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, cuadrado)
		var occ := OccluderPolygon2D.new()
		occ.polygon = cuadrado
		td.add_occluder_polygon(0)
		td.set_occluder_polygon(0, 0, occ)

	var suelo := _nueva_capa(ts)
	var camino := _nueva_capa(ts)
	var agua := _nueva_capa(ts)
	var capa_muros := _nueva_capa(ts)
	var liq: Dictionary = LIQUIDOS[estilo["agua"]]
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER_AGUA
	mat.set_shader_parameter("brillo", liq["brillo"])
	mat.set_shader_parameter("velocidad", liq["vel"])
	agua.material = mat
	var vw := ANCHO + 1
	for y in ALTO:
		for x in ANCHO:
			suelo.set_cell(Vector2i(x, y), 0, Vector2i((y % 4) * 4 + x % 4, 0))
			var trozo := (x % 2) + (y % 2) * 2
			for par in [[camino_v, camino, FILA_CAMINO], [agua_v, agua, FILA_AGUA]]:
				var v: PackedByteArray = par[0]
				var conf: int = v[y * vw + x] | (v[y * vw + x + 1] << 1) | (v[(y + 1) * vw + x] << 2) | (v[(y + 1) * vw + x + 1] << 3)
				if conf != 0:
					var i := (conf - 1) * 4 + trozo
					par[1].set_cell(Vector2i(x, y), 0, Vector2i(i % COLUMNAS, par[2] + floori(i / float(COLUMNAS))))
			var mu := muros[y * ANCHO + x]
			if mu != 0:
				var abajo := muros[(y + 1) * ANCHO + x] if y + 1 < ALTO else 0
				var col := (0 if mu == 1 else 2) + (1 if abajo != mu else 0)
				# 3 = muro invisible: solo lo usan las ciudades hechas a mano (ciudad_oakhaven.gd), bajo su dibujo
				if mu == 3 or (mu == 1 and estilo.has("linde")):
					col = 4
				elif mu == 2 and abajo == mu:
					col = 5 if _filas_tejado_arriba(x, y) < _filas_tejado_abajo(x, y) else 6
				elif abajo != mu and y + 1 < ALTO:
					_sombra_muro(Vector2(x + 0.5, y + 1.05) * T)
				capa_muros.set_cell(Vector2i(x, y), 0, Vector2i(col, FILA_MUROS))


func _filas_tejado_arriba(x: int, y: int) -> int:
	var n := 0
	while y - n - 1 >= 0 and muros[(y - n - 1) * ANCHO + x] == 2:
		n += 1
	return n


func _filas_tejado_abajo(x: int, y: int) -> int:   # sin contar la fachada
	var n := 0
	while y + n + 2 < ALTO and muros[(y + n + 2) * ANCHO + x] == 2:
		n += 1
	return n


# Sombra suave sobre el suelo al pie de un muro.
func _sombra_muro(pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = sombra_tex
	s.position = pos
	s.scale = Vector2(T * 1.6, T * 0.55) / 128.0
	s.modulate.a = 0.9
	add_child(s)


func _nueva_capa(ts: TileSet) -> TileMapLayer:
	var c := TileMapLayer.new()
	c.tile_set = ts
	add_child(c)
	return c


# Imagen con todas las casillas: suelo (16 trozos de una textura de 4×4 casillas), bordes de camino
# y de agua (15 combinaciones de esquinas × 4 trozos) y muros (piedra y tejado, con y sin frente).
func _crear_atlas() -> Image:
	var atlas := Image.create(COLUMNAS * T, (FILA_MUROS + 1) * T, false, Image.FORMAT_RGBA8)
	var suelo := _textura(estilo["suelo"], T * 4)
	for i in 16:
		atlas.blit_rect(suelo, Rect2i((i % 4) * T, floori(i / 4.0) * T, T, T), Vector2i(i * T, 0))
	_pintar_bordes(atlas, FILA_CAMINO, _textura(estilo["camino"], T * 2), "", 11)
	_pintar_bordes(atlas, FILA_AGUA, _textura(estilo["agua"], T * 2), estilo["agua"], 23)
	var piedra := _textura(estilo["muro"], T)
	var tejado := _textura("tejado", T)
	var y0 := FILA_MUROS * T
	_pintar_bloque(atlas, Vector2i(0, y0), piedra, piedra, false)
	_pintar_bloque(atlas, Vector2i(T, y0), piedra, piedra, true)
	_pintar_bloque(atlas, Vector2i(2 * T, y0), tejado, tejado, false)
	_pintar_bloque(atlas, Vector2i(3 * T, y0), tejado, _fachada(), true)
	# tejado a dos aguas: la mitad de arriba recibe el sol y la de abajo queda en sombra
	var sol := tejado.duplicate() as Image
	var sombra := tejado.duplicate() as Image
	for y in T:
		for x in T:
			sol.set_pixel(x, y, tejado.get_pixel(x, y).lightened(0.14))
			sombra.set_pixel(x, y, tejado.get_pixel(x, y).darkened(0.22))
	_pintar_bloque(atlas, Vector2i(5 * T, y0), sol, sol, false)
	_pintar_bloque(atlas, Vector2i(6 * T, y0), sombra, sombra, false)
	return atlas


# Casillas de borde: cada esquina está dentro o fuera; el borde se dibuja ondulado con ruido.
func _pintar_bordes(atlas: Image, fila0: int, tex: Image, liquido: String, sem: int) -> void:
	var r := FastNoiseLite.new()
	r.seed = sem
	r.frequency = 0.05
	r.fractal_octaves = 3
	var ruido := r.get_seamless_image(T * 2, T * 2)
	var liq: Dictionary = LIQUIDOS.get(liquido, {})
	for conf in range(1, 16):
		var c00 := float(conf & 1)
		var c10 := float((conf >> 1) & 1)
		var c01 := float((conf >> 2) & 1)
		var c11 := float((conf >> 3) & 1)
		for trozo in 4:
			var ox := (trozo % 2) * T
			var oy := floori(trozo / 2.0) * T
			var i := (conf - 1) * 4 + trozo
			var dx := (i % COLUMNAS) * T
			var dy := (fila0 + floori(i / float(COLUMNAS))) * T
			for y in T:
				var v := (y + 0.5) / T
				for x in T:
					var u := (x + 0.5) / T
					var w := lerpf(lerpf(c00, c10, u), lerpf(c01, c11, u), v)
					var s := w + (ruido.get_pixel(ox + x, oy + y).r - 0.5) * 0.55
					var alfa := smoothstep(0.44, 0.56, s)
					var col := tex.get_pixel(ox + x, oy + y)
					var sombra := 0.0
					if liq.is_empty():
						col = col.darkened((1.0 - smoothstep(0.5, 0.62, s)) * 0.18)    # borde del camino algo pisado
					else:
						col = col.lerp(liq["hondo"], smoothstep(0.6, 1.1, s) * 0.55)
						var espuma := clampf(1.0 - absf(s - 0.53) / 0.06, 0.0, 1.0)
						col = col.lerp(liq["borde"], espuma * 0.55)
						if liq["orilla"]:
							sombra = smoothstep(0.26, 0.48, s) * 0.45                  # orilla mojada y oscura
					var a := alfa + sombra * (1.0 - alfa)
					if a <= 0.0:
						continue
					var rgb := Color(col.r * alfa, col.g * alfa, col.b * alfa) + Color(0.05, 0.04, 0.03) * sombra * (1.0 - alfa)
					atlas.set_pixel(dx + x, dy + y, Color(rgb.r / a, rgb.g / a, rgb.b / a, a))


# Muro visto desde arriba; con frente, la parte de abajo es la cara vertical (más oscura).
func _pintar_bloque(atlas: Image, dest: Vector2i, arriba: Image, cara: Image, con_frente: bool) -> void:
	var corte := int(T * 0.3) if con_frente else T
	for y in T:
		for x in T:
			var c: Color
			if y < corte:
				c = arriba.get_pixel(x, y)
			else:
				var k := float(y - corte) / (T - corte)
				c = cara.get_pixel(x, y).darkened(0.15 + k * 0.35)
				if y < corte + 2:
					c = c.lightened(0.15)              # canto iluminado
			atlas.set_pixel(dest.x + x, dest.y + y, c)


# Fachada de casa: revoque, vigas de madera y una ventana con luz.
func _fachada() -> Image:
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	var r := FastNoiseLite.new()
	r.seed = 77
	r.frequency = 0.12
	for y in T:
		for x in T:
			var c := Color8(206, 190, 156).darkened(r.get_noise_2d(x, y) * 0.12 + 0.05)
			if x < 4 or x >= T - 4 or (y > 18 and y < 23):
				c = Color8(70, 46, 30).lightened(r.get_noise_2d(x * 3.0, y) * 0.1)
			if x >= 22 and x < 42 and y >= 30 and y < 52:
				c = Color8(255, 196, 110).darkened(float(y - 30) / 22.0 * 0.35)
				if x == 31 or x == 32 or y == 40:
					c = Color8(60, 40, 28)
			img.set_pixel(x, y, c)
	return img


# Textura sin costuras (se puede repetir). Si existe res://texturas/<nombre>.png, se usa esa.
func _textura(nombre: String, tam: int) -> Image:
	var ruta := "res://texturas/%s.png" % nombre
	if ResourceLoader.exists(ruta):
		var propia: Image = (Recursos.obtener(ruta, "zona") as Texture2D).get_image()
		propia.decompress()
		propia.convert(Image.FORMAT_RGBA8)
		propia.resize(tam, tam, Image.INTERPOLATE_LANCZOS)
		return propia
	var d: Dictionary = TEXTURAS[nombre]
	var sem := hash(nombre)
	var r1 := FastNoiseLite.new()
	r1.seed = sem
	r1.frequency = d["frec"]
	r1.fractal_octaves = 5
	var a := r1.get_seamless_image(tam, tam)
	var r2 := FastNoiseLite.new()
	r2.seed = sem + 1
	r2.frequency = d["frec"] * 6.0
	r2.fractal_octaves = 2
	var b := r2.get_seamless_image(tam, tam)
	var celdas: Image = null
	if d.has("celdas"):
		celdas = _voronoi(tam, maxi(6, int(1.0 / d["celdas"])), sem + 2)
	var grad := _gradiente(d["colores"])
	var rng := RandomNumberGenerator.new()
	rng.seed = sem
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	for y in tam:
		for x in tam:
			var c := grad.sample(a.get_pixel(x, y).r * 0.75 + b.get_pixel(x, y).r * 0.25)
			if celdas != null:
				var cel := celdas.get_pixel(x, y)
				var junta := clampf(1.0 - cel.g / 0.12, 0.0, 1.0)            # cerca del borde entre celdas
				if d.get("brillo_celdas", false):
					c = c.lightened(junta * 0.35)
				else:
					c = c.darkened((cel.r * 0.3 + junta * 0.55) * d.get("fuerza_celdas", 1.0))   # piedras con juntas
			if d.get("ladrillos", false):
				c = _ladrillo(c, x, y, tam)
			if d.get("tejas", false):
				c = _teja(c, x, y, tam)
			if d.has("motas") and rng.randf() < d["motas"][1]:
				c = c.lerp(d["motas"][0], 0.6)
			img.set_pixel(x, y, c)
	return img


# Celdas tipo piedra sin costuras: r = distancia al centro de la celda, g = distancia al borde.
func _voronoi(tam: int, celda: int, sem: int) -> Image:
	var n := maxi(1, roundi(float(tam) / celda))
	var paso := float(tam) / n
	var rng := RandomNumberGenerator.new()
	rng.seed = sem
	var puntos := PackedVector2Array()
	for j in n:
		for i in n:
			puntos.append(Vector2(i + rng.randf_range(0.15, 0.85), j + rng.randf_range(0.15, 0.85)) * paso)
	var img := Image.create(tam, tam, false, Image.FORMAT_RGB8)
	for y in tam:
		for x in tam:
			var gi := int(x / paso)
			var gj := int(y / paso)
			var d1 := 1e9
			var d2 := 1e9
			for oj in range(-1, 2):
				for oi in range(-1, 2):
					var ci := posmod(gi + oi, n)
					var cj := posmod(gj + oj, n)
					var q := puntos[cj * n + ci] + Vector2(gi + oi - ci, gj + oj - cj) * paso   # vecinos al otro lado
					var d := Vector2(x, y).distance_to(q)
					if d < d1:
						d2 = d1
						d1 = d
					elif d < d2:
						d2 = d
			img.set_pixel(x, y, Color(clampf(d1 / paso, 0.0, 1.0), clampf((d2 - d1) / paso, 0.0, 1.0), 0.0))
	return img


func _ladrillo(c: Color, x: int, y: int, tam: int) -> Color:
	var fila := floori(y / 16.0)
	var xx := (x + (fila % 2) * 16) % tam
	var col := floori(xx / 32.0)
	var lx := xx % 32
	var ly := y % 16
	if lx < 2 or ly < 2:
		return Color8(58, 54, 50)
	c = c.darkened(float(abs(hash(Vector2i(col, fila))) % 100) / 100.0 * 0.25)
	if ly < 4:
		c = c.lightened(0.12)
	elif ly > 13:
		c = c.darkened(0.15)
	return c


func _teja(c: Color, x: int, y: int, tam: int) -> Color:
	var fila := floori(y / 16.0)
	var xx := (x + (fila % 2) * 8) % tam
	var col := floori(xx / 16.0)
	var lx := xx % 16
	var ly := y % 16
	c = c.darkened(float(abs(hash(Vector2i(col, fila))) % 100) / 100.0 * 0.2)
	c = c.darkened(float(ly) / 16.0 * 0.35)
	if lx < 1:
		c = c.darkened(0.3)
	return c


func _gradiente(colores: Array) -> Gradient:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in colores.size():
		offs.append(float(i) / maxf(1.0, colores.size() - 1))
		cols.append(colores[i])
	g.offsets = offs
	g.colors = cols
	return g


# Generar las imágenes tarda un poco: se guardan en user:// y la próxima vez se cargan al momento.
func _cargar_cache(nombre: String, generar: Callable) -> Image:
	var ruta := "user://cache_zonas/%s_v%d.png" % [nombre, VERSION_CACHE]
	if FileAccess.file_exists(ruta):
		var img := Image.load_from_file(ruta)
		if img != null and not img.is_empty():
			return img
	var nueva: Image = generar.call()
	DirAccess.make_dir_recursive_absolute("user://cache_zonas")
	nueva.save_png(ruta)
	return nueva


# Si pones texturas propias en res://texturas, cambia el nombre de la caché para que se rehaga.
func _firma_texturas() -> String:
	var f := ""
	for k in ["suelo", "camino", "agua", "muro"]:
		var ruta := "res://texturas/%s.png" % estilo[k]
		if FileAccess.file_exists(ruta):
			f += str(FileAccess.get_modified_time(ruta) % 100000)
	if FileAccess.file_exists("res://texturas/tejado.png"):
		f += str(FileAccess.get_modified_time("res://texturas/tejado.png") % 100000)
	return "" if f == "" else "_" + f


# ================================================================= objetos

func _crear_objetos() -> void:
	_crear_hierba()
	_dibujar_puentes()
	sombras = Node2D.new()
	add_child(sombras)
	mundo_y = Node2D.new()
	mundo_y.y_sort_enabled = true
	add_child(mundo_y)
	for o in colocados:
		var sp_o := _poner_objeto(o["tipo"], o["pos"])
		if o["tipo"] == "cofre" and not _cofre_abierto(_id_cofre(o["pos"])):
			cofres.append([sp_o, _id_cofre(o["pos"]), false])
	altar = _poner_altar()
	if es_ciudad:
		_poner_npcs()
	_poner_detalles()
	_adornar_altar()
	_poner_hallazgos()


# El altar o monumento del final del camino. Una ciudad hecha a mano pone el suyo (ciudad_oakhaven.gd: el Árbol).
func _poner_altar() -> Node2D:
	return _poner_objeto("altar", meta * T)


# El orbe de luz que flota sobre el altar.
func _adornar_altar() -> void:
	var orbe := Sprite2D.new()
	orbe.texture = luz_tex
	orbe.material = mat_aditivo
	orbe.modulate = estilo["altar"]
	orbe.scale = Vector2(0.28, 0.28)
	orbe.position = Vector2(0, -100)
	altar.add_child(orbe)
	create_tween().set_loops().tween_property(orbe, "position:y", -112.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var luz := _nueva_luz(estilo["altar"], 1.2, 2.2)
	luz.position = Vector2(0, -100)
	altar.add_child(luz)


# Detalles de lore de este lugar (progreso.gd): una estela en las ruinas o junto a la plaza.
# El escenario cuenta la historia: al examinarla sale una frase corta y se apunta en el Diario.
func _poner_detalles() -> void:
	for d in load("res://progreso.gd").detalles_de(int(lugar["indice"])):
		var pos := _sitio_detalle(d["donde"])
		if pos.x < 0 or (es_ciudad and plaza.x < 0):
			pos = meta + Vector2(2.5, 1.5)               # sin ese rincón: junto al altar
		detalles.append([_poner_objeto("estela", pos * T), d])


# Dónde va un detalle (en casillas). Las mazmorras (garganta.gd) ponen los suyos en sitios fijos.
func _sitio_detalle(donde: String) -> Vector2:
	match donde:
		"plaza":
			return plaza + Vector2(3, -2)
		"plaza2":
			return plaza + Vector2(-3, 2)
	for l in lugares_interes:
		if l["tipo"] == donde:
			return l["pos"] + Vector2(1.4, 0.9)
	return Vector2(-1, -1)


# El brazalete de Kael brilla un instante al acercarse a un detalle que aún no ha visto. Nadie dice nada.
func _brazalete() -> void:
	var Progreso = load("res://progreso.gd")
	for dt in detalles:
		var id: String = dt[1]["id"]
		var dist: float = jugador.position.distance_to(dt[0].position)
		if dist > RADIO_BRAZALETE * 1.6:
			brillados.erase(id)
		elif dist < RADIO_BRAZALETE and not brillados.has(id) and not Progreso.visto(id):
			brillados[id] = true
			_brillo_brazalete()


# El brillo en la muñeca de Kael (también lo usa la grieta de Oakhaven: ciudad_oakhaven.gd).
func _brillo_brazalete() -> void:
	Sonido.efecto("brazalete")                   # un brillo que se oye, muy bajo (sonido.gd, T-083)
	var b := Sprite2D.new()
	b.texture = luz_tex
	b.material = mat_aditivo
	b.modulate = Color(1.0, 0.86, 0.42, 0.0)
	b.position = Vector2(-14, -44)               # muñeca izquierda de Kael
	b.scale = Vector2(0.04, 0.04)
	b.z_index = 5
	jugador.add_child(b)
	var t := create_tween()
	t.tween_property(b, "modulate:a", 1.0, 0.15)
	t.parallel().tween_property(b, "scale", Vector2(0.16, 0.16), 0.25)
	t.tween_property(b, "modulate:a", 0.0, 0.5)
	t.tween_callback(b.queue_free)


# Textura y material de la hierba, compartidos por la zona y el fondo del combate.
# La foto se carga tal cual la importa Godot (VRAM comprimida, con mipmaps); si no existe,
# se usan las 4 matas dibujadas por código.
func material_hierba() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = Shader.new()
	m.shader.code = SHADER_HIERBA
	if ResourceLoader.exists(TEXTURA_HIERBA):
		matas_tex = load(TEXTURA_HIERBA)
		m.set_shader_parameter("variantes", 1.0)
	else:
		matas_tex = ImageTexture.create_from_image(_cargar_cache("matas", _dibujar_matas))
		m.set_shader_parameter("variantes", 4.0)
		m.set_shader_parameter("corte_alfa", 0.3)
		m.set_shader_parameter("brillo", 1.0)
	return m


# Malla de una mata: un solo plano (2 triángulos). En 2D no hacen falta los planos en X:
# la cámara siempre mira de frente.
func malla_hierba() -> ArrayMesh:
	var malla := ArrayMesh.new()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(-28, -56), Vector2(28, -56), Vector2(28, 0), Vector2(-28, 0)])
	arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return malla


# Hierba alta por todo el prado (no en caminos, agua ni casas). Se reparte en trozos de
# TROZO_HIERBA píxeles, cada uno con su MultiMesh: Godot salta los trozos que quedan fuera de la
# cámara, así solo se dibuja la hierba que se ve (en 2D es lo que equivale al Visibility Range).
func _crear_hierba() -> void:
	if not estilo.has("hierba_alta"):
		return
	mat_hierba = material_hierba()
	var foto := ResourceLoader.exists(TEXTURA_HIERBA)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla + 21
	var claros := FastNoiseLite.new()
	claros.seed = semilla + 22
	claros.frequency = 0.004
	var paso := 30.0 if foto else 22.0           # cada foto es una mata grande: hacen falta menos
	var trozos := {}
	for gy in int(ALTO * T / paso):
		for gx in int(ANCHO * T / paso):
			var p := Vector2(gx + rng.randf(), gy + rng.randf()) * paso
			if not _hay_hierba(p) or claros.get_noise_2d(p.x, p.y) < -0.35 or rng.randf() > estilo["hierba_alta"]:
				continue
			var k := Vector2i(int(p.x / TROZO_HIERBA), int(p.y / TROZO_HIERBA))
			if not trozos.has(k):
				trozos[k] = []
			trozos[k].append(p)
	var malla := malla_hierba()
	var tono: Color = estilo["tono_hierba"]
	var claves := trozos.keys()
	claves.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))   # de arriba abajo
	for k in claves:
		var puntos: Array = trozos[k]
		puntos.sort_custom(func(a, b): return a.y < b.y)        # las de delante tapan a las de detrás
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_2D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = malla
		mm.instance_count = puntos.size()
		for i in puntos.size():
			var p: Vector2 = puntos[i]
			var s := rng.randf_range(0.6, 1.35)
			var ancho := s * rng.randf_range(0.85, 1.2)          # unas más anchas, otras más estrechas
			mm.set_instance_transform_2d(i, Transform2D(0.0, Vector2(ancho * (1.0 if rng.randf() < 0.5 else -1.0), s), 0.0, p))
			mm.set_instance_color(i, tono.darkened(rng.randf_range(0.0, 0.18)).lerp(Color(1.0, 0.95, 0.6), rng.randf_range(0.0, 0.15)))
			var variante := 0 if foto else (3 if rng.randf() < 0.12 else rng.randi_range(0, 2))
			mm.set_instance_custom_data(i, Color(variante, p.x, p.y, rng.randf() * TAU))
		var hierba := MultiMeshInstance2D.new()
		hierba.multimesh = mm
		hierba.texture = matas_tex
		hierba.material = mat_hierba
		hierba.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS   # usa los mipmaps: menos parpadeo y menos ancho de banda
		add_child(hierba)


func _hay_hierba(p: Vector2) -> bool:
	if mat_hierba == null:
		return false
	var c := Vector2i(int(p.x / T), int(p.y / T))
	if c.x < 0 or c.y < 0 or c.x >= ANCHO or c.y >= ALTO:
		return false
	var mu := muros[c.y * ANCHO + c.x]
	if mu == 2 or mu == 3 or (mu == 1 and not estilo.has("linde")):
		return false
	return _peso(camino_v, p / T) < 0.25 and _peso(agua_v, p / T) < 0.1


# Cuatro matas de hierba (la última con flores): hojas curvas, oscuras abajo y claras en la punta.
func _dibujar_matas() -> Image:
	var W := 48
	var img := Image.create(W * 4, W, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	var base_c := Color8(30, 80, 16)
	var punta_c := Color8(182, 236, 72)
	for v in 4:
		for b in 16:
			var bx := v * W + rng.randf_range(10, 38)
			var alto := rng.randf_range(22, 46)
			var curva := rng.randf_range(-14, 14)
			var ancho := rng.randf_range(2.2, 3.6)
			var tono := rng.randf_range(-0.12, 0.12)
			for i in int(alto):
				var t := i / alto
				var cx := bx + curva * t * t
				var w := ancho * (1.0 - t * 0.85)
				var y := W - 1 - i
				var c := base_c.lerp(punta_c, pow(t, 0.8)).lightened(tono)
				for x in range(int(cx - w) - 1, int(cx + w) + 2):
					if x < v * W or x >= (v + 1) * W:
						continue
					var a := clampf(w - absf(x - cx) + 0.5, 0.0, 1.0)
					if a <= 0.0:
						continue
					var cc := c.lightened(0.15) if x < cx else c.darkened(0.12)    # lado al sol / en sombra
					var antes := img.get_pixel(x, y)
					img.set_pixel(x, y, antes.lerp(Color(cc, 1.0), a) if antes.a > 0.0 else Color(cc, a))
		if v == 3:
			for f in 4:
				var centro := Vector2(v * W + rng.randf_range(9, 39), rng.randf_range(6, 22))
				for oy in range(-3, 4):
					for ox in range(-3, 4):
						var r := Vector2(ox, oy).length()
						if r > 3.2:
							continue
						var c := Color8(250, 214, 70) if r < 1.2 else Color8(250, 250, 240)
						img.set_pixel(int(centro.x) + ox, int(centro.y) + oy, c)
	return img


func _poner_objeto(tipo: String, pos: Vector2) -> Node2D:
	if tipo == "cofre" and _cofre_abierto(_id_cofre(pos)):
		var sp_c := _poner_objeto("cofre_abierto", pos)
		cofres.append([sp_c, _id_cofre(pos), true])
		return sp_c
	if DECORADO.has(tipo) and DECORADO[tipo].has("variantes"):   # una de sus fotos, fija para ese sitio
		tipo += "#%d" % (absi(hash(Vector2i(pos))) % int(DECORADO[tipo]["variantes"]) + 1)
	var d := _objeto(tipo)
	var ancho_sombra: float = d["sombra"]
	var s := Sprite2D.new()
	s.texture = sombra_tex
	s.position = pos + Vector2(ancho_sombra * 0.18, 2)
	s.scale = Vector2(ancho_sombra, ancho_sombra * 0.4) / 128.0
	sombras.add_child(s)
	var sp := Sprite2D.new()
	sp.texture = d["tex"]
	sp.centered = false
	sp.offset = -d["origen"]
	sp.scale = Vector2.ONE * d.get("escala", 1.0)
	sp.position = pos
	if d.get("mece", false):
		sp.material = mat_viento
	mundo_y.add_child(sp)
	# choque: óvalo en la base (más ancho que alto, como la copa vista desde arriba) que no se
	# puede atravesar; "choque" es su medio ancho en píxeles del mapa
	var radio: float = d["choque"] / d.get("escala", 1.0)   # dentro del sprite escalado
	if radio > 0.0:
		var poli := PackedVector2Array()
		for i in 12:
			poli.append(Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0) * 0.55) * radio)
		var cuerpo := StaticBody2D.new()
		var forma := CollisionShape2D.new()
		var ovalo := ConvexPolygonShape2D.new()
		ovalo.points = poli
		forma.shape = ovalo
		forma.position = Vector2(0, -radio * 0.2)                # un poco por encima del pie
		cuerpo.add_child(forma)
		sp.add_child(cuerpo)
		var occ := LightOccluder2D.new()
		occ.occluder = OccluderPolygon2D.new()
		occ.occluder.polygon = poli
		sp.add_child(occ)
	if d.has("luz"):
		var luz := _nueva_luz(d["luz"], d["energia"], 2.0)
		luz.position = d["luz_pos"]
		sp.add_child(luz)
		if d.get("fuego", false):
			luces_fuego.append([luz, d["energia"], randf() * TAU])
			var llama := _llamas(tipo == "farola")
			llama.position = d["luz_pos"] + Vector2(0, 6)
			sp.add_child(llama)
			var aviso := VisibleOnScreenEnabler2D.new()       # fuera de cámara la llama no se calcula
			aviso.rect = Rect2(d["luz_pos"] - Vector2(60, 80), Vector2(120, 120))
			sp.add_child(aviso)
			aviso.enable_node_path = aviso.get_path_to(llama)
	return sp


func _objeto(tipo: String) -> Dictionary:
	if texturas_obj.has(tipo):
		return texturas_obj[tipo]
	var base := tipo.get_slice("#", 0)
	if DECORADO.has(base) and "#" in tipo:            # variante: <imagen>_N.png
		var dv: Dictionary = DECORADO[base].duplicate()
		dv["imagen"] = dv["imagen"].get_basename() + "_" + tipo.get_slice("#", 1) + ".png"
		if ResourceLoader.exists(dv["imagen"]):
			return _objeto_foto(tipo, dv)
	if DECORADO.has(tipo) and ResourceLoader.exists(DECORADO[tipo]["imagen"]):   # foto de un modelo 3D
		return _objeto_foto(tipo, DECORADO[tipo].duplicate())
	if not OBJETOS.has(tipo):
		tipo = "arbusto"
	var d: Dictionary = OBJETOS[tipo].duplicate()
	var img := _cargar_cache("obj_" + tipo, _dibujar_objeto.bind(tipo))
	d["tex"] = ImageTexture.create_from_image(img)
	texturas_obj[tipo] = d
	return d


# Planta o roca hecha con la foto de un modelo 3D: los pies abajo en el centro y se mece con el viento.
func _objeto_foto(tipo: String, dd: Dictionary) -> Dictionary:
	var tex: Texture2D = Recursos.obtener(dd["imagen"], "zona")   # se libera al volver al mapa del mundo
	dd["tex"] = tex
	dd["origen"] = Vector2(tex.get_width() * 0.5, tex.get_height() - 3)
	dd["sombra"] = tex.get_width() * dd["escala"] * 0.85
	dd["mece"] = not tipo.begins_with("q_roca")
	texturas_obj[tipo] = dd
	return dd


func _dibujar_objeto(tipo: String) -> Image:
	var tam: Vector2i = OBJETOS[tipo]["tam"]
	var img := Image.create(tam.x, tam.y, false, Image.FORMAT_RGBA8)
	var verdes := [Color8(14, 36, 18), Color8(30, 66, 28), Color8(58, 104, 40), Color8(110, 150, 62), Color8(170, 196, 96)]
	match tipo:
		"arbol":
			_pintar_tronco(img, Vector2(96, 226), 116, 24, Color8(92, 64, 42))
			_pintar_copa(img, Vector2(96, 92), 84, 9, verdes, 31, 1.0, 0.18, false)
		"arbusto":
			_pintar_copa(img, Vector2(56, 50), 46, 6, verdes, 41, 0.8, 0.22, false)
		"arbusto_seco":
			_pintar_ramas(img, Vector2(48, 76))
		"pino":
			_pintar_pino(img, false)
		"pino_nevado":
			_pintar_pino(img, true)
		"cristal":
			_pintar_cristales(img)
		"brasero":
			_pintar_brasero(img)
		"farola":
			_pintar_farola(img)
		"altar":
			_pintar_altar(img)
		"columna":
			_pintar_columna(img)
		"muro_ruina":
			_pintar_muro_ruina(img)
		"tronco":
			_pintar_tronco_suelo(img)
		"cofre":
			_pintar_cofre(img, false)
		"cofre_abierto":
			_pintar_cofre(img, true)
		"estela":
			_pintar_estela(img)
		"guardado":
			_pintar_guardado(img)
		"palanca", "palanca_bajada":
			_pintar_palanca(img, tipo == "palanca_bajada")
		"ascensor":
			_pintar_ascensor(img)
		"puerta", "puerta_abierta":
			_pintar_puerta(img, tipo == "puerta_abierta")
		_:
			_pintar_copa(img, Vector2(52, 46), 46, 3, ROCAS[tipo], 53, 0.62, 0.05, tipo == "roca_nevada")
	return img


# Copa de hojas (o roca) con volumen: varias bolas iluminadas desde arriba a la izquierda.
func _pintar_copa(img: Image, centro: Vector2, radio: float, bolas: int, colores: Array, sem: int,
		aspecto: float, frec: float, nevada: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = sem
	var cs: Array[Vector2] = [centro]
	var rs: Array[float] = [radio * 0.62]
	for i in bolas:
		var ang := TAU * i / bolas + rng.randf_range(-0.3, 0.3)
		cs.append(centro + Vector2(cos(ang), sin(ang) * aspecto) * radio * rng.randf_range(0.35, 0.55))
		rs.append(radio * rng.randf_range(0.36, 0.48))
	var hojas := FastNoiseLite.new()
	hojas.seed = sem
	hojas.frequency = frec
	var grad := _gradiente(colores)
	var luz := Vector3(-0.55, -0.7, 0.5).normalized()
	var x0 := maxi(0, int(centro.x - radio * 1.15))
	var x1 := mini(img.get_width(), int(centro.x + radio * 1.15))
	var y0 := maxi(0, int(centro.y - radio * aspecto * 1.15))
	var y1 := mini(img.get_height(), int(centro.y + radio * aspecto * 1.15))
	for y in range(y0, y1):
		for x in range(x0, x1):
			var n := hojas.get_noise_2d(x, y)
			var mejor := -9.0
			var normal := Vector3.ZERO
			var cobertura := 0.0
			for i in cs.size():
				var r: float = rs[i] * (1.0 + n * 0.12)
				var q := Vector2(x - cs[i].x, (y - cs[i].y) / aspecto) / r
				var l2 := q.length_squared()
				if l2 >= 1.0:
					continue
				var h := sqrt(1.0 - l2)
				var alto := h + (centro.y - cs[i].y) / radio * 0.3        # las bolas de arriba tapan
				if alto > mejor:
					mejor = alto
					normal = Vector3(q.x, q.y, h)
				cobertura = maxf(cobertura, clampf((1.0 - sqrt(l2)) * r * 0.7, 0.0, 1.0))
			if cobertura <= 0.0:
				continue
			var dif := clampf(normal.normalized().dot(luz), 0.0, 1.0)
			var v := dif * 0.8 + n * 0.25 - (y - centro.y) / (radio * aspecto) * 0.12 + 0.05
			var c := grad.sample(clampf(v, 0.0, 1.0))
			if nevada and normal.y < -0.25 + n * 0.2:
				c = Color8(236, 242, 250).darkened(0.15 - dif * 0.15)
			var fondo := img.get_pixel(x, y)
			if fondo.a > 0.0:
				img.set_pixel(x, y, fondo.lerp(Color(c, 1.0), cobertura))
			else:
				img.set_pixel(x, y, Color(c, cobertura))


func _pintar_tronco(img: Image, base: Vector2, alto: float, ancho: float, color: Color) -> void:
	var r := FastNoiseLite.new()
	r.seed = 9
	r.frequency = 0.08
	for y in range(int(base.y - alto), int(base.y)):
		var t := (base.y - y) / alto
		var w := ancho * (1.0 - t * 0.35) + pow(1.0 - t, 6.0) * ancho * 0.9      # raíces abajo
		var izq := base.x - w * 0.5
		for x in range(int(izq), int(izq + w) + 1):
			var u := clampf((x - izq) / w, 0.0, 1.0)
			var veta := r.get_noise_2d(x * 3.0, y * 0.3)
			var c := color.lightened(0.3 * (1.0 - u)).darkened(0.45 * u + veta * 0.2)
			img.set_pixel(x, y, Color(c, clampf(minf(x - izq, izq + w - x), 0.0, 1.0)))


func _pintar_pino(img: Image, nevado: bool) -> void:
	_pintar_tronco(img, Vector2(64, 214), 50, 14, Color8(80, 56, 40))
	var r := FastNoiseLite.new()
	r.seed = 5
	r.frequency = 0.25
	var grad := _gradiente([Color8(10, 30, 22), Color8(22, 56, 36), Color8(40, 86, 50), Color8(80, 124, 70)])
	for k in 4:
		var base_y := 186.0 - k * 40.0
		var alto := 78.0 - k * 6.0
		var media := 58.0 - k * 11.0
		for y in range(int(base_y - alto), int(base_y)):
			var t := (base_y - y) / alto
			var w := media * (1.0 - t)
			for x in range(int(64 - w) - 2, int(64 + w) + 3):
				var n := r.get_noise_2d(x, y)
				var borde := w * (1.0 + n * 0.25) - absf(x - 64.0)
				if borde <= 0.0:
					continue
				var u := (x - 64.0) / maxf(w, 1.0)
				var v := 0.6 - u * 0.35 + n * 0.3 - (1.0 - t) * 0.25
				var c := grad.sample(clampf(v, 0.0, 1.0))
				if nevado and n + t * 0.9 - (u + 1.0) * 0.25 > 0.3:
					c = Color8(230, 238, 248).lerp(Color8(170, 186, 214), clampf(u * 0.5 + 0.5, 0.0, 1.0))
				img.set_pixel(x, y, Color(c, clampf(borde, 0.0, 1.0)))


func _pintar_ramas(img: Image, base: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	for i in 7:
		var ang := -PI * 0.5 + rng.randf_range(-1.1, 1.1)
		var fin := base + Vector2(cos(ang), sin(ang)) * rng.randf_range(34, 62)
		_linea(img, base, fin, 2.5, Color8(96, 72, 50))
		for j in 2:
			var desde := base.lerp(fin, rng.randf_range(0.4, 0.8))
			var a2 := ang + rng.randf_range(-0.8, 0.8)
			_linea(img, desde, desde + Vector2(cos(a2), sin(a2)) * rng.randf_range(10, 22), 1.5, Color8(120, 94, 66))


func _linea(img: Image, a: Vector2, b: Vector2, grosor: float, color: Color) -> void:
	var pasos_l := int(a.distance_to(b)) + 1
	for i in pasos_l:
		var p := a.lerp(b, float(i) / pasos_l)
		for oy in range(-2, 3):
			for ox in range(-2, 3):
				var q := Vector2i(int(p.x) + ox, int(p.y) + oy)
				if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height():
					continue
				var k := clampf(grosor * 0.5 - Vector2(q).distance_to(p) + 0.5, 0.0, 1.0)
				if k > img.get_pixelv(q).a:
					img.set_pixelv(q, Color(color.darkened(float(ox) * 0.08), k))


func _pintar_cristales(img: Image) -> void:
	var formas := [[40.0, 100.0, 14.0, 0.0], [24.0, 64.0, 10.0, -0.35], [56.0, 70.0, 10.0, 0.3], [34.0, 44.0, 7.0, -0.6]]
	for f in formas:
		var ancho: float = f[2]
		var largo: float = f[1]
		var base := Vector2(f[0], 104)
		var dir := Vector2(sin(f[3]), -cos(f[3]))
		var lado := dir.orthogonal() * ancho
		var punta := base + dir * largo
		var poli := PackedVector2Array([base - lado, base + lado, punta - dir * 14.0 + lado * 0.8, punta, punta - dir * 14.0 - lado * 0.8])
		for y in img.get_height():
			for x in img.get_width():
				var p := Vector2(x, y)
				if not Geometry2D.is_point_in_polygon(p, poli):
					continue
				var u := (p - base).dot(lado.normalized()) / ancho             # -1 izquierda, 1 derecha
				var t := (p - base).dot(dir) / largo
				var c := Color8(120, 60, 190).lerp(Color8(230, 190, 255), clampf(0.5 - u * 0.45 + t * 0.4, 0.0, 1.0))
				img.set_pixel(x, y, c)


func _pintar_brasero(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := Color(0, 0, 0, 0)
			var dx := (x - 28.0) / 24.0
			if y >= 16 and y < 34 and absf(dx) < 1.0 - (y - 16) / 40.0:   # cuenco
				c = Color8(46, 40, 38).lightened(0.25 * (1.0 - dx) * 0.5)
			if y >= 14 and y < 20 and absf(dx) < 1.0:                      # brasas
				c = Color8(255, 150, 50).lerp(Color8(120, 20, 0), absf(dx))
			if y >= 34 and y < 60 and (absf(x - 18) < 2 or absf(x - 38) < 2 or absf(x - 28) < 2):
				c = Color8(40, 36, 34)
			if c.a > 0.0:
				img.set_pixel(x, y, c)


func _pintar_farola(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := Color(0, 0, 0, 0)
			if x >= 18 and x < 23 and y >= 34:
				c = Color8(36, 34, 40).lightened(0.3 if x < 20 else 0.0)
			if y >= 138 and x >= 12 and x < 29:
				c = Color8(40, 38, 44)
			if y >= 10 and y < 36 and x >= 10 and x < 31:
				c = Color8(36, 34, 40)
				if y >= 14 and y < 32 and x >= 13 and x < 28:
					c = Color8(255, 222, 150).darkened(float(y - 14) / 18.0 * 0.3)
			if y >= 4 and y < 10 and absf(x - 20.5) < 12.0 - (10 - y) * 1.6:
				c = Color8(30, 28, 34)
			if c.a > 0.0:
				img.set_pixel(x, y, c)


func _pintar_altar(img: Image) -> void:
	var r := FastNoiseLite.new()
	r.seed = 13
	r.frequency = 0.15
	for y in img.get_height():
		for x in img.get_width():
			var dentro := (y >= 96 and y < 112 and x >= 10 and x < 102) or (y >= 60 and y < 96 and x >= 28 and x < 84) \
				or (y >= 50 and y < 60 and x >= 20 and x < 92)
			if not dentro:
				continue
			var c := Color8(150, 144, 134).darkened(r.get_noise_2d(x, y) * 0.2 + float(x - 10) / 92.0 * 0.35)
			if y == 50 or y == 51 or y == 96 or y == 97:
				c = c.lightened(0.3)
			img.set_pixel(x, y, c)


# Columna antigua rota: fuste redondeado con estrías, grietas, musgo y la parte de arriba quebrada.
func _pintar_columna(img: Image) -> void:
	var r := FastNoiseLite.new()
	r.seed = 21
	r.frequency = 0.12
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		var rotura := 22 + int((r.get_noise_1d(y * 0.0 + 3.0) + 1.0) * 6)
		for x in w:
			var u := (x - w * 0.5) / (w * 0.36)
			var base := y > h - 18
			var cap := absf(u) <= 1.25 and y > h - 18
			if absf(u) > 1.0 and not cap:
				continue
			if y < rotura + r.get_noise_1d(x * 1.0) * 14.0:     # parte de arriba rota
				continue
			var luz := 0.62 - u * 0.32
			var c := Color8(176, 168, 150) * (0.55 + luz * 0.55)
			if not base and int(x * 1.0) % 9 == 0:
				c = c.darkened(0.15)                           # estrías
			var n := r.get_noise_2d(x * 2.0, y * 2.0)
			c = c.darkened(maxf(0.0, n) * 0.25)
			if r.get_noise_2d(x * 0.7 + 50.0, y * 0.5) > 0.35:
				c = c.lerp(Color8(70, 100, 50), 0.55)           # musgo
			img.set_pixel(x, y, Color(c, 1.0))


# Estela de piedra con el símbolo del brazalete grabado: un anillo dorado partido por una grieta.
func _pintar_estela(img: Image) -> void:
	var r := FastNoiseLite.new()
	r.seed = 47
	r.frequency = 0.1
	var w := img.get_width()
	var h := img.get_height()
	var centro := Vector2(w * 0.5, 58)
	for y in h:
		for x in w:
			var u := (x - w * 0.5) / 24.0
			if absf(u) > 1.0 or y > h - 6:
				continue
			if y < 34 and Vector2(x, y).distance_to(Vector2(w * 0.5, 34)) > 24.0:   # remate redondeado
				continue
			if y < 14:
				continue
			var c := Color8(150, 144, 132) * (0.6 + (0.62 - u * 0.32) * 0.55)     # luz desde la izquierda
			c = c.darkened(maxf(0.0, r.get_noise_2d(x * 2.0, y * 2.0)) * 0.3)
			if r.get_noise_2d(x * 0.6 + 80.0, y * 0.5) > 0.4:
				c = c.lerp(Color8(70, 100, 50), 0.5)                               # musgo
			var d := Vector2(x, y).distance_to(centro)
			var ang := rad_to_deg((Vector2(x, y) - centro).angle())
			if absf(d - 13.0) < 2.2 and not (ang > -70.0 and ang < -40.0):         # anillo con un hueco
				c = Color8(232, 196, 106).lerp(Color8(255, 236, 170), clampf(-u, 0.0, 1.0) * 0.6)
			var grieta := absf((x - centro.x) * 0.9 - (y - centro.y) + 2.0) < 1.0 and d < 22.0 and x > centro.x - 4
			if grieta:
				c = Color8(40, 34, 30)
			img.set_pixel(x, y, Color(c, 1.0))
	for x in range(6, w - 6):                                                     # basa
		for y in range(h - 12, h - 4):
			img.set_pixel(x, y, Color8(110, 104, 96).darkened(float(y - (h - 12)) / 8.0 * 0.3))


# ---------------------------------------------------------------- piezas de mazmorra (garganta.gd)

func _px_rect(img: Image, r: Rect2i, c: Color) -> void:
	for y in range(maxi(0, r.position.y), mini(img.get_height(), r.end.y)):
		for x in range(maxi(0, r.position.x), mini(img.get_width(), r.end.x)):
			img.set_pixel(x, y, c)


func _px_linea(img: Image, a: Vector2, b: Vector2, grosor: float, c: Color) -> void:
	var n := int(a.distance_to(b)) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		for oy in range(-int(grosor), int(grosor) + 1):
			for ox in range(-int(grosor), int(grosor) + 1):
				var q := Vector2i(int(p.x) + ox, int(p.y) + oy)
				if Vector2(ox, oy).length() <= grosor and Rect2i(Vector2i.ZERO, img.get_size()).has_point(q):
					img.set_pixelv(q, c)


func _px_disco(img: Image, centro: Vector2, r: float, c: Color) -> void:
	for y in range(int(centro.y - r), int(centro.y + r) + 1):
		for x in range(int(centro.x - r), int(centro.x + r) + 1):
			if Vector2(x, y).distance_to(centro) <= r and Rect2i(Vector2i.ZERO, img.get_size()).has_point(Vector2i(x, y)):
				img.set_pixel(x, y, c)


# Anillo dorado partido (el símbolo del brazalete).
func _px_anillo(img: Image, centro: Vector2, r: float) -> void:
	for y in range(int(centro.y - r - 3), int(centro.y + r + 4)):
		for x in range(int(centro.x - r - 3), int(centro.x + r + 4)):
			var d := Vector2(x, y).distance_to(centro)
			var ang := rad_to_deg((Vector2(x, y) - centro).angle())
			if absf(d - r) < 2.2 and not (ang > -70.0 and ang < -40.0) and Rect2i(Vector2i.ZERO, img.get_size()).has_point(Vector2i(x, y)):
				img.set_pixel(x, y, Color8(232, 196, 106))


# Punto de guardado: cristal verde sobre una basa de piedra.
func _pintar_guardado(img: Image) -> void:
	var w := img.get_width()
	_px_rect(img, Rect2i(10, 92, w - 20, 12), Color8(104, 98, 90))
	_px_rect(img, Rect2i(14, 88, w - 28, 6), Color8(132, 126, 116))
	var c := Vector2(w * 0.5, 50)
	for y in range(6, 90):
		for x in w:
			var u := absf(x - c.x) / 18.0 + absf(y - c.y) / 42.0
			if u < 1.0:
				var luz := clampf(0.5 - (x - c.x) / 36.0 + (c.y - y) / 90.0, 0.0, 1.0)
				img.set_pixel(x, y, Color8(40, 140, 80).lerp(Color8(200, 255, 210), luz * 0.8 + (1.0 - u) * 0.2))


# Palanca de engranajes con el símbolo del anillo: arriba o bajada.
func _pintar_palanca(img: Image, bajada: bool) -> void:
	var w := img.get_width()
	_px_rect(img, Rect2i(8, 58, w - 16, 32), Color8(96, 92, 86))
	_px_rect(img, Rect2i(8, 58, w - 16, 5), Color8(140, 134, 124))
	_px_anillo(img, Vector2(w * 0.5, 76), 8.0)
	var base := Vector2(w * 0.5, 60)
	var punta := base + (Vector2(20, -6) if bajada else Vector2(-14, -46))
	_px_linea(img, base, punta, 3.0, Color8(70, 52, 36))
	_px_disco(img, punta, 6.0, Color8(170, 60, 40) if not bajada else Color8(120, 120, 120))


# Ascensor de madera: dos postes, una viga con polea, cuerdas y la plataforma.
func _pintar_ascensor(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var madera := Color8(110, 76, 46)
	_px_rect(img, Rect2i(8, 8, 10, h - 12), madera)
	_px_rect(img, Rect2i(w - 18, 8, 10, h - 12), madera)
	_px_rect(img, Rect2i(4, 6, w - 8, 10), madera.lightened(0.15))
	_px_disco(img, Vector2(w * 0.5, 12), 9.0, Color8(80, 60, 44))
	for x in [30, w - 30]:
		_px_linea(img, Vector2(x, 16), Vector2(x, h - 26), 1.0, Color8(190, 170, 130))
	_px_rect(img, Rect2i(14, h - 28, w - 28, 12), madera.darkened(0.1))
	for i in 6:
		_px_rect(img, Rect2i(16 + i * 14, h - 27, 1, 10), madera.darkened(0.4))


# Puerta tallada en la roca con el sello (cerrada) o solo el marco (abierta).
func _pintar_puerta(img: Image, abierta: bool) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var piedra := Color8(116, 110, 102)
	for y in h:
		for x in w:
			var dentro_arco := y > 40 or Vector2(x, y).distance_to(Vector2(w * 0.5, 40)) < w * 0.5
			if not dentro_arco:
				continue
			var marco := x < 18 or x > w - 19 or (y < 52 and Vector2(x, y).distance_to(Vector2(w * 0.5, 40)) > w * 0.5 - 18)
			if marco:
				img.set_pixel(x, y, piedra.darkened(0.15 + 0.2 * float(x > w * 0.5)))
			elif not abierta:
				var c := piedra.lerp(Color8(80, 76, 70), float(y) / h * 0.5)
				if x == int(w * 0.5):
					c = c.darkened(0.4)                       # junta de las dos hojas
				img.set_pixel(x, y, c)
	if not abierta:
		_px_disco(img, Vector2(w * 0.5, 96), 24.0, Color8(70, 64, 58))
		_px_anillo(img, Vector2(w * 0.5, 96), 16.0)
		for i in 3:                                          # marcas de garras
			_px_linea(img, Vector2(36 + i * 8, 140), Vector2(26 + i * 8, 176), 1.0, Color8(60, 56, 50))


# Trozo de muro de piedra derruido.
func _pintar_muro_ruina(img: Image) -> void:
	var r := FastNoiseLite.new()
	r.seed = 33
	r.frequency = 0.08
	var w := img.get_width()
	var h := img.get_height()
	for x in w:
		var alto := 28 + (r.get_noise_1d(x * 1.0) + 1.0) * 22.0
		for y in range(int(h - alto), h - 4):
			var fila := int((h - y) / 12.0)
			var col := int((x + (fila % 2) * 10) / 20.0)
			var junta := (h - y) % 12 < 2 or (x + (fila % 2) * 10) % 20 < 2
			var c := Color8(150, 142, 128).darkened(float(abs(hash(Vector2i(col, fila))) % 100) / 100.0 * 0.25)
			if junta:
				c = Color8(70, 66, 60)
			if y < h - alto + 4:
				c = c.lightened(0.18)                          # canto de arriba al sol
			if r.get_noise_2d(x * 0.6, y * 0.6 + 80.0) > 0.4:
				c = c.lerp(Color8(70, 100, 50), 0.5)
			c = c.darkened(float(x) / w * 0.25)
			img.set_pixel(x, y, c)


# Tronco caído para sentarse junto a la hoguera.
func _pintar_tronco_suelo(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var v := (y - h * 0.55) / (h * 0.36)
			if absf(v) > 1.0 or x < 6 or x > w - 6:
				continue
			var c := Color8(112, 78, 50).lightened(0.25 * (1.0 - v)).darkened(0.35 * maxf(0.0, v))
			if (x * 7 + y * 3) % 23 == 0:
				c = c.darkened(0.25)
			if x < 12 or x > w - 12:
				c = Color8(176, 140, 96).darkened(absf(v) * 0.3)        # corte del tronco con sus anillos
			img.set_pixel(x, y, c)


# Cofre de madera con refuerzos dorados (cerrado o abierto con monedas dentro).
func _pintar_cofre(img: Image, abierto: bool) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var y0 := h - 40                                   # parte de abajo del cofre
	for y in range(y0, h - 4):
		for x in range(6, w - 6):
			var c := Color8(130, 80, 40).darkened(float(y - y0) / 36.0 * 0.35)
			if x < 10 or x > w - 11 or y > h - 8 or (x > w * 0.5 - 3 and x < w * 0.5 + 3):
				c = Color8(220, 175, 60)                  # refuerzos dorados
			if (y - y0) % 9 == 0:
				c = c.darkened(0.25)                      # tablas
			img.set_pixel(x, y, c)
	if abierto:                                        # tapa abierta hacia atrás y monedas
		for y in range(y0 - 26, y0):
			for x in range(8, w - 8):
				img.set_pixel(x, y, Color8(110, 66, 34).darkened(float(y0 - y) / 26.0 * 0.4))
		for i in 18:
			var p := Vector2i(12 + (i * 7) % (w - 24), y0 + 2 + (i * 5) % 6)
			for oy in range(-2, 3):
				for ox in range(-2, 3):
					if ox * ox + oy * oy <= 5:
						img.set_pixel(p.x + ox, p.y + oy, Color8(255, 215, 80).darkened(0.1 * (oy + 2) / 4.0))
	else:                                              # tapa curva cerrada y cerradura
		for y in range(y0 - 14, y0):
			var k := float(y0 - y) / 14.0
			for x in range(6, w - 6):
				var u := (x - w * 0.5) / (w * 0.5 - 6)
				if k > sqrt(maxf(0.0, 1.0 - u * u * 0.6)):
					continue
				var c := Color8(150, 96, 50).lightened(0.25 * k)
				if x < 10 or x > w - 11 or (x > w * 0.5 - 3 and x < w * 0.5 + 3):
					c = Color8(235, 190, 70)
				img.set_pixel(x, y, c)
		for y in range(y0 - 2, y0 + 8):
			for x in range(int(w * 0.5) - 4, int(w * 0.5) + 4):
				img.set_pixel(x, y, Color8(60, 40, 20) if y > y0 + 1 and absi(x - int(w * 0.5)) < 2 else Color8(240, 200, 80))


# Puentes de tablas sobre el río (de piedra si el río es de lava o veneno).
func _dibujar_puentes() -> void:
	var nodo := Node2D.new()
	add_child(nodo)
	var piedra: bool = estilo["agua"] in ["lava", "veneno"]
	for pu in puentes:
		var centro: Vector2 = pu[0]
		var dir: Vector2 = pu[1]
		var largo: float = pu[2]
		var lado := dir.orthogonal()
		var ancho := T * 1.1
		var n := int(largo / 16.0)
		var sombra := Polygon2D.new()                       # sombra sobre el agua
		sombra.polygon = PackedVector2Array([centro - dir * largo * 0.5 + lado * ancho + Vector2(8, 10),
			centro + dir * largo * 0.5 + lado * ancho + Vector2(8, 10), centro + dir * largo * 0.5 - lado * ancho + Vector2(8, 10),
			centro - dir * largo * 0.5 - lado * ancho + Vector2(8, 10)])
		sombra.color = Color(0, 0, 0, 0.35)
		nodo.add_child(sombra)
		for i in n:                                         # tablas una a una
			var a := centro - dir * largo * 0.5 + dir * (i * 16.0)
			var tabla := Polygon2D.new()
			tabla.polygon = PackedVector2Array([a + lado * ancho, a + dir * 14.0 + lado * ancho, a + dir * 14.0 - lado * ancho, a - lado * ancho])
			var col := Color8(150, 146, 140) if piedra else Color8(132, 92, 56)
			tabla.color = col.darkened(float(abs(hash(i + int(centro.x)) % 100)) / 100.0 * 0.2)
			nodo.add_child(tabla)
		for s in [-1.0, 1.0]:                               # barandillas
			var bar := Line2D.new()
			bar.points = PackedVector2Array([centro - dir * largo * 0.5 + lado * ancho * s, centro + dir * largo * 0.5 + lado * ancho * s])
			bar.width = 7.0
			bar.default_color = Color8(110, 106, 100) if piedra else Color8(92, 60, 34)
			nodo.add_child(bar)


# ---------------------------------------------------------------- cofres

func _id_cofre(pos: Vector2) -> String:
	return "%d_%d_%d" % [int(lugar["indice"]), int(pos.x), int(pos.y)]


func _cofre_abierto(id: String) -> bool:
	return Engine.get_meta("cofres_abiertos", {}).has(id)


# Abre el cofre: monedas, pociones o éter (cada cofre solo se abre una vez en toda la partida).
func _abrir_cofre(c: Array) -> void:
	if Hallazgos.es_hallazgo(str(c[1])):                   # un cofre de hallazgo: su tomo, arma o accesorio
		_abrir_hallazgo(c)
		return
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	abiertos[c[1]] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	c[2] = true
	Sonido.efecto("cofre")                                 # la tapa y, después, el premio (sonido.gd)
	Sonido.efecto("tesoro", {"retraso": 0.3})
	var d := _objeto("cofre_abierto")
	var s: Sprite2D = c[0]
	s.texture = d["tex"]
	s.offset = -d["origen"]
	var inv = load("res://inventario.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(c[1])
	var premio := ""
	match rng.randi() % 4:
		0, 1:
			var oro := rng.randi_range(40, 120)
			inv.ganar_oro(oro)
			premio = "%d monedas" % oro
		2:
			inv.agregar_objeto("Poción", 2)
			premio = "2 Pociones"
		3:
			inv.agregar_objeto("Éter", 1)
			premio = "1 Éter"
	_mostrar_aviso("¡Has encontrado %s!" % premio)
	_poner_oro()
	_comentar_luego("cofre", 1.2)                          # alguien del grupo lo comenta, tras el premio
	var brillo := Sprite2D.new()                           # destello dorado
	brillo.texture = luz_tex
	brillo.material = mat_aditivo
	brillo.modulate = Color(1.0, 0.85, 0.3, 0.9)
	brillo.position = s.position + Vector2(0, -30)
	brillo.scale = Vector2(0.2, 0.2)
	add_child(brillo)
	var t := create_tween()
	t.tween_property(brillo, "scale", Vector2(0.9, 0.9), 0.4)
	t.parallel().tween_property(brillo, "modulate:a", 0.0, 0.6)
	t.tween_callback(brillo.queue_free)


# ================================================================= jugador

func _crear_jugador() -> void:
	jugador = CharacterBody2D.new()
	jugador.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	jugador.position = Vector2(salida_x, ALTO - 2.5) * T
	if Engine.get_meta("pos_zona_ok", false) and Engine.get_meta("pos_zona_lugar", -1) == lugar["indice"]:
		jugador.position = Engine.get_meta("pos_zona")
	for a in OS.get_cmdline_user_args():          # pruebas: godot ... -- pos=20,10 (en casillas)
		if a.begins_with("pos="):
			var xy := a.substr(4).split(",")
			jugador.position = Vector2(float(xy[0]), float(xy[1])) * T
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 14.0
	forma.shape = circulo
	jugador.add_child(forma)
	mundo_y.add_child(jugador)

	var s := Sprite2D.new()
	s.texture = sombra_tex
	s.scale = Vector2(56, 20) / 128.0
	jugador.add_child(s)
	sprite = load("res://muneco.gd").new()       # corre en 4 direcciones y respira quieto
	jugador.add_child(sprite)
	if matas_tex != null:
		hierba_pies = Sprite2D.new()
		hierba_pies.texture = matas_tex
		hierba_pies.centered = false
		hierba_pies.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var tw: float = matas_tex.get_width()
		var th: float = matas_tex.get_height()
		if not ResourceLoader.exists(TEXTURA_HIERBA):   # matas dibujadas: se usa la segunda de las 4
			hierba_pies.region_enabled = true
			hierba_pies.region_rect = Rect2(48, 0, 48, 48)
			tw = 48.0
			th = 48.0
		hierba_pies.offset = Vector2(-tw * 0.5, -th)
		hierba_pies.position = Vector2(0, 8)
		hierba_pies.scale = Vector2(82.0 / tw, 34.0 / th)
		hierba_pies.modulate = estilo["tono_hierba"]
		hierba_pies.material = mat_viento
		jugador.add_child(hierba_pies)
		hierba_pies.visible = _hay_hierba(jugador.position)
	RenderingServer.global_shader_parameter_set("jugador_pos", jugador.position)

	camara = Camera2D.new()
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = ANCHO * T
	camara.limit_bottom = ALTO * T
	camara.position_smoothing_enabled = true
	camara.position_smoothing_speed = 7.0
	jugador.add_child(camara)
	camara.make_current()
	camara.reset_smoothing()


# ================================================================= luz y clima

func _crear_recursos() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	luz_tex = GradientTexture2D.new()
	luz_tex.gradient = g
	luz_tex.fill = GradientTexture2D.FILL_RADIAL
	luz_tex.fill_from = Vector2(0.5, 0.5)
	luz_tex.fill_to = Vector2(1.0, 0.5)
	luz_tex.width = 256
	luz_tex.height = 256
	var gs := Gradient.new()
	gs.offsets = PackedFloat32Array([0.0, 1.0])
	gs.colors = PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0)])
	sombra_tex = GradientTexture2D.new()
	sombra_tex.gradient = gs
	sombra_tex.fill = GradientTexture2D.FILL_RADIAL
	sombra_tex.fill_from = Vector2(0.5, 0.5)
	sombra_tex.fill_to = Vector2(1.0, 0.5)
	sombra_tex.width = 128
	sombra_tex.height = 128
	mat_aditivo = CanvasItemMaterial.new()
	mat_aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat_viento = ShaderMaterial.new()
	mat_viento.shader = Shader.new()
	mat_viento.shader.code = SHADER_VIENTO


func _nueva_luz(color: Color, energia: float, escala: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = luz_tex
	l.color = color
	l.energy = energia
	l.texture_scale = escala
	return l


# Luz ambiente (más oscura en bosques, yermo y ceniza), luz del jugador con sombras,
# luz bajo la lava y rayos de sol entre los árboles.
func _crear_iluminacion() -> void:
	var ambiente := CanvasModulate.new()
	ambiente.color = estilo["ambiente"]
	add_child(ambiente)
	if estilo["luz"] > 0.0:
		luz_jugador = _nueva_luz(Color(1.0, 0.86, 0.64), estilo["luz"], 3.2)
		luz_jugador.position = Vector2(0, -40)
		luz_jugador.shadow_enabled = not es_ciudad      # en la ciudad las casas harían sombras enormes
		luz_jugador.shadow_filter = Light2D.SHADOW_FILTER_PCF13
		luz_jugador.shadow_filter_smooth = 6.0
		luz_jugador.shadow_color = Color(0, 0, 0, 0.35)
		jugador.add_child(luz_jugador)
	if estilo["agua"] in ["lava", "veneno"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla + 9
		var puestas := 0
		for intento in 300:
			var p := Vector2(rng.randi_range(1, ANCHO - 1), rng.randi_range(1, ALTO - 1))
			if _peso(agua_v, p) > 0.9 and puestas < 8:
				var l := _nueva_luz(Color(1.0, 0.45, 0.15) if estilo["agua"] == "lava" else Color(0.5, 1.0, 0.3), 1.0, 2.6)
				l.position = p * T
				add_child(l)
				luces_fuego.append([l, 1.0, rng.randf() * TAU])
				puestas += 1
	if estilo["rayos"]:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla + 3
		for i in 9:
			var rayo := Sprite2D.new()
			rayo.texture = tex
			rayo.material = mat_aditivo
			rayo.modulate = Color(1.0, 0.95, 0.7, 0.0)
			rayo.scale = Vector2(rng.randf_range(1.5, 2.6), rng.randf_range(12.0, 16.0))
			rayo.rotation_degrees = 28.0
			rayo.position = Vector2(rng.randf_range(4, ANCHO - 4), rng.randf_range(4, ALTO - 4)) * T
			rayo.z_index = 20
			add_child(rayo)
			var t := create_tween().set_loops()
			t.tween_property(rayo, "modulate:a", rng.randf_range(0.08, 0.14), rng.randf_range(2.5, 4.5))
			t.tween_property(rayo, "modulate:a", 0.03, rng.randf_range(2.5, 4.5))


# Partículas de clima alrededor de la cámara (se quedan en el mundo al moverse).
func _crear_clima() -> void:
	var tipo: String = estilo["clima"]
	if tipo == "":
		return
	var p := CPUParticles2D.new()
	p.local_coords = false
	p.texture = luz_tex
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(760, 440)
	var c1 := Color.WHITE
	var c2 := Color(1, 1, 1, 0)
	match tipo:
		"hojas":
			p.amount = 26
			p.lifetime = 8.0
			p.gravity = Vector2(18, 30)
			p.scale_amount_min = 0.03
			p.scale_amount_max = 0.05
			p.angular_velocity_min = -90.0
			p.angular_velocity_max = 90.0
			c1 = Color(0.55, 0.65, 0.25, 0.9)
			c2 = Color(0.5, 0.35, 0.15, 0.0)
		"nieve":
			p.amount = 180
			p.lifetime = 6.0
			p.gravity = Vector2(14, 60)
			p.scale_amount_min = 0.02
			p.scale_amount_max = 0.05
			c1 = Color(1, 1, 1, 0.9)
			c2 = Color(1, 1, 1, 0.0)
		"ceniza":
			p.amount = 140
			p.lifetime = 7.0
			p.gravity = Vector2(10, 22)
			p.scale_amount_min = 0.02
			p.scale_amount_max = 0.04
			c1 = Color(0.65, 0.6, 0.6, 0.8)
			c2 = Color(0.3, 0.28, 0.28, 0.0)
			var brasas := _llamas(false)
			brasas.amount = 30
			brasas.lifetime = 5.0
			brasas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			brasas.emission_rect_extents = Vector2(760, 440)
			brasas.gravity = Vector2(6, -18)
			brasas.local_coords = false
			camara.add_child(brasas)
		"polvo":
			p.amount = 50
			p.lifetime = 6.0
			p.gravity = Vector2(40, -2)
			p.scale_amount_min = 0.02
			p.scale_amount_max = 0.06
			c1 = Color(0.95, 0.85, 0.6, 0.35)
			c2 = Color(0.9, 0.8, 0.55, 0.0)
		"motas":
			p.amount = 50
			p.lifetime = 6.0
			p.gravity = Vector2(0, -10)
			p.material = mat_aditivo
			p.scale_amount_min = 0.02
			p.scale_amount_max = 0.05
			c1 = Color(0.8, 0.5, 1.0, 0.9)
			c2 = Color(0.5, 0.2, 0.9, 0.0)
		"polen":
			p.amount = 30
			p.lifetime = 7.0
			p.gravity = Vector2(6, -4)
			p.material = mat_aditivo
			p.scale_amount_min = 0.015
			p.scale_amount_max = 0.03
			c1 = Color(1.0, 0.95, 0.7, 0.7)
			c2 = Color(1.0, 0.9, 0.6, 0.0)
	if OS.has_feature("mobile") and p.amount > 60:   # móvil: como mucho 60, pero más grandes
		var k := sqrt(p.amount / 60.0)
		p.amount = 60
		p.scale_amount_min *= k
		p.scale_amount_max *= k
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	g.colors = PackedColorArray([Color(c1, 0.0), c1, c2])
	p.color_ramp = g
	p.z_index = 30
	camara.add_child(p)
	p.preprocess = p.lifetime


func _llamas(pequena: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = luz_tex
	p.material = mat_aditivo
	p.amount = 10 if pequena else 18
	p.lifetime = 0.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 3.0 if pequena else 8.0
	p.direction = Vector2(0, -1)
	p.spread = 15.0
	p.gravity = Vector2(0, -60)
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 0.03 if pequena else 0.05
	p.scale_amount_max = 0.06 if pequena else 0.12
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.85, 0.4, 1.0), Color(0.9, 0.2, 0.0, 0.0)])
	p.color_ramp = g
	return p


# ================================================================= interfaz

# Los botones y textos toman el estilo común (estilo.gd, lo aplica Recursos a toda la ventana).
func _crear_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var Estilo = load("res://estilo.gd")
	var titulo := Label.new()                       # nombre del lugar en cursiva, con una línea fina debajo
	titulo.text = lugar["nombre"]
	titulo.position = Vector2(20, 6)
	titulo.add_theme_font_override("font", Estilo.cursiva())
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.add_theme_constant_override("outline_size", 6)
	ui.add_child(titulo)
	var linea := ColorRect.new()
	linea.color = Color(Estilo.ORO, 0.8)
	linea.position = Vector2(22, 60)
	linea.size = Vector2(220, 2)
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(linea)
	var sub := Label.new()
	sub.text = NOMBRES_ESTILO[nombre_estilo].to_upper()
	sub.position = Vector2(22, 64)
	sub.add_theme_font_override("font", load("res://menu_combate.gd").fuente("res://fuentes/SairaCondensed-Light.ttf", 4, 0))
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Estilo.GRIS)
	ui.add_child(sub)

	var salir := Button.new()
	salir.text = "MAPA DEL MUNDO"
	salir.position = Vector2(1060, 14)
	salir.custom_minimum_size = Vector2(200, 50)
	salir.add_theme_font_size_override("font_size", 20)
	salir.pressed.connect(_salir)
	salir.focus_mode = Control.FOCUS_NONE              # tocarlo no le da el foco (las flechas siguen moviendo)
	salir.set_meta("clave", "MAPA DEL MUNDO")
	botones_hud.append(salir)
	ui.add_child(salir)
	if es_ciudad:                                   # tienda y posada
		var fila := HBoxContainer.new()
		fila.position = Vector2(18, 98)
		fila.add_theme_constant_override("separation", 10)
		ui.add_child(fila)
		for d in [["TIENDA", _abrir_tienda, "TIENDA"], ["POSADA (%d)" % PRECIO_POSADA, _boton_posada, "POSADA"]]:
			var b := Button.new()
			b.text = d[0]
			b.custom_minimum_size = Vector2(170, 48)
			b.add_theme_font_size_override("font_size", 20)
			b.pressed.connect(func():
				if barra_activa:
					ultimo_de_barra = d[2]
				d[1].call())
			b.focus_mode = Control.FOCUS_NONE
			b.set_meta("clave", d[2])
			botones_hud.append(b)
			fila.add_child(b)
		lbl_oro = Label.new()
		lbl_oro.add_theme_font_size_override("font_size", 20)
		lbl_oro.add_theme_color_override("font_color", Estilo.ORO)
		lbl_oro.position = Vector2(20, 152)
		ui.add_child(lbl_oro)
		_poner_oro()

	Entrada.encadenar(botones_hud)                   # MAPA DEL MUNDO y la fila TIENDA / POSADA no comparten contenedor
	boton_examinar = Button.new()
	boton_examinar.text = "Examinar"
	boton_examinar.position = Vector2(520, 600)
	boton_examinar.custom_minimum_size = Vector2(240, 52)
	boton_examinar.add_theme_font_size_override("font_size", 22)
	boton_examinar.visible = false
	boton_examinar.pressed.connect(_accion)
	boton_examinar.focus_mode = Control.FOCUS_NONE   # con teclado o mando, Intro / A (ui_accept)
	ui.add_child(boton_examinar)

	aviso = Label.new()
	aviso.position = Vector2(190, 110)
	aviso.size = Vector2(900, 60)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_font_override("font", Estilo.cursiva())
	aviso.add_theme_font_size_override("font_size", 32)
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.modulate.a = 0.0
	ui.add_child(aviso)

	if _hay_tactil():                              # cruceta para mover al personaje con el dedo
		var dpad = load("res://dpad.gd").new()
		dpad.position = Vector2(40, 440)
		ui.add_child(dpad)

	# cartel de la salida, al pie del camino
	var cartel := Label.new()
	cartel.text = "▼ Mapa del mundo"
	cartel.position = Vector2(salida_x * T - 100, ALTO * T - 46)
	cartel.size = Vector2(200, 30)
	cartel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cartel.add_theme_font_size_override("font_size", 20)
	cartel.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	cartel.add_theme_constant_override("outline_size", 6)
	cartel.z_index = 40
	add_child(cartel)

	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 1)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fundido)
	create_tween().tween_property(fundido, "color:a", 0.0, 0.6)


# ================================================================= NPCs de las ciudades

# Habitantes (fotos de sus modelos 3D). Se colocan alrededor de la plaza; al acercarse sale
# «Hablar» y cada pulsación dice la frase siguiente.
const NPCS := [
	{"nombre": "Caballero Aldric", "dialogo": "npc_aldric", "imagen": "res://personajes/npc/caballero.png", "lugar": Vector2(-3.5, -2.0),
		"frases": ["La guardia no deja salir a nadie de noche. Dicen que la niebla trae Hollines.",
			"Esos orcos llevan hachas del Vacío. Si te cruzas con uno, no le des la espalda.",
			"Que la luz te guíe, viajero."]},
	{"nombre": "Maga Selene", "dialogo": "npc_selene", "imagen": "res://personajes/npc/maga.png", "lugar": Vector2(3.5, -2.0),
		"frases": ["Las magias de nivel II golpean a todos los enemigos a la vez. Practica y las aprenderás.",
			"El Éter verde devuelve las fuerzas mágicas. Lleva siempre alguno encima.",
			"Siento una magia antigua en tu brazalete…"]},
	{"nombre": "Pip el Pícaro", "dialogo": "npc_pip", "imagen": "res://personajes/npc/picaro.png", "lugar": Vector2(-3.0, 2.5),
		"frases": ["¿Buscas algo? Yo no he visto nada… ni he tocado nada.",
			"Un consejo gratis: en el bosque hay árboles que no se pueden atravesar. Ja, ja.",
			"Si me das una moneda te cuento un secreto. ¿No? Pues nada."]},
	{"nombre": "Aldeana Rosa", "dialogo": "npc_rosa", "imagen": "res://personajes/npc/aldeana.png", "lugar": Vector2(3.0, 2.5),
		"frases": ["¡Buenos días! Estas flores las cogí junto al camino.",
			"En la ciudad podéis descansar: se recuperan la vida y la magia.",
			"Ten cuidado ahí fuera, ¿vale?"]},
]
const RADIO_NPC := 95.0


# Los vecinos de la ciudad. Una ciudad hecha a mano pone los suyos (ciudad_oakhaven.gd), y cada uno puede traer:
# «casilla» (dónde está, en vez de «lugar», que es respecto a la plaza), «tinte», «escala» y «corto» (para «Hablar con»).
func _npcs() -> Array:
	return NPCS


func _poner_npcs() -> void:
	for d in _npcs():
		if not ResourceLoader.exists(d["imagen"]):
			continue
		var tex: Texture2D = load(d["imagen"])
		var p: Vector2 = (d["casilla"] if d.has("casilla") else plaza + d["lugar"]) * T
		var k: float = 0.5 * d.get("escala", 1.0)
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		s.scale = Vector2.ONE * k
		s.modulate = d.get("tinte", Color.WHITE)
		s.position = p
		mundo_y.add_child(s)
		var sombra := Sprite2D.new()
		sombra.texture = sombra_tex
		sombra.position = p + Vector2(0, 2)
		sombra.scale = Vector2(60, 20) / 128.0
		sombras.add_child(sombra)
		var cuerpo := StaticBody2D.new()            # no se puede atravesar
		var forma := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 16.0 / s.scale.x
		forma.shape = c
		cuerpo.add_child(forma)
		s.add_child(cuerpo)
		var t := create_tween().set_loops()        # respira
		t.tween_property(s, "scale:y", k * 1.02, 1.2 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
		t.tween_property(s, "scale:y", k, 1.2 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
		npcs.append([s, d, 0])


# El botón sirve para hablar con el NPC más cercano o, si no hay ninguno, examinar el altar.
func _comprobar_cerca() -> void:
	cofre_cerca = null
	for c in cofres:
		if not c[2] and jugador.position.distance_to(c[0].position) < 85.0:
			cofre_cerca = c
	if cofre_cerca != null:
		boton_examinar.text = "Abrir cofre"
		boton_examinar.visible = true
		return
	detalle_cerca = null
	for dt in detalles:
		if jugador.position.distance_to(dt[0].position) < RADIO_DETALLE:
			detalle_cerca = dt
	if detalle_cerca != null:
		boton_examinar.text = "Examinar"
		boton_examinar.visible = true
		return
	npc_cerca = null
	var mejor := RADIO_NPC
	for n in npcs:
		var dd: float = jugador.position.distance_to(n[0].position)
		if dd < mejor:
			mejor = dd
			npc_cerca = n
	if npc_cerca != null:
		boton_examinar.text = "Hablar con " + npc_cerca[1].get("corto", npc_cerca[1]["nombre"].get_slice(" ", 0))
		boton_examinar.visible = true
	else:
		boton_examinar.text = "Examinar"
		boton_examinar.visible = jugador.position.distance_to(altar.position) < RADIO_ALTAR


func _accion() -> void:
	if cofre_cerca != null and not cofre_cerca[2]:
		_abrir_cofre(cofre_cerca)
		return
	if detalle_cerca != null:                      # una frase corta; con todos los del acto, página nueva
		var d: Dictionary = detalle_cerca[1]
		_mostrar_aviso(d["texto"])
		Sonido.efecto("examinar")                          # sonido.gd
		var acto: Dictionary = load("res://progreso.gd").ver_detalle(d["id"])
		_avisos_hallazgo(Hallazgos.al_examinar(int(lugar["indice"]), "detalle:" + d["id"]), 3.6 if acto.is_empty() else 8.2)
		if not acto.is_empty():
			get_tree().create_timer(4.0).timeout.connect(func():
				if is_instance_valid(self):
					Sonido.efecto("pagina")
					Sonido.efecto("misterio", {"retraso": 0.2})
					_mostrar_aviso("Nueva página en el Diario: «%s»" % acto["escena"]))
		return
	if npc_cerca != null and _empezar_dialogo(_dialogo_npc(npc_cerca)):
		npc_cerca[2] += 1                              # la próxima vez, otro (los de Oakhaven se turnan)
		return
	if npc_cerca != null:
		var frases: Array = npc_cerca[1]["frases"]
		_mostrar_aviso("%s: «%s»" % [npc_cerca[1]["nombre"], frases[npc_cerca[2] % frases.size()]])
		npc_cerca[2] += 1
	else:
		Sonido.efecto("examinar")                          # examinar el altar o monumento (sonido.gd, T-083)
		_mostrar_aviso(lugar["texto"])
		_avisos_hallazgo(Hallazgos.al_examinar(int(lugar["indice"]), "altar"), 3.6)


# Qué diálogo de Dialogic toca con este vecino ("" = sus frases de siempre). Una ciudad hecha a mano lo elige según la
# partida y las veces que se le ha hablado (ciudad_oakhaven.gd).
func _dialogo_npc(n: Array) -> String:
	return n[1].get("dialogo", "")


# Diálogos con Dialogic (addons/dialogic). Si el plugin no está, se usan los avisos de siempre.
func _empezar_dialogo(nombre: String) -> bool:
	if nombre == "" or not has_node("/root/Dialogic"):
		return false
	var d = get_node("/root/Dialogic")
	if d.current_timeline != null:
		return true
	tiene_destino = false
	boton_examinar.visible = false
	d.start(nombre)
	return true


func _en_dialogo() -> bool:
	return tienda_abierta or (has_node("/root/Dialogic") and get_node("/root/Dialogic").current_timeline != null)


# ---------------------------------------------------------------- tienda y posada

const PRECIO_POSADA := 30


func _abrir_tienda(pestana := "Objetos") -> void:
	if tienda_abierta:
		return
	tienda_abierta = true
	tiene_destino = false
	var capa := CanvasLayer.new()
	capa.layer = 5
	add_child(capa)
	var t = load("res://tienda.gd").new()
	t.pestana = pestana
	t.cerrado.connect(func():
		tienda_abierta = false
		capa.queue_free()
		_poner_oro()
		if barra_activa:                             # abierta desde los botones: el foco vuelve a TIENDA
			Entrada.enfocar(_boton_hud(ultimo_de_barra)))
	capa.add_child(t)


# Posada: se paga y el grupo recupera todos los PV y PM.
# El botón POSADA: descansar. Una ciudad puede preguntar antes (ciudad_oakhaven.gd: «¿Qué va a ser?»).
func _boton_posada() -> void:
	_posada()


func _posada() -> void:
	if not _pagar_posada():
		Sonido.efecto("ui_error")                          # sonido.gd
		_mostrar_aviso("No tienes monedas suficientes (la posada cuesta %d)." % PRECIO_POSADA)
		return
	Sonido.efecto("posada")
	load("res://grupo.gd").curar_todos()
	_poner_oro()
	var t := create_tween()                       # se hace de noche y amanece
	t.tween_property(fundido, "color", Color(0, 0, 0, 0.9), 0.5)
	t.tween_interval(0.6)
	t.tween_property(fundido, "color:a", 0.0, 0.6)
	t.tween_callback(_tras_posada)
	_mostrar_aviso("Descansáis en la posada. PV y PM recuperados.")


# Cobra la noche: false si no hay monedas. Una ciudad puede invitar (ciudad_oakhaven.gd: la noche gratis).
func _pagar_posada() -> bool:
	return load("res://inventario.gd").gastar_oro(PRECIO_POSADA)


# Al amanecer, tras descansar. Una ciudad puede poner aquí su escena (ciudad_oakhaven.gd).
func _tras_posada() -> void:
	pass


func _poner_oro() -> void:
	if lbl_oro != null:
		lbl_oro.text = "%d monedas" % load("res://inventario.gd").oro()


# En el móvil (o probando con -- dpad) se muestra la cruceta táctil.
func _hay_tactil() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or "dpad" in OS.get_cmdline_user_args()


func _mostrar_aviso(texto: String) -> void:
	aviso.text = texto
	if tween_aviso != null and tween_aviso.is_valid():
		tween_aviso.kill()
	tween_aviso = create_tween()
	tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	tween_aviso.tween_interval(3.2)
	tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


# ================================================================= entrada y movimiento

# Teclado y mando (entrada.gd): Intro / A examina, habla o abre el cofre cercano; Tab, Esc o Start ponen el foco en
# los botones (MAPA DEL MUNDO, TIENDA y POSADA) y paran al jugador; Esc / B, o un toque, lo quitan.
func activar_barra(si: bool) -> void:
	barra_activa = si
	tiene_destino = false
	for b in botones_hud:
		b.focus_mode = Control.FOCUS_ALL if si else Control.FOCUS_NONE
	if si:
		Entrada.enfocar(_boton_hud(ultimo_de_barra))
	else:
		var f := get_viewport().gui_get_focus_owner()
		if f != null and f in botones_hud:
			f.release_focus()


func _boton_hud(nombre: String) -> Button:
	for b in botones_hud:
		if b.get_meta("clave") == nombre:
			return b
	return botones_hud[0]


func _unhandled_input(event: InputEvent) -> void:
	if saliendo or _en_dialogo():
		return
	if barra_activa:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu_juego"):
			activar_barra(false)
			get_viewport().set_input_as_handled()
			return
		if not (event is InputEventMouseButton or event is InputEventScreenTouch):
			return
		activar_barra(false)                       # un toque (o clic) vuelve a andar
	elif event.is_action_pressed("menu_juego"):
		activar_barra(true)
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("ui_accept") and boton_examinar.visible:
		get_viewport().set_input_as_handled()
		_accion()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		destino = get_global_mouse_position()
		tiene_destino = true
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		destino = get_global_mouse_position()
		tiene_destino = true
	elif event is InputEventKey and event.pressed and event.keycode == KEY_E and not es_ciudad:
		_encuentro()


func _process(delta: float) -> void:
	tiempo += delta
	ui.visible = not _en_dialogo()                # los menús no tapan el cuadro de diálogo
	_atender_comentarios(delta)
	for f in luces_fuego:                          # las llamas parpadean
		f[0].energy = f[1] * (0.85 + 0.15 * sin(tiempo * 13.0 + f[2]) * sin(tiempo * 7.3 + f[2] * 2.0))


# ================================================================= hallazgos (hallazgos.gd)

# Los cofres propios de los hallazgos de este lugar (un tomo, un arma o un accesorio), cerca de su rincón. Uno ya
# encontrado se ve abierto. Su id es el del hallazgo (no su posición): no se confunde con los cofres de siempre.
func _poner_hallazgos() -> void:
	for h in Hallazgos.cofres_de(int(lugar.get("indice", -1))):
		var abierto: bool = Hallazgos.encontrado(h[0])
		var sp := _poner_objeto("cofre_abierto" if abierto else "cofre", _sitio_hallazgo(h[1]) * T)
		cofres.append([sp, h[0], abierto])


# Dónde va el cofre de un hallazgo (en casillas): en su rincón; «mirada», unas casillas al norte de las ruinas (adonde
# mira la estatua); «agua», en la orilla más cerca del centro. Sin ese rincón, junto al altar.
func _sitio_hallazgo(cerca: String) -> Vector2:
	var base := Vector2(-1, -1)
	match cerca:
		"agua":
			base = _orilla()
		"mirada":
			base = _rincon("ruinas")
			if base.x >= 0:
				base += Vector2(1.4, -5.0)
		_:
			base = _rincon(cerca)
	if base.x < 0:
		base = meta + Vector2(3.0, 2.0)
	return _casilla_libre(base)


func _rincon(tipo: String) -> Vector2:
	for l in lugares_interes:
		if l["tipo"] == tipo:
			return l["pos"] + Vector2(-1.4, 1.0)          # (el cofre de siempre y el detalle van a otro lado)
	return Vector2(-1, -1)


# La casilla de suelo junto al agua más cerca del centro del mapa (o (-1, -1) si no hay agua).
func _orilla() -> Vector2:
	var mejor := Vector2(-1, -1)
	var centro := Vector2(ANCHO, ALTO) * 0.5
	for y in range(2, ALTO - 2):
		for x in range(2, ANCHO - 2):
			var c := Vector2(x, y) + Vector2(0.5, 0.5)
			if not _suelo_libre(c):
				continue
			var junto := false
			for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				junto = junto or _en_agua((c + d) * T)
			if junto and (mejor.x < 0 or c.distance_to(centro) < mejor.distance_to(centro)):
				mejor = c
	return mejor


func _suelo_libre(c: Vector2) -> bool:
	var x := floori(c.x)
	var y := floori(c.y)
	return x > 0 and y > 0 and x < ANCHO - 1 and y < ALTO - 1 and muros[y * ANCHO + x] == 0 and not _en_agua(c * T)


# La casilla libre más cerca de «c», lejos de otros cofres, detalles y del altar.
func _casilla_libre(c: Vector2) -> Vector2:
	for r in [0.0, 0.8, 1.6, 2.4, 3.2, 4.0, 5.0, 6.0]:
		for k in 12:
			var q: Vector2 = c + Vector2(cos(TAU * k / 12.0), sin(TAU * k / 12.0)) * r
			if not _suelo_libre(q):
				continue
			var lejos := q.distance_to(meta) > 2.0
			for e in cofres + detalles:
				lejos = lejos and q.distance_to(e[0].position / T) > 1.8
			if lejos:
				return q
			if r == 0.0:
				break
	return c


func _abrir_hallazgo(c: Array) -> void:
	var textos: Array = Hallazgos.encontrar(str(c[1]))
	c[2] = true
	var d := _objeto("cofre_abierto")
	var s: Sprite2D = c[0]
	s.texture = d["tex"]
	s.offset = -d["origen"]
	Sonido.efecto("cofre")
	_avisos_hallazgo(textos, 0.0)
	_comentar_luego("cofre", 1.2 + 3.6 * textos.size())


# Los avisos de un hallazgo, uno detrás de otro desde «desde» segundos, con su sonido; y se guarda la partida.
func _avisos_hallazgo(textos: Array, desde: float) -> void:
	if textos.is_empty():
		return
	for i in textos.size():
		var t: String = textos[i]
		var cuando := desde + 3.6 * i
		if cuando <= 0.0:
			_mostrar_aviso(t)
		else:
			get_tree().create_timer(cuando).timeout.connect(func():
				if is_instance_valid(self):
					_mostrar_aviso(t))
	Sonido.efecto("tesoro", {"retraso": desde + 0.3})
	_poner_oro()
	guardar_posicion()
	load("res://progreso.gd").guardar(scene_file_path)


# ================================================================= comentarios de los héroes

# El momento del comentario al llegar: un lugar nuevo, o la Garganta (garganta.gd). Una ciudad hecha a mano pone el
# suyo (ciudad_oakhaven.gd). "" si no toca. Solo la primera vez en la sesión que se entra en ese lugar.
func _momento_llegada() -> String:
	var clave := "@lugar:%s" % lugar.get("indice", -1)
	if Comentarios.dichos().has(clave):
		return ""
	var d: Dictionary = Comentarios.dichos().duplicate(true)
	d[clave] = true
	Engine.set_meta(Comentarios.META, d)
	return "llegar:garganta" if str(lugar.get("nombre", "")).begins_with("Garganta") else "llegar:lugar_nuevo"


func _comentar_luego(momento: String, segundos: float) -> void:
	comentario_pendiente = momento
	comentario_t = segundos


# Cuenta atrás de la llegada y del comentario pendiente; si empieza un diálogo, el que esté en pantalla se quita.
func _atender_comentarios(delta: float) -> void:
	if ui == null or jugador == null:
		return
	if _en_dialogo():
		for n in ui.get_children():
			if n.name.begins_with("comentario"):
				n.queue_free()
	if llegada_t >= 0.0:
		llegada_t -= delta
		if llegada_t < 0.0:
			var m := _momento_llegada()
			if m != "":
				_comentar_luego(m, 0.0)
	if comentario_pendiente != "":
		comentario_t -= delta
		if comentario_t <= 0.0 and not _ocupado_para_comentar():
			_comentar(comentario_pendiente)
			comentario_pendiente = ""


func _ocupado_para_comentar() -> bool:
	return saliendo or barra_activa or tienda_abierta or _en_dialogo()


# Enseña un comentario si toca (y si no hay otro en pantalla). Devuelve si salió.
func _comentar(momento: String) -> bool:
	if _ocupado_para_comentar():
		return false
	for n in ui.get_children():
		if n.name.begins_with("comentario"):
			return false
	var c := Comentarios.elegir(momento)
	if c.is_empty():
		return false
	Comentarios.mostrar(ui, c)
	return true


func _physics_process(delta: float) -> void:
	if saliendo or _en_dialogo() or barra_activa:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		tiene_destino = false
	elif tiene_destino:
		var falta := destino - jugador.position
		if falta.length() < 6.0:
			tiene_destino = false
		else:
			dir = falta.normalized()
	var antes := jugador.position
	jugador.velocity = dir * VELOCIDAD
	jugador.move_and_slide()
	var p := jugador.position
	if _en_agua(p):                                # no se puede caminar por el agua
		if not _en_agua(Vector2(p.x, antes.y)):
			jugador.position = Vector2(p.x, antes.y)
		elif not _en_agua(Vector2(antes.x, p.y)):
			jugador.position = Vector2(antes.x, p.y)
		else:
			jugador.position = antes
			tiene_destino = false
	jugador.position = jugador.position.clamp(Vector2(8, 8), Vector2(ANCHO * T - 8, ALTO * T + 10))
	var movido := jugador.position.distance_to(antes)
	sprite.actualizar(jugador.position - antes, movido / maxf(VELOCIDAD * delta, 0.001), delta)
	if movido > 0.5:
		acum += movido
		if acum >= LONG_PASO:
			acum -= LONG_PASO
			_paso()
	_comprobar_cerca()
	if mat_hierba != null and movido > 0.5:            # solo cuando se mueve: un dato global para toda la hierba
		RenderingServer.global_shader_parameter_set("jugador_pos", jugador.position)
		hierba_pies.visible = _hay_hierba(jugador.position)
	if jugador.position.y > ALTO * T - 4:
		_salir()


func _en_agua(p: Vector2) -> bool:
	return _peso(agua_v, p / T) > 0.55 and not _en_puente(p)


func _paso() -> void:
	pasos += 1
	_brazalete()
	if load("res://progreso.gd").paso_incienso():
		_mostrar_aviso("El Incienso de Ceniza se ha consumido.")
	if es_ciudad:
		return
	# progreso.gd: pasos seguros, luego sube despacio; casi nada si la zona ya está «limpia» o con incienso
	if randf() < load("res://progreso.gd").prob_encuentro(PROB_ENCUENTRO, pasos, PASOS_MIN, nombre_estilo):
		_encuentro()


# ================================================================= cambios de escena

# Recursos la llama al cerrar la app, para volver justo aquí.
func guardar_posicion() -> void:
	Engine.set_meta("pos_zona", jugador.position)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", lugar["indice"])


func _encuentro() -> void:
	if saliendo:
		return
	saliendo = true
	Engine.set_meta("zona", nombre_estilo)
	Engine.set_meta("pos_zona", jugador.position)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", lugar["indice"])
	Engine.set_meta("desde_mapa", true)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("escena_retorno", scene_file_path)   # zona.tscn o una mazmorra (garganta.tscn)
	Sonido.efecto("emboscada")                         # sonido.gd
	_mostrar_aviso("¡Emboscada!")
	fundido.color = Color(1, 1, 1, 0)
	var t := create_tween()
	for i in 3:
		t.tween_property(fundido, "color:a", 0.85, 0.07)
		t.tween_property(fundido, "color:a", 0.0, 0.07)
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.45)
	await t.finished
	Recursos.cambiar_escena("res://combate.tscn")


func _salir() -> void:
	if saliendo:
		return
	saliendo = true
	Engine.set_meta("pos_zona_ok", false)
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, 0.5)
	await t.finished
	Recursos.cambiar_escena("res://mapa.tscn")
