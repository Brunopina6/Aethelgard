extends SceneTree
# V12 (14/11): fotos en Godot del piloto de Nix desde el FBX (personajes/nix/fbx/, interruptor «nix_fbx» encendido solo
# aquí), con ventana: junto a la Nix de siempre (misma luz y escala del juego), de frente, tres cuartos, perfil y
# espalda en guardia y en reposo, la cara de cerca y la canalización (mechones con retraso) en cuatro instantes; con el
# vestuario (14/11), los faldones abiertos al concentrarse (frente, tres cuartos y espalda), el emblema de la espalda y
# andar y correr.
# «-- salida=<carpeta>». No toca la partida.

var salida := ""
var nix: Node3D
var vieja: Node3D
var cam: Camera3D
var frames := 0
var paso := 0
var fotos: Array = []
var t_canal := 0.0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	if salida == "":
		print("FALLO: falta salida=<carpeta>")
		quit(1)
		return
	var raiz := Node3D.new()
	root.add_child(raiz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.66, 0.72)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.8, 0.9)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	raiz.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(1.0, 0.92, 0.8)
	sol.light_energy = 1.25
	sol.rotation_degrees = Vector3(-40, 30, 0)
	sol.shadow_enabled = true
	raiz.add_child(sol)
	vieja = load("res://personajes/nix/nix_3d.gd").new()
	raiz.add_child(vieja)
	vieja.position = Vector3(-1.1, 0, 0)
	Engine.set_meta("nix_fbx", true)
	nix = load("res://personajes/nix/nix_3d.gd").new()
	Engine.remove_meta("nix_fbx")
	raiz.add_child(nix)
	cam = Camera3D.new()
	cam.fov = 30.0
	raiz.add_child(cam)
	cam.current = true


func _mirar(desde: Vector3, a: Vector3) -> void:
	cam.position = desde
	cam.look_at(a, Vector3.UP)


func _foto(nombre: String) -> void:
	var img := root.get_texture().get_image()
	var ruta := "%s/%s.png" % [salida, nombre]
	img.save_png(ruta)
	fotos.append(ruta)


func _cerca_mano(lado: String, desde: Vector3) -> void:
	var sk: Skeleton3D = nix.skel
	var b := -1
	for i in sk.get_bone_count():
		if sk.get_bone_name(i).ends_with(lado + "Hand"):
			b = i
	if b < 0:
		return
	var p: Vector3 = sk.global_transform * sk.get_bone_global_pose(b).origin
	_mirar(p + desde, p)


func _girar(grados: float) -> void:
	nix.mirar(Vector3(sin(deg_to_rad(grados)), 0, cos(deg_to_rad(grados))), 0.0)


func _process(_d: float) -> bool:
	frames += 1
	if frames < 30 or frames % 15 != 0:
		return false
	match paso:
		0:
			vieja.mirar(Vector3(0, 0, 1), 0.0)
			_girar(0)
			_mirar(Vector3(-0.55, 1.0, 6.0), Vector3(-0.55, 0.9, 0))
		1:
			_foto("01_junto_a_la_nix_de_siempre_guardia")
			vieja.visible = false
			_mirar(Vector3(0.0, 1.0, 4.6), Vector3(0, 0.9, 0))
		2:
			_foto("02_frente_guardia")
			_girar(-40)
		3:
			_foto("03_tres_cuartos_guardia")
			_girar(-90)
		4:
			_foto("04_perfil_guardia")
			_girar(180)
		5:
			_foto("05_espalda_guardia")
			_girar(0)
			nix.activar_esperas(true)
		6:
			_foto("06_frente_reposo")
			_girar(-30)
			_mirar(Vector3(0.0, 1.5, 1.5), Vector3(0, 1.48, 0))
		7:
			_foto("07_cara")
			_mirar(Vector3(0.0, 1.3, 2.4), Vector3(0, 1.25, 0))
			nix.activar_esperas(false)
			nix.reposo()
		8:
			nix.concentrar()
			t_canal = Time.get_ticks_msec()
		9, 10, 11, 12:
			_foto("1%d_canalizar_%dms" % [paso - 9, Time.get_ticks_msec() - t_canal])
			if paso == 12:
				_mirar(Vector3(0.0, 1.0, 4.6), Vector3(0, 0.9, 0))
		13:
			# vestuario (14/11): los faldones abiertos en el bucle de la concentración, de frente, tres cuartos y espalda
			_foto("20_concentrar_frente")
			_girar(-40)
		14:
			_foto("21_concentrar_tres_cuartos")
			_girar(180)
		15:
			_foto("22_concentrar_espalda")
			nix.reposo()
			_girar(150)
		16:
			_foto("23_espalda_emblema_guardia")
			_mirar(Vector3(0.0, 1.3, 2.2), Vector3(0, 1.15, 0))
			_girar(180)
		17:
			_foto("24_emblema_cerca")
			_mirar(Vector3(0.0, 1.0, 4.6), Vector3(0, 0.9, 0))
			_girar(-90)
			nix.play("Walking", 0.1)
		18:
			_foto("25_andar_perfil")
			nix.play("Running", 0.1)
		19:
			_foto("26_correr_perfil")
			_girar(-40)
		20:
			_foto("27_correr_tres_cuartos")
			nix.reposo()
			_girar(0)
		# 15/11 (revisión de personajes): las MANOS de cerca (RightHandMiddle1 sin pesos: ¿se ve el dedo corazón de la
		# mano del cetro?), en guardia, en reposo de exploración y con el cetro en alto (ataque).
		21:
			_cerca_mano("Right", Vector3(0.45, 0.10, 0.55))
		22:
			_foto("30_mano_derecha_guardia")
			_cerca_mano("Left", Vector3(-0.45, 0.10, 0.55))
		23:
			_foto("31_mano_izquierda_guardia")
			nix.activar_esperas(true)
		24, 25:
			pass                                  # que llegue al reposo de exploración
		26:
			_cerca_mano("Right", Vector3(0.45, 0.10, 0.55))
		27:
			_foto("32_mano_derecha_reposo")
			_cerca_mano("Right", Vector3(0.0, 0.05, 0.6))
		28:
			_foto("33_mano_derecha_reposo_frente")
			nix.activar_esperas(false)
			nix.reproducir("ataque", 0.1)
		29:
			_cerca_mano("Right", Vector3(0.5, 0.15, 0.6))
		30:
			_foto("34_mano_derecha_ataque")
			nix.reposo()
		31:
			print("FOTOS: %d en %s" % [fotos.size(), salida])
			quit(0)
			return true
	paso += 1
	return false
