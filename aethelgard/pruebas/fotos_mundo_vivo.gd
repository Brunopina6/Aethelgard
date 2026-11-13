extends SceneTree
# V12, mundo vivo de Oakhaven (especialista de mundo 3D y NPC): capturas comparativas SIN y CON el interruptor
# «mundo_vivo_v12», mismos sitios, misma hora y misma cámara, con llamadas de dibujo, primitivas y GPU por vista.
# Copia recortada de fotos_oakhaven3d_completo.gd. Primeros planos de la familia en su sitio con «cerca» (cámara fija).
# Uso: --path aethelgard --script res://pruebas/fotos_mundo_vivo.gd --fixed-fps 30 -- <carpeta> 3d sin_prologo
#      [perfiles=bajo,medio,alto] [res=1600x720]
# No toca ninguna partida (progreso.gd no guarda en las pruebas). Los encuentros se quitan solo aquí (no hay en la ciudad).

const REGION := "res://zonas3d/oakhaven_3d.tscn"
const ESTADOS := ["sin", "con"]
# [nombre, posición de Kael]: la plaza con el corro, el mercado, la forja, la Puerta del Sur, la botica y el huerto
const SITIOS := [
	["v01_plaza", Vector3(40.0, 0, 31.0)],
	["v02_mercado", Vector3(52.0, 0, 31.2)],
	["v03_forja_huerto", Vector3(46.0, 0, 36.0)],
	["v04_puerta_sur", Vector3(40.2, 0, 52.0)],
	["v05_botica", Vector3(37.0, 0, 43.6)],
	["v06_calle_cuervo", Vector3(22.0, 0, 26.0)],
]
# Primeros planos (cámara fija): [nombre, cámara, punto al que mira, campo de visión]
const VISTAS := [
	["w01_plaza_cerca", Vector3(40.0, 5.5, 34.5), Vector3(40.0, 0.6, 26.0), 50.0],
	["w02_mercado_cerca", Vector3(53.0, 15.0, 40.0), Vector3(53.0, 0.0, 29.0), 45.0],
	["w03_forja_cerca", Vector3(45.5, 3.4, 39.0), Vector3(45.0, 0.8, 35.0), 55.0],
	["w04_calle_mayor_cerca", Vector3(40.5, 14.0, 36.0), Vector3(40.5, 0.0, 46.5), 45.0],
]
var perfiles: Array = ["medio"]
var salida := ""
var tam := Vector2i(1280, 720)
var ip := 0
var ie := 0
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
	Engine.set_meta("mundo_vivo_v12", ESTADOS[ie] == "con")
	for k in ["mazmorras", "cofres_abiertos", "lore_visto", "oak_franja", "oak_franja_t"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)
	seed(12345)                                   # el mismo reparto de los que andan en las dos pasadas
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
	var ruta := "%s/%s_%s_%dx%d_%s.png" % [salida, perfiles[ip], ESTADOS[ie], tam.x, tam.y, nombre]
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(ruta)
	var dib := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prim := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var obj := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var reparto = v.vivo.cuenta if v.vivo != null else {}
	print("DIBUJO %s %s %s: llamadas %d · primitivas %d · objetos %d · GPU %.2f ms · NPC %s" % [perfiles[ip],
		ESTADOS[ie], nombre, dib, prim, obj, _mediana(_gpu), reparto])


func _poner(p: Vector3) -> void:
	v.en_posada = false
	v._colocar_kael(p)
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)


func _process(_d: float) -> bool:
	frames += 1
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
			if frames - f_fase == 75:
				_foto(SITIOS[i_sitio][0])
				i_sitio += 1
				if i_sitio < SITIOS.size():
					_poner(SITIOS[i_sitio][1])
					_fase(2)
				else:
					_poner(Vector3(40.0, 0, 31.0))
					_fase(3)
		3:
			if frames - f_fase == 1:
				var vi: Array = VISTAS[i_vista]
				v.set_process(false)                  # la cámara fija (la del juego no la persigue)
				v.cam.global_position = vi[1]
				v.cam.look_at(vi[2], Vector3.UP)
				v.cam.fov = vi[3]
			elif frames - f_fase == 40:
				_foto(VISTAS[i_vista][0])
				v.set_process(true)
				i_vista += 1
				if i_vista < VISTAS.size():
					_fase(3)
				else:
					ie += 1
					if ie >= ESTADOS.size():
						ie = 0
						ip += 1
						if ip >= perfiles.size():
							Engine.remove_meta("calidad_proto")
							Engine.remove_meta("mundo_vivo_v12")
							print("FOTOS HECHAS")
							quit(0)
							return true
					_cargar()
	if frames > 8000:
		print("FALLO: las fotos no terminaron (fase %d)" % fase)
		quit(1)
		return true
	return false
