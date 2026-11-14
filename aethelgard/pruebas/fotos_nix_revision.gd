extends SceneTree
# V12 (14/11): REVISIÓN VISUAL de Nix desde el FBX junto a los protagonistas ORIGINALES chibi (solo capturas; no cambia
# nada del juego ni guarda partidas reales). Con ventana y datos aislados. Interruptores de sesión «nix_v12» y «nix_fbx».
#   --fixed-fps 30 -- modo=<explorar|combate|estudio|hoja> salida=<carpeta> [grupo=lya|garon] [spec=<json>] 3d
# Modos:
#   explorar  Oakhaven 3D con la partida del banco de pruebas (BASE; archivo de prueba en user:// aislado) y el grupo
#             Kael + Lya|Garon + Nix. grupo_3d.gd no tiene a Nix en RUTAS: se captura primero lo que hace el juego tal cual
#             y después se añade a Nix a la fila a mano (como haría _crear) a la escala del combate (0,56 / 0,67).
#   combate   combate real (combate.tscn), Kael + Lya|Garon + Nix: guardia, Ascuas y la canalización del Colapso con sus
#             fotogramas, hasta que se suelta.
#   estudio   alineación con los chibi (medidas en píxeles), primeros planos de Nix y secuencias de canalizar y andar.
#   hoja      compone hojas de contacto a partir de un JSON: [{"salida", "titulo", "columnas", "ancho",
#             "celdas": [[ruta, rótulo, [x, y, w, h] opcional]]}].

const ESC_EXPLORACION := {"Kael": 1.0, "Lya": 0.6 / 0.67, "Garon": 1.0, "Nix": 0.56 / 0.67}
const ORIGINAL := {"Kael": ["res://kael_3d.gd", "res://kael.fbx"],
	"Lya": ["res://maga_3d.gd", "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"],
	"Garon": ["res://garon_3d.gd", "res://garon.fbx"]}

var salida := ""
var modo := ""
var grupo := "lya"
var spec := ""
var region_arg := "oakhaven"
var n_fotos := 0
var registro: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("modo="):
			modo = a.substr(5)
		elif a.begins_with("grupo="):
			grupo = a.substr(6)
		elif a.begins_with("region="):
			region_arg = a.substr(7)
		elif a.begins_with("spec="):
			spec = a.substr(5)
	if salida == "" or modo == "":
		print("FALLO: falta modo= o salida=")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	Engine.set_meta("heroes_version", "originales")
	_correr.call_deferred()


