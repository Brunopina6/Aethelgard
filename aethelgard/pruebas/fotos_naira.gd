extends SceneTree
# Naira (nombre provisional), MODELO PROVISIONAL del concepto A: comprobaciones y capturas en una escena propia.
# 12/11/2026, especialista de animaciones. No toca el grupo, el combate, los menús ni las regiones.
#   --script res://pruebas/fotos_naira.gd -- salida=<carpeta> [solo_comprobar]
# 1. Comprueba (también sin ventana, con «solo_comprobar»): el GLB carga; hay AnimationPlayer, Skeleton3D con 23
#    huesos (y el del astrolabio) y los 10 clips de personajes/naira/naira_provisional_clips.json con su duración
#    (±1 fotograma); la altura en reposo es 1,55 m (±3 cm); 2 materiales como mucho.
# 2. Capturas (con ventana): Naira junto a Kael, Lya y Garon (alturas del grupo) con la cámara de la exploración
#    (vista3d.gd: 45°, 20 m, 38°) y de cerca; cada clip en su instante clave con una cámara como la del combate
#    (ortográfica, 12°); secuencias de lanzar_hechizo y magia_poderosa; y una cadena de clips con mezcla
#    (reposo → ataque → reposo → recibir_golpe → reposo → caminar → correr → reposo) como en el juego.
# No mide rendimiento.

const RUTA := "res://personajes/naira/naira_provisional.glb"
const RUTA_DATOS := "res://personajes/naira/naira_provisional_clips.json"
const TAM := Vector2i(960, 640)
const BUCLES := ["reposo", "caminar", "correr", "concentracion"]
var salida := ""
var solo_comprobar := false
var fotos: Array = []
var fallos := 0
var escena: Node3D
var cam: Camera3D
var naira: Node3D
var anim: AnimationPlayer
var datos: Dictionary


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a == "solo_comprobar":
			solo_comprobar = true
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_naira")
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = TAM
	_correr.call_deferred()


func _fallo(texto: String) -> void:
	print("FALLO: ", texto)
	fallos += 1


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


func _buscar(n: Node, clase: String) -> Node:
	if n.is_class(clase):
		return n
	for h in n.get_children():
		var r := _buscar(h, clase)
		if r:
			return r
	return null


func _mallas(n: Node, lista: Array) -> Array:
	if n is MeshInstance3D:
		lista.append(n)
	for h in n.get_children():
		_mallas(h, lista)
	return lista


# ---------------------------------------------------------------- comprobaciones

func _cargar_naira() -> Node3D:
	if not ResourceLoader.exists(RUTA):
		_fallo("no existe " + RUTA + " (¿falta importar?)")
		return null
	var ps: PackedScene = load(RUTA)
	var n: Node3D = ps.instantiate()
	n.name = "Naira"
	return n


func _comprobar() -> void:
	var f := FileAccess.open(RUTA_DATOS, FileAccess.READ)
	if f == null:
		_fallo("no se puede leer " + RUTA_DATOS)
		return
	datos = JSON.parse_string(f.get_as_text())
	if not datos.get("PROVISIONAL", false):
		_fallo("el JSON no marca el modelo como PROVISIONAL")
	naira = _cargar_naira()
	if naira == null:
		return
	root.add_child(naira)
	await _esperar(2)
	anim = _buscar(naira, "AnimationPlayer")
	var esq: Skeleton3D = _buscar(naira, "Skeleton3D")
	if anim == null:
		_fallo("sin AnimationPlayer")
		return
	if esq == null:
		_fallo("sin Skeleton3D")
	else:
		var nombres := []
		for i in esq.get_bone_count():
			nombres.append(esq.get_bone_name(i))
		print("huesos: ", esq.get_bone_count(), " ", nombres)
		# «neutral_bone» lo añade el exportador glTF cuando hay vértices sin peso: no debe aparecer
		if "neutral_bone" in nombres:
			_fallo("hay vértices sin peso (el GLB trae «neutral_bone»)")
		if esq.get_bone_count() != int(datos["huesos"]):
			_fallo("huesos: %d, se esperaban %d" % [esq.get_bone_count(), int(datos["huesos"])])
		if esq.find_bone("astrolabio") < 0:
			_fallo("falta el hueso del astrolabio")
	for clip in datos["clips"]:
		var d: Dictionary = datos["clips"][clip]
		if not anim.has_animation(clip):
			_fallo("falta el clip " + clip)
			continue
		var a: Animation = anim.get_animation(clip)
		var dif: float = abs(a.length - float(d["duracion"]))
		print("clip %-15s %.3f s (esperado %.3f)%s" % [clip, a.length, float(d["duracion"]),
				("  impacto %.3f s" % float(d["impacto"])) if d.has("impacto") else ""])
		if dif > 1.0 / 30.0 + 0.001:
			_fallo("%s dura %.3f s y debería durar %.3f s" % [clip, a.length, float(d["duracion"])])
		if d.has("impacto") and float(d["impacto"]) >= a.length:
			_fallo("%s: el impacto cae fuera del clip" % clip)
		if clip in BUCLES:
			a.loop_mode = Animation.LOOP_LINEAR
	# altura en reposo y materiales
	anim.play("reposo")
	anim.seek(0.0, true)
	await _esperar(2)
	var caja := AABB()
	var primera := true
	var mats := 0
	for m in _mallas(naira, []):
		var mi: MeshInstance3D = m
		var c: AABB = mi.global_transform * mi.mesh.get_aabb()
		caja = c if primera else caja.merge(c)
		primera = false
		mats += mi.mesh.get_surface_count()
	print("altura (malla en reposo): %.3f m · superficies: %d" % [caja.size.y, mats])
	if abs(caja.size.y - float(datos["altura_m"])) > 0.03:
		_fallo("altura %.3f m, esperada %.2f" % [caja.size.y, float(datos["altura_m"])])
	if mats > 2:
		_fallo("%d superficies (materiales): se esperaban 2 como mucho" % mats)


