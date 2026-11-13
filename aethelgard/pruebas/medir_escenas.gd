extends SceneTree
# MEDIDA reproducible en el PC de las escenas principales (encargo del 13/11: «primero mide»). No es una prueba de
# regresión: mide. Un proceso por escena y perfil (memoria limpia), con datos aislados (APPDATA propio) y, a ser
# posible, sin otros Godot, Blender ni compilaciones a la vez (medir_escenas.ps1 los apunta en cada pasada).
#   Godot --path aethelgard --script res://pruebas/medir_escenas.gd --fixed-fps 30 -- <carpeta> escena=<id>
#         [perfil=medio] [ciclos=3] [etiqueta=x] 3d sin_prologo [auto]
# <id>: titulo, pastos, garganta, oakhaven, granbosque, marcristal, ciclopea (regiones y portada), combate_brama (combate fijo de
# Bramavidrio lanzado desde el Mar de Cristal, como el gusano) y combate3 (un combate normal de Pastos Verdes con Kael,
# Lya y Garon; con «auto» los héroes atacan solos).
# Con --fixed-fps cada fotograma avanza 1/30 s de juego (el mismo recorrido en todas las pasadas) y sin tope de FPS ni
# sincronía vertical: el tiempo de cada fotograma es lo que cuesta (no el tope de 30 de la región).
# Fases por ciclo:
#   regiones: «carga» (1.ª = primera carga; 2.ª y siguientes = repetición con los recursos ya usados), «reposo»
#     (Kael quieto, 300 fotogramas), «activo» (Kael anda un cuadrado de 6 m, 450 fotogramas) y «fuera» (una escena
#     vacía: la memoria que queda al salir; si crece de ciclo en ciclo, algo se retiene).
#   combates: la región se carga una vez; por ciclo, «carga_combate» (desde el encuentro: incluye el fundido del aviso,
#     ~0,9 s, y «Preparando el combate…»), «combate» (600 fotogramas) y «vuelta» (de vuelta a la región).
#   titulo: «carga» (carga.tscn con su precarga hasta «TOCA PARA EMPEZAR»: la portada «listo»), «reposo» (300) y «fuera».
# Escribe <carpeta>/medicion_<id>_<perfil><etiqueta>.json: equipo, commit, cargas (ms) y por fase el tiempo por
# fotograma (media, mediana, p95, p99, máximo, tirones > 50 ms), dibujos y primitivas por fotograma y la memoria al
# acabar la fase (estática, vídeo, texturas, objetos, nodos, huérfanos y recursos). (El monitor de proceso y física de
# Godot da el máximo de cada segundo, no el de cada fotograma: no se usa.)

const REGIONES := {"pastos": "res://zonas3d/pastos_verdes_3d.tscn", "garganta": "res://zonas3d/garganta_3d.tscn",
	"oakhaven": "res://zonas3d/oakhaven_3d.tscn", "granbosque": "res://zonas3d/gran_bosque_3d.tscn",
	"marcristal": "res://zonas3d/mar_cristal_3d.tscn", "combate_brama": "res://zonas3d/mar_cristal_3d.tscn",
	"combate3": "res://zonas3d/pastos_verdes_3d.tscn", "titulo": "res://carga.tscn",
	"ciclopea": "res://zonas3d/ciclopea_3d.tscn"}   # V12 (13/11): las Cumbres de Ciclópea 3D (en pruebas; la escena se carga directa)
const COMBATE := "res://combate.tscn"
const CUADRADO := [Vector3(6, 0, 0), Vector3(6, 0, 6), Vector3(0, 0, 6), Vector3(0, 0, 0)]
# Recorrido fijo donde el cuadrado desde la llegada pisa una salida (la Garganta empieza junto a la del mapa): puntos
# absolutos de ida y vuelta por la entrada (los de medir_garganta3d.gd).
const RUTAS := {"garganta": [Vector3(-12, 0, 22), Vector3(-12, 0, 10)],
	"marcristal": [Vector3(45, 0, 96), Vector3(39, 0, 95), Vector3(40, 0, 99), Vector3(45, 0, 100)]}   # junto al campamento, lejos de la salida (z 106,5)
# En el Gran Bosque el cuadrado se gira para alejarse de la salida al mapa (_salida()).


