extends RefCounted
# PROPUESTA NARRATIVA V12 (fase 7, 14/11/2026), SIN CANON Y APAGADA: requiere la aprobación del usuario
# (docs/v12/OAKHAVEN_JUGABLE_V12.md, «Propuestas pendientes», y docs/v12/CANTERO_V12.md). Con el interruptor apagado,
# Oakhaven queda igual que sin este archivo: no hay piezas ni vecinos nuevos, la misión no sale en el Diario y el arcón
# no da la nota.
#
# «Las tres marcas del cantero» (misión secundaria) y la losa del cantero (secreto ambiental con deducción):
#   - Inicio: el aprendiz del cantero, al norte de la plaza (entre la fuente y el pórtico), labra un sillar. Su maestro, el cantero del
#     Concejo, se marchó hace dos inviernos; le dijo que le dejaba su última pieza bajo una losa y la clave en el arcón
#     del Concejo, que nadie sabe abrir. (También empieza si se abre antes el arcón: dentro hay una nota del cantero.)
#   - Las tres marcas son runas talladas donde la ciudad siempre mira (la fuente de la plaza, la puerta de la Torre de la
#     Campana y una raíz del Árbol), cada una con muescas: 1, 2 o 3. Se examinan (interacción) y el Diario las apunta.
#     En la 3D se ven: una placa de piedra con la runa y las muescas (zonas3d/oakhaven/vida3d.gd), y el brazalete brilla
#     cerca de las que faltan.
#   - Deducción: ordenadas por sus muescas, de fuera adentro, dan la combinación de la losa (Rayo, Agua y Luna). Nada lo
#     resuelve solo: el Diario guarda lo leído, no la respuesta.
#   - La losa, entre las raíces, es otra cerradura rúnica (la misma ventana, otra configuración). Se puede intentar en
#     cualquier momento, sin castigo; al abrirla, su premio UNA vez, y el cincel del cantero con una carta.
#   - Resolución: se le llevan al aprendiz. Lee la carta, da las gracias con un saco de Polvo de cantera (material de la
#     Alquimia de Lya: datos/materiales/polvo_cantera.tres, la investigación «La piedra que asienta») y, desde entonces,
#     dice otra cosa (talla su primera marca).
# Estado en «mazmorras»["oakhaven"] (ninguna clave nueva de partida): cantero_pedido, cantero_marca_1..3,
# cantero_marcas, cerradura_cantero_vista, cerradura_cantero_abierta y cantero_fin. Una partida antigua no los trae.
#
# INTERRUPTOR «oakhaven_propuestas_v12», APAGADO por defecto:
#   - Engine.set_meta("oakhaven_propuestas_v12", true)   (antes de entrar en Oakhaven)
#   - el argumento de usuario «oakhaven_propuestas_v12»   (godot ... -- oakhaven_propuestas_v12)
#   - user://ajustes.cfg, [mundo] propuestas_v12 = true    (14/11: SOLO en Auditoría o en el editor, con su opción en
#     Ajustes y en el banco de pruebas, para recorrerla y revisarla; el usuario lo autorizó así. Fuera, apagada)

const NOMBRE := "oakhaven"
const NOMBRE_LUGAR := "Oakhaven"
const ACTIVO_POR_DEFECTO := false

const NOTA := "Dentro, una nota de cantero: «Dejé tres marcas donde la ciudad siempre mira. Léelas por sus muescas.»"
const BAJO_LOSA := " Y, envueltos en un paño, un cincel gastado y una carta: «Para mi aprendiz»."

