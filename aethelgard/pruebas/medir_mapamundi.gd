extends SceneTree
# MEDIDA del mapamundi (T-085, fase 2): carga, tiempo por fotograma (quieto y andando), memoria de vídeo y estática,
# del mapa de siempre («antes») y del pintado («después»), con y sin agua animada. NO es una prueba de regresión:
# solo vale en un hueco SIN OTRA CARGA en el PC (lo decide el coordinador) y comparando condiciones de la misma tanda.
# Un proceso por condición y repetición (lo lanza medir_mapamundi.ps1, con datos aislados y en orden alterno):
#   Godot --path aethelgard --script res://pruebas/medir_mapamundi.gd --fixed-fps 30 -- <carpeta> condicion=<nombre>
#         [mapa_clasico] [agua_quieta] [3d] [ventana=1280x720] [fotogramas=600] sin_prologo
# Con --fixed-fps cada fotograma avanza 1/30 s de juego (el agua, la cámara y Kael hacen lo mismo en cada condición);
# sin sincronía vertical y sin tope de FPS: el tiempo real de cada fotograma es lo que cuesta.
# Fases:
#   base     30 fotogramas sin escena (la memoria de partida);
#   carga    de change_scene_to_file(mapa.tscn) al primer fotograma dibujado del mapa (incluye generar el terreno en
#            el de siempre o leer la máscara en el pintado, cargar las texturas y compilar los sombreados);
#   asiento  90 fotogramas sin medir;
#   quieto   <fotogramas> con Kael donde empieza (la vista al abrir el mapa);
#   andando  <fotogramas> con Kael recorriendo a 220 px/s la ruta Oakhaven → Gran Bosque → Garganta → Cumbres → Mar de
#            Arena → Sunken City (sin choques ni encuentros: solo se mueve el dibujo; la cámara, sin suavizado).
# Escribe <carpeta>/<condicion>.json: equipo, ventana, carga (ms), tiempos por fotograma de cada fase (mediana, media,
# p95, p99 y peor, en ms, y el trabajo de scripts), memoria (estática, vídeo, texturas, buffers) en cada fase,
# llamadas de dibujo y, si el controlador lo da, el tiempo de GPU del viewport.

const MAPA := "res://mapa.tscn"
const RUTA := [Vector2(520, 385), Vector2(720, 560), Vector2(1030, 680), Vector2(1250, 300), Vector2(1700, 430),
	Vector2(1930, 610)]
const VELOCIDAD := 220.0

var salida := ""
var condicion := "sin_nombre"
var n_fotogramas := 600
var ventana := Vector2i(1280, 720)
var fase := ""
var f_fase := 0
var u_ant := 0
var tiempos := {}                 # fase -> [ms por fotograma, reales]
var trabajo := {}                 # fase -> [ms de proceso (scripts)]
var gpu := {}                     # fase -> [ms de GPU del viewport, si el controlador los da]
var memoria := {}                 # fase -> {...}
var carga_ms := 0.0
var t_carga := 0
var m                             # el mapa
var tramo := 0
var dibujos := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("condicion="):
			condicion = a.substr(10)
		elif a.begins_with("fotogramas="):
			n_fotogramas = int(a.substr(11))
		elif a.begins_with("ventana="):
			var p := a.substr(8).split("x")
			ventana = Vector2i(int(p[0]), int(p[1]))
		elif salida == "" and not "=" in a and not a in ["mapa_clasico", "agua_quieta", "3d", "sin_prologo"]:
			salida = a
	if salida == "":
		print("FALLO: falta la carpeta de salida")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(ventana)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	_fase("base")


func _fase(n: String) -> void:
	if fase != "":
		memoria[fase] = _memoria()
	fase = n
	f_fase = _frames()
	if not tiempos.has(n):
		tiempos[n] = []
		trabajo[n] = []
		gpu[n] = []


func _frames() -> int:
	return Engine.get_process_frames()


