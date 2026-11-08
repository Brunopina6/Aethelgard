extends SceneTree
# Capturas del mapamundi (T-085) con ventana, con los MISMOS encuadres para el mapa actual y para la propuesta,
# para compararlos. No cambia nada del juego: mueve a Kael y la cámara a mano y saca fotos.
#   Godot --path aethelgard --script res://pruebas/prueba_mapamundi_fotos.gd --fixed-fps 30 -- <carpeta>
#         [escena=res://mapa.tscn] sin_prologo
# Escribe en <carpeta> (.png):
#   1_juego_inicio          lo que se ve al abrir el mapa (Kael junto a Oakhaven, interfaz incluida), 1280×720
#   2_mapa_entero_1a1       el mapa entero a escala 1:1 (2400×1350, cosido con 4 vistas; sin interfaz ni Kael)
#   3_mapa_entero_pantalla  el mapa entero reducido a la pantalla (zoom 0,533), sin interfaz
#   4_costa_1x / 5_costa_3x una costa (la del sur del Gran Bosque Verde) a escala del juego y ampliada ×3
#   6_ciudad_oakhaven       Kael junto a Oakhaven, con el botón «Entrar», 1280×720
#   7_destino_garganta      Kael junto a la Garganta del Diablo, con el botón «Entrar», 1280×720
#   8_destino_cumbres       Kael junto a las Cumbres de Ciclópea (montaña y nieve), 1280×720
#   9_movil_20x9            ventana de 1600×720 (20:9, como un móvil HD+ alargado), con la cruceta táctil: con el
#                           estirado «canvas_items» y el aspecto «keep» (project.godot) el juego ocupa 1280×720 en
#                           el centro y quedan franjas negras de 160 px; la foto las reproduce.
# y, si la escena lo tiene, terreno_original.png y zonas_original.png (las imágenes que genera mapa.gd).
# Sin el contador de FPS de Recursos (es de depuración y la captura lo falsea). La etiqueta «Zona» se pone al día al
# mover a Kael a mano (en el juego cambia al andar).
#
# Modo comparación (no abre el mapa):  ... -- <carpeta_salida> comparar=<carpeta_antes>,<carpeta_propuesta>
#   escribe <n>.png y <n>.jpg con ANTES a la izquierda y PROPUESTA a la derecha (mismo encuadre), y mide lo «plano»
#   del mapa entero a 1:1: % de bloques de 16×16 px cuya luminancia apenas varía (desviación < 2/255).

const NOMBRES := ["1_juego_inicio", "2_mapa_entero_1a1", "3_mapa_entero_pantalla", "4_costa_1x", "5_costa_3x",
	"6_ciudad_oakhaven", "7_destino_garganta", "8_destino_cumbres", "9_movil_20x9"]

const ESCENA_ACTUAL := "res://mapa.tscn"
const COSTA := Vector2(830, 735)        # costa sur del Gran Bosque Verde (playa, mar poco hondo y mar hondo)

var salida := ""
var escena := ESCENA_ACTUAL
var m                                   # la escena del mapa


func _initialize() -> void:
	var comparar := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("escena="):
			escena = a.substr(7)
		elif a.begins_with("comparar="):
			comparar = a.substr(9)
		elif salida == "" and not "=" in a and a != "sin_prologo":
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
		_capturar.call_deferred()


func _comparar(antes: String, propuesta: String) -> void:
	await _esperar(3)
	var titulo_f: Font = load("res://estilo.gd").normal()
	for n in NOMBRES:
		var a := Image.load_from_file("%s/%s.png" % [antes, n])
		var b := Image.load_from_file("%s/%s.png" % [propuesta, n])
		if a == null or b == null:
			print("FALLO: falta ", n)
			continue
		var esc := 1.0 if a.get_width() <= 1600 else 0.5
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
			l.text = "ANTES · mapa actual (mapa.tscn)" if k == 0 else "PROPUESTA · prototipo pintado (mapa_arte/prototipo_mapa.tscn)"
			l.add_theme_font_override("font", titulo_f)
			l.add_theme_font_size_override("font_size", 24)
			l.add_theme_color_override("font_color", Color("F2C86B") if k == 1 else Color("FFF6E3"))
			l.position = Vector2(k * (t.x + 12) + 10, 6)
			vp.add_child(l)
		root.add_child(vp)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.save_png("%s/%s.png" % [salida, n])
		img.save_jpg("%s/%s.jpg" % [salida, n], 0.88)
		vp.queue_free()
		print("CAPTURA comparación ", n, " ", img.get_size())
	for k in 2:
		var img := Image.load_from_file("%s/2_mapa_entero_1a1.png" % (antes if k == 0 else propuesta))
		print("MEDIDA %s: %s" % ["antes" if k == 0 else "propuesta", _planitud(img)])
	quit(0)


# Lo «plano»: % de bloques de 16×16 cuya luminancia apenas varía (desviación típica < 2/255) y desviación media.
func _planitud(img: Image) -> String:
	img.convert(Image.FORMAT_RGBA8)
	var planos := 0
	var bloques := 0
	var suma := 0.0
	for by in range(0, img.get_height() - 15, 16):
		for bx in range(0, img.get_width() - 15, 16):
			var s := 0.0
			var s2 := 0.0
			for y in range(by, by + 16):
				for x in range(bx, bx + 16):
					var c := img.get_pixel(x, y)
					var l := 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
					s += l
					s2 += l * l
			var media := s / 256.0
			var desv := sqrt(maxf(s2 / 256.0 - media * media, 0.0)) * 255.0
			suma += desv
			bloques += 1
			if desv < 2.0:
				planos += 1
	return "%.1f %% de bloques planos (%d de %d), desviación media %.2f/255" % [100.0 * planos / bloques, planos, bloques, suma / bloques]


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


