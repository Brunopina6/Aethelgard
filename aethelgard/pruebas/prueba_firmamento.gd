extends SceneTree
# V12 (12/11): Firmamento de los Ecos y Orbes Cristalinos (firmamento/orbes.gd, firmamento_datos.gd, firmamento.gd;
# interruptor «orbes_v12» APAGADO, encendido solo dentro de la prueba).
#   1. Apagado: nada cambia (estadísticas, efectos, partida guardada, ficha del Grupo sin botón) y ganar() no hace nada.
#   2. Datos: ids únicos, requisitos que existen, todos los nodos alcanzables desde el centro, precios de la tabla,
#      un nodo no vale más de ~3 niveles, los dormidos no bloquean a nadie y cada tablero tiene ≥ 2 caminos.
#   3. Compra y requisitos: bloqueado (no gasta), compra (gasta su precio), «todos» (hace falta cada requisito),
#      saldo insuficiente (no gasta ni desbloquea), dormido (no se compra), dos veces no.
#   4. La bonificación llega a grupo.estadisticas() UNA vez: atributos guardados intactos, llamar dos veces da lo mismo,
#      efectos de equipo_extra con su tope, vista previa = lo que queda tras comprar.
#   5. Guardado y carga (archivo propio): saldo, nodos y estadísticas iguales tras cargar (no se duplican), y una partida
#      antigua sin la clave «firmamento» carga con todo a cero y las estadísticas de siempre.
#   6. Interfaz: se construye en los tres conceptos y con los tres héroes; tocar elige; pellizco y rueda acercan;
#      arrastre desplaza; flechas mueven la selección; comprar pide confirmar; animación que termina; error que tiembla;
#      herramienta de desarrollo solo en Auditoría/editor; la ficha del Grupo abre y cierra el tablero.
#   7. Combate: los héroes del combate de verdad salen con el ataque y el crítico del tablero.
# No toca la partida de verdad.

const ARCHIVO := "user://prueba_firmamento.save"

var P
var G
var X
var O
var D
var fallos: Array = []
var notas: Array = []


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)


