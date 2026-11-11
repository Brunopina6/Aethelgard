extends RefCounted
# El buscador de metales de Kael (V11, hito D; docs/v11/BUSCADOR_METALES.md). La lógica: la región 3D (V12, el Mar de
# Cristal, zonas3d/mar_cristal_3d.gd) pone el aparato en pantalla (zonas3d/mar_cristal/buscador_hud.gd). Todo se puede
# probar sin escena (pruebas/prueba_buscador.gd).
#
# - Kael no lo tiene hasta que se lo presta Ismena («La caravana perdida», mc_inicio): tiene() y dar().
# - Cada región tiene sus hallazgos enterrados, repartidos con una SEMILLA: la misma región y la misma semilla dan
#   siempre los mismos sitios (reproducible, y igual en el PC que en el móvil).
# - Hay señales falsas (chatarra): pitan como metal, pero al cavar sale «Chatarra» y nada más. Con el buscador mejorado
#   (nivel 3) ya no pitan.
# - Los hallazgos ÚNICOS de una región (llaves, reliquias que empiezan encargos) están en su sitio fijo y salen una
#   sola vez. Los comunes también: lo desenterrado no vuelve. Un único con «hito» no pita ni sale hasta ese hito de la
#   historia (progreso.gd): el Sello de la caravana, después de examinar los restos.
# - Los comunes no caen donde no se puede andar: cada región dice qué círculos evitar («evitar»: [centro, radio]).
# - La señal sube al acercarse (0 lejos, 1 encima) y dice si lo cercano es «raro» (pitido distinto). El alcance y la
#   precisión de la excavación dependen del nivel del buscador (1-3); el nivel sube con las investigaciones de Kael
#   (investigar) o al acabar la misión.
# - Lo desenterrado se guarda en la partida (progreso.gd CLAVES «buscador»): {"nivel": n, "tiene": bool, "<región>": [ids]}.

const NIVELES := {1: {"alcance": 6.0, "cavar": 1.2, "falsas": true}, 2: {"alcance": 9.0, "cavar": 1.5, "falsas": true},
	3: {"alcance": 12.0, "cavar": 1.8, "falsas": false}}
# Lo común: [objeto de inventario, peso]. «raro» suena distinto.
const COMUNES := [["Moneda antigua", 55, false], ["Mineral rúnico", 20, false], ["Fragmento de espada", 15, false],
	["Reliquia de vidrio", 10, true]]
# Regiones: área (en metros, x y z), cuántos comunes y cuántas falsas, qué evitar y los únicos con su sitio fijo.
# El Mar de Cristal (V12): «La Orilla de Vidrio» (zonas3d/mar_cristal/trazado.gd); se evitan el estanque del oasis y
# las rocas sueltas. Los únicos son los de «La caravana perdida» (zonas3d/mar_cristal/mision.gd).
const REGIONES := {
	"mar_de_cristal_1": {"area": Rect2(18, 26, 62, 58), "comunes": 14, "falsas": 6,
		"evitar": [[Vector2(74.0, 72.0), 6.0], [Vector2(26.0, 30.0), 2.6], [Vector2(18.0, 54.0), 2.8],
			[Vector2(16.0, 41.0), 3.0]],
		"unicos": [
			{"id": "sello_caravana", "objeto": "Sello de la caravana", "pos": Vector2(55.5, 57.0), "raro": true,
				"hito": "mc_caravana"},
			{"id": "llave_vidrio", "objeto": "Llave de vidrio", "pos": Vector2(49.0, 21.0), "raro": true,
				"hito": "mc_ruinas"}]},
}
# La Aguja de Resonancia (equipo_extra.gd, premio de «La caravana perdida»): si Kael la tiene, oye un poco más lejos.
const AGUJA := "aguja_resonancia"
const ALCANCE_AGUJA := 2.0
# Investigaciones de Kael para mejorar el buscador: nivel → lo que gasta (objetos del inventario). Se hacen desde el
# propio aparato (buscador_hud.gd, «MEJORAR») con lo desenterrado. El nivel 2 también llega al acabar la misión.
const MEJORAS := {2: {"Fragmento de espada": 2, "Mineral rúnico": 1}, 3: {"Reliquia de vidrio": 2, "Moneda antigua": 5}}


static func _d() -> Dictionary:
	if not Engine.has_meta("buscador"):
		Engine.set_meta("buscador", {"nivel": 1})
	return Engine.get_meta("buscador")


# ¿Lo tiene Kael? Se lo presta Ismena al empezar la misión (y al acabarla se lo queda).
static func tiene() -> bool:
	return bool(Engine.get_meta("buscador", {}).get("tiene", false))


static func dar() -> void:
	_d()["tiene"] = true


static func nivel() -> int:
	return int(Engine.get_meta("buscador", {}).get("nivel", 1))


static func mejorar(n: int) -> void:
	_d()["nivel"] = clampi(n, 1, 3)


# ================================================================= investigaciones de Kael

# Lo que falta para la siguiente mejora: [] si se puede; si no, frases. En el nivel 3, «Ya está al máximo.».
static func falta_mejora() -> Array:
	var siguiente := nivel() + 1
	if not MEJORAS.has(siguiente):
		return ["Ya está al máximo."]
	var Inv = load("res://inventario.gd")
	var r: Array = []
	var pide: Dictionary = MEJORAS[siguiente]
	for o in pide:
		var hay: int = Inv.cantidad(o)
		if hay < int(pide[o]):
			r.append("%s: %d de %d" % [o, hay, int(pide[o])])
	return r


