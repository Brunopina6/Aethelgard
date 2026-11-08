extends SceneTree
# Prueba: lo que se prepara antes de jugar no provoca nada de juego (T-025 y D-061).
#   1. Pantalla de carga entera (archivos, sombreados de combate y vfx, interfaz de los diálogos, cachés de las zonas),
#      sin pulsar nada: ningún diálogo empieza ni acaba, Dialogic no emite señales ni eventos, no se escribe ninguna
#      partida, no aparece ningún estado de partida (hitos, grupo, cofres, combates, posición) y el botón «Seguir» de
#      los diálogos no sale. La interfaz de los diálogos queda preparada y oculta.
#   2. Al entrar en Pastos Verdes 3D (partida de prueba), la vitrina de sombreados (vista3d.gd) no deja copias ni las
#      mete en grupos, no cuenta pasos ni lanza encuentros, no abre diálogos antes de PV-02 y se va en pocos fotogramas.
# Sin ventana. Con «-- 3d sin_prologo». Todo en la carpeta aislada.

const CARGA := "res://carga.tscn"
const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const ESTADO := ["hitos", "grupo_activo", "cofres_abiertos", "combates_ganados", "pos_3d", "pos_3d_ok", "partida_lista",
	"ranura_prueba", "decisiones"]

var fallos: Array = []
var R
var D
var senales := {}


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _anotar(nombre: String) -> void:
	senales[nombre] = senales.get(nombre, 0) + 1


func _partidas() -> Array:
	var r: Array = []
	for f in DirAccess.get_files_at("user://"):
		if f.begins_with("partida") and f.contains(".save"):
			r.append(f)
	return r


func _probar() -> void:
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")
	await process_frame
	for s in ["timeline_started", "timeline_ended", "signal_event", "text_signal", "event_handled"]:
		D.get(s).connect(func(_a = null): _anotar(s))
	var antes_partidas := _partidas()
	var estado_antes := ESTADO.filter(func(k): return Engine.has_meta(k))
	# 1. La pantalla de carga entera, sin pulsar nada
	change_scene_to_file(CARGA)
	var boton_visto := [false]
	var listo := await _hasta(func():
		if root.get_node("BotonDialogo").visible:
			boton_visto[0] = true
		return _escena() == CARGA and current_scene.listo, 180.0)
	if not listo:
		_fallo("1: la pantalla de carga no termina")
	if not senales.is_empty():
		_fallo("1: durante la carga, Dialogic emite %s" % senales)
	if D.current_timeline != null:
		_fallo("1: durante la carga empieza un diálogo")
	if boton_visto[0]:
		_fallo("1: durante la carga sale el botón «Seguir» de los diálogos")
	if _partidas() != antes_partidas:
		_fallo("1: durante la carga se escribe una partida (%s)" % _partidas())
	var estado_ahora := ESTADO.filter(func(k): return Engine.has_meta(k))
	if estado_ahora != estado_antes:
		_fallo("1: durante la carga aparece estado de partida: %s" % estado_ahora)
	var interfaz = D.Styles.get_layout_node() if D.has_subsystem("Styles") else null
	if interfaz == null or interfaz.visible:
		_fallo("1: la interfaz de los diálogos no queda preparada y oculta")
	print("OK 1: la carga prepara sin provocar nada de juego")
	# 2. Entrar en la región (partida de prueba) y mirar la vitrina
	senales.clear()
	current_scene._empezar(true)
	if not await _hasta(func(): return _escena() == REGION, 120.0):
		_fallo("2: no se llega a Pastos Verdes 3D")
	else:
		var v = current_scene
		var ocluyen := get_nodes_in_group("ocluye").size()
		var vitrina_vista := false
		for i in 20:                                  # mientras sigue en negro y la vitrina dibuja
			await process_frame
			for n in v.cam.get_children():
				if n is Node3D and n.get_child_count() > 0 and n.get_child(0) is GeometryInstance3D:
					vitrina_vista = true
		await process_frame
		var copias_que_quedan: Array = v.cam.get_children().filter(func(n): return n is Node3D and n.get_child_count() > 0)
		if not vitrina_vista:
			_fallo("2: no se ve la vitrina de sombreados (la prueba no comprueba nada)")
		if not copias_que_quedan.is_empty():
			_fallo("2: la vitrina deja %d nodos con copias delante de la cámara" % copias_que_quedan.size())
		if get_nodes_in_group("ocluye").size() != ocluyen:
			_fallo("2: la vitrina mete copias en el grupo «ocluye» (%d → %d)" % [ocluyen, get_nodes_in_group("ocluye").size()])
		if v.pasos != 0 or v.saliendo or _escena() != REGION:
			_fallo("2: al entrar se cuentan pasos o se sale (pasos %d)" % v.pasos)
		if v._t_entrada < v.ESPERA_PV02 and (D.current_timeline != null or senales.has("timeline_started")):
			_fallo("2: un diálogo empieza antes de PV-02")
		print("OK 2: la vitrina se va sin dejar nada ni provocar nada")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
