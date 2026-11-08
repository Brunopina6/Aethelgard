extends SceneTree
# Medición de Pastos Verdes 3D en el PC con el mismo recorrido, para comparar con y sin grupo (o perfiles).
# No es una prueba de regresión: mide. Cada condición se lanza en su propio proceso (memoria limpia):
#   Godot --path aethelgard --script res://pruebas/medir_ruta.gd --fixed-fps 30 -- <carpeta> 3d sin_prologo auto
#         perfil=bajo grupo=si
# Con --fixed-fps cada fotograma avanza 1/30 s de juego: las dos condiciones recorren exactamente los mismos
# fotogramas. Sin tope de FPS (perfil_fps = 0) y sin sincronía vertical: el tiempo de cada fotograma es lo que cuesta.
# Fases: andar por el camino, cruzar el puente (ida y vuelta), interactuar (abrir el cofre y hablar con Tilo), entrar
# en combate (con la carga), unos segundos de combate, volver (con la carga) y andar otra vez.
# Escribe <carpeta>/medicion_<perfil>_<grupo>.json con el equipo, los tiempos por fase y la memoria.

const REGION := "res://zonas3d/pastos_verdes_3d.tscn"

var salida := ""
var perfil := "bajo"
var con_grupo := true
var R
var v
var frames := 0
var fase := ""
var f_fase := 0
var u_ant := 0
var tiempos := {}                                 # fase -> [ms por fotograma]
var trabajo := {}                                 # fase -> [ms de proceso + física]
var memoria := {}                                 # fase -> {...} al terminar la fase
var cargas := {}
var t_carga := 0
var pasos_fase := 0
var abierto_en := -1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0]
	for a in args:
		if a.begins_with("perfil="):
			perfil = a.substr(7)
		elif a.begins_with("grupo="):
			con_grupo = a.substr(6) == "si"
	R = root.get_node("Recursos")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Engine.set_meta("calidad_proto", perfil)
	if not con_grupo:
		Engine.set_meta("calidad_extra", {"grupo": false})
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "pv_05": true})
	Engine.set_meta("combates_ganados", {})
	change_scene_to_file(REGION)
	_fase("carga_region")
	t_carga = Time.get_ticks_usec()


func _fase(n: String) -> void:
	if fase != "" and fase in tiempos:
		memoria[fase] = _memoria()
	fase = n
	f_fase = frames
	if not tiempos.has(n):
		tiempos[n] = []
		trabajo[n] = []


func _memoria() -> Dictionary:
	return {"estatica_mb": OS.get_static_memory_usage() / 1048576.0,
		"video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"texturas_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"buffers_mb": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
		"objetos": Performance.get_monitor(Performance.OBJECT_COUNT),
		"nodos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"dibujos": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitivas": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}


func _escena() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _ir(p: Vector3) -> void:
	v.destino = v._ajustar_destino(Vector3(p.x, v.altura(p.x, p.z), p.z))


