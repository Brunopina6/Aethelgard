extends "res://pruebas/recorrido_ciudad.gd"
# DIAGNÓSTICO (rama verifica-romper, 16/11): intenta ROMPER la maqueta de la ciudad de Oakhaven con los CONTROLES NORMALES
# (los mismos clics en coordenadas de ventana, teclas y botones que recorrido_ciudad.gd, del que hereda las utilidades y
# las comprobaciones por tramo). No es una prueba de la lista: es una herramienta de verificación.
#   - salidas: Esc, Tab, Retroceso, M, Atrás de Android y empujar con las teclas contra la Puerta del Sur y la muralla;
#     clics al sur de la muralla; el botón de la Puerta del Sur pulsado muchas veces;
#   - toques: en varios sitios, una rejilla de toques sobre toda la pantalla comparada con lo que se VE (el suelo andable
#     del plano y las cajas de los bloques): toques perdidos (se ve suelo y el toque no hace nada), toques que caen lejos
#     de lo que se ve, toques en pretiles, muros y tejados y en la otra cota; los ejemplos se tocan de verdad;
#   - clics rápidos repetidos y arrastre;
#   - teclas en escaleras y pegado a paredes (en diagonal);
#   - «Guardar y recargar» a mitad de escalera, en el borde de las conexiones, bajo cubiertas, andando y dos veces seguidas;
#   - «Volver al banco» y entrar varias veces, CAL y recargas (nodos y objetos, sectores montados);
#   - el cargador (perfil bajo) vigilado en cada fotograma mientras se cruzan los sectores;
#   - «Salir del banco»: que no queda nada de la sesión (prólogo, lugar 103, ciudad_v12).
# Uso (con ventana): Godot --path aethelgard --script res://pruebas/diag_ciudad_romper.gd --fixed-fps 30
#   --resolution 1600x720 -- salida=<carpeta fuera del proyecto> [tam=1600x720] [video=0]

const PASO_PX := 48
const CERCA_VECINO := 4.0

var hall: PackedStringArray = []
var cajas_todas: Array = []                     # [sector, id, AABB]
var vigilar := false
var vig := {"frames": 0, "actual_sin_montar": 0, "exceso": 0, "error": [], "vecino": {}, "ej_vecino": {}}
var max_montados := 0


func _hallazgo(tipo: String, txt: String) -> void:
	var l := "HALLAZGO [%s] %s" % [tipo, txt]
	_nota(l)
	hall.append(l)


func _foto_marca(nombre: String, rojos: Array, amarillos: Array = []) -> String:
	if not con_fotos:
		return ""
	await _frames(2)
	n_foto += 1
	var img := root.get_texture().get_image()
	for par in [[rojos, Color(1, 0, 0)], [amarillos, Color(1, 0.9, 0)]]:
		for pp in par[0]:
			var c := Vector2i(int(pp.x), int(pp.y))
			img.fill_rect(Rect2i(c.x - 9, c.y - 1, 19, 3).intersection(Rect2i(Vector2i.ZERO, img.get_size())), par[1])
			img.fill_rect(Rect2i(c.x - 1, c.y - 9, 3, 19).intersection(Rect2i(Vector2i.ZERO, img.get_size())), par[1])
	var ruta := salida.path_join("%03d_%s.jpg" % [n_foto, _limpio(nombre)])
	img.save_jpg(ruta, 0.9)
	return ruta.get_file()


func _monitores() -> String:
	return "nodos %d, objetos %d, huérfanos %d, recursos %d" % [Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)]


# ================================================================= vigía del cargador (cada fotograma)

func _vigia() -> void:
	if not vigilar or not _vivo():
		return
	var c = v.cargador
	vig["frames"] += 1
	max_montados = maxi(max_montados, c.montados.size())
	if c.actual != "" and not c.montados.has(c.actual):
		vig["actual_sin_montar"] += 1
	if c.montados.size() > c.maximo():
		vig["exceso"] += 1
	for id in c.estado:
		if c.estado[id] == "error" and not id in vig["error"]:
			vig["error"].append(id)
	var k := _kael()
	for id in P.ORDEN:
		if c.montados.has(id) or id == c.actual:
			continue
		if P.distancia_a_sector(id, Vector2(k.x, k.z)) < CERCA_VECINO:
			vig["vecino"][id] = int(vig["vecino"].get(id, 0)) + 1
			if not vig["ej_vecino"].has(id):
				vig["ej_vecino"][id] = "Kael en %s [%s], a %.1f m de la caja de «%s» (montados: %s)" % [_txt(k), c.actual,
					P.distancia_a_sector(id, Vector2(k.x, k.z)), id, ", ".join(c.ids_montados())]


# ================================================================= lo que se VE en un punto de la pantalla

func _preparar_cajas() -> void:
	for s in P.ORDEN:
		for b in P.trazado(s).BLOQUES:
			for c in Comun.cajas_bloque(b):
				cajas_todas.append([s, String(b[0]), c])


