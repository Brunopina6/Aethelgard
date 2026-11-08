extends SceneTree
# Prueba del mapamundi pintado (T-085): lo dibujado coincide con lo que usa el juego y no cambia nada funcional.
#   Godot --headless --path aethelgard --script res://pruebas/prueba_mapamundi.gd --fixed-fps 30 -- sin_prologo
#   (con «mapa_clasico» comprueba que el prototipo vuelve al mapa de siempre)
# 1. réplica: datos_mapa.gd reproduce la máscara de tierra y zonas de mapa.gd (_generar_terreno), píxel a píxel;
# 2. máscara horneada: mapa_arte/mapa_zonas.png es idéntica a la que genera mapa.gd;
# 3. alineación: datos_mapa.tierra_juego(q) da lo mismo que mapa.gd._es_tierra(q) (cada 3 px en x, cada px en y);
# 4. costa dibujada: la tierra y el mar del dibujo (costa_datos.png, el campo con el que se pinta la costa)
#    coinciden con _es_tierra salvo junto a la costa: ningún desacuerdo a más de 4 px de la línea dibujada;
# 5. el prototipo (mapa_arte/prototipo_mapa.tscn) conserva lugares, posiciones, rutas, islas y radio de «Entrar»,
#    usa la misma máscara, y dibuja cada icono y cada rótulo en la posición de su lugar;
# 6. «Entrar»: Kael en cada lugar lo tiene cerca; a RADIO_LUGAR + 6 px, no.
# Termina con «FALLOS: n» y código 1 si algo no cuadra.

const PROTOTIPO := "res://mapa_arte/prototipo_mapa.tscn"
const TOLERANCIA_COSTA := 4.0

var fallos := 0
var M
var D


func _initialize() -> void:
	_probar.call_deferred()


