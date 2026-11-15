extends RefCounted
# Talleres (fase 2, 10/11): fabricar con una receta (datos/recetas/*.tres). Base técnica sin pantalla: la usarán los
# talleres jugables de la fase 3. No cambia la economía de hoy (no hay recetas aprobadas: datos/recetas/ está vacía).
#   Taller.puede(id)    → "" si se puede, o el motivo
#   Taller.fabricar(id) → gasta los materiales y da el resultado, todo o nada
# Las recetas en borrador solo se pueden fabricar si se pide (pruebas).

const Catalogo := preload("res://datos/catalogo.gd")
const Investigacion := preload("res://investigacion.gd")


static func puede(id: String, con_borradores := false) -> String:
	var r := Catalogo.uno("recetas", id)
	if r == null:
		return "No existe esa receta."
	if r.borrador and not con_borradores:
		return "Esa receta aún no está disponible."
	var mal := error_receta(r)                       # 15/11: una receta mal escrita no se ofrece ni gasta nada
	if mal != "":
		return "Esta receta no es válida (%s)." % mal
	if r.investigacion != "" and Investigacion.estado(r.investigacion) != "completada":
		return "Hay que investigarla antes."
	if _de_un_uso(r) and id in load("res://inventario.gd").datos().get("hechas", []):
		return "Ya está hecho."
	if r.resultado.begins_with("pieza:") or r.resultado.begins_with("runa:"):   # hace falta tener la pieza (V10)
		var pieza: String = r.resultado.get_slice(":", 1)
		if not pieza in load("res://inventario.gd").datos()["equipables"]:
			return "Necesitas %s." % str(load("res://inventario.gd")._objeto_base(pieza).get("nombre", pieza))
	var Inv = load("res://inventario.gd")
	for clave in r.materiales:
		if reservado(clave):
			return "Maese Ferro espera ese %s: llévaselo antes." % clave if clave == "Hierro de la Falla" \
				else "Hace falta el %s para investigar antes." % clave
		if Inv.cantidad(clave) < int(r.materiales[clave]):
			return "Faltan materiales: %s (%d de %d)." % [clave, Inv.cantidad(clave), int(r.materiales[clave])]
	if not _de_un_uso(r) and not Inv.objeto(r.resultado).is_empty() and r.resultado in Inv.datos()["equipables"]:
		return "Ya lo tienes."                       # 15/11: un equipable repetido gastaba los materiales y no daba nada
	return ""


# 15/11 (auditoría externa): qué tiene de malo una receta ("" si está bien), ANTES de gastar nada. Se comprueban el
# formato y el destino del resultado, el atributo o efecto, las cifras y los materiales:
#   "mejora:<héroe>:<ataque|atributo>:<entero > 0>"     héroe de grupo.gd HEROES; atributo de grupo.gd ATRIBUTOS
#   "tecnica:<héroe>:<efecto>:<número > 0 y ≤ máx>"     efecto numérico de equipo_extra.gd EFECTOS
#   "pieza:<equipable>:<ataque|atributo>:<entero > 0>"  equipable que existe
#   "runa:<equipable>:<efecto>:<número > 0 y ≤ máx>"
#   un equipable (inventario.objeto): cantidad 1
#   un objeto de combate (combate.gd OBJETOS_COMBATE) o un material (datos/materiales): cantidad > 0
static func error_receta(r: Resource) -> String:
	var Inv = load("res://inventario.gd")
	var X = load("res://equipo_extra.gd")
	var mats: Dictionary = X.materiales()
	var objetos: Dictionary = load("res://combate.gd").OBJETOS_COMBATE
	if not (r.materiales is Dictionary) or r.materiales.is_empty():
		return "sin materiales"
	for clave in r.materiales:
		var n = r.materiales[clave]
		if not (n is int or n is float) or int(n) <= 0 or float(n) != float(int(n)):
			return "cantidad de %s no válida" % str(clave)
		if not (mats.has(clave) or objetos.has(clave)):
			return "material desconocido «%s»" % str(clave)
	var res := str(r.resultado).strip_edges()
	if res == "":
		return "sin resultado"
	if ":" in res:
		var p := res.split(":")
		if p.size() != 4 or not p[0] in ["mejora", "tecnica", "pieza", "runa"]:
			return "resultado con formato desconocido «%s»" % res
		if p[0] in ["mejora", "tecnica"] and not load("res://grupo.gd").HEROES.has(p[1]):
			return "héroe desconocido «%s»" % p[1]
		if p[0] in ["pieza", "runa"] and Inv._objeto_base(p[1]).is_empty():
			return "pieza desconocida «%s»" % p[1]
		if p[0] in ["mejora", "pieza"]:
			if not (p[2] == "ataque" or p[2] in load("res://grupo.gd").ATRIBUTOS):
				return "atributo desconocido «%s»" % p[2]
			if not p[3].is_valid_int() or int(p[3]) <= 0:
				return "cifra no válida «%s»" % p[3]
		else:
			var ef: Dictionary = X.EFECTOS.get(p[2], {})
			if ef.is_empty() or str(ef.get("tipo", "")) != "num":
				return "efecto desconocido «%s»" % p[2]
			if not p[3].is_valid_float() or float(p[3]) <= 0.0 or float(p[3]) > float(ef.get("max", INF)):
				return "cifra no válida «%s»" % p[3]
		if int(r.cantidad) != 1:
			return "una mejora se hace de una en una"
		return ""
	if not Inv.objeto(res).is_empty():
		return "" if int(r.cantidad) == 1 else "un equipable se hace de uno en uno"
	if not (objetos.has(res) or mats.has(res)):
		return "resultado desconocido «%s»" % res
	if not (r.cantidad is int) or int(r.cantidad) <= 0:
		return "cantidad no válida"
	return ""


