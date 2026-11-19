extends SceneTree
# Capturas de «El bosque que no recuerda» (fase 3) para revisar a ojo: CON VENTANA. «-- salida=<carpeta>».
# La región con la aventura a medias (pistas, senda abierta), Kael junto a cada sitio, la pantalla de alquimia y el
# claro tras purificar. No es una prueba: no falla; solo guarda PNG.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
var salida := "user://fotos_bosque"
var R
var D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	DirAccess.make_dir_recursive_absolute(salida)
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	var h := {}
	for id in ["pv_02", "pv_03", "pv_05", "pv_06", "pv_07", "pv_14", "mecha_tilo", "bq_inicio", "bq_arbol", "bq_alquimia",
			"bq_pista_planta", "bq_pista_rastro", "bq_senda"]:
		h[id] = true
	Engine.set_meta("hitos", h)
	Engine.set_meta("combates_ganados", {"pastos_centinela": true})
	load("res://grupo.gd").unir("Lya")
	load("res://grupo.gd").unir("Garon")
	load("res://inventario.gd").agregar_objeto("Hierba lunar", 3)
	load("res://inventario.gd").agregar_objeto("Musgo de piedra", 2)
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	_fotos.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await _esperar(8)
	var img := root.get_texture().get_image()
	img.save_png(salida.path_join(nombre + ".png"))
	print("foto: ", nombre)


func _fotos() -> void:
	# (19/11, PC-10) por RELOJ (antes, 600 fotogramas, y al agotarse se seguía con la escena que hubiera)
	var t0 := Time.get_ticks_msec()
	while not (current_scene != null and current_scene.scene_file_path == REGION and not R.cambiando):
		if Time.get_ticks_msec() - t0 > 60000:
			print("FALLO: la región no se monta en 60 s (R.cambiando=%s, escena %s)" % [R.cambiando,
				current_scene.scene_file_path if current_scene != null else "(ninguna)"])
			print("FALLOS: 1")
			quit(1)
			return
		await process_frame
	await _esperar(40)
	if D.current_timeline != null:
		D.end_timeline()
	var r = current_scene
	for i in 100:
		if r.bosque.puntos.size() > 0:
			break
		await process_frame
	await _esperar(20)
	for id in ["arbol", "lirios", "surcos", "inscripcion", "manantial", "rec:bq_rec_savia_1", "rec:bq_rec_musgo_1"]:
		for p in r.bosque.puntos:
			if p["id"] == id and is_instance_valid(p["nodo"]):
				r._colocar_kael(p["nodo"].global_position + Vector3(1.4, 0, 1.4))
				await _esperar(10)
				r._comprobar_cerca()
				await _foto("bosque_" + id.replace(":", "_"))
	if r.bosque.guardian != null:
		r._colocar_kael(r.bosque.guardian.global_position + Vector3(4.5, 0, 4.5))
		await _foto("bosque_guardian_dormido")
	r.bosque.abrir_alquimia()
	await _foto("alquimia_recetas")
	r.bosque.alquimia.pestana = "Investigar"
	r.bosque.alquimia._pintar()
	await _foto("alquimia_investigar")
	r.bosque.alquimia.cerrar_menu()
	quit(0)
