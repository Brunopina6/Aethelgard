extends SceneTree
# La espada sola con cuatro materiales: completo, sin brillo, sin metal, solo color.
# Uso: --script prueba_material.gd -- <res://base sin extensión> <salida.png>

var f := 0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var base: String = a[0]
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.4, 0.5)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1.0, 0.86, 0.78)
	env.environment.ambient_light_energy = 0.6
	root.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, -40, 0)
	root.add_child(luz)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.3
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 0.4, 5), Vector3(0, 0.4, 0))
	var malla: Mesh = load(base + ".obj")
	var nuevo = load("res://material_arma.gd").de_base(base)
	for k in 4:
		var mi := MeshInstance3D.new()
		mi.mesh = malla
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load(base + "_color.jpg")
		if k < 3:
			mat.normal_enabled = true
			mat.normal_texture = load(base + "_normal.png")
			mat.roughness = 1.0
			mat.roughness_texture = load(base + "_rugosidad.png")
		if k == 0 or k == 1:
			mat.metallic = 1.0
			mat.metallic_texture = load(base + "_metal.png")
		if k == 0 or k == 2:
			mat.emission_enabled = true
			mat.emission_texture = load(base + "_brillo.png")
			mat.emission = Color(1, 1, 1)
		mi.material_override = nuevo if k == 0 else mat
		mi.position = Vector3(-0.75 + k * 0.5, 0, 0)
		root.add_child(mi)


func _process(_d: float) -> bool:
	f += 1
	if f == 8:
		root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[1])
		return true
	return false
