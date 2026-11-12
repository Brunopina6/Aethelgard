extends RefCounted
# Orbes Cristalinos y Firmamento de los Ecos (V12, 12/11). PROTOTIPO APAGADO: interruptor «orbes_v12».
# Servicio sin escena: saldo de orbes, nodos desbloqueados por héroe y las bonificaciones que salen de ellos.
# Diseño y decisiones pendientes: docs/v12/FIRMAMENTO_DE_LOS_ECOS.md. Valores y precios: firmamento_datos.gd.
#
# Uso:  var Orbes = load("res://firmamento/orbes.gd")
#   Orbes.activo()                         ¿está encendido el sistema? (si no, nada de aquí cambia el juego)
#   Orbes.saldo()                          orbes disponibles
#   Orbes.ganar(cantidad, motivo)          API para el futuro: la ÚNICA puerta de entrada de orbes (aún sin fuentes)
#   Orbes.estado(heroe, id)                desbloqueado | disponible | caro | bloqueado | dormido
#   Orbes.motivo(heroe, id)                por qué no se puede ("" si se puede)
#   Orbes.desbloquear(heroe, id)           gasta y lo desbloquea; "" o el motivo
#   Orbes.bonos(heroe)                     lo que suma grupo.gd (atributos, ataque, magia_extra) y equipo_extra.gd
#                                          (efectos); {} con el interruptor apagado
#   Orbes.vista_previa(heroe, id)          estadísticas antes y después (grupo.estadisticas con y sin el nodo)
#   Orbes.conceder_prueba(n)               SOLO Auditoría o editor: orbes temporales para probar compras
#
# GUARDADO: Engine «firmamento» (clave de progreso.gd CLAVES) = {"orbes": int, "nodos": {héroe: [ids]},
# "gastados": {héroe: int}, "historial": [[motivo, cantidad], ...] (los 30 últimos)}. Solo se crea al ganar o gastar
# orbes: con el interruptor apagado una partida nunca la lleva, y una partida antigua sin ella carga con todo a cero.
# Las bonificaciones NO se suman a los atributos guardados: se calculan al vuelo desde los nodos (no pueden aplicarse
# dos veces al cargar). Con el interruptor apagado, los datos se conservan pero no suman nada.

const Datos := preload("res://firmamento/firmamento_datos.gd")
const INTERRUPTOR := "orbes_v12"
const ACTIVO_POR_DEFECTO := false
const CLAVE := "firmamento"
const MAX_HISTORIAL := 30
const ATRIBUTOS := ["fuerza", "magia", "defensa", "velocidad", "vitalidad", "espiritu"]
const PLANOS := ["ataque", "magia_extra"]        # se suman como el ataque o la magia de un arma (grupo.gd)

# Vista previa: mientras vale [héroe, id], bonos() cuenta ese nodo como desbloqueado (solo dentro de vista_previa).
static var _previo: Array = []


# ================================================================= interruptor

# Encendido con Engine.set_meta("orbes_v12", true), con «-- orbes_v12», o, solo en Auditoría y en el editor, desde
# Ajustes (user://ajustes.cfg [firmamento] activo), para poder compararlo en el teléfono sin argumentos.
static func activo() -> bool:
	if Engine.has_meta(INTERRUPTOR):
		return bool(Engine.get_meta(INTERRUPTOR))
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	if herramienta_dev():
		var c := ConfigFile.new()
		if c.load("user://ajustes.cfg") == OK:
			return bool(c.get_value("firmamento", "activo", ACTIVO_POR_DEFECTO))
	return ACTIVO_POR_DEFECTO


static func elegir_en_ajustes(si: bool) -> Error:
	if not herramienta_dev():
		return ERR_UNAUTHORIZED
	Engine.set_meta(INTERRUPTOR, si)
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := c.load("user://ajustes.cfg")
		if err != OK:
			return err
	c.set_value("firmamento", "activo", si)
	return c.save("user://ajustes.cfg")


# Herramientas de desarrollo (conceder orbes, el interruptor en Ajustes): solo en la APK de Auditoría o en el editor.
# Nunca en las versiones normales (ni con argumentos: en Android no llegan, y en el PC normal tampoco se aceptan).
static func herramienta_dev() -> bool:
	return OS.has_feature("auditoria") or OS.has_feature("editor")


# ================================================================= datos guardados

static func _leer() -> Dictionary:                  # sin crear la clave (leer no debe cambiar la partida)
	var d = Engine.get_meta(CLAVE, {})
	return d if d is Dictionary else {}


static func _escribir() -> Dictionary:              # la crea si falta (solo al ganar o gastar)
	var d = Engine.get_meta(CLAVE) if Engine.has_meta(CLAVE) else null
	if not d is Dictionary:
		d = {}
		Engine.set_meta(CLAVE, d)
	if not d.has("orbes"):
		d["orbes"] = 0
	if not d.get("nodos") is Dictionary:
		d["nodos"] = {}
	if not d.get("gastados") is Dictionary:
		d["gastados"] = {}
	if not d.get("historial") is Array:
		d["historial"] = []
	return d