var salida := ""
var id := "pastos"
var perfil := "medio"
var ciclos := 3
var etiqueta := ""
var R
var v = null
var frames := 0
var fase := ""
var f_fase := 0
var ciclo := 0
var u_ant := 0
var t_carga := 0
var origen := Vector3.ZERO
var punto := 0
var vacia: PackedScene
var datos := {}                  # «fase#ciclo» → {tiempos, dibujos, primitivas, memoria}
var cargas := {}                 # «carga#ciclo» → ms
var tirones := []
var nuevos := []                 # nodos que entran en el árbol en este fotograma (para explicar los tirones)
var previos := []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0]
	for a in args:
		if a.begins_with("escena="):
			id = a.substr(7)
		elif a.begins_with("perfil="):
			perfil = a.substr(7)
		elif a.begins_with("ciclos="):
			ciclos = int(a.substr(7))
		elif a.begins_with("etiqueta="):
			etiqueta = "_" + a.substr(9)
	R = root.get_node("Recursos")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Engine.set_meta("calidad_proto", perfil)        # perfil fijo: sin calibración ni regulador (vista3d.gd)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for k in ["mazmorras", "combates_ganados", "cofres_abiertos", "grupo_combate", "combate_fijo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	node_added.connect(_nodo_nuevo)
	R.precalentar_dialogos.call_deferred()      # como el arranque (carga.gd _paso_dialogos): la interfaz de Dialogic ya hecha
	seed(7)
	var n := Node.new()
	vacia = PackedScene.new()
	vacia.pack(n)
	n.free()
	_cargar()


func _nodo_nuevo(nd: Node) -> void:
	if nuevos.size() < 40:
		nuevos.append("%s:%s" % [nd.get_class(), nd.name])


func _escena() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _es_combate() -> bool:
	return id.begins_with("combate")


func _cargar() -> void:
	_apuntar_memoria()
	ciclo += 1
	t_carga = Time.get_ticks_usec()
	change_scene_to_file(REGIONES[id])
	_fase("carga")


func _clave(n: String) -> String:
	return "%s#%d" % [n, ciclo]


func _apuntar_memoria() -> void:
	if fase != "" and datos.has(_clave(fase)):
		datos[_clave(fase)]["memoria"] = _memoria()


func _fase(n: String) -> void:
	_apuntar_memoria()
	fase = n
	f_fase = frames
	if not datos.has(_clave(n)):
		datos[_clave(n)] = {"tiempos": [], "dibujos": [], "primitivas": []}