# Kael lo mejora: gasta lo que pide y sube un nivel. Devuelve el texto para el jugador.
static func investigar() -> String:
	var f := falta_mejora()
	if not f.is_empty():
		return f[0] if f[0] == "Ya está al máximo." else "Faltan materiales. " + ", ".join(f) + "."
	var siguiente := nivel() + 1
	var Inv = load("res://inventario.gd")
	var o: Dictionary = Inv.datos()["objetos"]
	var pide: Dictionary = MEJORAS[siguiente]
	for k in pide:
		o[k] = int(o.get(k, 0)) - int(pide[k])
		if int(o[k]) <= 0:
			o.erase(k)
	mejorar(siguiente)
	return "Kael afina el buscador: ahora es de nivel %d." % siguiente


# ================================================================= hallazgos

# Los hallazgos de una región con una semilla: [{"id", "pos", "objeto", "raro", "falsa"}]. Siempre los mismos.
static func hallazgos(region: String, semilla: int) -> Array:
	var r: Dictionary = REGIONES.get(region, {})
	if r.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(region) ^ semilla
	var area: Rect2 = r["area"]
	var total := 0
	for c in COMUNES:
		total += int(c[1])
	var lista: Array = []
	for u in r.get("unicos", []):
		lista.append({"id": u["id"], "pos": u["pos"], "objeto": u["objeto"], "raro": u.get("raro", true), "falsa": false,
			"hito": u.get("hito", "")})
	for i in int(r["comunes"]) + int(r["falsas"]):
		var pos := _sitio(rng, area, r.get("evitar", []))
		if i >= int(r["comunes"]):
			lista.append({"id": "%s_f%d" % [region, i], "pos": pos, "objeto": "Chatarra", "raro": false, "falsa": true})
			continue
		var tirada := rng.randi_range(1, total)
		var elegido: Array = COMUNES[0]
		for c in COMUNES:
			tirada -= int(c[1])
			if tirada <= 0:
				elegido = c
				break
		lista.append({"id": "%s_%d" % [region, i], "pos": pos, "objeto": elegido[0], "raro": elegido[2], "falsa": false})
	return lista


# Un sitio al azar del área que no caiga en lo que hay que evitar (como mucho 12 intentos; si no, el último).
static func _sitio(rng: RandomNumberGenerator, area: Rect2, evitar: Array) -> Vector2:
	var pos := Vector2.ZERO
	for intento in 12:
		pos = Vector2(rng.randf_range(area.position.x + 2.0, area.end.x - 2.0), rng.randf_range(area.position.y + 2.0, area.end.y - 2.0))
		var libre := true
		for e in evitar:
			if pos.distance_to(e[0]) <= float(e[1]):
				libre = false
		if libre:
			break
	return pos


static func desenterrado(region: String, id: String) -> bool:
	return id in Engine.get_meta("buscador", {}).get(region, [])


# Lo que queda por desenterrar que este buscador oye (las falsas, solo hasta el nivel 2; un único con «hito», solo
# cuando la historia ha llegado a ese hito).
static func pendientes(region: String, semilla: int) -> Array:
	var oye_falsas: bool = NIVELES[nivel()]["falsas"]
	var P = load("res://progreso.gd")
	return hallazgos(region, semilla).filter(func(h): return not desenterrado(region, h["id"]) \
		and (oye_falsas or not h["falsa"]) and (str(h.get("hito", "")) == "" or P.hito(str(h["hito"]))))


# El alcance de ahora: el del nivel y, con la Aguja de Resonancia, un poco más.
static func alcance() -> float:
	var a: float = NIVELES[nivel()]["alcance"]
	var inv: Dictionary = Engine.get_meta("inventario", {})
	if AGUJA in inv.get("equipables", []):
		a += ALCANCE_AGUJA
	return a


# La señal en «pos»: {"intensidad": 0-1 (1 encima), "raro": si lo más cercano suena distinto, "distancia"}.
static func senal(region: String, semilla: int, pos: Vector2) -> Dictionary:
	var al := alcance()
	var mejor := {}
	var dmin := INF
	for h in pendientes(region, semilla):
		var d: float = pos.distance_to(h["pos"])
		if d < dmin:
			dmin = d
			mejor = h
	if mejor.is_empty() or dmin > al:
		return {"intensidad": 0.0, "raro": false, "distancia": dmin}
	return {"intensidad": clampf(1.0 - dmin / al, 0.0, 1.0), "raro": mejor["raro"], "distancia": dmin}


# Cavar en «pos»: lo más cercano a menos del radio de cavar de este nivel sale (una vez) y va al inventario (la chatarra
# no). Devuelve {"objeto", "falsa", "raro", "id", "texto"}; vacío si allí no hay nada.
static func excavar(region: String, semilla: int, pos: Vector2) -> Dictionary:
	var radio: float = NIVELES[nivel()]["cavar"]
	var mejor := {}
	var dmin := INF
	for h in pendientes(region, semilla):
		var d: float = pos.distance_to(h["pos"])
		if d <= radio and d < dmin:
			dmin = d
			mejor = h
	if mejor.is_empty():
		return {}
	var g := _d()
	if not g.has(region):
		g[region] = []
	g[region].append(mejor["id"])
	if mejor["falsa"]:
		return {"objeto": "Chatarra", "falsa": true, "raro": false, "id": mejor["id"],
			"texto": "Chatarra oxidada. El buscador se ha reído de ti."}
	load("res://inventario.gd").agregar_objeto(mejor["objeto"], 1)
	return {"objeto": mejor["objeto"], "falsa": false, "raro": mejor["raro"], "id": mejor["id"],
		"texto": ("¡Un hallazgo raro: %s!" if mejor["raro"] else "Desenterrado: %s.") % mejor["objeto"]}
