extends SceneTree
# Foto de un personaje 3D (script que hereda de maga_3d.gd) en varias poses.
# Uso: --script foto_3d.gd -- <res://script.gd> <carpeta> <metodo1,metodo2...> [alto_vista]

var p
var frames := 0
var salida := ""
var metodos: PackedStringArray
var i := 0
var cam: Camera3D


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	salida = a[1]
	metodos = a[2].split(",")
	var vista := float(a[3]) if a.size() > 3 else 2.6
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
	luz.light_color = Color("FFE2B0")
	root.add_child(luz)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = vista
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, vista * 0.45 + 1.2, 6), Vector3(0, vista * 0.45, 0))
	p = load(a[0]).new()
	root.add_child(p)


func _process(_d: float) -> bool:
	frames += 1
	if frames == 20:
		root.get_viewport().get_texture().get_image().save_png("%s/0_reposo.png" % salida)
	if frames >= 25 and (frames - 25) % 40 == 0 and i < metodos.size():
		var m := metodos[i]
		if m.begins_with("atacar") or m == "golpe_fuerte":
			p.call(m, func(): pass)
		else:
			p.call(m)
		set_meta("m", m)
	if frames >= 25 and (frames - 25) % 40 == 28 and i < metodos.size():
		root.get_viewport().get_texture().get_image().save_png("%s/%d_%s.png" % [salida, i + 1, get_meta("m")])
		i += 1
	return i >= metodos.size() and frames > 30
