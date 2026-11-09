extends SceneTree
# Medida de la carga del cuerpo de Érebo (erebo_3d.gd) y una captura fija para comparar antes y después (09/11).
# Con ventana (necesita GPU para la memoria de texturas). Argumentos tras «--»:
#   salida=<carpeta>   dónde dejar medida_<etiqueta>.txt y erebo_<etiqueta>_{reposo,alzar}.png
#   etiqueta=<texto>   p. ej. «antes» o «despues»
#   comparar=<a.png>,<b.png>   en vez de medir: diferencia por píxel entre dos capturas (media y máxima, 0-255)
# Mide: milisegundos de la parte síncrona de crear a Érebo (su _ready carga el modelo y las animaciones de los FBX),
# la memoria de texturas de vídeo y la estática antes, justo después y 20 fotogramas después.

var args := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var p := a.split("=", true, 1)
		args[p[0]] = p[1] if p.size() > 1 else ""
	if args.has("comparar"):
		_comparar(args["comparar"].split(","))
		return
	_medir.call_deferred()


func _mem() -> Array:
	return [Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0]


func _medir() -> void:
	var salida: String = args.get("salida", "user://")
	var etiqueta: String = args.get("etiqueta", "medida")
	root.size = Vector2i(960, 720)
	var mundo := Node3D.new()
	root.add_child(mundo)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.8, 1.45)
	mundo.add_child(cam)
	cam.look_at(Vector3(0, 0.62, 0))
	var rec = root.get_node_or_null("Recursos")
	if rec != null and rec.get("lbl_fps") != null:
		rec.lbl_fps.visible = false          # el contador de FPS cambia entre pasadas y ensucia la comparación
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, 30, 0)
	mundo.add_child(luz)
	var amb := WorldEnvironment.new()
	amb.environment = Environment.new()
	amb.environment.background_mode = Environment.BG_COLOR
	amb.environment.background_color = Color(0.16, 0.17, 0.2)
	amb.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	amb.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	mundo.add_child(amb)
	for i in 10:
		await process_frame
	var m0 := _mem()
	var t0 := Time.get_ticks_usec()
	var erebo = load("res://erebo_3d.gd").new()
	mundo.add_child(erebo)                       # su _ready carga el modelo y junta las animaciones de los FBX
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	var m1 := _mem()
	for i in 20:
		await process_frame
	var m2 := _mem()
	await create_timer(0.5).timeout
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(salida.path_join("erebo_%s_reposo.png" % etiqueta))
	if erebo.anim != null and erebo.anim.has_animation("Alzar"):
		erebo.anim.play("Alzar")
		erebo.anim.seek(1.0, true)
		erebo.anim.pause()
		for i in 5:
			await process_frame
		root.get_viewport().get_texture().get_image().save_png(salida.path_join("erebo_%s_alzar.png" % etiqueta))
	var linea := "MEDIDA %s: crear_ms=%.1f · texturas_MB antes=%.1f justo_despues=%.1f a_los_20=%.1f · estatica_MB antes=%.1f justo_despues=%.1f a_los_20=%.1f · animaciones=%s" % [
			etiqueta, ms, m0[0], m1[0], m2[0], m0[1], m1[1], m2[1],
			str(erebo.anim.get_animation_list() if erebo.anim != null else [])]
	print(linea)
	var f := FileAccess.open(salida.path_join("medida_%s.txt" % etiqueta), FileAccess.READ_WRITE if FileAccess.file_exists(salida.path_join("medida_%s.txt" % etiqueta)) else FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(linea)
		f.close()
	quit(0)


func _comparar(rutas: PackedStringArray) -> void:
	var a := Image.load_from_file(rutas[0])
	var b := Image.load_from_file(rutas[1])
	if a == null or b == null or a.get_size() != b.get_size():
		print("COMPARAR: no se pueden comparar (", rutas, ")")
		quit(1)
		return
	a.convert(Image.FORMAT_RGB8)
	b.convert(Image.FORMAT_RGB8)
	var da := a.get_data()
	var db := b.get_data()
	var suma := 0
	var maximo := 0
	var distintos := 0
	for i in da.size():
		var d: int = absi(int(da[i]) - int(db[i]))
		suma += d
		maximo = maxi(maximo, d)
		if d > 8:
			distintos += 1
	print("COMPARAR %s vs %s: media=%.3f máxima=%d · valores con diferencia >8: %d de %d" % [
			rutas[0].get_file(), rutas[1].get_file(), float(suma) / da.size(), maximo, distintos, da.size()])
	quit(0)
