extends SceneTree
# Tirón al volver del combate a Pastos Verdes 3D (rend2, 12/11, segunda pasada): medir_escenas.gd vio 115-137 ms en el
# fotograma ~70 tras volver, al crear el retrato de Dialogic (RetratoVivo). Aquí, con la carga común del arranque ya hecha
# como en el juego («con_carga»), se entra en Pastos, se lanza un combate, se vuelve y se miden los 200 fotogramas de la
# vuelta (5 s): el peor, en qué fotograma, qué nodos entraron justo antes y qué diálogo de Dialogic empezó. Dos vueltas.
# CON ventana y datos aislados.
# Uso: Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/sonda_retrato.gd --
#        salida=<carpeta> [etiqueta=x] [con_carga] [sin_precalentar_retratos] 3d sin_prologo auto

const PASTOS := "res://zonas3d/pastos_verdes_3d.tscn"
var salida := ""
var etiqueta := ""
var res := {}
var nuevos: Array = []
var dialogos: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
		elif a == "sin_precalentar_retratos":
			Engine.set_meta("sin_precalentar_retratos", true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.set_meta("calidad_proto", "medio")
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos", "grupo_combate", "combate_fijo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	node_added.connect(func(n: Node):
		if nuevos.size() > 0 and nuevos[-1].size() < 14:
			nuevos[-1].append("%s:%s" % [n.get_class(), String(n.name).left(20)]))
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		Engine.max_fps = 0
		var v = current_scene
		if v != null and v.get("perfil_fps") != null:
			v.perfil_fps = 0
		if v != null and v.get("pasos") != null:
			v.pasos = 0


func _hasta(ruta: String) -> void:
	var R = root.get_node("Recursos")
	for i in 3000:
		await _esperar(1)
		if current_scene != null and current_scene.scene_file_path == ruta and not R.cambiando:
			return


func _probar() -> void:
	await _esperar(3)
	var R = root.get_node("Recursos")
	if "con_carga" in OS.get_cmdline_user_args():
		var tc := Time.get_ticks_usec()
		for ruta in R.listar():
			if not R.esta(ruta):
				var r = load(ruta)
				if r != null:
					R.guardar(ruta, r)
		res["carga_comun_ms"] = snappedf((Time.get_ticks_usec() - tc) / 1000.0, 1.0)
	R.precalentar_dialogos()
	var dg = root.get_node_or_null("Dialogic")
	if "dialogo_antes" in OS.get_cmdline_user_args() and dg != null:    # prueba: el mismo diálogo, visible, antes de todo
		var t0 := Time.get_ticks_usec()
		dg.start("res://dialogos/pv_02.dtl")
		await _esperar(10)
		res["dialogo_antes_ms"] = snappedf((Time.get_ticks_usec() - t0) / 1000.0, 0.1)
		dg.end_timeline()
		await _esperar(10)
	if "capa_antes" in OS.get_cmdline_user_args() and dg != null:      # prueba: solo enseñar la interfaz vacía 3 fotogramas
		var capa = dg.Styles.get_layout_node()
		capa.show()
		await _esperar(3)
		capa.hide()
	if "texto_antes" in OS.get_cmdline_user_args() and dg != null:     # prueba: la interfaz con un texto y un nombre
		var capa = dg.Styles.get_layout_node()
		for n in get_nodes_in_group("dialogic_dialog_text") + get_nodes_in_group("dialogic_name_label"):
			n.text = "Kael: Pastos Verdes. Ni rastro de niebla, ¿y tú? ¡Ánimo! áéíóúñÁÉÍÓÚÑ 0123456789"
			n.visible_ratio = 1.0 if "visible_ratio" in n else 1.0
		capa.show()
		await _esperar(3)
		capa.hide()
	if "retrato_antes" in OS.get_cmdline_user_args() and dg != null:   # prueba: entra Kael con su retrato y se va
		var capa = dg.Styles.get_layout_node()
		capa.show()
		var kael = load("res://dialogos/personajes/kael.dch")
		var t0 := Time.get_ticks_usec()
		dg.Portraits.join_character(kael, "vivo_pv", "left")
		res["unir_ms"] = snappedf((Time.get_ticks_usec() - t0) / 1000.0, 0.1)
		await _esperar(4)
		dg.Portraits.remove_character(kael)
		capa.hide()
		print("SONDA unir: ", res["unir_ms"])
	if "guiones_dialogic" in OS.get_cmdline_user_args():              # prueba: compilar ya los guiones de Dialogic
		var lista: Array = []
		_gd("res://addons/dialogic/", lista)
		var t0 := Time.get_ticks_usec()
		var n := 0
		for g in lista:
			if not ResourceLoader.has_cached(g):
				var t1 := Time.get_ticks_usec()
				var sc = load(g)
				var ms := (Time.get_ticks_usec() - t1) / 1000.0
				if ms > 3.0:
					print("SONDA guion %.1f ms %s" % [ms, g])
				R.guardar(g, sc)
				n += 1
		print("SONDA guiones de Dialogic: %d en %.0f ms" % [n, (Time.get_ticks_usec() - t0) / 1000.0])
	if "partes" in OS.get_cmdline_user_args():      # qué parte del primer diálogo es la cara (cada una, cronometrada)
		var pasos := [["leer pv_02.dtl", func(): return load("res://dialogos/pv_02.dtl")]]
		var tl = null
		for p in pasos:
			var t0 := Time.get_ticks_usec()
			tl = p[1].call()
			res["parte_" + p[0]] = snappedf((Time.get_ticks_usec() - t0) / 1000.0, 0.1)
		var t1 := Time.get_ticks_usec()
		tl.process()
		res["parte_procesar"] = snappedf((Time.get_ticks_usec() - t1) / 1000.0, 0.1)
		var t2 := Time.get_ticks_usec()
		for c in ["kael", "lya", "tilo"]:
			var ch = load("res://dialogos/personajes/%s.dch" % c)
		res["parte_personajes"] = snappedf((Time.get_ticks_usec() - t2) / 1000.0, 0.1)
		var t3 := Time.get_ticks_usec()
		var rv: Node = load("res://dialogos/retrato_vivo.tscn").instantiate()
		root.add_child(rv)
		res["parte_retrato"] = snappedf((Time.get_ticks_usec() - t3) / 1000.0, 0.1)
		rv.queue_free()
		print("SONDA partes: ", res)
		await _esperar(5)
	if dg != null:
		dg.timeline_started.connect(func():
			dialogos.append(str(dg.current_timeline.resource_path) if dg.current_timeline != null else "?"))
	var antes_cache := {}                          # qué guiones de Dialogic no estaban compilados antes del diálogo
	var todos_gd: Array = []
	_gd("res://addons/dialogic/", todos_gd)
	_gd("res://dialogos/", todos_gd)
	for g in todos_gd:
		antes_cache[g] = ResourceLoader.has_cached(g)
	change_scene_to_file(PASTOS)
	await _hasta(PASTOS)
	await _esperar(90)
	for vuelta in 2:
		current_scene._encuentro("", 0)
		await _hasta("res://combate.tscn")
		for i in 900:                              # con «auto» los héroes atacan solos: como medir_escenas, 600 fotogramas
			await _esperar(1)
			if current_scene == null or current_scene.scene_file_path != "res://combate.tscn" or i >= 600:
				break
		if current_scene != null and current_scene.scene_file_path == "res://combate.tscn":
			current_scene._volver_al_mapa()
		await _hasta(PASTOS)
		nuevos = [[]]
		dialogos = []
		var fot: Array = []
		var proc: Array = []
		var ant := Time.get_ticks_usec()
		var t_inicio := Time.get_ticks_usec()
		for i in 3000:                             # 5 s de juego (en medir_escenas, a 30 FPS fijos, salía a ~2,3 s)
			if Time.get_ticks_usec() - t_inicio > 5000000:
				break
			await _esperar(1)
			var ahora := Time.get_ticks_usec()
			fot.append(snappedf((ahora - ant) / 1000.0, 0.1))
			proc.append(snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.1))
			ant = ahora
			nuevos.append([])
		var peor: float = fot.max()
		var j := fot.find(peor)
		var orden := fot.duplicate()
		orden.sort()
		res["vuelta_%d" % (vuelta + 1)] = {"peor_ms": peor, "en_el_fotograma": j, "mediana_ms": orden[orden.size() / 2], "fotogramas": fot.size(),
			"proceso_ms_en_el_peor": proc[j], "proceso_ms_siguiente": proc[mini(j + 1, proc.size() - 1)], "mas_de_50": fot.filter(func(x): return x > 50.0).size(), "dialogos": dialogos.duplicate(),
			"nodos": nuevos[maxi(0, j - 1)] + nuevos[j]}
		print("SONDA proceso (guiones) en ese fotograma y el siguiente: %.1f / %.1f ms" % [proc[j], proc[mini(j + 1, proc.size() - 1)]])
		print("SONDA vuelta %d: peor %.1f ms en el fotograma %d (mediana %.1f), diálogos %s, nodos %s" % [vuelta + 1, peor, j,
			orden[orden.size() / 2], dialogos, (nuevos[maxi(0, j - 1)] + nuevos[j]).slice(0, 6)])
		if vuelta == 0:
			var nuevos_gd: Array = []
			for g in todos_gd:
				if not antes_cache[g] and ResourceLoader.has_cached(g):
					nuevos_gd.append(g)
			res["guiones_del_primer_dialogo"] = nuevos_gd
			print("SONDA guiones compilados en el primer diálogo: ", nuevos_gd)
		if dg != null and dg.current_timeline != null:
			dg.end_timeline()
		await _esperar(30)
	var f := FileAccess.open(salida.path_join("sonda_retrato_%s.json" % etiqueta), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "\t"))
	f.close()
	print("SONDA FIN")
	quit(0)


func _gd(c: String, r: Array) -> void:
	for n in ResourceLoader.list_directory(c):
		if n.ends_with("/"):
			if not "Editor" in n and not "editor" in n:
				_gd(c.path_join(n), r)
		elif n.ends_with(".gd") and not n.contains("editor"):
			r.append(c.path_join(n))
