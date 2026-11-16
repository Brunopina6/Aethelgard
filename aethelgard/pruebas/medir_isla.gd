extends SceneTree
# MEDIDA (16/11), no prueba: la Arboleda Mítica 2D (isla.tscn) y, con «escena=tramo», el tramo experimental de la
# escalera de la Hospedería (zonas3d/arboleda_tramo/), en el PC con la ventana de verdad (--resolution 1600x720, la
# pantalla del Redmi). Como pruebas/medir_muestra_calle.gd:
#   - la entrada con Recursos.cambiar_escena: tiempo hasta el control, el peor fotograma de los 2 s siguientes y la
#     memoria (estática, vídeo y texturas);
#   - en cada sitio (portal, plaza, escalera, terraza y, en el tramo, el interior), Kael quieto 4 s con el límite normal
#     (30 FPS): ms REALES (mediana, p95, máximo); y otros 4 s SIN límite ni sincronía vertical: ms reales y los ms de CPU
#     y de GPU del dibujo que mide el motor, llamadas de dibujo y primitivas; más una captura del sitio.
#   La escena 2D no depende del perfil gráfico (calidad_proto solo escala el 3D): se anota igualmente.
# Resultado de PC: NO certifica Android (el Redmi está PENDIENTE: guion en docs/v12/ARBOLEDA_HOSPEDERIA.md).
# Uso: godot --path aethelgard --resolution 1600x720 --script res://pruebas/medir_isla.gd -- sin_prologo
#      escena=isla|tramo salida=<carpeta> [etiqueta=antes|despues] [perfil=bajo|medio|alto] [solo_fotos]

const ESCENAS := {"isla": "res://isla.tscn", "tramo": "res://zonas3d/arboleda_tramo/arboleda_tramo.tscn"}
# Sitios en píxeles de la isla (los pies de Kael). La terraza no se alcanza en isla.tscn: se pone a Kael ahí para
# medir el MISMO encuadre antes y después.
const SITIOS := {"portal": Vector2(1444, 2624), "plaza": Vector2(1640, 2040), "escalera": Vector2(2150, 2120),
	"terraza": Vector2(2392, 2100)}
var escena := "isla"
var salida := ""
var etiqueta := "antes"
var perfil := "bajo"
var solo_fotos := false
var lineas: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("escena="):
			escena = a.trim_prefix("escena=")
		elif a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
		elif a.begins_with("etiqueta="):
			etiqueta = a.trim_prefix("etiqueta=")
		elif a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a == "solo_fotos":
			solo_fotos = true
	Engine.set_meta("archivo_partida_prueba", "user://medir_isla.save")
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


func _foto(nombre: String) -> void:
	if salida == "":
		return
	DirAccess.make_dir_recursive_absolute(salida)
	root.get_viewport().get_texture().get_image().save_png(salida.path_join("%s_%s_%s.png" % [escena, etiqueta, nombre]))


func _colocar(v, s: String) -> void:
	if s == "interior":
		v.entrar_hospederia(true)                 # (solo el tramo) sin fundido
		await _frames(4)
		return
	if v.has_method("salir_hospederia") and v.dentro:
		v.salir_hospederia(true)
		await _frames(4)
	v.jugador.position = SITIOS[s]
	v.tiene_destino = false
	v.camara.reset_smoothing()
	v._poner_z()


func _medir() -> void:
	var P = load("res://progreso.gd")
	P.cargar()
	Engine.set_meta("partida_lista", true)
	var ruta: String = ESCENAS[escena]
	_nota("PC: %s · %s · %s · %d hilos · ventana %s · renderizador %s · perfil %s (no afecta a la 2D) · escena %s · %s" % [
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version(), OS.get_processor_name(),
		OS.get_processor_count(), str(root.get_window().size), ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		perfil, ruta, etiqueta])
	await _frames(30)
	_nota("[%s] antes de entrar: %s" % [escena, _mem()])
	var R = root.get_node("Recursos")
	var t0 := Time.get_ticks_usec()
	R.cambiar_escena(ruta)
	while R.cambiando or current_scene == null or current_scene.scene_file_path != ruta:
		await process_frame
		if Time.get_ticks_usec() - t0 > 60000000:
			break
	var carga := (Time.get_ticks_usec() - t0) / 1000.0
	var tras: Array = await _ms_reales(2.0)
	_nota("[%s] entrada (Recursos.cambiar_escena, primera del proceso): carga hasta el control %.0f ms · los 2 s siguientes: %s · %s" % [
		escena, carga, _resumen(tras), _mem()])
	var v = current_scene
	var vp_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var sitios: Array = SITIOS.keys()
	if escena == "tramo":
		sitios.append("interior")
	for s in sitios:
		await _colocar(v, s)
		await _frames(40)
		_foto(s)
		if solo_fotos:
			continue
		var ms: Array = await _ms_reales(4.0)
		var max_antes := Engine.max_fps
		Engine.max_fps = 0
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
		var obj := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		_nota("[%s] %s: con el límite (%d FPS) %s · SIN límite %s · dibujo CPU %.2f ms · GPU %.2f ms (medianas) · %d llamadas · %d objetos" % [
			escena, s, max_antes, _resumen(ms), _resumen(libre), cpu[cpu.size() / 2] if cpu.size() > 0 else -1.0,
			gpu[gpu.size() / 2] if gpu.size() > 0 else -1.0, dib, obj])
		Engine.max_fps = max_antes
		DisplayServer.window_set_vsync_mode(vsync_antes)
	_nota("[%s] al final: %s" % [escena, _mem()])
	if salida != "" and not solo_fotos:
		DirAccess.make_dir_recursive_absolute(salida)
		var f := FileAccess.open(salida.path_join("medida_%s_%s.txt" % [escena, etiqueta]), FileAccess.WRITE)
		f.store_string("\n".join(lineas) + "\n")
		f.close()
	quit(0)
