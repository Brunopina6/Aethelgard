extends SceneTree
# V12 (15/11): VÍDEOS BREVES DE MOVIMIENTO del grupo para que el usuario compare (Nix junto a los protagonistas). No es
# una prueba ni cambia nada del juego: se lanza con el Movie Maker de Godot, que graba imagen y sonido a ritmo fijo. Datos
# aislados (APPDATA y LOCALAPPDATA en una carpeta temporal). Los interruptores se encienden SOLO en esta sesión
# (Engine.set_meta) y se quitan al acabar: heroes_version, nix_fbx (solo al crear a Nix FBX) y, en «grupo» con Nix,
# nix_v12 y nix_fbx. No toca MAX_ACTIVOS (grupo.gd): el grupo activo sigue siendo de 3.
#
# Uso: godot --path aethelgard --write-movie <x.avi> --fixed-fps 30 --resolution 1280x720
#      --script res://pruebas/grabar_grupo_movimiento.gd -- modo=<solo|grupo|fila> [version=originales|v2|v3]
#      [quien=Kael|Lya|Garon|NixFBX|NixAntigua] [grupo=lya_garon|garon_nix] [dist=11] 3d sin_prologo
# Imprime «CLIP_INICIO <fotograma>» y «CLIP_FIN <fotograma>» (Engine.get_frames_drawn) para recortar el AVI.
# Modos:
#   solo   Pastos Verdes 3D con la cámara de exploración de la región (vista3d.gd: 45°, FOV 38, suavizado 6 y la
#          oclusión de los árboles; a «dist» m, 11 por defecto: un zoom que el jugador puede poner, entre 9 y 34; por
#          defecto 20); sigue al Kael del juego, oculto y pegado al personaje en cada fotograma (sin el adelanto de
#          1,5 m, que solo pone cuando Kael anda con el mando). Un personaje recorre el prado como lo mueve el juego
#          (marcha(v) con su velocidad real, mirar(dir, 0,12), parar_marcha y, Garon, su «Calma» al pararse, como
#          grupo_3d.gd): quieto, andar 1,3 m/s, correr 4,2 m/s, giro de 90° corriendo, media vuelta andando, andar,
#          parar y girarse en el sitio hacia la cámara. El grupo del juego, oculto; sin encuentros ni interfaz.
#   grupo  Pastos Verdes 3D tal cual: Kael con el stick (como un mando) y el grupo del juego siguiéndole
#          (zonas3d/grupo_3d.gd), con su cámara a «dist» m: quieto, andar, correr, giro y parada (los demás llegan).
#   fila   presentación (no es una escena del juego): estudio con suelo a cuadros de 1 m y los valores de luz de la
#          exploración (el sol, girado para que les dé de frente); Kael, Lya, Garon y Nix FBX en fila (1,4 m entre ellos;
#          en el juego 1,8) andando, corriendo y andando; se paran y se giran; cámara lateral que los sigue.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")
const ORIGINAL := {"Kael": ["res://kael_3d.gd", "res://kael.fbx"],
	"Lya": ["res://maga_3d.gd", "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"],
	"Garon": ["res://garon_3d.gd", "res://garon.fbx"]}
const ESCALA := {"Kael": 1.0, "Lya": 0.6 / 0.67, "Garon": 1.0, "NixAntigua": 0.56 / 0.67, "NixFBX": 0.56 / 0.67}
const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
# El prado llano y despejado del oeste (alturas medidas con fotos_grupo_comparar.gd modo=plano: ±0,1 m de x = -21 a
# -9 en z = 9,5), hacia el este (de perfil a la cámara), sin árboles entre la cámara y el recorrido (en el tramo de
# fotos_capa_garon_movimiento.gd, de (-9, 9) a (2, -0,5), dos copas tapaban al personaje los primeros segundos).
const INICIO := Vector3(-21, 0, 9.5)
const HACIA := Vector3(1, 0, 0)
const ANDAR := 1.3                                   # m/s: el stick poco inclinado (vista3d.gd STICK_MIN × 4,2)
const CORRER := 4.2                                  # m/s: el stick a fondo
# Recorrido del modo «solo»: [segundos, velocidad, grados que gira en el tramo]
const RECORRIDO := [[1.0, 0.0, 0.0], [3.0, ANDAR, 0.0], [1.2, CORRER, 0.0], [1.0, CORRER, 90.0], [1.6, ANDAR, 180.0],
	[1.0, ANDAR, 0.0]]
