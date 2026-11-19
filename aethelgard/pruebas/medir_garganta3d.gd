extends SceneTree
# Medición de la Garganta del Diablo 3D en el PC (o en un hueco sin otra carga): el mismo recorrido en cada perfil, para
# comparar perfiles y versiones. No es una prueba de regresión: mide. Un proceso por perfil (memoria limpia):
#   Godot --path aethelgard --script res://pruebas/medir_garganta3d.gd --fixed-fps 30 -- <carpeta> 3d garganta3d
#         sin_prologo perfil=bajo           (y luego perfil=medio y perfil=alto)
# Con «conteo» (se puede sin ventana): no mide tiempos, solo cuenta lo que hay en la escena en ese perfil (triángulos de
# roca, mallas, MultiMesh, partículas, capas transparentes y luces) y lo escribe en <carpeta>/conteo_<perfil>.json.
# Con --fixed-fps cada fotograma avanza 1/30 s de juego: todos los perfiles recorren los mismos fotogramas. Sin tope de
# FPS (perfil_fps = 0) y sin sincronía vertical: el tiempo de cada fotograma es lo que cuesta.
# Fases: entrar, andar por la entrada, cruzar los puentes, asomarse al abismo desde un puente (el peor caso de niebla y
# fondo), el paso de la puerta, la cornisa baja con el ascensor y el campamento, bajar al nido, la palanca con el puente
# cayendo, la arena con Gorthor y la cascada, la grieta, y un combate con su carga y su vuelta.
# Escribe <carpeta>/medicion_garganta3d_<perfil>.json con el equipo, las cargas y los tiempos y la memoria por fase.

const REGION := "res://zonas3d/garganta_3d.tscn"

var salida := ""
var perfil := "bajo"
var solo_conteo := false
var etiqueta := ""                       # «etiqueta=x»: conteo_<perfil>_x.json (varias cargas en la misma pasada)
var R
var T
var v
var frames := 0
const TOPE_MS := 300000           # (19/11, PC-10, KAEL_ESPERAS_19_11) tope global por reloj (antes, 20000 fotogramas)
var t_inicio := Time.get_ticks_msec()
var fase := ""
var f_fase := 0
var u_ant := 0
var tiempos := {}
var trabajo := {}
var memoria := {}
var cargas := {}
var t_carga := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0]
	for a in args:
		if a.begins_with("perfil="):
			perfil = a.substr(7)
		elif a == "conteo":
			solo_conteo = true
		elif a == "sin_cache":
			Engine.set_meta("garganta_sin_cache", true)
		elif a.begins_with("etiqueta="):
			etiqueta = "_" + a.substr(9)
	R = root.get_node("Recursos")
	T = load("res://zonas3d/garganta/trazado.gd")
	if not solo_conteo:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("pos_3d_ok", false)
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
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


func _poner(p: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 2.0, 0), p - Vector3(0, 6.0, 0))
	var hit: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		p.y = hit["position"].y
	v._colocar_kael(p)
	v._ultima = p


func _ir(p: Vector3) -> void:
	v.destino = v._ajustar_destino(p)


func _llego() -> bool:
	return v.destino == null and frames - f_fase > 3


func _process(_d: float) -> bool:
	frames += 1
	var ahora := Time.get_ticks_usec()
	if u_ant > 0 and fase in tiempos:
		var ms := (ahora - u_ant) / 1000.0
		tiempos[fase].append(ms)
		if ms > 50.0 and not solo_conteo:
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
				if solo_conteo:
					return _conteo()
				_fase("espera")
		"espera":                                   # deja que se asiente (sombras, sombreados, el título)
			if frames - f_fase >= 90:
				_ir(Vector3(-12, 0, 22))
				_fase("entrada")
		"entrada":
			if _llego() or frames - f_fase > 600:
				_ir(Vector3(-12, 0, 0.5))
				_fase("puentes")
		"puentes":
			if _llego() or frames - f_fase > 600:
				_poner(Vector3(-12, 0, 15.0))
				_fase("asomarse_al_abismo")
		"asomarse_al_abismo":
			if frames - f_fase >= 150:
				_poner(Vector3(-12, 0, -4.0))
				_ir(Vector3(-12, 0, -17.5))
				_fase("paso_de_la_puerta")
		"paso_de_la_puerta":
			if _llego() or frames - f_fase > 600:
				_poner(Vector3(11, -8, 31.0))
				_ir(Vector3(11, -8, -4.0))
				_fase("cornisa_baja")
		"cornisa_baja":
			if _llego() or frames - f_fase > 900:
				_poner(Vector3(6.2, -8, 19.8))
				_ir(T.VUELTA_NIDO)
				_fase("bajar_al_nido")
		"bajar_al_nido":
			if (_llego() and frames - f_fase > 60) or frames - f_fase > 600:
				_poner(Vector3(11.4, -8, -6.0))
				v.cerca = "palanca"
				v._accion()                         # tira de la palanca: el puente cae y la cámara lo mira
				_fase("palanca")
		"palanca":
			if frames - f_fase >= 170:
				_poner(Vector3(-12, 0, -23.0))
				_fase("arena")
		"arena":
			if frames - f_fase >= 150:
				_poner(Vector3(11.4, -8, -28.0))
				_fase("grieta")
		"grieta":
			if frames - f_fase >= 90:
				_poner(Vector3(-12, 0, 16.0))
				v._encuentro()
				t_carga = Time.get_ticks_usec()
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
				_ir(Vector3(-12, 0, 2.0))
			elif frames - f_fase > 30 and (v.destino == null or frames - f_fase > 400):
				return _terminar()
	if Time.get_ticks_msec() - t_inicio > TOPE_MS:
		return _agotado()
	return false