func _correr() -> void:
	match modo:
		"explorar": await _explorar()
		"combate": await _combate()
		"estudio": await _estudio()
		"cabeza": await _canal_cabeza()
		"hoja": await _hojas()
	var f := FileAccess.open(salida.path_join("registro_%s%s.txt" % [modo, ("_" + region_arg + "_" + grupo) if modo in ["explorar", "combate"] else ""]), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(registro) + "\n")
		f.close()
	for k in ["nix_v12", "nix_fbx", "heroes_version", "zona", "tipo_combate", "grupo_combate", "banco_caso"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	print("FOTOS: %d en %s" % [n_fotos, salida])
	quit(0)


func _log(t: String) -> void:
	print(t)
	registro.append(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(salida.path_join(nombre + ".png"))
	n_fotos += 1


# ====================================================================================================== EXPLORAR
func _explorar() -> void:
	var BP = load("res://banco_pruebas.gd")
	var G = load("res://grupo.gd")
	var acompa := "Lya" if grupo == "lya" else "Garon"
	var region: String = BP.preparar_partida()
	BP.poner_grupo(["Kael", acompa, "Nix"])
	Engine.set_meta("nix_fbx", true)
	Engine.set_meta("pos_3d_ok", false)
	_log("partida del banco: región %s · activos %s · nix_v12 %s · nix_fbx %s · héroes %s" % [region, str(G.activos()),
		str(Engine.get_meta("nix_v12", false)), str(Engine.get_meta("nix_fbx", false)),
		load("res://personajes/heroes_v2/heroes_v2.gd").version()])
	# sitios: [región, Kael al empezar, adónde anda (cámara del juego), adónde anda de cerca]
	var sitios := {"oakhaven": ["res://zonas3d/oakhaven_3d.tscn", Vector3(37.0, 0, 24.3), Vector3(43.5, 0, 30.0), Vector3(37.0, 0, 24.3)],
		"pastos": ["res://zonas3d/pastos_verdes_3d.tscn", Vector3(-9, 0, 9), Vector3(-3, 0, 5), Vector3(5.3, 0, -2)]}
	var si: Array = sitios[region_arg]
	region = si[0]
	var pre := "expl_%s_%s" % [region_arg, grupo]
	change_scene_to_file(region)
	var limite := Time.get_ticks_msec() + 120000
	while Time.get_ticks_msec() < limite and (current_scene == null or current_scene.scene_file_path != region or current_scene.get("kael") == null):
		await process_frame
	var v = current_scene
	if v == null or v.get("kael") == null:
		_log("FALLO: no cargó Oakhaven 3D")
		return
	v.set("pasos", -100000)
	await _frames(60)
	_poner(v, si[1])
	await _frames(120)
	var g = v.get("grupo")
	var nombres: Array = g.nodos().map(func(n): return String(n.name)) if g != null else []
	_log("TAL CUAL (sin tocar): Kael + %s · perfil %s" % [str(nombres), str(Engine.get_meta("calidad_proto", "(por defecto)"))])
	await _foto("%s_00_tal_cual" % pre)
	# Nix a mano en la fila (lo mismo que grupo_3d._crear, que no la tiene en RUTAS)
	var nix := _nix_en_fila(g)
	if nix == null:
		_log("FALLO: no se pudo crear a Nix")
		return
	g.colocar(Vector3.BACK)
	await _frames(150)
	_log("con Nix: %s · Nix escala %.3f · modelo %s" % [str(g.nodos().map(func(n): return String(n.name))),
		nix.scale.x, String(nix.get("ruta_modelo"))])
	await _foto("%s_01_quietos" % pre)
	# andando con la cámara del juego
	v.destino = si[2]
	for i in [18, 30, 42]:
		await _frames(12 if i > 18 else 18)
		v.set("pasos", -100000)
		await _foto("%s_02_andando_%02d" % [pre, i])
	var t := 0
	while v.destino != null and t < 400:
		await process_frame
		t += 1
	await _frames(100)
	await _foto("%s_03_parados" % pre)
	# de cerca (9 m, como fotos_heroes_pulido): mirando a la cámara
	if v.get("_dist_jugador") != null:
		v.set("_dist_jugador", 9.0)
	v.set("distancia", 9.0)
	await _frames(50)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	for f in 30:
		for n in [v.kael] + g.nodos():
			if n != null and n.has_method("mirar") and cam != null:
				var d: Vector3 = cam.global_position - n.global_position
				n.mirar(Vector3(d.x, 0, d.z), 0.0)
		await process_frame
	await _foto("%s_04_cerca_quietos" % pre)
	v.destino = si[3]
	await _frames(20)
	await _foto("%s_05_cerca_andando_a" % pre)
	await _frames(14)
	await _foto("%s_05_cerca_andando_b" % pre)
	t = 0
	while v.destino != null and t < 400:
		await process_frame
		t += 1
	await _frames(60)
	await _foto("%s_06_cerca_parados" % pre)
	for n in [v.kael] + g.nodos():
		_log("%s en %s · escala %.3f" % [n.name, n.global_position.snapped(Vector3.ONE * 0.01), n.scale.x])
	load("res://banco_pruebas.gd").salir()


func _poner(v, p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 3.0, 0), p - Vector3(0, 6.0, 0))
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	if not r.is_empty():
		p.y = r["position"].y
	v._colocar_kael(p)
	if v.get("grupo") != null:
		v.grupo.colocar(Vector3.BACK)


func _nix_en_fila(g) -> Node3D:
	for n in g.nodos():                              # (14/11) grupo_3d.gd ya la pone en la fila: se usa la del juego
		if String(n.name) == "Nix":
			_log("Nix ya está en la fila del juego (grupo_3d.gd): no se añade a mano")
			return n
	var nodo = load("res://personajes/nix/nix_3d.gd").new()
	nodo.name = "Nix"
	g.add_child(nodo)
	if nodo.get("anim") == null or nodo.get("skel") == null:
		nodo.queue_free()
		return null
	nodo.scale = Vector3.ONE * ESC_EXPLORACION["Nix"]
	nodo.activar_esperas()
	var delante: Node3D = g.miembros[g.miembros.size() - 1]["nodo"] if not g.miembros.is_empty() else g.kael
	var m := {"nombre": "Nix", "nodo": nodo, "lider": delante, "cola": [], "ultimo": delante.global_position,
		"estado": "?", "apartar": null, "t_apartar": 0.0, "dir": Vector3.ZERO, "t_quieto": 0.0, "mira": false,
		"reposo": "", "v": 0.0}
	g.miembros.append(m)
	return nodo


# ====================================================================================================== COMBATE
var c: Node
var paso := 0
var nix_p: Node3D


func _combate() -> void:
	var G = load("res://grupo.gd")
	G.datos()
	Engine.set_meta("nix_v12", true)
	Engine.set_meta("nix_fbx", true)
	G.unir("Nix")
	var acompa := "Lya" if grupo == "lya" else "Garon"
	G.formar(["Kael", acompa, "Nix"])
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 1)
	seed(14112026)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _frames(4)
	for e in c.enemigos:
		e["hp_max"] = 9999
		e["hp"] = 9999
	var nix := _heroe("Nix")
	nix_p = c._p3d(nix) if not nix.is_empty() else null
	_log("combate: %s · Nix %s" % [str(c.heroes.map(func(h): return h["nombre"])),
		String(nix_p.get("ruta_modelo")) if nix_p != null else "SIN MODELO"])
	await _frames(80)
	await _foto("comb_%s_00_guardia" % grupo)
	var t := 0
	while paso < 99 and t < 30 * 90:
		t += 1
		await process_frame
		if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
			await _turno(c.actor)
	_log("fin del guion (paso %d, %d fotogramas)" % [paso, t])


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _turno(quien: Dictionary) -> void:
	if quien["nombre"] != "Nix":
		c._defender()
		return
	quien["mp"] = maxi(quien["mp"], 60)
	var vivos: Array = c.enemigos.filter(func(x): return x["hp"] > 0)
	match paso:
		0:
			c._menu_magia(c.PESTANA_NEGRA)
			c._menu_escuela("nix_ascuas")
			c._elegir_negra("nix_ascuas", 1)
			if c.estado == "objetivo":
				c._confirmar_objetivo(vivos[0])
			for i in 8:
				await _frames(5)
				await _foto("comb_%s_01_ascuas_%02d" % [grupo, i])
			paso = 1
		1:
			quien["nx_sellos"] = 3
			c._menu_magia(c.PESTANA_NEGRA)
			c._menu_escuela("nix_colapso")
			c._elegir_negra("nix_colapso", 1)
			_log("Colapso: conjuro %s · clip %s" % [str(quien.has("conjuro")), String(nix_p.anim.current_animation) if nix_p != null else "?"])
			for i in 16:
				await _foto("comb_%s_02_canalizar_%02d_%03dms" % [grupo, i, i * 100])
				await _frames(3)
			for i in 6:
				await _frames(20)
				await _foto("comb_%s_03_canalizar_bucle_%02d" % [grupo, i])
			paso = 2
		_:
			c._defender()
			paso = 99
	await process_frame


