extends SceneTree
# V12, fase 9 (14/11/2026, PILOTO): capturas en Godot del Custodio de Porcelana (meshy_e01). Con ventana y
# «fotos=<carpeta>»:
#   1. Estudio: el GLB importado (materiales del GLB, renderizador Compatibility) junto a Kael y Garon a su escala real,
#      de frente, de perfil y de espalda, en el reposo, a 0,65 s (puños arriba), en el impacto (0,90) y a 1,65 s de la
#      Prensa, y en dos fases del paso (estudio_<clip>_<t>_<vista>.png).
#   2. Combate real (grupo 28, interruptor «meshy_e01»): su Prensa del Umbral contra Lya y Garon, fotograma a fotograma
#      (uno de cada dos, JPG a media resolución) con indice.txt (aviso, fija, impacto y fin de su turno).

const CLIPS := {"reposo": [0.0], "caminar": [0.0, 0.3], "ataque": [0.25, 0.65, 0.9, 1.65]}
var fotos := ""
var C
var G
var P
var PE
var n_foto := 0
var grabando := false
var indice: Array = []


func _initialize() -> void:
	C = load("res://combate.gd")
	G = load("res://grupo.gd")
	P = load("res://progreso.gd")
	PE = load("res://combate_meshy_e01.gd")
	Engine.set_meta("archivo_partida_prueba", "user://fotos_meshy_e01.save")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
	if fotos == "":
		fotos = OS.get_user_data_dir().path_join("fotos_meshy_e01")
	DirAccess.make_dir_recursive_absolute(fotos)
	process_frame.connect(func():
		if grabando:
			_grabar())
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _probar() -> void:
	await _esperar(10)
	await _estudio()
	await _combate()
	var f := FileAccess.open(fotos.path_join("indice.txt"), FileAccess.WRITE)
	f.store_string("\n".join(indice) + "\n")
	Engine.remove_meta("archivo_partida_prueba")
	print("FOTOS: ", fotos, " (", n_foto, " fotogramas del combate)")
	quit(0)


# ================================================================= 1. estudio

func _estudio() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1200, 900)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.42, 0.45, 0.50)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	env.environment.ambient_light_energy = 0.6
	vp.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, -35, 0)
	luz.light_energy = 1.2
	vp.add_child(luz)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 8)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.32, 0.36, 0.32)
	suelo.material_override = ms
	vp.add_child(suelo)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.1, 8), Vector3(0, 1.1, 0))
	var cus = load("res://enemigos/meshy_e01/meshy_e01_3d.gd").new()
	vp.add_child(cus)
	cus.position = Vector3(0.15, 0, 0)
	var acomp: Array = []
	for clave in ["kael3d", "garon3d"]:
		var m: Dictionary = C.MODELOS[clave]
		if C._ruta_3d(m) == "":
			continue
		var h = C.modelo_3d(m)
		vp.add_child(h)
		acomp.append(h)
	await _esperar(10)
	if acomp.size() > 0:
		acomp[0].position = Vector3(-1.15, 0, 0)
	if acomp.size() > 1:
		acomp[1].position = Vector3(1.45, 0, 0)
	for h in acomp:
		if h.has_method("mirar"):
			h.mirar(Vector3(0, 0, 1), 0.0)
		elif "rotation" in h:
			h.rotation = Vector3.ZERO
	for vista in [["frente", 0.0], ["perfil", 90.0], ["espalda", 180.0]]:
		for clip in CLIPS:
			for t in CLIPS[clip]:
				cus.mirar(Vector3(sin(deg_to_rad(vista[1])), 0, cos(deg_to_rad(vista[1]))), 0.0)
				cus.anim.play(clip)
				cus.anim.seek(t, true)
				cus.anim.speed_scale = 0.0
				await _esperar(4)
				var img := vp.get_texture().get_image()
				img.save_png(fotos.path_join("estudio_%s_%03d_%s.png" % [clip, int(round(t * 100)), vista[0]]))
	cus.anim.speed_scale = 1.0
	vp.queue_free()
	await _esperar(5)


# ================================================================= 2. combate

func _combate() -> void:
	for k in P.CLAVES + ["grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 4
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 28)
	Engine.set_meta(PE.INTERRUPTOR, true)
	seed(14112026)
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	var cus: Dictionary = {}
	for e in c.enemigos:
		if PE.es(e):
			cus = e
	for h in c.heroes:
		h["vel"] = 0.0
		h["atb"] = 40.0
	for e in c.enemigos:
		e["vel"] = 0.0
		e["atb"] = 0.0
	c.heroes[1]["hp"] = int(c.heroes[1]["hp_max"] * 0.6)          # Lya, la elegida; Garon, el de detrás
	await _esperar(60)
	grabando = true
	cus["vel"] = 10.0
	cus["atb"] = c.ATB_MAX - 0.01
	var empezado := false
	var visto := {}
	for fr in 900:
		await process_frame
		if is_same(c.atacante_actual, cus):
			empezado = true
			cus["vel"] = 0.0
		var at: Dictionary = cus.get("e01_ataque", {})
		for k in ["t_aviso", "t_fija", "t_impacto"]:
			if at.has(k) and int(at[k]) >= 0 and not visto.has(k):
				visto[k] = true
				indice.append("%s: f_%05d.jpg" % [k, n_foto])
		if empezado and c.atacante_actual == null:
			break
	indice.append("fin del turno: f_%05d.jpg" % n_foto)
	await _esperar(20)
	grabando = false
	c.queue_free()
	Engine.remove_meta(PE.INTERRUPTOR)
	await _esperar(10)


func _grabar() -> void:
	if Engine.get_process_frames() % 2 != 0:
		return
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		return
	img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	img.save_jpg(fotos.path_join("f_%05d.jpg" % n_foto), 0.85)
	n_foto += 1
