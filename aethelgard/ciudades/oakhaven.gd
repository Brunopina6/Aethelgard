extends RefCounted
# Oakhaven, «la ciudadela de los faroles» (T-089): los datos de la ciudad hecha a mano.
# Diseño: docs/diseno/ciudades_y_lugares.md §2.1. Enganches y arte que pedir: docs/memory/agents/narrativa.md.
# Lo usan ciudad_oakhaven.gd (la escena, que hereda de zona.gd como garganta.gd; se entra desde el mapa), progreso.gd
# (las notas, CIUDADES), diario.gd (la sección «Notas») y zonas3d/pastos_verdes_3d.gd (el ramito de lavanda).
#
# VERSIÓN NEUTRA (D-073): no afirma nada de lo que espera la decisión del usuario.
#   - La posadera del Cuervo Oxidado no tiene nombre ni se dice que criara a Kael (propuesta: Olvido).
#   - El crematorio tiene una puerta sellada y nada más (propuesta: la Cripta de las Urnas, debajo).
#   - No hay Aldea Rocío, ni trampilla, ni Pip guía, ni página arrancada del libro de guardia.
#   La versión de la propuesta está aparte, fuera del juego: dialogos/oakhaven/propuesta/ (con .gdignore).
#
# Casillas: x de 0 a 79 e y de 0 a 55 (zona.gd: ANCHO 80, ALTO 56, T 64 px). Norte arriba; la salida, al sur.
# Rect2(x, y, ancho, alto) cubre x ∈ [x, x + ancho) e y ∈ [y, y + alto).
# Estado: solo claves que ya existen en la partida (progreso.gd, CLAVES): hitos, decisiones, mazmorras["oakhaven"],
# cofres_abiertos, lore_visto (las notas, con el prefijo «nota_») e inventario. Ninguna clave nueva.
#
# Uso (desde la ciudad):
#   const Oak := preload("res://ciudades/oakhaven.gd")
#   Oak.registrar_dialogic()                          # una vez, antes del primer diálogo
#   Dialogic.start(Oak.dialogo_de("posadera", veces))   # «veces»: cuántas veces se le ha hablado en esta visita
#   Dialogic.signal_event → Oak.aplicar_senal(arg)     # devuelve el aviso que enseñar ("" si no hay)

const INDICE := 0                        # en LUGARES de mapa.gd
const NOMBRE := "oakhaven"               # su diccionario en «mazmorras»
const TAM := Vector2i(80, 56)
const HORA := "azul"                     # hora fija: la hora azul, justo después de ponerse el sol (diseño §2.1)
const PLAZA := Vector2(40, 26)
const ARBOL := Vector2(40, 7)            # el Árbol Milenario sustituye al altar (la «meta» de zona.gd)
const INICIO := Vector2(40, 53.5)        # donde aparece Kael al entrar por la Puerta del Sur
const SALIDA_X := 40.0
const PRECIO_POSADA := 30                # como hoy (zona.gd); la posadera dice «treinta monedas»
const TEXTO_NOCHE_GRATIS := "Esta noche invita la posadera."   # al despertar, si se usó la noche gratis
const TEXTO_ARBOL := "El Árbol Milenario. Su copa se ve desde toda la ciudad."
const RUTA_DIALOGOS := "res://dialogos/oakhaven/"
const DIALOGOS_CANON := ["npc_aldric", "npc_selene", "npc_pip", "npc_rosa"]   # res://dialogos/<id>.dtl, sin tocar

# Personajes nuevos de Dialogic. El editor (o «--import») los apunta solo en project.godot; mientras tanto,
# registrar_dialogic() los da a conocer en tiempo de juego, sin escribir nada.
const PERSONAJES := {
	"posadera": "res://dialogos/personajes/oakhaven/posadera.dch",
	"albar": "res://dialogos/personajes/oakhaven/albar.dch",
	"bastian": "res://dialogos/personajes/oakhaven/bastian.dch",
	"encina": "res://dialogos/personajes/oakhaven/encina.dch",
	"ferro": "res://dialogos/personajes/oakhaven/ferro.dch",      # V10 (docs/v10/DISENO_V10.md), propuesta
	"hilda": "res://dialogos/personajes/oakhaven/hilda.dch",
	"mirta": "res://dialogos/personajes/oakhaven/mirta.dch",
}

# ================================================================= trazado
# «pisable»: false = edificio (muro). «canon»: el lugar está en mapa.gd:41 (biblia v2, [C]).
const LUGARES := [
	{"id": "puerta_sur", "nombre": "Puerta del Sur", "rect": Rect2(37, 51, 7, 5), "pisable": true,
		"funcion": "entrada y salida al mapa (se conserva)"},
	{"id": "calle_mayor", "nombre": "Calle Mayor", "rect": Rect2(39, 31, 2, 20), "pisable": true,
		"funcion": "recorrido principal, con un farol cada 5 casillas"},
	{"id": "plaza", "nombre": "Plaza del Tapiz", "rect": Rect2(35, 21, 11, 10), "pisable": true,
		"funcion": "fuente, tablón de anuncios y puesto de flores"},
	{"id": "calle_cuervo", "nombre": "Calle del Cuervo", "rect": Rect2(6, 25, 29, 2), "pisable": true,
		"funcion": "de la plaza al Barrio del Cuervo"},
	{"id": "calle_mercado", "nombre": "Calle del Mercado", "rect": Rect2(46, 25, 28, 2), "pisable": true,
		"funcion": "de la plaza al mercado y a la colina"},
	{"id": "calle_arbol", "nombre": "Calle del Árbol", "rect": Rect2(39, 13, 2, 8), "pisable": true,
		"funcion": "de la plaza a las raíces"},
	{"id": "raices", "nombre": "Raíces del Árbol", "rect": Rect2(30, 2, 20, 11), "pisable": true,
		"funcion": "raíces que levantan el empedrado; hito del norte"},
	{"id": "arbol", "nombre": "Árbol Milenario", "rect": Rect2(38, 5, 4, 4), "pisable": false, "canon": true,
		"funcion": "tronco del roble (la copa, por encima, se ve desde toda la ciudad)"},
	{"id": "concejo", "nombre": "Casa del Concejo", "rect": Rect2(43, 16, 9, 5), "pisable": false,
		"funcion": "edificio con pórtico hacia la plaza"},
	{"id": "concejo_portico", "nombre": "Pórtico del Concejo", "rect": Rect2(43, 21, 9, 2), "pisable": true,
		"funcion": "el tapiz de los reyes (detalle oak_tapiz)"},
	{"id": "taberna", "nombre": "Taberna del Cuervo Oxidado", "rect": Rect2(11, 19, 10, 6), "pisable": false,
		"canon": true, "funcion": "la posada (POSADA, 30 monedas); letrero de hierro con un cuervo que chirría"},
	{"id": "patio_cuervo", "nombre": "Patio del Cuervo", "rect": Rect2(10, 27, 5, 4), "pisable": true,
		"funcion": "barriles (favor de la posadera)"},
	{"id": "callejon", "nombre": "Callejón", "rect": Rect2(22, 27, 3, 8), "pisable": true,
		"funcion": "Pip; al fondo, una grieta con luz"},
	{"id": "grieta", "nombre": "Grieta del callejón", "rect": Rect2(23, 35, 1, 1), "pisable": true,
		"funcion": "paso estrecho y escondido al Patio de las Velas"},
	{"id": "patio_velas", "nombre": "Patio de las Velas", "rect": Rect2(19, 36, 9, 4), "pisable": true,
		"funcion": "rincón escondido: un altar pequeño con el anillo partido y velas encendidas"},
	{"id": "botica", "nombre": "Botica de Selene", "rect": Rect2(33, 35, 5, 5), "pisable": false,
		"funcion": "edificio"},
	{"id": "plazuela_botica", "nombre": "Plazuela de la Botica", "rect": Rect2(33, 40, 6, 3), "pisable": true,
		"funcion": "Selene, a la puerta"},
	{"id": "mercado", "nombre": "Mercado", "rect": Rect2(48, 27, 12, 5), "pisable": true,
		"funcion": "puestos con toldos (TIENDA, se conserva)"},
	{"id": "guardia", "nombre": "Cuerpo de guardia", "rect": Rect2(44, 45, 5, 4), "pisable": false,
		"funcion": "edificio de la guardia nocturna"},
	{"id": "soportal_guardia", "nombre": "Soportal de la guardia", "rect": Rect2(41, 45, 3, 4), "pisable": true,
		"funcion": "el libro de guardia (nota)"},
	{"id": "patio_guardia", "nombre": "Patio de la guardia", "rect": Rect2(44, 49, 5, 4), "pisable": true,
		"funcion": "trastos requisados (cofre), junto a la Puerta del Sur"},
	{"id": "colina", "nombre": "Colina del Crematorio", "rect": Rect2(56, 4, 19, 15), "pisable": true,
		"funcion": "el único sitio frío de la ciudad"},
	{"id": "crematorio", "nombre": "Crematorio", "rect": Rect2(62, 7, 10, 8), "pisable": false, "canon": true,
		"funcion": "piedra hueso y chimenea con humo blanco; la puerta, sellada (detalle oak_sello)",
		"puerta": Vector2(67, 15.5), "sellada": true},
	{"id": "jardin_urnas", "nombre": "Jardín de urnas", "rect": Rect2(57, 9, 5, 5), "pisable": true,
		"funcion": "urnas de piedra (decorado)"},
	{"id": "subida_colina", "nombre": "Subida de la colina", "rect": Rect2(64, 19, 2, 6), "pisable": true,
		"funcion": "de la Calle del Mercado al crematorio"},
	{"id": "calle_torre", "nombre": "Calle de la Torre", "rect": Rect2(68, 27, 2, 17), "pisable": true,
		"funcion": "de la Calle del Mercado a la Torre de la Campana"},
	{"id": "torre", "nombre": "Torre de la Campana", "rect": Rect2(72, 38, 4, 4), "pisable": false,
		"funcion": "se sube por dentro: vista y paso a la ronda"},
	{"id": "pie_torre", "nombre": "Pie de la torre", "rect": Rect2(68, 42, 8, 3), "pisable": true,
		"funcion": "puerta de la torre"},
	{"id": "ronda", "nombre": "Ronda de la muralla este", "rect": Rect2(76, 28, 2, 14), "pisable": true,
		"funcion": "en alto, solo desde la torre: tres faroles apagados y un cofre al final", "en_alto": true},
]

