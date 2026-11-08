extends SceneTree
# Capturas del grupo en Pastos Verdes 3D (zonas3d/grupo_3d.gd), para revisarlas a ojo: al entrar, por el camino, en
# el puente, en la media vuelta, parados y de cerca. Con el perfil bajo (el del Redmi) y con el alto.
# Uso: --path aethelgard --script res://pruebas/prueba_grupo3d_fotos.gd --fixed-fps 30 -- <carpeta> 3d sin_prologo

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const RUTA := [Vector3(-9, 0, 9), Vector3(-3, 0, 5), Vector3(5.3, 0, -2), Vector3(12.7, 0, -2), Vector3(5.3, 0, -2),
	Vector3(-3, 0, 5)]
const PERFILES := ["bajo", "alto"]
# [tramo de la ruta, fotogramas desde que empieza, nombre]
const FOTOS := [[1, 20, "2_camino"], [3, 18, "3_puente"], [4, 6, "4_media_vuelta_a"], [4, 14, "4_media_vuelta_b"]]

var salida := ""
var ip := 0
var v
var frames := 0
var fase := 0
var f_fase := 0
var tramo := 0


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})   # Lya y Garon ya se han unido; sin escenas
	_cargar()


func _cargar() -> void:
	Engine.set_meta("calidad_proto", PERFILES[ip])
	change_scene_to_file(REGION)
	v = null
	_fase(1)


func _fase(n: int) -> void:
	fase = n
	f_fase = frames


func _foto(nombre: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [salida, PERFILES[ip], nombre])
	var g: Array = v.grupo.nodos() if v.grupo != null else []
	print("%s %s: Kael %s · %s" % [PERFILES[ip], nombre, v.kael.global_position.snapped(Vector3.ONE * 0.1),
		", ".join(g.map(func(n): return "%s %s" % [n.name, n.global_position.snapped(Vector3.ONE * 0.1)]))])


func _process(_d: float) -> bool:
	frames += 1
	match fase:
		1:
			if current_scene != null and current_scene.scene_file_path == REGION and frames - f_fase >= 45:
				v = current_scene
				_foto("1_entrada")
				tramo = 0
				v.destino = RUTA[0]
				_fase(2)
		2:
			v.pasos = 0                                    # siempre dentro de los pasos seguros: sin encuentros
			for f in FOTOS:
				if tramo == f[0] and frames - f_fase == f[1]:
					_foto(f[2])
			if v.destino == null or frames - f_fase > 600:
				tramo += 1
				if tramo >= RUTA.size():
					_fase(3)
				else:
					v.destino = RUTA[tramo]
					f_fase = frames
		3:
			if frames - f_fase == 90:
				_foto("5_parados")
				v.distancia = 9.0
			elif frames - f_fase == 120:
				_foto("6_cerca")
				ip += 1
				if ip >= PERFILES.size():
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
