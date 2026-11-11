extends RefCounted
# El Gremio de aventureros de Oakhaven (V11, hito C; docs/v11/GREMIO.md). Contratos del tablón de la plaza
# (ciudad_oakhaven.gd, pieza oak_tablon_gremio; la ventana es gremio_menu.gd), con rango y reputación.
#
# Un contrato se acepta, se cumple y se cobra en el tablón. Tipos (no solo matar):
#   derrotar  <clave de enemigo> × n   (combate.gd, al ganar, cuenta los caídos de los contratos aceptados)
#   entregar  <objeto> × n             (al cobrar se gastan del inventario)
#   cumplir   <condición de encargos.gd> (un hito, otro encargo acabado, un lugar…)
# Al cobrar: oro, objetos y reputación. Con reputación se sube de rango, y el rango abre contratos nuevos.
# Se guarda en Engine «gremio» (progreso.gd CLAVES): {"rep": n, "aceptados": {id: progreso}, "hechos": [id]}.
# Las partidas antiguas no lo traen: empiezan en Bronce, sin contratos. Los nombres y textos son PROPUESTA (sin canon).

const RANGOS := [{"nombre": "Bronce", "rep": 0}, {"nombre": "Plata", "rep": 6}, {"nombre": "Oro", "rep": 15}]

const CONTRATOS := [
	{"id": "gr_limos", "nombre": "Plaga de limos", "rango": 0, "tipo": "derrotar", "que": "slime", "n": 3,
		"texto": "Los limos se comen las coles de la huerta del este. Tres menos y el hortelano duerme.",
		"premio": {"oro": 40, "rep": 2}},
	{"id": "gr_musgo", "nombre": "Musgo para la botica", "rango": 0, "tipo": "entregar", "que": "Musgo de piedra", "n": 2,
		"texto": "Mirta se ha quedado sin musgo de piedra para sus emplastos. Dos puñados, y que no estén secos.",
		"premio": {"oro": 30, "rep": 2, "objetos": {"Poción": 1}}},
	{"id": "gr_formula", "nombre": "Un favor a la botica", "rango": 0, "tipo": "cumplir", "que": "hito:enc_formula_fin",
		"texto": "El gremio paga a quien ayude a Mirta con su cuaderno perdido. Las buenas obras también cuentan.",
		"premio": {"oro": 20, "rep": 2}},
	{"id": "gr_hachas", "nombre": "Hachas en el camino", "rango": 1, "tipo": "derrotar", "que": "grimfang", "n": 2,
		"texto": "Dos Grimfang asaltan a los carreteros que vienen de Pastos Verdes. Que no vuelvan a alzar el hacha.",
		"premio": {"oro": 70, "rep": 3}},
	{"id": "gr_garganta", "nombre": "Ojos en la Garganta", "rango": 1, "tipo": "cumplir", "que": "ganado:garganta_nido",
		"texto": "Algo grande anida en la Garganta del Diablo. El gremio quiere saber qué es y que deje de serlo.",
		"premio": {"oro": 110, "rep": 4, "objetos": {"Éter": 1}}},
	{"id": "gr_ambar", "nombre": "El encargo del maestro", "rango": 2, "tipo": "entregar", "que": "Mineral rúnico", "n": 1,
		"texto": "El maestro del gremio busca mineral rúnico para un sello nuevo. No pregunta para qué lo quieres tú.",
		"premio": {"oro": 150, "rep": 5}},
]


static func _d() -> Dictionary:
	if not Engine.has_meta("gremio"):
		Engine.set_meta("gremio", {"rep": 0, "aceptados": {}, "hechos": []})
	var g: Dictionary = Engine.get_meta("gremio")
	for k in [["rep", 0], ["aceptados", {}], ["hechos", []]]:
		if not g.has(k[0]):
			g[k[0]] = k[1]
	return g


static func reputacion() -> int:
	return int(_d()["rep"])


static func rango() -> int:
	var r := 0
	for i in RANGOS.size():
		if reputacion() >= int(RANGOS[i]["rep"]):
			r = i
	return r


static func nombre_rango() -> String:
	return RANGOS[rango()]["nombre"]


# La reputación que falta para el rango siguiente (0 si ya es el último).
static func falta_rango() -> int:
	var r := rango()
	return 0 if r >= RANGOS.size() - 1 else int(RANGOS[r + 1]["rep"]) - reputacion()


static func contrato(id: String) -> Dictionary:
	for c in CONTRATOS:
		if c["id"] == id:
			return c
	return {}


# "bloqueado" (falta rango), "disponible", "aceptado", "listo" (se puede cobrar) o "hecho".
static func estado(id: String) -> String:
	var c := contrato(id)
	var g := _d()
	if id in g["hechos"]:
		return "hecho"
	if g["aceptados"].has(id):
		return "listo" if progreso(id) >= total(id) else "aceptado"
	if int(c.get("rango", 0)) > rango():
		return "bloqueado"
	return "disponible"


static func total(id: String) -> int:
	var c := contrato(id)
	return 1 if c.get("tipo", "") == "cumplir" else int(c.get("n", 1))


static func progreso(id: String) -> int:
	var c := contrato(id)
	match c.get("tipo", ""):
		"derrotar":
			return mini(int(_d()["aceptados"].get(id, 0)), total(id))
		"entregar":
			return mini(load("res://inventario.gd").cantidad(c["que"]), total(id))
		"cumplir":
			return 1 if load("res://encargos.gd").cumple(c["que"]) else 0
	return 0


static func aceptar(id: String) -> bool:
	if estado(id) != "disponible":
		return false
	_d()["aceptados"][id] = 0
	return true


# combate.gd, al ganar: las claves de los enemigos caídos. Solo cuentan para los contratos aceptados.
static func contar_derrotas(claves: Array) -> void:
	if not Engine.has_meta("gremio"):
		return
	var g := _d()
	for c in CONTRATOS:
		if c["tipo"] == "derrotar" and g["aceptados"].has(c["id"]):
			g["aceptados"][c["id"]] = int(g["aceptados"][c["id"]]) + claves.count(c["que"])


# Cobrar un contrato cumplido: gasta lo entregado, da el premio una sola vez y devuelve el texto del premio ("" si no).
static func cobrar(id: String) -> String:
	if estado(id) != "listo":
		return ""
	var c := contrato(id)
	var Inv = load("res://inventario.gd")
	if c["tipo"] == "entregar":
		for i in int(c["n"]):
			Inv.gastar(c["que"])
	var rango_antes := rango()
	var g := _d()
	g["aceptados"].erase(id)
	g["hechos"].append(id)
	var p: Dictionary = c["premio"]
	g["rep"] = reputacion() + int(p.get("rep", 0))
	var partes: Array = []
	if int(p.get("oro", 0)) > 0:
		Inv.ganar_oro(int(p["oro"]))
		partes.append("%d monedas" % int(p["oro"]))
	for o in p.get("objetos", {}):
		Inv.agregar_objeto(o, int(p["objetos"][o]))
		partes.append("%d %s" % [int(p["objetos"][o]), o])
	partes.append("+%d de reputación" % int(p.get("rep", 0)))
	var t := "«%s»: %s." % [c["nombre"], ", ".join(partes)]
	if rango() > rango_antes:
		t += " ¡Rango %s en el gremio!" % nombre_rango()
	return t
