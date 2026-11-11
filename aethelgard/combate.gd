extends Node2D
# Combate ATB de Aethelgard (Godot 4.x)
# Personajes articulados, menú estilo FFIX, magias Agua y Fuego (con quemadura) y vida sobre los enemigos.
# Kael y la maga blanca (Lya) son modelos 3D que se dibujan cada uno en una ventana 3D propia (SubViewport).
# Kael necesita kael_3d.gd + maga_3d.gd + gestos_3d.gd + kael.fbx; la maga, maga_3d.gd + gestos_3d.gd + su .fbx.
# Si falta algo, se usa la versión 2D de antes (aventurero o Nyx 2D).
# Se adjunta al nodo raíz de combate.tscn (Nodo 2D). Crea toda la interfaz por código.

# Modo pruebas: las magias no gastan PM. Es solo de depuración: se activa al arrancar con «-- pm_infinitos».
# En el juego normal siempre se pagan los PM («false para el juego de verdad», como decía este comentario).
var MODO_PRUEBAS: bool = "pm_infinitos" in OS.get_cmdline_user_args()
# Frostfang: cada golpe de Kael congela al enemigo (pierde 2 de Vitalidad = 16 PV máximos durante
# 2 rondas). PROB_CONGELAR = probabilidad (1.0 = siempre).
const PROB_CONGELAR := 1.0
const RONDAS_CONGELACION := 2
const VITALIDAD_CONGELACION := 2
const ATB_MAX := 100.0
const Formulas := preload("res://combate_formulas.gd")   # fórmulas de daño (10/11)
const Recompensas := preload("res://combate_recompensas.gd")   # experiencia y monedas al terminar (10/11, fase 2)
const Escalado := preload("res://combate_escalado.gd")   # nivel del encuentro por región y jefes (V9, hito 7)
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
	# Alquimia de Lya (fase 3, «El bosque que no recuerda»; combate_bosque.gd). Solo salen en el menú si se tienen.
	"Esencia de enfoque": {"que": "ENFOQUE", "cura": 0, "imagen": "res://objetos/eter.png", "color": Color(0.7, 0.55, 1.0),
		"desc": "Su magia hace ×1,3 durante 3 turnos."},
	"Elixir de savia purificada": {"que": "PURIFICA", "cura": 0, "imagen": "res://objetos/pocion.png",
		"color": Color(0.55, 1.0, 0.45), "desc": "Purifica al Guardián del Bosque, en su segunda fase."},
	# V10, «La fórmula desaparecida»: el bálsamo de Mirta cura a todo el grupo (sin elegir a quién).
	"Bálsamo de Mirta": {"que": "PV_TODOS", "cura": 45, "imagen": "res://objetos/pocion.png", "color": Color(1.0, 0.7, 0.45),
		"desc": "+45 PV a todo el grupo."},
}
const Bosque := preload("res://combate_bosque.gd")   # el Guardián, la Esencia y el Elixir (fase 3)
const Coloso := preload("res://combate_coloso.gd")   # el Coloso de la Falla (V9, jefe 2; Garganta 3D)
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

# Ampliaciones de T-091 y T-092 (docs/diseno/combate_enganches.md): las artes van por su propia ruta (_elegir_arte y
# _lanzar_arte) y no tocan MAGIAS ni NIVELES_MAGIA; los accesorios solo suman sus efectos (equipo_extra.gd).
const Artes := preload("res://artes.gd")             # familias nuevas de T-091 (Alba, Escarcha y Lumbre)
const Extra := preload("res://equipo_extra.gd")       # accesorios y armas especiales de T-092 (C1)

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
	# Zarzalín (T-097, bestiario 01; escena y clips de animaciones: enemigos/zarzalin/). Encuadre ×1,25 (propuesta de
	# animaciones): 1,5 m de alto de vista mirando a 0,48 m; su centro (números y efectos) a 0,5 m, no a 0,85.
	"zarzalin": {
		"tipo": "3d", "esc": 0.6, "script": "res://enemigos/zarzalin/zarzalin_3d.gd", "gestos": "res://gestos_3d.gd",
		"rutas": ["res://enemigos/zarzalin/zarzalin_completo.glb"], "vp": Vector2i(1175, 525), "alto_vista": 1.5,
		"centro_y": 0.48, "barra_y": 40.0, "centro_3d": 0.5, "respaldo": "slime"},
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
	# Guardián del Bosque Olvidado (fase 3): respaldo 2D, el guardián de piedra grande y teñido de verde musgo, hasta tener su
	# modelo 3D (enemigos/guardian_bosque/).
	# Guardián del Bosque Olvidado (fase 3): modelo 3D propio (animaciones, Blender; enemigos/guardian_bosque/), con el 2D de respaldo.
	"guardian_bosque": {
		"tipo": "3d", "esc": 0.6, "script": "res://enemigos/guardian_bosque/guardian_bosque_3d.gd",
		"gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/guardian_bosque/guardian_bosque.glb"],
		"vp": Vector2i(1000, 1120), "alto_vista": 4.6, "centro_y": 1.95, "barra_y": 50.0, "centro_3d": 1.9,
		"respaldo": "guardian_bosque2d"},
	"guardian_bosque2d": {"tipo": "imagen", "imagen": "res://enemigos/guardian.png", "cadera": Vector2(160, 470), "tam": 1.45,
		"barra_y": -230.0, "centro_y": 60.0, "tinte": Color(0.62, 0.92, 0.58)},
	# Coloso de la Falla (V9, jefe 2; combate_coloso.gd). Su modelo 3D lo prepara animaciones (enemigos/coloso_falla/, con
	# la interfaz de guardian_bosque_3d.gd: despertar, cargar, atacar, ataque, fase2): la entrada 3D queda lista pero sin
	# usar (ENEMIGOS lleva el respaldo; combate_coloso.gd, MODELO_3D, dice cómo activarla). El encuadre es el del
	# Guardián del Bosque y habrá que ajustarlo con el modelo. Si se activa sin el GLB, se usa el respaldo 2D.
	"coloso_falla": {
		"tipo": "3d", "esc": 0.64, "script": "res://enemigos/coloso_falla/coloso_falla_3d.gd",
		"gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/coloso_falla/coloso_falla.glb"],
		"vp": Vector2i(1260, 1360), "alto_vista": 6.2, "centro_y": 2.3, "barra_y": 150.0, "centro_3d": 2.7,   # encuadre de animaciones (V9)
		"respaldo": "coloso_falla2d"},
	# Respaldo 2D: el guardián de piedra, grande (más alto que dos héroes) y teñido de gris cálido (la imagen es verdosa).
	# Con GRUPOS[12] en y = 90, los pies caen a unos 470 px de pantalla y la cabeza a unos 75: su vida y sus estados
	# (Piel de piedra, Expuesto…) se leen encima, dentro de la pantalla (capturas de pruebas/fotos_coloso.gd).
	"coloso_falla2d": {"tipo": "imagen", "imagen": "res://enemigos/guardian.png", "cadera": Vector2(160, 470), "tam": 1.45,
		"barra_y": -197.0, "centro_y": 90.0, "tinte": Color(1.05, 0.86, 0.8)},
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
	# Zarzalín: el enemigo inicial de Pastos Verdes. Enseña a Kael, cuando viaja solo, a leer un ataque cargado: avisa un
	# turno antes bajando el hocico, embiste (×1,8; Defender lo reduce a la mitad) y el turno siguiente recupera el
	# aliento. Si no, barre con el colmillo. Personalidad «embiste» (_turno_zarzalin).
	"zarzalin": {"nombre": "Zarzalín", "modelo": "zarzalin", "hp": 80, "atk": 11, "vel": 14.0, "exp": 20, "oro": 12,
		"personalidad": "embiste"},
	"golem_ambar": {"nombre": "Gólem de ámbar", "modelo": "guardian", "hp": 200, "atk": 17, "vel": 9.0, "exp": 70, "oro": 90, "personalidad": "bruto"},
	# Fase 3, «El bosque que no recuerda»: el jefe de Pastos Verdes (combate_bosque.gd). Dos fases (al 50 %: coraza de raíces y
	# débil al fuego), ataque cargado con aviso; se purifica con el Elixir o se derrota.
	"guardian_bosque": {"nombre": "Guardián del Bosque Olvidado", "modelo": "guardian_bosque", "hp": 420, "atk": 17, "vel": 9.0,
		"exp": 90, "oro": 0, "personalidad": "bosque", "fases": true, "titulo": true},
	# V9, jefe 2: el Coloso de la Falla, jefe opcional de la Garganta 3D (combate_coloso.gd). Lento y duro: piel de piedra
	# (golpes a la mitad) salvo en la ventana tras su golpe cargado; al 50 %, las runas (coraza rúnica alterna). Garon
	# puede leer sus inscripciones. «modelo»: «coloso_falla» cuando llegue su GLB (hoy, el respaldo 2D).
	"coloso_falla": {"nombre": "Coloso de la Falla", "modelo": "coloso_falla", "hp": 520, "atk": 21, "vel": 8.0,
		"exp": 80, "oro": 120, "personalidad": "coloso", "fases": true, "titulo": true},
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
	# para un grupo de uno o dos (versión experimental: Kael solo hasta PV-03, con Lya hasta PV-05)
	[["slime", Vector2(250, 120)]],                                         # 7
	[["slime", Vector2(140, 110)], ["slime", Vector2(380, 125)]],           # 8
	[["grimfang", Vector2(300, 130)]],                                      # 9
	[["zarzalin", Vector2(250, 120)]],                                      # 10: Zarzalín (Pastos Verdes)
	[["guardian_bosque", Vector2(150, -120)]],                               # 11: Guardián del Bosque (Pastos Verdes, fase 3)
	[["coloso_falla", Vector2(47, -256)]],                                    # 12: Coloso de la Falla (Garganta 3D, V9)
]
const GRUPOS_AL_AZAR := 5           # solo los primeros salen en encuentros aleatorios (con el grupo de tres)
# Encuentros al azar según cuántos héroes hay ahora en el grupo (grupo.gd, activos). Kael solo no tiene cura ni a
# nadie que le cubra: sus grupos se ganan solo con ataques (pruebas/prueba_grupos_combate.gd). Los combates fijos no
# cambian, y ninguno de estos enemigos aturde, duerme ni congela.
const AL_AZAR_POR_TAMANO := {1: [7, 8, 9, 10], 2: [1, 3, 8, 9, 10]}   # 10, Zarzalín (T-097): un randi() igual que antes


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
	"zarzalin": {"distancia": 150.0},
	"gorthor3d": {"distancia": 190.0},
	"hollin": {"distancia": 140.0},
	"gorthor": {"distancia": 170.0},
	"garon3d": {"distancia": 130.0},
	"guardian": {"distancia": 150.0},
	"guardian_bosque2d": {"distancia": 170.0},     # fase 3: el Guardián del Bosque (respaldo 2D)
	"guardian_bosque": {"distancia": 170.0},       # fase 3: ataca desde su sitio (_anim_guardian)
	"coloso_falla2d": {"distancia": 170.0},        # V9: el Coloso de la Falla (respaldo 2D)
	"coloso_falla": {"distancia": 170.0},          # V9: su modelo 3D, desde su sitio como el Guardián (_anim_guardian)
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
var ultimo_esquivado := false            # el último golpe físico lo esquivó un héroe (Pluma de arpía, T-092)


func _ready() -> void:
	var semilla := -1                              # pruebas: -- semilla=N (C0); en el juego, al azar como siempre
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semilla="):
			semilla = int(a.substr(8))
	if semilla >= 0:
		seed(semilla)
	else:
		randomize()
	# modo móvil: en Android (o probando con -- movil) los efectos son más ligeros
	movil = OS.has_feature("mobile") or "movil" in OS.get_cmdline_user_args()
	if movil:
		calidad = CALIDAD_MOVIL["particulas"]
		res_efectos = CALIDAD_MOVIL["res_efectos"]
		res_personajes = CALIDAD_MOVIL["res_personajes"]
		max_efectos_3d = CALIDAD_MOVIL["max_efectos_3d"]
	heroes = heroes.filter(func(h): return RESPALDO.has(h["modelo"]) or _ruta_3d(MODELOS[h["modelo"]]) != "")   # Garon sin modelo: no sale
	if ResourceLoader.exists("res://grupo.gd"):    # solo los que están ahora en el grupo (grupo.gd, activos)
		var en_grupo: Array = load("res://grupo.gd").activos()
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
			h["efectos"] = Extra.efectos_de(h["nombre"])           # accesorios (T-092); el equipo de hoy no da nada
			h["atb"] = Extra.atb_inicial(h["efectos"], ATB_MAX)     # Farol de peregrino; sin él, 0 como siempre
			_equipo_al_empezar(h)                                  # Lágrima, Brasa en frasco y Hoja sin Nombre
		_aliento_al_empezar()                                      # Rama del Árbol Milenario (sin ella, nada)
	_elegir_enemigos()
	_crear_texturas()
	_crear_interfaz()
	for e in enemigos:                               # los que tienen entrada (Zarzalín): llegan de un salto, con un
		var pe = _p3d(e)                             # fundido corto porque el clip empieza 0,85 m por detrás
		if pe != null and pe.has_method("entrada"):
			e["rig"].modulate.a = 0.0
			create_tween().tween_property(e["rig"], "modulate:a", 1.0, 0.15)
			_sonidos_bestia(e, pe)
			_sonar(str(e.get("clave", "")) + "_entrada")   # al empezar su clip de entrada (sonido.gd, tanda 4)
			pe.entrada()
	_iniciar_musica()
	_actualizar()
	_precalentar_efectos()
	for e in enemigos:                               # jefes: su nombre en grande al empezar
		if e.get("titulo", false):
			_presentar(e)


# Índice de un grupo al azar para un encuentro con «cuantos» héroes (los de tres, como siempre).
static func grupo_al_azar(cuantos: int) -> int:
	var tabla: Dictionary = AL_AZAR_POR_TAMANO
	if tabla.has(cuantos):
		var opciones: Array = tabla[cuantos]
		return opciones[randi() % opciones.size()]
	return randi() % GRUPOS_AL_AZAR


# Elige un grupo al azar (o el índice de Engine.get_meta("grupo_combate") si se ha fijado).
# Los repetidos se llaman "Slime A", "Slime B"...
func _elegir_enemigos() -> void:
	var grupo: Array = GRUPOS[grupo_al_azar(heroes.size())]
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
	# Nivel del encuentro (V9, combate_escalado.gd): se fija aquí, al empezar, con el nivel del grupo de ahora.
	var zona_enc: String = Engine.get_meta("zona", "llanura")
	var nivel_grupo_enc: int = load("res://progreso.gd").nivel_grupo()
	for g in grupo:
		var e: Dictionary = ENEMIGOS[g[0]].duplicate(true)
		Escalado.aplicar(e, zona_enc, nivel_grupo_enc, combate_fijo)   # en la base de la región, igual que ENEMIGOS
		e["hero"] = false
		e["clave"] = g[0]                              # qué enemigo es: su voz (sonido.gd, T-083)
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
	musica.bus = &"Musica"                           # buses y volúmenes: sonido.gd
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
	panel_obj = Control.new()                         # V11: la lista de objetivos a la derecha (encima de todo)
	panel_obj.position = PANEL_OBJ.position
	panel_obj.size = PANEL_OBJ.size
	panel_obj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_obj.visible = false
	capa.add_child(panel_obj)
	menu.marcado.connect(_al_marcar_orden)


# ---------------------------------------------------------------- V11: panel de objetivos (MEJORAS_COMBATE.md)
# Al elegir a quién (ATACAR, MAGIA, artes, objetos, curas), a la derecha sale la lista con el nombre de cada uno (los
# iguales ya llevan A, B…), sus PV, lo que se sabe de él (prepara un golpe, en guardia, aturdido, quemado, congelado) y
# los derrotados apagados. El apuntado lleva «▶» y marco dorado, igual que la flecha sobre él. Cada fila se toca (o se
# pasa el ratón) para apuntar y se suelta para confirmar; con teclado o mando, la selección de siempre la sigue. Con
# una magia o un arte que alcanza a todos, la lista marca a quién alcanza: al marcar la orden y mientras se lanza.
const PANEL_OBJ := Rect2(820, 214, 420, 316)
const FILA_OBJ := 52.0
var panel_obj: Control
var filas_obj: Array = []                          # [{"f": luchador, "nodo": Control, "ok": bool}]
var modo_panel := ""                               # "elegir" o "area"


