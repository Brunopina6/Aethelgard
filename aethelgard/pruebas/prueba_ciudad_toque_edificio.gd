extends SceneTree
# V12 (19/11, PC-16; Redmi: docs/v12/REDMI_18_11.md problema 2, «t03_plaza_4/5», «t03_plaza_7/8», «t04_este_3…10»;
# RECORRIDO.md §12): al TOCAR SOBRE UN EDIFICIO de la ciudad, Kael andaba hasta la pared y se quedaba pegado. El rayo del
# toque atravesaba la casa (lo alto no cuenta como suelo) y caía en el suelo de detrás (a veces a 30-40 m); la recta se
# cortaba en la pared, lejos de lo tocado.
# Sin ventana (viewport 1280×720), en la escena de la ciudad (banco, perfil bajo), con los choques montados y con
# TOQUES DE VERDAD (InputEventMouseButton en la pantalla, por ciudad._unhandled_input → _punto_suelo → _ajustar_destino):
#   1. TOCAR LA CASA (lo que se arregla): en casas de varios sectores (no ocultables, sin aclarar), Kael a 1 m de una
#      fachada y el toque en un punto de su TEJADO que se ve desde la cámara. La referencia la calcula la prueba aparte
#      (rejilla de 0,25 m por lo andable y holgado, escalones ≤ 0,3 m, como prueba_ciudad_plano): el punto andable más
#      cercano a lo tocado al que se llega con un rodeo de ≤ 6 m más que la recta. Se eligen los casos en que la recta
#      del toque de antes deja a Kael al menos 1,5 m más lejos de lo tocado que esa referencia. Kael ha de acabar a ≤ 0,6 m
#      más que la referencia, sin pisar lo no andable y sin salirse del suelo. (Sin el arreglo: pegado a la pared.)
#      Dos son los sitios del Redmi: la tienda al este de la plaza (Calle del Mercado) y la casa alta del oeste.
#   2. AL OTRO LADO (GUION_REDMI_19_11 punto 1): Kael a un lado de una casa o un muro y el toque en el suelo al otro
#      lado, cruzándolo de cara a cara (más de 3 m dentro: no es una esquina; directo a _ajustar_destino, como en
#      prueba_ciudad_esquinas, porque el suelo de detrás de una casa casi nunca se ve desde la cámara): con un rodeo corto
#      (referencia ≤ 6 m de más) Kael la rodea y llega (< 0,6 m); sin él, no la atraviesa y no acaba más lejos del toque
#      que antes (+1 m: antes se paraba algo antes del último punto andable de la recta, por el cuerpo y las rodillas).
#      Hoy (19/11) ningún caso de los 8 sectores tiene rodeo de ≤ 6 m: con el arreglo Kael se acerca rodeándola hasta
#      donde llega el rodeo corto (ciudad.RODEO_EXTRA) o se queda de su lado.
#   3. SUELO LIBRE (guarda): un toque en el suelo con la recta libre da el mismo destino que antes (el punto tocado).
#   4. COSTE: cuánto tarda cada toque con rodeo en el PC (≤ 60 ms; en el Redmi, sin medir).
#   (y 5. ARRASTRE: arrastrar sobre lo tocado sigue con el mismo rodeo, sin rehacerlo.)
# Imprime «FALLOS: n».