func _limpiar() -> void:
	for k in P.CLAVES + ["orbes_v12", "partida_lista", "naira_v12"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	X = load("res://equipo_extra.gd")
	O = load("res://firmamento/orbes.gd")
	D = load("res://firmamento/firmamento_datos.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	_correr.call_deferred()


func _correr() -> void:
	_apagado()
	_datos()
	_compras()
	_una_vez()
	_guardado()
	await _interfaz()
	await _combate()
	_limpiar()
	_borrar()
	for n in notas:
		print("  ", n)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(0 if fallos.is_empty() else 1)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


# ---------------------------------------------------------------- 1
func _apagado() -> void:
	_limpiar()
	_ok(not O.ACTIVO_POR_DEFECTO and not O.activo(), "1: el interruptor orbes_v12 está encendido por defecto")
	var antes := {}
	var ef_antes := {}
	for n in ["Kael", "Lya", "Garon"]:
		antes[n] = G.estadisticas(n)
		ef_antes[n] = X.efectos_de(n)
	_ok(O.ganar(10, "prueba") == 0 and O.saldo() == 0, "1: apagado, ganar() da orbes")
	_ok(not Engine.has_meta("firmamento"), "1: apagado, ganar() crea la clave en la partida")
	_ok(O.bonos("Kael").is_empty(), "1: apagado, bonos() no está vacío")
	_ok(O.desbloquear("Kael", "k_inicio") != "", "1: apagado, se puede desbloquear")
	_ok(not P.volcar("res://mapa.tscn").has("firmamento"), "1: apagado, la partida guarda «firmamento»")
	# aunque la partida traiga nodos (de cuando estaba encendido), apagado no suman
	Engine.set_meta("firmamento", {"orbes": 3, "nodos": {"Kael": ["k_inicio", "k_filo1"]}, "gastados": {}, "historial": []})
	for n in ["Kael", "Lya", "Garon"]:
		_ok(G.estadisticas(n) == antes[n], "1: apagado, cambian las estadísticas de %s" % n)
		_ok(X.efectos_de(n) == ef_antes[n], "1: apagado, cambian los efectos de %s" % n)
	Engine.remove_meta("firmamento")
	var m = load("res://menus.gd").new()
	root.add_child(m)
	_ok(root.get_node("Entrada").buscar(m, "firmamento") == null, "1: apagado, la ficha del Grupo enseña el botón Firmamento")
	m.free()


# ---------------------------------------------------------------- 2
func _alcanzables(tab: Array) -> Array:
	var hechos: Array = []
	var cambio := true
	while cambio:
		cambio = false
		for n in tab:
			if n["id"] in hechos or not O.despierto(n):
				continue
			var req: Array = n.get("req", [])
			var hay := req.filter(func(r): return r in hechos).size()
			var vale: bool = req.is_empty() or (hay == req.size() if n.get("todos", false) else hay > 0)
			if vale:
				hechos.append(n["id"])
				cambio = true
	return hechos


func _datos() -> void:
	for h in D.TABLEROS:
		var tab: Array = D.TABLEROS[h]
		var ids := {}
		var iniciales := 0
		for n in tab:
			_ok(not ids.has(n["id"]), "2: id repetido %s/%s" % [h, n["id"]])
			ids[n["id"]] = n
			_ok(D.PRECIOS.has(n["rango"]), "2: rango sin precio %s" % n["id"])
			_ok(n["nombre"].length() <= 22, "2: nombre largo (%d) %s" % [n["nombre"].length(), n["id"]])
			if n["req"].is_empty():
				iniciales += 1
			var equivale := 0.0                      # puntos de atributo equivalentes (aprox.): 1 nivel = 3 puntos
			for k in n["bonos"]:
				var v = n["bonos"][k]
				if k in O.ATRIBUTOS or k in O.PLANOS:
					equivale += float(v)
				elif k in ["critico", "esquiva"]:
					equivale += float(v) * 100.0 / 1.5
				elif k == "atb_inicio":
					equivale += float(v) / 5.0
				else:
					equivale += 3.0
			_ok(equivale <= 9.5, "2: %s vale %.1f puntos (> 3 niveles)" % [n["id"], equivale])
		_ok(iniciales == 1, "2: %s tiene %d nodos iniciales" % [h, iniciales])
		for n in tab:
			for r in n["req"]:
				_ok(ids.has(r), "2: %s pide %s, que no existe" % [n["id"], r])
				_ok(O.despierto(ids[r]) if ids.has(r) else true, "2: %s depende del nodo dormido %s" % [n["id"], r])
		var alc := _alcanzables(tab)
		var despiertos := tab.filter(func(n): return O.despierto(n)).size()
		_ok(alc.size() == despiertos, "2: %s: alcanzables %d de %d" % [h, alc.size(), despiertos])
		var inicio: String = tab.filter(func(n): return n["req"].is_empty())[0]["id"]
		var hijos := tab.filter(func(n): return inicio in n["req"]).size()
		_ok(hijos >= 2, "2: el nodo inicial de %s abre %d caminos" % [h, hijos])
		var total := 0
		for n in tab:
			total += O.precio(n)
		notas.append("%s: %d nodos, %d orbes el tablero entero" % [h, tab.size(), total])


# ---------------------------------------------------------------- 3
func _compras() -> void:
	_limpiar()
	Engine.set_meta("orbes_v12", true)
	_ok(O.activo(), "3: no se enciende")
	_ok(O.ganar(4, "prueba") == 4 and O.saldo() == 4, "3: ganar 4 no da 4")
	_ok(O.ganar(-3, "prueba") == 4 and O.ganar(0, "x") == 4, "3: ganar negativo cambia el saldo")
	_ok(Engine.get_meta("firmamento")["historial"] == [["prueba", 4]], "3: historial %s" % [Engine.get_meta("firmamento")["historial"]])
	# bloqueado
	_ok(O.estado("Kael", "k_filo1") == "bloqueado", "3: k_filo1 no está bloqueado sin el inicial")
	_ok(O.desbloquear("Kael", "k_filo1").begins_with("Requiere") and O.saldo() == 4, "3: bloqueado gasta o no explica")
	# compra
	_ok(O.estado("Kael", "k_inicio") == "disponible", "3: el inicial no está disponible")
	_ok(O.desbloquear("Kael", "k_inicio") == "" and O.saldo() == 3, "3: la compra del inicial no gasta 1")
	_ok(O.desbloquear("Kael", "k_inicio") != "" and O.saldo() == 3, "3: se compra dos veces")
	_ok(O.estado("Kael", "k_filo1") == "disponible" and O.estado("Kael", "k_vie1") == "disponible", "3: el inicial no abre los dos caminos")
	_ok(O.desbloquear("Kael", "k_filo1") == "" and O.saldo() == 2, "3: k_filo1")
	# saldo insuficiente
	_ok(O.estado("Kael", "k_crit1") == "caro", "3: k_crit1 (3) con 2 orbes no sale «caro»: %s" % O.estado("Kael", "k_crit1"))
	_ok(O.desbloquear("Kael", "k_crit1") == "Falta 1 orbe" and O.saldo() == 2 and not O.desbloqueado("Kael", "k_crit1"),
		"3: sin saldo se desbloquea o gasta")
	# «todos»
	O.ganar(40, "prueba")
	for id in ["k_crit1", "k_crit2"]:
		_ok(O.desbloquear("Kael", id) == "", "3: %s" % id)
	_ok(O.estado("Kael", "k_exc_filo") == "bloqueado", "3: el excepcional se abre con uno solo de sus dos requisitos")
	_ok(O.desbloquear("Kael", "k_tec1") == "", "3: k_tec1 (tiene k_crit1)")
	_ok(O.estado("Kael", "k_exc_filo") == "disponible", "3: el excepcional no se abre con los dos")
	# dormido
	_ok(O.estado("Garon", "g_me4") == "dormido" and O.desbloquear("Garon", "g_me4").begins_with("Dormido"), "3: el dormido se compra")
	# l_me4 (res_magica) nació dormido; los accesorios V12 engancharon res_magica (gancho A1): ahora está despierto
	_ok(O.despierto(O.nodo("Lya", "l_me4")), "3: l_me4 no despertó con el gancho A1 de res_magica")
	_ok(O.gastados("Kael") == 1 + 1 + 3 + 6 + 6, "3: gastados %d" % O.gastados("Kael"))
	# conceder_prueba: solo Auditoría o editor (aquí, el editor)
	var dev: bool = O.herramienta_dev()
	notas.append("herramienta de desarrollo en esta prueba: %s (editor %s, auditoria %s)" % [dev, OS.has_feature("editor"), OS.has_feature("auditoria")])
	var s: int = O.saldo()
	_ok(O.conceder_prueba(5) == dev and O.saldo() == s + (5 if dev else 0), "3: conceder_prueba no respeta herramienta_dev")


# ---------------------------------------------------------------- 4
func _una_vez() -> void:
	_limpiar()
	var base: Dictionary = G.estadisticas("Kael").duplicate(true)
	var base_ef: Dictionary = X.efectos_de("Kael")
	var guardados: Dictionary = G.datos()["Kael"]["atributos"].duplicate()
	Engine.set_meta("orbes_v12", true)
	_ok(G.estadisticas("Kael") == base, "4: encendido y sin nodos ya cambian las estadísticas")
	O.ganar(30, "prueba")
	var previa: Dictionary = O.vista_previa("Kael", "k_inicio")
	_ok(previa["antes"]["ataque"] == base["ataque"] and previa["despues"]["ataque"] == base["ataque"] + 1,
		"4: vista previa del inicial: %d → %d" % [previa["antes"]["ataque"], previa["despues"]["ataque"]])
	_ok(G.estadisticas("Kael") == base, "4: la vista previa se queda puesta")
	O.desbloquear("Kael", "k_inicio")                # +1 fuerza, +1 velocidad
	O.desbloquear("Kael", "k_filo1")                 # +2 fuerza
	O.desbloquear("Kael", "k_crit1")                 # +4 % crítico
	O.desbloquear("Kael", "k_vie1")                  # +2 velocidad
	O.desbloquear("Kael", "k_vie2")                  # +2 vitalidad
	var e: Dictionary = G.estadisticas("Kael")
	_ok(e["ataque"] == base["ataque"] + 3, "4: ataque %d (esperado %d)" % [e["ataque"], base["ataque"] + 3])
	_ok(e["velocidad"] == base["velocidad"] + 3.0, "4: velocidad %s" % e["velocidad"])
	_ok(e["pv_max"] == base["pv_max"] + 16, "4: PV máx. %d (esperado %d)" % [e["pv_max"], base["pv_max"] + 16])
	_ok(e["atributos"]["fuerza"] == base["atributos"]["fuerza"] + 3, "4: fuerza final")
	_ok(G.estadisticas("Kael") == e and G.estadisticas("Kael") == e, "4: llamar otra vez cambia (se acumula)")
	_ok(G.datos()["Kael"]["atributos"] == guardados, "4: el tablero toca los atributos guardados")
	var ef: Dictionary = X.efectos_de("Kael")
	_ok(is_equal_approx(float(ef.get("critico", 0.0)), float(base_ef.get("critico", 0.0)) + 0.04), "4: crítico %s" % ef)
	# el tope de EFECTOS se respeta (crítico máx. 0,30 entre equipo y tablero)
	var d: Dictionary = Engine.get_meta("firmamento")
	d["nodos"]["Kael"] += ["k_crit2", "k_exc_filo", "k_crit2"]    # aun repetido a mano (partida tocada), con tope
	_ok(float(X.efectos_de("Kael")["critico"]) <= float(X.EFECTOS["critico"]["max"]) + 0.0001, "4: crítico sin tope")
	# los otros héroes no se enteran
	_ok(O.bonos("Lya").is_empty(), "4: Lya recibe los nodos de Kael")


# ---------------------------------------------------------------- 5
func _guardado() -> void:
	_limpiar()
	Engine.set_meta("orbes_v12", true)
	var base: Dictionary = G.estadisticas("Garon").duplicate(true)
	O.ganar(20, "prueba")
	for id in ["g_inicio", "g_mu1", "g_ra1", "g_ra3"]:
		_ok(O.desbloquear("Garon", id) == "", "5: %s" % id)
	var e: Dictionary = G.estadisticas("Garon").duplicate(true)
	var ef: Dictionary = X.efectos_de("Garon")
	var saldo: int = O.saldo()
	Engine.set_meta("partida_lista", true)
	_ok(P.guardar("res://mapa.tscn"), "5: no guarda")
	for k in P.CLAVES:                               # otra sesión
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	var d = P.leer(ARCHIVO)
	_ok(d is Dictionary and d.has("firmamento"), "5: la partida no lleva «firmamento»")
	P.restaurar(d)
	_ok(O.saldo() == saldo and O.nodos_de("Garon") == ["g_inicio", "g_mu1", "g_ra1", "g_ra3"], "5: saldo o nodos tras cargar")
	_ok(G.estadisticas("Garon") == e, "5: estadísticas tras cargar %s ≠ %s" % [G.estadisticas("Garon")["pv_max"], e["pv_max"]])
	_ok(X.efectos_de("Garon") == ef, "5: efectos tras cargar")
	P.restaurar(P.leer(ARCHIVO))                     # cargar dos veces seguidas: igual
	_ok(G.estadisticas("Garon") == e, "5: cargar dos veces duplica")
	_ok(e["pv_max"] == base["pv_max"] + 3 * 8 and e["defensa"] == base["defensa"] + 3, "5: Garon no suma lo esperado")
	# partida antigua: sin la clave
	var vieja: Dictionary = d.duplicate(true)
	vieja.erase("firmamento")
	vieja["formato"] = 2
	P.restaurar(vieja)
	_ok(not Engine.has_meta("firmamento") and O.saldo() == 0 and O.nodos_de("Garon").is_empty(), "5: la partida antigua trae orbes")
	_ok(G.estadisticas("Garon") == base, "5: la partida antigua no da las estadísticas de siempre")
	_ok(O.estado("Garon", "g_inicio") == "caro", "5: partida antigua: el inicial no espera orbes")


# ---------------------------------------------------------------- 6
func _interfaz() -> void:
	_limpiar()
	Engine.set_meta("orbes_v12", true)
	O.ganar(12, "prueba")
	var f = load("res://firmamento/firmamento.gd").new()
	f.heroe = "Kael"
	root.add_child(f)
	await _esperar(3)
	_ok(f.seleccion == "k_inicio", "6: no empieza en el nodo inicial (%s)" % f.seleccion)
	_ok(root.disable_3d, "6: con el tablero abierto se sigue dibujando el 3D de debajo")
	for e in f.ESTILOS:                               # los tres conceptos con los tres héroes
		f.poner_estilo(e)
		for h in ["Kael", "Lya", "Garon"]:
			f._poner_heroe(h)
			await _esperar(2)
			_ok(f._fondo.material is ShaderMaterial and f.nodos.size() == D.TABLEROS[h].size(), "6: %s/%s" % [e, h])
	# Naira (prototipo sin aprobar): sin su interruptor no tiene tablero; con él, el suyo provisional
	_ok(not "Naira" in O.heroes(), "6: Naira tiene tablero sin su interruptor")
	Engine.set_meta("naira_v12", true)
	G.unir("Naira")
	_ok("Naira" in O.heroes(), "6: con naira_v12, Naira no tiene tablero")
	f._poner_heroe("Naira")
	await _esperar(2)
	_ok(f.nodos.size() == D.TABLEROS["Naira"].size() and f._tabs.get_child_count() == 4, "6: tablero de Naira")
	Engine.remove_meta("naira_v12")
	f._poner_heroe("Kael")
	await _esperar(1)
	# tocar elige (por posición en pantalla)
	var p: Vector2 = f.en_pantalla("k_filo1")
	_toque(f, p)
	_ok(f.seleccion == "k_filo1", "6: tocar k_filo1 elige %s" % f.seleccion)
	# arrastre desplaza (y no elige)
	var c0: Vector2 = f.centro
	_arrastre(f, Vector2(300, 400), Vector2(360, 430))
	_ok(f.centro.distance_to(c0 + Vector2(60, 30)) < 1.0 and f.seleccion == "k_filo1", "6: arrastrar no desplaza %s → %s" % [c0, f.centro])
	# pellizco acerca
	var z0: float = f.zoom
	_pellizco(f, Vector2(300, 360), 100.0, 160.0)
	_ok(f.zoom > z0 * 1.3, "6: pellizcar no acerca (%.2f → %.2f)" % [z0, f.zoom])
	var rueda := InputEventMouseButton.new()
	rueda.button_index = MOUSE_BUTTON_WHEEL_DOWN
	rueda.pressed = true
	rueda.position = Vector2(400, 360)
	var z1: float = f.zoom
	f._entrada_tablero(rueda)
	_ok(f.zoom < z1, "6: la rueda no aleja")
	# un toque emulado desde la pantalla táctil (ratón con DEVICE_ID_EMULATION) no cuenta dos veces
	f._encuadrar()
	# teclado: flecha a la derecha desde el inicial elige un nodo del Filo
	f.elegir("k_inicio")
	f._mover_seleccion(Vector2.RIGHT)
	_ok(f.seleccion.begins_with("k_filo"), "6: → desde el inicial elige %s" % f.seleccion)
	# comprar pide confirmar
	f.elegir("k_inicio")
	var s: int = O.saldo()
	f._accion()
	_ok(f.confirmando and O.saldo() == s and not O.desbloqueado("Kael", "k_inicio"), "6: un toque gasta sin confirmar")
	f._cancelar()
	_ok(not f.confirmando and O.saldo() == s, "6: cancelar")
	_ok(f.despertar("k_inicio") == "" and O.desbloqueado("Kael", "k_inicio") and O.saldo() == s - 1, "6: despertar desde la interfaz")
	_ok(not f.anim.is_empty() and f.anim["desde"] == ["centro"], "6: sin animación de desbloqueo (%s)" % [f.anim])
	_ok(f.estado_visible("k_inicio") == "disponible", "6: el nodo se ve despierto antes de que llegue la energía")
	await _esperar(int(f.T_TOTAL * 30.0) + 30)
	_ok(f.anim.is_empty() and f.estado_visible("k_inicio") == "desbloqueado", "6: la animación no termina")
	# error: bloqueado tiembla y no gasta
	s = O.saldo()
	_ok(f.despertar("k_crit2") != "" and not f.error_anim.is_empty() and O.saldo() == s, "6: un bloqueado no tiembla o gasta")
	# la herramienta de desarrollo existe solo con herramienta_dev()
	_ok((f._b_dev != null) == O.herramienta_dev(), "6: botón de orbes de prueba fuera de Auditoría/editor")
	# Intro / Esc
	f.elegir("k_vie1")
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	f._unhandled_input(ev)
	_ok(f.confirmando, "6: Intro no pide confirmar")
	ev = InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	f._unhandled_input(ev)
	_ok(not f.confirmando and is_instance_valid(f) and not f.is_queued_for_deletion(), "6: Esc con confirmación cierra el tablero")
	f._cerrar()
	await _esperar(2)
	_ok(not root.disable_3d, "6: al cerrar el tablero no vuelve el 3D")
	# ficha del Grupo: el botón y el tablero encima
	var m = load("res://menus.gd").new()
	root.add_child(m)
	await _esperar(2)
	var b: Button = root.get_node("Entrada").buscar(m, "firmamento")
	_ok(b != null, "6: encendido, la ficha del Grupo no enseña Firmamento")
	if b != null:
		b.pressed.emit()
		await _esperar(2)
		var abierto = null
		for c in m.get_children():
			if c.get_script() == load("res://firmamento/firmamento.gd"):
				abierto = c
		_ok(abierto != null and abierto.heroe == m.heroe, "6: el botón no abre el tablero del héroe de la ficha")
		if abierto != null:
			abierto._cerrar()
			await _esperar(2)
			_ok(m.is_processing_unhandled_input(), "6: al cerrar, el menú no recupera el teclado")
	m.queue_free()
	await _esperar(2)


func _toque(f, p: Vector2) -> void:
	for pulsado in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = p
		e.pressed = pulsado
		f._entrada_tablero(e)


func _arrastre(f, a: Vector2, b: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = a
	e.pressed = true
	f._entrada_tablero(e)
	var paso := (b - a) / 4.0
	for i in 4:
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = a + paso * (i + 1)
		d.relative = paso
		f._entrada_tablero(d)
	e = InputEventScreenTouch.new()
	e.index = 0
	e.position = b
	e.pressed = false
	f._entrada_tablero(e)


func _pellizco(f, m: Vector2, d0: float, d1: float) -> void:
	for i in 2:
		var e := InputEventScreenTouch.new()
		e.index = i
		e.position = m + Vector2((i * 2 - 1) * d0 * 0.5, 0)
		e.pressed = true
		f._entrada_tablero(e)
	for k in 5:
		var d := lerpf(d0, d1, (k + 1) / 5.0)
		for i in 2:
			var ev := InputEventScreenDrag.new()
			ev.index = i
			ev.position = m + Vector2((i * 2 - 1) * d * 0.5, 0)
			f._entrada_tablero(ev)
	for i in 2:
		var e := InputEventScreenTouch.new()
		e.index = i
		e.position = m
		e.pressed = false
		f._entrada_tablero(e)


# ---------------------------------------------------------------- 7
func _combate() -> void:
	_limpiar()
	Engine.set_meta("orbes_v12", true)
	O.ganar(20, "prueba")
	for id in ["k_inicio", "k_filo1", "k_crit1"]:
		O.desbloquear("Kael", id)
	var e: Dictionary = G.estadisticas("Kael")
	var ef: Dictionary = X.efectos_de("Kael")
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	var limite := 900
	while limite > 0 and c.estado != "menu":
		await process_frame
		limite -= 1
	var kael = null
	for h in c.heroes:
		if h["nombre"] == "Kael":
			kael = h
	_ok(kael != null, "7: el combate no tiene a Kael")
	if kael != null:
		_ok(kael["atk"] == e["ataque"], "7: ataque en combate %s ≠ %s" % [kael["atk"], e["ataque"]])
		_ok(is_equal_approx(float(kael["efectos"].get("critico", 0.0)), float(ef.get("critico", 0.0))), "7: crítico en combate")
		_ok(is_equal_approx(float(kael["efectos"].get("critico", 0.0)), 0.04), "7: el crítico del tablero no llega (%s)" % kael["efectos"])
		_ok(kael["vel"] == e["velocidad"], "7: velocidad en combate")
	c.queue_free()
	await _esperar(3)
