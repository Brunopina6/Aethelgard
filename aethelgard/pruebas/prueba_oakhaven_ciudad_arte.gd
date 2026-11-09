extends SceneTree
# La ciudad hecha a mano (ciudad_oakhaven.gd) con el arte DE VERDAD de gráficos (ciudades/oakhaven_piezas.gd, T-089).
# prueba_oakhaven juega la ciudad entera (ya con este arte) y prueba el contrato con un módulo falso; esta mira lo que
# solo se ve con el de verdad. Sin ventana, con su propia partida (user://prueba_oakhaven_ciudad_arte.save).
#   1. Usa el módulo de gráficos: el ambiente, sin hierba alta y la luz de Kael de farol de mano (LUZ_JUGADOR).
#   2. Las casas son las del RELLENO (todas puestas, con su dibujo y muro invisible debajo) y las farolas, las suyas:
#      ninguna farola de zona.gd ni otra luz 2D en el mundo (solo la de Kael).
#   3. Nada pintado dos veces: lo que ya pinta el dibujo de un lugar (PINTADO_EN) es un punto vacío, y el resto de
#      piezas, notas y detalles, el provisional; todos siguen en su casilla de ciudades/oakhaven.gd.
#   4. Los vecinos: posadera, Bastián, Doña Encina y Albar con su muñeco y sin tinte; los demás, como siempre.
#   5. Los faroles de la ronda: el farol N de la partida enciende en el dibujo el que está en su sitio (de norte a sur).
#   6. El cofre de las raíces: su destello es el del Árbol (sin el provisional) y se apaga al abrirlo.
#   7. Los árboles de los jardines, solo en jardín (no en calles ni casas).
# Imprime lo que cuesta (nodos del mundo y tiempo de entrada) e «FALLOS: n»; sale con 1 si hay alguno.

const Oak := preload("res://ciudades/oakhaven.gd")
const Piezas := preload("res://ciudades/oakhaven_piezas.gd")
const CIUDAD := "res://ciudad_oakhaven.tscn"
const ARCHIVO := "user://prueba_oakhaven_ciudad_arte.save"
const T := 64.0
const PROPIOS := ["posadera", "bastian", "encina", "albar"]

var P
var R
var fallos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _hasta(cond: Callable, segundos := 30.0) -> bool:
	var limite := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < limite:
		if cond.call():
			return true
		await process_frame
	return false


func _borrar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))


func _probar() -> void:
	P = load("res://progreso.gd")
	R = root.get_node("Recursos")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_borrar()
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	load("res://grupo.gd").empezar_solo()
	await _esperar(3)
	var l: Dictionary = load("res://mapa.gd").LUGARES[Oak.INDICE]
	Engine.set_meta("lugar", {"indice": Oak.INDICE, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "llanura", "texto": l["texto"]})
	Engine.set_meta("pos_zona_ok", false)
	var t0 := Time.get_ticks_msec()
	change_scene_to_file(CIUDAD)
	if not await _hasta(func(): return current_scene != null and current_scene.scene_file_path == CIUDAD \
			and current_scene.get("jugador") != null and not R.cambiando, 60.0):
		_fallo("no se abre la ciudad")
		_terminar()
		return
	var ms := Time.get_ticks_msec() - t0
	await _esperar(10)
	var z = current_scene
	print("COSTE entrada %d ms (con la carga de la escena); nodos en el mundo %d; piezas de gráficos %d" \
		% [ms, _contar(z.mundo_y), _piezas_de(z.mundo_y).size()])
	_modulo(z)
	_relleno(z)
	_sin_doble(z)
	_vecinos(z)
	await _faroles(z)
	await _cofre_raices(z)
	_arboles(z)
	_terminar()


func _terminar() -> void:
	_borrar()
	Engine.remove_meta("archivo_partida_prueba")
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _contar(n: Node) -> int:
	var k := 1
	for c in n.get_children():
		k += _contar(c)
	return k


func _piezas_de(n: Node) -> Array:
	return n.get_children().filter(func(c): return c.get("id") != null and c.has_method("poner_estado"))


# 1. El módulo, el ambiente y la luz.
func _modulo(z) -> void:
	if z.arte != Piezas:
		_fallo("1: la ciudad no usa ciudades/oakhaven_piezas.gd")
		return
	if z.estilo["ambiente"] != Piezas.AMBIENTE:
		_fallo("1: el ambiente no es el del arte (%s)" % z.estilo["ambiente"])
	if float(z.estilo.get("hierba_alta", 1.0)) != 0.0:
		_fallo("1: hay hierba alta sobre el arte")
	if z.luz_jugador == null or not is_equal_approx(z.luz_jugador.energy, Piezas.LUZ_JUGADOR["energia"]) \
			or not is_equal_approx(z.luz_jugador.texture_scale, Piezas.LUZ_JUGADOR["escala"]):
		_fallo("1: la luz de Kael no es la de farol de mano")


