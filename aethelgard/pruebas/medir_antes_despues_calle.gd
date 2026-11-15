extends SceneTree
# MEDIDA (15/11, tras la revisión), no prueba: el ANTES (la Calle del Cuervo de Oakhaven 3D) y el DESPUÉS (la muestra
# gráfica, zonas3d/muestra_calle/) medidos IGUAL, para que la comparación sea justa:
#   - la misma herramienta, el mismo perfil, la misma ventana y la misma cámara respecto a Kael (la de la muestra y la de
#     juego de Oakhaven, como fotos_muestra_calle.gd);
#   - SOLO Kael en los dos (en Oakhaven se esconden Lya y Garon; la muestra no los tiene);
#   - la escena quieta (su _process parado, como en las capturas) para que la cámara no se mueva;
#   - 90 fotogramas por cámara con la sincronía vertical QUITADA y sin límite de FPS: medianas de llamadas de dibujo,
#     primitivas y objetos (por fotograma), ms de CPU y de GPU del dibujo (los que mide el motor) y ms reales.
# Escribe medida_antes_despues_<perfil>.txt en «salida». Resultado de PC: NO certifica Android.
# Uso: godot --path aethelgard --resolution 1600x720 --script res://pruebas/medir_antes_despues_calle.gd -- 3d sin_prologo
#      perfil=bajo|medio|alto salida=<carpeta>

const OAKHAVEN := "res://zonas3d/oakhaven_3d.tscn"
const MUESTRA := "res://zonas3d/muestra_calle/muestra_calle.tscn"
const F := preload("res://pruebas/fotos_muestra_calle.gd")
const FOTOGRAMAS := 90

var perfil := "bajo"
var salida := ""
var lineas: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
	Engine.set_meta("archivo_partida_prueba", "user://medir_antes_despues_calle.save")
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("oakhaven_sin_cache", true)
	Engine.set_meta("muestra_sin_titulo", true)
	_medir.call_deferred()


func _nota(t: String) -> void:
	print(t)
	lineas.append(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _mediana(a: Array) -> float:
	if a.is_empty():
		return -1.0
	var o := a.duplicate()
	o.sort()
	return o[o.size() / 2]


func _abrir(ruta: String):
	change_scene_to_file(ruta)
	var t0 := Time.get_ticks_msec()
	while current_scene == null or current_scene.scene_file_path != ruta:
		await process_frame
		if Time.get_ticks_msec() - t0 > 60000:
			return null
	await _frames(60)
	return current_scene


func _sitio(v, escena: String) -> Vector3:
	if escena == "oakhaven":
		var p: Vector3 = F.OAK_KAEL
		var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 3.0, 0), p - Vector3(0, 6.0, 0))
		var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
		if not r.is_empty():
			p.y = r["position"].y
		return p
	return v.SITIO_FOTO


func _camara(v, cual: String) -> void:
	var k: Vector3 = v.kael.global_position
	if cual == "muestra":
		load("res://zonas3d/muestra_calle/muestra_calle.gd").camara_muestra(v.cam, k)
	else:
		var ojo := k + Vector3(0, 0.9, 0)
		var ang := deg_to_rad(F.JUEGO_INCL)
		v.cam.global_position = ojo + Vector3(0, sin(ang), cos(ang)) * F.JUEGO_DIST
		v.cam.look_at(ojo, Vector3.UP)
		v.cam.fov = 38.0


func _medir_escena(escena: String) -> void:
	var v = await _abrir(OAKHAVEN if escena == "oakhaven" else MUESTRA)
	if v == null:
		_nota("[%s] %s: NO CARGÓ" % [perfil, escena])
		return
	if escena == "oakhaven":
		v.en_posada = false
	v._colocar_kael(_sitio(v, escena))
	var escondidos := 0
	if v.get("grupo") != null and v.grupo != null:          # solo Kael, como en la muestra
		v.grupo.visible = false
		v.grupo.process_mode = Node.PROCESS_MODE_DISABLED
		escondidos = v.grupo.get_child_count()
	if v.get("boton_accion") != null:
		v.boton_accion.visible = false
	await _frames(30)
	var rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for cual in ["muestra", "juego"]:
		v.set_process(false)                                  # la cámara se queda donde se pone
		_camara(v, cual)
		Engine.max_fps = 0                                    # (vista3d._process pone el límite del perfil)
		await _frames(40)
		var dib: Array = []
		var prim: Array = []
		var obj: Array = []
		var cpu: Array = []
		var gpu: Array = []
		var ms: Array = []
		var ult := Time.get_ticks_usec()
		for i in FOTOGRAMAS:
			await process_frame
			var ahora := Time.get_ticks_usec()
			ms.append((ahora - ult) / 1000.0)
			ult = ahora
			dib.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
			prim.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
			obj.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
			cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid) + RenderingServer.get_frame_setup_time_cpu())
			var g := RenderingServer.viewport_get_measured_render_time_gpu(rid)
			if g > 0.0 and g < 1000.0:
				gpu.append(g)
		_nota("[%s] %s · cámara %s · Kael %s (grupo escondido: %d): %d llamadas · %d primitivas · %d objetos · dibujo CPU %.2f ms · GPU %.2f ms · fotograma real %.2f ms (medianas de %d fotogramas, sin vsync ni límite)" % [
			perfil, "ANTES (Calle del Cuervo)" if escena == "oakhaven" else "DESPUÉS (muestra)", cual,
			str(v.kael.global_position), escondidos, int(_mediana(dib)), int(_mediana(prim)), int(_mediana(obj)),
			_mediana(cpu), _mediana(gpu), _mediana(ms), FOTOGRAMAS])
		v.set_process(true)
	_nota("[%s] %s: memoria vídeo %.1f MB · texturas %.1f MB" % [perfil, escena,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])


func _medir() -> void:
	var P = load("res://progreso.gd")
	P.cargar()
	Engine.set_meta("partida_lista", true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_nota("PC: %s · %s · ventana %s · renderizador %s · perfil %s · vsync quitado" % [
		RenderingServer.get_video_adapter_name(), OS.get_processor_name(), str(root.get_window().size),
		ProjectSettings.get_setting("rendering/renderer/rendering_method"), perfil])
	for escena in ["oakhaven", "muestra"]:
		await _medir_escena(escena)
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		var f := FileAccess.open(salida.path_join("medida_antes_despues_%s.txt" % perfil), FileAccess.WRITE)
		f.store_string("\n".join(lineas) + "\n")
		f.close()
	quit(0)
