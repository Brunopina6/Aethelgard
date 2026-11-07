@tool
extends EditorPlugin
# Panel «Posador»: graba la pose de un PosadorIK como fotogramas y la guarda en una librería.

var panel: VBoxContainer
var estado: Label
var nombre: LineEdit
var libreria: LineEdit
var tiempo: SpinBox
var salto: SpinBox
var bucle: CheckBox
var lista: Label

var posador: PosadorIK
var anim: Animation


func _enter_tree() -> void:
	anim = PosadorGrabador.nueva_animacion(0.0)
	_crear_panel()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)
	EditorInterface.get_selection().selection_changed.connect(_seleccion)
	_seleccion()


func _exit_tree() -> void:
	if EditorInterface.get_selection().selection_changed.is_connected(_seleccion):
		EditorInterface.get_selection().selection_changed.disconnect(_seleccion)
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()


func _crear_panel() -> void:
	panel = VBoxContainer.new()
	panel.name = "Posador"
	estado = Label.new()
	estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(estado)

	nombre = _campo("Animación", "pose_kael")
	libreria = _campo("Librería", "res://animaciones/posador/kael.res")

	var fila := HBoxContainer.new()
	fila.add_child(_etiqueta("Tiempo (s)"))
	tiempo = SpinBox.new()
	tiempo.step = 0.01
	tiempo.max_value = 60.0
	tiempo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(tiempo)
	fila.add_child(_etiqueta("Salto"))
	salto = SpinBox.new()
	salto.step = 0.05
	salto.max_value = 10.0
	salto.value = 0.25
	fila.add_child(salto)
	panel.add_child(fila)

	bucle = CheckBox.new()
	bucle.text = "En bucle (andar, idle…)"
	panel.add_child(bucle)

	_boton("Grabar fotograma", _grabar)
	_boton("Borrar fotograma en este tiempo", _borrar)
	_boton("Recolocar objetivos en la pose actual", _recolocar)
	_boton("Guardar en la librería", _guardar)
	_boton("Empezar animación nueva", _nueva)

	lista = Label.new()
	lista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(lista)
	_actualizar_lista()


func _etiqueta(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


func _campo(t: String, valor: String) -> LineEdit:
	panel.add_child(_etiqueta(t))
	var e := LineEdit.new()
	e.text = valor
	panel.add_child(e)
	return e


func _boton(t: String, f: Callable) -> void:
	var b := Button.new()
	b.text = t
	b.pressed.connect(f)
	panel.add_child(b)


func _seleccion() -> void:
	posador = null
	for n in EditorInterface.get_selection().get_selected_nodes():
		var x: Node = n
		while x and posador == null:
			if x is PosadorIK:
				posador = x
			x = x.get_parent()
		if posador:
			break
	if estado:
		estado.text = ("Posador: %s" % posador.get_path()) if posador \
			else "Selecciona un PosadorIK o uno de sus objetivos."


func _animation_player() -> AnimationPlayer:
	if posador == null:
		return null
	var x: Node = posador.get_skeleton()
	while x:
		for c in x.get_children():
			if c is AnimationPlayer:
				return c
		x = x.get_parent()
	return null


func _grabar() -> void:
	var ap := _animation_player()
	if posador == null or ap == null:
		push_warning("Posador: no hay PosadorIK seleccionado o no encuentro su AnimationPlayer")
		return
	var ruta := PosadorGrabador.ruta_esqueleto(ap, posador.get_skeleton())
	var n := PosadorGrabador.grabar_fotograma(anim, posador, ruta, tiempo.value)
	print("Posador: fotograma %.2f s grabado (%d claves)" % [tiempo.value, n])
	tiempo.value += salto.value
	_actualizar_lista()


func _borrar() -> void:
	PosadorGrabador.borrar_fotograma(anim, tiempo.value)
	_actualizar_lista()


func _recolocar() -> void:
	if posador:
		posador.crear_objetivos()


func _guardar() -> void:
	anim.loop_mode = Animation.LOOP_LINEAR if bucle.button_pressed else Animation.LOOP_NONE
	var err := PosadorGrabador.guardar(anim, nombre.text.strip_edges(), libreria.text.strip_edges())
	if err == OK:
		print("Posador: '%s' guardada en %s" % [nombre.text, libreria.text])
		EditorInterface.get_resource_filesystem().scan()
	else:
		push_error("Posador: no se pudo guardar (%s)" % error_string(err))


func _nueva() -> void:
	anim = PosadorGrabador.nueva_animacion(0.0)
	tiempo.value = 0.0
	_actualizar_lista()


func _actualizar_lista() -> void:
	if lista == null:
		return
	var t := PosadorGrabador.tiempos(anim)
	lista.text = "Fotogramas: " + (", ".join(Array(t).map(func(x): return "%.2f" % x)) if t.size() else "ninguno")
