extends SceneTree
# Medición de los tirones de «la primera vez» en el PC: el primer diálogo y lo primero que se dibuja al explorar.
# No es una prueba de regresión: mide. Un proceso por condición:
#   Godot --path aethelgard --script res://pruebas/medir_primeras_veces.gd --fixed-fps 30 -- <carpeta> 3d sin_prologo
#         perfil=bajo nombre=<etiqueta> [dialogos=antes] [vaiven=N] [grupo=no] [oclusion=no] [firmas=si] [foto=si]
# «dialogos=antes» reproduce cómo era antes del arreglo de los diálogos, para comparar en el mismo código: la interfaz
# de Dialogic se borra al acabar cada diálogo («dialogic/layout/end_behaviour» = 0), la pantalla de carga no lee su
# estilo en segundo plano (se quita de su lista antes de que empiece) y se salta su paso «dialogos» (no la prepara).
# Para atribuir tirones: «vaiven=N» va y vuelve N veces por el primer tramo (¿cuesta cada vez o solo la primera?),
# «grupo=no» quita a Lya y Garon, «oclusion=no» hace que nada se vuelva transparente y «firmas=si» apunta una firma
# aproximada del material de lo que tapa a Kael. En el PC, sonda_aislada o ejecutar_pruebas (datos aislados), con ventana.
# Empieza como el juego: la pantalla de carga (carga.tscn, con todo lo que prepara) y después Pastos Verdes 3D con el
# cambio de escena del juego (Recursos.cambiar_escena). En la región hace el mismo recorrido dos veces:
#   pasada 1: la primera vez en esta ejecución (todo se carga, se compila y se dibuja por primera vez);
#   pasada 2: un recorrido posterior (se vuelve a entrar en la región).
# Cada recorrido: andar por el camino, cruzar el puente, abrir el cofre y dos diálogos seguidos con Tilo.
# Arranque en frío o con caché: Godot guarda los sombreados compilados en user://. Con una carpeta de datos nueva es
# como la primera vez tras instalar; repitiendo con la misma carpeta, un arranque posterior (sonda_aislada.ps1 -Carpeta).
# Junto a cada tirón (> 20 ms; aquí un fotograma normal tarda unos 3 ms) apunta en qué paso cae, si hay un diálogo
# abierto y cuántas piezas acaban de volverse transparentes por tapar a Kael (vista3d.gd, _oclusion).
# Cada fotograma se apunta al paso en que se hizo su trabajo: el que había al terminar el _process anterior.
# Escribe <carpeta>/primeras_veces_<nombre>.json.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const CARGA := "res://carga.tscn"
const UMBRAL_MS := 20.0

var salida := ""
var nombre := "medicion"
var perfil := "bajo"
var R
var D
var v
var pasada := 0
var frames := 0
var paso := ""
var f_paso := 0
var u_ant := 0
var etiqueta := ""                                # a qué paso se apunta el fotograma que empieza
var f_etiqueta := 0
var por_paso := {}                                # etiqueta -> [ms]
var tirones: Array = []
var oclusiones: Array = []                        # fotogramas en que algo empieza o deja de tapar a Kael
var series := {}                                  # al andar: [fotograma, ms, ms de CPU dibujando, ms de GPU, piezas tapando]
var t_carga := 0
var cargas := {}
var tap_prev: Array = []
var firmas_vistas := {}
var dialogos: Array = []
var dialogo := {}
var dirs_al_empezar: PackedStringArray
var como_antes := false
var sin_oclusion := false
var vaivenes := 0
var con_firmas := false                           # «firmas=si»: firma aproximada del material de lo que tapa
var con_foto := false
var vaiven_hechos := 0
var salida_kael := Vector3.ZERO


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0]
	for a in args:
		if a.begins_with("perfil="):
			perfil = a.substr(7)
		elif a.begins_with("nombre="):
			nombre = a.substr(7)
		elif a == "dialogos=antes":
			como_antes = true
		elif a == "grupo=no":                       # sin Lya ni Garon siguiendo a Kael (para atribuir tirones)
			Engine.set_meta("calidad_extra", {"grupo": false})
		elif a == "oclusion=no":                    # nada se vuelve transparente (para atribuir tirones)
			sin_oclusion = true
		elif a == "firmas=si":
			con_firmas = true
		elif a == "foto=si":                        # captura de cada diálogo con el texto ya escrito
			con_foto = true
		elif a.begins_with("vaiven="):              # ir y volver N veces por el primer tramo (¿cuesta cada vez?)
			vaivenes = int(a.substr(7))
	if como_antes:
		ProjectSettings.set_setting("dialogic/layout/end_behaviour", 0)
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	dirs_al_empezar = DirAccess.get_directories_at("user://")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(CARGA)
	t_carga = Time.get_ticks_usec()
	_paso("carga_juego")