func _mostrar_panel(candidatos: Array, modo: String) -> void:
	for n in panel_obj.get_children():
		n.queue_free()
	filas_obj = []
	modo_panel = modo
	var de_enemigos: bool = not candidatos.is_empty() and candidatos.all(func(f): return not f.get("hero", false))
	var lista: Array = enemigos if de_enemigos else candidatos
	var titulo := _etiqueta("LE ALCANZA" if modo == "area" else ("ENEMIGOS" if de_enemigos else "ALIADOS"), 18,
		menu.ORO, menu.f_nombre)
	titulo.position = Vector2(6, 0)
	panel_obj.add_child(titulo)
	var alto: float = minf(FILA_OBJ, (PANEL_OBJ.size.y - 30.0) / maxf(1.0, lista.size()) - 4.0)
	for i in lista.size():
		var f: Dictionary = lista[i]
		var ok: bool = f["hp"] > 0 and candidatos.any(func(c): return is_same(c, f))
		if f.get("hero", false):
			ok = candidatos.any(func(c): return is_same(c, f))      # (revivir: un aliado caído también vale)
		var fila := Control.new()
		fila.position = Vector2(0, 30 + i * (alto + 4.0))
		fila.size = Vector2(PANEL_OBJ.size.x, alto)
		fila.mouse_filter = Control.MOUSE_FILTER_STOP if ok and modo == "elegir" else Control.MOUSE_FILTER_IGNORE
		fila.clip_contents = true
		panel_obj.add_child(fila)
		var fondo := ColorRect.new()
		fondo.name = "fondo"
		fondo.size = fila.size
		fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(fondo)
		var borde := ColorRect.new()
		borde.name = "borde"
		borde.size = Vector2(4, alto)
		borde.color = menu.ORO
		borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(borde)
		var nombre := _etiqueta(f["nombre"], 24 if alto >= 44.0 else 20, menu.COLOR_HEROE.get(f["nombre"], menu.LUZ_CLARA),
			menu.f_nombre)
		nombre.name = "nombre"
		nombre.position = Vector2(14, 2)
		fila.add_child(nombre)
		var info := _etiqueta(_info_objetivo(f, ok), 16, Color(menu.LUZ_CLARA, 0.85), null)
		info.position = Vector2(14, alto - 22.0)
		info.size = Vector2(PANEL_OBJ.size.x - 20.0, 20)
		fila.add_child(info)
		var vida := ColorRect.new()                  # sus PV, en una raya fina a la derecha
		vida.position = Vector2(PANEL_OBJ.size.x - 120.0, 14)
		vida.size = Vector2(110.0 * clampf(float(f["hp"]) / maxf(1.0, f["hp_max"]), 0.0, 1.0), 4)
		vida.color = Color(0.55, 0.9, 0.55) if f.get("hero", false) else Color(1.0, 0.45, 0.3)
		vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(vida)
		if not ok:
			fila.modulate = Color(1, 1, 1, 0.38)
		elif modo == "elegir":
			var quien = f
			fila.gui_input.connect(func(ev: InputEvent): _toque_fila_obj(ev, quien, fila))
			fila.mouse_entered.connect(func():
				if estado == "objetivo":
					_apuntar(quien))
		filas_obj.append({"f": f, "nodo": fila, "ok": ok})
	panel_obj.visible = true
	_pintar_panel()


func _info_objetivo(f: Dictionary, ok: bool) -> String:
	if f["hp"] <= 0 and not f.get("hero", false):
		return "Derrotado"
	var t: Array = ["PV %d/%d" % [f["hp"], f["hp_max"]]]
	if f.get("cargando", false):
		var plan: Dictionary = PATRONES.get(f.get("personalidad", ""), {})
		if plan.get("encoge", false):
			t.append("⚠ Encogido: la magia rompe su guardia")
		elif not plan.is_empty():
			t.append("⚠ Prepara un golpe: dale fuerte y lo cortas")
		else:
			t.append("⚠ Prepara un golpe")
	if f.get("aturdido", false):
		t.append("Aturdido")
	elif f.get("defendiendo", false) and not f.get("hero", false):
		t.append("En guardia")
	if int(f.get("quemadura", 0)) > 0:
		t.append("Quemado")
	if int(f.get("congelado", 0)) > 0:
		t.append("Congelado")
	if f.get("hero", false) and f["hp"] <= 0:
		t.append("Caído")
	if not ok and f["hp"] > 0:
		t.append("No disponible")
	return " · ".join(t)


func _pintar_panel() -> void:
	for r in filas_obj:
		var marcado: bool = r["ok"] and (modo_panel == "area" or (objetivo_apuntado != null and is_same(r["f"], objetivo_apuntado)))
		var nodo: Control = r["nodo"]
		if not is_instance_valid(nodo):
			continue
		(nodo.get_node("fondo") as ColorRect).color = Color(0.16, 0.13, 0.08, 0.82) if marcado else Color(0.04, 0.05, 0.09, 0.62)
		nodo.get_node("borde").visible = marcado
		var n: Label = nodo.get_node("nombre")
		var base: String = r["f"]["nombre"]
		n.text = ("▶ " if marcado and modo_panel == "elegir" else ("◆ " if marcado else "")) + base


func _toque_fila_obj(ev: InputEvent, f: Dictionary, fila: Control) -> void:
	if estado != "objetivo" or not (ev is InputEventMouseButton) or ev.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	if ev.pressed:
		_apuntar(f)
	elif Rect2(Vector2.ZERO, fila.size).has_point(ev.position):
		_confirmar_objetivo(f)


func _ocultar_panel() -> void:
	if panel_obj != null:
		panel_obj.visible = false
	filas_obj = []
	modo_panel = ""
	_quitar_flechas_area()


# El menú avisa de la orden marcada: si alcanza a todos los enemigos, una flecha dorada sobre cada uno (la lista no:
# taparía el submenú de las magias); si no, se quitan.
var flechas_area: Array = []


func _al_marcar_orden(item: Dictionary) -> void:
	_quitar_flechas_area()
	if estado == "objetivo" or not item.get("area_enemigos", false) or item.get("apagado", false):
		return
	for e in enemigos.filter(func(x): return x["hp"] > 0):
		var fl := Control.new()
		fl.size = flecha.size
		fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fl.position = _pos_flecha(e)
		fl.draw.connect(func():
			var pts := PackedVector2Array([Vector2(0, 0), Vector2(36, 0), Vector2(18, 28)])
			fl.draw_colored_polygon(pts, Color(menu.ORO, 0.85))
			pts.append(pts[0])
			fl.draw_polyline(pts, Color(menu.SOMBRA, 0.8), 2.0))
		capa.add_child(fl)
		flechas_area.append(fl)


func _quitar_flechas_area() -> void:
	for fl in flechas_area:
		if is_instance_valid(fl):
			fl.queue_free()
	flechas_area = []


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
	f["centro_ofs"] = cam.unproject_position(Vector3(0, m.get("centro_3d", 0.85), 0)) / q * esc
	if f.get("hero", false) and ResourceLoader.exists("res://inventario.gd"):   # C2: el arma especial, con su color
		var arma: Dictionary = load("res://inventario.gd").arma_de(f["nombre"])
		for k in ["espada", "espada_izq"]:           # (las de Kael y Lya ya salen teñidas: material_arma.de_arma)
			if k in maga and maga.get(k) != null:
				load("res://material_arma.gd").tenir(maga.get(k), arma)


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
	Sonido.voz(o, "ataque")                          # su voz al alzar el arma (sonido.gd, T-083)
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
		_quitar_guardia(f["nombre"])             # la guardia de Garon, también (sin guardia, nada)
		_tic_estados_heroe(f)                    # Segundo Aliento y Cinta de Lumi (sin ellos, nada)
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
var atacante_actual = null                       # el enemigo que actúa (lo congela el Invierno Guardián al romperlo)


func _turno_enemigo(f: Dictionary) -> void:
	atacante_actual = f
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
	if p != "jefe" and p != "bosque" and p != "coloso" and limpia and randf() < 0.7:   # (los jefes no huyen)
		await _huir(f)
		_fin_turno_enemigo(f)
		return
	if p == "cobarde" and aliados.size() == 1 and f["hp"] < f["hp_max"] * 0.6 and randf() < 0.5:
		await _huir(f)
		_fin_turno_enemigo(f)
		return
	if p == "embiste":                               # Zarzalín: aviso, embestida y recuperación (T-097)
		await _turno_zarzalin(f, vivos, mult)
		_fin_turno_enemigo(f)
		return
	if p == "bosque":                                # el Guardián del Bosque Olvidado (fase 3)
		await _turno_guardian(f, vivos, mult)
		_fin_turno_enemigo(f)
		return
	if p == "coloso":                                # el Coloso de la Falla (V9, jefe 2)
		await _turno_coloso(f, vivos, mult)
		_fin_turno_enemigo(f)
		return
	if PATRONES.has(p):                              # Grimfang, el Slime y el Gólem: su ataque anunciado (T-097)
		if await _turno_patron(f, vivos, mult, PATRONES[p]):
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
		var presa := _cubre(_elegir_objetivo("cobarde", vivos))
		var mordisco: int = int(f["atk"] * 1.6 * mult) + randi_range(-2, 3)
		registro.text = "¡%s devora a %s!" % [f["nombre"], presa["nombre"]]
		f["devora"] = true                           # su mordisco suena al morder (sonido.gd, T-083)
		f["absorbido"] = 0
		await _animar_golpe(f, presa, mordisco, "")
		f["devora"] = false
		# se cura con lo que de verdad mordió: lo que paró la coraza de Escarcha no cuenta (sin coraza, igual que siempre)
		var cura: int = _cura_devorar(f, mordisco)
		if cura > 0 and f["hp"] > 0 and not ultimo_esquivado:   # si la presa lo esquiva (pluma), no se cura
			f["hp"] += cura
			_numero_flotante(f, "+%d" % cura, C_CURA)
			_actualizar()
		_fin_turno_enemigo(f)
		return
	# el jefe carga su golpe más fuerte (un turno de aviso); en la segunda fase, más a menudo
	if p == "jefe" and not f.get("cargando", false) and randf() < (0.45 if f.get("fase2", false) else 0.35):
		f["cargando"] = true
		_marcar_aviso(f, true)                       # la señal de aviso sobre él, hasta que golpee (se lee sin partículas)
		Sonido.efecto("carga_jefe")                 # sonido.gd
		registro.text = "¡%s se prepara para un golpe devastador!" % f["nombre"]
		_numero_flotante(f, "⚠ ¡Cuidado!", Color(1.0, 0.8, 0.2), 34)
		_particulas(_centro(f) + Vector2(0, 100), Color(1.0, 0.7, 0.2, 0.9), Color(1.0, 0.3, 0.0, 0.0), 40, 1.0,
			Vector2(40, 120), 90.0, Vector2(0, -1), 20.0, Vector2(0, -60), 0.1)
		_actualizar()
		await get_tree().create_timer(1.2).timeout
		_fin_turno_enemigo(f)
		return
	var objetivo = _cubre(_elegir_objetivo(p, vivos))   # (si Garon le cubre, va a Garon)
	if f.get("cargando", false):                # descarga: golpe fuerte a todo el grupo
		f["cargando"] = false
		_marcar_aviso(f, false)
		registro.text = "¡%s desata su golpe devastador!" % f["nombre"]
		var fuerte := int(f["atk"] * 2.2 * mult)
		f["descarga"] = true                         # Grimfang / Gorthor: golpe fuerte a dos manos
		await _animar_golpe(f, objetivo, fuerte, "")
		f["descarga"] = false
		for h0 in vivos:
			if h0 != objetivo and h0["hp"] > 0:
				var h: Dictionary = _cubre(h0, false)  # el golpe a quien Garon cubre lo recibe Garon (otro impacto más)
				if h["hp"] <= 0:
					continue
				var d2: int = maxi(1, fuerte - int(h.get("def", 0) / 2.0))
				if h.get("defendiendo", false) and not is_same(h, h0):
					d2 = maxi(1, int(d2 * 0.5))         # Garon en guardia: a la mitad, como al defender
				d2 = _quitar_pv(h, d2)                 # (con coraza, lo que llega a los PV)
				_golpe_visual(h, d2, "")
		Sonido.golpe(true)                           # la onda del golpe alcanza a los demás (sonido.gd)
		_temblor(14.0)
	else:
		var dano: int = int(f["atk"] * mult) + randi_range(-2, 3)
		registro.text = "%s ataca a %s" % [f["nombre"], objetivo["nombre"]]
		await _animar_golpe(f, objetivo, dano, "")
	_fin_turno_enemigo(f)


# El Guardián del Bosque Olvidado (fase 3, combate_bosque.gd). Fase 1, «El despertar de las raíces»: latigazo de raíz
# (a uno), esporas (a todos, flojas) y Raíces que aprisionan (aviso un turno antes, ×2 a uno; Defender lo reduce a la
# mitad). Fase 2, «El corazón del bosque» (al 50 %, _cambio_fase): carga más a menudo el Juicio del bosque (×1,6 a
# todos) y lleva la coraza de raíces (combate_bosque.dano_recibido). Con su modelo 3D, sus clips de carga y descarga.
func _turno_guardian(f: Dictionary, vivos: Array, mult: float) -> void:
	var fase2: bool = f.get("fase2", false)
	var modelo = _p3d(f)
	if f.get("cargando", false):
		f["cargando"] = false
		_marcar_aviso(f, false)
		f["descarga"] = true
		f["ataque_3d"] = "golpe_fuerte"              # su modelo 3D: las raíces que brotan (_anim_guardian)
		if fase2:
			registro.text = "¡%s desata el Juicio del bosque!" % f["nombre"]
			var dano := int(f["atk"] * 1.6 * mult)
			var principal: Dictionary = _cubre(_elegir_objetivo("bruto", vivos))
			await _animar_golpe(f, principal, dano + randi_range(-2, 3), "")
			for h0 in vivos:
				if h0 == principal or h0["hp"] <= 0:
					continue
				var h: Dictionary = _cubre(h0, false)
				if h["hp"] <= 0:
					continue
				var d2: int = maxi(1, dano - int(h.get("def", 0) / 2.0))
				if h.get("defendiendo", false):
					d2 = maxi(1, int(d2 * 0.5))
				_golpe_visual(h, _quitar_pv(h, d2), "")
			Sonido.golpe(true)
			_temblor(14.0)
		else:
			var obj = f.get("objetivo_carga", null)
			if obj == null or obj["hp"] <= 0:
				obj = _elegir_objetivo("agresivo", vivos)
			obj = _cubre(obj)
			registro.text = "¡Las raíces aprisionan a %s!" % obj["nombre"]
			await _animar_golpe(f, obj, int(f["atk"] * 2.0 * mult) + randi_range(-2, 3), "")
			_temblor(10.0)
		f["descarga"] = false
		f.erase("objetivo_carga")
		f.erase("ataque_3d")
		return
	var r := randf()
	if r < (0.4 if fase2 else 0.3):                  # carga su golpe: un turno de aviso
		var obj := _elegir_objetivo("agresivo", vivos)
		f["cargando"] = true
		f["objetivo_carga"] = obj
		_marcar_aviso(f, true)
		if modelo != null and modelo.has_method("cargar"):
			modelo.cargar("golpe_fuerte")
		Sonido.efecto("guardian_bosque_carga")      # V9: su latido grave, en lugar de «carga_jefe» (sonido.gd)
		if fase2:
			registro.text = "%s hunde sus raíces en la tierra: ¡va a golpear a todos!" % f["nombre"]
			_numero_flotante(f, "⚠ ¡Juicio del bosque!", Color(1.0, 0.8, 0.2), 32)
		else:
			registro.text = "%s tensa sus raíces: ¡va a por %s!" % [f["nombre"], obj["nombre"]]
			_numero_flotante(f, "⚠ ¡Raíces!", Color(1.0, 0.8, 0.2), 32)
		_particulas(_centro(f) + Vector2(0, 100), Color(0.55, 1.0, 0.45, 0.9), Color(0.2, 0.6, 0.1, 0.0), 30, 1.0,
			Vector2(30, 100), 80.0, Vector2(0, -1), 20.0, Vector2(0, -50), 0.1)
		_actualizar()
		await get_tree().create_timer(1.0).timeout
		return
	if r < (0.65 if fase2 else 0.6):                 # esporas: magia del bosque, flojas, a todos
		registro.text = "%s esparce esporas" % f["nombre"]
		if modelo != null and modelo.has_method("ataque"):
			modelo.ataque()                           # sacude sus ramas
		_voz(f, "ataque")
		var d := maxi(1, int(f["atk"] * 0.55 * mult))
		for h in vivos:
			if h["hp"] <= 0:
				continue
			var dh: int = d + randi_range(-1, 2)
			if h.get("defendiendo", false):
				dh = maxi(1, int(dh * 0.5))
			_particulas(_centro(h) + Vector2(0, 40), Color(0.75, 0.9, 0.5, 0.8), Color(0.4, 0.6, 0.2, 0.0), 14, 0.9,
				Vector2(20, 60), 60.0, Vector2(0, -1), 40.0, Vector2(0, 20), 0.12)
			_golpe_visual(h, _quitar_pv(h, maxi(1, dh)), "")
		_actualizar()
		await get_tree().create_timer(0.9).timeout
		return
	var objetivo: Dictionary = _cubre(_elegir_objetivo("agresivo", vivos))   # latigazo de raíz
	registro.text = "%s azota a %s con una raíz" % [f["nombre"], objetivo["nombre"]]
	await _animar_golpe(f, objetivo, int(f["atk"] * mult) + randi_range(-2, 3), "")


# El Coloso de la Falla (V9, jefe 2; las reglas y su porqué, en combate_coloso.gd). Fase 1, «La piedra que vigila»:
# puñetazo (a uno, ×1,25), lluvia de rocas (a todos, floja, ×0,5) y el Puño de la Falla (aviso un turno antes, ×2 a
# uno). Fase 2, «Las runas despiertan»: carga más a menudo el Derrumbe rúnico (×1,6 a todos). Tras descargar queda
# EXPUESTO hasta su turno siguiente, en el que se recompone sin atacar. Cada golpe se resuelve una vez, en el impacto de
# su animación (el respaldo 2D, la de imagen; su modelo 3D, _anim_guardian). Al acabar su turno, la lectura de Garon se
# gasta y, en la fase 2, cambia de defensa (combate_coloso.fin_turno), con su aviso.
const COLOR_RUNAS := Color(1.0, 0.7, 0.28)          # ámbar de las runas (fase 2, coraza rúnica y Leer runas)
const COLOR_VENTANA := Color(1.0, 0.42, 0.22)       # los puntos débiles, en la ventana
const TINTE_CORAZA := Color(1.4, 0.95, 0.55)        # el respaldo 2D con la coraza rúnica puesta (ámbar dorado)
const TINTE_PIEL := Color(1.15, 0.86, 0.68)         # el respaldo 2D en la fase 2, con la piel de piedra (gris cálido)


