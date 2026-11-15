extends RefCounted
# V12, mapamundi 3D (15/11/2026): datos y reglas de la PRIMERA REGIÓN del mapamundi 3D explorable, «Tierras de Oakhaven».
# EXPERIMENTAL DE AUDITORÍA, APAGADO POR DEFECTO (modo3d.gd, mapamundi_activo): sin la opción, el mapa de siempre
# (mapa.tscn) queda exactamente igual. Todo lo nuevo (campamento, cueva, secreto, nombres) es PROPUESTA, no canon.
#
# La región es el trozo del mapa 2D (mapa.gd, mapa_zonas.png) que rodea a Oakhaven y Pastos Verdes, a escala: un píxel
# del mapa 2D son ESCALA metros. Así la costa, las praderas y los bosques salen de la misma máscara que el mapa 2D y las
# posiciones relativas de Oakhaven (520, 330), el Portal del Vacío (650, 405), Pastos Verdes (660, 478) y el camino al
# Gran Bosque Verde (720, 540) se respetan.
#
# Guardado: en la clave EXISTENTE «mazmorras» de la partida (progreso.gd, estado/poner_estado), en mazmorras["mapamundi"]
# (un diccionario de sí/no). Sin ella (partidas antiguas) no hay nada descubierto ni ningún destino de viaje: nada se
# revela. Posición dentro del mapamundi: pos_3d con pos_3d_lugar = INDICE (como las regiones 3D).

const ESCENA := "res://zonas3d/mapamundi_3d.tscn"
const CUEVA := "res://zonas3d/cueva_provisional_3d.tscn"
const MAPA := "res://mapa.tscn"
const INDICE := 100                      # pos_3d_lugar del mapamundi (no es un lugar de mapa.gd: esos van de 0 a 10)
const INDICE_CUEVA := 101                # pos_3d_lugar de la cueva provisional
const CLAVE := "mapamundi"               # mazmorras["mapamundi"] (progreso.gd)
const LLEGADA := "mm3d_llegada"          # Engine: junto a qué entrada aparece Kael al volver de una ubicación (de la sesión)
const REGION := "Tierras de Oakhaven"
const CONTINENTE := "Norte"              # estructura futura: Norte, Oeste, Sur y Este (docs/v12/MAPAMUNDI_3D_V12.md)

# Escala y encuadre del trozo del mapa 2D
const ORIGEN_2D := Vector2(565, 400)     # el centro de la región en el mapa 2D (2400 × 1350)
const ESCALA := 0.25                     # metros por píxel del mapa 2D
const ANDABLE := Rect2(-55.0, -50.0, 112.0, 98.0)   # metros (x, z): fuera, bruma y borde de la maqueta

# Los sitios de la región, en metros (x, z). «entrada»: el círculo dorado que se pisa para entrar; «llegada»: donde
# aparece Kael al volver, fuera del círculo (la entrada no se arma hasta alejarse: sin reentradas automáticas).
# «lugar»: el índice del lugar del mapa 2D (mapa.gd LUGARES / LUGAR_PASTOS) o -1.
const SITIOS := {
	"oakhaven": {"nombre": "Oakhaven", "centro": Vector2(-11.25, -17.5), "entrada": Vector2(-11.25, -8.4),
		"llegada": Vector2(-9.6, -5.6), "lugar": 0, "radio_descubrir": 0.0},
	"pastos": {"nombre": "Pastos Verdes", "centro": Vector2(27.6, 14.6), "entrada": Vector2(24.6, 16.9),
		"llegada": Vector2(23.0, 19.3), "lugar": 10, "radio_descubrir": 0.0},
	"campamento": {"nombre": "Campamento de Pastos Verdes", "centro": Vector2(10.6, 16.4), "entrada": Vector2.INF,
		"llegada": Vector2(13.4, 13.6), "lugar": -1, "radio_descubrir": 5.0},
	"cueva": {"nombre": "Cueva de los Helechos", "centro": Vector2(-31.2, -8.6), "entrada": Vector2(-28.9, -7.0),
		"llegada": Vector2(-26.6, -5.2), "lugar": -1, "radio_descubrir": 7.0},
	"secreto": {"nombre": "Corro de los Mirlos", "centro": Vector2(-24.0, 11.0), "entrada": Vector2.INF,
		"llegada": Vector2(-22.5, 9.5), "lugar": -1, "radio_descubrir": 2.2},
	"portal": {"nombre": "Portal del Vacío", "centro": Vector2(21.25, 1.25), "entrada": Vector2(21.25, 3.1),
		"llegada": Vector2(20.6, 5.6), "lugar": 9, "radio_descubrir": 0.0},
	"gran_bosque": {"nombre": "Hacia el Gran Bosque Verde", "centro": Vector2(51.0, 41.2), "entrada": Vector2(51.0, 41.2),
		"llegada": Vector2(46.8, 38.0), "lugar": 1, "radio_descubrir": 0.0},
}

# Viaje rápido, primera entrega: Oakhaven y el campamento de Pastos Verdes. Se llega a «llegada» del sitio, en el
# mapamundi, fuera de su entrada. «requiere»: hito de la historia que hace falta (vacío = ninguno). Las barreras de
# progresión se escriben aquí cuando existan (p. ej. un destino que no se puede usar hasta cierto capítulo).
const DESTINOS := {
	"oakhaven": {"region": REGION + " · " + CONTINENTE, "requiere": ""},
	"campamento": {"region": REGION + " · Pastos Verdes", "requiere": ""},
}
const ORDEN_DESTINOS := ["oakhaven", "campamento"]

