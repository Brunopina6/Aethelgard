extends SceneTree
# DIAGNÓSTICO (18/11, Redmi: REDMI_18_11.md, «un muro tapa media figura de Kael»), NO prueba de la lista: sin ventana y
# sin escena, solo los trazados. Barre lo andable de la ciudad (rejilla de 0,25 m) donde Kael cabe (plano.holgado) y,
# desde la cámara de la ciudad (plano.posicion_camara), mira cuánto de la figura ANCHA de Kael (de −ANCHO a +ANCHO en x,
# de 0,85 a 1,45 m de alto: torso y cabeza) tapan los bloques que la escena NO aclara. La escena aclara un ocultable si
# corta un rayo a ciudad.gd PUNTOS_KAEL (±0,25 m de lado) con su caja ensanchada «margen» m en x (trazado_comun.gd,
# MARGEN_LADO; sector.gd, aclarar); los no ocultables no se aclaran nunca.
# Por qué la figura ancha: diag_ciudad_silueta.gd usa ±0,25 m, pero en la captura del Redmi (t04_este_5.png, 58 px por
# metro a 17,8 m de la cámara) Lya mide unos 45 px de ancho (≈ 0,8 m) y Kael con los brazos algo más: pegado a una fachada
# que tiene a su lado, la mitad de fuera de ±0,25 m quedaba tapada sin que ningún rayo de la escena tocase la casa.
# Imprime, para margen 0 (como hasta hoy) y para el margen de sector.gd, por bloque, en cuántas casillas tapa ≥ UMBRAL
# de la figura ancha y el peor ejemplo; y si el bloque es ocultable o no.
# Uso: Godot --path aethelgard --headless --script res://pruebas/diag_ciudad_fachadas.gd [-- umbral=0.25 ancho=0.4 margen=0.2]