const ESCENA := "res://zonas3d/ciudad/ciudad.tscn"
const P := preload("res://zonas3d/ciudad/plano.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const C := 0.25
const RODEO_REF := 6.0
const POR_SECTOR := 2
const TAM := Vector2(1280, 720)
var fallos := 0
var v
var ms_max := 0.0


func _initialize() -> void:
	_correr.call_deferred()


func _ok(cond: bool, t: String) -> void:
	if cond:
		print("OK " + t)
	else:
		fallos += 1
		print("FALLO: " + t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _libre(q: Vector2) -> bool:
	return P.andable(q.x, q.y) and P.holgado(q.x, q.y)


# Referencia: Dijkstra por la rejilla de 0,25 m desde «s» (8 vecinas; en diagonal solo con las dos de los lados libres;
# escalón ≤ 0,3 m), hasta un camino de «hasta» m. Devuelve {casilla: [largo, cota]}.
func _alcance(s: Vector3, hasta: float) -> Dictionary:
	var ini := Vector2i(roundi(s.x / C), roundi(s.z / C))
	var r := {}
	var libres := {}
	var abiertos := [[0.0, ini]]
	var largo := {ini: 0.0}
	var cerrados := {}
	var es_libre := func(c: Vector2i) -> bool:
		if not libres.has(c):
			libres[c] = _libre(Vector2(c) * C)
		return libres[c]
	while not abiertos.is_empty():
		var e: Array = _sacar(abiertos)
		var c: Vector2i = e[1]
		if cerrados.has(c):
			continue
		cerrados[c] = true
		var hc := P.altura(c.x * C, c.y * C)
		r[c] = [float(e[0]), hc]
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1),
				Vector2i(-1, 1), Vector2i(-1, -1)]:
			var n: Vector2i = c + d
			if cerrados.has(n) or not es_libre.call(n):
				continue
			if d.x != 0 and d.y != 0 and not (es_libre.call(c + Vector2i(d.x, 0)) and es_libre.call(c + Vector2i(0, d.y))):
				continue
			if absf(P.altura(n.x * C, n.y * C) - hc) > 0.3:
				continue
			var l: float = e[0] + C * Vector2(d).length()
			if l <= hasta and l < largo.get(n, INF):
				largo[n] = l
				_meter(abiertos, [l, n])
	return r


func _meter(h: Array, e: Array) -> void:
	h.append(e)
	var i := h.size() - 1
	while i > 0 and h[(i - 1) / 2][0] > e[0]:
		h[i] = h[(i - 1) / 2]
		i = (i - 1) / 2
	h[i] = e


func _sacar(h: Array) -> Array:
	var cima: Array = h[0]
	var e: Array = h.pop_back()
	if h.is_empty():
		return cima
	var i := 0
	while 2 * i + 1 < h.size():
		var j := 2 * i + 1
		if j + 1 < h.size() and h[j + 1][0] < h[j][0]:
			j += 1
		if h[j][0] >= e[0]:
			break
		h[i] = h[j]
		i = j
	h[i] = e
	return cima


# El punto alcanzado más cercano a «m» con un rodeo ≤ «rodeo»: [distancia a m, punto].
func _referencia(alc: Dictionary, s: Vector3, m: Vector2, rodeo := RODEO_REF) -> Array:
	var mejor := [INF, null]
	for c in alc:
		var q := Vector2(c) * C
		if float(alc[c][0]) - q.distance_to(Vector2(s.x, s.z)) > rodeo:
			continue
		var d := q.distance_to(m)
		if d < mejor[0]:
			mejor = [d, Vector3(q.x, alc[c][1], q.y)]
	return mejor


# El último punto andable de la recta de a a b (cada 0,1 m): lo que hacía la recta de antes.
func _fin_recto(a: Vector3, b: Vector3) -> Vector2:
	var pa := Vector2(a.x, a.z)
	var pb := Vector2(b.x, b.z)
	var ultimo := pa
	var n := int(ceil(pa.distance_to(pb) / 0.1))
	for i in range(1, n + 1):
		var q := pa.lerp(pb, float(i) / n)
		if not P.andable(q.x, q.y):
			break
		ultimo = q
	return ultimo


func _pantalla_ok(t: Vector2) -> bool:
	return t.x > 20 and t.y > 20 and t.x < TAM.x - 20 and t.y < TAM.y - 20 and not (t.x < 400 and t.y < 220) \
		and not (t.x > 1200 and t.y < 80)


# Lo primero que da el rayo de la cámara por el píxel t: [punto, nombre del cuerpo] o [].
func _primer_choque(t: Vector2) -> Array:
	var desde: Vector3 = v.cam.project_ray_origin(t)
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(desde, desde + v.cam.project_ray_normal(t) * 500.0))
	return [] if r.is_empty() else [r["position"], String((r["collider"] as Node).name)]


