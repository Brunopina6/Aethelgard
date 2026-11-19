extends SceneTree
# AJUSTES_19_11: en la pestaña Ajustes de menus.gd, una pulsación cambia solo lo suyo (la fila de volumen tocada o las
# marcas de su selector; en «Calidad gráfica», el bloque) en vez de repintar la pestaña entera (≈75-90 ms por
# pulsación en el PC, medido el 19/11). Sin ventana, con datos aislados (escribe user://ajustes.cfg).
#   godot --headless --path aethelgard --script res://pruebas/prueba_ajustes_parcial.gd --fixed-fps 30 -- 3d
# Con «3d» salen todas las filas (también las de las regiones y, en el editor, las de Auditoría).
#   1. Cada botón de Ajustes (todos, uno tras otro): tras pulsarlo, la pestaña se ve igual que con un repintado entero
#      (mismos nodos en el mismo orden, textos, colores, tamaños, botones apagados y barras de volumen): si un
#      selector dependiera de otro y no se pusiera al día, sale aquí. Los botones siguen siendo los mismos, el foco
#      sigue en el pulsado y la lista no se desplaza.
#   2. Con el teclado (Intro con el foco): ◀ de Música baja un 10 %, se guarda, el foco sigue (visible) en ◀ y la
#      fila dice lo mismo que un repintado; ▶ lo sube.
#   3. Lo que cuesta: peor fotograma de cada pulsación (sin el tope de fps). La mediana, por debajo de 30 ms (antes
#      ≈82 ms; ahora, unos pocos ms en el PC); el peor, solo se imprime (un tropiezo suelto del PC no es de Ajustes).

const ARCHIVO := "user://ajustes.cfg"
const MEDIANA_MAX := 30.0