const QUIETO_FINAL := 2.0
# Fila del estudio (solo presentación): 1,4 m entre ellos (en el juego, 1,8: grupo_3d.gd SEPARACION) para que quepan
# más grandes en la imagen; la cámara de lado, a la misma distancia de todos (sin que la perspectiva cambie su altura).
const FILA_SEP := 1.4
const FILA_CAM := Vector3(0.6, 1.2, 5.8)

var modo := "solo"
var version := "originales"
var quien := "Kael"
var grupo := "lya_garon"
var dist := 11.0
var r                                                # la región
var cam: Camera3D
var foco := Vector3.ZERO


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("modo="):
			modo = a.substr(5)
		elif a.begins_with("version="):
			version = a.substr(8)
		elif a.begins_with("quien="):
			quien = a.substr(6)
		elif a.begins_with("grupo="):
			grupo = a.substr(6)
		elif a.begins_with("dist="):
			dist = float(a.substr(5))
	root.size = Vector2i(1280, 720)
	Engine.set_meta("heroes_version", version)        # solo esta sesión
	_empezar.call_deferred()


func _empezar() -> void:
	var rec := root.get_node_or_null("Recursos")         # el contador de FPS (de desarrollo) no sale en el vídeo
	if rec != null and rec.get("lbl_fps") != null:
		rec.lbl_fps.visible = false
	match modo:
		"solo": await _solo()
		"grupo": await _grupo()
		"fila": await _fila()
		_: print("FALLO: modo desconocido %s" % modo)
	_stick(Vector2.ZERO)
	for k in ["nix_v12", "nix_fbx", "heroes_version", "pos_3d_ok", "hitos", "grupo_activo", "grupo_miembros", "grupo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		if r != null and is_instance_valid(r):
			r.set("pasos", -100000)                    # sin encuentros
		await process_frame


func _marca(que: String) -> void:
	print("%s %d" % [que, Engine.get_frames_drawn()])


# ====================================================================================================== PERSONAJES
func _crear(clave: String, padre: Node) -> Node3D:
	var h: Node3D
	if clave.begins_with("Nix"):
		Engine.set_meta("nix_fbx", clave == "NixFBX")  # se decide en _init (nix_3d.gd): solo para crearla
		h = load("res://personajes/nix/nix_3d.gd").new()
		Engine.remove_meta("nix_fbx")
	else:
		var s: String = ORIGINAL[clave][0]
		if version == "v2":
			s = HeroesV2.SCRIPTS[s]
		elif version == "v3":
			s = HeroesV3.SCRIPTS[s]
		h = load(s).new()
		h.ruta_modelo = ORIGINAL[clave][1]
	h.name = clave
	padre.add_child(h)
	h.scale = Vector3.ONE * ESCALA[clave]
	if h.has_method("activar_esperas"):
		h.activar_esperas(true)
	if h.get("esperas") != null:
		h.esperas.pausa = true                         # sin esperas al azar: el vídeo sale igual cada vez
	return h


# El reposo de exploración; Garon, su «Calma» (grupo_3d.gd _crear y _poner_estado).
func _reposo(h: Node3D, fundido := 0.3) -> void:
	if h.has_method("parar_marcha"):
		h.parar_marcha()
	else:
		h.reposo()
	if h.has_method("_guardia_viva") and h.anim.has_animation("Juicio"):
		var lib: AnimationLibrary = h.anim.get_animation_library("")
		if not lib.has_animation("Calma"):
			var calma: Animation = h._guardia_viva("Juicio")
			calma.loop_mode = Animation.LOOP_LINEAR
			lib.add_animation("Calma", calma)
		h.play("Calma", fundido)


func _cargar_region() -> bool:
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})   # sin escenas de llegada
	change_scene_to_file(REGION)
	for i in 900:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == REGION and current_scene.get("kael") != null:
			break
	r = current_scene
	if r == null or r.get("kael") == null:
		print("FALLO: no cargó Pastos Verdes 3D")
		return false
	await _frames(20)
	return true


func _suelo(p: Vector3, y_actual: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, y_actual + 0.6, p.z), Vector3(p.x, y_actual - 3.0, p.z))
	var hit: Dictionary = r.get_world_3d().direct_space_state.intersect_ray(q)
	return NAN if hit.is_empty() else float(hit["position"].y)


# Sin la interfaz de la región (objetivo, nombre de la región y botones de desarrollo del editor): solo el 3D.
func _sin_interfaz() -> void:
	for c in r.find_children("*", "CanvasLayer", true, false):
		c.visible = false


