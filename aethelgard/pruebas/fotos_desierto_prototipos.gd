extends SceneTree
# Capturas de los PROTOTIPOS del desierto (V12, 12/11/2026, especialista de animaciones; con ventana):
#   --script res://pruebas/fotos_desierto_prototipos.gd -- salida=<carpeta> [solo=personajes|criaturas]
# 1. Personajes: Ismena y Oren (personajes/desierto/npc_desierto_3d.gd) en arena, con Kael a escala, con la cámara de
#    la exploración (vista3d.gd: 45°, 20 m, 38°) y de cerca; cada gesto en su instante clave; y una secuencia de
#    diálogo simulada (hablar, hablar, gesto de espera…) en fotogramas → personajes.png (hoja) y cada foto.
# 2. Criaturas: Vidracrán y Tolvanera con una cámara como la del combate (ortográfica, 12° desde arriba), Kael a
#    escala a su lado; cada clip en sus instantes clave → criaturas_vidracran.png, criaturas_tolvanera.png.
# Escena propia (no toca la región ni el combate). No mide rendimiento.

const TAM := Vector2i(960, 640)
var salida := ""
var solo := ""
var fotos: Array = []
var fallos := 0
var escena: Node3D
var cam: Camera3D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("solo="):
			solo = a.substr(5)
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_desierto")
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = TAM
	_correr.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(salida.path_join(nombre + ".png"))
	fotos.append([nombre, img])


func _hoja(nombre: String, cols: int, escala := 0.5) -> void:
	if fotos.is_empty():
		return
	var w := int(TAM.x * escala)
	var h := int(TAM.y * escala)
	var filas := int(ceil(fotos.size() / float(cols)))
	var hoja := Image.create(w * cols, h * filas, false, Image.FORMAT_RGBA8)
	hoja.fill(Color(0.1, 0.1, 0.1))
	for i in fotos.size():
		var im: Image = fotos[i][1]
		im.convert(Image.FORMAT_RGBA8)
		im.resize(w, h, Image.INTERPOLATE_BILINEAR)
		hoja.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	hoja.save_png(salida.path_join(nombre + ".png"))
	print("HOJA ", salida.path_join(nombre + ".png"), " (", fotos.size(), " fotos)")
	fotos.clear()


func _montar_escena() -> void:
	if escena:
		escena.queue_free()
		await _esperar(2)
	escena = Node3D.new()
	root.add_child(escena)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.66, 0.74, 0.84)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.80, 0.82, 0.90)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	escena.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(1.0, 0.93, 0.80)
	sol.light_energy = 0.95
	sol.shadow_enabled = true
	sol.rotation_degrees = Vector3(-52, 35, 0)
	escena.add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.70, 0.58, 0.40)
	ms.roughness = 0.95
	suelo.material_override = ms
	escena.add_child(suelo)
	cam = Camera3D.new()
	escena.add_child(cam)
	cam.current = true


func _kael(pos: Vector3, giro: float) -> Node3D:
	var k: Node3D = load("res://kael_3d.gd").new()
	k.ruta_modelo = "res://kael.fbx"
	k.position = pos
	escena.add_child(k)
	k.rotation.y = giro
	return k


func _cam_exploracion(foco: Vector3, distancia := 20.0) -> void:
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 38.0
	var ang := deg_to_rad(45.0)
	var ojo := foco + Vector3(0, 0.9, 0)
	cam.global_position = ojo + Vector3(0, 0, 1) * cos(ang) * distancia + Vector3.UP * sin(ang) * distancia
	cam.look_at(ojo, Vector3.UP)


func _cam_combate(centro_y := 0.8, alto := 3.2, x := 0.0) -> void:
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = alto
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(x, centro_y + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(x, centro_y, 0))


func _correr() -> void:
	if solo != "criaturas":
		await _personajes()
	if solo != "personajes":
		await _criaturas()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _pose(n: Node3D, clip: String, t: float) -> void:
	var a: AnimationPlayer = n.anim
	if a == null or not a.has_animation(clip):
		print("FALLO: falta el clip ", clip)
		fallos += 1
		return
	a.play(clip, 0.0)
	a.seek(t, true)
	a.pause()


# ---------------------------------------------------------------- personajes

