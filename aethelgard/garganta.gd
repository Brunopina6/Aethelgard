extends "res://zona.gd"
# La Garganta del Diablo (cap. 4, Godot 4.x): la primera mazmorra con profundidad del documento
# «Diseño de juego de Aethelgard» (sección 3). Ocho pantallas y el nido, en un circuito:
#   arriba:  P1 Entrada → P2 Puentes colgantes → P3 Puerta sellada → P4 Gorthor
#   abajo:   P5 Cornisas I → P6 Cornisas II → P7 Palanca → P8 Grieta oculta;   el nido, bajo P6
#   P1 y P5 se unen por una escalera tallada en la roca.
# La puerta de P3 está cerrada al llegar. La palanca de P7 la abre, baja un puente de P7 a P3 y
# enciende el ascensor de P5 a la entrada: el atajo de vuelta, sin repetir la escalera.
# Encuentros: frecuentes en los puentes, pocos en las cornisas y ninguno en el resto (el nido es un
# combate fijo y Gorthor, el jefe). Secretos: el cofre raro del nido (se ve brillar desde los
# puentes), los pilares con el anillo (P2) y el pilar del peregrino (P8).
# Cada pantalla mide 20 casillas de ancho. Mientras no estén los fondos pintados, se dibuja con las
# casillas de zona.gd (estilo «garganta»: cornisas de roca sobre un abismo con niebla).

const Progreso := preload("res://progreso.gd")
const NOMBRE := "garganta"
const INDICE := 2                        # en LUGARES de mapa.gd
# Zonas en casillas: suelo que se pisa, abismo y sendas (solo dibujo). Rect2(x, y, ancho, alto).
const SUELO := [Rect2(0, 7, 58, 7), Rect2(58, 9, 4, 3), Rect2(62, 5, 16, 9),      # cornisa de arriba y arena
	Rect2(9, 14, 3, 17),                                                            # escalera P1 → P5
	Rect2(2, 31, 58, 8), Rect2(60, 34, 5, 2), Rect2(65, 31, 12, 8),                 # cornisas, paso estrecho y grieta
	Rect2(29, 39, 3, 8), Rect2(22, 47, 18, 6)]                                      # bajada al nido y nido
const ABISMO := [Rect2(13, 14, 64, 17), Rect2(22, 7, 6, 7), Rect2(31, 7, 7, 7)]     # el abismo y los huecos de P2
const SENDAS := [Rect2(0, 10, 74, 1.6), Rect2(10, 11, 1.6, 26), Rect2(2, 35, 72, 1.6),
	Rect2(30, 36, 1.6, 12)]
const INICIO := Vector2(3, 10.8)
const PUENTES := [[Vector2(25, 10.8), Vector2(1, 0), 8.0], [Vector2(34.5, 10.8), Vector2(1, 0), 9.0]]
const PUENTE_PALANCA := [Vector2(52, 22.5), Vector2(0, 1), 19.0]   # baja de P7 a P3
const PIEZAS := [
	{"tipo": "guardado", "pos": Vector2(5, 8.6)}, {"tipo": "guardado", "pos": Vector2(48, 8.6)},
	{"tipo": "palanca", "pos": Vector2(47, 33.2)},
	{"tipo": "ascensor_arriba", "pos": Vector2(19, 13.4), "otro": Vector2(19, 32.6)},
	{"tipo": "ascensor_abajo", "pos": Vector2(19, 31.6), "otro": Vector2(19, 12.2)},
	{"tipo": "puerta", "pos": Vector2(60, 11.9)},
]
const COFRE_NIDO := Vector2(31, 50.6)
const BRILLO_NIDO := Vector2(30, 24)     # el cofre del nido se ve brillar en el fondo desde los puentes
const RADIO_PIEZA := 95.0

var piezas: Array = []                   # [{tipo, pos (px), sprite, otro}]
var pieza_cerca = null
var choque_puerta: StaticBody2D


# ================================================================= construcción