# ====================================================================================================== ESTUDIO
var mundo: Node3D
var cam: Camera3D


func _mundo_estudio() -> void:
	mundo = Node3D.new()
	root.add_child(mundo)
	# la luz del combate (combate.gd _crear_rig_3d): sin tonemap, ambiente cálido 0,6, principal FFE2B0 a 1,3 y relleno
	# azul 7FA0D8 a 0,3; sin sombras (el combate no las tiene); fondo neutro oscuro y un suelo oscuro de referencia
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.22, 0.24, 0.28)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.86, 0.78)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	var luz := DirectionalLight3D.new()
	luz.light_color = Color("FFE2B0")
	luz.light_energy = 1.3
	luz.rotation_degrees = Vector3(-35, -40, 0)
	mundo.add_child(luz)
	var rel := DirectionalLight3D.new()
	rel.light_color = Color("7FA0D8")
	rel.light_energy = 0.3
	rel.rotation_degrees = Vector3(-15, 140, 0)
	mundo.add_child(rel)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	suelo.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.12)
	suelo.material_override = mat
	mundo.add_child(suelo)
	cam = Camera3D.new()
	mundo.add_child(cam)
	cam.current = true


func _heroe_estudio(n: String) -> Node3D:
	var h: Node3D
	if n == "Nix":
		Engine.set_meta("nix_fbx", true)
		h = load("res://personajes/nix/nix_3d.gd").new()
	else:
		h = load(ORIGINAL[n][0]).new()
		h.ruta_modelo = ORIGINAL[n][1]
	h.name = n
	mundo.add_child(h)
	h.scale = Vector3.ONE * ESC_EXPLORACION[n]
	return h