func _personajes() -> void:
	await _montar_escena()
	var NPC = load("res://personajes/desierto/npc_desierto_3d.gd")
	var ismena: Node3D = NPC.crear("ismena")
	escena.add_child(ismena)
	var oren: Node3D = NPC.crear("oren")
	oren.position = Vector3(-1.6, 0, 0.4)
	escena.add_child(oren)
	var kael := _kael(Vector3(2.6, 0, 1.0), -PI * 0.5)
	await _esperar(6)
	for n in [ismena, oren]:
		if n.anim == null:
			print("FALLO: ", n.quien, " sin AnimationPlayer")
			fallos += 1
			return
	ismena.mirar_a(kael.global_position, 0.0)
	oren.mirar_a(kael.global_position, 0.0)
	await _esperar(10)
	_cam_exploracion(Vector3(-0.4, 0, 1.0), 20.0)
	await _foto("p00_exploracion_20m")
	_cam_exploracion(Vector3(-0.4, 0, 1.0), 9.0)
	await _foto("p01_exploracion_9m")
	# de cerca, desde el sitio de Kael (3/4)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 30
	cam.look_at_from_position(Vector3(0.2, 1.5, 4.8), Vector3(-0.8, 0.85, 0.2))
	await _foto("p02_cerca_reposo")
	for t in [["ismena", "hablar", 34.0 / 30], ["ismena", "mapa", 50.0 / 30], ["ismena", "horizonte", 40.0 / 30],
			["ismena", "reganar", 18.0 / 30], ["oren", "hablar", 20.0 / 30], ["oren", "risa", 30.0 / 30],
			["oren", "encogerse", 20.0 / 30]]:
		var n: Node3D = ismena if t[0] == "ismena" else oren
		_pose(n, t[1], t[2])
		await _esperar(2)
		await _foto("p_%s_%s" % [t[0], t[1]])
		n.anim.play("reposo")
	_hoja("personajes_poses", 4)
	# secuencia simulada de diálogo (mc_superviviente / mc_cartografa_fin): frases cada 1,6 s, fotos cada 0,4 s
	ismena.en_dialogo(true)
	oren.en_dialogo(true)
	var guion := [oren, ismena, oren, oren, ismena, ismena]
	var k := 0
	for frase in guion:
		frase.hablar()
		for i in 4:
			await _esperar(12)
			await _foto("s%02d" % k)
			k += 1
	ismena.en_dialogo(false)
	oren.en_dialogo(false)
	_hoja("personajes_secuencia", 6, 0.34)
	escena.queue_free()
	escena = null
	await _esperar(3)


# ---------------------------------------------------------------- criaturas

func _criaturas() -> void:
	for cual in ["vidracran", "tolvanera"]:
		await _montar_escena()
		var c: Node3D = load("res://enemigos/%s/%s_3d.gd" % [cual, cual]).new()
		escena.add_child(c)
		var kael := _kael(Vector3(1.7, 0, 0.5), -PI * 0.5)
		await _esperar(8)
		if c.anim == null:
			print("FALLO: ", cual, " sin AnimationPlayer")
			fallos += 1
			continue
		_cam_combate(0.85 if cual == "vidracran" else 1.05, 2.9 if cual == "vidracran" else 3.4, 0.6)
		var tomas: Array
		if cual == "vidracran":
			tomas = [["reposo", 0.0], ["pinzas", 8.0 / 30], ["pinzas", 14.0 / 30], ["enterrarse", 20.0 / 30],
				["enterrado", 0.5], ["aviso_aguijon", 4.0 / 30], ["emerger_aguijon", 5.0 / 30],
				["emerger_aguijon", 10.0 / 30], ["emerger_aguijon", 15.0 / 30], ["recibir_golpe", 3.0 / 30],
				["derrota", 24.0 / 30], ["correr", 4.0 / 30]]
		else:
			tomas = [["reposo", 0.0], ["aviso_rafaga", 12.0 / 30], ["rafaga", 13.0 / 30], ["torbellino", 18.0 / 30],
				["torbellino", 26.0 / 30], ["torbellino", 32.0 / 30], ["curarse_viento", 24.0 / 30],
				["agua_asienta", 6.0 / 30], ["recibir_golpe", 3.0 / 30], ["entrada", 12.0 / 30], ["derrota", 20.0 / 30],
				["derrota", 40.0 / 30]]
		for t in tomas:
			if cual == "vidracran":
				c._poner_brillo(3.5 if t[0] == "aviso_aguijon" else (2.4 if t[0] == "emerger_aguijon" else 1.2))
			else:
				c._param("barro", 0.85 if t[0] == "agua_asienta" else 0.0)
				c._param("desvanecer", clampf(1.0 - (t[1] - 0.4) / 1.2, 0.0, 1.0) if t[0] == "derrota" else 1.0)
			_pose(c, t[0], t[1])
			await _esperar(3)
			await _foto("c_%s_%s_%02d" % [cual, t[0], int(round(t[1] * 30))])
		_hoja("criaturas_" + cual, 4)
		# en movimiento (el polvo y los escombros giran solos): 8 fotogramas del reposo
		c.anim.play("reposo")
		for i in 8:
			await _esperar(4)
			await _foto("m_%s_%d" % [cual, i])
		_hoja("criaturas_%s_movimiento" % cual, 4)
		escena.queue_free()
		escena = null
		await _esperar(3)
