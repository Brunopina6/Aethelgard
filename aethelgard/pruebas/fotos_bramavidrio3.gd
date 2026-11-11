extends SceneTree
# Bramavidrio v3 (12/11) en un combate de verdad, con ventana: el combate fijo del grupo 13 (los tres héroes, la
# interfaz y la cámara de _crear_rig_3d) con la versión pedida, y una foto en cada instante clave. No toca combate.gd ni
# combate_bramavidrio.gd: congela el combate y pone al gusano en cada clip con seek (como fotos_bramavidrio_combate.gd).
#   --script res://pruebas/fotos_bramavidrio3.gd -- salida=<carpeta> version=<1|2|3> etiqueta=<nombre>
#        [glb=<ruta de un GLB de fuera> tex=<su textura>]   (las variantes de crear_bramavidrio3.py ... variantes)
#        [orden=1]   además, cada instante con el orden de dibujo propuesto (bramavidrio3_3d.gd, ordenar_en_combate):
#                    «<etiqueta>_<clip>_<s>_antes.png» (el de ahora: el gusano siempre detrás) y «..._despues.png»
#        [heroe_activo=<nombre>]   ese héroe con z_index 5, como cuando actúa (_anim_fisico_3d…)
# Mide y escribe la apertura de la boca y el cierre (labio-mandíbula) en cada foto. No mide rendimiento.

const POSES := [["reposo", 0.0], ["reposo", 1.5], ["rugido", 1.2], ["ataque", 0.6], ["ataque", 1.0], ["ataque", 1.3],
	["ataque_sismico", 1.6], ["ataque_sismico", 2.55], ["ataque_aliento", 1.2], ["ataque_aliento", 2.1], ["herida", 0.15],
	["emerger", 1.2], ["derrota", 3.4]]

var salida := ""
var etiqueta := "v3"
var orden := false
var heroe_activo := ""
var c: Node


func _initialize() -> void:
	var ver := 3
	for a in OS.get_cmdline_user_args():
		var k := a.get_slice("=", 0)
		var v := a.substr(k.length() + 1)
		match k:
			"salida": salida = v
			"version": ver = int(v)
			"etiqueta": etiqueta = v
			"glb": Engine.set_meta("bramavidrio3_glb", v)
			"tex": Engine.set_meta("bramavidrio3_textura", v)
			"orden": orden = v == "1"
			"heroe_activo": heroe_activo = v
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_bramavidrio3")
	DirAccess.make_dir_recursive_absolute(salida)
	Engine.set_meta("bramavidrio_version", ver)
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
	var f: Dictionary = {}
	var p = null
	for i in 600:
		await process_frame
		if not c.enemigos.is_empty() and c.enemigos[0].has("p3d"):
			f = c.enemigos[0]
			p = f["p3d"]
			if p != null and p.anim != null and i > 90 and not p._entrando and p._clip == "reposo":
				break
	if p == null or p.anim == null:
		print("FALLO: el combate no crea el modelo 3D de Bramavidrio")
		quit(1)
		return
	await _esperar(20)
	c.process_mode = Node.PROCESS_MODE_DISABLED
	print("== %s: %s · %s" % [etiqueta, p.get_script().resource_path, Engine.get_meta("bramavidrio3_glb", "(modelo del proyecto)")])
	var rig: Node2D = f["rig"]
	var indice0 := rig.get_index()
	if heroe_activo != "":
		for h in c.heroes:
			if h.get("nombre", "") == heroe_activo and h.has("rig"):
				h["rig"].z_index = 5
	for pose in POSES:
		p._clip = pose[0]
		p._eventos = []
		p._espera = []
		p.anim.play(pose[0], 0.0)
		p.anim.seek(float(pose[1]), true)
		p._process(0.0)
		c.escena.move_child(rig, indice0)
		rig.z_index = 0
		await _esperar(3)
		var info := ""
		if p.has_method("cierre_boca"):
			info = " · boca %.1f°, labio-mandíbula %.3f m" % [p.angulo_boca(), p.cierre_boca()]
		print("   %-15s %.2f s%s" % [pose[0], pose[1], info])
		var base := "%s_%s_%.2f" % [etiqueta, pose[0], pose[1]]
		if orden and p.has_method("ordenar_en_combate"):
			await _foto(base + "_antes")
			p.ordenar_en_combate(c, f)
			print("      orden propuesto: índice %d → %d, z_index %d" % [indice0, rig.get_index(), rig.z_index])
			await _esperar(2)
			await _foto(base + "_despues")
		else:
			await _foto(base)
	print("FALLOS: 0")
	quit(0)
