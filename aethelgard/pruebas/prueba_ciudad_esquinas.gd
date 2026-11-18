extends SceneTree
# V12 (18/11, Redmi: docs/v12/REDMI_18_11.md; RECORRIDO.md §5 problema 2 y §7 problema 10): con TOQUES en diagonal,
# Kael se paraba contra la ESQUINA de una casa (Barrio Alto, «t02_diag_1/2»). La recta del toque corta la esquina de un
# bloque alto y grande (no «rodeable»: ciudad._bloque_rodeable) y ciudad._ajustar_destino la cortaba ahí: el destino
# quedaba ante la esquina, Kael llegaba, se paraba y ciudad._bordear no tenía nada que rodear.
# Sin ventana, en la escena de la ciudad (banco, perfil bajo), con los choques montados:
#   1. ESQUINAS: en esquinas de verdad de los 8 sectores (casas y muros, no rodeables), Kael a 0,6 m de una cara y el
#      toque a 0,6 m de la cara de al lado, al otro lado de la esquina, con suelo llano y holgado alrededor: el destino es
#      el punto tocado y Kael llega (a < 0,5 m) en ≤ 900 fotogramas, sin pisar nada no andable ni salirse del suelo.
#      (Sin el arreglo: el destino se queda ante la esquina y Kael, parado a más de 1 m del toque.)
#   (2 y 3 son guardas de regresión: pasaban también sin el arreglo; la que lo reproduce es la 1.)
#   2. ROZANDO: la recta no entra en la casa pero pasa a menos de RADIO_CUERPO de la esquina: también llega.
#   3. A TRAVÉS: tocar al otro lado de la casa, cruzándola entera de cara a cara opuesta, sigue dando el último punto
#      andable de la recta, ante ella (no se rodea una casa entera).
# Imprime «FALLOS: n».