func _mirar_cam(desde: Vector3, a: Vector3, fov := 30.0) -> void:
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = fov
	cam.look_at_from_position(desde, a, Vector3.UP)


func _orto(centro: Vector3, alto: float) -> void:
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = alto
	cam.look_at_from_position(centro + Vector3(0, 0, 10), centro, Vector3.UP)


func _girar(h: Node3D, grados: float) -> void:
	h.mirar(Vector3(sin(deg_to_rad(grados)), 0, cos(deg_to_rad(grados))), 0.0)


func _hueso(h: Node3D, parte: String) -> Vector3:
	var sk: Skeleton3D = h.skel
	for i in sk.get_bone_count():
		var nb := sk.get_bone_name(i)
		if nb.ends_with(parte):
			return sk.global_transform * sk.get_bone_global_pose(i).origin
	return Vector3.INF


# Altura visible (m) por píxeles en la vista ortográfica: solo «h» visible frente a la escena sin nadie.
func _medir(todos: Array, h: Node3D, alto_orto: float) -> Dictionary:
	var mpp0 := alto_orto / float(root.size.y)
	var cab0 := _hueso(h, "Head")
	var cx := int(cam.unproject_position(cab0).x) if cab0 != Vector3.INF else root.size.x / 2
	var media := int(0.2 / mpp0)                      # ±0,2 m alrededor de la cabeza para lo alto (sin armas encima)
	for x in todos:
		x.visible = false
	await _frames(3)
	await RenderingServer.frame_post_draw
	var fondo := root.get_texture().get_image()
	h.visible = true
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var top := -1
	var bot := -1
	var izq := 99999
	var der := -1
	for y in range(0, img.get_height(), 1):
		var hay := false
		for x in range(0, img.get_width(), 2):
			var a := img.get_pixel(x, y)
			var b := fondo.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.12:
				hay = true
				izq = mini(izq, x)
				der = maxi(der, x)
				if top < 0 and absi(x - cx) <= media:
					top = y
		if hay:
			bot = y
	for x in todos:
		x.visible = true
	var mpp := alto_orto / float(img.get_height())
	return {"alto": (bot - top) * mpp, "top_y": alto_orto * 0.5 - top * mpp, "ancho": (der - izq) * mpp}


