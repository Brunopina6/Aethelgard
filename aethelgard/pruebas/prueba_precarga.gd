extends SceneTree
# Precarga del arranque (fase 2, 10/11; recursos.gd listar):
#   1. No se dejó fuera nada que se use: cada dependencia de cada modelo .fbx/.glb precargado está en la lista, y
#      ninguna imagen que se quedó fuera la nombra un script, una escena o un recurso.
#   2. Lo que nunca va en la APK (vegetacion_prueba/, pruebas/) no se precarga.
#   3. Modelos con versión ligera (Oakhaven 3D): con el perfil bajo o medio, solo la ligera; con el alto, solo la
#      completa; los que no tienen ligera, siempre.
# Sin ventana ni escenas.

var fallos := 0


func _initialize() -> void:
	var R = load("res://recursos.gd")
	var alto: PackedStringArray = _lista(R, "alto")
	var bajo: PackedStringArray = _lista(R, "bajo")
	var medio: PackedStringArray = _lista(R, "medio")
	print("Precarga: %d archivos con el perfil alto, %d con el bajo, %d con el medio" % [alto.size(), bajo.size(), medio.size()])
	_nada_que_falte(alto)
	_nada_que_falte(bajo)
	for ruta in alto + bajo:
		if ruta.begins_with("res://vegetacion_prueba/") or ruta.begins_with("res://pruebas/"):
			_fallo("2: se precarga %s, que no va en la APK" % ruta)
			break
	_perfiles(alto, bajo, medio)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _fallo(t: String) -> void:
	fallos += 1
	if fallos < 30:
		print("FALLO: ", t)


func _lista(R, perfil: String) -> PackedStringArray:
	Engine.set_meta("calidad_proto", perfil)
	var r = R.new()
	var l: PackedStringArray = r.listar()
	r.free()
	Engine.remove_meta("calidad_proto")
	return l


func _ruta(dep: String) -> String:
	var p := dep.substr(maxi(0, dep.find("res://")))
	return p.substr(0, p.find("::")) if p.find("::") >= 0 else p


func _nada_que_falte(lista: PackedStringArray) -> void:
	var en := {}
	for r in lista:
		en[r] = true
	for r in lista:
		if r.get_extension() in ["fbx", "glb"]:
			for dep in ResourceLoader.get_dependencies(r):
				var d := _ruta(dep)
				if d.get_extension() in ["png", "jpg", "jpeg", "webp"] and not en.has(d):
					_fallo("1: %s usa %s y no se precarga" % [r, d])
	# Las imágenes de la raíz que se quedaron fuera: nadie las nombra.
	var textos := _textos("res://")
	for f in DirAccess.get_files_at("res://"):
		if f.get_extension() == "png" and not en.has("res://" + f) and textos.contains(f):
			_fallo("1: %s no se precarga y algún script o escena la nombra" % f)


func _textos(c: String) -> String:
	var t := ""
	for f in DirAccess.get_files_at(c):
		if f.get_extension() in ["gd", "tscn", "tres"] and not c.begins_with("res://pruebas"):
			t += FileAccess.get_file_as_string(c.path_join(f))
	for d in DirAccess.get_directories_at(c):
		if not d.begins_with(".") and d != "addons":
			t += _textos(c.path_join(d))
	return t


func _perfiles(alto: PackedStringArray, bajo: PackedStringArray, medio: PackedStringArray) -> void:
	var M := "res://zonas3d/oakhaven/modelos/"
	if not ResourceLoader.exists(M + "taberna_ligero.glb"):
		_fallo("3: no encuentro los modelos de Oakhaven 3D")
		return
	for n in ["taberna", "casa_3x4", "concejo", "arbol"]:
		if not (M + n + ".glb") in alto or (M + n + "_ligero.glb") in alto:
			_fallo("3: con el alto, %s debe ir completo y sin la ligera" % n)
		for l in [bajo, medio]:
			if (M + n + ".glb") in l or not (M + n + "_ligero.glb") in l:
				_fallo("3: con el bajo o el medio, %s debe ir solo en ligero" % n)
	for n in ["plaza", "farol", "puerta_sur"]:                # sin versión ligera: siempre
		for l in [alto, bajo, medio]:
			if not (M + n + ".glb") in l:
				_fallo("3: %s (sin versión ligera) no se precarga" % n)
