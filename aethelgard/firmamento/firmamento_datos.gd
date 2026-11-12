extends RefCounted
# Firmamento de los Ecos (V12, 12/11): CONFIGURACIÓN EDITABLE del tablero de Orbes Cristalinos. PROTOTIPO APAGADO
# (interruptor «orbes_v12», firmamento/orbes.gd). Nada de aquí está aprobado: precios y valores son PROVISIONALES y se
# cambian editando este archivo (no hace falta tocar el código). Diseño: docs/v12/FIRMAMENTO_DE_LOS_ECOS.md.
#
# Por qué un .gd y no un JSON: los presets de Android solo exportan recursos; un .json quedaría fuera del APK sin tocar
# export_presets.cfg (compartido). Un .gd con constantes se lee igual de fácil y siempre va dentro.
#
# CÓMO SE LEE UN NODO
#   "id":      clave única dentro del tablero del héroe (se guarda en la partida: no la cambies una vez publicada).
#   "nombre":  lo que se lee en el panel (corto: cabe en 22 caracteres a 26 px).
#   "rango":   basica | intermedia | avanzada | excepcional  → precio en PRECIOS y forma del nodo en el tablero.
#   "pos":     [ángulo en grados (0 = arriba, sentido de las agujas del reloj), radio en unidades del tablero].
#   "req":     ids que lo abren. Sin «todos», basta UNO de ellos desbloqueado; con "todos": true, hacen falta TODOS.
#              Vacío: cuelga del símbolo del centro (el nodo inicial).
#   "bonos":   lo que da. Tres familias (orbes.gd las separa):
#              - atributos de grupo.gd (fuerza, magia, defensa, velocidad, vitalidad, espiritu): se suman en
#                grupo.estadisticas() a los atributos FINALES (nunca a los guardados) → PV, PM, ataque, defensa,
#                multiplicador de magia y velocidad del ATB salen de las fórmulas de siempre;
#              - "ataque" y "magia_extra": lo mismo que suma un arma o un cetro (grupo.gd);
#              - efectos de equipo_extra.gd EFECTOS (critico, atb_inicio, esquiva, pm_turno, regen, barrera_inicio,
#                contra_defendiendo, cubrir, aliento_inicio, apoyo_turnos, robo_vida...): se suman en efectos_de()
#                con el MISMO TOPE que el equipo. Un efecto que no exista en EFECTOS o cuyo gancho no esté en HECHOS
#                deja el nodo DORMIDO: se ve, se explica, pero no se puede comprar (no hay trampa: no hace nada aún).
#   "glifo":   dibujo del centro del nodo (firmamento_lienzo.gd): espada, escudo, ala, corazon, gota, espiral, ojo,
#              estrella, runa, llama, raiz, mano, luna.
#   "texto":   una línea de ambiente (sin narrativa nueva: nada que revele historia).
#
# CALIBRACIÓN (revisada con las fórmulas reales el 12/11, grupo.gd y combate.gd):
#   - Un nivel da 3 puntos de atributo, +6 PV y +2 PM (grupo.gd PUNTOS_POR_NIVEL y estadisticas()); nivel máx. 50.
#   - 1 fuerza = +1 ataque; 1 vitalidad = +8 PV; 1 espíritu = +3 PM; 1 magia = +2,5 % de daño mágico; 2 defensa = -1
#     daño por golpe físico; velocidad llena antes la barra ATB.
#   - Básica (1 orbe): 2 puntos (2/3 de un nivel). Intermedia (3): 3 puntos o una pasiva pequeña. Avanzada (6): una
#     pasiva o 4-5 puntos (≈ 1,5 niveles). Excepcional (10): pasiva propia + algo de atributo (≈ 2-3 niveles).
#   - Tablero completo de un héroe: unos 30-34 puntos de atributo equivalentes (≈ 10-11 niveles de puntos, sin la
#     vida por nivel) y 74 orbes. Ningún nodo pasa de unos 3 niveles.
#   - Los topes de EFECTOS se comparten con el equipo: con el Diente de Grimfang (+8 %) y todo el tablero de Kael
#     (+15 %) el crítico queda en 0,12 + 0,23 = 35 %, por debajo del tope de +30 % del equipo extra.