func _estudio() -> void:
	_mundo_estudio()
	var hs := {}
	var xs := {"Kael": -1.85, "Lya": -0.62, "Garon": 0.62, "Nix": 1.85}
	for n in ["Kael", "Lya", "Garon", "Nix"]:
		hs[n] = _heroe_estudio(n)
		hs[n].position = Vector3(xs[n], 0, 0)
	await _frames(20)
	for n in hs:
		if hs[n].has_method("activar_esperas"):
			hs[n].activar_esperas(true)
		if hs[n].get("esperas") != null:
			hs[n].esperas.pausa = true
		hs[n].reposo()
		_girar(hs[n], 0)
	await _frames(40)
	# 1. alineación ortográfica de frente a la escala del juego y medidas
	var alto_orto := 2.6
	_orto(Vector3(0, 1.1, 0), alto_orto)
	await _frames(5)
	await _foto("est_01_alineacion_frente_escala_juego")
	var todos: Array = hs.values()
	var cent := 1.1
	for n in hs:
		var m: Dictionary = await _medir(todos, hs[n], alto_orto)
		var top_mundo: float = cent + float(m["top_y"])
		var cuello := _hueso(hs[n], "Neck")
		var cabeza := _hueso(hs[n], "Head")
		var cab_cuello := top_mundo - cuello.y if cuello != Vector3.INF else -1.0
		var cab := top_mundo - cabeza.y if cabeza != Vector3.INF else -1.0
		_log("MEDIDA %s (escala %.3f): alto visible %.3f m · ancho visible %.3f m · de lo alto al hueso del cuello %.3f m (%.2f «cabezas»: alto / eso) · de lo alto al hueso Head %.3f m" % [
			n, ESC_EXPLORACION[n], m["alto"], m["ancho"], cab_cuello, float(m["alto"]) / maxf(cab_cuello, 0.001), cab])
	# tres cuartos en perspectiva, la altura de una cámara de exploración (de arriba)
	_mirar_cam(Vector3(3.5, 3.2, 6.5), Vector3(0, 0.8, 0), 30.0)
	await _frames(5)
	await _foto("est_02_alineacion_arriba_tres_cuartos")
	# de espaldas
	for n in hs:
		_girar(hs[n], 180)
	_orto(Vector3(0, 1.1, 0), alto_orto)
	await _frames(5)
	await _foto("est_03_alineacion_espalda")
	for n in hs:
		_girar(hs[n], 0)
	# referencia: Nix a 1,0 (la misma escala de exploración que Kael) para comparar, sin decidir nada
	hs["Nix"].scale = Vector3.ONE
	_orto(Vector3(0, 1.1, 0), alto_orto)
	await _frames(5)
	await _foto("est_04_referencia_nix_a_escala_kael")
	var m2: Dictionary = await _medir(todos, hs["Nix"], alto_orto)
	_log("MEDIDA Nix a escala 1,0 (referencia): alto visible %.3f m" % m2["alto"])
	hs["Nix"].scale = Vector3.ONE * ESC_EXPLORACION["Nix"]
	# 2. primeros planos de Nix (sola, en el centro)
	for n in hs:
		hs[n].visible = n == "Nix"
	var nix: Node3D = hs["Nix"]
	nix.position = Vector3.ZERO
	await _frames(10)
	var cab := _hueso(nix, "Head")
	var ojo := cab + Vector3(0, 0.07, 0)
	_mirar_cam(ojo + Vector3(0, 0.02, 0.75), ojo, 30.0)
	await _frames(4)
	await _foto("cerca_01_cara_frente")
	_mirar_cam(ojo + Vector3(0, 0.02, 0.38), ojo, 30.0)
	await _frames(4)
	await _foto("cerca_02_ojos_muy_cerca")
	_mirar_cam(ojo + Vector3(0.47, 0.05, 0.6), ojo, 30.0)
	await _frames(4)
	await _foto("cerca_03_cara_tres_cuartos")
	_mirar_cam(ojo + Vector3(0.75, 0.0, 0.0), ojo, 30.0)
	await _frames(4)
	await _foto("cerca_04_cara_perfil")
	var pecho := cab + Vector3(0, -0.25, 0)
	_mirar_cam(pecho + Vector3(0, 0.05, 1.9), pecho, 30.0)
	await _frames(4)
	await _foto("cerca_05_medio_cuerpo_frente")
	_mirar_cam(pecho + Vector3(1.2, 0.1, 1.45), pecho, 30.0)
	await _frames(4)
	await _foto("cerca_06_medio_cuerpo_tres_cuartos")
	_girar(nix, 180)
	await _frames(3)
	var esp := cab + Vector3(0, -0.35, 0)
	_mirar_cam(esp + Vector3(0, 0.05, 1.7), esp, 30.0)
	await _frames(4)
	await _foto("cerca_07_espalda_emblema")
	_girar(nix, 0)
	var piernas := Vector3(0, 0.35, 0)
	_mirar_cam(piernas + Vector3(0, 0.15, 1.9), piernas, 30.0)
	await _frames(4)
	await _foto("cerca_08_piernas_frente_medias")
	_girar(nix, 180)
	await _frames(3)
	await _foto("cerca_09_piernas_espalda")
	_girar(nix, 0)
	# guardia de combate de cerca (el cetro)
	nix.activar_esperas(false)
	nix.play("Idle", 0.0)
	await _frames(20)
	_mirar_cam(Vector3(0.9, 1.2, 3.2), Vector3(0, 0.75, 0), 30.0)
	await _frames(4)
	await _foto("cerca_10_guardia_cetro")
	# 3. canalizar: tres Nix (frente, tres cuartos y espalda) a la vez
	nix.visible = false
	var tres: Array = []
	for i in 3:
		var x := _heroe_estudio("Nix")
		x.position = Vector3(-1.25 + 1.25 * i, 0, 0)
		tres.append(x)
	await _frames(20)
	for i in 3:
		tres[i].reposo()
		_girar(tres[i], [0.0, -40.0, 180.0][i])
	await _frames(40)
	_mirar_cam(Vector3(0, 1.0, 6.2), Vector3(0, 0.72, 0), 30.0)
	await _canalizar(tres, "canal_cuerpo")
	# medio cuerpo, dos vistas (frente y espalda), más cerca
	for i in 3:
		tres[i].reposo()
	tres[1].visible = false
	tres[0].position = Vector3(-0.55, 0, 0)
	tres[2].position = Vector3(0.55, 0, 0)
	_girar(tres[0], -20)
	_girar(tres[2], 160)
	await _frames(45)
	_mirar_cam(Vector3(0, 1.15, 3.0), Vector3(0, 0.95, 0), 30.0)
	await _canalizar([tres[0], tres[2]], "canal_cerca")
	# faldones de cerca, desde abajo-lado
	for x in tres:
		x.reposo()
	tres[2].visible = false
	tres[0].position = Vector3.ZERO
	_girar(tres[0], -30)
	await _frames(45)
	_mirar_cam(Vector3(0.6, 0.55, 2.4), Vector3(0, 0.5, 0), 30.0)
	await _canalizar([tres[0]], "canal_faldones")
	# 4. andar y correr (articulaciones): perfil y frente
	tres[0].reposo()
	tres[1].visible = true
	tres[1].position = Vector3(0.7, 0, 0)
	tres[0].position = Vector3(-0.7, 0, 0)
	_girar(tres[0], -90)
	_girar(tres[1], 0)
	tres[0].play("Walking", 0.0)
	tres[1].play("Walking", 0.0)
	_mirar_cam(Vector3(0, 0.9, 4.6), Vector3(0, 0.7, 0), 30.0)
	await _frames(10)
	for i in 8:
		await _foto("andar_%02d" % i)
		await _frames(4)
	tres[0].play("Running", 0.0)
	tres[1].play("Running", 0.0)
	await _frames(10)
	for i in 6:
		await _foto("correr_%02d" % i)
		await _frames(3)


