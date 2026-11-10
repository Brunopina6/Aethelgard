extends SceneTree
# Lo que falló en el Redmi con la v520 (11/11) y no se veía en el PC, porque las pruebas llamaban a _accion() o
# pulsaban Intro, nunca el botón con el dedo:
#   1. En la ciudad 2D (ciudad_oakhaven.gd), «Recoger la página» se pulsa con el dedo (aquí, con el ratón: Android
#      convierte el toque en ratón) y la página se recoge. Antes, zona.gd escondía el botón y la ciudad lo volvía a
#      enseñar en cada fotograma, y eso anulaba la pulsación. Se mantiene pulsado varios fotogramas, como un dedo.
#   2. El botón Atrás de Android (NOTIFICATION_WM_GO_BACK_REQUEST, no ui_cancel) cierra la ventana de un taller
#      (alquimia_menu.gd) y la de la botica (servicios_botica.gd); con la alquimia abierta dentro de la botica, cierra
#      solo la alquimia.
# Usa su propia partida (Engine «archivo_partida_prueba»): nunca toca la de verdad. Imprime «FALLOS: n».

const CIUDAD := "res://ciudad_oakhaven.tscn"
const ARCHIVO := "user://prueba_toque_oakhaven.save"
const T := 64.0
var fallos := 0


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _initialize() -> void:
	_probar.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _probar() -> void:
	await _pagina_con_el_dedo()
	await _atras()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _clic(pos: Vector2, pulsado: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pulsado
	var en_ventana: Vector2 = root.get_final_transform() * pos   # sin ventana, la ventana es diminuta y se escala
	ev.position = en_ventana
	ev.global_position = en_ventana
	root.push_input(ev)


func _pagina_con_el_dedo() -> void:
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true, "enc_formula_pedido": true, "enc_formula_pip": true})
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad"})
	Engine.set_meta("pos_zona", Vector2(40.0, 30.6) * T)      # junto a la página de la Calle Mayor (40, 30)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	change_scene_to_file(CIUDAD)
	await _frames(40)
	var z = current_scene
	if z == null or not z.has_method("_hay_otra_accion"):
		_fallo("1: no se abrió la ciudad 2D")
		return
	var b: Button = z.boton_examinar
	if not b.visible or b.text != "Recoger la página":
		_fallo("1: junto a la página, el botón no dice «Recoger la página» (visible %s, «%s»)" % [b.visible, b.text])
		return
	var centro := b.get_global_rect().get_center()
	var pulsado := [0]
	b.pressed.connect(func(): pulsado[0] += 1)
	_clic(centro, true)
	await _frames(6)                                          # un dedo tarda unos fotogramas en levantarse
	_clic(centro, false)
	await _frames(4)
	if pulsado[0] != 1:
		_fallo("1: el botón no se pulsó una vez con el dedo (%d)" % pulsado[0])
	if not load("res://progreso.gd").estado("oakhaven", "pagina_2"):
		_fallo("1: al pulsar «Recoger la página» con el dedo, la página no se recoge")
	if load("res://progreso.gd").estado("oakhaven", "pagina_1") or load("res://progreso.gd").estado("oakhaven", "pagina_3"):
		_fallo("1: se recogió otra página")


func _atras() -> void:
	var cerrada := [false]
	var a = load("res://alquimia_menu.gd").new()
	a.taller = "forja"
	a.cerrado.connect(func(): cerrada[0] = true)
	root.add_child(a)
	await _frames(2)
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames(2)
	if not cerrada[0] or is_instance_valid(a):
		_fallo("2: Atrás no cierra la ventana del taller")
	var botica = load("res://servicios_botica.gd").new()
	var botica_cerrada := [false]
	botica.cerrado.connect(func(): botica_cerrada[0] = true)
	root.add_child(botica)
	await _frames(2)
	botica.call("_alquimia")                                  # la alquimia de Lya, abierta encima de la botica
	await _frames(2)
	var alq = botica.abierto
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames(2)
	if is_instance_valid(alq):
		_fallo("2: con la alquimia abierta en la botica, Atrás no la cierra")
	if botica_cerrada[0] or not is_instance_valid(botica):
		_fallo("2: con la alquimia abierta, Atrás cierra también la botica")
	elif botica.abierto != null:
		_fallo("2: la botica no se entera de que la alquimia se cerró")
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames(2)
	if not botica_cerrada[0] or is_instance_valid(botica):
		_fallo("2: Atrás no cierra la botica")
