extends SceneTree
# Prueba del mapamundi pintado (T-085): lo dibujado coincide con lo que usa el juego y no cambia nada funcional.
#   Godot --headless --path aethelgard --script res://pruebas/prueba_mapamundi.gd --fixed-fps 30 -- [3d] sin_prologo
#   (con «mapa_clasico» comprueba que mapa.tscn vuelve al mapa de siempre)
# 1. réplica: datos_mapa.gd reproduce la máscara de tierra y zonas de mapa.gd (_generar_terreno), píxel a píxel;
# 2. máscara horneada: mapa_arte/mapa_zonas.png es idéntica a la que genera mapa.gd;
# 3. alineación: datos_mapa.tierra_juego(q) da lo mismo que mapa.gd._es_tierra(q) (cada 3 px en x, cada px en y);
#    la máscara va con el dibujo en todo el mapa (también en la mitad de abajo) y nada queda sin pintar abajo;
# 4. costa dibujada: la tierra y el mar del dibujo (costa_datos.png, el campo con el que se pinta la costa)
#    coinciden con _es_tierra salvo junto a la costa: ningún desacuerdo a más de 4 px de la línea dibujada;
# 5. zonas dibujadas: el bioma con el que se pinta cada punto es el de los encuentros y de «Zona: …» (_zona_en),
#    salvo a 4 px o menos de un borde entre zonas;
# 6. mapa.tscn (el mapa pintado) conserva lugares, posiciones, rutas, islas y radio de «Entrar» y usa la misma
#    máscara; cada icono contiene la posición de su lugar y cada rótulo está junto a ella; ningún rótulo pisa (ni
#    roza, a 6 px) otro rótulo, una región o el dibujo de otro icono (el suyo solo lo corona si va encima); los
#    iconos no se pisan entre sí; los rótulos van por encima de Kael y, al abrir el mapa, ni Kael ni la interfaz
#    (botón «Entrar», barra, «Misiones», brújula, «Zona: …» y la cruceta del móvil) tapan ninguno;
# 7. «Entrar»: Kael en cada lugar lo tiene cerca; a RADIO_LUGAR + 6 px, no;
# 8. el mapa clásico sin argumentos: en la versión experimental (con «3d»), [mapa] clasico=true en
#    user://ajustes.cfg lo elige y [mapa] agua_quieta=true quita el agua animada; se quitan sin tocar el resto del
#    archivo (el volumen de sonido.gd) y abrir el mapa no escribe nada. Fuera de ella, la opción no cuenta. Al acabar,
#    user://ajustes.cfg queda exactamente como estaba (las demás pruebas de la pasada lo comparten).
# Termina con «FALLOS: n» y código 1 si algo no cuadra.

const MAPA := "res://mapa.tscn"
const TOLERANCIA := 4.0           # px: desacuerdos de costa y de zona admitidos junto a la línea dibujada
const HOLGURA_ROTULO := 6.0       # px: un rótulo no puede acercarse más que esto a otro rótulo o a un icono
const ALFA := 0.3                 # lo que cuenta como «dibujado» en un icono o en Kael

var fallos := 0
var M
var D
var A
var clasico := false
var experimental := false


func _initialize() -> void:
	_probar.call_deferred()