# El suelo andable que se ve en pp (el plano), si delante no hay la caja de un bloque: {p, sector} o {bloque}.
func _suelo_visible(pp: Vector2) -> Dictionary:
	var cam: Camera3D = v.cam
	var o := cam.project_ray_origin(pp)
	var d := cam.project_ray_normal(pp)
	var t_b := INF
	var id_b := ""
	for c in _vis:
		var h = (c[2] as AABB).intersects_ray(o, d)
		if h != null:
			var t: float = (h - o).length()
			if t < t_b:
				t_b = t
				id_b = "%s/%s" % [c[0], c[1]]
	var t := 1.0
	while t < minf(t_b, 220.0):
		var p := o + d * t
		if P.sector_en_caja(p.x, p.z) != "" and p.y <= P.altura(p.x, p.z) + 0.02 and P.andable(p.x, p.z):
			return {"p": Vector3(p.x, P.altura(p.x, p.z), p.z), "sector": P.sector_en_caja(p.x, p.z)}
		t += 0.2
	return {"p": null, "bloque": id_b}


var _vis: Array = []


# Las cajas que se VEN ahora: de los sectores montados, todas menos las ocultables aclaradas; de los no montados, las de la
# maqueta lejana (≥ ALTO_LEJANA y sin puertas).
func _cajas_visibles() -> Array:
	var r: Array = []
	for s in P.ORDEN:
		var t = P.trazado(s)
		var m = v.cargador.montados.get(s)
		for b in t.BLOQUES:
			if m != null:
				if Comun.ocultable(b, t.OCULTABLES):
					if m.aclarado(String(b[0])):
						continue
			elif float(b[4]) < v.cargador.ALTO_LEJANA or String(b[5]) == "puerta":
				continue
			for c in Comun.cajas_bloque(b):
				r.append([s, String(b[0]), c])
	return r


func _primer_golpe(pp: Vector2) -> Dictionary:
	var cam: Camera3D = v.cam
	var o := cam.project_ray_origin(pp)
	return v.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(o, o + cam.project_ray_normal(pp) * 500.0))


# ================================================================= escaneo de toques en un sitio

func _escanear(lugar: String) -> void:
	await _segundos(1.2)
	_vis = _cajas_visibles()
	var k := _kael()
	var c = v.cargador
	var perdidos: Array = []
	var desviados: Array = []
	var bordes: Array = []
	var cotas: Array = []
	var total := 0
	var con_suelo := 0
	for py in range(124, 700, PASO_PX):
		for px in range(40, 1260, PASO_PX):
			var pp := Vector2(px, py)
			if not _se_puede_tocar(pp):
				continue
			total += 1
			var e := _suelo_visible(pp)
			var sp = v._punto_suelo(pp)
			if e["p"] != null:
				con_suelo += 1
				var ep: Vector3 = e["p"]
				var alcanzable := _recta_libre(k, ep, true, false)
				if sp == null:
					perdidos.append({"pp": pp, "ep": ep, "s": e["sector"], "montado": c.montados.has(e["sector"]), "recta": alcanzable})
				elif _plana(sp, ep) > 2.0:
					var sd = v._ajustar_destino(sp)
					desviados.append({"pp": pp, "ep": ep, "sp": sp, "sd": sd, "s": e["sector"], "recta": alcanzable})
				elif absf(ep.y - k.y) > 1.0 and _plana(ep, k) < 14.0:
					cotas.append({"pp": pp, "ep": ep, "sd": v._ajustar_destino(sp)})
			var g := _primer_golpe(pp)
			if not g.is_empty() and String((g["collider"] as Node).name).begins_with("Choque_") and _plana(g["position"], k) < 12.0:
				bordes.append({"pp": pp, "que": String((g["collider"] as Node).name), "p": g["position"], "sd": v._ajustar_destino(sp)})
	var sectores_perdidos := {}
	for x in perdidos:
		var clave := "%s(%s)" % [x["s"], "montado" if x["montado"] else "SIN MONTAR"]
		sectores_perdidos[clave] = int(sectores_perdidos.get(clave, 0)) + 1
	var cerca_perdidos := perdidos.filter(func(x): return _plana(x["ep"], k) < 15.0)
	cerca_perdidos.sort_custom(func(a, b): return _plana(a["ep"], k) < _plana(b["ep"], k))
	var foto := await _foto_marca("escaneo_%s" % lugar, perdidos.map(func(x): return x["pp"]), desviados.map(func(x): return x["pp"]))
	_nota("ESCANEO «%s» Kael en %s [%s], montados %s: %d toques, %d con suelo andable a la vista; PERDIDOS %d (a < 15 m: %d; %s), desviados > 2 m %d, otra cota %d, en bloques sólidos %d · foto %s" % [
		lugar, _txt(k), c.actual, ", ".join(c.ids_montados()), total, con_suelo, perdidos.size(), cerca_perdidos.size(),
		str(sectores_perdidos), desviados.size(), cotas.size(), bordes.size(), foto])
	if not cerca_perdidos.is_empty():
		var x: Dictionary = cerca_perdidos[0]
		var pv: Vector2 = x["pp"]
		_hallazgo("toque perdido", "«%s»: Kael en %s; tocar en (%d, %d) del viewport = (%d, %d) de la ventana %s se ve suelo andable de «%s» (%s, a %.1f m, %s, %s) y _punto_suelo da null · foto %s" % [
			lugar, _txt(k), pv.x, pv.y, (root.get_final_transform() * pv).x, (root.get_final_transform() * pv).y, root.size,
			x["s"], _txt(x["ep"]), _plana(x["ep"], k), "sector montado" if x["montado"] else "SECTOR SIN MONTAR (maqueta lejana, sin choques)",
			"en línea recta" if x["recta"] else "no en línea recta", foto])
	for x in desviados.slice(0, 2):
		_nota("  desviado: toque (%d, %d): se ve %s [%s]; la escena toca %s y Kael va a %s%s" % [x["pp"].x, x["pp"].y, _txt(x["ep"]),
			x["s"], _txt(x["sp"]), _txt(x["sd"]) if x["sd"] != null else "—", " (lo visto se alcanza en línea recta)" if x["recta"] else ""])
	# --- de verdad: un toque perdido cercano (Kael no se mueve), un desviado, dos en bloques y uno en otra cota
	if not cerca_perdidos.is_empty():
		await _clic_real(lugar, "perdido", cerca_perdidos[0]["pp"], k, null)
	if not desviados.is_empty():
		await _clic_real(lugar, "desviado", desviados[0]["pp"], k, desviados[0]["ep"])
	var elegidos: Array = []
	for x in bordes:
		var n: String = x["que"]
		if elegidos.size() < 3 and elegidos.filter(func(y): return y["que"] == n).is_empty():
			elegidos.append(x)
	for x in elegidos:
		await _clic_real(lugar, "bloque " + String(x["que"]), x["pp"], k, null)
	if not cotas.is_empty():
		await _clic_real(lugar, "otra cota", cotas[cotas.size() / 2]["pp"], k, cotas[cotas.size() / 2]["ep"])


