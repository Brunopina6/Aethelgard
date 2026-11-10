extends RefCounted
# Servicios de los comercios de Oakhaven (V10, docs/v10/DISENO_V10.md): lo que pasa al hablar con quien atiende.
# Lo usan la ciudad 2D (ciudad_oakhaven.gd, al acabar el diálogo con la señal oak:servicio_<x>) y el distrito 3D
# (zonas3d/oakhaven/distrito.gd). Reutiliza lo que ya hay: los talleres (alquimia_menu.gd) y la tienda (tienda.gd).
#   forja      → la forja de Kael (Maese Ferro)
#   armaduras  → armaduras y runas de Garon (Hilda)
#   botica     → «¿Qué necesitáis?»: comprar ingredientes (tienda, pestaña Botica) o la alquimia de Lya (Mirta)
# Devuelve el nodo abierto (o null) para que quien llama sepa cuándo se cierra (señal «cerrado»).

const SERVICIOS := ["forja", "armaduras", "botica"]


static func abrir(padre: Node, servicio: String) -> Node:
	match servicio:
		"forja", "armaduras":
			return _taller(padre, servicio)
		"botica":
			return _botica(padre)
	push_warning("Servicios: «%s» no existe" % servicio)
	return null


static func _taller(padre: Node, taller: String) -> Node:
	var a = load("res://alquimia_menu.gd").new()
	a.taller = taller
	padre.add_child(a)
	return a


# La botica: un pequeño menú con lo que se puede hacer allí.
static func _botica(padre: Node) -> Node:
	var capa = load("res://servicios_botica.gd").new()
	padre.add_child(capa)
	return capa
