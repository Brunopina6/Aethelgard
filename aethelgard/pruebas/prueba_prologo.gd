extends SceneTree
# Prueba del prólogo con su puesta en escena (T-081; escena_dialogo.gd, retrato_vivo.gd). Sin ventana, con datos
# aislados y «-- 3d». Pasadas por el mapa con una partida nueva:
#   1. Entero con el teclado: 9 frases, una pulsación por frase; los retratos son «vivos» y quien habla tiene el foco;
#      al acabar, todo vuelve como estaba (cámara, capa y transparencia de Dialogic, sin pausa, el muñeco del mapa a la
#      vista) y Kael vuelve a andar; ninguna pulsación de más llega al mapa.
#      Poses (T-084): mientras habla Lya, Kael está en reposo (sin la mano junto a la cabeza: la ilustración de reposo
#      no es la de antes); en cada una de sus cuatro frases hace un gesto con su ilustración, distinto en cada una, y
#      el fundido entre poses termina (no se queda la ilustración de encima a medias).
#   2. Saltado con Esc en mitad del diálogo: lo mismo, y no se queda nada a medias.
#   3. Saltado durante la entrada (antes de la primera frase): lo mismo.
#   4. Deprisa (T-084): una pulsación cada 0,1 s, también mientras se escribe y en mitad de los fundidos: termina,
#      ninguna frase se queda atrás y los retratos no se quedan a medias.
#   5. Reabierto (T-084): al acabar, la misma escena otra vez en el mismo mapa; empieza con Kael en reposo, se salta y
#      se vuelve a jugar.
# En ninguno cambia la misión: el prólogo queda visto y no se pone ningún hito ni se guarda nada raro.

const MAPA := "res://mapa.tscn"
const REPOSO := "res://dialogos/retratos/kael_reposo.png"
const ORIGINAL := "res://dialogos/retratos/kael.png"   # la de la mano junto a la cabeza: ya no sale en el prólogo
const GESTOS_KAEL := ["ligero", "brazalete", "sorpresa", "decidido"]   # sus cuatro frases, en orden

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