const PRECIOS := {"basica": 1, "intermedia": 3, "avanzada": 6, "excepcional": 10}
const NOMBRE_RANGO := {"basica": "Básica", "intermedia": "Intermedia", "avanzada": "Avanzada",
	"excepcional": "Excepcional"}

# Cómo se nombra cada bono en el panel (antes → después). Los atributos usan grupo.gd NOMBRES.
const NOMBRE_BONO := {"ataque": "Ataque", "magia_extra": "Daño mágico", "critico": "Crítico",
	"atb_inicio": "Barra al empezar", "esquiva": "Esquiva", "pm_turno": "PM por turno", "regen": "Vida por turno",
	"barrera_inicio": "Coraza al empezar", "contra_defendiendo": "Réplica en guardia", "cubrir": "Cubrir aliados",
	"aliento_inicio": "Aliento al empezar", "apoyo_turnos": "Aliento más largo", "robo_vida": "Robo de vida",
	"res_magica": "Resistencia mágica", "res_elemental": "Resistencia elemental",
	"fuerza": "Fuerza", "magia": "Magia", "defensa": "Defensa", "velocidad": "Velocidad", "vitalidad": "Vitalidad",
	"espiritu": "Espíritu"}
# Bonos que se leen en porcentaje.
const PORCENTAJE := ["critico", "esquiva", "regen", "barrera_inicio", "cubrir", "robo_vida", "res_magica"]

# Color de cada héroe en el tablero (el de menu_combate.gd COLOR_HEROE, aclarado para que brille sobre el fondo).
const COLOR := {"Kael": Color("8FD3FF"), "Lya": Color("F2D27A"), "Garon": Color("FF8A6A"), "Naira": Color("B48CFF")}
# Símbolo del centro (firmamento_lienzo.gd lo dibuja con líneas, sin texturas).
const SIMBOLO := {"Kael": "espada_estrella", "Lya": "caliz_luna", "Garon": "escudo_torre", "Naira": "eclipse"}
const CAMINOS := {
	"Kael": ["Filo (ataque y crítico)", "Viento (agilidad y esquiva)", "Memoria (aguante y chispa)"],
	"Lya": ["Marea (poder mágico)", "Amparo (apoyo y defensa mágica)", "Memoria (reserva de magia)"],
	"Garon": ["Muralla (defensa y proteger)", "Raíz (vida y resistencia)", "Memoria (fuerza y aguante)"],
	"Naira": ["Provisional"],
}
# Retrato del panel (los de los diálogos; se cargan solo con el tablero abierto).
const RETRATO := {"Kael": "res://dialogos/retratos/kael_reposo.png", "Lya": "res://dialogos/retratos/lya_reposo.png",
	"Garon": "res://dialogos/retratos/garon_reposo.png", "Naira": "res://personajes/naira/naira_retrato_provisional.png"}