# Un clic de verdad en pp con Kael en k0 (vuelve antes a k0 si se movió): comprueba lo de siempre (tramo) y adónde llega.
func _clic_real(lugar: String, tipo: String, pp: Vector2, k0: Vector3, visto) -> void:
	if _plana(_kael(), k0) > 0.4:
		await _andar_a(k0, 0.3)
		await _segundos(1.2)
	var prev = v._ajustar_destino(v._punto_suelo(pp))
	_empezar_tramo()
	var ka := _kael()
	var f0 := Engine.get_process_frames()
	await _clic(pp)
	var f := 0
	while f < 300 and v.destino != null:
		await _frames(2)
		f += 2
	await _frames(6)
	var kb := _kael()
	var mal := ""
	var r := {"llega": true, "clics": 1, "segundos": (Engine.get_process_frames() - f0) / FPS}
	var txt := "toque (%d, %d) en «%s»: prevista %s, Kael %s → %s (%.2f m)" % [pp.x, pp.y, lugar, _txt(prev) if prev != null else "nada",
		_txt(ka), _txt(kb), _plana(ka, kb)]
	if visto != null:
		txt += ", se veía %s" % _txt(visto)
	if prev != null and _plana(kb, prev) > 0.6:
		r["falta"] = _plana(kb, prev)
		if _recta_libre(ka, prev, true, true):
			mal = "se para a %.2f m de lo previsto con la recta libre (%s)" % [_plana(kb, prev), _freno(kb, prev)]
	if tipo == "perdido" and _plana(ka, kb) < 0.05:
		_hallazgo("toque perdido CONFIRMADO", txt + ": Kael no se mueve")
	await _cerrar_tramo(P.sector_de(kb.x, kb.z), "clic", "%s %s" % [tipo, txt], r, tipo == "perdido" or tipo == "desviado", mal)


# ================================================================= salidas

func _sin_salida_de_la_escena(que: String, antes) -> void:
	await _segundos(1.0)
	var R = root.get_node_or_null("Recursos")
	if current_scene != antes or (R != null and R.cambiando):
		_hallazgo("salida", "%s cambia de escena: «%s»" % [que, current_scene.scene_file_path if current_scene != null else "?"])
		await _cargar_ciudad()
	else:
		_nota("salida: %s no saca de la ciudad — OK" % que)


