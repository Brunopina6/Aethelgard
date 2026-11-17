extends SceneTree
# CAPTURAS (16/11, optimización de la ciudad), NO prueba (no va en lista_pruebas.txt): la CIUDAD COMPLETA de Oakhaven
# (maqueta EXPERIMENTAL, zonas3d/ciudad/, solo desde el banco de pruebas) en SITIOS fijos con la MISMA cámara, para comparar
# antes / después de un cambio (docs/v12/ciudad_sectores/MEDIDAS_PC.md §6). En cada sitio: Kael colocado, el grupo detrás,
# 1,5 s para que se asiente (cargas, aclarados y su sostén), captura PNG del viewport, llamadas y primitivas, y las piezas
# ACLARADAS (por nombre: vale con el sector de antes, una malla por ocultable, y con el de después, aclarado(id)).
# Con «comparar=<carpeta A>,<carpeta B>» no abre la ciudad: compara las capturas del mismo nombre (píxeles que cambian más
# de 8/255 en algún canal y la diferencia media) y escribe la imagen de diferencias.
# Uso (APPDATA y LOCALAPPDATA aislados; la partida es la del banco, en user://):
#   Godot --path aethelgard --resolution 1600x720 --script res://pruebas/fotos_ciudad_optimiza.gd -- perfil=bajo|medio|alto
#     salida=<carpeta fuera del proyecto> [escala=1.0]
#   Godot --path aethelgard --headless --script res://pruebas/fotos_ciudad_optimiza.gd -- comparar=<A>,<B> salida=<C>

const ESCENA := "res://zonas3d/ciudad/ciudad.tscn"
const P := preload("res://zonas3d/ciudad/plano.gd")
const Blockout := preload("res://zonas3d/ciudad/blockout.gd")
# [nombre, x, z]: Kael en el suelo del plano en (x, z), que ha de ser ANDABLE (P.andable; si no, se avisa y se le pone en
# lo andable más cercano). (Revisión del 16/11: 1, 3 y 7 no lo eran; corregidos a lo andable más cercano, 0,8-2,75 m. El 3
# es el solape de dos aclaradas de la Plaza y el 8, la Rampa de los Carros con 5 aclaradas: comprueban el orden de lejos
# a cerca de «Aclarados», sector.gd.)
const SITIOS := [
	["1_terrazas_bajo_alero_tejadillo_lavadero", -60.0, -70.3],
	["2_terrazas_paso_bajo_casa_puente", -63.0, -51.0],
	["3_plaza_casa_sur_aclarada", 15.0, 26.85],
	["4_pasajes_junto_al_arco", -39.9, 80.1],
	["5_caravanas_terraza_mas_llamadas", -25.3, 83.5],
	["6_pasajes_paso_de_la_botica", -31.9, 56.1],
	["7_plaza_bajo_toldo_flores", 9.7, -3.8],
	["8_rampa_de_los_carros", 44.0, 79.0],
	["9_plaza_toldo_puesto", -10.8, 15.6],
]

var perfil := "bajo"
var salida := ""
var escala := -1.0
var comparar := ""
var lineas: PackedStringArray = []
var v


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
		elif a.begins_with("escala="):
			escala = float(a.trim_prefix("escala="))
		elif a.begins_with("comparar="):
			comparar = a.trim_prefix("comparar=")
	if comparar != "":
		_comparar.call_deferred()
		return
	Engine.set_meta("calidad_proto", perfil)
	if escala > 0.0:
		Engine.set_meta("calidad_extra", {"escala_3d": escala})
	_fotos.call_deferred()