const TABLEROS := {
	# ------------------------------------------------------------------ KAEL: ataque físico, agilidad, crítico, espada
	"Kael": [
		{"id": "k_inicio", "nombre": "Primer destello", "rango": "basica", "pos": [0, 100], "req": [],
			"bonos": {"fuerza": 1, "velocidad": 1}, "glifo": "estrella",
			"texto": "La primera luz que despierta en el cristal."},
		# Filo (derecha): ataque y crítico
		{"id": "k_filo1", "nombre": "Filo templado", "rango": "basica", "pos": [40, 190], "req": ["k_inicio"],
			"bonos": {"fuerza": 2}, "glifo": "espada", "texto": "El acero recuerda cada golpe bien dado."},
		{"id": "k_filo2", "nombre": "Hoja despierta", "rango": "basica", "pos": [75, 215], "req": ["k_filo1"],
			"bonos": {"fuerza": 2}, "glifo": "espada", "texto": "Un brillo frío recorre la hoja."},
		{"id": "k_crit1", "nombre": "Ojo del corte", "rango": "intermedia", "pos": [35, 300], "req": ["k_filo1"],
			"bonos": {"critico": 0.04}, "glifo": "ojo", "texto": "Ver la grieta antes de que exista."},
		{"id": "k_filo3", "nombre": "Peso del acero", "rango": "intermedia", "pos": [95, 300], "req": ["k_filo2"],
			"bonos": {"ataque": 3}, "glifo": "espada", "texto": "La hoja cae con todo su peso."},
		{"id": "k_crit2", "nombre": "Estrella fugaz", "rango": "avanzada", "pos": [25, 400], "req": ["k_crit1"],
			"bonos": {"critico": 0.06}, "glifo": "ojo", "texto": "Un tajo que dura lo que un parpadeo."},
		{"id": "k_tec1", "nombre": "Guardia que responde", "rango": "avanzada", "pos": [62, 380],
			"req": ["k_crit1", "k_filo3"], "bonos": {"contra_defendiendo": 0.3}, "glifo": "escudo",
			"texto": "En guardia, la espada devuelve el golpe."},
		{"id": "k_filo4", "nombre": "Pulso de la hoja", "rango": "basica", "pos": [115, 390], "req": ["k_filo3"],
			"bonos": {"fuerza": 2}, "glifo": "espada", "texto": "El brazo y la hoja laten a la vez."},
		{"id": "k_exc_filo", "nombre": "Filo del Eco", "rango": "excepcional", "pos": [45, 480],
			"req": ["k_crit2", "k_tec1"], "todos": true, "bonos": {"critico": 0.05, "ataque": 5}, "glifo": "estrella",
			"texto": "Cada golpe resuena dos veces en el cristal."},
		# Viento (izquierda): agilidad y esquiva
		{"id": "k_vie1", "nombre": "Paso ligero", "rango": "basica", "pos": [-40, 190], "req": ["k_inicio"],
			"bonos": {"velocidad": 2}, "glifo": "ala", "texto": "Los pies apenas tocan el suelo."},
		{"id": "k_vie2", "nombre": "Aliento firme", "rango": "basica", "pos": [-75, 215], "req": ["k_vie1"],
			"bonos": {"vitalidad": 2}, "glifo": "corazon", "texto": "Respirar hondo entre dos golpes."},
		{"id": "k_vie3", "nombre": "Primer movimiento", "rango": "intermedia", "pos": [-35, 300], "req": ["k_vie1"],
			"bonos": {"atb_inicio": 15.0}, "glifo": "ala", "texto": "Moverse antes de que el otro piense."},
		{"id": "k_vie4", "nombre": "Sombra que se aparta", "rango": "intermedia", "pos": [-95, 300],
			"req": ["k_vie2"], "bonos": {"esquiva": 0.05}, "glifo": "luna", "texto": "El golpe corta el aire."},
		{"id": "k_vie5", "nombre": "Ráfaga", "rango": "avanzada", "pos": [-25, 400], "req": ["k_vie3"],
			"bonos": {"velocidad": 3, "esquiva": 0.03}, "glifo": "ala", "texto": "Viento que no se deja atrapar."},
		{"id": "k_vie6", "nombre": "Raíz del viento", "rango": "avanzada", "pos": [-62, 380],
			"req": ["k_vie3", "k_vie4"], "bonos": {"vitalidad": 3, "defensa": 2}, "glifo": "corazon",
			"texto": "Hasta el viento necesita dónde apoyarse."},
		{"id": "k_vie7", "nombre": "Temple", "rango": "basica", "pos": [-115, 390], "req": ["k_vie4"],
			"bonos": {"defensa": 2}, "glifo": "escudo", "texto": "La piel se acostumbra al frío del acero."},
		{"id": "k_exc_vie", "nombre": "Viento del Eco", "rango": "excepcional", "pos": [-45, 480],
			"req": ["k_vie5", "k_vie6"], "todos": true, "bonos": {"atb_inicio": 20.0, "velocidad": 3},
			"glifo": "estrella", "texto": "El primero en moverse, siempre."},
		# Memoria (abajo): une los dos caminos (un rodeo para quien quiera aguante o algo de chispa)
		{"id": "k_mem1", "nombre": "Recuerdo del filo", "rango": "basica", "pos": [140, 250], "req": ["k_filo3"],
			"bonos": {"espiritu": 2}, "glifo": "espiral", "texto": "Un resto de luz para el Fuego y el Rayo."},
		{"id": "k_mem3", "nombre": "Recuerdo del viento", "rango": "basica", "pos": [-140, 250], "req": ["k_vie4"],
			"bonos": {"vitalidad": 2}, "glifo": "corazon", "texto": "El cansancio pesa menos."},
		{"id": "k_mem2", "nombre": "Chispa guardada", "rango": "intermedia", "pos": [180, 250],
			"req": ["k_mem1", "k_mem3"], "bonos": {"magia": 3}, "glifo": "llama",
			"texto": "La magia que Kael casi no usa, más viva."},
		{"id": "k_mem4", "nombre": "Latido del cristal", "rango": "avanzada", "pos": [180, 380], "req": ["k_mem2"],
			"bonos": {"regen": 0.03}, "glifo": "corazon", "texto": "Cada turno, un poco de vida vuelve."},
	],
	# ------------------------------------------------------------------ LYA: poder mágico, reserva, defensa mágica, apoyo
	# La misma forma de Kael, girada media vuelta: los caminos cuelgan hacia abajo como un cáliz y la Memoria arriba.
	"Lya": [
		{"id": "l_inicio", "nombre": "Primera nota", "rango": "basica", "pos": [180, 100], "req": [],
			"bonos": {"magia": 1, "espiritu": 1}, "glifo": "estrella", "texto": "Una nota clara en el cristal."},
		# Marea (abajo a la izquierda en pantalla): poder mágico
		{"id": "l_ma1", "nombre": "Corriente", "rango": "basica", "pos": [220, 190], "req": ["l_inicio"],
			"bonos": {"magia": 2}, "glifo": "gota", "texto": "La magia fluye sin esfuerzo."},
		{"id": "l_ma2", "nombre": "Marea alta", "rango": "basica", "pos": [255, 215], "req": ["l_ma1"],
			"bonos": {"magia": 2}, "glifo": "gota", "texto": "Sube sin hacer ruido."},
		{"id": "l_ma3", "nombre": "Runa de la corriente", "rango": "intermedia", "pos": [215, 300],
			"req": ["l_ma1"], "bonos": {"magia_extra": 3}, "glifo": "runa", "texto": "Una runa que afila cada hechizo."},
		{"id": "l_ma4", "nombre": "Pulso del manantial", "rango": "intermedia", "pos": [275, 300], "req": ["l_ma2"],
			"bonos": {"pm_turno": 1.0}, "glifo": "espiral", "texto": "El manantial devuelve lo que da."},
		{"id": "l_ma5", "nombre": "Runa profunda", "rango": "avanzada", "pos": [205, 400], "req": ["l_ma3"],
			"bonos": {"magia_extra": 5}, "glifo": "runa", "texto": "Escrita donde la luz no llega."},
		{"id": "l_ma6", "nombre": "Mar en calma", "rango": "avanzada", "pos": [242, 380], "req": ["l_ma3", "l_ma4"],
			"bonos": {"magia": 4}, "glifo": "gota", "texto": "Calma por fuera, fuerza por dentro."},
		{"id": "l_ma7", "nombre": "Gota clara", "rango": "basica", "pos": [295, 390], "req": ["l_ma4"],
			"bonos": {"espiritu": 2}, "glifo": "gota", "texto": "Una gota más en el cántaro."},
		{"id": "l_exc_ma", "nombre": "Canto del Eco", "rango": "excepcional", "pos": [225, 480],
			"req": ["l_ma5", "l_ma6"], "todos": true, "bonos": {"magia_extra": 4, "magia": 3}, "glifo": "estrella",
			"texto": "Cada hechizo suena con su eco."},
		# Amparo (abajo a la derecha en pantalla): apoyo, defensa y la coraza (lo más parecido a defensa mágica que
		# el combate ya sabe aplicar: los enemigos de hoy solo golpean, no lanzan magia al grupo)
		{"id": "l_am1", "nombre": "Manos abiertas", "rango": "basica", "pos": [140, 190], "req": ["l_inicio"],
			"bonos": {"espiritu": 2}, "glifo": "mano", "texto": "Para dar hay que tener."},
		{"id": "l_am2", "nombre": "Paso sereno", "rango": "basica", "pos": [105, 215], "req": ["l_am1"],
			"bonos": {"defensa": 2}, "glifo": "escudo", "texto": "No retroceder tampoco es atacar."},
		{"id": "l_am3", "nombre": "Velo de escarcha", "rango": "intermedia", "pos": [145, 300], "req": ["l_am1"],
			"bonos": {"barrera_inicio": 0.06}, "glifo": "luna", "texto": "Empieza el combate tras un velo frío."},
		{"id": "l_am4", "nombre": "Raíz serena", "rango": "intermedia", "pos": [85, 300], "req": ["l_am2"],
			"bonos": {"vitalidad": 3}, "glifo": "corazon", "texto": "Aguantar para poder curar."},
		{"id": "l_am5", "nombre": "Aliento que perdura", "rango": "avanzada", "pos": [155, 400], "req": ["l_am3"],
			"bonos": {"apoyo_turnos": 1.0}, "glifo": "mano", "texto": "Su Aliento dura un turno más."},
		{"id": "l_am6", "nombre": "Brote de vida", "rango": "avanzada", "pos": [118, 380], "req": ["l_am3", "l_am4"],
			"bonos": {"regen": 0.03}, "glifo": "raiz", "texto": "Cada turno, algo vuelve a crecer."},
		{"id": "l_am7", "nombre": "Pie firme", "rango": "basica", "pos": [65, 390], "req": ["l_am4"],
			"bonos": {"vitalidad": 2}, "glifo": "corazon", "texto": "Tierra bajo los pies."},
		{"id": "l_exc_am", "nombre": "Coro del Eco", "rango": "excepcional", "pos": [135, 480],
			"req": ["l_am5", "l_am6"], "todos": true, "bonos": {"aliento_inicio": 1.0, "barrera_inicio": 0.06},
			"glifo": "estrella", "texto": "Empieza dando Aliento al más herido."},
		# Memoria (arriba): reserva de magia y la resistencia mágica (nació DORMIDA; despertó al integrar los accesorios
		# V12, que engancharon «res_magica» en el combate: hoy solo la usan las esporas del Guardián y el Aliento de Humbaba)
		{"id": "l_me1", "nombre": "Cántaro", "rango": "basica", "pos": [320, 250], "req": ["l_ma2"],
			"bonos": {"espiritu": 2}, "glifo": "espiral", "texto": "Guardar luz para luego."},
		{"id": "l_me3", "nombre": "Paso de viento", "rango": "basica", "pos": [40, 250], "req": ["l_am2"],
			"bonos": {"velocidad": 2}, "glifo": "ala", "texto": "Llegar a tiempo a quien lo necesita."},
		{"id": "l_me2", "nombre": "Cántaro sin fondo", "rango": "intermedia", "pos": [0, 250],
			"req": ["l_me1", "l_me3"], "bonos": {"espiritu": 3}, "glifo": "espiral", "texto": "Más PM para todo."},
		{"id": "l_me4", "nombre": "Velo contra la magia", "rango": "avanzada", "pos": [0, 380], "req": ["l_me2"],
			"bonos": {"res_magica": 0.15}, "glifo": "luna",
			"texto": "Un velo de luz que desvía parte de la magia enemiga."},
	],
	# ------------------------------------------------------------------ GARON: vida, defensa, resistencia, proteger
	# Alas anchas hacia los lados, como un escudo abierto.
	"Garon": [
		{"id": "g_inicio", "nombre": "Primer bastión", "rango": "basica", "pos": [0, 100], "req": [],
			"bonos": {"vitalidad": 1, "defensa": 1}, "glifo": "escudo", "texto": "La primera piedra del muro."},
		# Muralla (derecha): defensa y proteger al grupo
		{"id": "g_mu1", "nombre": "Piedra", "rango": "basica", "pos": [55, 190], "req": ["g_inicio"],
			"bonos": {"defensa": 2}, "glifo": "escudo", "texto": "No se mueve."},
		{"id": "g_mu2", "nombre": "Sillar", "rango": "basica", "pos": [92, 215], "req": ["g_mu1"],
			"bonos": {"defensa": 2}, "glifo": "escudo", "texto": "Una piedra encima de otra."},
		{"id": "g_mu3", "nombre": "Coraza de runas", "rango": "intermedia", "pos": [50, 300], "req": ["g_mu1"],
			"bonos": {"barrera_inicio": 0.08}, "glifo": "runa", "texto": "Empieza el combate tras una coraza."},
		{"id": "g_mu4", "nombre": "Escudo del hermano", "rango": "intermedia", "pos": [108, 300], "req": ["g_mu2"],
			"bonos": {"cubrir": 0.2}, "glifo": "mano", "texto": "Recibe el golpe del aliado con poca vida."},
		{"id": "g_mu5", "nombre": "Muralla que responde", "rango": "avanzada", "pos": [40, 400], "req": ["g_mu3"],
			"bonos": {"contra_defendiendo": 0.4}, "glifo": "espada", "texto": "En guardia, devuelve el golpe."},
		{"id": "g_mu6", "nombre": "Almena", "rango": "avanzada", "pos": [78, 380], "req": ["g_mu3", "g_mu4"],
			"bonos": {"defensa": 3, "cubrir": 0.1}, "glifo": "escudo", "texto": "Desde aquí se ve venir todo."},
		{"id": "g_mu7", "nombre": "Contrafuerte", "rango": "basica", "pos": [128, 390], "req": ["g_mu4"],
			"bonos": {"defensa": 2}, "glifo": "escudo", "texto": "Sostiene al que sostiene."},
		{"id": "g_exc_mu", "nombre": "Bastión del Eco", "rango": "excepcional", "pos": [60, 480],
			"req": ["g_mu5", "g_mu6"], "todos": true, "bonos": {"barrera_inicio": 0.1, "defensa": 4},
			"glifo": "estrella", "texto": "Detrás de él, nadie cae."},
		# Raíz (izquierda): vida y resistencia
		{"id": "g_ra1", "nombre": "Tronco", "rango": "basica", "pos": [-55, 190], "req": ["g_inicio"],
			"bonos": {"vitalidad": 2}, "glifo": "corazon", "texto": "Más ancho cada año."},
		{"id": "g_ra2", "nombre": "Savia", "rango": "basica", "pos": [-92, 215], "req": ["g_ra1"],
			"bonos": {"vitalidad": 2}, "glifo": "corazon", "texto": "Corre despacio, pero no para."},
		{"id": "g_ra3", "nombre": "Corteza viva", "rango": "intermedia", "pos": [-50, 300], "req": ["g_ra1"],
			"bonos": {"regen": 0.03}, "glifo": "raiz", "texto": "Cada turno, la herida se cierra un poco."},
		{"id": "g_ra4", "nombre": "Anillo del roble", "rango": "intermedia", "pos": [-108, 300], "req": ["g_ra2"],
			"bonos": {"vitalidad": 3}, "glifo": "corazon", "texto": "Un año más de madera."},
		{"id": "g_ra5", "nombre": "Mordisco de la tierra", "rango": "avanzada", "pos": [-40, 400], "req": ["g_ra3"],
			"bonos": {"robo_vida": 0.08}, "glifo": "llama", "texto": "Se cura parte del daño que hace."},
		{"id": "g_ra6", "nombre": "Raíz honda", "rango": "avanzada", "pos": [-78, 380], "req": ["g_ra3", "g_ra4"],
			"bonos": {"vitalidad": 4, "espiritu": 1}, "glifo": "raiz", "texto": "Lo que no se ve, aguanta."},
		{"id": "g_ra7", "nombre": "Hombros de piedra", "rango": "basica", "pos": [-128, 390], "req": ["g_ra4"],
			"bonos": {"fuerza": 2}, "glifo": "espada", "texto": "Para cargar con todos."},
		{"id": "g_exc_ra", "nombre": "Raíz del Eco", "rango": "excepcional", "pos": [-60, 480],
			"req": ["g_ra5", "g_ra6"], "todos": true, "bonos": {"regen": 0.04, "vitalidad": 3}, "glifo": "estrella",
			"texto": "El árbol que vuelve a brotar."},
		# Memoria (abajo): fuerza, PM para Embuir y la resistencia elemental (DORMIDA)
		{"id": "g_me1", "nombre": "Brazo de hierro", "rango": "basica", "pos": [155, 250], "req": ["g_mu2"],
			"bonos": {"fuerza": 2}, "glifo": "espada", "texto": "El golpe también protege."},
		{"id": "g_me3", "nombre": "Brasa de runa", "rango": "basica", "pos": [-155, 250], "req": ["g_ra2"],
			"bonos": {"espiritu": 2}, "glifo": "llama", "texto": "PM para Embuir sus espadas."},
		{"id": "g_me2", "nombre": "Martillo de forja", "rango": "intermedia", "pos": [180, 260],
			"req": ["g_me1", "g_me3"], "bonos": {"ataque": 3}, "glifo": "espada", "texto": "Golpe de herrero."},
		{"id": "g_me4", "nombre": "Piel de basalto", "rango": "avanzada", "pos": [180, 385], "req": ["g_me2"],
			"bonos": {"res_elemental": 0.2}, "glifo": "llama",
			"texto": "Dormido: despertará cuando los enemigos golpeen con elementos."},
	],
	# ------------------------------------------------------------------ NAIRA: PREPARADO Y APAGADO (prototipo sin aprobar)
	# Solo existe con su interruptor (grupo.gd naira_v12) y, además, el de los orbes. Valores de relleno, no definitivos.
	"Naira": [
		{"id": "n_inicio", "nombre": "Provisional", "rango": "basica", "pos": [0, 100], "req": [],
			"bonos": {"magia": 1, "espiritu": 1}, "glifo": "estrella", "texto": "Tablero provisional (Naira sin aprobar)."},
		{"id": "n_a1", "nombre": "Provisional A", "rango": "basica", "pos": [45, 200], "req": ["n_inicio"],
			"bonos": {"magia": 2}, "glifo": "gota", "texto": "Tablero provisional (Naira sin aprobar)."},
		{"id": "n_a2", "nombre": "Provisional A2", "rango": "intermedia", "pos": [45, 310], "req": ["n_a1"],
			"bonos": {"magia_extra": 3}, "glifo": "runa", "texto": "Tablero provisional (Naira sin aprobar)."},
		{"id": "n_b1", "nombre": "Provisional B", "rango": "basica", "pos": [-45, 200], "req": ["n_inicio"],
			"bonos": {"espiritu": 2}, "glifo": "espiral", "texto": "Tablero provisional (Naira sin aprobar)."},
		{"id": "n_b2", "nombre": "Provisional B2", "rango": "intermedia", "pos": [-45, 310], "req": ["n_b1"],
			"bonos": {"vitalidad": 3}, "glifo": "corazon", "texto": "Tablero provisional (Naira sin aprobar)."},
	],
}
