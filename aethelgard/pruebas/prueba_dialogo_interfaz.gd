extends SceneTree
# Prueba de la interfaz de los diálogos reutilizada (recursos.gd, carga.gd y «dialogic/layout/end_behaviour» = 1):
#   1. el proyecto oculta la interfaz al acabar un diálogo (no la borra) y el estilo existe;
#   2. precalentar_dialogos() la crea oculta una sola vez;
#   3. un diálogo la usa (la misma) y se ve;
#   4. cortado en seco (end_timeline(true), sin el final de Dialogic) no deja nada: ni texto, ni nombre, ni retratos, y la
#      interfaz sigue viva y oculta. Antes, un control: sin la limpieza de Recursos sí queda algo (si no, esta prueba no
#      comprobaría nada);
#   5. el diálogo siguiente usa la misma interfaz y no enseña nada del anterior;
#   6. con el final normal (end_timeline(): el «[clear]» de Dialogic) también acaba oculta, viva y limpia;
#   7. sigue viva tras cambiar de escena, y las conexiones a las señales de Dialogic no se acumulan entre
#      conversaciones ni al cambiar de escena;
#   8. una pulsación, una acción (boton_dialogo.gd): la Intro que abre un diálogo (como en la región) no pasa además
#      la primera frase aunque llegue otro evento en el mismo fotograma;
#   9. opciones: un diálogo con preguntas cortado a medias no deja botones de opción para el siguiente.
# Sin ventana. Usa los diálogos reales npc_rosa (con retrato) y pv_tilo, y uno de prueba con dos opciones. Teclas
# simuladas (Input.parse_input_event).

const ESPERA_FINAL := 150                        # fotogramas para el final normal de Dialogic (anima y tarda ~1-2 s)
const CON_OPCIONES := "Una pregunta de prueba.\n- Sí\n\tBien.\n- No\n\tVale."

var R
var D
var frames := 0
var paso := 0
var f_paso := 0
var interfaz
var fallos: Array = []
var conexiones := {}                             # señal -> conexiones al empezar
var acciones := 0                                # veces que Dialogic toma una pulsación (dialogic_action_priority)
var lanzador: Node


# Abre un diálogo con Intro y se queda con la pulsación, como la región 3D (_unhandled_input → _accion).
class Lanzador extends Node:
	func _unhandled_input(ev: InputEvent) -> void:
		if ev.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			get_node("/root/Dialogic").start("pv_tilo")


func _senales() -> Dictionary:
	var r := {}
	for s in ["timeline_started", "timeline_ended", "signal_event", "text_signal", "event_handled", "state_changed"]:
		r[s] = D.get(s).get_connections().size()
	r["Inputs.dialogic_action"] = D.Inputs.dialogic_action.get_connections().size()
	r["Inputs.dialogic_action_priority"] = D.Inputs.dialogic_action_priority.get_connections().size()
	r["Text.text_finished"] = D.Text.text_finished.get_connections().size()
	return r


