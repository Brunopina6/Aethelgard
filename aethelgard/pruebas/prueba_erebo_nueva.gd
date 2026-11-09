extends SceneTree
# T-101: la invocación nueva de Érebo (invocacion_erebo_nueva.gd). Sin ventana, con --fixed-fps 30:
#   --script res://pruebas/prueba_erebo_nueva.gd --fixed-fps 30 -- invocar erebo_nueva [solo_teatro] [fotos=<carpeta>]
# 1. En un teatro como el del combate (Lya, Kael, el doble de Grimfang y la cámara): éxito, fallo, contra un jefe
#    (Gorthor, el doble ×1,6) y saltada pronto (0,5 s) y tarde (a 1 s del final). En cada caso: el resultado se aplica
#    UNA vez, el de siempre (éxito: muerte; jefe: 20 %; fallo: nada), dura lo que pide la cinemática (éxito ≈11-13 s,
#    fallo ≈9-10 s, contando los 0,6 s en que vuelve la cámara), el tiempo vuelve a ×1, la cámara vuelve a su sitio, las luces a su energía y Érebo queda oculto.
#    En el contacto, la punta de la mano de Érebo está en el pecho del enemigo (colocación por la mano + IK).
# 2. En un combate de verdad (combate.tscn con «-- invocar erebo=exito erebo_nueva»): Lya invoca con la variante nueva,
#    el enemigo muere una vez, el teatro se cierra y el combate sigue.
# Termina con «FALLOS: n» y quit(1) si algo falla. Con «fotos=<carpeta>» (y ventana), guarda una captura cada 0,5 s.

const CONTACTO_MAX := 0.03       # metros entre la punta de la mano y el pecho, en el contacto (Fase 1: 0-2 cm)

var fallos: Array = []
var fotos := ""
var _n_foto := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _probar() -> void:
	await _esperar(6)
	if not load("res://invocacion_erebo_nueva.gd").elegida() and not "variante=actual" in OS.get_cmdline_user_args():
		_fallo("elegida() no ve «erebo_nueva» en los argumentos")
	var casos := [["exito", false, -1.0], ["fallo", false, -1.0], ["exito", true, -1.0], ["exito", false, 0.5],
			["exito", false, 9.5], ["fallo", false, 7.5]]
	if fotos != "":                                     # capturas: solo éxito y fallo enteros
		casos = [["exito", false, -1.0], ["fallo", false, -1.0]]
	for caso in casos:
		await _teatro(caso[0], caso[1], caso[2])
	if not "solo_teatro" in OS.get_cmdline_user_args():
		await _combate()
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= 1. el teatro

const CAPTURA := """
extends SkeletonModifier3D
var pose := {}
var huesos := []
func _process_modification() -> void:
	var sk := get_skeleton()
	for i in huesos:
		pose[i] = sk.get_bone_global_pose(i)
"""