func _ok(t: String) -> void:
	print("OK ", t)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _probar() -> void:
	clasico = "mapa_clasico" in OS.get_cmdline_user_args()
	experimental = load("res://modo3d.gd").activo()
	M = load("res://mapa.gd")
	D = load("res://mapa_arte/datos_mapa.gd").new()
	A = load("res://mapa_arte/mapa_arte.gd")
	var gen = M.new()
	var t0 := Time.get_ticks_msec()
	gen._generar_terreno()
	print("INFO _generar_terreno de mapa.gd: %d ms (indicativo)" % (Time.get_ticks_msec() - t0))
	var mascara: Image = gen.zonas_img
	if "solo_marcas" in OS.get_cmdline_user_args():      # para ajustar iconos y rótulos deprisa: solo 6-8
		gen.free()
		await _probar_mapa(mascara)
		_fin()
		return

	# 1. réplica exacta: la rejilla de 4 px (600×338) evaluada en la esquina de cada bloque, ×2 y recortada
	var rep := Image.create(600, 338, false, Image.FORMAT_RGBA8)
	for y in 338:
		for x in 600:
			var p := Vector2(x, y) * 4.0
			if D.campo_v(p) < 0.0:
				continue
			var zc: Color = M.ZONAS[D.ZONAS_ORDEN[D.zona_en(p)]]
			rep.set_pixel(x, y, Color(zc.r, zc.g, zc.b, 1.0))
	rep.resize(1200, 676, Image.INTERPOLATE_NEAREST)
	rep = rep.get_region(Rect2i(0, 0, 1200, 675))
	var dif := _diferencias(rep, mascara)
	if dif == 0 and mascara.get_size() == Vector2i(1200, 675):
		_ok("réplica: datos_mapa.gd da la misma máscara que mapa.gd (1200×675, 0 píxeles distintos)")
	else:
		_fallo("réplica: %d píxeles distintos (máscara de %s)" % [dif, mascara.get_size()])

	# 2. máscara horneada
	var r = load("res://mapa_arte/mapa_zonas.png")
	var horneada: Image = r if r is Image else null
	if horneada == null:
		_fallo("mapa_arte/mapa_zonas.png no se carga como Image")
	else:
		horneada = horneada.duplicate()
		horneada.convert(Image.FORMAT_RGBA8)
		dif = _diferencias(horneada, mascara)
		if dif == 0:
			_ok("máscara horneada idéntica a la que genera mapa.gd (tierra, mar y zonas)")
		else:
			_fallo("máscara horneada: %d píxeles distintos (¿falta regenerar con mapa_arte/generar_mapa.gd?)" % dif)

	# 3. alineación exacta del campo con el juego, y la máscara con el dibujo en la mitad de abajo
	var mal := 0
	var total := 0
	for y in range(0, 1350):
		for x in range(0, 2400, 3):
			var q := Vector2(x, y)
			total += 1
			if D.tierra_juego(q) != gen._es_tierra(q):
				mal += 1
	if mal == 0:
		_ok("alineación: tierra_juego(q) == _es_tierra(q) en %d puntos" % total)
	else:
		_fallo("alineación: %d de %d puntos distintos" % [mal, total])
	# el dibujo de siempre (un píxel por bloque de 4 px, a escala 4) y la máscara, bloque a bloque, en todo el mapa:
	# sin el desfase de 2 px que tenía la mitad de abajo
	var dib: Image = _imagen(gen.terreno_tex)
	mal = 0
	total = 0
	for y in range(1, 1350, 2):
		for x in range(1, 2400, 6):
			var bx := x / 4
			var by := y / 4
			if dib == null or by >= dib.get_height():
				mal += 1
				continue
			total += 1
			var c := dib.get_pixel(bx, by)
			var tierra_dibujo := c.b - c.r < 0.14            # el mar es azul (b − r ≥ 0,16); la tierra, no (≤ 0,09)
			if tierra_dibujo != gen._es_tierra(Vector2(x, y)):
				mal += 1
	if mal == 0:
		_ok("mapa de siempre: la máscara coincide con su dibujo bloque a bloque en todo el mapa (%d puntos, también abajo)" % total)
	else:
		_fallo("mapa de siempre: %d de %d puntos con dibujo y máscara distintos" % [mal, total])
	var alto_dibujo: int = gen.terreno_tex.get_height() * M.RES_TERRENO
	if alto_dibujo >= int(M.MAPA_TAM.y):
		_ok("mapa de siempre: el dibujo cubre el mapa entero (%d px de alto de %d; antes quedaban 2 px sin pintar)" % [alto_dibujo, int(M.MAPA_TAM.y)])
	else:
		_fallo("mapa de siempre: el dibujo solo cubre %d px de alto de %d" % [alto_dibujo, int(M.MAPA_TAM.y)])
	var pintado: Texture2D = load("res://mapa_arte/mapa_mundo.webp")
	if pintado != null and Vector2(pintado.get_size()) == M.MAPA_TAM:
		_ok("mapa pintado: %s, el mapa entero" % str(pintado.get_size()))
	else:
		_fallo("mapa pintado: tamaño %s, no %s" % [str(pintado.get_size()) if pintado else "?", M.MAPA_TAM])

	# 4. costa dibujada frente a la tierra del juego
	var rc = load("res://mapa_arte/costa_datos.png")
	var costa: Image = rc if rc is Image else null
	if costa == null:
		_fallo("mapa_arte/costa_datos.png no se carga como Image")
	else:
		costa = costa.duplicate()
		costa.convert(Image.FORMAT_RGBA8)
		var n := 0
		var desacuerdos := 0
		var peor := 0.0
		var hist := [0, 0, 0, 0, 0]
		var abajo := 0
		for y in range(0, 1350, 2):
			for x in range(0, 2400, 2):
				var q := Vector2(x + 0.5, y + 0.5)
				n += 1
				var dibujo := _campo(costa, q) >= 0.0
				if dibujo == gen._es_tierra(q):
					continue
				desacuerdos += 1
				if y >= 676:
					abajo += 1
				var d := _dist_costa(costa, q, dibujo)
				peor = maxf(peor, d)
				hist[mini(int(d), 4)] += 1
		var pct := 100.0 * desacuerdos / n
		print("INFO costa: %d de %d puntos (%.2f %%) con dibujo y juego en desacuerdo (%d en la mitad de abajo); distancia a la línea dibujada: <1 px %d, 1-2 %d, 2-3 %d, 3-4 %d, ≥4 %d; la peor %.1f px"
			% [desacuerdos, n, pct, abajo, hist[0], hist[1], hist[2], hist[3], hist[4], peor])
		if peor <= TOLERANCIA:
			_ok("costa dibujada: todo desacuerdo está a %.1f px o menos de la línea de costa (tolerancia %.0f px)" % [peor, TOLERANCIA])
		else:
			_fallo("costa dibujada: un desacuerdo a %.1f px de la costa (tolerancia %.0f px)" % [peor, TOLERANCIA])

	# 5. zonas dibujadas frente a las de los encuentros
	_comprobar_zonas(gen)
	gen.free()
	await _probar_mapa(mascara)
	_fin()