func _tocar(t: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = t
	var t0 := Time.get_ticks_usec()
	v._unhandled_input(ev)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	ms_max = maxf(ms_max, ms)
	var r = v.get("ultimo_rodeo")
	if r is Dictionary and r.has("ms"):
		print("   (toque: %.1f ms; rodeo: %.1f ms, %d casillas, %d puntos de paso)" % [ms, r["ms"], r["nodos"],
			(r["puntos"] as Array).size()])
		r.clear()


# Anda hasta que Kael se para; vigila cada fotograma lo que pisa. {k, mal}
func _andar() -> Dictionary:
	var mal: Array = []
	var quieto := 0
	var anterior: Vector3 = v.kael.global_position
	for f in 900:
		await process_frame
		var k: Vector3 = v.kael.global_position
		if not P.andable(k.x, k.z):
			mal.append("no andable en (%.2f, %.2f)" % [k.x, k.z])
		elif absf(k.y - P.altura(k.x, k.z)) > 0.15:
			mal.append("fuera del suelo en (%.2f, %.2f)" % [k.x, k.z])
		quieto = quieto + 1 if k.distance_to(anterior) < 0.0005 else 0
		anterior = k
		if v.destino == null and quieto >= 10:
			break
	var k: Vector3 = v.kael.global_position
	v._parar_kael()
	await _frames(2)
	return {"k": k, "mal": mal}


# Kael a un lado de la casa y el toque en el suelo al otro lado (de oeste a este, de este a oeste, de norte a sur o de sur
# a norte; a 0,8, 1,5 o 3 m de cada cara, en 3/10, 1/2 o 7/10 de la cara), con la recta cruzando la casa más de 3 m (no
# una esquina) y el suelo llano y holgado en los dos sitios. El suelo de detrás de una casa casi nunca se ve desde la
# cámara: este toque va derecho a _ajustar_destino (como en prueba_ciudad_esquinas). [salida, toque] o [].
func _par_otro_lado(rect: Rect2, sec: String) -> Array:
	for eje in [0, 1]:
		for lado in [1.0, -1.0]:
			for fuera in [0.8, 1.5, 3.0, 5.0]:
				for f in [[0.5, 0.5], [0.3, 0.7], [0.7, 0.3], [0.15, 0.85], [0.85, 0.15]]:
					var s: Vector2
					var g: Vector2
					if eje == 0:
						var sz := lerpf(rect.position.y, rect.end.y, f[0])
						var gz := lerpf(rect.position.y, rect.end.y, f[1])
						s = Vector2(rect.position.x - fuera if lado > 0 else rect.end.x + fuera, sz)
						g = Vector2(rect.end.x + fuera if lado > 0 else rect.position.x - fuera, gz)
					else:
						var sx := lerpf(rect.position.x, rect.end.x, f[0])
						var gx := lerpf(rect.position.x, rect.end.x, f[1])
						s = Vector2(sx, rect.position.y - fuera if lado > 0 else rect.end.y + fuera)
						g = Vector2(gx, rect.end.y + fuera if lado > 0 else rect.position.y - fuera)
					if not (_libre(s) and _libre(g) and P.sector_de(s.x, s.y) == sec):
						continue
					if absf(P.altura(s.x, s.y) - P.altura(g.x, g.y)) > 0.05:
						continue
					var dentro := 0
					for i in 101:
						if rect.has_point(s.lerp(g, i / 100.0)):
							dentro += 1
					if dentro * s.distance_to(g) / 100.0 < 3.0:
						continue
					return [Vector3(s.x, P.altura(s.x, s.y), s.y), Vector3(g.x, P.altura(g.x, g.y), g.y)]
	return []


# ¿Kael sigue del lado de la casa del que salió?
func _su_lado(k: Vector3, s: Vector3, rect: Rect2) -> bool:
	if s.x < rect.position.x:
		return k.x < rect.position.x
	if s.x > rect.end.x:
		return k.x > rect.end.x
	return k.z < rect.position.y if s.z < rect.position.y else k.z > rect.end.y


func _colocar(s: Vector3) -> void:
	v._colocar_kael(s)
	await _frames(6)
	v.cargador.actualizar(s, true)
	var sec = v.cargador.montados.get(P.sector_de(s.x, s.z))
	if sec != null and sec.has_method("terminar_choques"):
		sec.terminar_choques()
	await _frames(2)


func _casas(s: String) -> Array:
	var t = P.trazado(s)
	var r: Array = []
	for b in t.BLOQUES:
		var rect: Rect2 = b[2]
		if b[6] and String(b[5]) == "casa" and float(b[4]) >= 3.0 and not (String(b[0]) in t.OCULTABLES) \
				and minf(rect.size.x, rect.size.y) >= 2.5:
			r.append(b)
	return r


# Sitios de salida junto a las fachadas de la casa: a 1 m de cada cara, en 1/5, 1/2 y 4/5 de su largo.
func _salidas(b: Array, s: String) -> Array:
	var rect: Rect2 = b[2]
	var r: Array = []
	for f in [0.2, 0.5, 0.8]:
		for q in [Vector2(rect.position.x - 1.0, lerpf(rect.position.y, rect.end.y, f)),
				Vector2(rect.end.x + 1.0, lerpf(rect.position.y, rect.end.y, f)),
				Vector2(lerpf(rect.position.x, rect.end.x, f), rect.position.y - 1.0),
				Vector2(lerpf(rect.position.x, rect.end.x, f), rect.end.y + 1.0)]:
			if _libre(q) and P.sector_de(q.x, q.y) == s:
				r.append(Vector3(q.x, P.altura(q.x, q.y), q.y))
	return r


# Caso 1 en una casa desde «s»: un punto de su tejado que se vea (el primer choque del rayo es la casa) y, con
# «exigir», que la recta de antes deje a Kael al menos 1,5 m más lejos de lo tocado que la referencia. Con «pasos»
# fracciones del tejado, se queda con el de más diferencia. [pantalla, lo tocado, referencia, lo de antes] o [].
func _caso_tejado(b: Array, s: Vector3, fracciones: Array, exigir: bool) -> Array:
	var rect: Rect2 = b[2]
	var techo := float(b[3]) + float(b[4])
	var alc := {}
	var mejor: Array = []
	for fz in fracciones:
		for fx in fracciones:
			var r := Vector3(lerpf(rect.position.x, rect.end.x, fx), techo, lerpf(rect.position.y, rect.end.y, fz))
			if v.cam.is_position_behind(r):
				continue
			var t: Vector2 = v.cam.unproject_position(r)
			if not _pantalla_ok(t):
				continue
			var ch := _primer_choque(t)
			if ch.is_empty() or ch[1] != "Choque_" + String(b[0]):
				continue
			var hit: Vector3 = ch[0]
			var m := Vector2(clampf(hit.x, rect.position.x, rect.end.x), clampf(hit.z, rect.position.y, rect.end.y))
			var suelo = v._punto_suelo(t)
			if suelo == null:
				continue
			var antes := _fin_recto(s, suelo).distance_to(m)
			if alc.is_empty():
				alc = _alcance(s, s.distance_to(Vector3(m.x, s.y, m.y)) + 16.0)
			var ref := _referencia(alc, s, m)
			if ref[1] == null or (exigir and ref[0] + 1.5 > antes):
				continue
			if mejor.is_empty() or antes - float(ref[0]) > float(mejor[3]) - float(mejor[2][0]):
				mejor = [t, m, ref, antes]
			if exigir:
				return mejor
	return mejor


func _correr() -> void:
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()
	BP.poner_grupo(BP.EXPLORAR["ciudad"]["activos"])
	Engine.set_meta("calidad_proto", "bajo")
	root.size = Vector2i(TAM)
	change_scene_to_file(ESCENA)
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
			v = current_scene
			break
	await _frames(10)
	_ok(v != null, "la escena de la ciudad carga en el banco")
	if v == null:
		print("FALLOS: %d" % fallos)
		quit(1)
		return
	_ok(v.cam.get_viewport().get_visible_rect().size == TAM, "la pantalla es de 1280×720")

	# ---- 1. tocar la casa
	var casos: Array = []
	# los dos sitios del Redmi: junto a la puerta de la tienda, al este de la plaza (t04_este_6: Kael pegado a su cara
	# oeste, tocando su tejado), y junto a la cara este de la casa alta del oeste (t03_plaza_4). El punto del tejado, el
	# de más diferencia con la recta de antes (puede no haberla: entonces son guardas). Después, casas de cada sector.
	var finas: Array = []
	for i in 10:
		finas.append(0.05 + 0.1 * i)
	var fijos := [["plaza_tapiz", "tienda", Vector3(15.6, 0.0, -5.0)], ["plaza_tapiz", "casa_o_alta", Vector3(-16.0, 0.0, -3.0)]]
	var redmi := 0
	for f in fijos:
		for b in P.trazado(f[0]).BLOQUES:
			if b[0] == f[1]:
				var s: Vector3 = f[2]
				s.y = P.altura(s.x, s.z)
				await _colocar(s)
				var c := _caso_tejado(b, s, finas, false)
				if not c.is_empty():
					casos.append(["%s/%s (sitio del Redmi%s)" % [f[0], f[1], "" if c[3] - c[2][0] >= 1.5 else "; guarda"], s, c])
					redmi += 1
	_ok(redmi == 2, "los dos sitios del Redmi tienen un punto del tejado que se ve (%d)" % redmi)
	var sectores := {}
	for sec in P.ORDEN:
		var n := 0
		for b in _casas(sec):
			if n >= POR_SECTOR:
				break
			for s in _salidas(b, sec):
				await _colocar(s)
				var c := _caso_tejado(b, s, [0.15, 0.5, 0.85], true)
				if not c.is_empty():
					casos.append(["%s/%s" % [sec, b[0]], s, c])
					sectores[sec] = true
					n += 1
					break
	_ok(casos.size() >= 6 and sectores.size() >= 3, "hay casos de tocar una casa: %d en %d sectores %s" % [
		casos.size(), sectores.size(), str(sectores.keys())])
	var arrastre := false
	for caso in casos:
		var s: Vector3 = caso[1]
		var t: Vector2 = caso[2][0]
		var m: Vector2 = caso[2][1]
		var ref: Array = caso[2][2]
		await _colocar(s)
		_tocar(t)
		if not arrastre and v.get("_ruta") is Array and not (v.get("_ruta") as Array).is_empty():
			# arrastrar el dedo (o el ratón con el botón) sobre el mismo sitio no rehace ni pierde el rodeo en curso
			arrastre = true
			var d0 = v.destino
			var ruta0: Array = (v.get("_ruta") as Array).duplicate()
			var mov := InputEventMouseMotion.new()
			mov.button_mask = MOUSE_BUTTON_MASK_LEFT
			mov.position = t + Vector2(2, 1)
			v._unhandled_input(mov)
			_ok(v.destino == d0 and v.get("_ruta") == ruta0, "%s: arrastrar sobre lo tocado sigue con el mismo rodeo (%d puntos de paso)" % [
				caso[0], ruta0.size() + 1])
		var r := await _andar()
		var k: Vector3 = r["k"]
		var d := Vector2(k.x, k.z).distance_to(m)
		_ok(d <= float(ref[0]) + 0.6 and (r["mal"] as Array).is_empty(),
			"%s: desde (%.1f, %.1f), toque en el tejado sobre (%.1f, %.1f): Kael acaba en (%.2f, %.2f), a %.2f m de lo tocado (referencia %.2f en (%.2f, %.2f); la recta de antes, %.2f) %s" % [
				caso[0], s.x, s.z, m.x, m.y, k.x, k.z, d, ref[0], ref[1].x, ref[1].z, caso[2][3],
				str((r["mal"] as Array).slice(0, 3))])

	# ---- 2. al otro lado de una casa (guarda)
	var otros := 0
	for sec in P.ORDEN:
		var n_sec := 0
		for b in P.trazado(sec).BLOQUES:
			if otros >= 8 or n_sec >= 2:
				break
			var rect: Rect2 = b[2]
			if not (b[6] and String(b[5]) in ["casa", "muro"] and float(b[4]) >= 3.0 and minf(rect.size.x, rect.size.y) >= 2.5):
				continue
			var par := _par_otro_lado(rect, sec)
			if par.is_empty():
				continue
			var s3: Vector3 = par[0]
			var g3: Vector3 = par[1]
			var g := Vector2(g3.x, g3.z)
			await _colocar(s3)
			var alc := _alcance(s3, s3.distance_to(g3) + 16.0)
			var ref := _referencia(alc, s3, g)
			var ref_largo := _referencia(alc, s3, g, 10.0)
			var antes := _fin_recto(s3, g3).distance_to(g)
			v.set("_toque_edificio", null)
			v.destino = v._ajustar_destino(g3)
			var r := await _andar()
			var k: Vector3 = r["k"]
			var d := Vector2(k.x, k.z).distance_to(g)
			var limpio := (r["mal"] as Array).is_empty()
			if ref[1] != null and float(ref[0]) < 0.5:
				_ok(d < 0.6 and limpio, "%s/%s al otro lado, con rodeo corto: Kael la rodea y acaba a %.2f m del toque (< 0,6) %s" % [
					sec, b[0], d, str((r["mal"] as Array).slice(0, 3))])
			else:
				_ok(d <= antes + 1.0 and limpio,
					"%s/%s al otro lado, sin rodeo de ≤ 6 m (%s): no la atraviesa y acaba en (%.2f, %.2f), %s, a %.2f m del toque (antes %.2f) %s" % [
						sec, b[0], "con uno de ≤ 10 m" if ref_largo[1] != null and float(ref_largo[0]) < 0.5 else "ni de ≤ 10 m",
						k.x, k.z, "de su lado" if _su_lado(k, s3, rect) else "rodeándola", d, antes,
						str((r["mal"] as Array).slice(0, 3))])
			otros += 1
			n_sec += 1
	_ok(otros >= 3, "hay casas con suelo a los dos lados para tocar al otro lado (%d)" % otros)

	# ---- 3. suelo libre (guarda): el destino es el toque
	var libres := 0
	for sec in ["plaza_tapiz", "barrio_alto", "oficios", "cuervo"]:
		var a: Vector3 = P.ancla(P.SECTORES[sec]["ref"])
		await _colocar(a)
		for off in [Vector3(2.0, 0.0, -3.0), Vector3(-2.5, 0.0, 1.5), Vector3(0.0, 0.0, -4.0)]:
			var q: Vector3 = a + off
			if not _libre(Vector2(q.x, q.z)):
				continue
			q.y = P.altura(q.x, q.z)
			var t: Vector2 = v.cam.unproject_position(q)
			var suelo = v._punto_suelo(t)
			if suelo == null or Vector2(suelo.x, suelo.z).distance_to(Vector2(q.x, q.z)) > 0.3 \
					or _fin_recto(a, suelo).distance_to(Vector2(suelo.x, suelo.z)) > 0.15:
				continue
			_tocar(t)
			var d = v.destino
			_ok(d != null and Vector2(d.x - suelo.x, d.z - suelo.z).length() < 0.05,
				"%s: toque en suelo libre en (%.1f, %.1f): el destino es el toque (%s)" % [sec, suelo.x, suelo.z, str(d)])
			v._parar_kael()
			libres += 1
	_ok(libres >= 4, "hay toques en suelo libre (%d)" % libres)

	# ---- 4. coste
	_ok(ms_max <= 60.0, "el toque más caro tarda %.1f ms en el PC (≤ 60)" % ms_max)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
