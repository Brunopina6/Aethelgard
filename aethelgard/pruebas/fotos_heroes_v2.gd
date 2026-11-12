extends SceneTree
# Héroes v2 (fase B, V12): capturas ANTES (modelo y script originales) y DESPUÉS (v2) lado a lado.
#   godot --path aethelgard --script res://pruebas/fotos_heroes_v2.gd -- salida=<carpeta> [heroes=Kael,Lya,Garon]
# Con ventana (necesita dibujar). No toca partidas: no carga el juego, solo los héroes en una escena propia.
#   - combate: la cámara de combate.gd (_crear_rig_3d: ortográfica, 12° desde arriba, luz dorada y relleno azul),
#     con los dos héroes mirando a los enemigos (FRENTE), en los mismos instantes de guardia, ataque, magia, golpe,
#     victoria y derribo;
#   - exploración: cámara en perspectiva como la de las regiones (alta, 3/4) y otra cercana, con reposo, andar,
#     hablar, saltar e interactuar (solo v2: el original no tiene esos clips);
#   - cara: un primer plano de cada expresión.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const LUZ_PRINCIPAL := Color(1.0, 0.84, 0.62)
const LUZ_RELLENO := Color(0.55, 0.62, 1.0)
const ORIGINAL := {"Kael": ["res://kael_3d.gd", "res://kael.fbx"],
	"Lya": ["res://maga_3d.gd", "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"],
	"Garon": ["res://garon_3d.gd", "res://garon.fbx"]}

var salida := "user://fotos_heroes_v2"
var heroes := ["Kael"]
var cam: Camera3D
var mundo: Node3D
var env: Environment
var n_foto := 0
var a: Node3D      # antes
var b: Node3D      # después


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("salida="):
			salida = arg.substr(7)
		elif arg.begins_with("heroes="):
			heroes = Array(arg.substr(7).split(","))
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = Vector2i(1280, 720)
	_principal.call_deferred()


func _principal() -> void:
	for h in heroes:
		if not ResourceLoader.exists(HeroesV2.GLB[h]):
			print("FALTA el GLB de ", h, " (", HeroesV2.GLB[h], "): se salta")
			continue
		await _combate(h)
		await _exploracion(h)
		await _caras(h)
	print("FOTOS: ", n_foto, " en ", salida)
	quit(0)


func _escena(perspectiva: bool) -> void:
	if mundo != null:
		mundo.queue_free()
		await process_frame
	mundo = Node3D.new()
	root.add_child(mundo)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.72, 0.82) if perspectiva else Color(0.2, 0.22, 0.27)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.86, 0.78) if not perspectiva else Color(0.75, 0.8, 0.9)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	var luz := DirectionalLight3D.new()
	luz.light_color = LUZ_PRINCIPAL
	luz.light_energy = 1.3
	luz.rotation_degrees = Vector3(-35, -40, 0)
	luz.shadow_enabled = perspectiva
	mundo.add_child(luz)
	var rel := DirectionalLight3D.new()
	rel.light_color = LUZ_RELLENO
	rel.light_energy = 0.3
	rel.rotation_degrees = Vector3(-15, 140, 0)
	mundo.add_child(rel)
	if perspectiva:
		var suelo := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(40, 40)
		suelo.mesh = pm
		var ms := StandardMaterial3D.new()
		ms.albedo_color = Color(0.42, 0.55, 0.3)
		suelo.material_override = ms
		mundo.add_child(suelo)
	cam = Camera3D.new()
	mundo.add_child(cam)
	cam.current = true


func _pareja(h: String, separacion: float) -> void:
	a = load(ORIGINAL[h][0]).new()
	a.ruta_modelo = ORIGINAL[h][1]
	a.position = Vector3(-separacion, 0, 0)
	mundo.add_child(a)
	b = load(HeroesV2.SCRIPTS[ORIGINAL[h][0]]).new()
	b.ruta_modelo = ORIGINAL[h][1]           # como lo crea el combate: el script v2 lo cambia por su GLB
	b.position = Vector3(separacion, 0, 0)
	mundo.add_child(b)
	for i in 6:
		await process_frame


