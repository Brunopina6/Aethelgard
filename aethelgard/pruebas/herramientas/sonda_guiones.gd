extends SceneTree
# Qué guiones (.gd) no están en memoria después de la carga común del arranque (Recursos.listar(), como carga.gd) y cuánto
# cuesta leerlos y compilarlos la primera vez que el juego hace load() de ellos (rend2, 12/11). Sin ventana.
# Uso: Godot --headless --path aethelgard --script res://pruebas/herramientas/sonda_guiones.gd -- salida=<archivo.txt>

func _initialize() -> void:
	_probar.call_deferred()


func _guiones(c: String, r: PackedStringArray) -> void:
	for n in ResourceLoader.list_directory(c):
		var ruta := c.path_join(n)
		if n.ends_with("/"):
			if not ruta.begins_with("res://addons") and not ruta.begins_with("res://pruebas") and not ruta.begins_with("res://.godot") \
					and not ruta.begins_with("res://retirado"):
				_guiones(ruta, r)
		elif n.ends_with(".gd"):
			r.append(ruta)


func _probar() -> void:
	var salida := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	var R = root.get_node("Recursos")
	for ruta in R.listar():
		if not R.esta(ruta):
			var r = load(ruta)
			if r != null:
				R.guardar(ruta, r)
	var lista := PackedStringArray()
	_guiones("res://", lista)
	var filas: Array = []
	for g in lista:
		if ResourceLoader.has_cached(g):
			continue
		var t := Time.get_ticks_usec()
		var s = load(g)
		filas.append([(Time.get_ticks_usec() - t) / 1000.0, g])
		if s != null:
			R.guardar(g, s)                     # que siga en memoria: así el siguiente no recompila sus dependencias
	filas.sort_custom(func(a, b): return a[0] > b[0])
	var f := FileAccess.open(salida, FileAccess.WRITE)
	var total := 0.0
	for x in filas:
		total += x[0]
		f.store_line("%7.1f ms  %s" % [x[0], x[1]])
	f.store_line("TOTAL %.0f ms en %d guiones no cargados tras la carga común" % [total, filas.size()])
	f.close()
	print("SONDA guiones: %d, %.0f ms" % [filas.size(), total])
	quit()