# Los detalles de canon de progreso.gd que cambian de sitio (conservan su id, así nadie los pierde).
const SITIOS_DETALLE := {
	"oak_sello": Vector2(67, 16),         # «Sello del crematorio»: en su puerta (antes, en la plaza)
	"oak_tapiz": Vector2(47, 22),         # «Tapiz de los reyes»: en el pórtico del Concejo (antes, en la plaza)
}

# ================================================================= vecinos
# «dialogos»: en orden. Los «prioridad» que se cumplen van primero (misiones); si no, se turnan los demás que se
# cumplen, uno por conversación (dialogo_de). «si»: condición (ver cumple()). «frases»: los avisos de siempre si no
# hubiera Dialogic (zona.gd). «imagen»/«tinte»/«escala»: el muñeco del mundo, PROVISIONAL en los nuevos (arte pedido).
const NPCS := [
	{"id": "aldric", "nombre": "Caballero Aldric", "corto": "Aldric", "personaje": "aldric", "canon": true,
		"casilla": Vector2(40, 49.5), "donde": "Puerta del Sur", "imagen": "res://personajes/npc/caballero.png",
		"dialogos": [{"dialogo": "npc_aldric"}, {"dialogo": "oak_aldric_salida", "si": "cond:kael_salio"}],
		"frases": ["La guardia no deja salir a nadie de noche. Dicen que la niebla trae Hollines.",
			"Que la luz te guíe."]},
	{"id": "selene", "nombre": "Maga Selene", "corto": "Selene", "personaje": "selene", "canon": true,
		"casilla": Vector2(36, 41), "donde": "Puerta de la Botica", "imagen": "res://personajes/npc/maga.png",
		"dialogos": [{"dialogo": "npc_selene"}, {"dialogo": "oak_selene_lya", "si": "grupo:Lya"}],
		"frases": ["Siento una magia antigua en ese brazalete tuyo…",
			"Y lleva siempre algún Éter. Sin magia, un mago es solo alguien con un palo."]},
	{"id": "pip", "nombre": "Pip el Pícaro", "corto": "Pip", "personaje": "pip", "canon": true,
		"casilla": Vector2(23.5, 30), "donde": "Callejón del Barrio del Cuervo", "imagen": "res://personajes/npc/picaro.png",
		"dialogos": [
			{"dialogo": "oak_pip_cucharon", "si": ["estado:favores", "!estado:favor_cucharon", "!hito:oak_favores"],
				"prioridad": true},
			# V9, encargo «Canela se ha perdido» (datos/encargos_pastos.gd; la perra está en las ruinas de Pastos Verdes)
			{"dialogo": "oak_pip_perro", "si": ["hito:pv_14", "!hito:enc_perro_pedido"], "prioridad": true},
			{"dialogo": "oak_pip_perro_gracias", "si": ["hito:enc_perro_encontrado", "!hito:enc_perro_devuelto"], "prioridad": true},
			# V10, encargo B «La fórmula desaparecida»: Pip vio volar las páginas de Mirta
			{"dialogo": "oak_pip_paginas", "si": ["hito:enc_formula_pedido", "!hito:enc_formula_pip"], "prioridad": true},
			{"dialogo": "oak_pip_perro_despues", "si": "hito:enc_perro_devuelto"},
			{"dialogo": "npc_pip", "si": "!decision:pip_oak=pagado"},
			{"dialogo": "oak_pip_secreto", "si": ["!decision:pip_oak=pagado", "oro:1"]},
			{"dialogo": "oak_pip_sin_monedas", "si": ["!decision:pip_oak=pagado", "!oro:1"]},
			{"dialogo": "oak_pip_despues", "si": "decision:pip_oak=pagado"}],
		"frases": ["¿Buscas algo? Yo no he visto nada… ni he tocado nada.",
			"Si me das una moneda te cuento un secreto. ¿No? Pues nada."]},
	{"id": "rosa", "nombre": "Aldeana Rosa", "corto": "Rosa", "personaje": "rosa", "canon": true,
		"casilla": Vector2(44, 29), "donde": "Puesto de flores de la plaza", "imagen": "res://personajes/npc/aldeana.png",
		"dialogos": [
			{"dialogo": "oak_rosa_flores", "si": ["estado:favores", "!estado:favor_flores", "!hito:oak_favores"],
				"prioridad": true},
			{"dialogo": "oak_rosa_lavanda_entrega", "si": ["estado:lavanda_cogida", "!hito:oak_lavanda"], "prioridad": true},
			{"dialogo": "npc_rosa"},
			{"dialogo": "oak_rosa_lavanda", "si": ["modo:3d", "hito:pv_02", "!estado:lavanda", "!hito:oak_lavanda"]}],
		"frases": ["¡Buenos días! Estas flores las cogí junto al camino.", "Ten cuidado ahí fuera, ¿vale?"]},
	{"id": "posadera", "nombre": "Posadera", "corto": "la posadera", "personaje": "posadera",
		"casilla": Vector2(16, 26), "donde": "Puerta de la Taberna del Cuervo Oxidado",
		"imagen": "res://personajes/npc/aldeana.png", "tinte": Color(1, 0.86, 0.68),
		"dialogos": [
			{"dialogo": "oak_posadera_favores_fin", "si": ["cond:favores_listos", "!hito:oak_favores"], "prioridad": true},
			{"dialogo": "oak_posadera_favores_pendientes",
				"si": ["estado:favores", "!cond:favores_listos", "!hito:oak_favores"], "prioridad": true},
			{"dialogo": "oak_posadera"},
			{"dialogo": "oak_posadera_favores", "si": ["!estado:favores", "!hito:oak_favores"]},
			{"dialogo": "oak_posadera_niebla"}],   # (sus servicios, en el botón POSADA: oakhaven_posada.gd)
		"frases": ["Bienvenido al Cuervo Oxidado. Cama, sopa y silencio: treinta monedas.",
			"El silencio no lo garantizo. Los de la mesa del fondo cantan."]},
	{"id": "albar", "nombre": "Albar", "corto": "Albar", "personaje": "albar",
		"casilla": Vector2(63, 17), "donde": "Junto al crematorio",
		"imagen": "res://personajes/npc/maga.png", "tinte": Color(0.82, 0.82, 0.88),
		"dialogos": [{"dialogo": "oak_albar"}, {"dialogo": "oak_albar_puerta"}],
		"frases": ["Bienvenido al crematorio, muchacho. Aquí todo acaba en paz.",
			"Esa puerta no se abre. Ni para visitas, ni para preguntas."]},
	{"id": "bastian", "nombre": "Bastián", "corto": "Bastián", "personaje": "bastian",
		"casilla": Vector2(40, 43), "donde": "Calle Mayor (va de farol en farol)",
		"imagen": "res://personajes/npc/picaro.png", "tinte": Color(0.78, 0.86, 1), "escala": 0.8,
		"dialogos": [
			{"dialogo": "oak_bastian_ronda_fin", "si": ["cond:faroles_encendidos", "!hito:oak_faroles"], "prioridad": true},
			{"dialogo": "oak_bastian_ronda_pendiente", "si": ["estado:faroles", "!cond:faroles_encendidos"],
				"prioridad": true},
			{"dialogo": "oak_bastian", "si": ["!estado:faroles", "!hito:oak_faroles"]},
			{"dialogo": "oak_bastian_ronda", "si": ["!estado:faroles", "!hito:oak_faroles"]},
			{"dialogo": "oak_bastian_contento", "si": "hito:oak_faroles"}],
		"frases": ["¡Ciento doce faroles! Bueno, ciento nueve: tres están apagados.",
			"Si un farol se apaga, la niebla se acerca. Lo dice mi abuela."]},
	{"id": "encina", "nombre": "Doña Encina", "corto": "Doña Encina", "personaje": "encina",
		"casilla": Vector2(35, 10), "donde": "Raíces del Árbol",
		"imagen": "res://personajes/npc/maga.png", "tinte": Color(0.78, 0.9, 0.66),
		"dialogos": [
			# fase 3, «El bosque que no recuerda»: lo que pasó con el Guardián del Bosque (combate.gd, _premio_bosque)
			{"dialogo": "oak_encina_bosque_purificado", "si": ["hito:bq_purificado", "!estado:encina_bosque"], "prioridad": true},
			{"dialogo": "oak_encina_bosque_derrotado", "si": ["hito:bq_derrotado", "!estado:encina_bosque"], "prioridad": true},
			{"dialogo": "oak_encina_gracias", "si": ["hito:oak_lavanda", "!estado:encina_gracias"], "prioridad": true},
			{"dialogo": "oak_encina"}, {"dialogo": "oak_encina_anillo"},
			{"dialogo": "oak_encina_bosque_purificado", "si": "hito:bq_purificado"},
			{"dialogo": "oak_encina_bosque_derrotado", "si": "hito:bq_derrotado"}],
		"frases": ["Este roble ya era viejo cuando Oakhaven era una aldea. Respétalo.",
			"Cuenta sus anillos y sabrás su historia. Yo me perdí por el dos mil."]},
	# V10, «Oakhaven, el corazón vivo del reino» (docs/v10/DISENO_V10.md; personajes en propuesta, pendientes de canon).
	# Los diálogos de servicio acaban con la señal del taller (oak:servicio_*); los del encargo, con «prioridad».
	# Ferro: la herrería es la casa del final de la Calle del Mercado, al pie de la Calle de la Torre.
	{"id": "ferro", "nombre": "Maese Ferro", "corto": "Ferro", "personaje": "ferro",
		"casilla": Vector2(70.5, 26), "donde": "Herrería, junto al yunque (final de la Calle del Mercado)",
		"imagen": "res://personajes/npc/caballero.png", "tinte": Color(1, 0.74, 0.56),
		"dialogos": [
			# encargo A, «El pedido de Maese Ferro» (enc_herrero): con el hierro, se decide; antes, lo pide
			{"dialogo": "oak_ferro_veta", "si": ["hito:enc_herrero_veta", "!hito:enc_herrero_fin"], "prioridad": true},
			{"dialogo": "oak_ferro_pedido", "si": ["hito:pv_05", "!hito:enc_herrero_pedido"], "prioridad": true},
			{"dialogo": "oak_ferro_despues", "si": "hito:enc_herrero_fin"},
			# la variante: con el bosque resuelto o con la técnica aprendida (en vez de «hecha:frostfang_falla», que
			# cumple() no entiende, la decisión de quedarse el hierro: Ferro le enseña el Acero de la Falla)
			{"dialogo": "oak_ferro_v", "si": "hito:bq_resuelto"},
			{"dialogo": "oak_ferro_v", "si": ["decision:hierro_ferro=kael", "!hito:bq_resuelto"]},
			{"dialogo": "oak_ferro"}],
		"frases": ["¿Vienes a mirar o a trabajar? Aquí se trabaja.",
			"Venga, enséñame esa espada. …Hum. La has tratado como a una pala."]},
	# Hilda: su taller es la casa de la Calle del Mercado (frente al mercado); su puesto, a la entrada de la calle.
	{"id": "hilda", "nombre": "Hilda la Armera", "corto": "Hilda", "personaje": "hilda",
		"casilla": Vector2(47, 25.6), "donde": "Puesto de armaduras, a la entrada de la Calle del Mercado",
		"imagen": "res://personajes/npc/aldeana.png", "tinte": Color(0.8, 0.84, 0.92),
		"dialogos": [{"dialogo": "oak_hilda"}],
		"frases": ["Hilda, armera. Ni un remache de más, ni uno de menos.",
			"Lo que se ajusta hoy no se rompe mañana. A ver qué traéis."]},
	# Mirta: atiende dentro de la botica; en la ciudad 2D, en la plazuela, a un lado de Selene (que no se mueve).
	{"id": "mirta", "nombre": "Mirta la Boticaria", "corto": "Mirta", "personaje": "mirta",
		"casilla": Vector2(33.5, 41.5), "donde": "Plazuela de la Botica (sale del mostrador)",
		"imagen": "res://personajes/npc/maga.png", "tinte": Color(0.9, 0.8, 1),
		"dialogos": [
			# encargo B, «La fórmula desaparecida» (enc_formula): Lya recompone la fórmula, así que hace falta en el grupo
			{"dialogo": "oak_mirta_formula", "si": ["hito:enc_formula_paginas", "!hito:enc_formula_fin", "grupo:Lya"],
				"prioridad": true},
			{"dialogo": "oak_mirta_pedido", "si": ["hito:pv_03", "!hito:enc_formula_pedido"], "prioridad": true},
			{"dialogo": "oak_mirta_despues", "si": "hito:enc_formula_fin"},
			{"dialogo": "oak_mirta"}],
		"frases": ["¡Clientes! Pasad. Cuidado con el frasco verde. No, el otro verde.",
			"Una cosa sí sé: la mejor cura es la que llega a tiempo."]},
]