func _salidas() -> void:
	_nota("== SALIDAS")
	for k in [KEY_ESCAPE, KEY_TAB, KEY_BACKSPACE, KEY_M, KEY_F3, KEY_F3]:
		var antes = current_scene
		_tecla(k, true)
		await _frames(3)
		_tecla(k, false)
		await _sin_salida_de_la_escena("la tecla %s" % OS.get_keycode_string(k), antes)
	var a2 = current_scene
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _sin_salida_de_la_escena("el botón Atrás (NOTIFICATION_WM_GO_BACK_REQUEST)", a2)
	await _puerta_del_sur()
	# empujar contra la Puerta del Sur y la muralla con las teclas
	for teclas in [[KEY_DOWN], [KEY_DOWN, KEY_LEFT], [KEY_DOWN, KEY_RIGHT], [KEY_DOWN]]:
		_empezar_tramo()
		var k0 := _kael()
		for t in teclas:
			_tecla(t, true)
		await _segundos(2.5)
		for t in teclas:
			_tecla(t, false)
		await _frames(6)
		var mal := ""
		if _kael().z >= 95.0 or not P.andable(_kael().x, _kael().z):
			mal = "Kael sale de la ciudad: %s" % _txt(_kael())
		await _cerrar_tramo("puerta_sur", "salida", "teclas %s contra la muralla desde %s" % [str(teclas.map(func(x): return OS.get_keycode_string(x))), _txt(k0)],
			{"llega": true, "falta": 0.0}, teclas.size() == 1, mal)
		await _andar_a(P.ancla("puerta_sur"), 0.4)
	# clics al sur, en la franja de abajo
	for pp in [Vector2(640, 690), Vector2(200, 690), Vector2(1100, 690), Vector2(640, 600)]:
		if _se_puede_tocar(pp):
			_empezar_tramo()
			await _clic(pp)
			await _segundos(2.5)
			var mal := ""
			if _kael().z >= 95.0 or not P.andable(_kael().x, _kael().z) or current_scene != v:
				mal = "Kael sale: %s" % _txt(_kael())
			await _cerrar_tramo("puerta_sur", "salida", "clic al sur (%d, %d)" % [pp.x, pp.y], {"llega": true}, false, mal)
			await _andar_a(P.ancla("puerta_sur"), 0.4)
	# el botón de la Puerta del Sur muchas veces y Intro
	await _segundos(0.6)
	var antes = current_scene
	for i in 6:
		if v.boton_accion.is_visible_in_tree():
			await _clic_boton(v.boton_accion)
		await _frames(3)
	for i in 3:
		_tecla(KEY_ENTER, true)
		await _frames(2)
		_tecla(KEY_ENTER, false)
		await _segundos(0.6)
	await _sin_salida_de_la_escena("el botón de la Puerta del Sur (6 clics seguidos) e Intro (3)", antes)
	_nota("aviso tras la Puerta del Sur: «%s»" % v.ultimo_aviso)


# ================================================================= clics rápidos y arrastre

func _rapidos() -> void:
	_nota("== CLICS RÁPIDOS")
	_empezar_tramo()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1611
	for i in 30:
		var pp := Vector2(rng.randf_range(80, 1200), rng.randf_range(180, 680))
		if not _se_puede_tocar(pp):
			continue
		var w: Vector2 = root.get_final_transform() * pp
		for pulsada in [true, false]:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.position = w
			e.global_position = w
			e.pressed = pulsada
			Input.parse_input_event(e)
		await _frames(1)
	var f := 0
	while f < 300 and v.destino != null:
		await _frames(2)
		f += 2
	await _cerrar_tramo(P.sector_de(_kael().x, _kael().z), "rapido", "30 clics en 30 fotogramas", {"llega": true}, true)
	# arrastre: pulsar, mover por la pantalla y soltar
	_empezar_tramo()
	var a: Vector2 = root.get_final_transform() * Vector2(300, 600)
	var e1 := InputEventMouseButton.new()
	e1.button_index = MOUSE_BUTTON_LEFT
	e1.position = a
	e1.global_position = a
	e1.pressed = true
	Input.parse_input_event(e1)
	for i in 40:
		var q: Vector2 = root.get_final_transform() * Vector2(300 + i * 20, 600 - i * 8)
		var m := InputEventMouseMotion.new()
		m.position = q
		m.global_position = q
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(m)
		await _frames(1)
	var e2 := InputEventMouseButton.new()
	e2.button_index = MOUSE_BUTTON_LEFT
	e2.position = root.get_final_transform() * Vector2(1100, 280)
	e2.global_position = e2.position
	e2.pressed = false
	Input.parse_input_event(e2)
	f = 0
	while f < 300 and v.destino != null:
		await _frames(2)
		f += 2
	await _cerrar_tramo(P.sector_de(_kael().x, _kael().z), "rapido", "arrastre de 40 fotogramas", {"llega": true}, true)


# ================================================================= teclas

func _mantener(teclas: Array, seg: float) -> void:
	for t in teclas:
		_tecla(t, true)
	await _segundos(seg)
	for t in teclas:
		_tecla(t, false)
	await _frames(6)


func _teclas_escalera(s: String, i: int) -> void:
	var su: Array = P.trazado(s).SUELOS[i]
	var e: Variant = _extremos_rampa(su)
	if e == null:
		return
	var a: Vector3 = e[0]
	var b: Vector3 = e[1]
	await _andar_a(a, 0.3)
	var d := Vector2(b.x - a.x, b.z - a.z)
	var ida: Array = [KEY_DOWN if d.y > 0 else KEY_UP] if absf(d.y) > absf(d.x) else [KEY_RIGHT if d.x > 0 else KEY_LEFT]
	var vuelta: Array = [{KEY_DOWN: KEY_UP, KEY_UP: KEY_DOWN, KEY_LEFT: KEY_RIGHT, KEY_RIGHT: KEY_LEFT}[ida[0]]]
	var lado: Array = [KEY_LEFT] if ida[0] in [KEY_UP, KEY_DOWN] else [KEY_UP]
	for paso in [[ida, d.length() / 4.2 + 0.5, "ida"], [lado, 1.5, "de lado a mitad"], [vuelta, d.length() / 4.2 + 0.8, "vuelta"]]:
		if paso[2] == "de lado a mitad":
			await _andar_a(e[2], 0.3)
		_empezar_tramo()
		var k0 := _kael()
		await _mantener(paso[0], paso[1])
		await _cerrar_tramo(s, "teclas", "escalera %d %s: %s %.1f s desde %s hasta %s" % [i, paso[2], str(paso[0].map(func(x): return OS.get_keycode_string(x))),
			paso[1], _txt(k0), _txt(_kael())], {"llega": true}, paso[2] == "de lado a mitad")