const ESCENA := "res://zonas3d/ciudad/ciudad.tscn"
const P := preload("res://zonas3d/ciudad/plano.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const FUERA := 0.6               # a qué distancia de la cara van el inicio y el toque
const LARGO := 1.8               # cuánto antes / después de la esquina, a lo largo de la cara
const POR_SECTOR := 2
var fallos := 0
var v


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


func _rodeable(b: Array) -> bool:
	var r: Rect2 = b[2]
	return (float(b[4]) <= v.ALTO_RODEABLE and maxf(r.size.x, r.size.y) <= v.LARGO_RODEABLE) \
		or (r.size.x <= v.ANCHO_RODEABLE and r.size.y <= v.ANCHO_RODEABLE)


# Un punto «bueno» para la prueba: andable, holgado, a la cota «y» (±0,05) y en el sector «s».
func _bueno(p: Vector2, y: float, s: String) -> bool:
	return P.andable(p.x, p.y) and P.holgado(p.x, p.y) and absf(P.altura(p.x, p.y) - y) <= 0.05 and P.sector_de(p.x, p.y) == s


func _tramo_bueno(a: Vector2, b: Vector2, y: float, s: String) -> bool:
	var n := int(ceil(a.distance_to(b) / 0.1))
	for i in n + 1:
		if not _bueno(a.lerp(b, float(i) / maxf(n, 1)), y, s):
			return false
	return true


func _tramo_andable(a: Vector2, b: Vector2, y: float) -> bool:
	var n := int(ceil(a.distance_to(b) / 0.1))
	for i in n + 1:
		var q := a.lerp(b, float(i) / maxf(n, 1))
		if not P.andable(q.x, q.y) or absf(P.altura(q.x, q.y) - y) > 0.05:
			return false
	return true


# Esquinas de bloques sólidos no rodeables con suelo llano y holgado alrededor. Cada caso: [nombre, inicio, toque, tipo].
func _casos() -> Array:
	var r: Array = []
	for s in P.ORDEN:
		var n_sector := 0
		for b in P.trazado(s).BLOQUES:
			if n_sector >= POR_SECTOR:
				break
			if not b[6] or _rodeable(b) or float(b[4]) < 1.5:
				continue
			var rect: Rect2 = b[2]
			if minf(rect.size.x, rect.size.y) < LARGO + 0.5:
				continue
			for esq in [[rect.position, Vector2(-1, -1)], [Vector2(rect.end.x, rect.position.y), Vector2(1, -1)],
					[Vector2(rect.position.x, rect.end.y), Vector2(-1, 1)], [rect.end, Vector2(1, 1)]]:
				var c: Vector2 = esq[0]
				var o: Vector2 = esq[1]                  # hacia fuera de la esquina, en x y en z
				var vuelta := Vector2(c.x + o.x * FUERA, c.y + o.y * FUERA)
				if not P.andable(vuelta.x, vuelta.y):
					continue
				var y := P.altura(vuelta.x, vuelta.y)
				# de la cara de x (normal o.x) a la cara de z (normal o.y), y al revés
				for orden in 2:
					var a := Vector2(c.x + o.x * FUERA, c.y - o.y * LARGO)
					var d := Vector2(c.x - o.x * LARGO, c.y + o.y * FUERA)
					if orden == 1:
						var t := a
						a = d
						d = t
					if not (_tramo_bueno(a, vuelta, y, s) and _tramo_bueno(vuelta, d, y, s)):
						continue
					var medio := (a + d) * 0.5
					if P.andable(medio.x, medio.y):
						continue                         # (la recta no corta la esquina: no es el caso)
					r.append(["%s/%s esquina (%.1f, %.1f) %s" % [s, b[0], c.x, c.y, "x→z" if orden == 0 else "z→x"],
						Vector3(a.x, y, a.y), Vector3(d.x, y, d.y), "corta"])
					# rozando: la recta pasa por fuera, a 0,28 m de la esquina
					var desplaza := Vector2(o.x, o.y) * 0.8
					var a3 := a + desplaza
					var d3 := d + desplaza
					if _bueno(a3, y, s) and _bueno(d3, y, s) and _tramo_andable(a3, d3, y):
						r.append(["%s/%s esquina (%.1f, %.1f) %s rozando" % [s, b[0], c.x, c.y, "x→z" if orden == 0 else "z→x"],
							Vector3(a3.x, y, a3.y), Vector3(d3.x, y, d3.y), "roza"])
					n_sector += 1
					break
				if n_sector >= POR_SECTOR:
					break
	return r


# Un caso a través: una casa cruzada de cara a cara opuesta (la primera con suelo llano a los dos lados).
func _caso_traves() -> Array:
	for s in P.ORDEN:
		for b in P.trazado(s).BLOQUES:
			if not b[6] or _rodeable(b) or float(b[4]) < 1.5:
				continue
			var rect: Rect2 = b[2]
			var cz := rect.get_center().y
			var a := Vector2(rect.position.x - 1.0, cz)
			var d := Vector2(rect.end.x + 1.0, cz + 0.5)
			if P.andable(a.x, a.y) and P.andable(d.x, d.y) and P.holgado(a.x, a.y) \
					and absf(P.altura(a.x, a.y) - P.altura(d.x, d.y)) < 0.05 and P.sector_de(a.x, a.y) == s:
				return ["%s/%s de oeste a este" % [s, b[0]], Vector3(a.x, P.altura(a.x, a.y), a.y), Vector3(d.x, P.altura(d.x, d.y), d.y), rect]
	return []


func _andar(caso: Array) -> Dictionary:
	var desde: Vector3 = caso[1]
	var hasta: Vector3 = caso[2]
	v._colocar_kael(desde)
	await _frames(8)
	var sector := P.sector_de(desde.x, desde.z)
	var montado: bool = v.cargador.montados.has(sector)
	var d = v._ajustar_destino(hasta)
	v.destino = d
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
	v.destino = null
	await _frames(2)
	return {"destino": d, "falta": Vector2(k.x - hasta.x, k.z - hasta.z).length(), "mal": mal, "montado": montado, "k": k}


func _correr() -> void:
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()
	BP.poner_grupo(BP.EXPLORAR["ciudad"]["activos"])
	Engine.set_meta("calidad_proto", "bajo")
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
	var casos := _casos()
	var cortan := casos.filter(func(c): return c[3] == "corta").size()
	_ok(cortan >= 6, "hay esquinas de casas y muros para probar (%d que cortan, %d rozando)" % [cortan, casos.size() - cortan])
	for caso in casos:
		var r: Dictionary = await _andar(caso)
		var hasta: Vector3 = caso[2]
		var d = r["destino"]
		var en_toque: bool = d != null and Vector2(d.x - hasta.x, d.z - hasta.z).length() < 0.2
		_ok(r["montado"] and en_toque and r["falta"] < 0.5 and (r["mal"] as Array).is_empty(),
			"%s: destino %s, Kael acaba a %.2f m del toque (< 0,5) en (%.2f, %.2f), sin pisar lo sólido %s" % [
				caso[0], "en el toque" if en_toque else "cortado en %s" % str(d), r["falta"], r["k"].x, r["k"].z,
				str((r["mal"] as Array).slice(0, 3))])
	var tr := _caso_traves()
	_ok(not tr.is_empty(), "hay una casa con suelo a los dos lados para cruzarla")
	if not tr.is_empty():
		v._colocar_kael(tr[1])
		await _frames(8)
		var d = v._ajustar_destino(tr[2])
		var rect: Rect2 = tr[3]
		_ok(d != null and d.x < rect.position.x and P.andable(d.x, d.z),
			"%s: tocar al otro lado de la casa sigue dando el último punto andable ante ella (%s)" % [tr[0], str(d)])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
