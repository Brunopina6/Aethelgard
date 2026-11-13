extends SceneTree
# V12 (13/11): fotos de Nix (PROTOTIPO) en Godot, con ventana: de cuerpo entero y de cerca con sus ocho expresiones,
# en guardia, y los tres LOD a la distancia en que entran. Con la luz de un escenario sencillo (sol cálido y cielo),
# no la del combate. «-- salida=<carpeta>». No toca la partida ni el interruptor.

var salida := ""
var nix: Node3D
var cam: Camera3D
var frames := 0
var paso := 0
var fotos: Array = []
const EXPR := ["normal", "decidido", "sonrisa", "sorpresa", "entrecerrados", "cerrados", "dolor", "grito"]


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
	nix = load("res://personajes/nix/nix_3d.gd").new()
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


func _process(_d: float) -> bool:
	frames += 1
	if frames < 20:
		return false
	if frames % 12 != 0:
		return false
	match paso:
		0:
			nix.mirar(Vector3(0, 0, 1), 0.0)
			_mirar(Vector3(0.0, 1.0, 5.2), Vector3(0, 0.95, 0))
		1:
			_foto("01_cuerpo_guardia")
			nix.activar_esperas(true)
		2:
			_foto("02_cuerpo_reposo")
			_mirar(Vector3(0.25, 1.62, 1.55), Vector3(0, 1.5, 0))
		_:
			var i := paso - 3
			if i < EXPR.size() * 2:
				if i % 2 == 0:
					nix.expresion(EXPR[i / 2])
				else:
					_foto("1%d_cara_%s" % [i / 2, EXPR[i / 2]])
			elif i == EXPR.size() * 2:
				nix.expresion("normal")
				_mirar(Vector3(0.0, 1.0, 12.0), Vector3(0, 0.9, 0))
			elif i == EXPR.size() * 2 + 1:
				_foto("30_lod1_12m")
				_mirar(Vector3(0.0, 1.0, 22.0), Vector3(0, 0.9, 0))
			elif i == EXPR.size() * 2 + 2:
				_foto("31_lod2_22m")
				_mirar(Vector3(0.0, 1.0, 6.0), Vector3(0, 0.9, 0))
			else:
				_foto("29_lod0_6m")
				print("FOTOS: %d en %s" % [fotos.size(), salida])
				quit(0)
				return true
	paso += 1
	return false
