extends SceneTree
# Prueba del prólogo con su puesta en escena (T-081; escena_dialogo.gd, retrato_vivo.gd). Sin ventana, con datos
# aislados y «-- 3d». Tres pasadas por el mapa con una partida nueva:
#   1. Entero con el teclado: 9 frases, una pulsación por frase; los retratos son «vivos» y quien habla tiene el foco;
#      al acabar, todo vuelve como estaba (cámara, capa y transparencia de Dialogic, sin pausa, el muñeco del mapa a la
#      vista) y Kael vuelve a andar; ninguna pulsación de más llega al mapa.
#   2. Saltado con Esc en mitad del diálogo: lo mismo, y no se queda nada a medias.
#   3. Saltado durante la entrada (antes de la primera frase): lo mismo.
# En ninguno cambia la misión: el prólogo queda visto y no se pone ningún hito ni se guarda nada raro.

const MAPA := "res://mapa.tscn"

var D
var fallos: Array = []
var hechos: Array = []
var _retrato: PackedScene                         # precargado, como hace la pantalla de carga (Recursos)


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
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


func _probar() -> void:
	D = root.get_node("Dialogic")
	_retrato = load("res://dialogos/retrato_vivo.tscn")   # en el juego lo precarga la pantalla de carga
	await _esperar(3)
	root.get_node("Recursos").precalentar_dialogos()
	await _esperar(3)
	await _pasada("entero")
	await _pasada("saltar_dialogo")
	await _pasada("saltar_entrada")
	print("OK prólogo: ", ", ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _pasada(modo: String) -> void:
	var P = load("res://progreso.gd")
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	change_scene_to_file(MAPA)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == MAPA and current_scene.get("escena_dialogo") != null):
		_fallo("%s: en una partida nueva, el prólogo no empieza con su puesta en escena" % modo)
		return
	var m = current_scene
	var escena = m.escena_dialogo
	var zoom0: Vector2 = m.camara.zoom
	var lay = D.Styles.get_layout_node()
	var capa0: int = escena._capa_dialogic          # la de antes de la escena (que la sube mientras dura)
	if not Engine.get_meta("prologo_visto", false):
		_fallo("%s: el prólogo no queda visto al empezar" % modo)
	if m.jugador.visible:
		_fallo("%s: el muñeco del mapa sigue a la vista durante la escena" % modo)
	if not D.paused or D.current_timeline == null:
		_fallo("%s: durante la entrada, el diálogo no ha empezado en pausa (en el fotograma de llegada)" % modo)
	if root.get_node("BotonDialogo").visible:
		_fallo("%s: «SEGUIR» se ve durante la entrada" % modo)
	if modo == "saltar_entrada":
		await _esperar(10)
		await _pulsar(KEY_ESCAPE)
	else:
		if not await _hasta(func(): return not D.paused and _texto() != ""):
			_fallo("%s: el diálogo no aparece tras la entrada" % modo)
			return
		var frases := 0
		while D.current_timeline != null and frases < 20:
			if not await _hasta(func(): return D.current_timeline == null or (D.current_state == D.States.IDLE and _texto() != "" and _revelado())):
				break
			if D.current_timeline == null:
				break
			frases += 1
			if frases == 1:
				_comprobar_retratos()
			if modo == "saltar_dialogo" and frases == 3:
				await _pulsar(KEY_ESCAPE)
				break
			var antes := _texto()
			await _esperar(6)                      # como una persona: Dialogic no acepta pulsar en los 0,1 s tras
			await _pulsar(KEY_ENTER)               # escribir la frase (advance_delay), para no saltarse dos
			await _esperar(3)
			if D.current_timeline != null and _texto() == antes and _revelado() and D.current_state == D.States.IDLE:
				_fallo("%s: la frase %d no avanza con una pulsación" % [modo, frases])
		if modo == "entero" and frases != 9:
			_fallo("entero: salen %d frases (esperaba 9)" % frases)
	# al acabar (o al saltar): todo como estaba
	if not await _hasta(func(): return m.escena_dialogo == null and D.current_timeline == null, 15.0):
		_fallo("%s: la escena no termina" % modo)
		return
	await _esperar(5)
	if m.camara.zoom.distance_to(Vector2.ONE) > 0.01 and m.camara.zoom.distance_to(zoom0) > 0.01:
		_fallo("%s: la cámara no vuelve a su zoom (%s)" % [modo, m.camara.zoom])
	if lay != null and (lay.layer != capa0 or absf(lay.get_child(0).modulate.a - 1.0) > 0.01):
		_fallo("%s: la interfaz de los diálogos no vuelve a su capa o sigue transparente" % modo)
	if D.paused:
		_fallo("%s: Dialogic se queda en pausa" % modo)
	if not m.jugador.visible:
		_fallo("%s: el muñeco del mapa no vuelve a verse" % modo)
	if is_instance_valid(escena):
		_fallo("%s: la capa de la escena no se libera" % modo)
	if current_scene != m:
		_fallo("%s: una pulsación ha sacado al jugador del mapa (%s)" % [modo, current_scene.scene_file_path if current_scene else "?"])
		return
	var antes_pos: Vector2 = m.jugador.position
	Input.action_press("ui_right")
	await _esperar(20)
	Input.action_release("ui_right")
	if m.jugador.position.distance_to(antes_pos) < 4.0:
		_fallo("%s: al terminar, Kael no se mueve" % modo)
	if Engine.has_meta("hitos") and not Engine.get_meta("hitos", {}).is_empty():
		_fallo("%s: el prólogo ha puesto hitos de misión (%s)" % [modo, Engine.get_meta("hitos")])
	hechos.append(modo)


func _comprobar_retratos() -> void:
	var vivos := 0
	var con_foco := 0
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and n.get_script().resource_path == "res://dialogos/retrato_vivo.gd":
			vivos += 1
			if n.get("modulate") == Color.WHITE:
				con_foco += 1
	if vivos != 2:
		_fallo("en el prólogo hay %d retratos vivos (esperaba 2)" % vivos)
	elif con_foco != 1:
		_fallo("en la primera frase, %d retratos tienen el foco (esperaba 1: quien habla)" % con_foco)
