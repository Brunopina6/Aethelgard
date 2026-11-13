extends SceneTree
# Herramienta (V12, especialista de mundo, 13/11): las Cumbres de Ciclópea 2D (lugar 3) para su versión 3D.
# Vuelca la disposición que zona.gd genera para el lugar 3 (estilo «nieve», semilla 1000 + 3 × 7919) en
# res://zonas3d/ciclopea/disposicion_2d.gd, que es lo que lee la 3D (como volcar_bosque_2d.gd con el Gran Bosque):
# caminos, rincones, altar, puentes, cofres con sus ids «3_x_y», el sitio del detalle y el de cada cofre de hallazgo
# (zona.gd, _sitio_detalle y _sitio_hallazgo: el Tomo de Escarcha «mirada», al norte de las ruinas), los objetos en su
# casilla y las máscaras de agua, muros y camino. prueba_ciclopea3d comprueba que el archivo sigue siendo lo que da zona.gd.
# Con una carpeta, además, el esbozo (plano_2d.png y relieve.png; fuente/esbozo_ciclopea.py).
# Uso (datos aislados): Godot --headless --path aethelgard -s res://pruebas/herramientas/volcar_ciclopea_2d.gd [-- <carpeta>]

const LUGAR := 3
const DESTINO := "res://zonas3d/ciclopea/disposicion_2d.gd"


func _initialize() -> void:
	var carpeta := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	var d := datos()
	var f := FileAccess.open(DESTINO, FileAccess.WRITE)
	f.store_string(texto(d))
	f.close()
	print("CICLOPEA escrito %s: %d objetos, %d cofres, %d puentes, hallazgos %s, detalles %s" % [DESTINO,
		d["objetos"].size(), d["cofres"].size(), d["puentes"].size(), d["hallazgos"], d["detalles"]])
	if carpeta != "":
		_esbozo(carpeta)
	quit()


static func _r(v: float) -> float:
	return snappedf(v, 0.001)


static func zona_2d():
	var z = load("res://zona.gd").new()
	var l: Dictionary = load("res://mapa.gd").LUGARES[LUGAR]
	var estilo: String = load("res://mapa.gd").ZONA_LUGAR[LUGAR]
	z.lugar = {"indice": LUGAR, "nombre": l["nombre"], "tipo": l["tipo"], "zona": estilo, "texto": l["texto"]}
	z.nombre_estilo = estilo
	z.estilo = z.ESTILOS[estilo]
	z.es_ciudad = false
	z.semilla = 1000 + LUGAR * 7919                # zona.gd, _leer_lugar
	z._generar_disposicion()
	return z


static func datos() -> Dictionary:
	var z = zona_2d()
	var caminos: Array = []
	for c in z.caminos:
		caminos.append(Array(c).map(func(p): return Vector2(_r(p.x), _r(p.y))))
	var lugares: Array = []
	for li in z.lugares_interes:
		lugares.append([li["tipo"], Vector2(_r(li["pos"].x), _r(li["pos"].y))])
	var puentes: Array = []
	for pu in z.puentes:
		puentes.append([Vector2(_r(pu[0].x / z.T), _r(pu[0].y / z.T)), Vector2(_r(pu[1].x), _r(pu[1].y)), _r(pu[2] / z.T)])
	var cofres: Array = []
	var objetos: Array = []
	for o in z.colocados:
		var c := Vector2(_r(o["pos"].x / z.T), _r(o["pos"].y / z.T))
		if o["tipo"] == "cofre":
			cofres.append([z._id_cofre(o["pos"]), c])
		else:
			objetos.append([o["tipo"], c])
	var hallazgos: Array = []
	for h in load("res://hallazgos.gd").cofres_de(LUGAR):
		var s: Vector2 = z._sitio_hallazgo(h[1])
		hallazgos.append([h[0], h[1], Vector2(_r(s.x), _r(s.y))])
	var detalles: Array = []
	for dt in load("res://progreso.gd").detalles_de(LUGAR):
		var s: Vector2 = z._sitio_detalle(dt["donde"])
		if s.x < 0:
			s = z.meta + Vector2(2.5, 1.5)
		detalles.append([dt["id"], Vector2(_r(s.x), _r(s.y))])
	var mascara := func(v: PackedByteArray) -> String:
		var s := ""
		for b in v:
			s += "1" if b != 0 else "0"
		return s
	var r := {"semilla": z.semilla, "ancho": z.ANCHO, "alto": z.ALTO, "meta": Vector2(_r(z.meta.x), _r(z.meta.y)),
		"salida_x": z.salida_x, "caminos": caminos, "lugares": lugares, "puentes": puentes, "cofres": cofres,
		"hallazgos": hallazgos, "detalles": detalles, "objetos": objetos, "agua": mascara.call(z.agua_v),
		"muros": mascara.call(z.muros), "camino": mascara.call(z.camino_v)}
	z.free()
	return r


