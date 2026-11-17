extends SceneTree
# DIAGNÓSTICO (17/11, rama area-ciudad-redmi), NO prueba de la lista: sin ventana y sin escena, solo los trazados. En lo
# andable de la ciudad (rejilla de 0,25 m) donde Kael cabe (plano.holgado), cuánto de la SILUETA de Kael (5 × 3 puntos: de
# −0,25 a 0,25 m de ancho y de 0,85 a 1,45 m de alto, el torso y la cabeza) tapan, desde la cámara de la ciudad, los bloques que la escena NO aclara: los no ocultables y los
# ocultables que no cortan ninguno de los rayos de la escena (ciudad.gd, PUNTOS_KAEL). Lo que se vio en el Redmi (16/11):
# un pilar fino de la lonja delante de Kael y medio Kael tapado de lado por un pretil o un pilar del pórtico.
# Imprime, por bloque, en cuántas casillas tapa ≥ UMBRAL de la silueta, y los peores ejemplos.
# Uso: Godot --path aethelgard --headless --script res://pruebas/diag_ciudad_silueta.gd [-- umbral=0.4]

const P := preload("res://zonas3d/ciudad/plano.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
# (los puntos a los que la escena tira rayos: ciudad.gd, PUNTOS_KAEL; ciudad.gd no se carga con --script: usa autoloads)
const PUNTOS_KAEL := [Vector3(0.0, 1.5, 0.0), Vector3(0.0, 0.8, 0.0), Vector3(0.0, 0.25, 0.0),
	Vector3(-0.25, 0.8, 0.0), Vector3(0.25, 0.8, 0.0), Vector3(-0.25, 1.4, 0.0), Vector3(0.25, 1.4, 0.0)]
const PASO := 0.25

var umbral := 0.4


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("umbral="):
			umbral = float(a.trim_prefix("umbral="))
	_correr.call_deferred()


func _correr() -> void:
	var silueta: Array = []
	for i in 5:
		for j in 3:                              # (el torso y la cabeza: lo bajo delante de las piernas es lo normal)
			silueta.append(Vector3(-0.25 + i * 0.125, 0.85 + j * 0.3, 0.0))
	var por_bloque := {}
	var ejemplos := {}
	var casillas := 0
	var malas := 0
	for s in P.ORDEN:
		var t = P.trazado(s)
		for su in t.SUELOS:
			var r: Rect2 = su[1]
			for i in range(floori(r.position.x / PASO), ceili(r.end.x / PASO)):
				for j in range(floori(r.position.y / PASO), ceili(r.end.y / PASO)):
					var q := Vector2((i + 0.5) * PASO, (j + 0.5) * PASO)
					if not r.has_point(q) or not P.andable(q.x, q.y) or P.sector_en_caja(q.x, q.y) != s:
						continue
					if not P.holgado(q.x, q.y):
						continue                             # (17/11: Kael ya no se mete en la franja del cuerpo)
					casillas += 1
					var k := Vector3(q.x, P.altura(q.x, q.y), q.y)
					var x := tapado(k, silueta)
					if float(x[0]) >= umbral:
						malas += 1
						for id in x[1]:
							por_bloque[id] = int(por_bloque.get(id, 0)) + 1
							if not ejemplos.has(id) or float(x[0]) > float(ejemplos[id][0]):
								ejemplos[id] = [x[0], k]
	print("SILUETA: %d casillas andables; en %d la escena deja tapada ≥ %.0f %% de la silueta de Kael" % [casillas, malas, umbral * 100.0])
	var ids := por_bloque.keys()
	ids.sort_custom(func(a, b): return por_bloque[a] > por_bloque[b])
	for id in ids:
		print("  %s: %d casillas (peor %.0f %% en %s)" % [id, por_bloque[id], float(ejemplos[id][0]) * 100.0, str(ejemplos[id][1])])
	quit(0)


# [fracción de la silueta tapada por lo que no se aclara, [ids de esos bloques]] con Kael en k.
static func tapado(k: Vector3, silueta: Array) -> Array:
	var cam := P.posicion_camara(k)
	var rayos: Array = []
	for d in PUNTOS_KAEL:
		rayos.append(k + d)
	var zona := AABB(cam, Vector3.ZERO)
	for d in silueta:
		zona = zona.expand(k + d)
	var cerca: Array = []                       # [sector, bloque, cajas, se aclara]
	for s in P.ORDEN:
		var t = P.trazado(s)
		var planta := Rect2(zona.position.x, zona.position.z, zona.size.x, zona.size.z).grow(0.05)
		for b in t.BLOQUES:
			if not (b[2] as Rect2).intersects(planta, true):
				continue
			var cajas: Array = Comun.cajas_bloque(b)
			var aclara := false
			if Comun.ocultable(b, t.OCULTABLES):
				for c in cajas:
					for p in rayos:
						if (c as AABB).intersects_segment(cam, p):
							aclara = true
							break
					if aclara:
						break
			if not aclara:
				cerca.append(["%s/%s" % [s, b[0]], cajas])
	var n := 0
	var quien := {}
	for d in silueta:
		var p: Vector3 = k + d
		for x in cerca:
			var corta := false
			for c in x[1]:
				if (c as AABB).intersects_segment(cam, p):
					corta = true
					break
			if corta:
				n += 1
				quien[x[0]] = true
				break
	return [float(n) / silueta.size(), quien.keys()]