func _paso(n: String) -> void:
	paso = n
	f_paso = frames


func _ir(p: Vector3) -> void:
	v.destino = v._ajustar_destino(Vector3(p.x, v.altura(p.x, p.z), p.z))


func _ir_a_region() -> void:
	pasada += 1
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("combates_ganados", {})
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})
	if Engine.has_meta("cofres_abiertos"):
		Engine.remove_meta("cofres_abiertos")
	v = null
	tap_prev = []
	t_carga = Time.get_ticks_usec()
	R.cambiar_escena(REGION)
	_paso("entrar")


# Aproximación a la «clave» con que Godot hace un sombreado por material: piezas con la misma firma comparten sombreado.
func _firma(mi: MeshInstance3D) -> String:
	var m := mi.get_meta("mat_opaco", mi.material_override) as StandardMaterial3D
	if m == null:
		return "?"
	return "%d %d %d %s %s %d %s %d" % [m.transparency, m.shading_mode, m.cull_mode,
		m.vertex_color_use_as_albedo, m.albedo_texture != null, m.texture_filter, m.normal_enabled, m.depth_draw_mode]


func _process(_d: float) -> bool:
	frames += 1
	var ahora := Time.get_ticks_usec()
	var nuevos := 0
	var salen := 0
	var firmas_nuevas := 0
	if v != null and is_instance_valid(v) and current_scene == v:
		var tap: Array = v.tapados
		for mi in tap:
			if is_instance_valid(mi) and not tap_prev.has(mi):
				nuevos += 1
				if con_firmas:
					var fi := _firma(mi)
					if not firmas_vistas.has(fi):
						firmas_vistas[fi] = true
						firmas_nuevas += 1
		for mi in tap_prev:
			if not tap.has(mi):
				salen += 1
		tap_prev = tap.duplicate()
	if u_ant > 0 and etiqueta != "":
		var ms := (ahora - u_ant) / 1000.0
		if nuevos > 0 or salen > 0:                 # cada vez que algo se vuelve transparente o deja de serlo
			oclusiones.append({"donde": etiqueta, "fotograma": f_etiqueta, "ms": snappedf(ms, 0.1), "entran": nuevos,
				"salen": salen})
		if etiqueta.ends_with("andar") or etiqueta.ends_with("hasta_puente"):   # fotograma a fotograma al andar
			var proc := RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()) + RenderingServer.get_frame_setup_time_cpu()
			var gpu := RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
			if not series.has(etiqueta):
				series[etiqueta] = []
			series[etiqueta].append([f_etiqueta, snappedf(ms, 0.1), snappedf(proc, 0.1), snappedf(gpu, 0.1), tap_prev.size()])
		if not por_paso.has(etiqueta):
			por_paso[etiqueta] = []
		por_paso[etiqueta].append(ms)
		if not dialogo.is_empty() and etiqueta.ends_with(dialogo["paso"]):
			if f_etiqueta >= 10 and f_etiqueta < 40:
				dialogo["abrir_max_ms"] = maxf(dialogo["abrir_max_ms"], ms)
			elif f_etiqueta >= 55 and f_etiqueta < 85:
				dialogo["cerrar_max_ms"] = maxf(dialogo["cerrar_max_ms"], ms)
		if ms > UMBRAL_MS and not etiqueta.begins_with("carga"):
			tirones.append({"donde": etiqueta, "fotograma": f_etiqueta, "ms": snappedf(ms, 0.1),
				"dialogo_abierto": D.current_timeline != null, "tapados_nuevos": nuevos, "firmas_nuevas": firmas_nuevas})
	u_ant = ahora
	if paso != "carga_juego":
		Engine.max_fps = 0                          # sin tope: lo que cuesta cada fotograma
	if v != null and is_instance_valid(v) and current_scene == v:
		v.perfil_fps = 0
		v.pasos = 0                                 # sin encuentros al azar
	match paso:
		"carga_juego":
			var c := current_scene
			if c != null and c.scene_file_path == CARGA:
				if not cargas.has("estilo_en_la_lista"):          # primer fotograma con la pantalla, antes de su _process
					var estilo: String = R.ruta_estilo_dialogos()
					cargas["estilo_en_la_lista"] = c.pendientes.has(estilo)
					if como_antes and c.pendientes.has(estilo) and c.en_curso.is_empty() and c.hechos == 0:
						c.pendientes.remove_at(c.pendientes.find(estilo))
						c.total = maxi(1, c.pendientes.size())
						cargas["estilo_quitado"] = true
				if como_antes and c.fase == "dialogos":
					c.fase = "zonas"                # este _process va antes que el de la pantalla: se salta el paso
				if c.fase == "fin" and not cargas.has("pantalla_trabajo_ms"):
					cargas["pantalla_trabajo_ms"] = (Time.get_ticks_usec() - t_carga) / 1000.0
				if c.listo:
					cargas["pantalla_lista_ms"] = (Time.get_ticks_usec() - t_carga) / 1000.0
					cargas["estilo_leido_en_la_carga"] = R.esta(R.ruta_estilo_dialogos())
					_ir_a_region()
		"entrar":
			if v == null and current_scene != null and current_scene.scene_file_path == REGION:
				v = current_scene
			if v != null and not R.cambiando:
				cargas["region_%d_ms" % pasada] = (Time.get_ticks_usec() - t_carga) / 1000.0
				_paso("asentarse")
		"asentarse":
			if sin_oclusion and frames - f_paso == 1:
				for n in get_nodes_in_group("ocluye"):
					n.remove_from_group("ocluye")
			if frames - f_paso >= 60:
				salida_kael = v.kael.global_position
				vaiven_hechos = 0
				_ir(v.SENDERO[3])
				_paso("andar")
		"andar", "vaiven":
			if v.destino == null or frames - f_paso > 600:
				if vaiven_hechos < vaivenes * 2:
					vaiven_hechos += 1
					_ir(salida_kael if vaiven_hechos % 2 == 1 else v.SENDERO[3])
					_paso("vaiven")
				else:
					_ir(Vector3(5.3, 0, -2))
					_paso("hasta_puente")
		"hasta_puente":
			if v.destino == null or frames - f_paso > 400:
				_ir(Vector3(12.7, 0, -2))
				_paso("puente")
		"puente":
			if v.destino == null or frames - f_paso > 400:
				_ir(v.cofre.global_position + (Vector3(13.3, 0, -2) - v.cofre.global_position).normalized())
				_paso("hasta_cofre")
		"hasta_cofre":
			if v.cerca == "cofre" and v.destino == null:
				v._accion()                         # abre el cofre: tapa, destello y sonido
				_paso("cofre")
			elif frames - f_paso > 400:
				_paso("cofre")
		"cofre":
			if frames - f_paso == 60:
				var q: Vector3 = v.tilo.global_position + Vector3(1.0, 0, 0.6)
				v._colocar_kael(Vector3(q.x, v.altura(q.x, q.z), q.z))
				_paso("dialogo_1")
		"dialogo_1", "dialogo_2":
			var f := frames - f_paso
			if f == 10:
				var lay = D.Styles.get_layout_node() if D.has_subsystem("Styles") else null
				dialogo = {"pasada": pasada, "paso": paso, "interfaz_ya_hecha": lay != null, "abierto": false,
					"abrir_max_ms": 0.0, "cerrar_max_ms": 0.0}
				dialogos.append(dialogo)
				v._accion()                         # habla con Tilo
			elif f == 30:
				dialogo["abierto"] = D.current_timeline != null and v.dialogo_actual != ""
			elif f == 50 and con_foto:
				root.get_texture().get_image().save_png("%s/%s_%d_%s.png" % [salida, nombre, pasada, paso])
			elif f == 55:
				D.end_timeline()
			elif f == 85:
				if paso == "dialogo_1":
					_paso("dialogo_2")
				elif pasada == 1:
					_ir_a_region()
				else:
					return _terminar()
	if frames > 20000:
		return _terminar()
	var c2 := current_scene
	if paso == "carga_juego" and c2 != null and c2.scene_file_path == CARGA:
		etiqueta = "carga·" + str(c2.fase)
	else:
		etiqueta = "%d·%s" % [pasada, paso]
	f_etiqueta = frames - f_paso
	return false


