extends SceneTree
# Prueba de shaders/water.gdshader: suelo de colores debajo, agua encima, luz y cámara en tres cuartos.
# Saca dos fotos: con refracción y sin ella. Uso: --script prueba_agua3d.gd -- <carpeta>

var frames := 0
var salida := ""
var mat: ShaderMaterial


func _ruido(semilla: int, normal: bool) -> NoiseTexture2D:
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.as_normal_map = normal
	t.bump_strength = 6.0
	var n := FastNoiseLite.new()
	n.seed = semilla
	n.frequency = 0.02 if not normal else 0.04
	t.noise = n
	return t


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	var raiz := Node3D.new()
	root.add_child(raiz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.65, 0.75)
	raiz.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, -40, 0)
	luz.light_color = Color("FFE2B0")
	raiz.add_child(luz)
	# fondo: losas de colores bajo el agua para ver la refracción
	for i in 6:
		for j in 6:
			var c := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(3.0, 0.5, 3.0)
			c.mesh = b
			var m := StandardMaterial3D.new()
			m.albedo_color = Color.from_hsv(float(i * 6 + j) / 36.0, 0.5, 0.8)
			c.material_override = m
			c.position = Vector3(i * 3.0 - 7.5, -1.2, j * 3.0 - 7.5)
			raiz.add_child(c)
	var agua := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(18, 18)
	plano.subdivide_width = 64
	plano.subdivide_depth = 64
	agua.mesh = plano
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader")
	mat.set_shader_parameter("wave_noise", _ruido(1, false))
	mat.set_shader_parameter("normal_1", _ruido(2, true))
	mat.set_shader_parameter("normal_2", _ruido(3, true))
	mat.set_shader_parameter("wave_size", 0.6)
	mat.set_shader_parameter("texture_scale", 0.08)
	agua.material_override = mat
	raiz.add_child(agua)
	var cam := Camera3D.new()
	raiz.add_child(cam)
	cam.look_at_from_position(Vector3(0, 9, 13), Vector3(0, 0, 0))
	cam.current = true


func _process(_d: float) -> bool:
	frames += 1
	if frames == 30:
		root.get_viewport().get_texture().get_image().save_png(salida + "/con_refraccion.png")
		mat.set_shader_parameter("enable_refraction", false)
	if frames == 40:
		root.get_viewport().get_texture().get_image().save_png(salida + "/sin_refraccion.png")
		return true
	return false