# 2. Casas y farolas del RELLENO; ninguna luz 2D en el mundo.
func _relleno(z) -> void:
	if not z.con_relleno:
		_fallo("2: la ciudad no usa el RELLENO de gráficos")
		return
	var casas: Array = Piezas.RELLENO.filter(func(c): return not c.get("suelto", false))
	var farolas: Array = Piezas.RELLENO.filter(func(c): return c.get("id", "") == "farol")
	var con_dibujo := 0
	for n in z.nodos_casas:
		if str(n.get("id")).begins_with("casa_"):
			con_dibujo += 1
	if con_dibujo != casas.size():
		_fallo("2: hay %d casas con dibujo y el RELLENO trae %d" % [con_dibujo, casas.size()])
	for c in casas:
		var r: Rect2i = c["rect"]
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if z.muros[y * z.ANCHO + x] != 3:
					_fallo("2: bajo la casa %s no hay muro invisible (%d, %d)" % [r, x, y])
	if z.farolas.size() != farolas.size():
		_fallo("2: hay %d farolas y el RELLENO trae %d" % [z.farolas.size(), farolas.size()])
	var en_mundo: Array = _piezas_de(z.mundo_y).filter(func(n): return n.id == "farol")
	if en_mundo.size() != farolas.size():
		_fallo("2: hay %d farolas de gráficos en el mundo y %d sitios" % [en_mundo.size(), farolas.size()])
	var luces := _luces(z.mundo_y, z.luz_jugador)
	if not luces.is_empty():
		_fallo("2: hay %d luces 2D en el mundo (farolas o provisionales): %s" % [luces.size(), luces.slice(0, 4)])
	# solo se pisa lo que ciudades/oakhaven.gd dice que es calle, plaza o patio (prueba_oakhaven mira el resto)
	var mal := 0
	for y in z.ALTO:
		for x in z.ANCHO:
			if z.muros[y * z.ANCHO + x] != 0:
				continue
			var pisable := false
			for d in Oak.LUGARES:
				if d["pisable"] and Rect2(d["rect"]).has_point(Vector2(x, y) + Vector2(0.5, 0.5)):
					pisable = true
			if not pisable:
				mal += 1
	if mal > 0:
		_fallo("2: se pisan %d casillas que no son de ninguna calle, plaza ni patio" % mal)


func _luces(n: Node, de_kael: Node) -> Array:
	var r: Array = []
	for c in n.get_children():
		if c is PointLight2D and c != de_kael:
			var padre := c.get_parent()
			r.append("%s en %s (%s)" % [c.name, padre.name, padre.get("position")])
		r += _luces(c, de_kael)
	return r


# 3. Lo pintado por un lugar, sin provisional; todo en su casilla.
func _sin_doble(z) -> void:
	var todos: Array = []                         # [id, nodo, punto en píxeles]
	for e in z.piezas:
		todos.append([e[1]["id"], e[0], e[2]])
	for e in z.notas:
		todos.append([e[1]["id"], e[0], e[2]])
	for e in z.detalles:
		todos.append([e[1]["id"], e[0], e[0].position])
	var vistos := {}
	for e in todos:
		var id: String = e[0]
		vistos[id] = true
		var hueco: bool = e[1].get_class() == "Node2D" and e[1].get_script() == null
		if z.PINTADO_EN.has(id) and not hueco:
			_fallo("3: «%s» lleva el dibujo provisional encima del de %s" % [id, z.PINTADO_EN[id][0]])
		if not z.PINTADO_EN.has(id) and hueco and not Piezas.tiene(id):
			_fallo("3: «%s» no tiene dibujo ninguno" % id)
	for id in z.PINTADO_EN:
		if not vistos.has(id):
			_fallo("3: no está «%s»" % id)
	for e in z.piezas:
		if e[2] != e[1]["casilla"] * T:
			_fallo("3: la pieza %s no se usa desde su casilla" % e[1]["id"])
	for d in z.detalles:
		var c: Vector2 = Oak.SITIOS_DETALLE.get(d[1]["id"], Vector2.INF)
		if c != Vector2.INF and d[0].position != c * T:
			_fallo("3: el detalle %s no está en su sitio" % d[1]["id"])