var fallos: Array = []
var Ent
var Son
var m


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _tecla(codigo: Key, pulsada: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = pulsada
	Input.parse_input_event(e)


func _pulsar(codigo: Key) -> void:
	_tecla(codigo, true)
	await _esperar(2)
	_tecla(codigo, false)
	await _esperar(4)


func _foco() -> Control:
	return root.get_viewport().gui_get_focus_owner()


# Lo que se ve de la pestaña: cada nodo del cuerpo, en orden, con lo que cambia su aspecto.
func _foto() -> Array:
	var r: Array = []
	_foto_de(m.cuerpo, "", r)
	return r


func _foto_de(n: Node, ruta: String, r: Array) -> void:
	var t := "%s %s" % [ruta, n.get_class()]
	if n is Control:
		t += " min=%s vis=%s" % [n.custom_minimum_size, n.visible]
		for tipo in ["font_color", "font_focus_color"]:
			if n.has_theme_color_override(tipo):
				t += " %s=%s" % [tipo, n.get_theme_color(tipo)]
		if n.has_theme_font_size_override("font_size"):
			t += " tam=%d" % n.get_theme_font_size("font_size")
	if n is Label:
		t += " «%s»" % n.text
	if n is Button:
		t += " «%s» apagado=%s clave=%s" % [n.text, n.disabled, n.get_meta("clave", "")]
	if n is Panel:
		t += " pos=%s tam=%s" % [n.position, n.size]
	r.append(t)
	var i := 0
	for c in n.get_children():
		_foto_de(c, "%s/%d" % [ruta, i], r)
		i += 1


func _primera_diferencia(a: Array, b: Array) -> String:
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			return "«%s» / «%s»" % [a[i], b[i]]
	return "%d nodos / %d nodos" % [a.size(), b.size()]


func _probar() -> void:
	Ent = root.get_node("Entrada")
	Son = root.get_node("Sonido")
	await _esperar(3)
	if FileAccess.file_exists(ARCHIVO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO))
	await _pulsar(KEY_SHIFT)                       # modo teclado
	m = load("res://menus.gd").new()
	m.pestana = "Ajustes"
	root.add_child(m)
	await _esperar(6)
	var fps_antes := Engine.max_fps
	Engine.max_fps = 0
	await _esperar(2)

	# 1. Cada botón, contra un repintado entero.
	var claves: Array = []
	for b in m.cuerpo.find_children("*", "BaseButton", true, false):
		var k: String = Ent.clave(b)
		if k != "" and not k in claves and k != "volver_banco":   # (ese cierra el menú y cambia de escena)
			claves.append(k)
	if claves.size() < 40:
		_fallo("1: solo hay %d botones en Ajustes (¿falta el argumento 3d o ha cambiado la pestaña?)" % claves.size())
	var tiempos: Array = []
	var peor_clave := ""
	for k in claves:
		var b = Ent.buscar(m, k)
		if b == null:
			_fallo("1: no está el botón «%s»" % k)
			continue
		b.grab_focus()
		m.marco.ensure_control_visible(b)
		await _esperar(3)
		var desplazado: int = m.marco.scroll_vertical
		var antes_nodos: int = m.cuerpo.find_children("*", "", true, false).size()
		var ant := Time.get_ticks_usec()
		b.pressed.emit()
		var peor := 0.0
		for i in 4:
			await process_frame
			var ahora := Time.get_ticks_usec()
			peor = maxf(peor, (ahora - ant) / 1000.0)
			ant = ahora
		tiempos.append(peor)
		if tiempos.max() == peor:
			peor_clave = k
		if not is_instance_valid(b) or not b.is_inside_tree() or b.is_queued_for_deletion():
			_fallo("1: al pulsar «%s» se rehace el botón (repintado entero)" % k)
			continue
		if _foco() != b:
			_fallo("1: al pulsar «%s» el foco se va a «%s»" % [k, Ent.clave(_foco()) if _foco() != null else ""])
		if m.marco.scroll_vertical != desplazado:
			_fallo("1: al pulsar «%s» la lista se desplaza (%d → %d)" % [k, desplazado, m.marco.scroll_vertical])
		if m.cuerpo.find_children("*", "", true, false).size() != antes_nodos:
			_fallo("1: al pulsar «%s» cambia el número de nodos" % k)
		var parcial := _foto()
		m._pintar_de_nuevo()
		await _esperar(2)
		var entero := _foto()
		if parcial != entero:
			_fallo("1: tras pulsar «%s», la pestaña no es la de un repintado entero: %s" % [k, _primera_diferencia(parcial, entero)])
	var orden := tiempos.duplicate()
	orden.sort()
	var mediana: float = orden[orden.size() / 2] if not orden.is_empty() else 0.0
	print("  %d botones pulsados: peor fotograma por pulsación, mediana %.1f ms, el peor %.1f ms («%s»)"
		% [tiempos.size(), mediana, orden.back() if not orden.is_empty() else 0.0, peor_clave])

	# 2. Con el teclado: ◀ y ▶ de Música.
	Son.fijar("Musica", 100)
	m._pintar_de_nuevo()
	m.marco.scroll_vertical = 0
	await _esperar(3)
	var menos = Ent.buscar(m, "volumen:Musica:-1")
	menos.grab_focus()
	await _esperar(2)
	await _pulsar(KEY_ENTER)
	if Son.volumen("Musica") != 90:
		_fallo("2: Intro en ◀ deja Música en %d (esperaba 90)" % Son.volumen("Musica"))
	var c := ConfigFile.new()
	if c.load(ARCHIVO) != OK or int(c.get_value("volumen", "Musica", -1)) != 90:
		_fallo("2: el archivo de ajustes no guarda Música al 90")
	if _foco() != menos or not menos.has_focus(true):
		_fallo("2: tras bajar, el foco no sigue (visible) en el mismo ◀ de Música")
	var fila := _foto()
	m._pintar_de_nuevo()
	await _esperar(2)
	if fila != _foto():
		_fallo("2: la fila de Música al 90 %% no es la de un repintado: %s" % _primera_diferencia(fila, _foto()))
	if Ent.clave(_foco()) != "volumen:Musica:-1":
		_fallo("2: tras repintar, el foco no vuelve a ◀ de Música («%s»)" % Ent.clave(_foco()))
	await _pulsar(KEY_RIGHT)
	await _pulsar(KEY_ENTER)
	if Son.volumen("Musica") != 100 or Ent.clave(_foco()) != "volumen:Musica:1":
		_fallo("2: ▶ no sube Música a 100 con el foco en ▶ (%d, «%s»)" % [Son.volumen("Musica"), Ent.clave(_foco())])
	# con el dedo: el ◀ tocado no se queda resaltado (como cuando era un botón nuevo, tras repintar)
	menos = Ent.buscar(m, "volumen:Musica:-1")      # (el de antes se rehízo con el repintado de arriba)
	var p: Vector2 = root.get_final_transform() * menos.get_global_rect().get_center()   # (sin ventana, otra escala)
	for pulsado in [true, false]:
		var t := InputEventScreenTouch.new()
		t.position = p
		t.pressed = pulsado
		Input.parse_input_event(t)
		await _esperar(3)
	if Son.volumen("Musica") != 90:
		_fallo("2: tocar ◀ deja Música en %d (esperaba 90)" % Son.volumen("Musica"))
	if menos.is_hovered():
		_fallo("2: tras tocar ◀, se queda resaltado")

	# 3. Lo que cuesta.
	Engine.max_fps = fps_antes
	if mediana > MEDIANA_MAX:
		_fallo("3: la mediana del peor fotograma por pulsación es %.1f ms (máximo %.0f)" % [mediana, MEDIANA_MAX])
	m.queue_free()
	await _esperar(3)
	if FileAccess.file_exists(ARCHIVO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO))
	Son.cargar()
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
