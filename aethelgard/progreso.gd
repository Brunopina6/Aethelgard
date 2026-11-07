extends RefCounted
# Progreso de la partida (Godot 4.x), según el documento «Diseño de juego de Aethelgard»:
#   Ritmo sin grinding: nivel de cada zona, encuentros que suben despacio, experiencia que se
#     ajusta al nivel (ponerse al día / sin regalo por pasarse / los jefes dan mucho) e Incienso de Ceniza.
#   Lore ambiental: detalles que se examinan en cada lugar; el Diario los recoge y, con todos los de un
#     acto, se desbloquea una escena extra.
#   Guardado automático en user://partida.save: al entrar en cada zona, al volver al mapa, tras cada
#     combate y al cerrar la app. Al abrir el juego se vuelve justo donde estabas.
# Uso:  var Progreso = load("res://progreso.gd");  Progreso.mult_exp(...)

# Nivel recomendado de cada zona (tabla de actos: I 1→8, II 8→20, III 20→30, IV 30→38).
const NIVEL_ZONA := {"llanura": 2, "bosque": 4, "montana": 7, "garganta": 7, "desierto": 10, "nieve": 15,
	"yermo": 18, "ceniza": 34, "ciudad": 0}
const PASOS_SUBIDA := 60        # tras los pasos seguros, la probabilidad de encuentro sube despacio
const DIF_LIMPIA := 5           # niveles por encima de la zona: «zona limpia» y casi sin experiencia
const PROB_LIMPIA := 0.15       # en zona limpia salen muchos menos encuentros
const EXP_POR_ENCIMA := 0.1     # experiencia con 5 niveles o más por encima de la zona
const MULT_JEFE := 10.0         # un jefe da como unos 10 combates normales
const PASOS_INCIENSO := 150     # pasos sin encuentros con el Incienso de Ceniza
const INCIENSO := "Incienso de Ceniza"

# Detalles de lore de cada lugar (índice de LUGARES de mapa.gd). Una frase al examinar, 15 palabras o menos.
# "donde": en qué rincón de la zona se pone (ruinas, campamento, claro o plaza en las ciudades).
const DETALLES := {
	0: [{"id": "oak_sello", "nombre": "Sello del crematorio", "donde": "plaza",
			"texto": "Un sello rúnico roto con un anillo partido. Alguien raspó los nombres."},
		{"id": "oak_tapiz", "nombre": "Tapiz de los reyes", "donde": "plaza2",
			"texto": "Un tapiz viejo de la familia real. Han recortado a un niño de la tela."}],
	1: [{"id": "bosque_armadura", "nombre": "Armadura del árbol", "donde": "ruinas",
			"texto": "Un árbol abraza una armadura antigua. Su brazo izquierdo es de oro."}],
	2: [{"id": "garganta_puentes", "nombre": "Pilares de los puentes", "donde": "p2",
			"texto": "Cada pilar del puente lleva el anillo partido, más gastado cuanto más lejos."},
		{"id": "garganta_pilar", "nombre": "Pilar del peregrino", "donde": "p8",
			"texto": "El anillo partido, grabado en el pilar, gastado por miles de manos."}],
	3: [{"id": "ciclopea_estatua", "nombre": "Estatua sin brazo", "donde": "ruinas",
			"texto": "Un caballero de piedra sin brazo izquierdo. Mira hacia el pico."}],
	4: [{"id": "calid_maquina", "nombre": "Máquina enterrada", "donde": "ruinas",
			"texto": "Tubos de una máquina antigua que acaban en un hueco con forma de brazalete."}],
	5: [{"id": "sunken_contratos", "nombre": "Contratos del Águila", "donde": "plaza",
			"texto": "Contratos de la Compañía del Águila, firmados con el sello de la corona."}],
	7: [{"id": "templo_mural", "nombre": "Mural del Templo", "donde": "ruinas",
			"texto": "Una sacerdotisa con un bebé. Los reyes le ciñen un anillo al niño."}],
	# Pastos Verdes (región 3D de la rama experimental; texto propuesto en la biblia v3 §6.3, PV-04, no canon).
	10: [{"id": "pastos_estela", "nombre": "Estela del camino", "donde": "ruinas",
			"texto": "El anillo partido y nombres raspados. Uno de los raspados es reciente."}],
}
# Actos: qué lugares entran y la escena extra que se desbloquea con todos sus detalles.
const ACTOS := [
	{"nombre": "Acto I · Las Cenizas", "lugares": [0, 1, 2], "escena": "El primer portador",
		"texto": "Un caballero de brazo dorado cruzó la Garganta con el Sello. El bosque guardó lo que quedó de él. En Oakhaven, alguien se aseguró de que nadie recordara su nombre."},
	{"nombre": "Acto II · Las Reliquias", "lugares": [4, 5, 3, 7], "escena": "El niño del anillo",
		"texto": "El Sello alimentaba las máquinas de los reyes y devoraba a quien lo llevaba. Para la última pieza no buscaron un caballero: buscaron un niño."},
]
const GUARDADO := "user://partida.save"
# La versión experimental (exploración 3D, modo3d.gd) guarda en otro archivo: nunca toca la partida estable,
# ni siquiera en el PC, donde las dos comparten la carpeta user:// (el proyecto se llama igual).
const GUARDADO_EXP := "user://partida_exp.save"
# Datos de Engine que forman la partida. Las claves nuevas solo se añaden: una partida antigua carga igual
# (faltan y se usan los valores por defecto) y una nueva en una versión antigua deja esas claves sin leer.
const CLAVES := ["grupo", "inventario", "cofres_abiertos", "prologo_visto", "lugar", "pos_mapa", "pos_mapa_ok",
	"pos_zona", "pos_zona_ok", "pos_zona_lugar", "lore_visto", "incienso", "escena_guardada",
	"mazmorras", "combates_ganados", "decisiones", "pos_isla", "pos_isla_ok",
	"hitos", "pos_3d", "pos_3d_ok", "pos_3d_lugar"]
