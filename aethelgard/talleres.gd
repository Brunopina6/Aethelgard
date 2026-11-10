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
	if not Inv.objeto(r.resultado).is_empty():       # un arma, protección o accesorio: a los equipables
		Inv.agregar(r.resultado)
	else:                                            # un objeto o un material: a los objetos
		Inv.agregar_objeto(r.resultado, r.cantidad)
	return true
