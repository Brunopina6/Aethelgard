extends SceneTree
# Capturas de Oakhaven (T-089, gráficos) con ventana y con los MISMOS encuadres para la ciudad de hoy (zona.tscn, el
# lugar 0) y para la maqueta con el arte nuevo (ciudades/oakhaven_arte/maqueta_oakhaven.tscn), para compararlas.
# No cambia nada del juego: mueve a Kael y la cámara a mano y saca fotos. Siempre con datos aislados (zona.gd guarda
# al entrar): lánzalo con pruebas/ejecutar_pruebas.ps1 o con APPDATA redirigido.
#   Godot --path aethelgard --script res://pruebas/prueba_oakhaven_arte_fotos.gd --fixed-fps 30 -- <carpeta>
#         [antes] sin_prologo
#   Sin «antes», la maqueta (después); con «antes», la ciudad de hoy.
# Escribe en <carpeta> (.png, 1280×720 salvo lo dicho): los ENCUADRES (Kael en cada sitio, con la interfaz),
#   9_ciudad_entera (la ciudad entera reducida, sin interfaz ni Kael), 10_movil_20x9 (1600×720, con la cruceta y las
#   franjas negras del aspecto «keep») y, solo en la maqueta, 11_taberna_x2 (la fachada ampliada ×2) y
#   12_detras_concejo (Kael por detrás de la Casa del Concejo: el edificio se aclara a su alrededor).
#
# Modo comparación: ... -- <carpeta_salida> comparar=<carpeta_antes>,<carpeta_despues>
#   parejas <n>.jpg (ANTES a la izquierda, DESPUÉS a la derecha) y lamina_antes_despues.jpg.

const ENCUADRES := [["1_entrada", Vector2(40, 52.0)], ["2_plaza", Vector2(41.5, 28.5)], ["3_taberna", Vector2(15.5, 27.6)],
	["4_crematorio", Vector2(65.5, 18.3)], ["5_arbol", Vector2(38.0, 10.6)], ["6_mercado", Vector2(54, 30.5)],
	["7_torre_ronda", Vector2(71.0, 46.5)], ["8_callejon_velas", Vector2(23.5, 33.0)]]
const LAMINA := [["1_entrada", "Al entrar (Puerta del Sur)"], ["2_plaza", "Plaza del Tapiz"], ["3_taberna", "Taberna del Cuervo Oxidado"],
	["4_crematorio", "Crematorio"], ["5_arbol", "Árbol Milenario"], ["9_ciudad_entera", "La ciudad entera"],
	["10_movil_20x9", "Móvil 20:9 (1600 × 720)"]]
const BANDERAS := ["sin_prologo", "antes", "3d"]
const ESCENA_MAQUETA := "res://ciudades/oakhaven_arte/maqueta_oakhaven.tscn"

var salida := ""
var z                                    # la escena de la ciudad


func _initialize() -> void:
	var comparar := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("comparar="):
			comparar = a.substr(9)
		elif salida == "" and not "=" in a and not a in BANDERAS:
			salida = a
	if salida == "":
		print("FALLO: falta la carpeta de salida")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(salida)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	if comparar != "":
		_comparar.call_deferred(comparar.split(",")[0], comparar.split(",")[1])
	else:
		_capturar.call_deferred("antes" in OS.get_cmdline_user_args())


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 60.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _imagen() -> Image:
	await _esperar(3)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _foto(nombre: String) -> void:
	var img: Image = await _imagen()
	img.save_png("%s/%s.png" % [salida, nombre])
	print("CAPTURA %s %dx%d" % [nombre, img.get_width(), img.get_height()])


func _ir(casilla: Vector2, zoom := 1.0) -> void:
	z.jugador.position = casilla * z.T
	z.tiene_destino = false
	z.camara.zoom = Vector2(zoom, zoom)
	z.camara.reset_smoothing()
	RenderingServer.global_shader_parameter_set("jugador_pos", z.jugador.position)
	await _esperar(3)
	z.camara.reset_smoothing()
	z._comprobar_cerca()
	await _esperar(12)