# 6-8: mapa.tscn, «Entrar» y la opción de ajustes.cfg.
func _probar_mapa(mascara: Image) -> void:
	var m = await _abrir_mapa()
	if m == null:
		return
	if clasico:
		if m.arte_activo() or m.terreno_tex == null:
			_fallo("con «mapa_clasico», mapa.tscn debería dibujar el mapa de siempre")
		else:
			_ok("con «mapa_clasico», mapa.tscn dibuja el mapa de siempre (terreno generado por mapa.gd)")
		_comprobar_clasico(m)
	elif not m.arte_activo():
		_fallo("el mapa pintado no está activo en mapa.tscn (¿faltan archivos en mapa_arte/?)")
	else:
		_ok("mapa.tscn dibuja el mapa pintado; la máscara no se genera al cargar (terreno_tex = %s)" % str(m.terreno_tex))
	if _diferencias(m.zonas_img, mascara) == 0:
		_ok("mapa.tscn usa la misma máscara de tierra y zonas que mapa.gd")
	else:
		_fallo("mapa.tscn usa otra máscara")
	var esperados: Array = M.LUGARES + ([M.LUGAR_PASTOS] if experimental else [])
	var iguales: bool = m.lugares.size() == esperados.size()
	for i in mini(m.lugares.size(), esperados.size()):
		iguales = iguales and m.lugares[i] == esperados[i]
	if iguales and m.RUTAS == M.RUTAS and m.ISLAS == M.ISLAS and m.RADIO_LUGAR == M.RADIO_LUGAR and m.MAPA_TAM == M.MAPA_TAM:
		_ok("lugares (%d), nombres, tipos, posiciones, rutas, islas, radio de «Entrar» y tamaño, iguales que en mapa.gd" % esperados.size())
	else:
		_fallo("los datos funcionales de mapa.tscn no son los de mapa.gd")
	if not clasico:
		await _comprobar_marcas(m)
	# «Entrar»
	var bien := 0
	for i in m.lugares.size():
		var l: Dictionary = m.lugares[i]
		m.jugador.position = l["pos"]
		m._comprobar_cerca()
		var dentro: bool = m.cerca == l
		m.jugador.position = l["pos"] + Vector2(m.RADIO_LUGAR + 6.0, 0.0)
		m._comprobar_cerca()
		var fuera: bool = m.cerca != l
		if dentro and fuera:
			bien += 1
		else:
			_fallo("«Entrar» no cuadra en %s (dentro %s, fuera %s)" % [l["nombre"], dentro, fuera])
	if bien == m.lugares.size():
		_ok("«Entrar» aparece en cada lugar y no a RADIO_LUGAR + 6 px (%d lugares)" % bien)

	# 8. el mapa clásico elegido sin argumentos
	if not clasico:
		await _comprobar_opcion()