# ====================================================================================================== SOLO
func _solo() -> void:
	Engine.set_meta("grupo_activo", ["Kael"])
	if not await _cargar_region():
		return
	r.kael.visible = false
	if r.get("grupo") != null:
		r.grupo.visible = false
	_sin_interfaz()
	var n := _crear(quien, r)
	var son = root.get_node_or_null("Sonido")         # sus pasos, con el suelo de la región (como grupo_3d.gd)
	if son != null and son.has_method("pasos_3d") and r.has_method("suelo_de_pasos"):
		son.pasos_3d(n, Callable(r, "suelo_de_pasos"))
	var p := INICIO
	var y := _suelo(p, 0.0)
	p.y = 0.0 if is_nan(y) else y
	n.global_position = p
	var rumbo := HACIA.normalized()
	n.mirar(rumbo, 0.0)
	await _frames(10)
	_reposo(n, 0.0)
	# La cámara es la de la región (la del juego, con su suavizado y su oclusión: los árboles entre ella y Kael se
	# vuelven transparentes): sigue al Kael del juego, oculto, que va pegado al personaje en cada fotograma.
	r.set("distancia", dist)
	r._colocar_kael(n.global_position)
	await _frames(40)
	print("SOLO %s %s: script %s · modelo %s · escala %.3f · andar %.2f / correr %.2f m/s (vel_andar/vel_correr × escala)" % [
		quien, version, n.get_script().resource_path, String(n.get("ruta_modelo")), n.scale.x,
		float(n.get("vel_andar")) * n.scale.x, float(n.get("vel_correr")) * n.scale.x])
	_marca("CLIP_INICIO")
	var dt := 1.0 / 30.0
	var bloqueos := 0
	for tramo in RECORRIDO:
		var pasos_t := int(round(float(tramo[0]) * 30.0))
		var giro_paso := deg_to_rad(float(tramo[2])) / maxf(pasos_t, 1)
		var v: float = tramo[1]
		var clips: PackedStringArray = []
		for i in pasos_t:
			if v <= 0.0:
				r.kael.global_position = n.global_position
				await _frames(1)
				continue
			rumbo = rumbo.rotated(Vector3.UP, giro_paso)
			var sig: Vector3 = n.global_position + rumbo * v * dt
			var yy := _suelo(sig, n.global_position.y)
			if is_nan(yy) or absf(yy - n.global_position.y) > 0.5:
				bloqueos += 1
			else:
				n.global_position = Vector3(sig.x, yy, sig.z)
			n.mirar(rumbo, 0.12)
			if n.has_method("marcha"):
				n.marcha(v)
			r.kael.global_position = n.global_position
			var c := String(n.anim.current_animation)
			if not c in clips:
				clips.append(c)
			await _frames(1)
		print("tramo %.1f s a %.1f m/s girando %d°: clips %s · en %s" % [tramo[0], v, int(tramo[2]), str(clips),
			str(n.global_position.snapped(Vector3.ONE * 0.01))])
	_reposo(n)
	await _frames(12)
	n.mirar(Vector3(0, 0, 1), 0.5)                      # se gira en el sitio hacia la cámara
	for i in int(QUIETO_FINAL * 30.0):
		r.kael.global_position = n.global_position
		await _frames(1)
	_marca("CLIP_FIN")
	print("bloqueos del suelo: %d" % bloqueos)


# ====================================================================================================== GRUPO
func _stick(d: Vector2) -> void:
	for par in [["ui_right", d.x], ["ui_left", -d.x], ["ui_down", d.y], ["ui_up", -d.y]]:
		if par[1] > 0.001:
			Input.action_press(par[0], par[1])
		else:
			Input.action_release(par[0])