func _ready() -> void:
	super._ready()
	for c in get_children():                       # el cartel de salida va a la boca del desfiladero
		if c is Label and c.text.begins_with("▼"):
			c.text = "◀ Mapa del mundo"
			c.position = Vector2(0.2 * T, 8.1 * T)
			c.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var b := Sprite2D.new()
	b.texture = luz_tex
	b.material = mat_aditivo
	b.modulate = Color(1.0, 0.82, 0.35, 0.5)
	b.position = BRILLO_NIDO * T
	b.scale = Vector2(0.12, 0.12)
	add_child(b)
	var t := create_tween().set_loops()
	t.tween_property(b, "modulate:a", 0.15, 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(b, "modulate:a", 0.5, 1.1).set_trans(Tween.TRANS_SINE)


func _leer_lugar() -> void:
	super._leer_lugar()
	if int(lugar["indice"]) != INDICE:              # probando la escena suelta
		var l: Dictionary = load("res://mapa.gd").LUGARES[INDICE]
		lugar = {"indice": INDICE, "nombre": l["nombre"], "tipo": l["tipo"], "zona": "montana", "texto": l["texto"]}
	lugar = lugar.duplicate()
	if Progreso.ganado("garganta_gorthor"):
		lugar["texto"] = "La arena guarda silencio. Gorthor ya no espera a nadie."
	nombre_estilo = NOMBRE
	estilo = ESTILOS[NOMBRE]
	es_ciudad = false
	semilla = 1000 + INDICE * 7919


func _generar_disposicion() -> void:
	var vw := ANCHO + 1
	camino_v.resize(vw * (ALTO + 1))
	agua_v.resize(vw * (ALTO + 1))
	for vy in ALTO + 1:
		for vx in vw:
			var p := Vector2(vx, vy)
			agua_v[vy * vw + vx] = 1 if _dentro(p, ABISMO) else 0
			camino_v[vy * vw + vx] = 1 if _dentro(p, SENDAS) else 0
	muros.resize(ANCHO * ALTO)
	for y in ALTO:
		for x in ANCHO:
			var c := Vector2(x + 0.5, y + 0.5)
			muros[y * ANCHO + x] = 0 if _dentro(c, SUELO) or _dentro(c, ABISMO) else 1
	puentes.clear()
	for pu in PUENTES:
		puentes.append([pu[0] * T, pu[1], pu[2] * T])
	if Progreso.estado(NOMBRE, "palanca"):
		puentes.append([PUENTE_PALANCA[0] * T, PUENTE_PALANCA[1], PUENTE_PALANCA[2] * T])
	meta = Vector2(74, 9)
	salida_x = 1.0
	# rocas y pinos en las cornisas, lejos de las sendas y de las piezas
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var pesos: Dictionary = estilo["objetos"]
	var total := 0
	for k in pesos:
		total += pesos[k]
	for y in range(1, ALTO - 1):
		for x in range(1, ANCHO - 1):
			var c := Vector2(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9))
			if muros[y * ANCHO + x] != 0 or _dentro(c, ABISMO) or _cerca_senda(c) or rng.randf() >= estilo["densidad"]:
				continue
			if c.distance_to(meta) < 4.0 or c.distance_to(INICIO) < 3.0 or c.distance_to(COFRE_NIDO) < 3.0:
				continue
			var r := rng.randi_range(1, total)
			for k in pesos:
				r -= pesos[k]
				if r <= 0:
					colocados.append({"tipo": k, "pos": c * T})
					break
	colocados.append({"tipo": "cofre", "pos": COFRE_NIDO * T})
	for i in 7:                                        # el nido: ramas y hierba seca alrededor del cofre
		var a := TAU * i / 7.0 + 0.3
		colocados.append({"tipo": "tronco" if i % 2 == 0 else "q_hierba_seca",
			"pos": (COFRE_NIDO + Vector2(cos(a) * 3.2, sin(a) * 1.8)) * T})


func _dentro(p: Vector2, rects: Array) -> bool:
	for r in rects:
		if p.x >= r.position.x and p.x <= r.end.x and p.y >= r.position.y and p.y <= r.end.y:
			return true
	return false


func _cerca_senda(c: Vector2) -> bool:
	for r in SENDAS:
		if r.grow(1.4).has_point(c):
			return true
	for p in PIEZAS:
		if c.distance_to(p["pos"]) < 2.5:
			return true
	return false


func _crear_objetos() -> void:
	super._crear_objetos()
	var palanca: bool = Progreso.estado(NOMBRE, "palanca")
	for p in PIEZAS:
		var tipo: String = p["tipo"]
		var dibujo := tipo
		if tipo.begins_with("ascensor"):
			dibujo = "ascensor"
		elif tipo == "palanca" and palanca:
			dibujo = "palanca_bajada"
		elif tipo == "puerta" and palanca:
			dibujo = "puerta_abierta"
		var pz := {"tipo": tipo, "pos": p["pos"] * T, "sprite": _poner_objeto(dibujo, p["pos"] * T)}
		if p.has("otro"):
			pz["otro"] = p["otro"] * T
		if tipo.begins_with("ascensor") and not palanca:
			pz["sprite"].modulate = Color(0.6, 0.6, 0.65)   # apagado hasta tirar de la palanca
		piezas.append(pz)
	if not palanca:                                     # la puerta cierra el paso a la arena
		choque_puerta = StaticBody2D.new()
		var forma := CollisionShape2D.new()
		var caja := RectangleShape2D.new()
		caja.size = Vector2(T * 0.9, T * 3.4)
		forma.shape = caja
		choque_puerta.add_child(forma)
		choque_puerta.position = Vector2(60, 10.5) * T
		add_child(choque_puerta)