func _memoria() -> Dictionary:
	return {"estatica_mb": OS.get_static_memory_usage() / 1048576.0,
		"estatica_max_mb": OS.get_static_memory_peak_usage() / 1048576.0,
		"video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"texturas_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"buffers_mb": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
		"objetos": Performance.get_monitor(Performance.OBJECT_COUNT),
		"nodos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}


func _process(_d: float) -> bool:
	Engine.max_fps = 0                              # Recursos pone 30 en el mapa: aquí, sin tope
	var ahora := Time.get_ticks_usec()
	if u_ant > 0 and fase in ["quieto", "andando"]:
		tiempos[fase].append((ahora - u_ant) / 1000.0)
		trabajo[fase].append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		var g := RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		if g > 0.0:
			gpu[fase].append(g)
		dibujos[fase] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	u_ant = ahora
	var f := _frames() - f_fase
	match fase:
		"base":
			if f >= 30:
				_fase("carga")
				t_carga = Time.get_ticks_usec()
				change_scene_to_file(MAPA)
		"carga":
			if current_scene != null and current_scene.get("jugador") != null:
				m = current_scene
				_esperar_dibujo.call_deferred()
				_fase("esperando_dibujo")
		"asiento":
			if f >= 90:
				_colocar(RUTA[0])
				_fase("quieto")
		"quieto":
			if f >= n_fotogramas:
				tramo = 1
				_fase("andando")
		"andando":
			_andar()
			if f >= n_fotogramas:
				_fase("fin")
				_terminar()
	return false


func _esperar_dibujo() -> void:
	await RenderingServer.frame_post_draw
	carga_ms = (Time.get_ticks_usec() - t_carga) / 1000.0
	m.en_encuentro = true                           # sin encuentros, sin entrada ni «Entrar»: solo se dibuja
	m.camara.position_smoothing_enabled = false
	var fps = root.get_node("Recursos").get("lbl_fps")
	if fps != null:
		fps.visible = false                         # el contador de depuración, fuera en todas las condiciones
	_fase("asiento")


func _colocar(p: Vector2) -> void:
	m.jugador.position = p


# Un paso de 1/30 s a VELOCIDAD hacia el siguiente punto de la ruta (ida y vuelta, ≈ 245 fotogramas por sentido).
var sentido := 1


func _andar() -> void:
	var paso := VELOCIDAD / 30.0
	var falta: Vector2 = RUTA[tramo] - m.jugador.position
	if falta.length() <= paso:
		m.jugador.position = RUTA[tramo]
		if tramo + sentido < 0 or tramo + sentido >= RUTA.size():
			sentido = -sentido
		tramo += sentido
	else:
		m.jugador.position += falta.normalized() * paso


static func _estad(a: Array) -> Dictionary:
	if a.is_empty():
		return {}
	var s := a.duplicate()
	s.sort()
	var suma := 0.0
	for x in s:
		suma += x
	var p := func(q: float) -> float: return s[clampi(int(round(q * (s.size() - 1))), 0, s.size() - 1)]
	return {"n": s.size(), "mediana": p.call(0.5), "media": suma / s.size(), "p95": p.call(0.95), "p99": p.call(0.99),
		"peor": s[-1], "mejor": s[0]}


func _terminar() -> void:
	var r := {
		"condicion": condicion,
		"argumentos": " ".join(OS.get_cmdline_user_args()),
		"fecha": Time.get_datetime_string_from_system(),
		"equipo": {"gpu": RenderingServer.get_video_adapter_name(), "proveedor": RenderingServer.get_video_adapter_vendor(),
			"api": RenderingServer.get_video_adapter_api_version(), "cpu": OS.get_processor_name(),
			"nucleos": OS.get_processor_count(), "renderizador": ProjectSettings.get_setting("rendering/renderer/rendering_method")},
		"ventana": [ventana.x, ventana.y],
		"mapa": {"pintado": m.arte_activo() if m.has_method("arte_activo") else false, "agua_animada": m.get("agua_viva") == true,
			"lugares": m.lugares.size()},
		"carga_ms": carga_ms,
		"fotograma_ms": {"quieto": _estad(tiempos["quieto"]), "andando": _estad(tiempos["andando"])},
		"scripts_ms": {"quieto": _estad(trabajo["quieto"]), "andando": _estad(trabajo["andando"])},
		"gpu_ms": {"quieto": _estad(gpu["quieto"]), "andando": _estad(gpu["andando"])},
		"llamadas_dibujo": dibujos,
		"memoria": memoria,
	}
	var f := FileAccess.open("%s/%s.json" % [salida, condicion], FileAccess.WRITE)
	f.store_string(JSON.stringify(r, "  "))
	f.close()
	print("MEDIDA %s: carga %.0f ms · fotograma quieto %.2f ms (p95 %.2f) · andando %.2f ms (p95 %.2f) · vídeo %.1f MB · estática %.1f MB"
		% [condicion, carga_ms, r["fotograma_ms"]["quieto"].get("mediana", 0.0), r["fotograma_ms"]["quieto"].get("p95", 0.0),
		r["fotograma_ms"]["andando"].get("mediana", 0.0), r["fotograma_ms"]["andando"].get("p95", 0.0),
		memoria.get("quieto", {}).get("video_mb", 0.0), memoria.get("quieto", {}).get("estatica_mb", 0.0)])
	quit(0)