# 14/11 (revisión del recorrido): un material ÚNICO que aún hace falta no se vende ni se gasta en el taller:
#   - el Hierro de la Falla mientras «El pedido de Maese Ferro» está pendiente (la veta da uno solo: sin él, Ferro
#     repetía su escena para siempre y la forja del distrito no volvía a abrirse);
#   - el Polvo de cantera (solo lo da el aprendiz del cantero, una vez) mientras no se ha estudiado «La piedra que
#     asienta» (venderlo antes la dejaba bloqueada para siempre).
static func reservado(material: String) -> bool:
	var P = load("res://progreso.gd")
	if material == "Hierro de la Falla":
		return P.hito("enc_herrero_veta") and not P.hito("enc_herrero_fin")
	if material == "Polvo de cantera":
		return Investigacion.estado("lya_cantera") != "completada"
	return false


static func fabricar(id: String, con_borradores := false) -> bool:
	if puede(id, con_borradores) != "":
		return false
	var r := Catalogo.uno("recetas", id)
	var Inv = load("res://inventario.gd")
	# 15/11: primero el resultado y, solo si se ha aplicado, el gasto (todo o nada: si algo falla, el inventario y lo
	# hecho quedan igual)
	if _de_un_uso(r):                                # una mejora o una técnica (V9: oficios), una sola vez
		if not _aplicar(r.resultado):
			return false
		Inv.datos()["hechas"].append(id)
	elif not Inv.objeto(r.resultado).is_empty():     # un arma, protección o accesorio: a los equipables
		if r.resultado in Inv.datos()["equipables"]:
			return false
		Inv.agregar(r.resultado)
	else:                                            # un objeto o un material: a los objetos
		Inv.agregar_objeto(r.resultado, r.cantidad)
	for clave in r.materiales:
		for i in int(r.materiales[clave]):
			Inv.gastar(clave)
	return true


# Resultados de los oficios (V9), de un solo uso:
#   "mejora:<héroe>:<atributo>:<n>"   suma n a su ataque o a un atributo (grupo.gd, estadisticas)
#   "tecnica:<héroe>:<efecto>:<v>"    un efecto de equipo_extra.gd EFECTOS para siempre (equipo_extra.gd, efectos_de)
static func _de_un_uso(r: Resource) -> bool:
	return r.resultado.begins_with("mejora:") or r.resultado.begins_with("tecnica:") \
		or r.resultado.begins_with("pieza:") or r.resultado.begins_with("runa:")


static func _aplicar(resultado: String) -> bool:
	var p := resultado.split(":")
	if p.size() != 4:
		push_warning("Taller: resultado no válido «%s»" % resultado)
		return false
	var d: Dictionary = load("res://inventario.gd").datos()
	if p[0] == "pieza" or p[0] == "runa":            # una pieza concreta (V10): inventario.mejoras_objeto
		if not d["mejoras_objeto"].has(p[1]):
			d["mejoras_objeto"][p[1]] = {}
		var mo: Dictionary = d["mejoras_objeto"][p[1]]
		if p[0] == "pieza":
			mo[p[2]] = int(mo.get(p[2], 0)) + int(p[3])
		else:
			if not mo.has("efectos"):
				mo["efectos"] = {}
			mo["efectos"][p[2]] = float(mo["efectos"].get(p[2], 0.0)) + float(p[3])
		return true
	var clave := "mejoras" if p[0] == "mejora" else "tecnicas"
	if not d[clave].has(p[1]):
		d[clave][p[1]] = {}
	var de: Dictionary = d[clave][p[1]]
	if p[0] == "mejora":
		de[p[2]] = int(de.get(p[2], 0)) + int(p[3])
	else:
		de[p[2]] = float(de.get(p[2], 0.0)) + float(p[3])
	return true


# Qué hace un resultado, en una frase (para la pantalla del taller).
static func texto_resultado(resultado: String) -> String:
	var p := resultado.split(":")
	if p.size() != 4:
		return ""
	if p[0] == "pieza":
		return "%s: +%s de %s, para siempre." % [str(load("res://inventario.gd")._objeto_base(p[1]).get("nombre", p[1])), p[3], p[2]]
	if p[0] == "runa":
		return "Runa en %s: coraza al empezar cada combate." % str(load("res://inventario.gd")._objeto_base(p[1]).get("nombre", p[1])) \
			if p[2] == "barrera_inicio" else "Runa en %s: +%s de %s." % [str(load("res://inventario.gd")._objeto_base(p[1]).get("nombre", p[1])), p[3], p[2]]
	if p[0] == "mejora":
		return "%s: +%s de %s, para siempre." % [p[1], p[3], p[2]]
	var nombres := {"critico": "probabilidad de golpe crítico", "barrera_inicio": "coraza al empezar cada combate",
		"regen": "PV por turno", "pm_turno": "PM por turno"}
	var v := float(p[3])
	var cifra := "%d %%" % int(round(v * 100.0)) if v < 1.0 else str(v)
	return "%s: +%s de %s, para siempre." % [p[1], cifra, nombres.get(p[2], p[2])]
