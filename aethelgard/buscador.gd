extends RefCounted
# El buscador de metales de Kael (V11, hito D; docs/v11/BUSCADOR_METALES.md). SOLO LA LÓGICA: todavía no hay región
# que lo use (el Mar de Cristal está por hacer); la región 3D pondrá el aparato en pantalla (indicador, pitidos) y el
# botón «Excavar». Todo se puede probar sin escena (pruebas/prueba_buscador.gd).
#
# - Cada región tiene sus hallazgos enterrados, repartidos con una SEMILLA: la misma región y la misma semilla dan
#   siempre los mismos sitios (reproducible, y igual en el PC que en el móvil).
# - Hay señales falsas (chatarra): pitan como metal, pero al cavar sale «Chatarra» y nada más. Con el buscador mejorado
#   (nivel 3) ya no pitan.
# - Los hallazgos ÚNICOS de una región (llaves, reliquias que empiezan encargos) están en su sitio fijo y salen una
#   sola vez. Los comunes también: lo desenterrado no vuelve.
# - La señal sube al acercarse (0 lejos, 1 encima) y dice si lo cercano es «raro» (pitido distinto). El alcance y la
#   precisión de la excavación dependen del nivel del buscador (1-3).
# - Lo desenterrado se guarda en la partida (progreso.gd CLAVES «buscador»): {"nivel": n, "<región>": [ids]}.

const NIVELES := {1: {"alcance": 6.0, "cavar": 1.2, "falsas": true}, 2: {"alcance": 9.0, "cavar": 1.5, "falsas": true},
	3: {"alcance": 12.0, "cavar": 1.8, "falsas": false}}
# Lo común: [objeto de inventario, peso]. «raro» suena distinto.
const COMUNES := [["Moneda antigua", 55, false], ["Mineral rúnico", 20, false], ["Fragmento de espada", 15, false],
	["Reliquia de vidrio", 10, true]]
# Regiones: área (en metros, x y z), cuántos comunes y cuántas falsas, y los únicos con su sitio fijo.
const REGIONES := {
	"mar_de_cristal_1": {"area": Rect2(0, 0, 80, 80), "comunes": 14, "falsas": 6,
		"unicos": [{"id": "llave_vidrio", "objeto": "Llave de vidrio", "pos": Vector2(61.5, 18.0), "raro": true}]},
}


static func _d() -> Dictionary:
	if not Engine.has_meta("buscador"):
		Engine.set_meta("buscador", {"nivel": 1})
	return Engine.get_meta("buscador")


static func nivel() -> int:
	return int(Engine.get_meta("buscador", {}).get("nivel", 1))


static func mejorar(n: int) -> void:
	_d()["nivel"] = clampi(n, 1, 3)


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
		lista.append({"id": u["id"], "pos": u["pos"], "objeto": u["objeto"], "raro": u.get("raro", true), "falsa": false})
	for i in int(r["comunes"]) + int(r["falsas"]):
		var pos := Vector2(rng.randf_range(area.position.x + 2.0, area.end.x - 2.0), rng.randf_range(area.position.y + 2.0, area.end.y - 2.0))
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


static func desenterrado(region: String, id: String) -> bool:
	return id in Engine.get_meta("buscador", {}).get(region, [])


# Lo que queda por desenterrar que este buscador oye (las falsas, solo hasta el nivel 2).
static func pendientes(region: String, semilla: int) -> Array:
	var oye_falsas: bool = NIVELES[nivel()]["falsas"]
	return hallazgos(region, semilla).filter(func(h): return not desenterrado(region, h["id"]) and (oye_falsas or not h["falsa"]))


# La señal en «pos»: {"intensidad": 0-1 (1 encima), "raro": si lo más cercano suena distinto, "distancia"}.
static func senal(region: String, semilla: int, pos: Vector2) -> Dictionary:
	var alcance: float = NIVELES[nivel()]["alcance"]
	var mejor := {}
	var dmin := INF
	for h in pendientes(region, semilla):
		var d: float = pos.distance_to(h["pos"])
		if d < dmin:
			dmin = d
			mejor = h
	if mejor.is_empty() or dmin > alcance:
		return {"intensidad": 0.0, "raro": false, "distancia": dmin}
	return {"intensidad": clampf(1.0 - dmin / alcance, 0.0, 1.0), "raro": mejor["raro"], "distancia": dmin}


# Cavar en «pos»: lo más cercano a menos del radio de cavar de este nivel sale (una vez) y va al inventario (la chatarra
# no). Devuelve {"objeto", "falsa", "raro", "texto"}; vacío si allí no hay nada.
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
		return {"objeto": "Chatarra", "falsa": true, "raro": false, "texto": "Chatarra oxidada. El buscador se ha reído de ti."}
	load("res://inventario.gd").agregar_objeto(mejor["objeto"], 1)
	return {"objeto": mejor["objeto"], "falsa": false, "raro": mejor["raro"],
		"texto": ("¡Un hallazgo raro: %s!" if mejor["raro"] else "Desenterrado: %s.") % mejor["objeto"]}
