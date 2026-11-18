extends SceneTree
# Prueba del portal: mapa -> cruzar el portal -> ciudad flotante (andar, tapar, hablar) -> bajar -> mapa.
# Uso: --script prueba_isla.gd -- <carpeta> sin_prologo

var frames := 0
var salida := ""
var R
var fase := 0
var t_fase := 0                                  # (18/11) reloj de la espera de cada escena


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	R = root.get_node("Recursos")
	change_scene_to_file("res://mapa.tscn")


func _foto(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [salida, n])


func _process(_d: float) -> bool:
	frames += 1
	var esc = current_scene
	if fase == 0 and frames == 20:
		var portal: Dictionary = esc.LUGARES[9]
		esc.jugador.position = portal["pos"] + Vector2(0, 20)
		esc._comprobar_cerca()
		print("en el mapa junto al portal: ", esc.boton_entrar.text)
		_foto("1_mapa")
		esc._entrar()
		fase = 1
		t_fase = Time.get_ticks_msec()
	elif fase == 1 and esc != null and esc.scene_file_path == "res://isla.tscn" and not R.cambiando:
		fase = 2
		set_meta("f", frames)
		print("en la isla: pos ", esc.jugador.position, "  z_kael ", esc.z_kael, "  zona cargada: ", R.grupos["zona"].size(), " recursos")
	elif fase == 2 and frames == get_meta("f") + 30:
		_foto("2_llegada")
		esc.destino = Vector2(1364, 1700)           # sube hacia el templo por la plaza
		esc.tiene_destino = true
	elif fase == 2 and frames == get_meta("f") + 330:
		print("tras andar hacia el templo: pos ", esc.jugador.position, "  z_kael ", esc.z_kael)
		_foto("3_plaza")
		esc._comprobar_cerca()
		print("cerca: ", esc.boton.text if esc.boton.visible else "(nada)")
		if esc.npc_cerca != null:
			esc._accion()
			print("aviso: ", esc.aviso.text)
		var paredes := 0
		for p in [Vector2(1373, 1880), Vector2(300, 300), Vector2(1500, 3200)]:
			if not esc._se_anda(p):
				paredes += 1
		print("puntos que no se pisan (cristal, cielo, abajo): ", paredes, " de 3")
		esc.jugador.position = esc.PORTAL + Vector2(0, 40)
		esc.camara.reset_smoothing()
	elif fase == 2 and frames == get_meta("f") + 340:
		esc._comprobar_cerca()
		print("junto al portal de la isla: ", esc.boton.text)
		_foto("4_portal")
		esc._accion()
		fase = 3
		t_fase = Time.get_ticks_msec()
	elif fase == 3 and esc != null and esc.scene_file_path == "res://mapa.tscn" and not R.cambiando:
		print("de vuelta en el mapa en ", esc.jugador.position, " (portal en ", esc.LUGARES[9]["pos"], ")  zona liberada: ", R.grupos["zona"].size())
		return true
	# (18/11) la isla y la vuelta al mapa llegan con Recursos.cambiar_escena (carga en segundo plano, en tiempo REAL).
	# Antes todo acababa a los 1500 fotogramas, que con --fixed-fps y una pantalla de 144 Hz o más son 5-10 s, y en
	# silencio (salida 0, sin FALLO). Ahora cada escena se espera 60 s de reloj y, si no llega, se dice
	# (docs/v12/PRUEBAS_CARRERAS_18_11.md).
	if fase in [1, 3] and Time.get_ticks_msec() - t_fase > 60000:
		print("FALLO: fase %d: la escena no termina de cargarse en 60 s (R.cambiando=%s, escena=%s)" % [fase, R.cambiando,
			esc.scene_file_path if esc != null else "(ninguna)"])
		quit(1)
	return false