func _resumen(lista: Array) -> Dictionary:
	if lista.is_empty():
		return {}
	var o := lista.duplicate()
	o.sort()
	var suma := 0.0
	for x in o:
		suma += x
	var n := o.size()
	return {"fotogramas": n, "suma_ms": snappedf(suma, 0.1), "mediana": snappedf(o[n / 2], 0.01),
		"p95": snappedf(o[mini(n - 1, int(n * 0.95))], 0.01), "max": snappedf(o[n - 1], 0.1)}


func _terminar() -> bool:
	var commit := []
	OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "--short", "HEAD"], commit)
	var info := {"nombre": nombre, "perfil": perfil, "como_antes": como_antes,
		"commit": (commit[0].strip_edges() if commit.size() > 0 else "?"),
		"fecha": Time.get_datetime_string_from_system(), "godot": Engine.get_version_info()["string"],
		"gpu": RenderingServer.get_video_adapter_name(), "api": RenderingServer.get_video_adapter_api_version(),
		"dialogic_end_behaviour": ProjectSettings.get_setting("dialogic/layout/end_behaviour", 0),
		"carpetas_user_al_empezar": dirs_al_empezar, "carpetas_user_al_terminar": DirAccess.get_directories_at("user://"),
		"cargas_ms": cargas, "dialogos": dialogos, "tirones": tirones, "oclusiones": oclusiones, "series_andar": series,
		"pasos": {}}
	for k in por_paso:
		info["pasos"][k] = _resumen(por_paso[k])
	var ruta := "%s/primeras_veces_%s.json" % [salida, nombre]
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))
	f.close()
	print("CARGAS: ", cargas)
	for d in dialogos:
		print("DIALOGO pasada %d %s: abierto=%s interfaz_ya_hecha=%s abrir max %.1f ms, cerrar max %.1f ms" % [d["pasada"],
			d["paso"], d["abierto"], d["interfaz_ya_hecha"], d["abrir_max_ms"], d["cerrar_max_ms"]])
	for t in tirones:
		print("TIRON %s fotograma %d: %.1f ms  dialogo=%s tapados_nuevos=%d firmas_nuevas=%d" % [t["donde"], t["fotograma"],
			t["ms"], t["dialogo_abierto"], t["tapados_nuevos"], t["firmas_nuevas"]])
	for o in oclusiones:
		print("OCLUSION %s fotograma %d: %.1f ms  entran=%d salen=%d" % [o["donde"], o["fotograma"], o["ms"], o["entran"],
			o["salen"]])
	for k in series:
		var linea := "SERIE %s (fotograma:ms/cpu_dibujo/gpu/tapando):" % k
		for s in series[k]:
			if s[1] > 6.0 or s[4] > 0:
				linea += " %d:%.1f/%.1f/%.1f/%d" % s
		print(linea)
	for k in info["pasos"]:
		var r: Dictionary = info["pasos"][k]
		if not r.is_empty():
			print("PASO %s: %d fotogramas, mediana %.2f, p95 %.2f, max %.1f, suma %.0f ms" % [k, r["fotogramas"], r["mediana"],
				r["p95"], r["max"], r["suma_ms"]])
	print("MEDICION: ", ruta)
	quit(0)
	return true
