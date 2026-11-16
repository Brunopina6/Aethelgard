extends SceneTree
# V12 (16/11): CIUDAD COMPLETA de Oakhaven, M0: EL PLANO Y LOS TRAZADOS (zonas3d/ciudad/plano.gd y
# sectores/<id>/trazado.gd; docs/v12/CIUDAD_OAKHAVEN.md). Sin ventana y sin escena: solo datos.
#   1. Contrato: los 8 sectores (ids, cajas que no se solapan dentro de la caja de la ciudad, cotas, vecinos = conexiones);
#      cada trazado con SUELOS, BLOQUES, OCULTABLES, ANCLAS, PUERTAS, GRAFO y CAMARA_ZONAS y sus funciones; sus suelos
#      dentro de su caja y sin pisarse; tipos válidos; ningún bloque sólido sobre lo andable de OTRO sector; las
#      ocultables existen. Canon: nada andable bajo la Colina del Crematorio, ninguna puerta al crematorio, sin templo.
#   2. Anclas globales y de cada trazado en lo andable y a la altura del suelo; cada referencia en su sector; cada puerta
#      con fuera, mira, radio y texto, «fuera» andable y a su altura y a menos de su radio del umbral.
#   3. BFS de TODO lo andable de la ciudad (rejilla de 0,25 m) desde la Puerta del Sur: todo conectado; superficie andable
#      total y por sector (se imprime).
#   4. Sin saltos de más de 0,3 m entre casillas vecinas (también entre sectores).
#   5. Cada CONEXIÓN: en todo su ancho, a los dos lados, suelo andable a la cota acordada y llano LLANO_BORDE hacia dentro;
#      ancho mínimo según su tipo; la recta de 3 m a un lado a 3 m al otro se anda en los dos sentidos.
#   6. Grafo global simétrico con sus nodos en lo andable; los grafos locales, simétricos y con aristas rectas andables.
#   7. Cámara: la del barrio (altura, distancia, inclinación, campo, sin girar); el foco no salta entre casillas vecinas.
#   8. Kael visible: en una muestra de lo andable (cada metro, y además TODAS las casillas del borde de lo andable, junto a
#      bloques y huecos, donde la muestra de cada metro no veía casas ni carros: revisión del 16/11), el rayo de la cámara a su cabeza no corta ningún bloque que
#      la escena no aclare (se imprimen cuántas casillas necesitan aclarar algo) ni ningún suelo de otro nivel. Los
#      bloques finos (pilares ≤ 0,6 m) no cuentan: son más estrechos que Kael.
#   9. Sin huecos junto a lo andable (16/11, revisiones de la maqueta): ninguna casilla andable tiene una vecina sin suelo de
#      ningún sector ni bloque (salvo cubierta, copa o puerta) encima: eso es una zanja o una pared invisible.
# Imprime «FALLOS: n».