# 4. Los muñecos propios.
func _vecinos(z) -> void:
	for n in z.npcs:
		var id: String = n[1]["id"]
		var ruta: String = n[0].texture.resource_path
		var datos: Dictionary = Oak.NPCS.filter(func(d): return d["id"] == id)[0]
		if id in PROPIOS:
			if ruta != Piezas.MUNECOS[id]:
				_fallo("4: %s no lleva su muñeco (%s)" % [id, ruta])
			if n[0].modulate != Color.WHITE:
				_fallo("4: %s lleva tinte sobre su muñeco" % id)
		elif ruta != datos["imagen"] or n[0].modulate != datos.get("tinte", Color.WHITE):
			_fallo("4: %s ha cambiado de muñeco o de tinte" % id)
		if n[0].position != datos["casilla"] * T:
			_fallo("4: %s no está en su casilla" % id)
	print("VECINOS ", ", ".join(PackedStringArray(z.npcs.map(func(n): return "%s=%s" % [n[1]["id"], n[0].texture.resource_path.get_file()]))))


# 5. Los faroles de la ronda, emparejados por su sitio.
func _faroles(z) -> void:
	var ronda = z.nodos_lugar.get("ronda")
	if ronda == null:
		_fallo("5: la ronda no tiene dibujo")
		return
	var de_partida: Array = Oak.PIEZAS.filter(func(p): return p["id"].begins_with("oak_farol_"))
	for p in de_partida:
		for k in ["farol_1", "farol_2", "farol_3"]:
			P.poner_estado(Oak.NOMBRE, k, false)
		var estado: String = p["id"].trim_prefix("oak_")
		P.poner_estado(Oak.NOMBRE, estado)
		z._actualizar_piezas()
		await _esperar(2)
		var encendidos: Array = []
		for k in ["farol_1", "farol_2", "farol_3"]:
			if ronda.estados.has(k) and ronda.estados[k]["si"].any(func(n): return n.visible):
				encendidos.append(k)
		if encendidos.size() != 1:
			_fallo("5: con %s encendido, el dibujo enciende %s" % [estado, encendidos])
			continue
		# el farol encendido del dibujo es el que ocupa el mismo puesto de norte a sur que la pieza (las anclas del
		# dibujo están en alto, a la altura de la llama: no casan en vertical con la casilla del suelo)
		var puesto: int = de_partida.filter(func(q): return q["casilla"].y < p["casilla"].y).size()
		var del_dibujo: Array = ["farol_1", "farol_2", "farol_3"]
		del_dibujo.sort_custom(func(a, b): return ronda.ancla(a).y < ronda.ancla(b).y)
		var mejor: String = del_dibujo[puesto]
		if encendidos[0] != mejor:
			_fallo("5: %s (casilla y = %s) enciende el %s del dibujo y no el %s, que es el suyo" \
				% [estado, p["casilla"].y, encendidos[0], mejor])
		else:
			print("FAROL %s (y = %s) → %s del dibujo" % [estado, p["casilla"].y, mejor])


# 6. El destello del cofre de las raíces.
func _cofre_raices(z) -> void:
	if z.arbol == null or not z.arbol.has_method("tiene_estado") or not z.arbol.tiene_estado("cofre_raices_abierto"):
		_fallo("6: el Árbol no trae el destello de su cofre")
		return
	if z.destellos.has("oak_cofre_raices"):
		_fallo("6: el cofre de las raíces lleva el destello provisional además del del Árbol")
	var brillo: Array = z.arbol.estados["cofre_raices_abierto"]["no"]
	if not brillo.all(func(n): return n.visible):
		_fallo("6: el destello del Árbol no se ve con el cofre cerrado")
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {}).duplicate()
	abiertos["oak_cofre_raices"] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	z._actualizar_piezas()
	await _esperar(2)
	if brillo.any(func(n): return n.visible):
		_fallo("6: el destello del Árbol sigue con el cofre abierto")


# 7. Árboles solo en jardín.
func _arboles(z) -> void:
	var en_jardin := {}
	for c in z.jardines:
		en_jardin[c] = true
	var n := 0
	for o in z.colocados:
		if o["tipo"] in z.ARBOLES:
			n += 1
			var c := Vector2i(floori(o["pos"].x / T), floori(o["pos"].y / T))
			if not en_jardin.has(c):
				_fallo("7: un %s fuera de jardín en %s" % [o["tipo"], c])
	print("ARBOLES en jardines: %d" % n)
