extends RefCounted
# PROPUESTA NARRATIVA V12 (fase 7, 14/11/2026), SIN CANON Y APAGADA: requiere la aprobación del usuario
# (docs/v12/OAKHAVEN_JUGABLE_V12.md, «Propuestas pendientes»). Con el interruptor apagado, Oakhaven queda igual que sin
# este archivo: no hay piezas nuevas, la misión no sale en el Diario y el arcón no da la nota.
#
# «Las tres marcas del cantero» (misión secundaria) y la losa del cantero (secreto ambiental con deducción):
#   - Al abrir el arcón del Concejo (la cerradura rúnica, ciudades/oakhaven.gd CERRADURA) hay, además, una nota de un
#     cantero: dejó tres marcas en la ciudad y una losa que solo se abre leyéndolas en orden. Empieza la misión.
#   - Las tres marcas son runas talladas donde la ciudad siempre mira (la fuente de la plaza, la puerta de la Torre de la
#     Campana y una raíz del Árbol), cada una con muescas: 1, 2 o 3. Se examinan (interacción) y el Diario las apunta.
#   - Deducción: ordenadas por sus muescas, de fuera adentro, dan la combinación de la losa (Rayo, Agua y Luna). Nada lo
#     resuelve solo: el Diario guarda lo leído, no la respuesta.
#   - La losa, entre las raíces, es otra cerradura rúnica (la misma ventana, otra configuración). Se puede intentar en
#     cualquier momento, sin castigo; al abrirla, su premio UNA vez.
# Estado en «mazmorras»["oakhaven"] (ninguna clave nueva): cantero_marca_1..3, cantero_marcas, cerradura_cantero_vista,
# cerradura_cantero_abierta. Una partida antigua no los trae: todo por descubrir.
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

const PIEZAS := [
	{"id": "oak_marca_fuente", "nombre": "Marca en la fuente", "casilla": Vector2(42.2, 26), "accion": "Examinar la marca",
		"si": "", "senal": "oak:cantero_marca_2",
		"texto": "En el borde de la fuente, una runa de Agua tallada a cincel. Tiene dos muescas.", "texto_sin": ""},
	{"id": "oak_marca_torre", "nombre": "Marca en la torre", "casilla": Vector2(70, 43.5), "accion": "Examinar la marca",
		"si": "", "senal": "oak:cantero_marca_1",
		"texto": "Junto a la puerta de la torre, una runa de Rayo. Una sola muesca.", "texto_sin": ""},
	{"id": "oak_marca_raiz", "nombre": "Marca en la raíz", "casilla": Vector2(33, 5.5), "accion": "Examinar la marca",
		"si": "", "senal": "oak:cantero_marca_3",
		"texto": "En una raíz del Árbol, una runa de Luna, gastada. Tres muescas.", "texto_sin": ""},
	{"id": "oak_losa_cantero", "nombre": "Losa del cantero", "casilla": Vector2(31.5, 9.5), "accion": "Girar los anillos",
		"si": "!estado:cerradura_cantero_abierta", "senal": "",
		"texto": "", "texto_sin": "La losa del cantero, abierta. Debajo ya no queda nada."},
]

const CERRADURA := {"id": "oak_losa_cantero", "titulo": "La losa del cantero", "estado": "cerradura_cantero",
	"inscripcion": "Lee mis marcas por sus muescas, de fuera adentro.",
	"anillos": [["Agua", "Luna", "Cura", "Runa", "Fuego", "Rayo"], ["Rayo", "Runa", "Agua", "Cura", "Luna", "Fuego"],
		["Cura", "Fuego", "Runa", "Rayo", "Agua", "Luna"]],
	"nombres": ["de fuera", "del medio", "de dentro"], "objetivo": ["Rayo", "Agua", "Luna"], "inicio": [0, 0, 0],
	"premio": {"oro": 80, "objetos": {"Incienso de Ceniza": 1, "Éter": 1}}}

# Para el Diario (encargos.gd lo reúne; con el interruptor apagado no empieza nunca).
const MISIONES := [
	{"id": "prop_cantero", "nombre": "Las tres marcas del cantero", "quien": "", "tipo": "secundaria",
		"resumen": "En el arcón del Concejo había una nota: un cantero dejó tres marcas en la ciudad y una losa cerrada.",
		"empieza": ["cond:propuestas_v12", "estado_de:oakhaven/cerradura_abierta"],
		"fin": "estado_de:oakhaven/cerradura_cantero_abierta",
		"pasos": [
			{"id": "marcas", "texto": "Encuentra las tres marcas del cantero por la ciudad.", "hecho": "estado_de:oakhaven/cantero_marcas"},
			{"id": "losa", "texto": "Busca la losa del cantero y ábrela con lo que dicen las marcas.",
				"hecho": "estado_de:oakhaven/cerradura_cantero_abierta"}],
		"pistas": [
			{"texto": "La nota: «Dejé tres marcas donde la ciudad siempre mira. Léelas por sus muescas.»",
				"si": "estado_de:oakhaven/cerradura_abierta"},
			{"texto": "Fuente de la plaza: una runa de Agua con dos muescas.", "si": "estado_de:oakhaven/cantero_marca_2"},
			{"texto": "Puerta de la torre: una runa de Rayo con una muesca.", "si": "estado_de:oakhaven/cantero_marca_1"},
			{"texto": "Raíz del Árbol: una runa de Luna con tres muescas.", "si": "estado_de:oakhaven/cantero_marca_3"},
			{"texto": "La losa del cantero está entre las raíces del Árbol, al oeste del tronco.",
				"si": "estado_de:oakhaven/cerradura_cantero_vista"}],
		"recompensa": {}, "pago": "La losa del cantero está abierta. Las marcas siguen ahí, para quien sepa leerlas."},
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


# Condiciones propias (encargos.gd las pregunta a este módulo): «cond:propuestas_v12» = el interruptor.
static func cumple(c: String) -> bool:
	if c == "cond:propuestas_v12":
		return activado()
	push_warning("Propuestas de Oakhaven: condición desconocida «%s»" % c)
	return false


static func piezas() -> Array:
	return PIEZAS if activado() else []


static func cerradura(id: String) -> Dictionary:
	return CERRADURA if activado() and id == CERRADURA["id"] else {}


# Lo que se añade al abrir el arcón del Concejo ("" con el interruptor apagado).
static func al_abrir_arcon() -> String:
	return " " + NOTA if activado() else ""


# Las señales «oak:cantero_…» (las marcas). Cada marca se apunta una vez; con las tres, «cantero_marcas».
static func aplicar(s: String) -> String:
	if not activado() or not s.begins_with("oak:cantero_marca_"):
		return ""
	var P = _p()
	var k := s.trim_prefix("oak:")
	if P.estado(NOMBRE, k):
		return ""
	P.poner_estado(NOMBRE, k)
	var n := 0
	for i in [1, 2, 3]:
		n += 1 if P.estado(NOMBRE, "cantero_marca_%d" % i) else 0
	if n == 3:
		P.poner_estado(NOMBRE, "cantero_marcas")
	return "Marca del cantero (%d de 3). Apuntada en el Diario." % n