func _interfaz(ver: bool) -> void:
	var fps = root.get_node("Recursos").get("lbl_fps")
	if fps != null:
		fps.visible = false
	z.ui.offset = Vector2.ZERO if ver else Vector2(100000, 0)    # zona.gd vuelve a encender ui.visible en cada fotograma


func _capturar(antes: bool) -> void:
	await _esperar(3)
	var Oak = load("res://ciudades/oakhaven.gd")
	var l: Dictionary = load("res://mapa.gd").LUGARES[0]
	Engine.set_meta("lugar", {"indice": 0, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "llanura", "texto": l["texto"]})
	Engine.set_meta("pos_zona_ok", false)
	var escena := "res://zona.tscn" if antes else ESCENA_MAQUETA
	change_scene_to_file(escena)
	if not await _hasta(func(): return current_scene != null and current_scene.get("jugador") != null, 60.0):
		print("FALLO: no se abrió ", escena)
		quit(1)
		return
	z = current_scene
	await _esperar(20)
	print("CIUDAD: %s · %s" % [escena, "antes (la de hoy)" if antes else "maqueta con el arte nuevo"])
	if not antes:
		var nodos := 0
		var texturas := {}                         # sin repetir: las casas iguales comparten imagen
		for p in z.piezas_puestas:
			nodos += int(p[1].coste["nodos"])
			for n in _todos(p[1]):
				if n is Sprite2D and n.texture != null and n.texture.resource_path != "":
					texturas[n.texture.resource_path] = n.texture.get_width() * n.texture.get_height()
		var px := 0
		for k in texturas:
			px += texturas[k]
		print("PIEZAS: %d · nodos %d · %d texturas distintas, %.2f Mpx (%.1f MB en RGBA8)" % [z.piezas_puestas.size(), nodos,
			texturas.size(), px / 1e6, px * 4.0 / 1048576.0])
	_interfaz(true)
	for e in ENCUADRES:
		await _ir(e[1])
		await _foto(e[0])
	# la ciudad entera, reducida a la pantalla
	_interfaz(false)
	z.jugador.visible = false
	var cam: Camera2D = z.camara
	var lim := [cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom]
	cam.limit_left = -100000
	cam.limit_top = -100000
	cam.limit_right = 100000
	cam.limit_bottom = 100000
	await _ir(Vector2(z.ANCHO, z.ALTO) * 0.5, 720.0 / (z.ALTO * z.T))
	await _foto("9_ciudad_entera")
	cam.limit_left = lim[0]
	cam.limit_top = lim[1]
	cam.limit_right = lim[2]
	cam.limit_bottom = lim[3]
	z.jugador.visible = true
	if not antes:
		_interfaz(false)
		await _ir(Vector2(16.0, 27.2), 2.0)
		await _foto("11_taberna_x2")
		await _ir(Vector2(47.0, 14.6), 1.0)             # detrás de la Casa del Concejo (hierba, fuera de la plaza)
		await _foto("12_detras_concejo")
	# móvil alargado 20:9 (1600×720): con el estirado «canvas_items» y el aspecto «keep», franjas a los lados
	_interfaz(true)
	var dpad = load("res://dpad.gd").new()
	dpad.position = Vector2(30, 440)
	z.ui.add_child(dpad)
	DisplayServer.window_set_size(Vector2i(1600, 720))
	await _esperar(10)
	await _ir(ENCUADRES[1][1])
	var img: Image = await _imagen()
	img.convert(Image.FORMAT_RGBA8)
	var movil := Image.create(1600, 720, false, Image.FORMAT_RGBA8)
	movil.fill(Color(0, 0, 0, 1))
	movil.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((1600 - img.get_width()) / 2, (720 - img.get_height()) / 2))
	movil.save_png(salida + "/10_movil_20x9.png")
	print("CAPTURA 10_movil_20x9 1600x720 (vista del juego %dx%d)" % [img.get_width(), img.get_height()])
	DisplayServer.window_set_size(Vector2i(1280, 720))
	print("CAPTURAS hechas en ", salida)
	quit(0)


