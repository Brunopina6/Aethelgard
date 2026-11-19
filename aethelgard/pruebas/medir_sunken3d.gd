extends SceneTree
# MEDIDA (15/11), no prueba: Sunken City 3D en el PC, con la ventana de verdad. Para cada entrada desde el mapa
# (Recursos.cambiar_escena, como mapa._entrar): tiempo de carga hasta el control, el peor fotograma de los 2 s
# siguientes (tirones de la primera vez) y la memoria (estática, vídeo y texturas). Después, en tres sitios (muelle,
# Quilla y Cubierta Mayor), 4 s quieto: ms por fotograma REALES (mediana, p95, máximo) con el límite del perfil, y los
# ms de CPU y de GPU del dibujo que mide el motor (sin límite), llamadas de dibujo y primitivas.
# Tres entradas por proceso: la 1.ª de un proceso con la carpeta de datos nueva es la PRIMERA VEZ (sombreadores sin
# caché); las demás, POSTERIORES. Lanzando otra vez con la misma carpeta de datos se mide «con caché del disco».
# Resultado de PC: NO certifica Android.
# Uso: godot --path aethelgard --script res://pruebas/medir_sunken3d.gd -- 3d sunken3d sin_prologo perfil=bajo|medio|alto
#      salida=<carpeta> [etiqueta=frio|cache]

const REGION := "res://zonas3d/sunken_3d.tscn"
const T := preload("res://zonas3d/sunken/trazado.gd")
const SITIOS := {"muelle": Vector2(40.0, 57.0), "quilla": Vector2(40.0, 38.0), "cubierta": Vector2(40.0, 26.0)}
var perfil := "medio"
var salida := ""
var etiqueta := "frio"
var lineas: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
		elif a.begins_with("etiqueta="):
			etiqueta = a.trim_prefix("etiqueta=")
	Engine.set_meta("archivo_partida_prueba", "user://medir_sunken3d.save")
	Engine.set_meta("calidad_proto", perfil)
	root.size = Vector2i(1280, 720)
	_medir.call_deferred()


func _nota(t: String) -> void:
	print(t)
	lineas.append(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _mem() -> String:
	return "estática %.1f MB · vídeo %.1f MB · texturas %.1f MB · objetos %d" % [
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_COUNT))]


func _ms_reales(seg: float) -> Array:
	var r: Array = []
	var ult := Time.get_ticks_usec()
	var t0 := ult
	while Time.get_ticks_usec() - t0 < int(seg * 1000000.0):
		await process_frame
		var ahora := Time.get_ticks_usec()
		r.append((ahora - ult) / 1000.0)
		ult = ahora
	return r


func _resumen(ms: Array) -> String:
	var o := ms.duplicate()
	o.sort()
	if o.is_empty():
		return "sin datos"
	return "mediana %.1f · p95 %.1f · máx %.1f ms (%d fotogramas)" % [o[o.size() / 2], o[int(o.size() * 0.95)], o[-1], o.size()]


func _entrar(n: int) -> void:
	var R = root.get_node("Recursos")
	var t0 := Time.get_ticks_usec()
	R.cambiar_escena(REGION)
	while R.cambiando or current_scene == null or current_scene.scene_file_path != REGION:
		await process_frame
		if Time.get_ticks_usec() - t0 > 60000000:   # (19/11, PC-10) antes se seguía en silencio y la vuelta al mapa
			print("FALLO: Sunken City 3D no termina de cargarse en 60 s (entrada %d, R.cambiando=%s, escena %s)" % [
				n, R.cambiando, current_scene.scene_file_path if current_scene != null else "(ninguna)"])
			quit(1)                                  # siguiente se pedía con el cambio aún en curso
			return
	var carga := (Time.get_ticks_usec() - t0) / 1000.0
	var tras: Array = await _ms_reales(2.0)
	_nota("[%s · %s] entrada %d (%s): carga hasta el control %.0f ms · los 2 s siguientes: %s · %s" % [perfil, etiqueta, n,
		"PRIMERA del proceso" if n == 1 else "posterior", carga, _resumen(tras), _mem()])


func _sitios() -> void:
	var v = current_scene
	var vp_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	for s in SITIOS:
		v._colocar_kael(T.en_mundo(SITIOS[s]))
		await _frames(30)
		var ms: Array = await _ms_reales(4.0)
		var cpu := RenderingServer.viewport_get_measured_render_time_cpu(vp_rid)
		var gpu := RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
		var dib := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var prim := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		_nota("[%s · %s] %s: fotograma real (límite del perfil %s FPS) %s · dibujo CPU %.2f ms · GPU %.2f ms · %d llamadas · %d primitivas" % [
			perfil, etiqueta, s, str(Engine.max_fps if Engine.max_fps > 0 else "sin"), _resumen(ms), cpu, gpu, dib, prim])


func _medir() -> void:
	var P = load("res://progreso.gd")
	P.cargar()
	for h in ["pv_02", "pv_03", "pv_05"]:
		P.poner_hito(h)
	Engine.set_meta("partida_lista", true)
	_nota("PC: %s · %s · %s · %d hilos · ventana %s · renderizador %s · perfil %s · %s" % [
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version(), OS.get_processor_name(),
		OS.get_processor_count(), str(root.size), ProjectSettings.get_setting("rendering/renderer/rendering_method"), perfil, etiqueta])
	change_scene_to_file("res://mapa.tscn")
	await _frames(60)
	_nota("[%s · %s] en el mapa: %s" % [perfil, etiqueta, _mem()])
	for n in [1, 2, 3]:
		await _entrar(n)
		if n == 1:
			await _sitios()
		var R = root.get_node("Recursos")
		R.cambiar_escena("res://mapa.tscn")
		var t_mapa := Time.get_ticks_msec()
		while R.cambiando or current_scene == null or current_scene.scene_file_path != "res://mapa.tscn":
			if Time.get_ticks_msec() - t_mapa > 120000:   # (18/11) tope por reloj: nada de esperas sin límite
				print("FALLO: no vuelve al mapa en 120 s tras la entrada %d" % n)
				quit(1)
				return
			await process_frame
		await _frames(30)
		_nota("[%s · %s] de vuelta al mapa tras la entrada %d: %s" % [perfil, etiqueta, n, _mem()])
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		var f := FileAccess.open(salida.path_join("medida_%s_%s.txt" % [perfil, etiqueta]), FileAccess.WRITE)
		f.store_string("\n".join(lineas) + "\n")
		f.close()
	quit(0)