# Pegado a una pared: hacia ella y luego en diagonal (¿se desliza?).
func _teclas_pared(s: String, donde: Vector3, contra: Array, diagonal: Array, eje_lado: Vector2) -> void:
	await _andar_a(donde, 0.3)
	_empezar_tramo()
	await _mantener(contra, 1.5)
	var k0 := _kael()
	await _mantener(diagonal, 1.5)
	var dl := Vector2(_kael().x - k0.x, _kael().z - k0.z).dot(eje_lado)
	var txt := "pegado en %s con %s; luego %s 1,5 s: avanza %.2f m a lo largo de la pared (libre: %.1f)" % [_txt(k0),
		str(contra.map(func(x): return OS.get_keycode_string(x))), str(diagonal.map(func(x): return OS.get_keycode_string(x))), dl, 4.2 * 1.5 * 0.707]
	if dl < 0.3:
		_hallazgo("teclas", "[%s] %s: no se desliza" % [s, txt])
	await _cerrar_tramo(s, "teclas", txt, {"llega": true}, true)


# ================================================================= recargas difíciles

func _recargar_aqui(nombre: String) -> void:
	var k := _kael()
	var s := P.sector_de(k.x, k.z)
	_nota("recarga: %s en %s [%s]%s" % [nombre, _txt(k), s, (" con destino %s" % _txt(v.destino)) if v.destino != null else ""])
	await _recargar(s)
	if k_al_tocar != null:                          # (17/11) donde estaba al TOCAR el botón (recorrido_ciudad._recargar)
		k = k_al_tocar
	if _vivo():
		_nota("  guardado %s · reaparece %s [%s] (a %.2f m de donde estaba al tocar el botón)" % [
			_txt(Engine.get_meta("pos_3d", Vector3.ZERO)), _txt(_kael()), P.sector_de(_kael().x, _kael().z), _plana(k, _kael())])
	if _vivo() and absf(_kael().y - k.y) > 0.05:
		_hallazgo("recarga", "%s: Kael vuelve a otra altura (%.2f → %.2f)" % [nombre, k.y, _kael().y])
	if _vivo() and not v.cargador.montados.has(v.cargador.actual):
		_hallazgo("recarga", "%s: su sector no está montado al volver" % nombre)


func _recargas() -> void:
	_nota("== RECARGAS")
	var su: Array = P.trazado("plaza_tapiz").SUELOS
	var e: Variant = _extremos_rampa(su[1])
	if e != null:
		await _andar_a(e[2], 0.25)
		await _recargar_aqui("a mitad de la escalinata de la plaza")
	for cid in ["calle_mayor", "paso_botica", "calle_cuervo"]:
		var c := P.conexion(cid)
		await _andar_a(P.centro_conexion(c), 0.2)
		await _recargar_aqui("en el borde de la conexión %s" % cid)
	# andando
	await _andar_a(P.punto_conexion(P.conexion("calle_mayor"), "b", 4.0), 0.4)
	var s: Variant = _siguiente_toque(P.ancla("ref_plaza_tapiz"))
	if s != null:
		await _clic(s[1])
		await _segundos(0.4)
		await _recargar_aqui("andando (destino puesto)")
		if _vivo() and v.destino != null:
			_hallazgo("recarga", "tras recargar andando, Kael sigue con destino %s" % str(v.destino))
	# dos clics seguidos en «Guardar y recargar»
	var viejo = v
	var cuantas := [0]
	var R = root.get_node_or_null("Recursos")
	var t0 := Engine.get_process_frames()
	await _clic_boton(v.boton_recargar)
	if is_instance_valid(viejo) and viejo.is_inside_tree():
		await _clic_boton(viejo.boton_recargar)
	var escenas := {}
	var tt := Time.get_ticks_msec()
	while Time.get_ticks_msec() - tt < 8000:
		await process_frame
		if current_scene != null and current_scene != viejo:
			escenas[current_scene.get_instance_id()] = true
	await _cargar_ciudad()
	_nota("dos clics seguidos en «Guardar y recargar»: %d escena(s) nueva(s) — %s" % [escenas.size(), "OK" if escenas.size() == 1 else "MAL"])
	if escenas.size() != 1:
		_hallazgo("recarga", "dos clics seguidos en «Guardar y recargar» dan %d escenas nuevas" % escenas.size())


# ================================================================= ciclos (fugas)

func _contar_sectores() -> int:
	return current_scene.find_children("Sector_*", "", true, false).size() if current_scene != null else -1