const MAPA := "res://mapa.tscn"


# Archivo de la partida: el de la versión experimental si la exploración 3D está activa.
static func archivo() -> String:
	return GUARDADO_EXP if load("res://modo3d.gd").activo() else GUARDADO


# ================================================================= ritmo

static func nivel_grupo() -> int:
	var gr = load("res://grupo.gd")
	var total := 0
	for n in gr.miembros():
		total += int(gr.datos()[n]["nivel"])
	return maxi(1, roundi(float(total) / maxi(1, gr.miembros().size())))


static func nivel_zona(zona: String) -> int:
	return NIVEL_ZONA.get(zona, 1)


# «Zona limpia»: el grupo va 5 niveles o más por encima. Los enemigos débiles huyen solos.
static func zona_limpia(zona: String) -> bool:
	return nivel_grupo() >= nivel_zona(zona) + DIF_LIMPIA


# Probabilidad de encuentro en este paso: nada en los pasos seguros, luego sube despacio.
static func prob_encuentro(base: float, pasos: int, pasos_min: int, zona: String) -> float:
	if pasos < pasos_min or incienso_activo():
		return 0.0
	var p := base * clampf(float(pasos - pasos_min) / PASOS_SUBIDA, 0.2, 1.0)
	if zona_limpia(zona):
		p *= PROB_LIMPIA
	return p


# Experiencia: hasta el doble si el héroe va por debajo de la zona, muy poca si va 5 o más por
# encima, y los jefes dan como unos 10 combates.
static func mult_exp(zona: String, tipo_combate: String, nivel_heroe: int) -> float:
	var m := MULT_JEFE if tipo_combate in ["jefe", "superjefe"] else 1.0
	var nz := nivel_zona(zona)
	if nivel_heroe < nz:
		m *= 1.0 + minf(1.0, (nz - nivel_heroe) * 0.25)
	elif nivel_heroe >= nz + DIF_LIMPIA:
		m *= EXP_POR_ENCIMA
	return m


# ---------------------------------------------------------------- Incienso de Ceniza

static func usar_incienso() -> void:
	Engine.set_meta("incienso", PASOS_INCIENSO)


static func incienso_activo() -> bool:
	return int(Engine.get_meta("incienso", 0)) > 0


# Lo llaman el mapa y las zonas en cada paso. Devuelve true el paso en que se acaba.
static func paso_incienso() -> bool:
	var n := int(Engine.get_meta("incienso", 0))
	if n <= 0:
		return false
	Engine.set_meta("incienso", n - 1)
	return n == 1


