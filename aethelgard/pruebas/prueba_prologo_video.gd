extends SceneTree
# Vídeo del prólogo (T-084): poses, gestos y transiciones de los retratos EN MOVIMIENTO, para compararlos antes y
# después. Con ventana y datos aislados (ejecutar_pruebas.ps1 -Manual):
#   Godot --path aethelgard --script res://pruebas/prueba_prologo_video.gd --fixed-fps 30 -- <carpeta> 3d [etiqueta=antes]
# Tres tramos con una partida nueva en el mapa:
#   1. Entero, a ritmo de lectura: cada frase se deja a la vista LECTURA segundos después de escribirse.
#      Capturas «<etiqueta>_frase_NN_a» (recién escrita) y «_b» (justo antes de pasar a la siguiente).
#   2. Reabierto (la misma puesta en escena otra vez) y avanzado deprisa: una pulsación cada 0,3 s, también mientras
#      se escribe; a la quinta frase se salta con Esc. Captura «<etiqueta>_rapido_NN» de cada frase que se ve.
#   3. De vuelta al mapa: Kael anda. Captura «<etiqueta>_vuelta».
# Los fotogramas del vídeo (JPG, 960×540, 15 por segundo) van a «<carpeta>/<etiqueta>_video/»; se montan aparte.
# FALLO si el prólogo no aparece, una frase no avanza, el reabierto no se puede saltar o Kael no anda al acabar.

const MAPA := "res://mapa.tscn"
const LECTURA := 2.8                              # segundos a la vista tras escribirse (lectura tranquila)
const CADA := 2                                   # un fotograma de vídeo de cada 2 (a 30 por segundo: 15)

var salida := ""
var etiqueta := "antes"
var carpeta_video := ""
var D
var fallos: Array = []
var _n := 0
var _grabando := false


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
	carpeta_video = "%s/%s_video" % [salida, etiqueta]
	DirAccess.make_dir_recursive_absolute(carpeta_video)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	await _esperar(int(round(s * 30.0)))         # con --fixed-fps 30, el tiempo del juego avanza 1/30 s por fotograma


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	for i in int(segundos * 30.0):
		if cond.call():
			return true
		await process_frame
	return false


func _pulsar(codigo: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = true
	Input.parse_input_event(e)
	await _esperar(2)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await _esperar(2)


func _texto() -> String:
	for n in get_nodes_in_group("dialogic_dialog_text"):
		if n is RichTextLabel and n.is_visible_in_tree():
			return n.get_parsed_text()
	return ""


func _revelado() -> bool:
	for n in get_nodes_in_group("dialogic_dialog_text"):
		if n is RichTextLabel and n.is_visible_in_tree():
			return n.visible_characters < 0 or n.visible_ratio >= 0.999
	return false


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [salida, nombre])


# Un fotograma de vídeo de cada CADA, mientras se graba.
func _al_dibujar() -> void:
	if not _grabando:
		return
	_n += 1
	if _n % CADA != 0:
		return
	var img := root.get_texture().get_image()
	img.resize(960, 540, Image.INTERPOLATE_BILINEAR)
	img.save_jpg("%s/f_%05d.jpg" % [carpeta_video, _n / CADA], 0.88)


func _probar() -> void:
	D = root.get_node("Dialogic")
	load("res://dialogos/retrato_vivo.tscn")       # en el juego lo precarga la pantalla de carga
	await _esperar(3)
	root.get_node("Recursos").precalentar_dialogos()
	await _esperar(3)
	RenderingServer.frame_post_draw.connect(_al_dibujar)
	var P = load("res://progreso.gd")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	change_scene_to_file(MAPA)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == MAPA and current_scene.get("escena_dialogo") != null):
		_fallo("en una partida nueva, el prólogo no empieza")
		return _fin()
	var m = current_scene
	_grabando = true
	# 1. entero, a ritmo de lectura
	var frases := 0
	while D.current_timeline != null and frases < 20:
		if not await _hasta(func(): return D.current_timeline == null or (not D.paused and D.current_state == D.States.IDLE and _texto() != "" and _revelado())):
			break
		if D.current_timeline == null:
			break
		frases += 1
		await _segundos(0.4)
		await _foto("%s_frase_%02d_a" % [etiqueta, frases])
		await _segundos(LECTURA - 0.4)
		await _foto("%s_frase_%02d_b" % [etiqueta, frases])
		var antes := _texto()
		print("FRASE %02d · %s" % [frases, antes.left(80)])
		await _pulsar(KEY_ENTER)
		await _esperar(3)
		if D.current_timeline != null and _texto() == antes and _revelado() and D.current_state == D.States.IDLE:
			_fallo("la frase %d no avanza con una pulsación" % frases)
	if frases != 9:
		_fallo("salen %d frases (esperaba 9)" % frases)
	if not await _hasta(func(): return m.escena_dialogo == null and D.current_timeline == null, 15.0):
		_fallo("la escena no termina")
		return _fin()
	await _segundos(1.0)
	# 2. reabierto y deprisa: una pulsación cada 0,3 s (también mientras se escribe); a la quinta frase, Esc
	m._empezar_prologo()
	if not await _hasta(func(): return not D.paused and _texto() != "", 15.0):
		_fallo("el prólogo reabierto no aparece")
		return _fin()
	var vistas := {}
	var pulsaciones := 0
	while D.current_timeline != null and pulsaciones < 60:
		var t := _texto()
		if t != "" and not vistas.has(t):
			vistas[t] = true
			await _foto("%s_rapido_%02d" % [etiqueta, vistas.size()])
		if vistas.size() >= 5:
			await _segundos(0.3)
			await _pulsar(KEY_ESCAPE)
			break
		await _pulsar(KEY_ENTER)
		pulsaciones += 1
		await _segundos(0.3)
	print("RÁPIDO: %d frases vistas con %d pulsaciones; saltado con Esc" % [vistas.size(), pulsaciones])
	if not await _hasta(func(): return m.escena_dialogo == null and D.current_timeline == null, 15.0):
		_fallo("el prólogo reabierto no se puede saltar")
		return _fin()
	# 3. de vuelta al juego: Kael anda
	await _segundos(0.6)
	var antes_pos: Vector2 = m.jugador.position
	Input.action_press("ui_right")
	await _segundos(1.0)
	Input.action_release("ui_right")
	await _foto("%s_vuelta" % etiqueta)
	if m.jugador.position.distance_to(antes_pos) < 4.0:
		_fallo("al terminar, Kael no se mueve")
	await _segundos(0.5)
	_grabando = false
	print("VÍDEO: %d fotogramas en %s" % [_n / CADA, carpeta_video])
	_fin()


func _fin() -> void:
	print("CAPTURAS hechas en ", salida)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