func _ciclos() -> void:
	_nota("== CICLOS")
	var en_banco: Array = []
	for i in 4:
		await _volver_al_banco(false)
		await _segundos(1.5)
		en_banco.append(_monitores())
		_nota("ciclo %d en el banco: %s" % [i + 1, en_banco[-1]])
		var mal := await _entrar_desde_el_banco()
		if mal != "":
			_hallazgo("ciclos", "entrar %d: %s" % [i + 1, mal])
			return
		_nota("ciclo %d en la ciudad: %s; montados %s; nodos Sector_ %d; Dialogic timeline_ended %d conexiones" % [i + 1, _monitores(),
			", ".join(v.cargador.ids_montados()), _contar_sectores(),
			root.get_node("Dialogic").timeline_ended.get_connections().size() if root.has_node("Dialogic") else -1])
	# CAL tres veces (bajo → medio → alto → bajo)
	for i in 3:
		var bc: Button = null
		for x in v.find_children("*", "Button", true, false):
			if (x as Button).text.begins_with("CAL"):
				bc = x
		if bc == null:
			_nota("CAL: no hay botón")
			break
		var k := _kael()
		var viejo = v
		await _clic_boton(bc)
		var tt := Time.get_ticks_msec()
		while Time.get_ticks_msec() - tt < 20000 and (current_scene == viejo or current_scene == null):
			await process_frame
		await _cargar_ciudad()
		var cal = load("res://prototipos/calidad_proto.gd")
		_nota("CAL %d: perfil %s, Kael %s → %s, montados %s (máximo %d), nodos Sector_ %d; %s" % [i + 1, cal.actual(), _txt(k), _txt(_kael()),
			", ".join(v.cargador.ids_montados()), v.cargador.maximo(), _contar_sectores(), _monitores()])
		if _plana(k, _kael()) > 1.0:
			_hallazgo("CAL", "tras CAL (%s) Kael no vuelve a donde estaba: %s → %s" % [cal.actual(), _txt(k), _txt(_kael())])
		if v.cargador.montados.size() > v.cargador.maximo() or _contar_sectores() != v.cargador.montados.size():
			_hallazgo("CAL", "tras CAL (%s): %d montados y %d nodos Sector_" % [cal.actual(), v.cargador.montados.size(), _contar_sectores()])
	for i in 3:
		await _recargar(v.cargador.actual)
		_nota("recarga %d: %s; nodos Sector_ %d" % [i + 1, _monitores(), _contar_sectores()])


# ================================================================= el recorrido de ataque

func _ir(s: String, meta: Vector3, nombre: String) -> void:
	await _tramo(s, "ir", nombre, meta)


