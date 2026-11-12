extends SceneTree
# Herramienta (V12, migración del Gran Bosque Verde, 12/11): vuelca la disposición que zona.gd genera para el lugar 1
# (Gran Bosque Verde, estilo «bosque», semilla 1000 + 1 × 7919) en res://zonas3d/gran_bosque/disposicion_2d.gd, que es lo
# que lee la versión 3D: caminos, rincones (ruinas, campamento, claro), altar, puentes, cofres (con sus ids «1_x_y» de la
# 2D), el agua, los muros del borde, la tierra de los caminos y cada objeto (árboles, helechos, rocas…) en su casilla.
# Así la 3D tiene el bosque de la 2D: los mismos sitios, el mismo río con sus puentes, las mismas charcas y los árboles
# donde estaban, y una partida guardada en una se abre en la otra en el sitio equivalente.
# prueba_gran_bosque3d comprueba que el archivo sigue siendo lo que genera zona.gd (si cambia zona.gd, se vuelve a volcar).
# Uso (datos aislados):
#   Godot --headless --path aethelgard -s res://pruebas/herramientas/volcar_bosque_2d.gd [-- <carpeta para el plano.png>]

const DESTINO := "res://zonas3d/gran_bosque/disposicion_2d.gd"


func _initialize() -> void:
	var carpeta := ""
	for a in OS.get_cmdline_user_args():
		carpeta = a
	var d := datos(carpeta)
	var f := FileAccess.open(DESTINO, FileAccess.WRITE)
	f.store_string(texto(d))
	f.close()
	print("Escrito %s: %d objetos, %d cofres" % [DESTINO, d["objetos"].size(), d["cofres"].size()])
	quit()


static func _r(v: float) -> float:
	return snappedf(v, 0.001)


# La disposición del lugar 1 tal como la genera zona.gd (sin texturas ni escena: solo _generar_disposicion).
static func datos(carpeta_plano := "") -> Dictionary:
	var z = load("res://zona.gd").new()
	var l: Dictionary = load("res://mapa.gd").LUGARES[1]
	z.lugar = {"indice": 1, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "bosque", "texto": l["texto"]}
	z.nombre_estilo = "bosque"
	z.estilo = z.ESTILOS["bosque"]
	z.es_ciudad = false
	z.semilla = 1000 + 1 * 7919                    # zona.gd, _leer_lugar
	z._generar_disposicion()
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
	var mascara := func(v: PackedByteArray) -> String:
		var s := ""
		for b in v:
			s += "1" if b != 0 else "0"
		return s
	var r := {"semilla": z.semilla, "ancho": z.ANCHO, "alto": z.ALTO, "t": z.T, "meta": Vector2(_r(z.meta.x), _r(z.meta.y)),
		"salida_x": z.salida_x, "caminos": caminos, "lugares": lugares, "puentes": puentes, "cofres": cofres,
		"objetos": objetos, "agua": mascara.call(z.agua_v), "muros": mascara.call(z.muros), "camino": mascara.call(z.camino_v)}
	if carpeta_plano != "":
		var img := Image.create(z.ANCHO * 4, z.ALTO * 4, false, Image.FORMAT_RGB8)
		for y in z.ALTO * 4:
			for x in z.ANCHO * 4:
				var p := Vector2(x, y) / 4.0
				var col := Color(0.15, 0.35, 0.15)
				if z.muros[mini(int(p.y), z.ALTO - 1) * z.ANCHO + mini(int(p.x), z.ANCHO - 1)] != 0:
					col = Color(0.05, 0.12, 0.05)
				if z._peso(z.camino_v, p) > 0.5:
					col = Color(0.6, 0.48, 0.3)
				if z._en_agua(p * z.T):
					col = Color(0.2, 0.4, 0.8)
				img.set_pixel(x, y, col)
		for cf in cofres:
			img.fill_rect(Rect2i(int(cf[1].x * 4) - 3, int(cf[1].y * 4) - 3, 6, 6), Color(1, 0.85, 0.2))
		img.fill_rect(Rect2i(int(z.meta.x * 4) - 4, int(z.meta.y * 4) - 4, 8, 8), Color(0.6, 1, 0.6))
		img.save_png(carpeta_plano.path_join("bosque_2d_plano.png"))
	z.free()
	return r


static func _v(p: Vector2) -> String:
	return "Vector2(%s, %s)" % [str(p.x), str(p.y)]


# El archivo de datos (GDScript: se exporta siempre, sin filtros de exportación).
static func texto(d: Dictionary) -> String:
	var t := PackedStringArray()
	t.append("extends RefCounted")
	t.append("# GENERADO por pruebas/herramientas/volcar_bosque_2d.gd: NO se edita a mano. Es la disposición que zona.gd genera para el")
	t.append("# Gran Bosque Verde 2D (lugar 1, estilo «bosque»), en casillas de 64 px. La lee la versión 3D (zonas3d/gran_bosque/).")
	t.append("# prueba_gran_bosque3d comprueba que coincide con zona.gd.")
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
	t.append("const OBJETOS := [   # [tipo de zona.gd, casilla]")
	for o in d["objetos"]:
		t.append("\t[\"%s\", %s]," % [o[0], _v(o[1])])
	t.append("]")
	t.append("# máscaras: «1» = sí. AGUA y CAMINO por vértice ((ANCHO + 1) × (ALTO + 1)); MUROS por casilla (ANCHO × ALTO)")
	t.append("const AGUA := \"%s\"" % d["agua"])
	t.append("const MUROS := \"%s\"" % d["muros"])
	t.append("const CAMINO := \"%s\"" % d["camino"])
	return "\n".join(t) + "\n"
