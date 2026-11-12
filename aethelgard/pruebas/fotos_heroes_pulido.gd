extends SceneTree
# Héroes v2, pulido (V12, 13/11): capturas ANTES (originales) y DESPUÉS (v2) comparables y vídeos, con ventana y datos
# aislados (ejecutar_pruebas.ps1). No escribe partidas reales: el combate de pruebas no guarda y las regiones usan
# «archivo_partida_prueba» en user:// (aislado).
#   godot --path aethelgard --script res://pruebas/fotos_heroes_pulido.gd --fixed-fps 30 -- salida=<carpeta> modo=<modo>
#         [perfil=medio] [3d sin_prologo]
# Modos:
#   combate    combates de verdad (combate.tscn) SIN «auto» (todos en guardia, el mismo instante): Kael, Lya y Garon
#              solos y los tres juntos en Pastos (llanura), y los tres en el Gran Bosque (bosque), la Garganta (montana),
#              Oakhaven (ciudad) y el Mar de Cristal (desierto). Para cada uno, originales y v2 con la misma semilla.
#              combate_<fondo>_<grupo>_<antes|despues>.png
#   regiones   las cinco regiones 3D con los tres en el grupo, con la cámara del juego (la distancia por defecto) y de
#              cerca (9 m, los tres mirando a la cámara), mismo perfil y mismos fotogramas: region_<r>_<lejos|cerca>_<antes|despues>.png
#   video      estudio con la cámara y la luz del combate (_crear_rig_3d), original a la izquierda y v2 a la derecha a
#              la vez: guardia, ataque, magia, golpe recibido, victoria y reposo de exploración de cada uno. Para grabar con
#              --write-movie <archivo>.avi (un vídeo por héroe con heroes=Kael, etc.).
# El interruptor se cambia con Engine.set_meta("heroes_v2", …), lo mismo que hace la opción de Ajustes.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const ORIGINAL := {"Kael": ["res://kael_3d.gd", "res://kael.fbx"],
	"Lya": ["res://maga_3d.gd", "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"],
	"Garon": ["res://garon_3d.gd", "res://garon.fbx"]}
const REGIONES := {"pastos": "res://zonas3d/pastos_verdes_3d.tscn", "garganta": "res://zonas3d/garganta_3d.tscn",
	"oakhaven": "res://zonas3d/oakhaven_3d.tscn", "gran_bosque": "res://zonas3d/gran_bosque_3d.tscn",
	"mar_cristal": "res://zonas3d/mar_cristal_3d.tscn"}
const COMBATES := [["llanura", ["Kael"]], ["llanura", ["Lya"]], ["llanura", ["Garon"]], ["llanura", ["Kael", "Lya", "Garon"]],
	["bosque", ["Kael", "Lya", "Garon"]], ["montana", ["Kael", "Lya", "Garon"]], ["ciudad", ["Kael", "Lya", "Garon"]],
	["desierto", ["Kael", "Lya", "Garon"]]]

var salida := "user://fotos_heroes_pulido"
var modo := "combate"
var perfil := "medio"
var heroes := ["Kael", "Lya", "Garon"]
var regiones: Array = REGIONES.keys()
var n_fotos := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("salida="):
			salida = arg.substr(7)
		elif arg.begins_with("modo="):
			modo = arg.substr(5)
		elif arg.begins_with("perfil="):
			perfil = arg.substr(7)
		elif arg.begins_with("heroes="):
			heroes = Array(arg.substr(7).split(","))
		elif arg.begins_with("regiones="):
			regiones = Array(arg.substr(9).split(","))
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = Vector2i(1280, 720)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	Engine.set_meta("archivo_partida_prueba", "user://fotos_heroes_pulido.save")
	_correr.call_deferred()


# «modo=combate,regiones»: varios seguidos.
func _correr() -> void:
	for m in modo.split(","):
		match m:
			"combate": await _combates()
			"regiones": await _regiones()
			"video": await _video()
			_:
				print("FALLO: modo desconocido ", m)
				quit(1)
				return
	_fin()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(salida.path_join(nombre + ".png"))
	n_fotos += 1