const P := preload("res://zonas3d/ciudad/plano.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
# (ciudad.gd, PUNTOS_KAEL; ciudad.gd no se carga con --script: usa autoloads)
const PUNTOS_KAEL := [Vector3(0.0, 1.5, 0.0), Vector3(0.0, 0.8, 0.0), Vector3(0.0, 0.25, 0.0),
	Vector3(-0.25, 0.8, 0.0), Vector3(0.25, 0.8, 0.0), Vector3(-0.25, 1.4, 0.0), Vector3(0.25, 1.4, 0.0)]
const PASO := 0.25

var umbral := 0.25
var ancho := 0.4
var margen := Comun.MARGEN_LADO            # (el de la escena: sector.gd, aclarar)
var altos := 0.0                           # > 0: solo cuentan los bloques que suben esto sobre el suelo de Kael (fachadas)
var pegado := 0.0                          # > 0: solo las casillas PEGADAS a una pared a su lado (en x): donde Kael, movido
										   # esto en x, ya no cabe (plano.holgado); con 0,15, una pared a menos de 0,45 m


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("umbral="):
			umbral = float(a.trim_prefix("umbral="))
		elif a.begins_with("ancho="):
			ancho = float(a.trim_prefix("ancho="))
		elif a.begins_with("margen="):
			margen = float(a.trim_prefix("margen="))
		elif a.begins_with("altos="):
			altos = float(a.trim_prefix("altos="))
		elif a.begins_with("pegado="):
			pegado = float(a.trim_prefix("pegado="))
	_correr.call_deferred()


func _correr() -> void:
	var figura: Array = []
	for i in 9:
		for j in 3:
			figura.append(Vector3(-ancho + i * ancho / 4.0, 0.85 + j * 0.3, 0.0))
	# El sitio del Redmi (t04_este_5.png: Kael en el soportal de la Calle Mayor, pegado a la fachada oeste de la casa de
	# su derecha, ante la puerta «casa_soportal_s») y los de sitio=x,z;x,z…: qué tapa la figura ancha con cada margen.
	var sitios: Array = [Vector2(7.68, 50.5), Vector2(7.69, -27.19)]   # (fotos_ciudad_optimiza sitios=v18: v01 y v02)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("sitio="):
			for par in a.trim_prefix("sitio=").split(";"):
				var xz := par.split(",")
				sitios.append(Vector2(float(xz[0]), float(xz[1])))
	for q in sitios:
		var k := Vector3(q.x, P.altura(q.x, q.y), q.y)
		var cam := P.posicion_camara(k)
		var cortan: Array = []
		for s in P.ORDEN:
			var t = P.trazado(s)
			for b in t.BLOQUES:
				for c in Comun.cajas_bloque(b):
					var ok := false
					for d in figura:
						if (c as AABB).intersects_segment(cam, k + d):
							ok = true
							break
					if ok:
						cortan.append("%s/%s%s" % [s, b[0], " (ocultable)" if Comun.ocultable(b, t.OCULTABLES) else " (NO ocultable)"])
						break
		print("SITIO %s (holgura %.2f, cámara %s): cortan la figura ancha %s; tapado sin aclarar: margen 0 → %.0f %% %s, margen %.2f → %.0f %% %s" % [
			str(k), P.holgura(q.x, q.y), str(cam), str(cortan), float(tapado(k, figura, 0.0)[0]) * 100.0, str(tapado(k, figura, 0.0)[1]),
			margen, float(tapado(k, figura, margen)[0]) * 100.0, str(tapado(k, figura, margen)[1])])
	var celdas: Array = []
	for s in P.ORDEN:
		var t = P.trazado(s)
		for su in t.SUELOS:
			var r: Rect2 = su[1]
			for i in range(floori(r.position.x / PASO), ceili(r.end.x / PASO)):
				for j in range(floori(r.position.y / PASO), ceili(r.end.y / PASO)):
					var q := Vector2((i + 0.5) * PASO, (j + 0.5) * PASO)
					if not r.has_point(q) or not P.andable(q.x, q.y) or P.sector_en_caja(q.x, q.y) != s:
						continue
					if P.holgado(q.x, q.y) and (pegado <= 0.0 or not P.holgado(q.x + pegado, q.y) or not P.holgado(q.x - pegado, q.y)):
						celdas.append(Vector3(q.x, P.altura(q.x, q.y), q.y))
	var margenes := [0.0, margen]
	for m in margenes:
		var por_bloque := {}
		var ejemplos := {}
		var malas := 0
		for k in celdas:
			var x := tapado(k, figura, m, altos)
			if float(x[0]) >= umbral:
				malas += 1
				for id in x[1]:
					por_bloque[id] = int(por_bloque.get(id, 0)) + 1
					if not ejemplos.has(id) or float(x[0]) > float(ejemplos[id][0]):
						ejemplos[id] = [x[0], k]
		print("FACHADAS (margen %.2f m, figura ±%.2f m): %d casillas donde Kael cabe; en %d la escena deja tapado ≥ %.0f %% de la figura; %d bloques" % [
			m, ancho, celdas.size(), malas, umbral * 100.0, por_bloque.size()])
		var ids := por_bloque.keys()
		ids.sort_custom(func(a, b): return por_bloque[a] > por_bloque[b])
		for id in ids:
			print("  %s [%s]: %d casillas (peor %.0f %% en %s)" % [id, "ocultable" if _es_ocultable(id) else "NO ocultable",
				por_bloque[id], float(ejemplos[id][0]) * 100.0, str(ejemplos[id][1])])
	quit(0)


static func _es_ocultable(clave: String) -> bool:
	var partes := clave.split("/")
	var t = P.trazado(partes[0])
	for b in t.BLOQUES:
		if b[0] == partes[1]:
			return Comun.ocultable(b, t.OCULTABLES)
	return false


# [fracción de la figura tapada por lo que no se aclara, [ids de esos bloques]] con Kael en k; un ocultable se aclara si
# su caja, ensanchada «margen» en x, corta un rayo de la escena (como sector.gd, aclarar).
static func tapado(k: Vector3, figura: Array, margen: float, altos := 0.0) -> Array:
	var cam := P.posicion_camara(k)
	var rayos: Array = []
	for d in PUNTOS_KAEL:
		rayos.append(k + d)
	var zona := AABB(cam, Vector3.ZERO)
	for d in figura:
		zona = zona.expand(k + d)
	var planta := Rect2(zona.position.x, zona.position.z, zona.size.x, zona.size.z).grow(0.05)
	var cerca: Array = []                       # [clave, cajas] de lo que no se aclara
	for s in P.ORDEN:
		var t = P.trazado(s)
		for b in t.BLOQUES:
			if not (b[2] as Rect2).intersects(planta, true):
				continue
			if float(b[3]) + float(b[4]) < k.y + altos:
				continue                             # (con altos > 0: solo fachadas y muros, no lo bajo delante)
			var cajas: Array = Comun.cajas_bloque(b)
			var aclara := false
			if Comun.ocultable(b, t.OCULTABLES):
				for c in cajas:
					var cc := AABB((c as AABB).position - Vector3(margen, 0.0, 0.0), (c as AABB).size + Vector3(2.0 * margen, 0.0, 0.0))
					for p in rayos:
						if cc.intersects_segment(cam, p):
							aclara = true
							break
					if aclara:
						break
			if not aclara:
				cerca.append(["%s/%s" % [s, b[0]], cajas])
	var n := 0
	var quien := {}
	for d in figura:
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
	return [float(n) / figura.size(), quien.keys()]
