extends SceneTree
# Coste de un combate en el PC (rend3, 13/11): lo apagado mÃ¡s caro para cuando se encienda. CON ventana y datos aislados.
# Un combate con un grupo de enemigos fijo (GRUPOS[N]) y el grupo de hÃ©roes pedido; con los enemigos quietos, mide 240
# fotogramas: mediana del tiempo de GPU (viewport_get_measured_render_time_gpu de la ventana principal y la suma de las
# SubViewport de los personajes), dibujos y primitivas por fotograma, cuÃ¡ntas SubViewport hay y la memoria de vÃ­deo.
# Uso: Godot --path aethelgard --resolution 1280x720 --script res://pruebas/herramientas/sonda_combate_coste.gd --
#        salida=<carpeta> etiqueta=<x> grupo=<N> [heroes=Kael,Lya,Garon] [meta=turnos_v12,nix_v12,enemigos_v12]

var salida := ""
var etiqueta := ""
var grupo := 1
var heroes: Array = ["Kael", "Lya", "Garon"]
var c = null


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
		elif a.begins_with("grupo="):
			grupo = int(a.substr(6))
		elif a.begins_with("heroes="):
			heroes = Array(a.substr(7).split(","))
		elif a.begins_with("meta="):
			for m in a.substr(5).split(","):
				Engine.set_meta(m, true)
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.set_meta("archivo_partida_prueba", "user://sonda_combate_coste.save")
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("grupo_activo", heroes)
	Engine.set_meta("zona", "pastos")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		Engine.max_fps = 0
		if c != null and is_instance_valid(c):
			for e in c.enemigos:
				e["atb"] = 0.0


func _probar() -> void:
	await _esperar(5)
	var t0 := Time.get_ticks_usec()
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	var ready_ms := (Time.get_ticks_usec() - t0) / 1000.0
	await _esperar(120)
	var vps: Array = c.find_children("*", "SubViewport", true, false).filter(func(v): return is_instance_valid(v))
	for v in vps:
		RenderingServer.viewport_set_measure_render_time((v as SubViewport).get_viewport_rid(), true)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	await _esperar(10)
	var gpu: Array = []
	var gpu_sub: Array = []
	var dib: Array = []
	var prim: Array = []
	for i in 240:
		await _esperar(1)
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		var s := 0.0
		for v in vps:
			if is_instance_valid(v):
				s += RenderingServer.viewport_get_measured_render_time_gpu((v as SubViewport).get_viewport_rid())
		gpu_sub.append(s)
		dib.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		prim.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	for a in [gpu, gpu_sub, dib, prim]:
		a.sort()
	vps = vps.filter(func(v): return is_instance_valid(v))   # (las de los efectos que se precalientan se borran solas)
	var tam := {}
	for v in vps:
		var k := "%dx%d" % [v.size.x, v.size.y]
		tam[k] = tam.get(k, 0) + 1
	var res := {"grupo": grupo, "heroes": heroes, "enemigos": c.enemigos.map(func(e): return str(e.get("nombre", ""))),
		"ready_ms": snappedf(ready_ms, 0.1), "subviewports": vps.size(), "tamanos": tam,
		"gpu_principal_ms": snappedf(gpu[120], 0.01), "gpu_subviewports_ms": snappedf(gpu_sub[120], 0.01),
		"dibujos": dib[120], "primitivas": prim[120],
		"video_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1)}
	print("SONDA ", JSON.stringify(res))
	await _esperar(2)
	var f := FileAccess.open(salida.path_join("coste_%s.json" % etiqueta), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "\t"))
	f.close()
	if FileAccess.file_exists("user://sonda_combate_coste.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://sonda_combate_coste.save"))
	quit(0)