func _todos(n: Node) -> Array:
	var r: Array = []
	for c in n.get_children():
		r.append(c)
		r += _todos(c)
	return r


func _comparar(antes: String, despues: String) -> void:
	await _esperar(3)
	var nombres: Array = []
	for e in ENCUADRES:
		nombres.append(e[0])
	nombres += ["9_ciudad_entera", "10_movil_20x9"]
	for n in nombres:
		var a := Image.load_from_file("%s/%s.png" % [antes, n])
		var b := Image.load_from_file("%s/%s.png" % [despues, n])
		if a == null or b == null:
			print("FALLO: falta ", n)
			continue
		var img: Image = await _pareja(a, b, 1.0, "ANTES · la Oakhaven de hoy (zona.gd)", "DESPUÉS · arte nuevo (maqueta)")
		img.save_jpg("%s/%s.jpg" % [salida, n], 0.9)
		print("CAPTURA comparación ", n, " ", img.get_size())
	await _lamina(antes, despues)
	quit(0)


func _pareja(a: Image, b: Image, esc: float, titulo_a: String, titulo_b: String) -> Image:
	var f: Font = load("res://estilo.gd").normal()
	var t := Vector2i(int(a.get_width() * esc), int(a.get_height() * esc))
	var vp := SubViewport.new()
	vp.size = Vector2i(t.x * 2 + 12, t.y + 46)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var fondo := ColorRect.new()
	fondo.color = Color("0B0C26")
	fondo.size = Vector2(vp.size)
	vp.add_child(fondo)
	for k in 2:
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(a if k == 0 else b)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.position = Vector2(k * (t.x + 12), 46)
		tr.size = Vector2(t)
		vp.add_child(tr)
		var l := Label.new()
		l.text = titulo_a if k == 0 else titulo_b
		l.add_theme_font_override("font", f)
		l.add_theme_font_size_override("font_size", 24)
		l.add_theme_color_override("font_color", Color("F2C86B") if k == 1 else Color("FFF6E3"))
		l.position = Vector2(k * (t.x + 12) + 10, 6)
		vp.add_child(l)
	root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


func _lamina(antes: String, despues: String) -> void:
	var celda := Vector2i(640, 360)
	var ancho := celda.x * 2 + 36
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var fondo := ColorRect.new()
	fondo.color = Color("0B0C26")
	vp.add_child(fondo)
	var f: Font = load("res://estilo.gd").normal()
	var cab := Label.new()
	cab.text = "OAKHAVEN (T-089) · ANTES: la ciudad de hoy (zona.gd) · DESPUÉS: el arte nuevo en la maqueta"
	cab.add_theme_font_override("font", f)
	cab.add_theme_font_size_override("font_size", 24)
	cab.add_theme_color_override("font_color", Color("F2C86B"))
	cab.position = Vector2(12, 18)
	vp.add_child(cab)
	var y := 70
	var hechas := 0
	for fila in LAMINA:
		var a := Image.load_from_file("%s/%s.png" % [antes, fila[0]])
		var b := Image.load_from_file("%s/%s.png" % [despues, fila[0]])
		if a == null or b == null:
			print("AVISO lámina: falta ", fila[0])
			continue
		var l := Label.new()
		l.text = fila[1]
		l.add_theme_font_override("font", f)
		l.add_theme_font_size_override("font_size", 20)
		l.add_theme_color_override("font_color", Color("FFF6E3"))
		l.position = Vector2(12, y + 4)
		vp.add_child(l)
		for k in 2:
			var tr := TextureRect.new()
			tr.texture = ImageTexture.create_from_image(a if k == 0 else b)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.position = Vector2(12 + k * (celda.x + 12), y + 34)
			tr.size = Vector2(celda)
			vp.add_child(tr)
		y += celda.y + 40
		hechas += 1
	vp.size = Vector2i(ancho, y + 10)
	fondo.size = Vector2(vp.size)
	root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.save_jpg(salida + "/lamina_antes_despues.jpg", 0.88)
	print("CAPTURA lámina antes/después: %d filas, %s" % [hechas, img.get_size()])
