extends SceneTree
# PESTANAS_19_11: cambiar de pestaña y la ficha del Grupo en menus.gd, sin repintar de más. Sin ventana, con datos
# aislados (escribe user://ajustes.cfg).
#   godot --headless --path aethelgard --script res://pruebas/prueba_pestanas.gd --fixed-fps 30 -- 3d
#   1. Cambiar de pestaña: el cuerpo nuevo entra en la lista de una vez (con todo dentro: una sola inserción en lo que
#      ya estaba en el árbol, no una por fila) y se ve igual que con un repintado entero. Al volver a Ajustes, su
#      cuerpo de antes (oculto mientras tanto) se enseña puesto al día, también si algo cambió fuera (volumen, una
#      opción, la calidad): igual que un repintado entero. Lo oculto no se encuentra (Entrada.buscar) ni ocupa sitio.
#   2. Ficha del Grupo: cada «+», «Repartir» y ◀ ▶ de cada ranura (varias vueltas, con accesorios con icono y
#      resumen) deja la ficha igual que un repintado entero (nodos, textos, colores, tamaños, iconos, apagados), sin
#      rehacer el botón y con el foco en él; con el último punto (los «+» se apagan) o «Repartir» (se va), el foco va
#      donde iba con el repintado (el primer botón de la ficha).
#   3. Con el teclado (Intro): «+» y ▶ (el foco sigue visible en el mismo botón); con el ratón: ▶ no se queda resaltado.
#   4. Lo que cuesta (sin el tope de fps): mediana del peor fotograma al volver a Ajustes ≤ 50 ms (antes ≈110-120 ms
#      en el PC, medido) y por pulsación en la ficha ≤ 15 ms (antes ≈25-35 ms). Sin el cambio, falla.

const ARCHIVO := "user://ajustes.cfg"
const AJUSTES_MAX := 50.0
const FICHA_MAX := 15.0

var fallos: Array = []
var Ent
var Son
var G
var I
var m
var _antes := {}                                 # ids de los nodos del menú antes de una acción
var _inserciones := 0                            # nodos metidos en algo que ya estaba en el árbol


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
		if n.has_theme_font_override("font"):
			t += " fuente=%s" % n.get_theme_font("font")
	if n is Label:
		t += " «%s»" % n.text
	if n is Button:
		t += " «%s» apagado=%s clave=%s" % [n.text, n.disabled, n.get_meta("clave", "")]
	if n is Panel:
		t += " pos=%s tam=%s" % [n.position, n.size]
	if n is ProgressBar:
		t += " valor=%s/%s" % [n.value, n.max_value]
	if n is TextureRect:
		t += " textura=%s mod=%s" % [n.texture.resource_path if n.texture != null else "", n.modulate]
	if n.get_script() == load("res://icono_equipo.gd"):
		t += " icono=%s %s" % [n.categoria, n.color]
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


# ¿Se ve igual que con un repintado entero? (lo repinta: los botones de antes dejan de valer)
func _como_repintado(que: String) -> void:
	var parcial := _foto()
	var clave: String = Ent.clave(_foco()) if _foco() != null else ""
	m._pintar_de_nuevo()
	await _esperar(2)
	var entero := _foto()
	if parcial != entero:
		_fallo("%s: no se ve como un repintado entero: %s" % [que, _primera_diferencia(parcial, entero)])
	if clave != "" and Ent.clave(_foco()) != clave:
		_fallo("%s: tras repintar, el foco va a «%s» y no a «%s»" % [que, Ent.clave(_foco()), clave])


func _marcar(n: Node) -> void:
	_antes[n.get_instance_id()] = true
	for c in n.get_children():
		_marcar(c)


func _al_entrar(n: Node) -> void:
	var p := n.get_parent()
	if p != null and _antes.has(p.get_instance_id()):
		_inserciones += 1


func _ir_a(p: String) -> float:
	var b: Button = m.botones_pestana[m.pestanas.find(p)]
	b.grab_focus()
	await _esperar(2)
	_antes = {}
	_marcar(m)
	_inserciones = 0
	var ant := Time.get_ticks_usec()
	b.pressed.emit()
	var peor := 0.0
	for i in 4:
		await process_frame
		var ahora := Time.get_ticks_usec()
		peor = maxf(peor, (ahora - ant) / 1000.0)
		ant = ahora
	_antes = {}
	return peor