# Escena corta al descansar en la posada, según quién esté en el grupo (solo hablan los presentes).
const ESCENAS_POSADA := [
	{"dialogo": "oak_posada_grupo", "grupo": ["Kael", "Lya", "Garon"]},
	{"dialogo": "oak_posada_lya", "grupo": ["Kael", "Lya"]},
	{"dialogo": "oak_posada_solo", "grupo": ["Kael"]},
]

# Charlas de posada (narrativa, 09/11): conversaciones breves de los héroes al descansar en el Cuervo, una por noche en
# lugar de la escena de siempre: la más nueva sin ver de las que ya están desbloqueadas («hito», uno que ya existe, o «si»,
# una condición como las de los vecinos) y
# cuyo «grupo» está entero en el grupo activo. En la lista, de la más antigua a la más nueva (orden de la historia).
# Lo visto se guarda como estado de la ciudad («charla_…» en «mazmorras», ya en la partida): una partida antigua no
# lo tiene y vale «sin ver». Los diálogos, en dialogos/oakhaven/charlas/ (con el gesto de cada frase); «intenciones»,
# una por frase y en su orden («Quién: intención»), para animaciones.
const RUTA_CHARLAS := "res://dialogos/oakhaven/charlas/"
const CHARLAS_POSADA := [
	{"id": "charla_conocerse", "hito": "pv_03", "grupo": ["Kael", "Lya"], "tema": "Cómo se conocieron",
		"intenciones": ["Lya: lo saca con una sonrisa, a ver qué recuerda él", "Kael: ofendido de broma",
			"Lya: se defiende con datos", "Kael: la pilla", "Lya: digna, y tierna en la segunda frase",
			"Kael: le da las gracias sin dárselas"]},
	{"id": "charla_cama_grande", "hito": "pv_05", "grupo": ["Kael", "Lya", "Garon"], "tema": "La broma de la cama grande",
		"intenciones": ["Kael: abre el juicio, encantado", "Garon: impasible",
			"Lya: aporta la prueba, sin piedad y con cariño", "Garon: ni un parpadeo", "Kael: no se lo cree",
			"Garon: cierra el caso"]},
	{"id": "charla_miedo_garon", "hito": "pv_06", "grupo": ["Kael", "Lya", "Garon"], "tema": "El miedo de Garon",
		"intenciones": ["Lya: se lo agradece riñéndole", "Garon: corrige, seco", "Kael: curiosidad de verdad, sin broma",
			"Garon: lo dice una vez y no lo repetirá", "Lya: le devuelve la calma",
			"Garon: cuenta de verdad; se ablanda medio segundo"]},
	{"id": "charla_mano", "hito": "pv_07", "grupo": ["Kael", "Lya", "Garon"], "tema": "La mano del brazalete",
		"intenciones": ["Garon: lo ha visto; lo dice como un parte", "Kael: esconde la mano también con la broma",
			"Lya: preocupada de verdad", "Kael: le quita hierro", "Garon: una orden que es cariño",
			"Kael: lo promete, esta vez en serio"]},
	{"id": "charla_miedo_lya", "hito": "mecha_tilo", "grupo": ["Kael", "Lya"], "tema": "El miedo de Lya",
		"intenciones": ["Kael: lo nota y entra con una broma", "Lya: piensa en voz alta",
			"Lya: el miedo, dicho con precisión", "Kael: la cuida con un plan absurdo", "Lya: se ríe sin querer"]},
	{"id": "charla_miedo_kael", "hito": "oak_faroles", "grupo": ["Kael", "Lya"], "tema": "El miedo de Kael",
		"intenciones": ["Lya: lo saca con cuidado", "Kael: desvía", "Kael: el miedo, envuelto en chiste",
			"Lya: no le deja escapar", "Kael: lo acepta en serio"]},
	# las de la Garganta del Diablo: se desbloquean con sus combates fijos («combates_ganados»), no con un hito
	{"id": "charla_puentes", "si": "ganado:garganta_nido", "grupo": ["Kael", "Lya", "Garon"], "tema": "Las cuerdas de los puentes",
		"intenciones": ["Kael: le pilla, encantado", "Garon: la misma excusa de siempre, sin pestañear",
			"Lya: le sigue el juego", "Garon: seco, sin ceder", "Kael: une las dos excusas y se ríe",
			"Garon: le devuelve el golpe; es su forma de reírse"]},
	{"id": "charla_gorthor", "si": "ganado:garganta_gorthor", "grupo": ["Kael", "Lya", "Garon"], "tema": "Delante de Gorthor",
		"intenciones": ["Lya: aún con el susto", "Kael: lo convierte en chiste",
			"Garon: le deja sin escapatoria; lo dice con respeto", "Kael: lo admite a medias",
			"Lya: le da las gracias y le riñe a la vez", "Kael: tierno y terco"]},
]