const P := preload("res://zonas3d/ciudad/plano.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const PASO := 0.25
const IDS := ["puerta_sur", "plaza_tapiz", "oficios", "terrazas", "pasajes", "cuervo", "barrio_alto", "ribera"]
var fallos := 0
var celdas := {}                   # Vector2i → [altura, sector]


func _initialize() -> void:
	_correr.call_deferred()


func _ok(cond: bool, t: String) -> void:
	if cond:
		print("OK " + t)
	else:
		fallos += 1
		print("FALLO: " + t)


func _correr() -> void:
	var t0 := Time.get_ticks_msec()
	_contrato()
	_anclas()
	_rejilla()
	_conectado()
	_alturas()
	_conexiones()
	_grafos()
	_camara()
	_visible()
	_huecos()
	print("(%.1f s)" % ((Time.get_ticks_msec() - t0) / 1000.0))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


# ================================================================= 1

func _contrato() -> void:
	_ok(P.ORDEN == IDS and P.SECTORES.size() == 8 and P.TRAZADOS.size() == 8, "1: los 8 sectores del plan, en orden %s" % str(P.ORDEN))
	var mal: Array = []
	for i in IDS.size():
		var a: Rect2 = P.SECTORES[IDS[i]]["caja"]
		if not P.CAJA_CIUDAD.encloses(a):
			mal.append("%s fuera de la caja de la ciudad" % IDS[i])
		for j in range(i + 1, IDS.size()):
			if a.intersects(P.SECTORES[IDS[j]]["caja"]):
				mal.append("%s y %s se solapan" % [IDS[i], IDS[j]])
	_ok(mal.is_empty(), "1: cajas dentro de la ciudad y sin solaparse %s" % str(mal))
	# vecinos = los de las conexiones
	var vec := {}
	for s in IDS:
		vec[s] = []
	for c in P.CONEXIONES:
		vec[c["a"]].append(c["b"])
		vec[c["b"]].append(c["a"])
	mal = []
	for s in IDS:
		var v: Array = P.SECTORES[s]["vecinos"].duplicate()
		v.sort()
		var w: Array = vec[s].duplicate()
		w.sort()
		if v != w:
			mal.append("%s: vecinos %s, conexiones %s" % [s, str(v), str(w)])
	_ok(mal.is_empty(), "1: los vecinos de cada sector son los de sus conexiones %s" % str(mal))
	for s in IDS:
		var t = P.TRAZADOS[s]
		var faltan: Array = []
		var consts: Dictionary = (t as Script).get_script_constant_map()
		for k in ["ID", "SUELOS", "BLOQUES", "OCULTABLES", "ANCLAS", "PUERTAS", "GRAFO", "CAMARA_ZONAS"]:
			if not consts.has(k):
				faltan.append(k)
		var metodos: Array = (t as Script).get_script_method_list().map(func(m): return m["name"])
		for f in ["suelo_en", "bloque_en", "andable", "altura", "sector_de", "ancla"]:
			if not f in metodos:
				faltan.append(f + "()")
		_ok(faltan.is_empty() and t.ID == s, "1: %s: el trazado tiene el contrato completo (faltan %s)" % [s, str(faltan)])
		if not faltan.is_empty():
			continue
		var caja: Rect2 = P.SECTORES[s]["caja"]
		mal = []
		for i in t.SUELOS.size():
			var su: Array = t.SUELOS[i]
			if su[0] != s:
				mal.append("suelo %d dice sector %s" % [i, su[0]])
			if not caja.encloses(su[1]):
				mal.append("suelo %d %s fuera de la caja" % [i, str(su[1])])
			if not String(su[2]) in ["", "x", "z"]:
				mal.append("suelo %d con eje «%s»" % [i, su[2]])
			for j in range(i + 1, t.SUELOS.size()):
				if (su[1] as Rect2).intersects(t.SUELOS[j][1]):
					mal.append("suelos %d y %d se pisan" % [i, j])
		var ids := {}
		for b in t.BLOQUES:
			if b.size() != 7 or b[1] != s or not String(b[5]) in Comun.TIPOS or ids.has(b[0]):
				mal.append("bloque %s mal formado (sector, tipo o id repetido)" % str(b[0]))
			ids[b[0]] = true
		for o in t.OCULTABLES:
			if not ids.has(o):
				mal.append("ocultable %s no es un bloque" % o)
		_ok(mal.is_empty(), "1: %s: suelos dentro de su caja y sin pisarse, bloques bien formados %s" % [s, str(mal)])
	# ningún bloque sólido de un sector sobre lo andable de otro
	mal = []
	for s in IDS:
		for b in P.TRAZADOS[s].BLOQUES:
			if not b[6]:
				continue
			for o in IDS:
				if o == s:
					continue
				for su in P.TRAZADOS[o].SUELOS:
					if (b[2] as Rect2).intersects(su[1]):
						mal.append("%s/%s sobre un suelo de %s" % [s, b[0], o])
	_ok(mal.is_empty(), "1: ningún bloque sólido cae sobre lo andable de otro sector %s" % str(mal))
	# canon
	mal = []
	for s in IDS:
		for su in P.TRAZADOS[s].SUELOS:
			if (su[1] as Rect2).intersects(P.COLINA):
				mal.append("suelo de %s en la colina" % s)
		for id in P.TRAZADOS[s].PUERTAS:
			if "cremator" in String(id):
				mal.append("puerta %s" % id)
		for b in P.TRAZADOS[s].BLOQUES:
			if "templo" in String(b[0]) or "vidrier" in String(b[0]):
				mal.append("bloque %s" % b[0])
	_ok(mal.is_empty(), "1: canon: nada andable bajo la Colina del Crematorio, su puerta sin entrada, sin templo de vidrieras %s" % str(mal))


# ================================================================= 2

func _anclas() -> void:
	var mal: Array = []
	for id in P.ANCLAS:
		var a: Vector3 = P.ANCLAS[id]
		if not P.andable(a.x, a.z):
			mal.append("%s fuera de lo andable" % id)
		elif absf(a.y - P.altura(a.x, a.z)) > 0.02:
			mal.append("%s a %.3f y el suelo a %.3f" % [id, a.y, P.altura(a.x, a.z)])
	for s in IDS:
		var ref := P.ancla(P.SECTORES[s]["ref"])
		if P.sector_de(ref.x, ref.z) != s:
			mal.append("la referencia de %s cae en %s" % [s, P.sector_de(ref.x, ref.z)])
		var t = P.TRAZADOS[s]
		for id in t.ANCLAS:
			var a: Vector3 = t.ANCLAS[id]
			if not t.andable(a.x, a.z):
				mal.append("%s/%s fuera de lo andable" % [s, id])
			elif absf(a.y - t.altura(a.x, a.z)) > 0.02:
				mal.append("%s/%s a %.3f y el suelo a %.3f" % [s, id, a.y, t.altura(a.x, a.z)])
		for pid in t.PUERTAS:
			var d: Dictionary = t.PUERTAS[pid]
			if not (d.get("fuera") is Vector3 and (d.get("mira") is float or d.get("mira") is int) and float(d.get("radio", 0.0)) > 0.5
					and str(d.get("texto", "")) != "" and t.ANCLAS.has(str(d.get("ancla", "")))):
				mal.append("puerta %s/%s incompleta" % [s, pid])
				continue
			var f: Vector3 = d["fuera"]
			var u: Vector3 = t.ancla(d["ancla"])
			if not t.andable(f.x, f.z) or absf(f.y - t.altura(f.x, f.z)) > 0.02:
				mal.append("«fuera» de %s/%s no está en el suelo" % [s, pid])
			if Vector2(f.x - u.x, f.z - u.z).length() >= float(d["radio"]):
				mal.append("«fuera» de %s/%s lejos de su umbral" % [s, pid])
	_ok(mal.is_empty(), "2: anclas y puertas en lo andable, a la altura del suelo y en su sector %s" % str(mal))
	for e in ["reserva_rastreadores_caravanas", "reserva_rastreadores_almacen", "reserva_piezas_patio", "reserva_piezas_taller",
			"reserva_feria_plaza", "reserva_feria_patio", "inicio", "puerta_sur"]:
		_ok(P.ANCLAS.has(e), "2: ancla global «%s»" % e)
	_ok(P.sector_de(P.INICIO.x, P.INICIO.z) == "puerta_sur", "2: el inicio está en la Puerta del Sur")
	_ok(P.puertas().size() >= 8, "2: %d entradas previstas de edificios" % P.puertas().size())


# ================================================================= 3 y 4

func _rejilla() -> void:
	for s in IDS:
		var t = P.TRAZADOS[s]
		for su in t.SUELOS:
			var r: Rect2 = su[1]
			var solidos: Array = t.BLOQUES.filter(func(b): return b[6] and (b[2] as Rect2).intersects(r))
			for i in range(floori(r.position.x / PASO), ceili(r.end.x / PASO)):
				for j in range(floori(r.position.y / PASO), ceili(r.end.y / PASO)):
					var q := Vector2((i + 0.5) * PASO, (j + 0.5) * PASO)
					if not r.has_point(q):
						continue
					var libre := true
					for b in solidos:
						if (b[2] as Rect2).has_point(q):
							libre = false
							break
					if libre:
						celdas[Vector2i(i, j)] = [Comun.cota_suelo(su, q.x, q.y), s]


func _celda(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / PASO), floori(p.z / PASO))