# El aprendiz del cantero (vecino de la propuesta). «chibi»: su figura de la familia V12 (personajes/npc_v12: el cuerpo
# del herrero, con martillo, y su propio atlas, cantero_aprendiz.png); «hace»: «trabaja» (labra el sillar).
const NPCS := [
	{"id": "cantero", "nombre": "Aprendiz del cantero", "corto": "el aprendiz", "personaje": "cantero",
		"casilla": Vector2(43.4, 23.4), "donde": "Norte de la plaza, entre la fuente y el pórtico del Concejo, junto a un sillar",
		"imagen": "res://personajes/npc/caballero.png", "tinte": Color(0.78, 0.8, 0.86), "escala": 0.9,
		"chibi": ["herrero", "cantero_aprendiz"], "hace": "trabaja",
		"dialogos": [
			{"dialogo": "prop_cantero_fin", "si": ["estado:cerradura_cantero_abierta", "!estado:cantero_fin"],
				"prioridad": true},
			{"dialogo": "prop_cantero_nota", "si": ["estado:cerradura_abierta", "!estado:cantero_pedido",
				"!estado:cerradura_cantero_abierta"], "prioridad": true},
			{"dialogo": "prop_cantero_pedido", "si": ["!estado:cantero_pedido", "!estado:cerradura_cantero_abierta"],
				"prioridad": true},
			{"dialogo": "prop_cantero_pendiente", "si": ["estado:cantero_pedido", "!estado:cerradura_cantero_abierta"]},
			{"dialogo": "prop_cantero_despues", "si": "estado:cantero_fin"}],
		"frases": ["Cuidado con las lascas. Mi maestro, el cantero del Concejo, labró esta fuente y el pórtico.",
			"Mi maestro firmaba con muescas. Una, dos, tres… Nunca se saltaba ninguna."]},
]

const PIEZAS := [
	{"id": "oak_marca_fuente", "nombre": "Marca en la fuente", "casilla": Vector2(41.6, 27.7), "accion": "Examinar la marca",
		"si": "", "senal": "oak:cantero_marca_2",
		"texto": "En el borde de la fuente, una runa de Agua tallada a cincel. Tiene dos muescas.", "texto_sin": ""},
	{"id": "oak_marca_torre", "nombre": "Marca en la torre", "casilla": Vector2(70, 43.5), "accion": "Examinar la marca",
		"si": "", "senal": "oak:cantero_marca_1",
		"texto": "Junto a la puerta de la torre, una runa de Rayo. Una sola muesca.", "texto_sin": ""},
	{"id": "oak_marca_raiz", "nombre": "Marca en la raíz", "casilla": Vector2(39.8, 11.8), "accion": "Examinar la marca",
		"si": "", "senal": "oak:cantero_marca_3",
		"texto": "En la raíz que baja a la calle, una runa de Luna, gastada. Tres muescas.", "texto_sin": ""},
	{"id": "oak_losa_cantero", "nombre": "Losa del cantero", "casilla": Vector2(31.5, 9.5), "accion": "Girar los anillos",
		"si": "!estado:cerradura_cantero_abierta", "senal": "",
		"texto": "", "texto_sin": "La losa del cantero, abierta. Debajo ya no queda nada."},
]

# Las marcas: su runa y sus muescas (las dibuja la 3D; los textos de PIEZAS dicen lo mismo).
const MARCAS := {"oak_marca_fuente": ["Agua", 2], "oak_marca_torre": ["Rayo", 1], "oak_marca_raiz": ["Luna", 3]}

const CERRADURA := {"id": "oak_losa_cantero", "titulo": "La losa del cantero", "estado": "cerradura_cantero",
	"inscripcion": "Lee mis marcas por sus muescas, de fuera adentro.",
	"anillos": [["Agua", "Luna", "Cura", "Runa", "Fuego", "Rayo"], ["Rayo", "Runa", "Agua", "Cura", "Luna", "Fuego"],
		["Cura", "Fuego", "Runa", "Rayo", "Agua", "Luna"]],
	"nombres": ["de fuera", "del medio", "de dentro"], "objetivo": ["Rayo", "Agua", "Luna"], "inicio": [0, 0, 0],
	"abre": "la losa se aparta", "grabado_en": "Grabado en la losa", "premio": {"oro": 80, "objetos": {"Incienso de Ceniza": 1, "Éter": 1}}}

