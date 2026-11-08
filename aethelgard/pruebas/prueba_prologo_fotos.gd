extends SceneTree
# El primer diálogo al abrir el juego (T-081): el prólogo de Kael y Lya en el mapa del mundo. Con ventana y datos
# aislados, reproduce el arranque NORMAL (pantalla de carga → Intro → mapa) y guarda capturas para revisarlas a ojo.
#   Godot --path aethelgard --script res://pruebas/prueba_prologo_fotos.gd --fixed-fps 30 -- <carpeta> 3d [variante=existente] [etiqueta=antes]
# Partida nueva (por defecto): «<etiqueta>_entrada_NN» (la entrada, fotograma a fotograma, a modo de vídeo),
# «<etiqueta>_frase_NN» (cada frase ya escrita entera) y «<etiqueta>_despues» (el mapa al terminar). Comprueba que
# cada pulsación de Intro avanza una sola frase y que, al acabar, el jugador vuelve a moverse.
# Partida existente («variante=existente»): guarda antes una partida con el prólogo visto y comprueba qué sale al abrir.
# FALLO si el prólogo no aparece en la partida nueva, si aparece en la existente o si se pierde el control.

const CARGA := "res://carga.tscn"
const MAPA := "res://mapa.tscn"

var salida := ""
var etiqueta := "antes"
var existente := false
var solo_medir := false                          # «medir»: sin guardar capturas (no ensucian la medida)
var D
var Ent
var fallos: Array = []


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	for a in OS.get_cmdline_user_args():
		if a == "variante=existente":
			existente = true
		elif a.begins_with("etiqueta="):
			etiqueta = a.substr(9)
		elif a == "medir":
			solo_medir = true
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_probar.call_deferred()


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


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


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	if not solo_medir:
		root.get_texture().get_image().save_png("%s/%s.png" % [salida, nombre])


