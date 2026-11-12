extends SceneTree
# Herramienta del coordinador (12/11): aplica a combate.gd los cambios de parche_enemigos_v12.gd SALVO los que
# cambian el modelo de cada enemigo (enemigo_*): eso lo decide el interruptor enemigos_v12 en combate.gd.
# Uso: Godot --headless --path aethelgard --script res://pruebas/herramientas/aplicar_parche_enemigos_v12.gd
func _initialize() -> void:
	var P = load("res://pruebas/herramientas/parche_enemigos_v12.gd")
	var t := FileAccess.get_file_as_string("res://combate.gd").replace("\r\n", "\n")
	var faltan := []
	for i in P.CAMBIOS.size():
		var nombre: String = P.CAMBIOS[i][0]
		if nombre.begins_with("enemigo_"):
			continue
		var ancla: String = P.texto_de(i, 1)
		if t.count(ancla) != 1:
			faltan.append("%s (%d)" % [nombre, t.count(ancla)])
			continue
		t = t.replace(ancla, P.texto_de(i, 2))
	if not faltan.is_empty():
		print("NO APLICADO; faltan o se repiten: ", faltan)
		quit(1)
		return
	var f := FileAccess.open("res://combate.gd", FileAccess.WRITE)
	f.store_string(t)
	f.close()
	print("APLICADO")
	quit(0)