static func saldo() -> int:
	return maxi(0, int(_leer().get("orbes", 0)))


static func nodos_de(heroe: String) -> Array:
	var n = _leer().get("nodos", {})
	if not n is Dictionary:
		return []
	var l = n.get(heroe, [])
	return l if l is Array else []


static func gastados(heroe: String) -> int:
	var g = _leer().get("gastados", {})
	return int(g.get(heroe, 0)) if g is Dictionary else 0


# La única entrada de orbes. «motivo»: de dónde vienen (combate, cofre, mision, prueba...), para el historial y para
# decidir la economía. Devuelve el saldo nuevo. Con el interruptor apagado no hace nada (devuelve el saldo).
static func ganar(cantidad: int, motivo: String) -> int:
	if cantidad <= 0 or not activo():
		return saldo()
	var d := _escribir()
	d["orbes"] = int(d["orbes"]) + cantidad
	var h: Array = d["historial"]
	h.append([motivo, cantidad])
	while h.size() > MAX_HISTORIAL:
		h.pop_front()
	return int(d["orbes"])


# Herramienta de desarrollo: orbes temporales para probar compras (Auditoría o editor). false si no se permite.
static func conceder_prueba(cantidad: int) -> bool:
	if not herramienta_dev() or not activo():
		return false
	ganar(cantidad, "prueba_auditoria")
	return true


# ================================================================= tablero

static func heroes() -> Array:                       # los tableros que se enseñan (Naira solo si existe en la partida)
	var r: Array = []
	var G = load("res://grupo.gd")
	for n in ["Kael", "Lya", "Garon", "Naira"]:
		if Datos.TABLEROS.has(n) and G.disponible(n) and G.datos().has(n):
			r.append(n)
	return r


static func tablero(heroe: String) -> Array:
	return Datos.TABLEROS.get(heroe, [])


static func nodo(heroe: String, id: String) -> Dictionary:
	for n in tablero(heroe):
		if n["id"] == id:
			return n
	return {}


static func precio(n: Dictionary) -> int:
	return int(Datos.PRECIOS.get(n.get("rango", "basica"), 1))


static func desbloqueado(heroe: String, id: String) -> bool:
	return id in nodos_de(heroe)


# ¿Todo lo que da este nodo tiene ya su gancho en el juego? (si no, está dormido: se ve, pero no se compra)
static func despierto(n: Dictionary) -> bool:
	var X = load("res://equipo_extra.gd")
	for k in n.get("bonos", {}):
		if k in ATRIBUTOS or k in PLANOS:
			continue
		if not X.EFECTOS.has(k) or not X.EFECTOS[k]["gancho"] in X.HECHOS:
			return false
	return true


static func requisitos_cumplidos(heroe: String, n: Dictionary) -> bool:
	var req: Array = n.get("req", [])
	if req.is_empty():
		return true
	var hay := 0
	for r in req:
		if desbloqueado(heroe, r):
			hay += 1
	return hay == req.size() if n.get("todos", false) else hay > 0


# desbloqueado | disponible (se puede comprar ya) | caro (requisitos sí, orbes no) | bloqueado | dormido
static func estado(heroe: String, id: String) -> String:
	var n := nodo(heroe, id)
	if n.is_empty():
		return "bloqueado"
	if desbloqueado(heroe, id):
		return "desbloqueado"
	if not despierto(n):
		return "dormido"
	if not requisitos_cumplidos(heroe, n):
		return "bloqueado"
	return "disponible" if saldo() >= precio(n) else "caro"


static func motivo(heroe: String, id: String) -> String:
	var n := nodo(heroe, id)
	if not activo():
		return "El Firmamento está apagado"
	if n.is_empty():
		return "Ese nodo no existe"
	match estado(heroe, id):
		"desbloqueado":
			return "Ya está desbloqueado"
		"dormido":
			return "Dormido: aún no hay nada en el juego que lo use"
		"bloqueado":
			return "Requiere " + texto_requisitos(heroe, n)
		"caro":
			var f := texto_faltan(precio(n) - saldo())
			return f.substr(0, 1).to_upper() + f.substr(1)
	return ""


static func texto_requisitos(heroe: String, n: Dictionary) -> String:
	var nombres: Array = []
	for r in n.get("req", []):
		nombres.append(String(nodo(heroe, r).get("nombre", r)))
	if nombres.is_empty():
		return "nada"
	if nombres.size() == 1:
		return nombres[0]
	var ultimo: String = nombres.pop_back()
	return ", ".join(nombres) + (" y " if n.get("todos", false) else " o ") + ultimo


# Gasta y desbloquea. "" si se pudo; si no, el motivo (y no cambia nada).
static func desbloquear(heroe: String, id: String) -> String:
	var m := motivo(heroe, id)
	if m != "":
		return m
	var n := nodo(heroe, id)
	var d := _escribir()
	d["orbes"] = int(d["orbes"]) - precio(n)
	if not d["nodos"].get(heroe) is Array:
		d["nodos"][heroe] = []
	d["nodos"][heroe].append(id)
	d["gastados"][heroe] = int(d["gastados"].get(heroe, 0)) + precio(n)
	return ""


# ================================================================= bonificaciones

