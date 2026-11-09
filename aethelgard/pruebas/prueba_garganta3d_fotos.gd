extends SceneTree
# Capturas de la Garganta del Diablo 3D para revisarlas a ojo, en los perfiles bajo y alto: la entrada, los puentes
# colgantes (con el nido brillando abajo), los pilares del islote, el levadizo levantado y la puerta, la escalera de la
# presa, la cornisa baja con el ascensor, el nido, la palanca y el puente bajando, la arena de Gorthor, la grieta oculta,
# una vista de lejos y el plano desde arriba. Con ventana, a 1280 × 720.
# Uso: --path aethelgard --script res://pruebas/prueba_garganta3d_fotos.gd --fixed-fps 30 -- <carpeta> 3d garganta3d sin_prologo
# No toca ninguna partida: progreso.gd no guarda durante las pruebas. Los encuentros se quitan solo aquí (v.pasos = 0).

const REGION := "res://zonas3d/garganta_3d.tscn"
const PERFILES := ["bajo", "alto"]
# [nombre, posición de Kael (la y se busca en el suelo), fotogramas de espera]
const SITIOS := [
	["01_entrada", Vector3(-12.0, 0, 36.0)],
	["02_puente_colgante", Vector3(-12.0, 0, 15.5)],
	["03_islote_pilares", Vector3(-12.6, 0, 10.6)],
	["04_levadizo_y_puerta", Vector3(-12.0, 0, -4.0)],
	["05_puerta_sellada", Vector3(-12.0, 0, -17.6)],
	["06_escalera_presa", Vector3(-0.5, 0, 29.5)],
	["07_cornisa_baja_ascensor", Vector3(11.0, -8.0, 27.0)],
	["08_bajada_al_nido", Vector3(5.5, -10.0, 15.5)],
	["09_nido", Vector3(5.2, -14.0, 9.8)],
	["10_palanca", Vector3(11.4, -8.0, -5.5)],
	["13_arena_gorthor", Vector3(-11.2, 0, -24.4)],      # ya en la zona de cámara de la arena, antes del disparo (z < −26)
	["14_grieta_oculta", Vector3(11.4, -8.0, -28.0)],
]

var salida := ""
var ip := 0
var v
var frames := 0
var fase := 0
var f_fase := 0
var i_sitio := 0


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	DisplayServer.window_set_size(Vector2i(1280, 720))
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
	_fase(1)


func _fase(n: int) -> void:
	fase = n
	f_fase = frames


func _foto(nombre: String) -> void:
	var ruta := "%s/%s_%s.png" % [salida, PERFILES[ip], nombre]
	root.get_viewport().get_texture().get_image().save_png(ruta)
	print("%s %s: Kael %s · cámara %.0f° %.1f m · %d FPS" % [PERFILES[ip], nombre, v.kael.global_position.snapped(Vector3.ONE * 0.1),
		v.inclinacion, v.distancia, Engine.get_frames_per_second()])


# Kael en «p», con la y del suelo que haya debajo.
func _poner(p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 3.0, 0), p - Vector3(0, 6.0, 0))
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	if not r.is_empty():
		p.y = r["position"].y
	v._colocar_kael(p)
	if v.grupo != null:
		v.grupo.colocar(Vector3.BACK)


func _process(_d: float) -> bool:
	frames += 1
	if v != null:
		v.pasos = 0
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 20:
				v = current_scene
				_poner(SITIOS[0][1])
				_fase(2)
		2:                                          # cada sitio: colocar, esperar y foto
			if frames - f_fase == 50:
				_foto(SITIOS[i_sitio][0])
				i_sitio += 1
				if SITIOS[i_sitio - 1][0] == "10_palanca":
					v.cerca = "palanca"
					v._accion()                     # tira de la palanca: el puente baja
					_fase(3)
				elif i_sitio < SITIOS.size():
					_poner(SITIOS[i_sitio][1])
					_fase(2)
				else:
					_fase(4)
		3:
			var cuadros := {20: "11_levadizo_bajando", 50: "12_levadizo_bajando_2", 120: "12_levadizo_bajado"}
			if cuadros.has(frames - f_fase):
				_foto(cuadros[frames - f_fase])
			elif frames - f_fase == 150:
				_poner(SITIOS[i_sitio][1])
				_fase(2)
		4:                                          # vista de lejos: la garganta entera desde el sur, alta
			if frames - f_fase == 1:
				v.set_process(false)
				v.cam.global_position = Vector3(2.0, 34.0, 62.0)
				v.cam.look_at(Vector3(-1.0, -12.0, -8.0), Vector3.UP)
				v.cam.fov = 50.0
			elif frames - f_fase == 25:
				_foto("15_vista_de_lejos")
				v.cam.global_position = Vector3(-14.0, 12.0, -2.0)
				v.cam.look_at(Vector3(2.0, -16.0, 6.0), Vector3.UP)
				v.cam.fov = 45.0
			elif frames - f_fase == 50:
				_foto("16_desde_el_puente_al_nido")
				v.cam.projection = Camera3D.PROJECTION_ORTHOGONAL
				v.cam.size = 128.0
				v.cam.global_position = Vector3(0.0, 90.0, 4.0)
				v.cam.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
				v.cam.far = 400.0
			elif frames - f_fase == 75:
				_foto("17_plano_desde_arriba")
				ip += 1
				if ip >= PERFILES.size():
					Engine.remove_meta("calidad_proto")
					print("FOTOS HECHAS")
					quit(0)
					return true
				_cargar()
	if frames > 9000:
		print("FALLO: las fotos no terminaron (fase %d)" % fase)
		quit(1)
		return true
	return false
