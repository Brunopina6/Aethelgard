extends SceneTree
# V12 (14/11, fase 7): la cerradura rúnica del arcón del Concejo (cerradura_runica.gd; datos en ciudades/oakhaven.gd
# CERRADURA y la pieza oak_cerradura_runica), con datos aislados y su propia partida.
# Sin «3d» (lista: prueba_cerradura_runica):
#   1. El puzle: tres anillos con los seis símbolos (sin repetir), el objetivo en cada anillo, el inicio sin resolver;
#      engranaje (el de fuera arrastra al del medio y no al de dentro; el de dentro gira solo); desde CUALQUIER posición
#      (las 216) tiene solución corta; la inscripción del Diario es la de la cerradura.
#   2. Los controles: los botones ◀ ▶ (dedo y ratón) giran su anillo; tocar la rueda (ratón y pantalla táctil) gira el
#      anillo tocado hacia ese lado; teclado o mando (↑ ↓ eligen, ← → giran, Intro gira).
#   3. Abandonar nunca bloquea: Esc, Atrás de Android y «Salir» cierran sin premio y sin cambiar nada; al volver empieza
#      igual; no hay intentos ni tiempo (cientos de giros sin resolver no cierran nada).
#   4. Resolverla da el premio UNA vez (60 monedas, 1 Éter y 1 Mineral rúnico), se queda abierta y ya no gira; el Diario:
#      «El arcón del Concejo» oculto hasta mirar la cerradura, con la inscripción como pista y hecho al abrirla.
#   5. Guardar y cargar (disco aislado) conserva el arcón abierto y no repite el premio; una partida antigua sin
#      «mazmorras» la trae cerrada y con el premio por ganar.
#   6. En la ciudad 2D: junto al arcón, «Girar los anillos» abre la cerradura (Kael no anda); salir la cierra; resuelta,
#      el arcón se pinta abierto y el botón pasa a «Examinar» con su texto.
# Con «3d» (lista: prueba_cerradura_runica_3d):
#   7. En Oakhaven 3D: el arcón está (con su aro de runas), se alcanza, el botón dice «Girar los anillos» y abre la
#      cerradura (ocupado); salir la cierra; resuelta, la tapa se abre, se guarda y el botón pasa a «Examinar».
# Imprime «FALLOS: n».

