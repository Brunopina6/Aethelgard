extends Node2D
# Combate ATB de Aethelgard (Godot 4.x)
# Personajes articulados, menú estilo FFIX, magias Agua y Fuego (con quemadura) y vida sobre los enemigos.
# Kael y la maga blanca (Lya) son modelos 3D que se dibujan cada uno en una ventana 3D propia (SubViewport).
# Kael necesita kael_3d.gd + maga_3d.gd + gestos_3d.gd + kael.fbx; la maga, maga_3d.gd + gestos_3d.gd + su .fbx.
# Si falta algo, se usa la versión 2D de antes (aventurero o Nyx 2D).
# Se adjunta al nodo raíz de combate.tscn (Nodo 2D). Crea toda la interfaz por código.

# Modo pruebas: las magias no gastan PM. Ponlo en false para el juego de verdad.
const MODO_PRUEBAS := true
# Frostfang: cada golpe de Kael congela al enemigo (pierde 2 de Vitalidad = 16 PV máximos durante
# 2 rondas). PROB_CONGELAR = probabilidad (1.0 = siempre).
const PROB_CONGELAR := 1.0
const RONDAS_CONGELACION := 2
const VITALIDAD_CONGELACION := 2
const ATB_MAX := 100.0
const ESC := 0.8
const CANVAS := Vector2(320, 480)
const DANO_QUEMADURA := 5
# Música de los combates normales (los jefes y súper jefes tendrán la suya).
const MUSICA_NORMAL := "res://musica_combate_normal.mp3"
# Jefes: su música y la de la segunda fase. Si no están, se usa la normal y en la segunda fase
# se acelera y sube de tono (pitch).
const MUSICA_JEFE := "res://musica_jefe.mp3"
const MUSICA_JEFE_FASE2 := "res://musica_jefe_fase2.mp3"
const PITCH_FASE2 := 1.12
const RONDAS_QUEMADURA := 2
# Tiempos del ataque saltando de Kael (los mismos que T_AGACHAR, T_SALTO y T_CORTE de kael_3d.gd).
const SALTO_T := [0.2, 0.3, 0.14]
# Si falta el modelo 3D, qué personaje 2D se usa y dónde se coloca.
const RESPALDO := {"kael3d": ["aventurero", Vector2(485, 218)], "nyx3d": ["nyx", Vector2(578, 140)]}
# Golpes críticos (solo ataques físicos) y defensa.
const PROB_CRITICO := 0.12
const MULT_CRITICO := 1.6
const COLOR_DEFENSA := Color(0.75, 0.85, 1.25)
const CURA_POCION := 50
# Objetos que se pueden usar en combate (el dibujo es la foto del frasco de Meshy).
const OBJETOS_COMBATE := {
	"Poción": {"que": "PV", "cura": 60, "imagen": "res://objetos/pocion.png", "color": Color(1.0, 0.35, 0.3)},
	"Éter": {"que": "PM", "cura": 25, "imagen": "res://objetos/eter.png", "color": Color(0.35, 1.0, 0.6)},
}
# Menú de combate minimalista (menu_combate.gd). Ocupa el 40 % derecho de la pantalla, por eso los
# héroes van más a la izquierda y los enemigos se juntan a la izquierda: x = x * ENEMIGOS_X.x + ENEMIGOS_X.y
const ENEMIGOS_X := Vector2(0.75, -190.0)
# Armonía (barra de Lya): cada acción de un héroe la carga; llena, se puede usar la INVOCACIÓN.
const ARMONIA_POR_ACCION := 0.15
const INVOCACION := {"nombre": "Ladrón de Corazones", "prob_muerte": 0.2, "dano_jefe": 0.2,
	"desc": "Érebo arranca el corazón a un enemigo (20 %). A un jefe le quita el 20 % de su vida."}
# Colores de los números flotantes (Biblia de arte): daño, curación, hielo e invocación.
const C_DANO := Color(1, 1, 1)
const C_CURA := Color("8FF0B0")
const C_HIELO := Color("8FD3FF")
const C_INVOCACION := Color("E8C46A")
const TAM_NUMERO := 46
# Luz de los personajes 3D (Biblia de arte): principal dorada y relleno azul.
const LUZ_PRINCIPAL := Color("FFE2B0")
const LUZ_RELLENO := Color("7FA0D8")
# Tamaño de los luchadores sobre el fondo. Se encogen hacia PIVOTE_ESCENA (el suelo, en el centro)
# para que se vea el escenario. 1.0 = tamaño original.
const TAM_ESCENA := 0.74
const PIVOTE_ESCENA := Vector2(640, 505)

# Magias: cambia aquí el coste, el daño y los colores.
const MAGIAS := {
	# colores de los efectos según la Biblia de arte
	"Agua": {"coste": 6, "dano": 35, "color": Color("3B8FD8")},
	"Fuego": {"coste": 8, "dano": 50, "color": Color("FF7A3C"), "quemadura": true},
	"Rayo": {"coste": 7, "dano": 45, "color": Color("F2E36B")},
	"Cura": {"coste": 6, "dano": 45, "color": Color("8FF0B0"), "cura": true},
}
# Efectos 3D de las magias (escenas .tscn) y cómo se ajustan al tamaño del combate:
# VFX_PX_METRO = píxeles de la escena por metro (los personajes 3D miden 1,7 m).
# Calidad en el móvil: menos partículas, efectos 3D y personajes a menos resolución, como mucho
# 2 efectos 3D a la vez (el resto se dibuja en 2D) y sin luces 2D ni resplandor (bloom).
const CALIDAD_MOVIL := {"particulas": 0.4, "res_efectos": 0.5, "res_personajes": 0.7, "max_efectos_3d": 2}
const VFX_FUEGO := "res://vfx/FireImpactVFX.tscn"
const VFX_AGUA := "res://vfx/WaterImpactVFX.tscn"
const VFX_RAYO := "res://vfx/LightningImpactVFX.tscn"
const VFX_CURA := "res://vfx/HealingVFX.tscn"
const VFX_ALTO_VISTA := 4.0
const VFX_PX_METRO := 178.0
# Niveles de cada magia: el I es contra un enemigo; el II y el III dan a todos los enemigos a la vez.
# Se aprenden al subir de nivel el personaje (grupo.gd, NIVEL_MAGIA). "dano" es por cada enemigo.
const NIVELES_MAGIA := {
	"Fuego": [{"nombre": "Fuego", "coste": 8, "dano": 50, "todos": false},
		{"nombre": "Llamarada", "coste": 18, "dano": 70, "todos": true},
		{"nombre": "Infierno", "coste": 34, "dano": 140, "todos": true}],
	"Agua": [{"nombre": "Agua", "coste": 6, "dano": 35, "todos": false},
		{"nombre": "Torrente", "coste": 15, "dano": 55, "todos": true},
		{"nombre": "Maremoto", "coste": 30, "dano": 115, "todos": true}],
	"Rayo": [{"nombre": "Rayo", "coste": 7, "dano": 45, "todos": false},
		{"nombre": "Tormenta", "coste": 17, "dano": 65, "todos": true},
		{"nombre": "Cólera del Cielo", "coste": 32, "dano": 130, "todos": true}],
	# Cura: "dano" son los PV que recupera cada aliado; el II y el III curan a todo el grupo.
	"Cura": [{"nombre": "Cura", "coste": 6, "dano": 45, "todos": false},
		{"nombre": "Bendición", "coste": 16, "dano": 45, "todos": true},
		{"nombre": "Gracia Divina", "coste": 30, "dano": 100, "todos": true}],
}

const MODELOS := {
	"kael": {
		"cadera": Vector2(320, 494),
		"esc": 0.4,
		"cerrada": "res://kael2_cara_cerrados.png",
		"partes": [
			{"n": "piernas", "r": "res://kael2_piernas.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "cadera", "r": "res://kael2_cadera.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "torso", "r": "res://kael2_torso.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "brazo_a", "r": "res://kael2_brazo_a.png", "p": Vector2(231, 316), "padre": "cuerpo", "detras": false},
			{"n": "antebrazo_a", "r": "res://kael2_antebrazo_a_1.png", "p": Vector2(206, 426), "padre": "brazo_a", "detras": false},
			{"n": "cabeza", "r": "res://kael2_cara_normal.png", "p": Vector2(320, 277), "padre": "cuerpo", "detras": false},
			{"n": "brazo_f", "r": "res://kael2_brazo_f.png", "p": Vector2(409, 316), "padre": "cuerpo", "detras": false},
			{"n": "antebrazo_f", "r": "res://kael2_antebrazo_f.png", "p": Vector2(432, 426), "padre": "brazo_f", "detras": false},
			{"n": "arma", "r": "res://kael2_espada_h.png", "p": Vector2(419, 600), "padre": "antebrazo_f", "detras": true}
		]},
	"nyx": {
		"cadera": Vector2(160, 215),
		"cerrada": "res://nyx_cabeza_cerrada.png",
		"partes": [
			{"n": "falda", "r": "res://nyx_falda.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "pelo", "r": "res://nyx_pelo.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "torso", "r": "res://nyx_torso.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "brazo_a", "r": "res://nyx_brazo_a.png", "p": Vector2(120, 108), "padre": "cuerpo", "detras": false},
			{"n": "cabeza", "r": "res://nyx_cabeza.png", "p": Vector2(160, 88), "padre": "cuerpo", "detras": false},
			{"n": "brazo_f", "r": "res://nyx_brazo_f.png", "p": Vector2(200, 108), "padre": "cuerpo", "detras": false},
			{"n": "arma", "r": "res://nyx_baston.png", "p": Vector2(222, 234), "padre": "brazo_f", "detras": true}
		]},
	"hollin_a": {
		"cadera": Vector2(160, 240),
		"partes": [
			{"n": "piernas", "r": "res://hollin_a_piernas.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "torso", "r": "res://hollin_a_torso.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "brazo_f", "r": "res://hollin_a_brazo_f.png", "p": Vector2(222, 142), "padre": "cuerpo", "detras": false},
			{"n": "brazo_a", "r": "res://hollin_a_brazo_a.png", "p": Vector2(112, 150), "padre": "cuerpo", "detras": false},
			{"n": "cabeza", "r": "res://hollin_a_cabeza.png", "p": Vector2(130, 130), "padre": "cuerpo", "detras": false}
		]},
	"hollin_b": {
		"cadera": Vector2(160, 240),
		"partes": [
			{"n": "piernas", "r": "res://hollin_b_piernas.png", "p": Vector2(0, 0), "padre": "root", "detras": false},
			{"n": "torso", "r": "res://hollin_b_torso.png", "p": Vector2(0, 0), "padre": "cuerpo", "detras": false},
			{"n": "brazo_f", "r": "res://hollin_b_brazo_f.png", "p": Vector2(222, 142), "padre": "cuerpo", "detras": false},
			{"n": "arma", "r": "res://hollin_b_cuchilla.png", "p": Vector2(246, 380), "padre": "brazo_f", "detras": true},
			{"n": "brazo_a", "r": "res://hollin_b_brazo_a.png", "p": Vector2(112, 150), "padre": "cuerpo", "detras": false},
			{"n": "cabeza", "r": "res://hollin_b_cabeza.png", "p": Vector2(130, 130), "padre": "cuerpo", "detras": false}
		]},
	"kael3d": {
		"tipo": "3d", "esc": 0.67, "script": "res://kael_3d.gd", "gestos": "res://gestos_3d.gd", "base": "res://maga_3d.gd",
		"rutas": ["res://kael.fbx", "res://Meshy_AI_Azure_Starblade_biped_Meshy_Merged_Animations.fbx", "res://kael.glb"],
		"vp": Vector2i(700, 800), "alto_vista": 3.0, "centro_y": 1.35},   # sitio de sobra para el sable en alto
	"nyx3d": {
		"tipo": "3d", "esc": 0.6, "script": "res://maga_3d.gd", "gestos": "res://gestos_3d.gd",
		"rutas": ["res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx", "res://maga.fbx", "res://maga.glb"],
		"vp": Vector2i(580, 640), "alto_vista": 2.25, "centro_y": 1.05},
	# Garon «El Muro» (garon_3d.gd): más alto de vista por el salto de «Juicio».
	"garon3d": {
		"tipo": "3d", "esc": 0.67, "script": "res://garon_3d.gd", "gestos": "res://gestos_3d.gd", "base": "res://maga_3d.gd",
		"rutas": ["res://garon.fbx"], "vp": Vector2i(700, 860), "alto_vista": 3.2, "centro_y": 1.45},
	# Grimfang el goblin (goblin_3d.gd), con el hacha del Hollín. Mira a los héroes por sí solo: no se refleja.
	"grimfang": {
		"tipo": "3d", "esc": 0.6, "script": "res://goblin_3d.gd", "gestos": "res://gestos_3d.gd", "base": "res://maga_3d.gd",
		"rutas": ["res://goblin.fbx"], "vp": Vector2i(620, 640), "alto_vista": 2.3, "centro_y": 1.05, "barra_y": 60.0,
		"respaldo": "hollin"},
	# Gorthor: el mismo goblin, el doble de grande (los jefes, al menos el doble que un héroe) y teñido de rojo.
	"gorthor3d": {
		"tipo": "3d", "esc": 1.2, "script": "res://goblin_3d.gd", "gestos": "res://gestos_3d.gd", "base": "res://maga_3d.gd",
		"rutas": ["res://goblin.fbx"], "vp": Vector2i(620, 640), "alto_vista": 2.3, "centro_y": 1.05, "barra_y": 140.0,
		"tinte": Color(1.0, 0.62, 0.56), "respaldo": "gorthor", "pies_como": 0.6},   # crece desde los pies
	"aventurero": {
		"tipo": "frames", "cadera": Vector2(295.0, 640.0), "esc": 0.37, "fps": 10,
		"frames": ["res://aventurero_idle_00.png", "res://aventurero_idle_01.png", "res://aventurero_idle_02.png", "res://aventurero_idle_03.png", "res://aventurero_idle_04.png", "res://aventurero_idle_05.png", "res://aventurero_idle_06.png", "res://aventurero_idle_07.png", "res://aventurero_idle_08.png", "res://aventurero_idle_09.png", "res://aventurero_idle_10.png", "res://aventurero_idle_11.png"],
		"espada": "res://aventurero_espada.png", "piv": Vector2(124.9, 651.0),
		"agarres": [Vector2(144.8, 619.2), Vector2(142.1, 613.9), Vector2(140.0, 608.4), Vector2(138.3, 610.0), Vector2(138.0, 606.2), Vector2(139.7, 609.9), Vector2(141.1, 613.2), Vector2(145.1, 618.5), Vector2(144.5, 620.1), Vector2(146.3, 623.5), Vector2(145.4, 620.9), Vector2(143.1, 620.1)],
		"angs": [-46.0, -45.5, -45.0, -43.5, -43.0, -44.0, -45.0, -46.0, -47.0, -48.0, -47.5, -46.5]},
	# Slime (Free RPG Sprites de Segel2D): sprite completo con una animación por acción.
	# "ancla" es el centro inferior del cuerpo dentro del fotograma; "barra_y" y "centro_y"
	# colocan la vida y los efectos, porque es más bajito que el resto.
	"slime": {
		"tipo": "sprite", "cadera": Vector2(142.2, 422.2), "esc": 0.9, "ancla": Vector2(181.5, 182.0),
		"barra_y": 210.0, "centro_y": 315.0,
		"anims": {"idle": [12, 12.0, true], "move": [10, 14.0, true], "attack": [8, 14.0, false],
			"hurt": [6, 14.0, false], "dead": [6, 10.0, false]}},
	# Enemigos de una sola imagen (foto de un modelo 3D de Meshy): "cadera" = dónde van los pies dentro
	# del lienzo de 320×480, "tam" = escala de la imagen, "barra_y"/"centro_y" = vida y efectos.
	# Hollín (orco con hacha): fotogramas sacados de su modelo 3D. "anims" = tiras enemigos/hollin_<nombre>.png
	# con [fotogramas, por segundo]; "pies" = dónde están los pies dentro de cada fotograma.
	"hollin": {"tipo": "imagen", "imagen": "res://enemigos/hollin_guardia.png", "cadera": Vector2(160, 470), "tam": 0.95,
		"pies": Vector2(241, 475), "barra_y": -20.0, "centro_y": 215.0,
		"anims": {"guardia": [1, 1.0], "andar": [8, 12.0], "prep": [1, 1.0], "tajo": [1, 1.0], "herida": [1, 1.0]}},
	# Gorthor 2D (respaldo si falta el modelo del goblin): el guardián de piedra, más grande y teñido de rojo.
	"gorthor": {"tipo": "imagen", "imagen": "res://enemigos/guardian.png", "cadera": Vector2(160, 470), "tam": 1.45,
		"barra_y": -230.0, "centro_y": 60.0, "tinte": Color(1.0, 0.6, 0.52)},
	"guardian": {"tipo": "imagen", "imagen": "res://enemigos/guardian.png", "cadera": Vector2(160, 470), "tam": 0.92,
		"barra_y": 10.0, "centro_y": 210.0},
}

# Enemigos disponibles y grupos que pueden aparecer en un encuentro (se elige uno al azar).
const ENEMIGOS := {
	"slime": {"nombre": "Slime", "modelo": "slime", "hp": 55, "atk": 9, "vel": 16.0, "exp": 10, "oro": 6, "personalidad": "cobarde"},
	# Grimfang el goblin sustituye al Hombre de Hollín y al Goblin 2D (los dibujos del Hollín quedan de respaldo).
	"grimfang": {"nombre": "Grimfang", "modelo": "grimfang", "hp": 110, "atk": 15, "vel": 13.0, "exp": 28, "oro": 18, "personalidad": "agresivo"},
	"guardian": {"nombre": "Guardián de piedra", "modelo": "guardian", "hp": 180, "atk": 19, "vel": 8.0, "exp": 45, "oro": 40, "personalidad": "jefe"},
	# Garganta del Diablo (garganta.gd). Usan dibujos que ya hay hasta tener los suyos.
	# "fases": al 50 % cambia la música y el color, va más rápido y aprende Devorar.
	# "ultimo_aliento": al llegar a 0 PV cae de rodillas y Kael decide si le perdona.
	"gorthor": {"nombre": "Gorthor el Devorador", "modelo": "gorthor3d", "hp": 460, "atk": 22, "vel": 10.0, "exp": 60, "oro": 150,
		"personalidad": "jefe", "fases": true, "ultimo_aliento": true, "titulo": true},
	"golem_ambar": {"nombre": "Gólem de ámbar", "modelo": "guardian", "hp": 200, "atk": 17, "vel": 9.0, "exp": 70, "oro": 90, "personalidad": "bruto"},
}
const GRUPOS := [
	[["grimfang", Vector2(230, 150)], ["grimfang", Vector2(410, 115)]],
	[["slime", Vector2(250, 40)], ["slime", Vector2(60, 130)], ["slime", Vector2(440, 130)]],
	[["slime", Vector2(30, 90)], ["grimfang", Vector2(410, 115)], ["slime", Vector2(215, 135)]],
	[["grimfang", Vector2(230, 150)], ["slime", Vector2(410, 115)]],
	[["guardian", Vector2(150, 120)], ["grimfang", Vector2(420, 125)]],
	# combates fijos (Engine.set_meta("grupo_combate", n)); no salen al azar
	[["gorthor", Vector2(260, 120)]],                                    # 5: jefe de la Garganta
	[["golem_ambar", Vector2(150, 120)], ["grimfang", Vector2(420, 125)]],   # 6: nido de la Garganta
]
const GRUPOS_AL_AZAR := 5           # solo los primeros salen en encuentros aleatorios


const ANIM := {
	"kael": {"distancia": 150.0, "punta": Vector2(419, 131),
		"tex": {"esp_g": "res://kael2_espada_g.png", "esp_h": "res://kael2_espada_h.png",
			"esp_2": "res://kael2_espada_2.png", "ma_1": "res://kael2_antebrazo_a_1.png",
			"ma_2": "res://kael2_antebrazo_a_2.png"},
		"caras": {"normal": "res://kael2_cara_normal.png", "grito": "res://kael2_cara_grito.png",
			"dolor": "res://kael2_cara_dolor.png", "cerrados": "res://kael2_cara_cerrados.png",
			"sonrisa": "res://kael2_cara_sonrisa.png", "cansado": "res://kael2_cara_cansado.png"},
		"poses": {
			"guardia": {"f": -52.1, "codo_f": 72.7, "arma": 119.4, "a": 4.0, "codo_a": -6.0, "lean": -3.0, "z": 0, "esp": "g", "ma": 1},
			"ini": {"f": 20.8, "codo_f": 183.2, "arma": 76.0, "a": 4.0, "codo_a": -6.0, "lean": 0.0, "z": -1, "esp": "h", "ma": 1},
			"alto": {"f": -130.2, "codo_f": -97.9, "arma": 263.1, "a": 135.2, "codo_a": 112.6, "lean": 8.0, "z": 0, "esp": "2", "ma": 2},
			"golpe": {"f": 2.8, "codo_f": -268.1, "arma": 150.3, "a": 53.3, "codo_a": 226.2, "lean": -12.0, "z": 0, "esp": "2", "ma": 2},
			"magia": {"f": -50.1, "codo_f": 192.8, "arma": 217.3, "a": 178.4, "codo_a": 118.9, "lean": 3.0, "z": 0, "esp": "2", "ma": 2},
		}},
	"aventurero": {"distancia": 140.0, "prep": -20.0, "golpe": -115.0, "lean_prep": 6.0, "lean_golpe": -10.0,
		"m_arma": -12.0, "m_lean": 4.0, "punta": Vector2(192.0, 4.7)},
	"nyx3d": {"distancia": 110.0},
	"kael3d": {"distancia": 120.0},
	"nyx": {"distancia": 100.0, "prep": -100.0, "arma_prep": 150.0, "golpe": -260.0, "arma_golpe": 140.0,
		"ret": -360.0, "lean_prep": 6.0, "lean_golpe": -10.0,
		"m_brazo": -120.0, "m_arma": 90.0, "m_brazo_a": 30.0, "m_lean": 4.0, "punta": Vector2(223, 36)},
	"hollin_a": {"distancia": 90.0, "prep": -120.0, "golpe": -290.0, "ret": -360.0,
		"a_prep": -100.0, "a_golpe": -270.0, "a_ret": -360.0, "lean_prep": 10.0, "lean_golpe": -18.0},
	"hollin_b": {"distancia": 110.0, "prep": -150.0, "arma_prep": 175.0, "golpe": -310.0, "arma_golpe": 160.0,
		"ret": -360.0, "lean_prep": 12.0, "lean_golpe": -20.0},
	"slime": {"distancia": 200.0, "frame_golpe": 4},
	"grimfang": {"distancia": 120.0},
	"gorthor3d": {"distancia": 190.0},
	"hollin": {"distancia": 140.0},
	"gorthor": {"distancia": 170.0},
	"garon3d": {"distancia": 130.0},
	"guardian": {"distancia": 150.0},
}

var heroes: Array = [
	{"nombre": "Kael", "modelo": "kael3d", "hero": true, "hp": 120, "hp_max": 120, "mp": 16, "mp_max": 16,
		"atk": 21, "vel": 22.0, "atb": 0.0, "pos": Vector2(352, -14)},
	{"nombre": "Lya", "modelo": "nyx3d", "hero": true, "hp": 80, "hp_max": 80, "mp": 40, "mp_max": 40,
		"atk": 8, "vel": 26.0, "atb": 0.0, "pos": Vector2(548, 95)},
	# Garon «El Muro», delante: el tanque
	{"nombre": "Garon", "modelo": "garon3d", "hero": true, "hp": 150, "hp_max": 150, "mp": 4, "mp_max": 4,
		"atk": 28, "vel": 16.0, "atb": 0.0, "pos": Vector2(270, 100)},
]

var enemigos: Array = []

var pociones := 3
var cola: Array = []
var actor = null
var estado := "esperando"     # esperando, menu, objetivo, enemigo, accion, fin
var accion := ""
var magia_sel := ""
var nivel_sel := 1
var objetivo_apuntado = null

var capa: CanvasLayer
var escena: Node2D            # luchadores y efectos (escalados con TAM_ESCENA)
var registro: Label
var menu                      # menu_combate.gd
var fuera: Control            # tocar fuera del menú vuelve atrás (y salta la invocación)
var capa_zonas: Control       # zonas táctiles sobre los enemigos / aliados al elegir objetivo
var flecha: Control           # flecha que rebota sobre el objetivo
var obj_nombre: Label         # nombre del objetivo, arriba a la izquierda
var obj_linea: ColorRect
var al_elegir_obj: Callable
var volver_obj: Callable
var objetivos_posibles: Array = []
var armonia := 0.0
var magia_nivel_menu := {}    # última pestaña de magia de cada héroe
var saltar_invocacion := false
var combate_fijo := ""        # id de un combate fijo (jefe, nido...): al ganarlo no se repite
var fondo_nodo: Node2D        # el fondo de la zona (en la segunda fase de un jefe se tiñe de rojo)
var glow_tex: GradientTexture2D
var mat_aditivo: CanvasItemMaterial
var musica: AudioStreamPlayer
var sombras: Node2D
var sombra_tex: GradientTexture2D
var luz_3d := Color(1.0, 0.8, 0.6)       # luz principal de los modelos 3D (la cambia el fondo)
var relleno_3d := Color(0.55, 0.6, 1.0)  # contraluz de los modelos 3D
var tono_escena := Color(1, 1, 1)        # tinte de los luchadores según la luz de la zona
var movil := false
var calidad := 1.0                       # multiplica la cantidad de partículas
var res_efectos := 1.0                   # resolución de las ventanas 3D de las magias
var res_personajes := 0.75               # resolución de las ventanas 3D de Kael y Lya
var max_efectos_3d := 8                  # efectos 3D a la vez como mucho
var efectos_3d_activos := 0


func _ready() -> void:
	randomize()
	# modo móvil: en Android (o probando con -- movil) los efectos son más ligeros
	movil = OS.has_feature("mobile") or "movil" in OS.get_cmdline_user_args()
	if movil:
		calidad = CALIDAD_MOVIL["particulas"]
		res_efectos = CALIDAD_MOVIL["res_efectos"]
		res_personajes = CALIDAD_MOVIL["res_personajes"]
		max_efectos_3d = CALIDAD_MOVIL["max_efectos_3d"]
	heroes = heroes.filter(func(h): return RESPALDO.has(h["modelo"]) or _ruta_3d(MODELOS[h["modelo"]]) != "")   # Garon sin modelo: no sale
	if ResourceLoader.exists("res://grupo.gd"):    # solo los que están en el grupo
		var en_grupo: Array = load("res://grupo.gd").miembros()
		heroes = heroes.filter(func(h): return h["nombre"] in en_grupo)
	for h in heroes:
		if RESPALDO.has(h["modelo"]) and _ruta_3d(MODELOS[h["modelo"]]) == "":
			push_warning("Falta el modelo 3D de %s o sus scripts: se usa la versión 2D" % h["nombre"])
			h["pos"] = RESPALDO[h["modelo"]][1]
			h["modelo"] = RESPALDO[h["modelo"]][0]
	if ResourceLoader.exists("res://inventario.gd"):   # pociones del inventario
		var inv = load("res://inventario.gd")
		for a in OS.get_cmdline_user_args():          # pruebas: godot ... -- equipar=Kael:colmillo_nocturno
			if a.begins_with("equipar="):
				inv.equipar(a.substr(8).get_slice(":", 0), "arma", a.substr(8).get_slice(":", 1))
		pociones = inv.cantidad("Poción")
	if ResourceLoader.exists("res://grupo.gd"):        # nivel, atributos, equipo y vida de cada héroe
		var gr = load("res://grupo.gd")
		for a in OS.get_cmdline_user_args():          # pruebas: godot ... -- nivel=10
			if a.begins_with("nivel="):
				for n in gr.miembros():
					gr.datos()[n]["nivel"] = int(a.substr(6))
					gr.datos()[n]["pv"] = -1
		for h in heroes:
			if not gr.datos().has(h["nombre"]):
				continue
			var e: Dictionary = gr.estadisticas(h["nombre"])
			h["nivel"] = e["nivel"]
			h["hp_max"] = e["pv_max"]
			h["hp"] = maxi(1, e["pv"])
			h["mp_max"] = e["pm_max"]
			h["mp"] = e["pm"]
			h["atk"] = e["ataque"]
			h["vel"] = e["velocidad"]
			h["def"] = e["defensa"]
			h["magia_mult"] = e["magia_mult"]
			h["magia_extra"] = e["magia_extra"]
			h["mult_fisico"] = e["mult_fisico"]
			h["mult_magia"] = e["mult_magia"]
	_elegir_enemigos()
	_crear_texturas()
	_crear_interfaz()
	_iniciar_musica()
	_actualizar()
	_precalentar_efectos()
	for e in enemigos:                               # jefes: su nombre en grande al empezar
		if e.get("titulo", false):
			_presentar(e)


# Elige un grupo al azar (o el índice de Engine.get_meta("grupo_combate") si se ha fijado).
# Los repetidos se llaman "Slime A", "Slime B"...
func _elegir_enemigos() -> void:
	var grupo: Array = GRUPOS[randi() % GRUPOS_AL_AZAR]
	if Engine.has_meta("grupo_combate"):          # combate fijo: vale para este combate y se borra
		grupo = GRUPOS[clampi(Engine.get_meta("grupo_combate"), 0, GRUPOS.size() - 1)]
		Engine.remove_meta("grupo_combate")
	combate_fijo = Engine.get_meta("combate_fijo", "")
	if Engine.has_meta("combate_fijo"):
		Engine.remove_meta("combate_fijo")
	for a in OS.get_cmdline_user_args():          # pruebas: godot ... -- grupo=3
		if a.begins_with("grupo="):
			grupo = GRUPOS[clampi(int(a.substr(6)), 0, GRUPOS.size() - 1)]
	var cuantos := {}
	for g in grupo:
		cuantos[g[0]] = cuantos.get(g[0], 0) + 1
	var vistos := {}
	for g in grupo:
		var e: Dictionary = ENEMIGOS[g[0]].duplicate(true)
		e["hero"] = false
		var mod: Dictionary = MODELOS[e["modelo"]]
		if mod.get("tipo", "") == "3d" and _ruta_3d(mod) == "" and mod.has("respaldo"):   # falta el 3D: su dibujo 2D
			push_warning("Falta el modelo 3D de %s: se usa su respaldo 2D" % e["nombre"])
			e["modelo"] = mod["respaldo"]
		e["hp_max"] = e["hp"]
		e["atb"] = randf() * 30.0
		e["pos"] = Vector2(g[1].x * ENEMIGOS_X.x + ENEMIGOS_X.y, g[1].y)
		if cuantos[g[0]] > 1:
			e["nombre"] += " " + "ABCDEFGH"[vistos.get(g[0], 0)]
			vistos[g[0]] = vistos.get(g[0], 0) + 1
		enemigos.append(e)
	enemigos.sort_custom(func(a, b): return a["pos"].y < b["pos"].y)   # los de delante se dibujan encima


func _iniciar_musica() -> void:
	var tipo: String = Engine.get_meta("tipo_combate", "normal")
	var ruta := ""
	# los jefes usan su música (musica_jefe.ogg / .mp3) si existe; si no, la de los combates normales
	var opciones := [MUSICA_JEFE.get_basename() + ".ogg", MUSICA_JEFE] if tipo != "normal" else []
	opciones += [MUSICA_NORMAL.get_basename() + ".ogg", MUSICA_NORMAL]   # .ogg es mejor en el móvil
	for r in opciones:
		if ResourceLoader.exists(r):
			ruta = r
			break
	if ruta == "":
		return
	var pista = load(ruta)
	if pista is AudioStreamMP3 or pista is AudioStreamOggVorbis:
		pista.loop = true
	musica = AudioStreamPlayer.new()
	musica.stream = pista
	musica.volume_db = -6.0
	add_child(musica)
	musica.play()


func _bajar_musica() -> void:
	if musica != null:
		create_tween().tween_property(musica, "volume_db", -40.0, 1.8)


# ================================================================= interfaz

func _crear_texturas() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	glow_tex = GradientTexture2D.new()
	glow_tex.gradient = g
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	glow_tex.width = 256
	glow_tex.height = 256
	mat_aditivo = CanvasItemMaterial.new()
	mat_aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


func _crear_interfaz() -> void:
	capa = CanvasLayer.new()
	add_child(capa)
	_crear_fondo()
	escena = Node2D.new()
	escena.scale = Vector2(TAM_ESCENA, TAM_ESCENA)
	escena.position = PIVOTE_ESCENA * (1.0 - TAM_ESCENA)
	escena.modulate = tono_escena
	capa.add_child(escena)
	sombras = Node2D.new()                        # debajo de todos los luchadores
	escena.add_child(sombras)
	for f in enemigos + heroes:
		_crear_rig(f)
		_crear_sombra(f)

	# tocar fuera del menú: vuelve atrás (debajo del menú y de las zonas de objetivo)
	fuera = Control.new()
	fuera.size = Vector2(1280, 720)
	fuera.visible = false
	fuera.gui_input.connect(_toque_fuera)
	capa.add_child(fuera)
	capa_zonas = Control.new()
	capa_zonas.size = Vector2(1280, 720)
	capa_zonas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(capa_zonas)

	# menú minimalista (órdenes, grupo y Armonía)
	menu = load("res://menu_combate.gd").new()
	capa.add_child(menu)
	menu.preparar(heroes)
	menu.atras.connect(_atras)
	for e in enemigos:
		_crear_vida_enemigo(e)

	# texto de lo que pasa, arriba en el centro (sin ventana)
	registro = _etiqueta("¡Combate!", 34, menu.LUZ_CLARA, menu.f_nombre)
	registro.position = Vector2(240, 14)
	registro.size = Vector2(800, 50)
	registro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	capa.add_child(registro)

	# objetivo: flecha que rebota y su nombre arriba a la izquierda con una línea fina
	flecha = Control.new()
	flecha.size = Vector2(36, 30)
	flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flecha.visible = false
	flecha.draw.connect(func():
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(36, 0), Vector2(18, 28)])
		flecha.draw_colored_polygon(pts, menu.ORO)
		pts.append(pts[0])
		flecha.draw_polyline(pts, Color(menu.SOMBRA, 0.8), 2.0))
	capa.add_child(flecha)
	obj_nombre = _etiqueta("", 44, menu.LUZ_CLARA, menu.f_nombre)
	obj_nombre.position = Vector2(40, 16)
	obj_nombre.visible = false
	capa.add_child(obj_nombre)
	obj_linea = ColorRect.new()
	obj_linea.position = Vector2(40, 76)
	obj_linea.size = Vector2(240, 2)
	obj_linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obj_linea.visible = false
	capa.add_child(obj_linea)


func _etiqueta(texto: String, tam: int, color: Color, fuente: Font = null) -> Label:
	var l := Label.new()
	l.text = texto
	if fuente == null and menu != null:
		fuente = menu.f_numero
	if fuente != null:
		l.add_theme_font_override("font", fuente)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.07, 0.13))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# Barra fina sin marco (vida de los enemigos): el fondo y, dentro, el relleno (_poner_barra).