func _ok(t: String) -> void:
	print("OK ", t)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _probar() -> void:
	var clasico := "mapa_clasico" in OS.get_cmdline_user_args()
	M = load("res://mapa.gd")
	D = load("res://mapa_arte/datos_mapa.gd").new()
	var gen = M.new()
	var t0 := Time.get_ticks_msec()
	gen._generar_terreno()
	print("INFO _generar_terreno de mapa.gd: %d ms (indicativo)" % (Time.get_ticks_msec() - t0))
	var mascara: Image = gen.zonas_img

	# 1. réplica exacta
	var rep := Image.create(600, 337, false, Image.FORMAT_RGBA8)
	for y in 337:
		for x in 600:
			var p := Vector2(x, y) * 4.0
			if D.campo_v(p) < 0.0:
				continue
			var zc: Color = M.ZONAS[D.ZONAS_ORDEN[D.zona_en(p)]]
			rep.set_pixel(x, y, Color(zc.r, zc.g, zc.b, 1.0))
	rep.resize(1200, 675, Image.INTERPOLATE_NEAREST)
	var dif := _diferencias(rep, mascara)
	if dif == 0:
		_ok("réplica: datos_mapa.gd da la misma máscara que mapa.gd (1200×675, 0 píxeles distintos)")
	else:
		_fallo("réplica: %d píxeles distintos" % dif)

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
			_fallo("máscara horneada: %d píxeles distintos" % dif)

	# 3. alineación exacta del campo con el juego
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
		for y in range(0, 1350, 2):
			for x in range(0, 2400, 2):
				var q := Vector2(x + 0.5, y + 0.5)
				n += 1
				var dibujo := _campo(costa, q) >= 0.0
				if dibujo == gen._es_tierra(q):
					continue
				desacuerdos += 1
				var d := _dist_costa(costa, q, dibujo)
				peor = maxf(peor, d)
				hist[mini(int(d), 4)] += 1
		var pct := 100.0 * desacuerdos / n
		print("INFO costa: %d de %d puntos (%.2f %%) con dibujo y juego en desacuerdo; distancia a la línea dibujada: <1 px %d, 1-2 %d, 2-3 %d, 3-4 %d, ≥4 %d; la peor %.1f px"
			% [desacuerdos, n, pct, hist[0], hist[1], hist[2], hist[3], hist[4], peor])
		if peor <= TOLERANCIA_COSTA:
			_ok("costa dibujada: todo desacuerdo está a %.1f px o menos de la línea de costa (tolerancia %.0f px)" % [peor, TOLERANCIA_COSTA])
		else:
			_fallo("costa dibujada: un desacuerdo a %.1f px de la costa (tolerancia %.0f px)" % [peor, TOLERANCIA_COSTA])
	gen.free()

	# 5-6. el prototipo en la escena
	change_scene_to_file(PROTOTIPO)
	for i in 120:
		await process_frame
		if current_scene != null and current_scene.get("jugador") != null:
			break
	var m = current_scene
	if m == null or m.get("jugador") == null:
		_fallo("no se abrió " + PROTOTIPO)
		_fin()
		return
	await process_frame
	if clasico:
		if m.arte_activo() or m.terreno_tex == null:
			_fallo("con «mapa_clasico» el prototipo debería dibujar el mapa de siempre")
		else:
			_ok("con «mapa_clasico» el prototipo dibuja el mapa de siempre (terreno generado por mapa.gd)")
	elif not m.arte_activo():
		_fallo("el arte nuevo no está activo (¿faltan archivos en mapa_arte/?)")
	else:
		_ok("arte nuevo activo; la máscara no se genera al cargar (terreno_tex = %s)" % str(m.terreno_tex))
	if _diferencias(m.zonas_img, mascara) == 0:
		_ok("el prototipo usa la misma máscara de tierra y zonas que mapa.gd")
	else:
		_fallo("el prototipo usa otra máscara")
	var esperados: Array = M.LUGARES + ([M.LUGAR_PASTOS] if load("res://modo3d.gd").activo() else [])
	var iguales: bool = m.lugares.size() == esperados.size()
	for i in mini(m.lugares.size(), esperados.size()):
		iguales = iguales and m.lugares[i] == esperados[i]
	if iguales and m.RUTAS == M.RUTAS and m.ISLAS == M.ISLAS and m.RADIO_LUGAR == M.RADIO_LUGAR and m.MAPA_TAM == M.MAPA_TAM:
		_ok("lugares (%d), nombres, tipos, posiciones, rutas, islas, radio de «Entrar» y tamaño, iguales que en mapa.gd" % esperados.size())
	else:
		_fallo("los datos funcionales del prototipo no son los de mapa.gd")
	if not clasico:
		_comprobar_marcas(m)
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
	_fin()


func _comprobar_marcas(m) -> void:
	var I = load("res://mapa_arte/iconos_mapa.gd")
	var etiquetas := {}
	for c in m.marcas_arte.get_children():
		if c is Label:
			etiquetas[c.text] = c
	var bien := 0
	for i in m.lugares.size():
		var l: Dictionary = m.lugares[i]
		var p: Vector2 = l["pos"]
		if not m.iconos.has(i):
			_fallo("sin icono: " + l["nombre"])
			continue
		var e: float = m._escala(l)
		var rect := Rect2(p + Vector2(0, m.ICONO_BAJO) - m.ICONO_ANCLA * e, Vector2(I.TAM) * e)
		var et: Label = etiquetas.get(l["nombre"])
		if et == null:
			_fallo("sin rótulo: " + l["nombre"])
			continue
		var centro := et.position + et.size * 0.5
		if rect.has_point(p) and absf(centro.x - p.x) < 1.0 and absf(centro.y - p.y) < 150.0:
			bien += 1
		else:
			_fallo("icono o rótulo fuera de sitio: %s (icono %s, rótulo %s)" % [l["nombre"], rect, centro])
	if bien == m.lugares.size():
		_ok("cada icono contiene la posición de su lugar y cada rótulo está centrado sobre ella (%d)" % bien)


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