# Canalizar de cerca (cabeza y hombros): mechones delanteros y superior. Frente (-15°) y lado (-70°).
func _canal_cabeza() -> void:
	_mundo_estudio()
	for vista in [["frente", -15.0], ["lado", -70.0]]:
		var x := _heroe_estudio("Nix")
		await _frames(20)
		x.reposo()
		_girar(x, vista[1])
		await _frames(45)
		var cab := _hueso(x, "Head")
		var c0 := cab + Vector3(0, 0.0, 0)
		_mirar_cam(c0 + Vector3(0, 0.08, 1.35), c0 + Vector3(0, -0.05, 0), 30.0)
		await _canalizar([x], "canal_cabeza_" + vista[0])
		x.queue_free()
		await _frames(3)


func _canalizar(quienes: Array, pref: String) -> void:
	await _frames(3)
	await _foto("%s_000ms_antes" % pref)
	for q in quienes:
		q.concentrar()
	var t0 := 0
	for i in 13:                                      # 0-1,2 s cada 0,1 s
		await _frames(3)
		t0 += 3
		await _foto("%s_%03dms" % [pref, t0 * 100 / 3])
	for i in 6:                                       # el bucle: cada 0,2 s
		await _frames(6)
		t0 += 6
		await _foto("%s_%03dms" % [pref, t0 * 100 / 3])
	_log("%s: clip al final %s" % [pref, String(quienes[0].anim.current_animation)])


