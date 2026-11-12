extends SceneTree
# Cuánto cuesta crear a los acompañantes 3D (Lya y Garon, como zonas3d/grupo_3d.gd _crear) y a Kael (rend2, 12/11), la
# primera vez y las siguientes, con lo común ya cargado como en el juego («con_carga») o sin cargar (como
# medir_escenas.gd). CON ventana y datos aislados.
# Uso: Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/sonda_grupo.gd --
#        salida=<carpeta> [etiqueta=x] [con_carga] [veces=3]

const QUIENES := {"Kael": "res://kael_3d.gd", "Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd"}
var salida := ""
var etiqueta := ""
var veces := 3
var res := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
		elif a.begins_with("veces="):
			veces = int(a.substr(6))
	DirAccess.make_dir_recursive_absolute(salida)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _probar() -> void:
	await _esperar(5)
	var R = root.get_node("Recursos")
	if "con_carga" in OS.get_cmdline_user_args():
		var tc := Time.get_ticks_usec()
		for ruta in R.listar():
			if not R.esta(ruta):
				var r = load(ruta)
				if r != null:
					R.guardar(ruta, r)
		res["carga_comun_ms"] = snappedf((Time.get_ticks_usec() - tc) / 1000.0, 1.0)
		await _esperar(5)
	var hv = load("res://personajes/heroes_v2/heroes_v2.gd")
	for i in veces:
		for q in QUIENES:
			var t0 := Time.get_ticks_usec()
			var guion = load(hv.script_de(QUIENES[q]))
			var t1 := Time.get_ticks_usec()
			var nodo = guion.new()
			root.add_child(nodo)
			var t2 := Time.get_ticks_usec()
			var ms := [snappedf((t1 - t0) / 1000.0, 0.1), snappedf((t2 - t1) / 1000.0, 0.1)]
			res["%s_%d" % [q, i + 1]] = {"guion_ms": ms[0], "crear_ms": ms[1]}
			print("SONDA %s, vez %d: guion %.1f ms, crear y añadir %.1f ms" % [q, i + 1, ms[0], ms[1]])
			await _esperar(3)
			nodo.queue_free()
			await _esperar(3)
	var f := FileAccess.open(salida.path_join("sonda_grupo_%s.json" % etiqueta), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "\t"))
	f.close()
	print("SONDA FIN")
	quit(0)
