extends SceneTree
# El arte de Oakhaven (T-089, gráficos) sin ventana: la interfaz de ciudades/oakhaven_piezas.gd y lo que promete.
#   Godot --headless --path aethelgard --script res://pruebas/prueba_oakhaven_arte.gd --fixed-fps 30
# Comprueba:
#   - crear_pieza(): cada id da un Node2D (null si no hay arte o el tamaño de casilla no vale), con sus imágenes
#     cargadas, ordenadas con y_sort, con el material que les toca (edificios con el aclarado alrededor de Kael, la
#     calcomanía del suelo en mezcla premultiplicada y sin luz, efectos sin luz) y sin luces 2D ni partículas de más;
#   - las huellas: cada lugar de canon con arte se dibujó para SU rectángulo de ciudades/oakhaven.gd, y el cuerpo de
#     cada edificio cubre su huella (borde de abajo en la fachada sur, a lo ancho de la huella);
#   - otra huella o otro tamaño de casilla: la pieza se recoloca o se escala bien;
#   - anclas y estados: los faroles de la ronda (farol_1..3) y el destello del cofre de las raíces se encienden y se
#     apagan; el humo del crematorio sale dentro del mapa;
#   - el relleno que propone gráficos: dentro del mapa, sin pisar lugares, PNJ, piezas, notas, cofres ni detalles, y
#     las casas sin pisarse entre sí;
#   - el coste: nodos por pieza y memoria de las texturas (sin repetir las compartidas), con un tope.
# Imprime «FALLOS: n» y sale con 0 si no hay ninguno.

const Piezas := preload("res://ciudades/oakhaven_piezas.gd")
const Oak := preload("res://ciudades/oakhaven.gd")
const T := 64
const TOPE_MPX := 9.0             # memoria de texturas de toda la ciudad (megapíxeles RGBA8, sin repetir)
const TOPE_NODOS_PIEZA := 40

var fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func fallo(texto: String) -> void:
	fallos += 1
	print("FALLO: ", texto)


func _probar() -> void:
	await process_frame
	var ids: Array = Piezas.ids()
	print("Piezas con arte: %d · %s" % [ids.size(), ", ".join(PackedStringArray(ids))])
	if ids.is_empty():
		fallo("no hay piezas")
	if Piezas.crear_pieza("no_existe", Rect2i(0, 0, 1, 1), T) != null:
		fallo("un id sin arte no da null")
	if Piezas.crear_pieza(ids[0], Rect2i(0, 0, 1, 1), 0) != null:
		fallo("tam_casilla 0 no da null")
	var lugares := {}
	for d in Oak.LUGARES:
		lugares[d["id"]] = d
	var texturas := {}
	var nodos_total := 0
	for id in ids:
		var r := Piezas.rect_de(id)
		var p := Piezas.crear_pieza(id, r, T)
		if p == null:
			fallo("%s: crear_pieza da null" % id)
			continue
		root.add_child(p)
		await process_frame
		nodos_total += _revisar_pieza(id, p, r, texturas)
		if lugares.has(id) and Rect2i(lugares[id]["rect"]) != r:
			fallo("%s: dibujada para %s y en oakhaven.gd es %s" % [id, r, lugares[id]["rect"]])
		p.queue_free()
	await process_frame
	_otra_huella()
	_estados()
	_relleno(lugares)
	var px := 0
	for k in texturas:
		px += texturas[k]
	print("COSTE: %d texturas distintas, %.2f Mpx (%.1f MB en RGBA8, sin comprimir); %d nodos para una pieza de cada" % [
		texturas.size(), px / 1e6, px * 4.0 / 1048576.0, nodos_total])
	if px / 1e6 > TOPE_MPX:
		fallo("las texturas pasan del tope (%.2f > %.1f Mpx)" % [px / 1e6, TOPE_MPX])
	print("FALLOS: %d" % fallos)
	quit(0 if fallos == 0 else 1)