# ================================================================= misiones pequeñas
# «pasos»: en orden; «hecho», condición que lo da por hecho. «recompensa»: oro, objetos (los de tienda.gd) y
# «noche_gratis» (una noche en el Cuervo sin pagar). Las misiones avanzan con las señales de los diálogos
# ([signal arg="oak:…"]) o de las piezas, por aplicar_senal().
const MISIONES := [
	{"id": "oak_favores", "nombre": "Tres favores para el Cuervo", "quien": "posadera",
		"resumen": "La posadera no da abasto: un barril, flores de Rosa y su cucharón, que tiene Pip.",
		"empieza": "estado:favores", "fin": "hito:oak_favores",
		"pasos": [
			{"id": "barril", "texto": "Sube un barril del patio del Cuervo.", "hecho": "estado:favor_barril"},
			{"id": "flores", "texto": "Pide a Rosa flores para las mesas.", "hecho": "estado:favor_flores"},
			{"id": "cucharon", "texto": "Recupera el cucharón que tiene Pip.", "hecho": "estado:favor_cucharon"},
			{"id": "volver", "texto": "Vuelve con la posadera.", "hecho": "hito:oak_favores"}],
		"recompensa": {"noche_gratis": true, "objetos": {"Poción": 2}},
		"pago": "La posadera invita a una noche y a la cena; su cucharón, recuperado."},
	{"id": "oak_faroles", "nombre": "Los faroles de la ronda", "quien": "bastian",
		"resumen": "Bastián cuenta los faroles de la ciudad. Faltan tres, en la muralla del este.",
		"empieza": "estado:faroles", "fin": "hito:oak_faroles",
		"pasos": [
			{"id": "torre", "texto": "Sube a la Torre de la Campana.", "hecho": "estado:vista_torre"},
			{"id": "farol_1", "texto": "Enciende el primer farol de la ronda.", "hecho": "estado:farol_1"},
			{"id": "farol_2", "texto": "Enciende el segundo farol.", "hecho": "estado:farol_2"},
			{"id": "farol_3", "texto": "Enciende el tercer farol.", "hecho": "estado:farol_3"},
			{"id": "volver", "texto": "Cuéntaselo a Bastián.", "hecho": "hito:oak_faroles"}],
		"recompensa": {},
		"pago": "La muralla se ilumina y Bastián llega a ciento doce. El premio es el cofre de la ronda y la vista."},
	{"id": "oak_secreto_pip", "nombre": "Un secreto por una moneda", "quien": "pip", "tipo": "secreta",
		"resumen": "Pip vende un secreto por una moneda. Es verdad.",
		"empieza": "decision:pip_oak=pagado", "fin": "decision:pip_oak=pagado", "coste": 1,
		"pasos": [{"id": "pagar", "texto": "Paga una moneda a Pip.", "hecho": "decision:pip_oak=pagado"}],
		"recompensa": {},
		"pago": "La grieta del callejón lleva al Patio de las Velas."},
	{"id": "oak_lavanda", "nombre": "Lavanda para el Árbol", "quien": "rosa", "solo_3d": true,
		"resumen": "Rosa quiere lavanda de los Pastos para ponerla a los pies del Árbol Milenario.",
		"empieza": "estado:lavanda", "fin": "hito:oak_lavanda",
		"pasos": [
			{"id": "coger", "texto": "Coge un ramito de lavanda en Pastos Verdes.", "hecho": "estado:lavanda_cogida"},
			{"id": "entregar", "texto": "Llévaselo a Rosa.", "hecho": "hito:oak_lavanda"}],
		# V12 (fase 7; encargos.gd «pistas»): lo que dijo Rosa, para el Diario.
		"pistas": [{"texto": "Rosa: «Antes la lavanda crecía hasta en los tejados. Ahora solo en los Pastos.»",
			"si": "estado:lavanda"}],
		"recompensa": {"objetos": {"Poción": 2}},
		"pago": "Doña Encina: «Hacía años que nadie le traía flores»."},
]
# Dónde se coge la lavanda (fuera de Oakhaven): un detalle que examinar en la región 3D de Pastos Verdes, cerca del
# puesto de Tilo. Solo si Rosa la ha pedido (lavanda_disponible()). Enganche en zonas3d/pastos_verdes_3d.gd.
const LAVANDA := {"lugar": 10, "senal": "oak:lavanda_cogida", "texto": "Un ramito de lavanda de los Pastos. Huele a mañana."}

# ================================================================= cofres hechos a mano (id escrito, premio fijo)
# Premio modesto: un cofre normal de zona.gd da 40-120 monedas, 2 Pociones o 1 Éter.
const COFRES := [
	{"id": "oak_cofre_velas", "casilla": Vector2(20.5, 37.5), "premio": {"objetos": {"Éter": 1, "Incienso de Ceniza": 1}},
		"secreto": "oak_secreto_velas"},
	{"id": "oak_cofre_raices", "casilla": Vector2(43, 3.5), "premio": {"oro": 100, "objetos": {"Poción": 1}},
		"secreto": "oak_secreto_raices"},
	{"id": "oak_cofre_ronda", "casilla": Vector2(76.5, 28.5), "premio": {"objetos": {"Éter": 2}},
		"secreto": "oak_secreto_ronda", "brilla_desde": Vector2(54, 29)},
	{"id": "oak_cofre_requisados", "casilla": Vector2(47, 51), "premio": {"oro": 60, "objetos": {"Poción": 1}},
		"secreto": "oak_secreto_requisados", "nota": "nota_oak_requisados", "si": "cond:kael_salio",
		"bloqueado": "Aldric no te quita ojo. Mejor en otro momento."},
]

