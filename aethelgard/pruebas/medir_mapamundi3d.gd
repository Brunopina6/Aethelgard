extends SceneTree
# V12, mapamundi 3D (15/11/2026): MEDIDA en el PC (con ventana) del mapamundi 3D en pruebas, por perfil (bajo, medio y
# alto): carga con Recursos.cambiar_escena (primera del proceso y repetida), tiempo de _ready y del relieve (primera vez
# y desde la caché de la sesión), memoria estática y de vídeo, y en tres sitios (llegada de Oakhaven, campamento y el
# camino del Gran Bosque) la mediana de los ms de CPU y GPU del dibujo, llamadas de dibujo y primitivas durante 3 s.
# No certifica Android: en el Redmi, el panel RND de la escena. Uso:
#   godot --path aethelgard --resolution 1600x720 --script res://pruebas/medir_mapamundi3d.gd -- 3d mapamundi3d
#   sin_prologo salida=<carpeta>

const MM := "res://zonas3d/mapamundi_3d.tscn"
const MAPA := "res://mapa.tscn"
var D = load("res://zonas3d/mapamundi/datos.gd")
var R
var v
var salida := "D:/REBELUM_diagnostico/mapamundi_15_11"
var lineas: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	DisplayServer.window_set_size(Vector2i(1600, 720))
	root.size = Vector2i(1600, 720)
	_correr()


func _ms(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame


func _esc() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _anotar(t: String) -> void:
	print(t)
	lineas.append(t)


# Carga con Recursos (como en el juego) desde el mapa 2D y devuelve los ms hasta que la escena está montada y sin negro.
func _cargar() -> int:
	if _esc() != MAPA:
		change_scene_to_file(MAPA)
		while _esc() != MAPA:
			await process_frame
		await _ms(800)
	Engine.set_meta(D.LLEGADA, "oakhaven")
	var t0 := Time.get_ticks_msec()
	R.cambiar_escena(MM)
	while _esc() != MM or R.cambiando:
		await process_frame
	var t := Time.get_ticks_msec() - t0
	v = current_scene
	return t


func _mediana(a: Array) -> float:
	a.sort()
	return a[a.size() / 2] if a.size() > 0 else 0.0


func _medir_sitio(nombre: String, p: Vector2) -> void:
	v._colocar_kael(Vector3(p.x, v.T.altura(p.x, p.y), p.y))
	await _ms(800)
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var cpu: Array = []
	var gpu: Array = []
	var dib: Array = []
	var pri: Array = []
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 3000:
		await RenderingServer.frame_post_draw
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid) + RenderingServer.get_frame_setup_time_cpu())
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
		dib.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		pri.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_anotar("   %-22s CPU dibujo %.2f ms · GPU %.2f ms · %d dibujos · %d primitivas · %d FPS (tope del perfil %d)" % [nombre,
		_mediana(cpu), _mediana(gpu), int(_mediana(dib)), int(_mediana(pri)), Engine.get_frames_per_second(), v.perfil_fps])


func _correr() -> void:
	R = root.get_node("Recursos")
	Engine.set_meta("archivo_partida_prueba", "user://medir_mapamundi3d.save")
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta("mm3d_sin_encuentros", true)
	_anotar("MEDIDAS del mapamundi 3D (PC, ventana 1600×720, %s) · %s" % [RenderingServer.get_video_adapter_name(), Time.get_datetime_string_from_system()])
	var primera := true
	for pf in ["bajo", "medio", "alto"]:
		Engine.set_meta("calidad_proto", pf)
		var t1 := await _cargar()
		var relieve: int = v.T.datos()["ms"]
		var listo1: int = v.t_preparar_ms
		await _ms(1500)
		var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
		var vid := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
		var t2 := await _cargar()
		_anotar("Perfil %s: carga %d ms%s (repetida %d ms) · _ready %d ms (repetida %d ms) · relieve calculado una vez por sesión en %d ms · memoria estática %.0f MB · vídeo %.0f MB · árboles %d" % [
			pf, t1, " (la primera del proceso)" if primera else "", t2, listo1, v.t_preparar_ms, relieve, mem, vid, v.veg.cuantos])
		primera = false
		_anotar("   partes de la última _ready (ms): %s" % [v.tiempos])
		await _medir_sitio("llegada de Oakhaven", D.SITIOS["oakhaven"]["llegada"])
		await _medir_sitio("campamento", D.SITIOS["campamento"]["llegada"])
		await _medir_sitio("camino del Gran Bosque", Vector2(36.0, 31.0))
	DirAccess.make_dir_recursive_absolute(salida)
	var f := FileAccess.open(salida.path_join("medidas_mapamundi3d_pc.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lineas) + "\n")
	f.close()
	quit(0)