func _process(_d: float) -> bool:
	frames += 1
	var ahora := Time.get_ticks_usec()
	if u_ant > 0 and fase in tiempos:
		var ms := (ahora - u_ant) / 1000.0
		tiempos[fase].append(ms)
		if ms > 50.0:                               # dónde cae cada tirón (fase y fotograma dentro de ella)
			print("TIRON %.1f ms en «%s», fotograma %d de la fase" % [ms, fase, frames - f_fase])
		trabajo[fase].append((Performance.get_monitor(Performance.TIME_PROCESS) + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
	u_ant = ahora
	if v != null and is_instance_valid(v) and _escena() == REGION:
		v.perfil_fps = 0                            # sin tope: lo que cuesta cada fotograma
		v.pasos = 0                                 # el encuentro se lanza a mano (fase «combate»), no al azar
	match fase:
		"carga_region":
			if _escena() == REGION and not R.cambiando and frames > 5:
				cargas["region"] = (Time.get_ticks_usec() - t_carga) / 1000.0
				v = current_scene
				_fase("espera")
		"espera":                                   # deja que se asiente (sombras, sombreados, el título)
			if frames - f_fase >= 90:
				_ir(v.SENDERO[3])
				_fase("andar")
		"andar":
			if v.destino == null or frames - f_fase > 600:
				_ir(Vector3(5.3, 0, -2))
				_fase("hasta_puente")
		"hasta_puente":
			if v.destino == null or frames - f_fase > 400:
				_ir(Vector3(12.7, 0, -2))
				pasos_fase = 0
				_fase("puente")
		"puente":
			if v.destino == null or frames - f_fase > 400:
				pasos_fase += 1
				if pasos_fase >= 3:
					_ir(v.cofre.global_position + (Vector3(13.3, 0, -2) - v.cofre.global_position).normalized())
					_fase("interaccion")
				else:
					_ir(Vector3(5.3, 0, -2) if pasos_fase % 2 == 1 else Vector3(12.7, 0, -2))
		"interaccion":
			if v.cerca == "cofre" and v.destino == null and not v.cofre_abierto():
				print("cofre abierto en el fotograma %d de la fase" % (frames - f_fase))
				v._accion()                         # abre el cofre (tapa, destello, sonido, guardado)
				f_fase = frames
			elif v.cofre_abierto() and frames - f_fase == 60:
				var q: Vector3 = v.tilo.global_position + Vector3(1.0, 0, 0.6)
				v._colocar_kael(Vector3(q.x, v.altura(q.x, q.z), q.z))
			elif v.cofre_abierto() and frames - f_fase == 70:
				v._accion()                         # habla con Tilo (diálogo abierto)
			elif v.cofre_abierto() and frames - f_fase == 130:
				root.get_node("Dialogic").end_timeline()
			elif v.cofre_abierto() and frames - f_fase == 160:
				v._encuentro()
				t_carga = Time.get_ticks_usec()
				_fase("entrada_combate")
			elif frames - f_fase > 900:
				_fase("entrada_combate")
		"entrada_combate":
			if _escena() == "res://combate.tscn" and not R.cambiando:
				cargas["combate"] = (Time.get_ticks_usec() - t_carga) / 1000.0
				_fase("combate")
		"combate":
			if frames - f_fase >= 150:
				current_scene._volver_al_mapa()
				t_carga = Time.get_ticks_usec()
				_fase("vuelta")
		"vuelta":
			if _escena() == REGION and not R.cambiando and frames - f_fase > 5:
				cargas["vuelta_region"] = (Time.get_ticks_usec() - t_carga) / 1000.0
				v = current_scene
				_fase("tras_volver")
		"tras_volver":
			if frames - f_fase == 30:
				_ir(v.SENDERO[2])
			elif frames - f_fase > 30 and (v.destino == null or frames - f_fase > 400):
				return _terminar()
	if frames > 20000:
		return _terminar()
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
	var med: float = o[n / 2]
	var picos := 0
	for x in lista:
		if x > maxf(med * 2.0, 50.0):
			picos += 1
	return {"fotogramas": n, "media": suma / n, "mediana": med, "p95": o[mini(n - 1, int(n * 0.95))],
		"p99": o[mini(n - 1, int(n * 0.99))], "max": o[n - 1], "picos": picos}


func _terminar() -> bool:
	memoria[fase] = _memoria()
	var commit := []
	OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "--short", "HEAD"], commit)
	var info := {"perfil": perfil, "grupo": con_grupo, "commit": (commit[0].strip_edges() if commit.size() > 0 else "?"),
		"fecha": Time.get_datetime_string_from_system(), "godot": Engine.get_version_info()["string"],
		"cpu": OS.get_processor_name(), "nucleos": OS.get_processor_count(),
		"gpu": RenderingServer.get_video_adapter_name(), "gpu_marca": RenderingServer.get_video_adapter_vendor(),
		"api": RenderingServer.get_video_adapter_api_version(), "ram_mb": OS.get_memory_info().get("physical", 0) / 1048576.0,
		"ventana": DisplayServer.window_get_size(), "cargas_ms": cargas, "fases": {}}
	for f in tiempos:
		info["fases"][f] = {"tiempo_ms": _resumen(tiempos[f]), "proceso_y_fisica_ms": _resumen(trabajo[f]), "memoria": memoria.get(f, {})}
	var ruta := "%s/medicion_%s_%s.json" % [salida, perfil, "con_grupo" if con_grupo else "sin_grupo"]
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))
	f.close()
	print("MEDICION %s %s: %s" % [perfil, "con grupo" if con_grupo else "sin grupo", ruta])
	quit(0)
	return true
