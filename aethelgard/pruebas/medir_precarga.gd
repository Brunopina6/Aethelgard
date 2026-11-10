extends SceneTree
# Medida de la precarga del arranque (10/11, auditoría de rendimiento): qué archivos lista Recursos.listar(), por carpeta
# de primer nivel, cuánto pesan importados (.godot/imported o el propio archivo) y cuánto tarda cargarlos uno a uno.
# Sin ventana. Escribe la tabla en la salida. No cambia nada del juego.
func _initialize() -> void:
	_medir.call_deferred()


func _peso(ruta: String) -> int:
	var imp := ruta + ".import"
	if FileAccess.file_exists(imp):
		var cfg := ConfigFile.new()
		if cfg.load(imp) == OK:
			var dest = cfg.get_value("remap", "path", "")
			if dest == "":
				for k in cfg.get_section_keys("remap"):
					if k.begins_with("path."):
						dest = cfg.get_value("remap", k, "")
						break
			if dest != "" and FileAccess.file_exists(dest):
				var f := FileAccess.open(dest, FileAccess.READ)
				return f.get_length() if f != null else 0
	var g := FileAccess.open(ruta, FileAccess.READ)
	return g.get_length() if g != null else 0


func _medir() -> void:
	var rec = root.get_node("Recursos")
	var lista: PackedStringArray = rec.listar()
	var por := {}
	var t_total := 0
	for ruta in lista:
		var partes := ruta.substr(6).split("/")
		var carpeta: String = partes[0] if partes.size() > 1 else "(raíz)"
		if not por.has(carpeta):
			por[carpeta] = [0, 0, 0]
		var t0 := Time.get_ticks_usec()
		var r := ResourceLoader.load(ruta)
		var dt := Time.get_ticks_usec() - t0
		t_total += dt
		por[carpeta][0] += 1
		por[carpeta][1] += _peso(ruta)
		por[carpeta][2] += dt
	var claves := por.keys()
	claves.sort_custom(func(a, b): return por[a][1] > por[b][1])
	print("PRECARGA: %d archivos, %.1f MB importados, %.1f s cargándolos uno a uno (PC)" % [lista.size(), _suma(por, 1) / 1048576.0, t_total / 1e6])
	for k in claves:
		print("  %-22s %4d archivos  %7.1f MB  %6.2f s" % [k, por[k][0], por[k][1] / 1048576.0, por[k][2] / 1e6])
	print("Memoria estática tras cargarlo todo: %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	quit(0)


func _suma(por: Dictionary, i: int) -> float:
	var s := 0.0
	for k in por:
		s += por[k][i]
	return s
