extends SceneTree
# Capturas de «Las parejas del Cuervo» (V11, hito E), para revisarlas una persona: la mesa en el Patio del Cuervo con
# su botón, una partida a medias (dos parejas hechas y dos cartas distintas a la vista) y la partida ganada.
# Uso: «-- salida=<carpeta>». Con ventana.

var salida := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	Engine.set_meta("archivo_partida_prueba", "user://fotos_taberna.save")
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


func _pareja(m, i: int) -> int:
	for k in m.cartas.size():
		if k != i and m.cartas[k]["simbolo"] == m.cartas[i]["simbolo"]:
			return k
	return -1


func _probar() -> void:
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad"})
	var c: Vector2 = load("res://ciudades/oakhaven.gd").PIEZAS.filter(func(p): return p["id"] == "oak_mesa_parejas")[0]["casilla"]
	Engine.set_meta("pos_zona", (c + Vector2(0, -0.7)) * 64.0)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	change_scene_to_file("res://ciudad_oakhaven.tscn")
	await _esperar(60)
	await _foto("00_mesa_patio")
	current_scene._accion()
	await _esperar(5)
	var m = current_scene.juego_abierto
	for i in 2:                                      # dos parejas hechas
		var a := 0
		while m.cartas[a]["hecha"]:
			a += 1
		m.levantar(a)
		m.levantar(_pareja(m, a))
	var x := 0
	while m.cartas[x]["hecha"]:
		x += 1
	var y := x + 1
	while m.cartas[y]["hecha"] or m.cartas[y]["simbolo"] == m.cartas[x]["simbolo"]:
		y += 1
	m.levantar(x)
	m.levantar(y)
	await _foto("01_partida_a_medias")
	await create_timer(1.0).timeout
	for i in m.cartas.size():
		if not m.cartas[i]["hecha"]:
			m.levantar(i)
			m.levantar(_pareja(m, i))
	await _foto("02_ganada")
	print("FIN")
	quit(0)
