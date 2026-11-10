extends SceneTree
# Capturas del distrito de los oficios de Oakhaven 3D (V10, hitos 2 y 10: zonas3d/oakhaven/distrito.gd), siempre desde
# los mismos puntos: la entrada desde la Calle Mayor, la herrería, el taller de armaduras, los puestos y las casas, la
# botica, el rincón del pozo y dos vistas fijas (el barrio desde el sur y desde lo alto). Con «sin_distrito», la ciudad
# de antes (el mismo encuadre, sin el distrito): sirven de antes y después. Anota llamadas de dibujo, primitivas y GPU.
# No es una prueba (no está en lista_pruebas.txt): las capturas las revisa una persona.
# Uso: --path aethelgard --script res://pruebas/fotos_distrito_oakhaven.gd -- 3d oakhaven3d sin_prologo salida=<carpeta>
#      [perfiles=alto,bajo] [res=1600x720] [sin_distrito] [boton]
# No toca ninguna partida: progreso.gd no guarda durante las pruebas.

const REGION := "res://zonas3d/oakhaven_3d.tscn"
# [nombre, posición de Kael (la y se busca en el suelo)]
const SITIOS := [
	["d01_desde_la_calle_mayor", Vector3(40.0, 0, 37.6)],
	["d02_herreria", Vector3(46.4, 0, 35.3)],
	["d03_armeria", Vector3(50.55, 0, 35.35)],
	["d04_puestos", Vector3(57.3, 0, 35.6)],
	["d05_casas", Vector3(63.5, 0, 36.0)],
	["d06_botica", Vector3(34.75, 0, 42.25)],
	["d07_rincon_del_pozo", Vector3(47.95, 0, 40.6)],
	["d08_plaza", Vector3(42.0, 0, 30.0)],
]
# Vistas fijas: [nombre, posición de la cámara, punto al que mira, campo de visión]
const VISTAS := [
	["d09_barrio_desde_el_sur", Vector3(50.0, 22.0, 60.0), Vector3(50.0, 0.0, 36.0), 50.0],
	["d10_barrio_desde_lo_alto", Vector3(50.0, 34.0, 50.0), Vector3(50.0, 0.0, 38.0), 50.0],
]

var salida := "D:/REBELUM_diagnostico/v10/distrito"
var perfiles: Array = ["alto", "bajo"]
var tam := Vector2i(1280, 720)
var sin_distrito := false
var con_boton := false
var ip := 0
var v
var frames := 0
var fase := 0
var f_fase := 0
var i_sitio := 0
var i_vista := 0
var _gpu: Array = []
var _cpu: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("perfiles="):
			perfiles = Array(a.substr(9).split(","))
		elif a.begins_with("res="):
			var p: PackedStringArray = a.substr(4).split("x")
			tam = Vector2i(int(p[0]), int(p[1]))
		elif a == "sin_distrito":
			sin_distrito = true
		elif a == "boton":
			con_boton = true
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(tam)
	root.size = tam
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	if sin_distrito:
		Engine.set_meta("oakhaven_sin_distrito", true)
	Engine.set_meta("oakhaven_sin_cache", true)        # que la ciudad se junte siempre igual (sin caché de otra pasada)
	_cargar()


func _cargar() -> void:
	Engine.set_meta("calidad_proto", perfiles[ip])
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos", "lore_visto"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	v = null
	i_sitio = 0
	i_vista = 0
	_fase(1)


func _fase(n: int) -> void:
	fase = n
	f_fase = frames
	_gpu.clear()
	_cpu.clear()


func _muestra() -> void:
	var rid := root.get_viewport_rid()
	var g := RenderingServer.viewport_get_measured_render_time_gpu(rid)
	if g > 0.0 and g < 1000.0:
		_gpu.append(g)
	_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid) + RenderingServer.get_frame_setup_time_cpu())


func _mediana(a: Array) -> float:
	if a.is_empty():
		return -1.0
	var o := a.duplicate()
	o.sort()
	return o[o.size() / 2]


func _foto(nombre: String) -> void:
	var sufijo := "antes" if sin_distrito else "despues"
	var ruta := "%s/%s_%s_%dx%d_%s.png" % [salida, nombre, sufijo, tam.x, tam.y, perfiles[ip]]
	var img: Image = root.get_viewport().get_texture().get_image()
	if img.get_size() != tam:
		img.convert(Image.FORMAT_RGBA8)
		var movil := Image.create(tam.x, tam.y, false, Image.FORMAT_RGBA8)
		movil.fill(Color(0, 0, 0, 1))
		movil.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), (tam - img.get_size()) / 2)
		img = movil
	img.save_png(ruta)
	var dib := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prim := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var obj := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	print("DIBUJO %s %s %s %dx%d: llamadas %d · primitivas %d · objetos %d · GPU %.2f ms · CPU render %.2f ms (medianas) · %d FPS" % [
		sufijo, perfiles[ip], nombre, tam.x, tam.y, dib, prim, obj, _mediana(_gpu), _mediana(_cpu), Engine.get_frames_per_second()])
	if v != null and v.get("boton_accion") != null and v.boton_accion.visible:
		print("  botón: «%s»" % v.boton_accion.text)


func _poner(p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 3.0, 0), p - Vector3(0, 6.0, 0))
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	if not r.is_empty():
		p.y = r["position"].y
	v.en_posada = false
	v._colocar_kael(p)
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)


func _process(_d: float) -> bool:
	frames += 1
	if v != null and "pasos" in v:
		v.pasos = 0
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 20:
				v = current_scene
				var d = v.get("distrito")
				if d != null:
					print("DISTRITO %s: %s" % [perfiles[ip], str(d.resumen())])
				_poner(SITIOS[0][1])
				_fase(2)
		2:
			if frames - f_fase >= 40:
				_muestra()
			if frames - f_fase == 70:
				_foto(SITIOS[i_sitio][0])
				i_sitio += 1
				if i_sitio < SITIOS.size():
					_poner(SITIOS[i_sitio][1])
					_fase(2)
				else:
					_poner(SITIOS[0][1])
					v.set_process(false)
					v.boton_accion.visible = false
					_fase(3)
		3:
			if frames - f_fase == 1:
				var vi: Array = VISTAS[i_vista]
				v.cam.global_position = vi[1]
				v.cam.look_at(vi[2], Vector3.UP)
				v.cam.fov = vi[3]
			elif frames - f_fase >= 10 and frames - f_fase < 30:
				_muestra()
			elif frames - f_fase == 30:
				_foto(VISTAS[i_vista][0])
				i_vista += 1
				if i_vista < VISTAS.size():
					_fase(3)
				else:
					ip += 1
					if ip >= perfiles.size():
						Engine.remove_meta("calidad_proto")
						print("FOTOS HECHAS")
						quit(0)
						return true
					_cargar()
	if frames > 8000:
		print("FALLO: las fotos no terminaron (fase %d)" % fase)
		quit(1)
		return true
	return false
