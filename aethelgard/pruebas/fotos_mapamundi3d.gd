extends SceneTree
# V12, mapamundi 3D (15/11/2026): capturas del mapamundi 3D (en pruebas) con ventana, para revisar composición,
# legibilidad y escala a 1600×720 (la pantalla del Redmi). Con «-- 3d mapamundi3d sin_prologo salida=<carpeta>
# [perfil=bajo|medio|alto]» y --resolution 1600x720.
# Fotos: la región entera desde arriba (para comparar con el mapa 2D) y en diorama, y la cámara de juego en la llegada de
# Oakhaven, la bifurcación, el campamento, Pastos Verdes, el Portal, la cueva, el secreto, el viaje rápido abierto y la
# cueva por dentro. Cada foto apunta llamadas de dibujo, primitivas y ms de CPU y GPU del dibujo (PC).
# Partida propia (Engine «archivo_partida_prueba»): nunca la de verdad.

const MM := "res://zonas3d/mapamundi_3d.tscn"
const CUEVA := "res://zonas3d/cueva_provisional_3d.tscn"
var D = load("res://zonas3d/mapamundi/datos.gd")
var salida := ""
var v
var lineas: PackedStringArray = []
var tam := Vector2i(1600, 720)                    # la pantalla del Redmi (20:9); «res=1280x720» para otra


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		if a.begins_with("perfil="):
			Engine.set_meta("calidad_proto", a.substr(7))
		if a.begins_with("res="):
			var q: PackedStringArray = a.substr(4).split("x")
			tam = Vector2i(int(q[0]), int(q[1]))
	DisplayServer.window_set_size(tam)
	root.size = tam
	if salida == "":
		salida = "D:/REBELUM_diagnostico/mapamundi_15_11"
	DirAccess.make_dir_recursive_absolute(salida)
	_correr()


func _ms(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


func _cargar(ruta: String) -> void:
	change_scene_to_file(ruta)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ruta and current_scene.get("kael") != null:
			break
	await _ms(700)
	v = current_scene
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)


func _foto(nombre: String) -> void:
	await _ms(400)
	await RenderingServer.frame_post_draw
	var rid := root.get_viewport_rid()
	var cpu := RenderingServer.viewport_get_measured_render_time_cpu(rid) + RenderingServer.get_frame_setup_time_cpu()
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(rid)
	var img := root.get_texture().get_image()
	if img.get_size() != tam:                       # aspecto «keep»: la vista del juego con las franjas del móvil 20:9
		img.convert(Image.FORMAT_RGBA8)
		var movil := Image.create(tam.x, tam.y, false, Image.FORMAT_RGBA8)
		movil.fill(Color(0, 0, 0, 1))
		movil.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), (tam - img.get_size()) / 2)
		img = movil
	img.save_png(salida.path_join("%s_%s.png" % [nombre, load("res://prototipos/calidad_proto.gd").actual()]))
	var l := "%s · %d dibujos · %d primitivas · CPU dibujo %.2f ms · GPU %.2f ms · perfil %s" % [nombre,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), cpu, gpu,
		load("res://prototipos/calidad_proto.gd").actual()]
	print(l)
	lineas.append(l)


func _poner(p: Vector2, mira := Vector2.ZERO) -> void:
	v._colocar_kael(Vector3(p.x, v.T.altura(p.x, p.y), p.y))
	if mira != Vector2.ZERO:
		v.kael.mirar(Vector3(mira.x, 0, mira.y), 0.05)
	for e in v.entradas:
		v.entradas[e]["armada"] = false
	await _ms(300)


func _correr() -> void:
	Engine.set_meta("archivo_partida_prueba", "user://fotos_mapamundi3d.save")
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta("mm3d_sin_encuentros", true)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta(D.LLEGADA, "oakhaven")
	await _cargar(MM)
	await _foto("01_llegada_oakhaven")
	# la región desde arriba (ortográfica) y en diorama
	var ui_capa = v.capa_ui
	ui_capa.visible = false
	var cam: Camera3D = v.cam
	v.set_process(false)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 108.0
	cam.global_position = Vector3(0, 140, 0)
	cam.look_at(Vector3(0, 0, -0.01), Vector3(0, 0, -1))
	cam.far = 400.0
	await _foto("00_region_desde_arriba")
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40.0
	cam.global_position = Vector3(18, 62, 82)
	cam.look_at(Vector3(-2, 0, 2), Vector3.UP)
	await _foto("00b_region_diorama")
	v.set_process(true)
	ui_capa.visible = true
	await _poner(D.BIFURCACION + Vector2(0.6, 0.4), Vector2(-1, 0.2))
	await _foto("02_bifurcacion")
	for id in ["campamento", "cueva", "secreto"]:
		D.descubrir(id)
	v._actualizar_rotulos()
	await _poner(D.SITIOS["campamento"]["llegada"], Vector2(-1, 0.6))
	await _foto("03_campamento")
	await _poner(D.SITIOS["pastos"]["llegada"] + Vector2(-1.5, 0.5), Vector2(1, -1))
	await _foto("04_pastos_verdes")
	await _poner(D.SITIOS["portal"]["llegada"] + Vector2(0, 1.0), Vector2(0, -1))
	await _foto("05_portal")
	await _poner(D.SITIOS["cueva"]["llegada"], Vector2(-1, -0.6))
	await _foto("06_cueva_entrada")
	await _poner(D.SITIOS["secreto"]["centro"] + Vector2(1.2, -1.0), Vector2(-1, 1))
	await _foto("07_secreto")
	await _poner(Vector2(36.0, 31.0), Vector2(1, 1))
	await _foto("08_camino_gran_bosque")
	await _poner(D.SITIOS["oakhaven"]["llegada"] + Vector2(0, 1.5))
	v.abrir_viaje()
	await _foto("09_viaje_rapido")
	v.menu_abierto.cerrar()
	await _ms(200)
	Engine.set_meta("pos_3d_ok", false)
	await _cargar(CUEVA)
	await _foto("10_cueva_dentro")
	v.kael.global_position = Vector3(3.4, 0, -3.6)
	await _ms(500)
	await _foto("11_cueva_cristales")
	var f := FileAccess.open(salida.path_join("medidas_fotos_%s.txt" % load("res://prototipos/calidad_proto.gd").actual()), FileAccess.WRITE)
	f.store_string("\n".join(lineas) + "\n")
	f.close()
	print("FOTOS: %d en %s" % [lineas.size(), salida])
	quit(0)