func _memoria() -> Dictionary:
	return {"estatica_mb": OS.get_static_memory_usage() / 1048576.0,
		"video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"texturas_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"buffers_mb": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
		"objetos": Performance.get_monitor(Performance.OBJECT_COUNT),
		"nodos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"huerfanos": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"recursos": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)}


func _listo(ruta: String) -> bool:
	return _escena() == ruta and not R.cambiando


func _process(_d: float) -> bool:
	frames += 1
	Engine.max_fps = 0
	var ahora := Time.get_ticks_usec()
	if u_ant > 0 and datos.has(_clave(fase)) and not fase.begins_with("carga"):
		var ms := (ahora - u_ant) / 1000.0
		var d: Dictionary = datos[_clave(fase)]
		d["tiempos"].append(ms)
		d["dibujos"].append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		d["primitivas"].append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		if ms > 50.0 and frames - f_fase > 2:
			tirones.append([_clave(fase), frames - f_fase, snappedf(ms, 0.1), {"este": nuevos.slice(0, 12), "anterior": previos.slice(0, 6)}])
	u_ant = ahora
	previos = nuevos
	nuevos = []
	if v != null and not is_instance_valid(v):
		v = null
	if v != null and v.get("perfil_fps") != null:
		v.perfil_fps = 0
		if v.get("pasos") != null:
			v.pasos = 0                                 # sin encuentros al azar: los combates se lanzan a mano
	var t := frames - f_fase
	match fase:
		"carga":
			if id == "titulo":
				if _escena() != "" and _escena() != REGIONES[id] and not R.cambiando and t > 5 and current_scene.get("listo") != false:          # hasta «TOCA PARA EMPEZAR» (portada: listo)
					cargas[_clave("carga")] = (Time.get_ticks_usec() - t_carga) / 1000.0
					cargas["portada"] = _escena()
					_fase("reposo")
			elif _listo(REGIONES[id]) and t > 5:
				cargas[_clave("carga")] = (Time.get_ticks_usec() - t_carga) / 1000.0
				v = current_scene
				origen = v.kael.global_position
				_fase("asentar")
		"asentar":                                      # sombras, sombreados y textos de entrada: no se miden
			if t >= 60:
				if _es_combate():
					_lanzar_combate()
				else:
					_fase("reposo")
		"reposo":
			if t >= 300:
				if id == "titulo":
					_salir()
				else:
					punto = 0
					_ir()
					_fase("activo")
		"activo":
			if not is_instance_valid(v) or _escena() != REGIONES[id]:
				print("MEDIDA: la región se ha ido durante «%s» (una salida en el recorrido): se mide hasta aquí" % _clave(fase))
				cargas[_clave("salio_de_la_region")] = t
				v = null
				_fase("fuera")
				return false
			if v.destino == null and t > 3:
				_ir()
			if t >= 450:
				_salir()
		"fuera":
			if t >= 60:
				if ciclo >= ciclos:
					return _terminar()
				_cargar()
		"carga_combate":
			if _listo(COMBATE) and t > 2:
				cargas[_clave("carga_combate")] = (Time.get_ticks_usec() - t_carga) / 1000.0
				v = null
				_fase("combate")
		"combate":
			if t >= 600 or _escena() != COMBATE:
				if _escena() == COMBATE:
					current_scene._volver_al_mapa()
				t_carga = Time.get_ticks_usec()
				_fase("carga_vuelta")
		"carga_vuelta":
			if _listo(REGIONES[id]) and t > 5:
				cargas[_clave("carga_vuelta")] = (Time.get_ticks_usec() - t_carga) / 1000.0
				v = current_scene
				_fase("tras_volver")
		"tras_volver":
			if t >= 90:
				if ciclo >= ciclos:
					return _terminar()
				_apuntar_memoria()
				ciclo += 1
				_lanzar_combate()
	if frames > 30000:
		print("MEDIDA: se acaba el tiempo en «%s»" % _clave(fase))
		return _terminar()
	return false


func _ir() -> void:
	var ruta: Array = RUTAS.get(id, [])
	var p: Vector3 = ruta[punto % ruta.size()] if not ruta.is_empty() else origen + _girado(CUADRADO[punto % CUADRADO.size()])
	v.destino = v._ajustar_destino(p)
	punto += 1


func _girado(o: Vector3) -> Vector3:
	if not v.has_method("_salida"):
		return o
	var u: Vector3 = origen - v._salida()
	u.y = 0.0
	u = u.normalized() if u.length() > 0.1 else Vector3(0, 0, -1)
	var w := Vector3(-u.z, 0, u.x)
	return u * o.x + w * o.z


func _salir() -> void:
	_fase("fuera")                                  # (antes de salir: la memoria de la fase con la escena puesta)
	v = null
	change_scene_to_packed(vacia)


func _lanzar_combate() -> void:
	t_carga = Time.get_ticks_usec()
	if id == "combate_brama":
		Engine.set_meta("combates_ganados", {})
		v.encuentro("mc_bramavidrio", 13, "jefe", "¡Bramavidrio te cierra el paso! No hay huida.")
	else:
		seed(7 + ciclo)
		v._encuentro("", 0)
	_fase("carga_combate")


func _resumen(lista: Array, con_tirones := true) -> Dictionary:
	if lista.is_empty():
		return {}
	var o := lista.duplicate()
	o.sort()
	var suma := 0.0
	for x in o:
		suma += x
	var n := o.size()
	var tir := 0
	for x in lista:
		if x > 50.0:
			tir += 1
	return {"n": n, "media": snappedf(suma / n, 0.01), "mediana": snappedf(o[n / 2], 0.01),
		"p95": snappedf(o[mini(n - 1, int(n * 0.95))], 0.01), "p99": snappedf(o[mini(n - 1, int(n * 0.99))], 0.01),
		"max": snappedf(o[n - 1], 0.01)}.merged({"tirones_50ms": tir} if con_tirones else {})


func _terminar() -> bool:
	if datos.has(_clave(fase)):
		datos[_clave(fase)]["memoria"] = _memoria()
	var commit := []
	OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "--short", "HEAD"], commit)
	var info := {"escena": id, "perfil": perfil, "ciclos": ciclos, "etiqueta": etiqueta,
		"commit": (commit[0].strip_edges() if commit.size() > 0 else "?"), "argumentos": OS.get_cmdline_user_args(),
		"fecha": Time.get_datetime_string_from_system(), "godot": Engine.get_version_info()["string"],
		"cpu": OS.get_processor_name(), "nucleos": OS.get_processor_count(),
		"gpu": RenderingServer.get_video_adapter_name(), "api": RenderingServer.get_video_adapter_api_version(),
		"ventana": str(DisplayServer.window_get_size()), "cargas_ms": cargas, "tirones": tirones, "fases": {}}
	for k in datos:
		var d: Dictionary = datos[k]
		info["fases"][k] = {"fotograma_ms": _resumen(d["tiempos"]), "dibujos": _resumen(d["dibujos"], false), "primitivas": _resumen(d["primitivas"], false), "memoria": d.get("memoria", {})}
	var ruta := "%s/medicion_%s_%s%s.json" % [salida, id, perfil, etiqueta]
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))
	f.close()
	print("MEDICION %s %s: %s" % [id, perfil, ruta])
	quit(0)
	return true
