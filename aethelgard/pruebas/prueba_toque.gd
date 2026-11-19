extends SceneTree
# Avanzar los diálogos con el dedo y con el ratón (boton_dialogo.gd, autoload «BotonDialogo»), como en el móvil. Sin
# ventana, con datos aislados. Reescrita el 19/11 (PC-8): la de antes solo imprimía «AVANZA / no avanza» con toques
# en posiciones fijas del mapa y desde la puesta en escena del prólogo (10/11) no comprobaba nada.
# Un diálogo de prueba de 8 frases (DialogicTimeline desde texto, sin personajes ni hitos) con la interfaz real de
# Dialogic precalentada como en la carga. Toques SIMULADOS de verdad (InputEventScreenTouch, que Godot convierte también
# en clic como en el móvil) en coordenadas del juego (1280 × 720), pasados por la transformada de la ventana raíz.
#   1. Sin diálogo, el botón «SEGUIR» no se ve; con el diálogo, sí.
#   2. Un toque en el cuadro de texto pasa UNA frase (el toque y su clic emulado no cuentan dos veces).
#   3. Un clic de ratón en el cuadro de texto pasa una frase.
#   4. Un toque en «SEGUIR ▸» pasa una frase.
#   5. Un toque fuera del cuadro (arriba, sobre la escena) no pasa más de una frase (hoy, ninguna).
#   6. Un toque mientras se escribe la frase la completa y no la salta.
#   7. Dos toques seguidos en menos de 0,15 s pasan una sola frase (un toque del móvil da también un clic).
#   8. Tocando, el diálogo se acaba y «SEGUIR» se oculta.
# Los pasos 2, 3, 4 y 7 comprueban además (revisión 19/11) que la frase la pasa boton_dialogo.gd (BotonDialogo._seguir
# cambia _ultimo) y no la entrada propia de Dialogic, que también avanza con el clic izquierdo: con la zona de toque
# en MOUSE_FILTER_IGNORE el clic del paso 3 seguía pasando la frase. El paso 5 acepta cero o una frase (lo de fuera del
# cuadro es de Dialogic o de la escena): solo vigila que no pasen dos.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const FRASES := [                                 # largas: escribirlas lleva un rato (el paso 6 toca a medias)
	"Primera frase de la prueba de toques, con el cuadro de texto abajo y el botón de seguir a la derecha.",
	"Segunda frase: un toque en el cuadro de texto la ha traído, y uno solo, aunque el móvil dé también un clic.",
	"Tercera frase: ha llegado con un clic de ratón en el cuadro de texto, como se juega en el ordenador.",
	"Cuarta frase: esta la ha traído el botón de seguir, que está junto al cuadro y es grande para el dedo.",
	"Quinta frase: un toque arriba, sobre la escena, puede pasarla o no, pero nunca dos frases de golpe.",
	"Sexta frase: un toque mientras se escribe la completa sin saltarla, y el siguiente ya la pasa del todo.",
	"Séptima frase: dos toques muy seguidos, en menos de quince centésimas, cuentan como uno solo y pasan una.",
	"Octava y última frase de la prueba: con el siguiente toque se acaba el diálogo y el botón se esconde.",
]
const DENTRO := Vector2(640, 600)                 # el cuadro de texto (ZONA_TEXTO: y de 470 a 720)
const FUERA := Vector2(640, 200)                  # arriba, sobre la escena

var D
var B
var fallos: Array = []
var hechos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 10.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _segundos(s: float) -> void:
	var limite := Time.get_ticks_msec() + int(s * 1000.0)
	while Time.get_ticks_msec() < limite:
		await process_frame


func _texto() -> String:
	for n in get_nodes_in_group("dialogic_dialog_text"):
		if n is RichTextLabel and n.is_visible_in_tree():
			return n.get_parsed_text().strip_edges()
	return ""


func _revelado() -> bool:
	for n in get_nodes_in_group("dialogic_dialog_text"):
		if n is RichTextLabel and n.is_visible_in_tree():
			return n.visible_characters < 0 or n.visible_ratio >= 0.999
	return false


func _frase() -> int:
	return FRASES.find(_texto())


func _quieta() -> bool:
	return D.current_timeline != null and D.current_state == D.States.IDLE and _revelado() and _frase() >= 0


# La frase entera y quieta (y el retraso de Dialogic tras escribirla, advance_delay, pasado), como una persona.
func _lista() -> bool:
	var ok := await _hasta(_quieta)
	await _segundos(0.3)
	return ok


func _tocar(p: Vector2, soltar := true) -> void:
	for pulsado in ([true, false] if soltar else [true]):
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = root.get_final_transform() * p
		t.pressed = pulsado
		Input.parse_input_event(t)
		await _esperar(1)


func _clic(p: Vector2) -> void:
	for pulsado in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = root.get_final_transform() * p
		e.global_position = e.position
		e.pressed = pulsado
		Input.parse_input_event(e)
		await _esperar(1)