func _probar() -> void:
	Ent = root.get_node("Entrada")
	Son = root.get_node("Sonido")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	var X = load("res://equipo_extra.gd")
	await _esperar(3)
	if FileAccess.file_exists(ARCHIVO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO))
	Son.cargar()
	Engine.set_meta(X.INTERRUPTOR_V12, true)      # accesorios con icono, color de rareza y resumen
	G.datos()
	I.datos()
	for id in ["anillo_alba", "anillo_cuarzo", "colgante_eco", "talisman_ceniza", "farol_peregrino", "diente_grimfang",
			"escudo_madera", "escudo_hierro", "hoja_sin_nombre", "brazalete_centinela"]:
		I.agregar(id)
	G.datos()["Kael"]["puntos"] = 30
	G.guardar_vida("Kael", 20, 3)
	node_added.connect(_al_entrar)
	await _pulsar(KEY_SHIFT)                       # modo teclado
	m = load("res://menus.gd").new()
	root.add_child(m)
	await _esperar(6)
	var fps_antes := Engine.max_fps
	Engine.max_fps = 0
	await _esperar(2)

	# 1. Cambiar de pestaña.
	var vueltas_ajustes: Array = []
	for vuelta in 4:
		for p in ["Objetos", "Habilidades", "Ajustes", "Grupo"]:
			var guardado = m.get("_ajustes_guardado")   # (sin PESTANAS_19_11 no existe: null)
			var peor: float = await _ir_a(p)
			if m.pestana != p or Ent.clave(_foco()) != "pestana:" + p:
				_fallo("1: %s no se abre con el foco en su pestaña (%s, «%s»)" % [p, m.pestana, Ent.clave(_foco())])
			if p == "Ajustes" and vuelta > 0:
				vueltas_ajustes.append(peor)
				if m.cuerpo != guardado:
					_fallo("1: al volver a Ajustes se rehace su cuerpo en vez de enseñar el de antes")
				var esperadas := 2 if vuelta == 2 else 0     # (vuelta 2: las barras de Música y Efectos, cambiadas fuera)
				if _inserciones != esperadas:
					_fallo("1: al volver a Ajustes se meten %d nodos (%d)" % [_inserciones, esperadas])
			elif _inserciones != 1:
				_fallo("1: al pasar a %s, el cuerpo entra en %d inserciones (una sola, con todo dentro)" % [p, _inserciones])
			if p != "Ajustes" and Ent.buscar(m, "volumen:Musica:-1") != null:
				_fallo("1: en %s se encuentra un botón de Ajustes (oculto)" % p)
			if p != "Ajustes" and m.get("caja") != null and m.caja.get_combined_minimum_size().y != m.cuerpo.get_combined_minimum_size().y:
				_fallo("1: en %s, lo oculto de Ajustes ocupa sitio en la lista" % p)
			await _como_repintado("1: %s (vuelta %d)" % [p, vuelta])
		if vuelta == 1:                            # algo cambia fuera mientras Ajustes está oculto
			Son.fijar("Musica", 30)
			Son.fijar("Efectos", 0)
			load("res://portada/eleccion.gd").elegir(false)
			load("res://prototipos/calidad_auto.gd").guardar({"auto": false, "perfil": "bajo", "fps": 60})
	# lo cambiado fuera ya se ve al volver (y es lo de un repintado: _como_repintado arriba)
	await _ir_a("Ajustes")
	var textos: Array = m.cuerpo.find_children("*", "Label", true, false).map(func(l): return l.text)
	if not "30 %" in textos or not "Sin sonido" in textos:
		_fallo("1: al volver a Ajustes no se ve el volumen cambiado fuera")
	var b_orig = Ent.buscar(m, "portada:original")
	if b_orig == null or not b_orig.text.begins_with("●"):
		_fallo("1: al volver a Ajustes no se ve la portada elegida fuera")
	await _ir_a("Grupo")
	vueltas_ajustes.sort()
	var mediana_aj: float = vueltas_ajustes[vueltas_ajustes.size() / 2]
	print("  volver a Ajustes (%d veces): peor fotograma, mediana %.1f ms, el peor %.1f ms" % [vueltas_ajustes.size(), mediana_aj,
		vueltas_ajustes.back()])

	# 2. Ficha del Grupo.
	var claves: Array = []
	for k in G.ATRIBUTOS:
		claves.append("mas:" + k)
	for r in I.RANURAS:
		claves.append("ranura:%s:1" % r)
		claves.append("ranura:%s:-1" % r)
	var tiempos: Array = []
	for vuelta in 3:
		for k in claves:
			var b = Ent.buscar(m, k)
			if b == null:
				_fallo("2: no está el botón «%s»" % k)
				continue
			b.grab_focus()
			await _esperar(3)
			var desplazado: int = m.marco.scroll_vertical
			var ant := Time.get_ticks_usec()
			b.pressed.emit()
			var peor := 0.0
			for i in 4:
				await process_frame
				var ahora := Time.get_ticks_usec()
				peor = maxf(peor, (ahora - ant) / 1000.0)
				ant = ahora
			tiempos.append(peor)
			if not is_instance_valid(b) or not b.is_inside_tree() or b.is_queued_for_deletion():
				_fallo("2: al pulsar «%s» se rehace el botón (repintado entero)" % k)
				continue
			if _foco() != b:
				_fallo("2: al pulsar «%s» el foco se va a «%s»" % [k, Ent.clave(_foco())])
			if m.marco.scroll_vertical < desplazado:
				_fallo("2: al pulsar «%s» la lista salta arriba (%d → %d)" % [k, desplazado, m.marco.scroll_vertical])
			await _como_repintado("2: «%s» (vuelta %d)" % [k, vuelta])
	# el último punto: los «+» se apagan y el foco va al primer botón de la ficha, como al repintar
	G.datos()["Kael"]["puntos"] = 1
	m._pintar_de_nuevo()
	await _esperar(2)
	var mas = Ent.buscar(m, "mas:magia")
	mas.grab_focus()
	await _esperar(2)
	mas.pressed.emit()
	await _esperar(2)
	if not is_instance_valid(mas) or not mas.disabled or Ent.clave(_foco()) != "heroe:Kael":
		_fallo("2: con el último punto, «+» sigue encendido o el foco va a «%s» (heroe:Kael)" % Ent.clave(_foco()))
	await _como_repintado("2: el último punto")
	# Naira (reserva): «Repartir» se va y el foco, al primer botón
	Engine.set_meta("naira_v12", true)
	G.unir("Naira")
	G.datos()["Naira"]["puntos"] = 6
	m.heroe = "Naira"
	m._pintar_de_nuevo()
	await _esperar(2)
	var mas_n = Ent.buscar(m, "mas:espiritu")
	mas_n.grab_focus()
	await _esperar(2)
	mas_n.pressed.emit()
	await _esperar(2)
	if _foco() != mas_n:
		_fallo("2: Naira, «+»: el foco se va a «%s»" % Ent.clave(_foco()))
	await _como_repintado("2: Naira, «+»")
	var rep = Ent.buscar(m, "repartir:Naira")
	if rep == null:
		_fallo("2: Naira no tiene «Repartir»")
	else:
		rep.grab_focus()
		await _esperar(2)
		rep.pressed.emit()
		await _esperar(2)
		if Ent.buscar(m, "repartir:Naira") != null or int(G.datos()["Naira"]["puntos"]) != 0:
			_fallo("2: «Repartir» no gasta los puntos o sigue ahí")
		if Ent.clave(_foco()) != "heroe:Kael":
			_fallo("2: tras «Repartir», el foco va a «%s» (heroe:Kael)" % Ent.clave(_foco()))
		await _como_repintado("2: Naira, «Repartir»")
	Engine.remove_meta("naira_v12")
	m.heroe = "Kael"
	m._pintar_de_nuevo()
	await _esperar(2)

	# 3. Teclado y ratón.
	G.datos()["Kael"]["puntos"] = 3
	m._pintar_de_nuevo()
	await _esperar(2)
	var fuerza: int = G.datos()["Kael"]["atributos"]["fuerza"]
	var mf = Ent.buscar(m, "mas:fuerza")
	mf.grab_focus()
	await _esperar(2)
	await _pulsar(KEY_ENTER)
	if G.datos()["Kael"]["atributos"]["fuerza"] != fuerza + 1 or _foco() != mf or not is_instance_valid(mf) or not mf.has_focus(true):
		_fallo("3: Intro en «+» de Fuerza no sube uno o el foco no sigue (visible) en él")
	var antes_anillo: String = I.equipo_de("Kael").get("anillo", "")
	var ma = Ent.buscar(m, "ranura:anillo:1")
	ma.grab_focus()
	await _esperar(2)
	await _pulsar(KEY_ENTER)
	if I.equipo_de("Kael").get("anillo", "") == antes_anillo or _foco() != ma or not is_instance_valid(ma) or not ma.has_focus(true):
		_fallo("3: Intro en ▶ de Anillo no lo cambia o el foco no sigue (visible) en él")
	await _como_repintado("3: teclado")
	var mp = Ent.buscar(m, "ranura:pies:1")
	var p: Vector2 = root.get_final_transform() * mp.get_global_rect().get_center()   # (sin ventana, otra escala)
	var mov := InputEventMouseMotion.new()
	mov.position = p
	Input.parse_input_event(mov)
	await _esperar(2)
	var pies: String = I.equipo_de("Kael").get("pies", "")
	for pulsado in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = p
		e.pressed = pulsado
		Input.parse_input_event(e)
		await _esperar(3)
	if I.equipo_de("Kael").get("pies", "") == pies:
		_fallo("3: el clic en ▶ de Pies no lo cambia")
	if is_instance_valid(mp) and mp.is_hovered():
		_fallo("3: tras el clic, ▶ de Pies se queda resaltado")

	# 4. Lo que cuesta.
	tiempos.sort()
	var mediana: float = tiempos[tiempos.size() / 2]
	print("  ficha del Grupo (%d pulsaciones): peor fotograma, mediana %.1f ms, el peor %.1f ms" % [tiempos.size(), mediana, tiempos.back()])
	Engine.max_fps = fps_antes
	if mediana_aj > AJUSTES_MAX:
		_fallo("4: volver a Ajustes, mediana del peor fotograma %.1f ms (máximo %.0f)" % [mediana_aj, AJUSTES_MAX])
	if mediana > FICHA_MAX:
		_fallo("4: ficha del Grupo, mediana del peor fotograma por pulsación %.1f ms (máximo %.0f)" % [mediana, FICHA_MAX])
	m.queue_free()
	await _esperar(3)
	if FileAccess.file_exists(ARCHIVO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO))
	Son.cargar()
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
