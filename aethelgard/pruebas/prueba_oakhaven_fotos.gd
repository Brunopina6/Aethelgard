extends SceneTree
# Capturas de Oakhaven (T-089, fase 2) para revisarlas a ojo y comparar el antes y el después.
#   Godot --path aethelgard --script res://pruebas/prueba_oakhaven_fotos.gd --fixed-fps 30 -- <carpeta> [3d] sin_prologo [antes]
# Sin «antes»: entra desde el mapa, como un jugador (botón «Entrar» junto a Oakhaven), y fotografía lo que abra.
# Con «antes»: abre la zona generada de siempre (zona.tscn con el lugar 0), la Oakhaven que había antes de T-089.
# Escribe en <carpeta> (.png): 1_entrada, 2_plaza, 3_norte, 4_ciudad_entera y 5_dialogo; en la ciudad hecha a mano,
# también sus rincones (6_barrio_cuervo a 14_mercado: el Cuervo, el callejón y la grieta, el Patio de las Velas, la colina
# del crematorio, la ronda apagada y encendida, el Árbol y su copa translúcida, el mercado), el Diario con las notas
# (15_diario_notas), la posada con la noche gratis y su escena (16_ y 17_), un comentario de los héroes al explorar
# (19_comentario) y, con «3d», el ramito de lavanda en Pastos Verdes 3D (18_lavanda_pastos).
# Las de la ciudad hecha a mano usan partidas sintéticas (nada se guarda: las pruebas no escriben la partida).

const MAPA := "res://mapa.tscn"
const ZONA := "res://zona.tscn"
const CIUDAD := "res://ciudad_oakhaven.tscn"
const REGION := "res://zonas3d/pastos_verdes_3d.tscn"
const T := 64

var salida := ""
var antes := false
var R
var D


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	salida = args[0] if not args.is_empty() else "."
	antes = "antes" in args
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_capturar.call_deferred()


func _escena() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	await _esperar(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [salida, nombre])
	print("CAPTURA ", nombre)


# Pone a Kael en una casilla y espera a que la cámara llegue.
func _ir(z, casilla: Vector2, frames := 20) -> void:
	z.jugador.position = casilla * T
	z.camara.reset_smoothing()
	await _esperar(frames)


func _capturar() -> void:
	R = root.get_node("Recursos")
	D = root.get_node_or_null("Dialogic")
	await _esperar(3)
	if antes:
		var l: Dictionary = load("res://mapa.gd").LUGARES[0]
		Engine.set_meta("lugar", {"indice": 0, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "llanura", "texto": l["texto"]})
		Engine.set_meta("pos_zona_ok", false)
		change_scene_to_file(ZONA)
	else:
		change_scene_to_file(MAPA)
		await _hasta(func(): return _escena() == MAPA and current_scene.jugador != null, 60.0)
		await _esperar(10)
		var m = current_scene
		m.jugador.position = m.lugares[0]["pos"] + Vector2(20, 0)
		m._comprobar_cerca()
		m._entrar()
	await _hasta(func(): return _escena() in [ZONA, CIUDAD] and not R.cambiando and current_scene.jugador != null, 90.0)
	var z = current_scene
	print("ESCENA ", _escena())
	await _esperar(45)                                  # el fundido de entrada y el aviso de la ciudad
	await _foto("1_entrada")
	await _ir(z, z.plaza + Vector2(0, 2.5))
	await _foto("2_plaza")
	await _ir(z, z.meta + Vector2(0, 4))
	await _foto("3_norte")
	await _ir(z, Vector2(40, 30))
	z.camara.limit_left = -100000
	z.camara.limit_top = -100000
	z.camara.limit_right = 100000
	z.camara.limit_bottom = 100000
	z.camara.zoom = Vector2(0.2, 0.2)
	z.camara.position = Vector2(40, 28) * T - z.jugador.position
	z.camara.reset_smoothing()
	await _esperar(10)
	await _foto("4_ciudad_entera")
	z.camara.zoom = Vector2.ONE
	z.camara.position = Vector2.ZERO
	z.camara.limit_left = 0
	z.camara.limit_top = 0
	z.camara.limit_right = z.ANCHO * T
	z.camara.limit_bottom = z.ALTO * T
	var n = z.npcs[0] if _escena() == ZONA else _vecino(z, "posadera")
	if n != null and D != null:
		await _ir(z, n[0].position / T + Vector2(0.5, 0.6))
		z._comprobar_cerca()
		z._accion()
		await _esperar_texto()
		await _foto("5_dialogo")
		D.end_timeline(true)
		await _esperar(10)
	if _escena() == CIUDAD:
		await _rincones(z)
	print("FOTOS LISTAS en ", salida)
	quit(0)


