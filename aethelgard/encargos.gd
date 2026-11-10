extends RefCounted
# Encargos (V9, «mundo vivo y encargos»): un registro reutilizable de misiones y encargos de todas las regiones, con el
# MISMO formato que ya usaba Oakhaven (ciudades/oakhaven.gd, MISIONES): id, nombre, quien, resumen, empieza, fin,
# pasos [{id, texto, hecho}], recompensa y pago. Cada región aporta su módulo en FUENTES; añadir un encargo es añadir
# una entrada de datos, sin tocar este script. El Diario los muestra (diario.gd, pestaña «Encargos»).
#
# Condiciones (como en Oakhaven, «!» las niega, una lista exige todas):
#   hito:<id>  decision:<k>=<v>  grupo:<héroe>  oro:<n>  ganado:<combate fijo>
#   material:<clave de inventario>=<n>   investigacion:<id> (completada)   hecha:<receta> (oficios, de un solo uso)
#   estado_de:<lugar>/<clave>   (progreso.gd, estado de un lugar: p. ej. estado_de:oakhaven/encina_bosque)
# Las demás (estado:, cond:, modo:) las entiende el módulo de la región (su función cumple), si la tiene.

const FUENTES := ["res://ciudades/oakhaven.gd", "res://datos/encargos_pastos.gd", "res://datos/encargos_oakhaven.gd"]


static func _p():
	return load("res://progreso.gd")


# Todos los encargos: [{"m": datos, "fuente": ruta, "lugar": nombre del lugar}]
static func todos() -> Array:
	var r: Array = []
	for f in FUENTES:
		if not ResourceLoader.exists(f):
			continue
		var s = load(f)
		var c: Dictionary = s.get_script_constant_map()
		var lugar := str(c.get("NOMBRE_LUGAR", c.get("NOMBRE", "")))
		for m in c.get("MISIONES", []):
			r.append({"m": m, "fuente": f, "lugar": lugar.capitalize() if lugar == "oakhaven" else lugar})
	return r


static func cumple(cond: Variant, fuente := "") -> bool:
	if cond is Array:
		for c in cond:
			if not cumple(c, fuente):
				return false
		return true
	var c := str(cond).strip_edges()
	if c == "":
		return true
	if c.begins_with("!"):
		return not cumple(c.substr(1), fuente)
	var tipo := c.get_slice(":", 0)
	var valor := c.substr(tipo.length() + 1)
	var P = _p()
	match tipo:
		"hito":
			return P.hito(valor)
		"decision":
			return str(Engine.get_meta("decisiones", {}).get(valor.get_slice("=", 0), "")) == valor.get_slice("=", 1)
		"grupo":
			return valor in load("res://grupo.gd").activos()
		"oro":
			return load("res://inventario.gd").oro() >= int(valor)
		"ganado":
			return P.ganado(valor)
		"material":
			return load("res://inventario.gd").cantidad(valor.get_slice("=", 0)) >= int(valor.get_slice("=", 1))
		"investigacion":
			return load("res://investigacion.gd").estado(valor) == "completada"
		"hecha":
			return valor in load("res://inventario.gd").datos().get("hechas", [])
		"estado_de":
			return P.estado(valor.get_slice("/", 0), valor.get_slice("/", 1))
	if fuente != "" and load(fuente).has_method("cumple"):
		return load(fuente).cumple(c)
	push_warning("Encargos: condición desconocida «%s»" % c)
	return false


# "oculto" (aún no empieza), "activo" o "hecho".
static func estado(e: Dictionary) -> String:
	var m: Dictionary = e["m"]
	if cumple(m.get("fin", ""), e["fuente"]) and str(m.get("fin", "")) != "":
		return "hecho"
	if not cumple(m.get("empieza", ""), e["fuente"]):
		return "oculto"
	return "activo"


# El primer paso que falta (o {} si están todos).
static func paso_actual(e: Dictionary) -> Dictionary:
	for p in e["m"].get("pasos", []):
		if not cumple(p.get("hecho", ""), e["fuente"]):
			return p
	return {}


static func de(id: String) -> Dictionary:
	for e in todos():
		if e["m"]["id"] == id:
			return e
	return {}


# Lo que se ve en el Diario: los activos primero (con su paso), después los hechos.
static func para_diario() -> Array:
	var activos: Array = []
	var hechos: Array = []
	for e in todos():
		match estado(e):
			"activo":
				activos.append(e)
			"hecho":
				hechos.append(e)
	return activos + hechos
