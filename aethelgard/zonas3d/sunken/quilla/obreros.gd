extends Node3D
# La cuadrilla de la Quilla (PROPUESTA): pendiente (fase A2).
var lista: Array = []


func preparar(_q, _anclas: Dictionary, _mat) -> void:
	pass


func avanzar(_delta: float, _escena: Node) -> void:
	pass


func piezas() -> Array:
	return []


func es_obrero(_id: String) -> bool:
	return false


func hablar(_id: String, _desde: Vector3) -> String:
	return ""