# El camino principal (Oakhaven → campamento → Pastos Verdes → el Gran Bosque), la bifurcación hacia la cueva y la
# senda casi borrada del secreto (solo unas losas sueltas). En metros (x, z).
const CAMINO := [Vector2(-11.25, -9.4), Vector2(-9.6, -5.2), Vector2(-5.8, -1.9), Vector2(-0.6, 0.8),
	Vector2(4.0, 4.2), Vector2(8.2, 8.8), Vector2(12.6, 12.4), Vector2(17.6, 15.6), Vector2(22.4, 18.6),
	Vector2(26.8, 22.4), Vector2(31.2, 27.0), Vector2(37.2, 31.6), Vector2(44.0, 36.4), Vector2(50.0, 40.6),
	Vector2(57.0, 45.6)]
const BIFURCACION := Vector2(-0.6, 0.8)
const SENDA_CUEVA := [Vector2(-0.6, 0.8), Vector2(-6.2, 1.8), Vector2(-12.0, 0.6), Vector2(-17.6, -1.6),
	Vector2(-23.0, -4.2), Vector2(-28.4, -6.6)]
const SENDA_SECRETA := [Vector2(-14.6, -0.2), Vector2(-16.6, 3.4), Vector2(-19.4, 6.8), Vector2(-22.6, 9.6)]

# Encuentros por el camino, como en el mapa 2D (mapa.gd): un «paso» cada 20 px del mapa 2D = 5 m aquí, los mismos
# pasos seguros y la misma probabilidad (progreso.gd). Cerca de los sitios no hay (como en las ciudades del mapa 2D).
const LONG_PASO := 20.0 * ESCALA
const PASOS_MIN := 40
const PROB_ENCUENTRO := 0.01
const SIN_ENCUENTROS_CERCA := 6.0        # metros alrededor de cada sitio

# El hallazgo del secreto (PROPUESTA): una sola vez en la partida, como un cofre (cofres_abiertos).
const ID_SECRETO := "mm3d_corro_mirlos"
const ID_CUEVA := "mm3d_cueva_helechos"  # el brillo del fondo de la cueva provisional


static func a_3d(p: Vector2) -> Vector2:
	return (p - ORIGEN_2D) * ESCALA


static func a_2d(p: Vector2) -> Vector2:
	return p / ESCALA + ORIGEN_2D


static func plano(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


# ================================================================= descubrimientos (partida: mazmorras["mapamundi"])

static func _P():
	return load("res://progreso.gd")


static func descubierto(id: String) -> bool:
	return _P().estado(CLAVE, id)


# Lo apunta y devuelve si es nuevo.
static func descubrir(id: String) -> bool:
	if descubierto(id):
		return false
	_P().poner_estado(CLAVE, id)
	return true


static func estado_partida() -> Dictionary:
	var m = Engine.get_meta("mazmorras", {})
	return (m.get(CLAVE, {}) as Dictionary).duplicate() if m is Dictionary and m.get(CLAVE) is Dictionary else {}


# Los destinos de viaje rápido que la partida ya conoce, en orden. Los desconocidos no aparecen (ni su nombre).
static func destinos_conocidos() -> Array:
	var r: Array = []
	for id in ORDEN_DESTINOS:
		if descubierto(id):
			r.append(id)
	return r


# Por qué no se puede viajar ahora ("" si se puede). «escena»: la escena actual (el mapamundi).
static func motivo_bloqueo(escena: Node) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var actual: Node = tree.current_scene if tree != null else null
	if actual != null and actual.scene_file_path == "res://combate.tscn":
		return "No puedes viajar durante un combate."
	if escena != null and escena.get("en_encuentro") == true:
		return "No puedes viajar durante un combate."
	var dg = tree.root.get_node_or_null("Dialogic") if tree != null else null
	if dg != null and dg.current_timeline != null:
		return "No puedes viajar mientras dura una escena."
	if escena != null and escena.get("cinematica") == true:
		return "No puedes viajar mientras dura una escena."
	if escena != null and escena.get("saliendo") == true:
		return "Espera a terminar de llegar."
	if not Engine.get_meta("prologo_visto", false) and not Engine.has_meta("mm3d_sin_prologo"):
		return "Todavía no: la historia acaba de empezar. Termina el prólogo."
	return ""


# Por qué no se puede ir a ese destino ("" si se puede): desconocido, sin su hito o ya estás allí.
static func motivo_destino(id: String, desde: Vector2 = Vector2.INF, destinos: Dictionary = DESTINOS) -> String:
	if not destinos.has(id) or not descubierto(id):
		return "Ese destino no está disponible."
	var req: String = destinos[id].get("requiere", "")
	if req != "" and not _P().hito(req):
		return "Aún no puedes volver allí: la historia todavía no lo permite."
	if desde != Vector2.INF and desde.distance_to(SITIOS[id]["llegada"]) < 3.0:
		return "Ya estás en %s." % SITIOS[id]["nombre"]
	return ""


# El sitio de la región que corresponde a un lugar del mapa 2D (o "").
static func sitio_de_lugar(indice: int) -> String:
	for id in SITIOS:
		if int(SITIOS[id]["lugar"]) == indice and SITIOS[id]["entrada"] != Vector2.INF:
			return id
	return ""