# ================================================================= secretos
const SECRETOS := [
	{"id": "oak_secreto_velas", "tipo": "rincón escondido", "nombre": "El Patio de las Velas", "casilla": Vector2(23.5, 35.5),
		"como": "Pip lo vende por una moneda; de lejos solo se ve luz en una grieta del callejón; el brazalete brilla cerca.",
		"premio": "Cofre oak_cofre_velas y la nota del altar.", "cofre": "oak_cofre_velas", "nota": "nota_oak_velas",
		"estado": "estado:grieta"},
	{"id": "oak_secreto_raices", "tipo": "cofre escondido", "nombre": "El cofre de las raíces", "casilla": Vector2(43, 3.5),
		"como": "Un destello entre las hojas, al norte del tronco; se llega rodeando por una raíz estrecha del oeste.",
		"premio": "100 monedas y 1 Poción.", "cofre": "oak_cofre_raices"},
	{"id": "oak_secreto_ronda", "tipo": "cofre a la vista", "nombre": "El cofre de la ronda", "casilla": Vector2(76.5, 28.5),
		"como": "Brilla desde el mercado; se llega subiendo a la Torre de la Campana y recorriendo la ronda.",
		"premio": "2 Éter.", "cofre": "oak_cofre_ronda"},
	{"id": "oak_secreto_requisados", "tipo": "cofre", "nombre": "Los requisados", "casilla": Vector2(47, 51),
		"como": "En el patio de la guardia. Cuando Kael ya ha salido de la ciudad, Aldric mira hacia otro lado.",
		"premio": "60 monedas, 1 Poción y la nota de los requisados.", "cofre": "oak_cofre_requisados",
		"nota": "nota_oak_requisados"},
	# «texto»: el aviso que sale la primera vez mientras no esté la viñeta pintada («texto_pv07»: el de después de PV-07).
	{"id": "oak_vista_torre", "tipo": "vista", "nombre": "Desde la Torre de la Campana", "casilla": Vector2(73.5, 42.5),
		"como": "Al subir a la torre.",
		"premio": "Antes de PV-07, el brillo morado del Portal al sureste y la niebla al norte; después, también la ciudad flotante. Viñeta pintada de 4-6 s que se salta tocando.",
		"estado": "estado:vista_torre",
		"texto": "Al sureste, un brillo morado. Al norte, la niebla.",
		"texto_pv07": "Al sureste, un brillo morado. Al norte, la niebla. Y arriba, la ciudad flotante."},
	{"id": "oak_vista_raices", "tipo": "vista", "nombre": "Desde las raíces", "casilla": Vector2(40, 12.5),
		"como": "La primera vez que se llega a las raíces del Árbol.",
		"premio": "La ciudad entera en la hora azul; los faroles se encienden en ola, de la plaza hacia fuera.",
		"estado": "estado:vista_raices",
		"texto": "Desde las raíces se ve la ciudad entera. Los faroles se encienden en ola."},
]

# ================================================================= piezas (lo que se examina o se usa)
# «si»: cuándo se puede usar; si no, se enseña «texto_sin». «lleva_a»: a dónde pasa Kael (en casillas).
const PIEZAS := [
	{"id": "oak_barril", "nombre": "Barril", "casilla": Vector2(12, 29), "accion": "Subir el barril",
		"si": ["estado:favores", "!estado:favor_barril", "!hito:oak_favores"], "senal": "oak:favor_barril",
		"texto": "Subes el barril a la puerta del Cuervo. Pesa más de lo que parece.",
		"texto_sin": "Barriles de sidra. Huelen a manzana y a madera vieja."},
	{"id": "oak_torre", "nombre": "Torre de la Campana", "casilla": Vector2(73.5, 42.5), "accion": "Subir",
		"si": "", "senal": "oak:torre", "lleva_a": Vector2(76.5, 41.5),
		"texto": "Desde la torre se ve toda la ciudad. Y más allá.", "texto_sin": ""},
	{"id": "oak_ronda_bajar", "nombre": "Escalera de la torre", "casilla": Vector2(76.5, 41.5), "accion": "Bajar",
		"si": "", "senal": "", "lleva_a": Vector2(73.5, 43.5), "texto": "", "texto_sin": ""},
	{"id": "oak_farol_1", "nombre": "Farol de la ronda", "casilla": Vector2(76.5, 38.5), "accion": "Encender",
		"si": ["estado:faroles", "!estado:farol_1"], "senal": "oak:farol_1",
		"texto": "El farol prende. Uno menos.", "texto_sin": "Un farol apagado. La mecha está seca."},
	{"id": "oak_farol_2", "nombre": "Farol de la ronda", "casilla": Vector2(76.5, 34.5), "accion": "Encender",
		"si": ["estado:faroles", "!estado:farol_2"], "senal": "oak:farol_2",
		"texto": "El farol prende. Ya solo falta uno.", "texto_sin": "Un farol apagado. La mecha está seca."},
	{"id": "oak_farol_3", "nombre": "Farol de la ronda", "casilla": Vector2(76.5, 31.5), "accion": "Encender",
		"si": ["estado:faroles", "!estado:farol_3"], "senal": "oak:farol_3",
		"texto": "El farol prende. La muralla entera brilla.", "texto_sin": "Un farol apagado. La mecha está seca."},
	{"id": "oak_grieta", "nombre": "Grieta", "casilla": Vector2(23.5, 35.5), "accion": "Pasar",
		"si": "", "senal": "oak:grieta", "lleva_a": Vector2(23.5, 37),
		"texto": "La grieta se pasa de lado. Al otro lado, luz de velas.", "texto_sin": ""},
	# V10, «La fórmula desaparecida»: tres páginas del cuaderno de Mirta que el viento repartió (tras hablar con Pip).
	{"id": "oak_pagina_1", "nombre": "Página suelta", "casilla": Vector2(18.5, 26), "accion": "Recoger la página",
		"si": ["hito:enc_formula_pip", "!estado:pagina_1"], "senal": "oak:pagina_1",
		"texto": "Una página con letra apretada: «…dos de hierba lunar, nunca tres…».", "texto_sin": ""},
	{"id": "oak_pagina_2", "nombre": "Página suelta", "casilla": Vector2(40, 30), "accion": "Recoger la página",
		"si": ["hito:enc_formula_pip", "!estado:pagina_2"], "senal": "oak:pagina_2",
		"texto": "Pegada a un poste de la Calle Mayor: «…la savia, clara, al final…».", "texto_sin": ""},
	{"id": "oak_pagina_3", "nombre": "Página suelta", "casilla": Vector2(36.5, 12.5), "accion": "Recoger la página",
		"si": ["hito:enc_formula_pip", "!estado:pagina_3"], "senal": "oak:pagina_3",
		"texto": "A los pies del Árbol: «…y removerlo como quien acuna». Firmado: M.", "texto_sin": ""},
	# V11, hito C: el tablón del Gremio de aventureros en la plaza (gremio.gd; lo abre ciudad_oakhaven.gd)
	{"id": "oak_tablon_gremio", "nombre": "Tablón del gremio", "casilla": Vector2(37, 23), "accion": "Leer el tablón",
		"si": "", "senal": "", "texto": "", "texto_sin": ""},
	# V11, hito E: la mesa de juego del Patio del Cuervo (taberna_parejas.gd; lo abre ciudad_oakhaven.gd)
	{"id": "oak_mesa_parejas", "nombre": "Mesa de juego", "casilla": Vector2(14.5, 30.5), "accion": "Jugar a las parejas",
		"si": "", "senal": "", "texto": "", "texto_sin": ""},
	# V12, fase 7 (PROPUESTA): el arcón del Concejo, bajo el pórtico, con su cerradura rúnica (CERRADURA). Abierto, ya
	# solo se examina. Lo abre ciudad_oakhaven.gd (2D) o vida3d.gd (3D).
	{"id": "oak_cerradura_runica", "nombre": "Arcón del Concejo", "casilla": Vector2(50.5, 22), "accion": "Girar los anillos",
		"si": "!estado:cerradura_abierta", "senal": "", "texto": "",
		"texto_sin": "El arcón del Concejo, abierto y vacío. Los anillos ya no giran."},
]

