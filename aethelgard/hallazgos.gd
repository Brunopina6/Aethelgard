extends RefCounted
# Hallazgos (narrativa, 09/11): los tomos de las artes y las armas y accesorios de T-092 que aún no se podían encontrar,
# puestos en el mundo donde dice su diseño (equipo_extra.gd, «donde»; docs/diseno/combate_ampliaciones.md para los
# tomos). Solo datos y la entrega; los pone zona.gd (zonas 2D y ciudades) y ciudad_oakhaven.gd.
#
# CÓMO SE ENCUENTRAN («al»):
#   - "detalle:<id>": al examinar ese detalle de lore (progreso.gd, DETALLES), justo después de su texto;
#   - "cofre": en un cofre propio, cerca de «cerca» (un rincón de la zona: ruinas, campamento, claro; «mirada»: unas
#     casillas al norte de las ruinas, adonde mira la Estatua sin brazo; «agua»: junto al agua, lo más al centro);
#   - "altar": al examinar el altar o monumento del lugar (en Oakhaven, el pie del Árbol Milenario);
#   - "pieza:<id>": al examinar una pieza de la ciudad (en Oakhaven, el barril del patio del Cuervo).
# LO QUE DA: «arma» o «accesorio» (equipo_extra.gd, conseguir: va a «equipables») o «tomo» (artes.gd, dar_tomo).
# GUARDADO: cada hallazgo, una vez, apuntado en «cofres_abiertos» con su id («hall_…»): ninguna clave nueva; una partida
# antigua no lo tiene y se puede encontrar. Si ya tenías el objeto (comprado, por ejemplo), se apunta igual.
# Lo que aún no existe en el juego (la Arboleda Mítica: Gota de la cascada y Cinta de Lumi) o lo que ya da otra cosa
# (las Fauces de Gorthor y la Lágrima de ámbar, combate.gd; el Farol y la Moneda, las tiendas) no está aquí.
# Regiones 3D (V12, 12/11): las enganchan con zonas3d/examinables_3d.gd (hallazgo_al_examinar, hallazgo_pendiente),
# que hace lo de abajo; la primera, la Garganta 3D (el Báculo del Peregrino al examinar el pilar).
# Garganta 3D (garganta_3d.gd, de gráficos): al examinar el pilar del peregrino, la misma llamada que la 2D:
#     var t: Array = Hallazgos.al_examinar(2, "detalle:garganta_pilar")   # [] si no hay nada (o ya se encontró)
#     tras el aviso del detalle, cada texto de «t» con _mostrar_aviso(texto, 3.0), uno detrás de otro, y Sonido «tesoro»

const HALLAZGOS := [
	{"id": "hall_hoja_sin_nombre", "lugar": 1, "al": "detalle:bosque_armadura", "arma": "hoja_sin_nombre",
		"texto": "Entre las raíces, junto a la armadura, una hoja a la que alguien raspó el nombre."},
	{"id": "hall_diente_grimfang", "lugar": 1, "al": "cofre", "cerca": "campamento", "accesorio": "diente_grimfang",
		"texto": ""},
	{"id": "hall_baculo_peregrino", "lugar": 2, "al": "detalle:garganta_pilar", "arma": "baculo_peregrino",
		"texto": "Al pie del pilar, apoyado en la piedra, un báculo gastado por muchas manos."},
	{"id": "hall_guardiana_ambar", "lugar": 3, "al": "detalle:ciclopea_estatua", "arma": "guardiana_ambar",
		"texto": "A los pies de la estatua, medio enterrada, una espada con la guarda de ámbar."},
	{"id": "hall_pluma_arpia", "lugar": 3, "al": "cofre", "cerca": "ruinas", "accesorio": "pluma_arpia",
		"texto": ""},
	{"id": "hall_tomo_escarcha", "lugar": 3, "al": "cofre", "cerca": "mirada", "tomo": "tomo_escarcha",
		"texto": "Adonde mira la estatua, un cofre helado con un libro dentro."},
	{"id": "hall_tomo_alba", "lugar": 4, "al": "detalle:calid_maquina", "tomo": "tomo_alba",
		"texto": "Entre los tubos de la máquina, envuelto en tela, un libro con un sol en la tapa."},
	{"id": "hall_tomo_lumbre", "lugar": 6, "al": "cofre", "cerca": "agua", "tomo": "tomo_lumbre",
		"texto": "Junto al agua más quieta, un cofre con un libro que no se ha mojado."},
	{"id": "hall_brasa_frasco", "lugar": 6, "al": "cofre", "cerca": "ruinas", "accesorio": "brasa_frasco",
		"texto": ""},
	{"id": "hall_rama_milenaria", "lugar": 0, "al": "altar", "arma": "rama_milenaria",
		"texto": "Al pie del Árbol, una rama verde que el viento ha dejado caer. No se seca."},
	{"id": "hall_gemelas_muralla", "lugar": 0, "al": "pieza:oak_barril", "arma": "gemelas_muralla",
		"texto": "Detrás del barril, envueltas en un trapo, dos espadas cortas de la Guardia."},
]