# Solo el mapa (sin interfaz ni Kael): se congela el mapa (como durante un encuentro) para que ningún lugar quede
# «cerca» (ni botón «Entrar» ni anillo) mientras se mueve la cámara.
func _solo_mapa(si: bool) -> void:
	m.en_encuentro = si
	m.jugador.visible = not si
	if si:
		m.cerca = null
		m.boton_entrar.visible = false
		if m.get("marcas_arte") != null:
			m.marcas_arte.queue_redraw()
	_interfaz(not si)


# Coloca a Kael (y con él la cámara, que es su hija) y espera a que la cámara llegue.
func _ir(pos: Vector2, zoom := 1.0) -> void:
	m.jugador.position = pos
	m.tiene_destino = false
	m.camara.zoom = Vector2(zoom, zoom)
	m.camara.reset_smoothing()
	await _esperar(2)
	m.camara.reset_smoothing()
	if not m.en_encuentro:
		m._comprobar_cerca()
	m.zona_actual = m._zona_en(pos)
	m.etiqueta_zona.text = "Zona: %s" % m.NOMBRES_ZONA.get(m.zona_actual, m.zona_actual)
	await _esperar(4)


func _interfaz(ver: bool) -> void:
	var fps = root.get_node("Recursos").get("lbl_fps")     # el contador de FPS de Recursos (arriba, en el centro)
	if fps != null:
		fps.visible = false
	for c in m.ui.get_children():
		if c != m.boton_entrar:
			c.visible = ver
		elif not ver:
			c.visible = false
		else:
			c.visible = m.cerca != null


func _capturar() -> void:
	await _esperar(3)
	change_scene_to_file(escena)
	if not await _hasta(func(): return current_scene != null and current_scene.get("jugador") != null, 60.0):
		print("FALLO: no se abrió ", escena)
		quit(1)
		return
	m = current_scene
	await _esperar(20)
	if m.get("terreno_tex") != null:
		m.terreno_tex.get_image().save_png(salida + "/terreno_original.png")
	if m.get("zonas_img") != null:
		m.zonas_img.save_png(salida + "/zonas_original.png")

	# 1. lo que se ve al abrir el mapa (posición inicial: 55 px bajo Oakhaven)
	await _ir(m.LUGARES[0]["pos"] + Vector2(0, 55))
	_interfaz(true)
	await _foto("1_juego_inicio")

	# 2. el mapa entero a 1:1: cuatro vistas de 1280×720 cosidas (los límites de la cámara las encajan)
	_solo_mapa(true)
	var tam: Vector2 = m.MAPA_TAM
	var entero := Image.create(int(tam.x), int(tam.y), false, Image.FORMAT_RGBA8)
	for c in [Vector2(640, 360), Vector2(tam.x - 640, 360), Vector2(640, tam.y - 360), Vector2(tam.x - 640, tam.y - 360)]:
		await _ir(c)
		var img: Image = await _imagen()
		img.convert(Image.FORMAT_RGBA8)
		var origen := Vector2i(int(c.x - 640), int(c.y - 360))
		entero.blit_rect(img, Rect2i(0, 0, 1280, 720), origen)
	entero.save_png(salida + "/2_mapa_entero_1a1.png")
	print("CAPTURA 2_mapa_entero_1a1 %dx%d" % [entero.get_width(), entero.get_height()])

	# 3. el mapa entero reducido a la pantalla
	await _ir(tam * 0.5, 1280.0 / tam.x)
	await _foto("3_mapa_entero_pantalla")

	# 4-5. una costa, a escala del juego y ampliada
	await _ir(COSTA, 1.0)
	await _foto("4_costa_1x")
	await _ir(COSTA, 3.0)
	await _foto("5_costa_3x")

	# 6-8. ciudad y destinos, con Kael y la interfaz (el botón «Entrar» a la vista)
	_solo_mapa(false)
	await _ir(m.LUGARES[0]["pos"] + Vector2(48, 40), 1.0)
	_interfaz(true)
	await _foto("6_ciudad_oakhaven")
	await _ir(m.LUGARES[2]["pos"] + Vector2(-50, 40), 1.0)
	_interfaz(true)
	await _foto("7_destino_garganta")
	await _ir(m.LUGARES[3]["pos"] + Vector2(-40, 50), 1.0)
	_interfaz(true)
	await _foto("8_destino_cumbres")

	# 9. móvil alargado 20:9 (1600×720): con stretch «canvas_items» y aspecto «keep», franjas a los lados
	var dpad = load("res://dpad.gd").new()             # la cruceta, como en el móvil (mapa.gd, _crear_ui)
	dpad.position = Vector2(30, 440)
	m.ui.add_child(dpad)
	DisplayServer.window_set_size(Vector2i(1600, 720))
	await _esperar(10)
	await _ir(m.LUGARES[0]["pos"] + Vector2(0, 55), 1.0)
	_interfaz(true)
	var img: Image = await _imagen()                     # la vista del juego (1280×720) ...
	img.convert(Image.FORMAT_RGBA8)
	var movil := Image.create(1600, 720, false, Image.FORMAT_RGBA8)
	movil.fill(Color(0, 0, 0, 1))                        # ... con las franjas negras del aspecto «keep»
	movil.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((1600 - img.get_width()) / 2, (720 - img.get_height()) / 2))
	movil.save_png(salida + "/9_movil_20x9.png")
	print("CAPTURA 9_movil_20x9 1600x720 (vista del juego %dx%d)" % [img.get_width(), img.get_height()])
	DisplayServer.window_set_size(Vector2i(1280, 720))
	print("CAPTURAS hechas en ", salida)
	quit(0)