func _jugar() -> void:
	await _frames(3)
	_nota("DIAG ROMPER: ventana %s, viewport %s, transformación %s, perfil %s" % [root.size, root.get_visible_rect().size,
		root.get_final_transform(), perfil])
	var d0 := DirAccess.open("user://")
	_nota("user:// al empezar (%s): %s" % [OS.get_user_data_dir(), str(d0.get_files() if d0 != null else [])])
	_preparar_rejilla()
	_preparar_cajas()
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(BANCO)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == BANCO and current_scene.get("marco") != null:
			break
	await _segundos(1.0)
	_nota("en el banco: %s" % _monitores())
	var mal := await _entrar_desde_el_banco()
	if mal != "" or not _vivo():
		_hallazgo("entrada", "no se entra: " + mal)
		_fin()
		return
	process_frame.connect(_vigia)
	vigilar = true
	_nota("en la ciudad: %s" % _monitores())
	if "foco" in OS.get_cmdline_user_args():
		await _foco()
		_fin()
		return
	if "extra" in OS.get_cmdline_user_args():
		await _extra()
		_fin()
		return
	if "recargas" in OS.get_cmdline_user_args():          # (17/11) solo las recargas difíciles, para reproducirlas
		await _recargas()
		_fin()
		return
	await _salidas()
	await _rapidos()
	await _escanear("patio de caravanas")
	# Ribera, Oficios, Barrio Alto, Terrazas, Cuervo, Pasajes y la Plaza, escaneando en cada sitio
	await _ir("puerta_sur", _con("rampa_carros", "a"), "rampa de los carros (lado caravanas)")
	await _escanear("rampa de los carros, lado caravanas")
	await _ir("ribera", P.ancla("ref_ribera"), "Torre de la Campana")
	await _escanear("Torre de la Campana")
	await _ir("ribera", _con("escalera_molino", "b"), "Escalera del Molino (abajo)")
	await _ir("oficios", _con("escalera_molino", "a"), "Escalera del Molino (arriba)")
	await _ir("oficios", P.ancla("ref_oficios"), "la forja")
	await _escanear("la forja")
	await _ir("oficios", _con("subida_colina", "a"), "Subida de la Colina (abajo)")
	await _ir("barrio_alto", _con("subida_colina", "b"), "Subida de la Colina (arriba)")
	await _escanear("Subida de la Colina arriba")
	await _ir("barrio_alto", _ancla("barrio_alto", "n_paseo_e"), "Paseo del Concejo")
	await _escanear("Paseo del Concejo")
	await _ir("barrio_alto", P.ancla("ref_barrio_alto"), "el Árbol")
	await _escanear("el Árbol")
	await _ir("barrio_alto", _con("terrazas_altas", "b"), "terrazas altas (lado barrio)")
	await _ir("terrazas", P.ancla("ref_terrazas"), "lavadero")
	await _escanear("lavadero de las Terrazas")
	await _teclas_escalera("terrazas", _rampa_mas_larga("terrazas"))
	await _ir("terrazas", _con("escaleras_terrazas", "b"), "Escaleras de las Terrazas (arriba)")
	await _ir("cuervo", _con("escaleras_terrazas", "a"), "Escaleras de las Terrazas (abajo)")
	await _ir("cuervo", P.ancla("ref_cuervo"), "la taberna")
	await _escanear("Taberna del Cuervo")
	await _ir("cuervo", _con("pasaje_velas", "a"), "Pasaje del Corro (cuervo)")
	await _ir("pasajes", P.ancla("ref_pasajes"), "Patio de las Velas")
	await _escanear("Patio de las Velas")
	await _ir("pasajes", _con("paso_botica", "a", 2.0), "Paso de la Botica (pasajes)")
	await _escanear("Paso de la Botica, lado pasajes")
	await _ir("plaza_tapiz", _con("paso_botica", "b", 2.0), "Paso de la Botica (plaza)")
	await _escanear("Paso de la Botica, lado plaza")
	var cb := P.conexion("paso_botica")
	await _teclas_pared("plaza_tapiz", P.centro_conexion(cb), [KEY_UP], [KEY_UP, KEY_RIGHT], Vector2(1, 0))
	await _ir("plaza_tapiz", _con("calle_cuervo", "a"), "Calle del Cuervo (plaza)")
	await _escanear("Calle del Cuervo, lado plaza")
	await _ir("plaza_tapiz", P.ancla("ref_plaza_tapiz"), "la fuente")
	await _escanear("la fuente")
	await _teclas_escalera("plaza_tapiz", 1)
	await _recargas()
	vigilar = false
	await _ciclos()
	_nota("VIGÍA del cargador: %d fotogramas; el sector de Kael sin montar %d; más de los permitidos %d; máximo montados %d; errores %s; vecino sin montar a < %.0f m: %s" % [
		vig["frames"], vig["actual_sin_montar"], vig["exceso"], max_montados, str(vig["error"]), CERCA_VECINO, str(vig["vecino"])])
	for id in vig["ej_vecino"]:
		_nota("  vecino sin montar: " + vig["ej_vecino"][id])
	await _salir_del_banco()
	_fin()


func _con(id: String, lado: String, dentro := 3.0) -> Vector3:
	return P.punto_conexion(P.conexion(id), lado, dentro)


# Tocar donde se ve el punto del mundo w (sobre su suelo): qué dice la escena y qué hace Kael.
func _tocar_mundo(w: Vector3, nombre: String) -> void:
	await _segundos(1.0)
	var pp: Vector2 = v.cam.unproject_position(w)
	var sp = v._punto_suelo(pp)
	var m: Array = v.cargador.ids_montados()
	var k0 := _kael()
	_empezar_tramo()
	var foto := await _foto_marca("toque_%s" % nombre, [pp])
	await _clic(pp)
	var f := 0
	while f < 240 and v.destino != null:
		await _frames(2)
		f += 2
	await _frames(6)
	var txt := "«%s»: tocar %s [%s, %s] en (%d, %d) del viewport = %s de la ventana %s con Kael en %s (montados %s): la escena toca %s; Kael %s → %s (%.2f m)" % [
		nombre, _txt(w), P.sector_de(w.x, w.z), "montado" if v.cargador.montados.has(P.sector_de(w.x, w.z)) else "SIN MONTAR", pp.x, pp.y,
		str(root.get_final_transform() * pp), root.size, _txt(k0), ", ".join(m), _txt(sp) if sp != null else "NADA", _txt(k0), _txt(_kael()), _plana(k0, _kael())]
	if sp == null and _plana(k0, _kael()) < 0.05:
		_hallazgo("toque perdido CONFIRMADO", txt + " · foto " + foto)
	await _cerrar_tramo(P.sector_de(_kael().x, _kael().z), "clic", txt, {"llega": true}, false)


# La escalinata de la plaza con las teclas y «Guardar y recargar» a mitad de ella (quieto) y bajo cubiertas.
func _extra() -> void:
	_nota("== EXTRA: escalinata, recargas a mitad y bajo cubiertas")
	await _ir("puerta_sur", _con("calle_mayor", "a", 4.0), "Calle Mayor (caravanas)")
	await _teclas_escalera("plaza_tapiz", 2)
	var e: Variant = _extremos_rampa(P.trazado("plaza_tapiz").SUELOS[2])
	for f in [0.5, 0.25]:
		var m: Vector3 = _suelo((e[0] as Vector3).lerp(e[1], f))
		await _andar_a(m, 0.3)
		await _segundos(0.5)
		await _recargar_aqui("quieto en la escalinata (%.0f %%)" % (f * 100.0))
	for x in [["plaza_tapiz", "cubierta_paso"], ["plaza_tapiz", "toldo_flores"], ["terrazas", ""]]:
		var s: String = x[0]
		var b = null
		for bb in P.trazado(s).BLOQUES:
			if (x[1] != "" and bb[0] == x[1]) or (x[1] == "" and "tendedero" in String(bb[0])):
				b = bb
				break
		if b == null:
			continue
		var p: Variant = _bajo_cubierta(s, b)
		if p == null:
			continue
		await _ir(s, p, "bajo %s" % b[0])
		await _segundos(0.5)
		await _recargar_aqui("quieto bajo %s" % b[0])