# ---------------------------------------------------------------- escena de capturas

func _montar_escena() -> void:
	escena = Node3D.new()
	root.add_child(escena)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.72, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.80, 0.82, 0.90)
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	escena.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(1.0, 0.95, 0.86)
	sol.light_energy = 1.0
	sol.shadow_enabled = true
	sol.rotation_degrees = Vector3(-50, 30, 0)
	escena.add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.42, 0.55, 0.30)
	ms.roughness = 0.95
	suelo.material_override = ms
	escena.add_child(suelo)
	cam = Camera3D.new()
	escena.add_child(cam)
	cam.current = true


func _heroe(script: String, pos: Vector3, escala := 1.0, ruta := "") -> Node3D:
	var h: Node3D = load(script).new()
	if ruta != "":
		h.ruta_modelo = ruta
	h.position = pos
	h.scale = Vector3.ONE * escala
	escena.add_child(h)
	return h


func _cam_exploracion(foco: Vector3, distancia := 20.0) -> void:
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 38.0
	var ang := deg_to_rad(45.0)
	var ojo := foco + Vector3(0, 0.9, 0)
	cam.global_position = ojo + Vector3(0, 0, 1) * cos(ang) * distancia + Vector3.UP * sin(ang) * distancia
	cam.look_at(ojo, Vector3.UP)


func _cam_combate(x: float, centro_y := 0.9, alto := 2.6) -> void:
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = alto
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(x + 2.2, centro_y + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(x, centro_y, 0))


func _pose(clip: String, t: float) -> void:
	if not anim.has_animation(clip):
		_fallo("falta el clip " + clip)
		return
	anim.play(clip, 0.0)
	anim.seek(t, true)
	anim.pause()


func _capturas() -> void:
	_montar_escena()
	naira.get_parent().remove_child(naira)
	escena.add_child(naira)
	naira.position = Vector3(0, 0, 0)
	naira.rotation.y = 0.35
	_heroe("res://kael_3d.gd", Vector3(-3.0, 0, -0.4), 1.0, "res://kael.fbx")
	_heroe("res://maga_3d.gd", Vector3(-2.0, 0, -0.4), 0.6 / 0.67)
	_heroe("res://garon_3d.gd", Vector3(-1.0, 0, -0.4))
	anim.play("reposo")
	await _esperar(20)
	_cam_exploracion(Vector3(-1.2, 0, 0), 20.0)
	await _foto("n00_exploracion_20m")
	_cam_exploracion(Vector3(-1.2, 0, 0), 9.0)
	await _foto("n01_exploracion_9m")
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 30
	cam.look_at_from_position(Vector3(-1.0, 1.4, 5.0), Vector3(-1.4, 0.85, 0.0))
	await _foto("n02_grupo_de_cerca")
	cam.look_at_from_position(Vector3(0.5, 1.45, 1.9), Vector3(0.0, 1.25, 0.0))
	await _foto("n03_cara")
	_hoja("naira_grupo", 2)
	# cada clip en su instante clave, con la cámara del combate
	var tomas := [["reposo", 0.0], ["reposo", 1.9], ["caminar", 0.25], ["correr", 0.15], ["ataque", 0.27],
		["ataque", 0.40], ["recibir_golpe", 0.12], ["victoria", 1.99], ["derrota", 0.66], ["derrota", 1.59],
		["lanzar_hechizo", 0.63], ["lanzar_hechizo", 0.867], ["concentracion", 0.33], ["concentracion", 1.0],
		["magia_poderosa", 1.3], ["magia_poderosa", 1.70]]
	for t in tomas:
		_pose(t[0], t[1])
		_cam_combate(0.0, 0.95, 2.9)
		await _esperar(2)
		await _foto("c_%s_%02d" % [t[0], int(round(t[1] * 30))])
	_hoja("naira_clips", 4)
	for clip in ["lanzar_hechizo", "magia_poderosa"]:
		var largo: float = anim.get_animation(clip).length
		for i in 12:
			_pose(clip, largo * i / 11.0)
			await _esperar(1)
			await _foto("s_%s_%02d" % [clip, i])
		_hoja("naira_secuencia_" + clip, 6, 0.34)
	# cadena con mezclas, en tiempo real (como reproduce el juego): 0,2 s de mezcla entre clips
	var cadena := [["reposo", 0.8], ["ataque", 1.2], ["reposo", 0.6], ["recibir_golpe", 0.8], ["reposo", 0.5],
		["caminar", 1.0], ["correr", 0.9], ["reposo", 0.8]]
	var k := 0
	for paso in cadena:
		anim.play(paso[0], 0.2)
		var fin := Time.get_ticks_msec() + int(paso[1] * 1000)
		while Time.get_ticks_msec() < fin:
			await _esperar(4)
			if k < 36:
				await _foto("m%02d_%s" % [k, paso[0]])
			k += 1
	_hoja("naira_cadena_mezclas", 6, 0.34)


func _correr() -> void:
	await _comprobar()
	if naira != null and anim != null and not solo_comprobar:
		await _capturas()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