const ARCHIVO := "user://prueba_cerradura_runica.save"
const T := 64.0
var Oak
var P
var Inv
var E
var C
var fallos := 0


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	Oak = load("res://ciudades/oakhaven.gd")
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	E = load("res://encargos.gd")
	C = load("res://cerradura_runica.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa",
			"oak_franja", "oak_franja_t", "pos_3d", "pos_zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("pos_zona_ok", false)


func _probar() -> void:
	await _esperar(3)
	_limpiar()
	if "3d" in OS.get_cmdline_user_args():
		await _en_3d()
	else:
		_puzle()
		await _controles()
		await _abandonar()
		await _resolver()
		_guardar()
		await _ciudad()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _abrir_ventana(al_resolver := Callable()) -> Node:
	var m = C.new()
	m.config = Oak.CERRADURA
	m.al_resolver = al_resolver if al_resolver.is_valid() else Oak.abrir_cerradura
	root.add_child(m)
	await _esperar(2)
	return m


func _accion(nombre: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = nombre
	ev.pressed = true
	return ev


# 1. El puzle.
func _puzle() -> void:
	var cfg: Dictionary = Oak.CERRADURA
	var simbolos: Array = load("res://taberna_parejas.gd").SIMBOLOS
	var n: int = cfg["anillos"].size()
	_ok(n == 3 and cfg["objetivo"].size() == n and cfg["inicio"].size() == n and cfg["nombres"].size() == n,
		"1: la cerradura no tiene tres anillos completos")
	for i in n:
		var a: Array = cfg["anillos"][i]
		var orden := a.duplicate()
		orden.sort()
		var esperado := simbolos.duplicate()
		esperado.sort()
		_ok(orden == esperado, "1: el anillo %d no tiene los seis símbolos una vez (%s)" % [i, a])
		_ok(cfg["objetivo"][i] in a, "1: el objetivo del anillo %d no está en él" % i)
	_ok(not C.resuelta_en(cfg, cfg["inicio"]), "1: empieza resuelta")
	for i in n:
		_ok(C.simbolo_arriba(cfg, cfg["inicio"], i) != cfg["objetivo"][i], "1: al empezar, el anillo %d ya está bien" % i)
	# engranaje
	var g: Array = C.girar_en(cfg, [0, 0, 0], 0, 1)
	_ok(g == [1, 1, 0], "1: el de fuera no arrastra solo al del medio (%s)" % [g])
	g = C.girar_en(cfg, [0, 0, 0], 1, -1)
	_ok(g == [0, -1, -1], "1: el del medio no arrastra al de dentro (%s)" % [g])
	g = C.girar_en(cfg, [0, 0, 0], 2, 1)
	_ok(g == [0, 0, 1], "1: el de dentro no gira solo (%s)" % [g])
	# solución desde cualquier posición
	var peor := 0
	for a in 6:
		for b in 6:
			for c in 6:
				var ini := [a, b, c]
				var pasos: Array = C.solucion(cfg, ini)
				var x: Array = ini.duplicate()
				for p in pasos:
					x = C.girar_en(cfg, x, p[0], p[1])
				_ok(C.resuelta_en(cfg, x), "1: sin solución desde %s" % [ini])
				peor = maxi(peor, pasos.size())
	_ok(peor <= 9, "1: alguna posición necesita %d giros (máximo 9)" % peor)
	print("Cerradura: desde el inicio, %d giros; el peor caso, %d" % [C.solucion(cfg, cfg["inicio"]).size(), peor])
	# la inscripción del Diario es la de la tapa
	var arcon: Dictionary = E.de("enc_arcon")
	_ok(not arcon.is_empty() and str(arcon["m"]["pistas"][0]["texto"]).contains(cfg["inscripcion"].trim_suffix(".")),
		"1: la pista del Diario no es la inscripción de la cerradura")
	var p: Dictionary = Oak.pieza(cfg["id"])
	_ok(not p.is_empty() and Oak.error_condicion(p["si"]) == "", "1: la pieza del arcón no existe o su condición está mal")


# 2. Los controles.
func _controles() -> void:
	var m = await _abrir_ventana(func(): return "")
	_ok(m.botones.size() == 3 and m.botones[0].size() == 2, "2: no hay ◀ ▶ por anillo")
	m.botones[1][1].pressed.emit()                       # ▶ del medio
	_ok(m.giros == [0, 1, 1], "2: ▶ del medio no gira el medio con el de dentro (%s)" % [m.giros])
	m.botones[1][0].pressed.emit()                       # ◀ del medio
	_ok(m.giros == [0, 0, 0], "2: ◀ no deshace (%s)" % [m.giros])
	# tocar la rueda: a la derecha del anillo de fuera (ratón) y a la izquierda del de dentro (pantalla táctil)
	var clic := InputEventMouseButton.new()
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.pressed = true
	clic.position = C.CENTRO + Vector2(216, 0)
	m._tocar_rueda(clic)
	_ok(m.giros == [1, 1, 0], "2: tocar con el ratón a la derecha del de fuera no lo gira (%s)" % [m.giros])
	var toque := InputEventScreenTouch.new()
	toque.pressed = true
	toque.position = C.CENTRO + Vector2(-74, 0)
	m._tocar_rueda(toque)
	_ok(m.giros == [1, 1, -1], "2: tocar a la izquierda del de dentro no lo gira al revés (%s)" % [m.giros])
	# teclado o mando
	m.sel = 0
	m._unhandled_input(_accion("ui_down"))
	_ok(m.sel == 1, "2: ↓ no elige el anillo del medio")
	m._unhandled_input(_accion("ui_right"))
	_ok(m.giros == [1, 2, 0], "2: → no gira el anillo elegido (%s)" % [m.giros])
	m._unhandled_input(_accion("ui_left"))
	m._unhandled_input(_accion("ui_accept"))
	_ok(m.giros == [1, 2, 0], "2: ← e Intro no giran en sentidos contrarios (%s)" % [m.giros])
	m._unhandled_input(_accion("ui_up"))
	m._unhandled_input(_accion("ui_up"))
	_ok(m.sel == 2, "2: ↑ no da la vuelta a los anillos (%d)" % m.sel)
	m.cerrar_menu()
	await _esperar(2)


# 3. Abandonar.
func _abandonar() -> void:
	var oro0: int = Inv.oro()
	for como in ["esc", "atras", "salir"]:
		var cerrado := [false]
		var m = await _abrir_ventana()
		m.cerrado.connect(func(): cerrado[0] = true)
		for k in 300:                                    # sin intentos ni tiempo: cientos de giros, nada se cierra
			m.girar(k % 2, 1)
			if m.terminado:
				break
		if not m.terminado:
			_ok(is_instance_valid(m) and not cerrado[0], "3: girar mucho cierra la cerradura")
		match como:
			"esc":
				m._unhandled_input(_accion("ui_cancel"))
			"atras":
				root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
			"salir":
				m.salir.pressed.emit()
		await _esperar(3)
		_ok(cerrado[0] and not is_instance_valid(m), "3: «%s» no cierra la cerradura" % como)
	_ok(not Oak.cerradura_abierta() and Inv.oro() == oro0, "3: abandonar abre el arcón o da algo")
	var m2 = await _abrir_ventana()
	_ok(m2.giros == Oak.CERRADURA["inicio"], "3: al volver no empieza como al principio (%s)" % [m2.giros])
	m2.cerrar_menu()
	await _esperar(2)


# 4. Resolverla: premio una vez y el Diario.
func _resolver() -> void:
	var arcon: Dictionary = E.de("enc_arcon")
	_ok(E.estado(arcon) == "oculto", "4: el arcón sale en el Diario sin haberlo mirado")
	Oak.ver_cerradura()                                  # (lo que hace la ciudad al abrir la ventana)
	_ok(E.estado(arcon) == "activo" and E.pistas_conocidas(arcon).size() == 1, "4: tras mirarlo, el Diario no lo apunta")
	var oro0: int = Inv.oro()
	var eter0: int = Inv.cantidad("Éter")
	var min0: int = Inv.cantidad("Mineral rúnico")
	var m = await _abrir_ventana()
	var resuelta := [0]
	m.resuelta.connect(func(): resuelta[0] += 1)
	for p in C.solucion(Oak.CERRADURA, m.giros):        # con los botones, como un dedo
		m.botones[p[0]][0 if p[1] < 0 else 1].pressed.emit()
	_ok(m.terminado and resuelta[0] == 1 and m.mensaje.text.contains("Dentro del arcón"),
		"4: resolverla no abre el arcón («%s»)" % m.mensaje.text)
	_ok(Inv.oro() == oro0 + 60 and Inv.cantidad("Éter") == eter0 + 1 and Inv.cantidad("Mineral rúnico") == min0 + 1,
		"4: el premio no es 60 monedas, 1 Éter y 1 Mineral rúnico")
	_ok(not m.girar(0, 1) and m.botones[0][0].disabled, "4: resuelta, sigue girando")
	m._unhandled_input(_accion("ui_accept"))             # Intro, resuelta, la cierra
	await _esperar(3)
	_ok(not is_instance_valid(m), "4: Intro no cierra la cerradura resuelta")
	_ok(Oak.cerradura_abierta() and Oak.abrir_cerradura() == "" and Inv.oro() == oro0 + 60, "4: el premio se da dos veces")
	_ok(E.estado(arcon) == "hecho", "4: el Diario no da el arcón por hecho")
	var p: Dictionary = Oak.pieza(Oak.CERRADURA["id"])
	_ok(not Oak.cumple(p["si"]), "4: abierto, la pieza sigue ofreciendo girar los anillos")


# 5. Guardar y cargar.
func _guardar() -> void:
	var oro: int = Inv.oro()
	var d: Dictionary = P.volcar("res://mapa.tscn")
	_ok(P.escribir(d, ARCHIVO), "5: no se pudo escribir la partida")
	_limpiar()
	_ok(not Oak.cerradura_abierta(), "5: sin partida, el arcón sigue abierto")
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary, "5: no se pudo leer la partida")
	if not leida is Dictionary:
		return
	P.restaurar(leida)
	_ok(Oak.cerradura_abierta() and Inv.oro() == oro and Oak.abrir_cerradura() == "", "5: tras cargar, el arcón no está abierto o repite premio")
	var vieja: Dictionary = (leida as Dictionary).duplicate(true)
	vieja.erase("mazmorras")
	P.restaurar(vieja)
	_ok(not Oak.cerradura_abierta() and E.estado(E.de("enc_arcon")) == "oculto",
		"5: una partida antigua sin «mazmorras» no trae el arcón cerrado")
	_limpiar()


# 6. En la ciudad 2D.
func _ciudad() -> void:
	_limpiar()
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad"})
	var cas: Vector2 = Oak.pieza(Oak.CERRADURA["id"])["casilla"]
	Engine.set_meta("pos_zona", (cas + Vector2(0, 0.7)) * T)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	change_scene_to_file("res://ciudad_oakhaven.tscn")
	await _esperar(40)
	var z = current_scene
	if z == null or not z.has_method("_abrir_cerradura"):
		_ok(false, "6: no se cargó la ciudad 2D")
		return
	_ok(z.boton_examinar.visible and z.boton_examinar.text == "Girar los anillos",
		"6: junto al arcón el botón no dice «Girar los anillos» («%s»)" % z.boton_examinar.text)
	z._accion()
	await _esperar(3)
	var m = z.cerradura_abierta
	_ok(m != null and is_instance_valid(m) and z.tienda_abierta, "6: el botón no abre la cerradura (o Kael puede andar)")
	if m == null:
		return
	m._unhandled_input(_accion("ui_cancel"))
	await _esperar(3)
	_ok(z.cerradura_abierta == null and not z.tienda_abierta and not Oak.cerradura_abierta(), "6: salir no deja la ciudad como estaba")
	_ok(P.estado(Oak.NOMBRE, "cerradura_vista"), "6: mirar la cerradura no se apunta (Diario)")
	z._accion()
	await _esperar(3)
	m = z.cerradura_abierta
	for p in C.solucion(Oak.CERRADURA, m.giros):
		m.girar(p[0], p[1])
	m.cerrar_menu()
	await _esperar(4)
	_ok(Oak.cerradura_abierta(), "6: resolverla en la ciudad no abre el arcón")
	var pieza: Array = z.piezas.filter(func(e): return e[1]["id"] == Oak.CERRADURA["id"])
	_ok(pieza.size() == 1 and is_instance_valid(pieza[0][0]) and (pieza[0][0] as Node).has_meta("abierto"),
		"6: el arcón no se pinta abierto")
	z._comprobar_cerca()
	_ok(z.boton_examinar.text == "Examinar", "6: abierto, el botón no dice «Examinar» («%s»)" % z.boton_examinar.text)
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary and bool(leida.get("mazmorras", {}).get("oakhaven", {}).get("cerradura_abierta", false)),
		"6: al cerrar la cerradura no se guarda el arcón abierto")


