extends RefCounted
# PROPUESTA — NO ESTÁ EN EL JUEGO NI ES CANON (D-073: decisiones pendientes del usuario).
# Lo que cambiaría en ciudades/oakhaven.gd si el usuario aprueba las decisiones de las que depende. Esta carpeta lleva
# .gdignore: Godot no la importa, Dialogic no registra sus personajes ni sus diálogos y no entra en el APK.
# Diseño: docs/diseno/ciudades_y_lugares.md §2.1 y §3.1 (rama area-narrativa). Fuente: biblia v2 §4.7, §7.2 y §7.4.
#
# Para adoptar una parte: mover sus .dtl y .dch a dialogos/oakhaven/ y dialogos/personajes/oakhaven/ (quitando la
# primera línea, el comentario «# PROPUESTA…»), aplicar aquí SUSTITUYE_* y añadir MISIONES, SECRETOS, NOTAS, PIEZAS y
# SENALES a oakhaven.gd. prueba_ciudad_datos.gd ya comprueba estos datos y recorre estos diálogos.

# Decisiones pendientes (DECISIONS.md, D-073; diseño §7) de las que depende cada parte.
const DEPENDE_DE := {
	"olvido": "n.º 1: Olvido, la tabernera que crió a Kael, como posadera de Oakhaven",
	"cripta": "n.º 2: la Cripta de las Urnas bajo el crematorio",
	"rocio": "n.º 3: Aldea Rocío y la misión «El nombre borroso»",
	"pip_guia": "n.º 5: Pip y Lucero como acompañantes ligeros",
	"origen": "el origen de Kael (n.º 1: «crió a Kael») y la semilla de la v2 «Garon salvó al bebé» (acto III)",
}

const PERSONAJES := {
	"olvido": "res://dialogos/oakhaven/propuesta/olvido.dch",
	"hermano_albar": "res://dialogos/oakhaven/propuesta/hermano_albar.dch",
}
const RUTA := "res://dialogos/oakhaven/propuesta/"

# Vecinos que cambian: el id se conserva (la posición y el muñeco, también).
const SUSTITUYE_NPC := {
	"posadera": {"depende": "olvido", "nombre": "Olvido", "corto": "Olvido", "personaje": "olvido",
		"dialogos": [
			{"dialogo": "oak_olvido_deuda_fin", "si": ["cond:favores_listos", "!hito:oak_favores"], "prioridad": true},
			{"dialogo": "oak_olvido_nombre", "si": ["hito:oak_favores", "!hito:rocio_nombre"], "prioridad": true},
			{"dialogo": "oak_olvido"},
			{"dialogo": "oak_olvido_deuda", "si": ["!estado:favores", "!hito:oak_favores"]},
			{"dialogo": "oak_posadera_niebla"}],
		"frases": ["Me llamo Olvido y no se me olvida nada: ni una cara ni una deuda.",
			"Kael, cariño: tres cenas. Las tengo apuntadas con buena letra."]},
	"albar": {"depende": "cripta", "nombre": "Hermano Albar", "corto": "Albar", "personaje": "hermano_albar",
		"dialogos": [{"dialogo": "oak_albar"}, {"dialogo": "oak_hermano_albar"}],
		"frases": ["Recordar duele, muchacho. Nosotros ayudamos a soltar.",
			"La puerta de abajo no es para visitas. Ni para preguntas."]},
}

# Diálogos que cambian (neutro → propuesta).
const SUSTITUYE_DIALOGO := {
	"oak_posadera": "oak_olvido",
	"oak_posadera_favores": "oak_olvido_deuda",
	"oak_posadera_favores_fin": "oak_olvido_deuda_fin",
	"oak_posada_solo": "oak_posada_olvido_solo",
	"oak_posada_lya": "oak_posada_olvido_lya",
	"oak_posada_grupo": "oak_posada_olvido_grupo",
	"oak_pip_secreto": "oak_pip_trampilla",
	"oak_albar_puerta": "oak_hermano_albar",
}