func _teatro(forzar: String, jefe: bool, saltar_en: float) -> void:
	var nombre := "%s%s%s" % [forzar, " jefe" if jefe else "", (" saltada a %.1f s" % saltar_en) if saltar_en >= 0.0 else ""]
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var mundo := Node3D.new()
	vp.add_child(mundo)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_energy = 0.55
	env.environment.ambient_light_color = Color(0.55, 0.5, 0.8)
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.07, 0.05, 0.11)
	var suelo := MeshInstance3D.new()                  # (como el del teatro del combate)
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 24)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.2, 0.17, 0.22)
	suelo.material_override = ms
	mundo.add_child(env)
	mundo.add_child(suelo)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -40, 0)
	sol.shadow_enabled = true
	sol.light_energy = 1.2
	mundo.add_child(sol)
	var cam := Camera3D.new()
	cam.fov = 40
	mundo.add_child(cam)
	cam.look_at_from_position(Vector3(0.6, 2.3, 5.2), Vector3(-0.2, 0.7, 0))
	cam.current = true
	var cam0 := cam.global_transform
	var lya = load("res://maga_3d.gd").new()
	mundo.add_child(lya)
	lya.position = Vector3(1.7, 0, 0.5)
	var doble = load("res://goblin_3d.gd").new()
	doble.ruta_modelo = "res://goblin.fbx"
	if jefe:
		doble.scale = Vector3.ONE * 1.6
	mundo.add_child(doble)
	doble.position = Vector3(-1.8, 0, -0.1)
	await _esperar(6)
	var actual := "variante=actual" in OS.get_cmdline_user_args()   # para el «antes»: la invocación de siempre
	var inv = load("res://invocacion_erebo.gd" if actual else "res://invocacion_erebo_nueva.gd").new()
	mundo.add_child(inv)
	var aplicado := []
	var contacto := {"error": -1.0}
	inv.evento.connect(func(n: String):
		if n == "contacto":
			_medir_contacto.call_deferred(inv, contacto))
	var ctx := {"invocador": lya, "objetivo": doble, "es_jefe": jefe, "camara": cam, "kael": true,
		"forzar": forzar, "al_resultado": func(r): aplicado.append(r)}
	var t0 := Time.get_ticks_msec()
	var fotogramas := [0]
	var termina := {"si": false}
	var corre := func():
		await inv.lanzar(ctx)
		termina["si"] = true
	corre.call()
	while not termina["si"] and fotogramas[0] < 30 * 25:
		await process_frame
		fotogramas[0] += 1
		if fotos != "" and fotogramas[0] % 15 == 0 and saltar_en < 0.0:
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_jpg(fotos.path_join("%s_%s_%s_%04d.jpg" % ["actual" if actual else "nueva", forzar, "jefe" if jefe else "normal", fotogramas[0]]), 0.88)
		if saltar_en >= 0.0 and fotogramas[0] == int(saltar_en * 30):
			inv.saltar()
	var dur: float = fotogramas[0] / 30.0
	await _esperar(25)                                  # lo que tarda en restaurar la cámara (0,6 s)
	print("TEATRO %s: %.2f s, resultado %s, aplicado %d vez/veces, contacto a %.3f m, tiempo ×%.2f" % [nombre, dur,
		inv.resultado, aplicado.size(), contacto["error"], Engine.time_scale])
	if not termina["si"]:
		_fallo("%s: no termina en 25 s" % nombre)
	if aplicado.size() != 1:
		_fallo("%s: el resultado se aplica %d veces" % [nombre, aplicado.size()])
	elif jefe and (not aplicado[0]["exito"] or aplicado[0]["muerte"] or absf(aplicado[0]["dano_pct_actual"] - 0.2) > 0.001):
		_fallo("%s: contra un jefe el resultado es %s (debe ser éxito, sin muerte, 20 %%)" % [nombre, aplicado[0]])
	elif not jefe and aplicado[0]["muerte"] != (forzar == "exito"):
		_fallo("%s: resultado %s" % [nombre, aplicado[0]])
	if Engine.time_scale != 1.0:
		_fallo("%s: el tiempo se queda a ×%.2f" % [nombre, Engine.time_scale])
	if cam.global_transform.origin.distance_to(cam0.origin) > 0.01:
		_fallo("%s: la cámara no vuelve a su sitio (%.2f m)" % [nombre, cam.global_transform.origin.distance_to(cam0.origin)])
	if absf(sol.light_energy - 1.2) > 0.01 and saltar_en >= 0.0:
		_fallo("%s: la luz no vuelve (%.2f)" % [nombre, sol.light_energy])
	if inv.erebo != null and inv.erebo.visible:
		_fallo("%s: Érebo sigue visible" % nombre)
	if saltar_en < 0.0 and not actual:
		var esperado := Vector2(10.0, 13.0) if forzar == "exito" else Vector2(8.5, 10.5)   # (con los 0,6 s en que vuelve la cámara)
		if dur < esperado.x or dur > esperado.y:
			_fallo("%s: dura %.2f s (debe ir de %.1f a %.1f)" % [nombre, dur, esperado.x, esperado.y])
		if contacto["error"] < 0.0 or contacto["error"] > CONTACTO_MAX:
			_fallo("%s: en el contacto la punta de la mano está a %.3f m del pecho" % [nombre, contacto["error"]])
	vp.queue_free()
	Engine.time_scale = 1.0
	await _esperar(4)


# La punta de la mano (después de la IK) frente al punto del pecho al que va, en el fotograma del contacto.
func _medir_contacto(inv, contacto: Dictionary) -> void:
	var e = inv.erebo
	var cap := SkeletonModifier3D.new()
	var s := GDScript.new()
	s.source_code = CAPTURA
	s.reload()
	cap.set_script(s)
	cap.set("huesos", [e._i["RightHandMiddle1"]])
	e.skel.add_child(cap)
	await process_frame
	await process_frame
	var pose: Dictionary = cap.get("pose")
	if pose.has(e._i["RightHandMiddle1"]):
		var p: Vector3 = e.skel.global_transform * pose[e._i["RightHandMiddle1"]].origin
		contacto["error"] = p.distance_to(e.mano_objetivo)
	cap.queue_free()


# ================================================================= 2. un combate de verdad

func _combate() -> void:
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 0)
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	var vio := false
	var ini := {}
	for e in c.enemigos:
		ini[e["nombre"]] = e["hp"]
	for i in 30 * 90:
		await process_frame
		if c.inv_erebo != null and not vio:
			vio = true
			var es_nueva: bool = c.inv_erebo.get_script().resource_path == "res://invocacion_erebo_nueva.gd"
			print("COMBATE: Lya invoca a Érebo con la variante %s" % ("nueva" if es_nueva else "de siempre"))
			if not es_nueva:
				_fallo("combate: no usa la invocación nueva con «erebo_nueva»")
		if vio and c.inv_erebo == null and c.estado != "accion":
			break
	if not vio:
		_fallo("combate: Lya no llega a invocar a Érebo")
	var muertos: int = c.enemigos.filter(func(e): return e["hp"] <= 0).size()
	print("COMBATE: tras la invocación, %d enemigo(s) sin vida; estado «%s»; tiempo ×%.2f" % [muertos, c.estado, Engine.time_scale])
	if vio and muertos < 1:
		_fallo("combate: con «erebo=exito» el enemigo no muere")
	if Engine.time_scale != 1.0:
		_fallo("combate: el tiempo se queda a ×%.2f" % Engine.time_scale)
	c.queue_free()
	await _esperar(5)