# Lo que no se pone aquí, y por qué (prueba_hallazgos comprueba que todo el equipo de T-092 y los tomos tienen sitio).
const FUERA := {
	"gota_cascada": "Arboleda Mítica (T-090): aún no existe en el juego",
	"cinta_lumi": "regalo de Lumi en la Arboleda Mítica (T-090): aún no existe",
	"farol_peregrino": "tienda de Oakhaven (equipo_extra.gd, EN_TIENDA)",
	"moneda_aguila": "tienda de Sunken City (EN_TIENDA)",
	"lagrima_ambar": "primera victoria en el nido de la Garganta (combate.gd, RECOMPENSA_FIJO)",
	"fauces_gorthor": "al vencer a Gorthor (combate.gd, RECOMPENSA_FIJO)",
	"brote_guardian": "al purificar al Guardián del Bosque, Pastos Verdes (fase 3; combate.gd, _premio_bosque)",
	"corteza_guardian": "al derrotar al Guardián del Bosque, Pastos Verdes (fase 3; combate.gd, _premio_bosque)",
	"amuleto_claro": "se fabrica en el taller conjunto (V9; talleres.gd, receta amuleto_claro)",
	"fragmento_armadura": "al vencer al Coloso de la Falla, en la grieta de la Garganta 3D (V9, jefe 2; combate_coloso.gd, dar_premio)",
	"aguja_resonancia": "premio de Ismena al acabar «La caravana perdida», en el Mar de Cristal (V12; zonas3d/mar_cristal/mision.gd)",
}


static func de_lugar(lugar: int) -> Array:
	return HALLAZGOS.filter(func(h): return int(h["lugar"]) == lugar and disponible(h))


static func hallazgo(id: String) -> Dictionary:
	for h in HALLAZGOS:
		if h["id"] == id:
			return h
	return {}


static func es_hallazgo(id: String) -> bool:
	return not hallazgo(id).is_empty()


static func encontrado(id: String) -> bool:
	return Engine.get_meta("cofres_abiertos", {}).has(id)


# ¿Ya se puede dar? (el arma o el accesorio tienen su efecto enganchado; el tomo existe)
static func disponible(h: Dictionary) -> bool:
	if h.has("tomo"):
		return load("res://artes.gd").TOMOS.has(h["tomo"])
	return load("res://equipo_extra.gd").disponible(h.get("arma", h.get("accesorio", "")))


# Lo encuentra (una vez) y devuelve los avisos, en orden: el del sitio (si lo tiene) y lo que se consigue o se aprende.
# [] si no existe, no está disponible o ya se encontró.
static func encontrar(id: String) -> Array:
	var h := hallazgo(id)
	if h.is_empty() or encontrado(id) or not disponible(h):
		return []
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	abiertos[id] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	var r := ""
	if h.has("tomo"):
		var Artes = load("res://artes.gd")
		var nombre: String = Artes.NOMBRE_TOMO.get(h["tomo"], "un tomo")
		var aprende: String = Artes.dar_tomo(h["tomo"])
		r = "%s. %s" % [nombre, aprende if aprende != "" else "Ya sabías lo que enseña."]
	else:
		var Extra = load("res://equipo_extra.gd")
		var obj: String = h.get("arma", h.get("accesorio", ""))
		var c: String = Extra.conseguir(obj)
		r = c if c != "" else "%s (ya lo tenías)." % Extra.objeto(obj)["nombre"]
	return [r] if h["texto"] == "" else [h["texto"], r]


# Lo que toca al examinar algo en un lugar («detalle:<id>», «altar», «pieza:<id>»): sus avisos, o [] si nada.
static func al_examinar(lugar: int, que: String) -> Array:
	for h in de_lugar(lugar):
		if h["al"] == que and not encontrado(h["id"]):
			return encontrar(h["id"])
	return []


# Los cofres propios de un lugar: [id, «cerca»].
static func cofres_de(lugar: int) -> Array:
	return de_lugar(lugar).filter(func(h): return h["al"] == "cofre").map(func(h): return [h["id"], h.get("cerca", "")])
