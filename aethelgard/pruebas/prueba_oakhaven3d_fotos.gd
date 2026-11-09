extends SceneTree
# Capturas de Oakhaven 3D (T-103), primer tramo jugable, siempre desde los mismos puntos: la Puerta del Sur, Aldric, la
# Calle Mayor, la plaza, la Calle del Cuervo, la puerta de la taberna y la posada por dentro (con la posadera y su
# panel), y dos vistas fijas (la ciudad desde el sur y la sala desde arriba). Perfiles bajo y alto; con «res=1600x720»,
# la pantalla del móvil 20:9. Anota llamadas de dibujo, primitivas y GPU de cada vista.
# Uso: --path aethelgard --script res://pruebas/prueba_oakhaven3d_fotos.gd --fixed-fps 30 -- <carpeta> 3d oakhaven3d sin_prologo
# No toca ninguna partida: progreso.gd no guarda durante las pruebas. Los encuentros se quitan solo aquí (v.pasos = 0).

const REGION := "res://zonas3d/oakhaven_3d.tscn"
const PERFILES := ["bajo", "medio", "alto"]
# [nombre, posición de Kael (la y se busca en el suelo)]
const SITIOS := [
	["o01_puerta_sur", Vector3(40.0, 0, 53.0)],
	["o02_aldric", Vector3(39.7, 0, 48.6)],
	["o03_calle_mayor", Vector3(40.0, 0, 38.0)],
	["o04_plaza", Vector3(40.0, 0, 31.0)],
	["o05_calle_del_cuervo", Vector3(25.0, 0, 26.0)],
	["o06_puerta_de_la_taberna", Vector3(16.0, 0, 26.2)],
	["o07_posada_dentro", Vector3(206.0, 0, 207.2)],
	["o08_posadera", Vector3(203.4, 0, 203.05)],
]
# Vistas fijas: [nombre, posición de la cámara, punto al que mira, campo de visión]
const VISTAS := [
	["o09_ciudad_desde_el_sur", Vector3(40.0, 26.0, 78.0), Vector3(36.0, 0.0, 30.0), 50.0],
	["o10_sala_desde_arriba", Vector3(206.0, 9.5, 213.5), Vector3(206.0, 0.0, 203.5), 55.0],
]

var salida := ""
var tam := Vector2i(1280, 720)
var ip := 0
var v
var frames := 0
var fase := 0
var f_fase := 0
var i_sitio := 0
var i_vista := 0
var _gpu: Array = []                    # tiempo de la GPU (ms) de los fotogramas de espera del sitio
var _cpu: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0]
	for a in args:
		if a.begins_with("res="):
			var p: PackedStringArray = a.substr(4).split("x")
			tam = Vector2i(int(p[0]), int(p[1]))
	DisplayServer.window_set_size(tam)
	root.size = tam
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	_cargar()


func _limpiar() -> void:
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos", "lore_visto"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)


func _cargar() -> void:
	Engine.set_meta("calidad_proto", PERFILES[ip])
	_limpiar()
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


# Tiempo de render de este fotograma (la GPU, aunque el juego vaya con tope de FPS).
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
	var ruta := "%s/%s_%dx%d_%s.png" % [salida, PERFILES[ip], tam.x, tam.y, nombre]
	var img: Image = root.get_viewport().get_texture().get_image()
	if img.get_size() != tam:                       # aspecto «keep»: la vista del juego, con las franjas del móvil 20:9
		img.convert(Image.FORMAT_RGBA8)
		var movil := Image.create(tam.x, tam.y, false, Image.FORMAT_RGBA8)
		movil.fill(Color(0, 0, 0, 1))
		movil.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), (tam - img.get_size()) / 2)
		img = movil
	img.save_png(ruta)
	# lo que se dibuja en este fotograma (no depende de la carga del PC: sirve para comparar antes y después)
	var dib := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prim := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var obj := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	print("DIBUJO %s %s %dx%d: llamadas %d · primitivas %d · objetos %d · GPU %.2f ms · CPU render %.2f ms (medianas)" % [PERFILES[ip], nombre, tam.x, tam.y, dib, prim, obj, _mediana(_gpu), _mediana(_cpu)])
	print("%s %s: Kael %s · cámara %s · %d FPS" % [PERFILES[ip], nombre, v.kael.global_position.snapped(Vector3.ONE * 0.1),
		v.cam.global_position.snapped(Vector3.ONE * 0.1), Engine.get_frames_per_second()])


# Kael en «p», con la y del suelo que haya debajo; el grupo, detrás.
func _poner(p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 3.0, 0), p - Vector3(0, 6.0, 0))
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	if not r.is_empty():
		p.y = r["position"].y
	v.en_posada = p.x > 150.0                     # la sala de la posada está lejos de la ciudad (posada3d.gd)
	v._colocar_kael(p)
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)


func _process(_d: float) -> bool:
	frames += 1
	if v != null:
		if "pasos" in v:
			v.pasos = 0
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 20:
				v = current_scene
				_poner(SITIOS[0][1])
				_fase(2)
		2:                                          # cada sitio: colocar, esperar (la cámara se asienta) y foto
			if frames - f_fase >= 30:
				_muestra()
			if frames - f_fase == 50 and SITIOS[i_sitio][0] == "o08_posadera":
				v._abrir_servicios()                   # el panel de la posadera, abierto
			if frames - f_fase == 60:
				_foto(SITIOS[i_sitio][0])
				i_sitio += 1
				if i_sitio < SITIOS.size():
					_poner(SITIOS[i_sitio][1])
					_fase(2)
				else:
					v._cerrar_servicios()
					_poner(SITIOS[3][1])            # Kael en la plaza (se ve en la vista de lejos)
					v.set_process(false)
					_fase(3)
		3:                                          # vistas fijas
			if frames - f_fase == 1:
				var vi: Array = VISTAS[i_vista]
				v.cam.global_position = vi[1]
				v.cam.look_at(vi[2], Vector3.UP)
				v.cam.fov = vi[3]
			elif frames - f_fase >= 10 and frames - f_fase < 25:
				_muestra()
			elif frames - f_fase == 25:
				_foto(VISTAS[i_vista][0])
				i_vista += 1
				if i_vista < VISTAS.size():
					_fase(3)
				else:
					ip += 1
					if ip >= PERFILES.size():
						Engine.remove_meta("calidad_proto")
						print("FOTOS HECHAS")
						quit(0)
						return true
					_cargar()
	if frames > 6000:
		print("FALLO: las fotos no terminaron (fase %d)" % fase)
		quit(1)
		return true
	return false