func _crear_jugador() -> void:
	super._crear_jugador()
	if not (Engine.get_meta("pos_zona_ok", false) and Engine.get_meta("pos_zona_lugar", -1) == INDICE):
		jugador.position = INICIO * T


func _sitio_detalle(donde: String) -> Vector2:
	match donde:
		"p2":
			return Vector2(29.5, 9.0)                   # en el islote entre los dos puentes
		"p8":
			return Vector2(72, 34.2)                    # al fondo de la grieta oculta
	return super._sitio_detalle(donde)


# ================================================================= piezas

func _comprobar_cerca() -> void:
	pieza_cerca = null
	for p in piezas:
		if jugador.position.distance_to(p["pos"]) < RADIO_PIEZA:
			pieza_cerca = p
	if pieza_cerca == null:
		super._comprobar_cerca()
		return
	var palanca: bool = Progreso.estado(NOMBRE, "palanca")
	var textos := {"guardado": "Guardar partida", "palanca": "Palanca bajada" if palanca else "Tirar de la palanca",
		"ascensor_arriba": "Bajar en el ascensor", "ascensor_abajo": "Subir a la entrada", "puerta": "Examinar la puerta"}
	if pieza_cerca["tipo"] == "puerta" and palanca:
		pieza_cerca = null
		super._comprobar_cerca()
		return
	boton_examinar.text = textos[pieza_cerca["tipo"]]
	boton_examinar.visible = true


func _accion() -> void:
	if pieza_cerca == null:
		super._accion()
		return
	var palanca: bool = Progreso.estado(NOMBRE, "palanca")
	match pieza_cerca["tipo"]:
		"guardado":
			guardar_posicion()
			Progreso.guardar(scene_file_path)
			Sonido.efecto("guardado")                    # sonido.gd (T-083)
			_destello(pieza_cerca["pos"] + Vector2(0, -56), Color(0.55, 1.0, 0.65))
			_mostrar_aviso("Partida guardada.")
		"palanca":
			if not palanca:
				_tirar_palanca()
		"ascensor_arriba", "ascensor_abajo":
			if palanca:
				_viajar(pieza_cerca["otro"])
			else:
				Sonido.efecto("atascado")
				_mostrar_aviso("El ascensor no se mueve. Algo, más abajo, debería darle fuerza.")
		"puerta":
			Sonido.efecto("cerrada")
			_mostrar_aviso("Una puerta sellada con el anillo partido. No cede.")


# La palanca abre la puerta de P3, baja el puente de P7 a P3 y enciende el ascensor.
func _tirar_palanca() -> void:
	Progreso.poner_estado(NOMBRE, "palanca")
	Sonido.efecto("palanca")                           # y, poco después, el puente que baja a lo lejos (sonido.gd)
	Sonido.efecto("puente_baja", {"retraso": 0.5})
	for p in piezas:
		match p["tipo"]:
			"palanca":
				var d := _objeto("palanca_bajada")
				p["sprite"].texture = d["tex"]
			"puerta":
				var d := _objeto("puerta_abierta")
				p["sprite"].texture = d["tex"]
			"ascensor_arriba", "ascensor_abajo":
				create_tween().tween_property(p["sprite"], "modulate", Color.WHITE, 0.8)
	if choque_puerta != null:
		choque_puerta.queue_free()
		choque_puerta = null
	var nuevo := [PUENTE_PALANCA[0] * T, PUENTE_PALANCA[1], PUENTE_PALANCA[2] * T]
	var todos := puentes.duplicate()
	puentes = [nuevo]
	_dibujar_puentes()                                 # dibuja solo el puente nuevo...
	var nodo: Node = get_child(get_child_count() - 1)
	move_child(nodo, sombras.get_index())              # ...debajo de los objetos
	nodo.modulate.a = 0.0
	create_tween().tween_property(nodo, "modulate:a", 1.0, 1.2)
	todos.append(nuevo)
	puentes = todos
	_temblor_camara()
	_mostrar_aviso("Algo cruje a lo lejos. Un puente baja sobre el abismo.")
	guardar_posicion()
	Progreso.guardar(scene_file_path)


