extends SceneTree
# Prueba del prototipo de cámara 3D (prototipos/vista3d.tscn): camina, pasa detrás de las ruinas
# (oclusión), sube la escalera y compara perspectiva y ortográfica. Hace fotos en <carpeta>.
# Uso: --path aethelgard --script res://pruebas/prueba_vista3d.gd --fixed-fps 30 -- <carpeta>

var v: Node
var n := 0
var salida := ""


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	v = load("res://prototipos/vista3d.tscn").instantiate()
	root.add_child(v)


func _foto(nombre: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [salida, nombre])
	print(nombre, "  kael=", v.kael.global_position.snapped(Vector3.ONE * 0.1), "  tapados=", v.tapados.size(),
		"  fps=", Engine.get_frames_per_second())


func _process(_d: float) -> bool:
	n += 1
	match n:
		45: _foto("1_inicio_perspectiva")
		50: v.destino = Vector3(-6, 0, 1.4)              # detrás de una columna de las ruinas
		170: _foto("2_tras_ruinas")
		175: v.destino = Vector3(-2, 0, -14)             # sube la escalera a la terraza
		330: _foto("3_terraza")
		335:
			v.distancia = 30.0
		360: _foto("4_lejos_30m")
		365:
			v.distancia = 20.0
			v.cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		390: _foto("5_ortografica")
		395:                                             # encuadre bajo y abierto: deja ver el horizonte
			v.cam.projection = Camera3D.PROJECTION_PERSPECTIVE
			v.inclinacion = 30.0
			v.campo_vision = 55.0
			v.distancia = 16.0
		420: _foto("6_bajo_30grados_fov55")
	return n > 425
