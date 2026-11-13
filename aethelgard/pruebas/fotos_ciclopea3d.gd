extends SceneTree
# V12 (13/11), capturas de las Cumbres de Ciclópea 3D (primer sector, en pruebas): la entrada, la subida, el puente
# sobre el arroyo helado, las ruinas con la estatua y el Tomo de Escarcha, el campamento, el claro y el altar, y tres
# vistas fijas, en bajo, medio y alto, con llamadas de dibujo, primitivas y GPU por vista.
# Uso: --path aethelgard --script res://pruebas/fotos_ciclopea3d.gd --fixed-fps 30 -- <carpeta> 3d ciclopea3d sin_prologo
#      [perfiles=bajo,medio,alto] [res=1600x720]
# No toca ninguna partida (progreso.gd no guarda en las pruebas).

const REGION := "res://zonas3d/ciclopea_3d.tscn"
const T := preload("res://zonas3d/ciclopea/trazado.gd")
const D := preload("res://zonas3d/ciclopea/disposicion_2d.gd")
# [nombre, casilla de la 2D donde se pone a Kael]
var SITIOS := [
	["k01_entrada", Vector2(40.0, 52.5)],
	["k02_subida", Vector2(43.6, 45.0)],
	["k03_puente", Vector2(39.6, 32.4)],
	["k04_ruinas_estatua", Vector2(27.6, 48.4)],
	["k05_tomo_escarcha", Vector2(26.4, 43.6)],
	["k06_campamento", Vector2(22.5, 37.4)],
	["k07_claro", Vector2(62.6, 28.4)],
	["k08_altar", Vector2(45.8, 8.6)],
]
# [nombre, cámara (casilla, alto), punto al que mira (casilla), campo de visión]
var VISTAS := [
	["k09_desde_la_entrada", Vector3(40.0, 14.0, 60.0), Vector3(42.0, 4.0, 34.0), 55.0],
	["k10_subida_al_altar", Vector3(52.0, 22.0, 30.0), Vector3(44.0, 6.0, 10.0), 55.0],
	["k11_de_arriba", Vector3(40.0, 70.0, 34.0), Vector3(40.0, 0.0, 28.0), 60.0],
]
var perfiles: Array = ["bajo", "medio", "alto"]
var salida := ""
var tam := Vector2i(1280, 720)
var ip := 0
var v
var frames := 0
var fase := 0
var f_fase := 0
var i_sitio := 0
var i_vista := 0
var _gpu: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0]
	for a in args:
		if a.begins_with("res="):
			var p: PackedStringArray = a.substr(4).split("x")
			tam = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("perfiles="):
			perfiles = Array(a.substr(9).split(","))
	DisplayServer.window_set_size(tam)
	root.size = tam
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	_cargar()


func _cargar() -> void:
	Engine.set_meta("calidad_proto", perfiles[ip])
	for k in ["mazmorras", "cofres_abiertos", "lore_visto"]:
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


func _mediana(a: Array) -> float:
	if a.is_empty():
		return -1.0
	var o := a.duplicate()
	o.sort()
	return o[o.size() / 2]


func _foto(nombre: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s_%dx%d_%s.png" % [salida, perfiles[ip], tam.x, tam.y, nombre])
	print("DIBUJO %s %s: llamadas %d · primitivas %d · objetos %d · GPU %.2f ms" % [perfiles[ip], nombre,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), _mediana(_gpu)])


func _poner(c: Vector2) -> void:
	v._colocar_kael(v._sitio_libre(T.en_mundo(c)))
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)


func _process(_d: float) -> bool:
	frames += 1
	if v != null and "pasos" in v:
		v.pasos = 0                                   # sin encuentros mientras se hacen las fotos
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 20:
				v = current_scene
				_poner(SITIOS[0][1])
				_fase(2)
		2:
			if frames - f_fase >= 40:
				var g := RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
				if g > 0.0 and g < 1000.0:
					_gpu.append(g)
			if frames - f_fase == 70:
				_foto(SITIOS[i_sitio][0])
				i_sitio += 1
				if i_sitio < SITIOS.size():
					_poner(SITIOS[i_sitio][1])
					_fase(2)
				else:
					_fase(3)
		3:
			if frames - f_fase == 1:
				var vi: Array = VISTAS[i_vista]
				v.set_process(false)
				var a: Vector3 = vi[1]
				var b: Vector3 = vi[2]
				var pa := T.mundo(Vector2(a.x, a.z))
				var pb := T.mundo(Vector2(b.x, b.z))
				v.cam.global_position = Vector3(pa.x, a.y, pa.z)
				v.cam.look_at(Vector3(pb.x, b.y, pb.z), Vector3.UP)
				v.cam.fov = vi[3]
				v.cam.far = 400.0
			elif frames - f_fase == 30:
				_foto(VISTAS[i_vista][0])
				v.set_process(true)
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