# Lo que suman los nodos desbloqueados de un héroe: {"atributos": {...}, "ataque": n, "magia_extra": n, "efectos": {...}}.
# Vacío con el interruptor apagado. Los efectos se devuelven sin tope: equipo_extra.gd los suma con el suyo.
# Los ids que ya no existan en los datos (una versión que los quitó) se ignoran; los dormidos no suman.
static func bonos(heroe: String) -> Dictionary:
	if not activo():
		return {}
	var ids: Array = nodos_de(heroe).duplicate()
	if _previo.size() == 2 and _previo[0] == heroe and not _previo[1] in ids:
		ids.append(_previo[1])
	if ids.is_empty():
		return {}
	var r := {"atributos": {}, "ataque": 0, "magia_extra": 0, "efectos": {}}
	for id in ids:
		var n := nodo(heroe, str(id))
		if n.is_empty() or not despierto(n):
			continue
		var b: Dictionary = n.get("bonos", {})
		for k in b:
			if k in ATRIBUTOS:
				r["atributos"][k] = int(r["atributos"].get(k, 0)) + int(b[k])
			elif k in PLANOS:
				r[k] = int(r[k]) + int(b[k])
			elif b[k] is bool:
				r["efectos"][k] = bool(r["efectos"].get(k, false)) or b[k]
			else:
				r["efectos"][k] = float(r["efectos"].get(k, 0.0)) + float(b[k])
	return r


# Estadísticas antes y después de desbloquear un nodo (las de grupo.gd, con equipo y todo), y los efectos.
static func vista_previa(heroe: String, id: String) -> Dictionary:
	var G = load("res://grupo.gd")
	var X = load("res://equipo_extra.gd")
	var antes: Dictionary = G.estadisticas(heroe)
	var ef_antes: Dictionary = X.efectos_de(heroe)
	_previo = [heroe, id]
	var despues: Dictionary = G.estadisticas(heroe)
	var ef_despues: Dictionary = X.efectos_de(heroe)
	_previo = []
	return {"antes": antes, "despues": despues, "efectos_antes": ef_antes, "efectos_despues": ef_despues}


# Líneas «Nombre: antes → después» de lo que cambia (para el panel).
static func lineas_previa(heroe: String, id: String) -> Array:
	var v := vista_previa(heroe, id)
	var r: Array = []
	var a: Dictionary = v["antes"]
	var d: Dictionary = v["despues"]
	for par in [["pv_max", "PV máx."], ["pm_max", "PM máx."], ["ataque", "Ataque"], ["defensa", "Defensa"],
			["magia_extra", "Daño mágico"]]:
		if a[par[0]] != d[par[0]]:
			r.append([par[1], str(a[par[0]]), str(d[par[0]])])
	if not is_equal_approx(a["magia_mult"], d["magia_mult"]):
		r.append(["Poder mágico", "×%.3f" % a["magia_mult"], "×%.3f" % d["magia_mult"]])
	if not is_equal_approx(a["velocidad"], d["velocidad"]):
		r.append(["Velocidad", str(int(a["velocidad"])), str(int(d["velocidad"]))])
	var ea: Dictionary = v["efectos_antes"]
	var ed: Dictionary = v["efectos_despues"]
	for k in ed:
		if ea.get(k) != ed[k]:
			r.append([Datos.NOMBRE_BONO.get(k, k), _valor(k, ea.get(k, 0.0)), _valor(k, ed[k])])
	return r


static func _valor(k: String, v) -> String:
	if v is bool:
		return "sí" if v else "no"
	if k in Datos.PORCENTAJE:
		return "%d %%" % int(round(float(v) * 100.0))
	if k == "atb_inicio":
		return "%d %%" % int(round(float(v)))
	return str(snappedf(float(v), 0.01)).trim_suffix(".0")


# Texto corto de lo que da un nodo («+2 Fuerza · +4 % Crítico»).
static func texto_bonos(n: Dictionary) -> String:
	var r: Array = []
	var b: Dictionary = n.get("bonos", {})
	for k in b:
		var nombre: String = Datos.NOMBRE_BONO.get(k, k)
		if k in Datos.PORCENTAJE or k == "atb_inicio":
			r.append("+%s %s" % [_valor(k, b[k]), nombre])
		elif k in ["apoyo_turnos", "aliento_inicio"]:
			r.append("%s (+%d)" % [nombre, int(b[k])])
		elif k == "contra_defendiendo":
			r.append("%s (%d %% del ataque)" % [nombre, int(round(float(b[k]) * 100.0))])
		elif k == "pm_turno":
			r.append("+%d %s" % [int(b[k]), nombre])
		else:
			r.append("+%d %s" % [int(b[k]), nombre])
	return " · ".join(r)


# Resumen para menús y pruebas: orbes gastados y nodos de cada héroe.
static func resumen(heroe: String) -> String:
	return "%d / %d nodos · %d orbes invertidos" % [nodos_de(heroe).size(), tablero(heroe).size(), gastados(heroe)]


static func texto_faltan(n: int) -> String:
	return "falta 1 orbe" if n == 1 else "faltan %d orbes" % n
