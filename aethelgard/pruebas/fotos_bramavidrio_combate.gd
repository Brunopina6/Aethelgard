extends SceneTree
# Bramavidrio en un combate de verdad (V12, pasada 2; con ventana): para elegir el encuadre de MODELOS sin tocar
# combate.gd. Monta el combate fijo de Bramavidrio (grupo 13, los tres héroes, la interfaz) y, SOLO en esta prueba,
# esconde su foto 2D y crea su modelo 3D con la función del propio combate (_crear_rig_3d) y el ajuste de los jefes
# grandes («pies_como», como _crear_rig) para cada encuadre de OPCIONES. Mide en píxeles de pantalla (1280 × 720) dónde
# caen el agujero, lo más alto y lo más adelantado de cada clip, y saca una foto de cada uno.
#   --script res://pruebas/fotos_bramavidrio_combate.gd -- salida=<carpeta> [opciones=pasada1,grande]
# No mide rendimiento.

const GUION := "res://enemigos/bramavidrio/bramavidrio_3d.gd"
const BASE := {"tipo": "3d", "script": GUION, "gestos": "res://gestos_3d.gd",
	"rutas": ["res://enemigos/bramavidrio/bramavidrio.glb"], "barra_y": 0.0, "centro_3d": 1.9}
const OPCIONES := {
	"pasada1": {"vp": Vector2i(1800, 1400), "alto_vista": 7.0, "centro_y": 2.3, "esc": 0.9},
	"grande": {"vp": Vector2i(2200, 1250), "alto_vista": 4.6, "centro_y": 2.0, "esc": 1.0, "pies_como": 0.34},
	# la propuesta: pies_como 0 deja el agujero justo en la posición del grupo (GRUPOS[13] = (288, 600) → escena (26, 600))
	"propuesta": {"vp": Vector2i(1920, 1000), "alto_vista": 5.1, "centro_y": 1.45, "esc": 1.07, "pies_como": 0.0,
		"grupo": Vector2(288, 600)},
}
const POSES := [["reposo", 0.0], ["rugido", 0.9], ["ataque", 1.0], ["ataque_sismico", 1.6], ["ataque_sismico", 2.55],
	["ataque_aliento", 2.1], ["emerger", 0.9]]

var salida := ""
var elegidas: Array = []
var c: Node
var fallos := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("opciones="):
			elegidas = Array(a.substr(9).split(","))
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_bramavidrio_combate")
	if elegidas.is_empty():
		elegidas = OPCIONES.keys()
	DirAccess.make_dir_recursive_absolute(salida)
	Engine.set_meta("grupo_combate", 13)
	Engine.set_meta("combate_fijo", "mc_bramavidrio")
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("zona", "desierto")
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	_correr.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(salida.path_join(nombre + ".png"))
	print("  foto ", nombre)


func _correr() -> void:
	for i in 300:
		await process_frame
		if not c.enemigos.is_empty() and c.enemigos[0].has("rig") and i > 60:
			break
	if c.enemigos.is_empty():
		print("FALLO: el combate no crea a Bramavidrio")
		quit(1)
		return
	await _foto("combate_antes_foto2d")
	var f: Dictionary = c.enemigos[0]
	f["rig"].visible = false
	c.process_mode = Node.PROCESS_MODE_DISABLED              # quieto: el combate no sigue (solo se dibuja)
	print("  héroes: %s · pos del enemigo (escena) %s · TAM_ESCENA %.2f · escena en %s" %
		[c.heroes.map(func(h): return h["nombre"]), f["pos"], c.escena.scale.x, c.escena.position])
	for nombre in elegidas:
		await _opcion(nombre, f)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _a_pantalla(raiz: Node2D, cam: Camera3D, w: Vector3) -> Vector2:
	var local: Vector2 = cam.unproject_position(w) / c.res_personajes
	return c.escena.position + (raiz.position + raiz.scale * local) * c.escena.scale.x


func _opcion(nombre: String, f: Dictionary) -> void:
	var m: Dictionary = BASE.duplicate()
	m.merge(OPCIONES[nombre], true)
	var esc: float = m["esc"]
	var pos: Vector2 = f["pos"]
	if m.has("grupo"):                                       # otra posición del grupo 13 (combate.gd: x · 0,75 − 190)
		pos = Vector2(m["grupo"].x * 0.75 - 190.0, m["grupo"].y)
	var raiz := Node2D.new()
	raiz.scale = Vector2(esc, esc)
	raiz.position = pos
	c.escena.add_child(raiz)
	var f2 := {"nombre": "Bramavidrio", "hero": false, "pos": pos}
	c._crear_rig_3d(f2, m, raiz, pos, esc)
	if m.has("pies_como"):                                   # como _crear_rig: los pies donde los tendría a menor escala
		raiz.position += -f2["cuerpo"].position * (esc - m["pies_como"])
	var p: Node3D = f2["p3d"]
	var cam: Camera3D = f2["cam3d"]
	await _esperar(4)
	if p.anim == null:
		fallos += 1
		print("FALLO: [%s] el modelo no carga" % nombre)
		return
	var vp: Vector2i = m["vp"]
	print("== %s: vp %s, alto_vista %.1f, centro_y %.2f, esc %.2f, pies_como %s; ventana 3D %d × %d px (al %.0f %%)" %
		[nombre, vp, m["alto_vista"], m["centro_y"], esc, str(m.get("pies_como", "—")), int(vp.x * c.res_personajes),
		int(vp.y * c.res_personajes), c.res_personajes * 100.0])
	var esq0 := _a_pantalla(raiz, cam, Vector3.ZERO)
	for pose in POSES:
		p._clip = pose[0]
		p._eventos = []
		p._espera = []
		p.anim.play(pose[0], 0.0)
		p.anim.seek(float(pose[1]), true)
		p._process(0.0)                                       # la luz y el montículo del combate (el combate está quieto)
		await _esperar(2)
		var sk: Skeleton3D = p.skel
		var arriba := INF
		var delante := -INF
		for i in sk.get_bone_count():
			var bn := sk.get_bone_name(i)
			if not (bn.begins_with("col_") or bn.begins_with("mandibula") or bn == "cabeza"):
				continue
			var w: Vector3 = sk.global_transform * sk.get_bone_global_pose(i).origin
			if w.y < 0.0:
				continue
			var s: Vector2 = _a_pantalla(raiz, cam, w + Vector3(0, 1.9 * p.escala, 0))
			arriba = minf(arriba, s.y)
			delante = maxf(delante, _a_pantalla(raiz, cam, w).x)
		var hoc: Vector2 = _a_pantalla(raiz, cam, p.cabeza())
		delante = maxf(delante, hoc.x)
		print("   %-15s %.2f s: agujero (%.0f, %.0f) · lo más alto y=%.0f · lo más adelantado x=%.0f · alto en pantalla %.0f px" %
			[pose[0], pose[1], esq0.x, esq0.y, arriba, delante, esq0.y - arriba])
		await _foto("combate_%s_%s_%.2f" % [nombre, pose[0], pose[1]])
	raiz.queue_free()
	await _esperar(3)