# ====================================================================================================== HOJA
func _hojas() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(spec))
	if not d is Array:
		_log("FALLO: spec")
		return
	for h in d:
		await _hoja(h)


func _hoja(h: Dictionary) -> void:
	var cols: int = int(h.get("columnas", 3))
	var ancho: int = int(h.get("ancho", 480))
	var celdas: Array = h["celdas"]
	var imgs: Array = []
	var alto_celda := 0
	for cd in celdas:
		var img := Image.load_from_file(cd[0])
		if img == null:
			_log("FALTA %s" % cd[0])
			img = Image.create(64, 64, false, Image.FORMAT_RGB8)
		img.convert(Image.FORMAT_RGB8)
		if cd.size() > 2 and cd[2] is Array:
			var r: Array = cd[2]
			img = img.get_region(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
		var alto_i := int(round(float(img.get_height()) * ancho / img.get_width()))
		img.resize(ancho, alto_i, Image.INTERPOLATE_LANCZOS)
		imgs.append(img)
		alto_celda = maxi(alto_celda, alto_i)
	var filas := int(ceil(float(celdas.size()) / cols))
	var rot := 30
	var cab := 56
	var marg := 8
	var y_fila: Array = []                            # cada fila, tan alta como su imagen más alta
	var yy := cab
	for f in filas:
		y_fila.append(yy)
		var mx := 0
		for j in range(f * cols, mini((f + 1) * cols, imgs.size())):
			mx = maxi(mx, imgs[j].get_height())
		yy += mx + rot + marg
	var tam := Vector2i(cols * (ancho + marg) + marg, yy + marg)
	var vp := SubViewport.new()
	vp.size = tam
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var fondo := ColorRect.new()
	fondo.color = Color(0.12, 0.12, 0.14)
	fondo.size = Vector2(tam)
	vp.add_child(fondo)
	var t := Label.new()
	t.text = h.get("titulo", "")
	t.position = Vector2(marg, 10)
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_color_override("font_color", Color(1, 0.86, 0.5))
	vp.add_child(t)
	for i in imgs.size():
		var cx := marg + (i % cols) * (ancho + marg)
		var cy: int = y_fila[i / cols]
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(imgs[i])
		tr.position = Vector2(cx, cy)
		vp.add_child(tr)
		var l := Label.new()
		l.text = celdas[i][1]
		l.position = Vector2(cx + 2, cy + imgs[i].get_height() + 2)
		l.add_theme_font_size_override("font_size", 17)
		l.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
		vp.add_child(l)
	await _frames(3)
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(h["salida"])
	n_fotos += 1
	vp.queue_free()
	await _frames(2)
