extends SceneTree
# V12 (14/11, tarde): capturas del IRIS de Nix (piloto FBX) CON y SIN su emisión, en la misma pasada, para comparar.
# Solo capturas: no cambia nada del juego ni guarda partidas. Interruptores de sesión «nix_v12» y «nix_fbx».
#   --fixed-fps 30 -s res://pruebas/fotos_nix_iris.gd -- salida=<carpeta> [brillo=<cerca>,<lejos>] [nitidez=<0-1>]
# Dos luces: la del combate (como fotos_nix_revision.gd modo=estudio) y un anochecer oscuro con resplandor (glow con
# umbral 0,85, el más bajo de las zonas: así se ve si «brilla como un faro»). Tres cámaras: la cara de cerca (diálogo),
# la del combate (ortográfica, 12° desde arriba, Nix ≈ 205 px de alto como en combate) y una de exploración
# (perspectiva, 10 m, 35° desde arriba). Cada foto, entera y con los ojos ampliados (recorte × 8, sin suavizar).

const ESC := 0.56 / 0.67
const SHADER_V2 := "res://personajes/heroes_v2/heroe_v2.gdshader"

var salida := ""
var brillo := Vector2(-1, -1)
var nitidez := -1.0
var mundo: Node3D
var cam: Camera3D
var env: Environment
var luz: DirectionalLight3D
var rel: DirectionalLight3D
var nix: Node3D
var mat: ShaderMaterial
var shader_iris: Shader
var n_fotos := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("brillo="):
			var p := a.substr(7).split(",")
			brillo = Vector2(float(p[0]), float(p[1]))
		elif a.begins_with("nitidez="):
			nitidez = float(a.substr(8))
	if salida == "":
		print("FALLO: falta salida=")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	Engine.set_meta("nix_v12", true)
	Engine.set_meta("nix_fbx", true)
	_correr.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	_mundo()
	nix = load("res://personajes/nix/nix_3d.gd").new()
	nix.name = "Nix"
	mundo.add_child(nix)
	nix.scale = Vector3.ONE * ESC
	await _frames(20)
	nix.activar_esperas(true)
	if nix.get("esperas") != null:
		nix.esperas.pausa = true
	nix.reposo()
	nix.mirar(Vector3(0, 0, 1), 0.0)
	await _frames(40)
	nix.anim.pause()                                   # la misma pose en todas las fotos
	var mi := nix.find_child("cuerpo_nix", true, false) as MeshInstance3D
	mat = mi.get_surface_override_material(0) as ShaderMaterial
	shader_iris = mat.shader
	print("SHADER del cuerpo: ", shader_iris.resource_path if shader_iris != null else "ninguno")
	if brillo.x >= 0.0:
		mat.set_shader_parameter("iris_brillo", brillo)
	if nitidez >= 0.0:
		mat.set_shader_parameter("iris_nitidez", nitidez)
	var ojo := _ojos()
	for luz_n in ["combate", "anochecer"]:
		_luz(luz_n)
		for cam_n in ["cara", "combate", "exploracion"]:
			_camara(cam_n, ojo)
			for con in [true, false]:
				mat.shader = shader_iris if con else load(SHADER_V2)
				await _frames(3)
				await _foto("%s_%s_%s" % [luz_n, cam_n, "con" if con else "sin"], ojo, cam_n)
	mat.shader = shader_iris
	for k in ["nix_v12", "nix_fbx"]:
		Engine.remove_meta(k)
	print("FOTOS: %d en %s" % [n_fotos, salida])
	quit(0)


func _mundo() -> void:
	mundo = Node3D.new()
	root.add_child(mundo)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	luz = DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, -40, 0)
	mundo.add_child(luz)
	rel = DirectionalLight3D.new()
	rel.rotation_degrees = Vector3(-15, 140, 0)
	mundo.add_child(rel)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	suelo.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.13, 0.12)
	suelo.material_override = m
	mundo.add_child(suelo)
	cam = Camera3D.new()
	mundo.add_child(cam)
	cam.current = true


func _luz(n: String) -> void:
	if n == "combate":            # combate.gd: ambiente cálido 0,6, principal FFE2B0 1,3, relleno 7FA0D8 0,3, sin glow
		env.background_color = Color(0.22, 0.24, 0.28)
		env.ambient_light_color = Color(1.0, 0.86, 0.78)
		env.ambient_light_energy = 0.6
		luz.light_color = Color("FFE2B0"); luz.light_energy = 1.3
		rel.light_color = Color("7FA0D8"); rel.light_energy = 0.3
		env.glow_enabled = false
	else:                         # anochecer oscuro (como Oakhaven) con resplandor de umbral bajo
		env.background_color = Color(0.06, 0.07, 0.11)
		env.ambient_light_color = Color(0.45, 0.5, 0.72)
		env.ambient_light_energy = 0.3
		luz.light_color = Color("FFB070"); luz.light_energy = 0.35
		rel.light_color = Color("7FA0D8"); rel.light_energy = 0.15
		env.glow_enabled = true
		env.glow_intensity = 1.0
		env.glow_bloom = 0.1
		env.glow_hdr_threshold = 0.85


func _ojos() -> Vector3:
	var sk: Skeleton3D = nix.skel
	for i in sk.get_bone_count():
		if sk.get_bone_name(i).ends_with("Head"):
			return sk.global_transform * sk.get_bone_global_pose(i).origin + Vector3(0, 0.07, 0) * ESC
	return Vector3(0, 1.4, 0)


func _camara(n: String, ojo: Vector3) -> void:
	match n:
		"cara":
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE
			cam.fov = 30.0
			cam.look_at_from_position(ojo + Vector3(0, 0.02, 0.75), ojo, Vector3.UP)
		"combate":
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.size = 5.3                                   # Nix ≈ 205 px de alto en 720, como en el combate
			var ang := deg_to_rad(12.0)
			var c := Vector3(0, 0.9, 0)
			cam.look_at_from_position(c + Vector3(0, sin(ang) * 6.0, cos(ang) * 6.0), c, Vector3.UP)
		"exploracion":
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE
			cam.fov = 35.0
			var ang2 := deg_to_rad(35.0)
			var c2 := Vector3(0, 0.9, 0)
			cam.look_at_from_position(c2 + Vector3(0, sin(ang2) * 10.0, cos(ang2) * 10.0), c2, Vector3.UP)


func _foto(nombre: String, ojo: Vector3, cam_n: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(salida.path_join(nombre + ".png"))
	n_fotos += 1
	# recorte de los ojos, ampliado sin suavizar
	var p := cam.unproject_position(ojo)
	var tam := Vector2i(220, 120) if cam_n == "cara" else Vector2i(40, 24)
	var x := clampi(int(p.x) - tam.x / 2, 0, img.get_width() - tam.x)
	var y := clampi(int(p.y) - tam.y / 2, 0, img.get_height() - tam.y)
	var r := img.get_region(Rect2i(x, y, tam.x, tam.y))
	var f := 3 if cam_n == "cara" else 12
	r.resize(tam.x * f, tam.y * f, Image.INTERPOLATE_NEAREST)
	r.save_png(salida.path_join(nombre + "_ojos.png"))