func _abrir_mapa():
	var viejo = current_scene
	change_scene_to_file(MAPA)
	var m = null
	for i in 180:
		await process_frame
		var c = current_scene
		if c != null and c != viejo and c.get("jugador") != null:
			m = c
			break
	if m == null:
		_fallo("no se abrió " + MAPA)
		return null
	await process_frame
	return m


# Los píxeles de una textura, sin comprimir. Si viene de un archivo del proyecto, los del archivo de origen (la
# importación puede comprimirla y, sin ventana, no siempre se puede leer); si no, los de la textura.
func _imagen(tex: Texture2D) -> Image:
	if tex == null:
		return null
	var img: Image = null
	if tex is AtlasTexture:
		var base := _imagen(tex.atlas)
		if base != null:
			img = base.get_region(Rect2i(tex.region))
	elif tex.resource_path != "" and not tex.resource_path.contains("::"):
		img = Image.load_from_file(ProjectSettings.globalize_path(tex.resource_path))
	if img == null and not tex is AtlasTexture:
		img = tex.get_image()
	if img == null:
		return null
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


# ---------------------------------------------------------------- 5. zonas

func _comprobar_zonas(gen) -> void:
	var n := 0
	var desacuerdos := 0
	var peor := 0.0
	var des: Vector2 = D.desfase()
	for y in range(1, 1350, 4):
		for x in range(1, 2400, 4):
			var q := Vector2(x, y)
			if not gen._es_tierra(q):
				continue
			n += 1
			var dibujada: int = D.zona_en(q - des)          # con la que se pinta (generar_mapa.gd, datos_mapa.calcular)
			var juego: int = D.ZONAS_ORDEN.find(gen._zona_en(q))
			if dibujada == juego:
				continue
			desacuerdos += 1
			var d := 99.0                                     # distancia al borde de zona más cercano del dibujo
			for dy in range(-8, 9):
				for dx in range(-8, 9):
					var l := Vector2(dx, dy).length()
					if l < d and l <= 8.0 and D.zona_en(q + Vector2(dx, dy) - des) != dibujada:
						d = l
			peor = maxf(peor, d)
	print("INFO zonas: %d de %d puntos de tierra (%.2f %%) con la zona dibujada distinta de la del juego; la peor a %.1f px de un borde"
		% [desacuerdos, n, 100.0 * desacuerdos / maxi(n, 1), peor])
	if peor <= TOLERANCIA:
		_ok("zonas dibujadas: coinciden con las de los encuentros y «Zona: …» salvo a %.1f px o menos de un borde (tolerancia %.0f px)" % [peor, TOLERANCIA])
	else:
		_fallo("zonas dibujadas: un desacuerdo a %.1f px de un borde de zona (tolerancia %.0f px)" % [peor, TOLERANCIA])


