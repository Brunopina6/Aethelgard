extends SceneTree
# Capturas de Pastos Verdes 3D para revisarlas a ojo (perfiles bajo y alto): el cofre (desde el camino, de cerca,
# abriéndose y abierto). Guarda también el sonido del cofre en un .wav para escucharlo.
# Uso: --path aethelgard --script res://pruebas/prueba_region3d_fotos.gd --fixed-fps 30 -- <carpeta> 3d sin_prologo
# Los encuentros se quitan solo aquí (v.pasos = 0); la región jugable los conserva.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const PERFILES := ["bajo", "alto"]
const DESDE := Vector3(13.3, 0, -2)               # la salida del puente

var salida := ""
var ip := 0
var v
var frames := 0
var fase := 0
var f_fase := 0


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true})
	load("res://zonas3d/pastos_verdes_3d.gd").sonido_cofre().save_to_wav(salida + "/sonido_cofre.wav")
	_cargar()


func _cargar() -> void:
	Engine.set_meta("calidad_proto", PERFILES[ip])
	if Engine.has_meta("cofres_abiertos"):
		Engine.remove_meta("cofres_abiertos")
	change_scene_to_file(REGION)
	v = null
	_fase(1)


func _fase(n: int) -> void:
	fase = n
	f_fase = frames


func _foto(nombre: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [salida, PERFILES[ip], nombre])
	print("%s %s: Kael %s · cofre %s" % [PERFILES[ip], nombre, v.kael.global_position.snapped(Vector3.ONE * 0.1),
		v.cofre.global_position.snapped(Vector3.ONE * 0.1)])


func _process(_d: float) -> bool:
	frames += 1
	if v != null:
		v.pasos = 0
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 30:
				v = current_scene
				v._colocar_kael(Vector3(DESDE.x, v.altura(DESDE.x, DESDE.z), DESDE.z))
				_fase(2)
		2:
			if frames - f_fase == 45:
				_foto("cofre_1_desde_el_camino")
				v.destino = v._ajustar_destino(v.cofre.global_position + (DESDE - v.cofre.global_position).normalized())
				_fase(3)
		3:
			if v.cerca == "cofre" and v.destino == null:
				v.distancia = 9.0
				_fase(4)
			elif frames - f_fase > 600:
				print("FALLO: Kael no llegó al cofre")
				quit(1)
				return true
		4:
			if frames - f_fase == 45:
				_foto("cofre_2_cerca_cerrado")
				v._accion()
			elif frames - f_fase == 53:
				_foto("cofre_3_abriendose")
			elif frames - f_fase == 90:
				_foto("cofre_4_abierto")
				Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true, "pv_06": true})
				Engine.set_meta("combates_ganados", {"pastos_centinela": true})
				change_scene_to_file(REGION)
				v = null
				_fase(5)
		5:                                          # la cinemática del mirador (PV-07)
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 30:
				v = current_scene
				v._colocar_kael(Vector3(1.5, v.altura(1.5, -7.8), -7.8))
				_fase(6)
		6:
			if v.cinematica:
				_fase(7)
			elif frames - f_fase > 120:
				print("FALLO: la cinemática no empezó")
				quit(1)
				return true
		7:
			var cuadros := {45: "mirador_1", 105: "mirador_2_cascada", 165: "mirador_3", 210: "mirador_4_desde_arriba",
				285: "mirador_5", 330: "mirador_6_ciudad", 352: "mirador_7_vuelta"}
			if cuadros.has(frames - f_fase):
				_foto(cuadros[frames - f_fase])
			elif frames - f_fase == 400:
				_foto("mirador_8_conversacion")
				root.get_node("Dialogic").end_timeline()   # Dialogic es global: si no, el diálogo pasa a la escena siguiente
				Engine.set_meta("hitos", {"pv_02": true, "pv_03": true})
				Engine.remove_meta("combates_ganados")
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