func _probar() -> void:
	D = root.get_node("Dialogic")
	Ent = root.get_node("Entrada")
	_ultimo_g = Time.get_ticks_usec()
	process_frame.connect(_tic_global)            # todos los fotogramas, desde el principio
	RenderingServer.frame_pre_draw.connect(func(): _t_pre = Time.get_ticks_usec())
	RenderingServer.frame_post_draw.connect(func(): _dibujo.append((Time.get_ticks_usec() - _t_pre) / 1000.0))
	D.timeline_started.connect(func():
		if _tl < 0:
			_tl = _todos.size()
			_t_eventos = Time.get_ticks_usec())
	D.event_handled.connect(func(ev):            # cuánto tarda cada evento desde que empieza la línea de tiempo
		if _eventos.size() < 8:
			_eventos.append("%s %.1f ms" % [ev.get_script().resource_path.get_file().get_basename(), (Time.get_ticks_usec() - _t_eventos) / 1000.0]))
	D.timeline_ended.connect(func(): if _tl_fin < 0: _tl_fin = _todos.size())
	if existente:
		_guardar_partida_existente()
	await _esperar(3)
	change_scene_to_file(CARGA)
	if not await _hasta(func(): return _escena() == CARGA and current_scene.listo, 180.0):
		_fallo("la pantalla de carga no termina")
		return _fin()
	await _foto("%s_carga" % etiqueta)
	await _pulsar(KEY_ENTER)
	if not await _hasta(func(): return _escena() == MAPA and current_scene.get("jugador") != null, 60.0):
		_fallo("no se llega al mapa")
		return _fin()
	if existente:
		await _esperar(90)
		await _foto("%s_existente_mapa" % etiqueta)
		if D.current_timeline != null:
			_fallo("con una partida existente sale un diálogo al abrir (%s)" % D.current_timeline.resource_path)
		print("PARTIDA EXISTENTE: se vuelve al mapa; diálogo al abrir: %s" % ("ninguno" if D.current_timeline == null else "sí"))
		return _fin()
	# partida nueva: la entrada, fotograma a fotograma, midiendo cada fotograma en tiempo real
	var m = current_scene
	_medir(true)
	var t0 := Time.get_ticks_usec()
	var primera := -1.0
	for i in 24:
		await _esperar(3)
		await _foto("%s_entrada_%02d" % [etiqueta, i])
		if primera < 0.0 and _texto_visible() != "":
			primera = (Time.get_ticks_usec() - t0) / 1e6
	if D.current_timeline == null:
		_fallo("el prólogo no aparece en una partida nueva")
		return _fin()
	print("PRÓLOGO: %s" % D.current_timeline.resource_path)
	# una pulsación MIENTRAS se escribe la primera frase la completa (sin pasar a la siguiente); la siguiente avanza
	if await _hasta(func(): return _texto_visible() != "" and _proporcion() < 0.5, 20.0):
		var primera_frase := _texto_visible()
		await _pulsar(KEY_ENTER)
		await _esperar(3)
		if _texto_visible() != primera_frase:
			_fallo("una pulsación mientras se escribe la frase pasa a la siguiente en vez de completarla")
		elif _proporcion() < 0.999:
			_fallo("una pulsación mientras se escribe la frase no la completa (%.0f %%)" % (_proporcion() * 100.0))
		else:
			print("UNA PULSACIÓN: completa la frase que se escribía, sin pasar a la siguiente")
	var n := 0
	while D.current_timeline != null and n < 40:
		if not await _hasta(func(): return D.current_timeline == null or (D.current_state == D.States.IDLE and _texto_visible() != "" and _proporcion() >= 0.999), 20.0):
			break                                  # sin más frases: las salidas y el final, sin pulsar nada
		if D.current_timeline == null:
			break
		if primera < 0.0:
			primera = (Time.get_ticks_usec() - t0) / 1e6
		n += 1
		await _esperar(6)
		await _foto("%s_frase_%02d" % [etiqueta, n])
		var texto: String = _texto_visible()
		print("FRASE %02d · %s" % [n, texto.left(90)])
		await _pulsar(KEY_ENTER)
		await _esperar(4)
		if D.current_timeline != null and D.current_state == D.States.IDLE and _texto_visible() == texto:
			_fallo("la frase %d no avanza con una pulsación" % n)
	await _hasta(func(): return D.current_timeline == null, 10.0)
	var duracion := (Time.get_ticks_usec() - t0) / 1e6
	_medir(false)
	print("FRASES: %d" % n)
	print("PEOR FOTOGRAMA: el n.º %d desde que se llega al mapa (%s)" % [_peor_en, _peor_que])
	if _tl >= 0:
		var fin := _tl_fin if _tl_fin > _tl else _todos.size()
		var arranque: Array = _todos.slice(_tl, mini(_tl + 5, fin))
		var durante: Array = _todos.slice(_tl, fin)
		durante.sort()
		print("MEDIDAS DIÁLOGO: arranque (peor de los 5 fotogramas tras empezar) %.1f ms · durante: peor %.1f ms, p95 %.1f ms, mediana %.1f ms, %d fotogramas" % [
			arranque.max(), durante[-1], durante[int(0.95 * (durante.size() - 1))], durante[int(0.5 * (durante.size() - 1))], durante.size()])
		var i_peor: int = _tl + arranque.find(arranque.max())
		var dib: Array = []
		for k in range(maxi(0, i_peor - 2), mini(i_peor + 3, _dibujo.size())):
			dib.append("%.1f" % _dibujo[k])
		print("ARRANQUE: fotograma de %.1f ms; dibujo de los fotogramas de alrededor (ms): %s" % [_todos[i_peor], ", ".join(dib)])
		print("EVENTOS (desde el arranque): %s" % " · ".join(_eventos))
	print("MEDIDAS: primera frase a los %.2f s · prólogo entero %.1f s · fotograma peor %.1f ms, p95 %.1f ms, mediana %.1f ms · memoria estática %.1f → %.1f MB (máx. %.1f)" % [
		primera, duracion, _peor, _p(0.95), _p(0.5), _mem0, _mem1, _memmax])
	if "repetir" in OS.get_cmdline_user_args():   # ¿el coste del primer fotograma es de la primera vez o de cada vez?
		await _esperar(60)
		var desde := _todos.size()
		D.start("prologo")
		await _esperar(8)
		var otra: Array = _todos.slice(desde, _todos.size())
		print("SEGUNDA VEZ: peor de los 8 fotogramas tras empezar %.1f ms" % otra.max())
		D.end_timeline(true)
		await _esperar(30)
	await _esperar(60)
	await _foto("%s_despues" % etiqueta)
	if _escena() != MAPA:
		_fallo("la pulsación que cierra el prólogo también hace algo en el mapa: ahora se está en %s" % _escena())
		return _fin()
	var antes: Vector2 = m.jugador.position
	Input.action_press("ui_right")
	await _esperar(30)
	Input.action_release("ui_right")
	if m.jugador.position.distance_to(antes) < 4.0:
		_fallo("al terminar el prólogo, Kael no se mueve")
	_fin()