# ================================================================= lore

static func detalles_de(lugar: int) -> Array:
	return DETALLES.get(lugar, [])


static func visto(id: String) -> bool:
	return Engine.get_meta("lore_visto", {}).has(id)


# Apunta un detalle. Devuelve el acto completado con él (o {} si no completa ninguno).
static func ver_detalle(id: String) -> Dictionary:
	var v: Dictionary = Engine.get_meta("lore_visto", {})
	if v.has(id):
		return {}
	v[id] = true
	Engine.set_meta("lore_visto", v)
	for a in ACTOS:
		var ids := _ids_acto(a)
		if id in ids and ids.all(func(x): return v.has(x)):
			return a
	return {}


static func acto_completo(a: Dictionary) -> bool:
	return _ids_acto(a).all(func(x): return visto(x))


static func _ids_acto(a: Dictionary) -> Array:
	var ids: Array = []
	for l in a["lugares"]:
		for d in detalles_de(l):
			ids.append(d["id"])
	return ids


# ================================================================= mazmorras y combates fijos

# Estado de una mazmorra (palancas, puertas...): Engine.get_meta("mazmorras")[nombre][clave].
static func estado(mazmorra: String, clave: String) -> bool:
	return Engine.get_meta("mazmorras", {}).get(mazmorra, {}).get(clave, false)


static func poner_estado(mazmorra: String, clave: String, valor := true) -> void:
	var m: Dictionary = Engine.get_meta("mazmorras", {})
	if not m.has(mazmorra):
		m[mazmorra] = {}
	m[mazmorra][clave] = valor
	Engine.set_meta("mazmorras", m)


# Combates fijos (jefes, nidos...) ya ganados: no se repiten.
static func ganado(id: String) -> bool:
	return Engine.get_meta("combates_ganados", {}).has(id)


# ================================================================= hitos de la historia

# Hitos de la historia (biblia v3: «hitos.<id>»). Se guardan en la partida; los que faltan valen false.
static func hito(id: String) -> bool:
	return Engine.get_meta("hitos", {}).get(id, false)


static func poner_hito(id: String) -> void:
	var h: Dictionary = Engine.get_meta("hitos", {})
	h[id] = true
	Engine.set_meta("hitos", h)


# ================================================================= guardado

static func hay_partida() -> bool:
	return FileAccess.file_exists(archivo())


# Lo que se guarda: las CLAVES que haya en Engine. Lo usan guardar() y las pruebas (que no escriben archivos).
static func volcar(escena := "") -> Dictionary:
	if escena != "":
		Engine.set_meta("escena_guardada", escena)
	var d := {}
	for k in CLAVES:
		if Engine.has_meta(k):
			d[k] = Engine.get_meta(k)
	return d


# Guarda la partida. "escena" = dónde se vuelve al abrir el juego (el mapa o la zona).
static func guardar(escena := "") -> void:
	if "--script" in OS.get_cmdline_args() or not OS.get_cmdline_user_args().is_empty():
		return                                     # las pruebas no tocan la partida de verdad
	var d := volcar(escena)
	var f := FileAccess.open(archivo(), FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar la partida")
		return
	f.store_string(var_to_str(d))


# Pone en Engine una partida ya leída y devuelve la escena a la que volver. Si esa escena no existe en esta
# versión (por ejemplo, una región 3D en una versión sin exploración 3D), se vuelve al mapa sin error.
static func restaurar(d: Dictionary) -> String:
	for k in d:
		Engine.set_meta(k, d[k])
	var escena: String = d.get("escena_guardada", MAPA)
	if not ResourceLoader.exists(escena) or (escena.begins_with("res://zonas3d/") and not load("res://modo3d.gd").activo()):
		escena = MAPA
	if escena != MAPA:
		Engine.set_meta("pos_zona_ok", true)        # vuelve al mismo sitio de la zona o la mazmorra
	return escena


# Carga la partida guardada. Devuelve la escena donde estabas ("" si no hay partida).
static func cargar() -> String:
	if not hay_partida():
		return ""
	var d = str_to_var(FileAccess.get_file_as_string(archivo()))
	if not d is Dictionary:
		push_warning("La partida guardada no se pudo leer")
		return ""
	return restaurar(d)