func _revisar_pieza(id: String, p: Node2D, r: Rect2i, texturas: Dictionary) -> int:
	if not p.y_sort_enabled:
		fallo("%s: la raíz no ordena por y" % id)
	if p.position != Vector2(r.position) * T:
		fallo("%s: la raíz está en %s y no en la esquina de su huella" % [id, p.position])
	var n := _contar(p)
	if n > TOPE_NODOS_PIEZA:
		fallo("%s: %d nodos (tope %d)" % [id, n, TOPE_NODOS_PIEZA])
	var cuerpo: Sprite2D = null
	for s in _sprites(p):
		if s.texture == null:
			fallo("%s/%s: sin textura" % [id, s.name])
			continue
		var tex_ruta: String = s.texture.resource_path
		if tex_ruta != "":
			texturas[tex_ruta] = s.texture.get_width() * s.texture.get_height()
		var mat: Material = s.material
		if mat == null:
			fallo("%s/%s: sin material (recibiría el CanvasModulate dos veces)" % [id, s.name])
			continue
		if s.name == "suelo":
			if not (mat is CanvasItemMaterial and mat.blend_mode == CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
					and mat.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED):
				fallo("%s: la calcomanía del suelo no va premultiplicada y sin luz" % id)
		elif mat is ShaderMaterial:
			if not "unshaded" in mat.shader.code:
				fallo("%s/%s: su sombreado no es unshaded" % [id, s.name])
		elif mat is CanvasItemMaterial and mat.light_mode != CanvasItemMaterial.LIGHT_MODE_UNSHADED:
			fallo("%s/%s: recibe luces 2D" % [id, s.name])
		if s.name == "cuerpo":
			cuerpo = s
	for c in _todos(p):
		if c is Light2D:
			fallo("%s: trae una luz 2D (solo en el perfil alto)" % id)
		if c is CPUParticles2D and c.amount > 16:
			fallo("%s: partículas de más (%d)" % [id, c.amount])
	if cuerpo != null and not id in ["ronda", "arbol", "grieta"]:
		# el cuerpo tapa su huella: borde de abajo en la fachada sur y ancho de la huella (con margen de aleros)
		var tl := cuerpo.position + cuerpo.offset * cuerpo.scale
		var abajo := tl.y + cuerpo.texture.get_height() * cuerpo.scale.y
		var huella_abajo := float(r.size.y * T)
		if abajo < huella_abajo - 6.0 or abajo > huella_abajo + 3.0 * T:
			fallo("%s: el cuerpo acaba en y=%.0f y la fachada está en %.0f" % [id, abajo, huella_abajo])
		var ancho := cuerpo.texture.get_width() * cuerpo.scale.x
		if tl.x > 8.0 or tl.x + ancho < r.size.x * T - 8.0:
			fallo("%s: el cuerpo (x %.0f..%.0f) no cubre la huella (0..%d)" % [id, tl.x, tl.x + ancho, r.size.x * T])
		if absf(cuerpo.position.y - huella_abajo) > 2.0 * T and not id in ["puerta_sur"]:
			fallo("%s: ordena en y=%.0f, lejos de su fachada (%.0f)" % [id, cuerpo.position.y, huella_abajo])
	print("  %s: %d nodos, %d imágenes, anclas %s" % [id, n, _sprites(p).size(), ", ".join(PackedStringArray(p.anclas.keys()))])
	return n


func _otra_huella() -> void:
	# otra huella del mismo tamaño: se traslada entera; otro tamaño de casilla: se escala
	var r := Piezas.rect_de("taberna")
	var p := Piezas.crear_pieza("taberna", Rect2i(r.position + Vector2i(3, 2), r.size), T)
	if p.position != Vector2(r.position + Vector2i(3, 2)) * T:
		fallo("trasladar la taberna: %s" % p.position)
	p.free()
	var q := Piezas.crear_pieza("taberna", r, 32)
	if q.scale != Vector2(0.5, 0.5) or q.position != Vector2(r.position) * 32:
		fallo("taberna con casillas de 32 px: escala %s, posición %s" % [q.scale, q.position])
	var a: Vector2 = q.anclas["puerta"]
	root.add_child(q)
	var g: Vector2 = q.ancla("puerta")
	if not g.is_equal_approx(Vector2(r.position) * 32 + a * 0.5):
		fallo("ancla «puerta» con casillas de 32 px: %s" % g)
	if q.ancla("no_existe") != Vector2.INF:
		fallo("un ancla que no existe no da INF")
	q.free()


func _estados() -> void:
	var ronda := Piezas.crear_pieza("ronda", Piezas.rect_de("ronda"), T)
	if ronda == null:
		fallo("no hay ronda")
		return
	for k in range(1, 4):
		var e := "farol_%d" % k
		if not ronda.tiene_estado(e):
			fallo("la ronda no tiene el estado %s" % e)
			continue
		var nodos: Array = ronda.estados[e]["si"]
		if nodos.is_empty() or nodos.any(func(n): return n.visible):
			fallo("%s: encendido de partida" % e)
		ronda.poner_estado(e, true)
		if not nodos.all(func(n): return n.visible):
			fallo("%s: no se enciende" % e)
		ronda.poner_estado(e, false)
	if ronda.poner_estado("no_existe", true):
		fallo("poner_estado de un estado que no existe da true")
	ronda.free()
	var arbol := Piezas.crear_pieza("arbol", Piezas.rect_de("arbol"), T)
	if arbol == null or not arbol.tiene_estado("cofre_raices_abierto"):
		fallo("el árbol no tiene el destello del cofre de las raíces")
	else:
		var brillo: Array = arbol.estados["cofre_raices_abierto"]["no"]
		if brillo.is_empty() or not brillo[0].visible:
			fallo("el destello del cofre no se ve de partida")
		arbol.poner_estado("cofre_raices_abierto", true)
		if brillo[0].visible:
			fallo("el destello sigue con el cofre abierto")
	if arbol != null:
		arbol.free()
	var crem := Piezas.crear_pieza("crematorio", Piezas.rect_de("crematorio"), T)
	if crem != null:
		var h: Vector2 = crem.ancla("humo")
		if h.y < 2.5 * T:
			fallo("el humo del crematorio sale demasiado arriba (y=%.0f): no se vería" % h.y)
		crem.free()


