extends SceneTree
# Prueba de la Garganta del Diablo: vista general, palanca (puerta, puente, ascensor), cofre raro y
# combates fijos. Uso: --script prueba_garganta.gd -- <carpeta de salida>

var g: Node
var frames := 0
var salida := ""
var P


func _initialize() -> void:
	salida = OS.get_cmdline_user_args()[0]
	P = load("res://progreso.gd")
	g = load("res://garganta.tscn").instantiate()
	root.add_child(g)


func _foto(nombre: String, centro: Vector2, zoom: float) -> void:
	g.camara.position_smoothing_enabled = false
	g.camara.limit_left = -100000
	g.camara.limit_top = -100000
	g.camara.limit_right = 100000
	g.camara.limit_bottom = 100000
	g.camara.zoom = Vector2.ONE * zoom
	g.camara.global_position = centro
	g.ui.visible = false


func _pasa(p: Vector2) -> bool:                      # ¿se puede estar en este punto (casillas)?
	var t := Vector2i(int(p.x), int(p.y))
	return g.muros[t.y * g.ANCHO + t.x] == 0 and not g._en_agua(p * g.T)


func _process(_d: float) -> bool:
	frames += 1
	if frames == 3:
		print("puentes: ", g.puentes.size(), "  piezas: ", g.piezas.size(), "  detalles: ", g.detalles.size(), "  cofres: ", g.cofres.size())
		print("se pasa por: P1 ", _pasa(Vector2(3, 10.8)), "  puente P2 ", _pasa(Vector2(25, 10.8)), "  hueco P2 fuera del puente ", _pasa(Vector2(25, 8.0)),
			"  escalera ", _pasa(Vector2(10.5, 22)), "  abismo ", _pasa(Vector2(40, 22)), "  nido ", _pasa(Vector2(31, 50)), "  grieta ", _pasa(Vector2(72, 35)))
		print("puente de la palanca antes: ", _pasa(Vector2(52, 22.5)), "  choque puerta: ", g.choque_puerta != null)
		print("ritmo P2 ", g._ritmo(Vector2(30, 10.8)), "  P6 ", g._ritmo(Vector2(30, 35)), "  P3 ", g._ritmo(Vector2(48, 10)))
		_foto("general", Vector2(40, 28) * g.T, 1280.0 / (80 * g.T))
	if frames == 8:
		root.get_viewport().get_texture().get_image().save_png(salida + "/general.png")
		g.ui.visible = true
		g.camara.zoom = Vector2.ONE
		g.jugador.position = Vector2(47, 34.2) * g.T
		g.camara.global_position = g.jugador.position
		g._comprobar_cerca()
		print("junto a la palanca: ", g.boton_examinar.text)
		g._accion()
		print("palanca: ", P.estado("garganta", "palanca"), "  puente después: ", _pasa(Vector2(52, 22.5)), "  choque puerta: ", g.choque_puerta != null)
	if frames == 60:
		root.get_viewport().get_texture().get_image().save_png(salida + "/palanca.png")
		g.jugador.position = Vector2(19, 32.6) * g.T
		g._comprobar_cerca()
		print("junto al ascensor de abajo: ", g.boton_examinar.text)
		g._accion()
	if frames == 90:
		print("tras el ascensor, en casillas: ", g.jugador.position / g.T)
		g.jugador.position = Vector2(31, 49.4) * g.T
		g._comprobar_cerca()
		print("en el nido: ", g.boton_examinar.text)
		var oro: int = load("res://inventario.gd").oro()
		g._accion()
		print("cofre raro: oro ", oro, " -> ", load("res://inventario.gd").oro(), "  aviso: ", g.aviso.text)
	if frames == 95:
		g.camara.global_position = Vector2(60, 10) * g.T
		g.jugador.position = Vector2(58, 10.8) * g.T
	if frames == 110:
		root.get_viewport().get_texture().get_image().save_png(salida + "/puerta.png")
		print("combate fijo del nido: grupo ", Engine.get_meta("grupo_combate", -1), "  fijo ", Engine.get_meta("combate_fijo", "-"),
			"  vuelta ", Engine.get_meta("pos_zona", Vector2.ZERO) / g.T, "  retorno ", Engine.get_meta("escena_retorno", "-"))
		return true
	return false