func _turno_coloso(f: Dictionary, vivos: Array, mult: float) -> void:
	await _accion_coloso(f, vivos, mult)
	if f["hp"] > 0:
		_avisos_coloso(f, Coloso.fin_turno(f))


func _accion_coloso(f: Dictionary, vivos: Array, mult: float) -> void:
	var fase2: bool = f.get("fase2", false)
	var modelo = _p3d(f)
	if f.get("expuesto", false):                     # se recompone: la ventana se cierra
		f["expuesto"] = false
		_marcar_puntos(f, false)
		registro.text = "%s recompone sus placas de piedra" % f["nombre"]
		_numero_flotante(f, "Se recompone", Color(0.82, 0.8, 0.72), 28)
		_actualizar()
		await get_tree().create_timer(0.8).timeout
		return
	if f.get("cargando", false):
		f["cargando"] = false
		_marcar_aviso(f, false)
		f["descarga"] = true
		f["ataque_3d"] = "golpe_fuerte"              # su modelo 3D (cuando llegue): el golpe fuerte (_anim_guardian)
		if fase2:
			registro.text = "¡%s desata el Derrumbe rúnico!" % f["nombre"]
			var dano := int(f["atk"] * 1.6 * mult)
			var principal: Dictionary = _cubre(_elegir_objetivo("bruto", vivos))
			await _animar_golpe(f, principal, dano + randi_range(-2, 3), "")
			for h0 in vivos:
				if h0 == principal or h0["hp"] <= 0:
					continue
				var h: Dictionary = _cubre(h0, false)
				if h["hp"] <= 0:
					continue
				var d2: int = maxi(1, dano - int(h.get("def", 0) / 2.0))
				if h.get("defendiendo", false):
					d2 = maxi(1, int(d2 * 0.5))
				_golpe_visual(h, _quitar_pv(h, d2), "")
			Sonido.golpe(true)                       # la onda del derrumbe alcanza a los demás, una vez
			_temblor(14.0)
		else:
			var obj = f.get("objetivo_carga", null)
			if obj == null or obj["hp"] <= 0:
				obj = _elegir_objetivo("agresivo", vivos)
			obj = _cubre(obj)
			registro.text = "¡El Puño de la Falla cae sobre %s!" % obj["nombre"]
			await _animar_golpe(f, obj, int(f["atk"] * 2.0 * mult) + randi_range(-2, 3), "")
			_temblor(10.0)
		f["descarga"] = false
		f.erase("objetivo_carga")
		f.erase("ataque_3d")
		if f["hp"] > 0:                              # la ventana: queda expuesto hasta su turno siguiente
			f["expuesto"] = true
			_marcar_puntos(f, true)
			registro.text = "¡%s queda expuesto: sus puntos débiles brillan!" % f["nombre"]
			_numero_flotante(f, "¡Puntos débiles!", COLOR_VENTANA, 34)
			_sonar("coloso_expuesto")                # una vez, al abrirse la ventana (si sonido.gd lo tiene)
			_actualizar()
			await get_tree().create_timer(0.6).timeout
		return
	var r := randf()
	if r < (0.4 if fase2 else 0.3):                  # carga su golpe: un turno de aviso
		var obj := _elegir_objetivo("agresivo", vivos)
		f["cargando"] = true
		f["objetivo_carga"] = obj
		_marcar_aviso(f, true)
		if modelo != null and modelo.has_method("cargar"):
			modelo.cargar("golpe_fuerte")
		Sonido.efecto("carga_jefe")                 # sonido.gd
		if fase2:
			registro.text = "Las runas de %s arden: ¡va a golpear a todos!" % f["nombre"]
			_numero_flotante(f, "⚠ ¡Derrumbe rúnico!", Color(1.0, 0.8, 0.2), 32)
		else:
			registro.text = "%s alza el puño: ¡va a por %s!" % [f["nombre"], obj["nombre"]]
			_numero_flotante(f, "⚠ ¡Puño de la Falla!", Color(1.0, 0.8, 0.2), 32)
		_particulas(_centro(f) + Vector2(0, 100), Color(0.85, 0.78, 0.66, 0.9), Color(0.5, 0.45, 0.4, 0.0), 30, 1.0,
			Vector2(30, 100), 80.0, Vector2(0, -1), 20.0, Vector2(0, -50), 0.1)
		_actualizar()
		await get_tree().create_timer(1.0).timeout
		return
	if r < 0.6:                                      # lluvia de rocas: a todos, floja
		registro.text = "%s hace caer rocas sobre el grupo" % f["nombre"]
		if modelo != null and modelo.has_method("ataque"):
			modelo.ataque()
		_voz(f, "ataque")
		_temblor(8.0)
		var d := maxi(1, int(f["atk"] * 0.5 * mult))
		for h in vivos:
			if h["hp"] <= 0:
				continue
			var dh: int = d + randi_range(-1, 2)
			if h.get("defendiendo", false):
				dh = maxi(1, int(dh * 0.5))
			_particulas(_centro(h) + Vector2(0, -90), Color(0.7, 0.66, 0.6, 0.95), Color(0.4, 0.37, 0.33, 0.0), 12, 0.7,
				Vector2(60, 160), 60.0, Vector2(0, 1), 25.0, Vector2(0, 500), 0.14)
			_golpe_visual(h, _quitar_pv(h, maxi(1, dh)), "")
		Sonido.golpe()                               # las rocas caen: un golpe, una vez para todos
		_actualizar()
		await get_tree().create_timer(0.9).timeout
		return
	var objetivo: Dictionary = _cubre(_elegir_objetivo("agresivo", vivos))   # puñetazo
	registro.text = "%s descarga un puñetazo sobre %s" % [f["nombre"], objetivo["nombre"]]
	await _animar_golpe(f, objetivo, int(f["atk"] * 1.25 * mult) + randi_range(-2, 3), "")


# Avisa lo que ha cambiado al acabar su turno (combate_coloso.fin_turno): la lectura de Garon que se acaba y, en la fase 2,
# la defensa nueva (y el respaldo 2D cambia de tono con ella).
func _avisos_coloso(f: Dictionary, cambios: Array) -> void:
	var img = f["partes"].get("imagen", f["partes"].get("sprite"))
	for c in cambios:
		match c:
			"lectura_fin":
				_numero_flotante(f, "Las runas se cierran", Color(0.82, 0.78, 0.7), 26, Vector2(0, 90))
			"coraza":
				_numero_flotante(f, "Coraza rúnica: la magia hace la mitad", COLOR_RUNAS, 26, Vector2(0, 50))
				_sonar("coloso_coraza")
				if img != null and _p3d(f) == null:
					create_tween().tween_property(img, "modulate", TINTE_CORAZA, 0.5)
			"piel":
				_numero_flotante(f, "Piel de piedra: los golpes hacen la mitad", Color(0.85, 0.82, 0.76), 26, Vector2(0, 50))
				_sonar("coloso_piel")
				if img != null and _p3d(f) == null:
					create_tween().tween_property(img, "modulate", TINTE_PIEL, 0.5)
	_actualizar()


# Los puntos débiles del Coloso en la ventana: tres brillos que laten sobre sus juntas, sin partículas (se leen igual en
# el perfil bajo), hasta que se recompone o cae. Con «si» = false, fuera.
func _marcar_puntos(f: Dictionary, si: bool) -> void:
	var antes = f.get("puntos_nodo", null)
	if antes != null and is_instance_valid(antes):
		antes.queue_free()
	f.erase("puntos_nodo")
	if not si or not f.has("rig"):
		return
	var n := Node2D.new()
	n.position = _centro(f)
	n.z_index = 6
	escena.add_child(n)
	for ofs in [Vector2(-34, -70), Vector2(30, -10), Vector2(-12, 60)]:
		var b := _brillo(COLOR_VENTANA)
		b.position = ofs
		b.scale = Vector2.ONE * 0.5
		n.add_child(b)
		var t := b.create_tween().set_loops()
		t.tween_property(b, "scale", Vector2.ONE * 0.8, 0.45).set_trans(Tween.TRANS_SINE)
		t.tween_property(b, "scale", Vector2.ONE * 0.45, 0.45).set_trans(Tween.TRANS_SINE)
	f["puntos_nodo"] = n


func _coloso_vivo() -> Dictionary:
	for e in enemigos:
		if Coloso.es_coloso(e) and e["hp"] > 0:
			return e
	return {}


# Patrones de los enemigos de siempre (T-097, tanda del 09/11): como Zarzalín, cada uno avisa un turno antes de su
# golpe fuerte y, tras darlo, recupera el aliento un turno. El aviso se lee de cuatro maneras: el cartel («Grimfang alza
# el hacha: ¡va a por Kael!»), el texto sobre él, «⚠ Cargando» sobre su vida y una señal dibujada encima (sin
# partículas: igual en el perfil bajo). Con las animaciones y los sonidos que ya tienen (el golpe a dos manos de
# Grimfang, su voz de ataque...). Defender lo reduce a la mitad y la Guardia de Garon lo para.
#   agresivo (Grimfang, también con el dibujo del Hollín y en el centinela): Hachazo a uno, ×1,6.
#   cobarde (Slime): se encoge (recibe la mitad hasta su turno) y después rebota contra uno, ×1,3.
#   bruto (Gólem de ámbar): Pisotón a todo el grupo, ×1,0.
# Los jefes (Guardián, Gorthor) ya avisaban su golpe devastador; ahora también llevan la señal dibujada.
const PATRONES := {
	"agresivo": {"prob": 0.3, "a": "uno", "mult": 1.6, "prepara": "alza el hacha", "aviso": "⚠ ¡Hachazo!",
		"golpe": "¡%s descarga el hachazo sobre %s!"},
	"cobarde": {"prob": 0.3, "a": "uno", "mult": 1.3, "prepara": "se encoge", "aviso": "⚠ ¡Rebote!",
		"golpe": "¡%s rebota contra %s!", "encoge": true},
	"bruto": {"prob": 0.3, "a": "todos", "mult": 1.0, "prepara": "levanta los puños", "aviso": "⚠ ¡Pisotón!",
		"golpe": "¡%s da un pisotón que alcanza a todos!"},
}
# V11, interrupción (MEJORAS_COMBATE.md): mientras uno de estos prepara su golpe, si el grupo le quita de una vez o en
# varias al menos esta parte de su vida máxima, el golpe se corta y pierde su turno siguiente (aturdido). Al Slime
# encogido (en guardia) los golpes físicos le hacen la mitad, pero la magia le rompe la guardia. Así, ante un aviso hay
# dos respuestas: defenderse o cargar contra él. Los jefes (Guardián, Coloso, Gorthor) siguen con lo suyo.
const UMBRAL_INTERRUPCION := 0.25
var golpe_magico := false                         # lo pone quien resuelve un golpe de magia, para _vigilar_carga


func _vigilar_carga(f: Dictionary, d: int) -> void:
	if not f.get("cargando", false) or f["hp"] <= 0 or not PATRONES.has(f.get("personalidad", "")):
		return
	var plan: Dictionary = PATRONES[f["personalidad"]]
	if golpe_ruptura:                                 # Quiebra (Kael + Garon): corta siempre
		_interrumpir(f, "¡Quiebra!", "¡Kael y Garon rompen la carga de %s!" % f["nombre"])
		return
	if plan.get("encoge", false) and golpe_magico:
		_interrumpir(f, "¡Guardia rota!", "¡La magia rompe la guardia de %s!" % f["nombre"])
		return
	f["carga_recibido"] = int(f.get("carga_recibido", 0)) + d
	if f["carga_recibido"] >= ceili(f["hp_max"] * UMBRAL_INTERRUPCION):
		_interrumpir(f, "¡Interrumpido!", "¡%s pierde el equilibrio y no suelta el golpe!" % f["nombre"])


func _interrumpir(f: Dictionary, cartel: String, texto: String) -> void:
	f["cargando"] = false
	f["recupera"] = true                              # su turno siguiente lo pasa aturdido
	f["aturdido"] = true
	f.erase("objetivo_carga")
	f.erase("carga_recibido")
	_marcar_aviso(f, false)
	if PATRONES[f["personalidad"]].get("encoge", false):
		f["defendiendo"] = false
		if f.has("rig") and is_instance_valid(f["rig"]):
			create_tween().tween_property(f["rig"], "scale", f.get("escala_rig", Vector2.ONE), 0.15)
	_sonar(Artes.SONIDO_ESTADO["rota"])
	_numero_flotante(f, cartel, Color(1.0, 0.92, 0.45), 36, Vector2(0, -60))
	registro.text = texto
	_temblor(4.0)
	_actualizar()


# Devuelve true si este turno ha sido del patrón (avisar, golpear o recuperarse); false, el turno de siempre.
func _turno_patron(f: Dictionary, vivos: Array, mult: float, plan: Dictionary) -> bool:
	if f.get("recupera", false):
		f["recupera"] = false
		registro.text = ("%s, aturdido, recupera el aliento" if f.get("aturdido", false) else "%s recupera el aliento") % f["nombre"]
		f.erase("aturdido")
		_numero_flotante(f, "Recupera", Color(0.8, 0.85, 0.75), 28)
		await get_tree().create_timer(0.8).timeout
		return true
	if f.get("cargando", false):
		f["cargando"] = false
		f["recupera"] = true
		_marcar_aviso(f, false)
		if plan.get("encoge", false):                # deja de estar encogido
			f["defendiendo"] = false
			create_tween().tween_property(f["rig"], "scale", f.get("escala_rig", Vector2.ONE), 0.15)
		var dano := int(f["atk"] * float(plan["mult"]) * mult)
		f["descarga"] = true                         # Grimfang: el golpe a dos manos
		if plan["a"] == "todos":
			registro.text = plan["golpe"] % f["nombre"]
			var principal: Dictionary = _cubre(_elegir_objetivo("bruto", vivos))
			await _animar_golpe(f, principal, dano + randi_range(-2, 3), "")
			for h0 in vivos:
				if h0 == principal or h0["hp"] <= 0:
					continue
				var h: Dictionary = _cubre(h0, false)
				if h["hp"] <= 0:
					continue
				var d2: int = maxi(1, dano - int(h.get("def", 0) / 2.0))
				if h.get("defendiendo", false):
					d2 = maxi(1, int(d2 * 0.5))
				_golpe_visual(h, _quitar_pv(h, d2), "")
			Sonido.golpe(true)
			_temblor(10.0)
		else:
			var objetivo = f.get("objetivo_carga", null)
			if objetivo == null or objetivo["hp"] <= 0:
				objetivo = _elegir_objetivo("agresivo", vivos)
			objetivo = _cubre(objetivo)
			registro.text = plan["golpe"] % [f["nombre"], objetivo["nombre"]]
			await _animar_golpe(f, objetivo, dano + randi_range(-2, 3), "")
		f["descarga"] = false
		f.erase("objetivo_carga")
		return true
	if randf() >= float(plan["prob"]):
		return false
	var obj := _elegir_objetivo("agresivo", vivos)
	f["cargando"] = true
	f["carga_recibido"] = 0
	f["objetivo_carga"] = obj
	_marcar_aviso(f, true)
	if plan["a"] == "todos":
		registro.text = "%s %s: ¡va a golpear a todos!" % [f["nombre"], plan["prepara"]]
	else:
		registro.text = "%s %s: ¡va a por %s!" % [f["nombre"], plan["prepara"], obj["nombre"]]
	_numero_flotante(f, plan["aviso"], Color(1.0, 0.8, 0.2), 32)
	_voz(f, "ataque")                                # su voz (sonido.gd), como al lanzarse
	if plan.get("encoge", false):                    # el Slime se encoge: recibe la mitad hasta su turno
		f["defendiendo"] = true
		f["escala_rig"] = f["rig"].scale
		create_tween().tween_property(f["rig"], "scale", f["rig"].scale * Vector2(1.12, 0.78), 0.2).set_trans(Tween.TRANS_BACK)
	_actualizar()
	await get_tree().create_timer(1.0).timeout
	return true


# La señal de aviso sobre un enemigo que prepara un golpe (vfx/sena_arte.gd «aviso»): se queda hasta que golpea.
func _marcar_aviso(f: Dictionary, si: bool) -> void:
	var antes = f.get("aviso_nodo", null)
	if antes != null and is_instance_valid(antes):
		antes.queue_free()
	f.erase("aviso_nodo")
	if si and f.has("rig"):
		var s := _sena_arte("aviso", f, {"dur": 9999.0})
		# encima de «⚠ Cargando» y de la vida, sin taparlos (la señal vive en «escena», escalada: se pasa a sus medidas)
		s.position = (_ancla_vida(f) + Vector2(60, -40 - 24 * TAM_ESCENA) - escena.position) / TAM_ESCENA
		f["aviso_nodo"] = s