func _conectado() -> void:
	var inicio := _celda(P.ancla("puerta_sur"))
	_ok(celdas.has(inicio), "3: la Puerta del Sur está en lo andable")
	var visto := {inicio: true}
	var cola: Array = [inicio]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = c + d
			if celdas.has(q) and not visto.has(q):
				visto[q] = true
				cola.append(q)
	var sueltas := {}
	for c in celdas:
		if not visto.has(c):
			sueltas[celdas[c][1]] = int(sueltas.get(celdas[c][1], 0)) + 1
	_ok(visto.size() == celdas.size(), "3: el BFS desde la Puerta del Sur llega a TODO lo andable (%d de %d casillas de %.2f m; sueltas por sector %s)" % [
		visto.size(), celdas.size(), PASO, str(sueltas)])
	var por := {}
	for c in celdas:
		por[celdas[c][1]] = int(por.get(celdas[c][1], 0)) + 1
	var total := celdas.size() * PASO * PASO
	var lineas: Array = []
	for s in IDS:
		lineas.append("%s %.0f" % [s, int(por.get(s, 0)) * PASO * PASO])
	print("SUPERFICIE ANDABLE: %.0f m² (rejilla de %.2f m) · %s" % [total, PASO, ", ".join(PackedStringArray(lineas))])
	_ok(total > 5000.0, "3: superficie andable de la maqueta mínima: %.0f m²" % total)
	var no: Array = []
	for s in IDS:
		var t = P.TRAZADOS[s]
		for id in t.ANCLAS:
			if not visto.has(_celda(t.ancla(id))):
				no.append("%s/%s" % [s, id])
	_ok(no.is_empty(), "3: se llega a todas las anclas de los trazados %s" % str(no))