# V12, fase 7 (PROPUESTA, sin canon): la primera cerradura rúnica (cerradura_runica.gd). Un arcón viejo bajo el pórtico
# del Concejo; nadie sabe ya la combinación, pero la tapa la lleva grabada en verso. Los anillos llevan los seis símbolos
# del reino (los de las parejas). La solución sale de la inscripción: Fuego, Cura y Luna. Estado guardado en
# «mazmorras»["oakhaven"] (ninguna clave nueva): «cerradura_vista» (se ha mirado: el Diario apunta la inscripción) y
# «cerradura_abierta» (el premio, una sola vez). Premio modesto: un cofre normal da 40-120 monedas, 2 Pociones o 1 Éter;
# el Mineral rúnico sirve para «El encargo del maestro» del gremio (rango Oro).
const CERRADURA := {"id": "oak_cerradura_runica", "titulo": "El arcón del Concejo",
	"inscripcion": "De fuera adentro: lo que arde, lo que sana y lo que vela de noche.",
	"anillos": [["Runa", "Agua", "Fuego", "Luna", "Rayo", "Cura"], ["Luna", "Cura", "Rayo", "Agua", "Fuego", "Runa"],
		["Agua", "Rayo", "Luna", "Fuego", "Cura", "Runa"]],
	"nombres": ["de fuera", "del medio", "de dentro"], "objetivo": ["Fuego", "Cura", "Luna"], "inicio": [0, 0, 0],
	"premio": {"oro": 60, "objetos": {"Éter": 1, "Mineral rúnico": 1}}}

# ================================================================= notas del Diario (lista aparte: no cuentan para las
# páginas de los actos). Se guardan en «lore_visto» con su id («nota_…»). 15 palabras o menos.
const NOTAS := [
	{"id": "nota_oak_bando", "nombre": "Bando de la plaza", "casilla": Vector2(36, 29),
		"texto": "Bando: por prudencia, no se nombran en voz alta las aldeas perdidas."},
	{"id": "nota_oak_cuervo", "nombre": "Letrero del Cuervo", "casilla": Vector2(13, 25.5),
		"texto": "Un cuervo de hierro oxidado. Chirría con el viento, como si avisara."},
	{"id": "nota_oak_anillos", "nombre": "Raíz cortada", "casilla": Vector2(45, 10),
		"texto": "Miles de anillos en la madera. Uno, muy hondo, es negro como el carbón."},
	{"id": "nota_oak_guardia", "nombre": "Libro de guardia", "casilla": Vector2(42.5, 46.5),
		"texto": "Libro de guardia: «Noche tranquila. Niebla al norte. Dos faroles cambiados.»"},
	{"id": "nota_oak_velas", "nombre": "Altar de las velas", "casilla": Vector2(25.5, 38),
		"texto": "Un anillo partido y velas recién encendidas. Alguien sigue viniendo."},
	{"id": "nota_oak_requisados", "nombre": "Objetos requisados", "cofre": "oak_cofre_requisados",
		"texto": "Requisado: una cinta, tres dados y una carta sin abrir. Sin nombre."},
]

# Señales de los diálogos y de las piezas que entiende aplicar_senal().
const SENALES := ["oak:pip_pagar", "oak:favores_aceptados", "oak:favor_barril", "oak:favor_flores",
	"oak:favor_cucharon", "oak:favores_hechos", "oak:faroles_aceptados", "oak:farol_1", "oak:farol_2", "oak:farol_3",
	"oak:faroles_hechos", "oak:lavanda_pedida", "oak:lavanda_cogida", "oak:lavanda_entregada", "oak:encina_gracias",
	"oak:torre", "oak:grieta", "oak:vista_raices", "oak:sopa", "oak:rumor", "oak:dormir", "oak:encina_bosque", "oak:pip_perro", "oak:pip_perro_fin",
	"oak:servicio_forja", "oak:servicio_armaduras", "oak:servicio_botica", "oak:herrero_pedido", "oak:hierro_entregar",
	"oak:hierro_kael", "oak:formula_pedido", "oak:formula_pip", "oak:pagina_1", "oak:pagina_2", "oak:pagina_3", "oak:formula_fin"]
# Condiciones con nombre (las demás: hito:, estado:, decision:k=v, grupo:, oro:n, modo:3d/2d y ganado:<combate fijo>,
# uno de «combates_ganados», como garganta_gorthor; «!» las niega).
const CONDICIONES := {
	"kael_salio": "Kael ya ha salido de Oakhaven: tras PV-02 con la exploración 3D; sin ella, siempre (empieza fuera)",
	"faroles_encendidos": "los tres faroles de la ronda encendidos",
	"favores_listos": "el barril, las flores y el cucharón",
}
const TIPOS_CONDICION := ["hito", "estado", "decision", "grupo", "oro", "modo", "cond", "ganado"]
const PLURAL := {"Poción": "Pociones", "Éter": "Éter", "Incienso de Ceniza": "Inciensos de Ceniza"}


# ================================================================= consultas

static func npc(id: String) -> Dictionary:
	return _buscar(NPCS, id)


static func mision(id: String) -> Dictionary:
	return _buscar(MISIONES, id)


static func cofre(id: String) -> Dictionary:
	return _buscar(COFRES, id)


static func nota(id: String) -> Dictionary:
	return _buscar(NOTAS, id)


static func pieza(id: String) -> Dictionary:
	return _buscar(piezas_activas(), id)


# Las piezas de la ciudad: PIEZAS y, con el interruptor «oakhaven_propuestas_v12» (APAGADO), las de la propuesta
# (ciudades/oakhaven_propuestas.gd). La ciudad 2D y la 3D ponen estas.
static func piezas_activas() -> Array:
	return PIEZAS + load("res://ciudades/oakhaven_propuestas.gd").piezas()


static func _buscar(lista: Array, id: String) -> Dictionary:
	for d in lista:
		if d["id"] == id:
			return d
	return {}


# Ruta de un diálogo por su id: los cuatro de siempre en dialogos/, los nuevos en dialogos/oakhaven/.
static func ruta_dialogo(id: String) -> String:
	if id == "":
		return ""
	return "res://dialogos/%s.dtl" % id if id in DIALOGOS_CANON else RUTA_DIALOGOS + id + ".dtl"


# Todos los diálogos nuevos de la ciudad (sin los cuatro de siempre).
static func dialogos_nuevos() -> Array:
	var r: Array = []
	for n in NPCS:
		for d in n["dialogos"]:
			if not d["dialogo"] in DIALOGOS_CANON and not d["dialogo"] in r:
				r.append(d["dialogo"])
	for e in ESCENAS_POSADA:
		if not e["dialogo"] in r:
			r.append(e["dialogo"])
	return r


# Qué diálogo toca con este vecino. «veces»: cuántas veces se le ha hablado en esta visita (se turnan).
static func dialogo_de(id: String, veces := 0) -> String:
	var n := npc(id)
	if n.is_empty():
		return ""
	var normales: Array = []
	for d in n["dialogos"]:
		if not cumple(d.get("si", "")):
			continue
		if d.get("prioridad", false):
			return ruta_dialogo(d["dialogo"])
		normales.append(d["dialogo"])
	if normales.is_empty():
		return ""
	return ruta_dialogo(normales[posmod(veces, normales.size())])


# Escena al descansar en la posada, según el grupo activo (grupo.gd).
static func escena_posada() -> String:
	var activos: Array = load("res://grupo.gd").activos()
	for e in ESCENAS_POSADA:
		var todos := true
		for quien in e["grupo"]:
			if not quien in activos:
				todos = false
		if todos:
			return ruta_dialogo(e["dialogo"])
	return ruta_dialogo(ESCENAS_POSADA[-1]["dialogo"])


# La charla de posada que toca esta noche (su id), o "" si no hay ninguna desbloqueada y sin ver.
static func charla_posada() -> String:
	var P = load("res://progreso.gd")
	var activos: Array = load("res://grupo.gd").activos()
	for i in range(CHARLAS_POSADA.size() - 1, -1, -1):
		var c: Dictionary = CHARLAS_POSADA[i]
		if (c.has("hito") and not P.hito(c["hito"])) or (c.has("si") and not cumple(c["si"])) or charla_vista(c["id"]):
			continue
		if c["grupo"].all(func(q): return q in activos):
			return c["id"]
	return ""


static func charla_vista(id: String) -> bool:
	return load("res://progreso.gd").estado(NOMBRE, id)


static func marcar_charla(id: String) -> void:
	load("res://progreso.gd").poner_estado(NOMBRE, id)