# 7. En Oakhaven 3D.
func _en_3d() -> void:
	Engine.set_meta("partida_lista", true)
	change_scene_to_file("res://zonas3d/oakhaven_3d.tscn")
	await _esperar(25)
	var v = current_scene
	if v == null or v.get("vida") == null:
		_ok(false, "7: no se cargó Oakhaven 3D")
		return
	var vida = v.vida
	_ok(not vida.arcon.is_empty() and (vida.arcon["nodo"] as Node).get_node_or_null("Aro_runas") != null,
		"7: no está el arcón con su aro de runas")
	var cas: Vector2 = Oak.pieza(Oak.CERRADURA["id"])["casilla"]
	var ofrece := ""
	for pz in vida.piezas():
		if pz[0] == "pieza:" + Oak.CERRADURA["id"]:
			ofrece = pz[3]
	_ok(ofrece == "Girar los anillos", "7: la pieza no ofrece «Girar los anillos» («%s»)" % ofrece)
	v.en_posada = false
	v._colocar_kael(vida.sitio(cas + Vector2(0, 0.9)))
	await _esperar(3)
	v._bloqueo = 0.0
	v._comprobar_cerca()
	_ok(v.cerca == "pieza:" + Oak.CERRADURA["id"], "7: junto al arcón no se ofrece la cerradura (cerca = «%s»)" % v.cerca)
	v._accion()
	await _esperar(3)
	var m = vida.abierto
	_ok(m != null and String(m.get_script().resource_path).ends_with("cerradura_runica.gd") and v.ocupado(),
		"7: el botón no abre la cerradura (u ocupado no lo sabe)")
	if m == null:
		return
	m.salir.pressed.emit()
	await _esperar(3)
	_ok(vida.abierto == null and not Oak.cerradura_abierta(), "7: salir no cierra la cerradura")
	vida.usar_pieza(Oak.CERRADURA["id"])
	await _esperar(3)
	m = vida.abierto
	for p in C.solucion(Oak.CERRADURA, m.giros):
		m.girar(p[0], p[1])
	await _esperar(30)
	_ok(Oak.cerradura_abierta() and absf((vida.arcon["tapa"] as Node3D).rotation.x + 1.9) < 0.2,
		"7: resuelta, la tapa del arcón no se abre (%.2f)" % (vida.arcon["tapa"] as Node3D).rotation.x)
	m.cerrar_menu()
	await _esperar(3)
	for pz in vida.piezas():
		if pz[0] == "pieza:" + Oak.CERRADURA["id"]:
			ofrece = pz[3]
	_ok(ofrece == "Examinar", "7: abierto, el botón no dice «Examinar» («%s»)" % ofrece)
	vida.usar_pieza(Oak.CERRADURA["id"])
	await _esperar(2)
	_ok(vida.abierto == null and vida.ultimo_aviso.contains("abierto y vacío"), "7: abierto, examinarlo no dice que está vacío")
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary and bool(leida.get("mazmorras", {}).get("oakhaven", {}).get("cerradura_abierta", false)),
		"7: al cerrar la cerradura no se guarda el arcón abierto")
