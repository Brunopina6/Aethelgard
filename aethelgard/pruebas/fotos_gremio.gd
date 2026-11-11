extends SceneTree
# Capturas del Gremio de aventureros (V11, hito C), para revisarlas una persona: el tablón en la plaza de Oakhaven 2D
# con su botón, la ventana con los contratos (uno aceptado y uno cobrado) y el rango. Uso: «-- salida=<carpeta>».

var salida := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	Engine.set_meta("archivo_partida_prueba", "user://fotos_gremio.save")
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await _esperar(8)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(salida)
	root.get_texture().get_image().save_png(salida.path_join(nombre + ".png"))
	print("FOTO ", nombre)


func _probar() -> void:
	var Gr = load("res://gremio.gd")
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad"})
	var c: Vector2 = load("res://ciudades/oakhaven.gd").PIEZAS.filter(func(p): return p["id"] == "oak_tablon_gremio")[0]["casilla"]
	Engine.set_meta("pos_zona", (c + Vector2(0.4, 0.8)) * 64.0)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	Gr.aceptar("gr_limos")
	Gr.contar_derrotas(["slime", "slime", "slime"])
	Gr.cobrar("gr_limos")
	Gr.aceptar("gr_musgo")
	Engine.get_meta("gremio")["proyectos"] = ["pr_braseros"]   # los braseros de la plaza, ya pagados
	change_scene_to_file("res://ciudad_oakhaven.tscn")
	await _esperar(60)
	await _foto("00_tablon_plaza")
	current_scene._accion()
	await _foto("01_ventana_gremio")
	print("FIN")
	quit(0)