# Lo que da el aprendiz al recibir el cincel y la carta (una vez): el material de la Alquimia de Lya.
const GRACIAS := {"objetos": {"Polvo de cantera": 3}}

# Para el Diario (encargos.gd lo reúne; con el interruptor apagado no empieza nunca).
const MISIONES := [
	{"id": "prop_cantero", "nombre": "Las tres marcas del cantero", "quien": "cantero", "tipo": "secundaria",
		"resumen": "El cantero del Concejo dejó a su aprendiz una última pieza bajo una losa, y tres marcas para abrirla.",
		"empieza": "cond:cantero_empieza",
		"fin": "estado_de:oakhaven/cantero_fin",
		"pasos": [
			{"id": "arcon", "texto": "Abre el arcón del Concejo, bajo el pórtico.",
				"hecho": "cond:cantero_arcon"},   # (o la losa ya abierta: entonces el arcón no hace falta)
			{"id": "marcas", "texto": "Encuentra las tres marcas del cantero por la ciudad.",
				"hecho": "estado_de:oakhaven/cantero_marcas"},
			{"id": "losa", "texto": "Busca la losa del cantero y ábrela con lo que dicen las marcas.",
				"hecho": "estado_de:oakhaven/cerradura_cantero_abierta"},
			{"id": "volver", "texto": "Lleva el cincel y la carta al aprendiz del cantero, en la plaza.",
				"hecho": "estado_de:oakhaven/cantero_fin"}],
		"pistas": [
			{"texto": "El aprendiz: la clave está en el arcón del Concejo; la ciudad siempre mira al agua, a la campana y al Árbol.",
				"si": "estado_de:oakhaven/cantero_pedido"},
			{"texto": "La nota: «Dejé tres marcas donde la ciudad siempre mira. Léelas por sus muescas.»",
				"si": "estado_de:oakhaven/cerradura_abierta"},
			{"texto": "Fuente de la plaza: una runa de Agua con dos muescas.", "si": "estado_de:oakhaven/cantero_marca_2"},
			{"texto": "Puerta de la torre: una runa de Rayo con una muesca.", "si": "estado_de:oakhaven/cantero_marca_1"},
			{"texto": "Raíz del Árbol, junto a la calle: una runa de Luna con tres muescas.", "si": "estado_de:oakhaven/cantero_marca_3"},
			{"texto": "La losa del cantero está entre las raíces del Árbol, al oeste del tronco.",
				"si": "estado_de:oakhaven/cerradura_cantero_vista"}],
		"recompensa": {}, "pago": "El aprendiz guarda el cincel de su maestro y ya talla su primera marca."},
]


static func _p():
	return load("res://progreso.gd")


static func activado() -> bool:
	if Engine.has_meta("oakhaven_propuestas_v12"):
		return bool(Engine.get_meta("oakhaven_propuestas_v12"))
	if "oakhaven_propuestas_v12" in OS.get_cmdline_user_args():
		return true
	if not (OS.has_feature("auditoria") or OS.has_feature("editor")):   # (sin cargar prototipos/)
		return ACTIVO_POR_DEFECTO                   # 14/11: el archivo de ajustes solo cuenta en Auditoría o en el editor
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") != OK:
		return ACTIVO_POR_DEFECTO
	return bool(c.get_value("mundo", "propuestas_v12", ACTIVO_POR_DEFECTO))


