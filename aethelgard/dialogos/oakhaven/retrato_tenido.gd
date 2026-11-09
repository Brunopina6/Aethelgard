@tool
extends "res://addons/dialogic/Modules/Character/default_portrait.gd"
# Retrato PROVISIONAL de los vecinos nuevos de Oakhaven (T-089) que aún no tienen arte propio: reutiliza una de las
# cuatro ilustraciones de NPC que hay (dialogos/retratos/) con otro tinte, para no confundirlo con su dueño.
# El tinte va en el .dch del personaje («tinte» en export_overrides). Se quita cuando llegue su retrato (el arte
# pendiente está en docs/memory/agents/narrativa.md). Solo tiñe la imagen: los fundidos y el foco de Dialogic, que
# cambian «modulate» del nodo, se siguen viendo igual.

@export var tinte := Color.WHITE


func _update_portrait(passed_character: DialogicCharacter, passed_portrait: String) -> void:
	super._update_portrait(passed_character, passed_portrait)
	$Portrait.self_modulate = tinte
