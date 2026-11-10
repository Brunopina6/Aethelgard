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
	if r.investigacion != "" and Investigacion.estado(r.investigacion) != "completada":
		return "Hay que investigarla antes."
	if _de_un_uso(r) and id in load("res://inventario.gd").datos().get("hechas", []):
		return "Ya está hecho."
	var Inv = load("res://inventario.gd")
	for clave in r.materiales:
		if Inv.cantidad(clave) < int(r.materiales[clave]):
			return "Faltan materiales: %s (%d de %d)." % [clave, Inv.cantidad(clave), int(r.materiales[clave])]
	return ""


static func fabricar(id: String, con_borradores := false) -> bool:
	if puede(id, con_borradores) != "":
		return false
	var r := Catalogo.uno("recetas", id)
	var Inv = load("res://inventario.gd")
	for clave in r.materiales:
		for i in int(r.materiales[clave]):
			Inv.gastar(clave)
	if _de_un_uso(r):                                # una mejora o una técnica (V9: oficios), una sola vez
		_aplicar(r.resultado)
		Inv.datos()["hechas"].append(id)
	elif not Inv.objeto(r.resultado).is_empty():     # un arma, protección o accesorio: a los equipables
		Inv.agregar(r.resultado)
	else:                                            # un objeto o un material: a los objetos
		Inv.agregar_objeto(r.resultado, r.cantidad)
	return true


# Resultados de los oficios (V9), de un solo uso:
#   "mejora:<héroe>:<atributo>:<n>"   suma n a su ataque o a un atributo (grupo.gd, estadisticas)
#   "tecnica:<héroe>:<efecto>:<v>"    un efecto de equipo_extra.gd EFECTOS para siempre (equipo_extra.gd, efectos_de)
static func _de_un_uso(r: Resource) -> bool:
	return r.resultado.begins_with("mejora:") or r.resultado.begins_with("tecnica:")


static func _aplicar(resultado: String) -> void:
	var p := resultado.split(":")
	if p.size() != 4:
		push_warning("Taller: resultado no válido «%s»" % resultado)
		return
	var d: Dictionary = load("res://inventario.gd").datos()
	var clave := "mejoras" if p[0] == "mejora" else "tecnicas"
	if not d[clave].has(p[1]):
		d[clave][p[1]] = {}
	var de: Dictionary = d[clave][p[1]]
	if p[0] == "mejora":
		de[p[2]] = int(de.get(p[2], 0)) + int(p[3])
	else:
		de[p[2]] = float(de.get(p[2], 0.0)) + float(p[3])


# Qué hace un resultado, en una frase (para la pantalla del taller).
static func texto_resultado(resultado: String) -> String:
	var p := resultado.split(":")
	if p.size() != 4:
		return ""
	if p[0] == "mejora":
		return "%s: +%s de %s, para siempre." % [p[1], p[3], p[2]]
	var nombres := {"critico": "probabilidad de golpe crítico", "barrera_inicio": "coraza al empezar cada combate",
		"regen": "PV por turno", "pm_turno": "PM por turno"}
	var v := float(p[3])
	var cifra := "%d %%" % int(round(v * 100.0)) if v < 1.0 else str(v)
	return "%s: +%s de %s, para siempre." % [p[1], cifra, nombres.get(p[2], p[2])]