func _foto(nombre: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	n_foto += 1
	img.save_png(salida.path_join("%02d_%s.png" % [n_foto, nombre]))


func _esperar(t: float) -> void:
	await create_timer(t).timeout


func _combate(h: String) -> void:
	await _escena(false)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.4
	var cy := 1.2
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, cy + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, cy, 0))
	await _pareja(h, 1.05)
	await _esperar(1.0)
	await _foto("%s_combate_guardia" % h.to_lower())
	var nada := func(): pass
	# ataque básico
	var met: String = {"Kael": "ataque_salto", "Lya": "", "Garon": "atacar_juicio"}[h]
	if met != "":
		a.call(met, nada)
		b.call(met, nada)
		for t in [0.2, 0.3, 0.14, 0.2]:   # 0,2 · 0,5 · 0,64 (impacto) · 0,84
			await _esperar(t)
			await _foto("%s_combate_ataque" % h.to_lower())
		await _esperar(1.0)
	else:
		a.preparar_golpe()
		b.call("gesto", "ataque")
		await _esperar(0.25)
		a.golpear()
		await _esperar(0.2)
		await _foto("%s_combate_ataque" % h.to_lower())
		a.fin_golpe()
		await _esperar(1.0)
	# magia
	if h != "Garon":
		a.lanzar_magia()
		b.lanzar_magia()
		await _esperar(0.45)
		await _foto("%s_combate_magia_concentra" % h.to_lower())
		await _esperar(0.4)
		await _foto("%s_combate_magia_lanza" % h.to_lower())
		await _esperar(0.6)
		a.fin_magia()
		b.fin_magia()
		await _esperar(0.6)
	# golpe recibido
	a.herida()
	b.herida()
	await _esperar(0.1)
	await _foto("%s_combate_herida" % h.to_lower())
	await _esperar(1.2)
	# victoria
	# 13/11: la victoria en 6 instantes (0,25 · 0,5 · 0,75 · 1,0 · 1,3 · 2,0 s), para ver el arma en todo el gesto
	a.victoria()
	b.victoria()
	var t_prev := 0.0
	for t in [0.25, 0.5, 0.75, 1.0, 1.3, 2.0]:
		await _esperar(t - t_prev)
		t_prev = t
		await _foto("%s_combate_victoria_%03d" % [h.to_lower(), int(t * 100)])
	a.reposo()
	b.reposo()
	a.mirar_frente(0.0)
	b.mirar_frente(0.0)
	await _esperar(0.6)
	# derribo y KO
	a.morir()
	b.morir()
	await _esperar(0.5)
	await _foto("%s_combate_cae" % h.to_lower())
	await _esperar(1.5)
	await _foto("%s_combate_ko" % h.to_lower())
	a.revivir()
	b.revivir()
	await _esperar(1.5)
	await _foto("%s_combate_revive" % h.to_lower())


func _exploracion(h: String) -> void:
	await _escena(true)
	cam.fov = 40.0
	await _pareja(h, 0.9)
	for n in [a, b]:
		n.activar_esperas(true)
		n.mirar(Vector3(0.3, 0, 1), 0.0)
	await _esperar(1.0)
	# cámara alta de las regiones (lejos) y una cercana
	cam.look_at_from_position(Vector3(0, 9.0, 11.0), Vector3(0, 0.8, 0))
	await _foto("%s_explora_lejos_reposo" % h.to_lower())
	cam.look_at_from_position(Vector3(0.6, 2.2, 5.2), Vector3(0, 0.95, 0))
	await _foto("%s_explora_reposo" % h.to_lower())
	for n in [a, b]:
		n.marcha(1.4)
	await _esperar(0.5)
	await _foto("%s_explora_andar" % h.to_lower())
	for n in [a, b]:
		n.parar_marcha()
	await _esperar(0.8)
	if b.has_method("hablar"):
		b.call("gesto", "hablar")
		b.expresion("sonrisa", 2.0)
		await _esperar(0.9)
		await _foto("%s_explora_hablar" % h.to_lower())
		await _esperar(1.8)
		b.call("gesto", "hablar_b")
		await _esperar(0.9)
		await _foto("%s_explora_hablar_b" % h.to_lower())
		await _esperar(1.6)
		b.saltar()
		await _esperar(0.45)
		await _foto("%s_explora_saltar" % h.to_lower())
		await _esperar(0.8)
		b.interactuar()
		await _esperar(0.6)
		await _foto("%s_explora_interactuar" % h.to_lower())
		await _esperar(1.2)


func _caras(h: String) -> void:
	if b == null or b.get("v2") == null or not b.v2.tiene_cara():
		return
	var cab: Vector3 = b.skel.global_transform * b.skel.get_bone_global_pose(b.gestos.idx["cabeza"]).origin
	b.mirar(Vector3(0, 0, 1), 0.0)
	a.visible = false
	await _esperar(0.5)
	cam.fov = 30.0
	cam.look_at_from_position(cab + Vector3(0.25, 0.32, 1.3), cab + Vector3(0, 0.18, 0))
	for e in ["normal", "cerrados", "sonrisa", "dolor", "grito", "sorpresa", "entrecerrados", "decidido"]:
		b.v2.set_process(false)          # sin parpadeo durante la foto
		b.v2.poner_expresion(e)
		await _foto("%s_cara_%s" % [h.to_lower(), e])
	b.v2.set_process(true)
