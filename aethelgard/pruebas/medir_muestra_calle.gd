extends SceneTree
# MEDIDA (15/11), no prueba: la MUESTRA GRÁFICA de una calle de Oakhaven (zonas3d/muestra_calle/) en el PC, con la
# ventana de verdad (la pantalla del Redmi: --resolution 1600x720). Como pruebas/medir_sunken3d.gd:
#   - la entrada con Recursos.cambiar_escena (como desde el banco): tiempo hasta el control y el peor fotograma de los 2 s
#     siguientes (tirones de la primera vez), y la memoria (estática, vídeo y texturas);
#   - en cuatro sitios (el inicio, la puerta, la esquina y el callejón), 4 s quieto con el límite del perfil (30 FPS en bajo
#     y medio): ms por fotograma REALES (mediana, p95, máximo); y otros 4 s SIN límite ni sincronía vertical: ms reales, y los ms de CPU y de GPU
#     del dibujo que mide el motor, llamadas de dibujo y primitivas (del dibujo opaco: lo transparente no lo cuenta el
#     motor en Compatibility, comprobado el 15/11).
# Resultado de PC: NO certifica Android (el Redmi está PENDIENTE).
# Uso: godot --path aethelgard --resolution 1600x720 --script res://pruebas/medir_muestra_calle.gd -- 3d sin_prologo
#      perfil=bajo|medio|alto salida=<carpeta>

const ESCENA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
const SITIOS := {"inicio": Vector3(-9.5, 0, 1.0), "puerta": Vector3(-6.6, 0, -1.2), "esquina": Vector3(7.6, 0, 0.8),
	"callejon": Vector3(0.0, 0.85, -6.2)}
var perfil := "bajo"
var salida := ""
var lineas: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
	Engine.set_meta("archivo_partida_prueba", "user://medir_muestra_calle.save")
	Engine.set_meta("calidad_proto", perfil)
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


func _medir() -> void:
	var P = load("res://progreso.gd")
	P.cargar()
	Engine.set_meta("partida_lista", true)
	_nota("PC: %s · %s · %s · %d hilos · ventana %s · renderizador %s · perfil %s" % [
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version(), OS.get_processor_name(),
		OS.get_processor_count(), str(root.get_window().size), ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		perfil])
	await _frames(30)
	_nota("[%s] antes de entrar: %s" % [perfil, _mem()])
	var R = root.get_node("Recursos")
	var t0 := Time.get_ticks_usec()
	R.cambiar_escena(ESCENA)
	while R.cambiando or current_scene == null or current_scene.scene_file_path != ESCENA:
		await process_frame
		if Time.get_ticks_usec() - t0 > 60000000:
			break
	var carga := (Time.get_ticks_usec() - t0) / 1000.0
	var tras: Array = await _ms_reales(2.0)
	_nota("[%s] entrada (Recursos.cambiar_escena, primera del proceso): carga hasta el control %.0f ms · los 2 s siguientes: %s · %s" % [
		perfil, carga, _resumen(tras), _mem()])
	var v = current_scene
	var vp_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	for s in SITIOS:
		v._colocar_kael(SITIOS[s])
		await _frames(30)
		var ms: Array = await _ms_reales(4.0)
		var fps_perfil: int = v.perfil_fps
		v.perfil_fps = 0                                         # sin límite (vista3d._process lo pone cada fotograma)
		Engine.max_fps = 0
		# (15/11, revisión) y SIN sincronía vertical: con ella, los ms «sin límite» eran el refresco de la pantalla (144 Hz)
		var vsync_antes := DisplayServer.window_get_vsync_mode()
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		await _frames(20)
		var cpu: Array = []
		var gpu: Array = []
		var libre: Array = []
		var ult := Time.get_ticks_usec()
		var t1 := ult
		while Time.get_ticks_usec() - t1 < 4000000:
			await process_frame
			var ahora := Time.get_ticks_usec()
			libre.append((ahora - ult) / 1000.0)
			ult = ahora
			cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu())
			var g := RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
			if g > 0.0:
				gpu.append(g)
		cpu.sort()
		gpu.sort()
		var dib := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var prim := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		_nota("[%s] %s: con el límite (%d FPS) %s · SIN límite %s · dibujo CPU %.2f ms · GPU %.2f ms (medianas) · %d llamadas · %d primitivas" % [
			perfil, s, fps_perfil, _resumen(ms), _resumen(libre), cpu[cpu.size() / 2] if cpu.size() > 0 else -1.0,
			gpu[gpu.size() / 2] if gpu.size() > 0 else -1.0, dib, prim])
		v.perfil_fps = fps_perfil
		DisplayServer.window_set_vsync_mode(vsync_antes)
	_nota("[%s] al final: %s" % [perfil, _mem()])
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		var f := FileAccess.open(salida.path_join("medida_muestra_%s.txt" % perfil), FileAccess.WRITE)
		f.store_string("\n".join(lineas) + "\n")
		f.close()
	quit(0)