static func ruta_charla(id: String) -> String:
	return RUTA_CHARLAS + id + ".dtl"


# La escena al despertar en la posada: la charla que toque (y queda vista) o, si no hay, la de siempre.
static func escena_al_despertar() -> String:
	var c := charla_posada()
	if c == "":
		return escena_posada()
	marcar_charla(c)
	return ruta_charla(c)


# «sin_empezar», «en_curso» o «hecha».
static func estado_mision(id: String) -> String:
	var m := mision(id)
	if m.is_empty():
		return ""
	if cumple(m["fin"]):
		return "hecha"
	return "en_curso" if cumple(m["empieza"]) else "sin_empezar"


# Los pasos de una misión con «hecho» ya evaluado (para un futuro menú de misiones).
static func pasos_mision(id: String) -> Array:
	var r: Array = []
	for p in mision(id).get("pasos", []):
		var c: Dictionary = p.duplicate()
		c["hecho"] = cumple(p["hecho"])
		r.append(c)
	return r


static func lavanda_disponible() -> bool:
	return cumple(["estado:lavanda", "!estado:lavanda_cogida", "!hito:oak_lavanda"])


# ================================================================= condiciones

static func cumple(cond: Variant) -> bool:
	if cond is Array:
		for c in cond:
			if not cumple(c):
				return false
		return true
	var c := str(cond).strip_edges()
	if c == "":
		return true
	if c.begins_with("!"):
		return not cumple(c.substr(1))
	var tipo := c.get_slice(":", 0)
	var valor := c.substr(tipo.length() + 1)
	var P = _p()
	match tipo:
		"hito":
			return P.hito(valor)
		"estado":
			return P.estado(NOMBRE, valor)
		"decision":
			return str(Engine.get_meta("decisiones", {}).get(valor.get_slice("=", 0), "")) == valor.get_slice("=", 1)
		"grupo":
			return valor in load("res://grupo.gd").activos()
		"oro":
			return load("res://inventario.gd").oro() >= int(valor)
		"modo":
			return load("res://modo3d.gd").activo() == (valor == "3d")
		"ganado":
			return P.ganado(valor)
		"cond":
			match valor:
				"kael_salio":
					return P.hito("pv_02") or not load("res://modo3d.gd").activo()
				"faroles_encendidos":
					return P.estado(NOMBRE, "farol_1") and P.estado(NOMBRE, "farol_2") and P.estado(NOMBRE, "farol_3")
				"favores_listos":
					return P.estado(NOMBRE, "favor_barril") and P.estado(NOMBRE, "favor_flores") \
						and P.estado(NOMBRE, "favor_cucharon")
	push_warning("Oakhaven: condición desconocida «%s»" % c)
	return false


# "" si la condición está bien escrita; si no, qué le pasa (lo usan las pruebas).
static func error_condicion(cond: Variant) -> String:
	if cond is Array:
		for c in cond:
			var e := error_condicion(c)
			if e != "":
				return e
		return ""
	var c := str(cond).strip_edges().trim_prefix("!")
	if c == "":
		return ""
	var tipo := c.get_slice(":", 0)
	var valor := c.substr(tipo.length() + 1)
	if not tipo in TIPOS_CONDICION or valor == "":
		return "condición desconocida «%s»" % c
	if tipo == "cond" and not CONDICIONES.has(valor):
		return "condición con nombre desconocida «%s»" % valor
	if tipo == "decision" and valor.get_slice_count("=") != 2:
		return "decisión sin «=valor»: «%s»" % c
	if tipo == "oro" and not valor.is_valid_int():
		return "oro sin número: «%s»" % c
	if tipo == "modo" and not valor in ["3d", "2d"]:
		return "modo desconocido: «%s»" % c
	return ""


# ================================================================= efectos (señales de los diálogos y de las piezas)

# Aplica una señal «oak:…» y devuelve el aviso que enseñar ("" si no hace nada). Cada efecto se aplica una sola vez
# repetir la señal no da dos veces la recompensa (salvo «oak:sopa», que es un servicio que se paga cada vez). Las señales
# de otros sitios (sin «oak:») se ignoran.
static func aplicar_senal(arg: Variant) -> String:
	var s := str(arg)
	if not s.begins_with("oak:"):
		return ""
	var P = _p()
	var k := s.trim_prefix("oak:")
	if s.begins_with("oak:cantero_"):               # V12, fase 7: la propuesta del cantero (apagada: no hace nada)
		return load("res://ciudades/oakhaven_propuestas.gd").aplicar(s)
	match s:
		"oak:sopa":                                   # un servicio de la posada: se repite (ciudades/oakhaven_posada.gd)
			return load("res://ciudades/oakhaven_posada.gd").comer()["texto"]
		"oak:rumor", "oak:dormir":                    # los hace la escena al acabar el diálogo (ciudad_oakhaven.gd)
			return ""
		"oak:pip_pagar":
			if cumple("decision:pip_oak=pagado") or not load("res://inventario.gd").gastar_oro(1):
				return ""
			var d: Dictionary = Engine.get_meta("decisiones", {})
			d["pip_oak"] = "pagado"
			Engine.set_meta("decisiones", d)
			return "Le das una moneda a Pip."
		"oak:servicio_forja", "oak:servicio_armaduras", "oak:servicio_botica":   # V10: la ciudad abre el servicio al acabar
			return ""
		"oak:herrero_pedido":                         # V10, encargo A: Maese Ferro pide el hierro que canta
			if P.hito("enc_herrero_pedido"):
				return ""
			P.poner_hito("enc_herrero_pedido")
			return "Nuevo encargo: «El pedido de Maese Ferro» (Diario, Encargos)."
		"oak:hierro_entregar", "oak:hierro_kael":     # V10, encargo A: la decisión, una vez y con el hierro
			var Inv = load("res://inventario.gd")
			if P.hito("enc_herrero_fin") or Inv.cantidad("Hierro de la Falla") <= 0:
				return ""
			var dec: Dictionary = Engine.get_meta("decisiones", {})
			dec["hierro_ferro"] = "entregado" if s == "oak:hierro_entregar" else "kael"
			Engine.set_meta("decisiones", dec)
			P.poner_hito("enc_herrero_fin")
			if s == "oak:hierro_entregar":
				Inv.gastar("Hierro de la Falla")
				return "El pedido de Maese Ferro: " + _dar({"oro": 80}) + ". Ferro venderá Hierro de la Falla."
			return "El pedido de Maese Ferro: Kael se queda el hierro. Ferro le enseñará a templarlo (forja)."
		"oak:formula_pedido":                         # V10, encargo B: Mirta perdió su cuaderno
			if P.hito("enc_formula_pedido"):
				return ""
			P.poner_hito("enc_formula_pedido")
			return "Nuevo encargo: «La fórmula desaparecida» (Diario, Encargos)."
		"oak:formula_pip":                            # V10, encargo B: Pip vio volar las páginas
			if not P.hito("enc_formula_pedido") or P.hito("enc_formula_pip"):
				return ""
			P.poner_hito("enc_formula_pip")
			return "Pip vio volar tres páginas por la ciudad. Búscalas."
		"oak:pagina_1", "oak:pagina_2", "oak:pagina_3":   # V10, encargo B: cada página, una vez
			if not P.hito("enc_formula_pip") or P.estado(NOMBRE, k):
				return ""
			P.poner_estado(NOMBRE, k)
			var n := 0
			for i in [1, 2, 3]:
				if P.estado(NOMBRE, "pagina_%d" % i):
					n += 1
			if n == 3:
				P.poner_hito("enc_formula_paginas")
				return "Página %d de 3. Ya están todas: volved con Mirta." % n
			return "Página %d de 3 del cuaderno de Mirta." % n
		"oak:formula_fin":                            # V10, encargo B: Lya rehace la fórmula; premio una vez
			if not P.hito("enc_formula_paginas") or P.hito("enc_formula_fin"):
				return ""
			P.poner_hito("enc_formula_fin")
			return "La fórmula desaparecida: " + _dar({"oro": 40, "objetos": {"Bálsamo de Mirta": 2}}) \
				+ ". Mirta venderá su bálsamo y Lya puede investigar la fórmula."
		"oak:pip_perro":                              # V9: Pip pide ayuda; Canela aparece en Pastos Verdes
			if P.hito("enc_perro_pedido"):
				return ""
			P.poner_hito("enc_perro_pedido")
			return "Nuevo encargo: «Canela se ha perdido» (Diario, Encargos)."
		"oak:pip_perro_fin":                          # V9: se la devolvéis; el premio, una sola vez
			if not P.hito("enc_perro_encontrado") or P.hito("enc_perro_devuelto"):
				return ""
			P.poner_hito("enc_perro_devuelto")
			return "Canela se ha perdido: " + _dar(load("res://encargos.gd").de("enc_perro")["m"]["recompensa"]) + "."
		"oak:favores_aceptados":
			return _empezar("favores", "oak_favores")
		"oak:favor_barril", "oak:favor_flores", "oak:favor_cucharon":
			if not P.estado(NOMBRE, "favores") or P.hito("oak_favores") or P.estado(NOMBRE, k):
				return ""
			P.poner_estado(NOMBRE, k)
			var hechos := 0
			for f in ["favor_barril", "favor_flores", "favor_cucharon"]:
				hechos += 1 if P.estado(NOMBRE, f) else 0
			return "Favor hecho (%d de 3)." % hechos
		"oak:favores_hechos":
			if P.hito("oak_favores") or not cumple("cond:favores_listos"):
				return ""
			P.poner_hito("oak_favores")
			return "Tres favores para el Cuervo: " + _dar(mision("oak_favores")["recompensa"]) + "."
		"oak:faroles_aceptados":
			return _empezar("faroles", "oak_faroles")
		"oak:farol_1", "oak:farol_2", "oak:farol_3":
			if not P.estado(NOMBRE, "faroles") or P.estado(NOMBRE, k):
				return ""
			P.poner_estado(NOMBRE, k)
			var encendidos := 0
			for f in ["farol_1", "farol_2", "farol_3"]:
				encendidos += 1 if P.estado(NOMBRE, f) else 0
			return "Farol encendido (%d de 3)." % encendidos
		"oak:faroles_hechos":
			if P.hito("oak_faroles") or not cumple("cond:faroles_encendidos"):
				return ""
			P.poner_hito("oak_faroles")
			return "Misión cumplida: Los faroles de la ronda."
		"oak:lavanda_pedida":
			if P.hito("oak_lavanda"):
				return ""
			return _empezar("lavanda", "oak_lavanda")
		"oak:lavanda_cogida":
			if not lavanda_disponible():
				return ""
			P.poner_estado(NOMBRE, "lavanda_cogida")
			return LAVANDA["texto"]
		"oak:lavanda_entregada":
			if P.hito("oak_lavanda") or not P.estado(NOMBRE, "lavanda_cogida"):
				return ""
			P.poner_hito("oak_lavanda")
			return "Lavanda para el Árbol: " + _dar(mision("oak_lavanda")["recompensa"]) + "."
		"oak:encina_gracias", "oak:torre", "oak:grieta", "oak:vista_raices", "oak:encina_bosque":
			var clave: String = {"encina_gracias": "encina_gracias", "torre": "vista_torre", "grieta": "grieta",
				"vista_raices": "vista_raices", "encina_bosque": "encina_bosque"}[k]
			if not P.estado(NOMBRE, clave):
				P.poner_estado(NOMBRE, clave)
			return ""
	push_warning("Oakhaven: señal desconocida «%s»" % s)
	return ""