func _alturas() -> void:
	var salto := 0.0
	var donde := ""
	var ymin := INF
	var ymax := -INF
	for c in celdas:
		var y: float = celdas[c][0]
		ymin = minf(ymin, y)
		ymax = maxf(ymax, y)
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:
			var q: Vector2i = c + d
			if celdas.has(q):
				var dy := absf(float(celdas[q][0]) - y)
				if dy > salto:
					salto = dy
					donde = "(%.2f, %.2f) %s → %s" % [(c.x + 0.5) * PASO, (c.y + 0.5) * PASO, celdas[c][1], celdas[q][1]]
	_ok(salto <= P.SALTO_MAX, "4: sin saltos: el mayor entre casillas vecinas es %.3f m en %s" % [salto, donde])
	_ok(ymin <= -1.99 and ymax >= 15.99, "4: los desniveles del plan (de %.2f a %.2f m)" % [ymin, ymax])


# ================================================================= 5

func _conexiones() -> void:
	for c in P.CONEXIONES:
		var mal: Array = []
		var ancho: float = float(c["hasta"]) - float(c["desde"])
		var minimo: float = P.ANCHO_CALLE if c["tipo"] == "calle" else P.ANCHO_PASAJE
		if ancho < minimo - 0.001:
			mal.append("ancho %.2f < %.2f" % [ancho, minimo])
		if not (P.SECTORES.has(c["a"]) and P.SECTORES.has(c["b"])):
			mal.append("sectores")
		else:
			# el borde está entre las dos cajas y dentro de su extensión
			for lado in ["a", "b"]:
				var caja: Rect2 = P.SECTORES[c[lado]]["caja"]
				var ini: float = caja.position.x if c["borde"] == "x" else caja.position.y
				var fin: float = caja.end.x if c["borde"] == "x" else caja.end.y
				var lo: float = caja.position.y if c["borde"] == "x" else caja.position.x
				var hi: float = caja.end.y if c["borde"] == "x" else caja.end.x
				if not (is_equal_approx(ini, c["en"]) or is_equal_approx(fin, c["en"])) or c["desde"] < lo or c["hasta"] > hi:
					mal.append("el borde no es de la caja de %s" % c[lado])
				var cota: Vector2 = P.SECTORES[c[lado]]["cota"]
				if float(c["cota"]) < cota.x - 0.001 or float(c["cota"]) > cota.y + 0.001:
					mal.append("cota %.2f fuera de las de %s" % [c["cota"], c[lado]])
			var n := int(round(ancho / PASO))
			for i in n:
				var t := (i + 0.5) / n
				for lado in ["a", "b"]:
					for dentro in [0.125, P.LLANO_BORDE - 0.05]:
						var p := P.punto_conexion(c, lado, dentro, t)
						if P.sector_de(p.x, p.z) != c[lado]:
							mal.append("%s a %.2f m cae en %s" % [c[lado], dentro, P.sector_de(p.x, p.z)])
						elif not P.andable(p.x, p.z):
							mal.append("%s no andable en %s" % [c[lado], str(p)])
						elif absf(P.altura(p.x, p.z) - float(c["cota"])) > 0.01:
							mal.append("%s a %.3f en %s (cota %.2f)" % [c[lado], P.altura(p.x, p.z), str(Vector2(p.x, p.z)), c["cota"]])
			for sentido in [["a", "b"], ["b", "a"]]:
				var desde := P.punto_conexion(c, sentido[0], 3.0)
				var hasta := P.punto_conexion(c, sentido[1], 3.0)
				if not _recta(desde, hasta):
					mal.append("no se anda de %s a %s" % sentido)
		_ok(mal.is_empty(), "5: %s (%s ↔ %s, %.1f m, cota %.1f): bordes a la cota, llanos, andable en los dos sentidos %s" % [
			c["id"], c["a"], c["b"], ancho, c["cota"], str(mal.slice(0, 6))])


