extends SceneTree
# Arboleda Mítica, tramo «La escalera de la Hospedería» (EXPERIMENTAL, 16/11): prepara para el juego lo que sale de
# pruebas/herramientas/render_isla.gd y preparar_isla.gd (que se usan TAL CUAL), y las «sondas» 2D.
#
#   interior   <render> = carpeta con color_0_0.png y datos.json del render del interior; <prep> = la salida de
#              preparar_isla.gd (isla_paso/suelo/tapa.png); <anclas> = hospederia_anclas.json de crear_hospederia.py.
#              Escribe interior/color.png (lo de fuera de la sala, opaco y oscuro; las ventanas, transparentes: detrás
#              se ve el cielo con nubes; y un suavizado leve para igualar la blandura del render de Meshy), paso.png,
#              suelo.png, tapa.png, luz.png (sondas, 1/4) y anclas.json (las anclas en píxeles del interior).
#   luz        escribe tramo/luz_tramo.png: la luz del suelo de la isla a 1/4 (de la pasada de color de Meshy: la
#              luminancia del suelo por el que se anda, muy suavizada; 0,5 = la media de la plaza). Bajo los aleros y
#              los árboles sale más baja.
#   dibujo     escribe piezas/dibujo_lumi.png: el dibujo de Lumi (papel y cera), pintado por código.
# Uso: godot --headless --path aethelgard --script res://zonas3d/arboleda_tramo/fuente/preparar_tramo.gd --
#      interior <render> <prep> <anclas> | luz | dibujo

const DESTINO := "res://zonas3d/arboleda_tramo/"
const FONDO := Color("2A1C14")          # lo de fuera de la sala (madera en sombra)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	match a[0]:
		"interior":
			_interior(a[1], a[2], a[3])
		"luz":
			_luz_isla()
		"dibujo":
			_dibujo()
		"pieza":
			_pieza(a[1], a[2], float(a[3]))
	quit()


# Una pieza del atrezo: el render (al doble) recortado a lo que tiene algo, reducido a su escala (Lanczos) y con el mismo
# suavizado leve que el interior. Uso: pieza <carpeta del render> <salida res://…png> <factor de escala>
func _pieza(render: String, salida: String, factor: float) -> void:
	DirAccess.make_dir_recursive_absolute(_g("piezas"))
	var img := Image.load_from_file(render.path_join("color_0_0.png"))
	img.convert(Image.FORMAT_RGBA8)
	var rec := img.get_region(img.get_used_rect())
	rec.resize(maxi(1, int(round(rec.get_width() * factor))), maxi(1, int(round(rec.get_height() * factor))),
		Image.INTERPOLATE_LANCZOS)
	var sal := rec
	for vuelta in 2:                              # (2.ª pasada, 16/11: dos suavizados y el color más calmado)
		sal = _suavizar(sal)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1611
	for y in sal.get_height():
		for x in sal.get_width():
			var c := sal.get_pixel(x, y)
			if c.a < 0.01:
				continue
			var l := 0.3 * c.r + 0.59 * c.g + 0.11 * c.b
			var g := Color(l, l, l, c.a)
			c = c.lerp(g, 0.18) * (0.97 + rng.randf() * 0.06)
			c.a = sal.get_pixel(x, y).a
			sal.set_pixel(x, y, c)
	sal.save_png(ProjectSettings.globalize_path(salida))
	print("pieza %s: %d × %d" % [salida, sal.get_width(), sal.get_height()])


func _suavizar(rec: Image) -> Image:
	var sal := rec.duplicate()
	for y in range(1, rec.get_height() - 1):
		for x in range(1, rec.get_width() - 1):
			if rec.get_pixel(x, y).a < 0.05:
				continue
			var acc := Color(0, 0, 0, 0)
			var peso := 0.0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var q := rec.get_pixel(x + dx, y + dy)
					var p := (2.0 if dx == 0 else 1.0) * (2.0 if dy == 0 else 1.0) * q.a
					acc += q * p
					peso += p
			var c := acc / peso
			c.a = rec.get_pixel(x, y).a
			sal.set_pixel(x, y, c)
	return sal


func _g(ruta: String) -> String:
	return ProjectSettings.globalize_path(DESTINO + ruta)


# ----------------------------------------------------------------------------------------------------- interior