func _barra(tam: Vector2, color: Color) -> ColorRect:
	var b := ColorRect.new()
	b.size = tam
	b.color = Color(0.04, 0.07, 0.13, 0.55)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var relleno := ColorRect.new()
	relleno.size = tam
	relleno.color = color
	relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(relleno)
	return b


func _poner_barra(b: ColorRect, v: float) -> void:
	b.get_child(0).size.x = b.size.x * clampf(v, 0.0, 1.0)


# Fondo según la zona donde empezó el combate (fondo_combate.gd). Con Engine.set_meta("fondo_combate",
# "crematorio") se usa la imagen fondo.png (escenas de historia).
func _crear_fondo() -> void:
	var tipo: String = Engine.get_meta("fondo_combate", Engine.get_meta("zona", "llanura"))
	for a in OS.get_cmdline_user_args():          # pruebas: godot ... -- fondo=nieve
		if a.begins_with("fondo="):
			tipo = a.substr(6)
	if tipo != "crematorio" and ResourceLoader.exists("res://fondo_combate.gd"):
		var f = load("res://fondo_combate.gd").new()
		f.z_index = -100
		capa.add_child(f)
		fondo_nodo = f
		f.construir(tipo)
		luz_3d = f.luz_3d
		relleno_3d = f.relleno_3d
		tono_escena = f.tono
		return
	if ResourceLoader.exists("res://fondo.png"):
		var fondo := TextureRect.new()
		fondo.texture = load("res://fondo.png")
		fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fondo.stretch_mode = TextureRect.STRETCH_SCALE
		fondo.size = Vector2(1280, 720)
		fondo.z_index = -100
		capa.add_child(fondo)
	else:
		var plano := ColorRect.new()
		plano.color = Color(0.08, 0.08, 0.12)
		plano.size = Vector2(1280, 720)
		plano.z_index = -100
		capa.add_child(plano)


func _crear_vida_enemigo(e: Dictionary) -> void:
	var l := _etiqueta("", 20, Color.WHITE)
	l.position = _ancla_vida(e) + Vector2(0, -12)
	capa.add_child(l)
	var b := _barra(Vector2(120, 4), Color("FF7A3C"))
	b.position = _ancla_vida(e) + Vector2(0, 16)
	capa.add_child(b)
	e["lbl_hp"] = l
	e["barra_hp"] = b
	var est := _etiqueta("", 18, Color(0.6, 0.9, 1.0))       # estados: «Congelado»
	est.position = _ancla_vida(e) + Vector2(0, -40)
	capa.add_child(est)
	e["lbl_estado"] = est


# Dónde va la vida de un enemigo en pantalla: encima de su cabeza (centrada en los 3D).
func _ancla_vida(e: Dictionary) -> Vector2:
	if e.has("centro_ofs"):
		return _a_pantalla(Vector2(_centro(e).x, e["pos"].y + _alto_barra(e))) - Vector2(60, 0)
	return _a_pantalla(e["pos"] + Vector2(48, _alto_barra(e)))


# Sombra suave en el suelo, bajo los pies. Se mueve con el luchador y se encoge si salta.
func _crear_sombra(f: Dictionary) -> void:
	if sombra_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(0, 0, 0, 0.8), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0)])
		sombra_tex = GradientTexture2D.new()
		sombra_tex.gradient = g
		sombra_tex.fill = GradientTexture2D.FILL_RADIAL
		sombra_tex.fill_from = Vector2(0.5, 0.5)
		sombra_tex.fill_to = Vector2(1.0, 0.5)
		sombra_tex.width = 64
		sombra_tex.height = 64
	var m: Dictionary = MODELOS[f["modelo"]]
	var ancho := 190.0
	match m.get("tipo", ""):
		"3d":
			f["pie"] = f["cuerpo"].position
			ancho = 170.0
		"sprite":
			f["pie"] = m["cadera"]
			ancho = 170.0
		"imagen":
			f["pie"] = m["cadera"]
			ancho = 230.0
		"frames":
			f["pie"] = m["cadera"] + Vector2(-40, 88)
			ancho = 160.0
		_:
			f["pie"] = Vector2(CANVAS.x * 0.5, 465)
	var s := Sprite2D.new()
	s.texture = sombra_tex
	f["sombra"] = s
	f["tam_sombra"] = Vector2(ancho, ancho * 0.28) / 64.0
	sombras.add_child(s)
	_mover_sombra(f)


func _mover_sombra(f: Dictionary) -> void:
	var rig: Node2D = f["rig"]
	var pie: Vector2 = f["pie"] * rig.scale
	var p := rig.position + pie
	var suelo: float = f.get("suelo_salto", rig.position.y) + pie.y
	var k := clampf(1.0 - maxf(0.0, suelo - p.y) / 260.0, 0.35, 1.0)
	var s: Sprite2D = f["sombra"]
	s.position = Vector2(p.x, suelo)
	s.scale = f["tam_sombra"] * k
	s.modulate.a = k * rig.modulate.a


# Pasa una posición de la escena (luchadores) a la pantalla (interfaz).
func _a_pantalla(p: Vector2) -> Vector2:
	return escena.position + p * TAM_ESCENA


# ================================================================= personajes articulados

func _crear_rig(f: Dictionary) -> void:
	var m: Dictionary = MODELOS[f["modelo"]]
	var raiz := Node2D.new()
	var base: Vector2 = f["pos"]
	var esc: float = m.get("esc", ESC)
	if f["hero"] or m.get("tipo", "") == "3d":     # los enemigos 3D ya miran a los héroes: no se reflejan
		raiz.scale = Vector2(esc, esc)
	else:
		raiz.scale = Vector2(-esc, esc)
		base += Vector2(CANVAS.x * ESC, 0)
	raiz.position = base
	escena.add_child(raiz)
	if m.get("tipo", "") == "frames":
		_crear_rig_frames(f, m, raiz, base, esc)
		return
	if m.get("tipo", "") == "sprite":
		_crear_rig_sprite(f, m, raiz, base, esc)
		return
	if m.get("tipo", "") == "3d":
		_crear_rig_3d(f, m, raiz, base, esc)
		if m.has("pies_como"):                     # jefe grande: los pies donde los tendría a tamaño normal
			var mover: Vector2 = -f["cuerpo"].position * (esc - m["pies_como"])
			raiz.position += mover
			f["rig_base"] = raiz.position
			f["pos"] += mover
		return
	if m.get("tipo", "") == "imagen":
		_crear_rig_imagen(f, m, raiz, base, esc)
		return

	var cuerpo := Node2D.new()
	cuerpo.position = m["cadera"]
	var nodos := {"root": raiz, "cuerpo": cuerpo}
	var pivotes := {"root": Vector2.ZERO, "cuerpo": m["cadera"]}
	var partes := {}
	var cuerpo_puesto := false
	for d in m["partes"]:
		if d["padre"] == "cuerpo" and not cuerpo_puesto:
			raiz.add_child(cuerpo)
			cuerpo_puesto = true
		var s := Sprite2D.new()
		if ResourceLoader.exists(d["r"]):
			s.texture = load(d["r"])
		s.centered = false
		s.offset = -d["p"]
		s.position = d["p"] - pivotes[d["padre"]]
		s.show_behind_parent = d["detras"]
		nodos[d["padre"]].add_child(s)
		nodos[d["n"]] = s
		pivotes[d["n"]] = d["p"]
		partes[d["n"]] = s

	f["esc"] = esc
	f["rig"] = raiz
	f["rig_base"] = base
	f["cuerpo"] = cuerpo
	f["partes"] = partes
	f["pivotes"] = pivotes
	f["animando"] = false
	f["fase"] = randf() * 6.28
	f["quemadura"] = 0
	f["llama"] = null
	f["pose"] = "ini"
	f["cab_cerrada"] = null
	if m.has("cerrada") and ResourceLoader.exists(m["cerrada"]):
		f["cab_abierta"] = partes["cabeza"].texture
		f["cab_cerrada"] = load(m["cerrada"])
	var a: Dictionary = ANIM[f["modelo"]]
	if a.has("tex"):
		var tx := {}
		for k in a["tex"]:
			if ResourceLoader.exists(a["tex"][k]):
				tx[k] = load(a["tex"][k])
		f["tex"] = tx
	if a.has("caras"):
		var cs := {}
		for k in a["caras"]:
			if ResourceLoader.exists(a["caras"][k]):
				cs[k] = load(a["caras"][k])
		f["caras"] = cs
		_cara_reposo(f)
	if a.has("poses"):
		_fijar_pose(f, a["poses"]["ini"])


# Personaje animado por fotogramas (sprite completo) con la espada como pieza aparte.
func _crear_rig_frames(f: Dictionary, m: Dictionary, raiz: Node2D, base: Vector2, esc: float) -> void:
	var cuerpo := Node2D.new()
	cuerpo.position = m["cadera"]
	raiz.add_child(cuerpo)
	var espada := Sprite2D.new()                 # va detrás del cuerpo: la mano tapa la empuñadura
	if ResourceLoader.exists(m["espada"]):
		espada.texture = load(m["espada"])
	espada.centered = false
	espada.offset = -m["piv"]
	cuerpo.add_child(espada)
	var anim := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", m["fps"])
	sf.set_animation_loop("default", true)
	for r in m["frames"]:
		if ResourceLoader.exists(r):
			sf.add_frame("default", load(r))
	anim.sprite_frames = sf
	anim.centered = false
	anim.position = -m["cadera"]
	cuerpo.add_child(anim)
	anim.play("default")
	var nada := Node2D.new()
	cuerpo.add_child(nada)
	f["esc"] = esc
	f["rig"] = raiz
	f["rig_base"] = base
	f["cuerpo"] = cuerpo
	f["partes"] = {"arma": espada, "anim": anim, "brazo_a": nada}
	f["pivotes"] = {"arma": m["piv"]}
	f["animando"] = false
	f["fase"] = randf() * 6.28
	f["quemadura"] = 0
	f["llama"] = null
	f["pose"] = "ini"
	f["cab_cerrada"] = null
	_seguir_fotograma(f)
	anim.frame_changed.connect(_seguir_fotograma.bind(f))