func _fin() -> void:
	Engine.remove_meta("heroes_v2")
	if FileAccess.file_exists("user://fotos_heroes_pulido.save"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://fotos_heroes_pulido.save"))
	print("FOTOS: %d en %s" % [n_fotos, salida])
	quit(0)


# ---------------------------------------------------------------- combates de verdad
func _combates() -> void:
	for c in COMBATES:
		for v2 in [false, true]:
			Engine.set_meta("heroes_v2", v2)
			Engine.set_meta("grupo_activo", c[1])
			Engine.set_meta("fondo_combate", c[0])
			Engine.set_meta("grupo_combate", 3)
			seed(1234)
			var cb: Node = load("res://combate.tscn").instantiate()
			root.add_child(cb)
			await _frames(90)                                      # 3 s: los héroes en guardia, sin órdenes
			var nombre := "combate_%s_%s_%s" % [c[0], "_".join(c[1]).to_lower(), "despues" if v2 else "antes"]
			var cargados := []
			for o in cb.get("heroes"):
				var m = o.get("p3d")
				if m != null:
					cargados.append("%s:%s" % [o["nombre"], String(m.get("ruta_modelo")).get_file()])
			print(nombre, " · ", ", ".join(cargados))
			await _foto(nombre)
			cb.queue_free()
			await _frames(6)
	Engine.remove_meta("grupo_activo")
	Engine.remove_meta("fondo_combate")


# ---------------------------------------------------------------- regiones 3D
func _regiones() -> void:
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})
	for r in regiones:
		for v2 in [false, true]:
			Engine.set_meta("heroes_v2", v2)
			Engine.set_meta("pos_3d_ok", false)
			change_scene_to_file(REGIONES[r])
			var limite := Time.get_ticks_msec() + 120000
			while Time.get_ticks_msec() < limite and (current_scene == null or current_scene.scene_file_path != REGIONES[r] or current_scene.get("kael") == null):
				await process_frame
			var v = current_scene
			if v == null or v.get("kael") == null:
				print("FALLO: no cargó ", r)
				continue
			v.set("pasos", -100000)                               # sin encuentros
			var g0: Array = v.grupo.nodos() if v.get("grupo") != null else []
			for n in [v.kael] + g0:                               # sin esperas: la misma pose antes y después
				if n != null and n.get("esperas") != null:
					n.esperas.pausa = true
			await _frames(150)                                    # 5 s: sin el rótulo de la región
			var etiqueta := "despues" if v2 else "antes"
			var g: Array = v.grupo.nodos() if v.get("grupo") != null else []
			print("%s %s: Kael %s (%s) · grupo %d" % [r, etiqueta, v.kael.global_position.snapped(Vector3.ONE * 0.1),
				String(v.kael.get("ruta_modelo")).get_file(), g.size()])
			await _foto("region_%s_lejos_%s" % [r, etiqueta])
			# de cerca, los tres mirando a la cámara (la misma distancia y los mismos fotogramas en antes y después)
			if v.get("_dist_jugador") != null:
				v.set("_dist_jugador", 9.0)
			v.set("distancia", 9.0)
			await _frames(40)
			var cam: Camera3D = root.get_viewport().get_camera_3d()
			for f in 30:                                          # cada fotograma: que ninguna espera los gire
				for n in [v.kael] + g:
					if n != null and n.has_method("mirar") and cam != null:
						var d: Vector3 = cam.global_position - n.global_position
						n.mirar(Vector3(d.x, 0, d.z), 0.0)
				await process_frame
			await _foto("region_%s_cerca_%s" % [r, etiqueta])
	Engine.remove_meta("calidad_proto")
	Engine.remove_meta("grupo_activo")
	Engine.remove_meta("hitos")