func _vecino(z, id: String) -> Variant:
	for n in z.npcs:
		if n[1].get("id", "") == id:
			return n
	return null


# Espera a que una frase esté entera en pantalla (no basta con IDLE: entre eventos también lo está).
func _esperar_texto() -> void:
	await _hasta(func():
		if D.current_timeline == null or D.current_state != D.States.IDLE:
			return false
		var i: int = D.current_event_idx
		return i >= 0 and i < D.current_timeline_events.size() and D.current_timeline_events[i] is DialogicTextEvent, 10.0)
	await _esperar(10)


# Rincones de la ciudad hecha a mano (ciudades/oakhaven.gd), con partidas sintéticas que encienden lo que hay que ver.
func _rincones(z) -> void:
	var P = load("res://progreso.gd")
	await _ir(z, Vector2(15, 26.6))
	z._comprobar_cerca()
	await _foto("6_barrio_cuervo")
	await _ir(z, Vector2(23.5, 34.6))
	z._comprobar_cerca()
	await _foto("7_callejon_grieta")                     # el patio, a oscuras: solo se ve la luz de la grieta
	for e in z.piezas:
		if e[1]["id"] == "oak_grieta":
			z._usar_pieza(e)                           # «Pasar»
	await _esperar(60)
	await _foto("8_patio_velas")
	await _ir(z, Vector2(66.5, 17.4))
	await _foto("9_colina_crematorio")
	await _ir(z, Vector2(76.6, 35.5))
	await _foto("10_ronda_apagada")
	P.poner_estado("oakhaven", "faroles")
	for f in ["farol_1", "farol_2", "farol_3"]:
		P.poner_estado("oakhaven", f)
	z._actualizar_piezas()
	await _esperar(6)
	await _foto("11_ronda_encendida")
	await _ir(z, Vector2(36.6, 10.6))
	z._comprobar_cerca()
	await _foto("12_raices_arbol")
	await _ir(z, Vector2(41.0, 4.0), 40)                  # detrás de la copa: se vuelve translúcida
	await _foto("13_detras_del_arbol")
	await _ir(z, Vector2(55, 29.5))
	await _foto("14_mercado")
	for id in ["nota_oak_bando", "nota_oak_cuervo", "nota_oak_guardia"]:
		load("res://ciudades/oakhaven.gd").ver_nota(id)
	var d = load("res://diario.gd").new()
	z.ui.add_child(d)
	await _esperar(10)
	d.marco.scroll_vertical = 100000                      # abajo del todo: la sección «Notas»
	await _esperar(6)
	await _foto("15_diario_notas")
	d._cerrar()
	await _esperar(6)
	if D != null:
		P.poner_estado("oakhaven", "noche_gratis")
		z._actualizar_posada()
		await _ir(z, Vector2(16, 26.6))
		await _foto("16_posada_gratis")
		z._posada()
		await _hasta(func(): return D.current_timeline != null, 6.0)
		await _esperar_texto()
		await _foto("17_escena_posada")
		D.end_timeline(true)
		await _esperar(10)
	# un comentario de los héroes al explorar (dialogos/comentarios.gd), con su respuesta si está quien responde
	await _ir(z, Vector2(40, 30))
	for n in z.ui.get_children():
		if n.name.begins_with("comentario"):
			n.free()
	var Com = load("res://dialogos/comentarios.gd")
	var c: Dictionary = Com.MOMENTOS["cofre"]["frases"][0].duplicate(true)
	c["momento"] = "cofre"
	Com.mostrar(z.ui, c)
	await _esperar(20)
	await _foto("19_comentario")
	if load("res://modo3d.gd").activo():            # «Lavanda para el Árbol»: el ramito en Pastos Verdes 3D
		P.poner_hito("pv_02")                       # (sin PV-02 al entrar)
		P.poner_estado("oakhaven", "lavanda")
		Engine.set_meta("pos_3d_ok", false)
		change_scene_to_file(REGION)
		await _hasta(func(): return _escena() == REGION and current_scene.get("kael") != null and not R.cambiando, 120.0)
		await _esperar(30)
		var r = current_scene
		if r.get("lavanda") != null:
			r._colocar_kael(r.lavanda.global_position + Vector3(1.3, 0, 1.1))
			await _esperar(40)
			r._comprobar_cerca()
			await _foto("18_lavanda_pastos")