# Hace «accion» con la frase «antes» entera y comprueba que pasa a la siguiente, una sola.
func _paso(n: int, que: String, accion: Callable) -> void:
	var antes := _frase()
	var ultimo: int = B._ultimo
	await accion.call()
	await _lista()
	var despues := _frase()
	if despues != antes + 1:
		_fallo("%d: %s pasa de la frase %d a la %d (esperaba la %d)" % [n, que, antes + 1, despues + 1, antes + 2])
	elif B._ultimo == ultimo:
		# (revisión 19/11) la frase pasa, pero no por boton_dialogo.gd (_seguir apunta _ultimo): la ha pasado la entrada
		# propia de Dialogic (contraprueba con zona.mouse_filter = IGNORE: el clic del paso 3 seguía pasando la frase)
		_fallo("%d: %s pasa la frase, pero no por boton_dialogo.gd (BotonDialogo._seguir no se llama)" % [n, que])
	else:
		hechos.append(que)
	print("%d. %s: frase %d → %d" % [n, que, antes + 1, despues + 1])


func _probar() -> void:
	D = root.get_node("Dialogic")
	B = root.get_node("BotonDialogo")
	await _esperar(3)
	root.get_node("Recursos").precalentar_dialogos()
	await _esperar(3)
	# 1. sin diálogo, sin botón
	if B.visible:
		_fallo("1: «SEGUIR» se ve sin ningún diálogo")
	var t := DialogicTimeline.new()
	t.from_text("\n".join(FRASES))
	D.start(t)
	if not await _lista() or _frase() != 0:
		_fallo("1: el diálogo de prueba no enseña su primera frase («%s»)" % _texto())
		_fin()
		return
	if not B.visible:
		_fallo("1: con un diálogo abierto, «SEGUIR» no se ve")
	var caja: Rect2 = B.boton.get_global_rect()
	if not caja.has_point(caja.get_center()) or caja.size.x < 100.0:
		_fallo("1: el botón «SEGUIR» no tiene tamaño (%s)" % caja)
	hechos.append("botón con diálogo")
	# 2-5. una pulsación, una frase
	await _paso(2, "toque en el cuadro de texto", func(): await _tocar(DENTRO))
	await _paso(3, "clic en el cuadro de texto", func(): await _clic(DENTRO))
	await _paso(4, "toque en SEGUIR", func(): await _tocar(caja.get_center()))
	# 5. fuera del cuadro (arriba, sobre la escena): como mucho una frase (boton_dialogo.gd: avanza «el cuadro de texto»;
	#    lo de fuera es de Dialogic o de la escena). Hoy no pasa ninguna.
	var antes := _frase()
	await _tocar(FUERA)
	await _segundos(0.3)
	await _lista()
	var paso5 := _frase() - antes
	print("5. toque sobre la escena: frase %d → %d" % [antes + 1, _frase() + 1])
	if paso5 < 0 or paso5 > 1:
		_fallo("5: un toque sobre la escena pasa %d frases" % paso5)
	else:
		hechos.append("toque sobre la escena (%d frase)" % paso5)
	# 6. tocar mientras se escribe la completa. La frase empieza con la acción de Dialogic (como una tecla: no cuenta
	#    para los 0,15 s de boton_dialogo.gd) y se toca en cuanto Dialogic acepta pulsaciones (su bloqueo tras empezar,
	#    en tiempo de juego), con la frase aún a medias. Así vale con y sin --fixed-fps.
	await _lista()
	antes = _frase()
	D.Inputs.handle_input()
	await _esperar(1)
	await _hasta(func(): return not D.Inputs.is_input_blocked() or _revelado(), 5.0)
	if _frase() != antes + 1 or _revelado():
		_fallo("6: la frase %d no se está escribiendo cuando ya se puede tocar (frase %d, entera %s)" % [antes + 2, _frase() + 1, _revelado()])
	else:
		await _tocar(DENTRO)
		await _esperar(4)
		if _frase() != antes + 1 or not _revelado():
			_fallo("6: un toque mientras se escribe no deja la frase %d entera (frase %d, entera %s)" % [antes + 2, _frase() + 1, _revelado()])
		else:
			hechos.append("toque al escribir completa")
		print("6. toque mientras se escribe: frase %d, entera %s" % [_frase() + 1, _revelado()])
	# 7. dos toques muy seguidos: una frase
	await _lista()
	await _paso(7, "dos toques seguidos (< 0,15 s)", func():
		await _tocar(DENTRO)
		await _tocar(DENTRO))
	# 8. toques hasta el final: el diálogo se acaba y «SEGUIR» se oculta
	for i in FRASES.size():
		if D.current_timeline == null:
			break
		await _lista()
		await _tocar(DENTRO)
		await _segundos(0.2)
	if not await _hasta(func(): return D.current_timeline == null, 10.0):
		_fallo("8: los toques no acaban el diálogo («%s»)" % _texto())
	await _esperar(3)
	if B.visible:
		_fallo("8: acabado el diálogo, «SEGUIR» sigue a la vista")
	else:
		hechos.append("fin y botón oculto")
	_fin()


func _fin() -> void:
	if D.current_timeline != null:
		D.end_timeline(true)
	print("OK toques: ", ", ".join(hechos))
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