static func _v(p: Vector2) -> String:
	return "Vector2(%s, %s)" % [str(p.x), str(p.y)]


static func texto(d: Dictionary) -> String:
	var t := PackedStringArray()
	t.append("extends RefCounted")
	t.append("# GENERADO por pruebas/herramientas/volcar_ciclopea_2d.gd: NO se edita a mano. Es la disposición que zona.gd genera")
	t.append("# para las Cumbres de Ciclópea 2D (lugar 3, estilo «nieve»), en casillas de 64 px. La lee la versión 3D")
	t.append("# (zonas3d/ciclopea/). prueba_ciclopea3d comprueba que coincide con zona.gd.")
	t.append("")
	t.append("const SEMILLA := %d" % d["semilla"])
	t.append("const ANCHO := %d" % d["ancho"])
	t.append("const ALTO := %d" % d["alto"])
	t.append("const META := %s" % _v(d["meta"]))
	t.append("const SALIDA_X := %s" % str(d["salida_x"]))
	t.append("const CAMINOS := [")
	for c in d["caminos"]:
		t.append("\t[%s]," % ", ".join(c.map(func(p): return _v(p))))
	t.append("]")
	t.append("const LUGARES := [")
	for l in d["lugares"]:
		t.append("\t[\"%s\", %s]," % [l[0], _v(l[1])])
	t.append("]")
	t.append("const PUENTES := [   # [centro, dirección del camino, largo] en casillas")
	for p in d["puentes"]:
		t.append("\t[%s, %s, %s]," % [_v(p[0]), _v(p[1]), str(p[2])])
	t.append("]")
	t.append("const COFRES := [    # [id de zona.gd, casilla]")
	for c in d["cofres"]:
		t.append("\t[\"%s\", %s]," % [c[0], _v(c[1])])
	t.append("]")
	t.append("const HALLAZGOS := [  # [id del hallazgo, «cerca», casilla donde lo pone la 2D (zona.gd, _sitio_hallazgo)]")
	for h in d["hallazgos"]:
		t.append("\t[\"%s\", \"%s\", %s]," % [h[0], h[1], _v(h[2])])
	t.append("]")
	t.append("const DETALLES := [   # [id del detalle, casilla (zona.gd, _sitio_detalle)]")
	for dt in d["detalles"]:
		t.append("\t[\"%s\", %s]," % [dt[0], _v(dt[1])])
	t.append("]")
	t.append("const OBJETOS := [   # [tipo de zona.gd, casilla]")
	for o in d["objetos"]:
		t.append("\t[\"%s\", %s]," % [o[0], _v(o[1])])
	t.append("]")
	t.append("# máscaras: «1» = sí. AGUA y CAMINO por vértice ((ANCHO + 1) × (ALTO + 1)); MUROS por casilla (ANCHO × ALTO)")
	t.append("const AGUA := \"%s\"" % d["agua"])
	t.append("const MUROS := \"%s\"" % d["muros"])
	t.append("const CAMINO := \"%s\"" % d["camino"])
	return "\n".join(t) + "\n"


# El esbozo (13/11): plano en colores y el relieve de la 3D (si ya existe su trazado) en PNG para fuente/esbozo_ciclopea.py.
func _esbozo(carpeta: String) -> void:
	var z = zona_2d()
	var W: int = z.ANCHO
	var H: int = z.ALTO
	var k := 4
	var rel := Image.create(W * k, H * k, false, Image.FORMAT_L8)
	var plano := Image.create(W * k, H * k, false, Image.FORMAT_RGB8)
	var T = load("res://zonas3d/ciclopea/trazado.gd") if ResourceLoader.exists("res://zonas3d/ciclopea/trazado.gd") else null
	for y in H * k:
		for x in W * k:
			var p := Vector2(x, y) / float(k)
			var h := 0.0
			if T != null:
				var m: Vector3 = T.mundo(p)
				h = T.altura_calculada(m.x, m.z)
			rel.set_pixel(x, y, Color.from_hsv(0, 0, clampf(h / 22.0, 0.0, 1.0)))
			var col := Color(0.86, 0.9, 0.96)
			if z.muros[mini(int(p.y), H - 1) * W + mini(int(p.x), W - 1)] != 0:
				col = Color(0.42, 0.44, 0.5)
			if z._peso(z.camino_v, p) > 0.5:
				col = Color(0.62, 0.55, 0.46)
			if z._en_agua(p * z.T):
				col = Color(0.55, 0.75, 0.9)
			plano.set_pixel(x, y, col)
	rel.save_png(carpeta.path_join("relieve.png"))
	plano.save_png(carpeta.path_join("plano_2d.png"))
	z.free()
