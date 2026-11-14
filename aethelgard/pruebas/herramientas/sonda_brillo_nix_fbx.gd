extends SceneTree
# Sonda con ventana (piloto Nix FBX, 14/11): el cuerpo sale muy claro en Godot. Misma luz que fotos_nix_fbx.gd, tres
# figuras: Nix FBX tal cual, Nix FBX sin el mapa normal y Lya v2 (referencia del mismo material de los héroes v2).
# «-- salida=<carpeta>».

var salida := ""
var a: Node3D
var b: Node3D
var c: Node3D
var cam: Camera3D
var frames := 0


func _initialize() -> void:
	for x in OS.get_cmdline_user_args():
		if x.begins_with("salida="):
			salida = x.substr(7)
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
	raiz.add_child(sol)
	Engine.set_meta("nix_fbx", true)
	a = load("res://personajes/nix/nix_3d.gd").new()
	b = load("res://personajes/nix/nix_3d.gd").new()
	Engine.remove_meta("nix_fbx")
	raiz.add_child(a)
	raiz.add_child(b)
	a.position = Vector3(-0.9, 0, 0)
	Engine.set_meta("heroes_version", "v2")
	c = load("res://personajes/heroes_v2/lya_v2_3d.gd").new()
	Engine.remove_meta("heroes_version")
	raiz.add_child(c)
	c.position = Vector3(0.9, 0, 0)
	cam = Camera3D.new()
	cam.fov = 30.0
	raiz.add_child(cam)
	cam.current = true
	cam.position = Vector3(0, 1.0, 6.0)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)


func _process(_d: float) -> bool:
	frames += 1
	if frames == 20:
		for mi in b.find_children("*", "MeshInstance3D", true, false):
			var m = mi.get_surface_override_material(0)
			if m is ShaderMaterial:
				m.set_shader_parameter("tiene_normal", false)
	if frames == 40:
		var img := root.get_texture().get_image()
		img.save_png(salida + "/brillo_nixfbx_sinnormal_lya.png")
		quit(0)
		return true
	return false