func _interior(render: String, prep: String, ruta_anclas: String) -> void:
	DirAccess.make_dir_recursive_absolute(_g("interior"))
	var color := Image.load_from_file(render.path_join("color_0_0.png"))
	color.convert(Image.FORMAT_RGBA8)
	var w := color.get_width()
	var h := color.get_height()
	# 1) lo transparente que toca el borde es «fuera»: opaco y oscuro. Lo transparente encerrado (las ventanas) queda.
	var fuera := PackedByteArray()
	fuera.resize(w * h)
	var cola: Array = []
	for x in w:
		cola.append(x)
		cola.append((h - 1) * w + x)
	for y in h:
		cola.append(y * w)
		cola.append(y * w + w - 1)
	while not cola.is_empty():
		var k: int = cola.pop_back()
		if fuera[k] or color.get_pixel(k % w, k / w).a > 0.5:
			continue
		fuera[k] = 1
		var x := k % w
		var y := k / w
		if x > 0: cola.append(k - 1)
		if x < w - 1: cola.append(k + 1)
		if y > 0: cola.append(k - w)
		if y < h - 1: cola.append(k + w)
	# 2) suavizado leve (núcleo 1-2-1) solo en lo opaco, para que no se vea más nítido que el fondo de Meshy
	var suave := color.duplicate()
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c := color.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var acc := Color(0, 0, 0, 0)
			var peso := 0.0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var q := color.get_pixel(x + dx, y + dy)
					if q.a < 0.5:
						continue
					var p := (2.0 if dx == 0 else 1.0) * (2.0 if dy == 0 else 1.0)
					acc += q * p
					peso += p
			var r := acc / peso
			r.a = 1.0
			suave.set_pixel(x, y, r)
	var ventanas := 0
	for k in w * h:
		if fuera[k]:
			suave.set_pixel(k % w, k / w, FONDO)
		elif suave.get_pixel(k % w, k / w).a < 0.5:
			suave.set_pixel(k % w, k / w, Color(0, 0, 0, 0))
			ventanas += 1
	suave.save_png(_g("interior/color.png"))
	# 3) máscaras de preparar_isla.gd, con sus nombres del tramo
	for par in [["isla_paso.png", "paso.png"], ["isla_suelo.png", "suelo.png"], ["isla_tapa.png", "tapa.png"]]:
		var im := Image.load_from_file(prep.path_join(par[0]))
		im.save_png(_g("interior/" + par[1]))
	# 4) sondas: la luz del suelo del interior
	var paso := Image.load_from_file(prep.path_join("isla_paso.png"))
	_sondas(suave, paso, _g("interior/luz.png"), 4)
	# 5) anclas en píxeles del interior
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(render.path_join("datos.json")))
	var an: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta_anclas))
	var caja: Dictionary = an["caja_godot"]
	var cx: float = (float(caja["x"][0]) + float(caja["x"][1])) * 0.5
	var ws: float = datos["metros_ancho"]
	var hs: float = datos["metros_alto"]
	var px := {}
	for k in an["anclas"]:
		var p: Array = an["anclas"][k]
		var v: float = float(p[1]) * float(datos["cos"]) - float(p[2]) * float(datos["sen"])
		px[k] = [roundf((float(p[0]) - (cx - ws * 0.5)) / ws * w), roundf((float(datos["arriba_img"]) - v) / hs * h)]
	var f := FileAccess.open(_g("interior/anclas.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"tam": [w, h], "anclas": px, "px_por_metro": w / ws}, "\t"))
	f.close()
	print("interior: %d × %d, %d píxeles de ventana, anclas %s" % [w, h, ventanas, str(px)])


# La luz del suelo a 1/4: luminancia media de cada celda andable (de la imagen de color), suavizada con un radio de
# «r» celdas y normalizada a 0,5 en la mediana. Fuera de lo andable, la de la celda andable más cercana (suavizado).
func _sondas(color: Image, paso: Image, ruta: String, r: int) -> void:
	var w4 := paso.get_width()
	var h4 := paso.get_height()
	var lum := PackedFloat32Array()
	lum.resize(w4 * h4)
	var hay := PackedByteArray()
	hay.resize(w4 * h4)
	var vals: Array = []
	for y in h4:
		for x in w4:
			if paso.get_pixel(x, y).r < 0.5:
				continue
			var s := 0.0
			var n := 0
			for oy in 4:
				for ox in 4:
					var px := x * 4 + ox
					var py := y * 4 + oy
					if px < color.get_width() and py < color.get_height():
						var c := color.get_pixel(px, py)
						s += 0.3 * c.r + 0.59 * c.g + 0.11 * c.b
						n += 1
			if n > 0:
				lum[y * w4 + x] = s / n
				hay[y * w4 + x] = 1
				vals.append(s / n)
	vals.sort()
	var med: float = vals[vals.size() / 2] if vals.size() > 0 else 0.5
	var img := Image.create(w4, h4, false, Image.FORMAT_L8)
	for y in h4:
		for x in w4:
			var s := 0.0
			var n := 0.0
			for oy in range(-r, r + 1, 2):
				for ox in range(-r, r + 1, 2):
					var xx := x + ox
					var yy := y + oy
					if xx < 0 or yy < 0 or xx >= w4 or yy >= h4 or not hay[yy * w4 + xx]:
						continue
					s += lum[yy * w4 + xx]
					n += 1.0
			var v := 0.5 if n == 0.0 else clampf(0.5 * (s / n) / med, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	img.save_png(ruta)
	print("sondas %s: %d × %d, mediana %.3f" % [ruta, w4, h4, med])


# ----------------------------------------------------------------------------------------------------- exterior

func _luz_isla() -> void:
	DirAccess.make_dir_recursive_absolute(_g("tramo"))
	var color := Image.create(3072, 3348, false, Image.FORMAT_RGBA8)
	for j in 2:
		for i in 2:
			var t := Image.load_from_file(ProjectSettings.globalize_path("res://isla/isla_color_%d_%d.png" % [i, j]))
			t.convert(Image.FORMAT_RGBA8)
			color.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i(i * 1536, j * 1674))
	var paso: Image = (load("res://isla/isla_paso.png") as Texture2D).get_image()
	var extra := Image.load_from_file(_g("tramo/paso_extra.png"))
	var junto := Image.create(paso.get_width(), paso.get_height(), false, Image.FORMAT_L8)
	for y in paso.get_height():
		for x in paso.get_width():
			var si := paso.get_pixel(x, y).r > 0.5 or extra.get_pixel(x, y).r > 0.5
			junto.set_pixel(x, y, Color.WHITE if si else Color.BLACK)
	_sondas(color, junto, _g("tramo/luz_tramo.png"), 6)


# ----------------------------------------------------------------------------------------------------- dibujo

# El dibujo de Lumi: una hoja clavada con cera de colores. Arriba, el sol; abajo, una flor y un caminito con colores
# («Entonces abajo no es gris»). Pequeño: se ve a unos 40 píxeles en la pared.
func _dibujo() -> void:
	DirAccess.make_dir_recursive_absolute(_g("piezas"))
	var w := 64
	var h := 52
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var papel := Color("F4ECD8")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1609
	for y in h:
		for x in w:
			var dentro := x >= 3 and x < w - 3 and y >= 3 and y < h - 2
			if dentro:
				var c := papel.darkened(rng.randf() * 0.04)
				if x > w - 9 and y < 9 and (w - x) + y < 13:       # esquina doblada
					c = Color("DDD2B8")
				img.set_pixel(x, y, c)
			elif x >= 5 and x < w - 1 and y >= 5 and y < h:
				img.set_pixel(x, y, Color(0.1, 0.06, 0.03, 0.35))   # sombra en la pared
	var cera := func(cx: float, cy: float, rad: float, col: Color) -> void:
		for y in range(int(cy - rad - 1), int(cy + rad + 2)):
			for x in range(int(cx - rad - 1), int(cx + rad + 2)):
				if x < 4 or y < 4 or x >= w - 4 or y >= h - 3:
					continue
				var d := Vector2(x - cx, y - cy).length()
				if d <= rad and rng.randf() > 0.18:
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(col, 0.85))
	# sol con rayos
	cera.call(14.0, 13.0, 5.0, Color("F2B632"))
	for k in 8:
		var a := k * TAU / 8.0
		for t in range(7, 10):
			cera.call(14.0 + cos(a) * t, 13.0 + sin(a) * t, 0.8, Color("E8A020"))
	# nube gris tachada (arriba a la derecha) y debajo, colores
	for k in 4:
		cera.call(40.0 + k * 4.0, 12.0 + (k % 2), 3.2, Color("9C9CA4"))
	for t in range(0, 16):
		cera.call(38.0 + t, 8.0 + t * 0.55, 0.7, Color("C43C3C"))
	# suelo verde y caminito
	for x in range(6, w - 6):
		cera.call(float(x), 41.0 + sin(x * 0.4) * 1.2, 1.4, Color("5FA82E"))
	# la flor de abajo, grande, con su tallo
	for t in range(0, 14):
		cera.call(31.0, 39.0 - t, 0.8, Color("3E8A22"))
	for k in 6:
		var a := k * TAU / 6.0
		cera.call(31.0 + cos(a) * 4.0, 23.0 + sin(a) * 4.0, 2.4, Color("B06CD0"))
	cera.call(31.0, 23.0, 2.0, Color("F2D040"))
	# dos figuritas: una niña con lazo y alguien de abajo
	for p in [Vector2(17, 36), Vector2(46, 36)]:
		cera.call(p.x, p.y - 7.0, 2.2, Color("6A4A3A"))
		for t in range(0, 6):
			cera.call(p.x, p.y - 4.0 + t, 0.7, Color("3A6AC0") if p.x > 30 else Color("C04A70"))
	img.save_png(_g("piezas/dibujo_lumi.png"))
	print("dibujo de Lumi: %d × %d" % [w, h])