func _viajar(destino: Vector2) -> void:
	tiene_destino = false
	Sonido.efecto("ascensor")                          # sonido.gd
	var t := create_tween()
	t.tween_property(fundido, "color", Color(0, 0, 0, 1), 0.3)
	t.tween_callback(func():
		jugador.position = destino
		camara.reset_smoothing())
	t.tween_property(fundido, "color:a", 0.0, 0.35)


func _destello(pos: Vector2, color: Color) -> void:
	var b := Sprite2D.new()
	b.texture = luz_tex
	b.material = mat_aditivo
	b.modulate = Color(color, 0.9)
	b.position = pos
	b.scale = Vector2(0.1, 0.1)
	add_child(b)
	var t := create_tween()
	t.tween_property(b, "scale", Vector2(0.6, 0.6), 0.35)
	t.parallel().tween_property(b, "modulate:a", 0.0, 0.5)
	t.tween_callback(b.queue_free)


func _temblor_camara() -> void:
	var t := create_tween()
	for i in 8:
		t.tween_property(camara, "offset", Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.05)
	t.tween_property(camara, "offset", Vector2.ZERO, 0.05)


# El cofre del nido es el cofre raro de la mazmorra.
func _abrir_cofre(c: Array) -> void:
	if c[1] != _id_cofre(COFRE_NIDO * T):
		super._abrir_cofre(c)
		return
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	abiertos[c[1]] = true
	Engine.set_meta("cofres_abiertos", abiertos)
	c[2] = true
	Sonido.efecto("cofre")                             # sonido.gd
	Sonido.efecto("tesoro", {"retraso": 0.3})
	var d := _objeto("cofre_abierto")
	c[0].texture = d["tex"]
	c[0].offset = -d["origen"]
	var inv = load("res://inventario.gd")
	inv.ganar_oro(300)
	inv.agregar_objeto("Éter", 2)
	inv.agregar_objeto(Progreso.INCIENSO, 1)
	_destello(c[0].position + Vector2(0, -30), Color(1.0, 0.85, 0.3))
	_mostrar_aviso("¡Cofre raro! 300 monedas, 2 Éter y un Incienso de Ceniza.")


# ================================================================= encuentros y combates fijos

func _paso() -> void:
	pasos += 1
	_brazalete()
	if Progreso.paso_incienso():
		_mostrar_aviso("El Incienso de Ceniza se ha consumido.")
	var k := _ritmo(jugador.position / T)
	if k > 0.0 and randf() < Progreso.prob_encuentro(PROB_ENCUENTRO * k, pasos, PASOS_MIN, nombre_estilo):
		_encuentro()


# Cuántos encuentros hay en cada pantalla: muchos en los puentes (P2), pocos en las cornisas (P5 y P6).
func _ritmo(c: Vector2) -> float:
	if c.y < 14.5 and c.x >= 20.0 and c.x < 40.0:
		return 2.0
	if c.y > 30.5 and c.y < 39.5 and c.x < 40.0:
		return 0.5
	return 0.0


func _process(delta: float) -> void:
	super._process(delta)
	if saliendo or jugador == null or _en_dialogo():
		return
	var c := jugador.position / T
	if c.x < 0.6 and c.y < 14.0:
		_salir()
	elif c.y > 47.4 and not Progreso.ganado("garganta_nido"):
		_combate_fijo("garganta_nido", 6, "normal", Vector2(30.8, 44.0), "¡Algo se mueve en el nido!")
	elif c.x > 66.0 and c.y < 15.0 and not Progreso.ganado("garganta_gorthor"):
		_combate_fijo("garganta_gorthor", 5, "jefe", Vector2(63.0, 10.8), "¡Gorthor el Devorador!")


# Combate que no sale al azar (nido, jefe). Si se pierde, se vuelve un poco antes para no repetirlo
# nada más volver; al ganarlo ya no sale más (combate.gd lo apunta en "combates_ganados").
func _combate_fijo(id: String, grupo: int, tipo: String, vuelta: Vector2, aviso_texto: String) -> void:
	Engine.set_meta("grupo_combate", grupo)
	Engine.set_meta("combate_fijo", id)
	_encuentro()
	Engine.set_meta("tipo_combate", tipo)
	Engine.set_meta("pos_zona", vuelta * T)
	_mostrar_aviso(aviso_texto)