# Personaje de sprite completo con varias animaciones (reposo, ataque, daño, muerte...).
# Los fotogramas están en res://personajes/<modelo>/<modelo>_<anim>_NN.png
func _crear_rig_sprite(f: Dictionary, m: Dictionary, raiz: Node2D, base: Vector2, esc: float) -> void:
	var cuerpo := Node2D.new()
	cuerpo.position = m["cadera"]
	raiz.add_child(cuerpo)
	var anim := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for nombre in m["anims"]:
		var d: Array = m["anims"][nombre]
		sf.add_animation(nombre)
		sf.set_animation_speed(nombre, d[1])
		sf.set_animation_loop(nombre, d[2])
		for i in int(d[0]):
			var r := "res://personajes/%s/%s_%s_%02d.png" % [f["modelo"], f["modelo"], nombre, i]
			if ResourceLoader.exists(r):
				sf.add_frame(nombre, load(r))
	anim.sprite_frames = sf
	anim.centered = false
	anim.position = -m["ancla"]
	cuerpo.add_child(anim)
	anim.play("idle")
	anim.frame = randi() % sf.get_frame_count("idle")
	var nada := Node2D.new()
	cuerpo.add_child(nada)
	f["esc"] = esc
	f["rig"] = raiz
	f["rig_base"] = base
	f["cuerpo"] = cuerpo
	f["partes"] = {"anim": anim, "brazo_a": nada}
	f["pivotes"] = {}
	f["animando"] = false
	f["fase"] = randf() * 6.28
	f["quemadura"] = 0
	f["llama"] = null
	f["pose"] = "ini"
	f["cab_cerrada"] = null


# Devuelve la ruta del modelo 3D si existen el modelo y sus dos scripts; si no, "".
func _ruta_3d(m: Dictionary) -> String:
	if not ResourceLoader.exists(m["script"]) or not ResourceLoader.exists(m["gestos"]):
		return ""
	if m.has("base") and not ResourceLoader.exists(m["base"]):
		return ""
	for r in m["rutas"]:
		if ResourceLoader.exists(r):
			return r
	return ""


# Personaje 3D: se dibuja en una ventana 3D propia con fondo transparente
# y esa imagen se coloca en el combate como si fuera un sprite más.
func _crear_rig_3d(f: Dictionary, m: Dictionary, raiz: Node2D, base: Vector2, esc: float) -> void:
	var tam: Vector2i = m["vp"]
	var q := res_personajes                          # se dibuja más pequeño (75 %, en el móvil 70 %) y se amplía
	var vp := SubViewport.new()
	vp.size = Vector2i(int(tam.x * q), int(tam.y * q))
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE   # solo se dibuja mientras se ve
	raiz.add_child(vp)

	var cy: float = m["centro_y"]
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = m["alto_vista"]
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.86, 0.78)
	env.ambient_light_energy = 0.6
	cam.environment = env
	vp.add_child(cam)
	var ang := deg_to_rad(12.0)                      # cámara un poco desde arriba, como en FFIX
	cam.look_at_from_position(Vector3(0, cy + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, cy, 0))
	cam.current = true

	# Biblia de arte: luz dorada desde arriba a la izquierda (con un toque del color de la zona) y
	# relleno azul al 30 % desde la derecha
	var luz := DirectionalLight3D.new()
	luz.light_color = LUZ_PRINCIPAL.lerp(luz_3d, 0.3)
	luz.light_energy = 1.3
	luz.rotation_degrees = Vector3(-35, -40, 0)
	vp.add_child(luz)
	var relleno := DirectionalLight3D.new()
	relleno.light_color = LUZ_RELLENO
	relleno.light_energy = 0.3
	relleno.rotation_degrees = Vector3(-15, 140, 0)
	vp.add_child(relleno)

	var maga = load(m["script"]).new()
	maga.ruta_modelo = _ruta_3d(m)
	vp.add_child(maga)

	var cuerpo := Node2D.new()                       # su punto de giro está en los pies
	cuerpo.position = cam.unproject_position(Vector3.ZERO) / q
	raiz.add_child(cuerpo)
	var spr := Sprite2D.new()
	spr.texture = vp.get_texture()
	spr.centered = false
	spr.scale = Vector2.ONE / q
	spr.position = -cuerpo.position
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.modulate = m.get("tinte", Color.WHITE)       # un 3D teñido (como los jefes)
	cuerpo.add_child(spr)
	var nada := Node2D.new()
	cuerpo.add_child(nada)

	f["esc"] = esc
	f["rig"] = raiz
	f["rig_base"] = base
	f["cuerpo"] = cuerpo
	f["partes"] = {"brazo_a": nada, "sprite": spr}
	f["pivotes"] = {}
	f["animando"] = false
	f["fase"] = randf() * 6.28
	f["quemadura"] = 0
	f["llama"] = null
	f["pose"] = "ini"
	f["cab_cerrada"] = null
	f["p3d"] = maga
	f["cam3d"] = cam
	# centro del cuerpo en pantalla (para efectos y números de daño)
	f["centro_ofs"] = cam.unproject_position(Vector3(0, 0.85, 0)) / q * esc


# Personaje 3D (maga o Kael) de un luchador, o null si es 2D.
func _p3d(f: Dictionary):
	return f.get("p3d", null)


# Enemigo de una sola imagen (foto de un modelo 3D). El cuerpo gira y respira desde los pies.
func _crear_rig_imagen(f: Dictionary, m: Dictionary, raiz: Node2D, base: Vector2, esc: float) -> void:
	var cuerpo := Node2D.new()
	cuerpo.position = m["cadera"]
	raiz.add_child(cuerpo)
	var tam: float = m.get("tam", 1.0)
	var spr: Node2D
	if m.has("anims"):                               # varias poses (andar, alzar el arma, tajo...)
		var a := AnimatedSprite2D.new()
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		var carpeta: String = m["imagen"].get_base_dir()
		var prefijo: String = m["imagen"].get_file().get_slice("_", 0)
		for nombre in m["anims"]:
			var ruta := "%s/%s_%s.png" % [carpeta, prefijo, nombre]
			if not ResourceLoader.exists(ruta):
				continue
			var tira: Texture2D = load(ruta)
			var n: int = m["anims"][nombre][0]
			var w := tira.get_width() / n
			sf.add_animation(nombre)
			sf.set_animation_speed(nombre, m["anims"][nombre][1])
			sf.set_animation_loop(nombre, true)
			for i in n:
				var trozo := AtlasTexture.new()
				trozo.atlas = tira
				trozo.region = Rect2(i * w, 0, w, tira.get_height())
				sf.add_frame(nombre, trozo)
		a.sprite_frames = sf
		a.centered = false
		a.offset = -m["pies"]
		a.play("guardia")
		spr = a
	else:
		var s := Sprite2D.new()
		if ResourceLoader.exists(m["imagen"]):
			s.texture = load(m["imagen"])
		s.centered = false
		if s.texture != null:
			s.offset = Vector2(-s.texture.get_width() * 0.5, -s.texture.get_height())
		spr = s
	spr.scale = Vector2(tam, tam)
	spr.modulate = m.get("tinte", Color.WHITE)       # Gorthor 2D (respaldo): teñido de rojo
	cuerpo.add_child(spr)
	var nada := Node2D.new()
	cuerpo.add_child(nada)
	f["esc"] = esc
	f["rig"] = raiz
	f["rig_base"] = base
	f["cuerpo"] = cuerpo
	f["partes"] = {"brazo_a": nada, "imagen": spr}
	f["pivotes"] = {}
	f["animando"] = false
	f["fase"] = randf() * 6.28
	f["quemadura"] = 0
	f["llama"] = null
	f["pose"] = "ini"
	f["cab_cerrada"] = null


# Cambia la pose de un enemigo de imagen con varias poses (si no tiene, no hace nada).
func _pose_img(f: Dictionary, nombre: String) -> void:
	var a = f["partes"].get("imagen")
	if a is AnimatedSprite2D and a.sprite_frames.has_animation(nombre):
		a.play(nombre)