# Medidas comparables: duración real de cada fotograma (con ventana) y memoria estática, mientras dura el prólogo.
var _tiempos: Array = []
var _ultimo := 0
var _midiendo := false
var _todos: Array = []                         # cada fotograma desde el principio de la prueba, en ms
var _proceso: Array = []                       # de cada uno, el tiempo de proceso (scripts), en ms
var _dibujo: Array = []                        # de cada uno, lo que tarda en dibujarse (entre pre y post draw), en ms
var _t_pre := 0
var _t_eventos := 0
var _eventos: Array = []
var _ultimo_g := 0
var _tl := -1                                    # fotograma en que empieza la línea de tiempo
var _tl_fin := -1                                # y en el que termina
var _peor := 0.0
var _peor_en := 0
var _peor_que := ""
var _mem0 := 0.0
var _mem1 := 0.0
var _memmax := 0.0


func _medir(empezar: bool) -> void:
	if empezar:
		_tiempos.clear()
		_peor = 0.0
		_mem0 = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
		_memmax = _mem0
		_ultimo = Time.get_ticks_usec()
		_midiendo = true
		if not process_frame.is_connected(_tic):
			process_frame.connect(_tic)
	else:
		_midiendo = false
		_mem1 = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0


func _tic_global() -> void:
	var ahora := Time.get_ticks_usec()
	_todos.append((ahora - _ultimo_g) / 1000.0)
	_proceso.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)   # lo que gastan los scripts
	_ultimo_g = ahora


func _tic() -> void:
	if not _midiendo:
		return
	var ahora := Time.get_ticks_usec()
	var ms := (ahora - _ultimo) / 1000.0
	_ultimo = ahora
	_tiempos.append(ms)
	if ms > _peor:                                 # dónde cae el peor fotograma, para atribuirlo
		_peor_en = _tiempos.size()
		_peor_que = "texto «%s», línea %s" % [_texto_visible().left(24), D.current_timeline != null]
	_peor = maxf(_peor, ms)
	_memmax = maxf(_memmax, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)


func _p(q: float) -> float:
	if _tiempos.is_empty():
		return 0.0
	var t := _tiempos.duplicate()
	t.sort()
	return t[int(q * (t.size() - 1))]


# Cuánto de la frase está ya a la vista (Dialogic la va escribiendo; las pausas [pause] la dejan a medias un momento).
func _proporcion() -> float:
	for n in get_nodes_in_group("dialogic_dialog_text"):
		if n is RichTextLabel and n.is_visible_in_tree():
			return 1.0 if n.visible_characters < 0 else n.visible_ratio
	return 0.0


func _texto_visible() -> String:
	for n in get_nodes_in_group("dialogic_dialog_text"):
		if n is RichTextLabel and n.is_visible_in_tree():
			return n.get_parsed_text()
	return ""


func _guardar_partida_existente() -> void:
	var P = load("res://progreso.gd")
	var d := {"escena_guardada": MAPA, "prologo_visto": true, "pos_mapa": Vector2(520, 360), "pos_mapa_ok": true,
		"grupo_activo": ["Kael"]}
	var f := FileAccess.open(P.archivo(), FileAccess.WRITE)
	f.store_string(var_to_str(d))
	f.close()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _fin() -> void:
	print("CAPTURAS hechas en ", salida)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