func _grupo() -> void:
	var G = load("res://grupo.gd")
	G.datos()
	var activos := ["Kael", "Lya", "Garon"]
	if grupo == "garon_nix":
		Engine.set_meta("nix_v12", true)               # solo esta sesión: Nix existe y puede unirse
		Engine.set_meta("nix_fbx", true)               # solo esta sesión: la Nix del FBX
		G.unir("Nix")
		activos = ["Kael", "Garon", "Nix"]
	Engine.set_meta("grupo_activo", activos)
	if not await _cargar_region():
		return
	var g = r.get("grupo")
	print("GRUPO %s %s: activos %s · fila del juego %s · MAX_ACTIVOS %d" % [grupo, version, str(G.activos()),
		str(g.nodos().map(func(x): return "%s(%s, %.3f)" % [x.name, String(x.get("ruta_modelo")).get_file(), x.scale.x]) if g != null else []),
		G.MAX_ACTIVOS])
	_sin_interfaz()
	r.set("distancia", dist)
	r._colocar_kael(Vector3(INICIO.x, _suelo(INICIO, 0.0), INICIO.z))
	r.kael.mirar(HACIA, 0.0)
	if g != null:
		g.colocar(-HACIA)                               # detrás de Kael (al oeste), como al entrar en la región
	await _frames(60)
	_marca("CLIP_INICIO")
	var d := Vector2(HACIA.x, HACIA.z).normalized()
	await _frames(30)                                   # quietos 1 s
	_stick(d * 0.6)                                     # andar (1,26 m/s)
	await _frames(90)
	_stick(d * 1.0)                                     # correr (4,2 m/s)
	await _frames(36)
	for i in 30:                                        # giro de 90° corriendo
		_stick(d.rotated(-PI * 0.5 * (i + 1) / 30.0))
		await _frames(1)
	await _frames(15)
	_stick(Vector2.ZERO)                                # parada: los demás llegan y se paran
	await _frames(105)
	_marca("CLIP_FIN")
	if g != null:
		for x in g.nodos():
			print("%s en %s (Kael en %s)" % [x.name, str(x.global_position.snapped(Vector3.ONE * 0.01)),
				str(r.kael.global_position.snapped(Vector3.ONE * 0.01))])


# ====================================================================================================== FILA
func _fila() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var env := Environment.new()                        # la luz de fotos_grupo_comparar.gd (la de la exploración)
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.86, 0.9, 0.96)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.7, 0.88)
	env.ambient_light_energy = 0.38
	env.tonemap_exposure = 0.58
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.3
	env.adjustment_contrast = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(1.0, 0.9, 0.72)
	sol.light_energy = 1.05
	sol.rotation_degrees = Vector3(-48, 35, 0)          # de delante y del lado de la cámara (andan hacia +X)
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 40.0
	mundo.add_child(sol)
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)   # suelo a cuadros de 1 m: se ve que avanzan
	img.set_pixel(0, 0, Color(0.52, 0.54, 0.57))
	img.set_pixel(1, 1, Color(0.52, 0.54, 0.57))
	img.set_pixel(1, 0, Color(0.45, 0.47, 0.5))
	img.set_pixel(0, 1, Color(0.45, 0.47, 0.5))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_scale = Vector3(40, 40, 1)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	suelo.mesh = pm
	suelo.material_override = mat
	mundo.add_child(suelo)
	var orden := ["Kael", "Lya", "Garon", "NixFBX"]
	var hs: Array = []
	for i in orden.size():
		var h := _crear(orden[i], mundo)
		h.position = Vector3(-6.0 - i * FILA_SEP, 0, 0)  # Kael delante y los demás detrás, como la fila del juego
		hs.append(h)
	await _frames(10)
	for h in hs:
		h.mirar(Vector3.RIGHT, 0.0)
		_reposo(h, 0.0)
	cam = Camera3D.new()
	cam.fov = 40.0
	mundo.add_child(cam)
	cam.current = true
	var centro := func() -> Vector3:
		var c := Vector3.ZERO
		for h in hs:
			c += h.global_position
		return c / hs.size()
	foco = centro.call()
	await _frames(40)
	print("FILA %s: %s" % [version, str(hs.map(func(h): return "%s(%s, %.3f)" % [h.name, String(h.get("ruta_modelo")).get_file(), h.scale.x]))])
	_marca("CLIP_INICIO")
	# [segundos, velocidad]: quietos, andar, correr, andar, parar
	var tramos := [[0.7, 0.0], [4.0, ANDAR], [2.5, CORRER], [1.3, ANDAR]]
	var dt := 1.0 / 30.0
	for t in tramos:
		for i in int(round(float(t[0]) * 30.0)):
			for h in hs:
				if t[1] > 0.0:
					h.position.x += float(t[1]) * dt
					h.marcha(t[1])
			foco = foco.lerp(centro.call(), 1.0 - exp(-8.0 * dt))
			cam.look_at_from_position(foco + FILA_CAM, foco + Vector3(0, 0.85, 0), Vector3.UP)
			await process_frame
	for h in hs:
		_reposo(h)
	for i in 12:
		await process_frame
	for h in hs:
		h.mirar(Vector3(0.3, 0, 1), 0.5)                 # se giran hacia la cámara
	for i in 50:
		foco = foco.lerp(centro.call(), 1.0 - exp(-8.0 * dt))
		cam.look_at_from_position(foco + FILA_CAM, foco + Vector3(0, 0.85, 0), Vector3.UP)
		await process_frame
	_marca("CLIP_FIN")