# Devorar (Gorthor, segunda fase): se cura el 60 % de lo que de verdad mordió. Lo que paró la coraza de Escarcha
# («absorbido», que apunta el impacto de _animar_golpe) no cuenta; sin coraza, el 60 % del mordisco, como siempre.
func _cura_devorar(f: Dictionary, mordisco: int) -> int:
	return mini(maxi(0, int((mordisco - int(f.get("absorbido", 0))) * 0.6)), f["hp_max"] - f["hp"])


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


# Zarzalín (ficha del bestiario 01): enseña a leer un ataque cargado.
#   - Si avisó en su turno anterior («cargando»), embiste a quien eligió (×1,8; Defender lo reduce a la mitad, como
#     cualquier golpe) y el turno siguiente recupera el aliento: nunca dos ataques fuertes seguidos.
#   - Si no, a veces (40 %) avisa: baja el hocico y da dos golpes de pezuña (avisar() de zarzalin_3d.gd). Se ve
#     «⚠ Cargando» sobre su vida y el cartel dice a quién va.
#   - Si no, el colmillo lateral: un golpe corto a un objetivo.
# Cada ataque se resuelve una sola vez, en el impacto del clip (_anim_zarzalin).
const ZARZALIN := {"prob_aviso": 0.4, "mult_embestida": 1.8}


func _turno_zarzalin(f: Dictionary, vivos: Array, mult: float) -> void:
	var p = _p3d(f)
	if f.get("recupera", false):
		f["recupera"] = false
		registro.text = "%s recupera el aliento" % f["nombre"]
		_numero_flotante(f, "Recupera", Color(0.8, 0.85, 0.75), 28)
		await get_tree().create_timer(0.8).timeout
		return
	if f.get("cargando", false):
		f["cargando"] = false
		_marcar_aviso(f, false)
		f["recupera"] = true
		var objetivo = f.get("objetivo_carga", null)
		if objetivo == null or objetivo["hp"] <= 0:
			objetivo = _elegir_objetivo("agresivo", vivos)
		objetivo = _cubre(objetivo)                  # Garon puede cubrir al que avisó (recibe él la embestida, a la mitad)
		f.erase("objetivo_carga")
		registro.text = "¡%s embiste a %s!" % [f["nombre"], objetivo["nombre"]]
		f["ataque_3d"] = "embestida_espinosa"
		await _animar_golpe(f, objetivo, int(f["atk"] * ZARZALIN["mult_embestida"] * mult) + randi_range(-2, 3), "")
		f.erase("ataque_3d")
		return
	if randf() < ZARZALIN["prob_aviso"]:
		var objetivo := _elegir_objetivo("agresivo", vivos)
		f["cargando"] = true
		_marcar_aviso(f, true)
		f["objetivo_carga"] = objetivo
		registro.text = "%s baja el hocico: ¡va a embestir a %s!" % [f["nombre"], objetivo["nombre"]]
		_numero_flotante(f, "⚠ ¡Embestida!", Color(1.0, 0.8, 0.2), 32)
		_actualizar()
		if p != null and p.has_method("avisar"):
			await p.avisar("embestida_espinosa")
		else:
			await get_tree().create_timer(1.0).timeout
		return
	var objetivo := _cubre(_elegir_objetivo("agresivo", vivos))
	registro.text = "%s ataca a %s" % [f["nombre"], objetivo["nombre"]]
	f["ataque_3d"] = "colmillo_lateral"
	await _animar_golpe(f, objetivo, int(f["atk"] * mult) + randi_range(-2, 3), "")
	f.erase("ataque_3d")


func _fin_turno_enemigo(f: Dictionary) -> void:
	atacante_actual = null
	f["atb"] = 0.0
	_actualizar()
	await get_tree().create_timer(0.3).timeout
	if not _comprobar_fin():
		estado = "esperando"


# Un enemigo cobarde sale corriendo del combate (no da experiencia ni oro).
func _huir(f: Dictionary) -> void:
	registro.text = "¡%s huye!" % f["nombre"]
	Sonido.efecto("huida", {"db": -4.0})           # sonido.gd
	f["huido"] = true
	_marcar_aviso(f, false)
	var rig: Node2D = f["rig"]
	var pz = _p3d(f)
	if pz != null and pz.has_method("avisar"):        # Zarzalín: se da la vuelta y se va galopando
		pz.mirar(Vector3(-1, 0, 0.1), 0.12)
		pz.correr()
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
		Sonido.efecto("congelar")                    # el hielo cruje al congelarse (sonido.gd, T-083)
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
	elif estado in ["magia", "pocion", "invocacion"]:
		_mostrar_menu()


func _unhandled_input(event: InputEvent) -> void:
	if estado == "accion" and fuera.visible:          # la invocación en marcha: Intro / A o Esc / B la saltan
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()     # (como al tocar la pantalla, _toque_fuera)
			saltar_invocacion = true
			if inv_erebo != null:
				inv_erebo.saltar()
		return
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
	_mostrar_panel(candidatos, "elegir")
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
	_pintar_panel()


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
	if modo_panel == "elegir":
		_ocultar_panel()
	flecha.visible = false
	obj_nombre.visible = false
	obj_linea.visible = false
	fuera.visible = false


func _ocultar_menu() -> void:
	menu.cerrar()
	_limpiar_objetivo()
	_ocultar_panel()


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
	var inv := _estado_invocacion()                  # Érebo lo invoca Lya, con la Armonía llena
	menu.abrir(actor, [
		{"tipo": "carta", "texto": "ATACAR", "accion": func(): _menu_objetivo("atacar", ""),
			"texto_b": "DEFENDER", "accion_b": _defender},
		{"texto": "MAGIA", "accion": _menu_magia, "apagado": coste_min == 999 or not _puede_pagar(coste_min),
			"motivo": "No sabe magias" if coste_min == 999 else "Necesitas %d PM" % coste_min},
		{"tipo": "invocacion", "texto": "INVOCACIÓN", "accion": _invocar, "apagado": not inv["lista"],
			"motivo": inv["motivo"]},
		_orden_objeto(),
		_orden_huir(),
	])
	_pruebas_menu()


# OBJETO y HUIR, iguales en el menú de todos (con su motivo si están apagadas, T-100).
func _orden_objeto() -> Dictionary:
	return {"texto": "OBJETO", "accion": _menu_pocion, "apagado": OBJETOS_COMBATE.keys().all(func(n): return _cantidad_objeto(n) <= 0),
		"motivo": "No quedan objetos"}


func _orden_huir() -> Dictionary:
	return {"texto": "HUIR", "accion": _escapar, "apagado": Engine.get_meta("tipo_combate", "normal") != "normal",
		"motivo": "No se puede huir"}