# Condiciones propias (encargos.gd las pregunta a este módulo):
#   «cond:propuestas_v12»    el interruptor
#   «cond:cantero_empieza»   el interruptor y, además, el encargo del aprendiz, el arcón abierto o la losa ya abierta
#                            (lo que llegue antes; 15/11: con la losa primero, la misión se quedaba oculta en el Diario
#                            aunque tocaba volver con el aprendiz). Las marcas sueltas NO la empiezan: sin el aprendiz ni
#                            la nota son solo runas gastadas, y sus pistas salen en cuanto empieza.
#   «cond:cantero_arcon»     el paso del arcón, hecho con el arcón abierto o con la losa ya abierta (revisión del 14/11:
#                            si se abría la losa sin el arcón, el Diario seguía mandando al arcón y no decía «volver»)
static func cumple(c: String) -> bool:
	if c == "cond:propuestas_v12":
		return activado()
	if c == "cond:cantero_empieza":
		var P = _p()
		return activado() and (P.estado(NOMBRE, "cantero_pedido") or P.estado(NOMBRE, "cerradura_abierta")
			or P.estado(NOMBRE, "cerradura_cantero_abierta"))
	if c == "cond:cantero_arcon":
		return _p().estado(NOMBRE, "cerradura_abierta") or _p().estado(NOMBRE, "cerradura_cantero_abierta")
	push_warning("Propuestas de Oakhaven: condición desconocida «%s»" % c)
	return false


static func piezas() -> Array:
	return PIEZAS if activado() else []


static func npcs() -> Array:
	return NPCS if activado() else []


static func cerradura(id: String) -> Dictionary:
	return CERRADURA if activado() and id == CERRADURA["id"] else {}


# Lo que se añade al abrir el arcón del Concejo ("" con el interruptor apagado).
static func al_abrir_arcon() -> String:
	return " " + NOTA if activado() else ""


# Al abrir la losa: quien la abre ya leyó (o adivinó) las marcas, así que el paso de las marcas queda hecho; el cincel y
# la carta van con el premio (no son objetos: los lleva Kael hasta el aprendiz).
static func al_abrir_losa() -> String:
	if not activado():
		return ""
	var P = _p()
	var nueva: bool = not (P.estado(NOMBRE, "cantero_pedido") or P.estado(NOMBRE, "cerradura_abierta"))
	P.poner_estado(NOMBRE, "cantero_marcas")
	return BAJO_LOSA + (" Misión: %s." % MISIONES[0]["nombre"] if nueva else "")


# Las señales «oak:cantero_…»: el encargo del aprendiz, las marcas (cada una una vez; con las tres, «cantero_marcas»)
# y el final (el cincel y la carta, con las gracias UNA vez). Con el interruptor apagado no hacen nada.
static func aplicar(s: String) -> String:
	if not activado() or not s.begins_with("oak:cantero_"):
		return ""
	var P = _p()
	var k := s.trim_prefix("oak:")
	if s == "oak:cantero_pedido":
		if P.estado(NOMBRE, "cantero_pedido"):
			return ""
		var nueva: bool = not P.estado(NOMBRE, "cerradura_abierta")     # (con el arcón abierto ya estaba en el Diario)
		P.poner_estado(NOMBRE, "cantero_pedido")
		return "Misión: %s." % MISIONES[0]["nombre"] if nueva else "Diario: lo que cuenta el aprendiz, apuntado."
	if s == "oak:cantero_fin":
		if P.estado(NOMBRE, "cantero_fin") or not P.estado(NOMBRE, "cerradura_cantero_abierta"):
			return ""
		P.poner_estado(NOMBRE, "cantero_fin")
		return "El aprendiz te da %s (para la Alquimia de Lya). Misión cumplida: %s." % [load("res://ciudades/oakhaven.gd")._dar(GRACIAS),
			MISIONES[0]["nombre"]]
	if not s.begins_with("oak:cantero_marca_"):
		push_warning("Propuestas de Oakhaven: señal desconocida «%s»" % s)
		return ""
	if P.estado(NOMBRE, k):
		return ""
	P.poner_estado(NOMBRE, k)
	var n := 0
	for i in [1, 2, 3]:
		n += 1 if P.estado(NOMBRE, "cantero_marca_%d" % i) else 0
	if n == 3:
		P.poner_estado(NOMBRE, "cantero_marcas")
	return "Marca del cantero (%d de 3). Apuntada en el Diario." % n
