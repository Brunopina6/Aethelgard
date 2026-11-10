extends SceneTree
# Capturas del Claro del Guardián (V9, sector 3D: zonas3d/bosque/claro_guardian.gd) en Pastos Verdes 3D, CON VENTANA.
# No es una prueba: no falla; solo guarda PNG para revisar a ojo. No toca bosque_pastos.gd ni la región: instancia el
# sector encima del claro que ya monta la aventura, como lo haría la línea de integración de _crear_claro().
#   -- 3d sin_prologo salida=<carpeta> estado=dormido|purificado|derrotado [sin_sector] [movil]
# «sin_sector»: el claro de antes (para comparar). «movil»: perfil bajo (versión ligera del sector).
# En «purificado» y «derrotado» se esconden las formas provisionales de bosque_pastos.gd (tocón, brote y charco),
# que el sector sustituye.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const SECTOR := "res://zonas3d/bosque/claro_guardian.gd"
var salida := "user://fotos_claro"
var estado := "dormido"
var con_sector := true
var R
var D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("estado="):
			estado = a.substr(7)
		elif a == "sin_sector":
			con_sector = false
	DirAccess.make_dir_recursive_absolute(salida)
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	var h := {}
	# la aventura con las tres pistas (el Guardián duerme y espera), o ya resuelta
	for id in ["pv_02", "pv_03", "pv_05", "pv_06", "pv_07", "pv_14", "mecha_tilo", "bq_inicio", "bq_arbol", "bq_alquimia",
			"bq_pista_planta", "bq_pista_rastro", "bq_senda", "bq_pista_inscripcion"]:
		h[id] = true
	if estado != "dormido":
		for id in ["bq_pistas", "bq_guardian_visto", "bq_resuelto", "bq_final_visto"]:
			h[id] = true
		Engine.set_meta("decisiones", {"guardian_bosque": estado})
	Engine.set_meta("hitos", h)
	Engine.set_meta("combates_ganados", {"pastos_centinela": true})
	load("res://grupo.gd").unir("Lya")
	load("res://grupo.gd").unir("Garon")
	Engine.set_meta("pos_3d_ok", false)
	change_scene_to_file(REGION)
	_fotos.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await _esperar(10)
	var img := root.get_texture().get_image()
	var ruta := salida.path_join(nombre + ".png")
	img.save_png(ruta)
	print("foto: ", ruta, " ", img.get_size())


func _fotos() -> void:
	for i in 600:
		if current_scene != null and current_scene.scene_file_path == REGION and not R.cambiando:
			break
		await process_frame
	await _esperar(40)
	if D.current_timeline != null:
		D.end_timeline()
	var r = current_scene
	var claro: Node3D = null
	for i in 200:
		for n in r.bosque.get_children():
			if n is Node3D and (n.name == "bq_guardian_dormido" or String(n.name).begins_with("bq_claro_")):
				claro = n
		if claro != null:
			break
		await process_frame
	if claro == null:
		print("FALLO: la aventura no montó el claro")
		quit(1)
		return
	await _esperar(5)
	var centro := claro.global_position
	var sufijo := estado + ("_antes" if not con_sector else "") + ("_movil" if "movil" in OS.get_cmdline_user_args() else "")
	if con_sector and ResourceLoader.exists(SECTOR):
		if estado != "dormido":
			for c in claro.get_children():          # las formas provisionales que el sector sustituye
				if c is Node3D:
					c.visible = false
		var t0 := Time.get_ticks_usec()
		var s = load(SECTOR).crear(r, centro, estado, r.bosque)
		print("sector: ", s.name, " en %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0), " triángulos ", s.get_meta("triangulos", -1))
	r.bosque._claro_armado = false                  # que el Guardián no despierte con las fotos
	# la cámara de juego (vista3d.gd: 45°, 20 m) con Kael en tres sitios, y una vista de conjunto con el zum más abierto
	# que permite el juego (hasta 34 m; aquí 30)
	for toma in [["camino", Vector2(4.0, 8.5), 20.0], ["entrada", Vector2(3.2, 2.6), 20.0],
			["dentro", Vector2(0.9, 2.4), 20.0], ["conjunto", Vector2(0.9, 2.4), 30.0]]:
		var q: Vector2 = toma[1]
		r.distancia = toma[2]
		r._colocar_kael(Vector3(centro.x + q.x, r.altura(centro.x + q.x, centro.z + q.y), centro.z + q.y))
		await _esperar(20)
		await _foto("claro_" + sufijo + "_" + toma[0])
	r.distancia = 20.0
	quit(0)