func _tecla(codigo: Key, pulsada: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = pulsada
	Input.parse_input_event(e)


func _contar() -> void:
	acciones += 1


func _opciones_visibles() -> int:
	return get_nodes_in_group("dialogic_choice_button").filter(func(b): return b.is_visible_in_tree()).size()


func _initialize() -> void:
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")


func _fallo(texto: String) -> void:
	fallos.append(texto)


func _textos() -> String:
	var r := ""
	for n in get_nodes_in_group("dialogic_dialog_text"):
		r += str(n.text)
	for n in get_nodes_in_group("dialogic_name_label"):
		if n.is_visible_in_tree():
			r += str(n.text)
	return r.strip_edges()


func _retratos() -> int:
	return D.Portraits.get_joined_characters().size()


func _limpia(cuando: String) -> void:
	if D.current_timeline != null:
		_fallo("%s: el diálogo no ha terminado" % cuando)
	if not is_instance_valid(interfaz) or interfaz.is_queued_for_deletion() or D.Styles.get_layout_node() != interfaz:
		_fallo("%s: al acabar se ha borrado la interfaz" % cuando)
	elif interfaz.visible:
		_fallo("%s: al acabar la interfaz sigue viéndose" % cuando)
	if _retratos() > 0:
		_fallo("%s: al acabar queda un retrato" % cuando)
	if _textos() != "":
		_fallo("%s: al acabar queda texto («%s»)" % [cuando, _textos().left(40)])


func _siguiente() -> void:
	paso += 1
	f_paso = frames


func _process(_d: float) -> bool:
	frames += 1
	var f := frames - f_paso
	match paso:
		0:
			if frames < 3:
				return false
			if int(ProjectSettings.get_setting("dialogic/layout/end_behaviour", 0)) != 1:
				_fallo("1: el proyecto no oculta la interfaz al acabar (dialogic/layout/end_behaviour != 1)")
			var estilo: String = R.ruta_estilo_dialogos()
			if estilo == "" or not ResourceLoader.exists(estilo):
				_fallo("1: no se encuentra el estilo de los diálogos (%s)" % estilo)
			var us: int = R.precalentar_dialogos()
			interfaz = D.Styles.get_layout_node()
			if us <= 0 or interfaz == null:
				_fallo("2: precalentar_dialogos() no ha creado la interfaz")
			elif interfaz.visible:
				_fallo("2: la interfaz preparada se ve")
			if R.precalentar_dialogos() != 0 or D.Styles.get_layout_node() != interfaz:
				_fallo("2: precalentar_dialogos() la ha creado otra vez")
			conexiones = _senales()
			D.timeline_ended.disconnect(R._al_acabar_dialogo)   # para el control
			_siguiente()
		1:                                          # control, sin la limpieza de Recursos: algo queda
			if f == 2:
				if not is_instance_valid(interfaz) or not interfaz.is_inside_tree():
					_fallo("2: la interfaz preparada no está en el árbol")
				D.start("npc_rosa")
			elif f == 20:
				D.end_timeline(true)
			elif f == 25:
				if _retratos() == 0 and _textos() == "":
					_fallo("control: sin la limpieza de Recursos tampoco queda nada (la prueba 4 no comprobaría nada)")
				D.clear(DialogicGameHandler.ClearFlags.KEEP_VARIABLES)
				D.timeline_ended.connect(R._al_acabar_dialogo)
				_siguiente()
		2:                                          # cortado en seco, con la limpieza
			if f == 2:
				D.start("npc_rosa")
			elif f == 20:
				if D.current_timeline == null or D.Styles.get_layout_node() != interfaz or not interfaz.visible:
					_fallo("3: el diálogo no usa la interfaz preparada o no se ve")
				if _textos() == "" or _retratos() == 0:
					_fallo("3: el diálogo no muestra texto o retrato (la prueba no comprueba nada)")
				D.end_timeline(true)
			elif f == 25:
				_limpia("4 (cortado en seco)")
				_siguiente()
		3:                                          # el siguiente diálogo; luego, final normal
			if f == 2:
				D.start("pv_tilo")
			elif f == 3:
				if D.Styles.get_layout_node() != interfaz or not interfaz.visible:
					_fallo("5: el diálogo siguiente no usa la misma interfaz")
				if _retratos() > 0:
					_fallo("5: el diálogo siguiente empieza con un retrato del anterior")
				if "Rosa" in _textos() or "flores" in _textos():
					_fallo("5: el diálogo siguiente enseña texto del anterior")
			elif f == 20:
				D.end_timeline()
			elif f == 20 + ESPERA_FINAL:
				_limpia("6 (final normal)")
				_siguiente()
		4:                                          # 8. una pulsación, una acción
			if f == 2:
				lanzador = Lanzador.new()
				root.add_child(lanzador)
				D.Inputs.dialogic_action_priority.connect(_contar)
			elif f == 4:
				acciones = 0
				_tecla(KEY_ENTER, true)             # la abre el lanzador...
				_tecla(KEY_SHIFT, false)            # ...y en el mismo fotograma llega otro evento
			elif f == 6:
				_tecla(KEY_ENTER, false)
				if D.current_timeline == null:
					_fallo("8: Intro no abre el diálogo de prueba")
				elif D.current_state == D.States.IDLE:     # (al abrirse anima la caja y luego escribe: ANIMATING o REVEALING)
					_fallo("8: la Intro que abre el diálogo deja ya la primera frase entera (estado %d)" % D.current_state)
				if acciones != 0:
					_fallo("8: la Intro que abre el diálogo cuenta %d veces en Dialogic" % acciones)
			elif f == 8:
				D.end_timeline(true)
				D.Inputs.dialogic_action_priority.disconnect(_contar)
				lanzador.queue_free()
			elif f == 14:
				var t := DialogicTimeline.new()     # 9. opciones
				t.from_text(CON_OPCIONES)
				D.start(t)
			elif f == 70:
				if _opciones_visibles() == 0:
					_fallo("9: el diálogo de prueba no enseña sus opciones (la prueba no comprueba nada)")
				D.end_timeline(true)                # cortado con las opciones en pantalla
			elif f == 76:
				if _opciones_visibles() != 0:
					_fallo("9: al cortar el diálogo quedan %d opciones a la vista" % _opciones_visibles())
				D.start("pv_tilo")
			elif f == 80:
				if _opciones_visibles() != 0:
					_fallo("9: el diálogo siguiente enseña opciones del anterior")
				D.end_timeline(true)
			elif f == 86:
				change_scene_to_packed(_escena_vacia())
				_siguiente()
		5:
			if f == 5:
				if not is_instance_valid(interfaz) or D.Styles.get_layout_node() != interfaz:
					_fallo("7: la interfaz no sigue viva tras cambiar de escena")
				var ahora := _senales()
				for s in conexiones:
					if ahora[s] != conexiones[s]:
						_fallo("7: las conexiones a %s pasan de %d a %d tras varias conversaciones" % [s, conexiones[s], ahora[s]])
				print("OK interfaz de los diálogos: preparada una vez, oculta entre diálogos, limpia (texto, retratos y opciones), " +
					"sin conexiones de más, una pulsación una acción, y viva tras cambiar de escena")
				for t in fallos:
					print("FALLO: ", t)
				print("FALLOS: %d" % fallos.size())
				quit(1 if fallos.size() > 0 else 0)
				return true
	if frames > 900:
		print("FALLO: tiempo agotado en el paso %d" % paso)
		quit(1)
		return true
	return false


func _escena_vacia() -> PackedScene:
	var p := PackedScene.new()
	p.pack(Node.new())
	return p
