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

# (17/11, rama area-ciudad-redmi; con «sitios=redmi») los sitios de lo visto en el Redmi el 16/11
# (docs/v12/REDMI_16_11.md): [nombre, x, z] como arriba o [nombre, x, z, x2, z2]: Kael colocado en (x, z) y luego ANDA
# hacia (x2, z2) como tras un toque ahí (destino = _ajustar_destino del punto; la foto, ya parado).
const SITIOS_REDMI := [
	["r01_lonja_pilar_fino_t07", 8.25, 22.0],
	["r02_lonja_pilar_fino_cerca", 8.25, 25.6],
	["r03_soportal_pilar_fino", 4.2, 36.6],
	["r04_rampa_raices_jardinera_t10", 0.0, -64.5, -4.1, -66.0],
	["r05_portico_pilar_t13", 4.2, -82.0],
	["r06_portico_grupo_antes_recarga", 3.4, -82.8],
	["r07_portico_pegado_al_pilar", 0.0, -82.0, 4.4, -80.0],
	["r08_rotulo_pie_calle_arbol", 0.0, -16.0],
	["r09_rotulo_pie_escalinata_plaza", 0.0, 11.0],
	["r10_rotulo_rellano_1", 0.0, -28.0],
	["r11_rotulo_plaza_del_arbol", 0.0, -56.0],
	["r12_rotulo_terraza_raices", -8.0, -81.0],
	["r13_fuente_calle_mayor_a_calle_arbol", 0.0, 28.0, 0.0, -13.5],
	["r14_fuente_desde_el_este", 9.0, 0.0, -9.0, 0.0],
]

# (18/11, con «sitios=v18») lo visto en el Redmi el 18/11 (docs/v12/REDMI_18_11.md, visibilidad): Kael pegado a la
# fachada de su lado tras tocar el edificio ante una puerta (t04_este_5: soportal de la Calle Mayor, casa_e_baja; t02_diag:
# rellano 1 del Barrio Alto, casa_rellano_e) y los rótulos «(en obras)» cortados por lo que tienen delante (la copa del
# árbol de la plaza alta en hoja_perfiles, su propia fachada en los dos de antes, su casa en la Calle del Mercado).
const SITIOS_V18 := [
	["v01_soportal_pegado_casa_e_baja", 6.0, 50.5, 9.5, 50.5],
	["v02_rellano_pegado_casa_rellano_e", 0.0, -28.0, 9.5, -27.0],
	["v03_plaza_rotulo_tras_la_copa", 9.0, -10.0],
	["v04_mercado_rotulo_tras_su_casa", 33.0, 22.5],
]

var perfil := "bajo"
var sitios := "optimiza"
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
		elif a.begins_with("sitios="):
			sitios = a.trim_prefix("sitios=")
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
	_nota("Kael: caja visible %s (ancho en x %.2f m)" % [str(_caja_kael()), _caja_kael().size.x])
	for s in (SITIOS_REDMI if sitios == "redmi" else SITIOS_V18 if sitios == "v18" else SITIOS):
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
		var andar := ""
		if s.size() >= 5:                               # (sitios=redmi) andar hasta (x2, z2) como tras un toque ahí
			await _esperar(0.5)
			var meta := Vector3(s[3], 0.0, s[4])
			meta.y = P.altura(meta.x, meta.z)
			v.destino = v._ajustar_destino(meta)
			var t0 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t0 < 12000 and v.destino != null:
				await process_frame
			var k: Vector3 = v.kael.global_position
			andar = " · anda hacia %s y se para en (%.2f, %.2f, %.2f), a %.2f m" % [str(meta), k.x, k.y, k.z,
				Vector2(k.x - meta.x, k.z - meta.z).length()]
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
		_nota("%s · Kael %s · %d montados %s · %d llamadas · %d primitivas · aclaradas %d %s%s%s" % [s[0], str(v.kael.global_position),
			v.cargador.montados.size(), str(v.cargador.ids_montados()), ll, pr, v.aclarados, str(_aclaradas()), andar, _rotulos()])
	_terminar()


# La caja de lo que se ve de Kael (sus mallas), relativa a sus pies.
func _caja_kael() -> AABB:
	var r := AABB()
	var hay := false
	for m in v.kael.find_children("*", "VisualInstance3D", true, false):
		var c: AABB = (m as VisualInstance3D).global_transform * (m as VisualInstance3D).get_aabb()
		r = c if not hay else r.merge(c)
		hay = true
	r.position -= v.kael.global_position
	return r


# Los rótulos 3D que se dibujan (visibles y más allá de su visibility_range_begin): texto, distancia a la cámara y ancho
# en pantalla (fracción del ancho del cuadro).
func _rotulos() -> String:
	var r: Array = []
	var cam: Camera3D = v.cam
	for l in v.find_children("Rotulo_*", "Label3D", true, false):
		var lb := l as Label3D
		if not lb.is_visible_in_tree():
			continue
		var d := cam.global_position.distance_to(lb.global_position)
		if d < lb.visibility_range_begin - lb.visibility_range_begin_margin or cam.is_position_behind(lb.global_position):
			continue
		var c := lb.get_aabb()
		var a := cam.unproject_position(lb.global_position - cam.global_basis.x * c.size.x * 0.5)
		var b := cam.unproject_position(lb.global_position + cam.global_basis.x * c.size.x * 0.5)
		var vista := root.get_visible_rect().size
		if maxf(a.x, b.x) < 0.0 or minf(a.x, b.x) > vista.x or a.y < 0.0 or a.y > vista.y:
			continue
		r.append("«%s» a %.1f m, %.0f %% del ancho%s" % [lb.text, d, 100.0 * absf(b.x - a.x) / vista.x, _tapa_rotulo(lb, c.size.x)])
	return (" · rótulos: " + ", ".join(r)) if not r.is_empty() else ""


# (18/11) Cuánto del rótulo tapan los bloques opacos (las cajas de los trazados de los sectores montados, sin lo aclarado):
# 9 puntos a lo ancho de su línea central, rayo de la cámara a cada uno. Con no_depth_test, nada («encima»).
func _tapa_rotulo(lb: Label3D, ancho: float) -> String:
	if lb.no_depth_test:
		return " (encima de todo)"
	var cam: Camera3D = v.cam
	var tapados := 0
	var quien := {}
	for i in 9:
		var q := lb.global_position + cam.global_basis.x * ancho * (float(i) / 8.0 - 0.5)
		for id in v.cargador.ids_montados():
			var s: Node = v.cargador.montados[id]
			var t = P.trazado(id)
			var hay := false
			for bl in t.BLOQUES:
				if s.aclarado(String(bl[0])):
					continue
				for c in P.Comun.cajas_bloque(bl):
					if (c as AABB).intersects_segment(cam.global_position, q):
						hay = true
						quien[bl[0]] = true
						break
				if hay:
					break
			if hay:
				tapados += 1
				break
	return " (tapado %d de 9 %s)" % [tapados, str(quien.keys())] if tapados > 0 else " (sin tapar)"


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