# ---------------------------------------------------------------- 6. iconos y rótulos

func _comprobar_marcas(m) -> void:
	var rotulos := {}
	var regiones: Array = []
	for c in m.rotulos.get_children():
		if c is Label and c.has_meta("lugar"):
			rotulos[c.get_meta("lugar")] = c
		elif c is Label:
			regiones.append(c)
	if m.rotulos.z_index <= 0:
		_fallo("los rótulos no van por encima de Kael (z_index %d)" % m.rotulos.z_index)
	else:
		_ok("los rótulos van por encima de Kael (z_index %d): Kael nunca los tapa" % m.rotulos.z_index)
	var imgs := {}
	for i in m.iconos:
		var img := _imagen(m.iconos[i])
		if img == null:
			_fallo("no se puede leer el icono %d" % i)
			continue
		imgs[i] = img
	# cada icono contiene su lugar; cada rótulo, junto a él
	var bien := 0
	for i in m.lugares.size():
		var l: Dictionary = m.lugares[i]
		var p: Vector2 = l["pos"]
		if not m.iconos.has(i) or not rotulos.has(i):
			_fallo("sin icono o sin rótulo: " + l["nombre"])
			continue
		var ri: Rect2 = m.rect_icono(i)
		var rr: Rect2 = m.rect_rotulo(rotulos[i])
		var dist := _dist_rect(p, rr)
		print("INFO %-30s icono %s  rótulo %s (%s, a %.0f px del lugar)" % [l["nombre"], ri, rr,
			m.ROTULO_SITIO.get(l["nombre"], ["arriba"])[0], dist])
		if ri.has_point(p) and dist <= 130.0:
			bien += 1
		else:
			_fallo("icono o rótulo lejos de su lugar: %s (icono %s, rótulo a %.0f px)" % [l["nombre"], ri, dist])
	if bien == m.lugares.size():
		_ok("cada icono contiene la posición de su lugar y cada rótulo está junto a ella (%d)" % bien)
	# ningún rótulo pisa ni roza otro rótulo
	var choques := 0
	var claves: Array = rotulos.keys()
	for a in claves.size():
		var ra: Rect2 = m.rect_rotulo(rotulos[claves[a]]).grow(HOLGURA_ROTULO * 0.5)
		for b in range(a + 1, claves.size()):
			if ra.intersects(m.rect_rotulo(rotulos[claves[b]]).grow(HOLGURA_ROTULO * 0.5)):
				choques += 1
				_fallo("los rótulos de %s y %s se pisan" % [m.lugares[claves[a]]["nombre"], m.lugares[claves[b]]["nombre"]])
		for rg in regiones:
			if ra.intersects(m.rect_rotulo(rg).grow(8.0)):
				choques += 1
				_fallo("el rótulo de %s pisa la región %s" % [m.lugares[claves[a]]["nombre"], rg.text])
	# ningún rótulo pisa ni roza el dibujo de otro icono; el suyo, si va encima, lo corona (se toca a propósito), y si
	# va debajo o a un lado, no lo pisa
	for k in claves:
		var rr: Rect2 = m.rect_rotulo(rotulos[k])
		var arriba: bool = m.ROTULO_SITIO.get(m.lugares[k]["nombre"], ["arriba"])[0] == "arriba"
		for i in imgs:
			if i == k and arriba:
				continue
			var holgura := HOLGURA_ROTULO if i != k else 0.0
			var n := _pixeles_icono(m, imgs, i, rr.grow(holgura))
			if n > 0:
				choques += 1
				_fallo("el rótulo de %s pisa o roza el icono de %s (%d px a menos de %.0f px)" % [m.lugares[k]["nombre"],
					m.lugares[i]["nombre"], n, holgura])
	if choques == 0:
		_ok("ningún rótulo pisa ni roza (a %.0f px) otro rótulo, una región o el dibujo de un icono (%d rótulos)" % [HOLGURA_ROTULO, claves.size()])
	# los iconos no se pisan entre sí
	var pisados := 0
	var lista: Array = imgs.keys()
	for a in lista.size():
		for b in range(a + 1, lista.size()):
			var ia: int = lista[a]
			var ib: int = lista[b]
			var inter: Rect2 = m.rect_icono(ia).intersection(m.rect_icono(ib))
			if inter.size == Vector2.ZERO:
				continue
			var n := 0
			for y in range(int(inter.position.y), int(inter.end.y)):
				for x in range(int(inter.position.x), int(inter.end.x)):
					var w := Vector2(x + 0.5, y + 0.5)
					if _alfa_icono(m, imgs, ia, w) > ALFA and _alfa_icono(m, imgs, ib, w) > ALFA:
						n += 1
			if n > 0:
				pisados += 1
				_fallo("los iconos de %s y %s se pisan (%d px)" % [m.lugares[ia]["nombre"], m.lugares[ib]["nombre"], n])
	if pisados == 0:
		_ok("los iconos no se pisan entre sí (%d iconos)" % lista.size())
	# al abrir el mapa, ningún rótulo queda bajo la interfaz (botón «Entrar», barra, «Misiones», brújula, «Zona: …»
	# y, en el móvil, la cruceta)
	var inicio: Vector2 = m.LUGARES[0]["pos"] + Vector2(0, 55)
	m.jugador.position = inicio
	m._comprobar_cerca()
	await process_frame
	var vista := Rect2((inicio - Vector2(640, 360)).clamp(Vector2.ZERO, m.MAPA_TAM - Vector2(1280, 720)), Vector2(1280, 720))
	var interfaz := {"cruceta (móvil)": Rect2(30, 440, 180, 180)}
	for c in m.ui.get_children():
		if c is Control and c.visible and c.modulate.a > 0.01:
			interfaz[c.get("text") if c.get("text") else c.get_class()] = c.get_global_rect()
	var bajo_interfaz: Array = []
	for k in claves:
		var rr: Rect2 = m.rect_rotulo(rotulos[k])
		if not vista.intersects(rr):
			continue
		var en_pantalla := Rect2(rr.position - vista.position, rr.size)
		for nombre in interfaz:
			if en_pantalla.intersects(interfaz[nombre]):
				bajo_interfaz.append("%s bajo %s" % [m.lugares[k]["nombre"], nombre])
	if bajo_interfaz.is_empty():
		_ok("al abrir el mapa, ningún rótulo queda bajo la interfaz (%s)" % ", ".join(interfaz.keys()))
	else:
		_fallo("al abrir el mapa: %s" % "; ".join(bajo_interfaz))
	# Kael al abrir el mapa (55 px bajo Oakhaven) no tapa ningún rótulo
	var rk := _rect_kael(m, inicio)
	var tapados: Array = []
	for k in claves:
		if rk.intersects(m.rect_rotulo(rotulos[k])):
			tapados.append(m.lugares[k]["nombre"])
	if tapados.is_empty():
		_ok("al abrir el mapa, Kael (%s) no tapa ningún rótulo (Oakhaven a %.0f px por encima de su cabeza)" % [rk,
			rk.position.y - m.rect_rotulo(rotulos[0]).end.y])
	else:
		_fallo("al abrir el mapa, Kael tapa: %s" % ", ".join(tapados))