# ¿Se puede invocar a Érebo ahora? (T-101: la orden INVOCACIÓN y el HUD de la Armonía lo explican). Las reglas son las de
# siempre y no cambian: la Armonía llena y Lya en pie. «motivo»: por qué no, junto a la orden; «hud»: lo que se lee
# junto a «ARMONÍA». Sin Lya en el grupo no se la nombra (Kael solo, antes de conocerla).
func _estado_invocacion() -> Dictionary:
	var lya: Array = heroes.filter(func(h): return h["nombre"] == "Lya")
	var por_ciento := "%d %%" % roundi(clampf(armonia, 0.0, 1.0) * 100.0)
	if lya.is_empty():
		return {"lista": false, "motivo": "Nadie puede invocar", "hud": por_ciento}
	if lya[0]["hp"] <= 0:
		return {"lista": false, "motivo": "Lya ha caído", "hud": "LYA HA CAÍDO", "caida": true}
	if armonia < 1.0:
		return {"lista": false, "motivo": "Armonía al " + por_ciento, "hud": por_ciento}
	return {"lista": true, "motivo": "", "hud": "INVOCACIÓN LISTA"}


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
	# pruebas: con Engine «prueba_curar», quien sabe Cura la usa en el más herido si alguien baja del 50 % (un jugador
	# que cura a tiempo; pruebas/prueba_incorporacion.gd). En el juego normal esa meta no existe.
	if Engine.get_meta("prueba_curar", false) and heroes.any(func(h): return h["hp"] > 0 and float(h["hp"]) / h["hp_max"] < 0.5):
		for h in _hechizos(actor):
			if h[0] == "Cura" and actor["mp"] >= h[2]["coste"]:
				_elegir_hechizo.call_deferred("Cura", h[1], true)
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
	var minimo: int = GUARDIA["coste"]               # la Guardia (T-100) también va en ESGRIMA
	for t in TECNICAS_GARON.values():
		minimo = mini(minimo, t["coste"])
	if not _coloso_vivo().is_empty():                # contra el Coloso (V9), también «Leer runas»
		minimo = mini(minimo, Coloso.LECTURA["coste"])
	menu.abrir(actor, [
		{"tipo": "carta", "texto": "ATACAR", "accion": func(): _menu_objetivo("atacar", ""),
			"texto_b": "DEFENDER", "accion_b": _defender},
		{"texto": "ESGRIMA", "accion": _menu_esgrima, "apagado": not _puede_pagar(minimo),
			"motivo": "Necesitas %d PM" % minimo},
		{"texto": "EMBUIR", "accion": _menu_embuir, "apagado": not _puede_pagar(EMBUIR["coste"]),
			"motivo": "Necesitas %d PM" % EMBUIR["coste"]},
		_orden_objeto(),
		_orden_huir(),
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
		var paga := _puede_pagar(t["coste"])
		items.append({"texto": n, "accion": _elegir_tecnica.bind(n), "icono": actor.get("embuir", "") if actor.get("embuir", "") != "" else null,
			"derecha": "%d PM" % t["coste"], "apagado": not paga, "falta_pm": not paga,
			"desc": t["desc"] if paga else Artes.motivo_pm(t["coste"], actor["mp"])})
	for it in items:
		if it["icono"] == null:
			it.erase("icono")
	var paga_g := _puede_pagar(GUARDIA["coste"])       # la Guardia, detrás de las de ataque
	var motivo := "" if not _cubribles().is_empty() else GUARDIA["motivo"]
	if motivo == "" and not paga_g:
		motivo = Artes.motivo_pm(GUARDIA["coste"], actor["mp"])
	items.append({"texto": GUARDIA["nombre"], "accion": _elegir_guardia, "derecha": "%d PM" % GUARDIA["coste"],
		"apagado": motivo != "", "falta_pm": not paga_g, "desc": GUARDIA["desc"] if motivo == "" else motivo})
	var col := _coloso_vivo()                          # contra el Coloso de la Falla (V9): Garon lee sus inscripciones
	if not col.is_empty():
		var coste_l: int = Coloso.LECTURA["coste"]
		var paga_l := _puede_pagar(coste_l)
		var motivo_l := Coloso.motivo_lectura(col)
		if motivo_l == "" and not paga_l:
			motivo_l = Artes.motivo_pm(coste_l, actor["mp"])
		items.append({"texto": Coloso.LECTURA["nombre"], "accion": _leer_runas, "derecha": "%d PM" % coste_l,
			"apagado": motivo_l != "", "falta_pm": not paga_l, "desc": Coloso.LECTURA["desc"] if motivo_l == "" else motivo_l})
	menu.submenu(items)


# Garon lee las inscripciones del Coloso de la Falla (V9; combate_coloso.gd): su piel de piedra se abre durante sus dos
# turnos siguientes. Una acción de Garon con su coste, solo en este combate; no hace daño.
func _leer_runas() -> void:
	var col := _coloso_vivo()
	if col.is_empty() or Coloso.motivo_lectura(col) != "" or not _puede_pagar(Coloso.LECTURA["coste"]):
		return
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	_gastar_pm(quien, Coloso.LECTURA["coste"])
	Coloso.leer(col)
	registro.text = "%s lee las inscripciones: ¡la piel de piedra del Coloso se abre!" % quien["nombre"]
	_numero_flotante(quien, Coloso.LECTURA["nombre"], menu.COLOR_HEROE.get("Garon", Color.WHITE), 34)
	_sonar("leer_runas" if Sonido.EFECTOS.has("leer_runas") else "misterio")   # una vez, al leerlas
	_onda(_suelo_de(col), Color(COLOR_RUNAS, 0.9), 30.0, 220.0, 0.8, 8.0)
	_destello(_centro(col), COLOR_RUNAS, 1.4)
	_numero_flotante(col, "Runas leídas: piel abierta", COLOR_RUNAS, 28, Vector2(0, 50))
	_actualizar()
	await get_tree().create_timer(0.9).timeout
	_terminar_turno()


func _elegir_tecnica(n: String) -> void:
	if TECNICAS_GARON[n]["todos"]:
		_tecnica_garon(n, {})
	else:
		_pedir_objetivo(enemigos.filter(func(e): return e["hp"] > 0), func(f): _tecnica_garon(n, f), _menu_esgrima,
			"TOCA UN ENEMIGO")


# ---------------------------------------------------------------- Garon: la Guardia (T-100)
# Garon cubre a un aliado hasta su siguiente turno: se pone en guardia (Defender: los golpes le hacen la mitad) y los
# golpes que van a ese aliado los recibe él. Encaja con los ataques anunciados: si Zarzalín avisa que va a embestir a
# Kael, Garon le cubre y la embestida le da a él, a la mitad. Con varios golpes (el devastador de un jefe, a todos), el
# del aliado cubierto también va a Garon. Se acaba al empezar el turno siguiente de Garon, si Garon cae o si cae el
# aliado. No toca el ATB ni las 12 magias: es una técnica más de ESGRIMA, con su coste.
const GUARDIA := {"nombre": "Guardia", "coste": 4, "color": Color("C9D2E0"), "motivo": "No hay a quién cubrir.",
	"desc": "Cubre a un aliado hasta su turno: los golpes a él los recibe Garon, a la mitad."}


func _cubribles() -> Array:
	return heroes.filter(func(h): return h["hp"] > 0 and not is_same(h, actor))


func _elegir_guardia() -> void:
	if _cubribles().is_empty() or not _puede_pagar(GUARDIA["coste"]):
		return
	_pedir_objetivo(_cubribles(), _guardia, _menu_esgrima, "TOCA A UN ALIADO")


func _guardia(obj: Dictionary) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	_gastar_pm(quien, GUARDIA["coste"])
	_quitar_guardia(quien["nombre"])
	obj["guardia_de"] = quien["nombre"]
	quien["defendiendo"] = true                      # en guardia: como Defender, hasta su turno siguiente
	quien["rig"].modulate = COLOR_DEFENSA
	_actualizar()
	registro.text = "%s cubre a %s" % [quien["nombre"], obj["nombre"]]
	var p = _p3d(quien)                              # el gesto: se vuelve hacia el aliado y da un paso en guardia
	if p != null and p.has_method("mirar"):
		var dx: float = _centro(obj).x - _centro(quien).x
		p.mirar(Vector3(signf(dx) * 0.9, 0.0, 0.45), 0.2)
		if p.has_method("avanzar"):
			p.avanzar(0.8)
	_sonar("guardia")                                # una vez, al ponerse en guardia (sonido.gd, tanda 5)
	_sena_arte("guardia", obj, {"desde": _centro(quien) - _centro(obj)})
	_numero_flotante(obj, "Guardia", GUARDIA["color"], 30)
	await get_tree().create_timer(0.7).timeout
	if p != null and p.has_method("mirar_frente"):
		p.mirar_frente(0.25)
		p.reposo()
		if p.has_method("cubrir"):                # y se queda plantado, cubriendo, hasta que acaba la Guardia
			p.cubrir(Vector3.ZERO)                # (de cara a los enemigos, entre ellos y el aliado)
	await get_tree().create_timer(0.2).timeout
	_terminar_turno()


# El objetivo de un golpe enemigo, o Garon si le está cubriendo y sigue en pie. «avisar»: el texto «¡Cubre!» sobre
# Garon (no en los golpes de más de un ataque a todos, que ya lo dicen con el número).
var cubiertos := 0                               # golpes que la Guardia ha llevado a Garon en este combate


func _cubre(obj: Dictionary, avisar := true) -> Dictionary:
	var de := str(obj.get("guardia_de", ""))
	if de == "" or obj["hp"] <= 0:
		return _cubre_gemelas(obj, avisar)
	for h in heroes:
		if h["nombre"] == de and h["hp"] > 0 and not is_same(h, obj):
			cubiertos += 1
			if avisar:
				_numero_flotante(h, "¡Cubre a %s!" % obj["nombre"], GUARDIA["color"], 30, Vector2(-40, -40))
			return h
	return _cubre_gemelas(obj, avisar)


# C2, Gemelas de la Muralla: quien las lleva recibe el golpe de un aliado con poca vida (equipo_extra.gd quien_cubre).
# Sin ellas, el objetivo de siempre.
func _cubre_gemelas(obj: Dictionary, avisar := true) -> Dictionary:
	if obj["hp"] <= 0:
		return obj
	var q: Dictionary = Extra.quien_cubre(obj, heroes)
	if not is_same(q, obj):
		cubiertos += 1
		if avisar:
			_numero_flotante(q, "¡Cubre a %s!" % obj["nombre"], GUARDIA["color"], 30, Vector2(-40, -40))
	return q


# Quita la guardia que daba «nombre» (al empezar su turno o al caer). Sin guardia, no hace nada.
func _quitar_guardia(nombre: String) -> void:
	for g in heroes:                                # el gesto de cubrir de Garon (garon_3d.gd), fuera
		var pg = _p3d(g) if g["nombre"] == nombre else null
		if pg != null and pg.has_method("fin_cubrir"):
			pg.fin_cubrir()
	for h in heroes:
		if str(h.get("guardia_de", "")) == nombre:
			h.erase("guardia_de")


func _menu_embuir() -> void:
	estado = "magia"
	var items: Array = []
	var paga := _puede_pagar(EMBUIR["coste"])
	for el in EMBUIR["elementos"]:
		var activo: bool = actor.get("embuir", "") == el
		items.append({"texto": el, "accion": _embuir.bind(el), "icono": el, "apagado": not paga, "falta_pm": not paga,
			"derecha": "%d PM" % EMBUIR["coste"],
			"desc": (DESC_EMBUIR[el] + (" (activo: %d turnos)" % actor.get("embuir_turnos", 0) if activo else " Dura 3 turnos, +20 % de daño."))
				if paga else Artes.motivo_pm(EMBUIR["coste"], actor["mp"])})
	menu.submenu(items)


# Daño físico de un golpe de Garon (con Embuir, +20 %).
# Las fórmulas están en combate_formulas.gd (10/11): aquí se conservan las funciones de siempre.
func _dano_fisico(quien: Dictionary, mult := 1.0) -> int:
	return Formulas.dano_fisico(quien, mult, EMBUIR["extra"])


func _embuir(el: String) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	_gastar_pm(quien, EMBUIR["coste"])
	quien["embuir"] = el
	quien["embuir_turnos"] = EMBUIR["turnos"]
	quien["embuir_nuevo"] = true                    # este turno no cuenta
	Sonido.efecto("embuir")                         # sonido.gd
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
			Sonido.golpe(true)                       # el tajo de Juicio (sonido.gd)
			var dd: int = Coloso.dano_recibido(d, "", quien, obj)   # el Coloso (V9): piel o ventana; los demás, «d»
			_quitar_pv(obj, dd)
			Sonido.recibe(obj)                       # y su voz: herido o caída (sonido.gd)
			_destello(_centro(obj), menu.COLOR_HEROE.get("Garon", Color.WHITE).lightened(0.4), 1.8)
			_golpe_visual(obj, dd, _efecto_embuir(quien, obj))
		if _p3d(quien) != null and _p3d(quien).has_method("atacar_juicio"):
			await _anim_ataque_3d(quien, obj, impacto, "atacar_juicio")
		else:
			await _animar_golpe(quien, obj, d, "")
	else:
		var objs := enemigos.filter(func(e): return e["hp"] > 0)
		var impacto := func():
			Sonido.golpe()                           # una vez por vuelta del Giro (sonido.gd)
			for e in objs:
				if e["hp"] <= 0:
					continue
				var d := Coloso.dano_recibido(_dano_fisico(quien, t["mult"]), "", quien, e)   # (el Coloso, V9)
				_quitar_pv(e, d)
				Sonido.recibe(e)                     # su voz (sonido.gd: una por familia y dos a la vez como mucho)
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
	return r + Artes.hechizos(f["nombre"])          # y las artes que ya puede usar (artes.gd; Garon, ninguna)


# Menú de magia: arriba las pestañas de nivel (I, II, III; solo las que sabe) y debajo las magias de
# ese nivel con el icono de su elemento, su nombre y su coste (con el modo pruebas, «PM ∞»).
# Debajo, una línea explica la magia elegida.
# Detrás de I · II · III, una pestaña con icono por cada familia nueva que sabe (artes.gd: Alba, Lumbre...), con sus
# niveles en filas. Sin artes, las pestañas, las filas y su orden son exactamente los de antes.
const NIVELES_ROMANOS := ["I", "II", "III"]


func _menu_magia(nivel := 0) -> void:
	estado = "magia"
	var por_nivel := [[], [], []]
	var familias: Array = []                      # artes (artes.gd), en el orden de sus pestañas
	var sabe := {}                                # familia → nivel que puede usar
	for h in _hechizos(actor):
		if Artes.es_arte(h[0]):
			if not h[0] in familias:
				familias.append(h[0])
			sabe[h[0]] = h[1]
		else:
			por_nivel[h[1] - 1].append(h)
	if nivel == 0:
		nivel = magia_nivel_menu.get(actor["nombre"], 1)
	var duos := _duos_de(actor)                   # V11: técnicas combinadas (pestaña DÚO)
	var quiere_duo: bool = nivel == PESTANA_DUO and not duos.is_empty()
	var p: Dictionary = Artes.pestanas_magia(por_nivel.map(func(x): return not x.is_empty()), familias,
		1 if quiere_duo else nivel)
	nivel = PESTANA_DUO if quiere_duo else p["valor"]
	magia_nivel_menu[actor["nombre"]] = nivel     # 1-3: nivel; 4 y 5: primera y segunda familia; 9: DÚO
	var pestanas: Array = []
	for t in p["pestanas"]:
		var tab: Dictionary = t.duplicate()
		tab["accion"] = _menu_magia.bind(t["valor"])
		pestanas.append(tab)
	var activa: int = p["activa"]
	if not duos.is_empty():
		if pestanas.is_empty():                       # una sola pestaña de magias: se nombra para poder volver a ella
			pestanas.append({"texto": "MAGIA", "valor": p["valor"], "ancho": 140.0, "accion": _menu_magia.bind(p["valor"])})
		pestanas.append({"texto": "DÚO", "valor": PESTANA_DUO, "ancho": 110.0, "accion": _menu_magia.bind(PESTANA_DUO)})
		if quiere_duo:
			activa = pestanas.size() - 1
	var items: Array = []
	if quiere_duo:
		menu.submenu(duos, pestanas, activa)
		return
	if nivel >= 4:
		var fam: String = familias[nivel - 4]
		for it in Artes.filas_familia(fam, sabe[fam], actor, heroes, enemigos, cola, MODO_PRUEBAS, ATB_MAX):
			it["accion"] = _elegir_hechizo.bind(fam, it["nivel"])
			var da: Dictionary = Artes.datos(fam, it["nivel"])
			it["area_enemigos"] = da.get("todos", false) and da.get("a", "") == "enemigos"
			items.append(it)
	else:
		for h in por_nivel[nivel - 1]:
			var d: Dictionary = h[2]
			var paga := _puede_pagar(d["coste"])
			items.append({"texto": d["nombre"], "accion": _elegir_hechizo.bind(h[0], h[1]), "icono": h[0],
				"derecha": "PM ∞" if MODO_PRUEBAS else "%d PM" % d["coste"], "apagado": not paga, "falta_pm": not paga,
				"area_enemigos": d["todos"] and not MAGIAS[h[0]].get("cura", false),
				"desc": _desc_magia(h[0], d) if paga else Artes.motivo_pm(d["coste"], actor["mp"])})
	menu.submenu(items, pestanas, activa)


# ---------------------------------------------------------------- V11: técnicas combinadas (MEJORAS_COMBATE.md)
# Filo Arcano (Kael + Lya): Lya prende en fuego la espada de Kael. En el turno de Kael, si Lya está en pie, con 8 PM y
# con la mitad de su ATB: Kael golpea con su ataque más el 60 % del Fuego de Lya, con las llamas de Embuir (quema) y
# como golpe de magia (rompe la guardia del Slime y cuenta para interrumpir). Gasta 8 PM de Lya y su turno (su ATB
# vuelve a cero).
# Quiebra (Kael + Garon), en la pestaña DÚO de Kael: Garon en pie y con la mitad de su ATB; Kael paga 6 PM. Los dos
# golpean a la vez (el ataque de Kael más el 80 % del de Garon). Es un golpe de ruptura: a un enemigo que prepara su
# golpe (Grimfang, Slime o Gólem) se lo corta siempre, y le quita la guardia. Gasta el turno de Garon.
# Barrera Rúnica (Lya + Garon), en la pestaña DÚO de Lya: Garon en pie y con la mitad de su ATB; Lya paga 10 PM.
# Garon traza las runas y Lya las enciende: todo el grupo en pie recibe una coraza del 25 % de su vida máxima (la de
# las artes: no se suma a otra mayor). Para el golpe anunciado a todos (el Pisotón del Gólem). Gasta el turno de Garon.
const PESTANA_DUO := 9
const FILO_ARCANO := {"coste": 8, "parte_magia": 0.6, "atb_min": 0.5}
const QUIEBRA := {"coste": 6, "parte_garon": 0.8, "atb_min": 0.5}
const BARRERA_RUNICA := {"coste": 10, "barrera": 0.25, "atb_min": 0.5}
const C_RUNA := Color(1.0, 0.82, 0.45)
var golpe_ruptura := false                       # lo pone Quiebra mientras resuelve su golpe (_vigilar_carga)


func _heroe_de_grupo(nombre: String) -> Dictionary:
	for h in heroes:
		if h["nombre"] == nombre:
			return h
	return {}


# Por qué un compañero no puede prestar su turno ahora ("" si puede). «paga» y «coste»: quién pone los PM.
func _motivo_duo(socio: Dictionary, paga: Dictionary, coste: int, atb_min: float) -> String:
	if socio["hp"] <= 0:
		return "%s ha caído" % socio["nombre"]
	if not MODO_PRUEBAS and paga["mp"] < coste:
		return "%s necesita %d PM" % [paga["nombre"], coste]
	if socio["atb"] < ATB_MAX * atb_min:
		return "%s aún no está lista (%d %%)" % [socio["nombre"], roundi(socio["atb"] / ATB_MAX * 100.0)] \
			if socio["nombre"] == "Lya" else "%s aún no está listo (%d %%)" % [socio["nombre"], roundi(socio["atb"] / ATB_MAX * 100.0)]
	return ""


func _fila_duo(texto: String, icono: String, accion: Callable, coste: int, quien_paga: String, motivo: String,
		desc: String) -> Dictionary:
	return {"texto": texto, "icono": icono, "accion": accion, "apagado": motivo != "", "motivo": motivo,
		"derecha": "PM ∞" if MODO_PRUEBAS else ("%d PM %s" % [coste, quien_paga]).strip_edges(),
		"desc": desc if motivo == "" else motivo}


func _duos_de(quien: Dictionary) -> Array:
	var r: Array = []
	var lya := _heroe_de_grupo("Lya")
	var garon := _heroe_de_grupo("Garon")
	match quien.get("nombre", ""):
		"Kael":
			if not lya.is_empty():
				r.append(_fila_duo("Filo Arcano", "Fuego", _elegir_filo_arcano, FILO_ARCANO["coste"], "Lya",
					_motivo_duo(lya, lya, FILO_ARCANO["coste"], FILO_ARCANO["atb_min"]),
					("Kael y Lya: la espada en llamas. Golpe que quema, rompe guardias y corta golpes preparados. " +
					"Gasta %d PM y el turno de Lya.") % FILO_ARCANO["coste"]))
			if not garon.is_empty():
				r.append(_fila_duo("Quiebra", "", _elegir_quiebra, QUIEBRA["coste"], "",
					_motivo_duo(garon, quien, QUIEBRA["coste"], QUIEBRA["atb_min"]),
					"Kael y Garon a la vez: un golpe de ruptura que corta siempre un golpe preparado y quita la guardia. " +
					"Gasta %d PM de Kael y el turno de Garon." % QUIEBRA["coste"]))
		"Lya":
			if not garon.is_empty():
				r.append(_fila_duo("Barrera Rúnica", "Cura", _barrera_runica, BARRERA_RUNICA["coste"], "",
					_motivo_duo(garon, quien, BARRERA_RUNICA["coste"], BARRERA_RUNICA["atb_min"]),
					"Garon traza las runas y Lya las enciende: una coraza para todo el grupo. " +
					"Gasta %d PM de Lya y el turno de Garon." % BARRERA_RUNICA["coste"]))
	return r


# El compañero presta su turno: su ATB a cero y fuera de la cola.
func _prestar_turno(socio: Dictionary) -> void:
	socio["atb"] = 0.0
	cola = cola.filter(func(x): return not is_same(x, socio))
	_numero_flotante(socio, "¡Dúo!", Color(1.0, 0.85, 0.45), 30)


func _elegir_quiebra() -> void:
	_pedir_objetivo(enemigos.filter(func(e): return e["hp"] > 0), _quiebra, _menu_magia.bind(PESTANA_DUO),
		"TOCA UN ENEMIGO")


func _quiebra(obj: Dictionary) -> void:
	_ocultar_menu()
	estado = "accion"
	var kael: Dictionary = actor
	var garon := _heroe_de_grupo("Garon")
	_gastar_pm(kael, QUIEBRA["coste"])
	_prestar_turno(garon)
	registro.text = "Kael y Garon: ¡Quiebra!"
	_destello(_centro(garon), C_RUNA, 1.0)
	Sonido.golpe(true)
	_actualizar()
	await get_tree().create_timer(0.3).timeout
	var dano: int = maxi(1, int(kael["atk"] * kael.get("mult_fisico", 1.0))) + randi_range(-2, 3) \
		+ int(_dano_fisico(garon) * QUIEBRA["parte_garon"])
	golpe_ruptura = true
	await _animar_golpe(kael, obj, dano, "")
	golpe_ruptura = false
	_temblor(8.0)
	_terminar_turno()


func _barrera_runica() -> void:
	_ocultar_menu()
	estado = "accion"
	var lya: Dictionary = actor
	var garon := _heroe_de_grupo("Garon")
	_gastar_pm(lya, BARRERA_RUNICA["coste"])
	_prestar_turno(garon)
	registro.text = "Garon y Lya: ¡Barrera Rúnica!"
	var pl = _p3d(lya)
	if pl != null and pl.has_method("lanzar_magia"):
		pl.lanzar_magia()
	_sonar("guardia")
	_actualizar()
	await get_tree().create_timer(0.4).timeout
	for h in heroes.filter(func(x): return x["hp"] > 0):
		var b: int = Artes.poner_barrera(h, BARRERA_RUNICA["barrera"])
		_sena_arte("escarcha", h, {"color": C_RUNA})
		_numero_flotante(h, "Coraza %d" % b, C_RUNA, 28)
	_actualizar()
	await get_tree().create_timer(0.8).timeout
	_terminar_turno()


func _elegir_filo_arcano() -> void:
	_pedir_objetivo(enemigos.filter(func(e): return e["hp"] > 0), _filo_arcano, _menu_magia.bind(PESTANA_DUO),
		"TOCA UN ENEMIGO")


func _filo_arcano(obj: Dictionary) -> void:
	_ocultar_menu()
	estado = "accion"
	var kael: Dictionary = actor
	var lya := _heroe_de_grupo("Lya")
	if not MODO_PRUEBAS:
		lya["mp"] -= FILO_ARCANO["coste"]
	_prestar_turno(lya)                               # presta su turno
	registro.text = "Kael y Lya: ¡Filo Arcano!"
	var pl = _p3d(lya)
	if pl != null and pl.has_method("lanzar_magia"):
		pl.lanzar_magia()                              # su gesto de lanzar, sin esperar
	_destello(_centro(kael), Color(1.0, 0.55, 0.2), 1.2)
	_sonar("embuir")
	_actualizar()
	await get_tree().create_timer(0.35).timeout
	var antes = kael.get("embuir", null)
	kael["embuir"] = "Fuego"
	kael["filo_arcano"] = true
	var dano: int = maxi(1, int(kael["atk"] * kael.get("mult_fisico", 1.0))) + randi_range(-2, 3) \
		+ int(_dano_magia(lya, NIVELES_MAGIA["Fuego"][0]) * FILO_ARCANO["parte_magia"])
	await _animar_golpe(kael, obj, dano, "")
	kael.erase("filo_arcano")
	if antes == null:
		kael.erase("embuir")
	else:
		kael["embuir"] = antes
	_terminar_turno()


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
	if Artes.es_arte(magia):                        # familias nuevas (artes.gd): su ruta; las 12 de siempre, igual
		_elegir_arte(magia, nivel, sola)
		return
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


# ---------------------------------------------------------------- artes (T-091, artes.gd)

# Las de uno piden objetivo como las de siempre; las de todos, no. Con «sola» (pruebas: -- magia=Alba:1), al primero.
# Si no hay a quién o faltan PM, nada: el menú ya la enseña apagada con su motivo.
func _elegir_arte(fam: String, nv: int, sola := false) -> void:
	var d: Dictionary = Artes.datos(fam, nv)
	var objs: Array = Artes.objetivos(fam, nv, actor, heroes, enemigos, cola, ATB_MAX)
	if objs.is_empty() or not _puede_pagar(d["coste"]):
		return
	if d["todos"]:
		_lanzar_arte(fam, nv, objs)
	elif sola:
		_lanzar_arte(fam, nv, [objs[0]])
	else:
		_pedir_objetivo(objs, func(f): _lanzar_arte(fam, nv, [f]), _menu_magia.bind(0),
			"TOCA UN ENEMIGO" if d["a"] == "enemigos" else "TOCA A UN ALIADO")


# Lanza un arte: gasta los PM, anima a quien lanza (el círculo de siempre con el color de su familia), aplica el efecto
# (artes.gd), suena una vez y acaba el turno (la Armonía +0,15, como cualquier acción).
# Su seña (T-100): el gesto (se vuelve hacia el aliado al que va y conjura con su clip de siempre: el de Kael es
# «mage_soell_cast_7»), la silueta (vfx/sena_arte.gd, dibujada: se lee igual con las partículas del móvil) y el sonido,
# los tres en el momento en que el arte se aplica, una sola vez. En la Lumbre de Retorno, la brasa vuela primero y el
# caído vuelve al llegar: su fila del HUD se ilumina y sale «¡Kael vuelve!».
func _lanzar_arte(fam: String, nv: int, objs: Array) -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	var d: Dictionary = Artes.datos(fam, nv)
	_gastar_pm(quien, d["coste"])
	_actualizar()
	registro.text = "%s lanza %s" % [quien["nombre"], d["nombre"]]
	if d.get("todos", false) and d.get("a", "") == "enemigos":
		_mostrar_panel(objs, "area")                  # V11: a quién alcanza (se quita al acabar el turno)
	quien["animando"] = true
	var circulo := _carga_magia(quien, fam, 1.0 + 0.3 * (nv - 1))
	var p = _p3d(quien)
	var se_vuelve := _gesto_arte(quien, objs, d)
	if p != null:
		await p.lanzar_magia()
	else:
		await get_tree().create_timer(0.5).timeout
	var col: Color = Artes.COLOR[fam]
	if d.has("revive"):                              # la brasa vuela de quien lanza al caído; al llegar, se aplica
		for f in objs:
			_sena_arte("lumbre", f, {"desde": _centro(quien) - _centro(f), "viaje": SENA_VIAJE_LUMBRE})
		await get_tree().create_timer(SENA_VIAJE_LUMBRE).timeout
	var extra := int(quien.get("efectos", {}).get("apoyo_turnos", 0.0))   # Báculo del Peregrino (C2)
	var hechos: Array = Artes.aplicar(fam, nv, objs, cola, ATB_MAX, extra)
	_sonar(Artes.sonido(fam, nv))                    # una vez, al aplicarse (si sonido.gd ya lo tiene)
	if fam == "Alba" and nv == 3:
		_fogonazo(Color(1.0, 0.85, 0.45), 0.22, 1.0)  # Hora Dorada: un destello dorado
	if fam == "Alba" and nv == 2:
		_fogonazo(Color(0.55, 0.35, 0.8), 0.25, 1.2)   # Peso del Ocaso: la pantalla se tiñe de violeta
	for i in hechos.size():
		var x: Dictionary = hechos[i]
		var f: Dictionary = x["f"]
		_particulas(_centro(f) + Vector2(0, 60), Color(col, 1.0), Color(col, 0.0), 26, 1.0, Vector2(40, 120), 60.0,
			Vector2(0, -1), 30.0, Vector2(0, -60), 0.07)
		if x.has("atb"):
			_sena_arte("ocaso" if x["atb"] < 0.0 or not f.get("hero", false) else "alba", f, {"color": menu.ORO} if nv == 3 else {})
			_numero_flotante(f, "Retraso" if x["atb"] < 0.0 else "¡Antes!", col, 32)
		elif x.has("pv"):
			_revivir_visual(f)
			_numero_flotante(f, "+%d" % x["pv"], C_CURA)
			_numero_flotante(f, "¡%s vuelve!" % f["nombre"], menu.ORO, 36, Vector2(-40, -52))
			menu.destacar_heroe(f, col)
		elif x.has("aliento"):
			_sena_arte("aliento", f, {"hojas": int(x["aliento"])})
			if i == 0:                                # lo que dura, una vez (es igual para todos; el HUD lo cuenta)
				_numero_flotante(f, "Aliento: %d turnos" % int(x["aliento"]), Artes.COLOR_ESTADO["aliento"], 30)
		elif x.has("barrera"):                       # M3: la coraza de hielo se forma alrededor (y el HUD dice cuánto aguanta)
			_sena_arte("escarcha", f, {"color": C_HIELO} if d.get("congela", false) else {})   # el Invierno, más azul
			_numero_flotante(f, "❄ %d" % x["barrera"], col, 30)
		elif x.has("brasa"):
			_sena_arte("brasa", f)                   # M4: una llama queda sobre el aliado (y su icono en el HUD)
			_numero_flotante(f, "Brasa", col, 30)
	_actualizar()
	_quitar_carga(circulo)
	await get_tree().create_timer(0.9).timeout
	if p != null:
		p.fin_magia()
		if se_vuelve:
			p.mirar_frente(0.3)
	await get_tree().create_timer(0.3).timeout
	quien["animando"] = false
	_terminar_turno()


const SenaArte := preload("res://vfx/sena_arte.gd")
const SENA_VIAJE_LUMBRE := 0.45                      # lo que tarda la brasa de la Lumbre en llegar al caído
const COLOR_OCASO := Color(0.7, 0.5, 0.96)


# El gesto de un arte (T-100): hacia un aliado (el Compás, la Lumbre de Retorno), quien lanza se vuelve hacia él; a
# todo el grupo (Segundo Aliento), hacia delante. Las que van a los enemigos, como las magias: mirando al frente.
# Devuelve si se ha vuelto (para que mire otra vez al frente al acabar).
func _gesto_arte(quien: Dictionary, objs: Array, d: Dictionary) -> bool:
	var p = _p3d(quien)
	if p == null or not p.has_method("mirar") or objs.is_empty() or not objs[0].get("hero", false):
		return false
	if d["todos"]:
		p.mirar(Vector3(0.25, 0.0, 1.0), 0.3)
		return true
	if is_same(objs[0], quien):
		return false
	var dx: float = _centro(objs[0]).x - _centro(quien).x
	p.mirar(Vector3(signf(dx) * 0.9, 0.0, 0.45) if absf(dx) > 30.0 else Vector3(0.0, 0.0, 1.0), 0.25)
	return true


# La silueta de un arte sobre un luchador (vfx/sena_arte.gd). «extra»: propiedades del efecto (desde, viaje, hojas...).
func _sena_arte(tipo: String, f: Dictionary, extra := {}) -> Node2D:
	var s = SenaArte.new()
	s.tipo = tipo
	s.color = {"alba": Artes.COLOR["Alba"], "ocaso": COLOR_OCASO, "lumbre": Artes.COLOR["Lumbre"],
		"aliento": Artes.COLOR_ESTADO["aliento"], "hoja": Artes.COLOR_ESTADO["aliento"], "escarcha": Artes.COLOR["Escarcha"],
		"escarcha_golpe": Artes.COLOR["Escarcha"], "escarcha_rota": Artes.COLOR["Escarcha"], "aviso": Color(1.0, 0.72, 0.2),
		"guardia": GUARDIA["color"], "brasa": Artes.COLOR_ESTADO["brasa"]}.get(tipo, Color.WHITE)
	s.dur = {"alba": 1.5, "ocaso": 1.4, "lumbre": SENA_VIAJE_LUMBRE + 1.4, "aliento": 1.6, "hoja": 1.0, "escarcha": 1.5,
		"escarcha_golpe": 0.45, "escarcha_rota": 0.9, "guardia": 1.4, "brasa": 1.4}.get(tipo, 1.4)
	s.alto = clampf((_suelo_de(f).y - _centro(f).y) * 2.0, 120.0, 340.0)
	for k in extra:
		s.set(k, extra[k])
	s.position = _centro(f)
	s.z_index = 6
	escena.add_child(s)
	return s


# Lumbre de Retorno: el 3D se levanta (revivir(), que ya tienen los tres modelos); el 2D deshace la pose de caído de
# _restablecer_color (giro de 25° y 30 px abajo).
func _revivir_visual(f: Dictionary) -> void:
	var p = _p3d(f)
	if p != null and p.has_method("revivir"):
		p.revivir()
	elif f.has("cuerpo"):
		f["cuerpo"].rotation_degrees = 0.0
		f["rig"].position = f["rig_base"]
	_restablecer_color(f)


# Al empezar el turno de un héroe, antes de su menú: su Aliento (Segundo Aliento) y la regeneración de su equipo
# (Cinta de Lumi, C1). Sin ninguno de los dos, no hace nada.
func _tic_estados_heroe(f: Dictionary) -> void:
	var con_aliento := int(f.get("aliento", 0)) > 0
	var cura: int = Artes.curar_al_empezar_turno(f, Extra.regen(f.get("efectos", {})))
	if cura > 0:
		_numero_flotante(f, "+%d" % cura, C_CURA)
		if con_aliento:
			_sonar(Artes.SONIDO_ESTADO["aliento"])
		_actualizar()
	if con_aliento:                                  # T-100: el turno de Aliento gastado se ve (una hoja sube y el HUD
		_sena_arte("hoja", f)                        # cuenta uno menos); al acabarse, se dice
		_actualizar()
		if int(f.get("aliento", 0)) <= 0:
			create_tween().tween_callback(func(): _numero_flotante(f, "Aliento se acaba", Color(0.8, 0.85, 0.75), 24)).set_delay(0.5)


# Equipo que actúa al empezar el combate (M3, M4 y C2; sin él, nada cambia): la Lágrima de ámbar pone una coraza, la
# Brasa en frasco una Brasa. (La Hoja sin Nombre suma su ataque en grupo.gd estadisticas: también en el menú Grupo.)
const BRASA_FRASCO := 0.25                           # con qué parte de sus PV se levanta quien lleva la Brasa en frasco


func _equipo_al_empezar(h: Dictionary) -> void:
	var ef: Dictionary = h.get("efectos", {})
	if float(ef.get("barrera_inicio", 0.0)) > 0.0:
		Artes.poner_barrera(h, float(ef["barrera_inicio"]))
	if ef.get("brasa", false):
		Artes.poner_brasa(h, BRASA_FRASCO)


# Rama del Árbol Milenario (C2): al empezar, el aliado más herido recibe Aliento («aliento_inicio» turnos).
func _aliento_al_empezar() -> void:
	var turnos := 0
	for h in heroes:
		turnos = maxi(turnos, int(h.get("efectos", {}).get("aliento_inicio", 0.0)))
	if turnos <= 0:
		return
	var vivos := heroes.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		return
	vivos.sort_custom(func(a, b): return float(a["hp"]) / a["hp_max"] < float(b["hp"]) / b["hp_max"])
	Artes.dar_aliento(vivos[0], turnos, float(Artes.datos("Lumbre", 2)["regen"]))


# Última Brasa y Brasa en frasco (M4): el héroe que llega a 0 PV se levanta en ese instante, una vez. Su llama sube,
# suena «brasa» y lo dice. (artes.gd al_llegar_a_cero ya le ha devuelto los PV.)
func _brasa_levanta(f: Dictionary) -> void:
	_sonar(Artes.SONIDO_ESTADO["brasa"])
	_sena_arte("lumbre", f, {"viaje": 0.0, "color": Artes.COLOR_ESTADO["brasa"]})
	_numero_flotante(f, "¡%s se levanta!" % f["nombre"], Artes.COLOR_ESTADO["brasa"], 32, Vector2(-40, -50))
	menu.destacar_heroe(f, Artes.COLOR_ESTADO["brasa"])


# Sonidos nuevos (artes y accesorios): solo si ya están en el catálogo de sonido.gd. Mientras no estén, silencio (y
# sin el aviso de Sonido.efecto por un nombre que no conoce). La señal «sonido_pedido» sale siempre: con ella las pruebas
# comprueban que cada uno se pide una sola vez y en su momento, también antes de que exista el archivo.
signal sonido_pedido(nombre: String)
signal voz_pedida(quien: String, evento: String)   # las voces de los héroes (tanda 5), para las pruebas


# Una voz de héroe o enemigo (sonido.gd elige la familia por su nombre o su clave); la señal sale siempre.
func _voz(quien: Dictionary, evento: String) -> void:
	voz_pedida.emit(str(quien.get("nombre", "")), evento)
	Sonido.voz(quien, evento)


func _sonar(nombre: String) -> void:
	sonido_pedido.emit(nombre)
	if Sonido.EFECTOS.has(nombre):
		Sonido.efecto(nombre)


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
	return Formulas.dano_magia(quien, d)


# ¿Completó Lya «La savia que recuerda»? (su magia hace más al Guardián del Bosque; se mira una vez por combate)
var _lya_sabe_cache := -1


func _lya_sabe() -> bool:
	if _lya_sabe_cache < 0:
		_lya_sabe_cache = 1 if load("res://investigacion.gd").estado(Bosque.INVESTIGACION_VENTAJA) == "completada" else 0
	return _lya_sabe_cache == 1


func _aplicar_todos() -> void:
	_ocultar_menu()
	estado = "accion"
	var quien = actor
	var d: Dictionary = NIVELES_MAGIA[magia_sel][nivel_sel - 1]
	_gastar_pm(quien, d["coste"])
	_actualizar()
	registro.text = "%s lanza %s" % [quien["nombre"], d["nombre"]]
	var alcanzados: Array = enemigos.filter(func(e): return e["hp"] > 0)
	_mostrar_panel(alcanzados, "area")                # V11: a quién alcanza, mientras se lanza
	await _magia_grupal(quien, alcanzados, magia_sel, nivel_sel, _dano_magia(quien, d))
	_ocultar_panel()
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
		if n <= 0 and o.has("desc"):                 # los de la alquimia (fase 3), solo si se tienen
			continue
		var desc: String = o["desc"] if o.has("desc") else "Recupera %d %s a un aliado." % [o["cura"], o["que"]]
		var it := {"texto": nombre, "accion": _menu_objeto_aliado.bind(nombre), "apagado": n <= 0,
			"derecha": "×%d" % n, "desc": desc if n > 0 else "No te queda ninguno."}
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
	var que: String = OBJETOS_COMBATE[nombre]["que"]
	if que == "ENFOQUE":                              # a un aliado en pie que no lo tenga ya
		var conscientes := heroes.filter(func(h): return h["hp"] > 0 and int(h.get("enfoque_turnos", 0)) <= 0)
		if conscientes.is_empty():
			registro.text = "Nadie lo necesita ahora"
			return
		_pedir_objetivo(conscientes, func(f): _usar_objeto(nombre, f), _menu_pocion, "TOCA A UN ALIADO")
		return
	if que == "PV_TODOS":                             # el Bálsamo de Mirta (V10): a todos, sin elegir
		if heroes.filter(func(h): return h["hp"] > 0 and h["hp"] < h["hp_max"]).is_empty():
			registro.text = "Nadie lo necesita ahora"
			return
		_usar_objeto(nombre, actor)
		return
	if que == "PURIFICA":                             # sobre el Guardián del Bosque
		var guardianes := enemigos.filter(func(e): return e["hp"] > 0 and Bosque.es_guardian(e))
		if guardianes.is_empty():
			registro.text = "El elixir solo sirve contra el Guardián del Bosque."
			return
		_pedir_objetivo(guardianes, func(f): _usar_elixir(nombre, f), _menu_pocion, "TOCA AL GUARDIÁN")
		return
	var campo := "hp" if que == "PV" else "mp"
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
	if OBJETOS_COMBATE[nombre]["que"] == "PV_TODOS":   # Bálsamo de Mirta (V10): +45 PV a cada héroe en pie
		estado = "accion"
		var o_b: Dictionary = OBJETOS_COMBATE[nombre]
		registro.text = "%s usa %s" % [actor["nombre"], nombre]
		Sonido.efecto("pocion")
		for h in heroes:
			if h["hp"] <= 0:
				continue
			var cb: int = mini(int(o_b["cura"]), h["hp_max"] - h["hp"])
			h["hp"] += cb
			_efecto_cura(h)
			_numero_flotante(h, "+%d PV" % cb, C_CURA)
		_actualizar()
		await get_tree().create_timer(0.9).timeout
		for h in heroes:
			_restablecer_color(h)
		_terminar_turno()
		return
	if OBJETOS_COMBATE[nombre]["que"] == "ENFOQUE":    # Esencia de enfoque (fase 3)
		estado = "accion"
		quien["enfoque_turnos"] = Bosque.TURNOS_ENFOQUE
		quien["enfoque_nuevo"] = quien == actor        # el turno en que la toma no cuenta
		registro.text = "%s toma %s: su magia se afina" % [quien["nombre"], nombre] if quien == actor \
			else "%s da %s a %s: su magia se afina" % [actor["nombre"], nombre, quien["nombre"]]
		Sonido.efecto("pocion", {"tono": 1.2})
		_frasco(quien, OBJETOS_COMBATE[nombre])
		_luz(OBJETOS_COMBATE[nombre]["color"], 1.8, 4.0, 1.4, _centro(quien))
		_numero_flotante(quien, "¡Enfoque!", Color(0.8, 0.7, 1.0), 34)
		_actualizar()
		await get_tree().create_timer(0.9).timeout
		_terminar_turno()
		return
	if nombre == "Poción":
		pociones -= 1
	estado = "accion"
	var o: Dictionary = OBJETOS_COMBATE[nombre]
	var campo := "hp" if o["que"] == "PV" else "mp"
	var cura: int = min(o["cura"], quien[campo + "_max"] - quien[campo])
	quien[campo] += cura
	Sonido.efecto("pocion", {"tono": 1.0 if campo == "hp" else 1.12})   # el frasco (sonido.gd)
	if campo == "hp" and cura > 0:                     # su alivio, si la poción le cura PV (sonido.gd, tanda 5)
		_voz(quien, "alivio")
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


# Elixir de savia purificada (fase 3) sobre el Guardián: en su primera fase resbala (no se gasta y se vuelve al menú);
# en la segunda lo purifica: desenlace A, guardado en «decisiones» (combate_bosque.gd), y el combate termina en victoria.
func _usar_elixir(nombre: String, g: Dictionary) -> void:
	var motivo := Bosque.elixir_sobre(g)
	if motivo != "":
		registro.text = _texto_bosque(motivo, "La savia resbala por la corteza: aún está demasiado fuerte.") \
			if motivo == "elixir_fase1" else motivo
		_mostrar_menu()
		return
	if _cantidad_objeto(nombre) <= 0:
		return
	_ocultar_menu()
	estado = "accion"
	load("res://inventario.gd").gastar(nombre)
	Bosque.apuntar("purificado")
	g["purificado"] = true
	_marcar_aviso(g, false)
	g["cargando"] = false
	registro.text = _texto_bosque("purificacion", "La savia clara empapa sus raíces. El Guardián recuerda.")
	Sonido.efecto("pocion")
	Sonido.efecto("guardian_bosque_purificar")      # V9: cálido y luminoso; su bosque se calma (sonido.gd)
	_fogonazo(Color(0.75, 1.0, 0.6), 0.5, 1.2)
	_luz(Color(0.6, 1.0, 0.5), 2.4, 6.0, 2.0, _centro(g))
	_particulas(_centro(g) + Vector2(0, 120), Color(0.85, 1.0, 0.6, 1.0), Color(0.3, 0.9, 0.3, 0.0), 60, 2.0,
		Vector2(40, 140), 80.0, Vector2(0, -1), 40.0, Vector2(0, -40), 0.06)
	_onda(_suelo_de(g), Color(0.6, 1.0, 0.5, 0.9), 30.0, 260.0, 1.2, 10.0)
	var rig: Node2D = g["rig"]
	var t := create_tween()
	t.tween_property(rig, "modulate", Color(0.8, 1.3, 0.8, 0.0), 2.0)
	await t.finished
	g["hp"] = 0
	if g.has("sombra"):
		g["sombra"].visible = false
	g["lbl_hp"].visible = false
	_actualizar()
	await get_tree().create_timer(0.4).timeout
	if not _comprobar_fin():
		estado = "esperando"


# Textos cortos de la aventura del bosque (dialogos/notas/bosque.gd, de narrativa); si falta, el de aquí.
func _texto_bosque(clave: String, defecto: String) -> String:
	if ResourceLoader.exists("res://dialogos/notas/bosque.gd"):
		return str(load("res://dialogos/notas/bosque.gd").TEXTOS.get(clave, defecto))
	return defecto


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
	Sonido.efecto("defensa")                       # sonido.gd
	registro.text = "%s se pone en guardia" % quien["nombre"]
	quien["rig"].modulate = COLOR_DEFENSA
	_numero_flotante(quien, "Defensa", Color(0.7, 0.85, 1.0))
	await get_tree().create_timer(0.4).timeout
	_terminar_turno()


# Huir: en los combates normales siempre funciona (los jefes no lo permiten). No da experiencia.
func _escapar() -> void:
	_ocultar_menu()
	estado = "fin"
	Sonido.efecto("huida")                         # sonido.gd
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
	_ocultar_panel()
	estado = "accion"
	actor["atb"] = 0.0
	var pm_extra: int = Extra.pm_al_terminar(actor)            # Gota de la cascada alta (sin ella, 0)
	if pm_extra > 0:
		_numero_flotante(actor, "+%d PM" % pm_extra, Color(0.55, 1.0, 0.85), 30)
	if actor.get("enfoque_turnos", 0) > 0:        # Esencia de enfoque (fase 3): 3 turnos, sin contar el que la toma
		if actor.get("enfoque_nuevo", false):
			actor["enfoque_nuevo"] = false
		else:
			actor["enfoque_turnos"] -= 1
			if actor["enfoque_turnos"] <= 0:
				_numero_flotante(actor, "El enfoque se apaga", Color(0.8, 0.75, 0.95), 24)
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
# Con M3, a un héroe con coraza de Escarcha el golpe le llega primero a la coraza (artes.gd absorber): se ve, suena
# y, si se rompe, se rompe con su seña. Devuelve lo que llega a los PV (sin coraza, «d», como siempre).
func _quitar_pv(f: Dictionary, d: int) -> int:
	if f.get("hero", false) and int(f.get("barrera", 0)) > 0 and d > 0:
		var r: Dictionary = Artes.absorber(f, d)
		_coraza_golpeada(f, r)
		d = int(r["resto"])
	f["hp"] = maxi(0, f["hp"] - d)
	if f.get("hero", false) and f["hp"] <= 0 and Artes.al_llegar_a_cero(f):   # M4: con Brasa se levanta (una vez)
		_brasa_levanta(f)
	elif f.get("hero", false) and f["hp"] <= 0:         # la Guardia se acaba si cae Garon o el aliado que cubre
		_quitar_guardia(f["nombre"])
		f.erase("guardia_de")
	if not f.get("hero", false) and f["hp"] <= 0 and f.has("aviso_nodo"):
		_marcar_aviso(f, false)                       # cae con el golpe preparado: su señal de aviso, fuera
	if not f.get("hero", false) and f["hp"] <= 0 and f.has("puntos_nodo"):
		_marcar_puntos(f, false)                      # el Coloso cae expuesto: sus puntos débiles, fuera
	if f.get("fases", false) and not f.get("fase2", false) and f["hp"] > 0 and f["hp"] <= f["hp_max"] * 0.5:
		f["fase2"] = true
		f["fase2_pendiente"] = true
	if f.get("ultimo_aliento", false) and f["hp"] <= 0 and not f.get("decidido", false):
		f["hp"] = 1
		f["rendido"] = true
	if not f.get("hero", false) and d > 0:
		_vigilar_carga(f, d)                          # V11: un golpe preparado se puede interrumpir
	return d


# La coraza de un héroe recibe un golpe (M3): lo que absorbe sale en hielo («❄ 12») con su sonido; si se rompe, salta en
# esquirlas («¡Coraza rota!») con el suyo. Una vez por golpe, en el mismo instante en que se resuelve.
func _coraza_golpeada(f: Dictionary, r: Dictionary) -> void:
	if int(r.get("absorbido", 0)) <= 0:
		return
	_numero_flotante(f, "❄ %d" % int(r["absorbido"]), C_HIELO, 34, Vector2(-70, 10))
	if r.get("rota", false):
		_sonar(Artes.SONIDO_ESTADO["rota"])
		_sena_arte("escarcha_rota", f)
		if r.get("congela", false) and atacante_actual != null and atacante_actual["hp"] > 0:
			_congelar(atacante_actual)              # Invierno Guardián (M4): quien la rompe queda Congelado
		_numero_flotante(f, "¡Coraza rota!", C_HIELO, 28, Vector2(-40, -50))
	else:
		_sonar(Artes.SONIDO_ESTADO["absorbe"])
		_sena_arte("escarcha_golpe", f)


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
	if Bosque.es_guardian(f):                      # V9: su título y el tratamiento de su combate, atado a este (sonido.gd)
		Sonido.efecto("guardian_bosque_jefe", {"en": self})
	else:
		Sonido.efecto("jefe")                      # sonido.gd
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
	if Bosque.es_guardian(f):
		await _cambio_fase_bosque(f)
		return
	if Coloso.es_coloso(f):
		await _cambio_fase_coloso(f)
		return
	estado = "accion"
	registro.text = "¡%s se enfurece!" % f["nombre"]
	Sonido.efecto("fase2")                         # sonido.gd
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


# Segunda fase del Guardián del Bosque (fase 3): «El corazón del bosque». Destello verde, hojas, el escenario se tiñe de
# verde y aparece la coraza de raíces (golpes físicos a la mitad, débil al fuego: combate_bosque.gd). Más rápido.
func _cambio_fase_bosque(f: Dictionary) -> void:
	estado = "accion"
	registro.text = _texto_bosque("fase2", "¡El corazón del bosque despierta!")
	Sonido.efecto("guardian_bosque_fase2")         # V9: su rugido de corteza, en lugar de «fase2» (sonido.gd)
	_fogonazo(Color(0.55, 1.0, 0.45), 0.55, 0.8)
	_temblor(12.0)
	menu.vibrar(60)
	var modelo = _p3d(f)
	if modelo != null and modelo.has_method("fase2"):
		modelo.fase2()
	_numero_flotante(f, "¡CORAZA DE RAÍCES!", Color("9BE36B"), 40)
	_numero_flotante(f, "Débil al fuego", Color(1.0, 0.6, 0.3), 26, Vector2(0, 60))
	var verde := Color(0.78, 1.0, 0.78)
	if fondo_nodo != null:
		create_tween().tween_property(fondo_nodo, "modulate", verde, 1.2)
	create_tween().tween_property(escena, "modulate", tono_escena * Color(0.85, 1.0, 0.85), 1.2)
	var img = f["partes"].get("imagen", f["partes"].get("sprite"))
	if img != null:
		create_tween().tween_property(img, "modulate", Color(0.5, 0.85, 0.45), 0.8)
	f["brasas"] = _particulas(_centro(f) + Vector2(0, 80), Color(0.6, 1.0, 0.4, 0.9), Color(0.2, 0.6, 0.1, 0.0), 24, 1.8,
		Vector2(20, 70), 60.0, Vector2(0, -1), 40.0, Vector2(0, -30), 0.06, true)
	f["vel"] *= 1.3
	_musica_fase2()
	await get_tree().create_timer(1.6).timeout
	if estado == "accion":
		estado = "esperando"


# Segunda fase del Coloso de la Falla (V9): «Las runas despiertan». Destello ámbar, temblor, el escenario y el Coloso se
# tiñen de ámbar, chispas de las runas alrededor y la coraza rúnica puesta (la magia hace la mitad hasta su turno; luego
# alterna con la piel de piedra: combate_coloso.gd). Más rápido. Con su modelo 3D, su fase2().
func _cambio_fase_coloso(f: Dictionary) -> void:
	estado = "accion"
	registro.text = "¡Las runas del Coloso despiertan!"
	Sonido.efecto("fase2")
	_fogonazo(COLOR_RUNAS, 0.55, 0.8)
	_temblor(14.0)
	menu.vibrar(60)
	var modelo = _p3d(f)
	if modelo != null and modelo.has_method("fase2"):
		modelo.fase2()
	f["coraza_runica"] = true
	_numero_flotante(f, "¡LAS RUNAS DESPIERTAN!", COLOR_RUNAS, 40)
	_numero_flotante(f, "Coraza rúnica: la magia hace la mitad", COLOR_RUNAS.lightened(0.3), 26, Vector2(0, 60))
	if fondo_nodo != null:
		create_tween().tween_property(fondo_nodo, "modulate", Color(1.0, 0.86, 0.66), 1.2)
	create_tween().tween_property(escena, "modulate", tono_escena * Color(1.0, 0.9, 0.78), 1.2)
	var img = f["partes"].get("imagen", f["partes"].get("sprite"))
	if img != null and modelo == null:
		create_tween().tween_property(img, "modulate", TINTE_CORAZA, 0.8)
	f["brasas"] = _particulas(_centro(f) + Vector2(0, 80), Color(1.0, 0.75, 0.35, 0.9), Color(1.0, 0.45, 0.1, 0.0), 24, 1.6,
		Vector2(20, 70), 70.0, Vector2(0, -1), 30.0, Vector2(0, -40), 0.06, true)
	f["vel"] *= 1.25
	_musica_fase2()
	_actualizar()
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
	Sonido.voz(f, "caida")                         # se queja y las rodillas golpean el suelo (sonido.gd, T-083)
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
	Sonido.golpe(true)                             # sonido.gd
	_destello(_centro(f), Color(1.0, 0.9, 0.7), 2.0)
	_temblor(10.0)
	f["hp"] = 0
	Sonido.voz(f, "muerte")                        # su último aliento (sonido.gd, T-083)
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
# V11: INVOCACIÓN abre antes la lista de invocaciones (hoy, solo Érebo) con su emblema, su coste (la Armonía llena), lo
# que hace, quién la invoca y si se puede ahora; al elegirla se toca al enemigo, como siempre. Las reglas no cambian.
func _invocar() -> void:
	var inv := _estado_invocacion()
	_limpiar_objetivo()
	estado = "invocacion"                           # «atrás» vuelve al menú, como en Magia
	menu.submenu([{"texto": "Érebo", "icono": "Erebo", "derecha": "100 %", "accion": _invocar_objetivo,
		"apagado": not inv["lista"], "motivo": inv["motivo"],
		"desc": "%s: %s Coste: la Armonía llena; la invoca Lya." % [INVOCACION["nombre"], INVOCACION["desc"]]}])


func _invocar_objetivo() -> void:
	_pedir_objetivo(enemigos.filter(func(e): return e["hp"] > 0), _invocar_sobre, _invocar, "TOCA UN ENEMIGO")


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

	# T-101: la invocación nueva si se ha elegido en Ajustes (invocacion_erebo_nueva.gd); si no, la de siempre.
	var nueva: bool = ResourceLoader.exists("res://invocacion_erebo_nueva.gd") and load("res://invocacion_erebo_nueva.gd").elegida()
	var inv = load("res://invocacion_erebo_nueva.gd" if nueva else "res://invocacion_erebo.gd").new()
	mundo.add_child(inv)
	inv.ajustes.calidad = "movil" if movil else "alta"
	inv.evento.connect(_evento_erebo.bind(titulo))
	var ctx := {"invocador": lya, "objetivo": doble, "es_jefe": es_jefe, "camara": cam,
		"al_resultado": _resultado_erebo.bind(doble, al_resultado)}
	if nueva:                                      # Kael mira (y reacciona) si está en pie
		ctx["kael"] = heroes.any(func(h): return h["nombre"] == "Kael" and h["hp"] > 0)
	for a in OS.get_cmdline_user_args():           # pruebas: -- erebo=exito / erebo=fallo
		if a.begins_with("erebo="):
			ctx["forzar"] = a.substr(6)
	inv_erebo = inv
	# Se espera a «terminada» (la emiten las dos: al acabar y al saltar, una vez) y no a que acabe lanzar(): al saltar en
	# medio de una espera (el aplastamiento del orbe, Érebo surgiendo), limpiar() mata el tween que la coreografía
	# esperaba y esa corrutina ya no vuelve; el combate no debe quedarse esperándola (prueba_erebo_saltar).
	inv.lanzar(ctx)
	await inv.terminada
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
	if not is_instance_valid(doble) or ("anim" in doble and doble.get("anim") == null):
		return                                       # el doble aún no tiene su modelo (se ha saltado muy pronto)
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


const ALTO_DOBLE := {"slime": 0.95, "guardian": 1.9, "gorthor": 2.5, "hollin": 1.6, "coloso_falla2d": 2.7}


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
	var critico: bool = magia == "" and randf() < Extra.prob_critico(PROB_CRITICO, origen.get("efectos", {}))   # Diente: la misma tirada
	if critico:
		dano = int(dano * MULT_CRITICO)
	if magia == "" and objetivo["hero"]:              # la defensa del héroe resta daño a los golpes
		dano = max(1, dano - int(objetivo.get("def", 0) / 2.0))
	if objetivo.get("defendiendo", false):
		dano = max(1, int(dano * 0.5))
	if not objetivo["hero"]:                          # fase 3: el Guardián del Bosque y la Esencia de enfoque
		dano = Bosque.dano_recibido(dano, magia, origen, objetivo, _lya_sabe())
		dano = Coloso.dano_recibido(dano, magia, origen, objetivo)   # V9: el Coloso (piel, ventana, coraza rúnica)
	var congela: bool = magia == "" and origen["hero"] and _lleva_frostfang(origen) and randf() < PROB_CONGELAR
	# Pluma de arpía: un héroe esquiva un golpe físico (solo tira el dado con la pluma puesta: sin ella, nada cambia)
	var esquiva: bool = magia == "" and objetivo["hero"] and Extra.esquiva(objetivo.get("efectos", {}))
	ultimo_esquivado = esquiva
	var embuido: bool = magia == "" and origen.get("embuir", "") != ""    # Garon con Embuir: +20 % y su elemento
	if embuido:
		dano = int(dano * (1.0 + EMBUIR["extra"]))
	var impacto: Callable = func():
		if esquiva:                                    # el golpe no llega: ni daño, ni golpe, ni voz de dolor
			_sonar("esquiva")
			_numero_flotante(objetivo, "¡Esquiva!", Color(0.85, 0.95, 1.0), 34)
			return
		if magia == "":                                # golpe físico resuelto: su sonido, una vez (sonido.gd, T-083)
			Sonido.golpe(critico, objetivo.get("defendiendo", false))
			if origen.get("devora", false):
				Sonido.voz(origen, "devorar")              # el mordisco de Gorthor
		golpe_magico = magia != "" or origen.get("filo_arcano", false)
		var real: int = _quitar_pv(objetivo, dano)     # lo que llega a los PV (con coraza de Escarcha, menos; M3)
		golpe_magico = false
		origen["absorbido"] = dano - real              # lo que paró la coraza (el mordisco de Gorthor no se cura con eso)
		if magia == "":
			Sonido.recibe(objetivo)                    # la voz del enemigo golpeado: herido o caída (sonido.gd)
		if embuido:
			_golpe_visual(objetivo, real, _efecto_embuir(origen, objetivo), critico)
		else:
			_golpe_visual(objetivo, real, magia, critico)
		if congela and objetivo["hp"] > 0:
			_congelar(objetivo)
		if magia == "" and origen.get("hero", false):  # C2, Fauces de Gorthor: se cura parte de lo que hace (sin ellas, 0)
			var robo: int = Extra.robo_vida(origen, real)
			if robo > 0:
				_numero_flotante(origen, "+%d" % robo, C_CURA, 34)
		if magia == "" and objetivo.get("hero", false) and not origen.get("hero", false) and origen["hp"] > 0:
			var rep: int = Extra.replica(objetivo, objetivo.get("defendiendo", false))   # C2, Guardiana de Ámbar
			if rep > 0:
				_numero_flotante(objetivo, "Réplica", Color("FFC46A"), 28, Vector2(-30, -40))
				_golpe_visual(origen, _quitar_pv(origen, Coloso.dano_recibido(rep, "", objetivo, origen)), "")
	if magia != "" and _p3d(origen) != null:
		await _anim_magia_3d(origen, objetivo, magia, impacto)
	elif magia != "":
		await _anim_magia(origen, objetivo, magia, impacto)
	elif _p3d(origen) != null and _p3d(origen).has_method("avisar"):           # Zarzalín (T-097)
		await _anim_zarzalin(origen, objetivo, impacto, str(origen.get("ataque_3d", "colmillo_lateral")))
	elif _p3d(origen) != null and _p3d(origen).has_method("despertar"):        # Guardián del Bosque (fase 3): desde su sitio
		await _anim_guardian(origen, impacto, str(origen.get("ataque_3d", "ataque")))
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
	Sonido.voz(o, "ataque")                          # se estira para lanzarse (sonido.gd, T-083)
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
	_voz(o, "ataque")                                # su esfuerzo al golpear (sonido.gd, tanda 5)
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
	Sonido.efecto("salto")                         # el sable sube con el salto (sonido.gd)
	_voz(o, "ataque")                              # su esfuerzo al saltar (sonido.gd, tanda 5)
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
	var en_guardia: bool = p.has_method("avanzar") and p.has_method("retroceder")   # Garon: pasos de doble espada
	if en_guardia:
		p.avanzar()
	else:
		p.correr()
	var t1 := create_tween()
	t1.tween_property(rig, "position", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	Sonido.voz(o, "ataque")                            # el enemigo se lanza: su voz (sonido.gd; los héroes, nada)
	var golpes := [0]
	var al_golpear := func():
		golpes[0] += 1
		if golpes[0] == 1 or metodo == "atacar_giro":   # el Giro golpea en cada vuelta
			impacto.call()
			if metodo == "golpe_fuerte" or metodo == "atacar_juicio":
				_temblor(9.0)
		else:
			_temblor(4.0)
			# el segundo tajo del doble ataque no hace daño, pero se ve: suena, 6 dB más bajo (sonido.gd, T-083)
			Sonido.golpe(false, obj.get("defendiendo", false), -6.0)
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
	if en_guardia:                                     # vuelve de espaldas, sin perder de vista al enemigo
		p.retroceder()
	else:
		p.mirar(-ida, 0.2)
		p.correr()
	var t3 := create_tween()
	t3.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	p.mirar_frente(0.25)
	p.reposo()
	rig.z_index = 0
	o["animando"] = false


# Sonidos de una bestia del bestiario (sonido.gd, tanda 4, «Cómo pedirlos»), por su clave y con las señales de su
# modelo: el aviso al bajar el hocico, cada golpe de pezuña y el impacto (en el mismo instante en que se resuelve el
# daño, junto al Sonido.golpe de siempre). Su voz de herido o caída la da Sonido.recibe por su «clave».
func _sonidos_bestia(e: Dictionary, p) -> void:
	var clave := str(e.get("clave", ""))
	if p.has_signal("aviso"):
		p.aviso.connect(func(a: String): _sonar("%s_aviso_%s" % [clave, a.get_slice("_", 0)]))
	if p.has_signal("pezuna"):
		p.pezuna.connect(func(_n: int): _sonar(clave + "_pezuna"))
	if p.has_signal("impacto"):
		p.impacto.connect(func(a: String): _sonar("%s_%s" % [clave, a.get_slice("_", 0)]))


# Zarzalín ataca (T-097): galopa hasta el héroe, se planta donde sus colmillos llegan a él en el impacto del clip
# (propuesta de animaciones: los pies a centro − 30 − 0,632·px_m − alcance·px_m, y a la altura de los pies del objetivo),
# y atacar(ataque, al_golpear) llama al golpe UNA vez en su ancla. Durante el clip el rig no se mueve (el clip lleva el
# avance). Vuelve galopando y queda en reposo. Desde la carga (avisar), la embestida entra sin repetir la preparación.
# El Guardián del Bosque (fase 3; enemigos/guardian_bosque/guardian_bosque_3d.gd, de animaciones) ataca desde su sitio: su
# rama llega 2,27 m por delante y las raíces del golpe fuerte brotan a 1,7 m. El impacto, una vez, en el momento del clip.
func _anim_guardian(o: Dictionary, impacto: Callable, ataque: String) -> void:
	var p = _p3d(o)
	_voz(o, "ataque")                                # V9: la madera cruje al alzar la rama (sonido.gd, «corteza»)
	o["animando"] = true
	var golpes := [0]
	var al_golpear := func():
		golpes[0] += 1
		if golpes[0] == 1:
			impacto.call()
			if ataque == "golpe_fuerte":
				_temblor(9.0)
	await p.atacar(ataque, al_golpear)
	if golpes[0] == 0:
		al_golpear.call()
	o["animando"] = false


func _anim_zarzalin(o: Dictionary, obj: Dictionary, impacto: Callable, ataque: String) -> void:
	var p = _p3d(o)
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var m: Dictionary = MODELOS[o["modelo"]]
	var px_m: float = m["vp"].y / m["alto_vista"] * m["esc"]
	var alcance: float = p.alcance(ataque) if p.has_method("alcance") else 0.0
	var pies_x: float = _centro(obj).x - 30.0 - 0.632 * px_m - alcance * px_m
	var destino := base + Vector2(pies_x - _suelo_de(o).x, _suelo_de(obj).y - _suelo_de(o).y)
	var ida := Vector3(1, 0, 0.1)
	o["animando"] = true
	rig.z_index = 5
	p.mirar(ida, 0.15)
	p.correr()                                        # galopa (tras el aviso sigue «en carga»: la embestida no repite la preparación)
	var t1 := create_tween()
	t1.tween_property(rig, "position", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	p.mirar(ida, 0.1)
	if ataque == "colmillo_lateral":                 # las bestias no tienen voz de «ataque»: su aviso hace ese papel
		_sonar(str(o.get("clave", "")) + "_aviso_colmillo")   # (la embestida avisa con la señal «aviso», un turno antes)
	var golpes := [0]
	var al_golpear := func():
		golpes[0] += 1
		if golpes[0] == 1:
			impacto.call()
			if ataque == "embestida_espinosa":
				_temblor(9.0)
	await p.atacar(ataque, al_golpear)
	if golpes[0] == 0:                                 # sin el clip (o cortado): el golpe igualmente, una vez
		al_golpear.call()
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
	Sonido.voz(o, "ataque")                          # un enemigo de los de antes (Hollín): su voz (sonido.gd)
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
			if critico and dano > 0:
				_destello(centro, Color(1.0, 0.85, 0.4), 1.8)
				_numero_flotante(objetivo, "¡%d!" % dano, C_DANO, 58)
				registro.text = "¡Golpe crítico!"
				_temblor(10.0)
			elif dano > 0:
				_destello(centro, Color(1.0, 0.95, 0.85), 1.0)
				_numero_flotante(objetivo, str(dano), Color.WHITE)
				_temblor(3.0)
			else:                                      # todo lo paró la coraza de Escarcha (M3): ya lo dice «❄»
				_temblor(2.0)
			rig.modulate = Color(1.6, 0.3, 0.3) if dano > 0 else Color(0.8, 0.95, 1.45)   # parado entero: frío, no rojo
	_actualizar()
	if objetivo["hp"] > 0 and not objetivo["animando"] and dano > 0:   # parado entero por la coraza: sin dolor
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
	var color: Color = MAGIAS[magia]["color"] if MAGIAS.has(magia) else Artes.COLOR[magia]   # las artes, su color
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
		if not obj.get("hero", false):               # fase 3: el Guardián del Bosque y la Esencia de enfoque
			d = Bosque.dano_recibido(d, magia, o, obj, _lya_sabe())
			d = Coloso.dano_recibido(d, magia, o, obj)   # V9: el Coloso (coraza rúnica)
		golpe_magico = true
		_quitar_pv(obj, d)
		golpe_magico = false
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
	rng.seed = randi()                             # C0: sale de la semilla del combate (en el juego, igual de al azar)
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
	rng.seed = randi()                             # C0: sale de la semilla del combate (en el juego, igual de al azar)
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
	if f["hp"] <= 0 and Bosque.es_guardian(f) and not f.get("purificado", false) and not f.get("derrumbe", false):
		f["derrumbe"] = true                           # V9: el Guardián se desmorona, una vez (no si se purifica; sonido.gd)
		_sonar("guardian_bosque_derrumbe")
	var rig: Node2D = f["rig"]
	if _p3d(f) != null:
		if f["hp"] > 0:
			rig.modulate = COLOR_DEFENSA if f.get("defendiendo", false) else Color(1, 1, 1)
			_p3d(f).cansada(f["hp"] < f["hp_max"] * 0.3)
		else:
			f["defendiendo"] = false
			rig.modulate = Color(0.6, 0.6, 0.68)
			if not f["hero"] and _p3d(f).has_method("avisar") and not f.get("derrumbe", false):
				f["derrumbe"] = true                   # una bestia: su derrumbe, una vez, al empezar la derrota
				_sonar(str(f.get("clave", "")) + "_derrumbe")
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


func _numero_flotante(f: Dictionary, texto: String, color: Color, tam := TAM_NUMERO, desvio := Vector2.ZERO) -> void:
	var l := _etiqueta(texto, tam, color)
	l.add_theme_constant_override("outline_size", 8)
	if f.has("centro_ofs"):                       # personajes 3D: encima del cuerpo
		l.position = _a_pantalla(_centro(f) + Vector2(-28, -115))
	else:
		l.position = _a_pantalla(f["pos"] + Vector2(100, _alto_barra(f))) + Vector2(0, 50)
	l.position += desvio                          # dos textos a la vez sobre el mismo (la Lumbre: «+42» y «¡Kael vuelve!»)
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
		Sonido.efecto("victoria" if ganan else "derrota")   # sonido.gd
		if ganan:                                      # el gesto de uno de los que siguen en pie (tanda 5)
			voz_pedida.emit("", "victoria")
			Sonido.victoria_heroes(heroes)
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


# Recompensas especiales de los combates fijos (C2 y M3; decisión del coordinador del 09/11): la primera victoria las da,
# una vez. Contra Gorthor, las Fauces, se le perdone o no.
const RECOMPENSA_FIJO := {"garganta_gorthor": "fauces_gorthor", "garganta_nido": "lagrima_ambar"}


# Premio del Guardián del Bosque, una sola vez (el combate fijo queda ganado). Si no se purificó, es que se derrotó.
#   purificado: el Brote del Guardián (accesorio, magia natural) y dos Savias claras.
#   derrotado: el Corazón de roble (material, se vende caro) y la Corteza del Guardián (accesorio, coraza al empezar).
func _premio_bosque() -> String:
	if Bosque.desenlace() == "":
		Bosque.apuntar("derrotado")
	var P = load("res://progreso.gd")
	P.poner_hito("bq_resuelto")
	P.poner_hito("bq_" + Bosque.desenlace())        # bq_purificado o bq_derrotado: Oakhaven reacciona (ciudades/oakhaven.gd)
	var Inv = load("res://inventario.gd")
	var textos: Array = []
	if Bosque.desenlace() == "purificado":
		textos.append(Extra.conseguir("brote_guardian"))
		Inv.agregar_objeto("Savia clara", 2)
		textos.append("+2 Savia clara")
	else:
		Inv.agregar_objeto("Corazón de roble", 1)
		textos.append("+1 Corazón de roble")
		textos.append(Extra.conseguir("corteza_guardian"))
	return "  ".join(textos.filter(func(t): return t != ""))


func _fin_combate(ganan: bool) -> void:
	var aviso := ""
	if ganan and combate_fijo != "":
		var g: Dictionary = Engine.get_meta("combates_ganados", {})
		if not g.get(combate_fijo, false) and combate_fijo == Bosque.COMBATE:   # el Guardián del Bosque (fase 3)
			aviso = _premio_bosque()
		elif not g.get(combate_fijo, false) and combate_fijo == Coloso.COMBATE:  # el Coloso de la Falla (V9), una vez
			aviso = Coloso.dar_premio()
		elif not g.get(combate_fijo, false) and RECOMPENSA_FIJO.has(combate_fijo) and Extra.disponible(RECOMPENSA_FIJO[combate_fijo]):
			aviso = Extra.conseguir(RECOMPENSA_FIJO[combate_fijo])
		g[combate_fijo] = true
		Engine.set_meta("combates_ganados", g)
	if ganan:                                      # las investigaciones de Lya en curso avanzan (fase 3)
		load("res://investigacion.gd").avanzar_en_curso()
		# V11: los caídos cuentan para los contratos del gremio aceptados (gremio.gd; sin contratos, nada)
		load("res://gremio.gd").contar_derrotas(enemigos.filter(func(e): return e["hp"] <= 0).map(func(e): return e["clave"]))
	await _repartir_exp(ganan)
	if aviso != "":
		registro.text = aviso
		Sonido.efecto("ui_equipar_arma" if aviso.contains("Fauces") else "ui_equipar")
		await get_tree().create_timer(1.2).timeout
	_volver_al_mapa()


# Al ganar, cada héroe en pie gana la experiencia de todos los enemigos y puede subir de nivel.
# La vida que quede se guarda para el siguiente combate (al perder, el grupo vuelve con la vida llena).
func _repartir_exp(ganan: bool) -> void:
	if not ResourceLoader.exists("res://grupo.gd"):
		return
	var gr = load("res://grupo.gd")
	var dan: Dictionary = Recompensas.de_enemigos(enemigos)   # los que huyen no dan nada
	var total: int = dan["exp"]
	var oro: int = dan["oro"]
	for h in heroes:
		if gr.datos().has(h["nombre"]):
			gr.guardar_vida(h["nombre"], h["hp"], h["mp"])
	if not ganan:
		gr.curar_todos()
		return
	await get_tree().create_timer(1.0).timeout
	var mult: float = load("res://progreso.gd").mult_exp(Engine.get_meta("zona", "llanura"),
		Engine.get_meta("tipo_combate", "normal"), load("res://progreso.gd").nivel_grupo())
	oro = Extra.oro_con_extra(oro, heroes.map(func(h): return h.get("efectos", {})))   # Moneda del Águila, una vez
	registro.text = "+%d EXP   +%d monedas" % [int(round(total * mult)), oro]
	if oro > 0:
		Sonido.efecto("monedas")                   # sonido.gd
	if ResourceLoader.exists("res://inventario.gd"):
		load("res://inventario.gd").ganar_oro(oro)
		var botin: Array = Extra.botin_de(enemigos)    # las bestias dejan su material (Zarzalín: Corteza espinosa)
		for b in botin:
			load("res://inventario.gd").agregar_objeto(b)
		if not botin.is_empty():
			registro.text += "   +" + ", ".join(botin)
	# progreso.gd: más experiencia si van por debajo del nivel de la zona, muy poca si van 5 por encima;
	# los jefes dan mucho. Todos suben: los caídos ganan la mitad.
	var Progreso = load("res://progreso.gd")
	var zona: String = Engine.get_meta("zona", "llanura")
	var tipo: String = Engine.get_meta("tipo_combate", "normal")
	for h in heroes:
		if not gr.datos().has(h["nombre"]):
			continue
		var mult_h: float = Progreso.mult_exp(zona, tipo, gr.datos()[h["nombre"]]["nivel"])
		if h["hp"] <= 0:
			gr.ganar_exp(h["nombre"], Recompensas.exp_de_heroe(total, mult_h, true))
			continue
		var cantidad: int = Recompensas.exp_de_heroe(total, mult_h, false)
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
			Sonido.efecto("nivel")                     # sonido.gd
			_numero_flotante(h, "¡Nivel %d!" % nivel, Color(1.0, 0.9, 0.3), 40)
			_particulas(_centro(h) + Vector2(0, 80), Color(1.0, 0.95, 0.5, 1.0), Color(1.0, 0.8, 0.2, 0.0), 50, 1.2,
				Vector2(60, 160), 70.0, Vector2(0, -1), 25.0, Vector2(0, -60), 0.08)
			for k in NIVELES_MAGIA:                # magias nuevas
				var nm: int = gr.nivel_magia(h["nombre"], k)
				if nm > 0 and gr.NIVEL_MAGIA[nm - 1] > nivel - subidos:
					await get_tree().create_timer(1.0).timeout
					registro.text = "%s aprende %s" % [h["nombre"], NIVELES_MAGIA[k][nm - 1]["nombre"]]
			for x in Artes.nuevas_al_subir(h["nombre"], gr.datos()[h["nombre"]], nivel - subidos, nivel):   # artes
				await get_tree().create_timer(1.0).timeout
				registro.text = "%s aprende %s" % [h["nombre"], Artes.datos(x[0], x[1])["nombre"]]
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
	menu.poner_invocacion(_estado_invocacion())      # Érebo en el HUD (T-101): si se puede invocar y, si no, por qué
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
			if Coloso.es_coloso(e):                     # V9: piel de piedra, coraza rúnica, expuesto, runas leídas
				estados.append_array(Coloso.estados(e))
			e["lbl_estado"].text = "  ".join(estados)
			e["lbl_estado"].visible = vivo
