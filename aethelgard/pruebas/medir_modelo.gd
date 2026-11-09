extends SceneTree
# Medida y capturas de un modelo 3D suelto, para comparar su importación antes y después (09/11).
# Con ventana. Argumentos tras «--»:
#   modelo=res://garon.fbx   el modelo (FBX, GLB o escena)
#   salida=<carpeta>         dónde dejar medida_<etiqueta>.txt y <nombre>_<etiqueta>_{frente,tres_cuartos,detalle}.png
#   etiqueta=<texto>         p. ej. «antes» o «despues»
#   alto=<m>                 altura aproximada del modelo para encuadrarlo (por defecto 1,8)
# Mide los milisegundos de cargar la escena e instanciarla (en frío: un proceso por medida) y la memoria de texturas
# de vídeo antes y después. Las capturas usan la misma luz y la misma cámara en las dos pasadas.

var args := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var p := a.split("=", true, 1)
		args[p[0]] = p[1] if p.size() > 1 else ""
	_medir.call_deferred()


func _tex() -> float:
	return Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0


func _foto(cam: Camera3D, pos: Vector3, mira: Vector3, ruta: String) -> void:
	cam.position = pos
	cam.look_at(mira)
	for i in 4:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(ruta)


func _medir() -> void:
	var ruta_modelo: String = args.get("modelo", "res://garon.fbx")
	var salida: String = args.get("salida", "user://")
	var etiqueta: String = args.get("etiqueta", "medida")
	var alto := float(args.get("alto", "1.8"))
	var nombre := ruta_modelo.get_file().get_basename()
	root.size = Vector2i(960, 720)
	var rec = root.get_node_or_null("Recursos")
	if rec != null and rec.get("lbl_fps") != null:
		rec.lbl_fps.visible = false
	var mundo := Node3D.new()
	root.add_child(mundo)
	var cam := Camera3D.new()
	mundo.add_child(cam)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, 25, 0)
	mundo.add_child(luz)
	var amb := WorldEnvironment.new()
	amb.environment = Environment.new()
	amb.environment.background_mode = Environment.BG_COLOR
	amb.environment.background_color = Color(0.16, 0.17, 0.2)
	amb.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	amb.environment.ambient_light_color = Color(0.55, 0.55, 0.6)
	mundo.add_child(amb)
	for i in 10:
		await process_frame
	var t0 := _tex()
	var c0 := Time.get_ticks_usec()
	var escena = load(ruta_modelo)
	var cargar_ms := (Time.get_ticks_usec() - c0) / 1000.0
	var modelo: Node3D = escena.instantiate()
	mundo.add_child(modelo)
	var total_ms := (Time.get_ticks_usec() - c0) / 1000.0
	# encuadre: el modelo de pie, centrado; se escala para que mida «alto» si viene en otra unidad
	var caja := AABB()
	var primera := true
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.global_transform * mi.get_aabb()
		caja = b if primera else caja.merge(b)
		primera = false
	if caja.size.y > 0.001:
		var k := alto / caja.size.y
		modelo.scale *= k
		caja = AABB(caja.position * k, caja.size * k)
	var ap: AnimationPlayer = modelo.find_child("AnimationPlayer", true, false)
	if ap != null and ap.get_animation_list().size() > 0:
		ap.play(ap.get_animation_list()[0])
		ap.seek(0.0, true)
		ap.pause()
	for i in 10:
		await process_frame
	var t1 := _tex()
	var centro := caja.get_center()
	var h := maxf(caja.size.y, 0.5)
	await _foto(cam, centro + Vector3(0, 0.05 * h, 1.35 * h), centro, salida.path_join("%s_%s_frente.png" % [nombre, etiqueta]))
	await _foto(cam, centro + Vector3(0.95 * h, 0.15 * h, 0.95 * h), centro, salida.path_join("%s_%s_tres_cuartos.png" % [nombre, etiqueta]))
	var pecho := centro + Vector3(0, 0.22 * h, 0)
	await _foto(cam, pecho + Vector3(0.08 * h, 0.02 * h, 0.42 * h), pecho, salida.path_join("%s_%s_detalle.png" % [nombre, etiqueta]))
	var linea := "MEDIDA %s %s: cargar_ms=%.1f cargar_e_instanciar_ms=%.1f · texturas_MB antes=%.1f despues=%.1f (+%.1f)" % [
			nombre, etiqueta, cargar_ms, total_ms, t0, t1, t1 - t0]
	print(linea)
	var archivo := salida.path_join("medida_%s.txt" % etiqueta)
	var f := FileAccess.open(archivo, FileAccess.READ_WRITE if FileAccess.file_exists(archivo) else FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(linea)
		f.close()
	quit(0)