# El mapa de siempre: sus rótulos también van por encima de Kael.
func _comprobar_clasico(m) -> void:
	var n := 0
	var bajo := 0
	for c in m.get_children():
		if c is Node2D and c != m.jugador:
			for e in c.get_children():
				if e is Label and e.text in m.lugares.map(func(l): return l["nombre"]):
					n += 1
					if e.z_index <= 0:
						bajo += 1
	if n == m.lugares.size() and bajo == 0:
		_ok("mapa de siempre: los %d rótulos van por encima de Kael (al abrir, ya no tapa «Oakhaven»)" % n)
	else:
		_fallo("mapa de siempre: %d rótulos, %d por debajo de Kael" % [n, bajo])


# Rectángulo de lo dibujado de Kael (alfa > ALFA del fotograma actual) con los pies en `pie`.
func _rect_kael(m, pie: Vector2) -> Rect2:
	var s: AnimatedSprite2D = m.sprite
	var img := _imagen(s.sprite_frames.get_frame_texture(s.animation, s.frame))
	if img == null:
		_fallo("no se puede leer el fotograma de Kael")
		return Rect2()
	var x0 := img.get_width()
	var y0 := img.get_height()
	var x1 := 0
	var y1 := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > ALFA:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x + 1)
				y1 = maxi(y1, y + 1)
	return Rect2(pie + s.offset + Vector2(x0, y0), Vector2(x1 - x0, y1 - y0))