# (19/11, PC-10, KAEL_ESPERAS_19_11) Tope GLOBAL por RELOJ (antes, 20000 fotogramas, y se escribía la medida a medias): al agotarse, FALLO y salida 1, sin escribir la medida a medias
# como si estuviera completa. Lo que se mide cuando no se agota no cambia.
func _agotado() -> bool:
	print("FALLO: la medida no termina en %d s de reloj (fase «%s», %d fotogramas)" % [TOPE_MS / 1000, fase, frames])
	print("FALLOS: 1")
	quit(1)
	return true


# Lo que hay en la escena en este perfil (sin tiempos).
func _conteo() -> bool:
	var c := {"perfil": perfil, "carga_ms": cargas.get("region", 0.0), "triangulos_roca": v.esc.triangulos,
		"mallas_roca": v.esc.mallas_roca, "mallas": 0, "triangulos_mallas": 0, "multimesh": 0, "instancias_multimesh": 0,
		"particulas": 0, "particulas_total": 0, "transparentes": 0, "luces_omni": 0, "sombras": v.perfil.get("sombras", false)}
	for n in v.find_children("*", "GeometryInstance3D", true, false):
		if n is MeshInstance3D and n.mesh != null:
			c["mallas"] += 1
			c["triangulos_mallas"] += n.mesh.get_faces().size() / 3      # vale para ArrayMesh y para las primitivas
			var m = n.material_override
			if m is ShaderMaterial and (m.shader.code.find("blend_mix") >= 0 or m.shader.code.find("blend_add") >= 0):
				c["transparentes"] += 1
			elif m is BaseMaterial3D and m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				c["transparentes"] += 1
		elif n is MultiMeshInstance3D and n.multimesh != null:
			c["multimesh"] += 1
			c["instancias_multimesh"] += n.multimesh.instance_count
		elif n is CPUParticles3D:
			c["particulas"] += 1
			c["particulas_total"] += n.amount
	c["luces_omni"] = v.find_children("*", "OmniLight3D", true, false).size()
	c["construccion_ms"] = v.esc.get("tiempos")              # (null con código anterior a la medida por pasos)
	c["roca_de_cache"] = v.esc.get("leidas_de_cache")
	c["mallas_de_roca_hechas"] = v.esc.get("_n_roca")
	var ruta := "%s/conteo_%s%s.json" % [salida, perfil, etiqueta]
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(JSON.stringify(c, "  "))
	f.close()
	print("CONTEO %s: %s" % [perfil, JSON.stringify(c)])
	quit(0)
	return true


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
	var info := {"perfil": perfil, "commit": (commit[0].strip_edges() if commit.size() > 0 else "?"),
		"fecha": Time.get_datetime_string_from_system(), "godot": Engine.get_version_info()["string"],
		"cpu": OS.get_processor_name(), "nucleos": OS.get_processor_count(),
		"gpu": RenderingServer.get_video_adapter_name(), "gpu_marca": RenderingServer.get_video_adapter_vendor(),
		"api": RenderingServer.get_video_adapter_api_version(), "ram_mb": OS.get_memory_info().get("physical", 0) / 1048576.0,
		"ventana": DisplayServer.window_get_size(), "cargas_ms": cargas, "fases": {}}
	for f in tiempos:
		info["fases"][f] = {"tiempo_ms": _resumen(tiempos[f]), "proceso_y_fisica_ms": _resumen(trabajo[f]), "memoria": memoria.get(f, {})}
	var ruta := "%s/medicion_garganta3d_%s.json" % [salida, perfil]
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))
	f.close()
	print("MEDICION %s: %s" % [perfil, ruta])
	quit(0)
	return true
