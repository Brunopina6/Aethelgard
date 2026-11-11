extends SceneTree
# «Las parejas del Cuervo» (V11, hito E; taberna_parejas.gd y ciudades/taberna_juegos.gd), con datos aislados:
#   1. Premio sin apuestas: la primera victoria da 15 monedas y una Poción; ganar peor, nada; batir el récord, 10.
#      Va en la partida; una partida antigua empieza sin récord.
#   2. Una partida perfecta (semilla fija): 6 parejas en 6 intentos, gana y lo dice.
#   3. Dos distintas: se ven un momento y se vuelven; mientras, no se levanta otra; cuenta un intento.
#   4. Perder: con 14 intentos fallados se acaba sin premio.
#   5. Teclado o mando: las flechas mueven y Aceptar levanta; Atrás de Android cierra.
#   6. En la ciudad 2D, junto a la mesa del Patio del Cuervo, «Jugar a las parejas» abre el juego.
# Imprime «FALLOS: n».

const ARCHIVO := "user://prueba_taberna.save"
const T := 64.0
var J
var P
var Inv
var fallos := 0


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	J = load("res://ciudades/taberna_juegos.gd")
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await _esperar(5)
	_limpiar()
	_premios()
	await _perfecta()
	await _distintas()
	await _perder()
	await _teclado()
	await _ciudad()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _premios() -> void:
	var premio := {"oro": 15, "objetos": {"Poción": 1}}
	var oro0: int = Inv.oro()
	var p0: int = Inv.cantidad("Poción")
	var t: String = J.ganar("parejas", 9, premio)
	_ok(Inv.oro() == oro0 + 15 and Inv.cantidad("Poción") == p0 + 1 and J.record("parejas") == 9, "1: la primera victoria no da su premio («%s»)" % t)
	t = J.ganar("parejas", 11, premio)
	_ok(Inv.oro() == oro0 + 15 and J.record("parejas") == 9 and t.contains("récord sigue"), "1: ganar peor da algo («%s»)" % t)
	t = J.ganar("parejas", 7, premio)
	_ok(Inv.oro() == oro0 + 25 and J.record("parejas") == 7 and J.ganadas("parejas") == 3, "1: batir el récord no da 10 («%s»)" % t)
	var d: Dictionary = P.volcar("res://mapa.tscn")
	_ok(d.has("taberna") and int(d["taberna"]["parejas"]["record"]) == 7, "1: el récord no va en la partida")
	_ok(P.escribir(d, ARCHIVO), "1: no se pudo escribir la partida de prueba")
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary and int(leida.get("taberna", {}).get("parejas", {}).get("record", -1)) == 7, "1: la partida leída del disco no trae el récord")
	var vieja: Dictionary = d.duplicate(true)
	vieja.erase("taberna")
	P.restaurar(vieja)
	_ok(J.record("parejas") == 0, "1: una partida antigua trae récord")
	_limpiar()


func _nuevo(semilla := 7):
	var m = load("res://taberna_parejas.gd").new()
	m.semilla = semilla
	root.add_child(m)
	await _esperar(3)
	return m


func _pareja_de(m, i: int) -> int:
	for k in m.cartas.size():
		if k != i and m.cartas[k]["simbolo"] == m.cartas[i]["simbolo"]:
			return k
	return -1


func _perfecta() -> void:
	var m = await _nuevo(7)
	_ok(m.cartas.size() == 12, "2: no hay 12 cartas")
	var oro0: int = Inv.oro()
	for i in m.cartas.size():
		if m.cartas[i]["hecha"]:
			continue
		m.levantar(i)
		m.levantar(_pareja_de(m, i))
	await _esperar(2)
	_ok(m.terminado and m.parejas == 6 and m.intentos == 6 and m.mensaje.text.contains("6 intentos"),
		"2: la partida perfecta no gana con 6 intentos (%d parejas, %d intentos, «%s»)" % [m.parejas, m.intentos, m.mensaje.text])
	_ok(Inv.oro() == oro0 + 15, "2: ganar no da el premio de la primera vez")
	m.cerrar_menu()
	await _esperar(2)


func _distintas() -> void:
	var m = await _nuevo(11)
	var a := 0
	var b := 1
	while m.cartas[b]["simbolo"] == m.cartas[a]["simbolo"]:
		b += 1
	m.levantar(a)
	m.levantar(b)
	_ok(m.esperando and m.intentos == 1, "3: dos distintas no cuentan un intento")
	var otra := 0
	while otra == a or otra == b:
		otra += 1
	_ok(not m.levantar(otra), "3: se levanta una tercera mientras se ven las dos")
	await create_timer(1.2).timeout
	_ok(not m.esperando and not m.cartas[a]["boca_arriba"] and not m.cartas[b]["boca_arriba"], "3: las distintas no se vuelven")
	m.cerrar_menu()
	await _esperar(2)


func _perder() -> void:
	var m = await _nuevo(13)
	var oro0: int = Inv.oro()
	var a := 0
	var b := 1
	while m.cartas[b]["simbolo"] == m.cartas[a]["simbolo"]:
		b += 1
	for n in m.INTENTOS:
		m.levantar(a)
		m.levantar(b)
		if m.esperando:
			m._volver_cartas()
	_ok(m.terminado and m.parejas == 0 and Inv.oro() == oro0 and m.mensaje.text.contains("intentos"),
		"4: perder no acaba la partida o da algo («%s»)" % m.mensaje.text)
	m.cerrar_menu()
	await _esperar(2)


func _pulsar(accion: String) -> void:
	var ev := InputEventAction.new()
	ev.action = accion
	ev.pressed = true
	Input.parse_input_event(ev)
	await _esperar(2)
	var suelta := InputEventAction.new()
	suelta.action = accion
	suelta.pressed = false
	Input.parse_input_event(suelta)
	await _esperar(2)


func _teclado() -> void:
	var m = await _nuevo(5)
	var cerrado := [false]
	m.cerrado.connect(func(): cerrado[0] = true)
	await _pulsar("ui_right")
	await _pulsar("ui_down")
	_ok(m.sel == 1 + m.COLUMNAS, "5: las flechas no mueven la selección (%d)" % m.sel)
	await _pulsar("ui_accept")
	_ok(m.cartas[m.sel]["boca_arriba"], "5: Aceptar no levanta la carta")
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _esperar(3)
	_ok(cerrado[0], "5: Atrás no cierra el juego")


func _ciudad() -> void:
	_limpiar()
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad"})
	var mesa: Vector2 = load("res://ciudades/oakhaven.gd").PIEZAS.filter(func(p): return p["id"] == "oak_mesa_parejas")[0]["casilla"]
	Engine.set_meta("pos_zona", (mesa + Vector2(0, -0.7)) * T)   # por encima: debajo ya no es el patio
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	change_scene_to_file("res://ciudad_oakhaven.tscn")
	await _esperar(40)
	var z = current_scene
	_ok(z != null and z.boton_examinar.visible and z.boton_examinar.text == "Jugar a las parejas",
		"6: junto a la mesa el botón no dice «Jugar a las parejas» («%s»)" % (z.boton_examinar.text if z != null else "sin ciudad"))
	z._accion()
	await _esperar(3)
	_ok(z.juego_abierto != null and is_instance_valid(z.juego_abierto), "6: «Jugar a las parejas» no abre el juego")
	if z.juego_abierto != null:
		z.juego_abierto.cerrar_menu()
		await _esperar(3)
		_ok(z.juego_abierto == null and not z.tienda_abierta, "6: la ciudad no se entera de que se cerró el juego")