func _alfa_icono(m, imgs: Dictionary, i: int, w: Vector2) -> float:
	var ri: Rect2 = m.rect_icono(i)
	if not ri.has_point(w):
		return 0.0
	var img: Image = imgs[i]
	var u := (w - ri.position) / ri.size * Vector2(img.get_size())
	return img.get_pixel(clampi(int(u.x), 0, img.get_width() - 1), clampi(int(u.y), 0, img.get_height() - 1)).a


func _pixeles_icono(m, imgs: Dictionary, i: int, r: Rect2) -> int:
	var inter: Rect2 = m.rect_icono(i).intersection(r)
	if inter.size == Vector2.ZERO:
		return 0
	var n := 0
	for y in range(int(inter.position.y), int(ceil(inter.end.y))):
		for x in range(int(inter.position.x), int(ceil(inter.end.x))):
			if _alfa_icono(m, imgs, i, Vector2(x + 0.5, y + 0.5)) > ALFA:
				n += 1
	return n


static func _dist_rect(p: Vector2, r: Rect2) -> float:
	var c := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return p.distance_to(c)


# ---------------------------------------------------------------- 8. la opción de ajustes.cfg

func _comprobar_opcion() -> void:
	var ruta: String = A.AJUSTES
	var habia := FileAccess.file_exists(ruta)
	var original := FileAccess.get_file_as_bytes(ruta) if habia else PackedByteArray()
	# lo de sonido.gd (el volumen), si no estaba, para comprobar que no se toca
	var c := ConfigFile.new()
	if habia:
		c.load(ruta)
	if not c.has_section("volumen"):
		c.set_value("volumen", "Musica", 80)
		c.save(ruta)
	var volumen := _seccion(ruta, "volumen")

	var err: Error = A.elegir("clasico", true)
	var m = await _abrir_mapa()
	if m != null:
		if experimental:
			if err == OK and not m.arte_activo() and m.terreno_tex != null:
				_ok("versión experimental: [mapa] clasico=true en ajustes.cfg abre el mapa de siempre, sin argumentos")
			else:
				_fallo("versión experimental: [mapa] clasico=true no elige el mapa de siempre (error %d, pintado %s)" % [err, m.arte_activo()])
		elif m.arte_activo():
			_ok("fuera de la versión experimental, [mapa] clasico=true no cuenta: el mapa pintado sigue")
		else:
			_fallo("fuera de la versión experimental, la opción de ajustes.cfg ha cambiado el mapa")
	var antes_abrir := FileAccess.get_file_as_bytes(ruta)
	m = await _abrir_mapa()
	if FileAccess.get_file_as_bytes(ruta) == antes_abrir:
		_ok("abrir el mapa no escribe user://ajustes.cfg")
	else:
		_fallo("abrir el mapa ha escrito user://ajustes.cfg")
	A.elegir("clasico", false)
	var c2 := ConfigFile.new()
	c2.load(ruta)
	if not c2.has_section_key("mapa", "clasico") and _seccion(ruta, "volumen") == volumen:
		_ok("elegir(\"clasico\", false) quita la opción y deja el volumen como estaba")
	else:
		_fallo("elegir(\"clasico\", false): opción %s, volumen %s → %s" % [c2.has_section_key("mapa", "clasico"), volumen, _seccion(ruta, "volumen")])
	m = await _abrir_mapa()
	if m != null and not m.arte_activo():
		_fallo("sin la opción, el mapa pintado no vuelve")
	A.elegir("agua_quieta", true)
	m = await _abrir_mapa()
	if m != null:
		var fondo: Sprite2D = null
		for ch in m.get_children():
			if ch is Sprite2D:
				fondo = ch
				break
		var quieta: bool = fondo != null and fondo.material == null
		if experimental:
			if m.arte_activo() and quieta:
				_ok("versión experimental: [mapa] agua_quieta=true quita el agua animada (el mapa pintado sigue)")
			else:
				_fallo("versión experimental: [mapa] agua_quieta=true no quita el agua animada")
		elif not quieta:
			_ok("fuera de la versión experimental, [mapa] agua_quieta=true no cuenta")
		else:
			_fallo("fuera de la versión experimental, la opción ha quitado el agua animada")
	A.elegir("agua_quieta", false)
	# todo como estaba
	if habia:
		var f := FileAccess.open(ruta, FileAccess.WRITE)
		f.store_buffer(original)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	var igual := FileAccess.file_exists(ruta) == habia and (not habia or FileAccess.get_file_as_bytes(ruta) == original)
	if igual:
		_ok("user://ajustes.cfg queda como estaba (%s)" % ("restaurado byte a byte" if habia else "no existía: borrado"))
	else:
		_fallo("user://ajustes.cfg no ha quedado como estaba")


