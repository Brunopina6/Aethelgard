extends SceneTree
# Prueba: guardar y volver a cargar la partida con progreso.gd. Usa su propio archivo (user://prueba_guardado.save,
# Engine «archivo_partida_prueba»): nunca toca partida.save ni partida_exp.save, ni siquiera fuera del ejecutor
# aislado (TASKS.md, T-077).

const ARCHIVO := "user://prueba_guardado.save"


func _initialize() -> void:
	var P = load("res://progreso.gd")
	var inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	var fallos: Array = []
	if P.archivo() != ARCHIVO:
		print("FALLO: la prueba no usa su propio archivo, sino %s" % P.archivo())
		quit(1)
		return
	Engine.set_meta("partida_lista", true)          # como si la partida se hubiera cargado al arrancar
	inv.ganar_oro(77)
	Engine.set_meta("lugar", {"indice": 1, "nombre": "Gran Bosque Verde", "tipo": "lugar", "zona": "bosque", "texto": "x"})
	Engine.set_meta("pos_zona", Vector2(1234, 567))
	Engine.set_meta("pos_zona_lugar", 1)
	Engine.set_meta("lore_visto", {"bosque_armadura": true})
	if not P.guardar("res://zona.tscn"):
		fallos.append("guardar() no escribió en el archivo de la prueba")
	var oro: int = inv.oro()
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var escena: String = P.cargar()
	print("escena: ", escena, "  pos_zona: ", Engine.get_meta("pos_zona", null), "  ok: ", Engine.get_meta("pos_zona_ok", null),
		"  oro: ", inv.oro(), " (antes ", oro, ")  lore: ", Engine.get_meta("lore_visto", null))
	if escena != "res://zona.tscn":
		fallos.append("al cargar se vuelve a «%s» y no a la zona" % escena)
	if Engine.get_meta("pos_zona", null) != Vector2(1234, 567) or not Engine.get_meta("pos_zona_ok", false):
		fallos.append("no se recupera la posición en la zona")
	if inv.oro() != oro:
		fallos.append("el oro cargado (%d) no es el guardado (%d)" % [inv.oro(), oro])
	if Engine.get_meta("lore_visto", {}) != {"bosque_armadura": true}:
		fallos.append("no se recupera el lore visto")
	_borrar()
	Engine.remove_meta("archivo_partida_prueba")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
