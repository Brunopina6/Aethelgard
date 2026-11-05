extends SceneTree
# Prueba del menú de combate nuevo con toques simulados (como el dedo en el móvil):
# deslizar ATACAR -> DEFENDER, flecha, abrir MAGIA, volver con «‹», atacar tocando al enemigo,
# e invocación con la Armonía llena.

var c: Node
var frames := 0
var pasos := {}


func _initialize() -> void:
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	pasos = {
		100: func(): _info("inicio"),
		110: func(): _arrastre(Vector2(900, 197), Vector2(1010, 197)),
		125: func(): _info("tras deslizar (debe ser b = DEFENDER)"),
		130: func(): _toque(Vector2(1200, 197)),
		140: func(): _info("tras flecha (debe ser a = ATACAR)"),
		150: func(): _toque(Vector2(900, 268)),
		165: func(): _info("tras tocar MAGIA"),
		175: func(): _toque(Vector2(870, 90)),
		190: func(): _info("tras tocar ‹ (vuelve)"),
		200: func(): _toque(Vector2(900, 197)),
		215: func(): _info("tras tocar ATACAR (elige objetivo)"),
		225: func(): _toque_enemigo(),
		240: func(): _info("tras tocar enemigo"),
	}


func _info(t: String) -> void:
	var m = c.menu
	var lado := "-"
	for f in m.filas:
		if f.has("lado"):
			lado = f["lado"]
	var textos := []
	for f in m.filas:
		textos.append(f["lbl"].text)
	print("%s | estado=%s actor=%s carta=%s submenu=%s filas=%s objetivo=%s" % [t, c.estado,
		c.actor["nombre"] if c.actor != null else "-", lado, m.submenu_abierto, textos,
		c.objetivo_apuntado["nombre"] if c.objetivo_apuntado != null else "-"])


func _boton(p: Vector2, pulsado: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = p
	e.global_position = p
	e.pressed = pulsado
	Input.parse_input_event(e)


func _toque(p: Vector2) -> void:
	_boton(p, true)
	_boton(p, false)


func _arrastre(a: Vector2, b: Vector2) -> void:
	_boton(a, true)
	for i in 4:
		var m := InputEventMouseMotion.new()
		m.position = a.lerp(b, (i + 1) / 4.0)
		m.global_position = m.position
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(m)
	_boton(b, false)


func _toque_enemigo() -> void:
	var e = c.enemigos[0]
	var p: Vector2 = c._a_pantalla(c._centro(e))
	print("toco al enemigo en ", p)
	_toque(p)


func _process(_d: float) -> bool:
	frames += 1
	if pasos.has(frames - 40):
		pasos[frames - 40].call()
	if frames == 300:
		c.armonia = 1.0
		c.menu.poner_armonia(1.0)
	if frames > 300 and c.estado == "menu" and not get_meta("invocado", false):
		set_meta("invocado", true)
		_info("antes de invocar (f%d)" % frames)
		_toque(Vector2(900, 340))
		set_meta("f_inv", frames)
	if has_meta("f_inv") and frames == get_meta("f_inv") + 90:
		var hp := []
		for e in c.enemigos: hp.append(e["hp"])
		print("tras invocar: hp enemigos ", hp, " armonia ", c.armonia)
	return frames > 700
