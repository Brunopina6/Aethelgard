extends Node3D
# DUEÑO: agente C — stub de la fase 0. Firmas EXACTAS del contrato (docs/v12/BARRIO_OAKHAVEN_PLAN.md §11) con valores
# neutros: no hay vecinos, rutinas ni objetos; la región (zonas3d/barrio/barrio.gd) ya lo crea y lo llama.
#
# Lo que la región espera de este archivo (docs/v12/BARRIO_OAKHAVEN.md, «Contrato»):
#   - montar(region): una vez en el _ready de la región (ya hay Kael, cámara e interiores). region.ancla(id) da las
#     anclas (exteriores de trazado.gd e «int_*» de los interiores); region.interior dice dónde está Kael.
#   - piezas(): [[id_npc, posición, radio, texto del botón]] de la zona actual (fuera o el interior de Kael). Si el
#     botón elegido es un id de esta lista, la región llama a hablar(id).
#   - hablar(id): empieza la conversación (puede llamar a region.iniciar_dialogo(ruta) o region.avisar(frase)).
#   - reanudar_todos(): la región lo llama al acabar cada diálogo.
#   - ocupa(p): true si p lo ocupa un vecino o el caballo (la región no deja pisarlo).
#   - al_interior(id): la región avisa de que Kael ha entrado en un interior (id) o ha salido ("").
#   - vio(hecho): señal para lo que el jugador ve pasar (la misión, el Diario).

signal vio(hecho: String)

var region = null


func montar(r) -> void:
	region = r


func piezas() -> Array:
	return []


func hablar(_id: String) -> void:
	pass


func reanudar_todos() -> void:
	pass


func ocupa(_p: Vector3) -> bool:
	return false


func al_interior(_id: String) -> void:
	pass


# Cachés estáticas: las suelta banco_pruebas.salir() y la región al salir del árbol.
static func soltar_caches() -> void:
	pass