func _pulsar(codigo: Key, espera := 2) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = true
	Input.parse_input_event(e)
	await _esperar(espera)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await _esperar(espera)


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
	await _pasada("rapido")
	print("OK prólogo: ", ", ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# Los retratos vivos que hay ahora, por personaje («Kael», «Lya»).
func _vivos() -> Dictionary:
	var r := {}
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and n.get_script().resource_path == "res://dialogos/retrato_vivo.gd" and n.is_inside_tree():
			var c = n.get("character")
			if c != null:
				r[c.display_name] = n
	return r


func _ruta_textura(retrato: Node) -> String:
	var t: Texture2D = retrato.get_node("Foco/Gesto/Respira/Portrait").texture
	return t.resource_path if t != null else ""


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
	elif modo == "rapido":
		await _deprisa(modo)
	else:
		if not await _hasta(func(): return not D.paused and _texto() != ""):
			_fallo("%s: el diálogo no aparece tras la entrada" % modo)
			return
		var frases := 0
		var gestos_vistos: Array = []
		while D.current_timeline != null and frases < 20:
			# poses de Kael mientras se escribe la frase: desde que sale hasta que está entera
			var vistas := {}
			var hablante := ""
			while D.current_timeline != null and not (D.current_state == D.States.IDLE and _texto() != "" and _revelado()):
				var v := _vivos()
				if v.has("Kael") and _texto() != "":
					vistas[String(v["Kael"].get_meta("pose", "?"))] = true
					var sp = D.Text.get_current_speaker()
					hablante = sp.display_name if sp != null else ""
				await process_frame
			if D.current_timeline == null:
				break
			frases += 1
			var v2 := _vivos()
			if v2.has("Kael"):
				vistas[String(v2["Kael"].get_meta("pose", "?"))] = true
				var sp2 = D.Text.get_current_speaker()
				hablante = sp2.display_name if sp2 != null else hablante
			if frases == 1:
				_comprobar_retratos()
			if modo == "entero":
				_comprobar_poses(frases, hablante, vistas.keys(), gestos_vistos)
			if modo == "saltar_dialogo" and frases == 3:
				await _pulsar(KEY_ESCAPE)
				break
			var antes := _texto()
			await _esperar(6)                      # como una persona: Dialogic no acepta pulsar en los 0,1 s tras
			await _pulsar(KEY_ENTER)               # escribir la frase (advance_delay), para no saltarse dos
			await _esperar(3)
			if D.current_timeline != null and _texto() == antes and _revelado() and D.current_state == D.States.IDLE:
				_fallo("%s: la frase %d no avanza con una pulsación" % [modo, frases])
		if modo == "entero":
			if frases != 9:
				_fallo("entero: salen %d frases (esperaba 9)" % frases)
			if gestos_vistos != GESTOS_KAEL:
				_fallo("entero: los gestos de Kael en sus frases son %s (esperaba %s)" % [gestos_vistos, GESTOS_KAEL])
	# al acabar (o al saltar): todo como estaba
	if not await _volver_al_juego(m, escena, zoom0, lay, capa0, modo):
		return
	if modo == "entero":                           # 5. reabierto en el mismo mapa: empieza en reposo y se salta
		await _reabrir(m)
	hechos.append(modo)


# Kael en reposo mientras habla Lya, y con el gesto de la frase (con su ilustración) cuando habla él.
func _comprobar_poses(frase: int, hablante: String, vistas: Array, gestos_vistos: Array) -> void:
	var v := _vivos()
	if not v.has("Kael"):
		_fallo("frase %d: no está el retrato vivo de Kael" % frase)
		return
	var k: Node = v["Kael"]
	if _ruta_textura(k) == ORIGINAL:
		_fallo("frase %d: Kael sale con la ilustración de la mano junto a la cabeza (%s)" % [frase, ORIGINAL])
	if hablante == "Lya":
		if vistas != ["reposo"]:
			_fallo("frase %d (habla Lya): Kael no está en reposo (poses vistas: %s)" % [frase, vistas])
	elif hablante == "Kael":
		var gestos := vistas.filter(func(p): return p != "reposo")
		if gestos.is_empty():
			_fallo("frase %d (habla Kael): no hace ningún gesto con su ilustración" % frase)
		else:
			gestos_vistos.append(gestos[0])
	else:
		_fallo("frase %d: no sé quién habla («%s»)" % [frase, hablante])
	var encima: Sprite2D = k.get_node("Foco/Gesto/Respira/Siguiente")
	if encima.visible and k.get("_fundido") == null:
		_fallo("frase %d: la ilustración del fundido se queda a la vista sin fundido en marcha" % frase)


# Deprisa: una pulsación cada 0,1 s hasta el final (también mientras se escribe y en mitad de los fundidos).
func _deprisa(modo: String) -> void:
	if not await _hasta(func(): return not D.paused and _texto() != ""):
		_fallo("%s: el diálogo no aparece tras la entrada" % modo)
		return
	var vistas := {}
	var pulsaciones := 0
	while D.current_timeline != null and pulsaciones < 80:
		var t := _texto()
		if t != "":
			vistas[t] = true
		await _pulsar(KEY_ENTER, 1)
		pulsaciones += 1
		await _esperar(1)
		var v := _vivos()
		if v.has("Kael"):
			var encima: Sprite2D = v["Kael"].get_node("Foco/Gesto/Respira/Siguiente")
			var base: Sprite2D = v["Kael"].get_node("Foco/Gesto/Respira/Portrait")
			if base.texture == null:
				_fallo("%s: el retrato de Kael se queda sin ilustración" % modo)
				break
			if not encima.visible and absf(base.modulate.a - 1.0) > 0.01:
				_fallo("%s: el retrato de Kael se queda medio transparente (%.2f)" % [modo, base.modulate.a])
				break
	print("DEPRISA: %d frases vistas con %d pulsaciones" % [vistas.size(), pulsaciones])
	if D.current_timeline != null:
		_fallo("%s: con %d pulsaciones el prólogo no termina" % [modo, pulsaciones])
	elif vistas.size() != 9:
		_fallo("%s: se han visto %d frases (esperaba 9: ninguna se salta sin verse)" % [modo, vistas.size()])


# Al terminar: cámara, capa, transparencia, pausa, muñeco, la capa liberada, sin cambiar de escena, Kael anda y sin hitos.
func _volver_al_juego(m, escena, zoom0: Vector2, lay, capa0: int, modo: String) -> bool:
	if not await _hasta(func(): return m.escena_dialogo == null and D.current_timeline == null, 15.0):
		_fallo("%s: la escena no termina" % modo)
		return false
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
	if not _vivos().is_empty():
		_fallo("%s: al acabar quedan retratos vivos (%s)" % [modo, _vivos().keys()])
	if current_scene != m:
		_fallo("%s: una pulsación ha sacado al jugador del mapa (%s)" % [modo, current_scene.scene_file_path if current_scene else "?"])
		return false
	var antes_pos: Vector2 = m.jugador.position
	Input.action_press("ui_right")
	await _esperar(20)
	Input.action_release("ui_right")
	if m.jugador.position.distance_to(antes_pos) < 4.0:
		_fallo("%s: al terminar, Kael no se mueve" % modo)
	if Engine.has_meta("hitos") and not Engine.get_meta("hitos", {}).is_empty():
		_fallo("%s: el prólogo ha puesto hitos de misión (%s)" % [modo, Engine.get_meta("hitos")])
	return true


# Reabrir la escena en el mismo mapa (como si se volviera a lanzar): empieza limpia, con Kael en reposo; se salta con
# Esc a la segunda frase y el juego sigue.
func _reabrir(m) -> void:
	await _esperar(10)
	var zoom0: Vector2 = m.camara.zoom
	m._empezar_prologo()
	var escena = m.escena_dialogo
	var lay = D.Styles.get_layout_node()
	var capa0: int = escena._capa_dialogic if escena != null else 1
	if not await _hasta(func(): return not D.paused and _texto() != "", 15.0):
		_fallo("reabierto: el diálogo no aparece")
		return
	var v := _vivos()
	if not v.has("Kael") or v["Kael"].get_meta("pose", "") != "reposo" or _ruta_textura(v["Kael"]) != REPOSO:
		_fallo("reabierto: Kael no empieza en reposo (%s)" % (v["Kael"].get_meta("pose", "?") if v.has("Kael") else "sin retrato"))
	await _hasta(func(): return D.current_state == D.States.IDLE and _revelado(), 10.0)
	await _esperar(6)
	await _pulsar(KEY_ENTER)
	await _hasta(func(): return D.current_timeline == null or (_texto().begins_with("Lo he visto") and _revelado()), 10.0)
	await _pulsar(KEY_ESCAPE)
	if await _volver_al_juego(m, escena, zoom0, lay, capa0, "reabierto"):
		hechos.append("reabierto")


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
