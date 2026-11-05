extends SceneTree
# Prueba: guardar (con el mismo formato que progreso.gd) y volver a cargar la partida.

func _initialize() -> void:
	var P = load("res://progreso.gd")
	var hay_antes: bool = P.hay_partida()
	var copia := FileAccess.get_file_as_string(P.GUARDADO) if hay_antes else ""
	load("res://inventario.gd").ganar_oro(77)
	Engine.set_meta("lugar", {"indice": 1, "nombre": "Gran Bosque Verde", "tipo": "lugar", "zona": "bosque", "texto": "x"})
	Engine.set_meta("pos_zona", Vector2(1234, 567))
	Engine.set_meta("pos_zona_lugar", 1)
	Engine.set_meta("escena_guardada", "res://zona.tscn")
	Engine.set_meta("lore_visto", {"bosque_armadura": true})
	var d := {}
	for k in P.CLAVES:
		if Engine.has_meta(k):
			d[k] = Engine.get_meta(k)
	var f := FileAccess.open(P.GUARDADO, FileAccess.WRITE)
	f.store_string(var_to_str(d))
	f.close()
	var oro: int = load("res://inventario.gd").oro()
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var escena: String = P.cargar()
	print("escena: ", escena, "  pos_zona: ", Engine.get_meta("pos_zona"), "  ok: ", Engine.get_meta("pos_zona_ok"),
		"  oro: ", load("res://inventario.gd").oro(), " (antes ", oro, ")  lore: ", Engine.get_meta("lore_visto"))
	if hay_antes:                                  # deja la partida como estaba
		var g := FileAccess.open(P.GUARDADO, FileAccess.WRITE)
		g.store_string(copia)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(P.GUARDADO))
	quit()
