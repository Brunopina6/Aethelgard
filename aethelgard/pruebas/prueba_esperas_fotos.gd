extends SceneTree
# Capturas de las esperas de exploración (personalidad de los héroes, 09/11), con ventana:
#   --script res://pruebas/prueba_esperas_fotos.gd --fixed-fps 30 -- fotos=<carpeta> [heroe=Kael] [clip=espera_flor]
# Un estudio con suelo, la luz de pruebas/herramientas/foto_3d.gd y cada héroe con su arma, a su tamaño de exploración.
# Por cada espera guarda fotogramas a lo largo del clip desde dos cámaras (3/4 de frente y de lado):
#   <héroe>_<clip>_<vista>_<nn>.png ; y el reposo, <héroe>_reposo_<vista>.png (el «antes»: quieto sin esperas).
# Con «video» guarda además todos los fotogramas de la vista 3/4 (para montar un vídeo).

const HEROES := {"Kael": "res://kael_3d.gd", "Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd"}
const ESCALA := {"Kael": 1.0, "Lya": 0.6 / 0.67, "Garon": 1.0}
const MOMENTOS := [0.0, 0.14, 0.28, 0.42, 0.56, 0.7, 0.84, 1.0]
const VISTAS := {"34": Vector3(-1.5, 1.3, 2.6), "lado": Vector3(-2.9, 1.05, 0.2)}

var args := {}
var cam: Camera3D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var i := a.find("=")
		args[a.substr(0, i) if i > 0 else a] = a.substr(i + 1) if i > 0 else "si"
	DisplayServer.window_set_size(Vector2i(720, 900))
	DirAccess.make_dir_recursive_absolute(args.get("fotos", "user://esperas_fotos"))
	_estudio()
	_fotos.call_deferred()


func _estudio() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.66, 0.78)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1.0, 0.86, 0.78)
	env.environment.ambient_light_energy = 0.38
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	root.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, -35, 0)
	luz.light_color = Color("FFE2B0")
	luz.light_energy = 0.75
	luz.shadow_enabled = true
	root.add_child(luz)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	suelo.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.3, 0.14)
	mat.roughness = 1.0
	suelo.material_override = mat
	root.add_child(suelo)
	cam = Camera3D.new()
	cam.fov = 32.0
	root.add_child(cam)
	cam.current = true


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(ruta: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ruta)


func _vista(nombre: String, alto: float) -> void:
	var p: Vector3 = VISTAS[nombre]
	cam.look_at_from_position(p * Vector3(1, alto, 1) + Vector3(0, 0, 0), Vector3(0, 0.85 * alto, 0))


func _fotos() -> void:
	var dir: String = args.get("fotos", "user://esperas_fotos")
	for h in HEROES:
		if args.has("heroe") and args["heroe"] != h:
			continue
		var c = load(HEROES[h]).new()
		c.name = h
		root.add_child(c)
		c.scale = Vector3.ONE * ESCALA[h]
		await _esperar(10)
		c.activar_esperas()
		c.esperas.pausa = true
		c.mirar(Vector3(0, 0, 1), 0.0)
		if h == "Garon":
			var lib: AnimationLibrary = c.anim.get_animation_library("")
			if not lib.has_animation("Calma"):
				var calma: Animation = c._guardia_viva("Juicio")
				calma.loop_mode = Animation.LOOP_LINEAR
				lib.add_animation("Calma", calma)
			c.play("Calma", 0.0)
		else:
			c.reposo()
		await _esperar(30)
		var alto: float = ESCALA[h]
		for v in VISTAS:
			_vista(v, alto)
			await _esperar(2)
			await _foto(dir.path_join("%s_reposo_%s.png" % [h.to_lower(), v]))
		if args.has("porte"):
			await _porte(c, h, dir)
		for clip in c.esperas.clips:
			if (args.has("clip") and args["clip"] != clip) or args.has("solo_porte"):
				continue
			var a: Animation = c.anim.get_animation("esperas/" + clip)
			for v in VISTAS:
				_vista(v, alto)
				c.esperas.forzar(clip)
				var t := 0.0
				var k := 0
				var f := 0
				while c.esperas.actual == clip or t < 0.1:
					if k < MOMENTOS.size() and t >= MOMENTOS[k] * (a.length - 0.05):
						await _foto(dir.path_join("%s_%s_%s_%02d.png" % [h.to_lower(), clip, v, k]))
						k += 1
					elif args.has("video") and v == "34":
						await _foto(dir.path_join("video_%s_%s_%04d.png" % [h.to_lower(), clip, f]))
					else:
						await process_frame
					f += 1
					t += 1.0 / 30.0
					if t > a.length + 2.0:
						break
				await _esperar(25)
				print("FOTOS %s %s %s: %d" % [h, clip, v, k])
		c.queue_free()
		await _esperar(4)
	quit(0)


# Con «porte»: el porte de cada héroe al andar y al correr (maga_3d.gd, ESTILOS), de lado y en las mismas fases del
# clip, sin él (antes) y con él (después): <héroe>_porte_<andar|correr>_<antes|despues>_<n>.png
func _porte(c, h: String, dir: String) -> void:
	_vista("lado", ESCALA[h])
	for como in ["andar", "correr"]:
		var v := 1.3 if como == "andar" else 4.2
		for cual in ["antes", "despues"]:
			c.marcha(v * ESCALA[h])
			await _esperar(20)
			if cual == "antes":
				c.gestos.quitar("porte_" + como, 0.0)
			else:
				c.gestos.poner("porte_" + como, 1.0, 0.0)
			var largo: float = c.anim.current_animation_length
			for k in 4:
				c.anim.seek(largo * k / 4.0, true)
				c.anim.speed_scale = 0.0
				await _esperar(3)
				await _foto(dir.path_join("%s_porte_%s_%s_%d.png" % [h.to_lower(), como, cual, k]))
			c.anim.speed_scale = 1.0
		c.parar_marcha()
		await _esperar(15)
