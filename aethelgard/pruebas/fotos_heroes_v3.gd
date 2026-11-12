extends SceneTree
# Héroes v3 (V12): capturas de los TRES a la vez con la misma cámara y la misma luz: original (izquierda), v2 (centro)
# y v3 (derecha).
#   godot --path aethelgard --script res://pruebas/fotos_heroes_v3.gd -- salida=<carpeta> [heroes=Kael,Lya,Garon]
#         [partes=combate,cerca,caras]
# Con ventana (necesita dibujar). No toca partidas: no carga el juego, solo los héroes en una escena propia.
#   - combate: la cámara de combate.gd (ortográfica, 12° desde arriba, luz dorada y relleno azul), mirando a los
#     enemigos, en los mismos instantes de guardia, ataque, golpe, victoria y derribo;
#   - cerca: primer plano de los tres en reposo de exploración (cámara en perspectiva, como los diálogos);
#   - caras: el v3 de cerca con cada expresión y las cejas ya en su sitio.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")
const LUZ_PRINCIPAL := Color(1.0, 0.84, 0.62)
const LUZ_RELLENO := Color(0.55, 0.62, 1.0)
const ORIGINAL := {"Kael": ["res://kael_3d.gd", "res://kael.fbx"],
	"Lya": ["res://maga_3d.gd", "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"],
	"Garon": ["res://garon_3d.gd", "res://garon.fbx"]}

var salida := "user://fotos_heroes_v3"
var heroes := ["Kael"]
var partes := ["combate", "cerca", "caras"]
var cam: Camera3D
var mundo: Node3D
var env: Environment
var n_foto := 0
var trio: Array = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("salida="):
			salida = arg.substr(7)
		elif arg.begins_with("heroes="):
			heroes = Array(arg.substr(7).split(","))
		elif arg.begins_with("partes="):
			partes = Array(arg.substr(7).split(","))
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = Vector2i(1280, 720)
	_principal.call_deferred()


func _principal() -> void:
	for h in heroes:
		if not HeroesV3.listo(h):
			print("FALTA el v3 de ", h, ": se salta")
			continue
		if "combate" in partes:
			await _combate(h)
		if "cerca" in partes:
			await _cerca(h)
		if "caras" in partes:
			await _caras(h)
	print("FOTOS: ", n_foto, " en ", salida)
	quit(0)


func _escena(perspectiva: bool) -> void:
	if mundo != null:
		mundo.queue_free()
		await process_frame
	trio.clear()
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
	cam = Camera3D.new()
	mundo.add_child(cam)
	cam.current = true


func _crear_trio(h: String, separacion: float) -> void:
	var scripts := [ORIGINAL[h][0], HeroesV2.SCRIPTS[ORIGINAL[h][0]], HeroesV3.SCRIPTS[ORIGINAL[h][0]]]
	for i in 3:
		var n: Node3D = load(scripts[i]).new()
		n.ruta_modelo = ORIGINAL[h][1]          # como lo crea el combate: los scripts v2 y v3 lo cambian por su GLB
		n.position = Vector3((i - 1) * separacion, 0, 0)
		mundo.add_child(n)
		trio.append(n)
	for i in 6:
		await process_frame


func _todos(metodo: String, args := []) -> void:
	for n in trio:
		if n.has_method(metodo):
			n.callv(metodo, args)


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
	var cy := 1.1
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, cy + sin(ang) * 6.0, cos(ang) * 6.0), Vector3(0, cy, 0))
	await _crear_trio(h, 1.75)
	await _esperar(1.0)
	var hl := h.to_lower()
	await _foto("%s_combate_guardia" % hl)
	var nada := func(): pass
	var met: String = {"Kael": "ataque_salto", "Lya": "", "Garon": "atacar_juicio"}[h]
	if met != "":
		_todos(met, [nada])
		for t in [0.2, 0.3, 0.14, 0.2]:
			await _esperar(t)
			await _foto("%s_combate_ataque" % hl)
		await _esperar(1.0)
	if h != "Garon":
		_todos("lanzar_magia")
		await _esperar(0.85)
		await _foto("%s_combate_magia" % hl)
		await _esperar(0.6)
		_todos("fin_magia")
		await _esperar(0.6)
	_todos("herida")
	await _esperar(0.12)
	await _foto("%s_combate_herida" % hl)
	await _esperar(1.2)
	_todos("victoria")
	await _esperar(0.6)
	await _foto("%s_combate_victoria_060" % hl)
	await _esperar(1.4)
	await _foto("%s_combate_victoria_200" % hl)
	_todos("reposo")
	_todos("mirar_frente", [0.0])
	await _esperar(0.6)
	_todos("morir")
	await _esperar(0.5)
	await _foto("%s_combate_cae" % hl)
	await _esperar(1.5)
	await _foto("%s_combate_ko" % hl)
	_todos("revivir")
	await _esperar(1.5)


func _cerca(h: String) -> void:
	await _escena(true)
	cam.fov = 30.0
	await _crear_trio(h, 0.95)
	for n in trio:
		n.activar_esperas(true)
		n.mirar(Vector3(0, 0, 1), 0.0)
		if n.get("esperas") != null:
			n.esperas.set_process(false)       # la misma pose en los tres (sin esperas al azar)
	await _esperar(1.2)
	var hl := h.to_lower()
	cam.look_at_from_position(Vector3(0, 1.3, 5.6), Vector3(0, 0.9, 0))
	await _foto("%s_cerca_cuerpo" % hl)
	cam.look_at_from_position(Vector3(0, 1.45, 3.4), Vector3(0, 1.25, 0))
	await _foto("%s_cerca_cabezas" % hl)


func _caras(h: String) -> void:
	if trio.size() < 3:
		await _escena(true)
		await _crear_trio(h, 0.95)
	var b: Node3D = trio[2]
	if b.get("v2") == null or not b.v2.tiene_cara():
		print("SIN CARA v3: ", h)
		return
	trio[0].visible = false
	trio[1].visible = false
	b.mirar(Vector3(0, 0, 1), 0.0)
	await _esperar(0.5)
	var cab: Vector3 = b.skel.global_transform * b.skel.get_bone_global_pose(b.gestos.idx["cabeza"]).origin
	cam.fov = 30.0
	cam.look_at_from_position(cab + Vector3(0.22, 0.30, 1.25), cab + Vector3(0, 0.16, 0))
	for e in ["normal", "decidido", "sonrisa", "dolor", "sorpresa", "entrecerrados", "cerrados", "grito"]:
		b.v2.poner_expresion(e)
		b.v2._t_parpadeo = 99.0                  # sin parpadeo durante la foto
		await _esperar(0.35)                     # las cejas llegan a su sitio
		await _foto("%s_cara_%s" % [h.to_lower(), e])