func _seccion(ruta: String, s: String) -> Dictionary:
	var c := ConfigFile.new()
	c.load(ruta)
	var d := {}
	if c.has_section(s):
		for k in c.get_section_keys(s):
			d[k] = c.get_value(s, k)
	return d


# ---------------------------------------------------------------- utilidades

# Campo de la costa en q (px del mundo): costa_datos guarda R = 0,5 + 2·v en una rejilla de 2 px (centros en 2i+1).
func _campo(img: Image, q: Vector2) -> float:
	var u := q / 2.0 - Vector2(0.5, 0.5)
	var x0 := clampi(int(floor(u.x)), 0, img.get_width() - 1)
	var y0 := clampi(int(floor(u.y)), 0, img.get_height() - 1)
	var x1 := mini(x0 + 1, img.get_width() - 1)
	var y1 := mini(y0 + 1, img.get_height() - 1)
	var fx := clampf(u.x - floor(u.x), 0.0, 1.0)
	var fy := clampf(u.y - floor(u.y), 0.0, 1.0)
	var a := lerpf(img.get_pixel(x0, y0).r, img.get_pixel(x1, y0).r, fx)
	var b := lerpf(img.get_pixel(x0, y1).r, img.get_pixel(x1, y1).r, fx)
	return lerpf(a, b, fy) - 0.5


# Distancia (px) desde q al punto más cercano donde el dibujo cambia de tierra a mar (o al revés), hasta 8 px.
func _dist_costa(img: Image, q: Vector2, dibujo: bool) -> float:
	var mejor := 99.0
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			var d := Vector2(dx, dy).length()
			if d >= mejor or d > 8.0:
				continue
			if (_campo(img, q + Vector2(dx, dy)) >= 0.0) != dibujo:
				mejor = d
	return mejor


# Píxeles distintos entre dos máscaras: el alfa en todos; el color solo en la tierra (el color del mar no se usa).
func _diferencias(a: Image, b: Image) -> int:
	if a.get_size() != b.get_size():
		return a.get_width() * a.get_height()
	var n := 0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if (ca.a > 0.5) != (cb.a > 0.5) or (ca.a > 0.5 and ca != cb):
				n += 1
	return n


func _fin() -> void:
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