func _relleno(lugares: Dictionary) -> void:
	var mapa := Rect2i(1, 1, 78, 54)
	var puntos: Array = []
	for n in Oak.NPCS:
		puntos.append(["PNJ " + n["id"], n["casilla"]])
	for p in Oak.PIEZAS:
		puntos.append(["pieza " + p["id"], p["casilla"]])
	for c in Oak.COFRES:
		puntos.append(["cofre " + c["id"], c["casilla"]])
	for n in Oak.NOTAS:
		if n.has("casilla"):
			puntos.append(["nota " + n["id"], n["casilla"]])
	for k in Oak.SITIOS_DETALLE:
		puntos.append(["detalle " + k, Oak.SITIOS_DETALLE[k]])
	var casas: Array = []
	for c in Piezas.RELLENO:
		var r: Rect2i = c["rect"]
		var etiqueta := "%s en %s" % [c["id"], r]
		if not Piezas.tiene(c["id"]):
			fallo("relleno: %s sin arte" % etiqueta)
		elif Piezas.rect_de(c["id"]).size != r.size:
			fallo("relleno: %s con otro tamaño que su arte (%s)" % [etiqueta, Piezas.rect_de(c["id"]).size])
		if not mapa.encloses(r):
			fallo("relleno: %s se sale del mapa" % etiqueta)
		var suelto: bool = c.get("suelto", false)
		var rf := Rect2(r)
		for d in Oak.LUGARES:
			var lr: Rect2 = d["rect"]
			if suelto:
				if not d["pisable"] and lr.intersects(rf):
					fallo("relleno: %s dentro de %s" % [etiqueta, d["id"]])
			elif lr.intersects(rf):
				fallo("relleno: %s pisa %s" % [etiqueta, d["id"]])
		for pt in puntos:
			if rf.grow(0.3).has_point(pt[1]):
				fallo("relleno: %s tapa %s" % [etiqueta, pt[0]])
		if not suelto:
			for o in casas:
				if Rect2(o).intersects(rf):
					fallo("relleno: %s pisa otra casa %s" % [etiqueta, o])
			casas.append(r)
	# en 3/4, una casa tapa lo que queda al norte de su huella hasta la altura de su tejado: ninguna casa del relleno
	# puede tapar así una calle, la plaza u otro lugar pisable, ni un PNJ, una pieza, una nota o un cofre
	for c in Piezas.RELLENO:
		if c.get("suelto", false):
			continue
		var r: Rect2i = c["rect"]
		var alto := _alto_sobre_huella(c["id"])
		var sombra := Rect2(r.position.x + 0.2, r.position.y - alto, r.size.x - 0.4, alto)
		for d in Oak.LUGARES:
			if d["pisable"] and Rect2(d["rect"]).intersects(sombra) and not d["id"] in ["colina"]:
				fallo("relleno: %s en %s tapa %s (su tejado sube %.1f casillas)" % [c["id"], r, d["id"], alto])
		for pt in puntos:
			if sombra.has_point(pt[1]):
				fallo("relleno: %s en %s tapa %s" % [c["id"], r, pt[0]])
	for c in Piezas.RELLENO:                       # las sueltas (farolas, ropa) tampoco dentro de una casa
		if c.get("suelto", false):
			for o in casas:
				if Rect2(o).intersects(Rect2(c["rect"])):
					fallo("relleno: %s en %s dentro de la casa %s" % [c["id"], c["rect"], o])
	print("Relleno: %d casas y %d piezas sueltas, sin pisar nada" % [casas.size(), Piezas.RELLENO.size() - casas.size()])


# Cuántas casillas sube el arte de una pieza por encima del borde norte de su huella (lo que tapa detrás de ella).
func _alto_sobre_huella(id: String) -> float:
	var d: Dictionary = Piezas.Arte.PIEZAS[id]
	var r: Rect2i = d["rect"]
	var arriba := 1e9
	for s in d["sprites"]:
		if s["tipo"] == "edificio":
			arriba = minf(arriba, s["pos"].y)
	return maxf(0.0, (r.position.y * T - arriba) / T)


func _sprites(n: Node) -> Array:
	var r: Array = []
	for c in _todos(n):
		if c is Sprite2D and c.texture != null and c.texture.resource_path.begins_with("res://ciudades/oakhaven_arte/"):
			r.append(c)
	return r


func _todos(n: Node) -> Array:
	var r: Array = []
	for c in n.get_children():
		r.append(c)
		r += _todos(c)
	return r


func _contar(n: Node) -> int:
	return 1 + _todos(n).size()
