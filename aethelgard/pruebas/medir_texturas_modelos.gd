extends SceneTree
# Qué texturas de la raíz de res:// usan de verdad los modelos (fase 2, 10/11). Carga cada modelo .fbx/.glb de la raíz,
# recorre sus materiales y apunta las texturas que alcanza. Después lista las imágenes de la raíz que ningún modelo
# alcanza ni ningún script o escena nombra: candidatas a no precargarse. Sin ventana; no cambia nada.
func _initialize() -> void:
	_medir.call_deferred()


func _texturas_de(n: Node, usadas: Dictionary) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mats: Array = [mi.material_override]
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				mats.append(mi.mesh.surface_get_material(s))
				mats.append(mi.get_surface_override_material(s))
		for m in mats:
			if m is Material:
				for p in m.get_property_list():             # cualquier textura del material, sea del tipo que sea
					var t = m.get(p["name"])
					if t is Texture2D and t.resource_path != "":
						usadas[t.resource_path.get_file()] = true
				if m is ShaderMaterial:
					for p in m.get_property_list():
						if str(p["name"]).begins_with("shader_parameter/"):
							var t2 = m.get(p["name"])
							if t2 is Texture2D and t2.resource_path != "":
								usadas[t2.resource_path.get_file()] = true
	for h in n.get_children():
		_texturas_de(h, usadas)


func _medir() -> void:
	var usadas := {}
	for f in DirAccess.get_files_at("res://"):
		if f.get_extension() in ["fbx", "glb"]:
			var e = load("res://" + f)
			if e is PackedScene:
				var n: Node = e.instantiate()
				var antes := usadas.size()
				_texturas_de(n, usadas)
				print("modelo %-70s %d texturas nuevas" % [f, usadas.size() - antes])
				n.free()
	var textos := ""
	for carpeta in ["res://"]:
		for f in DirAccess.get_files_at(carpeta):
			if f.get_extension() in ["gd", "tscn", "tres"]:
				textos += FileAccess.get_file_as_string(carpeta + f)
	for d in DirAccess.get_directories_at("res://"):
		if d.begins_with("."):
			continue
		for f in _todos("res://" + d):
			textos += FileAccess.get_file_as_string(f)
	var total := 0
	print("IMÁGENES DE LA RAÍZ QUE NINGÚN MODELO USA NI NINGÚN TEXTO NOMBRA:")
	for f in DirAccess.get_files_at("res://"):
		if not f.get_extension() in ["png", "jpg", "webp"]:
			continue
		if usadas.has(f) or textos.contains(f) or textos.contains(f.get_basename()):
			continue
		var peso := _peso("res://" + f)
		total += peso
		print("  %6.1f MB  %s" % [peso / 1048576.0, f])
	print("TOTAL: %.1f MB importados" % (total / 1048576.0))
	print("USADAS POR LOS MODELOS: ", usadas.keys())
	for f in ["kael_2.png", "kael_3.png", "garon_2.png", "garon_3.png", "goblin_2.png", "goblin_3.png"]:
		print("  %s: %s" % [f, "la usa un modelo" if usadas.has(f) else "NINGÚN modelo la usa"])
	quit(0)


func _todos(c: String) -> PackedStringArray:
	var r := PackedStringArray()
	for f in DirAccess.get_files_at(c):
		if f.get_extension() in ["gd", "tscn", "tres"]:
			r.append(c + "/" + f)
	for d in DirAccess.get_directories_at(c):
		r.append_array(_todos(c + "/" + d))
	return r


func _peso(ruta: String) -> int:
	var cfg := ConfigFile.new()
	if cfg.load(ruta + ".import") == OK:
		for k in cfg.get_section_keys("remap"):
			if k.begins_with("path"):
				var dest: String = cfg.get_value("remap", k, "")
				if FileAccess.file_exists(dest):
					return FileAccess.open(dest, FileAccess.READ).get_length()
	return 0