# Enemigo de imagen: avanza (andando si tiene la pose), alza el arma, se lanza con un tajo y vuelve.
func _anim_fisico_imagen(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var cuerpo: Node2D = o["cuerpo"]
	var poses: bool = MODELOS[o["modelo"]].has("anims")
	var k := 0.35 if poses else 1.0                  # con poses de verdad, menos balanceo de la imagen
	var dist: float = ANIM[o["modelo"]]["distancia"]
	var dx: float = obj["pos"].x - o["pos"].x - dist
	var dy: float = (obj["pos"].y - o["pos"].y) * 0.8
	o["animando"] = true
	rig.z_index = 5
	_pose_img(o, "andar")
	var t1 := create_tween()
	t1.tween_property(rig, "position", base + Vector2(dx, dy), 0.6 if poses else 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.parallel().tween_property(cuerpo, "rotation_degrees", 6.0 * k, 0.45)
	await t1.finished
	_pose_img(o, "prep")                             # alza el arma
	var t2 := create_tween()
	t2.tween_property(cuerpo, "rotation_degrees", -14.0 * k, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t2.parallel().tween_property(cuerpo, "scale", Vector2(0.95, 1.05), 0.25)
	await t2.finished
	_pose_img(o, "tajo")                             # tajo hacia delante
	var t3 := create_tween()
	t3.tween_property(cuerpo, "rotation_degrees", 18.0 * k, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t3.parallel().tween_property(cuerpo, "scale", Vector2(1.06, 0.95), 0.1)
	t3.parallel().tween_property(rig, "position", base + Vector2(dx + 25, dy), 0.1)
	await t3.finished
	impacto.call()
	if poses:
		_temblor(5.0)
	await get_tree().create_timer(0.35).timeout
	_pose_img(o, "andar")
	var t4 := create_tween()
	t4.tween_property(cuerpo, "rotation_degrees", 0.0, 0.3)
	t4.parallel().tween_property(cuerpo, "scale", Vector2.ONE, 0.3)
	t4.parallel().tween_property(rig, "position", base, 0.55 if poses else 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t4.finished
	_pose_img(o, "guardia")
	rig.z_index = 0
	o["animando"] = false


func _es_sprite(f: Dictionary) -> bool:
	return MODELOS[f["modelo"]].get("tipo", "") == "sprite"


# Reproduce una animación de un personaje de sprite y, si no es de bucle, vuelve al reposo al acabar.
func _reproducir(f: Dictionary, nombre: String, volver := true) -> void:
	if not _es_sprite(f):
		return
	var anim: AnimatedSprite2D = f["partes"]["anim"]
	anim.play(nombre)
	if volver and not anim.sprite_frames.get_animation_loop(nombre):
		anim.animation_finished.connect(func():
			if anim.animation == nombre and f["hp"] > 0:
				anim.play("idle"), CONNECT_ONE_SHOT)


func _alto_barra(f: Dictionary) -> float:
	return MODELOS[f["modelo"]].get("barra_y", -8.0)


# La espada sigue a la mano en cada fotograma del reposo.
func _seguir_fotograma(f: Dictionary) -> void:
	var m: Dictionary = MODELOS[f["modelo"]]
	var i: int = f["partes"]["anim"].frame
	var e: Sprite2D = f["partes"]["arma"]
	e.position = m["agarres"][i] - m["cadera"]
	if not f["animando"]:
		e.rotation_degrees = m["angs"][i]


func _ang_reposo(f: Dictionary) -> float:
	var m: Dictionary = MODELOS[f["modelo"]]
	return m["angs"][f["partes"]["anim"].frame]


func _es_frames(f: Dictionary) -> bool:
	return MODELOS[f["modelo"]].get("tipo", "") == "frames"


const HUESOS := {"f": "brazo_f", "codo_f": "antebrazo_f", "arma": "arma", "a": "brazo_a", "codo_a": "antebrazo_a"}


func _fijar_pose(o: Dictionary, v: Dictionary) -> void:
	var p: Dictionary = o["partes"]
	for k in HUESOS:
		if v.has(k) and p.has(HUESOS[k]):
			p[HUESOS[k]].rotation_degrees = v[k]
	o["cuerpo"].rotation_degrees = v.get("lean", 0.0)
	if p.has("arma"):
		p["arma"].z_index = int(v.get("z", 0))
	_manos(o, v)


# Cambia el dibujo de las manos según la pose: una mano o las dos en la empuñadura.
func _manos(o: Dictionary, v: Dictionary) -> void:
	if not o.has("tex"):
		return
	var p: Dictionary = o["partes"]
	var tx: Dictionary = o["tex"]
	var e: String = "esp_" + str(v.get("esp", "g"))
	if tx.has(e) and p.has("arma"):
		p["arma"].texture = tx[e]
	var m: String = "ma_%d" % int(v.get("ma", 1))
	if tx.has(m) and p.has("antebrazo_a"):
		p["antebrazo_a"].texture = tx[m]


# Mueve todas las articulaciones hacia una pose, siempre por el camino más corto.
func _tween_pose(o: Dictionary, v: Dictionary, dur: float, golpe := false) -> Tween:
	var p: Dictionary = o["partes"]
	if p.has("arma"):
		p["arma"].z_index = int(v.get("z", 0))
	var dos_manos: bool = int(v.get("ma", 1)) == 2
	if not dos_manos:
		_manos(o, v)
	var t := create_tween().set_parallel(true)
	for k in HUESOS:
		if v.has(k) and p.has(HUESOS[k]):
			var actual: float = p[HUESOS[k]].rotation_degrees
			var destino: float = actual + wrapf(v[k] - actual, -180.0, 180.0)
			var tw := t.tween_property(p[HUESOS[k]], "rotation_degrees", destino, dur)
			if golpe:
				tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			else:
				tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(o["cuerpo"], "rotation_degrees", v.get("lean", 0.0), dur)
	if dos_manos:
		t.finished.connect(_manos.bind(o, v))   # la segunda mano se cierra al llegar a la empuñadura
	return t


func _pose_a(o: Dictionary) -> float:
	var a: Dictionary = ANIM[o["modelo"]]
	if a.has("poses"):
		return a["poses"][o["pose"]].get("a", 0.0)
	return 0.0


# ================================================================= bucle ATB

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for f in heroes + enemigos:
		if f["hp"] > 0:
			f["cuerpo"].scale = Vector2(1.0, 1.0 + 0.012 * sin(t * 1.9 + f["fase"]))
			if not f["animando"]:
				f["partes"]["brazo_a"].rotation_degrees = _pose_a(f) + sin(t * 1.6 + f["fase"] + 1.0) * 2.0
				if not ANIM[f["modelo"]].has("poses"):
					f["cuerpo"].rotation_degrees = sin(t * 1.3 + f["fase"]) * 0.8
		if f.has("sombra"):
			_mover_sombra(f)
	if estado == "esperando":                        # jefes: cambio de fase y último aliento, antes de otro turno
		for e in enemigos:
			if e.get("fase2_pendiente", false):
				e["fase2_pendiente"] = false
				_cambio_fase(e)
				return
			if e.get("rendido", false) and not e.get("decidido", false):
				_decidir(e)
				return
	if flecha.visible and objetivo_apuntado != null:
		flecha.position = _pos_flecha(objetivo_apuntado) + Vector2(0, sin(t * 7.0) * 6.0)
	if estado == "fin":
		return
	for f in heroes + enemigos:
		if f["hp"] > 0 and f["atb"] < ATB_MAX:
			f["atb"] = min(ATB_MAX, f["atb"] + f["vel"] * delta)
			if f["atb"] >= ATB_MAX:
				cola.append(f)
	_siguiente_turno()
	_actualizar()


func _siguiente_turno() -> void:
	if estado != "esperando" or cola.is_empty():
		return
	var f = cola.pop_front()
	if f["hp"] <= 0:
		return
	if f["hero"]:
		actor = f
		if f.get("defendiendo", false):          # la defensa dura hasta su siguiente turno
			f["defendiendo"] = false
			f["rig"].modulate = Color(1, 1, 1)
		_mostrar_menu()
	else:
		estado = "enemigo"
		_turno_enemigo(f)


# Turno de un enemigo: decide qué hacer según su personalidad (ENEMIGOS[...]["personalidad"]):
#   agresivo: va a por la curandera si ha curado; si no, a por el héroe con menos PV
#   bruto:    golpea a cualquiera, más fuerte cuando tiene rabia
#   cobarde:  ataca al más débil y huye si se queda solo y herido
#   apoyo:    cura al aliado más herido (chamanes); si no hay heridos, ataca
#   jefe:     como agresivo, y a veces carga un turno (con aviso) su golpe más fuerte a todos
# Con menos del 30 % de vida entran en furia: pegan un 50 % más.
func _turno_enemigo(f: Dictionary) -> void:
	if f.get("rendido", false):                     # de rodillas: espera la decisión de Kael
		_fin_turno_enemigo(f)
		return
	if f["quemadura"] > 0:
		await _tic_quemadura(f)
		if f["hp"] <= 0:
			f["atb"] = 0.0
			if not _comprobar_fin():
				estado = "esperando"
			return
	_tic_congelacion(f)
	var p: String = f.get("personalidad", "agresivo")
	var vivos := heroes.filter(func(h): return h["hp"] > 0)
	var aliados := enemigos.filter(func(e): return e["hp"] > 0)
	if not f.get("furia", false) and f["hp"] < f["hp_max"] * 0.3:
		f["furia"] = true
		_numero_flotante(f, "¡Furia!", Color(1.0, 0.35, 0.2), 34)
		_actualizar()
	var mult := 1.5 if f.get("furia", false) else 1.0
	if p == "bruto":
		mult *= randf_range(0.9, 1.3)
	# huir (en una «zona limpia», con el grupo muy por encima, los enemigos débiles huyen solos)
	var limpia: bool = load("res://progreso.gd").zona_limpia(Engine.get_meta("zona", "llanura"))
	if p != "jefe" and limpia and randf() < 0.7:
		await _huir(f)
		_fin_turno_enemigo(f)
		return
	if p == "cobarde" and aliados.size() == 1 and f["hp"] < f["hp_max"] * 0.6 and randf() < 0.5:
		await _huir(f)
		_fin_turno_enemigo(f)
		return
	# curar a un aliado
	if p == "apoyo":
		var herido = null
		for e in aliados:
			if e["hp"] < e["hp_max"] * 0.5 and (herido == null or e["hp"] * 1.0 / e["hp_max"] < herido["hp"] * 1.0 / herido["hp_max"]):
				herido = e
		if herido != null:
			var c: int = mini(int(herido["hp_max"] * 0.3), herido["hp_max"] - herido["hp"])
			registro.text = "%s cura a %s" % [f["nombre"], herido["nombre"]]
			herido["hp"] += c
			_efecto_cura(herido)
			_numero_flotante(herido, "+%d" % c, C_CURA)
			_actualizar()
			await get_tree().create_timer(1.0).timeout
			_restablecer_color(herido)
			_fin_turno_enemigo(f)
			return
	# segunda fase de Gorthor: Devorar (muerde al más débil y se cura con parte del daño)
	if f.get("fase2", false) and not f.get("cargando", false) and randf() < 0.35:
		var presa := _elegir_objetivo("cobarde", vivos)
		var mordisco: int = int(f["atk"] * 1.6 * mult) + randi_range(-2, 3)
		registro.text = "¡%s devora a %s!" % [f["nombre"], presa["nombre"]]
		await _animar_golpe(f, presa, mordisco, "")
		var cura: int = mini(int(mordisco * 0.6), f["hp_max"] - f["hp"])
		if cura > 0 and f["hp"] > 0:
			f["hp"] += cura
			_numero_flotante(f, "+%d" % cura, C_CURA)
			_actualizar()
		_fin_turno_enemigo(f)
		return
	# el jefe carga su golpe más fuerte (un turno de aviso); en la segunda fase, más a menudo
	if p == "jefe" and not f.get("cargando", false) and randf() < (0.45 if f.get("fase2", false) else 0.35):
		f["cargando"] = true
		registro.text = "¡%s se prepara para un golpe devastador!" % f["nombre"]
		_numero_flotante(f, "⚠ ¡Cuidado!", Color(1.0, 0.8, 0.2), 34)
		_particulas(_centro(f) + Vector2(0, 100), Color(1.0, 0.7, 0.2, 0.9), Color(1.0, 0.3, 0.0, 0.0), 40, 1.0,
			Vector2(40, 120), 90.0, Vector2(0, -1), 20.0, Vector2(0, -60), 0.1)
		_actualizar()
		await get_tree().create_timer(1.2).timeout
		_fin_turno_enemigo(f)
		return
	var objetivo = _elegir_objetivo(p, vivos)
	if f.get("cargando", false):                # descarga: golpe fuerte a todo el grupo
		f["cargando"] = false
		registro.text = "¡%s desata su golpe devastador!" % f["nombre"]
		var fuerte := int(f["atk"] * 2.2 * mult)
		f["descarga"] = true                         # Grimfang / Gorthor: golpe fuerte a dos manos
		await _animar_golpe(f, objetivo, fuerte, "")
		f["descarga"] = false
		for h in vivos:
			if h != objetivo and h["hp"] > 0:
				var d2: int = maxi(1, fuerte - int(h.get("def", 0) / 2.0))
				h["hp"] = maxi(0, h["hp"] - d2)
				_golpe_visual(h, d2, "")
		_temblor(14.0)
	else:
		var dano: int = int(f["atk"] * mult) + randi_range(-2, 3)
		registro.text = "%s ataca a %s" % [f["nombre"], objetivo["nombre"]]
		await _animar_golpe(f, objetivo, dano, "")
	_fin_turno_enemigo(f)


func _elegir_objetivo(p: String, vivos: Array) -> Dictionary:
	if p in ["agresivo", "jefe"]:
		for h in vivos:                          # la curandera primero
			if h.get("curo", false):
				return h
	if p == "bruto":
		return vivos.pick_random()
	var debil: Dictionary = vivos[0]               # el que tiene menos PV
	for h in vivos:
		if h["hp"] < debil["hp"]:
			debil = h
	return debil


func _fin_turno_enemigo(f: Dictionary) -> void:
	f["atb"] = 0.0
	_actualizar()
	await get_tree().create_timer(0.3).timeout
	if not _comprobar_fin():
		estado = "esperando"


# Un enemigo cobarde sale corriendo del combate (no da experiencia ni oro).
func _huir(f: Dictionary) -> void:
	registro.text = "¡%s huye!" % f["nombre"]
	f["huido"] = true
	var rig: Node2D = f["rig"]
	var t := create_tween()
	t.tween_property(rig, "position:x", rig.position.x - 500.0, 0.6).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(rig, "modulate:a", 0.0, 0.6)
	await t.finished
	f["hp"] = 0
	if f.has("sombra"):
		f["sombra"].visible = false
	_actualizar()


# ---------------------------------------------------------------- Congelación (Frostfang)

func _lleva_frostfang(f: Dictionary) -> bool:
	if not ResourceLoader.exists("res://inventario.gd"):
		return false
	return load("res://inventario.gd").equipo_de(f["nombre"]).get("arma", "") == "frostfang"


func _congelar(f: Dictionary) -> void:
	if f.get("congelado", 0) <= 0:                   # pierde Vitalidad: menos PV máximos
		var quitar := VITALIDAD_CONGELACION * 8
		f["congel_quitado"] = quitar
		f["hp_max"] = maxi(1, f["hp_max"] - quitar)
		f["hp"] = mini(f["hp"], f["hp_max"])
		_numero_flotante(f, "❄ Congelado", C_HIELO, 32)
		_particulas(_centro(f), Color(0.85, 0.97, 1.0, 1.0), Color(0.4, 0.75, 1.0, 0.0), 30, 0.8, Vector2(40, 140),
			60.0, Vector2(0, -1), 180.0, Vector2(0, 60), 0.07)
	f["congelado"] = RONDAS_CONGELACION
	f["cuerpo"].modulate = Color(0.6, 0.85, 1.35)
	_actualizar()


func _tic_congelacion(f: Dictionary) -> void:
	if f.get("congelado", 0) <= 0:
		return
	f["congelado"] -= 1
	if f["congelado"] <= 0:                          # vuelve a la normalidad
		f["hp_max"] += f.get("congel_quitado", 0)
		f["congel_quitado"] = 0
		f["cuerpo"].modulate = Color(1, 1, 1)
		_numero_flotante(f, "Descongelado", Color(0.8, 0.9, 1.0), 24)
	_actualizar()


# ================================================================= menús del jugador

# Volver atrás: Esc / botón B del mando / botón atrás del móvil, tocar «‹ Kael» o tocar fuera del menú.
func _atras() -> void:
	if estado == "objetivo":
		_limpiar_objetivo()
		if volver_obj.is_valid():
			volver_obj.call()
		else:
			_mostrar_menu()
	elif estado in ["magia", "pocion"]:
		_mostrar_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_atras()
	elif estado == "objetivo" and not objetivos_posibles.is_empty():
		var paso := 0
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
			paso = -1
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
			paso = 1
		if paso != 0:
			var i := wrapi(objetivos_posibles.find(objetivo_apuntado) + paso, 0, objetivos_posibles.size())
			_apuntar(objetivos_posibles[i])
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") and objetivo_apuntado != null:
			get_viewport().set_input_as_handled()
			_confirmar_objetivo(objetivo_apuntado)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:   # botón atrás de Android
		_atras()


func _toque_fuera(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		if estado == "accion":
			saltar_invocacion = true
			if inv_erebo != null:
				inv_erebo.saltar()
		else:
			_atras()


# Elegir objetivo tocándolo: cada candidato tiene una zona táctil más grande que su dibujo.
# Encima del apuntado rebota una flecha y arriba a la izquierda sale su nombre.
func _pedir_objetivo(candidatos: Array, al_elegir: Callable, volver: Callable, texto: String) -> void:
	estado = "objetivo"
	_limpiar_objetivo()
	objetivos_posibles = candidatos
	al_elegir_obj = al_elegir
	volver_obj = volver
	menu.aviso(texto)
	for f in candidatos:
		var z := Control.new()
		var c := _a_pantalla(_centro(f))
		z.position = c - Vector2(80, 140) * TAM_ESCENA - Vector2(30, 30)
		z.size = Vector2(160, 300) * TAM_ESCENA + Vector2(60, 60)
		var quien = f
		z.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
				_apuntar(quien)
				_confirmar_objetivo(quien))
		z.mouse_entered.connect(func(): _apuntar(quien))
		capa_zonas.add_child(z)
	fuera.visible = true
	_apuntar(candidatos[0])


func _apuntar(f: Dictionary) -> void:
	if objetivo_apuntado != null and objetivo_apuntado != f:
		menu.sonar("tic")
	objetivo_apuntado = f
	flecha.visible = true
	flecha.position = _pos_flecha(f)
	obj_nombre.text = f["nombre"]
	obj_nombre.visible = true
	obj_linea.visible = true
	obj_linea.color = Color(menu.COLOR_HEROE.get(f["nombre"], menu.LUZ_CLARA), 0.85)


func _pos_flecha(f: Dictionary) -> Vector2:
	var y: float = _centro(f).y - 170.0 if f.has("centro_ofs") else f["pos"].y + _alto_barra(f) - 40.0
	return _a_pantalla(Vector2(_centro(f).x, y)) - Vector2(18, 30)


func _confirmar_objetivo(f: Dictionary) -> void:
	if estado != "objetivo":
		return
	menu.sonar("confirmar")
	var c := al_elegir_obj
	_limpiar_objetivo()
	c.call(f)


func _limpiar_objetivo() -> void:
	for z in capa_zonas.get_children():
		z.queue_free()
	objetivos_posibles = []
	objetivo_apuntado = null
	flecha.visible = false
	obj_nombre.visible = false
	obj_linea.visible = false
	fuera.visible = false


func _ocultar_menu() -> void:
	menu.cerrar()
	_limpiar_objetivo()


func _puede_pagar(coste: int) -> bool:
	return MODO_PRUEBAS or actor["mp"] >= coste


func _mostrar_menu() -> void:
	estado = "menu"
	_limpiar_objetivo()
	registro.text = ""
	if _es_garon(actor):                          # Garon: su menú propio (Esgrima y Embuir)
		_menu_garon()
		return
	var coste_min := 999
	for h in _hechizos(actor):
		coste_min = min(coste_min, h[2]["coste"])
	var lya_viva := heroes.any(func(h): return h["nombre"] == "Lya" and h["hp"] > 0)   # Érebo lo invoca Lya
	menu.abrir(actor, [
		{"tipo": "carta", "texto": "ATACAR", "accion": func(): _menu_objetivo("atacar", ""),
			"texto_b": "DEFENDER", "accion_b": _defender},
		{"texto": "MAGIA", "accion": _menu_magia, "apagado": coste_min == 999 or not _puede_pagar(coste_min)},
		{"tipo": "invocacion", "texto": "INVOCACIÓN", "accion": _invocar, "apagado": armonia < 1.0 or not lya_viva},
		{"texto": "OBJETO", "accion": _menu_pocion, "apagado": _cantidad_objeto("Poción") + _cantidad_objeto("Éter") <= 0},
		{"texto": "HUIR", "accion": _escapar, "apagado": Engine.get_meta("tipo_combate", "normal") != "normal"},
	])
	_pruebas_menu()


func _pruebas_menu() -> void:
	if "invocar" in OS.get_cmdline_user_args() and actor["nombre"] == "Lya" and not get_meta("invocado", false):
		set_meta("invocado", true)                 # pruebas: -- invocar (Lya invoca a Érebo en su primer turno)
		armonia = 1.0
		var obj: Dictionary = enemigos.filter(func(e): return e["hp"] > 0)[0]
		_invocar_sobre.call_deferred(obj)
		return
	for a in OS.get_cmdline_user_args():          # pruebas: godot ... -- objeto=Éter (lo usa en sí mismo)
		if a.begins_with("objeto=") and _cantidad_objeto(a.substr(7)) > 0:
			actor["mp"] = 1
			actor["hp"] = int(actor["hp_max"] * 0.4)
			_usar_objeto.call_deferred(a.substr(7), actor)
			return
	for a in OS.get_cmdline_user_args():          # pruebas: godot ... -- magia=Fuego:3 (lanza sola en cada turno)
		if a.begins_with("magia="):
			for h in _hechizos(actor):
				if "%s:%d" % [h[0], h[1]] == a.substr(6) or (h[0] == a.substr(6) and h[1] == 1):
					if actor["mp"] >= h[2]["coste"]:
						_elegir_hechizo.call_deferred(h[0], h[1], true)
						return
	if "auto" in OS.get_cmdline_user_args():      # pruebas: -- auto (si no lanza magia, ataca)
		accion = "atacar"
		_aplicar.call_deferred(enemigos.filter(func(e): return e["hp"] > 0)[0])


# ---------------------------------------------------------------- Garon: Esgrima y Embuir
# Su menú no tiene Magia ni Invocación: Atacar/Defender y Objeto igual que los demás, y
#   ESGRIMA: técnicas con las dos espadas que gastan PM (TECNICAS_GARON).
#   EMBUIR:  pone un elemento en las dos hojas durante 3 turnos suyos: sus golpes hacen ese daño
#            y un 20 % más (Fuego quema, Hielo puede congelar como Frostfang). 5 PM.
const TECNICAS_GARON := {
	"Juicio": {"mult": 1.8, "coste": 6, "golpes": 1, "todos": false,
		"desc": "Salta y cae con un tajo descendente sobre un enemigo. Daño ×1,8."},
	"Giro": {"mult": 0.9, "coste": 10, "golpes": 2, "todos": true,
		"desc": "Gira con las dos hojas: 2 golpes a todos los enemigos (×0,9 cada uno)."},
}
const EMBUIR := {"coste": 5, "turnos": 3, "extra": 0.2, "elementos": ["Fuego", "Hielo", "Rayo", "Agua"]}
const DESC_EMBUIR := {
	"Fuego": "Hojas en llamas: sus golpes queman.",
	"Hielo": "Hojas de escarcha: sus golpes pueden congelar.",
	"Rayo": "Hojas cargadas de rayos.",
	"Agua": "Hojas envueltas en agua.",
}


func _es_garon(f) -> bool:
	return f != null and f["nombre"] == "Garon"


func _menu_garon() -> void:
	var minimo := 999
	for t in TECNICAS_GARON.values():
		minimo = mini(minimo, t["coste"])
	menu.abrir(actor, [
		{"tipo": "carta", "texto": "ATACAR", "accion": func(): _menu_objetivo("atacar", ""),
			"texto_b": "DEFENDER", "accion_b": _defender},
		{"texto": "ESGRIMA", "accion": _menu_esgrima, "apagado": not _puede_pagar(minimo)},
		{"texto": "EMBUIR", "accion": _menu_embuir, "apagado": not _puede_pagar(EMBUIR["coste"])},
		{"texto": "OBJETO", "accion": _menu_pocion, "apagado": _cantidad_objeto("Poción") + _cantidad_objeto("Éter") <= 0},
		{"texto": "HUIR", "accion": _escapar, "apagado": Engine.get_meta("tipo_combate", "normal") != "normal"},
	])
	for a in OS.get_cmdline_user_args():          # pruebas: -- esgrima=Giro / embuir=Fuego (en cada turno de Garon)
		if a.begins_with("embuir=") and actor.get("embuir", "") == "":
			_embuir.call_deferred(a.substr(7))
			return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("esgrima="):
			var n := a.substr(8)
			if TECNICAS_GARON.has(n):
				if TECNICAS_GARON[n]["todos"]:
					_tecnica_garon.call_deferred(n, {})
				else:
					_tecnica_garon.call_deferred(n, enemigos.filter(func(e): return e["hp"] > 0)[0])
				return
	_pruebas_menu()


func _menu_esgrima() -> void:
	estado = "magia"                               # «atrás» vuelve al menú, como en Magia
	var items: Array = []
	for n in TECNICAS_GARON:
		var t: Dictionary = TECNICAS_GARON[n]
		items.append({"texto": n, "accion": _elegir_tecnica.bind(n), "icono": actor.get("embuir", "") if actor.get("embuir", "") != "" else null,
			"derecha": "%d PM" % t["coste"], "apagado": not _puede_pagar(t["coste"]), "desc": t["desc"]})
	for it in items:
		if it["icono"] == null:
			it.erase("icono")
	menu.submenu(items)


func _elegir_tecnica(n: String) -> void:
	if TECNICAS_GARON[n]["todos"]:
		_tecnica_garon(n, {})
	else:
		_pedir_objetivo(enemigos.filter(func(e): return e["hp"] > 0), func(f): _tecnica_garon(n, f), _menu_esgrima,
			"TOCA UN ENEMIGO")


func _menu_embuir() -> void:
	estado = "magia"
	var items: Array = []
	for el in EMBUIR["elementos"]:
		var activo: bool = actor.get("embuir", "") == el
		items.append({"texto": el, "accion": _embuir.bind(el), "icono": el, "apagado": not _puede_pagar(EMBUIR["coste"]),
			"derecha": "%d PM" % EMBUIR["coste"],
			"desc": DESC_EMBUIR[el] + (" (activo: %d turnos)" % actor.get("embuir_turnos", 0) if activo else " Dura 3 turnos, +20 % de daño.")})
	menu.submenu(items)


# Daño físico de un golpe de Garon (con Embuir, +20 %).
func _dano_fisico(quien: Dictionary, mult := 1.0) -> int:
	var d: float = quien["atk"] * quien.get("mult_fisico", 1.0) * mult
	if quien.get("embuir", "") != "":
		d *= 1.0 + EMBUIR["extra"]
	return maxi(1, int(d) + randi_range(-2, 3))


func _embuir(el: String) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	_gastar_pm(quien, EMBUIR["coste"])
	quien["embuir"] = el
	quien["embuir_turnos"] = EMBUIR["turnos"]
	quien["embuir_nuevo"] = true                    # este turno no cuenta
	registro.text = "Garon imbuye sus espadas: %s" % el
	var col: Color = menu.COLOR_ELEMENTO.get(el, Color.WHITE)
	var p = _p3d(quien)
	if p != null and p.has_method("embuir"):
		p.embuir(el)
	_luz(col, 2.0, 4.0, 1.2, _centro(quien))
	_particulas(_centro(quien) + Vector2(0, 40), Color(col, 1.0), Color(col, 0.0), 34, 1.0, Vector2(40, 120), 70.0,
		Vector2(0, -1), 40.0, Vector2(0, -60), 0.07)
	_onda(_suelo_de(quien), Color(col, 0.9), 20.0, 170.0, 0.7, 8.0)
	_numero_flotante(quien, el, col, 34)
	_actualizar()
	await get_tree().create_timer(0.9).timeout
	_terminar_turno()


# Con Embuir: su efecto en cada golpe (el dibujo del elemento; Hielo puede congelar).
func _efecto_embuir(quien: Dictionary, obj: Dictionary) -> String:
	var el: String = quien.get("embuir", "")
	if el == "Hielo":
		if obj["hp"] > 0 and randf() < PROB_CONGELAR:
			_congelar(obj)
		return ""
	return el


# Técnica de Esgrima: Juicio (un enemigo) o Giro (todos, dos golpes).
func _tecnica_garon(n: String, obj: Dictionary) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	var t: Dictionary = TECNICAS_GARON[n]
	_gastar_pm(quien, t["coste"])
	_actualizar()
	registro.text = "Garon usa %s" % n
	_numero_flotante(quien, n, menu.COLOR_HEROE.get("Garon", Color.WHITE), 34)
	if not t["todos"]:
		var d := _dano_fisico(quien, t["mult"])
		var impacto := func():
			_quitar_pv(obj, d)
			_destello(_centro(obj), menu.COLOR_HEROE.get("Garon", Color.WHITE).lightened(0.4), 1.8)
			_golpe_visual(obj, d, _efecto_embuir(quien, obj))
		if _p3d(quien) != null and _p3d(quien).has_method("atacar_juicio"):
			await _anim_ataque_3d(quien, obj, impacto, "atacar_juicio")
		else:
			await _animar_golpe(quien, obj, d, "")
	else:
		var objs := enemigos.filter(func(e): return e["hp"] > 0)
		var impacto := func():
			for e in objs:
				if e["hp"] <= 0:
					continue
				var d := _dano_fisico(quien, t["mult"])
				_quitar_pv(e, d)
				_golpe_visual(e, d, _efecto_embuir(quien, e))
			_temblor(6.0)
		var centro: Dictionary = objs[0]               # se planta delante del enemigo del medio
		var medio := 0.0
		for e in objs:
			medio += _centro(e).x / objs.size()
		for e in objs:
			if absf(_centro(e).x - medio) < absf(_centro(centro).x - medio):
				centro = e
		if _p3d(quien) != null and _p3d(quien).has_method("atacar_giro"):
			await _anim_ataque_3d(quien, centro, impacto, "atacar_giro")
		else:
			for i in t["golpes"]:
				impacto.call()
				await get_tree().create_timer(0.5).timeout
	_terminar_turno()


# Magias que conoce un héroe: [magia, nivel, datos del nivel]. Sin grupo.gd, todas a nivel I.
func _hechizos(f: Dictionary) -> Array:
	var r: Array = []
	var gr = load("res://grupo.gd") if ResourceLoader.exists("res://grupo.gd") else null
	for k in NIVELES_MAGIA:
		var n := 1
		if gr != null and gr.datos().has(f["nombre"]):
			n = gr.nivel_magia(f["nombre"], k)
		for i in n:
			r.append([k, i + 1, NIVELES_MAGIA[k][i]])
	return r


# Menú de magia: arriba las pestañas de nivel (I, II, III; solo las que sabe) y debajo las magias de
# ese nivel con el icono de su elemento, su nombre y su coste (con el modo pruebas, «PM ∞»).
# Debajo, una línea explica la magia elegida.
const NIVELES_ROMANOS := ["I", "II", "III"]


func _menu_magia(nivel := 0) -> void:
	estado = "magia"
	var por_nivel := [[], [], []]
	for h in _hechizos(actor):
		por_nivel[h[1] - 1].append(h)
	if nivel == 0:
		nivel = magia_nivel_menu.get(actor["nombre"], 1)
	if por_nivel[nivel - 1].is_empty():
		nivel = 1
	magia_nivel_menu[actor["nombre"]] = nivel
	var pestanas: Array = []
	var activa := 0
	for n in 3:
		if not por_nivel[n].is_empty():
			if n + 1 == nivel:
				activa = pestanas.size()
			pestanas.append({"texto": NIVELES_ROMANOS[n], "accion": _menu_magia.bind(n + 1)})
	if pestanas.size() < 2:
		pestanas = []
	var items: Array = []
	for h in por_nivel[nivel - 1]:
		var d: Dictionary = h[2]
		items.append({"texto": d["nombre"], "accion": _elegir_hechizo.bind(h[0], h[1]), "icono": h[0],
			"derecha": "PM ∞" if MODO_PRUEBAS else "%d PM" % d["coste"], "apagado": not _puede_pagar(d["coste"]),
			"desc": _desc_magia(h[0], d)})
	menu.submenu(items, pestanas, activa)


func _desc_magia(magia: String, d: Dictionary) -> String:
	var a: String = "todos los enemigos" if d["todos"] else "un enemigo"
	match magia:
		"Fuego":
			return "Llamas sobre %s. Pueden quemar." % a
		"Agua":
			return "Un géiser de agua golpea a %s." % a
		"Rayo":
			return "Un rayo cae sobre %s." % a
		"Cura":
			return "Recupera PV a %s." % ("todo el grupo" if d["todos"] else "un aliado")
	return ""


# Una magia de nivel I se dirige a un enemigo; las de nivel II y III van a todos a la vez.
func _elegir_hechizo(magia: String, nivel: int, sola := false) -> void:
	nivel_sel = nivel
	if MAGIAS[magia].get("cura", false):           # magia de curación: se elige a un aliado
		magia_sel = magia
		if NIVELES_MAGIA[magia][nivel - 1]["todos"]:
			_aplicar_cura(heroes.filter(func(h): return h["hp"] > 0))
		elif sola:                                 # pruebas: al más herido
			var vivos := heroes.filter(func(h): return h["hp"] > 0)
			vivos.sort_custom(func(a, b): return float(a["hp"]) / a["hp_max"] < float(b["hp"]) / b["hp_max"])
			_aplicar_cura([vivos[0]])
		else:
			_menu_aliado()
		return
	if NIVELES_MAGIA[magia][nivel - 1]["todos"]:
		accion = "magia"
		magia_sel = magia
		_aplicar_todos()
	elif sola:
		accion = "magia"
		magia_sel = magia
		_aplicar(enemigos.filter(func(e): return e["hp"] > 0)[0])
	else:
		_menu_objetivo("magia", magia)


# Elegir a qué aliado curar: se toca al héroe.
func _menu_aliado() -> void:
	_pedir_objetivo(heroes.filter(func(h): return h["hp"] > 0), func(f): _aplicar_cura([f]), _menu_magia.bind(0),
		"TOCA A UN ALIADO")


func _aplicar_cura(objetivos: Array) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	var d: Dictionary = NIVELES_MAGIA[magia_sel][nivel_sel - 1]
	_gastar_pm(quien, d["coste"])
	quien["curo"] = true                          # los enemigos listos irán a por quien cura
	_actualizar()
	registro.text = "%s lanza %s" % [quien["nombre"], d["nombre"]]
	var cantidad := int(d["dano"] * quien.get("magia_mult", 1.0)) + int(quien.get("magia_extra", 0))
	await _lanzar_cura(quien, objetivos, cantidad, nivel_sel)
	_terminar_turno()


# Curación: círculo bajo quien la lanza y, sobre cada aliado curado, el pilar de luz verde y dorada
# (HealingVFX.tscn) con chispas que suben y los PV recuperados.
func _lanzar_cura(o: Dictionary, objs: Array, cantidad: int, nivel: int) -> void:
	o["animando"] = true
	var circulo := _carga_magia(o, "Cura", 1.0 + 0.3 * (nivel - 1))
	var maga = _p3d(o)
	if maga != null:
		await maga.lanzar_magia()
	else:
		await get_tree().create_timer(0.5).timeout
	if nivel == 3:
		_fogonazo(Color(1.0, 0.95, 0.6), 0.25, 0.6)
	for obj in objs:
		var c: int = mini(cantidad + randi_range(-3, 3), obj["hp_max"] - obj["hp"])
		obj["hp"] += c
		_efecto_cura(obj)
		_numero_flotante(obj, "+%d" % c, C_CURA)
	_actualizar()
	_quitar_carga(circulo)
	await get_tree().create_timer(1.2).timeout
	for obj in objs:
		_restablecer_color(obj)
	if maga != null:
		maga.fin_magia()
	await get_tree().create_timer(0.3).timeout
	o["animando"] = false


func _efecto_cura(obj: Dictionary) -> void:
	var suelo := _suelo_de(obj)
	if not _vfx_3d(VFX_CURA, suelo):
		_onda(suelo, Color(1.0, 0.9, 0.4, 0.9), 20.0, 160.0, 0.8, 8.0)
	_luz(Color(0.7, 1.0, 0.5), 1.8, 4.0, 1.6, _centro(obj))
	_particulas(_centro(obj) + Vector2(0, 80), Color(0.85, 1.0, 0.6, 1.0), Color(0.4, 1.0, 0.4, 0.0), 30, 1.2,
		Vector2(40, 110), 60.0, Vector2(0, -1), 20.0, Vector2(0, -60), 0.07)
	obj["rig"].modulate = Color(0.75, 1.45, 0.8)


func _gastar_pm(quien: Dictionary, coste: int) -> void:
	if not MODO_PRUEBAS:
		quien["mp"] -= coste


func _dano_magia(quien: Dictionary, d: Dictionary) -> int:
	var base: float = d["dano"] * quien.get("magia_mult", 1.0) + quien.get("magia_extra", 0)
	return maxi(1, int(base * quien.get("mult_magia", 1.0))) + randi_range(-3, 3)


func _aplicar_todos() -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	var d: Dictionary = NIVELES_MAGIA[magia_sel][nivel_sel - 1]
	_gastar_pm(quien, d["coste"])
	_actualizar()
	registro.text = "%s lanza %s" % [quien["nombre"], d["nombre"]]
	await _magia_grupal(quien, enemigos.filter(func(e): return e["hp"] > 0), magia_sel, nivel_sel, _dano_magia(quien, d))
	_terminar_turno()


func _menu_objetivo(a: String, magia: String) -> void:
	accion = a
	magia_sel = magia
	_pedir_objetivo(enemigos.filter(func(e): return e["hp"] > 0), _aplicar,
		_menu_magia.bind(0) if a == "magia" else _mostrar_menu, "TOCA UN ENEMIGO")


func _aplicar(objetivo: Dictionary) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	if accion == "magia":
		var d: Dictionary = NIVELES_MAGIA[magia_sel][nivel_sel - 1]
		_gastar_pm(quien, d["coste"])
		registro.text = "%s lanza %s" % [quien["nombre"], d["nombre"]]
		await _animar_golpe(quien, objetivo, _dano_magia(quien, d), magia_sel)
	else:
		registro.text = "%s ataca a %s" % [quien["nombre"], objetivo["nombre"]]
		await _animar_golpe(quien, objetivo, maxi(1, int(quien["atk"] * quien.get("mult_fisico", 1.0))) + randi_range(-2, 3), "")
	_terminar_turno()


# Objetos de combate: la Poción (roja) recupera PV y el Éter (verde) recupera PM.
func _menu_pocion() -> void:
	estado = "pocion"
	var items: Array = []
	for nombre in OBJETOS_COMBATE:
		var o: Dictionary = OBJETOS_COMBATE[nombre]
		var n := _cantidad_objeto(nombre)
		var it := {"texto": nombre, "accion": _menu_objeto_aliado.bind(nombre), "apagado": n <= 0,
			"derecha": "×%d" % n, "desc": "Recupera %d %s a un aliado." % [o["cura"], o["que"]]}
		if ResourceLoader.exists(o["imagen"]):
			it["icono"] = load(o["imagen"])
		items.append(it)
	menu.submenu(items)


func _cantidad_objeto(nombre: String) -> int:
	if ResourceLoader.exists("res://inventario.gd"):
		return load("res://inventario.gd").cantidad(nombre)
	return pociones if nombre == "Poción" else 0


# Se puede dar a cualquier aliado que siga en pie (si ya tiene todo lleno, no).
func _menu_objeto_aliado(nombre: String) -> void:
	var campo := "hp" if OBJETOS_COMBATE[nombre]["que"] == "PV" else "mp"
	var validos := heroes.filter(func(h): return h["hp"] > 0 and h[campo] < h[campo + "_max"])
	if validos.is_empty():
		registro.text = "Nadie lo necesita ahora"
		return
	_pedir_objetivo(validos, func(f): _usar_objeto(nombre, f), _menu_pocion, "TOCA A UN ALIADO")


func _usar_objeto(nombre: String, quien: Dictionary) -> void:
	if _cantidad_objeto(nombre) <= 0:
		return
	_ocultar_menu()
	if ResourceLoader.exists("res://inventario.gd"):
		load("res://inventario.gd").gastar(nombre)
	if nombre == "Poción":
		pociones -= 1
	estado = "accion"
	var o: Dictionary = OBJETOS_COMBATE[nombre]
	var campo := "hp" if o["que"] == "PV" else "mp"
	var cura: int = min(o["cura"], quien[campo + "_max"] - quien[campo])
	quien[campo] += cura
	if quien == actor:
		registro.text = "%s usa %s (+%d %s)" % [quien["nombre"], nombre, cura, o["que"]]
	else:
		registro.text = "%s da %s a %s (+%d %s)" % [actor["nombre"], nombre, quien["nombre"], cura, o["que"]]
	_frasco(quien, o)
	if campo == "hp":
		_efecto_cura(quien)                        # mismo pilar de luz que la magia Cura
	else:
		_luz(o["color"], 1.8, 4.0, 1.4, _centro(quien))
		_particulas(_centro(quien) + Vector2(0, 80), Color(0.7, 1.0, 0.75, 1.0), Color(0.2, 0.8, 0.5, 0.0), 40, 1.2,
			Vector2(40, 120), 70.0, Vector2(0, -1), 20.0, Vector2(0, -60), 0.07)
		_onda(_suelo_de(quien), Color(0.4, 1.0, 0.6, 0.9), 20.0, 160.0, 0.8, 8.0)
		quien["rig"].modulate = Color(0.75, 1.4, 0.95)
	_numero_flotante(quien, "+%d %s" % [cura, o["que"]], C_CURA if campo == "hp" else Color(0.55, 1.0, 0.85))
	_actualizar()
	await get_tree().create_timer(0.9).timeout
	_restablecer_color(quien)
	_terminar_turno()


# El frasco aparece sobre el aliado, se inclina, brilla y se desvanece.
func _frasco(quien: Dictionary, o: Dictionary) -> void:
	if not ResourceLoader.exists(o["imagen"]):
		return
	var s := Sprite2D.new()
	s.texture = load(o["imagen"])
	s.position = _centro(quien) + Vector2(0, -170)
	s.scale = Vector2(0.4, 0.4)
	s.modulate.a = 0.0
	s.z_index = 8
	escena.add_child(s)
	var g := _brillo(o["color"])
	g.scale = Vector2(1.2, 1.2)
	g.modulate.a = 0.0
	g.position = s.position
	escena.add_child(g)
	var t := create_tween()
	t.tween_property(s, "modulate:a", 1.0, 0.15)
	t.parallel().tween_property(s, "scale", Vector2(0.75, 0.75), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(g, "modulate:a", 0.7, 0.25)
	t.tween_property(s, "rotation_degrees", -35.0, 0.25)
	t.tween_property(s, "modulate:a", 0.0, 0.3)
	t.parallel().tween_property(g, "modulate:a", 0.0, 0.3)
	t.tween_callback(s.queue_free)
	t.tween_callback(g.queue_free)


# Defender: recibe la mitad de daño hasta su siguiente turno.
func _defender() -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	quien["defendiendo"] = true
	registro.text = "%s se pone en guardia" % quien["nombre"]
	quien["rig"].modulate = COLOR_DEFENSA
	_numero_flotante(quien, "Defensa", Color(0.7, 0.85, 1.0))
	await get_tree().create_timer(0.4).timeout
	_terminar_turno()


# Huir: en los combates normales siempre funciona (los jefes no lo permiten). No da experiencia.
func _escapar() -> void:
	_ocultar_menu()
	estado = "fin"
	registro.text = "¡El grupo huye!"
	for h in heroes:
		if h["hp"] <= 0:
			continue
		var t := create_tween().set_parallel(true)
		t.tween_property(h["rig"], "position:x", h["rig"].position.x + 520.0, 0.6).set_ease(Tween.EASE_IN)
		t.tween_property(h["rig"], "modulate:a", 0.0, 0.6)
		if h.has("sombra"):
			t.tween_property(h["sombra"], "modulate:a", 0.0, 0.4)
	if ResourceLoader.exists("res://grupo.gd"):
		var gr = load("res://grupo.gd")
		for h in heroes:
			if gr.datos().has(h["nombre"]):
				gr.guardar_vida(h["nombre"], maxi(1, h["hp"]), h["mp"])
	_bajar_musica()
	_volver_al_mapa()


func _terminar_turno(carga := true) -> void:
	estado = "accion"
	actor["atb"] = 0.0
	if actor.get("embuir_turnos", 0) > 0:         # Embuir dura 3 turnos de Garon (sin contar el que lo pone)
		if actor.get("embuir_nuevo", false):
			actor["embuir_nuevo"] = false
		else:
			actor["embuir_turnos"] -= 1
			if actor["embuir_turnos"] <= 0:
				actor["embuir"] = ""
				if _p3d(actor) != null and _p3d(actor).has_method("quitar_embuir"):
					_p3d(actor).quitar_embuir()
				_numero_flotante(actor, "Embuir se apaga", Color(0.8, 0.8, 0.85), 24)
	actor = null
	if carga:                                     # cada acción carga la Armonía
		armonia = minf(1.0, armonia + ARMONIA_POR_ACCION)
		menu.poner_armonia(armonia)
	menu.cerrar()
	_actualizar()
	await get_tree().create_timer(0.3).timeout
	if not _comprobar_fin():
		estado = "esperando"


# Quita PV a un luchador. Los jefes con "fases" avisan al bajar del 50 % (el cambio de fase llega
# antes del siguiente turno) y los de "ultimo_aliento" se quedan con 1 PV, de rodillas.
func _quitar_pv(f: Dictionary, d: int) -> void:
	f["hp"] = maxi(0, f["hp"] - d)
	if f.get("fases", false) and not f.get("fase2", false) and f["hp"] > 0 and f["hp"] <= f["hp_max"] * 0.5:
		f["fase2"] = true
		f["fase2_pendiente"] = true
	if f.get("ultimo_aliento", false) and f["hp"] <= 0 and not f.get("decidido", false):
		f["hp"] = 1
		f["rendido"] = true


# ---------------------------------------------------------------- jefes

# Presentación: el nombre del jefe en grande, en dorado, mientras sale «¡Combate!».
func _presentar(f: Dictionary) -> void:
	var antes := estado
	estado = "accion"
	var titulo := _etiqueta(f["nombre"], 84, C_INVOCACION, menu.f_nombre)
	titulo.size = Vector2(1280, 130)
	titulo.position = Vector2(0, 240)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.modulate.a = 0.0
	capa.add_child(titulo)
	_temblor(6.0)
	var t := create_tween()
	t.tween_property(titulo, "modulate:a", 1.0, 0.35)
	t.tween_interval(1.3)
	t.tween_property(titulo, "modulate:a", 0.0, 0.4)
	t.tween_callback(titulo.queue_free)
	await t.finished
	if estado == "accion":
		estado = antes


# Segunda fase (al 50 %): destello rojo, el fondo se tiñe, cambia la música, brasas alrededor del jefe,
# y va más rápido y pega más fuerte.
func _cambio_fase(f: Dictionary) -> void:
	estado = "accion"
	registro.text = "¡%s se enfurece!" % f["nombre"]
	_fogonazo(Color(1.0, 0.3, 0.2), 0.55, 0.7)
	_temblor(14.0)
	menu.vibrar(60)
	_numero_flotante(f, "¡FURIA DEL ABISMO!", Color("FF7A3C"), 40)
	var rojo := Color(1.0, 0.62, 0.55)
	if fondo_nodo != null:
		create_tween().tween_property(fondo_nodo, "modulate", rojo, 1.2)
	create_tween().tween_property(escena, "modulate", tono_escena * Color(1.0, 0.82, 0.78), 1.2)
	var img = f["partes"].get("imagen", f["partes"].get("sprite"))   # 2D: su imagen; 3D: su ventana
	if img != null:
		create_tween().tween_property(img, "modulate", Color(1.0, 0.45, 0.38), 0.8)
	var brasas := _particulas(_centro(f) + Vector2(0, 80), Color(1.0, 0.55, 0.2, 0.9), Color(1.0, 0.2, 0.0, 0.0), 24, 1.6,
		Vector2(20, 70), 70.0, Vector2(0, -1), 30.0, Vector2(0, -40), 0.06, true)
	f["brasas"] = brasas
	f["vel"] *= 1.4
	f["atk"] = int(f["atk"] * 1.15)
	_musica_fase2()
	await get_tree().create_timer(1.6).timeout
	if estado == "accion":
		estado = "esperando"


func _musica_fase2() -> void:
	if musica == null:
		return
	var ruta := ""
	for r in [MUSICA_JEFE_FASE2.get_basename() + ".ogg", MUSICA_JEFE_FASE2]:
		if ResourceLoader.exists(r):
			ruta = r
			break
	if ruta != "":                                 # su música propia: fundido de una a otra
		var t := create_tween()
		t.tween_property(musica, "volume_db", -40.0, 0.6)
		t.tween_callback(func():
			var pista = load(ruta)
			if pista is AudioStreamMP3 or pista is AudioStreamOggVorbis:
				pista.loop = true
			musica.stream = pista
			musica.play())
		t.tween_property(musica, "volume_db", -4.0, 0.6)
	else:                                          # sin música propia: la misma, más rápida y aguda
		var t := create_tween().set_parallel(true)
		t.tween_property(musica, "pitch_scale", PITCH_FASE2, 1.2)
		t.tween_property(musica, "volume_db", -3.0, 1.2)


# Último aliento: el jefe cae de rodillas y Kael decide (documento de diseño, sección 6).
# La decisión se guarda en la partida ("decisiones") y cambia una línea de Morgath más adelante.
func _decidir(f: Dictionary) -> void:
	estado = "decision"
	f["atb"] = 0.0
	if f.has("brasas") and is_instance_valid(f["brasas"]):
		f["brasas"].emitting = false
	registro.text = "%s cae de rodillas. Te mira, sin fuerzas." % f["nombre"]
	create_tween().tween_property(f["rig"], "position:y", f["rig_base"].y + 24.0, 0.5)
	if musica != null:
		create_tween().tween_property(musica, "volume_db", -18.0, 1.0)
	await get_tree().create_timer(1.2).timeout
	var kael: Dictionary = heroes[0]
	for h in heroes:
		if h["nombre"] == "Kael":
			kael = h
	menu.abrir(kael, [{"texto": "PERDONAR", "accion": _perdonar.bind(f)}, {"texto": "ACABAR", "accion": _acabar.bind(f)}])
	if "auto" in OS.get_cmdline_user_args():      # pruebas: perdona solo
		_perdonar.call_deferred(f)


func _perdonar(f: Dictionary) -> void:
	_apuntar_decision(f, "perdonado")
	registro.text = "Kael baja la espada. %s se arrastra hacia el abismo." % f["nombre"].get_slice(" ", 0)
	var rig: Node2D = f["rig"]
	var t := create_tween().set_parallel(true)
	t.tween_property(rig, "position:x", rig.position.x - 420.0, 1.6).set_ease(Tween.EASE_IN)
	t.tween_property(rig, "modulate:a", 0.0, 1.6)
	await t.finished
	f["hp"] = 0
	if f.has("sombra"):
		f["sombra"].visible = false
	f["lbl_hp"].visible = false
	_actualizar()
	if not _comprobar_fin():
		estado = "esperando"


func _acabar(f: Dictionary) -> void:
	_apuntar_decision(f, "muerto")
	registro.text = "Kael acaba con %s." % f["nombre"].get_slice(" ", 0)
	_destello(_centro(f), Color(1.0, 0.9, 0.7), 2.0)
	_temblor(10.0)
	f["hp"] = 0
	_restablecer_color(f)
	_actualizar()
	await get_tree().create_timer(1.0).timeout
	if not _comprobar_fin():
		estado = "esperando"


func _apuntar_decision(f: Dictionary, que: String) -> void:
	menu.cerrar()
	f["decidido"] = true
	f["rendido"] = false
	estado = "accion"
	var d: Dictionary = Engine.get_meta("decisiones", {})
	d[f["nombre"].get_slice(" ", 0).to_lower()] = que   # "gorthor": no depende de su modelo
	Engine.set_meta("decisiones", d)


# Invocación «Ladrón de Corazones» (con la Armonía llena): Lya invoca a Érebo contra UN enemigo.
# La cinemática (invocacion_erebo.gd) va en un escenario 3D propio que tapa el combate (_teatro_erebo).
#   Enemigo normal: 20 % de muerte instantánea; si falla, no le hace daño.
#   Jefe: inmune a la muerte; pierde el 20 % de su vida ACTUAL.
# Tocar la pantalla salta la cinemática (el resultado se aplica igual, una sola vez).
func _invocar() -> void:
	_pedir_objetivo(enemigos.filter(func(e): return e["hp"] > 0), _invocar_sobre, _mostrar_menu, "TOCA UN ENEMIGO")


func _invocar_sobre(obj: Dictionary) -> void:
	_ocultar_menu()
	estado = "accion"
	armonia = 0.0
	menu.poner_armonia(0.0)
	saltar_invocacion = false
	fuera.visible = true
	registro.text = "Lya invoca a Érebo"
	menu.vibrar(40)
	var es_jefe: bool = obj.get("personalidad", "") == "jefe" or obj.get("fases", false) or obj.get("ultimo_aliento", false)
	var out := {"dano": 0}                         # (las funciones anónimas no cambian variables de fuera)
	var al_resultado := func(r: Dictionary):
		if es_jefe:
			out["dano"] = maxi(1, int(round(obj["hp"] * INVOCACION["dano_jefe"])))
		elif r.get("muerte", false):
			out["dano"] = obj["hp"]
		if out["dano"] > 0:
			_quitar_pv(obj, out["dano"])
	if ResourceLoader.exists("res://invocacion_erebo.gd") and ResourceLoader.exists("res://erebo_idle.fbx"):
		await _teatro_erebo(obj, es_jefe, al_resultado)
	else:                                          # sin los archivos de Érebo: solo se tira el dado
		await _espera_invocacion(0.6)
		al_resultado.call({"exito": es_jefe or randf() < INVOCACION["prob_muerte"],
			"muerte": not es_jefe and randf() < INVOCACION["prob_muerte"]})
	# de vuelta al combate: el resultado sobre el enemigo de verdad
	var dano: int = out["dano"]
	if dano > 0:
		_golpe_visual(obj, dano, "Invocación")
		_particulas(_centro(obj), Color(0.75, 0.3, 0.9, 1.0), Color(1.0, 0.3, 0.45, 0.0), 26, 0.9, Vector2(60, 160),
			50.0, Vector2(0, -1), 60.0, Vector2(0, 40), 0.08)
		_temblor(8.0)
		registro.text = "¡Érebo le arranca el corazón!" if obj["hp"] <= 0 else "Érebo le roba parte de su vida"
	else:
		_numero_flotante(obj, "Falla", Color(0.75, 0.7, 0.85))
		registro.text = "La mano de Érebo sale vacía"
	_actualizar()
	await _espera_invocacion(0.7)
	fuera.visible = false
	_terminar_turno(false)


var inv_erebo = null          # la invocación en curso (tocar la pantalla la salta)


# Escenario 3D a pantalla completa para la cinemática: suelo, luces del combate, la cámara que mueve
# la invocación, Lya (la que invoca) y un doble del enemigo (su 3D, o su dibujo de pie si es 2D).
func _teatro_erebo(obj: Dictionary, es_jefe: bool, al_resultado: Callable) -> void:
	var movil := OS.has_feature("mobile") or "movil" in OS.get_cmdline_user_args()
	var q: float = res_personajes if movil else 1.0
	var capa_t := CanvasLayer.new()
	capa_t.layer = capa.layer + 1                   # encima del combate; el toque llega a «fuera» de debajo
	add_child(capa_t)
	var negro := ColorRect.new()
	negro.color = Color(0.03, 0.01, 0.05, 0.0)
	negro.size = Vector2(1280, 720)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_t.add_child(negro)
	var vp := SubViewport.new()
	vp.size = Vector2i(int(1280 * q), int(720 * q))
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED if movil else Viewport.MSAA_2X
	capa_t.add_child(vp)
	var pantalla := TextureRect.new()
	pantalla.texture = vp.get_texture()
	pantalla.size = Vector2(1280, 720)
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pantalla.stretch_mode = TextureRect.STRETCH_SCALE
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.modulate.a = 0.0
	capa_t.add_child(pantalla)

	# mundo: fondo de la zona a lo lejos, oscurecido; suelo; luz dorada y relleno azul (biblia de arte)
	var mundo := Node3D.new()
	vp.add_child(mundo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.07, 0.05, 0.11)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.5, 0.8)
	e.ambient_light_energy = 0.55
	e.fog_enabled = true
	e.fog_light_color = Color(0.12, 0.08, 0.18)
	e.fog_density = 0.035
	env.environment = e
	mundo.add_child(env)
	var tex_fondo := _textura_fondo()
	if tex_fondo != null:
		var lejos := Sprite3D.new()
		lejos.texture = tex_fondo
		lejos.pixel_size = 30.0 / tex_fondo.get_width()
		lejos.position = Vector3(0, 4.5, -11)
		lejos.shaded = false
		lejos.modulate = Color(0.42, 0.36, 0.5)
		mundo.add_child(lejos)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 24)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.2, 0.17, 0.22).lerp(luz_3d * 0.3, 0.3)
	ms.roughness = 0.95
	suelo.material_override = ms
	mundo.add_child(suelo)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -40, 0)
	sol.light_color = LUZ_PRINCIPAL.lerp(luz_3d, 0.3)
	sol.light_energy = 1.2
	sol.shadow_enabled = not movil
	mundo.add_child(sol)
	var relleno := DirectionalLight3D.new()
	relleno.light_color = LUZ_RELLENO
	relleno.light_energy = 0.35
	relleno.rotation_degrees = Vector3(-15, 140, 0)
	mundo.add_child(relleno)
	var cam := Camera3D.new()
	cam.fov = 40
	mundo.add_child(cam)
	cam.look_at_from_position(Vector3(0.6, 2.3, 5.2), Vector3(-0.2, 0.7, 0))
	cam.current = true

	var lya = load("res://maga_3d.gd").new()
	lya.ruta_modelo = _ruta_3d(MODELOS["nyx3d"])
	mundo.add_child(lya)
	lya.position = Vector3(1.7, 0, 0.5)
	var doble := _doble_3d(obj)
	mundo.add_child(doble)
	doble.position = Vector3(-1.8, 0, -0.1)

	var titulo := _etiqueta(INVOCACION["nombre"], 64, Color(1.0, 0.85, 0.9), menu.f_nombre)
	titulo.size = Vector2(1280, 90)
	titulo.position = Vector2(0, 26)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.modulate.a = 0.0
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_t.add_child(titulo)

	# entra: fundido a negro, y del negro sale el escenario (los modelos ya cargados)
	await create_tween().tween_property(negro, "color:a", 1.0, 0.35).finished
	for i in 4:
		await get_tree().process_frame
	create_tween().tween_property(pantalla, "modulate:a", 1.0, 0.4)

	var inv = load("res://invocacion_erebo.gd").new()
	mundo.add_child(inv)
	inv.ajustes.calidad = "movil" if movil else "alta"
	inv.evento.connect(_evento_erebo.bind(titulo))
	var ctx := {"invocador": lya, "objetivo": doble, "es_jefe": es_jefe, "camara": cam,
		"al_resultado": _resultado_erebo.bind(doble, al_resultado)}
	for a in OS.get_cmdline_user_args():           # pruebas: -- erebo=exito / erebo=fallo
		if a.begins_with("erebo="):
			ctx["forzar"] = a.substr(6)
	inv_erebo = inv
	await inv.lanzar(ctx)
	inv_erebo = null
	await get_tree().create_timer(0.3).timeout
	# sale: fundido a negro y de vuelta al combate
	var t := create_tween()
	t.tween_property(pantalla, "modulate:a", 0.0, 0.3)
	t.parallel().tween_property(titulo, "modulate:a", 0.0, 0.3)
	t.tween_property(negro, "color:a", 0.0, 0.35)
	await t.finished
	Engine.time_scale = 1.0
	capa_t.queue_free()


# Momentos de la cinemática: el título aparece cuando surge Érebo y se va cuando se hunde.
func _evento_erebo(n: String, titulo: Label) -> void:
	match n:
		"invocacion":
			create_tween().tween_property(titulo, "modulate:a", 1.0, 0.4)
		"estalla", "fallo":
			menu.vibrar(50)
		"se_hunde":
			create_tween().tween_property(titulo, "modulate:a", 0.0, 0.4)


# Al romperse el orbe (o al saltar): el resultado al enemigo de verdad y la reacción de su doble.
func _resultado_erebo(r: Dictionary, doble: Node3D, al_resultado: Callable) -> void:
	al_resultado.call(r)
	if r.get("muerte", false) and doble.has_method("morir"):
		doble.morir()
	elif doble.has_method("herida"):
		doble.herida()


# El doble del enemigo en el escenario de la invocación: su modelo 3D si lo tiene (Grimfang, Gorthor),
# o su dibujo de pie (muneco_invocacion.gd).
func _doble_3d(obj: Dictionary) -> Node3D:
	var m: Dictionary = MODELOS.get(obj["modelo"], {})
	if m.get("tipo", "") == "3d" and _ruta_3d(m) != "":
		var p = load(m["script"]).new()
		p.ruta_modelo = _ruta_3d(m)
		var s: float = clampf(m["esc"] / 0.6, 1.0, 1.6)   # los jefes, más grandes (sin pasarse: Érebo les mete la mano en el pecho)
		p.scale = Vector3.ONE * s
		return p
	var d = load("res://muneco_invocacion.gd").new()
	var alto: float = ALTO_DOBLE.get(obj["modelo"], 1.6)
	var tex: Texture2D = null
	var region := Rect2()
	var tinte: Color = m.get("tinte", Color.WHITE)
	for n in obj["rig"].find_children("*", "", true, false):
		if n is Sprite2D and n.texture != null and n.visible:
			tex = n.texture
			if n.region_enabled:
				region = n.region_rect
			elif n.hframes > 1 or n.vframes > 1:
				var w: float = tex.get_width() / float(n.hframes)
				var h: float = tex.get_height() / float(n.vframes)
				region = Rect2((n.frame % n.hframes) * w, (n.frame / n.hframes) * h, w, h)
			break
		if n is AnimatedSprite2D and n.sprite_frames != null:
			tex = n.sprite_frames.get_frame_texture(n.animation, n.frame)
			break
	if tex == null and m.has("imagen") and ResourceLoader.exists(m["imagen"]):
		tex = load(m["imagen"])
	if tex != null:
		d.preparar(tex, alto, tinte, region)
	return d


const ALTO_DOBLE := {"slime": 0.95, "guardian": 1.9, "gorthor": 2.5, "hollin": 1.6}


# La imagen del fondo de la zona (para verla a lo lejos en la invocación), o null.
func _textura_fondo() -> Texture2D:
	if fondo_nodo == null:
		return null
	if fondo_nodo is Sprite2D:
		return fondo_nodo.texture
	for n in fondo_nodo.find_children("*", "", true, false):
		if (n is Sprite2D or n is TextureRect) and n.texture != null:
			return n.texture
	return null


func _espera_invocacion(seg: float) -> void:
	var t := 0.0
	while t < seg and not saltar_invocacion:
		await get_tree().process_frame
		t += get_process_delta_time()


# ================================================================= animaciones

func _animar_golpe(origen: Dictionary, objetivo: Dictionary, dano: int, magia: String) -> void:
	var critico: bool = magia == "" and randf() < PROB_CRITICO
	if critico:
		dano = int(dano * MULT_CRITICO)
	if magia == "" and objetivo["hero"]:              # la defensa del héroe resta daño a los golpes
		dano = max(1, dano - int(objetivo.get("def", 0) / 2.0))
	if objetivo.get("defendiendo", false):
		dano = max(1, int(dano * 0.5))
	var congela: bool = magia == "" and origen["hero"] and _lleva_frostfang(origen) and randf() < PROB_CONGELAR
	var embuido: bool = magia == "" and origen.get("embuir", "") != ""    # Garon con Embuir: +20 % y su elemento
	if embuido:
		dano = int(dano * (1.0 + EMBUIR["extra"]))
	var impacto: Callable = func():
		_quitar_pv(objetivo, dano)
		if embuido:
			_golpe_visual(objetivo, dano, _efecto_embuir(origen, objetivo), critico)
		else:
			_golpe_visual(objetivo, dano, magia, critico)
		if congela and objetivo["hp"] > 0:
			_congelar(objetivo)
	if magia != "" and _p3d(origen) != null:
		await _anim_magia_3d(origen, objetivo, magia, impacto)
	elif magia != "":
		await _anim_magia(origen, objetivo, magia, impacto)
	elif _p3d(origen) != null and _p3d(origen).has_method("atacar_hacha"):     # Grimfang y Gorthor
		# golpe fuerte a dos manos con rabia o al descargar el golpe cargado; si no, el doble tajo
		var fuerte: bool = origen.get("furia", false) or origen.get("descarga", false)
		await _anim_ataque_3d(origen, objetivo, impacto, "golpe_fuerte" if fuerte else "atacar_hacha")
	elif _p3d(origen) != null and _p3d(origen).has_method("atacar_juicio"):    # Garon
		await _anim_ataque_3d(origen, objetivo, impacto, "atacar_juicio")
	elif _p3d(origen) != null and _p3d(origen).has_method("ataque_salto"):
		await _anim_salto_3d(origen, objetivo, impacto)
	elif _p3d(origen) != null:
		await _anim_fisico_3d(origen, objetivo, impacto)
	elif ANIM[origen["modelo"]].has("poses"):
		await _anim_fisico_poses(origen, objetivo, impacto)
	elif _es_frames(origen):
		await _anim_fisico_frames(origen, objetivo, impacto)
	elif MODELOS[origen["modelo"]].get("tipo", "") == "imagen":
		await _anim_fisico_imagen(origen, objetivo, impacto)
	elif _es_sprite(origen):
		await _anim_fisico_sprite(origen, objetivo, impacto)
	else:
		await _anim_fisico(origen, objetivo, impacto)


# Kael: levanta el espadón con las dos manos y lo baja en vertical.
func _anim_fisico_poses(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var a: Dictionary = ANIM[o["modelo"]]
	var ps: Dictionary = a["poses"]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var dx: float = obj["pos"].x - o["pos"].x + a["distancia"]
	var dy: float = (obj["pos"].y - o["pos"].y) * 0.8
	o["animando"] = true
	rig.z_index = 5
	_cara(o, "grito")
	var t1 := _tween_pose(o, ps["alto"], 0.45)
	t1.tween_property(rig, "position", base + Vector2(dx, dy), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	var t2 := _tween_pose(o, ps["golpe"], 0.16, true)
	await t2.finished
	impacto.call()
	await get_tree().create_timer(0.35).timeout
	var t3 := _tween_pose(o, ps["guardia"], 0.4)
	t3.tween_property(rig, "position", base, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	o["pose"] = "guardia"
	rig.z_index = 0
	o["animando"] = false
	_cara_reposo(o)


# Aventurero: se acerca, levanta la espada y da un tajo de arriba abajo por delante.
func _anim_fisico_frames(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var a: Dictionary = ANIM[o["modelo"]]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var e: Sprite2D = o["partes"]["arma"]
	var dx: float = obj["pos"].x - o["pos"].x + a["distancia"]
	var dy: float = (obj["pos"].y - o["pos"].y) * 0.8
	o["animando"] = true
	rig.z_index = 5
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(rig, "position", base + Vector2(dx, dy), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(e, "rotation_degrees", a["prep"], 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t1.tween_property(o["cuerpo"], "rotation_degrees", a["lean_prep"], 0.45)
	await t1.finished
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(e, "rotation_degrees", a["golpe"], 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t2.tween_property(o["cuerpo"], "rotation_degrees", a["lean_golpe"], 0.15)
	await t2.finished
	impacto.call()
	await get_tree().create_timer(0.3).timeout
	var t3 := create_tween().set_parallel(true)
	t3.tween_property(e, "rotation_degrees", _ang_reposo(o), 0.35)
	t3.tween_property(o["cuerpo"], "rotation_degrees", 0.0, 0.35)
	t3.tween_property(rig, "position", base, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	rig.z_index = 0
	o["animando"] = false


# Slime: se desliza hasta el héroe, se lanza contra él y vuelve a su sitio.
func _anim_fisico_sprite(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var a: Dictionary = ANIM[o["modelo"]]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var anim: AnimatedSprite2D = o["partes"]["anim"]
	var dist: float = a["distancia"]
	var dx: float = obj["pos"].x - o["pos"].x + (dist if o["hero"] else -dist)
	var dy: float = (obj["pos"].y - o["pos"].y) * 0.8
	o["animando"] = true
	rig.z_index = 5
	anim.play("move")
	var t1 := create_tween()
	t1.tween_property(rig, "position", base + Vector2(dx, dy), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	anim.play("attack")
	while anim.animation == "attack" and anim.frame < int(a["frame_golpe"]):
		await anim.frame_changed
	impacto.call()
	if anim.animation == "attack" and anim.is_playing():
		await anim.animation_finished
	anim.play("move")
	var t2 := create_tween()
	t2.tween_property(rig, "position", base, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t2.finished
	anim.play("idle")
	rig.z_index = 0
	o["animando"] = false


# Maga 3D: corre hacia el enemigo, le da un golpe con la palma y vuelve corriendo.
func _anim_fisico_3d(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var maga = _p3d(o)
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var dx: float = obj["pos"].x - o["pos"].x + ANIM[o["modelo"]]["distancia"]
	var dy: float = (obj["pos"].y - o["pos"].y) * 0.8
	o["animando"] = true
	rig.z_index = 5
	maga.mirar(Vector3(-1, 0, 0.1), 0.15)
	maga.correr()
	var t1 := create_tween()
	t1.tween_property(rig, "position", base + Vector2(dx, dy), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	maga.preparar_golpe()
	await get_tree().create_timer(0.28).timeout
	maga.golpear()
	await get_tree().create_timer(0.1).timeout
	impacto.call()
	await get_tree().create_timer(0.35).timeout
	maga.fin_golpe()
	maga.mirar(Vector3(1, 0, 0.1), 0.2)
	maga.correr()
	var t3 := create_tween()
	t3.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	maga.mirar_frente(0.25)
	maga.reposo()
	rig.z_index = 0
	o["animando"] = false


# Kael 3D: corre con el sable al hombro, se agacha, salta con el sable en alto
# y cae cortando sobre el enemigo; después vuelve corriendo.
func _anim_salto_3d(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var k = _p3d(o)
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var dx: float = obj["pos"].x - o["pos"].x + ANIM[o["modelo"]]["distancia"]
	var despegue := base + Vector2(dx + 70.0, 0.0)   # los pies de Kael y del enemigo están a la misma altura
	o["animando"] = true
	rig.z_index = 5
	k.mirar(Vector3(-1, 0, 0.1), 0.15)
	k.correr()
	var t1 := create_tween()
	t1.tween_property(rig, "position", despegue, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	k.mirar(Vector3(-1, 0, 0.3), 0.1)
	k.ataque_salto(_impacto_fuerte.bind(impacto))
	await get_tree().create_timer(SALTO_T[0]).timeout
	o["suelo_salto"] = despegue.y                  # la sombra se queda en el suelo mientras salta
	var t2 := create_tween()
	t2.tween_property(rig, "position", despegue + Vector2(-40, -130), SALTO_T[1]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t2.tween_property(rig, "position", despegue + Vector2(-70, 0), SALTO_T[2]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t2.finished
	o.erase("suelo_salto")
	await get_tree().create_timer(0.65).timeout
	k.mirar(Vector3(1, 0, 0.1), 0.2)
	k.correr()
	var t3 := create_tween()
	t3.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	k.mirar_frente(0.25)
	k.reposo()
	rig.z_index = 0
	o["animando"] = false


# Ataque de un personaje 3D con su propia animación de golpe (Garon, Grimfang, Gorthor): corre hasta
# el objetivo, ataca con "metodo" (que llama al impacto en cada golpe) y vuelve. Los héroes van hacia
# la izquierda y los enemigos hacia la derecha. El daño se hace en el primer golpe; los demás tiemblan.
func _anim_ataque_3d(o: Dictionary, obj: Dictionary, impacto: Callable, metodo: String) -> void:
	var p = _p3d(o)
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var lado := 1.0 if o["hero"] else -1.0             # el héroe se para a la derecha del enemigo
	var hueco: float = ANIM[o["modelo"]].get("distancia", 120.0) + ANIM[obj["modelo"]].get("distancia", 120.0) * 0.4
	var destino := base + Vector2(_centro(obj).x + hueco * lado - _centro(o).x, (obj["pos"].y - o["pos"].y) * 0.8)
	if obj.has("centro_ofs") and o.has("centro_ofs"):  # los dos 3D: los pies a la misma altura
		destino.y = base.y + (_suelo_de(obj).y - _suelo_de(o).y)
	var ida := Vector3(-1 * lado, 0, 0.1)
	o["animando"] = true
	rig.z_index = 5
	p.mirar(ida, 0.15)
	p.correr()
	var t1 := create_tween()
	t1.tween_property(rig, "position", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	var golpes := [0]
	var al_golpear := func():
		golpes[0] += 1
		if golpes[0] == 1 or metodo == "atacar_giro":   # el Giro golpea en cada vuelta
			impacto.call()
			if metodo == "golpe_fuerte" or metodo == "atacar_juicio":
				_temblor(9.0)
		else:
			_temblor(4.0)
	match metodo:
		"golpe_fuerte":
			await p.golpe_fuerte(al_golpear)
		"atacar_hacha":
			await p.atacar_hacha(al_golpear)
		"atacar_juicio":
			await p.atacar_juicio(al_golpear)
		"atacar_giro":
			await p.atacar_giro(al_golpear)
	if golpes[0] == 0:                                 # sin esa animación: el golpe igualmente
		impacto.call()
	p.mirar(-ida, 0.2)
	p.correr()
	var t3 := create_tween()
	t3.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	p.mirar_frente(0.25)
	p.reposo()
	rig.z_index = 0
	o["animando"] = false


func _impacto_fuerte(impacto: Callable) -> void:
	impacto.call()
	_temblor(9.0)


# Personaje 3D: alza las manos (o el sable), la luz nace ahí y sale disparada hacia el enemigo.
func _anim_magia_3d(o: Dictionary, obj: Dictionary, magia: String, impacto: Callable) -> void:
	var maga = _p3d(o)
	var color: Color = MAGIAS[magia]["color"]
	o["animando"] = true
	var circulo := _carga_magia(o, magia)
	await maga.lanzar_magia()
	var cam: Camera3D = o["cam3d"]
	var spr: Sprite2D = o["partes"]["sprite"]
	var punto := escena.to_local(spr.to_global(cam.unproject_position(maga.punto_magia())))

	var halo := _brillo(color)
	halo.position = punto
	halo.scale = Vector2.ZERO
	escena.add_child(halo)
	_particulas(punto, Color(color.r, color.g, color.b, 0.9), Color(color.r, color.g, color.b, 0.0), 40, 0.6,
		Vector2(60, 140), 70.0, Vector2(0, -1), 180.0, Vector2(0, 0), 0.08)
	var t2 := create_tween()
	t2.tween_property(halo, "scale", Vector2(1.1, 1.1), 0.5)
	t2.tween_property(halo, "scale", Vector2(0.6, 0.6), 0.15)
	await t2.finished

	halo.queue_free()
	await _lanzar(punto, _centro(obj), magia)
	impacto.call()
	_quitar_carga(circulo)
	await get_tree().create_timer(0.8).timeout
	maga.fin_magia()
	await get_tree().create_timer(0.35).timeout
	o["animando"] = false


# Resto de personajes: avanza, prepara el golpe, golpea y vuelve.
func _anim_fisico(o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var p: Dictionary = o["partes"]
	var a: Dictionary = ANIM[o["modelo"]]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var cuerpo: Node2D = o["cuerpo"]
	var heroe: bool = o["hero"]
	var dist: float = a["distancia"]
	var dx: float = obj["pos"].x - o["pos"].x + (dist if heroe else -dist)
	var dy: float = (obj["pos"].y - o["pos"].y) * 0.8
	o["animando"] = true
	rig.z_index = 5
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(rig, "position", base + Vector2(dx, dy), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(p["brazo_f"], "rotation_degrees", a["prep"], 0.45)
	if p.has("arma"):
		t1.tween_property(p["arma"], "rotation_degrees", a["arma_prep"], 0.45)
	if a.has("a_prep"):
		t1.tween_property(p["brazo_a"], "rotation_degrees", a["a_prep"], 0.45)
	t1.tween_property(cuerpo, "rotation_degrees", a["lean_prep"], 0.45)
	await t1.finished
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(p["brazo_f"], "rotation_degrees", a["golpe"], 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if p.has("arma"):
		t2.tween_property(p["arma"], "rotation_degrees", a["arma_golpe"], 0.17)
	if a.has("a_golpe"):
		t2.tween_property(p["brazo_a"], "rotation_degrees", a["a_golpe"], 0.17)
	t2.tween_property(cuerpo, "rotation_degrees", a["lean_golpe"], 0.17)
	await t2.finished
	impacto.call()
	await get_tree().create_timer(0.35).timeout
	var t3 := create_tween().set_parallel(true)
	t3.tween_property(p["brazo_f"], "rotation_degrees", a["ret"], 0.35)
	if p.has("arma"):
		t3.tween_property(p["arma"], "rotation_degrees", 0.0, 0.35)
	if a.has("a_ret"):
		t3.tween_property(p["brazo_a"], "rotation_degrees", a["a_ret"], 0.35)
	t3.tween_property(cuerpo, "rotation_degrees", 0.0, 0.35)
	t3.tween_property(rig, "position", base, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	p["brazo_f"].rotation_degrees = 0.0
	p["brazo_a"].rotation_degrees = 0.0
	rig.z_index = 0
	o["animando"] = false


# Magia: cierra los ojos, levanta el arma, carga luz en la punta y envuelve al enemigo.
func _anim_magia(o: Dictionary, obj: Dictionary, magia: String, impacto: Callable) -> void:
	var p: Dictionary = o["partes"]
	var a: Dictionary = ANIM[o["modelo"]]
	var color: Color = MAGIAS[magia]["color"]
	o["animando"] = true
	_set_ojos(o, true)
	var circulo := _carga_magia(o, magia)
	var t1: Tween
	if a.has("poses"):
		t1 = _tween_pose(o, a["poses"]["magia"], 0.6)
	elif _es_frames(o):
		t1 = create_tween().set_parallel(true)
		t1.tween_property(p["arma"], "rotation_degrees", a["m_arma"], 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t1.tween_property(o["cuerpo"], "rotation_degrees", a["m_lean"], 0.5)
	else:
		t1 = create_tween().set_parallel(true)
		t1.tween_property(p["brazo_f"], "rotation_degrees", a["m_brazo"], 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t1.tween_property(p["arma"], "rotation_degrees", a["m_arma"], 0.6)
		t1.tween_property(p["brazo_a"], "rotation_degrees", a["m_brazo_a"], 0.6)
		t1.tween_property(o["cuerpo"], "rotation_degrees", a["m_lean"], 0.6)
	await t1.finished

	# luz que se concentra en la punta del arma
	var k: float = ESC / float(o["esc"])
	var halo := _brillo(color)
	halo.position = a["punta"] - o["pivotes"]["arma"]
	halo.scale = Vector2.ZERO
	p["arma"].add_child(halo)
	var t2 := create_tween()
	t2.tween_property(halo, "scale", Vector2(0.9, 0.9) * k, 0.5)
	t2.tween_property(halo, "scale", Vector2(0.6, 0.6) * k, 0.15)
	await t2.finished

	# la luz sale disparada hacia el enemigo
	var desde := escena.to_local(halo.global_position)
	halo.queue_free()
	await _lanzar(desde, _centro(obj), magia)
	impacto.call()
	_quitar_carga(circulo)
	await get_tree().create_timer(0.8).timeout

	# volver a la guardia y abrir los ojos
	var t4: Tween
	if a.has("poses"):
		t4 = _tween_pose(o, a["poses"]["guardia"], 0.45)
		o["pose"] = "guardia"
	elif _es_frames(o):
		t4 = create_tween().set_parallel(true)
		t4.tween_property(p["arma"], "rotation_degrees", _ang_reposo(o), 0.4)
		t4.tween_property(o["cuerpo"], "rotation_degrees", 0.0, 0.4)
	else:
		t4 = create_tween().set_parallel(true)
		t4.tween_property(p["brazo_f"], "rotation_degrees", 0.0, 0.4)
		t4.tween_property(p["arma"], "rotation_degrees", 0.0, 0.4)
		t4.tween_property(p["brazo_a"], "rotation_degrees", 0.0, 0.4)
		t4.tween_property(o["cuerpo"], "rotation_degrees", 0.0, 0.4)
	await t4.finished
	_set_ojos(o, false)
	o["animando"] = false


# Expresiones de la cara (solo personajes que tienen caras).
func _cara(f: Dictionary, nombre: String) -> void:
	if f.has("caras") and f["caras"].has(nombre):
		f["partes"]["cabeza"].texture = f["caras"][nombre]


func _cara_reposo(f: Dictionary) -> void:
	if not f.has("caras"):
		return
	if f["hp"] <= 0:
		_cara(f, "cerrados")
	elif f["hp"] < f["hp_max"] * 0.3:
		_cara(f, "cansado")
	else:
		_cara(f, "normal")


func _set_ojos(f: Dictionary, cerrados: bool) -> void:
	if f.has("caras"):
		if cerrados:
			_cara(f, "cerrados")
		else:
			_cara_reposo(f)
		return
	if f["cab_cerrada"] != null:
		f["partes"]["cabeza"].texture = f["cab_cerrada"] if cerrados else f["cab_abierta"]


func _centro(f: Dictionary) -> Vector2:
	if f.has("centro_ofs"):
		return f["pos"] + f["centro_ofs"]
	return f["pos"] + Vector2(CANVAS.x * ESC * 0.5, MODELOS[f["modelo"]].get("centro_y", CANVAS.y * ESC * 0.45))


func _brillo(color: Color) -> Sprite2D:
	var g := Sprite2D.new()
	g.texture = glow_tex
	g.material = mat_aditivo
	g.modulate = color
	return g


# ================================================================= efectos

func _golpe_visual(objetivo: Dictionary, dano: int, magia: String, critico := false, potencia := 1.0) -> void:
	var rig: Node2D = objetivo["rig"]
	var base: Vector2 = objetivo["rig_base"]
	var centro := _centro(objetivo)
	menu.vibrar(20)
	match magia:
		"Invocación":
			_destello(centro, C_INVOCACION, 1.6)
			rig.modulate = Color(1.6, 1.3, 0.7)
			_numero_flotante(objetivo, str(dano), C_INVOCACION)
		"Agua":
			_efecto_agua(centro, _suelo_de(objetivo), potencia)
			rig.modulate = Color(0.6, 0.85, 1.6)
			_numero_flotante(objetivo, str(dano), C_DANO)
		"Rayo":
			_efecto_rayo(centro, _suelo_de(objetivo), potencia)
			rig.modulate = Color(0.9, 1.5, 1.9)
			_numero_flotante(objetivo, str(dano), C_DANO)
		"Fuego":
			_efecto_fuego(centro, _suelo_de(objetivo), potencia)
			rig.modulate = Color(1.7, 0.7, 0.3)
			_numero_flotante(objetivo, str(dano), C_DANO)
			if objetivo["hp"] > 0:
				objetivo["quemadura"] = RONDAS_QUEMADURA
				_encender_llama(objetivo)
		_:
			if critico:
				_destello(centro, Color(1.0, 0.85, 0.4), 1.8)
				_numero_flotante(objetivo, "¡%d!" % dano, C_DANO, 58)
				registro.text = "¡Golpe crítico!"
				_temblor(10.0)
			else:
				_destello(centro, Color(1.0, 0.95, 0.85), 1.0)
				_numero_flotante(objetivo, str(dano), Color.WHITE)
				_temblor(3.0)
			rig.modulate = Color(1.6, 0.3, 0.3)
	_actualizar()
	if objetivo["hp"] > 0 and not objetivo["animando"]:
		_cara(objetivo, "dolor")
		_reproducir(objetivo, "hurt")
		if MODELOS[objetivo["modelo"]].has("anims"):     # pose de herido un momento
			_pose_img(objetivo, "herida")
			get_tree().create_timer(0.45).timeout.connect(func():
				if objetivo["hp"] > 0 and not objetivo["animando"]:
					_pose_img(objetivo, "guardia"))
		if _p3d(objetivo) != null:
			_p3d(objetivo).herida()
	if objetivo["animando"]:
		_restablecer_color(objetivo)
		return
	var t := create_tween()
	t.tween_property(rig, "position", base + Vector2(14, 0), 0.04)
	t.tween_property(rig, "position", base - Vector2(14, 0), 0.04)
	t.tween_property(rig, "position", base + Vector2(7, 0), 0.04)
	t.tween_property(rig, "position", base, 0.04)
	t.tween_interval(0.25)
	t.tween_callback(func(): _restablecer_color(objetivo))


func _particulas(pos: Vector2, c1: Color, c2: Color, cantidad: int, vida: float, vel: Vector2,
		radio: float, direccion: Vector2, apertura: float, gravedad: Vector2, escala: float, continuo := false) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = glow_tex
	p.material = mat_aditivo
	p.position = pos
	p.amount = maxi(3, int(cantidad * calidad))
	p.lifetime = vida
	p.one_shot = not continuo
	p.explosiveness = 0.0 if continuo else 0.55
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radio
	p.direction = direccion
	p.spread = apertura
	p.gravity = gravedad
	p.initial_velocity_min = vel.x
	p.initial_velocity_max = vel.y
	p.scale_amount_min = escala * 0.5
	p.scale_amount_max = escala
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([c1, c2])
	p.color_ramp = g
	escena.add_child(p)
	p.emitting = true
	if not continuo:
		get_tree().create_timer(vida + 0.6).timeout.connect(p.queue_free)
	return p


# ================================================================= magias (efectos)
# Todo se dibuja por código (anillos, partículas y luces) y se borra al terminar: no usa imágenes.

# Efecto 3D (una escena .tscn con partículas, luz...) dibujado en su propia ventana 3D con fondo
# transparente y puesto encima del combate como un sprite (con su color, también sobre fondos claros).
# "suelo" es el punto del combate donde va el origen del efecto (los pies del enemigo).
# La ventana se borra cuando el efecto termina (señal "terminado" de la escena). Devuelve false si no existe.
func _vfx_3d(ruta: String, suelo: Vector2, oculto := false) -> bool:
	if not ResourceLoader.exists(ruta):
		return false
	if not oculto:
		if efectos_3d_activos >= max_efectos_3d:   # demasiados a la vez: que se dibuje en 2D
			return false
		efectos_3d_activos += 1
	var vp := SubViewport.new()
	vp.size = Vector2i(int(512 * res_efectos), int(768 * res_efectos))
	vp.own_world_3d = true
	vp.transparent_bg = true
	# el de precalentar no se ve, pero tiene que dibujarse para que se compilen sus shaders
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if oculto else SubViewport.UPDATE_WHEN_VISIBLE
	escena.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = VFX_ALTO_VISTA
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	cam.environment = env
	vp.add_child(cam)
	var ang := deg_to_rad(12.0)                      # misma inclinación que los personajes 3D
	cam.look_at_from_position(Vector3(0, 1.4 + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, 1.4, 0))
	cam.current = true
	var fx = load(ruta).instantiate()
	if fx.get_meta("bloom", false) and not movil:  # resplandor alrededor de lo que brilla (rayo)
		env.glow_enabled = true
		env.glow_intensity = 1.2
		env.glow_bloom = 0.25
		env.glow_hdr_threshold = 0.9
	vp.add_child(fx)
	var spr := Sprite2D.new()
	spr.texture = vp.get_texture()
	spr.centered = false
	var k := VFX_PX_METRO / (vp.size.y / VFX_ALTO_VISTA)
	spr.scale = Vector2(k, k)
	spr.position = suelo - cam.unproject_position(Vector3.ZERO) * k
	spr.z_index = 6                                  # delante del enemigo
	spr.visible = not oculto
	escena.add_child(spr)
	var borrar := func():
		spr.queue_free()
		vp.queue_free()
		if not oculto:
			efectos_3d_activos -= 1
	if fx.has_signal("terminado"):
		fx.terminado.connect(borrar)
	else:
		get_tree().create_timer(3.0).timeout.connect(borrar)
	return true


# Al empezar el combate se lanza una vez cada efecto 3D sin que se vea: así sus shaders se compilan
# mientras sale «¡Combate!» y no a mitad de una magia (en el móvil eso daba un parón).
func _precalentar_efectos() -> void:
	for ruta in [VFX_FUEGO, VFX_AGUA, VFX_RAYO, VFX_CURA]:
		_vfx_3d(ruta, Vector2(-2000, -2000), true)


# Punto del suelo bajo los pies de un luchador (donde está su sombra).
func _suelo_de(f: Dictionary) -> Vector2:
	if f.has("sombra"):
		return f["sombra"].position
	return _centro(f) + Vector2(0, 150)


# Círculo mágico que gira en el suelo bajo quien lanza la magia, con chispas que suben.
func _carga_magia(o: Dictionary, magia: String, tam := 1.0) -> Node2D:
	var color: Color = MAGIAS[magia]["color"]
	var raiz := Node2D.new()
	raiz.position = _suelo_de(o)
	raiz.scale = Vector2(1.0, 0.32) * tam         # aplastado: parece tumbado en el suelo
	raiz.material = mat_aditivo
	raiz.modulate.a = 0.0
	escena.add_child(raiz)
	var giro := Node2D.new()
	giro.use_parent_material = true
	raiz.add_child(giro)
	giro.draw.connect(func(): _dibujar_circulo(giro, color))
	create_tween().bind_node(giro).set_loops().tween_property(giro, "rotation", TAU, 4.0).from(0.0)
	var t := create_tween()
	t.tween_property(raiz, "modulate:a", 1.0, 0.3)
	var gl := _brillo(color)
	gl.scale = Vector2(1.6, 1.6)
	gl.modulate.a = 0.5
	raiz.add_child(gl)
	var chispas := _particulas(raiz.position, Color(color, 0.9), Color(color, 0.0), 30, 1.0, Vector2(40, 110),
		90.0, Vector2(0, -1), 10.0, Vector2(0, -60), 0.06, true)
	raiz.set_meta("chispas", chispas)
	return raiz


func _dibujar_circulo(n: Node2D, color: Color) -> void:
	var c := Color(color.r, color.g, color.b, 0.9)
	n.draw_arc(Vector2.ZERO, 120, 0, TAU, 72, c, 4.0)
	n.draw_arc(Vector2.ZERO, 100, 0, TAU, 72, c, 2.0)
	n.draw_arc(Vector2.ZERO, 46, 0, TAU, 48, c, 2.0)
	for tri in 2:                                  # estrella de seis puntas
		var pts := PackedVector2Array()
		for i in 4:
			var a := TAU * i / 3.0 + tri * PI / 3.0 - PI / 2.0
			pts.append(Vector2(cos(a), sin(a)) * 100.0)
		n.draw_polyline(pts, c, 2.0)
	for i in 6:
		var a := TAU * i / 6.0 - PI / 2.0
		n.draw_circle(Vector2(cos(a), sin(a)) * 100.0, 7.0, c)
	for i in 36:                                   # marcas como runas entre los dos anillos
		var a := TAU * i / 36.0
		var r1 := 104.0
		var r2 := 116.0 if i % 3 == 0 else 110.0
		n.draw_line(Vector2(cos(a), sin(a)) * r1, Vector2(cos(a), sin(a)) * r2, c, 2.0)


func _quitar_carga(c: Node2D) -> void:
	if c == null or not is_instance_valid(c):
		return
	var ch = c.get_meta("chispas", null)
	if ch != null and is_instance_valid(ch):
		ch.emitting = false
		get_tree().create_timer(1.2).timeout.connect(ch.queue_free)
	var t := create_tween()
	t.tween_property(c, "modulate:a", 0.0, 0.5)
	t.tween_callback(c.queue_free)


# Bola de fuego o de agua que vuela hasta el enemigo dejando una estela.
func _proyectil(desde: Vector2, hasta: Vector2, magia: String) -> void:
	var color: Color = MAGIAS[magia]["color"]
	var bola := _brillo(color)
	bola.position = desde
	bola.scale = Vector2(0.55, 0.55)
	escena.add_child(bola)
	var nucleo := _brillo(Color(1.0, 0.8, 0.35, 0.85) if magia == "Fuego" else Color(1, 1, 1, 0.9))
	nucleo.scale = Vector2(0.45, 0.45)
	bola.add_child(nucleo)
	var estela := CPUParticles2D.new()
	estela.texture = glow_tex
	estela.material = mat_aditivo
	estela.local_coords = false
	estela.amount = 60
	estela.lifetime = 0.45
	estela.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	estela.emission_sphere_radius = 14.0
	estela.gravity = Vector2(0, -80) if magia == "Fuego" else Vector2(0, 260)
	estela.initial_velocity_min = 10.0
	estela.initial_velocity_max = 40.0
	estela.spread = 180.0
	estela.scale_amount_min = 0.12
	estela.scale_amount_max = 0.22
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(color.lightened(0.4), 0.9), Color(color, 0.0)])
	estela.color_ramp = g
	bola.add_child(estela)
	var luz := _luz(color, 1.4, 3.0)
	bola.add_child(luz)
	# vuela con un pequeño arco
	var medio := desde.lerp(hasta, 0.5) + Vector2(0, -90)
	var t := create_tween()
	t.tween_method(func(k: float):
		bola.position = desde.lerp(medio, k).lerp(medio.lerp(hasta, k), k), 0.0, 1.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	estela.emitting = false
	estela.reparent(escena)
	get_tree().create_timer(0.6).timeout.connect(estela.queue_free)
	bola.queue_free()


# Luz de verdad que ilumina el fondo y a los luchadores (se apaga sola si se le pone duración).
func _luz(color: Color, energia: float, escala: float, dur := 0.0, pos := Vector2.ZERO) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = glow_tex
	l.color = color
	l.energy = energia
	l.texture_scale = escala
	l.enabled = not movil                            # en el móvil las luces 2D cuestan demasiado
	if dur > 0.0:
		l.position = pos
		escena.add_child(l)
		var t := create_tween()
		t.tween_property(l, "energy", 0.0, dur).set_ease(Tween.EASE_IN)
		t.tween_callback(l.queue_free)
	return l


# Onda que se abre en el suelo y se desvanece.
func _onda(pos: Vector2, color: Color, r0: float, r1: float, dur: float, grosor: float) -> void:
	var n := Node2D.new()
	n.position = pos
	n.scale = Vector2(1.0, 0.32)
	n.material = mat_aditivo
	escena.add_child(n)
	var est := {"t": 0.0}
	n.draw.connect(func():
		var k: float = est["t"]
		var r := lerpf(r0, r1, 1.0 - pow(1.0 - k, 3.0))
		n.draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(color.r, color.g, color.b, color.a * (1.0 - k)), grosor * (1.0 - k * 0.7)))
	var t := create_tween()
	t.tween_method(func(v: float):
		est["t"] = v
		n.queue_redraw(), 0.0, 1.0, dur)
	t.tween_callback(n.queue_free)


# Destello de color en toda la pantalla (debajo de los menús).
func _fogonazo(color: Color, alfa: float, dur: float) -> void:
	var r := ColorRect.new()
	r.color = Color(color, alfa)
	r.position = -escena.position / TAM_ESCENA
	r.size = Vector2(1280, 720) / TAM_ESCENA
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escena.add_child(r)                            # el último de la escena: encima de los luchadores
	var t := create_tween()
	t.tween_property(r, "color:a", 0.0, dur)
	t.tween_callback(r.queue_free)


# Humo oscuro que sube despacio (sin brillo).
func _humo(pos: Vector2, color: Color, cantidad: int) -> void:
	var p := CPUParticles2D.new()
	p.texture = glow_tex
	p.position = pos
	p.amount = mini(cantidad, 60) if movil else cantidad   # móvil: como mucho 60 partículas
	p.lifetime = 1.6
	p.one_shot = true
	p.explosiveness = 0.3
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 50.0
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2(10, -50)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.7
	var c := Curve.new()
	c.add_point(Vector2(0, 0.4))
	c.add_point(Vector2(1, 1.0))
	p.scale_amount_curve = c
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	g.colors = PackedColorArray([Color(color, 0.0), Color(color, 0.45), Color(color, 0.0)])
	p.color_ramp = g
	escena.add_child(p)
	p.emitting = true
	get_tree().create_timer(2.4).timeout.connect(p.queue_free)


# Magias de nivel II y III: dan a todos los enemigos a la vez.
# Nivel II: la carga se divide en un proyectil para cada enemigo.
# Nivel III: Infierno hace caer meteoros sobre cada enemigo; Maremoto lanza una ola gigante.
func _magia_grupal(o: Dictionary, objs: Array, magia: String, nivel: int, dano: int) -> void:
	var color: Color = MAGIAS[magia]["color"]
	o["animando"] = true
	var circulo := _carga_magia(o, magia, 1.3 if nivel == 2 else 1.7)
	var maga = _p3d(o)
	var punto: Vector2
	if maga != null:
		await maga.lanzar_magia()
		var cam: Camera3D = o["cam3d"]
		var spr: Sprite2D = o["partes"]["sprite"]
		punto = escena.to_local(spr.to_global(cam.unproject_position(maga.punto_magia())))
	else:
		await get_tree().create_timer(0.5).timeout
		punto = _centro(o) + Vector2(0, -80)
	# carga más larga y más grande cuanto más nivel
	var halo := _brillo(color)
	halo.position = punto
	halo.scale = Vector2.ZERO
	escena.add_child(halo)
	var carga := 0.6 if nivel == 2 else 1.0
	var chispas := _particulas(punto, Color(color, 0.9), Color(color, 0.0), 30 * nivel, carga, Vector2(80, 200),
		90.0 * nivel, Vector2(0, -1), 180.0, Vector2(0, 0), 0.08)
	chispas.gravity = Vector2.ZERO
	var t := create_tween()
	t.tween_property(halo, "scale", Vector2(1.0, 1.0) * nivel * 0.7, carga).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	if nivel == 3:
		_fogonazo(color, 0.35, 0.8)
		_temblor(5.0)
	halo.queue_free()

	var potencia := 0.7 if nivel == 2 else 1.0001     # distinto de 1: sin destello ni temblor por cada enemigo
	var impacto_en := func(obj: Dictionary) -> void:
		var d := dano + randi_range(-4, 4)
		_quitar_pv(obj, d)
		_golpe_visual(obj, d, magia, false, potencia)
	if nivel == 2:
		_fogonazo(color, 0.2, 0.4)
		for obj in objs:
			_lanzar(punto, _centro(obj), magia)
		await get_tree().create_timer(0.44 if magia != "Rayo" else 0.2).timeout
		_temblor(7.0)
		for obj in objs:
			impacto_en.call(obj)
	elif magia == "Fuego":
		await _lluvia_meteoros(objs, impacto_en)
	elif magia == "Rayo":
		await _tormenta(objs, impacto_en)
	else:
		await _maremoto(objs, impacto_en)
	_quitar_carga(circulo)
	await get_tree().create_timer(0.9).timeout
	if maga != null:
		maga.fin_magia()
	await get_tree().create_timer(0.35).timeout
	o["animando"] = false


# Infierno: meteoros que caen del cielo, uno sobre cada enemigo y otros alrededor.
func _lluvia_meteoros(objs: Array, impacto_en: Callable) -> void:
	_fogonazo(Color(1.0, 0.3, 0.05), 0.25, 1.4)
	_luz(Color(1.0, 0.4, 0.1), 2.0, 12.0, 2.0, Vector2(300, 300))
	var rng := RandomNumberGenerator.new()
	for i in 6:                                    # meteoros de adorno (no hacen daño)
		var p := Vector2(rng.randf_range(-150, 650), rng.randf_range(380, 560))
		get_tree().create_timer(rng.randf_range(0.0, 0.9)).timeout.connect(func():
			await _proyectil(p + Vector2(300, -800), p, "Fuego")
			_destello(p, Color(1.0, 0.45, 0.1, 0.7), 1.2)
			_onda(p, Color(1.0, 0.6, 0.2, 0.8), 10.0, 140.0, 0.5, 10.0)
			_particulas(p, Color(1.0, 0.6, 0.15, 0.8), Color(0.6, 0.03, 0.0, 0.0), 40, 0.7, Vector2(150, 350),
				30.0, Vector2(0, -1), 30.0, Vector2(0, -150), 0.2))
	for i in objs.size():
		var obj: Dictionary = objs[i]
		var c := _centro(obj)
		get_tree().create_timer(0.15 + i * 0.22).timeout.connect(func():
			await _proyectil(c + Vector2(320, -820), c, "Fuego")
			impacto_en.call(obj)
			_temblor(13.0))
	await get_tree().create_timer(0.15 + objs.size() * 0.22 + 0.6).timeout


# Maremoto: una ola gigante cruza la pantalla y golpea a cada enemigo al pasar.
func _maremoto(objs: Array, impacto_en: Callable) -> void:
	_fogonazo(Color(0.3, 0.6, 1.0), 0.25, 1.2)
	var suelo_y := 0.0
	for obj in objs:
		suelo_y += _suelo_de(obj).y
	suelo_y /= maxf(1.0, objs.size())
	var desde := 1150.0
	var hasta := -500.0
	var dur := 1.3
	var ola := Node2D.new()
	ola.position = Vector2(desde, suelo_y)
	escena.add_child(ola)
	for k in 6:                                    # cuerpo de la ola: manchas azules superpuestas
		var b := _brillo(Color(0.25, 0.55, 1.0, 0.55))
		b.position = Vector2(k * 60.0, -120.0 - k * 22.0)
		b.scale = Vector2(2.2, 3.2 - k * 0.3)
		ola.add_child(b)
	var cresta := _brillo(Color(0.85, 0.95, 1.0, 0.8))
	cresta.position = Vector2(-20, -260)
	cresta.scale = Vector2(1.6, 0.9)
	ola.add_child(cresta)
	var espuma := CPUParticles2D.new()               # espuma que salta de la cresta
	espuma.texture = glow_tex
	espuma.material = mat_aditivo
	espuma.local_coords = false
	espuma.amount = 60 if movil else 120
	espuma.lifetime = 0.9
	espuma.position = Vector2(-20, -250)
	espuma.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	espuma.emission_rect_extents = Vector2(40, 160)
	espuma.direction = Vector2(-1, -0.6)
	espuma.spread = 30.0
	espuma.initial_velocity_min = 200.0
	espuma.initial_velocity_max = 420.0
	espuma.gravity = Vector2(0, 700)
	espuma.scale_amount_min = 0.06
	espuma.scale_amount_max = 0.14
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(0.9, 0.97, 1.0, 1.0), Color(0.4, 0.7, 1.0, 0.0)])
	espuma.color_ramp = g
	ola.add_child(espuma)
	ola.add_child(_luz(Color(0.4, 0.7, 1.0), 1.6, 6.0))
	var t := create_tween()
	t.tween_property(ola, "position:x", hasta, dur)
	for obj in objs:                               # el golpe llega cuando la ola pasa por cada enemigo
		var x := _centro(obj).x
		var cuando := clampf((desde - x) / (desde - hasta), 0.0, 1.0) * dur
		var o2: Dictionary = obj
		get_tree().create_timer(cuando).timeout.connect(func():
			impacto_en.call(o2)
			_temblor(10.0))
	await t.finished
	espuma.emitting = false
	var t2 := create_tween()
	t2.tween_property(ola, "modulate:a", 0.0, 0.4)
	t2.tween_callback(ola.queue_free)


# Lanza la magia hacia el enemigo: Fuego y Agua vuelan como proyectil; el Rayo no vuela, la
# carga sube al cielo y el rayo cae directamente sobre el enemigo.
func _lanzar(desde: Vector2, hasta: Vector2, magia: String) -> void:
	if magia != "Rayo":
		await _proyectil(desde, hasta, magia)
		return
	var chispa := _brillo(MAGIAS["Rayo"]["color"])
	chispa.position = desde
	chispa.scale = Vector2(0.5, 0.5)
	escena.add_child(chispa)
	var t := create_tween()
	t.tween_property(chispa, "position", desde + Vector2(0, -500), 0.18).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(chispa, "scale", Vector2(0.15, 1.2), 0.18)
	await t.finished
	chispa.queue_free()
	_fogonazo(Color(0.75, 0.92, 1.0), 0.18, 0.12)
	await get_tree().create_timer(0.08).timeout


# Rayo: cae del cielo sobre el enemigo (LightningImpactVFX.tscn) con destello, onda eléctrica,
# chispas y luz que parpadea. Si falta la escena, un rayo 2D en zigzag.
func _efecto_rayo(centro: Vector2, suelo: Vector2, potencia := 1.0) -> void:
	var q := potencia
	var cian := Color(0.5, 0.88, 1.0)
	if potencia == 1.0:
		_fogonazo(Color(0.8, 0.95, 1.0), 0.35, 0.18)
		_temblor(9.0)
	_vfx_3d(VFX_RAYO, suelo)                       # rayo 3D con su disco de impacto en el suelo
	_rayo_2d(suelo)                                # tronco grueso con ramas y resplandor
	var luz := _luz(cian, 3.5, 6.0, 0.4, suelo + Vector2(0, -60))
	var t := create_tween()                         # la luz parpadea dos veces
	for i in 2:
		t.tween_property(luz, "energy", 4.0, 0.03)
		t.tween_property(luz, "energy", 0.6, 0.05)
	_destello(suelo + Vector2(0, -30), Color(0.6, 0.9, 1.0, 0.6), 1.4)
	_onda(suelo, Color(0.6, 0.92, 1.0, 0.95), 15.0, 230.0, 0.45, 9.0)
	_onda(suelo, Color(0.85, 0.97, 1.0, 0.8), 10.0, 140.0, 0.3, 6.0)
	_particulas(suelo, Color(0.95, 1.0, 1.0, 1.0), Color(0.3, 0.7, 1.0, 0.0), int(60 * q), 0.5, Vector2(250, 600),
		25.0, Vector2(0, -1), 70.0, Vector2(0, 700), 0.05)
	_particulas(centro, Color(0.7, 0.95, 1.0, 0.9), Color(0.3, 0.6, 1.0, 0.0), int(30 * q), 0.35, Vector2(40, 160),
		70.0, Vector2(0, -1), 180.0, Vector2(0, 0), 0.07)


# Rayo dibujado en 2D: tronco en zigzag desde el cielo con varias ramas, en tres capas
# (resplandor cian, cuerpo claro y núcleo blanco). Tiembla un par de veces y se apaga.
func _rayo_2d(suelo: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var tronco := _zigzag(rng, Vector2(suelo.x + rng.randf_range(-60, 60), suelo.y - 1000.0), suelo, 45.0, 34.0)
	var trazos: Array = [[tronco, 1.0]]
	for i in 4:                                    # ramas que salen del tronco
		var desde: Vector2 = tronco[rng.randi_range(3, tronco.size() - 4)]
		var lado := 1.0 if rng.randf() < 0.5 else -1.0
		var hasta := desde + Vector2(lado * rng.randf_range(90, 200), rng.randf_range(60, 180))
		trazos.append([_zigzag(rng, desde, hasta, 22.0, 18.0), 0.45])
	var nodo := Node2D.new()
	nodo.material = mat_aditivo
	escena.add_child(nodo)
	for tr in trazos:
		for capa_r in [[34.0, Color(0.35, 0.75, 1.0, 0.4)], [13.0, Color(0.75, 0.94, 1.0, 0.9)], [5.0, Color(1, 1, 1, 1)]]:
			var l := Line2D.new()
			l.points = tr[0]
			l.width = capa_r[0] * tr[1]
			l.default_color = capa_r[1]
			l.use_parent_material = true
			l.joint_mode = Line2D.LINE_JOINT_ROUND
			l.end_cap_mode = Line2D.LINE_CAP_ROUND
			nodo.add_child(l)
	var t := create_tween()                        # aparece de golpe, parpadea dos veces y se apaga
	for i in 2:
		t.tween_property(nodo, "modulate:a", 0.35, 0.04)
		t.tween_property(nodo, "modulate:a", 1.0, 0.04)
	t.tween_property(nodo, "modulate:a", 0.0, 0.22).set_ease(Tween.EASE_IN)
	t.tween_callback(nodo.queue_free)


func _zigzag(rng: RandomNumberGenerator, a: Vector2, b: Vector2, paso: float, desvio: float) -> PackedVector2Array:
	var pts := PackedVector2Array([a])
	var n := maxi(2, int(a.distance_to(b) / paso))
	var normal := (b - a).normalized().orthogonal()
	for i in range(1, n):
		pts.append(a.lerp(b, float(i) / n) + normal * rng.randf_range(-desvio, desvio))
	pts.append(b)
	return pts


# Cólera del Cielo: el cielo se oscurece y caen varios rayos seguidos sobre cada enemigo.
func _tormenta(objs: Array, impacto_en: Callable) -> void:
	var oscuro := ColorRect.new()
	oscuro.color = Color(0.02, 0.04, 0.12, 0.0)
	oscuro.position = -escena.position / TAM_ESCENA
	oscuro.size = Vector2(1280, 720) / TAM_ESCENA
	oscuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escena.add_child(oscuro)
	escena.move_child(oscuro, 1)                   # detrás de los luchadores
	var t := create_tween()
	t.tween_property(oscuro, "color:a", 0.45, 0.3)
	await t.finished
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 5:                                    # rayos de adorno alrededor
		var p := Vector2(rng.randf_range(-150, 650), rng.randf_range(400, 560))
		get_tree().create_timer(rng.randf_range(0.0, 0.9)).timeout.connect(func():
			if not movil:                          # en el móvil, los rayos de adorno solo en 2D
				_vfx_3d(VFX_RAYO, p)
			_rayo_2d(p)
			_onda(p, Color(0.6, 0.92, 1.0, 0.8), 10.0, 150.0, 0.4, 7.0)
			_fogonazo(Color(0.8, 0.95, 1.0), 0.15, 0.1))
	for i in objs.size():
		var obj: Dictionary = objs[i]
		get_tree().create_timer(0.1 + i * 0.25).timeout.connect(func():
			impacto_en.call(obj)
			_fogonazo(Color(0.85, 0.97, 1.0), 0.3, 0.15)
			_temblor(12.0))
	await get_tree().create_timer(0.1 + objs.size() * 0.25 + 0.6).timeout
	var t2 := create_tween()
	t2.tween_property(oscuro, "color:a", 0.0, 0.5)
	t2.tween_callback(oscuro.queue_free)


# Agua: ondas en el suelo, un géiser que lo levanta, gotas que giran en espiral,
# una burbuja que lo envuelve y una lluvia de gotas al caer.
func _efecto_agua(centro: Vector2, suelo: Vector2, potencia := 1.0) -> void:
	var q := potencia                             # varios enemigos a la vez: menos partículas por cada uno
	var azul := Color(0.45, 0.75, 1.0)
	if potencia == 1.0:
		_fogonazo(Color(0.4, 0.7, 1.0), 0.22, 0.35)
	_luz(azul, 2.2, 5.0, 1.0, centro)
	for i in 3:
		get_tree().create_timer(i * 0.12).timeout.connect(_onda.bind(suelo, Color(0.7, 0.9, 1.0, 0.9), 20.0, 220.0 + i * 40.0, 0.8, 10.0))
	# géiser 3D (WaterImpactVFX.tscn) donde llega el proyectil; si no está, chorro de gotas 2D
	if not _vfx_3d(VFX_AGUA, suelo):
		_particulas(suelo, Color(0.55, 0.8, 1.0, 0.8), Color(0.15, 0.4, 1.0, 0.0), int(110 * q), 1.1, Vector2(450, 750),
			35.0, Vector2(0, -1), 9.0, Vector2(0, 1100), 0.11)
	# espiral de gotas alrededor del enemigo
	var esp := _particulas(suelo + Vector2(0, -20), Color(0.8, 0.95, 1.0, 1.0), Color(0.3, 0.6, 1.0, 0.0), int(70 * q), 1.0, Vector2(10, 30),
		85.0, Vector2(0, -1), 20.0, Vector2(0, -260), 0.1)
	esp.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	esp.orbit_velocity_min = 0.9
	esp.orbit_velocity_max = 1.3
	# burbuja que lo envuelve
	var burbuja := _brillo(Color(0.3, 0.6, 1.0, 0.0))
	burbuja.position = centro
	burbuja.scale = Vector2(0.3, 0.3)
	escena.add_child(burbuja)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(burbuja, "scale", Vector2(1.8, 2.2), 0.3)
	t.tween_property(burbuja, "modulate:a", 0.75, 0.3)
	t.chain().tween_interval(0.4)
	t.chain().tween_property(burbuja, "scale", Vector2(2.4, 2.6), 0.15)
	t.parallel().tween_property(burbuja, "modulate:a", 0.0, 0.15)
	t.chain().tween_callback(burbuja.queue_free)
	# al reventar la burbuja: salpicadura en todas direcciones
	get_tree().create_timer(0.7).timeout.connect(func():
		_particulas(centro, Color(0.9, 0.97, 1.0, 1.0), Color(0.3, 0.6, 1.0, 0.0), int(60 * q), 0.8, Vector2(250, 480),
			40.0, Vector2(0, -1), 180.0, Vector2(0, 900), 0.09)
		_humo(suelo + Vector2(0, -30), Color(0.85, 0.92, 1.0), 14))


# Fuego: onda de calor, columna de llamas, chispas que saltan, humo y suelo chamuscado.
func _efecto_fuego(centro: Vector2, suelo: Vector2, potencia := 1.0) -> void:
	var q := potencia
	var naranja := Color(1.0, 0.55, 0.15)
	if potencia == 1.0:
		_fogonazo(Color(1.0, 0.32, 0.05), 0.22, 0.35)
		_temblor(8.0)
	_destello(centro, Color(1.0, 0.32, 0.04, 0.45), 1.5)
	_luz(naranja, 3.0, 6.0, 1.3, centro)
	_onda(suelo, Color(1.0, 0.7, 0.3, 0.9), 20.0, 300.0, 0.6, 16.0)
	# suelo chamuscado
	var marca := Sprite2D.new()
	marca.texture = glow_tex
	marca.position = suelo
	marca.scale = Vector2(1.6, 0.45)
	marca.modulate = Color(0.08, 0.04, 0.02, 0.7)
	sombras.add_child(marca)
	var tm := create_tween()
	tm.tween_interval(1.0)
	tm.tween_property(marca, "modulate:a", 0.0, 1.5)
	tm.tween_callback(marca.queue_free)
	# vórtice de fuego 3D (FireImpactVFX.tscn) donde llega el proyectil; si no está, columna de llamas 2D
	if not _vfx_3d(VFX_FUEGO, suelo):
		_particulas(suelo, Color(1.0, 0.55, 0.12, 0.75), Color(0.6, 0.03, 0.0, 0.0), int(120 * q), 0.9, Vector2(300, 560),
			55.0, Vector2(0, -1), 12.0, Vector2(0, -250), 0.3)
	# bola de fuego que envuelve al enemigo
	_particulas(centro, Color(1.0, 0.45, 0.1, 0.7), Color(0.5, 0.03, 0.0, 0.0), int(50 * q), 0.6, Vector2(120, 260),
		70.0, Vector2(0, -1), 180.0, Vector2(0, -120), 0.22)
	# chispas que saltan y caen
	_particulas(centro, Color(1.0, 1.0, 0.8, 1.0), Color(1.0, 0.4, 0.0, 0.0), int(70 * q), 0.9, Vector2(300, 650),
		20.0, Vector2(0, -1), 180.0, Vector2(0, 900), 0.05)
	get_tree().create_timer(0.35).timeout.connect(_humo.bind(centro, Color(0.18, 0.15, 0.14), 26))


# Quemadura: una llama pequeña permanece encima del enemigo mientras dure.
func _encender_llama(f: Dictionary) -> void:
	if f["llama"] != null and is_instance_valid(f["llama"]):
		return
	f["llama"] = _particulas(_centro(f) + Vector2(0, -40), Color(1.0, 0.8, 0.3, 0.9), Color(0.8, 0.15, 0.0, 0.0), 16, 0.6,
		Vector2(30, 70), 18.0, Vector2(0, -1), 20.0, Vector2(0, -60), 0.12, true)


func _apagar_llama(f: Dictionary) -> void:
	if f["llama"] != null and is_instance_valid(f["llama"]):
		var ll: CPUParticles2D = f["llama"]
		ll.emitting = false
		get_tree().create_timer(1.0).timeout.connect(ll.queue_free)
	f["llama"] = null


func _tic_quemadura(f: Dictionary) -> void:
	registro.text = "%s sufre quemaduras" % f["nombre"]
	_particulas(_centro(f) + Vector2(0, 40), Color(1.0, 0.85, 0.35, 1.0), Color(0.8, 0.1, 0.0, 0.0), 40, 0.6,
		Vector2(90, 200), 50.0, Vector2(0, -1), 25.0, Vector2(0, -120), 0.2)
	_quitar_pv(f, DANO_QUEMADURA)
	f["quemadura"] -= 1
	f["rig"].modulate = Color(1.6, 0.7, 0.3)
	_numero_flotante(f, str(DANO_QUEMADURA), Color(1.0, 0.6, 0.2))
	_actualizar()
	await get_tree().create_timer(0.5).timeout
	if f["quemadura"] <= 0 or f["hp"] <= 0:
		_apagar_llama(f)
	_restablecer_color(f)
	await get_tree().create_timer(0.3).timeout


func _restablecer_color(f: Dictionary) -> void:
	var rig: Node2D = f["rig"]
	if _p3d(f) != null:
		if f["hp"] > 0:
			rig.modulate = COLOR_DEFENSA if f.get("defendiendo", false) else Color(1, 1, 1)
			_p3d(f).cansada(f["hp"] < f["hp_max"] * 0.3)
		else:
			f["defendiendo"] = false
			rig.modulate = Color(0.6, 0.6, 0.68)
			_p3d(f).morir()
			if not f["hero"]:                          # enemigo 3D: cae y luego se desvanece
				var t := create_tween()
				t.tween_interval(0.9)
				t.tween_property(rig, "modulate:a", 0.0, 0.5)
		return
	if not f["animando"]:
		_cara_reposo(f)
	if f["hp"] > 0:
		rig.modulate = COLOR_DEFENSA if f.get("defendiendo", false) else Color(1, 1, 1)
	elif f["hero"]:
		f["defendiendo"] = false
		rig.modulate = Color(0.35, 0.35, 0.4)
		f["cuerpo"].rotation_degrees = 25.0
		rig.position = f["rig_base"] + Vector2(0, 30)
	else:
		_apagar_llama(f)
		var t := create_tween()
		if _es_sprite(f):
			rig.modulate = Color(1, 1, 1)
			_reproducir(f, "dead", false)
			t.tween_interval(0.7)                  # deja ver la animación de muerte antes de desvanecerse
		t.tween_property(rig, "modulate:a", 0.0, 0.5)


func _destello(centro: Vector2, color: Color, tam: float) -> void:
	var g := _brillo(color)
	g.position = centro
	g.scale = Vector2(0.2, 0.2) * tam
	escena.add_child(g)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(g, "scale", Vector2(1.5, 1.5) * tam, 0.35)
	t.tween_property(g, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(g.queue_free)


# Sacude toda la escena unos instantes.
func _temblor(fuerza: float) -> void:
	var t := create_tween()
	for i in 6:
		var k := fuerza * (1.0 - i / 6.0)
		t.tween_property(capa, "offset", Vector2(randf_range(-k, k), randf_range(-k, k)), 0.03)
	t.tween_property(capa, "offset", Vector2.ZERO, 0.03)


func _numero_flotante(f: Dictionary, texto: String, color: Color, tam := TAM_NUMERO) -> void:
	var l := _etiqueta(texto, tam, color)
	l.add_theme_constant_override("outline_size", 8)
	if f.has("centro_ofs"):                       # personajes 3D: encima del cuerpo
		l.position = _a_pantalla(_centro(f) + Vector2(-28, -115))
	else:
		l.position = _a_pantalla(f["pos"] + Vector2(100, _alto_barra(f))) + Vector2(0, 50)
	capa.add_child(l)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 60.0, 0.9)
	t.tween_property(l, "modulate:a", 0.0, 0.9)
	t.chain().tween_callback(l.queue_free)


# ================================================================= fin y textos

func _comprobar_fin() -> bool:
	var ganan := enemigos.all(func(e): return e["hp"] <= 0)
	var pierden := heroes.all(func(h): return h["hp"] <= 0)
	if ganan or pierden:
		estado = "fin"
		_ocultar_menu()
		registro.text = "¡Victoria!" if ganan else "Derrota..."
		if ganan:
			for h in heroes:
				if h["hp"] > 0:
					_cara(h, "sonrisa")
					if _p3d(h) != null:
						_p3d(h).victoria()
		_bajar_musica()
		_fin_combate(ganan)
		return true
	return false


func _fin_combate(ganan: bool) -> void:
	if ganan and combate_fijo != "":
		var g: Dictionary = Engine.get_meta("combates_ganados", {})
		g[combate_fijo] = true
		Engine.set_meta("combates_ganados", g)
	await _repartir_exp(ganan)
	_volver_al_mapa()


# Al ganar, cada héroe en pie gana la experiencia de todos los enemigos y puede subir de nivel.
# La vida que quede se guarda para el siguiente combate (al perder, el grupo vuelve con la vida llena).
func _repartir_exp(ganan: bool) -> void:
	if not ResourceLoader.exists("res://grupo.gd"):
		return
	var gr = load("res://grupo.gd")
	var total := 0
	var oro := 0
	for e in enemigos:
		if e.get("huido", false):                 # los que huyen no dan nada
			continue
		total += int(e.get("exp", 0))
		oro += int(e.get("oro", 0))
	for h in heroes:
		if gr.datos().has(h["nombre"]):
			gr.guardar_vida(h["nombre"], h["hp"], h["mp"])
	if not ganan:
		gr.curar_todos()
		return
	await get_tree().create_timer(1.0).timeout
	var mult: float = load("res://progreso.gd").mult_exp(Engine.get_meta("zona", "llanura"),
		Engine.get_meta("tipo_combate", "normal"), load("res://progreso.gd").nivel_grupo())
	registro.text = "+%d EXP   +%d monedas" % [int(round(total * mult)), oro]
	if ResourceLoader.exists("res://inventario.gd"):
		load("res://inventario.gd").ganar_oro(oro)
	# progreso.gd: más experiencia si van por debajo del nivel de la zona, muy poca si van 5 por encima;
	# los jefes dan mucho. Todos suben: los caídos ganan la mitad.
	var Progreso = load("res://progreso.gd")
	var zona: String = Engine.get_meta("zona", "llanura")
	var tipo: String = Engine.get_meta("tipo_combate", "normal")
	for h in heroes:
		if not gr.datos().has(h["nombre"]):
			continue
		var cantidad := int(round(total * Progreso.mult_exp(zona, tipo, gr.datos()[h["nombre"]]["nivel"])))
		if h["hp"] <= 0:
			gr.ganar_exp(h["nombre"], cantidad / 2)
			continue
		var subidos: int = gr.ganar_exp(h["nombre"], cantidad)
		if subidos > 0:
			await get_tree().create_timer(1.0).timeout
			var nivel: int = gr.datos()[h["nombre"]]["nivel"]
			var e: Dictionary = gr.estadisticas(h["nombre"])   # al subir se cura del todo
			h["hp_max"] = e["pv_max"]
			h["hp"] = e["pv"]
			h["mp_max"] = e["pm_max"]
			h["mp"] = e["pm"]
			_actualizar()
			registro.text = "¡%s sube al nivel %d!" % [h["nombre"], nivel]
			_numero_flotante(h, "¡Nivel %d!" % nivel, Color(1.0, 0.9, 0.3), 40)
			_particulas(_centro(h) + Vector2(0, 80), Color(1.0, 0.95, 0.5, 1.0), Color(1.0, 0.8, 0.2, 0.0), 50, 1.2,
				Vector2(60, 160), 70.0, Vector2(0, -1), 25.0, Vector2(0, -60), 0.08)
			for k in NIVELES_MAGIA:                # magias nuevas
				var nm: int = gr.nivel_magia(h["nombre"], k)
				if nm > 0 and gr.NIVEL_MAGIA[nm - 1] > nivel - subidos:
					await get_tree().create_timer(1.0).timeout
					registro.text = "%s aprende %s" % [h["nombre"], NIVELES_MAGIA[k][nm - 1]["nombre"]]
	await get_tree().create_timer(0.6).timeout


# Si el combate empezó en un mapa, tras un par de segundos se vuelve a él.
func _volver_al_mapa() -> void:
	if not Engine.get_meta("desde_mapa", false):
		# combate suelto (sin mapa): ofrecer repetirlo
		await get_tree().create_timer(1.5).timeout
		menu.abrir({"nombre": "Fin", "mp": 0, "mp_max": 0}, [{"texto": "REINTENTAR", "accion": func(): get_tree().reload_current_scene()}])
		return
	await get_tree().create_timer(2.0).timeout
	Engine.set_meta("desde_mapa", false)
	# vuelve a la escena desde la que empezó (mapa del mundo o mapa de una zona)
	load("res://progreso.gd").guardar(Engine.get_meta("escena_retorno", "res://mapa.tscn"))   # guardado tras el combate
	var negro := ColorRect.new()
	negro.color = Color(0, 0, 0, 0)
	negro.size = Vector2(1280, 720)
	capa.add_child(negro)
	await create_tween().tween_property(negro, "color:a", 1.0, 0.4).finished
	Recursos.cambiar_escena(Engine.get_meta("escena_retorno", "res://mapa.tscn"))


func _actualizar() -> void:
	menu.actualizar_grupo(actor)
	for e in enemigos:
		var vivo: bool = e["hp"] > 0
		e["lbl_hp"].visible = vivo
		e["barra_hp"].visible = vivo
		e["lbl_hp"].text = "PV %d/%d" % [e["hp"], e["hp_max"]]
		_poner_barra(e["barra_hp"], float(e["hp"]) / e["hp_max"])
		if e.has("lbl_estado"):
			var estados := PackedStringArray()
			if e.get("congelado", 0) > 0:
				estados.append("❄ Congelado")
			if e.get("cargando", false):
				estados.append("⚠ Cargando")
			if e.get("furia", false):
				estados.append("Furia")
			e["lbl_estado"].text = "  ".join(estados)
			e["lbl_estado"].visible = vivo