# Recta andable con alturas continuas (pasos de 0,1 m: ≤ SALTO_MAX).
func _recta(a: Vector3, b: Vector3) -> bool:
	var n := int(ceil(Vector2(b.x - a.x, b.z - a.z).length() / 0.1))
	var y0 := P.altura(a.x, a.z)
	for i in n + 1:
		var p := a.lerp(b, float(i) / maxf(n, 1))
		if not P.andable(p.x, p.z):
			return false
		var y := P.altura(p.x, p.z)
		if absf(y - y0) > P.SALTO_MAX:
			return false
		y0 = y
	return true


# ================================================================= 6

func _grafos() -> void:
	var g := P.grafo()
	var mal: Array = []
	for n in g:
		var p := P.nodo(n)
		if not P.andable(p.x, p.z):
			mal.append("%s fuera de lo andable %s" % [n, str(p)])
		for m in g[n]:
			if not g.has(m) or not n in g[m]:
				mal.append("%s→%s sin vuelta" % [n, m])
	_ok(mal.is_empty() and g.size() == 8 + P.CONEXIONES.size(), "6: grafo global de %d nodos, simétrico y en lo andable %s" % [g.size(), str(mal)])
	for s in IDS:
		var t = P.TRAZADOS[s]
		mal = []
		for n in t.GRAFO:
			if not t.ANCLAS.has(n):
				mal.append("%s no es un ancla" % n)
				continue
			for m in t.GRAFO[n]:
				if not t.GRAFO.has(m) or not n in t.GRAFO[m]:
					mal.append("%s→%s sin vuelta" % [n, m])
				elif not _recta(t.ancla(n), t.ancla(m)):
					mal.append("%s→%s no se anda en línea recta" % [n, m])
		_ok(mal.is_empty(), "6: %s: grafo local (%d nodos) simétrico con aristas rectas andables %s" % [s, t.GRAFO.size(), str(mal)])


# ================================================================= 7