# Misiones que cambian o se añaden.
const MISIONES := [
	{"id": "oak_deuda", "sustituye": "oak_favores", "depende": "olvido", "nombre": "La deuda de Olvido", "quien": "posadera",
		"resumen": "Kael debe tres cenas. Olvido se las cambia por tres favores.",
		"empieza": "estado:favores", "fin": "hito:oak_favores",
		"pasos": [
			{"id": "barril", "texto": "Sube un barril del patio del Cuervo.", "hecho": "estado:favor_barril"},
			{"id": "flores", "texto": "Pide a Rosa flores para las mesas.", "hecho": "estado:favor_flores"},
			{"id": "cucharon", "texto": "Recupera el cucharón que tiene Pip.", "hecho": "estado:favor_cucharon"},
			{"id": "volver", "texto": "Vuelve con Olvido.", "hecho": "hito:oak_favores"}],
		"recompensa": {"noche_gratis": true, "objetos": {"Poción": 2}},
		"pago": "Olvido tacha la deuda… y apunta otra: «Kael, una cena». Queda presentado su libro de cuentas."},
	{"id": "rocio_nombre", "depende": "rocio", "nombre": "El nombre borroso", "quien": "posadera",
		"resumen": "Nadie recuerda cómo se llamaba la aldea del norte. Lo escrito a mano resiste.",
		"empieza": "hito:oak_favores", "fin": "hito:rocio_nombre",
		"pasos": [
			{"id": "mapa", "texto": "Mira el mapa de la taberna.", "hecho": "estado:mapa_visto"},
			{"id": "libro", "texto": "Pide a Olvido su libro de cuentas.", "hecho": "hito:rocio_nombre"}],
		"recompensa": {},
		"pago": "El nombre vuelve al mapa de la taberna y Aldea Rocío aparece en el mapamundi (diseño §3.7)."},
	{"id": "oak_pip_guia", "depende": "pip_guia", "nombre": "Pip, guía de pago", "quien": "pip",
		"resumen": "Por otra moneda, Pip guía hasta la cripta y abre un atajo. En el primer combate, huye.",
		"empieza": "decision:pip_oak=pagado", "fin": "decision:pip_guia=hecho", "coste": 1,
		"pasos": [{"id": "pagar", "texto": "Paga a Pip otra moneda.", "hecho": "decision:pip_guia=hecho"}],
		"recompensa": {},
		"pago": "Pip enseña el atajo de las alcantarillas (diseño §4.4)."},
]

const SECRETOS := [
	{"id": "oak_secreto_trampilla", "depende": "cripta", "tipo": "pasadizo", "nombre": "La trampilla del Cuervo",
		"casilla": Vector2(12, 30), "como": "Pip la vende; aparece al subir el barril; una rejilla del callejón echa aire frío.",
		"premio": "Las alcantarillas y la Cripta de las Urnas (diseño §3.1); se sale al jardín de urnas.",
		"estado": "estado:trampilla"},
]

const PIEZAS := [
	{"id": "oak_trampilla", "depende": "cripta", "nombre": "Trampilla", "casilla": Vector2(12, 30), "accion": "Bajar",
		"si": "estado:favor_barril", "senal": "oak:trampilla",
		"texto": "Debajo del barril, una trampilla. Sale aire frío y huele a ceniza.",
		"texto_sin": "Barriles de sidra. Huelen a manzana y a madera vieja."},
	{"id": "oak_mapa_taberna", "depende": "rocio", "nombre": "Mapa de la taberna", "casilla": Vector2(19, 26),
		"accion": "Mirar", "si": "", "senal": "oak:mapa_visto", "texto": "", "texto_sin": ""},
]

const NOTAS := [
	{"id": "nota_oak_mapa", "depende": "rocio", "nombre": "Mapa de la taberna", "casilla": Vector2(19, 26),
		"texto": "El nombre de la aldea del norte se ha vuelto borroso. ¿Cómo se llamaba?"},
	{"id": "nota_oak_pagina", "depende": "origen", "nombre": "Página arrancada", "casilla": Vector2(42.5, 46.5),
		"sustituye": "nota_oak_guardia",
		"texto": "Libro de guardia: falta una página de hace diecisiete años. Alguien la arrancó."},
	{"id": "nota_oak_urna", "depende": "cripta", "nombre": "La urna de la cinta azul",
		"donde": "Cripta de las Urnas (diseño §3.1), no en la ciudad",
		"texto": "Entre urnas sin nombre, una lleva una cinta azul atada con prisa."},
]

const SENALES := ["oak:rocio_nombre", "oak:mapa_visto", "oak:trampilla", "oak:pip_guia"]
