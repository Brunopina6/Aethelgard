extends SceneTree
# MEDIDA (16/11, agente A), no prueba: el BARRIO EXPERIMENTAL de Oakhaven (zonas3d/barrio/, en pruebas; solo desde el
# banco de Auditoría) en el PC, con la ventana de verdad (la pantalla del Redmi: --resolution 1600x720). Como
# pruebas/medir_muestra_calle.gd:
#   - la entrada con Recursos.cambiar_escena (como desde el banco): tiempo hasta el control, el peor fotograma de los 2 s
#     siguientes y la memoria (estática, vídeo y texturas);
#   - en un sitio de cada tramo (los de fotos_barrio.gd), con Kael y el grupo (Lya y Garon), 3 s con el límite del perfil
#     (30 FPS en bajo y medio): ms REALES; y 3 s SIN límite ni sincronía vertical: ms reales, ms de CPU y de GPU del
#     dibujo que mide el motor, llamadas de dibujo, primitivas y qué sectores se dibujan; y lo mismo SOLO con Kael (el
#     grupo oculto: comparable con la muestra de la calle, medida así).
# Resultado de PC: NO certifica Android (el Redmi está PENDIENTE). La partida es la del banco (su archivo, en user://):
# lánzalo con APPDATA y LOCALAPPDATA en una carpeta aislada, nunca la real.
# Uso: godot --path aethelgard --resolution 1600x720 --script res://pruebas/medir_barrio.gd -- 3d sin_prologo
#      perfil=bajo|medio|alto salida=<carpeta>

const ESCENA := "res://zonas3d/barrio/barrio.tscn"
const SITIOS := [
	["caravanas", Vector2(-42.0, 0.5)],
	["comercial", Vector2(-21.0, 1.8)],
	["plaza", Vector2(0.0, 1.0)],
	["talleres", Vector2(0.0, -17.0)],
	["residencial", Vector2(-24.0, -28.0)],
	["atajo", Vector2(-42.0, -15.5)],
]
var perfil := "bajo"
var salida := ""
var lineas: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
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


# 3 s sin límite ni sincronía vertical: [ms reales, CPU, GPU, llamadas, primitivas].
func _sin_limite(v, vp_rid: RID) -> Array:
	var fps_perfil: int = v.perfil_fps
	v.perfil_fps = 0
	Engine.max_fps = 0
	var vsync_antes := DisplayServer.window_get_vsync_mode()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _frames(20)
	var cpu: Array = []
	var gpu: Array = []
	var libre: Array = []
	var ult := Time.get_ticks_usec()
	var t1 := ult
	while Time.get_ticks_usec() - t1 < 3000000:
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
	v.perfil_fps = fps_perfil
	DisplayServer.window_set_vsync_mode(vsync_antes)
	return [libre, cpu[cpu.size() / 2] if cpu.size() > 0 else -1.0, gpu[gpu.size() / 2] if gpu.size() > 0 else -1.0, dib, prim]


func _medir() -> void:
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()                                  # la partida del banco (archivo propio en user://)
	BP.poner_grupo(BP.EXPLORAR["barrio"]["activos"])
	_nota("PC: %s · %s · %s · %d hilos · ventana %s · renderizador %s · perfil %s" % [
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version(), OS.get_processor_name(),
		OS.get_processor_count(), str(root.get_window().size), ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		perfil])
	await _frames(30)
	_nota("[%s] antes de entrar: %s" % [perfil, _mem()])
	var R = root.get_node("Recursos")
	var t0 := Time.get_ticks_usec()
	R.cambiar_escena(ESCENA)
	while R.cambiando or current_scene == null or current_scene.scene_file_path != ESCENA or current_scene.get("kael") == null:
		await process_frame
		if Time.get_ticks_usec() - t0 > 60000000:
			break
	if R.cambiando or current_scene == null or current_scene.scene_file_path != ESCENA or current_scene.get("kael") == null:
		# (19/11, PC-10) antes, al agotarse los 60 s se seguía midiendo en silencio con la escena a medias
		print("FALLO: %s no termina de cargarse en 60 s (R.cambiando=%s, escena %s)" % [ESCENA, R.cambiando,
			current_scene.scene_file_path if current_scene != null else "(ninguna)"])
		print("FALLOS: 1")
		quit(1)
		return
	var carga := (Time.get_ticks_usec() - t0) / 1000.0
	var tras: Array = await _ms_reales(2.0)
	var v = current_scene
	_nota("[%s] entrada (Recursos.cambiar_escena, primera del proceso): carga hasta el control %.0f ms · los 2 s siguientes: %s · %s" % [
		perfil, carga, _resumen(tras), _mem()])
	_nota("[%s] tramos horneados: %s · choques %d (+%d de piezas) · materiales %d" % [perfil, str(v.acabados), v.choques,
		v.choques_piezas, v.materiales_usados.size()])
	v.boton_recargar.visible = false
	for q in v.acabados:                                   # superficies (= llamadas, si se ve entero) de cada sector
		var sup := {}
		var tri := 0
		for mi in (v.sectores[q] as Node3D).find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).mesh
			sup[String(mi.name).get_slice("_", 0)] = sup.get(String(mi.name).get_slice("_", 0), 0) + m.get_surface_count()
			for i in m.get_surface_count():
				tri += (m.surface_get_array_index_len(i) if m.surface_get_array_index_len(i) > 0 else m.surface_get_array_len(i)) / 3
		_nota("[%s] sector %s: superficies %s (total %d) · %d triángulos" % [perfil, q, str(sup), sup.values().reduce(func(a, b): return a + b, 0), tri])
	var vp_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	for s in SITIOS:
		var p: Vector2 = s[1]
		v._colocar_kael(Vector3(p.x, 0.0, p.y))
		if v.grupo != null:
			v.grupo.visible = true
			v.grupo.colocar(Vector3.BACK)
		await _frames(30)
		var dib_sec: Array = v.sectores.keys().filter(func(q): return v.visibles.get(q, true)).map(
			func(q): return q + ("" if v.detalle_visible.get(q, true) else " (solo lo fijo)"))
		var ms: Array = await _ms_reales(3.0)
		var r: Array = await _sin_limite(v, vp_rid)
		_nota("[%s] %s (con el grupo): con el límite (%d FPS) %s · SIN límite %s · dibujo CPU %.2f ms · GPU %.2f ms · %d llamadas · %d primitivas · sectores %s" % [
			perfil, s[0], v.perfil_fps, _resumen(ms), _resumen(r[0]), r[1], r[2], r[3], r[4], str(dib_sec)])
		if v.grupo != null:
			v.grupo.visible = false
			await _frames(10)
			var r2: Array = await _sin_limite(v, vp_rid)
			_nota("[%s] %s (solo Kael): SIN límite %s · dibujo CPU %.2f ms · GPU %.2f ms · %d llamadas · %d primitivas" % [
				perfil, s[0], _resumen(r2[0]), r2[1], r2[2], r2[3], r2[4]])
			v.grupo.visible = true
	_nota("[%s] al final: %s" % [perfil, _mem()])
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		var f := FileAccess.open(salida.path_join("medida_barrio_%s.txt" % perfil), FileAccess.WRITE)
		f.store_string("\n".join(lineas) + "\n")
		f.close()
	quit(0)