func _nota(t: String) -> void:
	print(t)
	lineas.append(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _esperar(seg: float) -> void:
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < int(seg * 1000000.0):
		await process_frame


func _aclaradas() -> Array:
	var r: Array = []
	var claro: Material = Blockout.material(true)
	for id in v.cargador.ids_montados():
		var s: Node = v.cargador.montados[id]
		for o in s.ocultables:
			if s.has_method("aclarado"):
				if s.aclarado(String(o[0])):
					r.append("%s/%s" % [id, o[0]])
			elif (o[0] as MeshInstance3D).material_override == claro:
				r.append("%s/%s" % [id, String((o[0] as Node).name).trim_prefix("Ocultable_")])
	r.sort()
	return r


func _fotos() -> void:
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()
	BP.poner_grupo(BP.EXPLORAR["ciudad"]["activos"])
	change_scene_to_file(ESCENA)
	for i in 600:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
			v = current_scene
			break
	if v == null:
		_nota("FALLO: la ciudad no abre")
		_terminar()
		return
	await _esperar(2.0)
	DirAccess.make_dir_recursive_absolute(salida)
	_nota("FOTOS perfil %s · escala %.2f · ventana %s · %s" % [perfil, root.scaling_3d_scale, str(DisplayServer.window_get_size()),
		Time.get_datetime_string_from_system()])
	for s in SITIOS:
		var p := Vector3(s[1], 0.0, s[2])
		if not P.andable(p.x, p.z):
			var mejor := p
			var dm := INF
			for ix in range(-12, 13):
				for iz in range(-12, 13):
					var q := p + Vector3(ix * 0.25, 0.0, iz * 0.25)
					if P.andable(q.x, q.z) and p.distance_to(q) < dm:
						dm = p.distance_to(q)
						mejor = q
			_nota("AVISO: %s no es andable; Kael en %s (corrige SITIOS)" % [s[0], str(mejor)])
			p = mejor
		p.y = P.altura(p.x, p.z)
		v.destino = null
		v._colocar_kael(p)
		if v.grupo != null:
			v.grupo.colocar(Vector3.BACK)
		var fd0 := Engine.get_frames_drawn()
		var fp0 := Engine.get_process_frames()
		await _esperar(1.5)
		await _frames(2)
		var dib := Engine.get_frames_drawn() - fd0
		var pro := Engine.get_process_frames() - fp0
		if dib < pro * 0.9:
			_nota("AVISO: en %s la ventana dibujó %d de %d fotogramas (¿minimizada u oculta?): esta captura NO VALE" % [s[0], dib, pro])
		var RS := RenderingServer
		var ll := RS.get_rendering_info(RS.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var pr := RS.get_rendering_info(RS.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var img := root.get_texture().get_image()
		img.save_png(salida.path_join(String(s[0]) + ".png"))
		_nota("%s · Kael %s · %d montados %s · %d llamadas · %d primitivas · aclaradas %d %s" % [s[0], str(v.kael.global_position),
			v.cargador.montados.size(), str(v.cargador.ids_montados()), ll, pr, v.aclarados, str(_aclaradas())])
	_terminar()


func _comparar() -> void:
	var dirs := comparar.split(",")
	DirAccess.make_dir_recursive_absolute(salida)
	for f in DirAccess.get_files_at(dirs[0]):
		if not f.ends_with(".png") or not FileAccess.file_exists(dirs[1].path_join(f)):
			continue
		var a := Image.load_from_file(dirs[0].path_join(f))
		var b := Image.load_from_file(dirs[1].path_join(f))
		if a.get_size() != b.get_size():
			_nota("%s: tamaños distintos %s / %s" % [f, a.get_size(), b.get_size()])
			continue
		a.convert(Image.FORMAT_RGB8)
		b.convert(Image.FORMAT_RGB8)
		var da := a.get_data()
		var db := b.get_data()
		var dif := Image.create(a.get_width(), a.get_height(), false, Image.FORMAT_L8)
		var dd := PackedByteArray()
		dd.resize(a.get_width() * a.get_height())
		var cambian := 0
		var suma := 0.0
		for i in dd.size():
			var m := maxi(maxi(absi(da[i * 3] - db[i * 3]), absi(da[i * 3 + 1] - db[i * 3 + 1])), absi(da[i * 3 + 2] - db[i * 3 + 2]))
			suma += m
			if m > 8:
				cambian += 1
			dd[i] = mini(255, m * 4)
		dif.set_data(a.get_width(), a.get_height(), false, Image.FORMAT_L8, dd)
		dif.save_png(salida.path_join("dif_" + f))
		_nota("%s: %.2f %% de píxeles cambian más de 8/255 · diferencia media %.3f/255" % [f, 100.0 * cambian / dd.size(), suma / dd.size()])
	_terminar()


func _terminar() -> void:
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		var f := FileAccess.open(salida.path_join("fotos_%s.txt" % (perfil if comparar == "" else "comparacion")), FileAccess.WRITE)
		f.store_string("\n".join(lineas) + "\n")
		f.close()
	quit(0)
