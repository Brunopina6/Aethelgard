extends SceneTree
# Lista lo que precarga el arranque (Recursos.listar(), lo mismo que carga.gd), archivo por archivo y de mayor a menor
# peso importado, con su carpeta. Sin ventana; no cambia nada. Sirve para decidir qué no hace falta tener en memoria
# toda la partida (V12, 12/11, rendimiento de cargas).
# Uso: --headless --path aethelgard -s res://pruebas/herramientas/listar_precarga.gd -- [perfil=medio] [n=80] [3d]


func _initialize() -> void:
	_listar.call_deferred()


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


func _listar() -> void:
	var n := 80
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			Engine.set_meta("calidad_proto", a.substr(7))
		elif a.begins_with("n="):
			n = int(a.substr(2))
	var lista: PackedStringArray = root.get_node("Recursos").listar()
	var filas: Array = []
	var total := 0
	var por_ext := {}
	for r in lista:
		var p := _peso(r)
		total += p
		filas.append([p, r])
		var e := r.get_extension()
		por_ext[e] = por_ext.get(e, 0) + p
	filas.sort_custom(func(a, b): return a[0] > b[0])
	print("PRECARGA: %d archivos, %.1f MB" % [lista.size(), total / 1048576.0])
	for e in por_ext:
		print("  .%-8s %7.1f MB" % [e, por_ext[e] / 1048576.0])
	for i in mini(n, filas.size()):
		print("  %7.2f MB  %s" % [filas[i][0] / 1048576.0, filas[i][1]])
	quit(0)