func _foco() -> void:
	_nota("== FOCO: acercarse al Paso Cubierto de la Botica desde la Calle Mayor")
	await _ir("plaza_tapiz", _con("calle_mayor", "b", 4.0), "Calle Mayor (plaza)")
	await _ir("plaza_tapiz", Vector3(-26.2, 2.0, 55.6), "ante el Paso de la Botica")
	_nota("montados: %s" % ", ".join(v.cargador.ids_montados()))
	await _escanear("ante el Paso de la Botica (desde la Calle Mayor)")
	if _plana(_kael(), Vector3(-26.2, 2.0, 55.6)) > 0.4:
		await _andar_a(Vector3(-26.2, 2.0, 55.6), 0.3)
	for w in [Vector3(-33.0, 2.0, 55.5), Vector3(-36.0, 2.0, 55.5)]:
		if P.andable(w.x, w.z):
			await _tocar_mundo(Vector3(w.x, P.altura(w.x, w.z), w.z), "el Paso de la Botica, dentro de los Pasajes")
			await _andar_a(Vector3(-26.2, 2.0, 55.6), 0.3)
	# lejos, arriba de la pantalla, en varios sitios
	for sitio in [["la fuente", P.ancla("ref_plaza_tapiz")], ["Calle del Cuervo (plaza)", _con("calle_cuervo", "a")],
			["Calle del Mercado (plaza)", _con("calle_mercado", "a")], ["Calle del Árbol (plaza)", _con("calle_arbol", "a")],
			["Calle del Cuervo (cuervo)", _con("calle_cuervo", "b")], ["Pasaje del Corro (pasajes)", _con("pasaje_velas", "b")]]:
		await _ir(P.sector_de(sitio[1].x, sitio[1].z), sitio[1], sitio[0])
		await _escanear(sitio[0])
	_nota("VIGÍA: vecino sin montar a < %.0f m: %s" % [CERCA_VECINO, str(vig["vecino"])])
	for id in vig["ej_vecino"]:
		_nota("  vecino sin montar: " + vig["ej_vecino"][id])


func _rampa_mas_larga(s: String) -> int:
	var t = P.trazado(s)
	var mejor := 0
	var lmax := 0.0
	for i in t.SUELOS.size():
		var su: Array = t.SUELOS[i]
		if String(su[2]) == "":
			continue
		var l := absf(float(su[4]) - float(su[3]))
		if l > lmax and _extremos_rampa(su) != null:
			lmax = l
			mejor = i
	return mejor


func _salir_del_banco() -> void:
	await _volver_al_banco(false)
	await _segundos(1.0)
	var b: Button = null
	for x in current_scene.find_children("*", "Button", true, false):
		if (x as Button).text == "Salir del banco":
			b = x
	if b == null:
		_nota("no hay «Salir del banco»")
		return
	var R0 = root.get_node_or_null("Recursos")
	await _pulsar(b, func(): return R0.cambiando or current_scene == null or current_scene.scene_file_path != BANCO, 3.0)
	var tt := Time.get_ticks_msec()
	while Time.get_ticks_msec() - tt < 15000 and (R0.cambiando or current_scene == null):
		await process_frame
	if R0.cambiando or current_scene == null:          # (19/11, PC-10, KAEL_ESPERAS_19_11) antes, seguía en silencio
		_nota("FALLO: tras «Salir del banco» el cambio de escena no termina en 15 s de reloj (R.cambiando=%s)" % R0.cambiando)
		fallos += 1
	await _segundos(1.0)
	var quedan: Array = []
	for m in ["ciudad_v12", "banco_pruebas", "archivo_partida_prueba", "prologo_visto", "pos_3d", "pos_3d_lugar", "pos_3d_ok", "calidad_proto"]:
		if Engine.has_meta(m):
			quedan.append("%s=%s" % [m, str(Engine.get_meta(m))])
	var d := DirAccess.open("user://")
	_nota("tras «Salir del banco»: escena «%s»; metas que quedan: %s; user://: %s" % [current_scene.scene_file_path if current_scene != null else "?",
		str(quedan), str(d.get_files() if d != null else [])])
	for q in quedan:
		if q.begins_with("prologo_visto") or q.begins_with("pos_3d_lugar=103") or q.begins_with("ciudad_v12"):
			_hallazgo("sesión", "tras salir del banco queda %s" % q)


func _fin() -> void:
	_nota("HALLAZGOS: %d" % hall.size())
	for h in hall:
		_nota("  " + h)
	_terminar()