# ---------------------------------------------------------------- vídeo (estudio con la cámara del combate)
var mundo: Node3D
var cam3: Camera3D


func _estudio() -> void:
	mundo = Node3D.new()
	root.add_child(mundo)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.27)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.86, 0.78)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	var luz := DirectionalLight3D.new()
	luz.light_color = Color(1.0, 0.84, 0.62)
	luz.light_energy = 1.3
	luz.rotation_degrees = Vector3(-35, -40, 0)
	mundo.add_child(luz)
	var rel := DirectionalLight3D.new()
	rel.light_color = Color(0.55, 0.62, 1.0)
	rel.light_energy = 0.3
	rel.rotation_degrees = Vector3(-15, 140, 0)
	mundo.add_child(rel)
	cam3 = Camera3D.new()
	mundo.add_child(cam3)
	cam3.current = true
	cam3.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam3.size = 3.4
	var ang := deg_to_rad(12.0)
	cam3.look_at_from_position(Vector3(0, 1.2 + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, 1.2, 0))
	var capa := CanvasLayer.new()
	mundo.add_child(capa)
	for t in [["ORIGINAL", 330.0], ["V2 (PULIDO)", 870.0]]:
		var l := Label.new()
		l.text = t[0]
		l.position = Vector2(t[1], 24)
		l.add_theme_font_size_override("font_size", 26)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		l.add_theme_constant_override("outline_size", 6)
		capa.add_child(l)
	var rotulo := Label.new()
	rotulo.name = "Rotulo"
	rotulo.position = Vector2(24, 660)
	rotulo.add_theme_font_size_override("font_size", 24)
	rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	rotulo.add_theme_constant_override("outline_size", 6)
	capa.add_child(rotulo)


func _rotulo(t: String) -> void:
	(mundo.find_child("Rotulo", true, false) as Label).text = t


func _seg(t: float) -> void:
	await _frames(int(round(t * 30.0)))


func _video() -> void:
	_estudio()
	for h in heroes:
		var a: Node3D = load(ORIGINAL[h][0]).new()
		a.ruta_modelo = ORIGINAL[h][1]
		a.position = Vector3(-1.05, 0, 0)
		mundo.add_child(a)
		var b: Node3D = load(HeroesV2.SCRIPTS[ORIGINAL[h][0]]).new()
		b.ruta_modelo = ORIGINAL[h][1]
		b.position = Vector3(1.05, 0, 0)
		mundo.add_child(b)
		await _frames(8)
		var nada := func(): pass
		_rotulo("%s · guardia" % h)
		await _seg(1.5)
		_rotulo("%s · ataque" % h)
		if h == "Kael":
			a.ataque_salto(nada)
			b.ataque_salto(nada)
			await _seg(2.0)
		elif h == "Garon":
			a.atacar_juicio(nada)
			b.atacar_juicio(nada)
			await _seg(2.8)
		else:                                         # como el combate: preparar, 0,28 s, golpear, 0,45 s, fin
			a.preparar_golpe()
			b.preparar_golpe()
			await _seg(0.28)
			a.golpear()
			b.golpear()
			await _seg(0.45)
			a.fin_golpe()
			b.fin_golpe()
			await _seg(1.0)
		if h != "Garon":
			_rotulo("%s · magia" % h)
			a.lanzar_magia()
			b.lanzar_magia()
			await _seg(1.5)
			a.fin_magia()
			b.fin_magia()
			await _seg(0.8)
		_rotulo("%s · golpe recibido" % h)
		a.herida()
		b.herida()
		await _seg(1.6)
		_rotulo("%s · victoria" % h)
		a.victoria()
		b.victoria()
		await _seg(2.6)
		_rotulo("%s · reposo (exploración)" % h)
		for n in [a, b]:
			n.reposo()
			n.mirar(Vector3(0.3, 0, 1), 0.3)
			n.activar_esperas(true)
		await _seg(4.5)
		a.queue_free()
		b.queue_free()
		await _frames(4)
	mundo.queue_free()