static func _empezar(clave: String, id_mision: String) -> String:
	if _p().estado(NOMBRE, clave):
		return ""
	_p().poner_estado(NOMBRE, clave)
	return "Misión: %s." % mision(id_mision)["nombre"]


# Da una recompensa y devuelve cómo decirla: «una noche gratis en el Cuervo, 100 monedas y 2 Pociones».
static func _dar(premio: Dictionary) -> String:
	var inv = load("res://inventario.gd")
	var partes := PackedStringArray()
	if premio.get("noche_gratis", false):
		_p().poner_estado(NOMBRE, "noche_gratis")
		partes.append("una noche gratis en el Cuervo")
	if premio.get("oro", 0) > 0:
		inv.ganar_oro(premio["oro"])
		partes.append("%d monedas" % premio["oro"])
	var objetos: Dictionary = premio.get("objetos", {})
	for o in objetos:
		inv.agregar_objeto(o, objetos[o])
		partes.append("%d %s" % [objetos[o], o if objetos[o] == 1 else PLURAL.get(o, o)])
	if partes.is_empty():
		return ""
	if partes.size() == 1:
		return partes[0]
	return ", ".join(partes.slice(0, partes.size() - 1)) + " y " + partes[partes.size() - 1]


# Abre un cofre hecho a mano: {"texto": aviso, "nota": id de su nota o ""}; {"bloqueado": aviso} si aún no se puede;
# {} si no es de Oakhaven o ya estaba abierto. Cada cofre se abre una sola vez en toda la partida.
static func abrir_cofre(id: String) -> Dictionary:
	var c := cofre(id)
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	if c.is_empty() or abiertos.has(id):
		return {}
	if not cumple(c.get("si", "")):
		return {"bloqueado": c.get("bloqueado", "")}
	abiertos[id] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	var r := {"texto": "¡Has encontrado %s!" % _dar(c["premio"]), "nota": c.get("nota", "")}
	if r["nota"] != "":
		ver_nota(r["nota"])
	return r


# V12, fase 7: la cerradura rúnica del arcón (CERRADURA). ver_cerradura() al abrir la ventana (el Diario apunta la
# inscripción); abrir_cerradura() al resolverla: el premio UNA vez y su texto ("" si ya estaba abierta).
# Las cerraduras se buscan por el id de su pieza (la del arcón y, con la propuesta encendida, la losa del cantero); su
# estado: «<estado>_vista» y «<estado>_abierta» («estado» de la configuración; el arcón, «cerradura»).
static func config_cerradura(id: String) -> Dictionary:
	if id == CERRADURA["id"]:
		return CERRADURA
	return load("res://ciudades/oakhaven_propuestas.gd").cerradura(id)


static func _clave_cerradura(id: String) -> String:
	return str(config_cerradura(id).get("estado", "cerradura"))


static func cerradura_abierta(id: String = CERRADURA["id"]) -> bool:
	return _p().estado(NOMBRE, _clave_cerradura(id) + "_abierta")


static func ver_cerradura(id: String = CERRADURA["id"]) -> void:
	if not _p().estado(NOMBRE, _clave_cerradura(id) + "_vista"):
		_p().poner_estado(NOMBRE, _clave_cerradura(id) + "_vista")


static func abrir_cerradura(id: String = CERRADURA["id"]) -> String:
	var cfg := config_cerradura(id)
	if cfg.is_empty() or cerradura_abierta(id):
		return ""
	ver_cerradura(id)
	_p().poner_estado(NOMBRE, _clave_cerradura(id) + "_abierta")
	if id == CERRADURA["id"]:
		return "Dentro del arcón: %s.%s" % [_dar(cfg["premio"]),
			load("res://ciudades/oakhaven_propuestas.gd").al_abrir_arcon()]
	return "Bajo la losa: %s." % _dar(cfg["premio"])


# Apunta una nota en el Diario (progreso.gd, ver_nota: en «lore_visto»). Devuelve true si es nueva. No completa ningún
# acto.
static func ver_nota(id: String) -> bool:
	return not nota(id).is_empty() and _p().ver_nota(id)


# La noche gratis de «Tres favores para el Cuervo»: true (y se gasta) si quedaba.
static func usar_noche_gratis() -> bool:
	if not _p().estado(NOMBRE, "noche_gratis"):
		return false
	_p().poner_estado(NOMBRE, "noche_gratis", false)
	return true


# ================================================================= Dialogic

# Da a conocer los personajes nuevos a Dialogic en tiempo de juego (como hace el editor en project.godot), para que
# «posadera: …» encuentre su .dch. No escribe nada en disco; si ya están en project.godot, no hace nada.
# En el editor no hace nada: allí Dialogic guardaría project.godot.
static func registrar_dialogic() -> void:
	if Engine.is_editor_hint() or not ResourceLoader.exists("res://addons/dialogic/Core/DialogicResourceUtil.gd"):
		return
	var util = load("res://addons/dialogic/Core/DialogicResourceUtil.gd")
	var dir: Dictionary = util.get_directory("dch").duplicate()
	var cambia := false
	for id in PERSONAJES:
		if not dir.has(id) and ResourceLoader.exists(PERSONAJES[id]):
			dir[id] = PERSONAJES[id]
			cambia = true
	if cambia:
		util.set_directory("dch", dir)


static func _p():
	return load("res://progreso.gd")
