extends SceneTree
# Capturas y medidas de las dos pantallas de inicio (11/11), para compararlas a ojo. Con ventana y datos aislados:
#   Godot --path aethelgard --script res://pruebas/fotos_portada.gd -- <carpeta> <original|alternativa> <ancho>x<alto> 3d
#   (para la alternativa, además «portada_alternativa»; con «con_partida», el menú enseña Continuar)
# Escribe en <carpeta>: <pantalla>_<ancho>x<alto>_{1_cargando,2_lista,3_menu,4_creditos,5_opciones}.png (las tres
# últimas, solo la alternativa) y medidas_<pantalla>_<ancho>x<alto>.txt: segundos hasta acabar la carga, memoria
# estática, memoria de vídeo y de texturas, nodos y llamadas de dibujo, y FPS sin límite ni vsync durante 6 s (tiempo
# medio por fotograma, y el de la GPU si el renderizador lo da).

const CARGA := "res://carga.tscn"

var salida := ""
var pantalla := ""
var tam := Vector2i(1280, 720)
var lineas: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0]
	pantalla = args[1]
	var t: PackedStringArray = args[2].split("x")
	tam = Vector2i(int(t[0]), int(t[1]))
	DisplayServer.window_set_size(tam)
	_capturar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _tecla(codigo: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = true
	Input.parse_input_event(e)
	await _esperar(2)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await _esperar(6)


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := "%s/%s_%dx%d_%s.png" % [salida, pantalla, tam.x, tam.y, nombre]
	var img := root.get_texture().get_image()
	# La textura de la ventana es el lienzo del juego (1280×720). En una pantalla más ancha (el Redmi, 1600×720) el
	# juego lo enseña centrado con bandas negras a los lados (estiramiento «canvas_items», aspecto «keep»): se compone
	# así para que la captura sea lo que se ve.
	if img.get_size() != tam:
		var escala := minf(float(tam.x) / img.get_width(), float(tam.y) / img.get_height())
		img.resize(int(img.get_width() * escala), int(img.get_height() * escala), Image.INTERPOLATE_LANCZOS)
		var lienzo := Image.create(tam.x, tam.y, false, img.get_format())
		lienzo.fill(Color.BLACK)
		lienzo.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), (tam - img.get_size()) / 2)
		img = lienzo
	img.save_png(ruta)
	print("CAPTURA ", ruta)


func _apuntar(t: String) -> void:
	lineas.append(t)
	print(t)


func _memoria(cuando: String) -> void:
	_apuntar("%s: memoria estática %.1f MB · vídeo %.1f MB · texturas %.1f MB · nodos %d · dibujos %d" % [cuando,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])


func _capturar() -> void:
	# «con_partida»: una partida mínima en la carpeta aislada, para que el menú enseñe Continuar
	if "con_partida" in OS.get_cmdline_user_args():
		var P = load("res://progreso.gd")
		P.escribir({"escena_guardada": "res://mapa.tscn", "prologo_visto": true}, P.archivo())
	await _esperar(3)
	var t0 := Time.get_ticks_msec()
	change_scene_to_file(CARGA)
	await _esperar(40)
	await _foto("1_cargando")
	var esperada := "res://portada/inicio_alternativo.tscn" if pantalla == "alternativa" else CARGA
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == esperada \
			and current_scene.listo, 240.0):
		_apuntar("FALLO: la pantalla %s no termina la carga" % pantalla)
		_fin()
		return
	var c = current_scene
	_apuntar("%s %dx%d: carga terminada a los %.2f s de pantalla (%.2f s de reloj desde el cambio de escena)" % [
		pantalla, tam.x, tam.y, c.tiempo, (Time.get_ticks_msec() - t0) / 1000.0])
	_memoria("al acabar la carga")
	await _esperar(75)
	await _foto("2_lista")
	if pantalla == "alternativa":
		await _tecla(KEY_ENTER)
		await _esperar(30)
		await _foto("3_menu")
		_memoria("con el menú")
		await _tecla(KEY_UP)                       # Créditos (el menú da la vuelta)
		await _tecla(KEY_ENTER)
		await _esperar(12)
		await _foto("4_creditos")
		await _tecla(KEY_ESCAPE)
		await _esperar(12)
		await _tecla(KEY_UP)                       # Opciones
		await _tecla(KEY_ENTER)
		await _esperar(12)
		await _foto("5_opciones")
		await _tecla(KEY_ESCAPE)
		await _esperar(12)
	# FPS sin límite ni vsync, con la pantalla quieta (la alternativa, con su menú abierto)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	await _esperar(60)
	var n := 0
	var gpu := 0.0
	var cpu := 0.0
	var inicio := Time.get_ticks_usec()
	while Time.get_ticks_usec() - inicio < 6000000:
		await process_frame
		n += 1
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
	var ms := (Time.get_ticks_usec() - inicio) / 1000.0 / n
	_apuntar("%s %dx%d: sin límite, %.0f FPS (%.2f ms por fotograma; dibujo en CPU %.2f ms, en GPU %.2f ms)" % [
		pantalla, tam.x, tam.y, 1000.0 / ms, ms, cpu / n, gpu / n])
	_memoria("al medir")
	_fin()


func _fin() -> void:
	var f := FileAccess.open("%s/medidas_%s_%dx%d.txt" % [salida, pantalla, tam.x, tam.y], FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lineas) + "\n")
		f.close()
	quit()