func _camara() -> void:
	var T = load("res://zonas3d/barrio/trazado.gd")
	_ok(P.OFFSET_CAMARA == T.OFFSET_CAMARA and is_equal_approx(P.INCLINACION, T.INCLINACION) and is_equal_approx(P.CAMPO, T.CAMPO),
		"7: la cámara del barrio (altura, distancia, inclinación y campo)")
	var c := Camera3D.new()
	root.add_child(c)
	P.poner_camara(c, P.ancla("inicio"))
	_ok(absf(c.global_rotation_degrees.y) < 0.001 and absf(c.global_rotation_degrees.z) < 0.001, "7: la cámara no gira")
	c.free()
	var peor := 0.0
	var donde := ""
	for k in celdas:
		var p := Vector3((k.x + 0.5) * PASO, celdas[k][0], (k.y + 0.5) * PASO)
		var f0 := P.foco_camara(p)
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:
			var q: Vector2i = k + d
			if celdas.has(q):
				var f1 := P.foco_camara(Vector3((q.x + 0.5) * PASO, celdas[q][0], (q.y + 0.5) * PASO))
				var df := f1.distance_to(f0)
				if df > peor:
					peor = df
					donde = str(Vector2(p.x, p.z))
	_ok(peor < 0.6, "7: el foco no salta entre casillas vecinas (el mayor paso: %.3f m por 0,25 m de Kael, en %s)" % [peor, donde])


# ================================================================= 8

func _visible() -> void:
	var muestras := 0
	var con_aclarado := 0
	var tapados: Array = []
	var por_bloque := {}
	for k in celdas:
		if (posmod(k.x, 4) != 0 or posmod(k.y, 4) != 0) and not _borde(k):
			continue
		muestras += 1
		var p := Vector3((k.x + 0.5) * PASO, celdas[k][0], (k.y + 0.5) * PASO)
		var aclara := false
		for x in P.tapan_a_kael(p):
			if x[2]:
				aclara = true
			else:
				var clave := "%s/%s" % [x[0], x[1]]
				por_bloque[clave] = int(por_bloque.get(clave, 0)) + 1
				if tapados.size() < 12:
					tapados.append("%s tapa en %s" % [clave, str(Vector2(p.x, p.z))])
		if aclara:
			con_aclarado += 1
		for su in P.suelos_que_tapan(p):
			var clave := "suelo " + String(su)
			por_bloque[clave] = int(por_bloque.get(clave, 0)) + 1
			if tapados.size() < 12:
				tapados.append("%s tapa en %s" % [clave, str(Vector2(p.x, p.z))])
	print("VISIBILIDAD: %d casillas de muestra (cada metro y todo el borde de lo andable); en %d la escena aclara algo (cubiertas, copas u ocultables)" % [
		muestras, con_aclarado])
	_ok(por_bloque.is_empty() and muestras > 1000, "8: Kael visible desde la cámara en toda la muestra (bloques que tapan: %s; ej. %s)" % [
		str(por_bloque), str(tapados)])


func _borde(k: Vector2i) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if not celdas.has(k + d):
			return true
	return false


# ================================================================= 9

func _huecos() -> void:
	# Lo que «tapa» el suelo en la rejilla: los suelos de todos los sectores y los bloques que no pasan por encima.
	var cubierto := {}
	for s in IDS:
		var t = P.TRAZADOS[s]
		var rects: Array = []
		for su in t.SUELOS:
			rects.append(su[1])
		for b in t.BLOQUES:
			if not String(b[5]) in ["cubierta", "copa", "puerta"]:
				rects.append(b[2])
		for r in rects:
			for i in range(floori((r as Rect2).position.x / PASO), ceili((r as Rect2).end.x / PASO)):
				for j in range(floori((r as Rect2).position.y / PASO), ceili((r as Rect2).end.y / PASO)):
					if (r as Rect2).has_point(Vector2((i + 0.5) * PASO, (j + 0.5) * PASO)):
						cubierto[Vector2i(i, j)] = true
	var por := {}
	var ej: Array = []
	for k in celdas:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = k + d
			if not celdas.has(q) and not cubierto.has(q):
				var s: String = celdas[k][1]
				por[s] = int(por.get(s, 0)) + 1
				if ej.size() < 12:
					ej.append("%s junto a %s" % [s, str(Vector2((q.x + 0.5) * PASO, (q.y + 0.5) * PASO))])
	_ok(por.is_empty(), "9: ningún borde de lo andable da a un hueco sin suelo ni bloque (por sector %s; ej. %s)" % [str(por), str(ej)])
